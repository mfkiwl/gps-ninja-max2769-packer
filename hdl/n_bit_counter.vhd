--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: n_bit_counter.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Contador de n bits
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity n_bit_counter is
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
		count				: out std_logic_vector((nmbr_of_bits - 1) downto 0);
		zero_flag			: out std_logic;
		user_flag		 	: out std_logic;
		end_flag			: out std_logic
	);
end n_bit_counter;

architecture n_bit_counter_behaviour of n_bit_counter is
	signal current_count : std_logic_vector((nmbr_of_bits-1) downto 0) := (others => '0');
	signal next_count : std_logic_vector((nmbr_of_bits-1) downto 0) := (others => '0');
begin

	comb_next_word_proc : process(current_count, s_reset, enable)
	begin
		if (s_reset = '1') then
			next_count <= std_logic_vector(to_unsigned(reset_count, nmbr_of_bits));
		elsif (enable = '1') then
			next_count <= std_logic_vector(unsigned(current_count) + 1);
		else
			next_count <= current_count;
		end if;
	end process;

	count <= current_count;

	zero_flag <= '1'  when (unsigned(current_count) = to_unsigned(0, nmbr_of_bits)) else
				 '0';

	user_flag <= '1'  when (unsigned(current_count) = to_unsigned(user_flag_nmbr, nmbr_of_bits)) else
				 '0';

	end_flag <= '1'  when (unsigned(current_count) = to_unsigned(2**(nmbr_of_bits) - 1, nmbr_of_bits)) else
				'0';

	seq_proc : process(clock, a_reset)
	begin
		if (a_reset = '1') then
			current_count <= std_logic_vector(to_unsigned(reset_count, nmbr_of_bits));
		elsif rising_edge(clock) then
			current_count <= next_count;
		end if;
	end process;
		
end n_bit_counter_behaviour;
