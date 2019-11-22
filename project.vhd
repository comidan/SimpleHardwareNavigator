----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.12.2018 11:23:41
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    port (
        i_clk : in  std_logic;
        i_start : in  std_logic;
        i_rst : in  std_logic;
        i_data : in  std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0) );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
--TYPE
type State_t is (IDLE, BITMASK_READ, PIVOT_READ_X, PIVOT_READ_Y, POINTS_LOOP_INIT_READ, POINTS_LOOP_READ_X, POINTS_LOOP_READ_Y, COMPUTE_DISTANCE, WRITE_DISTANCE, COMPUTE_MINIMUM_DISTANCE, DONE);
type mem is array(1 downto 0) of STD_LOGIC_VECTOR(7 downto 0);

--SIGNAL
signal state, next_state: State_t;
signal reg, next_reg : mem := (0=>"00000000", 1=>"00000000"); --x, y coordinates
signal validationString, next_validationString : STD_LOGIC_VECTOR(7 downto 0);
signal distanceX, next_distanceX : STD_LOGIC_VECTOR(7 downto 0);
signal distanceY, next_distanceY : STD_LOGIC_VECTOR(7 downto 0);
signal distance, next_distance : STD_LOGIC_VECTOR(8 downto 0); --9 bit per caso peggiore
signal distanceMin, next_distanceMin : STD_LOGIC_VECTOR(8 downto 0); --9 bit per caso peggiore
signal result, next_result : STD_LOGIC_VECTOR(7 downto 0);
signal x, next_x: STD_LOGIC_VECTOR(7 downto 0):="00000000";
signal y, next_y: STD_LOGIC_VECTOR(7 downto 0):="00000000";
signal address, next_address : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
signal write_enabled, next_write_enabled: STD_LOGIC := '0';
signal index, next_index : STD_LOGIC_VECTOR(3 downto 0); --indice per muoversi nella RAM
signal counter, next_counter: STD_LOGIC_VECTOR(3 downto 0); --indice per ciclare sugli 8 punti

