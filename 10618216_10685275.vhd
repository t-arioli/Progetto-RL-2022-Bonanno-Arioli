library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
--interface
entity project_reti_logiche is
    Port ( 
        i_clk : in std_logic;
            i_rst : in std_logic;
            i_start : in std_logic;
            i_data : in std_logic_vector(7 downto 0);
            o_address : out std_logic_vector(15 downto 0);
            o_done : out std_logic;
            o_en : out std_logic;
            o_we : out std_logic;
            o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    component datapath is
        port(  --SPECIFIC SIGNALS
            i_clk : in std_logic;
            i_rst : in std_logic;
            i_data : in std_logic_vector(7 downto 0);
            o_address : out std_logic_vector(15 downto 0);
            o_done : out std_logic;
            o_data : out std_logic_vector (7 downto 0);

            addr_reg_load :  in std_logic; --load addr_reg
            o_mem_reg_load : in std_logic; --load o_mem_reg
            n_word_reg_load : in std_logic; --load n_word_reg
            data_load : in std_logic; --permit the i_data's content loading into com,putational section 
            j_reg_load : in std_logic; --load j_reg
            out_shift : in std_logic; --permit the shifting in the reg16
            load_second_part : in std_logic; --load the first 8 bits or second 8 bits in the o_data from reg16
            o_addr_select: in std_logic; --select the content from addr_reg or o_mem_reg
            end_words: in std_logic; --notifies the ending of words
            automa_clk: in std_logic; --permit the d flip flops funcionality
            reset_state: in std_logic -- automatically initialize the registers
         ); 
    end component;
    
    --ADDRESS COUNTER SECTION--
    signal o_addr_reg : std_logic_vector(15 downto 0);
    signal addr_sum : std_logic_vector(15 downto 0);
    signal addr_reg_comp : std_logic;
    --ADDRESS CALCULATOR SECTION--
    signal o_mem_reg : std_logic_vector(15 downto 0);
    signal o_mem_sum : std_logic_vector(15 downto 0);
    --WORD COUNTER SECTION--
    signal o_n_word_reg : std_logic_vector(7 downto 0);
    signal o_n_word_sub : std_logic_vector(7 downto 0);
    signal o_n_word_mux : std_logic_vector(7 downto 0);
    --J_REG SECTION--
    signal o_j_reg : std_logic_vector(2 downto 0);
    signal o_j_sum : std_logic_vector(2 downto 0);
    --COMPUTATIONAL SECTION--
    signal o_comp_mux : std_logic_vector(7 downto 0);
    signal uk : std_logic;
    signal uk_1 : std_logic;
    signal uk_2 : std_logic;
    signal p1k : std_logic;
    signal p2k : std_logic;
    --REG16 SECTION--
    signal o_reg16 : std_logic_vector(15 downto 0);
    -- FSA SIGNALS
    signal addr_reg_load : std_logic;
    signal o_mem_reg_load : std_logic;
    signal n_word_reg_load : std_logic;
    signal data_load : std_logic;
    signal j_reg_load : std_logic;
    signal out_shift : std_logic;
    signal load_second_part : std_logic;
    signal o_addr_select: std_logic;
    signal end_words: std_logic;
    signal automa_clk: std_logic; --!!!
    signal reset_state: std_logic; --!!!
    --
    type state_type is(RST, S0, S1, S1_1, S2, S3, S3_1, S3_2, S3_3, S3_4, S3_5, S3_6, S3_7, S4, S5, S6, S7);
    signal curr_state, next_state: state_type; 

    --DATAPATH
    begin
    --ADDRESS COUNTER SECTION
    --addr_reg
    process(i_clk, i_rst, reset_state)
    begin
        if(i_rst = '1' or reset_state = '1') then
            o_addr_reg <= "0000000000000000";
        elsif(i_clk'event and i_clk = '1') then
            if(addr_reg_load = '1') then
                o_addr_reg <= addr_sum;
            end if;
        end if;
    end process; 
    
    --8 bit adder
    addr_sum <= o_addr_reg + "0000000000000001";
    
    --comparator
    addr_reg_comp <= '1' when (o_addr_reg = "0000000000000000") else '0';
    
    --ADDRESS CALCULATOR SECTION
    --o_mem_reg
    process(i_clk, i_rst, reset_state, o_mem_reg_load)
    begin
        if(i_rst = '1' or reset_state = '1') then
            o_mem_reg <= "0000001111101000";
        elsif(i_clk'event and i_clk = '1') then
            if(o_mem_reg_load = '1') then
                o_mem_reg <= o_mem_sum;
            end if;
        end if;
    end process;
    
    --8 bit adder
    o_mem_sum <= o_mem_reg + "0000000000000001";
    
    --O_ADDRESS HANDLING SECTION
    --o_address_mux
    with o_addr_select select
        o_address <= o_addr_reg when '0',
            o_mem_reg when '1',
              "UUUUUUUUUUUUUUUU" when others; --impossible

    --WORD COUNTER SECTION
    --n_word_reg
    process(i_clk)
    begin
        if(i_clk'event and i_clk = '1') then
            if(n_word_reg_load = '1') then
                o_n_word_reg <= o_n_word_mux;
            end if;
        end if;
    end process;
    
    --8 bit subber 
    o_n_word_sub <= o_n_word_reg - "00000001";
    
    --n_word_mux
    with addr_reg_comp select
        o_n_word_mux <= o_n_word_sub when '0',
            i_data when '1',
            "XXXXXXXX" when others; --impossible
    
    --comparator
    end_words <= '1' when (o_n_word_reg = "00000000") else '0';
    
    --JREG SECTION
    --j_reg
    process(i_clk)
    begin
        if(i_clk'event and i_clk = '1') then
            if(j_reg_load = '1') then
                o_j_reg <= o_j_sum;
            else
                o_j_reg <= "000";
            end if;
        end if;
    end process;
    
    --3 bit summer
    o_j_sum <= o_j_reg + "001";
    
    --COMPUTATIONAL SECTION
    -- 1 bit mux
    with data_load select
        o_comp_mux <= i_data when '1',
            "00000000" when '0',
            "XXXXXXXX" when others; --impossible
            
    -- 3 bit mux
    with o_j_reg select
        uk <= o_comp_mux(7) when "000",
            o_comp_mux(6) when "001",
            o_comp_mux(5) when "010",
            o_comp_mux(4) when "011",
            o_comp_mux(3) when "100",
            o_comp_mux(2) when "101",
            o_comp_mux(1) when "110",
            o_comp_mux(0) when "111",
            'X' when others; --impossible;
            
    --ff d 1 
    process(i_clk, automa_clk)
    begin
        if(i_clk'event and i_clk = '1' and automa_clk = '1') then 
            uk_1 <= uk;
        end if;
    end process;
    
    --ff d 2 
    process(i_clk, automa_clk)
    begin
        if(i_clk'event and i_clk = '1' and automa_clk = '1') then
            uk_2 <= uk_1;
        end if;
    end process;
    
    --xor 
    p1k <= (uk xor uk_2);
    p2k <= (uk xor uk_1 xor uk_2);
          
    --REG16 SECTION
    --mux16
    with load_second_part select
        o_data <= o_reg16(15 downto 8) when '0',
            o_reg16(7 downto 0) when '1',
            "XXXXXXXX" when others; --impossible
                    
    --REG16
    process(i_clk, out_shift)
    begin
        if(i_clk'event and i_clk = '1' and out_shift = '1')then
            o_reg16 <=  o_reg16(13 downto 0) & p1k & p2k;
        end if;
    end process;
    
    --FSA
    process(i_clk, i_rst)
        begin
            if(i_rst = '1') then
                curr_state <= RST;
            elsif i_clk'event and i_clk = '1' then
                curr_state <= next_state;
        end if ;
    end process;
    
    process(curr_state, i_start, end_words)
    begin
        next_state <= curr_state;
        case curr_state is
            when RST =>
                if i_start = '1' then
                    next_state <= S0;
                end if;
            when S0 =>
                next_state <= S1;
            when S1 =>
                    next_state <= S1_1;
            when S1_1 =>
                    if(end_words = '1') then
                        next_state <= S7;
                    else
                        next_state <= S2;
                    end if;
            when S2 =>
                    next_state <= S3;
            when S3 =>
                    next_state <= S3_1;
            when S3_1 =>
                    next_state <= S3_2;
            when S3_2 =>
                    next_state <= S3_3;
            when S3_3 =>
                    next_state <= S3_4;
            when S3_4 =>
                    next_state <= S3_5;
            when S3_5 =>
                    next_state <= S3_6;
            when S3_6 =>
                    next_state <= S3_7;
            when S3_7 =>
                    next_state <= S4;
            when S4 =>
                    next_state <= S5;
            when S5 =>
                next_state <= S6;
            when S6 =>
                    next_state <= S1;
            when S7 =>
                    if(i_start = '0') then
                        next_state <= RST;
                    end if;      
            when others =>
       end case;
    end process;
    
    process(curr_state)
    begin
        addr_reg_load <= '0';
        o_mem_reg_load <= '0';
        data_load <= '0';
        j_reg_load <= '0';
        out_shift <= '0';
        load_second_part <= '0';
        o_addr_select <= '0';
        o_en <= '0';     
        o_we <= '0';     
        o_done <= '0';
        n_word_reg_load <= '0';
        automa_clk <= '0';
        reset_state <= '0';
        case curr_state is
            when RST =>
                automa_clk <= '1';
                reset_state <= '1';
            when S0 =>
                o_en <= '1';
            when S1 =>
                addr_reg_load <= '1';
                n_word_reg_load <= '1';
            when S1_1 =>
            when S2 =>
                o_en <= '1';
            when S3 | S3_1 | S3_2 | S3_3 | S3_4 | S3_5 | S3_6 | S3_7 =>
                automa_clk <= '1';
                data_load <= '1';
                j_reg_load <= '1';
                out_shift <= '1';
            when S4 =>
            when S5 =>
                o_mem_reg_load <= '1';
                o_en <= '1';
                o_we <= '1';
                o_addr_select <= '1';
                load_second_part <= '0';
            when S6 =>
                o_mem_reg_load <= '1';
                o_en <= '1';
                o_we <= '1';
                o_addr_select <= '1';
                load_second_part <= '1';
            when S7 =>
                o_done <= '1';
            when others => 
        end case;
    end process;
    
    
end Behavioral;