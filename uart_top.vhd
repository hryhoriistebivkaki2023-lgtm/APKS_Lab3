library ieee;
use ieee.std_logic_1164.all;

entity uart_top is
    generic (
        g_CLKS_PER_BIT : integer := 434
    );
    port (
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_tx_start  : in  std_logic;
        i_tx_byte   : in  std_logic_vector(7 downto 0);
        o_tx_active : out std_logic;
        o_tx_serial : out std_logic;
        o_tx_done   : out std_logic;
        i_rx_serial : in  std_logic;
        o_rx_done   : out std_logic;
        o_rx_byte   : out std_logic_vector(7 downto 0)
    );
end entity uart_top;

architecture structural of uart_top is
begin
    u_tx : entity work.uart_tx
        generic map (g_CLKS_PER_BIT => g_CLKS_PER_BIT)
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_tx_start  => i_tx_start,
            i_tx_byte   => i_tx_byte,
            o_tx_active => o_tx_active,
            o_tx_serial => o_tx_serial,
            o_tx_done   => o_tx_done
        );

    u_rx : entity work.uart_rx
        generic map (g_CLKS_PER_BIT => g_CLKS_PER_BIT)
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_rx_serial => i_rx_serial,
            o_rx_done   => o_rx_done,
            o_rx_byte   => o_rx_byte
        );
end architecture structural;