library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
         port (
             i_clk   : in std_logic;
             i_rst   : in std_logic;
             i_start : in std_logic;
             i_w     : in std_logic;
             o_z0    : out std_logic_vector(7 downto 0);
             o_z1    : out std_logic_vector(7 downto 0);
             o_z2    : out std_logic_vector(7 downto 0);
             o_z3    : out std_logic_vector(7 downto 0);
             o_done  : out std_logic;
             o_mem_addr : out std_logic_vector(15 downto 0);
             i_mem_data : in std_logic_vector(7 downto 0);
             o_mem_we   : out std_logic;
             o_mem_en   : out std_logic
         );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is

type t_State is (Reset, C1, C2, ADDRLoop, ASK_Mem, READ_Mem, Display);
signal State: t_State;

--Control signals for Address-Shifter
signal w_as_rst             :   std_logic;
signal w_as_enable          :   std_logic;
signal w_as_counter_rst     :   std_logic;
signal w_as_counter_enable  :   std_logic;

--Control signals for Channel-Address-Register
signal w_car_rst            :   std_logic;
signal w_car_enable         :   std_logic;
signal w_car_sel            :   std_logic;

--Control signals for Z-Register
signal w_z_reg_rst          :   std_logic;
signal w_z_reg_enable       :   std_logic;

signal w_sel                :   std_logic; --Control signal for MUX W_Selector
signal w_done               :   std_logic; --Done signal

--Output signals of MUX W_Selector
signal w_i_as               :   std_logic;
signal w_i_car              :   std_logic;

--Registers
signal r_as_counter         :   unsigned(0 to 3);
signal r_as                 :   unsigned(0 to 15);
signal r_car                :   std_logic_vector(0 to 1);
signal r_z_reg_0            :   std_logic_vector(0 to 7);
signal r_z_reg_1            :   std_logic_vector(0 to 7);  
signal r_z_reg_2            :   std_logic_vector(0 to 7);  
signal r_z_reg_3            :   std_logic_vector(0 to 7);   

begin

StateProcess : process(i_clk, i_rst) is
--Sequential Process
--State cycle management
begin
    if i_rst = '1' then
        State <= Reset;
    elsif rising_edge(i_clk) then
        case State is
            when Reset      =>
                State <= C1;
            when C1         =>
                if i_start = '1' then
                    State <= C2;
                end if;
            when C2         =>
                State <= ADDRLoop;
            when ADDRLoop   =>
                if i_start = '0' then
                    State <= ASK_Mem;
                end if;
            when ASK_Mem    =>
                State <= READ_Mem;
            when READ_Mem   =>
                State <= Display;
            when Display    =>
                State <= C1;
        end case;
    end if;
end process StateProcess;

ControlProcess : process(State) is
--Combinational Process
--Control signal management
begin
    o_done              <= '0';
    o_mem_we            <= '0';
    o_mem_en            <= '0';
    w_as_rst            <= '0';
    w_as_enable         <= '0';
    w_as_counter_rst    <= '0';
    w_as_counter_enable <= '0';
    w_car_rst           <= '0';
    w_car_enable        <= '0';
    w_car_sel           <= '0';
    w_z_reg_rst         <= '0';
    w_z_reg_enable      <= '0';
    w_sel               <= '0';
    w_done              <= '0';
    case state is
        when Reset      =>
            w_as_rst            <= '1';
            w_as_counter_rst    <= '1';
            w_car_rst           <= '1';
            w_z_reg_rst         <= '1';
        when C1         =>
            w_as_rst            <= '1';
            w_as_counter_rst    <= '1';
            w_car_enable        <= '1';
        when C2         =>
            w_car_enable        <= '1';
            w_car_sel           <= '1';
        when ADDRLoop   =>
            w_as_enable         <= '1';
            w_as_counter_enable <= '1';
            w_sel               <= '1';
        when ASK_Mem    =>
            o_mem_en            <= '1';
        when READ_Mem   =>
            w_z_reg_enable      <= '1';
        when Display    =>
            o_done              <= '1';
            w_done              <= '1';
    end case;
end process ControlProcess;

W_Selector : process(i_w, w_sel) is
--Combinational Process
--W routing
begin
    if w_sel = '0' then
        w_i_car <= i_w;
        w_i_as  <= '0';
    else 
        w_i_car <= '0';
        w_i_as  <= i_w;
    end if;
end process W_Selector;

CAR_Register : process(i_clk, w_car_rst) is
--Sequential Process
--Saving channel address
begin
    if w_car_rst = '1' then
        r_car(0) <= '0';
        r_car(1) <= '0';
    elsif rising_edge(i_clk) then
        if w_car_enable = '1' then
            case w_car_sel is
                when '0' => r_car(0) <= w_i_car;
                when '1' => r_car(1) <= w_i_car;
                when others =>
            end case;
        end if;
    end if;
end process CAR_Register;

