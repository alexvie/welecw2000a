------------------------------------------------------------------------------
--  LEON3 Demonstration design
--  Copyright (C) 2004 Jiri Gaisler, Gaisler Research
--  Copyright (C) 2009 Alexander Lindert
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
------------------------------------------------------------------------------
--  modified by Thomas Ameseder, Gleichmann Electronics 2004, 2005 to
--  support the use of an external AHB slave and different HPE board versions
------------------------------------------------------------------------------
--  further adapted from Hpe_compact to Hpe_mini (Feb. 2005)
--  further adapted for the Open Source W2000A Scope (Feb. 2009)
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.memctrl.all;
use gaisler.leon3.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.net.all;
use gaisler.ata.all;
use gaisler.jtag.all;
library esa;
use esa.memoryctrl.all;
--library gleichmann;
--use gleichmann.hpi.all;
--use gleichmann.dac.all;
library DSO;
use DSO.pDSOConfig.all;
use DSO.Global.all;
--use DSO.pshram.all;
--use DSO.pVGA.all;
use DSO.pSFR.all;
use DSO.pSpecialFunctionRegister.all;
use DSO.pTrigger.all;
use DSO.pSignalAccess.all;
--use DSO.pSRamPriorityAccess.all;
use DSO.pLedsKeysAnalogSettings.all;
use work.config.all;


entity leon3mini is
  generic (
    fabtech : integer := CFG_FABTECH;
    memtech : integer := CFG_MEMTECH;
    padtech : integer := CFG_PADTECH;
    clktech : integer := CFG_CLKTECH;
    disas   : integer := CFG_DISAS;	-- Enable disassembly to console
    dbguart : integer := CFG_DUART;	-- Print UART on console
    pclow   : integer := CFG_PCLOW;
    freq    : integer := 25000	     -- frequency of main clock (used for PLLs)
    );
  port (
    --RS232
    iRXD : in  std_ulogic;		--RS232 
    oTXD : out std_ulogic;

    --USB
    iUSBRX : in	 std_ulogic;		-- Receive from USB
    oUSBTX : out std_ulogic;		-- Transmit to USB

    --SWITCH on board
    iSW1 : in std_ulogic;		--switch 1
    iSW2 : in std_ulogic;		--switch 2 (reset)

    --FLASH
    oA_FLASH  : out   std_ulogic_vector (cFLASHAddrWidth-1 downto 0);
    bD_FLASH  : inout std_logic_vector (7 downto 0);
    iRB_FLASH : in    std_ulogic;
    oOE_FLASH : out   std_ulogic;
    oCE_FLASH : out   std_ulogic;
    oWE_FLASH : out   std_ulogic;
    --RESET_FLASH :out std_ulogic; connected to SW2
    --ACC_FLASH :out std_ulogic;

    --SRAM
    oA_SRAM   : out   std_ulogic_vector (cSRAMAddrWidth-1 downto 0);
    bD_SRAM   : inout std_logic_vector (31 downto 0);  --inout
    oCE_SRAM  : out   std_ulogic;
    oWE_SRAM  : out   std_ulogic;
    oOE_SRAM  : out   std_ulogic;
    oUB1_SRAM : out   std_ulogic;
    oUB2_SRAM : out   std_ulogic;
    oLB1_SRAM : out   std_ulogic;
    oLB2_SRAM : out   std_ulogic;

    -- framebuffer VGA
    oDCLK      : out std_ulogic;
    oHD	       : out std_ulogic;
    oVD	       : out std_ulogic;
    oDENA      : out std_ulogic;
    oRed       : out std_ulogic_vector(5 downto 3);
    oGreen     : out std_ulogic_vector(5 downto 3);
    oBlue      : out std_ulogic_vector(5 downto 3);
    --FRONT PANEL
    oFPSW_PE   : out std_ulogic;
    iFPSW_DOUT : in  std_ulogic;
    oFPSW_CLK  : out std_ulogic;
    iFPSW_F2   : in  std_ulogic;
    iFPSW_F1   : in  std_ulogic;
    oFPLED_OE  : out std_ulogic;
    oFPLED_WR  : out std_ulogic;
    oFPLED_DIN : out std_ulogic;
    oFPLED_CLK : out std_ulogic;

    --FPGA2
    iFPGA2_C7	: in std_ulogic;
    iFPGA2_H11	: in std_ulogic;
    iFPGA2_AB10 : in std_ulogic;
    iFPGA2_U10	: in std_ulogic;
    iFPGA2_W9	: in std_ulogic;
    iFPGA2_T7	: in std_ulogic;

    --CONTROL of inputs
    iUx6	: in  std_ulogic;  -- not soldering register channels 1,2  3,4
    iUx11	: in  std_ulogic;	-- not soldering register channels 1,2
    iAAQpin5	: in  std_ulogic;	-- ? does not fit to analog_inputs.png
    oCalibrator : out std_ulogic;

    -- NormalTrigger-ea.vhd,... they all can trigger with 1 Gs!
    oPWMout  : out std_ulogic;		--Level Of External Syncro
    iSinhcro : in  std_ulogic;		--Comparator external syncro.
    oDesh    : out std_ulogic_vector(2 downto 0);  --demux. write strob for 4094
    oDeshENA : out std_ulogic;
    oRegCLK  : out std_ulogic;
    oRegData : out std_ulogic;

    --ADC
    oADC1CLK : out std_ulogic;
    oADC2CLK : out std_ulogic;
    oADC3CLK : out std_ulogic;
    oADC4CLK : out std_ulogic;
    iCh1ADC1 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);
    iCh1ADC2 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);
    iCh1ADC3 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);
    iCh1ADC4 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);
    iCh2ADC1 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);
    iCh2ADC2 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);
    iCh2ADC3 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);
    iCh2ADC4 : in  std_ulogic_vector (cADCBitWidth-1 downto 0);

