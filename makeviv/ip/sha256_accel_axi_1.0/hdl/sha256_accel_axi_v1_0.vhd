library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library sha256_lib;
use sha256_lib.sha256_pkg.all;

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
	attribute X_CORE_INFO : string;
	attribute X_CORE_INFO of arch_imp: architecture is "sha256_accel_axi_v1_0,Vivado 2014.1";
	attribute CHECK_LICENSE_TYPE : string;
	attribute CHECK_LICENSE_TYPE of arch_imp : architecture is "zynq_design_sha256_accel_axi_0_0,sha256_accel_axi_v1_0,{}";
	attribute X_INTERFACE_INFO : string;
	attribute X_INTERFACE_INFO of sha256_accel_axi_awaddr: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWADDR";
	attribute X_INTERFACE_INFO of sha256_accel_axi_awprot: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWPROT";
	attribute X_INTERFACE_INFO of sha256_accel_axi_awvalid: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWVALID";
	attribute X_INTERFACE_INFO of sha256_accel_axi_awready: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWREADY";
	attribute X_INTERFACE_INFO of sha256_accel_axi_wdata: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WDATA";
	attribute X_INTERFACE_INFO of sha256_accel_axi_wstrb: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WSTRB";
	attribute X_INTERFACE_INFO of sha256_accel_axi_wvalid: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WVALID";
	attribute X_INTERFACE_INFO of sha256_accel_axi_wready: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WREADY";
	attribute X_INTERFACE_INFO of sha256_accel_axi_bresp: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI BRESP";
	attribute X_INTERFACE_INFO of sha256_accel_axi_bvalid: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI BVALID";
	attribute X_INTERFACE_INFO of sha256_accel_axi_bready: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI BREADY";
	attribute X_INTERFACE_INFO of sha256_accel_axi_araddr: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARADDR";
	attribute X_INTERFACE_INFO of sha256_accel_axi_arprot: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARPROT";
	attribute X_INTERFACE_INFO of sha256_accel_axi_arvalid: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARVALID";
	attribute X_INTERFACE_INFO of sha256_accel_axi_arready: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARREADY";
	attribute X_INTERFACE_INFO of sha256_accel_axi_rdata: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RDATA";
	attribute X_INTERFACE_INFO of sha256_accel_axi_rresp: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RRESP";
	attribute X_INTERFACE_INFO of sha256_accel_axi_rvalid: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RVALID";
	attribute X_INTERFACE_INFO of sha256_accel_axi_rready: signal is "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RREADY";
	attribute X_INTERFACE_INFO of sha256_accel_axi_aclk: signal is "xilinx.com:signal:clock:1.0 SHA256_ACCEL_AXI_CLK CLK";
	attribute X_INTERFACE_INFO of sha256_accel_axi_aresetn: signal is "xilinx.com:signal:reset:1.0 SHA256_ACCEL_AXI_RST RST";

	constant REG_STATE_IN: integer := 0;
	constant REG_PREFIX: integer := 8;
	constant REG_DIFFICULTY_MASK: integer := 11;
	constant REG_NONCE_CANDIDATE: integer := 19;
	constant REG_NONCE_CURRENT: integer := 20;
	constant REG_NONCE_FIRST: integer := 21;
	constant REG_NONCE_LAST: integer := 22;
	constant REG_STATUS: integer := 23;
	constant REG_CONTROL: integer := 24;
	constant REG_IRQ_MASK: integer := 25;
	constant REG_STEP: integer := 26;
	constant REG_DEBUG: integer := 27;

	-- AXI4LITE signals
	signal axi_awaddr: unsigned(9 downto 0);
	signal axi_awready: std_logic;
	signal axi_wready: std_logic;
	signal axi_bresp: std_logic_vector(1 downto 0);
	signal axi_bvalid: std_logic;
	signal axi_araddr: unsigned(9 downto 0);
	signal axi_arready: std_logic;
	signal axi_rdata: std_logic_vector(31 downto 0);
	signal axi_rresp: std_logic_vector(1 downto 0);
	signal axi_rvalid: std_logic;

	signal slv_reg_rden: std_logic;
	signal slv_reg_wren: std_logic;
	signal reg_data_out: std_logic_vector(31 downto 0);

	-- sha256 registers
	signal sha256_accel_state_in: std_logic_vector(255 downto 0);
	signal sha256_accel_prefix: std_logic_vector(95 downto 0);
	signal sha256_accel_difficulty_mask: std_logic_vector(255 downto 0);
	signal sha256_accel_nonce_candidate: w32;
	signal sha256_accel_nonce_current: w32;
	signal sha256_accel_nonce_first: w32;
	signal sha256_accel_nonce_last: w32;
	signal sha256_accel_status: std_logic_vector(31 downto 0);
	signal sha256_accel_control: std_logic_vector(31 downto 0);
	signal sha256_accel_irq_mask: std_logic;

	signal internal_clk: std_ulogic;
	signal internal_state_in: std_ulogic_vector(255 downto 0);
	signal internal_prefix: std_ulogic_vector(95 downto 0);
	signal internal_difficulty_mask: std_ulogic_vector(255 downto 0);
	signal internal_nonce_candidate: w32;
	signal internal_nonce_current: w32;
	signal internal_nonce_first: w32;
	signal internal_nonce_last: w32;
	signal internal_status: std_ulogic_vector(31 downto 0);
	signal internal_control: std_ulogic_vector(31 downto 0);

	signal internal_irq: std_ulogic;
	signal external_irq: std_logic;
	signal internal_dbg: w32_vector(0 to 24);

