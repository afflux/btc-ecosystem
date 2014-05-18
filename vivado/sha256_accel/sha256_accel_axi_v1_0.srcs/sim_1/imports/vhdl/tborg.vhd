-- vim:et:ts=2:sw=2:sts=2:fileencoding=utf-8
library sha256_lib;
use sha256_lib.sha256_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library std;
use std.textio.all;

entity tborg is
end entity;

architecture arc of tborg is
  -- clock counter
  signal ctr: integer := -2;

  -- signals connected to DUT
  signal clk: std_ulogic := '0';
  signal state_in: std_ulogic_vector(255 downto 0);
  signal prefix: std_ulogic_vector(95 downto 0);
  signal mask: std_ulogic_vector(255 downto 0) := (7 downto 4 => '1', others=>'0');
  signal ctrl: std_ulogic_vector(31 downto 0) := (others=>'0');
       
  signal nonce_candidate: unsigned(31 downto 0);
  signal nonce_current: unsigned(31 downto 0);
  signal status: std_ulogic_vector(31 downto 0);
  signal irq: std_ulogic;

  signal dbg: w32_vector(0 to 24);
begin

  sha: entity work.org(arc) port map(clk, state_in, prefix, mask, ctrl, nonce_candidate, nonce_current, status, irq, dbg, '1');

  CLK_GEN: process
  begin
    for i in -2 to 116 + 16*256*4 + 2 loop
      ctr <= i;
      clk <= '0';
      wait for 10 ns;
      clk <= '1';
      wait for 10 ns;
    end loop;
    report "Simulation finished after " & integer'image(ctr) & " cycles" severity note;
    wait;
  end process CLK_GEN;

  -- this corresponds to sha256_unpadded("01000000" +"81cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000" + "e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0")
  state_in <= X"9524c59305c5671316e669ba2d2810a007e86e372f56a9dacd5bce697a78da2d";

  prefix <= X"f1fc122bc7f5d74df2b9441a";

  SIG_GEN: process(ctr, irq)
    variable l: LINE;
  begin
    -- reset DUT
    if ctr = -2 then
      report "reset high" severity note;
      ctrl <= (0=>'1', others=>'0');
    elsif ctr = -1 then
      report "reset low" severity note;
      ctrl <= (others=>'0');
    end if;

    if ctr'event then
      case ctr is
        when 0 =>
          report "start high" severity note;
          ctrl <= (1=>'1', others=>'0');

        when 1 =>
          --report "start low" severity note;
          --ctrl <= (others=>'0');

        when others =>
      end case;
    end if;

    if irq = '1' and irq'event then
      report "result " severity note;
      hwrite(l, dbg);
      writeline(output, l);
    end if;

  end process;

end architecture;
