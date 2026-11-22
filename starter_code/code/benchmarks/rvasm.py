#!/usr/bin/env python3
"""rvasm.py - minimal RV32I assembler for the CTRL-ALT-ELITE test suite.

Source syntax (one instruction per line; '#' or '//' starts a comment):

    start:  addi x1, x0, 10        # label form
            sw   x1, 0(x2)         # memory form  off(reg)
            lw   x3, 4(x2)
            beq  x1, x3, 1000014   # absolute target address (hex, bare)
            bne  x1, x0, start     # or a label
            ecall

Bare numeric tokens are read as hexadecimal. Branch/jal targets at or above
the program base are treated as absolute addresses; anything smaller is an
offset from the current instruction.

Output: one 32-bit word per line, lowercase hex, ready for $readmemh
(help/../verif/tests/<dir>/<name>.x).

Usage:
    tools/rvasm.py foo.txt                  # writes foo.x
    tools/rvasm.py -o out.x foo.txt
    tools/rvasm.py foo.txt --check foo.x    # assemble and compare, exit 1 on difference
"""
import argparse
import re
import sys

BASE = 0x01000000  # must match `BASE_ADDR in code/constants.svh

REGS = {
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7, "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15, "a6": 16, "a7": 17,
    "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23, "s8": 24,
    "s9": 25, "s10": 26, "s11": 27, "t3": 28, "t4": 29, "t5": 30, "t6": 31,
}
REGS.update({f"x{i}": i for i in range(32)})

R_TYPE = {"add": (0, 0x00), "sub": (0, 0x20), "sll": (1, 0x00), "slt": (2, 0x00),
          "sltu": (3, 0x00), "xor": (4, 0x00), "srl": (5, 0x00), "sra": (5, 0x20),
          "or": (6, 0x00), "and": (7, 0x00)}
I_ALU = {"addi": (0, 0x00), "slti": (2, 0x00), "sltiu": (3, 0x00), "xori": (4, 0x00),
         "ori": (6, 0x00), "andi": (7, 0x00), "slli": (1, 0x00),
         "srli": (5, 0x00), "srai": (5, 0x20)}
B_TYPE = {"beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7}


class AsmError(Exception):
    pass


def reg(tok):
    t = tok.strip().lower()
    if t not in REGS:
        raise AsmError(f"unknown register {tok!r}")
    return REGS[t]


def num(tok):
    """Immediate values: decimal, or hex with a 0x prefix. Matches the
    convention used by the existing hand-written tests (`addi x3,x0,30` is 30)."""
    t = tok.strip()
    neg = t.startswith("-")
    if neg:
        t = t[1:]
    if re.fullmatch(r"0[xX][0-9a-fA-F]+", t):
        v = int(t, 16)
    elif re.fullmatch(r"[0-9]+", t):
        v = int(t, 10)
    else:
        raise AsmError(f"bad number {tok!r}")
    return -v if neg else v


def split_ops(rest):
    rest = rest.strip()
    if not rest:
        return []
    # split on commas that are not inside parentheses
    out, depth, cur = [], 0, ""
    for ch in rest:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def mem_operand(tok):
    m = re.fullmatch(r"(.*)\(([^()]*)\)", tok.strip())
    if not m:
        raise AsmError(f"expected off(reg), got {tok!r}")
    return num(m.group(1)), reg(m.group(2))


def r_enc(f7, rs2, rs1, f3, rd, op=0x33):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def i_enc(imm, rs1, f3, rd, op):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def s_enc(imm, rs2, rs1, f3, op=0x23):
    imm &= 0xFFF
    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 0x1F) << 7) | op


