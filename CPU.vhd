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
    component MicrocodeFSM is
        generic port(N : INTEGER);
        port(clk         : IN STD_LOGIC;
             rst         : IN STD_LOGIC;
             Din         : IN STD_LOGIC_VECTOR(N - 1 downto 0);
             Z_Flag      : IN STD_LOGIC;
             N_Flag      : IN STD_LOGIC;
             O_Flag      : IN STD_LOGIC;
             uInstr      : OUT STD_LOGIC_VECTOR(10 downto 0)); -- TODO: tweak size or add more signals?
    end component;

    component Datapath is
        generic (M: INTEGER;
                 N : INTEGER);
        port (Input     : in STD_LOGIC_VECTOR(N - 1 downto 0);
              Offset    : in STD_LOGIC_VECTOR(N - 1 downto 0);
              Bypass    : in STD_LOGIC_VECTOR(1 downto 0); -- bypass A and B
              IE        : in STD_LOGIC;
              WAddr     : in STD_LOGIC_VECTOR(M - 1 downto 0);
              Write     : in STD_LOGIC;
              RA        : in STD_LOGIC_VECTOR(M - 1 downto 0);
              ReadA     : in STD_LOGIC;
              RB        : in STD_LOGIC_VECTOR(M - 1 downto 0);
              ReadB     : in STD_LOGIC;
              OE        : in STD_LOGIC;
              OP        : in STD_LOGIC_VECTOR(2 downto 0);
              Output    : out STD_LOGIC_VECTOR(N - 1 downto 0);
              Z_Flag    : out STD_LOGIC;
              N_Flag    : out STD_LOGIC;
              O_Flag    : out STD_LOGIC;
              clk       : in STD_ULOGIC;
              rst       : in STD_LOGIC);
    end component;

    -- registers for clocked saving (IR and uPC are clocked in FSM)
    signal s_Dout    : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_Address : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_RW      : STD_LOGIC;

begin
    FSM : MicrocodeFSM generic map(N => N)
                       port map (clk => clk,
                                 rst => rst,
                                 Din => Din, -- TODO: should be latched
                                 address);

    Datapath : Datapath generic map(M => M,
                                    N => N)
                        port map(Input => Din,
                                 Offset => ,
                                 Bypass => uInstr(); -- TODO should I access it via record fields or bits of vector?

    execute : process(uInstr)
    begin

    end process;

    registers : process(clk, rst, uInstr)
    begin
        if rst then
            s_Dout <= (others => '0');
            s_Address <= (others => '0');
            s_RW <= '0';
            address <= (others => '0');
            Dout <= (others => '0');
            RW <=
        elsif rising_edge(clk)
            case uInstr(1 downto 0) is
                when L_IR => -- load IR move it from mcu
                when L_FLAG => -- TODO what about flags here? move them from MCU and leave uPC there
                when L_ADDR => address <= s_Address;
                when L_DOUT => Dout <= s_Dout;
            end case;
            s_RW <= uInstr(1 downto 0);
        else
            -- retain old values?
        end if;
    end process;

end structural;
