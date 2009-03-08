
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
  generic (
    gAddrWidth : integer := 14);
  port (
    iClk  : in  std_ulogic;
    oData : out std_ulogic_vector(31 downto 0);
    iAddr : in  std_ulogic_vector(31 downto 0));
end entity;

architecture Rtl of ROM is
  subtype aDataVec is std_ulogic_vector(31 downto 0);
  type    aMem is array (2**gAddrWidth-1 downto 0) of aDataVec;

  constant mem : aMem := (
     0 => x"7f454c46",
     1 => x"01020100",
     2 => x"00000000",
     3 => x"00000000",
     4 => x"0002006a",
     5 => x"00000001",
     6 => x"00000000",
     7 => x"00000034",
     8 => x"00000124",
     9 => x"00000000",
    10 => x"00340020",
    11 => x"00020028",
    12 => x"00090008",
    13 => x"00000001",
    14 => x"00000074",
    15 => x"00000000",
    16 => x"00000000",
    17 => x"00000065",
    18 => x"00000065",
    19 => x"00000005",
    20 => x"00000001",
    21 => x"00000001",
    22 => x"000000d9",
    23 => x"00000068",
    24 => x"00000068",
    25 => x"00000008",
    26 => x"00000008",
    27 => x"00000006",
    28 => x"00000001",
    29 => x"0b0b0b0b",
    30 => x"80700b0b",
    31 => x"0b80ec0c",
    32 => x"3a0b0b0b",
    33 => x"80de0400",
    34 => x"00000000",
    35 => x"00000000",
    36 => x"00000000",
    37 => x"803d0d80",
    38 => x"51830b86",
    39 => x"8da00c70",
    40 => x"802e8838",
    41 => x"70812e8d",
    42 => x"38963981",
    43 => x"0b868da0",
    44 => x"0c8151eb",
    45 => x"3981c70b",
    46 => x"868da00c",
    47 => x"8251e039",
    48 => x"800b868d",
    49 => x"a00c8111",
    50 => x"51847125",
    51 => x"d238823d",
    52 => x"0d04c13f",
    53 => x"800b800c",
    54 => x"04000000",
    55 => x"00000000",
    56 => x"00002e73",
    57 => x"68737472",
    58 => x"74616200",
    59 => x"2e666978",
    60 => x"65645f76",
    61 => x"6563746f",
    62 => x"7273002e",
    63 => x"74657874",
    64 => x"002e6461",
    65 => x"7461002e",
    66 => x"63746f72",
    67 => x"73002e64",
    68 => x"746f7273",
    69 => x"002e6273",
    70 => x"73002e73",
    71 => x"7461636b",
    72 => x"00000000",
    73 => x"00000000",
    74 => x"00000000",
    75 => x"00000000",
    76 => x"00000000",
    77 => x"00000000",
    78 => x"00000000",
    79 => x"00000000",
    80 => x"00000000",
    81 => x"00000000",
    82 => x"00000000",
    83 => x"0000000b",
    84 => x"00000001",
    85 => x"00000002",
    86 => x"00000000",
    87 => x"00000074",
    88 => x"00000020",
    89 => x"00000000",
    90 => x"00000000",
    91 => x"00000020",
    92 => x"00000000",
    93 => x"0000001a",
    94 => x"00000001",
    95 => x"00000006",
    96 => x"00000020",
    97 => x"00000094",
    98 => x"00000045",
    99 => x"00000000",
   100 => x"00000000",
   101 => x"00000001",
   102 => x"00000000",
   103 => x"00000020",
   104 => x"00000001",
   105 => x"00000003",
   106 => x"00000068",
   107 => x"000000d9",
   108 => x"00000008",
   109 => x"00000000",
   110 => x"00000000",
   111 => x"00000001",
   112 => x"00000000",
   113 => x"00000026",
   114 => x"00000001",
   115 => x"00000001",
   116 => x"00000070",
   117 => x"000000e1",
   118 => x"00000000",
   119 => x"00000000",
   120 => x"00000000",
   121 => x"00000001",
   122 => x"00000000",
   123 => x"0000002d",
   124 => x"00000001",
   125 => x"00000001",
   126 => x"00000070",
   127 => x"000000e1",
   128 => x"00000000",
   129 => x"00000000",
   130 => x"00000000",
   131 => x"00000001",
   132 => x"00000000",
   133 => x"00000034",
   134 => x"00000008",
   135 => x"00000001",
   136 => x"00000070",
   137 => x"000000e1",
   138 => x"00000000",
   139 => x"00000000",
   140 => x"00000000",
   141 => x"00000001",
   142 => x"00000000",
   143 => x"00000039",
   144 => x"00000001",
   145 => x"00000001",
   146 => x"00ff0000",
   147 => x"000000e1",
   148 => x"00000000",
   149 => x"00000000",
   150 => x"00000000",
   151 => x"00000001",
   152 => x"00000000",
   153 => x"00000001",
   154 => x"00000003",
   155 => x"00000000",
   156 => x"00000000",
   157 => x"000000e1",
   158 => x"00000040",
   159 => x"00000000",
   160 => x"00000000",
   161 => x"00000001",
   162 => x"00000000",
others => (others => '-'));
begin  -- Rtl
  ROM : process (iClk)
 -- variable i : unsigned(2**gAddrWidth-1 downto 0);
 -- variable j : natural;
  begin  
    if iClk'event and iClk = '0' then   -- FALLING clock edge
   --   i := unsigned(iAddr(2**gAddrWidth-1 downto 0));
    --  j := to_integer(i);
    --  oData <= mem(j);
      oData <= mem(to_integer(unsigned(iAddr(gAddrWidth-1 downto 0))));
    end if;
  end process;
end architecture;