AS_Counter : process(i_clk, w_as_counter_rst) is
--Sequential Process
--Incoming bit counter
begin
    if w_as_counter_rst = '1' then
        r_as_counter <= "0000";
    elsif rising_edge(i_clk) then
        if w_as_counter_enable = '1' then
            r_as_counter <= r_as_counter + 1;
        end if;
    end if;
end process AS_Counter;

AS_Register : process(i_clk, w_as_rst) is
--Sequential Process
--Saving address bits
begin
    if w_as_rst = '1' then
        r_as <= "0000000000000000";
    elsif rising_edge(i_clk) then
        if i_start = '1' then
            case r_as_counter is
                when "0000" => r_as(0)  <= w_i_as;
                when "0001" => r_as(1)  <= w_i_as;
                when "0010" => r_as(2)  <= w_i_as;
                when "0011" => r_as(3)  <= w_i_as;
                when "0100" => r_as(4)  <= w_i_as;
                when "0101" => r_as(5)  <= w_i_as;
                when "0110" => r_as(6)  <= w_i_as;
                when "0111" => r_as(7)  <= w_i_as;
                when "1000" => r_as(8)  <= w_i_as;
                when "1001" => r_as(9)  <= w_i_as;
                when "1010" => r_as(10) <= w_i_as;
                when "1011" => r_as(11) <= w_i_as;
                when "1100" => r_as(12) <= w_i_as;
                when "1101" => r_as(13) <= w_i_as;
                when "1110" => r_as(14) <= w_i_as;
                when "1111" => r_as(15) <= w_i_as;
                when others => 
            end case;
        end if;
    end if;
end process AS_Register;

AS_Shift : process(r_as, r_as_counter) is
--Combinational Process
--Address bit shifting
begin
    case r_as_counter is
        when "0001" => o_mem_addr <= r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8) & r_as(9) & r_as(10) & r_as(11) & r_as(12) & r_as(13) & r_as(14) & r_as(15);
        when "0010" => o_mem_addr <= "000000000000000" & r_as(0);
        when "0011" => o_mem_addr <= "00000000000000" & r_as(0) & r_as(1);
        when "0100" => o_mem_addr <= "0000000000000" & r_as(0) & r_as(1) & r_as(2);
        when "0101" => o_mem_addr <= "000000000000” & r_as(0) & r_as(1) & r_as(2) & r_as(3);
        when “0110” => o_mem_addr <= “00000000000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4);
        when “0111” => o_mem_addr <= “0000000000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5);
        when “1000” => o_mem_addr <= “000000000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6);
        when “1001” => o_mem_addr <= “00000000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7);
        when “1010” => o_mem_addr <= “0000000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8);
        when “1011” => o_mem_addr <= “000000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8) & r_as(9);
        when “1100” => o_mem_addr <= “00000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8) & r_as(9) & r_as(10);
        when “1101” => o_mem_addr <= “0000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8) & r_as(9) & r_as(10) & r_as(11);
        when “1110” => o_mem_addr <= “000” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8) & r_as(9) & r_as(10) & r_as(11) & r_as(12);
        when “1111” => o_mem_addr <= “00” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8) & r_as(9) & r_as(10) & r_as(11) & r_as(12) & r_as(13);
        when “0000” => o_mem_addr <= “0” & r_as(0) & r_as(1) & r_as(2) & r_as(3) & r_as(4) & r_as(5) & r_as(6) & r_as(7) & r_as(8) & r_as(9) & r_as(10) & r_as(11) & r_as(12) & r_as(13) & r_as(14);
        when others => o_mem_addr <= “XXXXXXXXXXXXXXXX”;
    end case;
end process AS_Shift;

Z_Register : process(i_clk, w_z_reg_rst) is
–Sequential Process
–Saving memory output
begin
if w_z_reg_rst = ‘1’ then
r_z_reg_0 <= “00000000”;
r_z_reg_1 <= “00000000”;
r_z_reg_2 <= “00000000”;
r_z_reg_3 <= “00000000”;
elsif rising_edge(i_clk) then
if w_z_reg_enable = ‘1’ then
case r_car is
when “00” => r_z_reg_0 <= i_mem_data;
when “01” => r_z_reg_1 <= i_mem_data;
when “10” => r_z_reg_2 <= i_mem_data;
when “11” => r_z_reg_3 <= i_mem_data;
when others =>
end case;
end if;
end if;
end process Z_Register;

Output : process(r_z_reg_0, r_z_reg_1, r_z_reg_2, r_z_reg_3, w_done) is
–Combinational Process
–Display of output registers on output channels
begin
if w_done = ‘1’ then
o_z0 <= r_z_reg_0;
o_z1 <= r_z_reg_1;
o_z2 <= r_z_reg_2;
o_z3 <= r_z_reg_3;
elsif w_done = ‘0’ then
o_z0 <= “00000000”;
o_z1 <= “00000000”;
o_z2 <= “00000000”;
o_z3 <= “00000000”;
end if;
end process Output;

end project_reti_logiche_arch;