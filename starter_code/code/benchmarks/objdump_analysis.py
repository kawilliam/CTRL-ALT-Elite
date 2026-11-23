#!/usr/bin/env python3
"""objdump_analysis.py - what is actually in compiled RISC-V code.

Reads one or more `objdump -d` listings and reports the things this project needs
to know about code nobody shaped by hand:

  * instruction mix, so the mix can be compared with the hand-written kernels
  * cycles-at-best = instruction count (the floor a perfect pipeline reaches)
  * adjacent addi->branch pairs, split by which operand the branch tests:
        v1   branch.rs1 == addi.rd      (what fusion v1 accepts)
        v2   branch.rs2 == addi.rd      (what fusion v2 added)
        -    neither, so not fusable without a third register read
  * loop-back branches specifically, since that is the pair that fires once per
    iteration and dominates any loop optimisation

Usage:  python3 objdump_analysis.py bubble.objdump [gcd.objdump ...]
"""
import re, sys
from collections import Counter

COND   = {'beq','bne','blt','bge','bltu','bgeu'}
LOAD   = {'lb','lh','lw','lbu','lhu'}
STORE  = {'sb','sh','sw'}
ALU_I  = {'addi','slti','sltiu','xori','ori','andi','slli','srli','srai'}
ALU_R  = {'add','sub','sll','slt','sltu','xor','srl','sra','or','and'}
UPPER  = {'lui','auipc'}
JUMP   = {'jal','jalr'}

LINE = re.compile(r'^\s*([0-9a-f]+):\s+([0-9a-f]+)\s+([a-z][a-z0-9.]*)\s*(.*)$')

def parse(path):
    ins = []
    for ln in open(path, errors='ignore'):
        m = LINE.match(ln)
        if not m:
            continue
        pc = int(m.group(1), 16)
        mn = m.group(3).lower()
        ops = [o.strip().split(' ')[0] for o in m.group(4).split(',')] if m.group(4).strip() else []
        ins.append((pc, mn, ops))
    return ins

def kind(mn):
    if mn in COND:   return 'branch'
    if mn in LOAD:   return 'load'
    if mn in STORE:  return 'store'
    if mn in ALU_I:  return 'alu-imm'
    if mn in ALU_R:  return 'alu-reg'
    if mn in UPPER:  return 'upper-imm'
    if mn in JUMP:   return 'jump'
    if mn in ('ecall', 'ebreak'): return 'system'
    return 'other'

def main(paths):
    for path in paths:
        ins = parse(path)
        if not ins:
            print(f"{path}: no instructions parsed")
            continue
        mix = Counter(kind(mn) for _, mn, _ in ins)
        total = len(ins)
        print(f"\n=== {path}  ({total} instructions) ===")
        order = ['alu-imm','alu-reg','load','store','branch','jump','upper-imm','system','other']
        print("  mix: " + "  ".join(f"{k} {mix[k]} ({100*mix[k]/total:.0f}%)"
                                     for k in order if mix[k]))
        print(f"  cycles-at-best (1 IPC): {total}")

        # adjacent addi -> conditional branch
        v1 = v2 = none = 0
        back_v1 = back_v2 = back_none = 0
        for i in range(total - 1):
            pc, mn, ops = ins[i]
            npc, nmn, nops = ins[i+1]
            if mn != 'addi' or nmn not in COND or npc != pc + 4 or len(nops) < 3:
                continue
            rd, rs1, rs2 = ops[0], nops[0], nops[1]
            tgt = None
            try: tgt = int(nops[2], 16)
            except ValueError: pass
            backward = tgt is not None and tgt < npc
            if rs1 == rd:
                v1 += 1; back_v1 += backward
            elif rs2 == rd:
                v2 += 1; back_v2 += backward
            else:
                none += 1; back_none += backward
        print(f"  addi+branch pairs: v1 {v1} (of which loop-back {back_v1})   "
              f"v2 {v2} (loop-back {back_v2})   not fusable {none} (loop-back {back_none})")
        fusable = v1 + v2
        if fusable:
            print(f"  -> fusion could remove {fusable} of {total} instructions "
                  f"= {100*fusable/total:.1f}% at best (one cycle each)")

        # every backward branch: does the loop counter get fused?
        backs = [(pc, mn, ops) for pc, mn, ops in ins if mn in COND and len(ops) >= 3
                 and re.match(r'^[0-9a-f]+$', ops[2]) and int(ops[2], 16) < pc]
        print(f"  backward branches: {len(backs)}")
        for pc, mn, ops in backs:
            prev = next((x for x in reversed(ins) if x[0] < pc), None)
            tag = "—"
            if prev and prev[0] == pc - 4 and prev[1] == 'addi':
                rd = prev[2][0]
                tag = "v1" if ops[0] == rd else ("v2" if ops[1] == rd else "not fusable")
            print(f"    {pc:#08x}  {mn:5} {','.join(ops):18}  preceding addi: {tag}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    main(sys.argv[1:])
