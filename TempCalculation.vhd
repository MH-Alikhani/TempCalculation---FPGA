library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TempCalculator is
    Port ( clk        : in  STD_LOGIC;
           reset      : in  STD_LOGIC;
           scl        : inout  STD_LOGIC;
           sda        : inout  STD_LOGIC;
           temperature : out  STD_LOGIC_VECTOR(7 downto 0));
end TempCalculator;

architecture Behavioral of TempCalculator is

    -- I2C States
    type state_type is (IDLE, START, SEND_ADDR, READ_TEMP, STOP, CONVERT);
    signal state : state_type := IDLE;

    -- Registers for data storage
    signal raw_data     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal temp_celsius : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    -- I2C signals
    signal scl_internal : STD_LOGIC := '1';
    signal sda_internal : STD_LOGIC := '1';
    signal bit_cnt      : integer := 0;

    -- I2C sensor address and commands
    constant SENSOR_ADDR : STD_LOGIC_VECTOR(6 downto 0) := "1001000"; -- Example address
    constant READ_CMD    : STD_LOGIC_VECTOR(7 downto 0) := "10101010"; -- Example read command

    -- Clock divider for I2C timing
    signal clk_div : integer := 0;
    constant CLK_DIV_MAX : integer := 50000; -- Adjust based on system clock

begin

    -- I2C Interface process
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            raw_data <= (others => '0');
            temp_celsius <= (others => '0');
            scl_internal <= '1';
            sda_internal <= '1';
            bit_cnt <= 0;
            clk_div <= 0;
        elsif rising_edge(clk) then
            -- Clock divider for I2C timing
            if clk_div < CLK_DIV_MAX then
                clk_div <= clk_div + 1;
            else
                clk_div <= 0;
                case state is
                    when IDLE =>
                        state <= START;
                    when START =>
                        -- Send start condition
                        sda_internal <= '0';
                        state <= SEND_ADDR;
                    when SEND_ADDR =>
                        -- Send sensor address and read command
                        if bit_cnt < 8 then
                            sda_internal <= SENSOR_ADDR(bit_cnt);
                            bit_cnt <= bit_cnt + 1;
                        else
                            bit_cnt <= 0;
                            state <= READ_TEMP;
                        end if;
                    when READ_TEMP =>
                        -- Read temperature data from sensor
                        if bit_cnt < 16 then
                            raw_data(bit_cnt) <= sda_internal;
                            bit_cnt <= bit_cnt + 1;
                        else
                            bit_cnt <= 0;
                            state <= STOP;
                        end if;
                    when STOP =>
                        -- Send stop condition
                        sda_internal <= '1';
                        state <= CONVERT;
                    when CONVERT =>
                        -- Convert raw data to Celsius (Example conversion)
                        temp_celsius <= std_logic_vector(to_signed(signed(raw_data(15 downto 8)) * 9/5 + 32, 8));
                        state <= IDLE;
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- I2C Signals assignment
    scl <= scl_internal;
    sda <= sda_internal;
    temperature <= temp_celsius;

end Behavioral;