--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: mux.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Mux de 1 bit y de entrada y selección variable.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity mux is
	generic(
		nmbr_of_sel_lines : positive range 1 to 8 := 2
	);
port (
    input			: in std_logic_vector((2**nmbr_of_sel_lines - 1) downto 0);
    sel				: in std_logic_vector((nmbr_of_sel_lines - 1) downto 0);
	output			: out std_logic
);
end mux;

architecture mux_behaviour of mux is
begin
	output <= input(to_integer(unsigned(sel)));
end mux_behaviour;