-- pragma translate_off
    errorn	: out std_ulogic;
    resoutn	: out std_ulogic;
    oResetAsync : out std_ulogic;
-- pragma translate_on

    --CLK
--    iResetAsync : in	std_ulogic;	  -- Where is the async reset input pin ?
    iclk25_2  : in  std_ulogic;
    iclk25_7  : in  std_ulogic;
    iclk25_10 : in  std_ulogic;
    iclk25_15 : in  std_ulogic;
    iclk13inp : in  std_ulogic;		--wire W12-U15
    oclk13out : out std_ulogic;		--W12-U15
    iclk12_5  : in  std_ulogic
    );
end;

architecture rtl of leon3mini is
  signal ux_valid   : std_ulogic;
  signal ResetAsync : std_ulogic;
  signal ClkDesign  : std_ulogic;
  signal ClkCPU	    : std_ulogic;
  signal ClkADC25   : std_ulogic_vector(0 to cADCsperChannel-1);
  signal ClkADC250  : std_ulogic_vector(0 to cADCsperChannel-1);
  signal ClkLocked  : std_ulogic;

  signal ADCIn		   : aADCIn;
  signal TriggerMemtoCPU   : aTriggerMemOut;
  signal CPUtoTriggerMem   : aTriggerMemIn;
  signal SFRControltoCPU   : aSFR_in;
  signal SFRControlfromCPU : aSFR_out;

  --signal LedsfromCPU	  : aLeds;
  signal LedstoPanel	: aShiftOut;
  -- signal KeystoCPU	   : aKeys;
  signal KeysFromPanel	: aShiftIn;
  signal AnalogSettings : aAnalogSettingsOut;
  signal SyncPWM	: std_ulogic;
  signal SerialClk	: std_ulogic;
  -- internal ROM
  signal BootRomRd	: std_ulogic;
  signal BootACK	: std_ulogic;
  signal BootCS		: std_ulogic;
  signal BootOE		: std_ulogic;
  signal PWM_Offset	: aByte;
--  signal RamtoVGA	  : aSharedRamReturn;
--  signal VGAtoRam	  : aSharedRamAccess;
  -- signal CPUIn	   : aSharedRamAccess;
  -- signal CPUOut	   : aSharedRamReturn;

  signal VGA_PWM : unsigned(0 downto 0);
  signal Dena	 : std_ulogic;

  signal memi : memory_in_type;
  signal memo : memory_out_type;

  signal apbi  : apb_slv_in_type;
  signal apbo  : apb_slv_out_vector := (others => apb_none);
  signal ahbsi : ahb_slv_in_type;
  signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
  signal ahbmi : ahb_mst_in_type;
  signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);

  signal clkm, rstn, sdclkl : std_ulogic;
  signal cgi		    : clkgen_in_type;
  signal cgo		    : clkgen_out_type;
  signal u1i, dui	    : uart_in_type;
  signal u1o, duo	    : uart_out_type;

  signal irqi : irq_in_vector(0 to CFG_NCPU-1);
  signal irqo : irq_out_vector(0 to CFG_NCPU-1);

  signal dbgi : l3_debug_in_vector(0 to CFG_NCPU-1);
  signal dbgo : l3_debug_out_vector(0 to CFG_NCPU-1);

  signal dsui : dsu_in_type;
  signal dsuo : dsu_out_type;


  signal gpti : gptimer_in_type;

