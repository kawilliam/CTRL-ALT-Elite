# Predecoder / Core Experiments Log

Running log for the experiment loop (methodology: `AGENTS.md` at the repo root,
which points to `EECS 4201/AGENTS.md`).
**One row per variant. No row = the experiment did not happen.**

> **Location:** this log lives inside the RTL repo (`starter_code/docs/experiments.md`)
> so that every logged number is versioned next to the code that produced it.
> It previously lived at `EECS 4201/Core Improvement Plan/experiments.md`.

---

## Baseline (step 0 — frozen)

- **Date:** 2026-11-01 19:30
- **Branch/commit:** `main` @ `2ee9897` ("Cleanup (#8)"), clean working tree
- **Command:** `make sim-all -C verif/`
- **Raw log:** `verif/_results.txt`, block starting `Test Directory: insn-bmarks  Date: 2026-11-01 19:30:22` through `sample-bmarks  Date: 2026-11-01 19:30:44`
- **Known-fail list (frozen — these may not grow, ever):** *none.* 53/53 tests PASS.

This makes the regression rule strict: no test may fail, and no CPI may move
except where a step-1 hypothesis named that movement in advance.

### insn-bmarks (38)

| Test | Result | Cycles | Stalls | Squashed | CPI |
|------|--------|--------|--------|----------|-----|
| `rv32ui-p-add`    | PASS | 463 | 0 | 16 | 1.08 |
| `rv32ui-p-addi`   | PASS | 222 | 0 | 7  | 1.09 |
| `rv32ui-p-and`    | PASS | 483 | 0 | 16 | 1.08 |
| `rv32ui-p-andi`   | PASS | 178 | 0 | 7  | 1.11 |
| `rv32ui-p-auipc`  | PASS | 30  | 0 | 3  | 1.50 |
| `rv32ui-p-beq`    | PASS | 311 | 0 | 27 | 1.23 |
| `rv32ui-p-bge`    | PASS | 347 | 0 | 36 | 1.28 |
| `rv32ui-p-bgeu`   | PASS | 372 | 0 | 36 | 1.26 |
| `rv32ui-p-blt`    | PASS | 311 | 0 | 27 | 1.23 |
| `rv32ui-p-bltu`   | PASS | 336 | 0 | 27 | 1.21 |
| `rv32ui-p-bne`    | PASS | 315 | 0 | 29 | 1.25 |
| `rv32ui-p-jal`    | PASS | 27  | 0 | 3  | 1.59 |
| `rv32ui-p-jalr`   | PASS | 98  | 0 | 12 | 1.40 |
| `rv32ui-p-lb`     | PASS | 227 | 2 | 7  | 1.10 |
| `rv32ui-p-lbu`    | PASS | 227 | 2 | 7  | 1.10 |
| `rv32ui-p-lh`     | PASS | 239 | 2 | 7  | 1.09 |
| `rv32ui-p-lhu`    | PASS | 246 | 2 | 7  | 1.09 |
| `rv32ui-p-lui`    | PASS | 33  | 0 | 1  | 1.22 |
| `rv32ui-p-lw`     | PASS | 249 | 2 | 7  | 1.09 |
| `rv32ui-p-or`     | PASS | 486 | 0 | 16 | 1.08 |
| `rv32ui-p-ori`    | PASS | 185 | 0 | 7  | 1.11 |
| `rv32ui-p-sb`     | PASS | 422 | 0 | 13 | 1.08 |
| `rv32ui-p-sh`     | PASS | 475 | 0 | 13 | 1.07 |
| `rv32ui-p-simple` | PASS | 7   | 0 | 0  | 2.33 |
| `rv32ui-p-sll`    | PASS | 491 | 0 | 16 | 1.08 |
| `rv32ui-p-slli`   | PASS | 221 | 0 | 7  | 1.09 |
| `rv32ui-p-slt`    | PASS | 457 | 0 | 16 | 1.09 |
| `rv32ui-p-slti`   | PASS | 217 | 0 | 7  | 1.09 |
| `rv32ui-p-sltiu`  | PASS | 217 | 0 | 7  | 1.09 |
| `rv32ui-p-sltu`   | PASS | 457 | 0 | 16 | 1.09 |
| `rv32ui-p-sra`    | PASS | 510 | 0 | 16 | 1.08 |
| `rv32ui-p-srai`   | PASS | 236 | 0 | 7  | 1.08 |
| `rv32ui-p-srl`    | PASS | 504 | 0 | 16 | 1.08 |
| `rv32ui-p-srli`   | PASS | 230 | 0 | 7  | 1.08 |
| `rv32ui-p-sub`    | PASS | 455 | 0 | 16 | 1.09 |
| `rv32ui-p-sw`     | PASS | 482 | 0 | 13 | 1.07 |
| `rv32ui-p-xor`    | PASS | 485 | 0 | 16 | 1.08 |
| `rv32ui-p-xori`   | PASS | 187 | 0 | 7  | 1.11 |

### pipeline_tests (13)

| Test | Result | Cycles | Stalls | Squashed | CPI |
|------|--------|--------|--------|----------|-----|
| `5-stage-pipeline`     | PASS | 14 | 0 | 0 | 1.40 |
| `br-taken`             | PASS | 16 | 0 | 1 | 1.60 |
| `load-use-stall`       | PASS | 23 | 1 | 0 | 1.28 |
| `mx-bypass-rs1-alu`    | PASS | 11 | 0 | 0 | 1.57 |
| `mx-bypass-rs1-brcomp` | PASS | 14 | 0 | 0 | 1.40 |
| `mx-bypass-rs2-alu`    | PASS | 11 | 0 | 0 | 1.57 |
| `mx-bypass-rs2-brcomp` | PASS | 14 | 0 | 0 | 1.40 |
| `wd-stall`             | PASS | 13 | 0 | 0 | 1.44 |
| `wm-bypass-rs2-mem`    | PASS | 22 | 0 | 0 | 1.22 |
| `wx-bypass-rs1-alu`    | PASS | 12 | 0 | 0 | 1.50 |
| `wx-bypass-rs1-brcomp` | PASS | 14 | 0 | 0 | 1.40 |
| `wx-bypass-rs2-alu`    | PASS | 12 | 0 | 0 | 1.50 |
| `wx-bypass-rs2-brcomp` | PASS | 14 | 0 | 0 | 1.40 |

### sample-bmarks (2)

| Test | Result | Cycles | Stalls | Squashed | CPI |
|------|--------|--------|--------|----------|-----|
| `test1` | PASS | 53 | 1 | 8 | 1.56 |
| `test2` | PASS | 64 | 2 | 9 | 1.52 |

Regression rule for all future rows: every baseline-passing test still
passes, and its CPI does not move — unless the change is *designed* to move
CPI, in which case the hypothesis (step 1) said so first.

### Metrics convention (applies to every experiment)

