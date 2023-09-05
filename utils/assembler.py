from enum import Enum
import re

class instr_t(Enum):
    R = 0
    I = 1
    S = 2
    B = 3
    U = 4
    J = 5
    
instrToOpcode = {
    'LUI':      (instr_t.U, 'lui rd, imm[31:12]',        'imm[31:12]_rd_0110111'),
    'AUIPC': 	(instr_t.U, 'auipc rd, imm[31:12]',      'imm[31:12]_rd_0010111'),
    'JAL': 	    (instr_t.J, 'jal rd, imm[20:1]',         'imm[20|10:1|11|19:12]_rd_1101111'),
    'JALR':	    (instr_t.I, 'jalr rd, rs1, imm[11:0]',   'imm[11:0]_rs1_000_rd_1100111'),
    'BEQ':		(instr_t.B, 'beq rs1, rs2, imm[12:1]',   'imm[12|10:5]_rs2_rs1_000_imm[4:1|11]_1100011'),
    'BNE':		(instr_t.B, 'bne rs1, rs2, imm[12:1]',   'imm[12|10:5]_rs2_rs1_001_imm[4:1|11]_1100011'),
    'BLT':		(instr_t.B, 'blt rs1, rs2, imm[12:1]',   'imm[12|10:5]_rs2_rs1_100_imm[4:1|11]_1100011'),
    'BGE':		(instr_t.B, 'bge rs1, rs2, imm[12:1]',   'imm[12|10:5]_rs2_rs1_101_imm[4:1|11]_1100011'),
    'BLTU':	    (instr_t.B, 'bltu rs1, rs2, imm[12:1]',  'imm[12|10:5]_rs2_rs1_110_imm[4:1|11]_1100011'),
    'BGEU':	    (instr_t.B, 'bgeu rs1, rs2, imm[12:1]',  'imm[12|10:5]_rs2_rs1_111_imm[4:1|11]_1100011'),
    'LB':		(instr_t.I, 'lb rd, imm[11:0](rs1)',     'imm[11:0]_rs1_000_rd_0000011'),
    'LH':		(instr_t.I, 'lh rd, imm[11:0](rs1)',     'imm[11:0]_rs1_001_rd_0000011'),
    'LW':		(instr_t.I, 'lw rd, imm[11:0](rs1)',     'imm[11:0]_rs1_010_rd_0000011'),
    'LBU':		(instr_t.I, 'lbu rd, imm[11:0](rs1)',    'imm[11:0]_rs1_100_rd_0000011'),
    'LHU':		(instr_t.I, 'lhu rd, imm[11:0](rs1)',    'imm[11:0]_rs1_101_rd_0000011'),
    'SB':		(instr_t.S, 'sb rs2, imm[11:0](rs1)',    'imm[11:5]_rs2_rs1_000_imm[4:0]_0100011'),
    'SH':	    (instr_t.S, 'sh rs2, imm[11:0](rs1)',    'imm[11:5]_rs2_rs1_001_imm[4:0]_0100011'),
    'SW':	    (instr_t.S, 'sw rs2, imm[11:0](rs1)',    'imm[11:5]_rs2_rs1_010_imm[4:0]_0100011'),
    'ADDI':	    (instr_t.I, 'addi rd, rs1, imm[11:0]',   'imm[11:0]_rs1_000_rd_0010011'),
    'SLTI':	    (instr_t.I, 'slti rd, rs1, imm[11:0]',   'imm[11:0]_rs1_010_rd_0010011'),
    'SLTIU':	(instr_t.I, 'sltiu rd, rs1, imm[11:0]',  'imm[11:0]_rs1_011_rd_0010011'),
    'XORI':	    (instr_t.I, 'xori rd, rs1, imm[11:0]',   'imm[11:0]_rs1_100_rd_0010011'),
    'ORI':		(instr_t.I, 'ori rd, rs1, imm[11:0]',    'imm[11:0]_rs1_110_rd_0010011'),
    'ANDI':	    (instr_t.I, 'andi rd, rs1, imm[11:0]',   'imm[11:0]_rs1_111_rd_0010011'),
    'SLLI':	    (instr_t.R, 'slli rd, rs1, imm[4:0]',    '0000000_imm[4:0]_rs1_001_rd_0010011'),
    'SRLI':	    (instr_t.R, 'srli rd, rs1, imm[4:0]',    '0000000_imm[4:0]_rs1_101_rd_0010011'),
    'SRAI':	    (instr_t.R, 'srai rd, rs1, imm[4:0]',    '0100000_imm[4:0]_rs1_101_rd_0010011'),
    'ADD':		(instr_t.R, 'add rd, rs1, rs2',          '0000000_rs2_rs1_000_rd_0110011'),
    'SUB':		(instr_t.R, 'sub rd, rs1, rs2',          '0100000_rs2_rs1_000_rd_0110011'),
    'SLL':		(instr_t.R, 'sll rd, rs1, rs2',          '0000000_rs2_rs1_001_rd_0110011'),
    'SLT':		(instr_t.R, 'slt rd, rs1, rs2',          '0000000_rs2_rs1_010_rd_0110011'),
    'SLTU':	    (instr_t.R, 'sltu rd, rs1, rs2',         '0000000_rs2_rs1_011_rd_0110011'),
    'XOR':		(instr_t.R, 'xor rd, rs1, rs2',          '0000000_rs2_rs1_100_rd_0110011'),
    'SRL':		(instr_t.R, 'srl rd, rs1, rs2',          '0000000_rs2_rs1_101_rd_0110011'),
    'SRA':		(instr_t.R, 'sra rd, rs1, rs2',          '0100000_rs2_rs1_101_rd_0110011'),
    'OR':		(instr_t.R, 'or rd, rs1, rs2',           '0000000_rs2_rs1_110_rd_0110011'),
    'AND':		(instr_t.R, 'and rd, rs1, rs2',          '0000000_rs2_rs1_111_rd_0110011'),
    'FENCE':	(instr_t.I, 'fence pre, succ', ''),
    'FENCE.I':	(instr_t.I, '', ''),
    'ECALL':	(instr_t.I, 'ecall', ''),
    'EBREAK':	(instr_t.I, 'ebreak', ''),
    'CSRRW':	(instr_t.I, '', ''),
    'CSRRS':	(instr_t.I, '', ''),
    'CSRRC':	(instr_t.I, '', ''),
    'CSRRWI':	(instr_t.I, '', ''),
    'CSRRSI': 	(instr_t.I, '', ''),
    'CSRRCI': 	(instr_t.I, '', '')}

