library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
-- ENTITY: spi_master_rx
-- Опис: Модуль SPI Master (Приймач)
--       Реалізує логіку Master для прийому N біт даних.
--       Генерує тактові імпульси SCLK та керує SS_n.
--       Читає дані з i_miso.
--=============================================================================
entity spi_master_rx is
    generic (
        G_NBITS             : positive := 8;
        G_CLK_DIV_RATIO     : positive := 5; 
        G_CPOL              : std_logic := '0';
        G_CPHA              : std_logic := '0'
    );
    port (
        -- === Входи Керування ===
        i_clk               : in  std_logic;
        i_reset             : in  std_logic;
        i_start             : in  std_logic;
        
        -- === Вхідні Дані ===
        -- i_miso:  Вхідні дані Master (Master In Slave Out)
        i_miso              : in  std_logic;
        
        -- === Виходи SPI ===
        o_sclk              : out std_logic;
        o_ss_n              : out std_logic;
        
        -- === Вихідні Дані ===
        -- o_data:  Прийняті дані
        o_data              : out std_logic_vector(G_NBITS-1 downto 0);
        
        -- === Виходи Статусу ===
        o_busy              : out std_logic;
        o_done              : out std_logic
    );
end entity spi_master_rx;

architecture rtl of spi_master_rx is

    -- Визначення станів FSM
    type t_state is (
        IDLE,           -- Очікування
        LOAD,           -- (Тут просто встановлення лічильника)
        ASSERT_SS,      -- Активація Slave Select
        PREP_CPHA0,     -- (CPHA=0) Очікування 1-го SCLK
        ALIGN_CPHA1,    -- (CPHA=1) Очікування 1-го SCLK
        SHIFT,          -- Зсув та прийом бітів
        DONE_FRAME      -- Завершення, виставлення даних
    );
    
    -- === Внутрішні Регістри та Сигнали === 
    signal r_state      : t_state := IDLE;
    signal r_next_state : t_state := IDLE;
    
    -- r_shreg_rx: Зсувний регістр для прийому даних
    signal r_shreg_rx   : std_logic_vector(G_NBITS-1 downto 0);
    
    -- r_bitcnt: Лічильник бітів (зворотний, від Nbits до 0)
    signal r_bitcnt     : integer range 0 to G_NBITS;
    
    -- r_sclk: Внутрішній регістр для генерації SCLK
    signal r_sclk       : std_logic := G_CPOL;
    
    -- r_clk_div_cnt: Лічильник для дільника частоти SCLK
    signal r_clk_div_cnt: integer range 0 to G_CLK_DIV_RATIO-1;
    
    -- r_done_pulse: Регістр для генерації імпульсу o_done
    signal r_done_pulse : std_logic;

    -- sclk_tick: Внутрішній імпульс, що позначає зміну SCLK
    signal s_sclk_tick  : std_logic;
    
    -- s_sample_edge: Імпульс, що позначає "Sample" фронт SCLK
    signal s_sample_edge: std_logic;
    
    -- r_data_out: Регістр для вихідних даних (o_data)
    signal r_data_out   : std_logic_vector(G_NBITS-1 downto 0);

