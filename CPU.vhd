library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CPU is
    generic (M : INTEGER;
             N : INTEGER);
    port (clk     : IN STD_LOGIC;
          rst     : IN STD_LOGIC;
          Din     : IN STD_LOGIC_VECTOR(N - 1 downto 0);
          address : OUT STD_LOGIC_VECTOR(N - 1 downto 0);
          Dout    : OUT STD_LOGIC_VECTOR(N - 1 downto 0);
          RW      : OUT STD_LOGIC);
end CPU;

architecture structural of CPU is

end structural;
