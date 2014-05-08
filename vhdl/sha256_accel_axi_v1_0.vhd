library ieee;
use ieee.std_logic_1164.all;

entity sha256_accel_axi_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface SHA256_ACCEL_AXI
		C_SHA256_ACCEL_AXI_DATA_WIDTH : integer := 32;
		C_SHA256_ACCEL_AXI_ADDR_WIDTH : integer := 4
	);
	port (
		-- Users to add ports here

		sha256_accel_irq : out std_logic;

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Slave Bus Interface SHA256_ACCEL_AXI
		sha256_accel_axi_aclk : in std_logic;
		sha256_accel_axi_aresetn : in std_logic;
		sha256_accel_axi_awaddr : in std_logic_vector(C_SHA256_ACCEL_AXI_ADDR_WIDTH - 1 downto 0);
		sha256_accel_axi_awprot : in std_logic_vector(2 downto 0);
		sha256_accel_axi_awvalid : in std_logic;
		sha256_accel_axi_awready : out std_logic;
		sha256_accel_axi_wdata : in std_logic_vector(C_SHA256_ACCEL_AXI_DATA_WIDTH - 1 downto 0);
		sha256_accel_axi_wstrb : in std_logic_vector((C_SHA256_ACCEL_AXI_DATA_WIDTH / 8) - 1 downto 0);
		sha256_accel_axi_wvalid : in std_logic;
		sha256_accel_axi_wready : out std_logic;
		sha256_accel_axi_bresp : out std_logic_vector(1 downto 0);
		sha256_accel_axi_bvalid : out std_logic;
		sha256_accel_axi_bready : in std_logic;
		sha256_accel_axi_araddr : in std_logic_vector(C_SHA256_ACCEL_AXI_ADDR_WIDTH - 1 downto 0);
		sha256_accel_axi_arprot : in std_logic_vector(2 downto 0);
		sha256_accel_axi_arvalid : in std_logic;
		sha256_accel_axi_arready : out std_logic;
		sha256_accel_axi_rdata : out std_logic_vector(C_SHA256_ACCEL_AXI_DATA_WIDTH - 1 downto 0);
		sha256_accel_axi_rresp : out std_logic_vector(1 downto 0);
		sha256_accel_axi_rvalid : out std_logic;
		sha256_accel_axi_rready : in std_logic
	);
end entity;

architecture arch_imp of sha256_accel_axi_v1_0 is
	-- component declaration
	component sha256_accel_axi_v1_0_SHA256_ACCEL_AXI is
		generic (
			C_S_AXI_DATA_WIDTH : integer := 32;
			C_S_AXI_ADDR_WIDTH : integer := 4
		);
		port (
			irq : out std_logic;

			S_AXI_ACLK : in std_logic;
			S_AXI_ARESETN : in std_logic;
			S_AXI_AWADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
			S_AXI_AWPROT : in std_logic_vector(2 downto 0);
			S_AXI_AWVALID : in std_logic;
			S_AXI_AWREADY : out std_logic;
			S_AXI_WDATA : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
			S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH / 8) - 1 downto 0);
			S_AXI_WVALID : in std_logic;
			S_AXI_WREADY : out std_logic;
			S_AXI_BRESP : out std_logic_vector(1 downto 0);
			S_AXI_BVALID : out std_logic;
			S_AXI_BREADY : in std_logic;
			S_AXI_ARADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
			S_AXI_ARPROT : in std_logic_vector(2 downto 0);
			S_AXI_ARVALID : in std_logic;
			S_AXI_ARREADY : out std_logic;
			S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
			S_AXI_RRESP : out std_logic_vector(1 downto 0);
			S_AXI_RVALID : out std_logic;
			S_AXI_RREADY : in std_logic
		);
	end component;
begin

-- Instantiation of Axi Bus Interface SHA256_ACCEL_AXI
sha256_accel_axi_v1_0_SHA256_ACCEL_AXI_inst : sha256_accel_axi_v1_0_SHA256_ACCEL_AXI
	generic map (
		C_S_AXI_DATA_WIDTH => C_SHA256_ACCEL_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH => C_SHA256_ACCEL_AXI_ADDR_WIDTH
	)
	port map (
		irq => sha256_accel_irq,

		S_AXI_ACLK => sha256_accel_axi_aclk,
		S_AXI_ARESETN => sha256_accel_axi_aresetn,
		S_AXI_AWADDR => sha256_accel_axi_awaddr,
		S_AXI_AWPROT => sha256_accel_axi_awprot,
		S_AXI_AWVALID => sha256_accel_axi_awvalid,
		S_AXI_AWREADY => sha256_accel_axi_awready,
		S_AXI_WDATA => sha256_accel_axi_wdata,
		S_AXI_WSTRB => sha256_accel_axi_wstrb,
		S_AXI_WVALID => sha256_accel_axi_wvalid,
		S_AXI_WREADY => sha256_accel_axi_wready,
		S_AXI_BRESP => sha256_accel_axi_bresp,
		S_AXI_BVALID => sha256_accel_axi_bvalid,
		S_AXI_BREADY => sha256_accel_axi_bready,
		S_AXI_ARADDR => sha256_accel_axi_araddr,
		S_AXI_ARPROT => sha256_accel_axi_arprot,
		S_AXI_ARVALID => sha256_accel_axi_arvalid,
		S_AXI_ARREADY => sha256_accel_axi_arready,
		S_AXI_RDATA => sha256_accel_axi_rdata,
		S_AXI_RRESP => sha256_accel_axi_rresp,
		S_AXI_RVALID => sha256_accel_axi_rvalid,
		S_AXI_RREADY => sha256_accel_axi_rready
	);

	-- Add user logic here

	-- User logic ends

end architecture;
