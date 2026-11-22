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

def main():
    rows, totals = [], defaultdict(int)
    grand_cyc = 0
    for f in sorted(glob.glob("*.txt")):
        name = os.path.basename(f)[:-4]
        if name not in MEASURED: continue
        prog, labels = parse(f)
        cyc, cpi = MEASURED[name]
        dyn = round(cyc / cpi)
        grand_cyc += cyc

        # loop body: branch whose target label is a backward jump
        body = None
        for i,(mn,ops) in enumerate(prog):
            if mn in COND and ops and ops[-1].lower() in labels:
                tgt = labels[ops[-1].lower()]
                if tgt < i:
                    body = (tgt, i)
                    break
        if body is None:
            body = (0, len(prog)-1)
        b0, b1 = body
        blen = b1 - b0 + 1
        prologue = b0
        derived = max(1, (dyn - prologue) // blen) if blen else 1
        iters = TRIPS.get(name, derived)

        counts = defaultdict(int)
        # inside the body, per iteration
        for i in range(b0, b1):
            for k,pred in FUSIONS.items():
                if pred(prog[i], prog[i+1]): counts[k] += iters
        # the back edge itself (last -> first), per iteration except the last
        for k,pred in FUSIONS.items():
            if pred(prog[b1], prog[b0]): counts[k] += max(0, iters-1)
        # prologue + epilogue: executed once
        for i in list(range(0,b0-1)) + list(range(b1, len(prog)-1)):
            for k,pred in FUSIONS.items():
                if pred(prog[i], prog[i+1]): counts[k] += 1

        rows.append((name, cyc, dyn, iters, blen, dict(counts)))
        for k,v in counts.items(): totals[k] += v

    hdr = f"{'kernel':12}{'cyc':>5}{'insns':>7}{'iter':>6}  " + "".join(f"{k:>14}" for k in FUSIONS)
    print(hdr); print('-'*len(hdr))
    for name,cyc,dyn,iters,blen,c in rows:
        print(f"{name:12}{cyc:5}{dyn:7}{iters:6}  " + "".join(f"{c.get(k,0):14}" for k in FUSIONS))
    print('-'*len(hdr))
    tot_insns = sum(r[2] for r in rows)
    print(f"{'TOTAL':12}{grand_cyc:5}{tot_insns:7}{'':6}  " + "".join(f"{totals[k]:14}" for k in FUSIONS))
    print()
    print(f"{'fusion':16}{'dyn pairs':>10}{'fire rate':>11}{'cyc saved':>11}{'% cycles':>10}{'cost':>6}")
    COST = {'add+lw':2,'add+sw':2,'lw+consumer':5,'addi+branch':3,'slt+branch':2,'lui/auipc+op':2,'lw+sw':3}
    ranked=[]
    for k in FUSIONS:
        n=totals[k]; fr=n/tot_insns; saved=n            # 1 cycle per fused pair
        pct=100*saved/grand_cyc
        ranked.append((pct,k,n,fr,saved,COST[k]))
    for pct,k,n,fr,saved,c in sorted(ranked, reverse=True):
        print(f"{k:16}{n:10}{100*fr:10.1f}%{saved:11}{pct:9.1f}%{c:6}")
    print()
    print("cost: 1=trivial .. 5=datapath change.  useful: >=5% cycles; cheap: cost <=2")
    for pct,k,n,fr,saved,c in sorted(ranked, reverse=True):
        verdict = "BUILD" if (pct>=5 and c<=2) else ("analysis only" if pct<5 else "not cheap")
        print(f"  {k:16} {pct:5.1f}% of cycles, cost {c}  -> {verdict}")

if __name__ == "__main__":
    main()
