# SimpleHardwareNavigator
Simple navigator entirely relying on its own hardware built with VHDL.

It was used a FPGA xc7a200tfbg484-1 with a clock of 100ns.

```
entity project_logic_net is
port (
    i_clk : in std_logic;
    i_start : in std_logic;
    i_rst : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);
end project_logic_net;
```
In particular:
&nbsp;&nbsp;&nbsp;● i_clk it's the clock signal
&nbsp;&nbsp;&nbsp;● i_start it's the start of computation signal
&nbsp;&nbsp;&nbsp;● i_rst it's the RESET signal which allow the component to reeive a START signal
&nbsp;&nbsp;&nbsp;● i_data it's the signal coming from the RAM in a form of a vector after a RAM read request
&nbsp;&nbsp;&nbsp;● o_address it's the vector signal for telling the RAM which address I want to read from
&nbsp;&nbsp;&nbsp;● o_done it's the signal of the end of the computation
&nbsp;&nbsp;&nbsp;● o_en it's the ENABLE signal for allowing communication with RAM, needed for both writes and reads
&nbsp;&nbsp;&nbsp;● o_we it's the WRITE ENABLE signal which has to be sent to the RAM equal to 1 to be able to write. Instead for reading it must be equal to 0
&nbsp;&nbsp;&nbsp;● o_data it's the vector signal sent to the RAM which will be written at the requested address

RAM description
```
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity rams_sp_wf is
port(
    clk : in std_logic;
    we : in std_logic;
    en : in std_logic;
    addr : in std_logic_vector(15 downto 0);
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0)
);
end rams_sp_wf;
architecture syn of rams_sp_wf is
type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
signal RAM : ram_type;
begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            if en = '1' then
                if we = '1' then
                    RAM(conv_integer(addr)) <= di;
                    do <= di;
                else
                    do <= RAM(conv_integer(addr));
                end if;
            end if;
        end if;
    end process;
end syn;
```
