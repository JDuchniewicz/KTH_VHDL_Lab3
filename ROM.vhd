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
                                                    -- IE, bypass, WA_en, RA_en, RB_en, ALU, OE, RW, Flag, LE
        ROM_content(to_integer(unsigned(0000000))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ, ZERO, L_IR); -- Load Instruction TODO: fix ALU to have good ops at least in this Lab
        ROM_content(to_integer(unsigned(0000001))) := ('0', NOBR, '1', '1', '1', OP_ADD, '0', READ, ZERO, L_FLAG); -- Fetch Ops (TODO: I do not understand how to use L_Flag?)
        ROM_content(to_integer(unsigned(0000010))) := ('0', BP_B, '1', '1', '0', OP_INCR, '1', READ. ZERO, L_ADDR); -- Execute
        ROM_content(to_integer(unsigned(0000011))) := ('0', NOBR, '0', '0', '0', OP_MOV, '0', READ. ZERO, NONE); -- Latch Reads

        -- SUB = 0001 Flag = 0 Addr = 0001000
        ROM_content(to_integer(unsigned(0001000))) := (); -- Load Instruction
        ROM_content(to_integer(unsigned(0001001))) := (); -- Fetch Ops
        ROM_content(to_integer(unsigned(0001010))) := (); -- Execute
        ROM_content(to_integer(unsigned(0001011))) := (); -- Latch Reads

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
