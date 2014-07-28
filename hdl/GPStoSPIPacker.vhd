--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: GPStoSPIPacker.vhd
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
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity GPStoSPIPacker is
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
end GPStoSPIPacker;

architecture GPStoSPIPacker_behaviour of GPStoSPIPacker is


	--------------------Constants-------------------
	constant log2_lines 		: positive := 4;	--log2(n° de bits de palabra)
	constant read_count_width 	: positive := 10;	--N° de bits que tiene read_count de la FIFO (depende del tamaño)
	------------------------------------------------

	--signal MAX_I 				: std_logic_vector(1 downto 0) := (others => '0');
	--signal MAX_Q				: std_logic_vector(1 downto 0) := (others => '0');

	--signal IQ_lines				: positive range 1 to 4 := 4;
	signal MAX_IQ_vector		: std_logic_vector(3 downto 0);

	signal fifo_write_enable_max	: std_logic := '0';
	signal fifo_full_flag 		: std_logic := '0';
	signal fifo_read_enable 	: std_logic := '0';
	signal fifo_data_valid 		: std_logic := '0';
	signal fifo_empty			: std_logic := '0';

	signal datapath_reset		: std_logic := '0';

	signal test_on				: std_logic := '0';

	signal external_reset		: std_logic := '0';

	signal s1					: std_logic := '0';
	signal s2					: std_logic := '0';
	signal s3					: std_logic := '0';

	signal g1					: std_logic := '0';
	signal g2					: std_logic := '0';
	signal g3					: std_logic := '0';

	signal g1_reg				: std_logic := '0';
	signal g2_reg				: std_logic := '0';
	signal g3_reg				: std_logic := '0';

	signal load_data_reg		: std_logic := '0';	
	--signal SPIread_clk			: std_logic := '0';
	--signal SPIread_nCS			: std_logic := '1';
	signal sr1_load_nShift		: std_logic := '0';
	signal sr2_load_nShift		: std_logic := '0';
	signal sr3_load_nShift		: std_logic := '0';
	signal serial_data1			: std_logic := '0';
	signal serial_data2			: std_logic := '0';
	signal serial_data3			: std_logic := '0';
	signal data_ready_IRQ1flag	: std_logic := '0';
	signal data_ready_IRQ2flag	: std_logic := '0';
	signal data_ready_IRQ3flag	: std_logic := '0';

	signal not_FPGA_clock		: std_logic := '0';

	component ffD 
		port (
 		    clock			: in std_logic;
			a_reset			: in std_logic;
			en				: in std_logic;
   		 	d				: in std_logic;
   		 	q				: out std_logic;
			not_q			: out std_logic
		);
	end component;

	component access_controller
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
	end component;

	component testController
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
	end component;

	component rx_manager
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
	end component;

	component tx_manager
		generic (
			counter_lines		: positive range 2 to 8 --2**counter_lines es el número de bits de una palabra que se transmiten por SPI
		);
		port (
			reset				: in std_logic;
			FPGA_clock			: in std_logic;
			max_clock			: in std_logic;
			LD					: in std_logic;
			SPI1_clk			: in std_logic;
			SPI2_clk			: in std_logic;
			SPI3_clk			: in std_logic;
			SPI1_nCS			: in std_logic;
			SPI2_nCS			: in std_logic;
			SPI3_nCS			: in std_logic;
			s1					: in std_logic;
    		s2					: in std_logic;
			s3					: in std_logic;
			g1					: in std_logic;
   			g2					: in std_logic;
			g3					: in std_logic;
	
			--Control de la FIFO
			fifo_write_enable 	: out std_logic;
			fifo_full			: in std_logic;
			fifo_read_enable	: out std_logic;
			fifo_data_valid		: in std_logic;
			fifo_empty			: in std_logic;

			--Reset asincrónico de todo el datapath
			reset_datapath		: out std_logic;

			--Control del registro del datapath
			load_data_reg		: out std_logic;

			--Control de los shift registers
			sr1_load_nShift		: out std_logic;
			sr2_load_nShift		: out std_logic;
			sr3_load_nShift		: out std_logic
		);
	end component;

	component datapath 
	generic(
		log2_lines			: positive range 2 to 8 := 4; 	--2**log2_lines es el número de bits por palabra
		IRQ_threshold		: positive := 32;				--Número de palabras que debe tener la FIFO para levantar la señal de IRQ
		read_count_width	: positive	:= 7;				--Ancho de la palabra word_count de la FIFO
		IQ_lines			: positive range 1 to 4 := 4	--Número de bits que se utilizan del MAX
	);
	port (
		MAX_clockout			: in std_logic;
		MAX_IQ_vector			: in std_logic_vector((IQ_lines - 1) downto 0);
		fifo_write_enable_max	: in std_logic;
		fifo_full				: out std_logic;
		test_mode_on			: in std_logic;
		a_reset					: in std_logic;	
		datapath_reset			: in std_logic;	
		FPGA_clock				: in std_logic;
		fifo_read_enable		: in std_logic;
		fifo_data_valid			: out std_logic;
		fifo_empty				: out std_logic;
		load_data_reg			: in std_logic;			
		SPI1_clk				: in std_logic;
		SPI2_clk				: in std_logic;
		SPI3_clk				: in std_logic;

		sr1_load_nShift			: in std_logic;
		sr2_load_nShift			: in std_logic;
		sr3_load_nShift			: in std_logic;

		serial_data1			: out std_logic;
		serial_data2			: out std_logic;
		serial_data3			: out std_logic;
		data_ready_IRQ1flag		: out std_logic;
		data_ready_IRQ2flag		: out std_logic;
		data_ready_IRQ3flag		: out std_logic;
		
		testGenClock			: out std_logic;
		read_cnt_MSB			: out std_logic
	);
	end component;


	signal testGenClock			: std_logic;
	signal read_cnt_MSB			: std_logic;