--  signal errorn	  : std_ulogic;
  signal dsuact : std_logic;
  signal dsuen	: std_ulogic;
--  signal oen_ctrl	  : std_logic;
--  signal sdram_selected : std_logic;

--  signal shortcut : std_logic;
  signal rx : std_logic;
  signal tx : std_logic;

  signal UartSel  : std_ulogic;
  signal rxd1sync : std_ulogic_vector(0 to 1);
  signal rxd1	  : std_logic;
  signal txd1	  : std_logic;
  signal dsutx	  : std_ulogic;		-- DSU tx data
  signal dsurx	  : std_ulogic;		-- DSU rx data
  signal dsubre	  : std_ulogic;

  signal ram_address : std_ulogic_vector(31 downto 0);
  signal rom_address : std_ulogic_vector(31 downto 0);
  signal D_SRAM	     : std_logic_vector(31 downto 0);
  signal D_ROM	     : std_logic_vector(31 downto 0);

  signal vgao	   : apbvga_out_type;
  signal video_clk : std_logic;
  signal clk_sel   : std_logic_vector(1 downto 0);

  constant BOARD_FREQ : integer := freq;  -- input frequency in KHz
  constant CPU_FREQ   : integer := BOARD_FREQ * CFG_CLKMUL / CFG_CLKDIV;  -- cpu frequency in KHz
  
begin

---------------------------------------------------------------------------------------
-- DSO: Scope Components without direct AHB or APB access
---------------------------------------------------------------------------------------
  -- oA_FLASH  <= (others => '1');
--  bD_FLASH  <= (others => '1');
  --   iRB_FLASH : in	 std_ulogic;
  oOE_FLASH <= '1';
  oCE_FLASH <= '1';
  oWE_FLASH <= '1';

  -- oTXD    <= txd1;
  -- rxd1    <= iRXD;
  -- dsurx   <= iUSBRX;			   -- Receive from USB
  -- oUSBTX  <= dsutx;			   -- Transmit to USB

--  oTXD  <= dsutx;
--  dsurx <= iRXD;
--  rxd1  <= iSinhcro;

  UARTSELECT : process (ClkCPU, ResetAsync)
  begin
    if ResetAsync = cResetActive then
      oTXD     <= '1';
      dsurx    <= '1';
      rxd1     <= '1';
      UartSel  <= '0';
      rxd1sync <= (others => '1');
    elsif rising_edge(ClkCPU) then
      rxd1sync(0) <= iRXD;
      rxd1sync(1) <= rxd1sync(0);
      oTXD	  <= '1';
      dsurx	  <= '1';
      rxd1	  <= '1';
      if SFRControlFromCPU.nConfigADC(0) = '1' then
	rxd1 <= rxd1sync(1);
	oTXD <= txd1;
      else
	dsurx <= rxd1sync(1);
	oTXD  <= dsutx;
      end if;
    end if;
  end process;

  dsubre      <= '0';
  -- dsuactn <= not dsuact;
  dsuen	      <= '1';
  -- pragma translate_off
  resoutn     <= rstn;
  oResetAsync <= ResetAsync;
  -- pragma translate_on
  ClkADC25(0) <= iclk25_2;
  ClkADC25(1) <= iclk25_7;
  ClkADC25(2) <= iclk25_10;
  ClkADC25(3) <= iclk25_15;
  oADC1CLK    <= ClkADC250(0);
  oADC2CLK    <= ClkADC250(1);
  oADC3CLK    <= ClkADC250(2);
  oADC4CLK    <= ClkADC250(3);
  
  ADCIn <= (				-- only for W2012A and W2022A 
    0	=> (
      0 => iCh1ADC1,
      1 => iCh2ADC1),
    1	=> (
      0 => iCh1ADC2,
      1 => iCh2ADC2),
    2	=> (
      0 => iCh1ADC3,
      1 => iCh2ADC3),
    3	=> (
      0 => iCh1ADC4,
      1 => iCh2ADC4));

