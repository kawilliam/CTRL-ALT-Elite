# Benchmarks

These live under `code/` because only the `code/` folder is submitted. The harness
reaches them through the symlink `verif/tests/benchmarks`, which is why
`make sim -C verif/ TEST_DIR=benchmarks` still works.

Representative loop/array workloads used to validate CPI work. These are **not**
the graded autograder binaries — the grader's sources are not available. They are
programs of the same algorithmic shape (counted loops, array access, nested loops,
call/return), and they are the only workloads in the repo that can demonstrate a
branch-predictor benefit.

## Building

    make bench-build -C verif/

`rvasm.py` (in this folder) assembles every `.txt` here into a `.x` hex image next to it. The
assembler is validated by reproducing all thirteen hand-written `pipeline_tests`
images byte for byte.

## Running

    make run -C verif/ TEST_DIR=benchmarks TEST=loop10
    make sim -C verif/ TEST_DIR=benchmarks     # every benchmark
    make sim-all -C verif/                     # every directory, 66 tests

## Contents

| Test | Shape | Self-check |
|---|---|---|
| `smoke` | 2 instructions | flow sanity |
| `sweep4/10/25/50/100` | counted loop, N iterations, one branch | iterations == N |
| `loop10` | counted loop + accumulate | sum 1..10 == 55 |
| `nested` | 5 outer x 4 inner | sum == 30 |
| `if-in-loop` | hot loop, branch falls through once | marker == 1 |
| `sum-array` | store/load loop over 4 words | total == 10 |
| `array-idx` | `s += a[i]` with a scaled index, 8 words | total == 36 |
| `fib` | iterative Fibonacci | fib(11) == 89 |
| `smul` | shift-and-add multiply, 32 iterations | 6*7 == 42 |
| `callret` | 3 calls + 3 returns | 3*5 == 15 |

`smul` is the shape a libgcc multiply takes on RV32I without the M extension, and
therefore the shape *factorial* and *GCD* contain. `callret` uses the canonical
`jal x1` / `jalr x0,0(x1)` pair, which is what a return-address stack would key on.

## Measurements

Same build, only the BHT prediction output forced to zero. All 13 pass in both
configurations, so every difference below is performance, not correctness.

| Test | BHT on (cyc) | BHT off (cyc) | Saved |
|---|---|---|---|
| `smoke` | 6 | 6 | 0 |
| `sweep4` | 29 | 29 | 0 |
| `loop10` = `sweep10` | 47 | 59 | +12 (+20.3%) |
| `sweep25` | 92 | 134 | +42 (+31.3%) |
| `sweep50` | 167 | 259 | +92 (+35.5%) |
| `sweep100` | 317 | 509 | +192 (+37.7%) |
| `nested` | 112 | 130 | +18 (+13.8%) |
| `if-in-loop` | 56 | 80 | +24 (+30.0%) |
| `sum-array` | 51 | 51 | 0 |
| `fib` | 69 | 81 | +12 (+14.8%) |
| `smul` | 218 | 328 | +110 (+33.5%) |
| `callret` | 37 | 35 | **−2 (−5.7%)** |

Two conclusions, both worth stating in the report:

- **Benefit scales with trip count and saturates near one avoided redirect per
  iteration.** Saving per iteration: 1.20 at N=10, 1.68 at N=25, 1.84 at N=50,
  1.92 at N=100 — approaching 2 cycles, i.e. one fully avoided mispredict per
  iteration. Loops shorter than ~4 iterations get nothing, because the two warm-up
  mispredicts cost as much as the predictor saves.
- **A cold 2-bit counter can make a very short loop slower.** `callret` regresses by
  2 cycles: its loop-back branch runs only three times, so seeding a new entry
  costs more than prediction recovers. This is the honest cost side of the design,
  not a bug.

## Fusion opportunity: adjacent add+lw

`array-idx` exists to answer one question before any macro-op fusion RTL is written:
how often does an `add` sit immediately before a `lw`?

Its loop body is six instructions with exactly one such pair:

    slli x10, x9, 2        byte offset
    add  x11, x2, x10      address          <- add
    lw   x12, 0(x11)       value            <- lw    (fusable pair)
    add  x8, x8, x12       sum += value
    addi x9, x9, 1         i++
    blt  x9, x6, loop

Measured: 91 cycles, 8 stalls, 3 flush cycles, CPI 1.25, so about 73 retired
instructions and 8 dynamic pairs (one per iteration).

| Quantity | Value |
|---|---|
| fire rate (pairs / retired instructions) | 8 / 73 = **11.0%** |
| saved cycles, 1 per pair | **8 cycles (8.8% of 91)** |
| `fire rate x cycles` (the loose bound) | 10.0 cycles (11.0%) |

The two bounds differ because only 73 of the 91 cycles are issue cycles: 8 stalls,
3 flush cycles and pipeline fill cannot be removed by eliminating an instruction.
Counting one cycle per pair is the tighter and correct bound; multiplying by CPI
over-credits the fusion by the stall and redirect cycles.

### Verdict

**Below the 15-20% bar, so: analysis only, no RTL.** Three reasons this kernel
overstates the case rather than understating it:

1. **The pattern is confined to indexed array code.** A census of all fourteen
   kernels finds `add`+`lw` pairs only in `array-idx` (9 static) and `sum-array`
   (4); every other kernel has **zero**. Fusion would do nothing for `fib`,
   `smul`, `nested`, `callret`, `if-in-loop` or any `sweep`.
2. **`slli`+`add` and `add`+`lw` target the same address computation.** Fusing the
   scaled index does not leave a second pair behind, so one saved slot per array
   access is the ceiling, not two.
3. **The 8 load-use stalls survive fusion.** The fused op still produces its data
   one cycle after the consumer needs it, so CPI does not improve; and moving the
   address add into the load's own cycle shortens the slack, not lengthens it.

The loop-back `addi`+branch pair is a larger opportunity - it appears once per
iteration in essentially every kernel, and fusing both would put the saving at
about 17.6% of this kernel's cycles. That case crosses the bar, but it removes
branches from the dynamic stream, which is the signal the BHT/BTB is measured on.

---

## Conventions

- Program base is `0x01000000` (`BASE_ADDR`).
- Immediates are **decimal**; branch/jal targets are **hex addresses** (or labels).
- Data addresses must stay small: the data port does not subtract `BASE_ADDR`, so
  use something like `0x1000` (built with `lui x2, 1`), not `0x01001000`.
- **Pass criterion differs by testbench:**
  - `top_tb.sv` (these benchmarks, `pipeline_tests`, `sample-bmarks`) checks
    **`x1 == 1`**.
  - `rv_official_tb.sv` (`insn-bmarks`) checks **`x3 == 1`**.
- **`ecall` must be the last executed instruction, padded with `nop`s.** The
  testbench waits ~5 cycles after `ecall` is fetched before sampling the registers,
  and anything after it retires during that window. Use the `done:` pattern: set
  `x1 = 0` by default, skip the `x1 = 1` marker on mismatch, and jump to a single
  `ecall` followed only by `nop`s.
- **A `ret`-encoded instruction is a trap for this harness.** `top_tb.sv` treats a
  fetched `0x00008067` (`jalr x0,0(x1)`) as "program finished" when `x2 ==
  BASE + MEM_DEPTH`, and the register file *resets `x2` to exactly that value*.
  Any benchmark containing a canonical return must clear `x2` first — see
  `callret.txt`.
