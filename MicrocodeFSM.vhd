library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.assembly_instructions.all;

entity MicrocodeFSM is
    generic port(N : INTEGER;
                 K : INTEGER);
    port(clk    : IN STD_LOGIC;
         rst    : IN STD_LOGIC;
         Din    : IN STD_LOGIC_VECTOR(N - 1 downto 0); -- TODO: understand Latch reads controlling Din from slide 6 diagram?
         Z_Flag : IN STD_LOGIC;
         N_Flag : IN STD_LOGIC;
         O_Flag : IN STD_LOGIC;
         WA     : OUT STD_LOGIC_VECTOR(K - 1 downto 0);
         RA     : OUT STD_LOGIC_VECTOR(K - 1 downto 0);
         RB     : OUT STD_LOGIC_VECTOR(K - 1 downto 0);
         uInstr : OUT STD_LOGIC_VECTOR(3 downto 0); -- TODO: tweak size or add more signals?
         RW     : OUT STD_LOGIC);
end MicrocodeFSM;

architecture structural of MicrocodeFSM is
    component ROM is
        port(opcode : IN OPCODE; -- TODO: do the uInstr LUT in the ROM
             flag   : IN STD_LOGIC;
             uPC    : IN STD_LOGIC_VECTOR(1 downto 0);
             uInstr : OUT STD_LOGIC_VECTOR(3 downto 0); -- TODO: tweak size or add more signals?
             RW     : OUT STD_LOGIC);
    end component;

    signal s_opcode : OPCODE;
    signal s_flag   : STD_LOGIC; -- TODO: add mux to select the proper flag
    signal s_uPC    : STD_LOGIC_VECTOR(1 downto 0);
    signal s_IR     : STD_LOGIC_VECTOR(N - 1 downto 0);
    -- TODO: program counter? (in the CPU and propagated from here)

    type t_fsm_state is (S_ADD, S_SUB, S_AND, S_OR, S_XOR, S_NOT, S_MOV, S_NOP, S_LD, S_ST, S_LDI, S_NA, S_BRZ, S_BRN, S_BRO, S_BRA);
    --signal s_next_state : t_fsm_state;
    signal s_curr_state : t_fsm_state;

begin
    ROM1 : ROM port map(opcode => s_opcode,
                        flag => s_flag,
                        uPC => s_uPC,
                        uInstr => uInstr,
                        RW => RW);

    s_opcode <= s_IR(N - 1 downto N - 5);
    s_curr_state <= t_fsm_state(s_opcode);
    -- split Din into components depending on the opcode
    -- progress each operation if uPC is not done yet ?
    proc : process(clk, rst, Din, Z_Flag, N_Flag, O_Flag)
    begin
        if rst = '1' then
            WA <= (others => '0');
            RA <= (others => '0');
            RB <= (others => '0');
            uInstr <= (others => '0');
            RW <= '0';
            s_opcode <= (others => '0');
            s_flag <= '0';
            s_uPC <= (others => '0');
            s_curr_state <= s_curr_state; -- TODO what it should reset to?
            s_IR <= (others => '0');
        elsif rising_edge(clk) then
            if s_uPC = "11" then
                s_uPC <= "00";
            else
                s_uPC <= s_uPC + 1;
            end if;
            s_IR <= Din; -- register the Din TODO: (only enable when uPC is 0)?


        -- ROM will contain all the instructions coded and output it as uInstr which is mapped to a std_vector of signals coming out of this component and documented properly
        end if;
    end process;

    micropipeline : process (s_uPC)
    begin
        -- do general things depending on the uPC
        -- TODO: last uPC  loads the new instruction already

    end process;


end structural;
