library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package assembly_instructions is
    -- mapping from raw bits to testbench types
    subtype opcode is STD_LOGIC_VECTOR(3 downto 0); -- 4 upper bits of the instruction
    subtype reg_code is STD_LOGIC_VECTOR(2 downto 0); -- 3-bit Registers
    subtype immediate is STD_LOGIC_VECTOR(8 downto 0); -- 9-bit Data
    subtype offset is STD_LOGIC_VECTOR(11 downto 0); -- 12-bit offset
    -- because we have multiple different encodings we will store it as a vector of bits
    subtype instruction is STD_LOGIC_VECTOR(15 downto 0);
    type program is array(natural range<>) of instruction;

    -- constants to code the ops because VHDL is VERY picky for type correctness
    constant ADD : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    constant iSUB : STD_LOGIC_VECTOR(3 downto 0) := "0001";
    constant iAND : STD_LOGIC_VECTOR(3 downto 0) := "0010";
    constant iOR : STD_LOGIC_VECTOR(3 downto 0) := "0011";
    constant iXOR : STD_LOGIC_VECTOR(3 downto 0) := "0100";
    constant iNOT : STD_LOGIC_VECTOR(3 downto 0) := "0101";
    constant MOV : STD_LOGIC_VECTOR(3 downto 0) := "0110";
    constant NOP : STD_LOGIC_VECTOR(3 downto 0) := "0111";
    constant LD : STD_LOGIC_VECTOR(3 downto 0) := "1000";
    constant ST : STD_LOGIC_VECTOR(3 downto 0) := "1001";
    constant LDI : STD_LOGIC_VECTOR(3 downto 0) := "1010";
    constant NA : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    constant BRZ : STD_LOGIC_VECTOR(3 downto 0) := "1100";
    constant BRN : STD_LOGIC_VECTOR(3 downto 0) := "1101";
    constant BRO : STD_LOGIC_VECTOR(3 downto 0) := "1110";
    constant BRA : STD_LOGIC_VECTOR(3 downto 0) := "1111";

    -- constants for instructions for test to compile
    constant Tail3 : STD_LOGIC_VECTOR(2 downto 0) := "000";
    -- register constants (stored in the CPU memory)
    constant R0 : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant R1 : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant R2 : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant R3 : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant R4 : STD_LOGIC_VECTOR(2 downto 0) := "100";
    constant R5 : STD_LOGIC_VECTOR(2 downto 0) := "101";
    constant R6 : STD_LOGIC_VECTOR(2 downto 0) := "110";
end assembly_instructions;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package microcode_instructions is
    -- all Datapath and PC/Address control signals here
    --subtype nop is STD_LOGIC; -- 0 => valid instruction, 1 => NOP, ignore all bits
    --subtype alu_op is STD_LOGIC_VECTOR(2 downto 0); -- op to choose at ALU
    --subtype latch_flag is STD_LOGIC; -- 0 => don't latch the flag, 1 => latch it
    --subtype addr_r is STD_LOGIC; -- 0 => addr = r1, 1 => addr = r2
    --subtype addr_pc is STD_LOGIC; -- 0 => address = pc, 1 => address = pc + 1
    --subtype pc_op is STD_LOGIC; -- 0 => pc = pc + 1, 1 -> pc = pc + sign-extended offset
    --subtype dout_r2 is STD_LOGIC; -- 0 => NOP, 1 => Dout = R2
    --subtype load_r1 is STD_LOGIC; -- 0 => r1 = data, 1 => r1 = sign-extended data
    --subtype r_w is STD_LOGIC; -- 0 => W, 1 => R

    --type uInstruction is STD_LOGIC_VECTOR(10 downto 0); -- 11 bits
    --type memory is array(natural range<>) of uInstruction;

    -- the instructions are passed immediately to the Datapath
    subtype alu_opcode is STD_LOGIC_VECTOR(2 downto 0);
    type uInstruction is record
        IE : STD_LOGIC;
        bypass : STD_LOGIC_VECTOR(1 downto 0); -- could be extended?
        WA_en : STD_LOGIC;
        RA_en : STD_LOGIC;
        RB_en : STD_LOGIC;
        ALU : ALU_OPCODE;
        OE : STD_LOGIC;
        RW : STD_LOGIC;
        SEL : STD_LOGIC_VECTOR(1 downto 0); -- select the flag??
        LE : STD_LOGIC_VECTOR(2 downto 0); -- enable the output register (data or Address)
    end record;
    type uMemory is array (natural range<>) of uInstruction;

    -- constants for easier code understanding
    constant NOBR  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant BP_A  : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant BP_B  : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant BP_AB : STD_LOGIC_VECTOR(1 downto 0) := "11";

    constant OP_ADD : ALU_OPCODE := "000";
    constant OP_SUB : ALU_OPCODE := "001";
    constant OP_AND : ALU_OPCODE := "010";
    constant OP_OR  : ALU_OPCODE := "011";
    constant OP_XOR : ALU_OPCODE := "100";
    constant OP_INCR : ALU_OPCODE := "101";
    constant OP_MOVA : ALU_OPCODE := "110";
    constant OP_MOVB : ALU_OPCODE := "111";

    constant READ  : STD_LOGIC := '1';
    constant WRITE : STD_LOGIC := '0';

    constant ZERO     : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant NEGATIVE : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant OVERFLOW : STD_LOGIC_VECTOR(1 downto 0) := "10";

    constant NONE  : STD_LOGIC_VECTOR(2 downto 0) := "000"; -- various load enable signals to trigger
    constant L_IR  : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant L_FLAG : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant L_ADDR : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant L_DOUT : STD_LOGIC_VECTOR(2 downto 0) := "100";

    constant init_instruction : uInstruction := (IE => '0', bypass => (others => '0'), WA_en => '0', RA_en => '0', RB_en => '0',
                                                 ALU => (others => '0'), OE => '0', RW => '0', SEL => (others => '0'), LE => (others => '0'));

end microcode_instructions;
