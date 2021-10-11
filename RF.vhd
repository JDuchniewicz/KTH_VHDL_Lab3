library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RF is
    generic (M : INTEGER;
             N : INTEGER);
    port (WD        : in STD_LOGIC_VECTOR(N - 1 downto 0);
          WAddr     : in STD_LOGIC_VECTOR(M - 1 downto 0);
          Write     : in STD_LOGIC;
          RA        : in STD_LOGIC_VECTOR(M - 1 downto 0);
          ReadA     : in STD_LOGIC;
          RB        : in STD_LOGIC_VECTOR(M - 1 downto 0);
          ReadB     : in STD_LOGIC;
          QA        : out STD_LOGIC_VECTOR(N - 1 downto 0);
          QB        : out STD_LOGIC_VECTOR(N - 1 downto 0);
          rst       : in STD_LOGIC;
          clk       : in STD_ULOGIC);
end RF;

architecture data_flow of RF is
    -- memory to hold the data
    subtype t_word is STD_LOGIC_VECTOR(N - 1 downto 0);
    type t_memory is array (0 to 2 ** M - 1) of t_word;
    signal mem  : t_memory;
begin
    proc : process (WD, WAddr, Write, RA, ReadA, RB, ReadB, rst, clk)
    begin
    if rst = '1' then
        QA <= (others => '0');
        QB <= (others => '0');
        mem <= (others => (others => '0')); -- reset the memory contents
    else
        -- write 1 on rising_edge and read 2 async
        if rising_edge(clk) then
            if Write = '1' then
                mem(to_integer(unsigned(WAddr))) <= WD;
            end if;
        end if;

        if ReadA = '1' then
            QA <= mem(to_integer(unsigned(RA)));
        else
            QA <= (others => '0');
        end if;

        if ReadB = '1' then
            QB <= mem(to_integer(unsigned(RB)));
        else
            QB <= (others => '0');
        end if;
    end if;
    end process;
end data_flow;
