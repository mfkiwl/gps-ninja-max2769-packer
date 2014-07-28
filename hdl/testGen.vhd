--------------------------------------------------------------------------------
-- Company: Satellogic.
--
-- File: testGen.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Generador de datos de testeo.
--
-- Targeted device: <Family::IGLOO> <Die::AGL125V5> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library IEEE;

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity testGen is
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
end testGen;

architecture testGen_behaviour of testGen is

	signal sel 					: std_logic_vector(3 downto 0) := (others => '0');
	signal overflow 			: std_logic := '0';
	signal count				: std_logic_vector(15 downto 0) := (others => '0');
	signal data_out_int 		: std_logic_vector((nmbr_of_bits - 1) downto 0)  := (others => '0');
	signal enable_test_reg		: std_logic := '0';
	signal not_enable_test_reg	: std_logic := '0';
	signal reset_counters		: std_logic := '0';

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
	--Se registra el enable porque viene con otro clock
	ffD_test_on_inst : ffD
		port map (
   	 		clock			=> clock,
			a_reset			=> a_reset,
			en				=> '1',
   			d				=> enable_test,
   			q				=> enable_test_reg,
			not_q			=> not_enable_test_reg
		);

	reset_counters <= not_enable_test_reg or overflow;

	--Dependiendo el número de bits (nmbr_of_bits) cuenta hasta un número distinto:
	-- 1: 16 cuentas (16/1 = 16 partes). log2(16) = 4 bits
	-- 2: 8 cuentas (16/2 = 8 partes). log2(8) = 3 bits
	-- 3: 6 cuentas (16/3 = 6 partes). log2(6) = 3 bits
	-- 4: 4 cuentas (16/4 = 4 partes). log2(4) = 2 bits
	one_bit_generate : if 	nmbr_of_bits = 1 generate
		n_bit_counter_inst : n_bit_counter 
			generic map (
				nmbr_of_bits	=> 4,
				reset_count		=> 0,
				user_flag_nmbr  => 15
			)
			port map (
   				clock				=> clock,
				a_reset				=> a_reset,
				s_reset 			=> reset_counters,
				enable				=> enable_test_reg,
				count				=> sel,
				zero_flag			=> open,
				user_flag		 	=> overflow,
				end_flag			=> open
			);

		--MUX a la salida del contador
		data_out_int(0) <= count(15 - to_integer(unsigned(sel)));
	end generate;

	two_bit_generate : if 	nmbr_of_bits = 2 generate
		n_bit_counter_inst : n_bit_counter 
			generic map (
				nmbr_of_bits	=> 3,
				reset_count		=> 0,
				user_flag_nmbr  => 7
			)
			port map (
   				clock				=> clock,
				a_reset				=> a_reset,
				s_reset 			=> reset_counters,
				enable				=> enable_test_reg,
				count				=> sel(2 downto 0),
				zero_flag			=> open,
				user_flag		 	=> overflow,
				end_flag			=> open
			);

		sel(3) <= '0';

		process(sel, count)
		begin
			if (sel = "0000") then
				data_out_int(1) <= count(14);
				data_out_int(0) <= count(15);
			elsif (sel = "0001") then
				data_out_int(1) <= count(12);
				data_out_int(0) <= count(13);
			elsif (sel = "0010") then
				data_out_int(1) <= count(10);
				data_out_int(0) <= count(11);
			elsif (sel = "0011") then
				data_out_int(1) <= count(8);
				data_out_int(0) <= count(9);
			elsif (sel = "0100") then
				data_out_int(1) <= count(6);
				data_out_int(0) <= count(7);
			elsif (sel = "0101") then
				data_out_int(1) <= count(4);
				data_out_int(0) <= count(5);
			elsif (sel = "0110") then
				data_out_int(1) <= count(2);
				data_out_int(0) <= count(3);
			else	--0111
				data_out_int(1) <= count(0);
				data_out_int(0) <= count(1);
			end if;
		end process;
	end generate;

	three_bit_generate : if nmbr_of_bits = 3 generate
		n_bit_counter_inst : n_bit_counter 
			generic map (
				nmbr_of_bits	=> 3,
				reset_count		=> 0,
				user_flag_nmbr  => 5
			)
			port map (
   				clock				=> clock,
				a_reset				=> a_reset,
				s_reset 			=> reset_counters,
				enable				=> enable_test_reg,
				count				=> sel(2 downto 0),
				zero_flag			=> open,
				user_flag		 	=> overflow,
				end_flag			=> open
			);

		sel(3) <= '0';

		process(sel, count)
		begin
			if (sel = "0000") then
				data_out_int(2) <= count(15);
				data_out_int(1) <= '0';
				data_out_int(0) <= '0';
			elsif (sel = "0001") then
				data_out_int(2) <= count(12);
				data_out_int(1) <= count(13);
				data_out_int(0) <= count(14);
			elsif (sel = "0010") then
				data_out_int(2) <= count(9);
				data_out_int(1) <= count(10);
				data_out_int(0) <= count(11);
			
			elsif (sel = "0011") then
				data_out_int(2) <= count(6);
				data_out_int(1) <= count(7);
				data_out_int(0) <= count(8);

			elsif (sel = "0100") then
				data_out_int(2) <= count(3);
				data_out_int(1) <= count(4);
				data_out_int(0) <= count(5);
			else --0101
				data_out_int(2) <= count(0);
				data_out_int(1) <= count(1);
				data_out_int(0) <= count(2);
			end if;
		end process;
	end generate;

	four_bit_generate : if 	nmbr_of_bits = 4 generate
		n_bit_counter_inst : n_bit_counter 
			generic map (
				nmbr_of_bits	=> 2,
				reset_count		=> 0,
				user_flag_nmbr  => 3
			)
			port map (
   				clock				=> clock,
				a_reset				=> a_reset,
				s_reset 			=> reset_counters,
				enable				=> enable_test_reg,
				count				=> sel(1 downto 0),
				zero_flag			=> open,
				user_flag		 	=> overflow,
				end_flag			=> open
			);
		sel(2) <= '0';
		sel(3) <= '0';

		process(sel, count)
		begin
			if (sel = "0000") then
				data_out_int(3) <= count(12);
				data_out_int(2) <= count(13);
				data_out_int(1) <= count(14);
				data_out_int(0) <= count(15);
			elsif (sel = "0001") then
				data_out_int(3) <= count(8);
				data_out_int(2) <= count(9);
				data_out_int(1) <= count(10);
				data_out_int(0) <= count(11);
			elsif (sel = "0010") then
				data_out_int(3) <= count(4);
				data_out_int(2) <= count(5);
				data_out_int(1) <= count(6);
				data_out_int(0) <= count(7);
			else --0011
				data_out_int(3) <= count(0);
				data_out_int(2) <= count(1);
				data_out_int(1) <= count(2);
				data_out_int(0) <= count(3);
			end if;
		end process;
	end generate;

	sixteen_bit_counter : n_bit_counter 
		generic map (
			nmbr_of_bits	=> 16,
			reset_count		=> 0,
			user_flag_nmbr  => 0
		)
		port map (
   			clock				=> clock,
			a_reset				=> a_reset,
			s_reset 			=> not_enable_test_reg,
			enable				=> overflow,
			count				=> count,
			zero_flag			=> open,
			user_flag		 	=> open,
			end_flag			=> open
		);

	reg_gen : for i in 0 to (nmbr_of_bits - 1) generate
    begin 
		ffD_data_inst : ffD
			port map (
   		 		clock			=> clock,
				a_reset			=> a_reset,
				en				=> enable_test_reg,
    			d				=> data_out_int(i),
    			q				=> data_out(i),
				not_q			=> open
			);
	end generate;

	--FFD que genera la señal data_valid, que indica cuándo pueden leerse datos del módulo
	ffD_data_valid_inst : ffD
		port map (
   		 	clock			=> clock,
			a_reset			=> a_reset,
			en				=> '1',
    		d				=> enable_test_reg,
    		q				=> data_valid,
			not_q			=> open
		);
	
end testGen_behaviour;
