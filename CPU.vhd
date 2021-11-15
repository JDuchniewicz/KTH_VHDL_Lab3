library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.microcode_instructions.all;
use work.assembly_instructions.all;

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
    component ROM is
        port(opcode : IN OPCODE; -- TODO: do the uInstr LUT in the ROM
             flag   : IN STD_LOGIC;
             uPC    : IN STD_LOGIC_VECTOR(1 downto 0);
             uInstr : OUT uInstruction); -- TODO: tweak size or add more signals?
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
    signal s_DatapathOut    : STD_LOGIC_VECTOR(N - 1 downto 0);

    -- TODO merging code!!!!
    signal s_flag   : STD_LOGIC;
    signal s_uPC    : STD_LOGIC_VECTOR(1 downto 0);
    signal s_IR     : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_IR_op  : STD_LOGIC_VECTOR(3 downto 0);
    signal s_uInstr : uInstruction; -- TODO: tweak if necessary

    type t_fsm_state is (S_ADD, S_SUB, S_AND, S_OR, S_XOR, S_NOT, S_MOV, S_NOP, S_LD, S_ST, S_LDI, S_NA, S_BRZ, S_BRN, S_BRO, S_BRA, S_INVALID);
    signal s_curr_state : t_fsm_state;

    -- connect Datapath
    signal s_Z_Flag : STD_LOGIC;
    signal s_N_Flag : STD_LOGIC;
    signal s_O_Flag : STD_LOGIC;
    signal s_WA          : STD_LOGIC_VECTOR(M - 1 downto 0);
    signal s_RA          : STD_LOGIC_VECTOR(M - 1 downto 0);
    signal s_RB          : STD_LOGIC_VECTOR(M - 1 downto 0);

begin
    ROM1 : ROM port map(opcode => s_IR(N - 1 downto N - 5),
                        flag => s_flag,
                        uPC => s_uPC,
                        uInstr => s_uInstr);

    Datapath1  : Datapath generic map(M => M,
                                    N => N)
                        port map(Input => Din,
                                 Offset => s_IR(11 downto 0), -- TODO: sign extend
                                 Bypass => s_uInstr.bypass, -- TODO should I access it via record fields or bits of vector?
                                 IE => s_uInstr.IE,
                                 WAddr => s_WA,
                                 Write => s_uInstr.WA_en,
                                 RA => s_RA,
                                 ReadA => s_uInstr.RA_en,
                                 RB => s_RB,
                                 ReadB => s_uInstr.RB_en,
                                 OE => s_uInstr.OE,
                                 OP => s_uInstr.ALU,
                                 Output => s_DatapathOut,
                                 Z_Flag => s_Z_Flag,
                                 N_Flag => s_N_Flag,
                                 O_Flag => s_O_Flag,
                                 clk => clk,
                                 rst => rst);

    s_WA <= s_IR(11 downto 9);
    s_RA <= s_IR(8 downto 6);
    s_RB <= s_IR(5 downto 3);
    s_IR_op <= s_IR(N - 1 downto N - 5);
    -- split Din into components depending on the opcode

    state : process (s_IR)
    begin
        case s_IR_op is
            when "0000" => s_curr_state <= S_ADD;
            when "0001" => s_curr_state <= S_SUB;
            when "0010" => s_curr_state <= S_AND;
            when "0011" => s_curr_state <= S_OR;
            when "0100" => s_curr_state <= S_XOR;
            when "0101" => s_curr_state <= S_NOT;
            when "0110" => s_curr_state <= S_MOV;
            when "0111" => s_curr_state <= S_NOP;
            when "1000" => s_curr_state <= S_LD;
            when "1001" => s_curr_state <= S_ST;
            when "1010" => s_curr_state <= S_LDI;
            when "1011" => s_curr_state <= S_NA;
            when "1100" => s_curr_state <= S_BRZ;
            when "1101" => s_curr_state <= S_BRN;
            when "1110" => s_curr_state <= S_BRO;
            when "1111" => s_curr_state <= S_BRA;
            when others => s_curr_state <= S_INVALID;
        end case;
    end process;

    registers : process(clk, rst, s_uInstr)
    begin
        if rst = '1' then
            s_uInstr <= init_instruction;
            s_uPC <= (others => '0');
            s_IR <= (others => '0');
            s_DatapathOut <= (others => '0');
            RW <= '0';
            address <= (others => '0');
            Dout <= (others => '0');
        elsif rising_edge(clk) then
            -- uPC
            if s_uPC = "11" then
                s_uPC <= "00";
            else
                s_uPC <= std_logic_vector(unsigned(s_uPC) + 1);
            end if;

            RW <= s_uInstr.RW;
            s_IR <= s_IR; -- retain old IR
            case s_uInstr.LE is
                when L_IR => s_IR <= Din;
                when L_FLAG =>
                                case s_curr_state is
                                    when S_BRZ => s_flag <= s_Z_Flag;
                                    when S_BRN => s_flag <= s_N_Flag;
                                    when S_BRO => s_flag <= s_O_Flag;
                                    when others => s_flag <= '0'; -- zero for other instructions?
                                end case;
                when L_ADDR => address <= s_DatapathOut;
                when L_DOUT => Dout <= s_DatapathOut; -- probably need to register them
                when others => Dout <= (others => 'X'); -- TODO what?
            end case;
        else
            -- retain old values?
        end if;
    end process;

end structural;
