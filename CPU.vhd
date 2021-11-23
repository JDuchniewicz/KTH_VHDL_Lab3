library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.microcode_instructions.all;
use work.assembly_instructions.all;

entity CPU is
    generic (M : INTEGER;
             N : INTEGER);
    port (clk     : IN STD_LOGIC;
          reset   : IN STD_LOGIC;
          Din     : IN STD_LOGIC_VECTOR(N - 1 downto 0);
          address : OUT STD_LOGIC_VECTOR(N - 1 downto 0);
          Dout    : OUT STD_LOGIC_VECTOR(N - 1 downto 0);
          RW      : OUT STD_LOGIC);
end CPU;

architecture structural of CPU is
    component ROM is
        port(opcode : IN STD_LOGIC_VECTOR(3 downto 0); -- TODO: do the uInstr LUT in the ROM
             flag   : IN STD_LOGIC;
             uPC    : IN STD_LOGIC_VECTOR(1 downto 0);
             uInstr : OUT uInstruction); -- TODO: tweak size or add more signals?
    end component;

    component Datapath is
        generic (M: INTEGER;
                 N : INTEGER);
        port (Input     : in STD_LOGIC_VECTOR(N - 1 downto 0);
              Offset    : in STD_LOGIC_VECTOR(N - 1 downto 0);
              Bypass    : in STD_LOGIC_VECTOR(2 downto 0); -- bypass A and B
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
    signal s_signExtendedOffset : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_signExtendedData : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_OffsetData : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_RW : STD_LOGIC;
    signal s_dout : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_address : STD_LOGIC_VECTOR(N - 1 downto 0);

    signal s_flag   : STD_LOGIC;
    signal s_uPC    : STD_LOGIC_VECTOR(1 downto 0);
    signal s_IR     : STD_LOGIC_VECTOR(N - 1 downto 0);
    signal s_IR_op  : STD_LOGIC_VECTOR(3 downto 0);
    signal s_uInstr : uInstruction; -- TODO: tweak if necessary

    -- connect Datapath
    signal s_Z_Flag : STD_LOGIC;
    signal s_N_Flag : STD_LOGIC;
    signal s_O_Flag : STD_LOGIC;
    signal s_WA          : STD_LOGIC_VECTOR(M - 1 downto 0); -- TODO: do not understand how to map 3 bit inputs to the M - 1 (8 bits)
    signal s_RA          : STD_LOGIC_VECTOR(M - 1 downto 0);
    signal s_RB          : STD_LOGIC_VECTOR(M - 1 downto 0);

begin
    ROM1 : ROM port map(opcode => s_IR_op, -- current state stores the current opcode
                        flag => s_flag,
                        uPC => s_uPC,
                        uInstr => s_uInstr);

    Datapath1  : Datapath generic map(M => M,
                                    N => N)
                        port map(Input => Din,
                                 Offset => s_OffsetData,
                                 Bypass => s_uInstr.bypass,
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
                                 rst => reset);

    s_signExtendedOffset <= std_logic_vector(resize(signed(s_IR(11 downto 0)), N));
    s_signExtendedData <= std_logic_vector(resize(signed(s_IR(8 downto 0)), N));

    s_WA <= std_logic_vector(resize(unsigned(s_IR(11 downto 9)), M));
    s_RA <= std_logic_vector(resize(unsigned(s_IR(8 downto 6)), M));
    s_RB <= std_logic_vector(resize(unsigned(s_IR(5 downto 3)), M));
    s_IR_op <= Din(N - 1 downto N - 4) when s_uPC /= "11" else s_IR_op; -- NASTY HACK for LD requiring a change in Din during 11 uPC cycle

    RW <= s_RW;
    Dout <= s_dout;
    address <= s_address;

    registers : process(clk, reset, s_uInstr)
    begin
        if reset = '1' then
            --s_uInstr <= init_instruction;
            s_uPC <= (others => '0');
            s_IR <= (others => '0');
            --s_DatapathOut <= (others => '0'); -- this causes latches
            s_RW <= '0';
            s_flag <= '0';
            s_address <= (others => '0');
            s_dout <= (others => '0');
        elsif rising_edge(clk) then
            -- uPC
            if s_uPC = "11" then
                s_uPC <= "00";
            else
                s_uPC <= std_logic_vector(unsigned(s_uPC) + 1);
            end if;

            s_RW <= s_uInstr.RW;
            case s_uInstr.LE is
                when L_IR => s_IR <= Din;
                --when L_FLAG =>
                when L_ADDR => s_address <= s_DatapathOut;
                when L_DOUT => s_dout <= s_DatapathOut; -- probably need to register them
                when others => s_dout <= s_dout; -- TODO what?
            end case;
            --case s_IR_op is
            --    when BRZ => s_flag <= s_Z_Flag;
            --    when BRN => s_flag <= s_N_Flag;
            --    when BRO => s_flag <= s_O_Flag;
            --    when others => s_flag <= '0'; -- zero for other instructions?
            --end case;
        else
            -- retain old values (registers)
            s_uPC <= s_uPC;
            s_IR <= s_IR;
            s_RW <= s_RW;
            s_flag <= s_flag;
            s_address <= s_address;
            s_dout <= s_dout;
        end if;
    end process;

    -- data extension (combi)
    combi : process(s_IR_op, s_signExtendedData, s_signExtendedOffset)
    begin
        -- data extension
        case s_IR_op is
            when LDI => s_OffsetData <= s_signExtendedData;
            when others => s_OffsetData <= s_signExtendedOffset;
        end case;
    end process;

end structural;
