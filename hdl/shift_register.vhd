--------------------------------------------------------------------------------
-- Company: Satellogic
--
-- File: shift_register.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Shift Register.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN250V2> <Package::100 VQFP>
-- Author: Manuel F. Díaz Ramos
--
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity shift_register is
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
end shift_register;

architecture shift_register_behaviour of shift_register is
	signal reg : std_logic_vector((nbits - 1) downto 0) := (others => '0');
begin

	serial_out <= reg(nbits - 1) when (MSB_first = '1') else
					reg(0);

   	process(clock, a_reset)
	begin
		if (a_reset = '1') then
			reg <= (others => '0');
		elsif rising_edge(clock) then
			if (load_nShift = '1') then
				reg <= parallel_in;
			else
				if (MSB_first = '1') then
					for i in 1 to (nbits-1) loop
						reg(i) <= reg(i-1);
					end loop;
					if (barrel = '1') then
						reg(0) <= reg(nbits-1);
					else
						reg(0) <= '0';
					end if;
				else --Se shiftea para el otro lado
					for i in 1 to (nbits-1) loop
						reg(i-1) <= reg(i);
					end loop;
					if (barrel = '1') then
						reg((nbits-1)) <= reg(0);
					else
						reg((nbits-1)) <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
end shift_register_behaviour;
