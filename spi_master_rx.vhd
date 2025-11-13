library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_rx is
    generic (
        G_NBITS         : positive := 8;
        G_CLK_DIV_RATIO : positive := 5;
        G_CPOL          : std_logic := '0';
        G_CPHA          : std_logic := '0'  -- припускаємо CPHA=0
    );
    port (
        i_clk   : in  std_logic;
        i_reset : in  std_logic;
        i_start : in  std_logic;

        i_miso  : in  std_logic;

        o_sclk  : out std_logic;
        o_ss_n  : out std_logic;

        o_data  : out std_logic_vector(G_NBITS-1 downto 0);

        o_busy  : out std_logic;
        o_done  : out std_logic
    );
end entity spi_master_rx;

architecture rtl of spi_master_rx is

    type t_state is (
        IDLE,
        LOAD,
        ASSERT_SS,
        SHIFT,
        DONE_FRAME
    );

    signal r_state       : t_state := IDLE;

    signal r_shreg_rx    : std_logic_vector(G_NBITS-1 downto 0) := (others => '0');
    signal r_data_out    : std_logic_vector(G_NBITS-1 downto 0) := (others => '0');
    signal r_bitcnt      : integer range 0 to G_NBITS := 0;

    signal r_sclk        : std_logic := G_CPOL;
    signal r_clk_div_cnt : integer range 0 to G_CLK_DIV_RATIO-1 := 0;

    signal r_ss_n        : std_logic := '1';
    signal r_busy        : std_logic := '0';
    signal r_done_pulse  : std_logic := '0';

    -- прапорець вирівнювання: перший фронт SCLK після ASSERT_SS ми використовуємо
    -- лише щоб "завестись", а не семплити дані
    signal r_started     : std_logic := '0';

begin

    o_sclk <= r_sclk;
    o_ss_n <= r_ss_n;
    o_data <= r_data_out;
    o_busy <= r_busy;
    o_done <= r_done_pulse;

    process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            r_state       <= IDLE;
            r_shreg_rx    <= (others => '0');
            r_data_out    <= (others => '0');
            r_bitcnt      <= 0;
            r_sclk        <= G_CPOL;
            r_clk_div_cnt <= 0;
            r_ss_n        <= '1';
            r_busy        <= '0';
            r_done_pulse  <= '0';
            r_started     <= '0';

        elsif rising_edge(i_clk) then
            r_done_pulse <= '0';

            case r_state is

                -- Очікування старту
                when IDLE =>
                    r_busy        <= '0';
                    r_ss_n        <= '1';
                    r_sclk        <= G_CPOL;
                    r_clk_div_cnt <= 0;
                    r_started     <= '0';
                    if i_start = '1' then
                        r_state <= LOAD;
                    end if;

                -- Ініціалізація прийому
                when LOAD =>
                    r_busy        <= '1';
                    r_ss_n        <= '1';
                    r_shreg_rx    <= (others => '0');
                    r_bitcnt      <= G_NBITS;
                    r_sclk        <= G_CPOL;
                    r_clk_div_cnt <= 0;
                    r_started     <= '0';
                    r_state       <= ASSERT_SS;

                -- Опускаємо SS_n
                when ASSERT_SS =>
                    r_busy        <= '1';
                    r_ss_n        <= '0';
                    r_sclk        <= G_CPOL;
                    r_clk_div_cnt <= 0;
                    r_started     <= '0';
                    r_state       <= SHIFT;

                -- Генерація SCLK і семплінг MISO
                -- Тестбенч виставляє біт на falling_edge(SCLK).
                -- Ми:
                --   * перший rising після ASSERT_SS використовуємо тільки для старту (r_started = '1')
                --   * далі на кожному rising (0->1), коли r_started='1', семплимо MISO.
                when SHIFT =>
                    r_busy <= '1';
                    r_ss_n <= '0';

                    if r_clk_div_cnt = G_CLK_DIV_RATIO-1 then
                        r_clk_div_cnt <= 0;

                        if r_sclk = '0' then
                            -- зараз буде перехід 0->1 (rising)
                            if r_started = '0' then
                                -- перший фронт: лише вирівнюємось
                                r_started <= '1';
                            else
                                -- подальші rising: семплимо біти
                                if r_bitcnt > 0 then
                                    r_shreg_rx <= r_shreg_rx(G_NBITS-2 downto 0) & i_miso;
                                    r_bitcnt   <= r_bitcnt - 1;
                                end if;

                                if r_bitcnt = 1 then
                                    -- щойно семплили останній біт
                                    r_state <= DONE_FRAME;
                                end if;
                            end if;
                        end if;

                        -- Тепер реально перемикаємо SCLK
                        r_sclk <= not r_sclk;

                    else
                        r_clk_div_cnt <= r_clk_div_cnt + 1;
                    end if;

                -- Завершення кадру
                when DONE_FRAME =>
                    r_busy        <= '0';
                    r_ss_n        <= '1';
                    r_sclk        <= G_CPOL;
                    r_clk_div_cnt <= 0;
                    r_data_out    <= r_shreg_rx;
                    r_done_pulse  <= '1';
                    r_started     <= '0';
                    r_state       <= IDLE;

            end case;
        end if;
    end process;

end architecture rtl;
