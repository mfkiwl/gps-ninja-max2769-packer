--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: rx_controller.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Circuito de control de recepción de datos por SPO para configurar el módulo GPS MAX2769.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity rx_controller is
port (
    s1			: in std_logic;
    s2			: in std_logic;
	s3			: in std_logic;
	g1			: in std_logic;
    g2			: in std_logic;
	g3			: in std_logic;
	rx_ctrl		: out std_logic_vector(1 downto 0);
	rdy_to_rx	: out std_logic
);
end rx_controller;

architecture rx_controller_behaviour of rx_controller is
begin
	process(s1, s2, s3, g1, g2, g3)
	begin
		if(s1 = '1' and g1 = '1') then --El gumstix1 configura el MAX
			rx_ctrl <= "01";
			rdy_to_rx <= '1';
		elsif (s2 = '1' and g2 = '1') then --El gumstix2 configura el MAX
			rx_ctrl <= "10";
			rdy_to_rx <= '1';
		elsif(s3 = '1' and g3 = '1') then --El gumstix3 configura el MAX
			rx_ctrl <= "11";
			rdy_to_rx <= '1';
		else						--Las señales SPI del MAX quedan desconectadas de todo gumstix
			rx_ctrl <= "00";
			rdy_to_rx <= '0';
		end if;
	end process;
end rx_controller_behaviour;
