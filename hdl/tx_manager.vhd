--------------------------------------------------------------------------------
-- Company: Satellogic
-- File: tx_manager.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Circuito de control de transmisión. Controla la FIFO, el registro del datapath y el shift register.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity tx_manager is
generic (
	counter_lines		: positive range 2 to 8 := 4 --2**counter_lines es el número de bits de una palabra que se transmiten por SPI
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
	--SPIread_clk			: out std_logic;
	--SPI_nCS				: out std_logic;
	
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
end tx_manager;

architecture tx_manager_behaviour of tx_manager is
	signal tx_control 					: std_logic_vector(1 downto 0) := (others => '0');
	signal ready_to_tx					: std_logic := '0';
	signal ready_to_tx_write_clocked	: std_logic := '0';
	--signal ready_to_tx_write_clocked_2	: std_logic := '0';

	signal fifo_full_or_max_not_ready 	: std_logic := '0';

	signal data_reg_free_flag			: std_logic := '0';

	signal internal_reset_datapath		: std_logic := '0';

	signal SPI_clk						: std_logic_vector(3 downto 0) := (others => '0');
	signal SPI_nCS						: std_logic_vector(3 downto 0) := (others => '0');
	signal not_SPI_nCS					: std_logic_vector(3 downto 0) := (others => '0');
	signal init_load_reg_window 		: std_logic_vector(3 downto 0) := (others => '0');
	signal close_load_reg_window 		: std_logic_vector(3 downto 0) := (others => '0');
	signal sr_load_nShift 				: std_logic_vector(3 downto 0) := (others => '0');
	signal ffSR_free_reg_window_aReset 	: std_logic_vector(3 downto 0) := (others => '0');
	signal datapath_reg_is_free 		: std_logic_vector(3 downto 0) := (others => '0');
	signal reg_is_free					: std_logic := '0';

	signal internal_load_data_reg		: std_logic := '0';

	signal ffSR_free_reg_flag_s 		: std_logic := '0';

	signal not_max_clock				: std_logic := '0';

	signal not_LD_reg					: std_logic := '0';

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

	component tx_controller
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
	end component;

	component output_controller
	port (
   		clock		: in std_logic;
		a_reset		: in std_logic;
		fifo_empty	: in std_logic;
		data_valid	: in std_logic;
		reg_is_free	: in std_logic;
		read_enable	: out std_logic;
		load_reg	: out std_logic
	);
	end component;

	component n_bit_counter
	generic(
		nmbr_of_bits	: positive range 1 to 32 := 4;	--Número de bits del contador
		reset_count		: natural := 0;					--Cuenta inicial del reset
		user_flag_nmbr  : natural := 0					--Número de cuenta en el que se sube el user_flag
	);
	port (
 	    clock				: in std_logic;
		a_reset				: in std_logic;
		s_reset 			: in std_logic;
		enable				: in std_logic;
		count				: out std_logic_vector((nmbr_of_bits-1) downto 0);
		zero_flag			: out std_logic;
		user_flag		 	: out std_logic;
		end_flag			: out std_logic
	);
	end component;

	component ffSR
	port (
 	   	clock			: in std_logic;
		a_reset			: in std_logic;
		a_set			: in std_logic;
		r				: in std_logic;
  	  	s				: in std_logic;
	    q				: out std_logic
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

begin
	not_max_clock <= not max_clock;

	--Control de las señales SPI al gumstix
	tx_controller_inst : tx_controller
		port map (
			s1			=> s1,
			s2			=> s2,
			s3			=> s3,
			g1			=> g1,
			g2			=> g2,
			g3			=> g3,
			tx_ctrl		=> tx_control,
			rdy_to_tx	=> ready_to_tx
		);

	ffD_ready_to_tx_write_clocked : ffD 
		port map(
 		    clock			=> not_max_clock,
			a_reset			=> internal_reset_datapath,
			en				=> '1',
   		 	d				=> ready_to_tx,
   		 	q				=> ready_to_tx_write_clocked,
			not_q			=> open
		);

	LD_ffD : ffD
		port map (
   	 		clock		=>  not_max_clock,
			a_reset		=>  reset,
			en			=>  '1',
   	 		d			=>  LD,
    		q			=>  open,
			not_q		=>  not_LD_reg
		);

	---------Señales de control de la FIFO-------------
	fifo_full_or_max_not_ready <= fifo_full or not_LD_reg;

	--Para escribir en la FIFO, deben cumplirse las siguientes 3 condiciones:
	-- 1) el módulo debe estar configurado en modo transmisión (ready_to_tx = 1),
	-- 2) la FIFO no debe estar llena (fifo_full = 0),
	-- 3) el max debe estar listo (LD = 1)
	fifo_write_enable <= ready_to_tx_write_clocked and (not fifo_full_or_max_not_ready);

	--La FIFO (y todo el datapath) se resetea (borrando los datos) si se cumple alguna de las siguientes 4 condiciones:
	-- 1) reset externo (reset = 1),
	-- 2) el módulo no está configurado en modo transmisión (ready_to_tx = 0) para que no queden datos viejos,
	-- 3) la FIFO está llena,
	-- 4) el max no está listo (LD = 0)
	internal_reset_datapath <= reset or fifo_full_or_max_not_ready or (not ready_to_tx);
	---------------------------------------------------

	--Reset de todos los bloques del datapath
	reset_datapath <= internal_reset_datapath;
	
	--Controla la lectura de la FIFO
	output_controller_inst : output_controller
	port map (
   		clock		=> FPGA_clock,
		a_reset		=> internal_reset_datapath,
		fifo_empty	=> fifo_empty,
		data_valid	=> fifo_data_valid,
		reg_is_free	=> data_reg_free_flag,
		read_enable	=> fifo_read_enable,
		load_reg	=> internal_load_data_reg
	);

	load_data_reg <= internal_load_data_reg;

	SPI_clk(0) <= '0';
	SPI_clk(1) <= SPI1_clk;
	SPI_clk(2) <= SPI2_clk;
	SPI_clk(3) <= SPI3_clk;

	SPI_nCS(0) <= '1';
	SPI_nCS(1) <= SPI1_nCS;
	SPI_nCS(2) <= SPI2_nCS;
	SPI_nCS(3) <= SPI3_nCS;

	sr_load_nShift(0) <= '0';
	sr1_load_nShift <= sr_load_nShift(1);
	sr2_load_nShift <= sr_load_nShift(2);
	sr3_load_nShift <= sr_load_nShift(3);

	not_SPI_nCS(0) 					<= '0';
	ffSR_free_reg_window_aReset(0) 	<= '0';
	close_load_reg_window(0)		<= '0';
	init_load_reg_window(0) 		<= '0';
	datapath_reg_is_free(0) 		<= '1';

	for_each_SPI :   for i in 1 to 3 generate --El 0 no se usa. El sintetizador lo va a ignorar
    begin 
		not_SPI_nCS(i) <= not SPI_nCS(i);
	
       --Cuenta los bits de salida de MISO y controla la carga del Shift Register y del registro del datapath
		bit_counter_i : n_bit_counter
		generic map (
			nmbr_of_bits		=> counter_lines,
			reset_count			=> 15,
			user_flag_nmbr 		=> 13
		)
		port map (
 	   		clock				=> SPI_clk(i),
			a_reset				=> SPI_nCS(i),
			s_reset 			=> SPI_nCS(i),
			enable				=> not_SPI_nCS(i),
			count				=> open,
			zero_flag			=> init_load_reg_window(i),
			user_flag		 	=> close_load_reg_window(i),
			end_flag			=> sr_load_nShift(i)
		);

		ffSR_free_reg_window_aReset(i) <= SPI_nCS(i) or internal_load_data_reg;

		--Setea la ventana de tiempo en la que se puede modificar el registro del datapath
		ffSR_free_reg_window_i : ffSR
			port map (
 	   			clock		=> SPI_clk(i),
				a_reset		=> ffSR_free_reg_window_aReset(i),
				a_set		=> '0',
				r			=> close_load_reg_window(i),
  	  			s			=> init_load_reg_window(i),
	   			q			=> datapath_reg_is_free(i)
			);
   	end generate for_each_SPI;

	mux_reg_in_use_inst : mux 
	generic map(
		nmbr_of_sel_lines => 2
	)
	port map (
		input 	=> datapath_reg_is_free,
		sel 	=> tx_control,
		output	=> reg_is_free
	);

	ffSR_free_reg_flag_s <= reg_is_free and (not internal_load_data_reg);

	--Setea la ventana de tiempo en la que se puede modificar el registro del datapath
	ffSR_free_reg_flag : ffSR
	port map (
 	   	clock		=> FPGA_clock,
		a_reset		=> '0',
		a_set		=> internal_reset_datapath,
		r			=> internal_load_data_reg,
  	  	s			=> ffSR_free_reg_flag_s,
	    q			=> data_reg_free_flag
	);
	
end tx_manager_behaviour;
