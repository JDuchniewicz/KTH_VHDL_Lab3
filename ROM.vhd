library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.assembly_instructions.all;
use work.microcode_instructions.all;

-- this is just the ROM part of microcode which contains all the necessary translations
entity ROM is
    port(opcode : IN OPCODE;
         flag   : IN STD_LOGIC;
         uPC    : IN STD_LOGIC_VECTOR(1 downto 0);
         uInstr : OUT uInstruction;
end ROM;

architecture structural of ROM is
    -- address is opcode+flag+uPC so they flow easily
    -- function to initialize ROM
    constant ROM_size : NATURAL := 2 ** 7;
    function init_ROM return uMemory is
        variable ROM_content : uMemory;
    begin
        -- zero out the ROM
        for i in 0 to ROM_size - 1 loop
            ROM_content(i) := (others => '0');
        end loop;

    -- add functions
        -- ADD = 0000 Flag = 0 Addr = 0000000
                                                    -- IE, bypass, WA_en, RA_en, RB_en, ALU, OE, RW, Flag, LE (TODO: maybe move the latching of registers to outer MCU instead of the FSM)
        ROM_content(to_integer(unsigned(0000000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction TODO: fix ALU to have good ops at least in this Lab
        ROM_content(to_integer(unsigned(0000001))) := ('0', NOBR, '1', '1', '1', OP_ADD, '0', READ, ZERO, L_FLAG); -- Fetch Ops (TODO: I do not understand how to use L_Flag?) (latch flag, but should I also store the value in output?
        ROM_content(to_integer(unsigned(0000010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0000011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads
        --TODO how to use IE flag here? it loads the data to memory

        -- SUB = 0001 Flag = 0 Addr = 0001000
        ROM_content(to_integer(unsigned(0001000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(0001001))) := ('0', NOBR, '1', '1', '1', OP_SUB, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(0001010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0001011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- AND = 0010 Flag = 0 Addr = 0010000
        ROM_content(to_integer(unsigned(0010000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(0010001))) := ('0', NOBR, '1', '1', '1', OP_AND, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(0010010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0010011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- OR = 0011 Flag = 0 Addr =  0011000
        ROM_content(to_integer(unsigned(0011000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(0011001))) := ('0', NOBR, '1', '1', '1', OP_OR, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(0011010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0011011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- XOR = 0100 Flag = 0 Addr = 0100000
        ROM_content(to_integer(unsigned(0100000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(0100001))) := ('0', NOBR, '1', '1', '1', OP_XOR, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(0100010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0100011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- NOT = 0101 Flag = 0 Addr = 0101000 (TODO: is this present after we fix the ALU?)
        ROM_content(to_integer(unsigned(0101000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(0101001))) := ('0', NOBR, '1', '1', ' OP_MOV0', OP_NOT, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(0101010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0101011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- MOV = 0110 Flag = 0 Addr = 0110000 (TODO: this requires MOVB operation)
        ROM_content(to_integer(unsigned(0110000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(0110001))) := ('0', NOBR, '1', '1', '1', OP_MOV, '0', READ, ZERO, L_FLAG); -- Fetch Ops
        ROM_content(to_integer(unsigned(0110010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0110011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- NOP = 0111 Flag = 0 Addr = 0111000
        ROM_content(to_integer(unsigned(0111000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(0111001))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(0111010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0111011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- LD = 1000 Flag = 0 Addr =  1000000
        ROM_content(to_integer(unsigned(1000000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1000001))) := ('0', NOBR, '0', '0', '1', OP_MOV, '1', READ, ZERO, L_ADDR); -- Fetch Ops (load Data from Address and latch it) -- do the microop translation to ALU instr in the MCU
        ROM_content(to_integer(unsigned(1000010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1000011))) := ('0', BP_A, '1', '1', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads (load Data to R1 via bypass A)

        -- ST = 1001 Flag = 0 Addr =  1001000
        ROM_content(to_integer(unsigned(1001000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1001001))) := ('0', BP_A, '0', '0', '1', OP_MOV, '1', READ, ZERO, L_DOUT); -- Fetch Ops (load content at  TODO: Force 0 on A??
        ROM_content(to_integer(unsigned(1001010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1001011))) := ('0', NOBR, '0', '1', '0', OP_MOV, '1', WRITE, ZERO, L_ADDR); -- Latch Reads

        -- LDI = 1010 Flag = 0 Addr = 1010000
        ROM_content(to_integer(unsigned(1010000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1010001))) := ('0', BP_A, '1', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(1010010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1010011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- NOP = 1011 Flag = 0 Addr = 1011000
        ROM_content(to_integer(unsigned(1011000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1011001))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(1011010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1011011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRZ = 1011 Flag = 0 Addr = 1011000
        ROM_content(to_integer(unsigned(1011000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1011001))) := ('0', BP_B, '1', '0', '0', OP_INCR, '0', READ, ZERO, NONE); -- Fetch Ops -- PC is stored at last RF address (use Bypass B to access it)
        ROM_content(to_integer(unsigned(1011010))) := ('0', BP_B, '1', '1', '0', OP_MOV, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1011011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRZ = 1011 Flag = 1 Addr = 1011100
        ROM_content(to_integer(unsigned(1011100))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1011101))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(1011110))) := ('0', BP_B, '1', '1', '0', OP_MOV, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1011111))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRN = 1100 Flag = 0 Addr = 1100000
        ROM_content(to_integer(unsigned(1100000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1100001))) := ('0', BP_B, '1', '0', '0', OP_INCR, '0', READ, ZERO, NONE); -- Fetch Ops -- PC is stored at last RF address (use Bypass B to access it)
        ROM_content(to_integer(unsigned(1100010))) := ('0', BP_B, '1', '1', '0', OP_MOV, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1100011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRN = 1100 Flag = 1 Addr = 1100100
        ROM_content(to_integer(unsigned(1100100))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1100101))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(1100110))) := ('0', BP_B, '1', '1', '0', OP_MOV, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1100111))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRO = 1101 Flag = 0 Addr = 1101000
        ROM_content(to_integer(unsigned(1101000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1101001))) := ('0', BP_B, '1', '0', '0', OP_INCR, '0', READ, ZERO, NONE); -- Fetch Ops -- PC is stored at last RF address (use Bypass B to access it)
        ROM_content(to_integer(unsigned(1101010))) := ('0', BP_B, '1', '1', '0', OP_MOV, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1101011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRO = 1101 Flag = 1 Addr = 1101100
        ROM_content(to_integer(unsigned(1101100))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1101101))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(1101110))) := ('0', BP_B, '1', '1', '0', OP_MOV, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1101111))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- BRA = 1110 Flag = 0 Addr = 1110000
        ROM_content(to_integer(unsigned(1110000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction
        ROM_content(to_integer(unsigned(1110001))) := ('0', BP_AB, '1', '0', '0', OP_ADD, '0', READ, ZERO, NONE); -- Fetch Ops
        ROM_content(to_integer(unsigned(1110010))) := ('0', BP_B, '1', '1', '0', OP_MOV, '1', READ, ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(1110011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, NONE); -- Latch Reads

        -- TODO: add control words signals for initialization of the memory
        return ROM_content;
    end function;

    -- create a good uInstr mapping to enabling signals
    constant memory : uMemory := init_ROM;
begin

    decode : process(opcode, flag, uPC)
    begin
        uInstr <= memory(to_integer(unsigned(opcode & flag & uPC)));
    end process;
end structural;
