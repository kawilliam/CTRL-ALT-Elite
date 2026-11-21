# Benchmarks

Representative loop/array workloads used to validate CPI work. These are **not**
the graded autograder binaries — the grader's sources are not available. They are
programs of the same algorithmic shape (counted loops, array access, branches).

## Building

    make bench-build -C verif/

`tools/rvasm.py` assembles every `.txt` here into a `.x` hex image next to it. The
assembler is validated against the thirteen hand-written `pipeline_tests` images,
which it reproduces byte for byte.

## Conventions

- Program base is `0x01000000` (`BASE_ADDR`).
- Immediates are **decimal**; branch/jal targets are **hex addresses** (or labels).
- Data addresses must stay small: the data port does not subtract `BASE_ADDR`, so
  use something like `0x1000` (built with `lui x2, 1`), not `0x01001000`.
- **Pass criterion differs by testbench:**
  - `top_tb.sv` (these benchmarks, `pipeline_tests`, `sample-bmarks`) checks
    **`x1 == 1`** — `pipeline_pass()` falls through to that for unknown names.
  - `rv_official_tb.sv` (`insn-bmarks`) checks **`x3 == 1`**.
- **`ecall` must be the last executed instruction, padded with `nop`s.** The
  testbench waits ~5 cycles after seeing `ecall` in IF before sampling the
  registers, and anything after it retires during that window. A non-`nop`
  instruction after `ecall` will silently overwrite the pass register — this cost
  one debugging session to find.
- Prefer a **self-check**: compute an expected value, compare, and leave `x1 = 0`
  on mismatch.

## Running

    make run -C verif/ TEST_DIR=benchmarks TEST=loop10
    make sim-all -C verif/          # sweeps every directory, including this one

## Contents

| Test | Shape | Checks |
|---|---|---|
| `smoke` | 2 instructions | end-to-end flow sanity |
| `loop10` | counted loop, 10 iterations | sum 1..10 == 55 |
| `sum-array` | store/load loop over 4 words | load-use forwarding, total == 10 |
| `fib` | iterative Fibonacci, 10 iterations | fib(11) == 89 |
