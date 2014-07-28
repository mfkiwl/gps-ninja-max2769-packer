----------------------------------------------------------------------
-- Created by Actel SmartDesign Mon Apr 14 14:22:44 2014
-- Testbench Template
-- This is a basic testbench that instantiates your design with basic 
-- clock and reset pins connected.  If your design has special
-- clock/reset or testbench driver requirements then you should 
-- copy this file and modify it. 
----------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: test_testbench.vhd
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


library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity test_testbench is
end test_testbench;

architecture behavioral of test_testbench is

    constant FPGA_clk_period 		: time := 40 ns; --25MHz
	constant SPI_read_clk_period 	: time := 41.66 ns; --83.33 ns; --12MHz --21 ns; --47.6MHz
	constant SPI_write_clk_period 	: time := 25 ns; --40MHz
	constant MAX_clock_period		: time := 250 ns; --125 ns; --8MHz

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

	signal TP_35			: std_logic := '0';
	signal TP_36	: std_logic := '0';
	signal TP_37	: std_logic := '0';
	signal TP_38	: std_logic := '0';

	signal read_SPI : std_logic := '0';
	signal write_SPI : std_logic := '0';

	signal LD 			: std_logic := '0';

	signal MAX_I0		: std_logic := '0';
	signal MAX_I1		: std_logic := '1';
	signal MAX_Q0		: std_logic := '0';
	signal MAX_Q1		: std_logic := '1';

	signal SPI1_MISO : std_logic := '0';
	signal SPI1_IRQ : std_logic := '0';

    component GPStoSPIPacckerTest
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
            --G3_select : in std_logic;
            SPI1_SCK : in std_logic;
            --SPI3_SCK : in std_logic;
            SPI1_nCS : in std_logic;
            --SPI3_nCS : in std_logic;
            SPI1_MOSI : in std_logic;
            --SPI3_MOSI : in std_logic;

            -- Outputs
            SPI1_MISO : out std_logic;
            --SPI3_MISO : out std_logic;
            SPI1_IRQ : out std_logic;
            --SPI3_IRQ : out std_logic;
            SPI_max_clk : out std_logic;
            SPI_max_nCS : out std_logic;
            SPI_max_data : out std_logic;

			TP_35			: out std_logic;
			TP_36			: out std_logic;
			TP_37			: out std_logic;
			TP_38			: out std_logic

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
		variable test_loops : integer := 3;
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



		wait for  ( FPGA_clk_period * 15000 ); --Solo para esperar un tiempito

		wait until falling_edge(SPI_read_clk);
--		El micro ya puede leer
		SPI1_nCS <= '0';
		for i in 0 to 1999 loop --Se leen 1000 palabras
			read_SPI <= '1';
			for j in 0 to 15 loop --de 16 bits
				wait until falling_edge(SPI_read_clk);
			end loop;
			read_SPI <= '0';
			wait for  ( FPGA_clk_period * 9 ); --Solo para esperar un tiempito
		end loop;

		SPI1_nCS <= '1';
		read_SPI <= '0';


		--test_loops := 1;
--		reading_test_1 : loop
--			wait until SPI1_IRQ = '1';
--			wait for  ( FPGA_clk_period * 100 ); --Solo para esperar un tiempito
--			wait until falling_edge(SPI_read_clk);
--			--El micro ya puede leer
--			SPI1_nCS <= '0';
--			for i in 0 to 8 loop --Se leen 8 palabras
--				read_SPI <= '1';
--				for j in 0 to 15 loop --de 16 bits
--					wait until falling_edge(SPI_read_clk);
--				end loop;
--				read_SPI <= '0';
--				wait for  ( FPGA_clk_period * 20 ); --Solo para esperar un tiempito
--			end loop;
--
--			SPI1_nCS <= '1';
--			read_SPI <= '0';
--
--			test_loops := test_loops - 1;
--
--			if (test_loops = 0) then
--				exit reading_test_1;
--			end if;
--		end loop;
--
--		wait for  ( FPGA_clk_period * 5000 ); --Solo para esperar un tiempito
--
--		test_loops := 3;
--		reading_test_2 : loop
--			wait until SPI1_IRQ = '1';
--			wait for  ( FPGA_clk_period * 200 ); --Solo para esperar un tiempito
--			wait until falling_edge(SPI_read_clk);
--			--El micro ya puede leer
--			SPI1_nCS <= '0';
--			for i in 0 to 63 loop --Se leen 64 palabras
--				read_SPI <= '1';
--				for j in 0 to 15 loop --de 16 bits
--					wait until falling_edge(SPI_read_clk);
--				end loop;
--				read_SPI <= '0';
--				wait for  ( FPGA_clk_period * 4 ); --Solo para esperar un tiempito
--			end loop;
--
--			SPI1_nCS <= '1';
--			read_SPI <= '0';
--
--			test_loops := test_loops - 1;
--
--			if (test_loops = 0) then
--				exit reading_test_2;
--			end if;
--		end loop;
--
--		wait for  ( FPGA_clk_period * 2 ); --Solo para esperar un tiempito
--		G1_select <= '1'; --Comienza la escritura en modo configuracion
--
--		wait for  ( FPGA_clk_period * 20 ); --Solo para esperar un tiempito
--		G1_select <= '0'; --Comienza la lectura en modo real
--
--		reading : loop
--			wait until SPI1_IRQ = '1';
--			wait for  ( FPGA_clk_period * 2 ); --Solo para esperar un tiempito
--			wait until falling_edge(SPI_read_clk);
--			--El micro ya puede leer
--			SPI1_nCS <= '0';
--			read_SPI <= '1';
--			for i in 0 to 64*16 loop --Se leen 64 palabras
--				wait until rising_edge(SPI_read_clk);
--			end loop;
--
--			SPI1_nCS <= '1';
--			read_SPI <= '0';
--		end loop;

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


    -- Instantiate Unit Under Test:  GPStoSPIPacckerTest
    GPStoSPIPacckerTest_0 : GPStoSPIPacckerTest
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
            --G3_select 		=> G3_select,
            SPI1_SCK 		=> SPI1_clk,
            --SPI3_SCK 		=> SPI3_clk,
            SPI1_nCS 		=> SPI1_nCS,
            --SPI3_nCS 		=> SPI3_nCS,
            SPI1_MOSI 		=> SPI1_MOSI,
            --SPI3_MOSI 		=> SPI3_MOSI,

            -- Outputs
            SPI1_MISO 		=>  SPI1_MISO,
            --SPI3_MISO 		=>  SPI3_MISO,
            SPI1_IRQ 		=>  SPI1_IRQ,
            --SPI3_IRQ 		=>  SPI3_IRQ,
            SPI_max_clk 	=>  SPI_max_clk,
            SPI_max_nCS 	=>  SPI_max_nCS,
            SPI_max_data 	=>  SPI_max_data,

			TP_35			=> TP_35,
			TP_36			=> TP_36,
			TP_37			=> TP_37,
			TP_38			=> TP_38
            -- Inouts

        );

end behavioral;

