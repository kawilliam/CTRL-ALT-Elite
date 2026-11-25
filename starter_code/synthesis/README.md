# Synthesis scripts

Two scripts, deliberately separate, because they answer different questions.

| script | memory | numbers describe | artefacts |
|---|---|---|---|
| `synthesis.ys` | `code/main_memory.sv`, the real array | the full design | `synth.v`, `synth.json` |
| `synthesis_nomem.ys` | `synthesis/main_memory_bb.sv`, a port-identical blackbox | the pipeline logic only | `synth_nomem.v`, `synth_nomem.json` |

`fmax_sweep.sh` maps once and then brackets the clock period with OpenSTA. Set
`SCRIPT=synthesis/synthesis_nomem.ys` to sweep the pipeline-only build.

## Why the second script exists

`code/main_memory.sv` is a behavioural array written for simulation. Synthesised
as-is it becomes tens of thousands of flip-flops whose read path dominates the
critical path, so the resulting frequency describes the memory, not the
processor. A physical implementation would use an SRAM macro.

Blackboxing removes that array, which is useful for asking "how fast is the
pipeline logic?" — but the number that comes out is **not** the frequency of a
buildable core, because the load-to-use forwarding path runs memory output →
mux → ALU, and with the memory blackboxed that path starts at a blackbox port.

## Reporting rule

Never quote a `synthesis_nomem.ys` number as the core's frequency without
saying so. Either report both, or report the full-design number. The honest form
is: "pipeline logic meets P at X MHz with the memory assumed to close in one
cycle; the array as written does not meet it, and a macro would need to."

Keep the blackbox's ports in sync with `code/main_memory.sv`. A missing port
becomes a hierarchy error, which is the failure you want.
