library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture control of servocontrol is

  signal cnt : unsigned(9 downto 0);
	signal pwmi : unsigned(9 downto 0);
  --signal pwm_gen : std_logic;
  type state is (idle,addr_rd,data_rd,move,hold);
  signal currentState : state;
  signal nextState: state;

begin

	-- State_trans describes the transitions of the states.
	state_trans: process(rst,currentState,set,clk) begin
		if rst = '1' then
			nextState <= idle;
		else
			case currentState is
				when idle =>
					if set = '1' then
						nextState <= addr_rd;
					else
						nextState <= idle;
					end if;
				when addr_rd =>
					if falling_edge(clk) then
						if (set = '1' and (unsigned(data) = address or unsigned(data) = 255)) then
							nextState <= data_rd;
						elsif set ='0' then
							nextState <= idle;
						else
							nextState <= hold;
						end if;
					end if;
				when data_rd =>
					nextState <= move;
				when move =>
					nextState <= hold;
				when hold =>
					if set ='1' then
						nextState <= addr_rd;
					elsif set ='0' then
						nextState <= hold;
					end if;
				when others =>
					nextState <= idle;
				end case;
			end if;
	end process state_trans;

	-- Transition is the actual transition beteen states
	transition: process(clk) begin
		if rising_edge(clk) then
			currentState <= nextState;
		end if;
	end process transition;

	-- set_output determines which output correspont with a state
	-- The done is defined so it works on bus structure, 3 state logic
	set_output: process(currentState) begin
		case currentState is
			when idle =>
				done <= 'H';
				--pwm <= pwm_gen;
			when addr_rd =>
				done <= 'H';
			when data_rd =>
				done <= 'L';
			when move =>
				done <= 'L';
			when hold =>
				done <= 'H';
				--pwm <= pwm_gen;
			when others =>
				-- done <= '-';
		end case;
	end process set_output;

	-- pwm_data sets the amount of ticks needed to generate a correct duration with servo clock = 510kHz
	-- 1.25ms = 637 ticks, 1.5ms = 765 ticks, 1.75ms = 892 ticks
	pwm_data: process(currentState,clk) begin
		case currentState is
			when idle =>
				pwmi <= unsigned(765); -- values according to 510kHz servo clock.
			when move =>
				if falling_edge(clk) then
					if data >= 255 then
						pwmi <= unsigned(892);
					else
						pwmi <= unsigned('0' & data) + 637;
					end if;
				end if;
			when others =>
		end case;
	end process pwm_data;

	-- gen_pwm is a combination of the proces below and the one-liners below it.
	-- gen_pwm counts the amount of ticks according to sclk and resets every clk
	gen_pwm: process(clk, sclk) begin
		if rising_edge(clk) then
			cnt <= (others => '0');
		elsif rising_edge(sclk) then
			if cnt < 1023 then
				cnt <= cnt + 1;
			end if;
		end if;
	end process gen_pwm;
	-- one-liner is the actual code that generates the output signal
	-- pwm_gen <= '1' when (cnt < pwmi) else '0'; -- this only sends pwm signal when explicitly asked by set_output
	pwm <= '1' when (cnt < pwmi) else '0'; -- this holds the pwm signal at all times

end architecture control;