--  PLL0 : entity DSO.PLL0
--    port map (
--	pllena => '1',
--	inclk0 => ClkADC25(0),
--	c0     => ClkADC250(0),
--	locked => open);

--  PLL1 : entity DSO.PLL1
--    port map (
--	inclk0 => ClkADC25(1),
--	pllena => '1',
--	c0     => ClkADC250(1),
--	locked => open);

--  PLL2 : entity DSO.PLL2
--    port map (
--	inclk0 => ClkADC25(2),
--	pllena => '1',
--	c0     => ClkADC250(2),
--	locked => open);

--  PLL3 : entity DSO.PLL3
--    port map (
--	inclk0 => ClkADC25(3),
--	pllena => '1',
--	c0     => ClkADC250(3),
--	   c1	  => ClkDesign,
--	c2     => ClkCPU,
--	locked => ResetAsync);

  CaptureSignals : entity DSO.SignalCapture
    port map (
      oClkDesign	=> ClkDesign,
      oClkCPU		=> ClkCPU,
      --    iResetAsync		 => iResetAsync,
      iClkADC		=> ClkADC25,
      oClkADC		=> ClkADC250,
      oResetAsync	=> ResetAsync,
      iADC		=> ADCIn,
      iDownSampler	=> SFRControlfromCPU.Decimator,
      iSignalSelector	=> SFRControlfromCPU.SignalSelector,
      iTriggerCPUPort	=> SFRControlfromCPU.Trigger,
      oTriggerCPUPort	=> SFRControltoCPU.Trigger,
      iTriggerMem	=> CPUtoTriggerMem,
      oTriggerMem	=> TriggerMemtoCPU,
      iExtTriggerSrc	=> SFRControlfromCPU.ExtTriggerSrc,
      iExtTrigger	=> iSinhcro,
      oExtTriggerPWM(1) => oPWMout);

  FrontPanel : entity DSO.LedsKeysAnalogSettings
    port map (
      iClk		=> ClkCPU,
      iResetAsync	=> ResetAsync,
      iLeds		=> SFRControlfromCPU.Leds,
      oLeds		=> LedstoPanel,
      iKeysData		=> iFPSW_DOUT,
      onFetchKeys	=> KeysfromPanel,
      oKeys		=> SFRControltoCPU.Keys,
      iEnableProbeClock => SFRControlfromCPU.AnalogSettings.EnableProbeClock,
      oSerialClk	=> SerialClk);

  oFPSW_PE    <= KeysFromPanel.nFetchStrobe;
  oFPSW_CLK   <= KeysFromPanel.SerialClk;
  --  iFPSW_F2	 : in  std_ulogic;
  --  iFPSW_F1	 : in  std_ulogic;
  oFPLED_OE   <= LedstoPanel.nOutputEnable;
  oFPLED_WR   <= LedstoPanel.ValidStrobe;
  oFPLED_DIN  <= LedstoPanel.Data;
  oFPLED_CLK  <= LedstoPanel.SerialClk;
  oCalibrator <= SerialClk;		-- 1 KHz Clk

  oDesh	   <= SFRControlfromCPU.AnalogSettings.Addr;  --demux. write strob for 4094
  oDeshENA <= SFRControlfromCPU.AnalogSettings.Enable;
  oRegCLK  <= SFRControlfromCPU.AnalogSettings.SerialClk;
  oRegData <= SFRControlfromCPU.AnalogSettings.Data;


