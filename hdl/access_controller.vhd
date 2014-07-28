--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: access_controller.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
-- Máquina de estados que elige qué gumstix opera con el circuito.
--
-- <Description here>
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity access_controller is
	port (
		clock	: in std_logic;
   		a_reset : in std_logic;
    	g1 		: in std_logic;
    	g2 		: in std_logic;
		g3 		: in std_logic;
		s1		: out std_logic;
		s2		: out std_logic;
		s3		: out std_logic
	);
end access_controller;

architecture access_controller_behaviour of access_controller is
	
	type status is (STANDBY, GUMSTIX1, GUMSTIX2, GUMSTIX3);

	signal current_state 	: status := STANDBY;
	signal next_state		: status;

begin
	--Proceso combinacional de la máquina de estados
	comb_process: process(current_state, g1, g2, g3)
	begin
		s1 <= '0';
		s2 <= '0';
		s3 <= '0';

		case current_state is
			when STANDBY	=>
				if (g1 = '1') then
					next_state <= GUMSTIX1;
				elsif (g2 = '1') then
					next_state <= GUMSTIX2;
				elsif (g3 = '1') then
					next_state <= GUMSTIX3;
				else
					next_state <= STANDBY;
				end if;
			when GUMSTIX1	=>
				s1 <= '1';
				next_state <= GUMSTIX1;
			when GUMSTIX2	=>
				s2 <= '1';
				next_state <= GUMSTIX2;
			when GUMSTIX3	=>
				s3 <= '1';
				next_state <= GUMSTIX3;
		end case;
	end process;


	--Proceso secuencial de la máquina de estados.
	seq_process: process(clock, a_reset)
	begin
		if (a_reset = '1') then
			current_state 	<= STANDBY;
		elsif rising_edge(clock) then
			current_state	<= next_state;
		end if;
	end process;
end access_controller_behaviour;