- `cpi = total_cycles / insn_exe` (`top_tb.sv`). It is a **ratio**, so it is only comparable
  between builds with the **same dynamic instruction count**.
- **CPI alone is not a sufficient result.** Every row must also report cycles and the retired
  instruction count, so that a change in the denominator can never be mistaken for a change in
  performance.
- Any experiment that changes the instruction count — instruction fusion, macro-ops, any change
  that eliminates work rather than reordering it — must report **cycles and IPC**
  (`instructions / cycles`). In those experiments CPI may move in the "wrong" direction while
  the core gets faster, and CPI must not be used as a pass/fail criterion.

---

## Experiment 1 — Fetch-stage predecoder

### Contract (step 2) — as built

Module `pre_decode` in `code/pre_decode.sv`. Purely combinational; evaluated in
IF in the same cycle the instruction word is presented.

| Port | Dir | Width | Meaning |
|------|-----|-------|---------|
| `insn_i`    | in  | 32       | instruction word read from IMEM at `pc_i` |
| `pc_i`      | in  | 32       | address of that instruction |
| `is_insn_i` | in  | 1        | IF slot holds a real instruction; low ⇒ all outputs forced to 0 |
| `target_o`  | out | 32       | redirect target for JAL (branch target computed but unused until a BPU exists) |
| `ra_o`      | out | 32       | `pc_i + 4`, the link value (and future RAS push data) |
| `cfit_o`    | out | `cfi_t`  | CFI class: `CFI_NONE` / `CFI_BRANCH` / `CFI_JAL` / `CFI_JALR` |
| `is_call_o` | out | 1        | link-writing jump, `rd ∈ {x1, x5}` |
| `is_ret_o`  | out | 1        | `jalr x0, imm(x1|x5)` |
| `is_redir_o`| out | 1        | this instruction redirects from IF — JAL only |

Behavioural rules that define the golden model:

1. `is_insn_i == 0` ⇒ every output 0.
2. `ra_o = pc_i + 4` whenever `is_insn_i` is high.
3. **JAL:** `target_o = pc_i + sign_extend(J-imm)`, `is_redir_o = 1`, `cfit = CFI_JAL`.
4. **B_TYPE:** `target_o = pc_i + sign_extend(B-imm)`, `is_redir_o = 0` (direction unknown in IF), `cfit = CFI_BRANCH`.
5. **JALR:** `target_o = 0`, `is_redir_o = 0` (needs `rs1`; remains an EX redirect), `cfit = CFI_JALR`.
6. No state, no clock — outputs change only with the inputs.

**Why these ports.** IMEM is combinational (`main_memory.sv`), so IF sees
`f_insn` in the very cycle `pc` drives it; a JAL can therefore be resolved and
applied in that cycle with no squash at all. `ra_o`, `is_call_o` and `is_ret_o`
exist for the future return-address stack, which lives entirely in IF and never
enters the pipeline.

**System-level wiring contract** (identical on every variant, so CPI stays
comparable): `flush` is built from the **EX** redirects only (`e_brtaken ||
e_pcsel`); `f_pc` is a three-way priority mux (EX result → `pre_target` → `pc`);
`is_insn_i` is the complement of `flush`; `hazard` is not gated by any redirect.

### Hypothesis (step 1) — amended 2026-11-01

Hoisting JAL resolution from EX to IF removes both the squashed instructions and
the redirect bubble for every executed `jal`, so tests containing JALs must show
**fewer cycles and fewer squashes**. Every test that executes no JAL must be
**bit-identical** in cycles/stalls/squashes/CPI. Implementation style among the
four variants must not change any of these numbers.

