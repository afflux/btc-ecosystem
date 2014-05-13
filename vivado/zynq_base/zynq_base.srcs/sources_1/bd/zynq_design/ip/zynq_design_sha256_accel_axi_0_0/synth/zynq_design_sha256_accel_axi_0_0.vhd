-- (c) Copyright 1995-2014 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: makess:user:sha256_accel_axi:1.43
-- IP Revision: 1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY global_lib;
USE global_lib.sha256_accel_axi_v1_0;

ENTITY zynq_design_sha256_accel_axi_0_0 IS
  PORT (
    sha256_accel_irq : OUT STD_LOGIC;
    sha256_accel_axi_awaddr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    sha256_accel_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    sha256_accel_axi_awvalid : IN STD_LOGIC;
    sha256_accel_axi_awready : OUT STD_LOGIC;
    sha256_accel_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    sha256_accel_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    sha256_accel_axi_wvalid : IN STD_LOGIC;
    sha256_accel_axi_wready : OUT STD_LOGIC;
    sha256_accel_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    sha256_accel_axi_bvalid : OUT STD_LOGIC;
    sha256_accel_axi_bready : IN STD_LOGIC;
    sha256_accel_axi_araddr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    sha256_accel_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    sha256_accel_axi_arvalid : IN STD_LOGIC;
    sha256_accel_axi_arready : OUT STD_LOGIC;
    sha256_accel_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    sha256_accel_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    sha256_accel_axi_rvalid : OUT STD_LOGIC;
    sha256_accel_axi_rready : IN STD_LOGIC;
    sha256_accel_axi_aclk : IN STD_LOGIC;
    sha256_accel_axi_aresetn : IN STD_LOGIC
  );
END zynq_design_sha256_accel_axi_0_0;

ARCHITECTURE zynq_design_sha256_accel_axi_0_0_arch OF zynq_design_sha256_accel_axi_0_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : string;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF zynq_design_sha256_accel_axi_0_0_arch: ARCHITECTURE IS "yes";

  COMPONENT sha256_accel_axi_v1_0 IS
    PORT (
      sha256_accel_irq : OUT STD_LOGIC;
      sha256_accel_axi_awaddr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      sha256_accel_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      sha256_accel_axi_awvalid : IN STD_LOGIC;
      sha256_accel_axi_awready : OUT STD_LOGIC;
      sha256_accel_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      sha256_accel_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      sha256_accel_axi_wvalid : IN STD_LOGIC;
      sha256_accel_axi_wready : OUT STD_LOGIC;
      sha256_accel_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      sha256_accel_axi_bvalid : OUT STD_LOGIC;
      sha256_accel_axi_bready : IN STD_LOGIC;
      sha256_accel_axi_araddr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      sha256_accel_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      sha256_accel_axi_arvalid : IN STD_LOGIC;
      sha256_accel_axi_arready : OUT STD_LOGIC;
      sha256_accel_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      sha256_accel_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      sha256_accel_axi_rvalid : OUT STD_LOGIC;
      sha256_accel_axi_rready : IN STD_LOGIC;
      sha256_accel_axi_aclk : IN STD_LOGIC;
      sha256_accel_axi_aresetn : IN STD_LOGIC
    );
  END COMPONENT sha256_accel_axi_v1_0;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF zynq_design_sha256_accel_axi_0_0_arch: ARCHITECTURE IS "sha256_accel_axi_v1_0,Vivado 2014.1";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF zynq_design_sha256_accel_axi_0_0_arch : ARCHITECTURE IS "zynq_design_sha256_accel_axi_0_0,sha256_accel_axi_v1_0,{}";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_awaddr: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWADDR";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_awprot: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWPROT";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_awvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWVALID";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_awready: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI AWREADY";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_wdata: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WDATA";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_wstrb: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WSTRB";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_wvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WVALID";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_wready: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI WREADY";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_bresp: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI BRESP";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_bvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI BVALID";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_bready: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI BREADY";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_araddr: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARADDR";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_arprot: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARPROT";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_arvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARVALID";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_arready: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI ARREADY";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_rdata: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RDATA";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_rresp: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RRESP";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_rvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RVALID";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_rready: SIGNAL IS "xilinx.com:interface:aximm:1.0 SHA256_ACCEL_AXI RREADY";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_aclk: SIGNAL IS "xilinx.com:signal:clock:1.0 SHA256_ACCEL_AXI_CLK CLK";
  ATTRIBUTE X_INTERFACE_INFO OF sha256_accel_axi_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 SHA256_ACCEL_AXI_RST RST";
BEGIN
  U0 : sha256_accel_axi_v1_0
    PORT MAP (
      sha256_accel_irq => sha256_accel_irq,
      sha256_accel_axi_awaddr => sha256_accel_axi_awaddr,
      sha256_accel_axi_awprot => sha256_accel_axi_awprot,
      sha256_accel_axi_awvalid => sha256_accel_axi_awvalid,
      sha256_accel_axi_awready => sha256_accel_axi_awready,
      sha256_accel_axi_wdata => sha256_accel_axi_wdata,
      sha256_accel_axi_wstrb => sha256_accel_axi_wstrb,
      sha256_accel_axi_wvalid => sha256_accel_axi_wvalid,
      sha256_accel_axi_wready => sha256_accel_axi_wready,
      sha256_accel_axi_bresp => sha256_accel_axi_bresp,
      sha256_accel_axi_bvalid => sha256_accel_axi_bvalid,
      sha256_accel_axi_bready => sha256_accel_axi_bready,
      sha256_accel_axi_araddr => sha256_accel_axi_araddr,
      sha256_accel_axi_arprot => sha256_accel_axi_arprot,
      sha256_accel_axi_arvalid => sha256_accel_axi_arvalid,
      sha256_accel_axi_arready => sha256_accel_axi_arready,
      sha256_accel_axi_rdata => sha256_accel_axi_rdata,
      sha256_accel_axi_rresp => sha256_accel_axi_rresp,
      sha256_accel_axi_rvalid => sha256_accel_axi_rvalid,
      sha256_accel_axi_rready => sha256_accel_axi_rready,
      sha256_accel_axi_aclk => sha256_accel_axi_aclk,
      sha256_accel_axi_aresetn => sha256_accel_axi_aresetn
    );
END zynq_design_sha256_accel_axi_0_0_arch;
