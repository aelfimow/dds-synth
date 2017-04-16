library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity main is

    generic (RST_ACTIVE: std_logic := '0');

    port (
        CLK_I: in std_logic;
        RST_I: in std_logic;
        PHASE_INCREMENT_I: in std_logic_vector(15 downto 0);
        ADDR_O: out std_logic_vector(15 downto 0);
        LATCH_CP_O: out std_logic;
        LATCH_OE_O: out std_logic);

end entity main;

architecture ArchMain of main is

    -- States for local state machine
    type STATE_TYPE is (
        RESET_STATE,
        LATCH_ADDR_STATE,
        WAIT_STATE_0,
        WAIT_STATE_1,
        WAIT_STATE_2,
        WAIT_STATE_3,
        LATCH_DATA_STATE);

    -- States of the local state machine
    signal STATE: STATE_TYPE;
    signal NEW_STATE: STATE_TYPE;

    -- Local signals
    signal CLK: std_logic;
    signal RST: std_logic;
    signal RST_SYNC_A: std_logic;
    signal RST_SYNC_B: std_logic;
    signal RST_SYNC: std_logic;

    -- Phase accumulator related signals
    signal PHASE_INCREMENT: std_logic_vector(15 downto 0);
    signal PHASE_ACC: std_logic_vector(15 downto 0);
    signal TMP_PHASE_SUM: std_logic_vector(15 downto 0);
    signal PHASE_ACC_ENABLE: std_logic;

    -- Control signals for external latch
    signal LATCH_OE: std_logic;
    signal LATCH_CP: std_logic;

begin

    -- Input/output block
    IN_OUT_BLOCK: block
    begin
        CLK <= CLK_I;
        RST <= RST_I;
        LATCH_CP_O <= LATCH_CP;
        LATCH_OE_O <= LATCH_OE;
        ADDR_O <= PHASE_ACC;
        PHASE_INCREMENT <= PHASE_INCREMENT_I;
    end block IN_OUT_BLOCK;

    -- This process generates/synchronizes reset signal RST_SYNC
    RESET_SYNC_PROCESS: process(CLK)
    begin
        if rising_edge(CLK) then
            RST_SYNC_A <= RST;
            RST_SYNC_B <= RST_SYNC_A;
            RST_SYNC <= RST_SYNC_B;
        end if;
    end process RESET_SYNC_PROCESS;

    -- This process computes temporary phase sum
    PHASE_SUM_PROCESS: process(PHASE_ACC, PHASE_INCREMENT)
    begin
        TMP_PHASE_SUM <= PHASE_ACC + PHASE_INCREMENT;
    end process PHASE_SUM_PROCESS;

    -- Save temporary sum in the register PHASE_ACC
    PHASE_ACC_PROCESS: process(CLK)
    begin
        if rising_edge(CLK) then
            if RST_SYNC = RST_ACTIVE then
                PHASE_ACC <= (others => '0');
            elsif PHASE_ACC_ENABLE = '1' then
                PHASE_ACC <= TMP_PHASE_SUM;
            else
                PHASE_ACC <= PHASE_ACC;
            end if;
        end if;
    end process PHASE_ACC_PROCESS;

    -- This process implements input logic of the state machine
    INPUT_LOGIC_PROCESS: process(STATE)
    begin
        case STATE is
            when RESET_STATE =>
                NEW_STATE <= LATCH_ADDR_STATE;
            when LATCH_ADDR_STATE =>
                NEW_STATE <= WAIT_STATE_0;
            when WAIT_STATE_0 =>
                NEW_STATE <= WAIT_STATE_1;
            when WAIT_STATE_1 =>
                NEW_STATE <= WAIT_STATE_2;
            when WAIT_STATE_2 =>
                NEW_STATE <= WAIT_STATE_3;
            when WAIT_STATE_3 =>
                NEW_STATE <= LATCH_DATA_STATE;
            when LATCH_DATA_STATE =>
                NEW_STATE <= LATCH_ADDR_STATE;
            when others =>
                NEW_STATE <= RESET_STATE;
        end case;
    end process INPUT_LOGIC_PROCESS;

    -- This process implements state transition logic
    STATE_TRANSITION_PROCESS: process(CLK)
    begin
        if rising_edge(CLK) then
            if RST_SYNC = RST_ACTIVE then
                STATE <= RESET_STATE;
            else
                STATE <= NEW_STATE;
            end if;
        end if;
    end process STATE_TRANSITION_PROCESS;

    -- This process implements output logic of the state machine
    OUTPUT_LOGIC_PROCESS: process(STATE)
    begin
        case STATE is
            when RESET_STATE =>
                LATCH_OE <= '1';
                LATCH_CP <= '0';
                PHASE_ACC_ENABLE <= '0';
            when LATCH_ADDR_STATE =>
                LATCH_OE <= '0';
                LATCH_CP <= '0';
                PHASE_ACC_ENABLE <= '1';
            when WAIT_STATE_0 =>
                LATCH_OE <= '0';
                LATCH_CP <= '0';
                PHASE_ACC_ENABLE <= '0';
            when WAIT_STATE_1 =>
                LATCH_OE <= '0';
                LATCH_CP <= '0';
                PHASE_ACC_ENABLE <= '0';
            when WAIT_STATE_2 =>
                LATCH_OE <= '0';
                LATCH_CP <= '0';
                PHASE_ACC_ENABLE <= '0';
            when WAIT_STATE_3 =>
                LATCH_OE <= '0';
                LATCH_CP <= '0';
                PHASE_ACC_ENABLE <= '0';
            when LATCH_DATA_STATE =>
                LATCH_OE <= '0';
                LATCH_CP <= '1';
                PHASE_ACC_ENABLE <= '0';
            when others =>
                LATCH_OE <= '1';
                LATCH_CP <= '0';
                PHASE_ACC_ENABLE <= '0';
        end case;
    end process OUTPUT_LOGIC_PROCESS;

end architecture ArchMain;

