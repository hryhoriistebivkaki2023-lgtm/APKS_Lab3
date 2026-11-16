library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        g_CLKS_PER_BIT : integer := 434
    );
    port (
        i_clk       : in  std_logic;                      -- Тактовий сигнал (50 МГц)
        i_rst       : in  std_logic;                      -- Синхронне скидання (активний '1')
        i_rx_serial : in  std_logic;                      -- Послідовний вхід RxD
        o_rx_done   : out std_logic;                      -- Прапорець готовності прийнятого байта
        o_rx_byte   : out std_logic_vector(7 downto 0)    -- Прийнятий байт даних
    );
end entity uart_rx;

architecture rtl of uart_rx is
    type t_rx_state is (s_IDLE, s_START_BIT, s_DATA_BITS, s_STOP_BIT, s_CLEANUP);
    signal r_state    : t_rx_state := s_IDLE;
    signal r_rx_sync1 : std_logic := '1';
    signal r_rx_data  : std_logic := '1';
    signal r_clk_cnt  : integer range 0 to g_CLKS_PER_BIT - 1 := 0;
    signal r_bit_idx  : integer range 0 to 7 := 0;
    signal r_rx_byte  : std_logic_vector(7 downto 0) := (others => '0');
    signal r_rx_done  : std_logic := '0';
begin
    -- Двокаскадна синхронізація вхідної асинхронної лінії RxD
    p_sync : process(i_clk)
    begin
        if rising_edge(i_clk) then
            r_rx_sync1 <= i_rx_serial;
            r_rx_data  <= r_rx_sync1;
        end if;
    end process p_sync;

    p_uart_rx : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_state   <= s_IDLE;
                r_rx_done <= '0';
                r_clk_cnt <= 0;
                r_bit_idx <= 0;
                r_rx_byte <= (others => '0');
            else
                case r_state is
                    when s_IDLE =>
                        r_rx_done <= '0';
                        r_clk_cnt <= 0;
                        r_bit_idx <= 0;
                        if r_rx_data = '0' then
                            r_state <= s_START_BIT;
                        end if;

                    when s_START_BIT =>
                        -- Перевірка середини стартового біта
                        if r_clk_cnt = (g_CLKS_PER_BIT - 1) / 2 then
                            if r_rx_data = '0' then
                                r_clk_cnt <= 0;
                                r_state   <= s_DATA_BITS;
                            else
                                r_state <= s_IDLE;
                            end if;
                        else
                            r_clk_cnt <= r_clk_cnt + 1;
                        end if;

                    when s_DATA_BITS =>
                        -- Стробування кожного біта по центру інтервалу
                        if r_clk_cnt < g_CLKS_PER_BIT - 1 then
                            r_clk_cnt <= r_clk_cnt + 1;
                        else
                            r_clk_cnt            <= 0;
                            r_rx_byte(r_bit_idx) <= r_rx_data;
                            if r_bit_idx < 7 then
                                r_bit_idx <= r_bit_idx + 1;
                            else
                                r_bit_idx <= 0;
                                r_state   <= s_STOP_BIT;
                            end if;
                        end if;

                    when s_STOP_BIT =>
                        if r_clk_cnt < g_CLKS_PER_BIT - 1 then
                            r_clk_cnt <= r_clk_cnt + 1;
                        else
                            r_rx_done <= '1';
                            r_clk_cnt <= 0;
                            r_state   <= s_CLEANUP;
                        end if;

                    when s_CLEANUP =>
                        r_rx_done <= '0';
                        r_state   <= s_IDLE;
                end case;
            end if;
        end if;
    end process p_uart_rx;

    o_rx_done <= r_rx_done;
    o_rx_byte <= r_rx_byte;
end architecture rtl;