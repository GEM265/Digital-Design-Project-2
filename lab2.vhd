library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Fixed register module with proper generic usage
entity reg_module is
    Generic (N: integer := 4);
    Port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        we   : in  std_logic;
        din  : in  std_logic_vector(N-1 downto 0);
        dout : out std_logic_vector(N-1 downto 0)
    );
end reg_module;

architecture behavioral of reg_module is
    signal reg_data : std_logic_vector(N-1 downto 0) := (others => '0');
begin 
    process (rst, clk)
    begin 
        if rst = '0' then 
            reg_data <= (others => '0');
        elsif rising_edge(clk) then 
            if we = '1' then 
                reg_data <= din;
            end if;
        end if;
    end process;
    
    -- Output the stored data
    dout <= reg_data;
end behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Fixed multiplexer - removed unused din port
entity mux_8to1 is
    Generic (N : integer := 4);
    Port (
        addr : in std_logic_vector (2 downto 0);
        din_0: in  std_logic_vector ((N-1) downto 0);
        din_1: in  std_logic_vector ((N-1) downto 0);
        din_2: in  std_logic_vector ((N-1) downto 0);
        din_3: in  std_logic_vector ((N-1) downto 0);
        din_4: in  std_logic_vector ((N-1) downto 0);
        din_5: in  std_logic_vector ((N-1) downto 0);
        din_6: in  std_logic_vector ((N-1) downto 0);
        din_7: in  std_logic_vector ((N-1) downto 0);
        dout : out  std_logic_vector((N-1) downto 0)
    );
end mux_8to1;

architecture behavioral of mux_8to1 is
begin
    process(addr, din_0, din_1, din_2, din_3, din_4, din_5, din_6, din_7)
    begin
        case addr is
            when "000" => 
                dout <= din_0;
            when "001" =>
                dout <= din_1;
            when "010" => 
                dout <= din_2;
            when "011" => 
                dout <= din_3;
            when "100" => 
                dout <= din_4;
            when "101" => 
                dout <= din_5;
            when "110" => 
                dout <= din_6;
            when others => 
                dout <= din_7;
        end case;
    end process;
end behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Fixed decoder - corrected the output pattern
entity decoder_3to8 is 
    port (
        addr : in std_logic_vector(2 downto 0);
        we: in std_logic;
        dout : out std_logic_vector (7 downto 0)
    );
end decoder_3to8;
   
architecture dataflow of decoder_3to8 is
    signal weaddr: std_logic_vector(3 downto 0);
begin 
    weaddr <= we & addr;
    
    with weaddr select
        dout <= "00000001" when "1000",  -- addr=000, we=1
                "00000010" when "1001",  -- addr=001, we=1
                "00000100" when "1010",  -- addr=010, we=1
                "00001000" when "1011",  -- addr=011, we=1
                "00010000" when "1100",  -- addr=100, we=1
                "00100000" when "1101",  -- addr=101, we=1
                "01000000" when "1110",  -- addr=110, we=1
                "10000000" when "1111",  -- addr=111, we=1 (Fixed this line)
                "00000000" when others;  -- we=0 or other cases
end dataflow;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_file is 
    port (
        clk: in std_logic;
        rst: in std_logic;
        we: in std_logic;
        addr: in std_logic_vector(2 downto 0);
        din: in std_logic_vector (3 downto 0);
        dout: out std_logic_vector (3 downto 0)
    );
end reg_file;        

architecture structural of reg_file is 

    component mux_8to1
        Generic (N : integer := 4);
        Port (
            addr : in  std_logic_vector (2 downto 0);
            din_0: in  std_logic_vector ((N-1) downto 0);
            din_1: in  std_logic_vector ((N-1) downto 0);
            din_2: in  std_logic_vector ((N-1) downto 0);
            din_3: in  std_logic_vector ((N-1) downto 0);
            din_4: in  std_logic_vector ((N-1) downto 0);
            din_5: in  std_logic_vector ((N-1) downto 0);
            din_6: in  std_logic_vector ((N-1) downto 0);
            din_7: in  std_logic_vector ((N-1) downto 0);
            dout : out  std_logic_vector((N-1) downto 0)
        );
    end component;
    
    component decoder_3to8 
        port (
            addr : in std_logic_vector(2 downto 0);
            we: in std_logic;
            dout : out std_logic_vector (7 downto 0)
        );
    end component;        
    
    component reg_module 
        Generic (N: integer := 4);
        Port (
            clk  : in  std_logic;
            rst  : in  std_logic;
            we   : in  std_logic;
            din  : in  std_logic_vector(N-1 downto 0);
            dout : out std_logic_vector(N-1 downto 0)
        );
    end component;        

    type reg_t is array (0 to 7) of std_logic_vector (3 downto 0);
    signal reg_out: reg_t;
    signal decoder_we: std_logic_vector (7 downto 0);            
    
begin 

    mux: mux_8to1 generic map (N => 4)
        port map (
            addr => addr,
            din_0 => reg_out(0),
            din_1 => reg_out(1),
            din_2 => reg_out(2),
            din_3 => reg_out(3),
            din_4 => reg_out(4),
            din_5 => reg_out(5),
            din_6 => reg_out(6),
            din_7 => reg_out(7),
            dout => dout
        );
        
    dec: decoder_3to8
        port map (
            addr => addr,
            we => we,
            dout => decoder_we
        );
        
    gen: for i in 0 to 7 generate 
        reg: reg_module generic map (N => 4)
            port map (
                clk => clk,
                rst => rst,
                we => decoder_we(i),
                din => din,
                dout => reg_out(i)
            );
    end generate;
    
end structural;
    