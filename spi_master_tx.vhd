-- Підключення стандартних бібліотек IEEE
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
-- ENTITY: spi_master_tx
-- Опис: Модуль SPI Master (Передавач)
--       Реалізує логіку Master для передачі N біт даних.
--       Генерує тактові імпульси SCLK та керує SS_n.
--       FSM базується на наданій діаграмі.
--=============================================================================
entity spi_master_tx is
    generic (
        -- Кількість біт у фреймі (з діаграми "Nbits")
        G_NBITS             : positive := 8;
        -- Співвідношення дільника для SCLK
        -- SCLK_freq = CLK_freq / (2 * G_CLK_DIV_RATIO)
        G_CLK_DIV_RATIO     : positive := 5; 
        -- CPOL: Полярність тактового сигналу (0 = idle low, 1 = idle high)
        G_CPOL              : std_logic := '0';
        -- CPHA: Фаза тактового сигналу (0 = sample 1st edge, 1 = sample 2nd edge)
        G_CPHA              : std_logic := '0'
    );
    port (
        -- === Входи Керування ===
        -- i_clk:   Системний тактовий сигнал (швидкий)
        i_clk               : in  std_logic;
        -- i_reset: Асинхронний сигнал скидання (активний високий)
        i_reset             : in  std_logic;
        -- i_start: Сигнал запуску передачі (один імпульс)
        i_start             : in  std_logic;
        
        -- === Вхідні Дані ===
        -- i_data:  Дані, які необхідно передати (MSB виходить першим)
        i_data              : in  std_logic_vector(G_NBITS-1 downto 0);
        
        -- === Виходи SPI ===
        -- o_sclk:  Згенерований SPI тактовий сигнал (Master Clock)
        o_sclk              : out std_logic;
        -- o_mosi:  Вихідні дані Master (Master Out Slave In)
        o_mosi              : out std_logic;
        -- o_ss_n:  Вибір підлеглого (Slave Select, активний низький)
        o_ss_n              : out std_logic;
        
        -- === Виходи Статусу ===
        -- o_busy:  Високий, коли FSM виконує передачу
        o_busy              : out std_logic;
        -- o_done:  Імпульс на один такт, коли передача завершена
        o_done              : out std_logic
    );
end entity spi_master_tx;

architecture rtl of spi_master_tx is

    -- 1. Визначення станів FSM (з вашої діаграми)
    type t_state is (
        IDLE,           -- Очікування
        LOAD,           -- Завантаження даних
        ASSERT_SS,      -- Активація Slave Select
        PREP_CPHA0,     -- (CPHA=0) Виставлення 1-го біта до SCLK
        ALIGN_CPHA1,    -- (CPHA=1) Очікування 1-го фронту SCLK
        SHIFT,          -- Зсув та передача бітів
        DONE_FRAME      -- Завершення, деактивація SS
    );
    
    -- === Внутрішні Регістри та Сигнали === 
    -- r_state, r_next_state: Поточний та наступний стан FSM
    signal r_state      : t_state := IDLE;
    signal r_next_state : t_state := IDLE;
    
    -- r_shreg: Зсувний регістр для передачі даних
    signal r_shreg      : std_logic_vector(G_NBITS-1 downto 0);
    
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
    
