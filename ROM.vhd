library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.assembly_instructions.all;
use work.microcode_instructions.all;

-- this is just the ROM part of microcode which contains all the necessary translations
entity ROM is
    port(opcode : IN STD_LOGIC_VECTOR(3 downto 0);
         flag   : IN STD_LOGIC;
         uPC    : IN STD_LOGIC_VECTOR(1 downto 0);
         uInstr : OUT uInstruction);
end ROM;

architecture structural of ROM is
    -- add a helper function to convert the string literal to a vector
    function to_std_logic_vector(s : string)
        return std_logic_vector
    is
        variable ret : std_logic_vector(s'length - 1 downto 0); -- strings are indexed from 1 to N inclusive
    begin
        for i in 1 to s'length loop
            if s(i) = '0' then
                ret(s'length  - i) := '0';
            elsif s(i) = '1' then
                ret(s'length - i) := '1';
            else
                ret(s'length - i) := 'X';
            end if;
        end loop;
        return ret;
    end function;
    -- address is opcode+flag+uPC so they flow easily
    -- function to initialize ROM
    constant ROM_size : NATURAL := 2 ** 7;
    function init_ROM return uMemory is
        variable ROM_content : uMemory (0 to ROM_size - 1);
    begin
        -- zero out the ROM
        for i in 0 to ROM_size - 1 loop
            ROM_content(i) := init_instruction;
        end loop;

        -- add functions (2 pairs for ones with flag 1 as well)
        -- ADD = 0000 Flag = 0 Addr = 0000000
                                                    -- IE, bypass, WA_en, RA_en, RB_en, ALU, OE, RW, Flag, LE
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000001")))) := ('0', NOBR, '1', '1', '1', OP_ADD, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000011")))) := ('0', NOBR, '0', '0', '0',  OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- ADD = 0000 Flag = 1 Addr = 0000100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000101")))) := ('0', NOBR, '1', '1', '1', OP_ADD, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0000111")))) := ('0', NOBR, '0', '0', '0',  OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- SUB = 0001 Flag = 0 Addr = 0001000
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001001")))) := ('0', NOBR, '1', '1', '1', OP_SUB, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- SUB = 0001 Flag = 1 Addr = 0001100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001101")))) := ('0', NOBR, '1', '1', '1', OP_SUB, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0001111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- AND = 0010 Flag = 0 Addr = 0010000
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010001")))) := ('0', NOBR, '1', '1', '1', OP_AND, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- AND = 0010 Flag = 1 Addr = 0010100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010101")))) := ('0', NOBR, '1', '1', '1', OP_AND, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0010111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- OR = 0011 Flag = 0 Addr =  0011000
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011001")))) := ('0', NOBR, '1', '1', '1', OP_OR, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- OR = 0011 Flag = 1 Addr =  0011100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011101")))) := ('0', NOBR, '1', '1', '1', OP_OR, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0011111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- XOR = 0100 Flag = 0 Addr = 0100000
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100001")))) := ('0', NOBR, '1', '1', '1', OP_XOR, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- XOR = 0100 Flag = 1 Addr = 0100100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100101")))) := ('0', NOBR, '1', '1', '1', OP_XOR, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0100111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- NOT = 0101 Flag = 0 Addr = 0101000
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101001")))) := ('0', BP_NOT, '1', '1', '1', OP_XOR, '0', READ, ZERO, L_FLAG); -- Fetch Ops (R2 xor 1's)
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- NOT = 0101 Flag = 1 Addr = 0101100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101101")))) := ('0', BP_NOT, '1', '1', '1', OP_XOR, '0', READ, ZERO, L_FLAG); -- Fetch Ops (R2 xor 1's)
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0101111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- MOV = 0110 Flag = 0 Addr = 0110000
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110001")))) := ('0', NOBR, '1', '1', '1', OP_MOVA, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- MOV = 0110 Flag = 1 Addr = 0110100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110101")))) := ('0', NOBR, '1', '1', '1', OP_MOVA, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0110111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- NOP = 0111 Flag = 0 Addr = 0111000
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111001")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- NOP = 0111 Flag = 1 Addr = 0111100
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111101")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("0111111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- LD = 1000 Flag = 0 Addr =  1000000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000001")))) := ('0', NOBR, '0', '1', '0', OP_MOVA, '1', READ, ZERO, L_ADDR); -- Fetch Ops (load Data from Address and latch it)
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000011")))) := ('1', NOBR, '1', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads (load Data to R1 via bypass A)

        -- LD = 1000 Flag = 1 Addr =  1000100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000101")))) := ('0', NOBR, '0', '1', '0', OP_MOVA, '1', READ, ZERO, L_ADDR); -- Fetch Ops (load Data from Address and latch it)
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1000111")))) := ('1', NOBR, '1', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads (load Data to R1 via bypass A)

        -- ST = 1001 Flag = 0 Addr =  1001000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001001")))) := ('0', BP_A, '0', '0', '1', OP_MOVB, '1', READ, ZERO, L_DOUT); -- Fetch Ops (MOVB R2 and output it to Dout
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001011")))) := ('0', NOBR, '0', '1', '0', OP_MOVA, '1', WRITE, ZERO, L_ADDR); -- Latch Reads

        -- ST = 1001 Flag = 1 Addr =  1001100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001101")))) := ('0', BP_A, '0', '0', '1', OP_MOVB, '1', READ, ZERO, L_DOUT); -- Fetch Ops (MOVB R2 and output it to Dout
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1001111")))) := ('0', NOBR, '0', '1', '0', OP_MOVA, '1', WRITE, ZERO, L_ADDR); -- Latch Reads

        -- LDI = 1010 Flag = 0 Addr = 1010000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010001")))) := ('0', BP_A, '1', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- LDI = 1010 Flag = 1 Addr = 1010100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010101")))) := ('0', BP_A, '1', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1010111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- Not Used = 1011 Flag = 0 Addr = 1011000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011001")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011010")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- Not Used = 1011 Flag = 1 Addr = 1011100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011101")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011110")))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1011111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRZ = 1100 Flag = 0 Addr = 1100000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100001")))) := ('0', BP_B, '1', '0', '0', OP_INCR, '0', READ, ZERO, NONE); -- Fetch Ops -- PC is stored at last RF address (use Bypass B to access it)
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100010")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRZ = 1100 Flag = 1 Addr = 1100100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100101")))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100110")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1100111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRN = 1101 Flag = 0 Addr = 1101000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101001")))) := ('0', BP_B, '1', '0', '0', OP_INCR, '0', READ, ZERO, NONE); -- Fetch Ops -- PC is stored at last RF address (use Bypass B to access it)
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101010")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRN = 1101 Flag = 1 Addr = 1101100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101101")))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101110")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1101111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRO = 1110 Flag = 0 Addr = 1110000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110001")))) := ('0', BP_B, '1', '0', '0', OP_INCR, '0', READ, ZERO, NONE); -- Fetch Ops -- PC is stored at last RF address (use Bypass B to access it)
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110010")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRO = 1110 Flag = 1 Addr = 1110100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110101")))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110110")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1110111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRA = 1111 Flag = 0 Addr = 1111000
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111000")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111001")))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111010")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111011")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRA = 1111 Flag = 1 Addr = 1111100
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111100")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111101")))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111110")))) := ('0', BP_B, '0', '0', '0', OP_MOVB, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(to_std_logic_vector("1111111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, NONE); -- Latch Reads

        -- TODO: add control words signals for initialization of the memory
        -- CONTROL Addr = 1111111
        --ROM_content(to_integer(unsigned(to_std_logic_vector("1111111")))) := ('0', NOBR, '0', '0', '0', OP_MOVA, '0', READ, ZERO, L_IR); -- Load Instruction

        return ROM_content;
    end function;

    -- create a good uInstr mapping to enabling signals
    constant memory : uMemory := init_ROM;
begin

    decode : process(opcode, flag, uPC)
        variable address : STD_LOGIC_VECTOR(6 downto 0);
    begin
        address := opcode & flag & uPC;
        uInstr <= memory(to_integer(unsigned(address)));
    end process;
end structural;
