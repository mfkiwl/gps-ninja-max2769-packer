--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: output_controller.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Máquina de estados que lee la FIFO.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity output_controller is
port (
   	clock		: in std_logic;
	a_reset		: in std_logic;
	fifo_empty	: in std_logic;
	data_valid	: in std_logic;
	reg_is_free	: in std_logic;
	read_enable	: out std_logic;
	load_reg	: out std_logic
);
end output_controller;

architecture output_controller_behaviour of output_controller is
	type status is (IDLE, READ_FIFO, WAIT_FOR_DATA, DATA_READY_ON_FIFO, LOAD_REGISTER);

	signal current_state : status := IDLE;
	signal next_state : status := IDLE;
begin
	--Proceso combinacional de la máquina de estados
	comb_process : process(current_state, fifo_empty, data_valid, reg_is_free)
	begin
		read_enable	<= '0';
		load_reg	<= '0';
		next_state  <= current_state;

		case current_state is
			when IDLE =>
				if (fifo_empty = '0') then
					next_state <= READ_FIFO;
				end if;
			when READ_FIFO => --Lee la FIFO
				read_enable <= '1';
				next_state  <= WAIT_FOR_DATA;
			when WAIT_FOR_DATA => --Espera que los datos salgan de la FIFO
				if (data_valid = '1' and reg_is_free = '0') then
					next_state  <= DATA_READY_ON_FIFO;
				elsif (data_valid = '1' and reg_is_free = '1') then
					next_state  <= LOAD_REGISTER;
				end if;
			when DATA_READY_ON_FIFO => --Los datos están en la boca de la FIFO, pero el registro no está listo
				if (reg_is_free = '1') then --Si se libera el registro...
					next_state  <= LOAD_REGISTER;
				end if;
			when LOAD_REGISTER => --Se carga el registro
				load_reg <= '1';
				--if (fifo_empty = '0') then --Si la FIFO tiene datos, vuelve a leerse
					--next_state  <= READ_FIFO;
				--else
					next_state  <= IDLE;
				--end if;
		end case;
	end process;

	--Proceso sequencial de la máquina de estados
	seq_process : process(clock, a_reset)
	begin
		if (a_reset = '1') then
			current_state <= IDLE;
		elsif rising_edge(clock) then
			current_state <= next_state;
		end if;
	end process;
end output_controller_behaviour;
