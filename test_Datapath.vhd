library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_Datapath is

end tb_Datapath;

architecture tb of tb_Datapath is
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

    constant c_M : INTEGER := 3;
    constant c_N : INTEGER := 3;

    signal clk          : STD_ULOGIC := '0';
    signal rst          : STD_LOGIC;
    signal tt_Input     : STD_LOGIC_VECTOR(c_N - 1 downto 0);
    signal tt_Offset    : STD_LOGIC_VECTOR(c_N - 1 downto 0);
    signal tt_Bypass    : STD_LOGIC_VECTOR(1 downto 0);
    signal tt_IE        : STD_LOGIC;
    signal tt_WAddr     : STD_LOGIC_VECTOR(c_M - 1 downto 0);
    signal tt_Write     : STD_LOGIC;
    signal tt_RA        : STD_LOGIC_VECTOR(c_M - 1 downto 0);
    signal tt_ReadA     : STD_LOGIC;
    signal tt_RB        : STD_LOGIC_VECTOR(c_M - 1 downto 0);
    signal tt_ReadB     : STD_LOGIC;
    signal tt_OE        : STD_LOGIC;
    signal tt_OP        : STD_LOGIC_VECTOR(2 downto 0);
    signal tt_Output    : STD_LOGIC_VECTOR(c_N - 1 downto 0);
    signal tt_Z_Flag    : STD_LOGIC;
    signal tt_N_Flag    : STD_LOGIC;
    signal tt_O_Flag    : STD_LOGIC;

    shared variable sv_expected_output : STD_LOGIC_VECTOR(c_N - 1 downto 0);
begin
    DUT_Datapath : Datapath generic map(M => c_M,
                                        N => c_N)
                            port map(Input => tt_Input,
                                     Offset => tt_Offset,
                                     Bypass => tt_Bypass,
                                     IE => tt_IE,
                                     WAddr => tt_WAddr,
                                     Write => tt_Write,
                                     RA => tt_RA,
                                     ReadA => tt_ReadA,
                                     RB => tt_RB,
                                     ReadB => tt_ReadB,
                                     OE => tt_OE,
                                     OP => tt_OP,
                                     Output => tt_Output,
                                     Z_Flag => tt_Z_Flag,
                                     N_Flag => tt_N_Flag,
                                     O_Flag => tt_O_Flag,
                                     clk => clk,
                                     rst => rst);

    clk <= not clk after 5 ns;

    monitor : process(tt_Output)
    begin
        if tt_Output /= sv_expected_output then
            assert false
            report "Wrong data on Output = " & integer'image(to_integer(signed(tt_Output))) & " expected = " & integer'image(to_integer(signed(sv_expected_output))) -- signed?
            severity error;
        end if;
    end process;

    generator : process
    begin

    rst <= '1';
    tt_IE <= '0';
    tt_OE <= '0';
    sv_expected_output := "ZZZ";
    wait for 10 ns;

    rst <= '0';

    -- store 1 at address 001
    tt_OP <= "110";
    tt_Bypass <= "00"; -- no bypassing whatsoever
    tt_WAddr <= std_logic_vector(to_unsigned(1, tt_WAddr'length));
    tt_Input <= std_logic_vector(to_unsigned(1, tt_Input'length));
    tt_Write <= '1';
    tt_IE <= '1'; -- select data from Input
    wait for 10 ns;

    -- store 1 at address 002
    tt_WAddr <= std_logic_vector(to_unsigned(2, tt_WAddr'length));
    wait for 10 ns;


    -- kickstart the addition
    tt_OP <= "000";
    tt_WAddr <= std_logic_vector(to_unsigned(1, tt_WAddr'length));
    --tt_Write <= '0'; -- do not write yet!, 1 cycle latency for the data to propagate to ALU
    tt_OE <= '0';
    -- load the 1's to ALU
    tt_RA <= std_logic_vector(to_unsigned(1, tt_RA'length));
    tt_ReadA <= '1';
    tt_RB <= std_logic_vector(to_unsigned(2, tt_RB'length));
    tt_ReadB <= '1';
    wait for 10 ns; -- still 'ZZZ' on the output since OE is 0

    -- 2 cycle operation due to RF write/op latency
    for i in 2 to 7 loop
        tt_OE <= '1'; -- now the results will be good to write to the RF
        tt_IE <= '0'; -- read only data from ALU
        tt_Write <= '1';
        sv_expected_output := std_logic_vector(to_unsigned(i, sv_expected_output'length));
        wait for 20 ns; -- while it waits here next operation propagates
    end loop;

    -- check if overflowed
    sv_expected_output := std_logic_vector(to_unsigned(0, sv_expected_output'length));
    wait for 10 ns;

    -- store the PC in last register
    -- MOV
    tt_OP <= "110";
    tt_WAddr <= (others => '1');
    tt_Input <= "010";
    tt_Write <= '1';
    tt_IE <= '1';
    wait for 20 ns;
    -- store in second to last
    tt_Input <= "111";
    tt_WAddr <= "110";
    wait for 20 ns;

    -- test Bypass operation
    tt_OP <= "110"; -- MOV
    tt_Bypass <= "10";
    tt_Offset <= "111";
    wait for 10 ns; -- just one cycle here as we bypass the RF
    sv_expected_output := "111";
    wait for 10 ns;

    tt_WAddr <= "011"; -- redirect the result data from ALU somewhere
    tt_OP <= "010"; -- AND
    tt_Bypass <= "11";
    wait for 10 ns;
    sv_expected_output := "010"; -- have to wait, because it takes time to compute the expected result
    wait for 10 ns;

    tt_Bypass <= "01";
    tt_RA <= "010";
    wait for 10 ns;
    sv_expected_output := "010"; -- PC contains 010

    end process;
end tb;

