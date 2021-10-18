library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.assembly_instructions.all;

-- this is just the ROM part of microcode which contains all the necessary translations
entity ROM is
    port(opcode : IN OPCODE;
         flag   : IN STD_LOGIC;
         uPC    : IN STD_LOGIC_VECTOR(1 downto 0);
         uInstr : OUT STD_LOGIC_VECTOR(3 downto 0); -- TODO: tweak size or add more signals?
         RW     : OUT STD_LOGIC);
end ROM;

architecture structural of ROM is

begin


end structural;
