library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tb is
end entity uart_tb;

architecture sim of uart_tb is
    constant c_CLK_PERIOD   : time    := 20 ns;  -- 50 МГц
    constant c_CLKS_PER_BIT : integer := 434;    -- 115200 бод

    signal r_clk       : std_logic := '0';
    signal r_rst       : std_logic := '1';
    signal r_tx_start  : std_logic := '0';
    signal r_tx_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal w_tx_active : std_logic;
    signal w_tx_serial : std_logic;
    signal w_tx_done   : std_logic;
    signal w_rx_done   : std_logic;
    signal w_rx_byte   : std_logic_vector(7 downto 0);
begin
    r_clk <= not r_clk after c_CLK_PERIOD / 2;

    dut : entity work.uart_top
        generic map (
            g_CLKS_PER_BIT => c_CLKS_PER_BIT
        )
        port map (
            i_clk       => r_clk,
            i_rst       => r_rst,
            i_tx_start  => r_tx_start,
            i_tx_byte   => r_tx_byte,
            o_tx_active => w_tx_active,
            o_tx_serial => w_tx_serial,
            o_tx_done   => w_tx_done,
            i_rx_serial => w_tx_serial,
            o_rx_done   => w_rx_done,
            o_rx_byte   => w_rx_byte
        );

    p_stim : process
    begin
        r_rst <= '1';
        wait for 100 ns;
        r_rst <= '0';
        wait for 100 ns;

        -- Тест 1: передача байта 0x55
        wait until rising_edge(r_clk);
        r_tx_byte  <= x"55";
        r_tx_start <= '1';
        wait until rising_edge(r_clk);
        r_tx_start <= '0';

        wait until w_rx_done = '1';
        assert w_rx_byte = x"55"
            report "Error receiving byte 0x55!" severity error;

        wait for 2 us;

        -- Тест 2: передача байта 0xA3
        wait until rising_edge(r_clk);
        r_tx_byte  <= x"A3";
        r_tx_start <= '1';
        wait until rising_edge(r_clk);
        r_tx_start <= '0';

        wait until w_rx_done = '1';
        assert w_rx_byte = x"A3"
            report "Error receiving byte 0xA3!" severity error;

        wait for 2 us;
        report "UART simulation completed successfully!" severity note;
        wait;
    end process p_stim;
end architecture sim;