regToInt = {
    'x0': 0,                            # hard-wired zero
    'x1': 1,   'ra': 1,                 # return address (caller)
    'x2': 2,   'sp': 2,                 # stack pointer (callee)
    'x3': 3,   'gp': 3,                 # global pointer
    'x4': 4,   'tp': 4,                 # thread pointer
    'x5': 5,   't0': 5,                 # temporary / alternative link reg (caller)
    'x6': 6,   't1': 6,                 # temporary (caller)
    'x7': 7,   't2': 7,
    'x8': 8,   's0': 8,   'fp': 8,	    # saved reg / frame pointer (callee)
    'x9': 9,   's1': 9,                 # saved reg (callee)
    'x10': 10, 'a0': 10,                # function argument / return values (caller)
    'x11': 11, 'a1': 11,
    'x12': 12, 'a2': 12,                # function argument (caller)
    'x13': 13, 'a3': 13,
    'x14': 14, 'a4': 14,
    'x15': 15, 'a5': 15,
    'x16': 16, 'a6': 16,
    'x17': 17, 'a7': 17,
    'x18': 18, 's2': 18,				# saved reg (caller)
    'x19': 19, 's3': 19,
    'x20': 20, 's4': 20,
    'x21': 21, 's5': 21,
    'x22': 22, 's6': 22,
    'x23': 23, 's7': 23,
    'x24': 24, 's8': 24,
    'x25': 25, 's9': 25,
    'x26': 26, 's10': 26,
    'x27': 27, 's11': 27,
    'x28': 28, 't3': 28,				# temporaries (caller)
    'x29': 29, 't4': 29,
    'x30': 30, 't5': 30,
    'x31': 31, 't6': 31}


