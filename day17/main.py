#!/usr/bin/env python3
import sys
import re
from dataclasses import dataclass

@dataclass
class Registers:
    A: int
    B: int
    C: int

_int_re = re.compile(r"-?\d+")

def parse_input(text):
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    def first_int(line):
        m = _int_re.search(line)
        if not m:
            raise ValueError("no int in line: %r" % (line,))
        return int(m.group(0))
    A = first_int(lines[0])
    B = first_int(lines[1])
    C = first_int(lines[2])
    program = [int(x) for x in _int_re.findall(lines[3])]
    return Registers(A, B, C), program

def combo_value(op, regs):
    if 0 <= op <= 3:
        return op
    match op:
        case 4:
            return regs.A
        case 5:
            return regs.B
        case 6:
            return regs.C
        case _:
            raise ValueError("invalid combo operand %d" % op)

def run_program(regs, program):
    ip = 0
    out = []
    n = len(program)
    while ip < n:
        if ip + 1 >= n:
            break
        opcode = program[ip]
        operand = program[ip + 1]
        advance = True
        match opcode:
            case 0:  # adv
                denom = 1 << combo_value(operand, regs)
                regs.A //= denom
            case 1:  # bxl
                regs.B ^= operand
            case 2:  # bst
                regs.B = combo_value(operand, regs) % 8
            case 3:  # jnz
                if regs.A != 0:
                    ip = operand
                    advance = False
            case 4:  # bxc
                regs.B ^= regs.C
            case 5:  # out
                out.append(combo_value(operand, regs) % 8)
            case 6:  # bdv
                denom = 1 << combo_value(operand, regs)
                regs.B = regs.A // denom
            case 7:  # cdv
                denom = 1 << combo_value(operand, regs)
                regs.C = regs.A // denom
            case _:
                raise ValueError("unknown opcode %d" % opcode)
        if advance:
            ip += 2
    return out

def val_digit(a):
    lo = a & 7
    b2 = lo ^ 1
    c = a >> b2
    return ((lo ^ 4) ^ (c & 7)) & 7

def run_math(A):
    out = []
    while A != 0:
        out.append(val_digit(A))
        A //= 8
    return out

def find_min_A_for_program(program):
    expected = list(reversed(program))
    last_idx = len(expected) - 1

    def search(m, n, idx):
        for a in range(m, n):
            if val_digit(a) != expected[idx]:
                continue
            if idx == last_idx:
                if a > 0:
                    yield a
            else:
                yield from search(a * 8, (a + 1) * 8, idx + 1)

    for candidate in search(0, 8, 0):
        return candidate
    return None

def main():
    text = sys.stdin.read()
    init_regs, program = parse_input(text)

    part1_out = run_math(init_regs.A)
    part1_answer = ",".join(str(x) for x in part1_out)

    part2_answer = find_min_A_for_program(program)

    print(part1_answer)
    print(part2_answer)

if __name__ == "__main__":
    main()