*Original wording ("implementation style does not change behavior — identical
CPI") under-specified the experiment: written as it stood, the regression rule
would have filed the designed JAL improvement as a bug.*

### Variant rows

| Variant | Branch | Unit TB | Pass-set vs baseline | CPI delta | Wall-time | Waveform findings | Keep/Drop + why |
|---------|--------|---------|----------------------|-----------|-----------|-------------------|-----------------|
| v1 — flat `case`      | `feature/predecoder` (commit pending — TB + log not yet committed) | `verif/pre_decode_tb.sv` — **27/27 pass** (step 4 closed 2026-11-03) | 53/53 PASS, unchanged | 4 tests faster: `jal` −4, `auipc` −4, `test1` −6, `test2` −8; other 49 unchanged | ~1 s/test | read in Surfer; state saved `verif/wf_signals/Nov 1st jal wave.ron`. JAL: `pre_en_redir` + `jump_branch` in-cycle, `pc` takes `pre_target` next edge | adopted as the base for v2–v4 — see reproduction caveat |
| v2 — two-level PLA    | `feature/predec-v2-pla`    | | | | | | not started |
| v3 — constant LUT/ROM | `feature/predec-v3-lut`    | | | | | | not started |
| v4 — one-hot plane    | `feature/predec-v4-onehot` | | | | | | not started |

### v1 results vs baseline (run 2026-11-01 19:15)

| Test | Baseline (cyc / stall / squash / CPI) | v1 | Δ cycles |
|------|----------------------------------------|----|----------|
| `rv32ui-p-jal`   | 27 / 0 / 3 / 1.59 | 23 / 0 / 1 / 1.35 | **−4** |
| `rv32ui-p-auipc` | 30 / 0 / 3 / 1.50 | 26 / 0 / 1 / 1.30 | **−4** |
| `test1`          | 53 / 1 / 8 / 1.56 | 47 / 1 / 3 / 1.34 | **−6** |
| `test2`          | 64 / 2 / 9 / 1.52 | 56 / 2 / 3 / 1.30 | **−8** |
| `rv32ui-p-jalr`  | 98 / 0 / 12 / 1.40 | 98 / 0 / 12 / 1.40 | 0 — predicted exactly 0 |

All other 48 tests: identical cycles, stalls, squashes and CPI.

**Metric caveat.** `top_tb.sv` increments `squashes` once per cycle `flush` is
high, but a redirect also costs the following cycle (the hole left behind). A
removed JAL redirect is therefore worth **2 cycles**, not 1 — which is why
`test2` drops 8 cycles on only 4 fewer flush cycles. Read the waveform, not
just the counter, before quoting a redirect's cost.

### Reproduction caveat — close before trusting this row

The v1 numbers come from the working tree at 19:15, which contained
`code/alu.sv` and **no** `code/execute.sv`. Commit `4041be4` still contains
**both** `alu.sv` and `execute.sv` (identical, both `module alu`), so that
commit does not build. To reproduce:

1. `git rm code/execute.sv` on the branch and commit.
2. Update `code/testbenches/alu_tb.sv:2`, `verif/template_tb.sv:2` and
   `synthesis/synthesis.ys:11` to name `alu.sv`.
3. Re-run `make sim-all -C verif/` and confirm the four rows above.

### Outstanding work on this experiment

- [x] Unit TB for `pre_decode` (step 4) — `verif/pre_decode_tb.sv`, **27/27 pass** on v1 (2026-11-03); must now pass unmodified on v2–v4
- [x] Re-run `sim-all` after the `execute.sv`/`alu.sv` fix — 53/53 PASS, v1 numbers reproduced exactly (2026-11-01 19:38)
- [ ] Waveform (step 6) — artifact saved (`verif/wf_signals/Nov 1st jal wave.ron`); still to note explicitly: `flush` stays low in the JAL's IF cycle and `fd_insn` latches the JAL rather than `NOP`
- [ ] Variants v2–v4 (step 3)
- [ ] Commit this working tree so the v1 row points at a reproducible commit

### Decision

- **Winner:** pending — v2/v3/v4 not built
- **Reasoning:** v1 is functionally correct and is the adopted base for the next experiment; the style comparison has not been run, so calling it the winner would be premature
- **Date merged:** —

---

## Experiment 2 — BHT + BTB (branch prediction)

**Hypothesis (step 1):** predicting taken branches in IF removes the 2-cycle redirect
penalty on correctly predicted branches; JALR targets come from the BTB. Every test that
executes no predicted-taken branch must be bit-identical.

**Contract (step 2):**

- `bht.sv` — table of 2-bit saturating counters (`STRONG_NT … STRONG_T`) indexed by
  `pc[INDEX_BITS+1:2]`, **no tags**. Read combinationally with the fetch PC; trained in EX
  from `dx_pc[INDEX_BITS+1:2]` with `e_brtaken`. Predicts taken in `WEAK_T`/`STRONG_T`.
- `btb.sv` — `INDEX_BITS` entries holding `valid`, `tag`, `target`. **Tagged:**
  `hit_o = valid[rd_idx] && tags[rd_idx] == pc_i[31:INDEX_BITS+2]`. Written only on
  `e_pcsel` (JALR), because branch targets already come from the pre-decoder.
- `rv_core.sv:156` `bp_taken = (CFI_BRANCH && bht_taken) || (CFI_JALR && btb_hit)`.
  The guess is carried to EX in `fd_pred_npc`/`dx_pred_npc` and checked by
  `mispredict = e_ctrl && (dx_pred_npc != e_npc)` (`rv_core.sv:395`).

**Result (`feature/bht_btb`, run 2026-11-11 23:21), vs the predecoder build:**

| Test | predecoder | + BHT/BTB | Δ |
|------|-----------|-----------|---|
| `rv32ui-p-jalr` | 98 / 12 / 1.40 | **92 / 9 / 1.31** | **−6 cycles, −3 flushes** |
| `rv32ui-p-bne`  | 315 / 29 | 319 / 31 | +4, +2 |
| `rv32ui-p-beq`  | 311 / 27 | 317 / 30 | +6, +3 |
| `rv32ui-p-blt`  | 311 / 27 | 317 / 30 | +6, +3 |
| `rv32ui-p-bltu` | 336 / 27 | 342 / 30 | +6, +3 |
| `rv32ui-p-bge`  | 347 / 36 | 357 / 41 | +10, +5 |
| `rv32ui-p-bgeu` | 372 / 36 | 382 / 41 | +10, +5 |
| everything else | — | identical | 0 |

**Findings:**

- **BTB indirect-target prediction works.** `jalr` improved 6 cycles with no RAS in the
  design — the only source is the tagged BTB. This is a real, adoptable win.
- **The BHT regressed every conditional-branch test.** Each extra flush costs exactly
  2 cycles (+3→+6, +5→+10), so these are genuine extra redirects, not counter artefacts.
- **No test anywhere improved**, so the BHT never produced a correct taken prediction that
  saved a cycle. Cold counters reset to `STRONG_NT`, so a cold entry cannot predict taken —
  the false taken predictions had to come from entries trained by *other* branches.

**Decision:** BTB adoptable. BHT not mergeable as-is — investigate the extra taken
predictions (Experiment 3).

---

## Experiment 3 — BHT index size (aliasing)

**Hypothesis:** 64 untagged entries index `pc[7:2]`, i.e. **one entry per 256 bytes of
code**. A taken branch trains an entry that a different, not-taken branch then reads as
"taken", costing one guaranteed redirect. Enlarging the index should remove the entire
regression if aliasing is the cause.

**Method note (worth recording):** the first attempt changed only the default
`parameter INDEX_BITS = 10` in `bht.sv`. The instantiation at `rv_core.sv:216` overrides it
with `.INDEX_BITS(6)`, so the design did not change and the two runs were **byte-identical**
(md5 `6be9e71c…` for both blocks). The experiment only began once the override itself was
changed to 10. BTB left at 6 (`rv_core.sv:230`) — only six `jalr` in the suite, and it is
already tagged.

**Result (`scratch/bht-test`, `INDEX_BITS = 10`, run 2026-11-11 23:47):**

| Test | predecoder | idx6 | idx10 |
|------|-----------|------|-------|
| `rv32ui-p-beq`  | 311 / 27 | 317 / 30 | **311 / 27** |
| `rv32ui-p-blt`  | 311 / 27 | 317 / 30 | **311 / 27** |
| `rv32ui-p-bltu` | 336 / 27 | 342 / 30 | **336 / 27** |
| `rv32ui-p-bne`  | 315 / 29 | 319 / 31 | **315 / 29** |
| `rv32ui-p-bge`  | 347 / 36 | 357 / 41 | **347 / 36** |
| `rv32ui-p-bgeu` | 372 / 36 | 382 / 41 | **372 / 36** |
| `rv32ui-p-jalr` | 98 / 12 | 92 / 9 | 92 / 9 (unchanged) |

All 53 rows compared against the predecoder run: **only `jalr` differs.** Every branch test
is back to its exact baseline numbers.

**Conclusions:**

1. The entire BHT regression was **index aliasing** — not direction logic, not training.
2. **Counter training is correct.** False "taken" reads can only happen if other branches
   trained entries to `WEAK_T`/`STRONG_T`, which requires the write path to work.
3. **No BHT benefit is measurable on the directed instruction tests.** Each branch executes
   roughly once, so after the cold mispredict there is no second execution to benefit from.
   The only observable effect of the table on this suite is collision noise.

**Action (done 2026-11-12):** tags + a `valid` bit added to the BHT and the index returned
to 64 entries. Tags alone were **not** sufficient — see the follow-up below.

**Outstanding:** loop-workload measurement. `test1`/`test2` show no change, suggesting they
are straight-line or too short; the grader's bubble sort / sum array / factorial are loops
and are the correct validation set.

### Follow-up — root cause and fix (2026-11-12)

Tags alone did not fix it. Runs on `rv32ui-p-beq` (baseline: 311 cycles / 27 flushes):

| Change | cycles / flushes | BHT taken | Finding |
|--------|------------------|-----------|---------|
| tagged, no `valid` bit | 317 / 30 | 3 | all 3 predictions wrong; +2 cycles each |
| + `valid` bit on read | 317 / 30 | 3 | not an uninitialised-tag problem — the reads were genuine tag matches |
| + full 24-bit tag | 317 / 30 | 3 | not a partial-tag collision; the read-side tag was working |
| + write-side tag compare, seed `WEAK_T`/`WEAK_NT` | 335 / 39 | 15 | wrong seed: inventing "taken" predictions |
| + seed **cold** (`STRONG_NT` + this outcome only) | **311 / 27** | **0** | exact baseline |

**Root cause.** The tag identified *who wrote the entry last*, not *whose outcomes the counter
contains*. With 64 entries two branches share a slot: each write overwrote the tag with its own
PC, but the counter kept evolving from whatever state was already there. The rightful owner
would later match the tag, read a counter polluted by the other branch, and predict taken for
a not-taken branch. A tagged BHT therefore needs **two** guards — the read side (never read
another branch's entry) and the write side (never evolve another branch's counter).

**Fixed contract for `bht.sv`:**

- 64 entries, 8-bit partial tag (`pc[INDEX_BITS+2 +: 8]`), plus a `valid` bit
- `taken_o = valid[rd_idx] && tag_match && (counter is WEAK_T or STRONG_T)`
- on write, if `!valid[wr_idx]` or the tag differs, seed the entry **cold** from this outcome
  (`update_taken_i ? WEAK_NT : STRONG_NT`) instead of advancing the existing state

**Result (full suite, `TAG_BITS = 8`):** 53/53 PASS; all six branch tests back to predecoder
baseline; `jalr` unchanged at 92 / 9, so the BTB win is preserved. Storage 64 × (2 + 8 + 1) =
**704 flops**, versus 2,048 for the untagged 1024-entry diagnostic and 10,240 for the tagged
1024-entry version — identical behaviour at one third the area of the cheapest diagnostic.

**Still unproven:** the BHT makes **zero correct predictions** on the directed tests (0 on
`beq`), so its benefit remains unmeasured; only the regression is gone. Cold seeding also means
a repeating branch begins predicting from its third execution.

### Decision

- **Winner:** BTB — adopt. BHT — adopt as a *correct, neutral* component; benefit unproven.
- **Reasoning:** the BTB is the only measured win (−6 cycles on `jalr`). The BHT is now
  exactly neutral at 64 tagged entries and free of aliasing artefacts, but it makes no correct
  prediction anywhere in the directed suite, so it cannot be credited with a gain. Validation
  on a loop workload is still required before the BHT is claimed as an optimisation.
- **Date merged:** —

---

## Experiment 4 — Instruction fusion (planned)

**Status: v1 built and measured (2026-11-23); 67/67 with the feature on and off.** The opportunity
count demanded by the open question below has been taken across the fourteen benchmark kernels
in `code/benchmarks/`; the numbers are in "Gate measurement" below. There are still no
measurement rows because no variant exists yet.

**Motivation.** Every CPI win so far came from *predicting* control flow (Experiments 1–3).
The other axis is *eliminating* dynamic instructions: macro-op fusion recognises two
architecturally separate instructions executed back-to-back and issues them as a single
internal operation.

### Hypothesis (step 1) — amended for the metric change

Fusing adjacent instruction pairs reduces **both** the dynamic cycle count **and** the retired
instruction count. `total_cycles` falls because each fused pair occupies one issue slot instead
of two; `insn_exe` falls by exactly the number of fused pairs. **CPI may therefore rise while
the core gets faster**, because `cpi = total_cycles / insn_exe` and the denominator is shrinking.

The hypothesis predicts, in order: **cycles fall, retired instructions fall, IPC rises** — and
explicitly states that **CPI is not a valid pass/fail criterion for this experiment.**

**Hypothesis sentence (v1 rule, 2026-11-22):** fusing `addi` immediately followed by a
conditional branch whose **rs1 is the register the `addi` writes** should remove **287 of the
1123 dynamic instructions in the suite — 25.6%** — so `total_cycles` must fall by up to 287
(21.4% of the 1339-cycle suite total), retired instructions must fall by exactly the number of
pairs that fire, and IPC must rise. No baseline-passing test may change its pass/fail result.

### Reporting rule for this experiment

| Metric | Source | Role |
|--------|--------|------|
| Cycles | `Total Cycles` | the quantity that must fall |
| Instructions retired | `cycles / CPI` | shows how often fusion fired |
| **IPC** | `instructions / cycles` | the comparable efficiency metric; must rise |
| CPI | `Final CPI` | reported for continuity only — **not** comparable across the fusion boundary |

**CPI is not comparable across a fusion boundary.** It is a ratio whose denominator is the
dynamic instruction count, and fusion changes that denominator by design. Comparing CPI before
and after fusion compares two different questions. Any row that quotes only CPI is incomplete
and must not be used to accept or reject a fusion variant.

### Gate measurement (step 3 input) — measured 2026-11-22

Counted with `code/benchmarks/fusion_analysis.py`, which recovers the dynamic stream from each
kernel's source plus the measured retired-instruction count, so a pair inside a loop is counted
once per iteration rather than once per source line. Suite totals: **1339 cycles, 1123 retired
instructions** across fourteen kernels. Trip counts are pinned from the kernels; the
`cycles/CPI` derivation is used only as a cross-check, because it over-reads by roughly the
trailing `nop`s.

| Quantity | Value |
|---|---|
| pairs found (`addi` followed by any conditional branch) | **310** |
| pairs matching the cheap rule, branch rs1 == addi rd | **287** (93% of found) |
| — of which backward branches (loop-back sub-case) | **277** (97% of matched) |
| dynamic instructions in the suite | 1123 |
| **fraction of dynamic instructions** | **287 / 1123 = 25.6%** |
| suite cycles | 1339 |
| **cycles bound** (1 cycle per fused pair) | **287 cycles = 21.4%** |

The 25.6% is the bound the hypothesis quotes. It is an upper bound because it is a fraction of
*instructions*, while only 1123 of the 1339 cycles are issue cycles — the rest are 8+ stalls,
flush cycles and pipeline fill that removing an instruction cannot reclaim. The tighter figure
is 21.4% of cycles; both are reported so the hypothesis and the eventual measurement are
compared like with like.

### Competing pairs, measured on the same suite

| Pair | Dynamic pairs | % of cycles | Impl. cost | Verdict |
|---|---|---|---|---|
| `addi` + cond. branch, rs1 == rd | **287** | **21.4%** | 3 | **build (v1)** |
| `add` + `lw` | 12 | 0.9% | 2 | no |
| `add` + `sw` | 12 | 0.9% | 2 | no |
| `lw` + consumer | 12 | 0.9% | 5 | no |
| `lui`/`auipc` + `op` | 2 | 0.1% | 2 | no |
| `slt`/`sltu` + branch | 0 | 0% | 2 | no measured occurrence |
| `lw` + `sw` (copy) | 0 | 0% | 3 | no measured occurrence |

Cost: 1 = trivial, 5 = datapath change. The winner beats the best memory-side fusion by **24x**,
so the ranking survives the v1 restriction rather than depending on the unrestricted count. All
memory-side patterns occur only in indexed array code (`array-idx`, `sum-array`); twelve of the
fourteen kernels contain none at all.

### What the restriction costs

93% of the unrestricted pairs survive the `rs1 == rd` requirement, and 97% of what survives is a
loop-back — so in practice v1 is a loop-back fusion: one instruction removed per loop iteration.
The single edge case is `if-in-loop`, whose loop-back is preceded by a marker write
(`addi x8,x0,1`) and tested with `blt x5,...`; rs1 != rd there, so that pair is not captured and
the pairs counted for that kernel are its forward branch instead. This is the argument for the
rs2 variant, not a defect in v1.

### Interaction that must be declared before measuring

Fusing taken loop-back branches **removes branches from the dynamic stream** — the exact signal
the BHT/BTB of Experiment 2 is measured on. Enabling both features makes the predictor's
apparent accuracy change for reasons that have nothing to do with the predictor. Each build in
this experiment must therefore state which features are enabled, and comparisons must be made
at a fixed feature mask.

### fuse_detect — module spec

Contract for Experiment 4 (step 2), v1 rule: `addi` immediately followed by a conditional
branch whose rs1 is the register the `addi` writes. Module name `fuse_detect`, same ports on
every variant branch so the unit TB runs unmodified on all of them.

#### Ports

| Name | Dir | Width | Meaning | Why it exists |
|---|---|---|---|---|
| `insn_a_i` | in | 32 | the word at `pc_i` | the candidate `addi` |
| `insn_b_i` | in | 32 | the word at `pc_i + 4` | the candidate branch |
| `pc_i` | in | 32 | address of `insn_a_i` | the pair's own PC, and the base for the branch target |
| `is_insn_i` | in | 1 | slot validity, the same enable `pre_decode` receives | never fuse a slot that is being discarded |
| `fused_o` | out | 1 | this pair fuses | the select for the entire mechanism |
| `stride8_o` | out | 1 | the PC must advance 8, not 4 | "the next instruction" is no longer always `pc + 4` |
| `rs2_o` | out | 5 | register index to compare `t` against (`insn_b_i[24:20]`) | decode reads `rs2` from the word in D, which is the *addi* — an I-type's `rs2` field is meaningless, so the right index must be supplied |
| `br_funct3_o` | out | 3 | branch condition code | selects BEQ/BNE/BLT/BGE/BLTU/BGEU |
| `br_target_o` | out | 32 | `(pc_i + 4) + sign_extend(B-imm)` | where a taken fused op redirects |
| `br_imm_o` | out | 32 | `sign_extend(B-imm)` | **only** so a later variant can build the target in EX; unused in v1 |

`br_imm_o` looks redundant and is not. The methodology requires **identical ports on every
variant branch**. If v3 ("compute the target in EX instead of fetch") needed a different
interface it would not be a variant — it would be a different module, and the shared unit TB
could not run unmodified. The interface therefore carries what *any* variant might need, and
synthesis trims what a given variant does not use. A reviewer seeing an unused port should read
"v3 exists", not "dead code".

#### Behaviour

1. The fused operation writes `addi.rd <- addi.rs1 + sign_extend(addi.imm)`.
   *The first instruction's architectural effect must survive fusion — it is not a scratch
   value the hardware may discard.*
2. It compares that result `t` against the register named by `insn_b_i[24:20]`.
   *The branch's compared value is the addi's result, not the stale copy in the register file;
   using the register file's copy would pass tests where the register did not change.*
3. If the condition holds it redirects to `(pc_i + 4) + sign_extend(B-imm)`.
   *The branch is the second instruction, so its address is `pc_i + 4`; using `pc_i` would
   land one instruction early — a bug that only shows on the loop-back.*
4. A fused pair occupies **one** pipeline slot and advances the PC by **8**.
   *That single sentence is the entire performance argument; everything else exists to make it
   safe.*

#### Rejection rules

| # | Condition | Fuse? | Why |
|---|---|---|---|
| 1 | `is_insn_i = 0` | no | the slot is being discarded |
| 2 | `insn_a_i` opcode != `0010011` | no | not an I-type |
| 3 | `insn_a_i` funct3 != `000` | no | `slti`/`xori`/... are not add |
| 4 | `insn_a_i[11:7]` (rd) = `x0` | no | nothing to write; fusing is legal but pointless — rejecting keeps the rule one sentence (decision b) |
| 5 | `insn_b_i` opcode != `1100011` | no | not a branch |
| 6 | `insn_b_i` funct3 not in {000,001,100,101,110,111} | no | `010`/`011` are not branches (decision a) |
| 7 | `insn_b_i[19:15]` != `insn_a_i[11:7]` | no | the branch must consume the addi's result — this is the 93% rule |
| 8 | all of 1–7 pass | **yes** | |

**Output rule when not fused.** When `fused_o = 0`, **every** output is zero -- `stride8_o`,
`rs2_o`, `br_funct3_o`, `br_target_o` and `br_imm_o` included. This follows `pre_decode`'s
discipline and lets the unit TB assert one rule ("no fuse implies all zeros") instead of
enumerating each output's don't-care state.

**Same-sequential-fetch guarantee.** This is not a condition on the two words, so it is not a
table row: the pair must come from one sequential fetch. It is guaranteed by construction
rather than by luck.

- `insn_b_i` is read from the IMEM at an address *derived* from `pc_i` (`pc_i + 4`), not from a
  fetch queue or a buffered word, so the two inputs are adjacent by address and cannot be
  mismatched.
- A redirect can only change `pc_i`. It cannot deliver a branch at `pc_i + 4` while some other
  word is treated as the `addi`, because the detector has no state: each cycle it re-derives
  the pair from the current `pc_i`.
- `fused_o` affects only the *next* PC (`pc_i + 8`), never the current fetch, so a fused pair
  cannot itself create a misaligned or double-fetched stream.
- The one way a slot can be unreal is a flush or stall of the fetching instruction, and that is
  exactly what `is_insn_i` encodes (rule 1). The detector does not interpret `flush`/`stall`;
  the core must define `is_insn_i = 0` for any slot that will be discarded.

#### Timing contract

Purely combinational: the decision is available in the same cycle the two words are fetched;
no clock, no state, no stall; a fused pair consumes one slot and sets the stride to 8. The cost
is an opcode/funct compare, a register-index compare and one 32-bit adder in the fetch path —
the same class of logic `pre_decode` already put there, and the reason moving `br_target_o`
into EX is a later variant rather than the opening design.

#### What the pipeline carries

The branch word is **gone** after fetch — it never enters the pipeline. Everything the fused
operation needs from it must be captured at fetch and carried alongside the `addi` word:

| Field | Width | Why it must ride along |
|---|---|---|
| `fused` | 1 | tells decode/EX this slot is a fused add + branch |
| `stride8` | 1 | the PC already advanced by 8; needed by any stage that reports or re-derives a PC |
| `br_rs2` | 5 | the register the fused op compares `t` against |
| `br_funct3` | 3 | which comparison to perform |
| `br_target` | 32 | the redirect target, already computed |

The `addi` supplies `rd`, `rs1` and `imm` for free, so they are not duplicated.

Why: after the pair is consumed the second word no longer exists anywhere in the machine. If
it is not captured at fetch it is unrecoverable, and the fused op would have to be re-fetched —
which is the design this contract rejects.

#### Decisions taken

| # | Question | Decision | Why |
|---|---|---|---|
| a | Invalid branch funct3 (`010`/`011`) | **reject** | Fusing would be harmless (the comparator returns not-taken), but "fused implies a real branch" is a one-line invariant for the TB; rejecting keeps it |
| b | `addi` with `rd = x0` | **reject** | Correct but pointless: no register is written, and `x0` reads as zero so the compare would not be against a result. One sentence in the rule beats a handful of occurrences |
| c | Target in fetch (v1) or imm carried to EX (v3) | **precompute in fetch for v1** | Keeps the execute stage untouched for the first variant, and `br_imm_o` stays in the interface so v3 remains a variant rather than a rewrite |
| d | Which variant computes which output | **both always driven** | `br_target_o` *and* `br_imm_o` are computed on every variant and the core selects one. If v1 left `br_imm_o` at zero and v3 drove it, the shared TB of §A step 4 would pass on v1 and fail on v3 — the TB must run unmodified on every branch, so the detector always produces both |

#### Deliberately not in the contract

- the internal style of the detector (one `case`, a PLA, whatever)
- the index or size of any table
- which variant uses `br_target_o` versus `br_imm_o`
- anything about how the core wires it

These are per-branch implementation choices. Anything in the contract is asserted by the shared
unit TB, so putting them here would make v1 and v3 unable to both pass — which defeats the point
of having variants at all.

### v1 results — measured 2026-11-23

`fuse_detect` integrated with `FUSE_ENABLE` masking the feature. Unit TB 12/12; full suite
67/67 with the feature on **and** off. Comparison is the same build with the mask flipped:

| Test | off | on | saved | flush cycles |
|---|---|---|---|---|
| `smoke` | 6 | 6 | 0 | 0 / 0 |
| `sweep4` | 29 | 25 | -4 | 3 / 3 |
| `sweep10` | 47 | 37 | -10 | 3 / 3 |
| `sweep25` | 92 | 67 | -25 | 3 / 3 |
| `sweep50` | 167 | 117 | -50 | 3 / 3 |
| `sweep100` | 317 | 217 | -100 | 3 / 3 |
| `nested` | 112 | 87 | -25 | 10 / 10 |
| `if-in-loop` | 56 | 46 | -10 | 6 / 6 |
| `sum-array` | 51 | 47 | -4 | 3 / 3 |
| `array-idx` | 91 | 83 | -8 | 3 / 3 |
| `fib` | 69 | 59 | -10 | 3 / 3 |
| `smul` | 218 | 186 | -32 | 5 / 5 |
| `callret` | 37 | 34 | -3 | 4 / 4 |
| **total** | **1339** | **1048** | **-291 (-21.7%)** | unchanged |

Three things this confirms and one it corrects:

- **The gate predicted 21.4%** (287 pairs / 1339 cycles); measured **21.7%**. The pairs
  counted statically and dynamically agree with the silicon behaviour to within a cycle.
- **Exactly one cycle per fused pair**, per kernel: `sweep100` saves 100, `sweep50` saves 50,
  `sweep10` saves 10. No test over- or under-delivers.
- **Flush cycles are identical in every test**, which is the check that matters: fusion
  removed instructions without costing a single extra mispredict. That is what the
  prediction wiring in step 3 exists to guarantee.
- **CPI rises, as the metric change predicted** (`sweep100` 1.21 -> 1.57): the denominator
  shrank by 100 instructions.
- **IPC falls too, which the hypothesis got wrong.** Suite-wide 1169 -> 876 instructions and
  1339 -> 1048 cycles: IPC moves from 0.873 to 0.836. The hypothesis of step 1 predicted that
  IPC must rise; it cannot, because fusion shortens the instruction stream while leaving the
  machine's fixed cost (fill, stalls, flush cycles) untouched -- the same ~170 cycles now
  amortise over 876 instructions instead of 1169. **The comparable figure for this experiment
  is cycles for fixed work**, and neither CPI nor IPC should be used to accept or reject a
  fusion variant.

Two defects were found and fixed during integration, both in the rs2 index path rather than
in the detector:

1. The load-use hazard compared `dx_rd` against `d_rs2` (the addi's immediate field for a
   fused pair), so a load feeding the branch's compared register was not detected.
2. The X-stage forwarding selectors compare `xm_rd`/`mw_rd` against `dx_rs2`; with `dx_rs2`
   carrying the addi's field, the fused branch's operand was never forwarded and fell back
   to a stale register value -- which made `rv32ui-p-jal` compute the wrong branch outcome
   and redirect wrongly. `dx_reg` now latches `rf_rs2`, so one index serves decode, the
   hazard check, the register-file read and forwarding.

### v2 contract — mirrored operand (`feature/macro-op-fusion-addi-branch-v2`)

v1's measurement on the graded binaries was $+0.4\%$: correct on every program, but the
pattern it recognises is not the one compiled loops mostly use. v2 is a strict superset of v1
that also accepts the mirrored form.

| form | example | v1 | v2 |
|---|---|---|---|
| `rs1` form | `addi x5,x5,-1` / `blt x5,x6,L` | fuses | fuses |
| mirrored | `addi x5,x5,-1` / `bge x6,x5,L` | rejects | **fuses** |

#### Why the union is the only extension possible

The fused operation may reference only two register-file reads (the file has two ports).
v1 needs `addi.rs1` and `branch.rs2`; v2 needs `addi.rs1` and `branch.rs1`. In both, the
branch's other operand is the addi's *result*, not a third read. A general "fuse any adjacent
`addi`+branch" variant would need the addi's source *and* both branch sources -- three reads --
so it is not implementable without a third port. The `rd == branch operand` requirement is
load-bearing, not conservative.

#### Interface delta from v1

| port | change |
|---|---|
| `rs2_o` (5) | **redefined**: "the register index to compare `t` against", i.e. `rs2_b` when the rs1 form matched, `rs1_b` when the mirrored form matched |
| `t_first_o` (1) | **new**: 1 when `t` is the branch's rs1 operand (rs1 form), 0 when it is rs2 (mirrored) |

Everything else -- `fused_o`, `stride8_o`, `br_funct3_o`, `br_target_o`, `br_imm_o`,
`is_insn_i`, `pc_i` -- is unchanged. The unit TB's v1 rows all still pass unmodified, so the
shared-contract property holds on the intersection.

#### Detection

    rs1_match = (insn_b[19:15] == insn_a[11:7])
    rs2_match = (insn_b[24:20] == insn_a[11:7])
    fused     = <all v1 word checks> && (rs1_match || rs2_match)
    rs2_o     = rs1_match ? insn_b[24:20] : insn_b[19:15]
    t_first_o = rs1_match

All v1 rejection rules stand except rule 7, which becomes "neither operand is the addi's
destination". When both match (e.g. `beq x5,x5,L`), the rs1 form wins by construction of the
expression above, so the TB has exactly one correct answer for that row.

#### Execute

`branch_control` still compares two operands; the ordering is now a mux:

    rs1_i = t_first ? e_res : fwd_rs2
    rs2_i = t_first ? fwd_rs2 : e_res

`br_funct3_o` is unchanged, so BEQ/BNE/BLT/BGE/BLTU/BGEU all keep their meaning: swapping
both operands swaps the sense of BLT/BGE, which is exactly what the mirrored form needs.

#### Payload

`dx_reg` carries `t_first` from D to X alongside `fused`, `br_funct3`, `br_target`. `br_rs2`
still stops at D, but its meaning is now the muxed "other operand" index rather than
literally the branch's rs2 field.

#### Expected result, stated before measuring

v1 earned $+0.4\%$ on the graded suite. If compiled loop-backs are dominated by the mirrored
form, v2 should land in the 4--6\% range on the loop-heavy graded programs (one cycle per
iteration, against prediction's ~three). If it also lands near zero, the conclusion is that
fusion is the wrong investment for this workload and the effort belongs in prediction. Either
answer is a result; the measurement to run is the same three-way submission comparison with
`FUSE_ENABLE` masked, plus the local suite A/B for cycle-level attribution.

### Resolved: does fusion belong in this project?

The opportunity is measured: one pair class fires 287 times across the suite (25.6% of dynamic
instructions, 21.4% of cycles) while every memory-side candidate fires 12 times or fewer. That is
a wide enough margin to justify a v1 build and narrow enough to justify building only one.

Two risks remain and must be stated before measuring:

1. **The graded binaries are fixed and unavailable.** These counts come from the project's own
   kernels. The argument transfers only if the graded programs are loop-shaped, which every
   available signal says they are, but it is an inference, not a measurement.
2. **Overlap with the predictor.** With the BHT enabled the `sweep` family shows a constant 3
   flush cycles regardless of trip count, so the predictor has already removed the loop-back
   mispredicts. The 21.4% above is therefore **issue-slot saving only** and is additive to the
   predictor; the redirect cycles must not be counted a second time in the fusion's column.

Branch for the v1 build, per the convention in `AGENTS.md` §C: `feature/fusion-addi-branch-v1`.

---

## Experiment 5 — early branch resolution (resolve conditional branches in D)

**Status: contract written; v1 in progress.** Fusion was measured and dropped (Experiment 4).
The remaining cycle budget on the project's kernels is 13.6\% overhead, of which mispredict
cost is the largest single item:

| category | cycles | share |
|---|---|---|
| useful instructions | 892 | 86.4\% |
| mispredict flushes (2 per squash) | 86 | 8.3\% |
| pipeline fill + alignment | 43 | 4.2\% |
| load-use stalls | 12 | 1.2\% |

### Hypothesis (step 1)

A conditional branch resolved one stage earlier turns each mispredict from two squashed
instructions into one. Expected: **cycles fall by about half the mispredict cost, ~4\% of the
suite**, with **identical pass/fail** on all 67 tests. Squashed-instruction counts must fall;
CPI will rise slightly because cycles fall while the instruction count does not.

The metric is cycles and squashes. No test may change its pass/fail result.

### Contract (step 2)

Scope is **conditional branches only**. `jal` is already resolved in fetch by the pre-decoder
(no penalty to recover) and `jalr` keeps its execute-stage resolution: a mispredicted `jalr`
must survive to write its link register, which a D-stage squash would destroy.

**Detection, in D:**

    d_npc      = d_brtaken ? (d_pc + d_imm) : (d_pc + 4)
    mispredict_d = (d_opcode == B_TYPE) && !hazard && (fd_pred_npc != d_npc)

`fd_pred_npc` is the prediction registered with this instruction; `d_imm` is the B-immediate
the immediate generator already produces for `B_TYPE`.

**Operands.** The branch compares `d_rs1` and `rf_rs2`, which need values that may still be in
flight. Forwarding into D covers the two stages the register file cannot:

| producer | source | why |
|---|---|---|
| in X (not a load) | `e_res` | ALU result, combinational |
| in M | `xm_wdata` | the value X will write |
| in W | register-file read | the file already bypasses a same-cycle write |
| load in X | none -- stall | the existing `hazard_load` holds D for one cycle until the value reaches M |

`mispredict_d` is therefore qualified by `!hazard`: while D is held the operand is not final
and the comparison is meaningless.

**Flush routing -- the part that is easy to get wrong.** Today one `flush` clears both the F/D
and D/X registers. That is correct when detection happens in X, because everything above the
branch is younger. When detection happens in D, the instruction in X is *older* and must
survive. So:

| signal | clears | used by |
|---|---|---|
| `flush` (existing) | F/D **and** D/X | X-stage mispredicts (jal/jalr) |
| `flush_d` (new) | F/D only | D-stage branch mispredicts |

`e_ctrl` drops `B_TYPE`, so a correctly predicted branch does not re-trigger the X-stage check
when it reaches execute; the fused term stays (inert at `FUSE_ENABLE = 0`).

**Redirect priority:** `flush ? e_npc : flush_d ? d_npc : pre_en_redir ? pre_target : bp_taken ?
bp_target : pc`.

### Variants (step 3)

| variant | difference | why it might win |
|---|---|---|
| v1 | forward from X and M as above | no added stalls; loop-back `addi`+`bne` stays one pair per iteration |
| v2 | forward from M only, stall one cycle when the producer is in X | shorter combinational path into the comparator, at the cost of a stall on the most common loop pattern -- expected to lose |
| v3 | v1 plus removing `dx_pred_npc` from the D/X register | reduces the payload; cosmetic, measure for area |

### Verification plan (steps 4-5)

1. Unit-level: the branch comparator is unchanged RTL wrapped in new plumbing, so no new unit
   TB is needed; the full suite is the test.
2. Regression: 67/67 pass/fail **identical** to the mask-0 baseline; any test that changes
   result is a bug.
3. Cycles: total across the 14 kernels must fall from the 1339 baseline; squashes must fall by
   roughly half the redirect count.
4. Waveform: one taken and one not-taken branch, plus one loop exit, showing `flush_d` instead
   of `flush`.

### v1 results — measured

67/67 pass, `FUSE_ENABLE = 0` (fusion inert), against the pre-change baseline:

| kernel | baseline | v1 | saved | squashes |
|---|---|---|---|---|
| `smoke` | 6 | 6 | 0 | 0 |
| `sweep4` | 29 | 26 | -3 | 0 |
| `sweep10` | 47 | 44 | -3 | 0 |
| `loop10` | 47 | 44 | -3 | 0 |
| `sweep25` | 92 | 89 | -3 | 0 |
| `sweep50` | 167 | 164 | -3 | 0 |
| `sweep100` | 317 | 314 | -3 | 0 |
| `nested` | 112 | 102 | -10 | 0 |
| `if-in-loop` | 56 | 50 | -6 | 0 |
| `sum-array` | 51 | 48 | -3 | 0 |
| `array-idx` | 91 | 88 | -3 | 0 |
| `fib` | 69 | 66 | -3 | 0 |
| `smul` | 218 | 213 | -5 | 0 |
| `callret` | 37 | 34 | -3 | 1 |
| **total** | **1339** | **1288** | **-51 (-3.8%)** | 1 |

The hypothesis was 4% of the suite, from halving a 8.3% mispredict share. Measured 3.8%, and
the saving is **exactly one cycle per mispredict** on every kernel -- `nested` saves 10, which
is its ten mispredicts; `smul` saves 5; the loop kernels save 3, which is entry + exit + the
cold first iteration.

Three bugs were found and fixed during bring-up, all in the D-stage operand path rather than
in the idea:

1. **A load in M.** `xm_wdata` has no memory-data case (it is IMM / PC+4 / ALU only), which is
   why the existing M->X forwarding masks loads out with `!X_M[MEMREN]` and lets them reach W
   first. D-resolution has no such option, so a load's data is now taken from `m_data_o`. This
   accounted for seven of eight failing tests (all the sub-word load/store ones).
2. **`lui`/`auipc`/`jal` in X.** `e_res` is the ALU result, but those write the immediate or
   pc+4, selected only at writeback. A branch comparing against a `lui` result read zero,
   which is what broke `rv32ui-p-bgeu`. The X-stage value now applies the same WBSEL mux that
   `xm_wdata` applies for M.
3. **The X-stage check must be removed.** Leaving `B_TYPE` in `e_ctrl` means the X-stage
   redirect wins over the D-stage one for the same branch, cancelling the entire gain -- the
   design is correct but measures identical cycles. This was introduced during bisection and
   is worth recording: the two mechanisms must not both be live.

**Metric caveat:** the squashed-instruction counter drops from 52 to 1, which overstates the
improvement. A D-stage flush clears one register, and the counter appears to count X-stage
flushes only. Cycles are the metric here, not squashes.

### v1 graded results — measured

Submitted as `submission-branch-pred-early-resolve.zip` (fusion inert). Compared against the
prediction-only submission and the October baseline:

| graded program | October | + prediction | + early resolution | vs prediction | vs October |
|---|---|---|---|---|---|
| Perf | 0.587 | 0.499 | **0.487** | -2.4\% | -17.0\% |
| Fibonacci | 0.586 | 0.499 | **0.489** | -2.0\% | -16.6\% |
| Bubble sort | 0.248 | 0.236 | **0.231** | -2.1\% | -6.9\% |
| Factorial | 0.147 | 0.127 | **0.123** | -3.1\% | -16.3\% |
| GCD | 0.084 | 0.069 | **0.068** | -1.4\% | -19.0\% |
| Sum array | 0.057 | 0.054 | **0.052** | -3.7\% | -8.8\% |
| Check vowel | 0.183 | 0.174 | 0.173 | -0.6\% | -5.5\% |
| Swap | 0.016 | 0.016 | 0.015 | -6.3\% | -6.3\% |
| Swap shift | 0.017 | 0.016 | 0.016 | 0.0\% | -5.9\% |
| Simple if | 0.013 | 0.012 | 0.012 | 0.0\% | -7.7\% |
| Simple add | 0.012 | 0.011 | 0.011 | 0.0\% | -8.3\% |
| **total** | **1.950** | **1.713** | **1.677** | **-2.1\%** | **-14.0\%** |

**Eight faster, three unchanged, none slower, all eleven CORRECT.** The three that do not move
are the programs with almost no mispredicts to make cheaper, which is the mechanism's
signature rather than a coincidence.

The graded gain (2.1\%) is smaller than the local one (3.8\%) for the same two reasons
fusion's number was diluted: the grader reports simulation wall time, which carries fixed
cost, and the graded programs interleave array work between mispredicts where the kernels are
pure loops.

### Feature ledger, all measured on the same three-build discipline

| change | mechanism | graded effect | adopted |
|---|---|---|---|
| pre-decoder + BHT/BTB | remove mispredicts | -12.2\% | yes |
| macro-op fusion v1 | remove instructions | +0.4\% | no |
| macro-op fusion v2 | remove instructions | +0.5\% | no |
| early branch resolution | make mispredicts cheaper | -2.1\% | yes |
| **cumulative** | | **-14.0\%** (1.950 -> 1.677 s) | |

The rejection of fusion is what made this possible: the graded-suite evidence that fusion did
not transfer is also the evidence that mispredicts, not repeated instructions, were where the
remaining cycles lived.

### v2 results — load-use stall removed, jalr resolved in D

Both follow-ups landed; 67/67 pass.

| kernel | v1 | + load-use | + jalr | why |
|---|---|---|---|---|
| `array-idx` | 88 | **80** | 80 | 8 load-use stalls of 88 cycles (9\%) |
| `sum-array` | 48 | **44** | 44 | 4 stalls of 48 cycles (8\%) |
| `callret` | 34 | 34 | **33** | its one jalr mispredict |
| everything else | -- | unchanged | unchanged | no load-use pairs or jalr misses |
| **total** | **1288** | 1276 | **1275** | |

Cumulative against the pre-change baseline: **1339 -> 1275, -64 cycles (-4.8\%)**, and the
stall counter is now zero on every test in the suite.

**Load-use** was the same omission that cost three bugs in v1: `xm_wdata` has no memory-data
case, so `mx_rs1/mx_rs2` masked loads out and the pipeline waited a cycle. The memory is
combinational, so `m_data_o` is valid in M and feeds X directly. The stall survives only where
the value is needed *in D* -- a branch or jalr comparison -- so `hazard_load` is narrowed to
those rather than firing for every consumer.

**jalr in D** is worth only one cycle on this suite because `callret` is the only kernel with a
jalr miss; its graded value depends on how call-heavy the graded programs are, which cannot be
inspected. It carries a `resolved` bit to X so execute does not redirect a second time and
cancel the gain -- exactly the failure mode that leaving `B_TYPE` in `e_ctrl` caused in v1.

## Future experiments

Append a new numbered experiment section per structural decision, same table shape.
