library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture control of servocontrol is

  signal cnt : unsigned(9 downto 0) := (others => '0');
	signal pwmi : unsigned(9 downto 0) := (others => '0');

  --signal pwm_gen : std_logic;
  type state is (idle,addr_rd,data_rd,move,hold);
  signal currentState : state:= idle;
  signal nextState: state:= idle;

begin

	-- State_trans describes the transitions of the states.
	state_trans: process(currentState,set) 
		begin
		case currentState is
			when idle =>
				report "state: idle";
				if set = '1' then
					report "go to addr_rd";
					nextState <= addr_rd;
				else
					nextState <= idle;
				end if;
			when addr_rd =>
				report "state: addr_rd";
				if set = '1' then
					report "set is high";
					report "address is "& integer'image(to_integer(address));
					report "data (address) is "&integer'image(to_integer(unsigned(data))); 
					if unsigned(data) = address then
						nextState <= data_rd;
						report "reading plaats";
					else
						report "holding";
						nextState <= hold;
						
					end if;
				else
					nextState <= idle;
					report "idling";
				
				end if;
					
			when data_rd =>
				report "state: data_rd";
				nextState <= move;
			when move =>
				report "state: move";
				nextState <= hold;
			when hold =>
				report "state: hold";
				if set ='1' then
					nextState <= addr_rd;
				elsif set ='0' then
					nextState <= hold;
				end if;
			when others =>
				nextState <= idle;
			end case;
			
	end process state_trans;

	-- Transition is the actual transition beteen states
	transition: process(rst,clk) begin
		if rst = '1' then
			currentState <= idle;
		elsif falling_edge(clk) then
			currentState <= nextState;
		end if;
	end process transition;

	-- set_output determines which output correspont with a state
	-- The done is defined so it works on bus structure, 3 state logic
	set_output: process(currentState,clk, nextState) begin
		if(rising_edge(clk)) then
			case currentState is
				when idle =>
					done <= '1';
				when addr_rd =>
					if(nextState=data_rd) then
						done <= '0';
					else
						done <='1';
					end if;
				when data_rd =>
					done <= '0';
				when move =>
					done <= '1';
				when hold =>
					done <= '1';
					
				when others =>
					-- done <= '-';
			end case;
		end if;
	end process set_output;

	-- pwm_data sets the amount of ticks needed to generate a correct duration with servo clock = 510kHz
	-- 1.25ms = 637 ticks, 1.5ms = 765 ticks, 1.75ms = 892 ticks
	pwm_data: process(currentState,clk) begin
		case currentState is
			when idle =>
				pwmi <= to_unsigned(765,10); -- values according to 510kHz servo clock.
			when move =>
				report "moving";
				
				report "setting value";
				if data > std_logic_vector(to_unsigned(255,8)) then
					report "255";
					pwmi <= to_unsigned(892,10);
				else
					report "setting ...";
					pwmi <= unsigned(data) + to_unsigned(637,10);
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
			if (cnt < 1023) then
				cnt <= cnt + 1;
			end if;
		end if;
	end process gen_pwm;
	-- one-liner is the actual code that generates the output signal
	-- pwm_gen <= '1' when (cnt < pwmi) else '0'; -- this only sends pwm signal when explicitly asked by set_output
	pwm <= '1' when (cnt < pwmi) else '0'; -- this holds the pwm signal at all times

end architecture control;
