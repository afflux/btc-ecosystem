-- vim:et:ts=2:sw=2:sts=2:fileencoding=utf-8
library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library sha256_lib;
use sha256_lib.sha256_pkg.all;

entity org is
  generic(
    instances: natural range 1 to 16 := 2
  );
  port(
    clk: in std_ulogic;

    state_in: in std_ulogic_vector(0 to 255);
    prefix: in std_ulogic_vector(0 to 95);
    mask: in std_ulogic_vector(0 to 255);
    ctrl: in std_ulogic_vector(31 downto 0);
    nonce_first: in w32;
    nonce_last: in w32;

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
  constant PADDING_0: std_ulogic_vector(0 to 383) := (0=>'1', 374=>'1', 376=>'1', others=>'0');
  constant PADDING_1: std_ulogic_vector(0 to 255) := (0=>'1', 247=>'1', others=>'0');

  type std_ulogic_vector_2d is array (0 to instances - 1) of std_ulogic_vector(0 to 10);
  type w32_vector_2d is array (0 to instances - 1) of w32_vector(0 to 10);
  type block256_2d is array (0 to instances - 1) of block256;

  signal stage_pipe: std_ulogic_vector_2d;
  signal nonce_pipe: w32_vector_2d;

  type state_t is (RDY, BUSY, FIN, IDLE, FOUND, ERR);
  signal status_internal: state_t;
  signal nonce: w32;
  signal nonce_candidate_internal: w32;
  signal ctr: unsigned(7 downto 0);

  signal result_0, result_1: block256_2d;
  signal result_candidate: block256;

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
  
  function uand(a: boolean; b: std_ulogic) return std_ulogic is
  begin
    if a = false then
      return '0';
    else
      return b;
    end if;
  end function uand;
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
        stage_pipe <= (others=>(others=>'0'));
        status_internal <= RDY;
        clk_counter <= to_unsigned(0, clk_counter'length);
        ctr <= to_unsigned(0, ctr'length);
      elsif step = '1' then
        clk_counter <= clk_counter + 1;

        -- the pipelines have to keep mooving, independent from the current state (status_internal)
        for i in 0 to instances - 1 loop
          if ctr mod 16 = i then
            nonce_pipe(i) <= to_unsigned(0, nonce_pipe(i)'length) & nonce_pipe(i)(nonce_pipe(i)'low to nonce_pipe(i)'high - 1);
            stage_pipe(i) <= '0' & stage_pipe(i)(stage_pipe(i)'low to stage_pipe(i)'high - 1);
          end if;
        end loop;
        ctr <= ctr + 1;

        case status_internal is
          when RDY =>
            if ctrl(RUN_IDX) = '1' then
              status_internal <= BUSY;
              ctr <= to_unsigned(0, ctr'length);
              nonce <= nonce_first;
            end if;

          when BUSY =>
            for i in 0 to instances - 1 loop
              -- if the counter is a multiple of 16
              if ctr mod 16 = i then
                -- we can feed in the next value
                stage_pipe(i)(0) <= '1';
                nonce_pipe(i)(0) <= nonce;
                -- and calculate the next nonce
                nonce <= nonce + 1;
              end if;
            end loop;

            if nonce = nonce_last then
              ctr <= to_unsigned(1, ctr'length);
              status_internal <= FIN;
            end if;

          when FIN =>
            if ctr = stage_pipe(0)'high * 16 then
              irq <= '1';
              status_internal <= IDLE;
            end if;

          when IDLE =>

          when FOUND =>
            if ctrl(RUN_IDX) = '1' then
              status_internal <= BUSY;
              ctr <= to_unsigned(0, ctr'length);
              nonce <= nonce_candidate_internal + 1;
            end if;

          when others =>
            status_internal <= ERR;
        end case;

        if (status_internal = BUSY or status_internal = FIN) then
          for i in 0 to instances - 1 loop
            if stage_pipe(i)(stage_pipe(i)'high) = '1' and is_candidate(mask, result_1(i)) then
              nonce_candidate_internal <= nonce_pipe(i)(nonce_pipe(i)'high);
              result_candidate <= result_1(i);
              irq <= '1';
              status_internal <= FOUND;
            end if;
          end loop;
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

  sha_instances: for i in 0 to instances - 1 generate
    sha_0: entity work.hw(arc)
    port map (
      clk,
      ctrl(RST_IDX), -- reset
      uand(ctr mod 16 = i, stage_pipe(i)(0)), -- load
      to_block256(state_in), -- initial state
      to_block512(prefix & std_ulogic_vector(nonce_pipe(i)(0)) & PADDING_0), -- padded message
      result_0(i),
      step
    );

    sha_1: entity work.hw(arc)
    port map (
      clk,
      ctrl(RST_IDX), -- reset
      uand(ctr mod 16 = i, stage_pipe(i)(5)), -- load
      H0, -- initial state
      to_block512(to_suv256(result_0(i)) & PADDING_1), -- padded message
      result_1(i),
      step
    );
  end generate;

  nonce_current <= nonce;
  nonce_candidate <= nonce_candidate_internal;
  dbg(0 to 7) <= result_candidate;
  dbg(8 to 15) <= to_block256(mask);
  dbg(16 to 23) <= to_block256(to_suv256(result_candidate) and mask);
  dbg(24) <= clk_counter;

end architecture;
