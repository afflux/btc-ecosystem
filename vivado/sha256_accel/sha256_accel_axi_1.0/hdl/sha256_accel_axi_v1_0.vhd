library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

entity sha256_accel_axi_v1_0 is
	port (
		sha256_accel_irq : out std_logic;

		-- Ports of Axi Slave Bus Interface SHA256_ACCEL_AXI

		-- Global Clock Signal
		sha256_accel_axi_aclk : in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		sha256_accel_axi_aresetn : in std_logic;
		-- Write address (issued by master, acceped by Slave)
		sha256_accel_axi_awaddr : in std_logic_vector(9 downto 0);
		-- Write channel Protection type. This signal indicates the privilege and security level of the transaction, and whether
		-- the transaction is a data access or an instruction access.
		sha256_accel_axi_awprot : in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling valid write address and control information.
		sha256_accel_axi_awvalid : in std_logic;
		-- Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		sha256_accel_axi_awready : out std_logic;
		-- Write data (issued by master, acceped by Slave)
		sha256_accel_axi_wdata : in std_logic_vector(31 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight
		-- bits of the write data bus.
		sha256_accel_axi_wstrb : in std_logic_vector(3 downto 0);
		-- Write valid. This signal indicates that valid write data and strobes are available.
		sha256_accel_axi_wvalid : in std_logic;
		-- Write ready. This signal indicates that the slave can accept the write data.
		sha256_accel_axi_wready : out std_logic;
		-- Write response. This signal indicates the status of the write transaction.
		sha256_accel_axi_bresp : out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel is signaling a valid write response.
		sha256_accel_axi_bvalid : out std_logic;
		-- Response ready. This signal indicates that the master can accept a write response.
		sha256_accel_axi_bready : in std_logic;
		-- Read address (issued by master, acceped by Slave)
		sha256_accel_axi_araddr : in std_logic_vector(9 downto 0);
		-- Protection type. This signal indicates the privilege and security level of the transaction, and whether the
		-- transaction is a data access or an instruction access.
		sha256_accel_axi_arprot : in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel is signaling valid read address and control information.
		sha256_accel_axi_arvalid : in std_logic;
		-- Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		sha256_accel_axi_arready : out std_logic;
		-- Read data (issued by slave)
		sha256_accel_axi_rdata : out std_logic_vector(31 downto 0);
		-- Read response. This signal indicates the status of the read transfer.
		sha256_accel_axi_rresp : out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is signaling the required read data.
		sha256_accel_axi_rvalid : out std_logic;
		-- Read ready. This signal indicates that the master can accept the read data and response information.
		sha256_accel_axi_rready : in std_logic
	);
end entity;

architecture arch_imp of sha256_accel_axi_v1_0 is
	-- AXI4LITE signals
	signal axi_awaddr : unsigned(9 downto 0);
	signal axi_awready : std_logic;
	signal axi_wready : std_logic;
	signal axi_bresp : std_logic_vector(1 downto 0);
	signal axi_bvalid : std_logic;
	signal axi_araddr : unsigned(9 downto 0);
	signal axi_arready : std_logic;
	signal axi_rdata : std_logic_vector(31 downto 0);
	signal axi_rresp : std_logic_vector(1 downto 0);
	signal axi_rvalid : std_logic;

	signal slv_reg_rden : std_logic;
	signal slv_reg_wren : std_logic;
	signal reg_data_out : std_logic_vector(31 downto 0);

	-- sha256 registers
	signal sha256_accel_state_in : std_logic_vector(255 downto 0);
	signal sha256_accel_prefix : std_logic_vector(95 downto 0);
	signal sha256_accel_num_leading_zero : unsigned(7 downto 0);
	signal sha256_accel_nonce_candidate : unsigned(31 downto 0);
	signal sha256_accel_nonce_current : unsigned(31 downto 0);

	signal sha256_accel_status : std_logic_vector(31 downto 0);
	signal sha256_accel_control : std_logic_vector(31 downto 0);
	signal sha256_accel_irq_mask : std_logic;
	
	signal internal_state_in : std_ulogic_vector(255 downto 0);
    signal internal_prefix : std_ulogic_vector(95 downto 0);
    signal internal_num_leading_zero : unsigned(7 downto 0);
    signal internal_nonce_candidate : unsigned(31 downto 0);
    signal internal_nonce_current : unsigned(31 downto 0);

    signal internal_status : std_ulogic_vector(31 downto 0);
    signal internal_control : std_ulogic_vector(31 downto 0);
    signal internal_clk: std_ulogic;
	
	signal internal_irq: std_ulogic;
	signal external_irq: std_logic;
    signal internal_dbg1, internal_dbg2, internal_dbg3, internal_dbg4: std_ulogic_vector(31 downto 0);
    signal internal_step: std_ulogic;
begin
	-- I/O Connections assignments
	sha256_accel_axi_awready <= axi_awready;
	sha256_accel_axi_wready <= axi_wready;
	sha256_accel_axi_bresp <= axi_bresp;
	sha256_accel_axi_bvalid <= axi_bvalid;
	sha256_accel_axi_arready <= axi_arready;
	sha256_accel_axi_rdata <= axi_rdata;
	sha256_accel_axi_rresp <= axi_rresp;
	sha256_accel_axi_rvalid <= axi_rvalid;

	-- Implement axi_awready generation
	-- axi_awready is asserted for one sha256_accel_axi_aclk clock cycle when both
	-- sha256_accel_axi_awvalid and sha256_accel_axi_wvalid are asserted. axi_awready is de-asserted when reset is low.
	process (sha256_accel_axi_aclk)
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			if sha256_accel_axi_aresetn = '0' then
				axi_awready <= '0';
			else
				if (axi_awready = '0' and sha256_accel_axi_awvalid = '1' and sha256_accel_axi_wvalid = '1') then
					-- slave is ready to accept write address when
					-- there is a valid write address and write data
					-- on the write address and data bus. This design
					-- expects no outstanding transactions.
					axi_awready <= '1';
				else
					axi_awready <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both sha256_accel_axi_awvalid and sha256_accel_axi_wvalid are valid.
	process (sha256_accel_axi_aclk)
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			if sha256_accel_axi_aresetn = '0' then
				axi_awaddr <= (others => '0');
			else
				if (axi_awready = '0' and sha256_accel_axi_awvalid = '1' and sha256_accel_axi_wvalid = '1') then
					-- Write Address latching
					axi_awaddr <= unsigned(sha256_accel_axi_awaddr);
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_wready generation
	-- axi_wready is asserted for one sha256_accel_axi_aclk clock cycle when both
	-- sha256_accel_axi_awvalid and sha256_accel_axi_wvalid are asserted. axi_wready is de-asserted when reset is low.
	process (sha256_accel_axi_aclk)
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			if sha256_accel_axi_aresetn = '0' then
				axi_wready <= '0';
			else
				if (axi_wready = '0' and sha256_accel_axi_wvalid = '1' and sha256_accel_axi_awvalid = '1') then
					-- slave is ready to accept write data when
					-- there is a valid write address and write data
					-- on the write address and data bus. This design
					-- expects no outstanding transactions.
					axi_wready <= '1';
				else
					axi_wready <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, sha256_accel_axi_wvalid, axi_wready and sha256_accel_axi_wvalid are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and sha256_accel_axi_wvalid and axi_awready and sha256_accel_axi_awvalid;

	process (sha256_accel_axi_aclk)
		variable loc_addr : natural;
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			internal_step <= '0';

			sha256_accel_irq_mask <= '0';

			if sha256_accel_axi_aresetn = '0' then
				sha256_accel_state_in <= (others => '0');
				sha256_accel_prefix <= (others => '0');
				sha256_accel_num_leading_zero <= (others => '0');
				sha256_accel_control <= (others => '0');
			else
				loc_addr := to_integer(axi_awaddr(9 downto 2));
				if (slv_reg_wren = '1') then
					case loc_addr is
					when 0 to 7 =>
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								sha256_accel_state_in(loc_addr * 32 + byte_index * 8 + 7 downto loc_addr * 32 + byte_index * 8) <= sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
							end if;
						end loop;
					when 8 to 10 =>
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								sha256_accel_prefix((loc_addr - 8) * 32 + byte_index * 8 + 7 downto (loc_addr - 8) * 32 + byte_index * 8) <= sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
							end if;
						end loop;
					when 11 =>
						if (sha256_accel_axi_wstrb(0) = '1') then
							sha256_accel_num_leading_zero <= unsigned(sha256_accel_axi_wdata(7 downto 0));
						end if;
					when 12 =>
						-- sha256_accel_nonce_candidate is read only
					when 13 =>
						-- sha256_accel_nonce_current is read only
					when 14 =>
						-- sha256_accel_status is read only
					when 15 =>
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								sha256_accel_control(byte_index * 8 + 7 downto byte_index * 8) <= sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
							end if;
						end loop;
					when 16 =>
						if (sha256_accel_axi_wstrb(0) = '1') then
							sha256_accel_irq_mask <= sha256_accel_axi_wdata(0);
						end if;
                    when 19 =>
                        if (sha256_accel_axi_wstrb(0) = '1') then
                            internal_step <= sha256_accel_axi_wdata(0);
                        end if;
					when others =>
					end case;
				end if;
			end if;
		end if;
	end process;

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave
	-- when axi_wready, sha256_accel_axi_wvalid, axi_wready and sha256_accel_axi_wvalid are asserted.
	-- This marks the acceptance of address and indicates the status of
	-- write transaction.
	process (sha256_accel_axi_aclk)
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			if sha256_accel_axi_aresetn = '0' then
				axi_bvalid <= '0';
				axi_bresp <= "00"; --need to work more on the responses
			else
				if (axi_awready = '1' and sha256_accel_axi_awvalid = '1' and axi_wready = '1' and sha256_accel_axi_wvalid = '1' and axi_bvalid = '0') then
					axi_bvalid <= '1';
					axi_bresp <= "00";
				elsif (sha256_accel_axi_bready = '1' and axi_bvalid = '1') then --check if bready is asserted while bvalid is high)
					axi_bvalid <= '0'; -- (there is a possibility that bready is always asserted high)
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_arready generation
	-- axi_arready is asserted for one sha256_accel_axi_aclk clock cycle when
	-- sha256_accel_axi_arvalid is asserted. axi_awready is
	-- de-asserted when reset (active low) is asserted.
	-- The read address is also latched when sha256_accel_axi_arvalid is
	-- asserted. axi_araddr is reset to zero on reset assertion.
	process (sha256_accel_axi_aclk)
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			if sha256_accel_axi_aresetn = '0' then
				axi_arready <= '0';
				axi_araddr <= (others => '1');
			else
				if (axi_arready = '0' and sha256_accel_axi_arvalid = '1') then
					-- indicates that the slave has acceped the valid read address
					axi_arready <= '1';
					-- Read Address latching
					axi_araddr <= unsigned(sha256_accel_axi_araddr);
				else
					axi_arready <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one sha256_accel_axi_aclk clock cycle when both
	-- sha256_accel_axi_arvalid and axi_arready are asserted. The slave registers
	-- data are available on the axi_rdata bus at this instance. The
	-- assertion of axi_rvalid marks the validity of read data on the
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are
	-- cleared to zero on reset (active low).
	process (sha256_accel_axi_aclk)
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			if sha256_accel_axi_aresetn = '0' then
				axi_rvalid <= '0';
				axi_rresp <= "00";
			else
				if (axi_arready = '1' and sha256_accel_axi_arvalid = '1' and axi_rvalid = '0') then
					-- Valid read data is available at the read data bus
					axi_rvalid <= '1';
					axi_rresp <= "00"; -- 'OKAY' response
				elsif (axi_rvalid = '1' and sha256_accel_axi_RREADY = '1') then
					-- Read data is accepted by the master
					axi_rvalid <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and sha256_accel_axi_arvalid and (not axi_rvalid);

	process
		variable loc_addr : natural;
	begin
		if sha256_accel_axi_aresetn = '0' then
			reg_data_out <= (others => '1');
		else
			reg_data_out <= (others => '0');
			-- Address decoding for reading registers
			loc_addr := to_integer(axi_araddr(9 downto 2));
			case loc_addr is
			when 0 to 7 =>
				reg_data_out <= sha256_accel_state_in(loc_addr * 32 + 31 downto loc_addr * 32 );
			when 8 to 10 =>
			    reg_data_out <= sha256_accel_prefix((loc_addr - 8) * 32 + 31 downto (loc_addr - 8) * 32 );
			when 11 =>
			    reg_data_out <= (X"000000") & std_logic_vector(sha256_accel_num_leading_zero);
			when 12 =>
				reg_data_out <= std_logic_vector(sha256_accel_nonce_candidate);
			when 13 =>
				reg_data_out <= std_logic_vector(sha256_accel_nonce_current);
			when 14 =>
				reg_data_out <= sha256_accel_status;
			when 15 =>
				reg_data_out <= sha256_accel_control;
			when 16 =>
				reg_data_out <= (others=>sha256_accel_irq_mask);
            when 17 =>
                reg_data_out <= to_stdlogicvector(internal_dbg1);
            when 18 =>
                reg_data_out <= to_stdlogicvector(internal_dbg2);
            when 19 =>
                reg_data_out <= to_stdlogicvector(internal_dbg3);
            when 20 =>
                reg_data_out <= to_stdlogicvector(internal_dbg4);
            when 21 =>
                reg_data_out <= (others=>internal_step);
			when others =>
			end case;
		end if;
	end process;

	-- Output register or memory read data
	process (sha256_accel_axi_aclk)
	begin
		if (rising_edge(sha256_accel_axi_aclk)) then
			if (sha256_accel_axi_aresetn = '0') then
				axi_rdata <= (others => '0');
			else
				if (slv_reg_rden = '1') then
					-- When there is a valid read address (sha256_accel_axi_arvalid) with
					-- acceptance of read address by the slave (axi_arready),
					-- output the read dada
					-- Read address mux
					axi_rdata <= reg_data_out; -- register read data
				end if;
			end if;
		end if;
	end process;
	
	process (sha256_accel_axi_aclk)
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			if sha256_accel_axi_aresetn = '0' then
				external_irq <= '0';
			else
				if sha256_accel_irq_mask = '1' then
					external_irq <= '0';
				elsif internal_irq = '1' then
					external_irq <= '1';
				end if;
			end if;
		end if;
	end process;

	sha256_accel_irq <= external_irq;

	inst: entity work.org(arc) port map(
		internal_clk,
		internal_state_in,
		internal_prefix,
		internal_num_leading_zero,
		internal_control,
		internal_nonce_candidate,
		internal_nonce_current,
		internal_status,
		internal_irq,
		internal_dbg1,
		internal_dbg2,
		internal_dbg3,
		internal_dbg4,
		internal_step
	);

	internal_clk <= sha256_accel_axi_aclk;
	internal_state_in <= to_stdulogicvector(sha256_accel_state_in);
	internal_prefix <= to_stdulogicvector(sha256_accel_prefix);
	internal_num_leading_zero <= sha256_accel_num_leading_zero;
	internal_control <= to_stdulogicvector(sha256_accel_control);
	sha256_accel_nonce_candidate <= internal_nonce_candidate;
	sha256_accel_nonce_current <= internal_nonce_current;
	sha256_accel_status <= to_stdlogicvector(internal_status);

end architecture;