--	signal internal_step: std_ulogic;
	constant internal_step: std_ulogic := '1';
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
		variable loc_addr, reg_addr, data_bit : natural;
	begin
		if rising_edge(sha256_accel_axi_aclk) then
			sha256_accel_irq_mask <= '0';
			sha256_accel_control <= (others => '0');
--			internal_step <= sha256_accel_control(8);

			if sha256_accel_axi_aresetn = '0' then
				sha256_accel_state_in <= (others => '0');
				sha256_accel_prefix <= (others => '0');
				sha256_accel_difficulty_mask <= (others => '0');
				sha256_accel_nonce_first <= (others => '0');
				sha256_accel_nonce_last <= (others => '1');
			else
				loc_addr := to_integer(axi_awaddr(9 downto 2));
				if (slv_reg_wren = '1') then
					case loc_addr is
					when REG_STATE_IN to REG_STATE_IN + 7 =>
						reg_addr := loc_addr - REG_STATE_IN;
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								data_bit := reg_addr * 32 + byte_index * 8;
								sha256_accel_state_in(255 - data_bit downto 255 - 7 - data_bit) <= sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
							end if;
						end loop;
					when REG_PREFIX to REG_PREFIX + 2 =>
						reg_addr := loc_addr - REG_PREFIX;
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								data_bit := reg_addr * 32 + byte_index * 8;
								sha256_accel_prefix(95 - data_bit downto 95 - 7 - data_bit) <= sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
							end if;
						end loop;
					when REG_DIFFICULTY_MASK to REG_DIFFICULTY_MASK + 7 =>
						reg_addr := loc_addr - REG_DIFFICULTY_MASK;
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								data_bit := reg_addr * 32 + byte_index * 8;
								sha256_accel_difficulty_mask(255 - data_bit downto 255 - 7 - data_bit) <= sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
							end if;
						end loop;
					when REG_NONCE_CANDIDATE =>
						-- sha256_accel_nonce_candidate is read only
					when REG_NONCE_CURRENT =>
						-- sha256_accel_nonce_current is read only
					when REG_STATUS =>
						-- sha256_accel_status is read only
					when REG_CONTROL =>
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								sha256_accel_control(byte_index * 8 + 7 downto byte_index * 8) <= sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8);
							end if;
						end loop;
					when REG_NONCE_FIRST =>
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								sha256_accel_nonce_first(byte_index * 8 + 7 downto byte_index * 8) <= unsigned(sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8));
							end if;
						end loop;
					when REG_NONCE_LAST =>
						for byte_index in 0 to 3 loop
							if (sha256_accel_axi_wstrb(byte_index) = '1') then
								sha256_accel_nonce_last(byte_index * 8 + 7 downto byte_index * 8) <= unsigned(sha256_accel_axi_wdata(byte_index * 8 + 7 downto byte_index * 8));
							end if;
						end loop;
					when REG_IRQ_MASK =>
						if (sha256_accel_axi_wstrb(0) = '1') then
							sha256_accel_irq_mask <= sha256_accel_axi_wdata(0);
						end if;
					when REG_STEP =>
