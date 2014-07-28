--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: datapath.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- 
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity datapath is
generic(
	log2_lines			: positive range 2 to 8 := 4; 	--2**log2_lines es el número de bits por palabra
	IRQ_threshold		: positive := 32;				--Número de palabras que debe tener la FIFO para levantar la señal de IRQ
	read_count_width	: positive := 7;				--Ancho de la palabra word_count de la FIFO
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
end datapath;

architecture datapath_behaviour of datapath is

	signal fifo_data_in 			: std_logic_vector((IQ_lines - 1) downto 0) := (others => '0');
	signal fifo_data_out			: std_logic_vector((2**log2_lines - 1) downto 0) := (others => '0');
	signal reg_data_out				: std_logic_vector((2**log2_lines - 1) downto 0) := (others => '0');
	signal parallel_in				: std_logic_vector((2**log2_lines - 1) downto 0) := (others => '0');
	signal word_count				: std_logic_vector((read_count_width - 1) downto 0) := (others => '0');
	signal full						: std_logic := '0';

	signal not_MAX_clockout			: std_logic := '0';

	signal SPI_clk 					: std_logic_vector(3 downto 0) := (others => '0');
	signal sr_load_nShift 			: std_logic_vector(3 downto 0) := (others => '0');
	signal serial_data 				: std_logic_vector(3 downto 0) := (others => '0');

	--signal fifo_data_in_max 		: std_logic_vector((IQ_lines - 1) downto 0) := (others => '0');
	signal fifo_data_in_IQ			: std_logic_vector((IQ_lines - 1) downto 0) := (others => '0');
	signal fifo_data_in_test 		: std_logic_vector((IQ_lines - 1) downto 0) := (others => '0');
	signal fifo_write_enable		: std_logic := '0';
	signal valid_data_test			: std_logic := '0';

	component fifo
   		port( 
		  DATA   	: in    std_logic_vector((IQ_lines - 1) downto 0);
          Q     	: out   std_logic_vector((2**log2_lines - 1)  downto 0);
          WE    	: in    std_logic;
          RE     	: in    std_logic;
          WCLOCK 	: in    std_logic;
          RCLOCK	: in    std_logic;
          FULL  	: out   std_logic;
          EMPTY  	: out   std_logic;
          RESET  	: in    std_logic;
          DVLD   	: out   std_logic;
          RDCNT  	: out   std_logic_vector((read_count_width-1) downto 0)
        );
	end component;

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

	component shift_register
	generic(
		nbits		: positive := 16;	 	--Número de bits de registro
		MSB_first	: std_logic := '1';		--Indica si se shiftea para un lado o para el otro
		barrel		: std_logic := '0'		--Indica si el registro es circular o se rellena con ceros
	);
	port (
 	   clock		: in std_logic;
		a_reset		: in std_logic;
		load_nShift	: in std_logic;
		parallel_in : in std_logic_vector((nbits - 1) downto 0);
		serial_out	: out std_logic
	);
	end component;

	component testGen
		generic (
			nmbr_of_bits : positive range 1 to 4 := 4 --Genera datos de un contador de 16 bits en 1, 2, 3 o 4 bits
		);
		port (
 	 	  	clock 		: in std_logic;	
			a_reset		: in std_logic;
			enable_test	: in std_logic;
			data_out 	: out std_logic_vector((nmbr_of_bits - 1) downto 0);
			data_valid	: out std_logic
		);
	end component;

begin
	not_MAX_clockout <= not MAX_clockout;

	testGenClock <= not_MAX_clockout;
	read_cnt_MSB <= word_count(read_count_width - 1);

--0: I0; 1: I1-I0; 2: I1-I0-Q1; 3: I0 Q0; 4: I1-I0 Q1-Q0

	--fifo_data_in_max(0) <= MAX_I(1);
	--fifo_data_in_max(1) <= MAX_I(0);	
	--fifo_data_in_max(2) <= MAX_Q(1);
	--fifo_data_in_max(3) <= MAX_Q(0);

	input_reg_gen : for i in 0 to (IQ_lines - 1) generate
    begin 
       	input_reg_inst : ffD
		port map (
   	 		clock		=> not_MAX_clockout,
			a_reset		=> datapath_reset,
			en			=> '1',
   	 		d			=> MAX_IQ_vector(i),
    		q			=> fifo_data_in_IQ(i),
			not_q		=> open
		);
  	end generate;

	testGen_inst : testGen
		generic map(
			nmbr_of_bits => IQ_lines
		)
		port map (
   			clock 		=> not_MAX_clockout,
			a_reset		=> datapath_reset,
			enable_test	=> test_mode_on,
			data_out 	=> fifo_data_in_test,
			data_valid	=> valid_data_test
		);

	process(test_mode_on, fifo_data_in_test, fifo_data_in_IQ, valid_data_test, fifo_write_enable_max)
	begin
		if (test_mode_on = '1') then
			fifo_data_in 		<= fifo_data_in_test;
			fifo_write_enable 	<= valid_data_test;
		else
			fifo_data_in 		<= fifo_data_in_IQ;
			fifo_write_enable 	<= fifo_write_enable_max;
		end if;
	end process;

	fifo_inst : fifo
   		port map( 
			DATA   => fifo_data_in,
          	Q      => fifo_data_out,
         	WE     => fifo_write_enable,
         	RE     => fifo_read_enable,
         	WCLOCK => not_MAX_clockout,
         	RCLOCK => FPGA_clock,
         	FULL   => full,
         	EMPTY  => fifo_empty,
         	RESET  => datapath_reset,
         	DVLD   => fifo_data_valid,
         	RDCNT  => word_count
        );

	ffD_full_inst : ffD
		port map (
   	 		clock		=>  not_MAX_clockout,
			a_reset		=>  a_reset,
			en			=>  '1',
   	 		d			=>  full,
    		q			=>  fifo_full,
			not_q		=>	open
		);

	--Se enciende el IRQ cuando hay una cantidad mínima de palabras en la FIFO
	data_ready_IRQ1flag <= '1' when (unsigned(word_count) >= to_unsigned(IRQ_threshold, read_count_width)) else
							'0';

	data_ready_IRQ2flag <= '1' when (unsigned(word_count) >= to_unsigned(IRQ_threshold, read_count_width)) else
							'0';

	data_ready_IRQ3flag <= '1' when (unsigned(word_count) >= to_unsigned(IRQ_threshold, read_count_width)) else
							'0';

	reg_gen : for i in 0 to (2**log2_lines - 1) generate
    begin 
       	ffD_inst : ffD
		port map (
   	 		clock		=>  FPGA_clock,
			a_reset		=>  datapath_reset,
			en			=>  load_data_reg,
   	 		d			=>  fifo_data_out(i),
    		q			=>  reg_data_out(i),
			not_q		=>	open
		);
   end generate;


	--Si se numera cuatro muestras IQ del max temporalmente con subíndices 0, 1, 2, 3.
	--parallel_in tiene la siguiente forma:
	--(Q0Q1I0I1)_3 (Q0Q1I0I1)_2 (Q0Q1I0I1)_1 (Q0Q1I0I1)_0 
	parallel_in <= reg_data_out;

	SPI_clk(0) <= '0';
	SPI_clk(1) <= SPI1_clk;
	SPI_clk(2) <= SPI2_clk;
	SPI_clk(3) <= SPI3_clk;

	sr_load_nShift(0) <= '0';
	sr_load_nShift(1) <= sr1_load_nShift;
	sr_load_nShift(2) <= sr2_load_nShift;
	sr_load_nShift(3) <= sr3_load_nShift;

	serial_data(0) <= '0';
	serial_data1 <= serial_data(1);
	serial_data2 <= serial_data(2);
	serial_data3 <= serial_data(3);

	for_each_SPI :   for i in 1 to 3 generate --El 0 no se usa. El sintetizador lo va a ignorar
    begin 
		SR_i : shift_register
		generic map(
			nbits		=> 2**log2_lines,
			MSB_first	=> '0', --LSB primero
			barrel		=> '0'
		)
		port map (
 	    	clock		=> SPI_clk(i),
			a_reset		=> datapath_reset,
			load_nShift	=> sr_load_nShift(i),
			parallel_in => parallel_in,
			serial_out	=> serial_data(i)
		);
	end generate for_each_SPI;

end datapath_behaviour;
