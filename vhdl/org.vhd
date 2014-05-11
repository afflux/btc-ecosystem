-- vim:et:ts=2:sw=2:sts=2:fileencoding=utf-8
library sha256_lib;
use sha256_lib.sha256_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library STD;
use STD.textio.all;

entity org is
  port(clk: in std_ulogic;
       state_in: in std_ulogic_vector(255 downto 0);
       prefix: in std_ulogic_vector(95 downto 0);
       nlz: in unsigned(7 downto 0);
       ctrl: in std_ulogic_vector(32 downto 0);
       
       nonce_candidate: out unsigned(31 downto 0);
       nonce_current: out unsigned(31 downto 0);
       status: out std_ulogic_vector(31 downto 0);
       irq: out std_ulogic
  );
end entity org;


architecture arc of org is
  constant RST_IDX: natural := 0;
  constant RUN_IDX: natural := 1;
  constant NONCE_MAX: unsigned(31 downto 0) := (others=>'1');
  constant PADDING_0: std_ulogic_vector(0 to 383) := (0=>'1', 374 to 383 => "1010000000", others=>'0');
  constant PADDING_1: std_ulogic_vector(0 to 255) := (0=>'1', 247 to 255 =>  "100000000", others=>'0');

  type nonce_pipe_t is array(integer range <>) of unsigned(31 downto 0);
  signal stage_pipe: std_ulogic_vector(0 to 132);
  signal nonce_pipe: nonce_pipe_t(0 to 132);


  signal nonce: unsigned(31 downto 0);
  signal ctr: unsigned(3 downto 0);

  signal rst_0, rst_1: std_ulogic;
  signal load_0, load_1: std_ulogic;
  signal h_in: block256;
  signal padded_msg_0, padded_msg_1: block512;
  signal result_0, result_1: block256;

  type state_t is (RDY, BUSY, IDLE);
  signal status_internal: state_t;


  function to_block512(d : std_ulogic_vector(0 to 511)) return block512 is
    variable res : block512;
  begin
    for i in res'range loop
      res(i) := w32(d(i * 32 to (i*32)+31));
    end loop;
    return res;
  end function to_block512;

  function to_block256(d : std_ulogic_vector(0 to 255)) return block256 is
    variable res : block256;
  begin
    for i in res'range loop
      res(i) := w32(d(i * 32 to (i*32)+31));
    end loop;
    return res;
  end function to_block256;

  function to_suv256(d : block256) return std_ulogic_vector is
    variable res : std_ulogic_vector(0 to 255);
  begin
    for i in d'range loop
      res(i * 32 to (i*32) + 31) := std_ulogic_vector(d(i));
    end loop;
    return res;
  end function to_suv256;
begin


  sha_0: entity work.hw(arc) port map(clk, rst_0, load_0, h_in, padded_msg_0, result_0);
  sha_1: entity work.hw(arc) port map(clk, rst_1, load_1, H0,   padded_msg_1, result_1);

  process(clk, ctrl)
    function is_candidate(nlz: unsigned(7 downto 0); candidate: block256) return boolean is
      variable nlzi: integer := to_integer(nlz);
      variable mask: unsigned(255 downto 0);
      variable c: unsigned(0 to 255);
    begin
      for i in 0 to 31 loop
        for j in 7 downto 0 loop
          mask(i*8 + j) := '1' when (i*8) + (7-j) < nlzi else '0';
        end loop;
      end loop;
      c := unsigned(to_suv256(candidate));
      return (mask and c) = 0;
    end function is_candidate;
  begin
    status_internal <= status_internal;
    ctr <= ctr;
    nonce_pipe <= nonce_pipe;
    stage_pipe <= stage_pipe;
    nonce <= nonce;
    irq <= '0';

    if ctrl(RST_IDX) = '1' then
      stage_pipe <= (others=>'0');
      nonce_pipe <= (others=>(others=>'0'));
      nonce <= (others=>'0');
      ctr <= (others=>'0');
      status_internal <= RDY;
    elsif RISING_EDGE(clk) then

      case status_internal is
        when RDY =>
          if ctrl(RUN_IDX) = '1' then
            status_internal <= BUSY;
          end if;
        when BUSY =>
          ctr <= (ctr + 1) mod 16;
          if nonce = NONCE_MAX then
            status_internal <= IDLE;
          end if;

          nonce_pipe <= (nonce) & (nonce_pipe(nonce_pipe'low to nonce_pipe'high - 1));
          if ctr = 0 then
            nonce <= nonce + 1;
            stage_pipe <= ('1') & (stage_pipe(stage_pipe'low to stage_pipe'high - 1));
          else
            stage_pipe <= ('0') & (stage_pipe(stage_pipe'low to stage_pipe'high - 1));
          end if;

          if stage_pipe(stage_pipe'high) = '1' then
            if is_candidate(nlz, result_1) then
              nonce_candidate <= nonce_pipe(nonce_pipe'high);
              irq <= '1';
              status_internal <= IDLE;
            end if;
          end if;

        when IDLE =>
          null;
      end case;
    end if;
  end process;

  with status_internal select
    status <= (0=>'1', others=>'0') when RDY,
              (1=>'1', others=>'0') when BUSY,
              (others=>'0') when IDLE;

  padded_msg_0 <= to_block512(prefix & std_ulogic_vector(nonce_pipe(0)) & PADDING_0);
  padded_msg_1 <= to_block512(to_suv256(result_0) & PADDING_1);
  h_in <= to_block256(state_in);
  rst_0 <= ctrl(RST_IDX);
  rst_1 <= ctrl(RST_IDX);
  load_0 <= stage_pipe(0);
  load_1 <= stage_pipe(66);
  nonce_current <= nonce;

end architecture arc;