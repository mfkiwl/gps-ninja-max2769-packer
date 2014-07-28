--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: tx_controller.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Circuito de control de transmisión de datos por SPI a uno de los gumstix
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity tx_controller is
port (
    s1			: in std_logic;
    s2			: in std_logic;
	s3			: in std_logic;
	g1			: in std_logic;
    g2			: in std_logic;
	g3			: in std_logic;
	tx_ctrl		: out std_logic_vector(1 downto 0);
	rdy_to_tx	: out std_logic
);
end tx_controller;

architecture tx_controller_behaviour of tx_controller is
begin
	process(s1, s2, s3, g1, g2, g3)
	begin
		if(s1 = '1' and g1 = '0') then --El gumstix1 configura el MAX
			tx_ctrl 	<= "01";
			rdy_to_tx 	<= '1';
		elsif (s2 = '1' and g2 = '0') then --El gumstix2 configura el MAX
			tx_ctrl 	<= "10";
			rdy_to_tx 	<= '1';
		elsif(s3 = '1' and g3 = '0') then --El gumstix3 configura el MAX
			tx_ctrl 	<= "11";
			rdy_to_tx 	<= '1';
		else						--Las señales SPI del MAX quedan desconectadas de todo gumstix
			tx_ctrl 	<= "00";
			rdy_to_tx 	<= '0';
		end if;
	end process;
end tx_controller_behaviour;
