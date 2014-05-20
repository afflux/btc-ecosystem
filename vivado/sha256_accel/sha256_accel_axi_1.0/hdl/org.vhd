-- vim:et:ts=2:sw=2:sts=2:fileencoding=utf-8
library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library sha256_lib;
use sha256_lib.sha256_pkg.all;

entity org is
  port(
    clk: in std_ulogic;

    state_in: in std_ulogic_vector(0 to 255);
    prefix: in std_ulogic_vector(0 to 95);
    mask: in std_ulogic_vector(0 to 255);
    ctrl: in std_ulogic_vector(31 downto 0);

    nonce_candidate: out w32;
    nonce_current: out w32;
    status: out std_ulogic_vector(31 downto 0);
    irq: out std_ulogic;

    dbg: out w32_vector(0 to 24);
    step: in std_ulogic
  );
end entity;

architecture arc of org is
  constant RST_IDX: natural := 0;
  constant RUN_IDX: natural := 1;
  constant NONCE_MAX: w32 := (others=>'1');
  constant PADDING_0: std_ulogic_vector(0 to 383) := (0=>'1', 374=>'1', 376=>'1', others=>'0');
  constant PADDING_1: std_ulogic_vector(0 to 255) := (0=>'1', 247=>'1', others=>'0');

  signal stage_pipe: std_ulogic_vector(0 to 132);
  signal nonce_pipe: w32_vector(0 to 132);

  type state_t is (RDY, BUSY, FIN, IDLE, FOUND, ERR);
  signal status_internal: state_t;
  signal nonce: w32;
  signal ctr: unsigned(7 downto 0);

  signal rst_0, rst_1: std_ulogic;
  signal load_0, load_1: std_ulogic;
  signal h_in: block256;
  signal padded_msg_0, padded_msg_1: block512;
  signal result_0, result_1, result_candidate: block256;

  signal clk_counter: w32;

  function to_block512(d : std_ulogic_vector(0 to 511)) return block512 is
    variable res : block512;
  begin
    for i in res'range loop
      res(i) := w32(d(i * 32 to (i*32)+31));
    end loop;
    return res;
  end function;

  function to_block256(d : std_ulogic_vector(0 to 255)) return block256 is
    variable res : block256;
  begin
    for i in res'range loop
      res(i) := w32(d(i * 32 to (i*32)+31));
    end loop;
    return res;
  end function;

  function to_suv256(d : block256) return std_ulogic_vector is
    variable res : std_ulogic_vector(0 to 255);
  begin
    for i in d'range loop
      res(i * 32 to (i*32) + 31) := std_ulogic_vector(d(i));
    end loop;
    return res;
  end function;
begin

  process(clk)
    function is_candidate(mask: std_ulogic_vector(0 to 255); candidate: block256) return boolean is
      variable c: std_ulogic_vector(0 to 255) := to_suv256(candidate);
    begin
      return (mask and c) = (0 to 255=>'0');
    end function;
  begin
    if rising_edge(clk) then
      -- the interrupt line is low by default and will only be hight for one clock cycle when an interrupt has to be signaled
      irq <= '0';
      if ctrl(RST_IDX) = '1' then
        stage_pipe <= (others=>'0');
        status_internal <= RDY;
        clk_counter <= to_unsigned(0, clk_counter'length);
      elsif step = '1' then
        clk_counter <= clk_counter + 1;

        -- the pipelines have to keep mooving, independent from the current state (status_internal)
        nonce_pipe <= nonce & nonce_pipe(nonce_pipe'low to nonce_pipe'high - 1);
        stage_pipe <= '0' & stage_pipe(stage_pipe'low to stage_pipe'high - 1);
        ctr <= ctr + 1;

        case status_internal is
          when RDY =>
            if ctrl(RUN_IDX) = '1' then
              status_internal <= BUSY;
              ctr <= to_unsigned(0, ctr'length);
              nonce <= to_unsigned(0, nonce'length);
            end if;

          when BUSY =>
            -- if the counter is a multiple of 16
            if ctr mod 16 = 0 then
              -- we can feed in the next value
              stage_pipe(0) <= '1';
              -- and calculate the next nonce
              nonce <= nonce + 1;
              ctr <= to_unsigned(1, ctr'length);
            end if;

            if nonce = NONCE_MAX then
              status_internal <= FIN;
            end if;

          when FIN =>
            if ctr = stage_pipe'high then
              status_internal <= IDLE;
              irq <= '1';
            end if;

          when IDLE =>

          when FOUND =>

          when others =>
            status_internal <= ERR;
        end case;

        if (status_internal = BUSY or status_internal = FIN) and stage_pipe(stage_pipe'high) = '1' and is_candidate(mask, result_1) then
          nonce_candidate <= nonce_pipe(nonce_pipe'high);
          result_candidate <= result_1;
          irq <= '1';
          status_internal <= FOUND;
        end if;
      end if;
    end if;
  end process;

  with status_internal
    select status <=
      (0=>'1', others=>'0') when RDY,
      (1=>'1', others=>'0') when BUSY,
      (2=>'1', others=>'0') when FIN,
      (3=>'1', others=>'0') when IDLE,
      (4=>'1', others=>'0') when FOUND,
      (5=>'1', others=>'0') when ERR,
      (6=>'1', others=>'0') when others;

  padded_msg_0 <= to_block512(prefix & std_ulogic_vector(nonce_pipe(0)) & PADDING_0);
  padded_msg_1 <= to_block512(to_suv256(result_0) & PADDING_1);
  h_in <= to_block256(state_in);
  rst_0 <= ctrl(RST_IDX);
  rst_1 <= ctrl(RST_IDX);
  load_0 <= stage_pipe(0);
  load_1 <= stage_pipe(66);

  sha_0: entity work.hw(arc) port map(clk, rst_0, load_0, h_in, padded_msg_0, result_0, step);
  sha_1: entity work.hw(arc) port map(clk, rst_1, load_1, H0,   padded_msg_1, result_1, step);

  nonce_current <= nonce;
  dbg(0 to 7) <= result_candidate;
  dbg(8 to 15) <= to_block256(mask);
  dbg(16 to 23) <= to_block256(to_suv256(result_candidate) and mask);
  dbg(24) <= clk_counter;

end architecture;