def assembleInstr(instrStr):
    instrArgs = re.split('[ ,()]+', instrStr)
    print(instrArgs)
    assert instrArgs[0].upper() in instrToOpcode, "Instruction '%s' is invalid" % instrArgs[0]
    
    type, templateStr, templateBin = instrToOpcode[instrArgs[0].upper()]
    templateArgs = re.split('[ ,()]+', templateStr)
    assert len(templateArgs) == len(instrArgs), '%d args in template, but %d args in instr' % (len(templateArgs), len(instrArgs))
    templateArgs[0] = 'instr'
    
    instrArgsToVals = dict(zip(templateArgs, instrArgs))
    
    immFormat, immVal = None, None
    if 'imm' in templateArgs[-1]:
        immFormat = templateArgs[-1]
        immVal = instrArgsToVals[immFormat]
    print('%s, %s' % (immFormat, immVal))
        
    templateBinArgs = templateBin.split('_')
    instrBinStr = ''
    for arg in templateBinArgs:
        print('===================\narg(%s)' % str(arg))
        if 'imm' in arg:
            print('> case 0 imm:')
            dataBinStr = convertImmFormat(immFormat, arg, immVal)
            assert all(char in '01' for char in dataBinStr)
            print('arg(%s) -> bin(%s)' % (arg, dataBinStr))
            instrBinStr = instrBinStr + dataBinStr
        elif arg in instrArgsToVals:
            print('> case 1 arg:')
            reg = instrArgsToVals[arg]
            print('reg(%s)' % reg)
            assert reg in regToInt
            regBinStr = f'{regToInt[reg]:05b}'
            print('arg(%s) -> bin(%s)' % (arg, regBinStr))
            instrBinStr = instrBinStr + regBinStr
        else:
            print('> case 2 digit:')
            assert arg.isdigit()
            assert all(char in '01' for char in instrBinStr)
            print('arg(%s) -> bin(%s)' % (arg, arg))
            instrBinStr = instrBinStr + arg
        print('--- %s' % instrBinStr)
        
    assert len(instrBinStr) == 32, 'instrction %s is only %d bits' % (instrBinStr, len(instrBinStr))
       
    instrBin = bin(int(instrBinStr, 2))
    print(instrBin)
    print(hex(int(instrBin, 2)))
    return instrBin


def convertImmFormat(inFormat, outFormat, inBinaryStr):
    assert '[' in inFormat and ']' in inFormat
    assert '[' in outFormat and ']' in outFormat
    assert type(inBinaryStr) == str
    
    inListSeq = inFormat.split('[')[1].split(']')[0].split('|')
    inBinList = list(inBinaryStr)
    inDictSeq = {}
    for seq in inListSeq:
        if ':' in seq:
            high, low = seq.split(':')
            assert high.isdigit()
            assert low.isdigit()
            for i in range(int(high), int(low)-1, -1):
                assert len(inBinList) > 0
                assert i not in inDictSeq
                inDictSeq[i] = inBinList.pop(0)
        else:
            assert seq.isdigit()
            assert int(seq) not in inDictSeq
            assert len(inBinList) > 0
            inDictSeq[int(seq)] = inBinList.pop(0)
    assert len(inBinList) == 0, 'inBinList not cleared, %d bits left' % len(inBinList)
            
    outListSeq = outFormat.split('[')[1].split(']')[0].split('|')
    outBinStr = ''
    for seq in outListSeq:
        if ':' in seq:
            high, low = seq.split(':')
            assert high.isdigit()
            assert low.isdigit()
            assert int(high) >= int(low)
            for i in range(int(high), int(low)-1, -1):
                assert len(inDictSeq) > 0
                assert i in inDictSeq
                outBinStr = outBinStr + inDictSeq.pop(i)
        else:
            assert seq.isdigit()
            assert int(seq) in inDictSeq
            assert len(inDictSeq) > 0
            outBinStr = outBinStr + inDictSeq.pop(i)
            
    return outBinStr

def test_convertImmFormat():
    print('Testing convertImmFormat() on integers')
    inForm = 'imm[3:1|5:4|0]'
    outForm = 'imm[2:0|5:3]'
    inBin = '321540'
    outBin = convertImmFormat(inForm, outForm, inBin)
    assert outBin == '210543'
    print('--- Passed ---')
    
    print('Testing convertImmFormat() on select integers')
    inForm = 'imm[3:1|5:4|0]'
    outForm = 'imm[4:1]'
    inBin = '321540'
    outBin = convertImmFormat(inForm, outForm, inBin)
    assert outBin == '4321'
    print('--- Passed ---')

    print('Testing convertImmFormat() on binary')
    inForm = 'imm[3:1|5:4|0]'
    outForm = 'imm[2:0|5:3]'
    inBin = '101100'
    assert all(char in '01' for char in inBin)
    outBin = convertImmFormat(inForm, outForm, inBin)
    assert outBin == '010101'
    print('--- Passed ---')
    
# test_convertImmFormat()
assembleInstr('addi x1, x2, 000100100011') #addi rd, rs1, imm[11:0]