#!/usr/bin/env python3

# Crude Assembler for the StarCore-1 Processor
# Made by: Shaun Beautement & Neo Vorsatz

# Define constants
PROG_SIZE = 32
DATA_SIZE = 16
RESERVED_LBL = "this_label_is_reserved"
OPCODES = {
    "LD": "0000",
    "ST": "0001",
    "ADD": "0010",
    "SUB": "0011",
    "INV": "0100",
    "SHL": "0101",
    "SHR": "0110",
    "AND": "0111",
    "OR": "1000",
    "SLT": "1001",
    "RETI": "1010",
    "BEQ": "1011",
    "BNE": "1100",
    "JMP": "1101",
}

# Define types
class JumpAddress:
    label: str
    def __init__(self, label: str) -> None:
        self.label = label
class BranchAddress:
    label: str
    def __init__(self, label: str) -> None:
        self.label = label
type Assembled = str|JumpAddress|BranchAddress

# Assisting functions
def load_file(filename: str) -> list[str]:
    """
    Loads a file into a list of lines
    """
    with open(filename, "r") as f:
        return f.read().splitlines()

def to_bin(value:int, bits:int) -> str:
    """
    Converts integer to signed/unsigned binary string.
    """
    if value < 0:
        value = (1 << bits) + value
    return format(value & ((1 << bits) - 1), f"0{bits}b")

def assemble(lines: list[str]) -> tuple[list[list[Assembled]], dict[str, int]]:
    """
    Returns
    - an intermediate representation: partially-assembled instructions with unresolved symbols
    - label table
    """
    # List of assembled bits and unresolved labels
    assembled: list[list[Assembled]] = []
    # List of labels
    labels: dict[str, int] = {}

    lineno = -1
    loc = 0
    for line in lines:
        lineno += 1

        # remove comments
        code = line.split("#", 1)[0].split(";", 1)[0].split("@", 1)[0]

        if ":" in code:
            label, code = code.split(":")
            label = label.strip()
            if label.isidentifier():
                labels[label] = loc
            else:
                raise Exception(
                    f"Error at line {lineno}: found colon, but preceding text was not a label."
                )

        # Clean up line and split components (quick-and-dirty)
        syms = code.replace(",", " ").replace("(", " ").replace(")", " ").split()

        if not syms:
            continue

        instr = syms[0].upper()
        if instr in OPCODES:
            op = OPCODES[instr]
        else:
            raise Exception(
                f"Error in line {lineno}: {instr} is not a vaild operation."
            )

        # R-type: [OP][RS1][RS2][WS][unused]
        if instr in ["ADD", "SUB", "SHL", "SHR", "AND", "OR", "SLT"]:
            ws, rs1, rs2 = [int(x[1:]) for x in syms[1:4]]
            assembled.append(
                [op + to_bin(rs1, 3) + to_bin(rs2, 3) + to_bin(ws, 3) + "000"]
            )

        # Special R-type: INV
        elif instr == "INV":
            ws, rs1 = [int(x[1:]) for x in syms[1:3]]
            assembled.append([op + to_bin(rs1, 3) + "000" + to_bin(ws, 3) + "000"])

        # I-type: [OP][RS1][WS][Offset]
        elif instr in ["LD", "ST"]:
            # "LD R1, 4(R2)"
            ws, offset, rs1 = [
                int(x[1:]) if x.startswith("R") else int(x) for x in syms[1:4]
            ]
            # WS is encoded in [8:6] for I-type
            assembled.append(
                [op + to_bin(rs1, 3) + to_bin(ws, 3) + to_bin(offset, 6)]
            )
        elif instr in ["BEQ", "BNE"]:
            rs1 = int(syms[1][1:])
            rs2 = int(syms[2][1:])
            target = syms[3]
            try:
                target = int(target)
                assembled.append(
                    [
                        op + to_bin(rs1, 3) + to_bin(rs2, 3),
                        to_bin(target, 6),
                    ]
                )
            except ValueError:
                assembled.append(
                    [
                        op + to_bin(rs1, 3) + to_bin(rs2, 3),
                        BranchAddress(label=target),
                    ]
                )

        # J-type: [OP][Offset]
        elif instr == "JMP":
            target = syms[1]
            try:
                target = int(target)
                assembled.append([op + to_bin(target, 12)])
            except ValueError:
                assembled.append([op, JumpAddress(label=target)])

        # Return from interrupt
        elif instr == "RETI":
            assembled.append([op + "0" * 12])

        loc += 2

    return assembled, labels

def link(code: list[list[Assembled]], labels: dict[str, int], outfilename: str):
    """
    Resolves all labels in the intermediate representation
    and writes the final assembly to the output file.
    """
    with open(outfilename, "w") as of:
        loc = 0
        for line in code:
            for symbol in line:
                match symbol:
                    # jump addresses are 13 bits, missing the low bit (always 0)
                    # they are relative to the upper 3 bits of the program counter
                    case JumpAddress():
                        of.write(to_bin(labels[symbol.label] // 2, 12))
                    # branch address are 6 bits, signed, relative to the PC+2, missing the low bit (always 0)
                    case BranchAddress():
                        of.write(to_bin((labels[symbol.label] - (loc + 2)) // 2, 6))
                    # already assembled
                    case str():
                        of.write(symbol)

            of.write("\n")
            loc += 2

        for _ in range(PROG_SIZE - loc // 2):
            # print out no-ops to fill the rest of instruction memory
            of.write("1111" + "0" * 12 + "\n")

# Usage
if __name__ == "__main__":
    # Get program name
    program_name = input("Program name: ")

    # Append files and framing
    file_content = ["JMP "+RESERVED_LBL]
    file_content += load_file("assembly/"+program_name+"/interrupt.s")
    if not (file_content[-1].upper().startswith("RETI")):
        file_content.append("RETI") # Add the return instruction
    file_content += [RESERVED_LBL+":"]
    file_content += load_file("assembly/"+program_name+"/program.s")

    # Assemble and link
    asm, labels = assemble(file_content)
    link(asm, labels, "test/test.prog")

    # Data Memory
    with open("assembly/"+program_name+"/data_memory", "r") as f:
        data = f.readlines()
    if data[-1][-1] != "\n":
        data[-1] += "\n"
    for i in range(DATA_SIZE-len(data)):
        data.append("0000000000000000\n")
    with open("test/test.data", "w") as f:
        f.writelines(data)
