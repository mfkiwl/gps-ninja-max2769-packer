--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: rx_manager.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Circuito encargado de habilitar la configuración SPI del max multiplexando las señales SPI de uno de los gumstix.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity rx_manager is
port (
    SPI1_clk	: in std_logic;
	SPI2_clk	: in std_logic;
	SPI3_clk	: in std_logic;
	SPI1_MOSI	: in std_logic;
	SPI2_MOSI	: in std_logic;
	SPI3_MOSI	: in std_logic;
	SPI1_nCS	: in std_logic;
	SPI2_nCS	: in std_logic;
	SPI3_nCS	: in std_logic;
	s1			: in std_logic;
    s2			: in std_logic;
	s3			: in std_logic;
	g1			: in std_logic;
    g2			: in std_logic;
	g3			: in std_logic;
	SPImax_clk	: out std_logic;
	SPImax_MOSI	: out std_logic;
	SPImax_nCS	: out std_logic
);
end rx_manager;

architecture rx_manager_behaviour of rx_manager is

	signal rx_control 			: std_logic_vector(1 downto 0):= (others => '0');
	signal SPI_clk_mux_input 	: std_logic_vector(3 downto 0) := (others => '0');
	signal SPI_MOSI_mux_input 	: std_logic_vector(3 downto 0) := (others => '0');
	signal SPI_nCS_mux_input 	: std_logic_vector(3 downto 0) := (others => '0');

	component mux
		generic(
			nmbr_of_sel_lines : positive range 1 to 8 := 2
		);
		port (
    		input			: in std_logic_vector((2**nmbr_of_sel_lines - 1) downto 0);
    		sel				: in std_logic_vector((nmbr_of_sel_lines-1) downto 0);
			output			: out std_logic
		);
	end component;

	component rx_controller
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
	end component;
begin
	--Control de las señales SPI al MAX
	rx_controller_inst : rx_controller
		port map(
			s1			=> s1,
			s2			=> s2,
			s3			=> s3,
			g1			=> g1,
			g2			=> g2,
			g3			=> g3,
			rx_ctrl		=> rx_control,
			rdy_to_rx	=> open
		);

	--Multiplexación de los SPI_clock de los tres gumstix para atacar el SPI_clock del MAX
	SPI_clk_mux_input(0) <= '0';
	SPI_clk_mux_input(1) <= SPI1_clk;
	SPI_clk_mux_input(2) <= SPI2_clk;
	SPI_clk_mux_input(3) <= SPI3_clk;

	mux_SPI_clk_inst : mux 
		generic map(
			nmbr_of_sel_lines => 2
		)
		port map (
			input 	=> SPI_clk_mux_input,
			sel 	=> rx_control,
			output	=> SPImax_clk
		);

	--Multiplexación de los MISO de los tres gumstix para atacar el MISO del MAX
	SPI_MOSI_mux_input(0) <= '0';
	SPI_MOSI_mux_input(1) <= SPI1_MOSI;
	SPI_MOSI_mux_input(2) <= SPI2_MOSI;
	SPI_MOSI_mux_input(3) <= SPI3_MOSI;

	mux_SPI_MOSI_inst : mux 
		generic map(
			nmbr_of_sel_lines => 2
		)
		port map (
			input 	=> SPI_MOSI_mux_input,
			sel 	=> rx_control,
			output	=> SPImax_MOSI
		);


	--Multiplexación de los CS de los tres gumstix para atacar el CS del MAX
	SPI_nCS_mux_input(0) <= '1';
	SPI_nCS_mux_input(1) <= SPI1_nCS;
	SPI_nCS_mux_input(2) <= SPI2_nCS;
	SPI_nCS_mux_input(3) <= SPI3_nCS;

	mux_SPI_nCS_inst : mux 
		generic map(
			nmbr_of_sel_lines => 2
		)
		port map (
			input 	=> SPI_nCS_mux_input,
			sel 	=> rx_control,
			output	=> SPImax_nCS
		);

end rx_manager_behaviour;
