library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity servocontrol is
	generic (
		address : unsigned(7 downto 0)
	);
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    sclk  : in std_logic;
    set   : in std_logic;
    data  : in std_logic_vector(7 downto 0);
    done  : out std_logic;
    pwm   : out std_logic
  );
end entity;
