--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: ffD.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Flip-flop D con reset asincrónico.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity ffD is
port (
    clock			: in std_logic;
	a_reset			: in std_logic;
	en				: in std_logic;
    d				: in std_logic;
    q				: out std_logic;
	not_q			: out std_logic
);
end ffD;

architecture ff_behaviour of ffD is
	signal reg : std_logic;
begin
	q 		<= reg;
	not_q 	<= not reg;
	
	process(clock, a_reset)
	begin
		if (a_reset = '1') then
			reg <= '0';
		elsif rising_edge(clock) then
			if (en = '1') then
				reg <= d;
			end if;
		end if;
	end process;
end ff_behaviour;
