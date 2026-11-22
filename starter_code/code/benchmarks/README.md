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

## Fusion opportunity: measured before any RTL

Four macro-op fusion variants were considered before writing any RTL. Each is
judged by its **fire rate** - the share of the dynamic instruction stream that
could actually fuse - measured over all fourteen kernels rather than assumed
from one example. `array-idx` exists to make the `add`+`lw` case measurable.

### Census (static pairs per kernel)

| Kernel | `addr>lw` | `addr>sw` | `lw>sw` | load-use |
|---|---|---|---|---|
| `array-idx` | 1 | 8 | 0 | 1 |
| `sum-array` | 1 | 4 | 0 | 1 |
| the other 12 kernels | **0** | **0** | **0** | **0** |

Two facts decide the question:

- The `addr>lw` pairs are inside loop bodies, so they fire once per iteration.
- The `addr>sw` pairs are **all in prologues** - the setup that stores 1..8 into
  memory before the loop. They execute once per program, never per iteration.
- `lw>sw` - the memory-to-memory copy idiom - occurs **nowhere**. A copy fusion
  would have a fire rate of exactly zero on this suite.

### What each variant would buy

| Variant | Where it fires | Cycles saved | Verdict |
|---|---|---|---|
| `add`+`lw` | 2 of 14 kernels, once per iteration | 8 cycles in `array-idx` (8.8%) | not worth it |
| `add`+`sw` | 12 pairs, all prologue, none in a loop | ~12 cycles once per program | not worth it |
| `lw`+`sw` (copy) | nowhere | 0 | nothing to measure |
| `lw`+consumer | the same array loops | ~17% on `array-idx` | clears the bar, but see below |

### The measured case: array-idx

`array-idx` is the compiler shape for `for (i=0;i<n;i++) sum += a[i];` - six
instructions per iteration with exactly one adjacent `add`+`lw`:

    slli x10, x9, 2        byte offset
    add  x11, x2, x10      address          <- add
    lw   x12, 0(x11)       value            <- lw    (fusable pair)
    add  x8, x8, x12       sum += value
    addi x9, x9, 1         i++
    blt  x9, x6, loop

Measured: 91 cycles, 8 stalls, 3 flush cycles, CPI 1.25 - about 73 retired
instructions and 8 dynamic pairs.

| Quantity | Value |
|---|---|
| fire rate (pairs / retired instructions) | 8 / 73 = **11.0%** |
| saved cycles, 1 per pair | **8 cycles = 8.8% of total** |
| `fire rate x cycles` (the loose bound) | 10.0 cycles (11.0%) |

The two bounds differ because only 73 of the 91 cycles are issue cycles: 8 stalls,
3 flush cycles and pipeline fill cannot be removed by deleting an instruction.
One cycle per pair is the tighter and correct bound; multiplying by CPI
over-credits fusion by the stall and redirect cycles.

### Why the slot variants are not worth a month

1. **The pattern is confined to indexed array code.** `add`+`lw` exists in two of
   fourteen kernels and in none of `fib`, `smul`, `nested`, `callret`,
   `if-in-loop` or any `sweep`. A feature that cannot fire in twelve of the
   fourteen kernels does not justify a month, whatever its rate where it does fire.
2. **`slli`+`add` and `add`+`lw` target the same address computation.** Fusing the
   scaled index leaves no second pair behind, so one saved slot per array access
   is the ceiling, not two.
3. **The stalls survive.** The 8 load-use stalls in `array-idx` are the same size
   as the whole slot opportunity and fusion of two ALU-adjacent ops cannot remove
   them; the loaded value still arrives a cycle late.

### The one variant that clears the bar

`lw`+consumer - a load fused with the instruction that reads its result, as in
x86's `add eax,[mem]` - removes **both** the issue slot and the load-use stall:
about 17% on `array-idx` and 16% on `sum-array`.

It is also the most expensive option considered: the memory read and the ALU
operation must happen in one cycle, so the ALU gains a third input fed from
memory and the M-stage path grows by an ALU delay. That is a datapath change, not
a decode trick, and it moves timing in the wrong direction for the clock-speed
work.

**Decision: no fusion RTL.** The slot variants fall below the 15-20% bar and the
only variant above it costs the most and helps two kernels.

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
