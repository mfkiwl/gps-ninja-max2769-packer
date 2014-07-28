--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: ffSR.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Flip-Flop SR con clear y set asincrónicos.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity ffSR is
port (
    clock			: in std_logic;
	a_reset			: in std_logic;
	a_set			: in std_logic;
	r				: in std_logic;
    s				: in std_logic;
    q				: out std_logic
);
end ffSR;

architecture ffSR_behaviour of ffSR is

begin
	
	process(clock, a_reset, a_set)
	begin
		if (a_reset = '1') then
			q <= '0';
		elsif (a_set = '1') then
			q <= '1';
		elsif rising_edge(clock) then
			if (r = '1') then
				q <= '0';
			elsif (s = '1') then
				q <= '1';
			end if;
		end if;
	end process;

end ffSR_behaviour;

