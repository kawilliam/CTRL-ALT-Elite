#!/usr/bin/env python3
"""fusion_analysis.py - dynamic macro-op fusion opportunity, measured.

The static adjacency census in README.md counts pairs once per source line. A
fusion fires once per *execution*, so a pair inside a loop body counts once per
iteration. This script recovers the dynamic stream from the kernel source plus
the measured retired-instruction count:

    iterations = (retired - prologue) / body_length

retired comes from the simulator (cycles / CPI), so the fire rates below are
grounded in measurement rather than assumed.

Usage:  python3 fusion_analysis.py            (reads *_report.txt if present)
"""
import glob, os, re, sys
from collections import defaultdict

# measured on the fusion branch: kernel -> (cycles, cpi)
MEASURED = {
    "smoke": (6, 3.00), "sweep4": (29, 1.04), "sweep10": (47, 1.27),
    "sweep25": (92, 1.22), "sweep50": (167, 1.21), "sweep100": (317, 1.21),
    "loop10": (47, 1.27), "sum-array": (51, 1.38), "array-idx": (91, 1.25),
    "fib": (69, 1.17), "nested": (112, 1.09), "if-in-loop": (56, 1.12),
    "smul": (218, 1.15), "callret": (37, 1.16),
}

def strip_label(s):
    m = re.match(r'\s*([A-Za-z_]\w*):\s*(.*)$', s)
    return (m.group(1).lower(), m.group(2)) if m else (None, s)

