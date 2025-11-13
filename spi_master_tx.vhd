library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_tx is
    generic (
        G_NBITS         : positive := 8;
        G_CLK_DIV_RATIO : positive := 5;   -- системних тактів на півперіод SCLK
        G_CPOL          : std_logic := '0';
        G_CPHA          : std_logic := '0' -- тут не повністю використовується, але залишаємо
    );
    port (
        i_clk   : in  std_logic;
        i_reset : in  std_logic;
        i_start : in  std_logic;

        i_data  : in  std_logic_vector(G_NBITS-1 downto 0);

        o_sclk  : out std_logic;
        o_mosi  : out std_logic;
        o_ss_n  : out std_logic;

        o_busy  : out std_logic;
        o_done  : out std_logic
    );
end entity spi_master_tx;

architecture rtl of spi_master_tx is

    type t_state is (
        IDLE,
        LOAD,
        ASSERT_SS,
        SHIFT,
        DONE_FRAME
    );

    signal r_state       : t_state := IDLE;

    signal r_shreg       : std_logic_vector(G_NBITS-1 downto 0) := (others => '0');
    signal r_bitcnt      : integer range 0 to G_NBITS := 0;

    signal r_sclk        : std_logic := G_CPOL;
    signal r_clk_div_cnt : integer range 0 to G_CLK_DIV_RATIO-1 := 0;

    signal r_ss_n        : std_logic := '1';
    signal r_mosi        : std_logic := '0';
    signal r_busy        : std_logic := '0';
    signal r_done_pulse  : std_logic := '0';

begin

    o_sclk <= r_sclk;
    o_mosi <= r_mosi;
    o_ss_n <= r_ss_n;
    o_busy <= r_busy;
    o_done <= r_done_pulse;

    process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            r_state       <= IDLE;
            r_shreg       <= (others => '0');
            r_bitcnt      <= 0;
            r_sclk        <= G_CPOL;
            r_clk_div_cnt <= 0;
            r_ss_n        <= '1';
            r_mosi        <= '0';
            r_busy        <= '0';
            r_done_pulse  <= '0';

        elsif rising_edge(i_clk) then
            r_done_pulse <= '0';  -- за замовчуванням

            case r_state is

                when IDLE =>
                    r_busy <= '0';
                    r_ss_n <= '1';
                    r_sclk <= G_CPOL;
                    r_clk_div_cnt <= 0;
                    if i_start = '1' then
                        r_state <= LOAD;
                    end if;

                when LOAD =>
                    r_busy  <= '1';
                    r_shreg <= i_data;
                    r_bitcnt <= G_NBITS;
                    r_ss_n <= '1';
                    r_sclk <= G_CPOL;
                    r_clk_div_cnt <= 0;
                    r_state <= ASSERT_SS;

                when ASSERT_SS =>
                    r_ss_n <= '0';
                    -- виставляємо перший біт одразу
                    r_mosi <= r_shreg(G_NBITS-1);
                    r_state <= SHIFT;

                when SHIFT =>
                    r_busy <= '1';
                    r_ss_n <= '0';

                    if r_clk_div_cnt = G_CLK_DIV_RATIO-1 then
                        r_clk_div_cnt <= 0;
                        -- перемикаємо SCLK
                        r_sclk <= not r_sclk;

                        -- якщо це перехід 0->1 (r_sclk був '0'), вважаємо його "активним"
                        if r_sclk = '0' then
                            -- після активного фронту зсуваємо дані
                            if r_bitcnt > 0 then
                                r_shreg <= r_shreg(G_NBITS-2 downto 0) & '0';
                                r_bitcnt <= r_bitcnt - 1;
                                -- наступний біт на MOSI (MSB)
                                r_mosi <= r_shreg(G_NBITS-2);
                            end if;

                            if r_bitcnt = 1 then
                                -- щойно переданий останній біт
                                r_state <= DONE_FRAME;
                            end if;
                        end if;
                    else
                        r_clk_div_cnt <= r_clk_div_cnt + 1;
                    end if;

                when DONE_FRAME =>
                    r_ss_n       <= '1';
                    r_busy       <= '0';
                    r_sclk       <= G_CPOL;
                    r_clk_div_cnt <= 0;
                    r_mosi       <= '0';
                    r_done_pulse <= '1';
                    -- одразу повертаємось в IDLE, однотактний імпульс o_done
                    r_state      <= IDLE;

            end case;
        end if;
    end process;

end architecture rtl;
