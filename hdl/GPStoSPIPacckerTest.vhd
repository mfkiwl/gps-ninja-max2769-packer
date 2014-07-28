--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: GPStoSPIPacckerTest.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::IGLOO> <Die::AGLN125V2> <Package::100 VQFP>
-- Author: <Name>
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity GPStoSPIPacckerTest is
port (
    MAX_clockout	: in std_logic;
		MAX_I0			: in std_logic;
		MAX_I1			: in std_logic;
		MAX_Q0			: in std_logic;
		MAX_Q1			: in std_logic;
		LD				: in std_logic;

		FPGA_clock		: in std_logic;
		nReset			: in std_logic;

		G1_select 		: in std_logic;
    	--G2_select 		: in std_logic;
		--G3_select 		: in std_logic;

 		SPI1_SCK		: in std_logic;
		--SPI2_SCK		: in std_logic;
		--SPI3_SCK		: in std_logic;
		SPI1_nCS		: in std_logic;
		--SPI2_nCS		: in std_logic;
		--SPI3_nCS		: in std_logic;
		SPI1_MOSI		: in std_logic;
		--SPI2_MOSI		: in std_logic;
		--SPI3_MOSI		: in std_logic;
		SPI1_MISO		: out std_logic;
		--SPI2_MISO		: out std_logic;
		--SPI3_MISO		: out std_logic;
		SPI1_IRQ		: out std_logic;
		--SPI2_IRQ		: out std_logic;
		--SPI3_IRQ		: out std_logic;

		SPI_max_clk		: out std_logic;
		SPI_max_nCS		: out std_logic;
		SPI_max_data	: out std_logic;
		
		TP_35			: out std_logic;
		TP_36			: out std_logic;
		TP_37			: out std_logic;
		TP_38			: out std_logic
);
end GPStoSPIPacckerTest;

architecture GPStoSPIPacckerTest_behaviour of GPStoSPIPacckerTest is

	signal G2_select : std_logic;
	signal SPI2_SCK : std_logic;
	signal SPI2_nCS : std_logic;
	signal SPI2_MOSI : std_logic;

	signal G3_select : std_logic;
	signal SPI3_SCK : std_logic;
	signal SPI3_nCS : std_logic;
	signal SPI3_MOSI : std_logic;

component GPStoSPIPacker is
	generic (
		IRQ_threshold 	: positive := 32;	--Cantidad de palabras que tiene que tener la FIFO para subir el IRQ. Puede ser menor al número de palabras que se leen. El umbral debe elegirse mediante simulación. Con este umbral se esperan leer 64 palabras
		IQ				: natural range 0 to 4 := 4 --0: I0; 1: I1-I0; 2: I1-I0-Q1; 3: I0 Q0; 4: I1-I0 Q1-Q0
	);
	port (
    	MAX_clockout	: in std_logic;
		MAX_I0			: in std_logic;
		MAX_I1			: in std_logic;
		MAX_Q0			: in std_logic;
		MAX_Q1			: in std_logic;
		LD				: in std_logic;
		FPGA_clock		: in std_logic;
		nReset			: in std_logic;
		G1_select 		: in std_logic;
    	G2_select 		: in std_logic;
		G3_select 		: in std_logic;
 		SPI1_SCK		: in std_logic;
		SPI2_SCK		: in std_logic;
		SPI3_SCK		: in std_logic;
		SPI1_nCS		: in std_logic;
		SPI2_nCS		: in std_logic;
		SPI3_nCS		: in std_logic;
		SPI1_MOSI		: in std_logic;
		SPI2_MOSI		: in std_logic;
		SPI3_MOSI		: in std_logic;
		SPI1_MISO		: out std_logic;
		SPI2_MISO		: out std_logic;
		SPI3_MISO		: out std_logic;
		SPI1_IRQ		: out std_logic;
		SPI2_IRQ		: out std_logic;
		SPI3_IRQ		: out std_logic;

		SPI_max_clk		: out std_logic;
		SPI_max_nCS		: out std_logic;
		SPI_max_data	: out std_logic;

		TP_35			: out std_logic;
		TP_36			: out std_logic;
		TP_37			: out std_logic;
		TP_38			: out std_logic
	);
end component;

begin
	--fpga_clock_test <= FPGA_clock;

	G2_select <= '0';
	SPI2_SCK  <= '0';
	SPI2_MOSI <= '0';
	SPI2_nCS  <= '1';

	G3_select <= '0';
	SPI3_SCK  <= '0';
	SPI3_MOSI <= '0';
	SPI3_nCS  <= '1';

	GPStoSPIPacker_inst : GPStoSPIPacker
	generic map(
		IRQ_threshold 	=> 32,
		IQ				=> 1
	)
	port map (
		MAX_clockout	=> MAX_clockout,
		MAX_I0			=> MAX_I0,
		MAX_I1			=> MAX_I1,
		MAX_Q0			=> MAX_Q0,
		MAX_Q1			=> MAX_Q1,
		LD				=> LD,
		FPGA_clock		=> FPGA_clock,
		nReset			=> nReset,
		G1_select 		=> G1_select,
    	G2_select 		=> G2_select,
		G3_select 		=> G3_select,
 		SPI1_SCK		=> SPI1_SCK,
		SPI2_SCK		=> SPI2_SCK,
		SPI3_SCK		=> SPI3_SCK,
		SPI1_nCS		=> SPI1_nCS,
		SPI2_nCS		=> SPI2_nCS,
		SPI3_nCS		=> SPI3_nCS,
		SPI1_MOSI		=> SPI1_MOSI,
		SPI2_MOSI		=> SPI2_MOSI,
		SPI3_MOSI		=> SPI3_MOSI,
		SPI1_MISO		=> SPI1_MISO,
		SPI2_MISO		=> open,
		SPI3_MISO		=> open,
		SPI1_IRQ		=> SPI1_IRQ,
		SPI2_IRQ		=> open,
		SPI3_IRQ		=> open,
		SPI_max_clk		=> SPI_max_clk,
		SPI_max_nCS		=> SPI_max_nCS,
		SPI_max_data	=> SPI_max_data,
		TP_35			=> TP_35,
		TP_36			=> TP_36,
		TP_37			=> TP_37,
		TP_38			=> TP_38
	);

end GPStoSPIPacckerTest_behaviour;
