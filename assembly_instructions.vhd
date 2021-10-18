library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package assembly_instructions is
    subtype opcode is STD_LOGIC_VECTOR(3 downto 0); -- 4 upper bits of the instruction
    subtype reg_code is STD_LOGIC_VECTOR(2 downto 0); -- 3-bit Registers
    subtype immediate is STD_LOGIC_VECTOR(8 downto 0); -- 9-bit Data
    subtype offset is STD_LOGIC_VECTOR(11 downto 0); -- 12-bit offset
    -- because we have multiple different encodings we will store it as a vector of bits
    type instruction is STD_LOGIC_VECTOR(15 downto 0);
    type program is array(natural range<>) of instruction;
end assembly_instructions;
