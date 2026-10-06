# Test format

Every testbench follows `verif/template_tb.sv` provided by the professor exactly.

1. A table of tests (`tests.push_back(...)`): one row per test, listing every input and every expected output.
2. On each rising edge, the next row is driven into the module under test.
3. On the next falling edge, all outputs are compared with the row. Mismatches print `FAIL`.
4. At the end: `Completed N Tests` and `Test Passed` / `Test Failed`. A `TIMEOUT` guard stops hangs.

Run one: `make tb-<name> -C verif/`

# Coverage
Note that all modules designed have been covered, including trivial, corner, invalid and non trivial sequences.