begin

    --=========================================================================
    -- ПРОЦЕС 1: Синхронна Логіка (Регістри FSM та Дільник SCLK)
    --=========================================================================
    p_sync : process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            -- Скидання FSM та всіх регістрів
            r_state       <= IDLE;
            r_shreg_rx    <= (others => '0');
            r_data_out    <= (others => '0');
            r_bitcnt      <= 0;
            r_clk_div_cnt <= 0;
            r_sclk        <= G_CPOL; -- SCLK у стані 'idle'
            r_done_pulse  <= '0';
            
        elsif rising_edge(i_clk) then
            
            r_state <= r_next_state;
            
            -- Генерація імпульсу o_done
            r_done_pulse <= '0'; 
            if (r_next_state = DONE_FRAME) and (r_state /= DONE_FRAME) then
                r_done_pulse <= '1';
            end if;

            -- === Логіка Дільника SCLK  ===
            if (r_state = SHIFT) then
                if r_clk_div_cnt = G_CLK_DIV_RATIO-1 then
                    r_clk_div_cnt <= 0;
                    r_sclk        <= not r_sclk; -- Зміна стану SCLK
                else
                    r_clk_div_cnt <= r_clk_div_cnt + 1;
                end if;
            else
                r_clk_div_cnt <= 0; 
                r_sclk        <= G_CPOL;
            end if;

            -- === Логіка Регістрів (залежить від стану) ===
            case r_state is
                when LOAD =>
                    r_bitcnt   <= G_NBITS; -- Встановлення лічильника
                    r_shreg_rx <= (others => '0'); -- Очищення регістра прийому
                
                when SHIFT =>
                    -- Прийом та зсув відбуваються на "Sample" фронті SCLK
                    if s_sample_edge = '1' then
                        -- Зсуваємо і приймаємо i_miso у LSB (або MSB, залежно від реалізації)
                        -- Ця реалізація приймає MSB першим.
                        r_shreg_rx <= r_shreg_rx(G_NBITS-2 downto 0) & i_miso;
                        r_bitcnt   <= r_bitcnt - 1;
                    end if;
                
                when DONE_FRAME =>
                    -- Виставляємо прийняті дані на вихід
                    r_data_out <= r_shreg_rx;
                    
                when others =>
                    -- (IDLE, ASSERT_SS, PREP, ALIGN)
                    -- Немає змін регістрів
            end case;
            
        end if;
    end process p_sync;
    
    
    -- Визначення "Tick" та "Sample Edge"
    s_sclk_tick <= '1' when (r_clk_div_cnt = G_CLK_DIV_RATIO-1) and (r_state = SHIFT) else '0';
    
    -- Для прийому (Rx) CPHA визначає, на якому фронті ми *читаємо*
    -- CPHA=0: Sample на 1-му фронті (r_sclk = not G_CPOL)
    -- CPHA=1: Sample на 2-му фронті (r_sclk = G_CPOL)
    s_sample_edge <= '1' when (s_sclk_tick = '1') and ((G_CPHA = '0' and r_sclk = G_CPOL) or (G_CPHA = '1' and r_sclk /= G_CPOL)) else '0';

    
    --=========================================================================
    -- ПРОЦЕС 2: Комбінаторна Логіка (Виходи та Наступний Стан)
    --=========================================================================
    p_comb : process(r_state, i_start, r_bitcnt, r_done_pulse, r_data_out)
    begin
        -- === Значення за замовчуванням ===
        r_next_state <= r_state;
        o_busy       <= '1'; 
        o_ss_n       <= '1'; 
        o_done       <= r_done_pulse;
        o_data       <= r_data_out; -- Вихід регістра
        
        -- === Логіка FSM (з діаграми) ===
        case r_state is
            when IDLE =>
                o_busy <= '0';
                if i_start = '1' and r_done_pulse = '0' then
                    r_next_state <= LOAD;
                end if;

            when LOAD =>
                r_next_state <= ASSERT_SS;

            when ASSERT_SS =>
                o_ss_n <= '0'; -- Активація SS_n (активний низький)
                -- Для Rx неважливо, коли починати, але ми дотримуємось FSM
                if G_CPHA = '1' then
                    r_next_state <= ALIGN_CPHA1;
                else
                    r_next_state <= PREP_CPHA0;
                end if;

            when PREP_CPHA0 | ALIGN_CPHA1 =>
                o_ss_n <= '0';
                r_next_state <= SHIFT;

            when SHIFT =>
                o_ss_n <= '0';
                if r_bitcnt = 0 then
                    r_next_state <= DONE_FRAME;
                end if;

            when DONE_FRAME =>
                o_busy <= '0';
                o_ss_n <= '1'; -- Деактивація SS_n
                if i_start = '1' then
                    r_next_state <= LOAD;
                else
                    r_next_state <= IDLE;
                end if;
                
        end case;
    end process p_comb;
    
    -- === Призначення виходів ===
    o_sclk <= r_sclk;

end architecture rtl;