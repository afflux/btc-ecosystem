-- vim:et:ts=2:sw=2:sts=2:fileencoding=utf-8
library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library sha256_lib;
use sha256_lib.sha256_pkg.all;

library std;
use std.textio.all;

entity org is
  port(
    clk: in std_ulogic;
    state_in: in std_ulogic_vector(255 downto 0);
    prefix: in std_ulogic_vector(95 downto 0);
    nlz: in unsigned(7 downto 0);
    ctrl: in std_ulogic_vector(31 downto 0);

    nonce_candidate: out unsigned(31 downto 0);
    nonce_current: out unsigned(31 downto 0);
    status: out std_ulogic_vector(31 downto 0);
    irq: out std_ulogic;
    dbg1: out std_ulogic_vector(31 downto 0);
    dbg2: out std_ulogic_vector(31 downto 0);
    dbg3: out std_ulogic_vector(31 downto 0);
    dbg4: out std_ulogic_vector(31 downto 0);
    step: in std_ulogic
  );
end entity;

architecture arc of org is
  constant RST_IDX: natural := 0;
  constant RUN_IDX: natural := 1;
  constant NONCE_MAX: unsigned(31 downto 0) := (others=>'1');
  constant PADDING_0: std_ulogic_vector(0 to 383) := (0=>'1', 374=>'1', 376=>'1', others=>'0');
  constant PADDING_1: std_ulogic_vector(0 to 255) := (0=>'1', 247=>'1', others=>'0');

  type nonce_pipe_t is array(integer range <>) of unsigned(31 downto 0);
  signal stage_pipe: std_ulogic_vector(0 to 132);
  signal nonce_pipe: nonce_pipe_t(0 to 132);

  type state_t is (RDY, BUSY, FIN, IDLE, FOUND, ERR);
  signal status_internal: state_t;
  signal nonce: unsigned(31 downto 0);
  signal ctr: unsigned(3 downto 0);

  signal rst_0, rst_1: std_ulogic;
  signal load_0, load_1: std_ulogic;
  signal h_in: block256;
  signal padded_msg_0, padded_msg_1: block512;
  signal result_0, result_1: block256;

  signal clk_counter: unsigned(31 downto 0);

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
  function mask_candidate(nlz: unsigned(7 downto 0)) return std_ulogic_vector is
    constant nlzi: integer := to_integer(nlz);
    variable mask: std_ulogic_vector(255 downto 0);
  begin
    for i in 0 to 31 loop
      for j in 0 to 7 loop
        mask(i*8 + j) := '1' when (i*8) + (7-j) < nlzi else '0';
      end loop;
    end loop;
    return mask;
  end function;
begin

  sha_0: entity work.hw(arc) port map(clk, rst_0, load_0, h_in, padded_msg_0, result_0, step);
  sha_1: entity work.hw(arc) port map(clk, rst_1, load_1, H0,   padded_msg_1, result_1, step);

  process(clk)
    function is_candidate(nlz: unsigned(7 downto 0); candidate: block256) return boolean is
      variable mask: std_ulogic_vector(255 downto 0) := mask_candidate(nlz);
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
        nonce_pipe <= (others=>(others=>'0'));
        nonce <= (others=>'0');
        ctr <= (others=>'0');
        status_internal <= RDY;

        clk_counter <= (others => '0');
      elsif step = '1' then

        clk_counter <= clk_counter + 1;

        -- the pipelines have to keep mooving, independent from the current state (status_internal)
        nonce_pipe <= nonce & nonce_pipe(nonce_pipe'low to nonce_pipe'high - 1);
        stage_pipe <= '0' & stage_pipe(stage_pipe'low to stage_pipe'high - 1);
        ctr <= (ctr + 1) mod 16;


        case status_internal is
          when RDY =>
            if ctrl(RUN_IDX) = '1' then
              status_internal <= BUSY;
              ctr <= (others=>'0');
            end if;

          when BUSY =>
            -- if the counter is a multiple of 16 (ctr mod 16 = 0)
            if ctr = 0 then
              -- we can feed in the next value
              stage_pipe(0) <= '1';
              -- and calculate the next nonce
              nonce <= nonce + 1;
            end if;

            if nonce = NONCE_MAX then
              status_internal <= FIN;
            end if;

          when FIN =>
            -- FIXME: we have to wait until the pipeline is completely done
            status_internal <= IDLE;

          when IDLE =>
            null;

          when FOUND =>
            null;

          when others =>
            status_internal <= ERR;
        end case;

        if (status_internal = BUSY or status_internal = FIN) and stage_pipe(stage_pipe'high) = '1' and is_candidate(nlz, result_1) then
          nonce_candidate <= nonce_pipe(nonce_pipe'high);
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
  nonce_current <= nonce;
  dbg1 <= std_ulogic_vector(result_1(7));
  dbg2 <= mask_candidate(nlz)(31 downto 0);
  dbg3 <= std_ulogic_vector(result_1(7)) and mask_candidate(nlz)(31 downto 0);
  dbg4 <= std_ulogic_vector(clk_counter);

end architecture;
