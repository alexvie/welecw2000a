-------------------------------------------------------------------------------
-- Project    : Welec W2000A
-------------------------------------------------------------------------------
-- File	      : FastSRAMctrl-ea.vhd
-- Author     : Alexander Lindert <alexander_lindert at gmx.at> 
-- Created    : 2010-02-07
-- Last update: 2011-05-01
-- Platform   : Welec W2000A
-------------------------------------------------------------------------------
-- Description: This is the fastest possible external rom and ram access for
-- the LEON3 based design!
-- It's made because of troubles with the SRAM and the memory demand of the
-- VGA controller on the W2000A plattform.
-- Because control pins like chip select and byte enable have to be all time
-- low, the read modify write mode is used!
-------------------------------------------------------------------------------
--  Copyright (c) 2010, Alexander Lindert
--
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
--
--  For commercial applications where source-code distribution is not
--  desirable or possible, I offer low-cost commercial IP licenses.
--  Please contact me per mail.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date	       Version	
-- 2010-02-07  1.0	
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
library gaisler;
use grlib.devices.all;


entity FastSRAMctrl is
  generic (
    hindex  : integer := 0;
    romaddr : integer := 0;
    rommask : integer := 16#ff0#;
    ramaddr : integer := 16#400#;
    rammask : integer := 16#ff0#;
    ioaddr  : integer := 16#200#;	-- uncached ram mirror
    iomask  : integer := 16#ff0#;
    romws   : integer := 2
    );
  port (
    inResetAsync : in  std_ulogic;
    iClk	 : in  std_ulogic;
    ahbsi	 : in  ahb_slv_in_type;
    ahbso	 : out ahb_slv_out_type;

    oRAMAddr : out std_ulogic_vector(31 downto 0);
    oROMAddr : out std_ulogic_vector(31 downto 0);

    bDataRAM		      : inout std_logic_vector(31 downto 0);
    oncsRAM, onoeRAM, onwrRAM : out   std_ulogic;
    onbeRAM		      : out   std_ulogic_vector(3 downto 0);

    bDataROM		      : inout std_logic_vector(7 downto 0);
    oncsROM, onoeROM, onwrROM : out   std_ulogic
    );
end entity;

architecture rtl of FastSRAMctrl is

  constant VERSION : amba_version_type := 0;
  constant hconfig : ahb_config_type := (
    0	   => ahb_device_reg(VENDOR_LINDERT, LINDERT_SRCTL, 0, VERSION, 0),
    4	   => ahb_membar(romaddr, '1', '1', rommask),
    5	   => ahb_membar(ramaddr, '1', '1', rammask),
    6	   => ahb_membar(ioaddr, '0', '0', iomask),
    others => zero32);

  type aRAMState is (idle, reading, writing, rmw0, rmw1, rmw2);
  type aROMState is (idle, wait_wr, rom_wr, rom_rd, wait_rd);

  type ap0 is record
    state  : aRAMState;
    oen	   : std_ulogic;
    wr	   : std_ulogic;
    addr   : std_ulogic_vector(31 downto 0);
    data   : std_logic_vector(31 downto 0);
    hready : std_ulogic;
    hcache : std_ulogic;
    size   : std_ulogic_vector(2 downto 0);
  end record;

  type arom is record
    state : aROMState;
    addr  : std_ulogic_vector(31 downto 0);
    data  : std_logic_vector(31 downto 0);
    byte  : unsigned(1 downto 0);
    ws	  : natural range 0 to 7;
    busy  : std_ulogic;
    --	 rd	  : std_ulogic;
    --	 wr	  : std_ulogic;
  end record;


  signal p0, p0i	   : ap0;
  signal rom, romi	   : arom;
  signal prev_oen, prev_wr : std_ulogic;
--  signal rmw	   : std_ulogic;


-- vectored output enable to data pads
--  signal rbdrive, ribdrive	    : std_logic_vector(31 downto 0);
--  attribute syn_preserve	    : boolean;
--  attribute syn_preserve of rbdrive : signal is true;

