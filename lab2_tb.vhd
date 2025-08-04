library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file_tb is
    -- Notice that no inputs and outputs in testbenches
end reg_file_tb;

architecture behavioral of reg_file_tb is
    -- period to wait for one clock cycle
    constant PERIOD : time := 10 ns;
    
    -- Component Declaration
    component reg_file 
        port(
            clk  : in  std_logic;
            rst  : in  std_logic;
            we   : in  std_logic;
            addr : in  std_logic_vector(2 downto 0);
            din  : in  std_logic_vector(3 downto 0);
            dout : out std_logic_vector(3 downto 0)
        );
    end component;
    
    -- Signal declarations
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';
    signal we   : std_logic := '0';
    signal addr : std_logic_vector(2 downto 0) := (others => '0');
    signal din  : std_logic_vector(3 downto 0) := (others => '0');
    signal dout : std_logic_vector(3 downto 0);
    
begin
    -- Component Instantiation
    uut: reg_file
    port map (
        clk  => clk,
        rst  => rst,
        we   => we,
        addr => addr,
        din  => din,
        dout => dout
    );
    
    -- Generate clock signal 
    clk_gen: process
    begin
        clk <= '0';
        wait for PERIOD/2;
        clk <= '1';
        wait for PERIOD/2;
    end process;
    
    -- Test Bench Statements
    tb : process
    begin
        -- Initial reset - set rst low (active low reset)
        rst <= '0';
        we <= '0';
        wait for 15 ns;
        
        -- Release reset
        rst <= '1';
        wait for 15 ns;
        
        -- Test writing to each register
        report "Starting write operations...";
        
        for i in 0 to 7 loop
            -- Set address and data
            addr <= std_logic_vector(to_unsigned(i, 3));
            din <= std_logic_vector(to_unsigned(i + 5, 4)); -- Write different values (5,6,7,8,9,10,11,12)
            we <= '1'; -- Enable writing
            
            wait for PERIOD; -- Wait for one clock cycle
            
            we <= '0'; -- Disable writing
            
            -- Change din to verify it doesn't affect output when we=0
            din <= "1111";
            wait for PERIOD;
            
            report "Written " & integer'image(i + 5) & " to register " & integer'image(i);
        end loop;
        
        -- Test reading from each register
        report "Starting read operations...";
        we <= '0'; -- Ensure writing is disabled
        din <= "0000"; -- Set din to known value
        
        for i in 0 to 7 loop
            addr <= std_logic_vector(to_unsigned(i, 3));
            wait for 10 ns; -- Wait for combinational delay
            
            report "Read from register " & integer'image(i) & 
                   ": Expected=" & integer'image(i + 5) & 
                   ", Got=" & integer'image(to_integer(unsigned(dout)));
            
            -- Verify the read data
            assert dout = std_logic_vector(to_unsigned(i + 5, 4))
                report "ERROR: Register " & integer'image(i) & 
                       " contains wrong data!"
                severity error;
            
            wait for 10 ns;
        end loop;
        
        -- Test reset functionality
        report "Testing reset functionality...";
        
        -- Set to read register 0 (should contain value 5)
        addr <= "000";
        wait for 10 ns;
        assert dout = "0101" -- Should be 5
            report "ERROR: Register 0 doesn't contain expected value before reset!"
            severity error;
        
        -- Apply reset
        rst <= '0';
        wait for 15 ns;
        
        -- Check if output is cleared (should be 0 due to reset)
        assert dout = "0000"
            report "ERROR: Output not cleared during reset!"
            severity error;
        
        -- Release reset and check all registers are cleared
        rst <= '1';
        wait for 15 ns;
        
        report "Checking all registers after reset...";
        for i in 0 to 7 loop
            addr <= std_logic_vector(to_unsigned(i, 3));
            wait for 10 ns;
            
            assert dout = "0000"
                report "ERROR: Register " & integer'image(i) & 
                       " not cleared after reset!"
                severity error;
        end loop;
        
        -- Test partial write (write only to some registers after reset)
        report "Testing partial writes after reset...";
        
        -- Write to registers 1, 3, 5
        for i in 1 to 5 loop
            if i mod 2 = 1 then -- Only odd registers
                addr <= std_logic_vector(to_unsigned(i, 3));
                din <= std_logic_vector(to_unsigned(15 - i, 4)); -- Different pattern
                we <= '1';
                wait for PERIOD;
                we <= '0';
                wait for PERIOD;
                
                report "Written " & integer'image(15 - i) & " to register " & integer'image(i);
            end if;
        end loop;
        
        -- Verify the pattern
        for i in 0 to 7 loop
            addr <= std_logic_vector(to_unsigned(i, 3));
            wait for 10 ns;
            
            if i = 1 or i = 3 or i = 5 then
                assert dout = std_logic_vector(to_unsigned(15 - i, 4))
                    report "ERROR: Register " & integer'image(i) & 
                           " doesn't contain expected value!"
                    severity error;
            else
                assert dout = "0000"
                    report "ERROR: Register " & integer'image(i) & 
                           " should be zero!"
                    severity error;
            end if;
        end loop;
        
        report "Testbench completed successfully!";
        wait; -- End simulation
        
    end process;
    
end behavioral;

