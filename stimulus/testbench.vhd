----------------------------------------------------------------------
-- Created by Actel SmartDesign Sun Apr 06 17:24:10 2014
-- Testbench Template
-- This is a basic testbench that instantiates your design with basic 
-- clock and reset pins connected.  If your design has special
-- clock/reset or testbench driver requirements then you should 
-- copy this file and modify it. 
----------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: testbench.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: <Name>
--
--------------------------------------------------------------------------------


library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity testbench is
end testbench;

architecture behavioral of testbench is

    constant FPGA_clk_period 		: time := 40 ns; --25MHz
	constant SPI_read_clk_period 	: time := 21 ns; --47.6MHz
	constant SPI_write_clk_period 	: time := 25 ns; --40MHz
	constant MAX_clock_period		: time := 125 ns; --8MHz

	constant MOSI_vector			: std_logic_vector(7 downto 0) := "10101010";

    signal FPGA_clk 		: std_logic := '0';
	signal SPI1_clk			: std_logic := '0';
	signal SPI_read_clk 	: std_logic := '0';
	signal SPI_write_clk 	: std_logic := '0';
	signal maxclockout	 	: std_logic := '0';
    signal nReset 			: std_logic := '0';

	signal G1_select		: std_logic := '0';
	signal SPI1_MOSI		: std_logic := '0';
	signal SPI1_nCS			: std_logic := '1';

	signal SPI_max_clk	: std_logic := '0';
	signal SPI_max_nCS	: std_logic := '1';
	signal SPI_max_data	: std_logic := '0';

	signal read_SPI : std_logic := '0';
	signal write_SPI : std_logic := '0';

	signal LD 			: std_logic := '0';

	signal MAX_I0		: std_logic := '0';
	signal MAX_I1		: std_logic := '1';
	signal MAX_Q0		: std_logic := '0';
	signal MAX_Q1		: std_logic := '1';

	signal SPI1_MISO : std_logic := '0';
	signal SPI1_IRQ : std_logic := '0';

    component GPStoSPIPacker
        -- ports
        port( 
            -- Inputs
            MAX_clockout : in std_logic;
            MAX_I0 : in std_logic;
            MAX_I1 : in std_logic;
            MAX_Q0 : in std_logic;
            MAX_Q1 : in std_logic;
            LD : in std_logic;
            FPGA_clock : in std_logic;
            nReset : in std_logic;
            G1_select : in std_logic;
            G2_select : in std_logic;
            G3_select : in std_logic;
            SPI1_SCK : in std_logic;
            SPI2_SCK : in std_logic;
            SPI3_SCK : in std_logic;
            SPI1_nCS : in std_logic;
            SPI2_nCS : in std_logic;
            SPI3_nCS : in std_logic;
            SPI1_MOSI : in std_logic;
            SPI2_MOSI : in std_logic;
            SPI3_MOSI : in std_logic;

            -- Outputs
            SPI1_MISO : out std_logic;
            SPI2_MISO : out std_logic;
            SPI3_MISO : out std_logic;
            SPI1_IRQ : out std_logic;
            SPI2_IRQ : out std_logic;
            SPI3_IRQ : out std_logic;
            SPI_max_clk : out std_logic;
            SPI_max_nCS : out std_logic;
            SPI_max_data : out std_logic

            -- Inouts

        );
    end component;