begin

  regs : process(iClk, inResetAsync)
  begin
    if inResetAsync = '0' then
      p0.wr	<= '1';
      p0.oen	<= '1';
      p0.hready <= '1';
      p0.hcache <= '1';
      rom.state <= Idle;
      rom.busy	<= '0';
      rom.byte	<= "00";
      prev_oen	<= '1';
      prev_wr	<= '1';
    elsif rising_edge(iClk) then
      rom      <= romi;
      p0       <= p0i;
      prev_oen <= p0.oen;
      prev_wr  <= p0.wr;
      
    end if;
  end process;

  onwrRAM <= p0.wr;
  onoeRAM <= p0.oen;
  oncsRAM <= '0';
  oncsROM <= '0';

  ctl : process (p0, prev_oen, rom, romi, bDataROM, bDataRAM, ahbsi)
  begin

    onwrROM <= '1';
    onoeROM <= '1';

    bDataRAM <= (others => 'Z');
    bDataROM <= (others => 'Z');
    oRAMAddr <= p0.addr;
    oROMAddr <= rom.addr;
    p0i	     <= p0;
    romi     <= rom;

    romi.ws   <= romws;
    romi.busy <= '1';

    p0i.hready <= '1';
    p0i.hcache <= not ahbsi.hmbsel(2);
    p0i.wr     <= '1';
    p0i.oen    <= '1';
    onbeRAM    <= "1111";

    --	rmw	       <= '1';

    ahbso.hready  <= p0.hready;
    ahbso.hresp	  <= "00";
    ahbso.hrdata  <= rom.data;
    ahbso.hconfig <= hconfig;
    ahbso.hcache  <= p0.hcache;		--not ahbsi.hmbsel(2);
    ahbso.hirq	  <= (others => '0');
    ahbso.hindex  <= hindex;
    ahbso.hsplit  <= (others => '0');



    if p0.oen = '0' then
      ahbso.hrdata <= bDataRAM;
      p0i.data	   <= bDataRAM;
    end if;

    if p0.wr = '0' then
      bDataRAM <= ahbsi.hwdata;
      case p0.size is
	when "000" =>
	  case p0.addr(1 downto 0) is
	    when "00" =>
	      onbeRAM(3) <= '0';
	      bDataRAM	 <= ahbsi.hwdata(31 downto 24) & p0.data(23 downto 0);
	    when "01" =>
	      onbeRAM(2) <= '0';
	      bDataRAM	 <= p0.data(31 downto 24) & ahbsi.hwdata(23 downto 16) & p0.data(15 downto 0);
	    when "10" =>
	      onbeRAM(1) <= '0';
	      bDataRAM	 <= p0.data(31 downto 16) & ahbsi.hwdata(15 downto 8) & p0.data(7 downto 0);
	    when "11" =>
	      onbeRAM(0) <= '0';
	      bDataRAM	 <= p0.data(31 downto 8) & ahbsi.hwdata(7 downto 0);
	    when others =>
	      null;
	  end case;
	when "001" =>
	  if p0.addr(1) = '0' then
	    onbeRAM(3 downto 2) <= "00";
	    bDataRAM <= ahbsi.hwdata(31 downto 16) & p0.data(15 downto 0);
	    else
	    onbeRAM(1 downto 0) <= "00";
	    bDataRAM <= p0.data(31 downto 16) & ahbsi.hwdata(15 downto 0);
	  end if;
	when others =>
	  onbeRAM(3 downto 0) <= "0000";
	  bDataRAM <= ahbsi.hwdata;
      end case;
    end if;

    if (ahbsi.hready and ahbsi.hsel(hindex) and ahbsi.htrans(1)) = '1' then

      case p0.state is
	when idle =>
	  if ahbsi.hmbsel(1) = '1' or ahbsi.hmbsel(2) = '1' then
	    if rom.busy = '1' then
	      p0i.hready <= '0';
	    else
	      
	      p0i.addr <= std_ulogic_vector(ahbsi.haddr);
	      p0i.size <= std_ulogic_vector(ahbsi.hsize);
	      if ahbsi.hwrite = '1' then
		if ahbsi.hsize(2 downto 1) = "00" then

		  	  p0i.hready <= '0';
		  	  p0i.state  <= rmw0;

		  	else
		  
		  p0i.hready <= '0';
		  p0i.state  <= writing;
		  
		end if;
	      else
		if prev_wr = '0' then
		  p0i.hready <= '0';
		  p0i.state  <= reading;
		else
		  p0i.oen   <= '0';
		  p0i.state <= idle;
		end if;
	      end if;
	    end if;
	    
	  elsif ahbsi.hmbsel(0) = '1' then
	    p0i.hready		   <= '0';
	    romi.addr(31 downto 2) <= std_ulogic_vector(ahbsi.haddr(31 downto 2));
	    if (p0.oen and p0.wr) = '1' then
	      if ahbsi.hwrite = '1' then
		romi.state <= wait_wr;
	      else
		romi.state <= rom_rd;
	      end if;
	    end if;
	  end if;
	when others =>
	  p0i.hready <= '0';
      end case;
    else
      p0i.State	 <= Idle;
      p0i.hready <= '1';
      case p0.State is
	when rmw0 =>
	  p0i.State  <= rmw1;
	  p0i.oen    <= '0';
	  p0i.hready <= '0';
	when rmw1 =>
	  p0i.State  <= rmw2;
	  p0i.hready <= '0';
	when rmw2 =>
	  p0i.wr <= '0';
	when reading =>
	  p0i.oen <= '0';
	when writing =>
	  p0i.wr <= '0';
	when others =>
	  null;
      end case;
    end if;

    romi.addr(1 downto 0) <= std_ulogic_vector(romi.byte);
    case rom.state is
      when idle =>
	romi.busy <= '0';
      when rom_rd =>
	p0i.hready   <= '0';
	romi.ws	     <= (rom.ws -1) mod 8;
	onoeROM	     <= '0';
	ahbso.hrdata <= rom.data;
	if rom.ws = 0 then
	  romi.ws   <= romws;
	  romi.byte <= (rom.byte +1) mod 4;
	  romi.data <= bDataROM & rom.data(31 downto 8);
	  if rom.byte = "11" then
	    romi.state <= idle;
	    p0i.hready <= '1';
	    romi.busy  <= '0';
	  end if;
	end if;
	
      when wait_wr =>
	romi.data  <= ahbsi.hwdata;
	romi.state <= rom_wr;

      when rom_wr =>
	romi.ws	   <= (rom.ws -1) mod 8;
	p0i.hready <= '0';
	bDataROM   <= rom.data(31 downto 24);
	if rom.ws = 0 then
	  romi.ws		 <= romws;
	  onwrROM		 <= '0';
	  romi.byte		 <= rom.byte +1;
	  romi.data(31 downto 8) <= rom.data(23 downto 0);
	  romi.data(7 downto 0)	 <= (others => '-');
	  if rom.byte = "11" then
	    p0i.hready <= '1';
	    romi.busy  <= '0';
	    romi.state <= idle;
	  else
	    romi.data(31 downto 8) <= rom.data(23 downto 0);
	  end if;
	end if;
      when wait_rd =>
	romi.state   <= Idle;
	ahbso.hrdata <= rom.data;
    end case;
  end process;

-- pragma translate_off
  bootmsg : report_version
    generic map ("FastSRAMctrl" & tost(hindex) &
		 ": 32-bit PROM/SRAM controller rev " & tost(VERSION));
-- pragma translate_on

end;

