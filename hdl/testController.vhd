--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: testController.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Máquina de estados que maneja el modo TEST.
-- Con una señal Gx en 1, se configura el MAX con el gumstix x. La primera vez que se pone Gx en 0, el gumstix puede recibir datos por SPI en modo test.
--
-- Targeted device: <Family::IGLOO> <Die::AGL125V5> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity testController is
port (
   	clock	: in std_logic;
   	a_reset : in std_logic;
    g1 		: in std_logic;
    g2 		: in std_logic;
	g3 		: in std_logic;
	s1		: in std_logic;
	s2		: in std_logic;
	s3		: in std_logic;
	test_on	: out std_logic
);
end testController;

architecture testController_behaviour of testController is
	
	type status is (STANDBY, CONF_ON, TEST_MODE_ON, TEST_MODE_OFF);

	signal current_state 	: status := STANDBY;
	signal next_state		: status;

begin
	
	--Proceso combinacional de la máquina de estados
	comb_process: process(current_state, g1, g2, g3, s1, s2, s3)
	begin
		case current_state is
			when STANDBY	=>
				test_on  <= '0';
				if (g1 = '1' or g2 = '1' or g3 = '1') then
					next_state <= CONF_ON;
				else
					next_state <= STANDBY;
				end if;
			when CONF_ON =>
				test_on  <= '0';
				if ((s1 = '1' and g1 = '0') or (s2 = '1' and g2 = '0') or (s3 = '1' and g3 = '0')) then
					next_state <= TEST_MODE_ON;
				else
					next_state <= CONF_ON;
				end if;
			when TEST_MODE_ON =>
				test_on  <= '1';
				if ((s1 = '1' and g1 = '1') or (s2 = '1' and g2 = '1') or (s3 = '1' and g3 = '1')) then
					next_state <= TEST_MODE_OFF;
				else
					next_state <= TEST_MODE_ON;
				end if;
			when TEST_MODE_OFF => --El modo test solo dura la primera vez que gx baja a cero.
				test_on  <= '0';
				next_state <= TEST_MODE_OFF;
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
end testController_behaviour;
