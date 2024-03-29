library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_servocontroller is
end;

architecture test of tb_servocontroller is


--inputs dut
signal clk: std_logic;
signal rst: std_logic;
signal sclk: std_logic;
signal set: std_logic;
signal data: std_logic_vector(7 downto 0);
--outputs dut
signal done: std_logic;
signal pwm: std_logic;
--timing
constant clkPeriod: time:= 20 ms;
constant sclkPeriod: time:= 1.960784 us; --aan te passen
constant dutyCycle: real := 0.5;
constant idle_time: time:= 1.5 ms;
constant min_time: time:= 1.25 ms;
constant tol: real:= 1.0;
--end of simulation
signal EndOfSim: boolean:= false;


signal plaats: unsigned(8 downto 0):=(others => '0');
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
		report "normale werking, plaats is "&integer'image(to_integer(plaats));
		wait until rising_edge(clk);
		set <='H';
		data <=std_logic_vector(to_unsigned(1,data'length)); -- address sturen
		wait until falling_edge(clk);
		assert(done = 'H')
		report "Done is "&std_logic'image(done)&", verwacht 'H'"
		severity error;
		wait until rising_edge(clk);
		data <= std_logic_vector(plaats(7 downto 0)); -- positie sturen
		wait until falling_edge(clk);
		assert(done ='L')
		report "Done is "&std_logic'image(done)&", verwacht 'L'"
		severity error;
		wait until rising_edge(clk);
		set <= 'L';
		wait until falling_edge(clk);
		assert( done ='L')
		report "Done is "&std_logic'image(done)&", verwacht 'L'"
		severity error;
		wait until rising_edge(pwm);
		pwm_start<=now;
		wait until falling_edge(pwm);
		pwm_stop<=now;
		wait until falling_edge(clk);
		--assert pwmsignaal juist
		assert(abs(((pwm_stop-pwm_start)-(min_time+ to_integer(plaats)*sclkPeriod)))<sclkPeriod*tol)
		report "Fout PWM signaal: " &time'image(pwm_stop-pwm_start)&" /= "&time'image(min_time+to_integer(plaats)*sclkPeriod)
		severity error;
		wait until falling_edge(clk);
		assert(done ='H')
		report "Done is "&std_logic'image(done)&", verwacht 'H'"
		severity error;
		plaats <= plaats+32;
		wait for 1 ms;
	end loop;
	
	--reset test (plaats =224)
	plaats <= to_unsigned(224,9);
	wait for 1 ms;
	report "Reset test";
	wait until rising_edge(clk);
	set <='H';
	data <=std_logic_vector(to_unsigned(1,data'length)); -- address sturen
	wait until falling_edge(clk);
	assert(done = 'H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait for 5 ms;
	rst <='1';
	wait for 1 ms;
	rst <='0';
	wait until rising_edge(clk);
	data <= std_logic_vector(plaats(7 downto 0)); -- positie sturen
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(clk);
	set <= 'L';
	wait until falling_edge(clk);
	assert( done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(pwm);
	pwm_start<=now;
	wait until falling_edge(pwm);
	pwm_stop<=now;
	wait until falling_edge(clk);
	--assert pwmsignaal juist
	assert(abs((pwm_stop-pwm_start)-idle_time)<sclkPeriod*tol)
	report "Fout PWM signaal: "& time'image(pwm_stop-pwm_start)&" /= "&time'image(idle_time)
	severity error;
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	
	
	
	--Test Broadcast address (plaats =224)
	report "Test broadcast adres, plaats ="&integer'image(to_integer(plaats));
	wait until rising_edge(clk);
	set <='H';
	data <=std_logic_vector(to_unsigned(255,data'length)); -- address sturen
	wait until rising_edge(clk);
	data <= std_logic_vector(plaats(7 downto 0)); -- positie sturen
	wait until rising_edge(clk);
	set <= 'L';
	wait until rising_edge(clk);
	wait until rising_edge(pwm);
	pwm_start<=now;
	wait until falling_edge(pwm);
	pwm_stop<=now;
	wait until falling_edge(clk);
	--assert pwmsignaal juist
	assert(abs((pwm_stop-pwm_start)-(min_time+ to_integer(plaats)*sclkPeriod))<sclkPeriod*tol)
	report "Fout PWM signaal: "& time'image(pwm_stop-pwm_start)&" /= "&time'image(min_time+to_integer(plaats)*sclkPeriod)
	severity error;
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	
	--wrong address (huidige hold plaats= 224 )
	plaats <= to_unsigned(32,9);
	wait for 1 ms;
	report "Geef fout adres mee";
	wait until rising_edge(clk);
	set <='H';
	data <=std_logic_vector(to_unsigned(2,data'length)); -- address sturen
	wait until falling_edge(clk);
	assert(done = 'H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(clk);
	data <= std_logic_vector(plaats(7 downto 0)); -- positie sturen
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(clk);
	set <= 'L';
	wait until falling_edge(clk);
	assert( done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(pwm);
	pwm_start<=now;
	wait until falling_edge(pwm);
	pwm_stop<=now;
	wait until falling_edge(clk);
	--assert pwmsignaal juist (vorige positie)
	assert(abs((pwm_stop-pwm_start)-(min_time+ 224*sclkPeriod))<sclkPeriod*tol)
	report "Fout PWM signaal: "& time'image(pwm_stop-pwm_start)&" /= "&time'image(min_time+224*sclkPeriod)
	severity error;
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait for 1 ms;
	
	--no position set after address sent (set goes to 0 on next clk pulse)
	report "no position sent after address sent (set ='0' op volgende klokperiode)";
	wait until rising_edge(clk);
	set <='H';
	data <=std_logic_vector(to_unsigned(1,data'length)); -- address sturen
	wait until falling_edge(clk);
	assert(done = 'H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(clk);
	set <='L';
	wait until falling_edge(clk);
	assert(done ='L')
	report "Done is "&std_logic'image(done)&", verwacht 'L'"
	severity error;
	wait until rising_edge(clk);
	wait until falling_edge(clk);
	assert( done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(pwm);
	pwm_start<=now;
	wait until falling_edge(pwm);
	pwm_stop<=now;
	wait until falling_edge(clk);
	--assert pwmsignaal juist (idle positie)
	assert(abs((pwm_stop-pwm_start)-idle_time)<sclkPeriod*tol)
	report "Fout PWM signaal: "& time'image(pwm_stop-pwm_start)&" /= "&time'image(idle_time)
	severity error;
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait for 1 ms;
	
	
	--set =0 voor volgende puls
	report "no position sent after address sent (set ='0' voor volgende klokperiode)";
	wait until rising_edge(clk);
	set <='H';
	data <=std_logic_vector(to_unsigned(1,data'length)); -- address sturen
	wait until falling_edge(clk);
	assert(done = 'H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait for 5 ms;
	set <='L';
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(clk);
	wait until falling_edge(clk);
	assert( done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait until rising_edge(pwm);
	pwm_start<=now;
	wait until falling_edge(pwm);
	pwm_stop<=now;
	wait until falling_edge(clk);
	--assert pwmsignaal juist (idle positie)
	assert(abs((pwm_stop-pwm_start)-idle_time)<sclkPeriod*tol)
	report "Fout PWM signaal: "& time'image(pwm_stop-pwm_start)&" /= "&time'image(idle_time)
	severity error;
	wait until falling_edge(clk);
	assert(done ='H')
	report "Done is "&std_logic'image(done)&", verwacht 'H'"
	severity error;
	wait for 1 ms;
	
	
	rst<='1';
	wait until falling_edge(clk);
	rst<='0';
	wait until rising_edge(clk);
-- normale werking
	plaats <= (others => '0');
	wait for 1 ms;
	while (plaats < 60) loop
		report "normale werking zonder testen, plaats is "&integer'image(to_integer(plaats));
		wait until rising_edge(clk);
		set <='H';
		data <=std_logic_vector(to_unsigned(1,data'length)); -- address sturen
		wait until rising_edge(clk);
		data <= std_logic_vector(plaats(7 downto 0)); -- positie sturen
		wait until rising_edge(clk);
		set <= 'L';
		wait until falling_edge(clk);
		plaats <= plaats+27;
		
		wait for 1 ms;
	end loop;
	wait until rising_edge(pwm);
	pwm_start<=now;
	wait until falling_edge(pwm);
	pwm_stop<=now;
	wait until falling_edge(clk);
	--assert pwmsignaal juist (54)
	assert(abs((pwm_stop-pwm_start)-(min_time+ 54*sclkPeriod))<sclkPeriod*tol)
	report "Fout PWM signaal: "& time'image(pwm_stop-pwm_start)&" /= "&time'image(min_time+54*sclkPeriod)
	severity error;
	wait for 1 ms;

	EndOfSim <= true;
	wait;
end process;


end architecture;