begin

    --=========================================================================
    -- ПРОЦЕС 1: Синхронна Логіка (Регістри FSM та Дільник SCLK)
    -- Опис: Цей процес відповідає за всі зміни, що відбуваються
    --       по фронту системного тактового сигналу (i_clk).
    --=========================================================================
    p_sync : process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            -- Скидання FSM та всіх регістрів
            r_state       <= IDLE;
            r_shreg       <= (others => '0');
            r_bitcnt      <= 0;
            r_clk_div_cnt <= 0;
            r_sclk        <= G_CPOL; -- SCLK у стані 'idle'
            r_done_pulse  <= '0';
            
        elsif rising_edge(i_clk) then
            
            -- Регістр стану FSM
            r_state <= r_next_state;
            
            -- Генерація імпульсу o_done
            r_done_pulse <= '0'; -- Скидається за замовчуванням
            if (r_next_state = DONE_FRAME) and (r_state /= DONE_FRAME) then
                r_done_pulse <= '1'; -- Встановлюється на 1 такт
            end if;

            -- === Логіка Дільника SCLK  ===
            -- Дільник активний тільки у стані SHIFT
            if (r_state = SHIFT) then
                if r_clk_div_cnt = G_CLK_DIV_RATIO-1 then
                    r_clk_div_cnt <= 0;
                    r_sclk        <= not r_sclk; -- Зміна стану SCLK
                else
                    r_clk_div_cnt <= r_clk_div_cnt + 1;
                end if;
            else
                r_clk_div_cnt <= 0; -- Скидання дільника
                r_sclk        <= G_CPOL; -- SCLK в idle
            end if;

            -- === Логіка Регістрів (залежить від стану) ===
            case r_state is
                when LOAD =>
                    r_shreg  <= i_data;  -- Завантаження даних у зсувний регістр
                    r_bitcnt <= G_NBITS; -- Встановлення лічильника (з діаграми)
                
                when SHIFT =>
                    -- Зсув та підрахунок бітів відбуваються на "Sample" фронті SCLK
                    if s_sample_edge = '1' then
                        r_shreg  <= r_shreg(G_NBITS-2 downto 0) & '0'; -- Зсув MSB
                        r_bitcnt <= r_bitcnt - 1;
                    end if;
                    
                when others =>
                    -- (IDLE, ASSERT_SS, PREP, ALIGN, DONE_FRAME)
                    -- Немає змін регістрів (крім скидання дільника SCLK вище)
            end case;
            
        end if;
    end process p_sync;
    
    
    -- Визначення "Tick" та "Sample Edge"
    -- s_sclk_tick: імпульс, коли SCLK має змінитись
    s_sclk_tick <= '1' when (r_clk_div_cnt = G_CLK_DIV_RATIO-1) and (r_state = SHIFT) else '0';
    
    -- s_sample_edge: імпульс на "Sample" фронті SJSON
    -- Для CPHA=0: Sample на 1-му фронті (r_sclk = not G_CPOL)
    -- Для CPHA=1: Sample на 2-му фронті (r_sclk = G_CPOL)
    s_sample_edge <= '1' when (s_sclk_tick = '1') and ((G_CPHA = '0' and r_sclk = G_CPOL) or (G_CPHA = '1' and r_sclk /= G_CPOL)) else '0';

    
    --=========================================================================
    -- ПРОЦЕС 2: Комбінаторна Логіка (Виходи та Наступний Стан)
    -- Опис: Цей процес визначає логіку виходів (o_mosi, o_ss_n)
    --       та логіку переходів FSM (r_next_state).
    --=========================================================================
    p_comb : process(r_state, i_start, r_shreg, r_bitcnt, r_done_pulse)
    begin
        -- === Значення за замовчуванням ===
        r_next_state <= r_state;
        o_busy       <= '1'; -- Зайнятий у всіх станах, крім IDLE
        o_mosi       <= '0'; -- За замовчуванням
        o_ss_n       <= '1'; -- Неактивний
        o_done       <= r_done_pulse;
        
        -- === Логіка FSM (з діаграми) ===
        case r_state is
        
            when IDLE =>
                o_busy <= '0';
                if i_start = '1' and r_done_pulse = '0' then
                    r_next_state <= LOAD;
                end if;

            when LOAD =>
                -- (busy=1, done=0 з діаграми)
                r_next_state <= ASSERT_SS;

            when ASSERT_SS =>
                o_ss_n <= '0'; -- Активація SS_n (активний низький)
                if G_CPHA = '1' then
                    r_next_state <= ALIGN_CPHA1;
                else
                    r_next_state <= PREP_CPHA0;
                end if;

            when PREP_CPHA0 => -- (CPHA=0)
                o_ss_n <= '0';
                o_mosi <= r_shreg(G_NBITS-1); -- Виставляємо MSB *до* 1-го SCLK
                r_next_state <= SHIFT;
            
            when ALIGN_CPHA1 => -- (CPHA=1)
                o_ss_n <= '0';
                -- MOSI ще не виставляється
                r_next_state <= SHIFT;

            when SHIFT =>
                o_ss_n <= '0';
                -- MOSI виставляється відповідно до MSB зсувного регістра
                o_mosi <= r_shreg(G_NBITS-1);
                
                -- Перевірка завершення
                if r_bitcnt = 0 then
                    r_next_state <= DONE_FRAME;
                end if;

            when DONE_FRAME =>
                o_busy <= '0';
                o_ss_n <= '1'; -- Деактивація SS_n
                if i_start = '1' then
                    r_next_state <= LOAD; -- Готові до наступної передачі
                else
                    r_next_state <= IDLE;
                end if;
                
        end case;
    end process p_comb;
    
    -- === Призначення виходів ===
    o_sclk <= r_sclk; -- Підключення внутрішнього SCLK до виходу

end architecture rtl;