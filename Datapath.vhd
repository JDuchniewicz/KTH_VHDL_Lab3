library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Datapath is
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
          EN        : in STD_LOGIC;
          OP        : in STD_LOGIC_VECTOR(2 downto 0);
          Output    : out STD_LOGIC_VECTOR(N - 1 downto 0);
          Z_Flag    : out STD_LOGIC;
          N_Flag    : out STD_LOGIC;
          O_Flag    : out STD_LOGIC;
          clk       : in STD_ULOGIC;
          rst       : in STD_LOGIC);
end Datapath;

architecture structural of Datapath is
    component RF is
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
    end component;

    component ALU is
        generic (N : INTEGER := 4); -- default value??
        port (OP		: in STD_LOGIC_VECTOR(2 downto 0);
                A		: in STD_LOGIC_VECTOR(N - 1 downto 0);
                B		: in STD_LOGIC_VECTOR(N - 1 downto 0);
                Sum	    : out STD_LOGIC_VECTOR(N - 1 downto 0);
                Z_Flag  : out STD_LOGIC;
                N_Flag  : out STD_LOGIC;
                O_Flag  : out STD_LOGIC;
                en      : IN STD_LOGIC;
                rst     : IN STD_LOGIC);
    end component;

    -- signal connections
    signal s_WD : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_QA : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_QB : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_Sum : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_A_input_f : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_RB_input_f: STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_ReadB_input_f : STD_LOGIC;

begin
    RF_1 : RF generic map(M => M,
                          N => N)
                port map(WD => s_WD,
                         WAddr => WAddr,
                         Write => Write,
                         RA => RA,
                         ReadA => ReadA,
                         RB => s_RB_input_f,
                         ReadB => ReadB,
                         QA => s_QA,
                         QB => s_QB,
                         rst => rst,
                         clk => clk);

    ALU_1 : ALU generic map(N => N)
                port map(OP => OP,
                         A => s_A_input_f,
                         B => s_QB,
                         Sum => s_Sum,
                         Z_Flag => Z_Flag,
                         N_Flag => N_Flag,
                         O_Flag => O_Flag,
                         en => EN,
                         rst => rst);

    proc : process (IE, OE, clk)
    begin
    -- IE
    if IE = '1' then
        s_WD <= Input;
    else
        s_WD <= s_Sum;
    end if;

    -- OE
    if OE = '1' then
        Output <= s_Sum;
    else
        Output <= (others => 'Z');
    end if;

    -- Bypass -- TODO: what about sign extensions? to data and offset
    if Bypass = "11" then -- branch instruction
        -- A
        s_A_input_f <= Offset;

        -- B
        s_RB_input_f <= (others => '1');
        s_ReadB_input_f <= '1';
    elsif Bypass = "10" then
        -- A
        s_A_input_f <= Offset;

        -- B
        s_ReadB_input_f <= readB;
        s_RB_input_f <= s_QB;
    elsif Bypass = "01" then
        -- A
        s_A_input_f <= s_QA;

        -- B
        s_RB_input_f <= (others => '1');
        s_ReadB_input_f <= '1';
    else -- normal case
        s_A_input_f <= s_QA;
        s_ReadB_input_f <= readB;
        s_RB_input_f <= s_QB;
    end if;
    end process;
end structural;