--						if (sha256_accel_axi_wstrb(0) = '1') then
--							internal_step <= sha256_accel_axi_wdata(0);
--						end if;
					when REG_DEBUG =>
						-- debug is read only
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
		variable loc_addr, reg_addr, data_bit : natural;
	begin
		if sha256_accel_axi_aresetn = '0' then
			reg_data_out <= (others => '1');
		else
			reg_data_out <= (others => '0');
			-- Address decoding for reading registers
			loc_addr := to_integer(axi_araddr(9 downto 2));
			case loc_addr is
			when REG_STATE_IN to REG_STATE_IN + 7 =>
				reg_addr := loc_addr - REG_STATE_IN;
				for byte_index in 0 to 3 loop
					data_bit := reg_addr * 32 + byte_index * 8;
					reg_data_out(byte_index * 8 + 7 downto byte_index * 8) <= sha256_accel_state_in(255 - data_bit downto 255 - 7 - data_bit);
				end loop;
			when REG_PREFIX to REG_PREFIX + 2 =>
				reg_addr := loc_addr - REG_PREFIX;
				for byte_index in 0 to 3 loop
					data_bit := reg_addr * 32 + byte_index * 8;
					reg_data_out(byte_index * 8 + 7 downto byte_index * 8) <= sha256_accel_prefix(95 - data_bit downto 95 - 7 - data_bit);
				end loop;
			when REG_DIFFICULTY_MASK to REG_DIFFICULTY_MASK + 7 =>
				reg_addr := loc_addr - REG_DIFFICULTY_MASK;
				for byte_index in 0 to 3 loop
					data_bit := reg_addr * 32 + byte_index * 8;
					reg_data_out(byte_index * 8 + 7 downto byte_index * 8) <= sha256_accel_difficulty_mask(255 - data_bit downto 255 - 7 - data_bit);
				end loop;
			when REG_NONCE_CANDIDATE =>
				reg_data_out <= std_logic_vector(sha256_accel_nonce_candidate);
			when REG_NONCE_CURRENT =>
				reg_data_out <= std_logic_vector(sha256_accel_nonce_current);
			when REG_STATUS =>
				reg_data_out <= sha256_accel_status;
			when REG_CONTROL =>
				-- sha256_accel_control is write only
			when REG_NONCE_FIRST =>
				reg_data_out <= std_logic_vector(sha256_accel_nonce_first);
			when REG_NONCE_LAST =>
				reg_data_out <= std_logic_vector(sha256_accel_nonce_last);
			when REG_IRQ_MASK =>
				-- sha256_accel_irq_mask is write only
			when REG_STEP =>
				-- internal_step is write only
			when REG_DEBUG to REG_DEBUG + 24 =>
				reg_addr := loc_addr - REG_DEBUG;
				reg_data_out <= std_logic_vector(internal_dbg(reg_addr));
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
					-- acceptance of read address by the slave (axi_arready), output the read data
					axi_rdata <= reg_data_out;
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

	internal_clk <= sha256_accel_axi_aclk;
	internal_state_in <= to_stdulogicvector(sha256_accel_state_in);
	internal_prefix <= to_stdulogicvector(sha256_accel_prefix);
	internal_difficulty_mask <= to_stdulogicvector(sha256_accel_difficulty_mask);
	internal_control <= to_stdulogicvector(sha256_accel_control);
	sha256_accel_nonce_candidate <= internal_nonce_candidate;
	sha256_accel_nonce_current <= internal_nonce_current;
	internal_nonce_first <= sha256_accel_nonce_first;
	internal_nonce_last <= sha256_accel_nonce_last;
	sha256_accel_status <= to_stdlogicvector(internal_status);
	sha256_accel_irq <= external_irq;

	inst: entity work.org(arc)
	generic map (
		1
	)
	port map (
		internal_clk,
		internal_state_in,
		internal_prefix,
		internal_difficulty_mask,
		internal_control,
		internal_nonce_first,
		internal_nonce_last,
		internal_nonce_candidate,
		internal_nonce_current,
		internal_status,
		internal_irq,
		internal_dbg,
		internal_step
	);

end architecture;