--  pPWM : entity DSO.PWM
--    generic map (
--	gBitWidth => aByte'length)
--    port map (
--	iClk	  => ClkCPU,
--	iResetAsync => ResetAsync,
--	iRefON	  => SFRControlfromCPU.AnalogSettings.PWM_Offset,
--	iRefOff	  => (others => '0'),
--	oPWM	  => oPWMout);


  -- pragma translate_off

  BootRomRd <= BootCS or BootOE;
  Bootloader : entity work.BootRom
    generic map (
      pipe => 1)
    port map(
      rstn  => rstn,
      clk   => clkm,
      ren   => BootRomRd,
      iaddr => std_logic_vector(rom_address(31 downto 2)),
      odata => D_ROM,
      oACK  => BootACK);

  process (rom_address(1 downto 0), D_ROM)
  begin
    case rom_address(1 downto 0) is
      when "11"	  => bD_FLASH <= D_ROM(31 downto 24);
      when "10"	  => bD_FLASH <= D_ROM(23 downto 16);
      when "01"	  => bD_FLASH <= D_ROM(15 downto 8);
      when others => bD_FLASH <= D_ROM(7 downto 0);
    end case;
  end process;

--  BootRomRd <= memo.romsn(0) or memo.oen;
--  Bootloader : entity work.BootRom
--    generic map (
--	pipe => 1)
--    port map(
--	rstn  => rstn,
--	clk   => clkm,
--	ren   => BootRomRd,
--	iaddr => memo.address(31 downto 2),
--	odata => memi.data,
--	oACK  => BootACK);

  -- pragma translate_on


----------------------------------------------------------------------
---  Reset and Clock generation	 -------------------------------------
----------------------------------------------------------------------

--  vcc		<= (others => '1'); gnd <= (others => '0');
--  cgi.pllctrl <= "00"; cgi.pllrst <= not resetn; cgi.pllref <= clk;  --'0'; --pllref;
  cgi.pllctrl <= "00"; cgi.pllrst <= not ResetAsync; cgi.pllref <= ClkCPU;  --'0'; --pllref;
--  clkgen0 : clkgen			  -- clock generator using toplevel generic 'freq'
--    generic map (tech	   => CFG_CLKTECH, clk_mul => CFG_CLKMUL,
--		   clk_div => CFG_CLKDIV, sdramen => CFG_MCTRL_SDEN,
--		   noclkfb => CFG_CLK_NOFB, freq => freq)
--    port map (clkin => clk, pciclkin => gnd(0), clk => clkm, clkn => open,
--		clk2x => open, sdclk => sdclkl, pciclk => open,
--		cgi   => cgi, cgo => cgo);

  rst0 : rstgen				-- reset generator
    --	port map (resetn, clkm, cgo.clklock, rstn);
    port map (ResetAsync, clkm, cgo.clklock, rstn);
  clkm <= ClkCPU;
--  sdclkl <= clk;
  -- rstn	<= resetn;
  cgo  <= (others => '1') after 1 ns,
	  (others => '1') after 100 ns;
---------------------------------------------------------------------- 
---  AHB CONTROLLER --------------------------------------------------
----------------------------------------------------------------------

  ahb0 : ahbctrl			-- AHB arbiter/multiplexer
    generic map (defmast => CFG_DEFMST, split => CFG_SPLIT,
		 rrobin	 => CFG_RROBIN, ioaddr => CFG_AHBIO,
		 nahbm	 => 3, nahbs => 4)
    port map (rstn, clkm, ahbmi, ahbmo, ahbsi, ahbso);

----------------------------------------------------------------------
---  LEON3 processor and DSU -----------------------------------------
----------------------------------------------------------------------

  l3 : if CFG_LEON3 = 1 generate
    cpu : for i in 0 to CFG_NCPU-1 generate
      u0 : leon3s			-- LEON3 processor
	generic map (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8,
		     0, CFG_MAC, pclow, 0, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE,
		     CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
		     CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
		     CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP,
		     CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR,
		     CFG_NCPU-1)
	port map (clkm, rstn, ahbmi, ahbmo(i), ahbsi, ahbso,
		  irqi(i), irqo(i), dbgi(i), dbgo(i));
    end generate;
    -- pragma translate_off
    errorn_pad : odpad generic map (tech => padtech) port map (errorn, dbgo(0).error);
    -- pragma translate_on

    dsugen : if CFG_DSU = 1 generate
      dsu0 : dsu3			-- LEON3 Debug Support Unit
	generic map (hindex => 2, haddr => 16#900#, hmask => 16#F00#,
		     ncpu   => CFG_NCPU, tbits => 30, tech => memtech, irq => 0, kbytes => CFG_ATBSZ)
	port map (rstn, clkm, ahbmi, ahbsi, ahbso(2), dbgo, dbgi, dsui, dsuo);
      dsuen_pad	 : inpad generic map (tech  => padtech) port map (dsuen, dsui.enable);
      --	**** tame: do not use inversion
      dsubre_pad : inpad generic map (tech  => padtech) port map (dsubre, dsui.break);
      dsuact_pad : outpad generic map (tech => padtech) port map (dsuact, dsuo.active);
    end generate;
  end generate;
  nodcom : if CFG_DSU = 0 generate ahbso(2) <= ahbs_none; end generate;

  dcomgen : if CFG_AHB_UART = 1 generate
    dcom0 : ahbuart			-- Debug UART
      generic map (hindex => CFG_NCPU, pindex => 4, paddr => 7)
      port map (rstn, clkm, dui, duo, apbi, apbo(4), ahbmi, ahbmo(CFG_NCPU));
    dsurx_pad : inpad generic map (tech	 => padtech) port map (dsurx, dui.rxd);
    dsutx_pad : outpad generic map (tech => padtech) port map (dsutx, duo.txd);
  end generate;
  nouah : if CFG_AHB_UART = 0 generate apbo(4) <= apb_none; end generate;

----------------------------------------------------------------------
---  Memory controllers ----------------------------------------------
----------------------------------------------------------------------

--  mg2 : if CFG_SRCTRL = 1 generate
--    srctrl0 : srctrl
--	generic map  -- (rmw => 1, prom8en => 0, srbanks => 1, banksz => 9)
--	(hindex	 => 0,
--	 romaddr => 0,
--	 rommask => 16#ff8#,
--	 ramaddr => 16#400#,
--	 rammask => 16#ffe#,
--	 ioaddr	 => 16#200#,
--	 iomask	 => 16#ffe#,
--	 ramws	 => CFG_SRCTRL_RAMWS,
--	 romws	 => CFG_SRCTRL_PROMWS,
--	 iows	 => CFG_SRCTRL_IOWS,
--	 rmw	 => CFG_SRCTRL_RMW,	-- read-modify-write enable
--	 prom8en => CFG_SRCTRL_8BIT,
--	 oepol	 => 0,
--	 srbanks => CFG_SRCTRL_SRBANKS,
--	 banksz	 => CFG_SRCTRL_BANKSZ,
--	 romasel => CFG_SRCTRL_ROMASEL)
--	port map (rstn, clkm, ahbsi, ahbso(0), memi, memo, open);
--  end generate;

--  bD_SRAM <= memo.data after 1 ns when
--	     (memo.writen = '0' and memo.ramsn(0) = '0')
--	     else (others => 'Z');
--  memi.data <= bD_SRAM after 1 ns;

--  oA_SRAM   <= std_ulogic_vector(memo.address(oA_SRAM'length+1 downto 2));
--  oA_FLASH  <= std_ulogic_vector(memo.address(oA_FLASH'length-1 downto 0));
--  -- oCE_SRAM	 <= memo.ramsn(0) and memo.iosn;
--  oOE_SRAM  <= memo.ramoen(0);
--  oWE_SRAM  <= memo.writen;
--  --	oLB1_SRAM <= memo.wrn(0);
--  --	oUB1_SRAM <= memo.wrn(1);
--  --	oLB2_SRAM <= memo.wrn(2);
--  --	oUB2_SRAM <= memo.wrn(3);
--  oCE_SRAM  <= cLowActive;
--  oLB1_SRAM <= cLowActive;
--  oUB1_SRAM <= cLowActive;
--  oLB2_SRAM <= cLowActive;
--  oUB2_SRAM <= cLowActive;

--  memi.brdyn	<= '1'; memi.bexcn <= '1';
--  memi.writen <= '1'; memi.wrn <= "1111"; memi.bwidth <= "10";


  oA_SRAM   <= ram_address(oA_SRAM'length+1 downto 2);
  oLB1_SRAM <= cLowActive;
  oUB1_SRAM <= cLowActive;
  oLB2_SRAM <= cLowActive;
  oUB2_SRAM <= cLowActive;

  mg2 : entity DSO.FastSRAMctrl
    generic map (
      hindex  => 0,
      romaddr => 0,
      rommask => 16#ff0#,
      ramaddr => 16#400#,
      rammask => 16#ff0#,
      ioaddr  => 16#200#,		-- uncached ram mirror
      iomask  => 16#ff0#,
      romws   => 2)
    port map (
      inResetAsync => rstn,
      iClk	   => clkm,
      ahbsi	   => ahbsi,
      ahbso	   => ahbso(0),

      -- oAddr	  => address,
      oRAMAddr => ram_address,
      oROMAddr => rom_address,
      bDataRAM => bD_SRAM,
      --  bDataROM => D_ROM,
      oncsRAM  => oCE_SRAM,
      onoeRAM  => oOE_SRAM,
      onwrRAM  => oWE_SRAM,
      onbeRAM  => open,
      -- onbeRAM(0) =>oLB1_SRAM,
      -- onbeRAM(1) =>oUB1_SRAM,
      -- onbeRAM(2) =>oLB2_SRAM,
      -- onbeRAM(3) =>oUB2_SRAM,
      bDataROM => bD_FLASH,
      oncsROM  => BootCS,
      onoeROM  => BootOE,
      onwrROM  => open);

  ---------------------------------------------------------------------------------------
  -- DSO: AHB devices
  ---------------------------------------------------------------------------------------

  genDSO : if CFG_DSO_ENABLE /= 0 generate
    TriggerMem : SignalAccess
      generic map (
	hindex => 3,
	haddr  => 16#A00#,
	hmask  => 16#FFF#,
	kbytes => 32
	)
      port map (
	rst_in	    => rstn,
	clk_i	    => clkm,
	ahbsi	    => ahbsi,
	ahbso	    => ahbso(3),
	iClkDesign  => ClkDesign,
	iResetAsync => ResetAsync,
	iTriggerMem => TriggerMemtoCPU,
	oTriggerMem => CPUtoTriggerMem
	);
  end generate;

----------------------------------------------------------------------
---  APB Bridge and various periherals -------------------------------
----------------------------------------------------------------------

  apb0 : apbctrl			-- AHB/APB bridge
    generic map (hindex => 1, haddr => CFG_APBADDR)
    port map (rstn, clkm, ahbsi, ahbso(1), apbi, apbo);

  ua1 : if CFG_UART1_ENABLE /= 0 generate
    uart1 : apbuart			-- UART 1
      generic map (pindex   => 1, paddr => 1, pirq => 2, console => dbguart,
		   fifosize => CFG_UART1_FIFO)
      port map (rstn, clkm, apbi, apbo(1), u1i, u1o);
    u1i.rxd <= rxd1; u1i.ctsn <= '0'; u1i.extclk <= '0'; txd1 <= u1o.txd;

    process (apbi)
    begin
      if apbi.psel(1) = '1' and apbi.penable = '1' and apbi.pwrite = '1'
	and apbi.paddr(3 downto 2) = "00" then
	ux_valid <= '1';
      else
	ux_valid <= '0';
      end if;
    end process;
  end generate;
  noua0 : if CFG_UART1_ENABLE = 0 generate apbo(1) <= apb_none; end generate;

  irqctrl : if CFG_IRQ3_ENABLE /= 0 generate
    irqctrl0 : irqmp			-- interrupt controller
      generic map (pindex => 2, paddr => 2, ncpu => CFG_NCPU)
      port map (rstn, clkm, apbi, apbo(2), irqo, irqi);
  end generate;
  irq3 : if CFG_IRQ3_ENABLE = 0 generate
    x : for i in 0 to CFG_NCPU-1 generate
      irqi(i).irl <= "0000";
    end generate;
    apbo(2) <= apb_none;
  end generate;

  gpt : if CFG_GPT_ENABLE /= 0 generate
    timer0 : gptimer			-- timer unit
      generic map (pindex => 3, paddr => 3, pirq => CFG_GPT_IRQ,
		   sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW, ntimers => CFG_GPT_NTIM,
		   nbits  => CFG_GPT_TW)
      port map (rstn, clkm, apbi, apbo(3), gpti, open);
    gpti.dhalt <= dsuo.active; gpti.extclk <= '0';
  end generate;
  notim : if CFG_GPT_ENABLE = 0 generate apbo(3) <= apb_none; end generate;

-----------------------------------------------------------------------
--- DSO: SFR ----------------------------------------------------------
-----------------------------------------------------------------------
  genSFRDSO : if CFG_DSO_ENABLE /= 0 generate
    SFR0 : SFR
      generic map(pindex => 5,
		  paddr	 => 5,
		  pmask	 => 16#FFF#,
		  pirq	 => 5)
      port map(rst_in	    => rstn,
	       iResetAsync  => ResetAsync,
	       clk_i	    => clkm,
	       clk_design_i => ClkDesign,
	       apb_i	    => apbi,
	       apb_o	    => apbo(5),
	       iSFRControl  => SFRControltoCPU,
	       oSFRControl  => SFRControlfromCPU);
  end generate;

  vga : if CFG_VGA_ENABLE /= 0 generate
    vga0 : apbvga generic map(memtech => memtech, pindex => 5, paddr => 6)
					--    port map(rstn, clkm, clk, apbi, apbo(5), vgao);
      port map(rstn, clkm, ClkDesign, apbi, apbo(5), vgao);
  end generate;


--  oDENA  <= vgao.blank;
--  oRed   <= std_ulogic_vector(vgao.video_out_r(7 downto 5));
--  oGreen <= std_ulogic_vector(vgao.video_out_g(7 downto 5));
--  oBlue  <= std_ulogic_vector(vgao.video_out_b(7 downto 5));
--  oVD	   <= vgao.vsync;
--  oHD	   <= vgao.hsync;
  oDCLK <= not video_clk;

  oVD	<= vgao.vsync;
  oHD	<= vgao.hsync;
					-- oDCLK <= video_clk;
  oDENA <= Dena;

  process (video_clk, ResetAsync)
  begin
    if ResetAsync = cResetActive then
      oRed    <= (others => '0');
      oGreen  <= (others => '0');
      oBlue   <= (others => '0');
      Dena    <= '0';
      VGA_PWM <= (others => '0');
    elsif rising_edge(video_clk) then
      if Dena = '1' or vgao.vsync = '0' then
	VGA_PWM <= VGA_PWM + 1;
      end if;
      oRed(5)	<= vgao.video_out_r(7);
      oGreen(5) <= vgao.video_out_g(7);
      oBlue(5)	<= vgao.video_out_b(7);
      oRed(3)	<= vgao.video_out_r(6);
      oGreen(3) <= vgao.video_out_g(6);
      oBlue(3)	<= vgao.video_out_b(6);
      oRed(4)	<= (vgao.video_out_r(5) and VGA_PWM(0));
      oGreen(4) <= (vgao.video_out_g(5) and VGA_PWM(0));
      oBlue(4)	<= (vgao.video_out_b(5) and VGA_PWM(0));
      Dena	<= vgao.blank;
    end if;
  end process;

  svga : if CFG_SVGA_ENABLE /= 0 generate
    svga0 : entity DSO.DoubleBufferVGA
      generic map(memtech => memtech, pindex => 6, paddr => 6,
		  hindex  => CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG,
		  clk0	  => 40000, clk1 => 1000000000/((BOARD_FREQ * CFG_CLKMUL)/CFG_CLKDIV),
		  clk2	  => 20000, clk3 => 15385, burstlen => 6)

--    svga0 : svgactrl generic map(memtech => memtech, pindex => 6, paddr => 6,
--				   hindex  => CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG,
--				   clk0	   => 40000, clk1 => 1000000000/((BOARD_FREQ * CFG_CLKMUL)/CFG_CLKDIV),
--				   clk2	   => 20000, clk3 => 15385, burstlen => 6)

      port map(rstn, clkm, video_clk, apbi, apbo(6), vgao, ahbmi,
	       ahbmo(CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG), clk_sel);
					--   video_clk <= clk when clk_sel = "00"      else clkm;
    video_clk <= iclk25_2;		-- when clk_sel = "00" else ClkCPU;
  end generate;

  novga : if CFG_VGA_ENABLE+CFG_SVGA_ENABLE = 0 generate
    apbo(6) <= apb_none; vgao <= vgao_none;
  end generate;

-----------------------------------------------------------------------
---  Drive unused bus elements	---------------------------------------
-----------------------------------------------------------------------

  nam1 : for i in (CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+CFG_SVGA_ENABLE+CFG_GRETH) to NAHBMST-1 generate
    ahbmo(i) <= ahbm_none;
  end generate;
  nap0 : for i in 7 to NAPBSLV-1-CFG_GRETH generate apbo(i) <= apb_none; end generate;
  nah0 : for i in 8 to NAHBSLV-1 generate ahbso(i)	    <= ahbs_none; end generate;

-----------------------------------------------------------------------
---  Boot message  ----------------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off
  x : report_version
    generic map (
      msg1 => "Open Source Digital Storage Oscilloscope FPGA-Design by Alexander Lindert",
      msg2 => "GRLIB Version " & tost(LIBVHDL_VERSION/1000) & "." & tost((LIBVHDL_VERSION mod 1000)/100)
      & "." & tost(LIBVHDL_VERSION mod 100) & ", build " & tost(LIBVHDL_BUILD),
      --	msg3 => "Target technology: " & tech_table(fabtech) & ",	memory library: " & tech_table(memtech),
      mdel => 1
      );
-- pragma translate_on

end rtl;
