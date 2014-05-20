-- vim:et:ts=2:sw=2:sts=2:fileencoding=utf-8
library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library sha256_lib;
use sha256_lib.sha256_pkg.all;

entity hw is
  port(
    clk: in std_ulogic;
    rst: in std_ulogic;
    load: in std_ulogic;
    hin: in block256;
    padded_msg: in block512;
    state: out block256;
    step: in std_ulogic
  );
end entity;

architecture arc of hw is
  signal w: block2048;
  signal stage_enable: std_ulogic_vector(0 to 64); -- yes this is 65

  type state_pipe is array(natural range <>) of block256;
  -- states is the unrolled intermediate a_h states
  signal states: state_pipe(0 to 4);
  -- hin_pipe carries the input state to the last cycle for the final combination
  signal hin_pipe: state_pipe(0 to 4);
begin

  process(clk)
    variable state_in: block256;
    variable w_in: w32;
    variable k_in: w32;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        stage_enable <= (others=>'0');
      elsif step = '1' then
        if load = '1' then
          -- parallel load of the first 16 message blocks
          w(padded_msg'range) <= padded_msg;
        end if;

        hin_pipe(0) <= hin;
        stage_enable <= load & stage_enable(stage_enable'low to stage_enable'high -1);

        for i in 16 to w'high loop
          -- w_16 can be computed in the first cycle, offset accordingly
          if stage_enable(i - 16) = '1' then
            -- one iteration of message scheduling
            w(i) <= ms1(w(i - 2), w(i - 7), w(i - 15), w(i - 16));
          end if;
        end loop;

        for i in 0 to states'high - 1 loop
          state_in := (others=>(others=>'0'));
          w_in := (others=>'0');
          k_in := (others=>'0');
          case stage_enable(i*16 to i*16+15) is
            when "0000000000000000" =>
            when "1000000000000000" =>
              if i = 0 then
                state_in := hin_pipe(0);
                w_in := w(0);
                k_in := k(0);
              else
                state_in := states(i - 1);
                w_in := w(i*16 + 0);
                k_in := k(i*16 + 0);
              end if;
              hin_pipe(i + 1) <= hin_pipe(i);
            when "0100000000000000" =>
              state_in := states(i);
              w_in := w(i*16 + 1);
              k_in := k(i*16 + 1);
            when "0010000000000000" =>
              state_in := states(i);
              w_in := w(i*16 + 2);
              k_in := k(i*16 + 2);
            when "0001000000000000" =>
              state_in := states(i);
              w_in := w(i*16 + 3);
              k_in := k(i*16 + 3);
            when "0000100000000000" =>
              state_in := states(i);
              w_in := w(i*16 + 4);
              k_in := k(i*16 + 4);
            when "0000010000000000" =>
              state_in := states(i);
              w_in := w(i*16 + 5);
              k_in := k(i*16 + 5);
            when "0000001000000000" =>
              state_in := states(i);
              w_in := w(i*16 + 6);
              k_in := k(i*16 + 6);
            when "0000000100000000" =>
              state_in := states(i);
              w_in := w(i*16 + 7);
              k_in := k(i*16 + 7);
            when "0000000010000000" =>
              state_in := states(i);
              w_in := w(i*16 + 8);
              k_in := k(i*16 + 8);
            when "0000000001000000" =>
              state_in := states(i);
              w_in := w(i*16 + 9);
              k_in := k(i*16 + 9);
            when "0000000000100000" =>
              state_in := states(i);
              w_in := w(i*16 + 10);
              k_in := k(i*16 + 10);
            when "0000000000010000" =>
              state_in := states(i);
              w_in := w(i*16 + 11);
              k_in := k(i*16 + 11);
            when "0000000000001000" =>
              state_in := states(i);
              w_in := w(i*16 + 12);
              k_in := k(i*16 + 12);
            when "0000000000000100" =>
              state_in := states(i);
              w_in := w(i*16 + 13);
              k_in := k(i*16 + 13);
            when "0000000000000010" =>
              state_in := states(i);
              w_in := w(i*16 + 14);
              k_in := k(i*16 + 14);
            when "0000000000000001" =>
              state_in := states(i);
              w_in := w(i*16 + 15);
              k_in := k(i*16 + 15);
            when others =>
              -- pragma synthesis_off
              report "invalid stage enable vector" severity error;
              -- pragma synthesis_on
          end case;
          states(i) <= cf1(state_in, w_in, k_in);
        end loop;

        if stage_enable(4*16) = '1' then
          for i in block256'range loop
            states(4)(i) <= states(3)(i) + hin_pipe(hin_pipe'high)(i);
          end loop;
        end if;
      end if;
    end if;
  end process;

  state <= states(states'high);

end architecture;
