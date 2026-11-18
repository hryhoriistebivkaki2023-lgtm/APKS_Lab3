library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        -- Коефіцієнт ділення частоти: 50 МГц / 115200 бод = 434 такти на біт
        g_CLKS_PER_BIT : integer := 434
    );
    port (
        i_clk       : in  std_logic;                      -- Тактовий сигнал (50 МГц)
        i_rst       : in  std_logic;                      -- Синхронне скидання (активний '1')
        i_tx_start  : in  std_logic;                      -- Строб запуску передачі байта
        i_tx_byte   : in  std_logic_vector(7 downto 0);   -- Байт даних для передачі
        o_tx_active : out std_logic;                      -- Прапорець активної передачі
        o_tx_serial : out std_logic;                      -- Послідовний вихід TxD
        o_tx_done   : out std_logic                       -- Імпульс завершення передачі
    );
end entity uart_tx;

architecture rtl of uart_tx is
    type t_tx_state is (s_IDLE, s_START_BIT, s_DATA_BITS, s_STOP_BIT, s_CLEANUP);
    signal r_state   : t_tx_state := s_IDLE;
    signal r_clk_cnt : integer range 0 to g_CLKS_PER_BIT - 1 := 0;
    signal r_bit_idx : integer range 0 to 7 := 0;
    signal r_tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal r_tx_done : std_logic := '0';
begin
    p_uart_tx : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_state     <= s_IDLE;
                o_tx_serial <= '1';
                o_tx_active <= '0';
                r_tx_done   <= '0';
                r_clk_cnt   <= 0;
                r_bit_idx   <= 0;
            else
                case r_state is
                    when s_IDLE =>
                        o_tx_serial <= '1';
                        r_tx_done   <= '0';
                        r_clk_cnt   <= 0;
                        r_bit_idx   <= 0;
                        if i_tx_start = '1' then
                            o_tx_active <= '1';
                            r_tx_data   <= i_tx_byte;
                            r_state     <= s_START_BIT;
                        else
                            o_tx_active <= '0';
                            r_state     <= s_IDLE;
                        end if;

                    when s_START_BIT =>
                        o_tx_serial <= '0';
                        if r_clk_cnt < g_CLKS_PER_BIT - 1 then
                            r_clk_cnt <= r_clk_cnt + 1;
                        else
                            r_clk_cnt <= 0;
                            r_state   <= s_DATA_BITS;
                        end if;

                    when s_DATA_BITS =>
                        o_tx_serial <= r_tx_data(r_bit_idx);
                        if r_clk_cnt < g_CLKS_PER_BIT - 1 then
                            r_clk_cnt <= r_clk_cnt + 1;
                        else
                            r_clk_cnt <= 0;
                            if r_bit_idx < 7 then
                                r_bit_idx <= r_bit_idx + 1;
                            else
                                r_bit_idx <= 0;
                                r_state   <= s_STOP_BIT;
                            end if;
                        end if;

                    when s_STOP_BIT =>
                        o_tx_serial <= '1';
                        if r_clk_cnt < g_CLKS_PER_BIT - 1 then
                            r_clk_cnt <= r_clk_cnt + 1;
                        else
                            r_tx_done   <= '1';
                            r_clk_cnt   <= 0;
                            o_tx_active <= '0';
                            r_state     <= s_CLEANUP;
                        end if;

                    when s_CLEANUP =>
                        r_tx_done <= '1';
                        r_state   <= s_IDLE;
                end case;
            end if;
        end if;
    end process p_uart_tx;

    o_tx_done <= r_tx_done;
end architecture rtl;