begin 
    process (i_rst, i_clk)
    begin
        if(i_rst = '1') then
            state <= IDLE;
        elsif(i_clk'event and i_clk = '1') then
            index <= next_index;
            counter <= next_counter;
            state <= next_state;
            address <= next_address;
            distance <= next_distance;
            distanceMin <= next_distanceMin;
            distanceX <= next_distanceX;
            distanceY <= next_distanceY;
            validationString <= next_validationString;
            write_enabled <= next_write_enabled;
            reg <= next_reg;
            result <= next_result;
            x <= next_x;
            y <= next_y;
        end if;
    end process;

    process(i_start, state, index, counter, address, next_address, write_enabled, validationString, reg, x, y, distanceX, distanceY, distance, distanceMin, result, i_data)
    begin
            next_index <= index;
            next_counter <= counter;
            next_state <= state;
            next_distanceX <= distanceX;
            next_distanceY <= distanceY;
            next_distanceMin <= distanceMin;
            next_distance <= distance;
            next_validationString <= validationString;
            next_write_enabled <= write_enabled;
            next_result <= result;
            next_reg <= reg;
            next_x <= x;
            next_y <= y;
            next_address <= address;
            o_done <= '0';
            o_en <= '1';
            o_we <= '0';
            o_address <= address;
            o_data <= result;
            case state is
                when IDLE => --stato inziale
                    next_distanceMin <= (others => '1');
                    next_result <= (others => '0');
                    next_distanceX <= (others => '0');
                    next_distanceY <= (others => '0');
                    next_distance <= (others => '0');
                    o_address <= (others => '0');
                    next_address <= (others => '0');
                    o_done <= '0';
                    o_en <= '0';
                    o_we <= '0';
                    next_write_enabled <= '0';
                    o_data <= (others => '0');
                    next_x <= (others => '0');
                    next_y <= (others => '0');
                    next_validationString <= (others => '0');
                    next_index <= (0 => '1', others => '0');
                    next_counter <= (others => '0');
                    if i_start = '1' then
                        o_en <= '1';
                        next_state <= BITMASK_READ;
                    else
                        next_state <= IDLE;
                    end if;
                when BITMASK_READ => --stato di lettura della bitmask dei punti da considerare
                    next_validationString <= i_data;
                    next_address <= "0000000000010001";
                    o_address <= "0000000000010001";
                    o_en <= '1';
                    o_we <= '0';
                    next_state <= PIVOT_READ_X;
                when PIVOT_READ_X => --stato in cui memorizzo la prima coppia di  coordinate x e y e le salvo in un registro da 2 byte, ottimizza con più stati
                    next_x <= i_data;
                    next_address <= "0000000000010010";
                    o_address <= "0000000000010010";
                    o_en <= '1';
                    o_we <= '0';
                    next_state <= PIVOT_READ_Y;
                when PIVOT_READ_Y =>
                    next_y <= i_data;
                    next_state <= POINTS_LOOP_INIT_READ;
                when POINTS_LOOP_INIT_READ => --stato in cui leggo i valori delle coordinate dei punti di cui computare la distanza
                    if(counter <"00001000" and validationString(to_integer(unsigned(counter))) = '1') then
                        o_en <= '1';
                        o_we <= '0';
                        next_address <= std_logic_vector(resize(unsigned(index), o_address'length));
                        o_address <= std_logic_vector(resize(unsigned(index), o_address'length));
                        next_state <= POINTS_LOOP_READ_X;
                    elsif(counter < "00001000" and validationString(to_integer(unsigned(counter))) = '0') then
                        next_address <= address + '1';
                        next_index <= index + "010";
                        next_counter <= counter + "001";
                        o_en <= '1';
                        o_we <= '0';
                        next_state <= POINTS_LOOP_INIT_READ;
                    else
                        next_state <= DONE;
                    end if;
                when POINTS_LOOP_READ_X =>
                    next_reg(0) <= i_data;
                    o_en <= '1';
                    o_we <= '0';
                    next_address <= std_logic_vector(resize(unsigned(index), o_address'length)) + '1';
                    o_address <= std_logic_vector(resize(unsigned(index), o_address'length)) + '1';
                    next_state <= POINTS_LOOP_READ_Y;
                when POINTS_LOOP_READ_Y =>
                    next_index <= index + "010";
                    next_counter <= counter + "001";
                    next_reg(1) <= i_data;
                    next_state <= COMPUTE_DISTANCE;
                when COMPUTE_DISTANCE => --stato in cui si calcola la distanza di manhattan
                    if(reg(0) > x) then
                        next_distanceX <= reg(0) - x;
                    else
                        next_distanceX <= x - reg(0);
                    end if;
                    if(reg(1) > y) then
                        next_distanceY <= reg(1) - y;
                    else
                        next_distanceY <= y - reg(1);
                    end if;
                    next_state <= WRITE_DISTANCE;
                when WRITE_DISTANCE =>
                    next_distance <= std_logic_vector(to_unsigned(to_integer(unsigned(distanceX)) + to_integer(unsigned(distanceY)), 9));
                    next_state <= COMPUTE_MINIMUM_DISTANCE;
                when COMPUTE_MINIMUM_DISTANCE  => --stato in cui calcolo la distanza minore e la rappresento nell'array da 1 byte d'uscita
                   if(distance < distanceMin) then
                        next_distanceMin <= distance;
                        next_result <= "00000000";
                        next_result(to_integer(unsigned(counter)) - 1) <= '1';
                    elsif (distance = distanceMin) then
                        next_result(to_integer(unsigned(counter)) - 1) <= '1';
                    end if;
                    next_state <= POINTS_LOOP_INIT_READ;
                when DONE =>
                    if(write_enabled = '0') then
                        next_write_enabled <= '1';
                        o_en <= '1';
                        o_we <= '1';
                        o_address <= "0000000000010011";
                        o_data <= result;
                    else
                        o_done <= '1';
                        o_data <= result;
                        next_state <= IDLE;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
    end process; 
end Behavioral;