begin

	--Proceso de reset
    process
        variable vhdl_initial : BOOLEAN := TRUE;

    begin
        if ( vhdl_initial ) then
            --Reset
            nReset <= '0';
            wait for ( FPGA_clk_period * 10 ); --400ns
            nReset <= '1';
			wait;
        end if;
    end process;

	process
	begin
		 wait for ( FPGA_clk_period * 20 ); --800ns
		 wait until rising_edge(FPGA_clk); --Solo para que G1_select suba en flanco positivo (el módulo lo registra en el flanco negativo)
		--Comienza la escritura SPI del MAX
		G1_select <= '1';
		wait for ( FPGA_clk_period * 10 ); --1200ns
		--Se comienza una transferencia SPI al max
		SPI1_nCS <= '0';
		wait until falling_edge(SPI_write_clk);
		write_SPI <= '1';
		--Se envia una palabra
		for i in 7 downto 0 loop
			SPI1_MOSI <= MOSI_vector(i);
			wait until falling_edge(SPI_write_clk);
		end loop;
		SPI1_nCS <= '1';
		--Fin de la transferencia SPI al max
		write_SPI <= '0';
		LD  <= '1'; --El max está listo
		wait for ( FPGA_clk_period * 10 );
		
		G1_select <= '0'; --Comienza la lectura en modo test

		reading_test : loop
			wait until SPI1_IRQ = '1';
			wait for  ( FPGA_clk_period * 2 ); --Solo para esperar un tiempito
			wait until falling_edge(SPI_read_clk);
			--El micro ya puede leer
			SPI1_nCS <= '0';
			read_SPI <= '1';
			for i in 0 to 64*16 loop --Se leen 64 palabras
				wait until rising_edge(SPI_read_clk);
			end loop;

			SPI1_nCS <= '1';
			read_SPI <= '0';
		end loop;

		wait for  ( FPGA_clk_period * 2 ); --Solo para esperar un tiempito
		G1_select <= '1'; --Comienza la lectura en modo configuracion

		wait for  ( FPGA_clk_period * 20 ); --Solo para esperar un tiempito
		G1_select <= '0'; --Comienza la lectura en modo real

		reading : loop
			wait until SPI1_IRQ = '1';
			wait for  ( FPGA_clk_period * 2 ); --Solo para esperar un tiempito
			wait until falling_edge(SPI_read_clk);
			--El micro ya puede leer
			SPI1_nCS <= '0';
			read_SPI <= '1';
			for i in 0 to 64*16 loop --Se leen 64 palabras
				wait until rising_edge(SPI_read_clk);
			end loop;

			SPI1_nCS <= '1';
			read_SPI <= '0';
		end loop;

		wait;
	end process;

	--Simula la salida de datos del max con un contador de 4 bits (de 0 a 15)
	process	
		variable counter : std_logic_vector(3 downto 0) := "0000";
	begin
		wait until rising_edge(maxclockout);
		MAX_I0 <= counter(0);
		MAX_I1 <= counter(1);
		MAX_Q0 <= counter(2);
		MAX_Q1 <= counter(3);
		counter := std_logic_vector(unsigned(counter) + 1);
	end process;


    -- 25MHz FPGA Clock Driver
    FPGA_clk <= not FPGA_clk after (FPGA_clk_period / 2.0 );

	-- 50MHz SPI read Clock Driver
    SPI_read_clk <= not SPI_read_clk after (SPI_read_clk_period / 2.0 );

	-- 40MHz SPI write Clock Driver
    SPI_write_clk <= not SPI_write_clk after (SPI_write_clk_period / 2.0 );


	-- 8MHz MAX clock Driver
	maxclockout <= not maxclockout after (MAX_clock_period / 2.0);

	SPI1_clk <= SPI_read_clk when read_SPI = '1' else
				SPI_write_clk when write_SPI = '1' else
				'0';


    -- Instantiate Unit Under Test:  GPStoSPIPacker
    GPStoSPIPacker_0 : GPStoSPIPacker
        -- port map
        port map( 
            -- Inputs
            MAX_clockout 	=> maxclockout,
            MAX_I0 			=> MAX_I0,
            MAX_I1 			=> MAX_I1,
            MAX_Q0 			=> MAX_Q0,
            MAX_Q1 			=> MAX_Q1,
            LD 				=> LD,
            FPGA_clock		=> FPGA_clk,
            nReset 			=> nReset,
            G1_select 		=> G1_select,
            G2_select => '0',
            G3_select => '0',
            SPI1_SCK 		=> SPI1_clk,
            SPI2_SCK => '0',
            SPI3_SCK => '0',
            SPI1_nCS 		=> SPI1_nCS,
            SPI2_nCS => '0',
            SPI3_nCS => '0',
            SPI1_MOSI 		=> SPI1_MOSI,
            SPI2_MOSI => '0',
            SPI3_MOSI => '0',

            -- Outputs
            SPI1_MISO 		=>  SPI1_MISO,
            SPI2_MISO =>  open,
            SPI3_MISO =>  open,
            SPI1_IRQ 		=>  SPI1_IRQ,
            SPI2_IRQ =>  open,
            SPI3_IRQ =>  open,
            SPI_max_clk 	=>  SPI_max_clk,
            SPI_max_nCS 	=>  SPI_max_nCS,
            SPI_max_data 	=>  SPI_max_data

            -- Inouts

        );


end behavioral;

