library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.assembly_instructions.all;

entity MicrocodeFSM is
    generic port(N : INTEGER;
                 K : INTEGER);
    port(clk         : IN STD_LOGIC;
         rst         : IN STD_LOGIC;
         Din         : IN STD_LOGIC_VECTOR(N - 1 downto 0);
         Z_Flag      : IN STD_LOGIC;
         N_Flag      : IN STD_LOGIC;
         O_Flag      : IN STD_LOGIC;
         WA          : OUT STD_LOGIC_VECTOR(K - 1 downto 0);
         RA          : OUT STD_LOGIC_VECTOR(K - 1 downto 0);
         RB          : OUT STD_LOGIC_VECTOR(K - 1 downto 0);
         Data_offset : OUT STD_LOGIC_VECTOR(N - K - 1 downto 0); -- TODO: manage Address and PC in the upper block (know from the uInst what to do here)
         uInstr      : OUT STD_LOGIC_VECTOR(10 downto 0)); -- TODO: tweak size or add more signals?
end MicrocodeFSM;

architecture structural of MicrocodeFSM is
    component ROM is
        port(opcode : IN OPCODE; -- TODO: do the uInstr LUT in the ROM
             flag   : IN STD_LOGIC;
             uPC    : IN STD_LOGIC_VECTOR(1 downto 0);
             uInstr : OUT STD_LOGIC_VECTOR(10 downto 0)); -- TODO: tweak size or add more signals?
    end component;

    signal s_opcode : OPCODE;
    signal s_flag   : STD_LOGIC;
    signal s_uPC    : STD_LOGIC_VECTOR(1 downto 0);
    signal s_IR     : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_IR_enable : STD_LOGIC;

    type t_fsm_state is (S_ADD, S_SUB, S_AND, S_OR, S_XOR, S_NOT, S_MOV, S_NOP, S_LD, S_ST, S_LDI, S_NA, S_BRZ, S_BRN, S_BRO, S_BRA);
    --signal s_next_state : t_fsm_state;
    signal s_curr_state : t_fsm_state;

begin
    ROM1 : ROM port map(opcode => s_opcode,
                        flag => s_flag,
                        uPC => s_uPC,
                        uInstr => uInstr);

    s_opcode <= s_IR(N - 1 downto N - 5);
    s_curr_state <= t_fsm_state(s_opcode); -- debug?? TODO: print state name in Modelsim

    WA <= s_IR(11 downto 9);
    RA <= s_IR(8 downto 6);
    RB <= s_IR(5 downto 3);
    Data_offset <= s_IR(11 downto 0); -- TODO sign extend?
    -- split Din into components depending on the opcode
    proc : process(clk, rst, Din, Z_Flag, N_Flag, O_Flag)
    begin
        if rst = '1' then
            WA <= (others => '0');
            RA <= (others => '0');
            RB <= (others => '0');
            uInstr <= (others => '0');
            s_opcode <= (others => '0');
            s_flag <= '0';
            s_uPC <= (others => '0');
            s_IR <= (others => '0');
            s_IR_enable <= '0';
        elsif rising_edge(clk) then
            if s_uPC = "11" then
                s_uPC <= "00";
                s_IR_enable <= '1';
            else
                s_uPC <= s_uPC + 1;
                s_IR_enable <= '0';
            end if;
            -- load the IR register
            if s_IR_enable = '1' then
                s_IR <= Din; -- register the Din TODO: (only enable when uPC is 0)?
            else
                s_IR <= s_IR;
            end if;
        -- ROM will contain all the instructions coded and output it as uInstr which is mapped to a std_vector of signals coming out of this component and documented properly
        end if;
    end process;

    -- control the s_flag depending on current state
    flags : process (s_curr_state)
    begin
        case s_curr_state is
            when S_BRZ => s_flag <= Z_Flag;
            when S_BRN => s_flag <= N_Flag;
            when S_BRO => s_flag <= O_Flag;
            when others => s_flag <= '0'; -- zero for other instructions?
        end case;
    end process;

end structural;