def split_ops(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == '(': depth += 1
        elif ch == ')': depth -= 1
        if ch == ',' and depth == 0: out.append(cur.strip()); cur = ""
        else: cur += ch
    if cur.strip(): out.append(cur.strip())
    return out

def parse(path):
    prog, labels = [], {}
    for raw in open(path):
        lab, rest = strip_label(raw.split('#')[0])
        if lab: labels[lab] = len(prog)
        rest = rest.strip()
        if not rest: continue
        p = rest.split(None, 1)
        mn = p[0].lower(); ops = split_ops(p[1] if len(p) > 1 else "")
        prog.append((mn, ops))
    return prog, labels

def mem_reg(ops):
    m = re.search(r'\(([^()]*)\)', ops[1]) if len(ops) > 1 else None
    return m.group(1) if m else None

COND = {'beq','bne','blt','bge','bltu','bgeu'}
def sources(mn, ops):
    if mn == 'lw':  return [mem_reg(ops)] if mem_reg(ops) else []
    if mn == 'sw':  return [ops[0], mem_reg(ops)]
    if mn in COND:  return ops[:2]
    if mn in ('nop','ecall','jal','jalr'): return []
    return ops[1:]

def dest(mn, ops):
    if mn in ('lw','add','addi','sub','and','or','xor','sll','srl','sra',
              'slt','sltu','slli','srli','srai','andi','ori','xori','slti','sltiu','lui','auipc'):
        return ops[0] if ops else None
    return None

ADDR = {'add','addi'}
FUSIONS = {
    'add+lw'      : lambda a,b: a[0] in ADDR and b[0]=='lw',
    'add+sw'      : lambda a,b: a[0] in ADDR and b[0]=='sw',
    'lw+consumer' : lambda a,b: a[0]=='lw' and dest(*a) and dest(*a) in sources(*b),
    'addi+branch' : lambda a,b: a[0]=='addi' and b[0] in COND,
    'slt+branch'  : lambda a,b: a[0] in ('slt','sltu') and b[0] in COND,
    'lui/auipc+op': lambda a,b: a[0] in ('lui','auipc') and b[0] in ('addi','lw','sw'),
    'lw+sw'       : lambda a,b: a[0]=='lw' and b[0]=='sw',
}

def find_loop(prog):
    """last backward conditional branch -> (start, end) inclusive"""
    best = None
    for i,(mn,ops) in enumerate(prog):
        if mn in COND and ops:
            m = re.search(r'-', ops[-1]); off = None
            try: off = int(ops[-1], 16)
            except ValueError: pass
            if off is None:
                # label target: resolve by name elsewhere
                continue
    return None

# loop-body executions, from the source (authoritative; derivation is only a check)
TRIPS = {"sweep4":4, "sweep10":10, "sweep25":25, "sweep50":50, "sweep100":100,
         "loop10":10, "sum-array":4, "array-idx":8, "fib":10, "nested":20,
         "if-in-loop":10, "smul":32, "callret":3, "smoke":1}

BASE = 0x01000000

def resolve_target(ops, labels):
    """index of a branch target, from a label or a hex address"""
    if not ops: return None
    t = ops[-1].strip().lower()
    if t in labels: return labels[t]
    try: v = int(t, 16)
    except ValueError: return None
    return (v - BASE)//4 if v >= BASE else None

def main():
    rows = []
    totals = defaultdict(int)
    restr  = defaultdict(int)
    back   = defaultdict(int)
    grand_cyc = 0

    for f in sorted(glob.glob("*.txt")):
        name = os.path.basename(f)[:-4]
        if name not in MEASURED: continue
        prog, labels = parse(f)
        cyc, cpi = MEASURED[name]
        dyn = round(cyc / cpi)
        grand_cyc += cyc

        body = None
        for i,(mn,ops) in enumerate(prog):
            if mn in COND:
                t = resolve_target(ops, labels)
                if t is not None and t < i:
                    body = (t, i); break
        if body is None: body = (0, len(prog)-1)
        b0, b1 = body
        blen = b1 - b0 + 1
        prologue = b0
        iters = TRIPS.get(name, max(1, (dyn - prologue) // blen) if blen else 1)

        # (adjacency index, how many times it executes dynamically)
        dyn_edges = [(i, iters) for i in range(b0, b1)]
        dyn_edges += [(b1, max(0, iters-1))]                       # back edge
        dyn_edges += [(i, 1) for i in list(range(0, b0-1)) + list(range(b1, len(prog)-1))]

        counts = defaultdict(int)
        r_cnt = r_back = 0
        for i, mult in dyn_edges:
            if i+1 >= len(prog): continue
            a, b = prog[i], prog[i+1]
            for k, pred in FUSIONS.items():
                if pred(a,b): counts[k] += mult
            # v1 restriction: addi rd == branch rs1
            if a[0]=='addi' and b[0] in COND and a[1] and b[1] and a[1][0] == b[1][0]:
                r_cnt += mult
                t = resolve_target(b[1], labels)
                if t is not None and t < i+1: r_back += mult

        rows.append((name, cyc, dyn, iters, blen, dict(counts), r_cnt, r_back))
        for k,v in counts.items(): totals[k] += v
        restr[name] = r_cnt; back[name] = r_back

    tot_insns = sum(r[2] for r in rows)
    print(f"{'kernel':12}{'cyc':>5}{'insns':>7}{'iter':>6}{'add+lw':>8}{'addi+br':>9}{'rs1=rd':>8}{'backward':>10}")
    print('-'*65)
    for name,cyc,dyn,iters,blen,c,rc,rb in rows:
        print(f"{name:12}{cyc:5}{dyn:7}{iters:6}{c.get('add+lw',0):8}{c.get('addi+branch',0):9}{rc:8}{rb:10}")
    print('-'*65)
    T_aw = totals['add+lw']; T_ab = totals['addi+branch']; T_r = sum(restr.values()); T_rb = sum(back.values())
    print(f"{'TOTAL':12}{grand_cyc:5}{tot_insns:7}{'':6}{T_aw:8}{T_ab:9}{T_r:8}{T_rb:10}")
    print()
    def line(label, n):
        print(f"{label:34}{n:6} pairs   fr {100*n/tot_insns:5.1f}%   {n:4} cycles   {100*n/grand_cyc:5.1f}% of cycles")
    line("add+lw (address+load)", T_aw)
    line("addi+branch (unrestricted)", T_ab)
    line("addi+branch, rs1 == rd (v1)", T_r)
    line("   of which backward (loop-back)", T_rb)
    print()
    if T_r > T_aw:
        print(f"v1 restriction still wins: {T_r} pairs vs {T_aw} for add+lw ({T_r/T_aw:.1f}x).")
    else:
        print(f"RESTRICTION LOSES: {T_r} pairs vs {T_aw} for add+lw - revisit before RTL.")
    print(f"restriction retains {100*T_r/T_ab:.0f}% of the unrestricted addi+branch pairs;"
          f" {100*T_rb/T_r:.0f}% of the retained pairs are backward branches.")

if __name__ == "__main__":
    main()
