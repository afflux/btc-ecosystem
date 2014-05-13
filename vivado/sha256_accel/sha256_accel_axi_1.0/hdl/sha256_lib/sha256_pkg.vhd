library global_lib;
library ieee;

use global_lib.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_TEXTIO.all;

library STD;
use STD.textio.all;

package sha256_pkg is
	subtype w32 is unsigned(31 downto 0);
	type w32_vector is array(natural range <>) of w32;
	subtype block256 is w32_vector(0 to 7);
	subtype block512 is w32_vector(0 to 15);
	subtype block2048 is w32_vector(0 to 63);
	type block512_vector is array(natural range <>) of block512;
	type block256_vector is array(natural range <>) of block256;

	constant BLOCK_MAX: integer := 512 - 64 - 1;

	-- mathieu && alexandrine
	type tv is record
		m: std_ulogic_vector(0 to 1023); --message
		                      -- The numeration 0 to 1023 was annoying
		                      -- to the declaration of the test vector.
		                      -- Is it really necessary? And if it is
		                      -- is there a way to force the size of
		                      -- the message?
		                      -- Kjell: sorry guys, I think it is
		                      -- necessary. Using the type in the
		                      -- testvectors definition and the check
		                      -- function fails without it
		l: natural; -- length
		s: block256; -- hash of the message
	end record;

	constant H0: block256 := ( --let's call it H0
		x"6a09e667",
		x"bb67ae85",
		x"3c6ef372",
		x"a54ff53a",
		x"510e527f",
		x"9b05688c",
		x"1f83d9ab",
		x"5be0cd19"
	);

	constant K: block2048 := (
		x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5", x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
		x"d807aa98", x"12835b01", x"243185be", x"550c7dc3", x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
		x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc", x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
		x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7", x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
		x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13", x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
		x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3", x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
		x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5", x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
		x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208", x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2"
	);

	-- pragma translate_off
	-- first test vector with length < 512 - 1 - 64
	constant tv1 : tv := (
		(x"616263", others=>'0'),
		24,
		(x"ba7816bf", x"8f01cfea", x"414140de", x"5dae2223", x"b00361a3", x"96177a9c", x"b410ff61", x"f20015ad")
	);

	-- second test vector with length between 512 - 1 - 64 and 512
	constant tv2 : tv := (
		(x"6162636462636465636465666465666765666768666768696768696a68696a6b696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f7071", others=>'0'),
		448,
		(x"248d6a61", x"d20638b8", x"e5c02693", x"0c3e6039", x"a33ce459", x"64ff2167", x"f6ecedd4", x"19db06c1")
	);

	-- third test vector with length between 512 and 2*512 - 1 - 64
	constant tv3 : tv := (
		(x"61626364656667686263646566676869636465666768696a6465666768696a6b65666768696a6b6c666768696a6b6c6d6768696a6b6c6d6e68696a6b6c6d6e6f696a6b6c6d6e6f706a6b6c6d6e6f70716b6c6d6e6f7071726c6d6e6f707172736d6e6f70717273746e6f707172737475", others=>'0'),
		896,
		(x"cf5b16a7", x"78af8380", x"036ce59e", x"7b049237", x"0b249b11", x"e8f07a51", x"afac4503", x"7afee9d1")
	);

	type tv_list is array(natural range <>) of tv;
	constant testvectors : tv_list := (tv1, tv2, tv3);
	-- pragma translate_on

	-- mathieu
	function sigma0(x: w32) return w32;
	-- alexandrine
	function sigma1(x: w32) return w32;
	-- nicolas
	function sum0(x: w32) return w32;
	-- pop
	function sum1(x: w32) return w32;
	--michele
	function Ch(x, y, z: w32) return w32;
	-- luca
	function Maj(x, y, z: w32) return w32;

	-- simone
	function ms1(wm2, wm7, wm15, wm16: w32) return w32;
	-- nicolas
	function cf1(a_h: block256; w, k: w32) return block256;

	-- pragma translate_off
	-- radwhane
	function ms(w: block512) return block2048;--the parameter should not be called 'm'?
	-- robin
	impure function cf(a_h: block256; w: block2048; debug: boolean := false) return block256;
	-- tiago (don't care about debug parameter, michele will do it)
	impure function sha256(m: std_ulogic_vector; debug: boolean := false) return block256;
	impure function sha256_padded(pm: block512_vector; debug: boolean := false) return block256;
	-- martin
	function pad(m: std_ulogic_vector) return block512_vector;
	-- kjell
	impure function check(debug: boolean := false) return boolean;

	procedure HWRITE(L:inout LINE; VALUE:in w32_vector;
	                        JUSTIFIED:in SIDE := RIGHT; FIELD:in WIDTH := 0);
	-- pragma translate_on
end package sha256_pkg;

package body sha256_pkg is
	-- pragma translate_off
	procedure HWRITE(L:inout LINE; VALUE:in w32_vector;
	                        JUSTIFIED:in SIDE := RIGHT; FIELD:in WIDTH := 0) is
	begin
		for i in VALUE'range loop
			hwrite(L, std_ulogic_vector(VALUE(i)), JUSTIFIED, FIELD);
			write(L, string'(" "));
		end loop;
	end procedure hwrite;

	-- pragma translate_on
	function sigma0(x: w32) return w32 is
	begin
		-- modified to rotate and shift functions instead of ror, srl, etc.
		-- because they are safer.
		return rotate_right(x, 7) xor rotate_right(x, 18) xor shift_right(x, 3);
	end sigma0;

	function sigma1(x: w32) return w32 is
	begin
		return rotate_right(x, 17) xor rotate_right(x, 19) xor shift_right(x, 10);
	end sigma1;

	function sum0(x: w32) return w32 is
	begin
		return rotate_right(x, 2) xor rotate_right(x, 13) xor rotate_right(x, 22);
	end sum0;

	function sum1(x: w32) return w32 is
	begin
		return rotate_right(x, 6) xor rotate_right(x, 11) xor rotate_right(x, 25);
	end sum1;

	function Ch(x, y, z: w32) return w32 is
	begin
		return (x and y) xor ((not x) and z);
	end Ch;

	function Maj(x, y, z: w32) return w32 is
	begin
		return (x and y) xor (x and z) xor (y and z);
	end Maj;

	function ms1(wm2, wm7, wm15, wm16: w32) return w32 is
	begin
		return sigma1(wm2) + wm7 + sigma0(wm15) + wm16;
	end ms1;

	function cf1(a_h: block256; w, k: w32) return block256 is
		variable t1, t2: w32; 
		variable a_h_new: block256;
	begin
		t1 := a_h(7) + sum1(a_h(4)) + Ch(a_h(4), a_h(5), a_h(6)) + k + w;
		t2 := sum0(a_h(0)) + Maj(a_h(0), a_h(1), a_h(2));

		a_h_new(0) := t1 + t2;
		a_h_new(1) := a_h(0);
		a_h_new(2) := a_h(1);
		a_h_new(3) := a_h(2);
		a_h_new(4) := a_h(3) + t1;
		a_h_new(5) := a_h(4);
		a_h_new(6) := a_h(5);
		a_h_new(7) := a_h(6);
		return a_h_new;
	end function cf1;
	-- pragma translate_off

	function ms(w: block512) return block2048 is
		variable w_tmp : block2048; -- local W
	begin
		w_tmp(w'range) := w(w'range);
		for j in 16 to 63 loop
			w_tmp(j) := ms1(w_tmp(j - 2), w_tmp(j - 7), w_tmp(j - 15), w_tmp(j - 16)); --for j=16..63  w(j)= ms1(w(j-2), w(j-7), w(j-15), w(j-16))
		end loop;
		return w_tmp;
	end ms;

	impure function cf(a_h: block256; w: block2048; debug: boolean := false) return block256 is
		variable a_h_temp : block256 := a_h; -- local a_h
		variable l: line;
	begin
		if debug then
			write(l, string'("          a        b        c        d        e        f        g        h"));
			writeline(output, l);
			write(l, string'("init:  "));
			hwrite(l, a_h);
			writeline(output, l);
		end if;
		for j in w'range loop
			a_h_temp := cf1(a_h_temp, w(j), k(j));
			if debug then
				write(l, string'("t = "));
				write(l, j, RIGHT, 2);
				write(l, string'(" "));
				hwrite(l, a_h_temp);
				writeline(output, l);
			end if;
		end loop; -- j
		return a_h_temp;
	end function cf;

	function pad_0_len(m : std_ulogic_vector) return integer is
	begin
		return  (-m'length - 1 - 64) mod 512;
	end function pad_0_len;

	function pad_len(m : std_ulogic_vector) return integer is
	begin
		return m'length + 1 + pad_0_len(m) + 64;
	end function pad_len;

	impure function sha256(m: std_ulogic_vector; debug: boolean := false) return block256 is
		variable H: block256;          -- stores the hash value
		variable l: line;
	begin
		-- computed the padded message from the input
		H := sha256_padded(pad(m));
		if debug then
			write(l, string'("SHA-256(M="));
			hwrite(l, m);
			write(l, string'(")="));
			hwrite(l, H);
			writeline(output, l);
		end if;
		return H;
	end function sha256;

	impure function sha256_padded(pm: block512_vector; debug: boolean := false) return block256 is
		variable a_h: block256;        -- registers a to h
		variable H, Hn_1: block256;          -- stores the hash value
		variable w: block2048;         -- message schedule
		variable l: line;
	begin
		-- load H0 to the hash value, for the first loop
		H := H0;
		-- loops for every block of the message
		for i in pm'range loop
			-- compute the message schedule used in the compression function
			w := ms(pm(i));
			-- initialize registers a to h with the (i-1)th intermediate hash value
			a_h := H;
			-- apply the compression function
			a_h := cf(a_h, w, debug);
			-- compute new intermediate hash value
			if debug and i=pm'length-1 then
				Hn_1 := H;    -- save the n-1th hash
			end if;
			for j in H'range loop
				H(j) := a_h(j) + H(j);
			end loop;
		end loop;
		if debug then
			write(l, string'("Block 1 has been processed. The values of {Hi} are"));
			writeline(output, l);
			for i in H'range loop
				write(l, string'("H"));
				write(l, i+1);
				write(l, string'(" = "));
				hwrite(l, std_ulogic_vector(a_h(i)));
				write(l, string'(" + "));
				hwrite(l, std_ulogic_vector(Hn_1(i)));
				write(l, string'(" = "));
				hwrite(l, std_ulogic_vector(H(i)));
				writeline(output, l);
			end loop;
		end if;
		return H; -- voila

	end function sha256_padded;

	function to_block512(d : std_ulogic_vector(0 to 511)) return block512 is
		variable res : block512;
	begin
		for i in res'range loop
			res(i) := w32(d(i * 32 to (i*32)+31));
		end loop;
		return res;
	end function to_block512;

	function pad(m: std_ulogic_vector) return block512_vector is
		-- amount of zero bits required to get the padded message length to a multiple of 512
		constant zero_padding: integer := pad_0_len(m);

		-- padded length = original length of the message
		--               + 1 "1" bit
		--               + missing bits to fill the padded vector length to a multiple of 512
		--               + 64 bits for the message length
		constant padded_length: integer := pad_len(m);

		-- the entire padded message
		variable padded: std_ulogic_vector(0 to padded_length - 1);

		-- the padded message split up into junks of 32 bits
		variable res: block512_vector(0 to padded_length / 512 - 1); 
	begin
		-- make sure we didn't mess up the padding calculation
		assert (padded'length mod 512 = 0) report "padded message does not have length multiple of 512" severity error;
		assert (padded'length >= m'length + 64 + 1) report "padded message is not long enough" severity error;
		assert (padded'length < m'length + 64 + 1 + 512) report "padded message is too long" severity error;

		-- all parts of the padded message put together
		-- (instead of creating the zero padding ourself and then appending 64 bits representing the length,
		-- we just tell the lenght part at the end to be of the combined length and thereby automatically create a enough zeros)
		padded := m & '1' & std_ulogic_vector(to_unsigned(m'length, zero_padding + 64));

		-- split the padded message into junks of 32 bits
		for i in res'range loop
			res(i) := to_block512(padded(i * 512 to (i * 512) + 511));
		end loop;
		return res;
	end function pad;

	impure function check(debug: boolean := false) return boolean is
			variable t : tv;
			variable d_out : block256;
			variable result : boolean;
			variable s : line;
	begin
		result := true;
		for i in testvectors'range loop
			t := testvectors(i);
			d_out := sha256(t.m(0 to t.l - 1), debug);
			if (t.s /= d_out) then
				write(s, string'("test suited failed at in="));
				hwrite(s, t.m(0 to t.l - 1));
				write(s, string'(" len="));
				write(s, t.l);
				write(s, string'(" out="));
				hwrite(s, d_out);
				write(s, string'(" expected="));
				hwrite(s, t.s);
				writeline(output, s);
				result := false;
			end if;
		end loop;
		return result;
	end function check;
	-- pragma translate_on
end package body sha256_pkg;