def b_enc(off, rs2, rs1, f3, op=0x63):
    o = off & 0x1FFF
    return (((o >> 12) & 1) << 31) | (((o >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | (((o >> 1) & 0xF) << 8) | (((o >> 11) & 1) << 7) | op


def j_enc(off, rd, op=0x6F):
    o = off & 0x1FFFFF
    return (((o >> 20) & 1) << 31) | (((o >> 1) & 0x3FF) << 21) | (((o >> 11) & 1) << 20) | \
           (((o >> 12) & 0xFF) << 12) | (rd << 7) | op


def target_value(tok, labels, pc):
    """Branch/jal targets are written as hex addresses in this suite
    (`beq x1,x3,1000014`). Values at or above BASE are absolute; smaller
    values are offsets from the current instruction. Labels also work."""
    t = tok.strip()
    if t.lower() in labels:
        return labels[t.lower()]
    if re.fullmatch(r"0[xX][0-9a-fA-F]+|[0-9a-fA-F]+", t):
        v = int(t, 16)
    else:
        v = num(t)
    return v if v >= BASE else pc + v


def assemble(text):
    lines = []
    for raw in text.splitlines():
        s = raw.split("#")[0].split("//")[0].rstrip()
        if not s.strip():
            continue
        while ":" in s:
            lab, _, rest = s.partition(":")
            if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", lab.strip()):
                break
            lines.append(("label", lab.strip().lower(), None))
            s = rest
            if not s.strip():
                break
        if s.strip():
            parts = s.strip().split(None, 1)
            lines.append(("insn", parts[0].lower(), parts[1] if len(parts) > 1 else ""))

    labels, addr = {}, BASE
    for kind, a, b in lines:
        if kind == "label":
            if a in labels:
                raise AsmError(f"duplicate label {a!r}")
            labels[a] = addr
        else:
            addr += 4

    words, addr = [], BASE
    for kind, a, b in lines:
        if kind == "label":
            continue
        try:
            words.append(_encode(a, b, labels, addr))
        except AsmError as e:
            raise AsmError(f"pc=0x{addr:08x} {a} {b}: {e}")
        addr += 4
    return words


def _encode(mn, rest, labels, pc):
    if mn == "nop":
        return 0x00000013
    if mn == "ecall":
        return 0x00000073
    ops = split_ops(rest)
    if mn in R_TYPE:
        f3, f7 = R_TYPE[mn]
        return r_enc(f7, reg(ops[2]), reg(ops[1]), f3, reg(ops[0]))
    if mn in I_ALU:
        f3, f7 = I_ALU[mn]
        imm = num(ops[2]) if len(ops) == 3 else num(ops[1])
        rs1 = reg(ops[1])
        if mn in ("slli", "srli", "srai"):
            return i_enc((f7 << 5) | (imm & 0x1F), rs1, f3, reg(ops[0]), 0x13)
        return i_enc(imm, rs1, f3, reg(ops[0]), 0x13)
    if mn == "lw":
        off, rs1 = mem_operand(ops[1])
        return i_enc(off, rs1, 2, reg(ops[0]), 0x03)
    if mn == "jalr":
        if len(ops) == 2:
            off, rs1 = mem_operand(ops[1])
        else:
            off, rs1 = num(ops[2]), reg(ops[1])
        return i_enc(off, rs1, 0, reg(ops[0]), 0x67)
    if mn == "sw":
        off, rs1 = mem_operand(ops[1])
        return s_enc(off, reg(ops[0]), rs1, 2)
    if mn in ("lui", "auipc"):
        return ((num(ops[1]) & 0xFFFFF) << 12) | (reg(ops[0]) << 7) | (0x37 if mn == "lui" else 0x17)
    if mn == "jal":
        rd = reg(ops[0]) if len(ops) > 1 else 1
        tgt = target_value(ops[-1], labels, pc)
        return j_enc(tgt - pc, rd)
    if mn in B_TYPE:
        tgt = target_value(ops[2], labels, pc)
        return b_enc(tgt - pc, reg(ops[1]), reg(ops[0]), B_TYPE[mn])
    raise AsmError(f"unsupported mnemonic {mn!r}")


def main():
    ap = argparse.ArgumentParser(description="minimal RV32I assembler")
    ap.add_argument("source")
    ap.add_argument("-o", "--output")
    ap.add_argument("--check", metavar="EXPECTED", help="compare against an existing .x")
    args = ap.parse_args()

    with open(args.source, encoding="utf-8") as f:
        words = assemble(f.read())
    text = "".join(f"{w:08x}\n" for w in words)

    if args.check:
        with open(args.check, encoding="utf-8") as f:
            want = [l.strip().lower() for l in f if l.strip()]
        got = [f"{w:08x}" for w in words]
        if want == got:
            print(f"OK    {args.source} matches {args.check} ({len(got)} words)")
            return 0
        print(f"DIFF  {args.source} vs {args.check}")
        for i in range(max(len(want), len(got))):
            a = want[i] if i < len(want) else "<missing>"
            b = got[i] if i < len(got) else "<missing>"
            if a != b:
                print(f"  word {i:3d}: expected {a:8s} got {b:8s}")
        return 1

    out = args.output or (args.source.rsplit(".", 1)[0] + ".x")
    with open(out, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {out} ({len(words)} words)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