begin

	------TEST------
	--SPI1_SCK_test 	<= SPI1_SCK;
	--TP_35			<= testGenClock;
	TP_36			<= read_cnt_MSB;
	TP_37			<= SPI1_nCS;
	TP_38			<= (data_ready_IRQ1flag and SPI1_nCS);

	ffD_testGenClock : ffD 
		port map (
 		    clock			=> FPGA_clock,
			a_reset			=> external_reset,
			en				=> '1',
   		 	d				=> testGenClock,
   		 	q				=> TP_35,
			not_q			=> open
		);
	----------------

	external_reset <= not nReset;

	not_FPGA_clock <= not FPGA_clock;

	ffD_g1 : ffD 
		port map (
 		    clock			=> not_FPGA_clock,
			a_reset			=> external_reset,
			en				=> '1',
   		 	d				=> G1_select,
   		 	q				=> g1,
			not_q			=> open
		);

	ffD_g2 : ffD 
		port map (
 		    clock			=> not_FPGA_clock,
			a_reset			=> external_reset,
			en				=> '1',
   		 	d				=> G2_select,
   		 	q				=> g2,
			not_q			=> open
		);

	ffD_g3 : ffD 
		port map (
 		    clock			=> not_FPGA_clock,
			a_reset			=> external_reset,
			en				=> '1',
   		 	d				=> G3_select,
   		 	q				=> g3,
			not_q			=> open
		);

	access_controller_inst : access_controller
		port map (
			clock	=> FPGA_clock,
   			a_reset => external_reset,
    		g1 		=> g1,
    		g2 		=> g2,
			g3 		=> g3,
			s1		=> s1,
			s2		=> s2,
			s3		=> s3
		);

	ffD_g1_reg : ffD 
		port map (
 		    clock			=> FPGA_clock,
			a_reset			=> external_reset,
			en				=> '1',
   		 	d				=> g1,
   		 	q				=> g1_reg,
			not_q			=> open
		);

	ffD_g2_reg : ffD 
		port map (
 		    clock			=> FPGA_clock,
			a_reset			=> external_reset,
			en				=> '1',
   		 	d				=> g2,
   		 	q				=> g2_reg,
			not_q			=> open
		);

	ffD_g3_reg : ffD 
		port map (
 		    clock			=> FPGA_clock,
			a_reset			=> external_reset,
			en				=> '1',
   		 	d				=> g3,
   		 	q				=> g3_reg,
			not_q			=> open
		);

	testController_inst : testController
		port map (
   			clock	=> FPGA_clock,
   			a_reset => external_reset,
    		g1 		=> g1_reg,
   			g2 		=> g2_reg,
			g3 		=> g3_reg,
			s1		=> s1,
			s2		=> s2,
			s3		=> s3,
			test_on	=> test_on
		);

	rx_manager_inst : rx_manager
		port map (
	   		SPI1_clk	=> SPI1_SCK,
			SPI2_clk	=> SPI2_SCK,
			SPI3_clk	=> SPI3_SCK,
			SPI1_MOSI	=> SPI1_MOSI,
			SPI2_MOSI	=> SPI2_MOSI,
			SPI3_MOSI	=> SPI3_MOSI,
			SPI1_nCS	=> SPI1_nCS,
			SPI2_nCS	=> SPI2_nCS,
			SPI3_nCS	=> SPI3_nCS,
			s1			=> s1,
 	   	 	s2			=> s2,
			s3			=> s3,
			g1			=> g1_reg,
 	  		g2			=> g2_reg,
			g3			=> g3_reg,
			SPImax_clk	=> SPI_max_clk,
			SPImax_MOSI	=> SPI_max_data,
			SPImax_nCS	=> SPI_max_nCS
	);

	tx_manager_inst : tx_manager
		generic map (
			counter_lines		=> log2_lines
		)
		port map (
			reset				=> external_reset,
			FPGA_clock			=> FPGA_clock,
			max_clock			=> MAX_clockout,
			LD					=> LD,
			SPI1_clk			=> SPI1_SCK,
			SPI2_clk			=> SPI2_SCK,
			SPI3_clk			=> SPI3_SCK,
			SPI1_nCS			=> SPI1_nCS,
			SPI2_nCS			=> SPI2_nCS,
			SPI3_nCS			=> SPI3_nCS,
			s1					=> s1,
   	 		s2					=> s2,
			s3					=> s3,
			g1					=> g1_reg,
   	 		g2					=> g2_reg,
			g3					=> g3_reg,
			fifo_write_enable 	=> fifo_write_enable_max,
			fifo_full			=> fifo_full_flag,
			fifo_read_enable	=> fifo_read_enable,
			fifo_data_valid		=> fifo_data_valid,
			fifo_empty			=> fifo_empty,
			reset_datapath		=> datapath_reset,
			load_data_reg		=> load_data_reg,
			--Control de los shift registers
			sr1_load_nShift		=> sr1_load_nShift,
			sr2_load_nShift		=> sr2_load_nShift,
			sr3_load_nShift		=> sr3_load_nShift
		);

	--MAX_I(1)  <= MAX_I1;
	--MAX_I(0)  <= MAX_I0;
	--MAX_Q(1)  <= MAX_Q1;
	--MAX_Q(0)  <= MAX_Q0;

	--NOTA: el elsif generate no está habilitado en todas las versiones de VHDL. Creo que se habilita en VHDL 2008.
	IQ0_generate : if IQ = 0 generate --I0
		MAX_IQ_vector(0) <= MAX_I0;
		MAX_IQ_vector(1) <= '0'; 
		MAX_IQ_vector(2) <= '0'; 
		MAX_IQ_vector(3) <= '0';

		datapath_inst : datapath 
			generic map(
				log2_lines			=> log2_lines,
				IRQ_threshold		=> IRQ_threshold,
				read_count_width	=> read_count_width,
				IQ_lines			=> 1
			)
			port map(
				MAX_clockout			=> MAX_clockout,
				MAX_IQ_vector			=> MAX_IQ_vector(0 downto 0),

				fifo_write_enable_max	=> fifo_write_enable_max,
				fifo_full				=> fifo_full_flag,
				test_mode_on			=> test_on,
				a_reset					=> external_reset,
				datapath_reset			=> datapath_reset,	
				FPGA_clock				=> FPGA_clock,
				fifo_read_enable		=> fifo_read_enable,
				fifo_data_valid			=> fifo_data_valid,
				fifo_empty				=> fifo_empty,
				load_data_reg			=> load_data_reg,		

				SPI1_clk				=> SPI1_SCK,
				SPI2_clk				=> SPI2_SCK,
				SPI3_clk				=> SPI3_SCK,

				sr1_load_nShift			=> sr1_load_nShift,
				sr2_load_nShift			=> sr2_load_nShift,
				sr3_load_nShift			=> sr3_load_nShift,

				serial_data1			=> serial_data1,
				serial_data2			=> serial_data2,
				serial_data3			=> serial_data3,
				data_ready_IRQ1flag		=> data_ready_IRQ1flag,
				data_ready_IRQ2flag		=> data_ready_IRQ2flag,
				data_ready_IRQ3flag		=> data_ready_IRQ3flag,

				testGenClock			=> testGenClock,
				read_cnt_MSB			=> read_cnt_MSB
			);
	end generate;

	IQ1_generate : if IQ = 1 generate --I1-I0
		MAX_IQ_vector(0) <= MAX_I1;
		MAX_IQ_vector(1) <= MAX_I0;
		MAX_IQ_vector(2) <= '0'; 
		MAX_IQ_vector(3) <= '0';

		datapath_inst : datapath 
			generic map(
				log2_lines			=> log2_lines,
				IRQ_threshold		=> IRQ_threshold,
				read_count_width	=> read_count_width,
				IQ_lines			=> 2
			)
			port map(
				MAX_clockout			=> MAX_clockout,
				MAX_IQ_vector			=> MAX_IQ_vector(1 downto 0),

				fifo_write_enable_max	=> fifo_write_enable_max,
				fifo_full				=> fifo_full_flag,
				test_mode_on			=> test_on,
				a_reset					=> external_reset,
				datapath_reset			=> datapath_reset,	
				FPGA_clock				=> FPGA_clock,
				fifo_read_enable		=> fifo_read_enable,
				fifo_data_valid			=> fifo_data_valid,
				fifo_empty				=> fifo_empty,
				load_data_reg			=> load_data_reg,		

				SPI1_clk				=> SPI1_SCK,
				SPI2_clk				=> SPI2_SCK,
				SPI3_clk				=> SPI3_SCK,

				sr1_load_nShift			=> sr1_load_nShift,
				sr2_load_nShift			=> sr2_load_nShift,
				sr3_load_nShift			=> sr3_load_nShift,

				serial_data1			=> serial_data1,
				serial_data2			=> serial_data2,
				serial_data3			=> serial_data3,
				data_ready_IRQ1flag		=> data_ready_IRQ1flag,
				data_ready_IRQ2flag		=> data_ready_IRQ2flag,
				data_ready_IRQ3flag		=> data_ready_IRQ3flag,

				testGenClock			=> testGenClock,
				read_cnt_MSB			=> read_cnt_MSB
			);
	end generate;

	IQ2_generate : if IQ = 2 generate --I1-I0-Q1
		MAX_IQ_vector(0) <= MAX_I1;
		MAX_IQ_vector(1) <= MAX_I0;	
		MAX_IQ_vector(2) <= MAX_Q1;
		MAX_IQ_vector(3) <= '0';

		datapath_inst : datapath 
			generic map(
				log2_lines			=> log2_lines,
				IRQ_threshold		=> IRQ_threshold,
				read_count_width	=> read_count_width,
				IQ_lines			=> 3
			)
			port map(
				MAX_clockout			=> MAX_clockout,
				MAX_IQ_vector			=> MAX_IQ_vector(2 downto 0),

				fifo_write_enable_max	=> fifo_write_enable_max,
				fifo_full				=> fifo_full_flag,
				test_mode_on			=> test_on,
				a_reset					=> external_reset,
				datapath_reset			=> datapath_reset,	
				FPGA_clock				=> FPGA_clock,
				fifo_read_enable		=> fifo_read_enable,
				fifo_data_valid			=> fifo_data_valid,
				fifo_empty				=> fifo_empty,
				load_data_reg			=> load_data_reg,		

				SPI1_clk				=> SPI1_SCK,
				SPI2_clk				=> SPI2_SCK,
				SPI3_clk				=> SPI3_SCK,

				sr1_load_nShift			=> sr1_load_nShift,
				sr2_load_nShift			=> sr2_load_nShift,
				sr3_load_nShift			=> sr3_load_nShift,

				serial_data1			=> serial_data1,
				serial_data2			=> serial_data2,
				serial_data3			=> serial_data3,
				data_ready_IRQ1flag		=> data_ready_IRQ1flag,
				data_ready_IRQ2flag		=> data_ready_IRQ2flag,
				data_ready_IRQ3flag		=> data_ready_IRQ3flag,

				testGenClock			=> testGenClock,
				read_cnt_MSB			=> read_cnt_MSB
			);
	end generate;

	IQ3_generate : if IQ = 3 generate --I0 Q0
		MAX_IQ_vector(0) <= MAX_I0;
		MAX_IQ_vector(1) <= MAX_Q0;	
		MAX_IQ_vector(2) <= '0'; 
		MAX_IQ_vector(3) <= '0';

		datapath_inst : datapath 
			generic map(
				log2_lines			=> log2_lines,
				IRQ_threshold		=> IRQ_threshold,
				read_count_width	=> read_count_width,
				IQ_lines			=> 2
			)
			port map(
				MAX_clockout			=> MAX_clockout,
				MAX_IQ_vector			=> MAX_IQ_vector(1 downto 0),

				fifo_write_enable_max	=> fifo_write_enable_max,
				fifo_full				=> fifo_full_flag,
				test_mode_on			=> test_on,
				a_reset					=> external_reset,
				datapath_reset			=> datapath_reset,	
				FPGA_clock				=> FPGA_clock,
				fifo_read_enable		=> fifo_read_enable,
				fifo_data_valid			=> fifo_data_valid,
				fifo_empty				=> fifo_empty,
				load_data_reg			=> load_data_reg,		

				SPI1_clk				=> SPI1_SCK,
				SPI2_clk				=> SPI2_SCK,
				SPI3_clk				=> SPI3_SCK,

				sr1_load_nShift			=> sr1_load_nShift,
				sr2_load_nShift			=> sr2_load_nShift,
				sr3_load_nShift			=> sr3_load_nShift,

				serial_data1			=> serial_data1,
				serial_data2			=> serial_data2,
				serial_data3			=> serial_data3,
				data_ready_IRQ1flag		=> data_ready_IRQ1flag,
				data_ready_IRQ2flag		=> data_ready_IRQ2flag,
				data_ready_IRQ3flag		=> data_ready_IRQ3flag,

				testGenClock			=> testGenClock,
				read_cnt_MSB			=> read_cnt_MSB
			);
	end generate;

	IQ4_generate : if IQ = 4 generate --I1-I0 Q1-Q0
		MAX_IQ_vector(0) <= MAX_I1;
		MAX_IQ_vector(1) <= MAX_I0;	
		MAX_IQ_vector(2) <= MAX_Q1;
		MAX_IQ_vector(3) <= MAX_Q0;

		datapath_inst : datapath 
			generic map(
				log2_lines			=> log2_lines,
				IRQ_threshold		=> IRQ_threshold,
				read_count_width	=> read_count_width,
				IQ_lines			=> 4
			)
			port map(
				MAX_clockout			=> MAX_clockout,
				MAX_IQ_vector			=> MAX_IQ_vector(3 downto 0),

				fifo_write_enable_max	=> fifo_write_enable_max,
				fifo_full				=> fifo_full_flag,
				test_mode_on			=> test_on,
				a_reset					=> external_reset,
				datapath_reset			=> datapath_reset,	
				FPGA_clock				=> FPGA_clock,
				fifo_read_enable		=> fifo_read_enable,
				fifo_data_valid			=> fifo_data_valid,
				fifo_empty				=> fifo_empty,
				load_data_reg			=> load_data_reg,		

				SPI1_clk				=> SPI1_SCK,
				SPI2_clk				=> SPI2_SCK,
				SPI3_clk				=> SPI3_SCK,

				sr1_load_nShift			=> sr1_load_nShift,
				sr2_load_nShift			=> sr2_load_nShift,
				sr3_load_nShift			=> sr3_load_nShift,

				serial_data1			=> serial_data1,
				serial_data2			=> serial_data2,
				serial_data3			=> serial_data3,
				data_ready_IRQ1flag		=> data_ready_IRQ1flag,
				data_ready_IRQ2flag		=> data_ready_IRQ2flag,
				data_ready_IRQ3flag		=> data_ready_IRQ3flag,

				testGenClock			=> testGenClock,
				read_cnt_MSB			=> read_cnt_MSB
			);
	end generate;

	SPI1_MISO <= serial_data1 when (SPI1_nCS = '0' and s1 = '1' and g1_reg = '0') else 
				'Z';

	SPI2_MISO <= serial_data2 when (SPI2_nCS = '0' and s2 = '1' and g2_reg = '0') else 
				'Z';

	SPI3_MISO <= serial_data3 when (SPI3_nCS = '0' and s3 = '1' and g3_reg = '0') else 
				'Z';

	--Las señales de IRQ sólo se encienden si no ningún micro esta leyendo
	SPI1_IRQ <= (data_ready_IRQ1flag and SPI1_nCS) when (s1 = '1' and g1_reg = '0') else --Hay que estar en modo transmisión
				'Z';

	SPI2_IRQ <= (data_ready_IRQ2flag and SPI2_nCS) when (s2 = '1' and g2_reg = '0') else
				'Z';

	SPI3_IRQ <= (data_ready_IRQ3flag and SPI3_nCS) when (s3 = '1' and g3_reg = '0') else
				'Z';

end GPStoSPIPacker_behaviour;
