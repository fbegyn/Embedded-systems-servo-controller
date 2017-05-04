library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_servocontroller is
end;

architecture test of tb_servocontroller is

--component servocontroller_entity
--generic(
--	address: unsigned(7 downto 0)
--);
--port(
--	clk: in std_logic;
--	rst: in std_logic;
--	sclk: in std_logic;
--	set: in std_logic;
--	data: in std_logic_vector(7 downto 0);
--	done: out std_logic;
--	pwm: out std_logic
--);
--end component;

--inputs
signal clk: std_logic;
signal rst: std_logic;
signal sclk: std_logic;
signal set: std_logic;
signal data: std_logic_vector(7 downto 0);
--outputs
signal done: std_logic;
signal pwm: std_logic;
--clockperiodes
constant clkPeriod: time:= 20 ms;
constant sclkPeriod: time:=	1.960784 us; --aan te passen
constant dutyCycle: real :=0.5;
--end of simulation
signal EndOfSim: boolean:= false;


signal plaats: unsigned(7 downto 0):=(others => '0');
signal pwm_start: time;
signal pwm_stop: time;
begin


dut: entity work.servocontrol 
generic map( address => to_unsigned(1,8)
)
port map(
	clk => clk,
	rst => rst,
	sclk => sclk,
	set => set,
	data => data,
	done => done,
	pwm => pwm
);


clk_gen: process
begin 
	clk <= '0';
	wait for (1.0-dutyCycle)*clkPeriod;
	clk <= '1';
	wait for dutyCycle*clkPeriod;
	if EndOfSim then
		wait;
	end if;
end process clk_gen;

servoclk_gen: process
begin
	sclk <= '0';
	wait for (1.0-dutyCycle)*sclkPeriod;
	sclk <= '1';
	wait for dutyCycle*sclkPeriod;
	if EndOfSim then 
		wait;
	end if;
end process servoclk_gen; 




input_gen: process
begin
	rst<='1';
	wait until falling_edge(clk);
	rst<='0';
	wait until rising_edge(clk);
-- normale werking
	plaats <= (others => '0');
	while (plaats < 256) loop
		report " "&integer'image(to_integer(plaats));
		wait until rising_edge(clk);
		set <='1';
		data <=std_logic_vector(to_unsigned(1,8)); -- address sturen
		wait until falling_edge(clk);
		assert(done = '1')
		report "Done is "&std_logic'image(done)&", verwacht '1'"
		severity error;
		wait until rising_edge(clk);
		data <= std_logic_vector(plaats); -- positie sturen
		wait until falling_edge(clk);
		assert(done ='0')
		report "Done is "&std_logic'image(done)&", verwacht '0'"
		severity error;
		wait until rising_edge(clk);
		set <= '0';
		wait until falling_edge(clk);
		assert( done ='0')
		report "Done is "&std_logic'image(done)&", verwacht '0'"
		severity error;
		wait until rising_edge(pwm);
		pwm_start<=now;
		wait until falling_edge(pwm);
		pwm_stop<=now;
		wait until falling_edge(clk);
		--assert pwmsignaal juist
		assert(pwm_stop-pwm_start=1.25 ms + to_integer(plaats)*sclkPeriod)
		report "Fout PWM signaal"
		severity error;
		report time'image(pwm_stop-pwm_start)&" /= "&time'image(1.25 ms+to_integer(plaats)*sclkPeriod);
		
		wait until falling_edge(clk);
		assert(done ='1')
		report "Done is "&std_logic'image(done)&", verwacht '1'"
		severity error;
		plaats <= plaats+32;
		wait for 30 ms;
	end loop;

	EndOfSim <= true;
	wait;
end process;


end architecture;