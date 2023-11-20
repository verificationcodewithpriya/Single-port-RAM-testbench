////////////////////////// Transaction ////////////////////////////////////////

typedef enum {WRITE, READ} T_type;
class transaction #(parameter M=3,parameter N=8);
  bit clk,rst;
  rand bit w_r_com;
  randc bit[M-1:0]addr;
  rand bit[N-1:0]wr_data;
  bit[N-1:0] re_data;
  rand T_type op_type; 
  
  
  constraint op_type_c {if (op_type == WRITE) w_r_com == 1;
                        else w_r_com == 0;}
  
  function void print(string tag =" ");
    $display($time," tag= %0s, w_r_com = %0h, addr = %0h, wr_data = %0h, re_data = %0h",tag,w_r_com,addr,wr_data,re_data);
  endfunction
  
   /*function void pre_randomize();
     $display("\n", $time," Before randomize w_r_com = %0h, addr = %0h, wr_data = %0h",w_r_com,addr,wr_data);
  endfunction
  
   function void post_randomize();
     $display($time," After randomize w_r_com = %0h, addr = %0h, wr_data = %0h\n",w_r_com,addr,wr_data);
  endfunction*/
  
endclass

/////////////////// Generatore /////////////////////////////////////////////////

class generator #(parameter M=3,parameter N=8);
  transaction pkts = new();
  mailbox #(transaction)drv_mb;
  event drv_done;
  int num = 30;   

  function void build();
    //$display($time , " GNERATOR TRIGGERED");
    drv_mb = new();
    //$display($time , " GNERATOR EXIT");
  endfunction
  
  virtual task run();   
    for(int i=0; i<num; i++)begin
      pkts.randomize();
      drv_mb.put(pkts);
      @(drv_done);      
    end 
    $display($time, " [Generator] done generation of %0d pkts",num);   
  endtask  
endclass

////////////WRITE FIRST READ NEXT/////////////////
class write_first_read_next extends generator;
 int num2 = 16;
  task run();
    for(int i=0; i<num2; i++)begin
      pkts.randomize() with { 
        if (i < num2/2)
        {addr == i[2:0];
        op_type == WRITE;}
       else 
       { addr == i-(num2/2);
         op_type == READ;}                                        
      };
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done); 
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass

///////////WRITE ONLY INCREMENTAL ADDRESS////////////
class write_only_incremental_addr extends generator;
  
  task run();
    for(int i=0; i<num; i++)begin
            
      pkts.randomize() with  
      {     
        addr == i[2:0];
        op_type == WRITE;
        wr_data>=10;        
      };
      drv_mb.put(pkts);
       
      $display($time, " num[%0d]",i);
      @(drv_done);      
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass


/////////WRITE ONLY RANDOM ADDRESS/////////////////

class write_only_random_addr extends generator;
  
  task run();
    for(int i=0; i<num; i++)begin
            
      pkts.randomize() with  
      {        
        wr_data>=10;        
      };
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done);      
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass

/////////READ ONLY INCREMENTAL ADDRESS/////////////

class read_only_incremental_addr extends generator;
  
  task run();
    for(int i=0; i<num; i++)begin
      pkts.randomize() with  
      { 
        pkts.addr == i[2:0];
        w_r_com == 0;        
      };
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done);      
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass

//////////////WRITE READ BACK TO BACK//    WRITE FOLLWED BY READ////////////

class write_read_b2b extends generator;
  
  task run();
    for(int i=0; i<num; i++)begin      
      pkts.randomize() with  
      { 
        w_r_com == 0;
        wr_data inside {[0:10]};        
      };
      drv_mb.put(pkts);
     
      @(drv_done);
      
      pkts.randomize() with  
      { 
        w_r_com == 1;
        wr_data inside {[0:10]};        
      };
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done);
       
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass


//////////////WRITE READ BACK TO BACK WITH INCREMENTAL ADDRESS//////////////

class write_read_b2b_with_incremental_addr extends generator;
  
  task run();
    for(int i=0; i<num; i++)begin      
      pkts.randomize() with  
      { 
        addr == i[2:0];
        w_r_com == 1;
        wr_data inside {[0:10]};
      };
      drv_mb.put(pkts);
      @(drv_done);
      
      pkts.randomize() with  
      { 
        addr == i[2:0];
        w_r_com == 0;
        wr_data inside {[0:10]};
      };
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done);
      
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass

////////////WRITE READ FROM EVEN LOCATION////////////////////

class write_read_even_loc extends generator;
  int x[$];
  task run();
    for(int i=0; i<num; i++)begin 
      pkts.randomize() with  
      { 
        if (addr % 2 != 0) 
          addr == addr + 1;       
          w_r_com == 1;
         
      };     
      x.push_front(pkts.wr_data);
      $display($time, " x = %p",x);
      pkts.print("WRITE TO EVEN LOCATION");
      drv_mb.put(pkts);
      @(drv_done); 
      
      pkts.randomize() with  
      {       
        if (addr % 2 != 0) 
          addr == addr + 1;       
          w_r_com == 0;
         
      };
      x.push_front(pkts.wr_data);
      $display($time, " x = %p",x);
      pkts.print(" READ FROM EVEN LOCATION");
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done); 
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass

////////////WRITE TO EVEN AND READ FROM ODD LOCATION WITH INCREMETING THE LOCATIONS////////////////////

class write_even_and_read_odd_loc extends generator;
  int x[$];
  task run();
    for(int i=0; i<num; i++)begin
      
      pkts.randomize() with  
      {       
        addr == i[2:0];
        w_r_com == (i%2==0)?1:0;
         
      };
      x.push_front(pkts.addr);
      $display($time, " x = %p",x);
      pkts.print(" READ FROM EVEN LOCATION");
      drv_mb.put(pkts);
      @(drv_done); 
    end 
    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass

////////////WRITE TO ODD AND READ FROM EVEN LOCATION////////////////////

class write_odd_and_read_even_loc extends generator;
  int x[$];
  task run();
    for(int i=0; i<num; i++)begin 
      pkts.randomize() with  
      { 
        if (addr % 2 == 0) 
          addr == addr + 1;       
          w_r_com == 1;
         
      };     
      x.push_front(pkts.wr_data);
      $display($time, " x = %p",x);
      //pkts.print("WRITE TO EVEN LOCATION");
      drv_mb.put(pkts);
      @(drv_done); 
      
      pkts.randomize() with  
      {       
        if (addr % 2 != 0) 
          addr == addr + 1;       
          w_r_com == 0;
         
      };
      x.push_front(pkts.wr_data);
      $display($time, " x = %p",x);
      //pkts.print(" READ FROM EVEN LOCATION");
      drv_mb.put(pkts);
      //$display($time, " num[%0d]",i);
      @(drv_done); 
    end 
    //$display($time, " [Generator] done generation of %0d pkts", num);
  endtask
endclass

////////////WRITE FIRST HALF MEM AND READ NEXT/////////////////
class write_first_half_mem_read_next extends generator;
   int num1 = 2**M;
  
  task run();
    for(int i=0; i<num1; i++)begin
      pkts.randomize() with { 
        if (i<num1/2)
        {addr == i[2:0];
          op_type == WRITE;}         
        else 
        { addr == i-num1/2;
         op_type == READ;}                                       
      };
      drv_mb.put(pkts);
      @(drv_done);  
    end 
        
   top.reset_mode();
        
   for(int i=0; i<num1; i++)begin
      pkts.randomize() with {
        if (i<num1/2)
        {addr == i[2:0];
          op_type == WRITE;}         
        else         
        { addr == i-num1/2;
         op_type == READ;}                                       
      };
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done);          
    end 
    $display($time, " [Generator] done generation of %0h pkts", num);
  endtask
endclass
        
////////////WRITE SECOND HALF MEM AND READ NEXT/////////////////
class write_second_half_mem_read_next extends generator;
   int num1 = 2**M;
  
  task run();
    for(int i=0; i<num1; i++)begin
      pkts.randomize() with { 
        if (i>=num1/2)
        {addr == i[2:0];
          op_type == READ;}         
        else 
        { addr == i+num1/2;
         op_type == WRITE;}                                       
      };
      drv_mb.put(pkts);
      $display($time, " num[%0d]",i);
      @(drv_done);          
    end 
        
   top.reset_mode();

    $display($time, " [Generator] done generation of %0d pkts", num);
  endtask
    
endclass


//////////////////////// Interface //////////////////////////////////////////////////

interface interface_if #(parameter M=3,parameter N=8) (input bit clk);
  logic rst;
  logic[M-1:0] addr;
  logic w_r_com;
  logic[N-1:0] wr_data;
  logic[N-1:0] re_data;
  
  
  clocking Design_cb @(posedge clk);
    default input #1 output #2;
    output addr;
    output rst;
    output w_r_com;
    output wr_data;
    input re_data;
  endclocking
  
  clocking Tb_cb @(posedge clk);
    default input #0 output #0;
    input rst;
    input addr;
    input w_r_com;
    input wr_data;
    input re_data;
  endclocking
  
  modport MOD1(clocking Design_cb, clocking Tb_cb);
  modport DUT(input clk,rst,addr,w_r_com,wr_data,output re_data);
  
endinterface
  
//////////////////// Driver //////////////////////////////////////////////////////////'
    
class driver;
  virtual interface_if vif;
  mailbox #(transaction)drv_mb;
  event drv_done;
  
  function void build();
    //$display($time , " DRIVER TRIGGERED");
    drv_mb = new();
    //$display($time , " DRIVER EXIT");
  endfunction
  
  task run();  
    @(vif.MOD1.Design_cb)begin
      forever begin    
        transaction pkts;      
        drv_mb.get(pkts);
        pre_driver(pkts);
        pkts.print("Driver");
        vif.MOD1.Design_cb.w_r_com <= pkts.w_r_com;
        vif.MOD1.Design_cb.addr <= pkts.addr;
        vif.MOD1.Design_cb.wr_data <= pkts.wr_data;
        post_driver(pkts);
        @(vif.MOD1.Design_cb);
        ->drv_done; 
      end
    end     
  endtask

  
  virtual task pre_driver(transaction pkts);    
  endtask

  virtual task post_driver(transaction pkts);
  endtask  
endclass
    
class driver1 extends driver;
   
  //callback method to modify the wdata
  
  task pre_driver(transaction pkts);    
    pkts.wr_data <= pkts.wr_data + 1;
    $display($time, " Pre_driver: wr_data before predrive = %0h",pkts.wr_data);
  endtask
  
  task post_driver(transaction pkts);
    #10;
    $display($time," Post_driver: Modified wdata is %0h", pkts.wr_data);
  endtask
endclass

    
    
//////////////////////// Monitor ///////////////////////////////////////////////////////
    
class monitor;
  virtual interface_if vif;
  mailbox #(transaction)scb_mb;
  mailbox #(transaction)cvg_mb;
  event reset_triggered;
  
  function void build();
    //$display($time , " MONITOR TRIGGERED");
    scb_mb = new();
    cvg_mb = new();
    //$display($time , " MONITOR EXIT");
  endfunction
  
 task run();   
      sample_port("Thread0");   
  endtask
  
  task sample_port(string tag = " ");   
    forever begin
      @(vif.MOD1.Tb_cb);       
      if(vif.MOD1.Tb_cb.rst == 1)begin
        transaction pkts = new();                
          pkts.addr = vif.MOD1.Tb_cb.addr;
          pkts.w_r_com = vif.MOD1.Tb_cb.w_r_com;          
          pkts.wr_data = vif.MOD1.Tb_cb.wr_data;
          pkts.re_data = vif.MOD1.Tb_cb.re_data; 
          scb_mb.put(pkts);  
          cvg_mb.put(pkts);
          pkts.print({"Monitor_ ",tag});
          $display($time, " vif.MOD1.Tb_cb.rst = %0d",vif.MOD1.Tb_cb.rst);
      end 
      
      if(vif.MOD1.Tb_cb.rst == 0)begin
        -> reset_triggered;        
        $display($time, " MONITOR: rst triggerd vif.MOD1.Tb_cb.rst = %0d",vif.MOD1.Tb_cb.rst);
        end 
    end
  endtask
endclass
    
////////////////////// Scoreboard /////////////////////////////////////////////////////    
class scoreboard #(parameter M=3,parameter N=8) ;
  mailbox #(transaction)scb_mb;
  event reset_captured;        
  bit [N-1:0]expected_outr;
  int ref_mem[int]; 
  
  function void build();
    //$display($time , " SCOREBOARD TRIGGERED");
    scb_mb = new();  
    //$display($time , " SCOREBOARD EXIT");
  endfunction
  
  task run();
    forever fork      
      begin
        wait(reset_captured.triggered);
        $display($time, " SCOREBOARD: reset captured ");
        ref_mem.delete();
        $display($time ," RFE_MEM = %p",ref_mem);
        expected_outr = 0;
        #1;
      end
       begin
        transaction pkts;
        scb_mb.get(pkts);
        ref_mem_update(pkts); 
        if(pkts.w_r_com == 1) write_check(pkts);       
        if(pkts.w_r_com == 0) read_check(pkts);        
      end
    join_any
  endtask
  
  function void ref_mem_update(transaction pkts);    
      if(pkts.w_r_com == 1)begin
        ref_mem[pkts.addr] = pkts.wr_data;
      end
    else if(pkts.w_r_com == 0) begin
      if(ref_mem.exists(pkts.addr))begin
        expected_outr = ref_mem[pkts.addr];        
      end
       else
         expected_outr = 'h0;         
      end
  endfunction
      
      function void write_check(transaction pkts);
        if(ref_mem[pkts.addr] == top.dut.mem[pkts.addr])begin
          $display($time," WRITE OPERATION CHECKER PASSED: ref_mem[pkts.addr]=%0h, top.dut.mem[pkts.addr] = %0h", ref_mem[pkts.addr],top.dut.mem[pkts.addr]);
        end
        else begin
          $error($time," WRITE CHECKER FAILED: addr=%0h, DUT_MEM_VALUE=%0h, TB_REF_MEM_VALUE=%0h\n", pkts.addr,top.dut.mem[pkts.addr],ref_mem[pkts.addr]);
        end
     endfunction
      
      function void read_check(transaction pkts);
        if(pkts.re_data === expected_outr)begin
          $display($time," READ OPERATION CHECKER PASSED : addr=%0h pkts.re_data=%0h expected_outr=%0h\n", pkts.addr, pkts.re_data,expected_outr);
        end
        else begin
          $error($time," READ CHECKER FAILED: addr=%0h, pkts.re_data=%0h, expected_outr=%0h\n", pkts.addr, pkts.re_data,expected_outr);
    	end
  endfunction       
endclass

////////////////////////Functional coverage/////////////////////////////
    
class fun_coverage #(parameter M=3,parameter N=8);
  mailbox #(transaction)cvg_mb;
  transaction pkts; 
  bit clk;
  
  bit write_b2b_incr_addr;
  transaction q1[$];
  
  bit write_b2b_random_addr;
  transaction q2[$];
  
  bit write_follwed_by_read_incr_addr;
  transaction q3[$];
  
  bit write_follwed_by_read_random_addr;
  transaction q4[$];
  
  bit Write_to_even_location;
  bit Write_to_odd_location;
  
  covergroup cg;// @(posedge clk);
    option.goal = 100;
    
    cp1: coverpoint pkts.w_r_com {
      							  bins write_com = {1};
      							  bins read_com = {0};}// iff (pkts.rst==1); 
    cp2: coverpoint pkts.addr {
      bins write_adress[] = {[0:$]};// iff (pkts.rst);
    						  }
    cp3: coverpoint pkts.wr_data {
                                  wildcard bins wr_data_ones_8 = {8'b1???????};
                                  wildcard bins wr_data_ones_7 = {8'b?1??????};
                                  wildcard bins wr_data_ones_6 = {8'b??1?????};
                                  wildcard bins wr_data_ones_5 = {8'b???1????};
                                  wildcard bins wr_data_ones_4 = {8'b????1???};
                                  wildcard bins wr_data_ones_3 = {8'b?????1??};
                                  wildcard bins wr_data_ones_2 = {8'b??????1?};
                                  wildcard bins wr_data_ones_1 = {8'b???????1};

                                  wildcard bins wr_data_zeros_8 = {8'b0???????};
                                  wildcard bins wr_data_zeros_7 = {8'b?0??????};
                                  wildcard bins wr_data_zeros_6 = {8'b??0?????};
                                  wildcard bins wr_data_zeros_5 = {8'b???0????};
                                  wildcard bins wr_data_zeros_4 = {8'b????0???};
                                  wildcard bins wr_data_zeros_3 = {8'b?????0??};
                                  wildcard bins wr_data_zeros_2 = {8'b??????0?};
                                  wildcard bins wr_data_zeros_1 = {8'b???????0};
                                }
    ///In wildcard bin if data is 10001001 then the bins 8,4,1 will be hit it means 3/8 = 37.5% 
    cp4: coverpoint pkts.re_data{
                                  wildcard bins re_data_ones_8 = {8'b1???????};
                                  wildcard bins re_data_ones_7 = {8'b?1??????};
                                  wildcard bins re_data_ones_6 = {8'b??1?????};
                                  wildcard bins re_data_ones_5 = {8'b???1????};
                                  wildcard bins re_data_ones_4 = {8'b????1???};
                                  wildcard bins re_data_ones_3 = {8'b?????1??};
                                  wildcard bins re_data_ones_2 = {8'b??????1?};
                                  wildcard bins re_data_ones_1 = {8'b???????1};

                                  wildcard bins re_data_zeros_8 = {8'b0???????};
                                  wildcard bins re_data_zeros_7 = {8'b?0??????};
                                  wildcard bins re_data_zeros_6 = {8'b??0?????};
                                  wildcard bins re_data_zeros_5 = {8'b???0????};
                                  wildcard bins re_data_zeros_4 = {8'b????0???};
                                  wildcard bins re_data_zeros_3 = {8'b?????0??};
                                  wildcard bins re_data_zeros_2 = {8'b??????0?};
                                  wildcard bins re_data_zeros_1 = {8'b???????0};
    							}
    
    cp1Xcp2: cross cp1,cp2;// {bins writeXaddr = binsof(cp1.write_com);
                           // bins readXaddr = binsof(cp1.read_com);}
    
    WRITE_B2B_INCR_WADDR: coverpoint write_b2b_incr_addr {option.at_least = 7;
                                                          bins write_b2b_incr_addr_high = {1};
                                                          ignore_bins write_b2b_incr_addr_low = {0};
                                                         }
    WRITE_B2B_RANDOM_WADDR: coverpoint write_b2b_random_addr {option.at_least = 7;
                                                              bins write_b2b_random_addr_high = {1};
                                                              ignore_bins write_b2b_random_addr_low = {0};
                                                             }
    WRITE_FOLLWED_BY_READ_INCR_ADDR: coverpoint write_follwed_by_read_incr_addr {option.at_least = 7;
                                                                                  bins write_follwed_by_read_incr_addr_high = {1};
                                                                                  ignore_bins write_follwed_by_read_incr_addr_low = {0};
                                                                                 }
    
    WRITE_FOLLWED_BY_READ_RANDOM_ADDR: coverpoint write_follwed_by_read_random_addr {option.at_least = 7;
                                                                                  bins write_follwed_by_read_random_addr_high = {1};
                                                                                  ignore_bins write_follwed_by_read_random_addr_low = {0};
                                                                                 }
    WRITE_TO_EVEN_LOCATION: coverpoint Write_to_even_location {option.at_least = 7;
                                                               bins Write_to_even_location_high  = {1};
                                                               ignore_bins Write_to_even_location_low  = {0};}
    
    WRITE_TO_ODD_LOCATION: coverpoint Write_to_odd_location {option.at_least = 7;
                                                               bins Write_to_odd_location_high  = {1};
                                                               ignore_bins Write_to_odd_location_low  = {0};}
  endgroup
    
  function new();
    cg = new();
  endfunction

//////////write_b2b_incr_addr////////////////////////
  function void f_write_b2b_incr_addr();
      if((q1[q1.size()-2].addr - q1[q1.size()-1].addr) == 1)begin
        write_b2b_incr_addr = 1;
        $display("\n",$time," Coverage Functional f_write_b2b_incr_addr HIT : %0d, q1[q1.size()-2].addr = %0d, q1[q1.size()-1.addr = %0d", write_b2b_incr_addr,q1[q1.size()-2].addr, q1[q1.size()-1].addr);
      end
       else begin
        write_b2b_incr_addr = 0;
         $display("\n",$time," Coverage Functional f_write_b2b_incr_addr: %0d q1[q1.size()-2].addr = %0d, q1[q1.size()-1.addr = %0d", write_b2b_incr_addr,q1[q1.size()-2].addr, q1[q1.size()-1].addr);
      end
      cg.sample();
    $display($time, " Coverage of WRITE_B2B_INCR_WADDR = %0.2f%%, q1[q1.size()-2].addr = %0d, q1[q1.size()-1.addr = %0d \n",cg.WRITE_B2B_INCR_WADDR.get_coverage(), q1[q1.size()-2].addr, q1[q1.size()-1].addr );
      q1.pop_back();
      write_b2b_incr_addr = 0;
  endfunction
  
/////////////////write_b2b_random_addr///////////////  
  function void f_write_b2b_random_addr();    
      if(q2[q2.size()-2].addr - q2[q2.size()-1].addr != 1)begin
        write_b2b_random_addr = 1;
        $display($time," Coverage Functional f_write_b2b_random_addr HIT: %0d, q2[q2.size()-2].addr = %0d, q2[q2.size()-1.addr = %0d", write_b2b_random_addr,q2[q2.size()-2].addr, q2[q2.size()-1].addr);
      end
      else begin
        write_b2b_random_addr = 0;
        $display($time," Coverage Functional f_write_b2b_random_addr: %0d, q2[q2.size()-2].addr = %0d, q2[q2.size()-1.addr = %0d", write_b2b_random_addr,q2[q2.size()-2].addr, q2[q2.size()-1].addr);
      end
      cg.sample();
      $display($time, " Coverage of WRITE_B2B_RANDOM_WADDR = %0.2f%%\n",cg.WRITE_B2B_RANDOM_WADDR.get_coverage()); 
      q2.pop_back();
      write_b2b_random_addr = 0;
  endfunction
  
////////////////write_follwed_by_read_incr_addr///////////////
  function void f_write_follwed_by_read_incr_addr();
    if((q3[q3.size()-2].addr - q3[q3.size()-1].addr) == 1)begin
      if(q3[q3.size()-2].w_r_com !== q3[q3.size()-1].w_r_com)begin
          write_follwed_by_read_incr_addr = 1;
        $display($time," Coverage Functional f_write_follwed_by_read_incr_addr HIT: %0d, q3[q3.size()-2].w_r_com = %0d, q3[q3.size()-1.w_r_com = %0d", write_follwed_by_read_incr_addr,q3[q3.size()-2].w_r_com, q3[q3.size()-1].w_r_com);
        end       
      else  begin
         write_follwed_by_read_incr_addr = 0;
        $display("\n",$time," Coverage Functional f_write_follwed_by_read_incr_addr NOT HIT: %0d q3[q3.size()-2].w_r_com = %0d, q3[q3.size()-1.w_r_com = %0d", write_follwed_by_read_incr_addr,q3[q3.size()-2].w_r_com, q3[q3.size()-1].w_r_com);
       end
      end
      cg.sample();        
    $display($time, " Coverage of WRITE_FOLLWED_BY_READ_INCR_ADDR = %0.2f%%, addr = %0d, w_r_com = %0d\n",cg.WRITE_FOLLWED_BY_READ_INCR_ADDR.get_coverage(), pkts.addr,pkts.w_r_com);
      q3.pop_back(); 
      write_follwed_by_read_incr_addr = 0;
  endfunction
  
////////////////write_follwed_by_read_random_addr///////////////
  function void f_write_follwed_by_read_random_addr();
    if((q4[q4.size()-2].addr - q4[q4.size()-1].addr) != 1 && (q4[q4.size()-2].addr != q4[q4.size()-1].addr))begin
      if(q4[q4.size()-2].w_r_com != q4[q4.size()-1].w_r_com)begin
          write_follwed_by_read_random_addr = 1;
        $display($time," Coverage Functional f_write_follwed_by_read_random_addr HIT: %0d, q4[q4.size()-2].addr = %0d, q4[q4.size()-1.addr = %0d, q4[q4.size()-2].w_r_com = %0d, q4[q4.size()-1.w_r_com = %0d", write_follwed_by_read_random_addr,q4[q4.size()-2].addr, q4[q4.size()-1].addr, q4[q4.size()-2].w_r_com, q4[q4.size()-1].w_r_com);
        end       
      else  begin
        write_follwed_by_read_random_addr= 0;
        $display($time," Coverage Functional f_write_follwed_by_read_random_addr NOT HIT: %0d, q4[q4.size()-2].addr = %0d, q4[q4.size()-1.addr = %0d, q4[q4.size()-2].w_r_com = %0d, q4[q4.size()-1.w_r_com = %0d", write_follwed_by_read_random_addr,q4[q4.size()-2].addr, q4[q4.size()-1].addr, q4[q4.size()-2].w_r_com, q4[q4.size()-1].w_r_com);
       end
      end
      cg.sample();        
      $display($time, " Coverage of WRITE_FOLLWED_BY_READ_RANDOM_ADDR = %0.2f%%\n",cg.WRITE_FOLLWED_BY_READ_RANDOM_ADDR.get_coverage());
      q4.pop_back();
      write_follwed_by_read_random_addr= 0;
  endfunction
  
/////////////////////////Write to even location//////////////////////////////////
  function void f_Write_to_even_location();
    if(pkts.w_r_com == 1)begin
      if(pkts.addr%2 == 0)begin
        Write_to_even_location = 1;
        $display($time," Coverage Functional f_Write_to_even_location HIT: %0d , pkts.addr = %0d, pkts.w_r_com = %0d",Write_to_even_location, pkts.addr, pkts.w_r_com);
      end
      else begin
        Write_to_even_location = 0;
        $display($time," Coverage Functional f_Write_to_even_location: %0d , pkts.addr = %0d, pkts.w_r_com = %0d",Write_to_even_location, pkts.addr, pkts.w_r_com);
      end
    end
    cg.sample();
    $display($time, " Coverage of WRITE_TO_EVEN_LOCATION = %0.2f%%\n",cg.WRITE_TO_EVEN_LOCATION.get_coverage());
  endfunction

  /////////////////////////Write to odd location//////////////////////////////////
  function void f_Write_to_odd_location();
    if(pkts.w_r_com == 1)begin
      if(pkts.addr%2 != 0)begin
        Write_to_odd_location = 1;
        $display($time," Coverage Functional f_Write_to_odd_location HIT: %0d , pkts.addr = %0d, pkts.w_r_com = %0d",Write_to_odd_location, pkts.addr, pkts.w_r_com);//, q2[q2.size()-2].addr = %0d, q2[q2.size()-1.addr = %0d", Write_to_even_location,q2[q2.size()-2].addr, q2[q2.size()-1].addr);
      end
      else begin
        Write_to_odd_location = 0;
        $display($time," Coverage Functional f_Write_to_odd_location: %0d , pkts.addr = %0d, pkts.w_r_com = %0d",Write_to_odd_location, pkts.addr, pkts.w_r_com);
      end
    end
    cg.sample();      
    $display($time, " Coverage of WRITE_TO_ODD_LOCATION = %0.2f%%\n",cg.WRITE_TO_ODD_LOCATION.get_coverage());
  endfunction
  
  function void build();
    $display($time , " FUNCTIONAL_COVERAGE TRIGGERED");
    cvg_mb = new();
    $display($time , " FUNCTIONAL_COVERAGE EXIT");
  endfunction
  
  task run();
    forever begin
      cvg_mb.get(pkts);        
      if(pkts.w_r_com == 1)q1.push_front(pkts); 
      if(pkts.w_r_com == 1)q2.push_front(pkts); 
      q3.push_front(pkts); 
      q4.push_front(pkts); 
      
      /*if(q1.size > 2)begin
         f_write_b2b_incr_addr();     //write_b2b_incr_addr
         //cg.sample();
      end
      
      if(q2.size > 2)begin
         f_write_b2b_random_addr();   ///write_b2b_random_addr
         //cg.sample();
      end*/
      
      /*if(q3.size > 2)begin
        f_write_follwed_by_read_incr_addr();
        //cg.sample();
      end*/
      
      if(q4.size > 2)begin
        f_write_follwed_by_read_random_addr();
        //cg.sample();
      end    
      
      f_Write_to_even_location();
      cg.sample;

      
      //f_Write_to_odd_location();
      //cg.sample;

      
      // Printing elements inside the queue
      /*foreach (q1[i]) begin
        $display($time,"  q1 Element[%0d]: w_r_com = %0d, addr = %0d", i, q1[i].w_r_com, q1[i].addr);
      end
      
      
      // Printing elements inside the queue
      foreach (q2[i]) begin
        $display($time,"  q2 Element[%0d]: w_r_com = %0d, addr = %0d", i, q2[i].w_r_com, q2[i].addr);
      end*/
 
      $display("\n",$time, " Coverage of w_r_com = %0.2f%%",cg.cp1.get_coverage());
      $display($time, " Coverage of addr = %0.2f%%",cg.cp2.get_coverage());
      $display($time, " Coverage of wr_data = %0.2f%%",cg.cp3.get_coverage());
      $display($time, " Coverage of re_data = %0.2f%%",cg.cp4.get_coverage());
      $display($time, " Coverage of cross = %0.2f%%",cg.cp1Xcp2.get_coverage());
      $display($time, " OVERALL Coverage = %0.2f%%\n",cg.get_coverage());       
    end
  endtask    
endclass
  
    
/////////////////////// Environment ////////////////////////////////////////////////////////
    
class environment;
  generator g0;
  monitor m0;
  driver d0;
  scoreboard s0;
  fun_coverage f0;
  
  mailbox #(transaction)drv_mb;
  mailbox #(transaction)scb_mb;
  mailbox #(transaction)cvg_mb;
  
  virtual interface_if vif;
  event drv_done;
  event reset_captured;
  event reset_triggered;
  
  function build();
    //$display($time," ENV NEW METHOD TRIGGERED");
    g0 = new();
    m0 = new();
    d0 = new();
    s0 = new();
    f0 = new();
    
    g0.build();
    m0.build();
    d0.build();
    s0.build();
    f0.build();
    
    
    drv_mb = new;
    scb_mb = new;
    cvg_mb = new;
    //$display($time," ENV NEW METHOD EXIT");
  endfunction
  
  
 virtual function void connect();
    d0.drv_mb = drv_mb;
    g0.drv_mb = drv_mb;
    m0.scb_mb = scb_mb;
    s0.scb_mb = scb_mb;
    m0.cvg_mb = cvg_mb;
    f0.cvg_mb = cvg_mb;
    
    d0.drv_done = drv_done;
    g0.drv_done = drv_done;
   
    m0.reset_triggered = reset_captured ;
    s0.reset_captured = reset_captured;
        
    d0.vif = vif;
    m0.vif = vif;    
  endfunction
  
  virtual task run();
    fork
      d0.run();
      m0.run();
      g0.run();
      s0.run();
      f0.run();
    join_any
  endtask
     
endclass
    
/////////////// Test ////////////////////////////////////////////
    
class test;  
  environment e0; 
  
  virtual function void  build();
    //$display($time , " Test TRIGGERED");
    e0 = new();
    e0.build();
    //$display($time , " TEST EXIT");
  endfunction
  
  virtual function void  connect();
    e0.connect();
  endfunction
  
  virtual task run();
    e0.run();
  endtask  
endclass

class test1 extends test;   //TEST FOR WRITE FIRST READ NEXT
 write_first_read_next c1;
  
  function void build();
    super.build();
    c1 = new();
  endfunction
  
  function void connect();
    e0.g0 = c1;
    e0.connect();
  endfunction  
endclass
    
class test2 extends test;   //WRITE ONLY INCREMENTAL ADDRESS
  write_only_incremental_addr c2;
    
  function void build();
    super.build();
    c2 = new();
  endfunction
  
  function void  connect();
    e0.g0 = c2;
    e0.connect();
  endfunction  
endclass
    
class test3 extends test;   //WRITE READ BACK TO BACK WITH RANDOM ADDRESS
  write_read_b2b c3;
    
  function void  build();
    super.build();
    c3 = new();
  endfunction
  
  function void  connect();
    e0.g0 = c3;
    e0.connect();
  endfunction  
endclass
    
class test4 extends test;   // WRITE READ FROM EVEN LOCATIONS
  write_read_even_loc c4;
    
  function void  build();
    super.build();
    c4 = new();
  endfunction
  
  function void  connect();
    e0.g0 = c4;
    e0.connect();
  endfunction  
endclass 
    
class test5 extends test;   // WRITE ONLY RANDOM ADDRESS
  write_only_random_addr c5;
    
  function void  build();
    super.build();
    c5 = new();
  endfunction
  
  function void  connect();
    e0.g0 = c5;
    e0.connect();
  endfunction  
endclass 
    
class test6 extends test;   // READ ONLY INCREMENTAL ADDRESS
  read_only_incremental_addr c6;
    
  function void  build();
    super.build();
    c6 = new();
  endfunction
  
 function void  connect();
    e0.g0 = c6;
    e0.connect();
  endfunction  
endclass
    
class test7 extends test;   //WRITE READ BACK TO BACK WITH INCREMENTAL ADDRESS
 write_read_b2b_with_incremental_addr c7;
    
  function void  build();
    super.build();
    c7 = new();
  endfunction
  
  function void  connect();
    e0.g0 = c7;
    e0.connect();
  endfunction  
endclass
    
class test8 extends test;   //WRITE TO EVEN AND READ FROM ODD LOCATION
 write_even_and_read_odd_loc c8;
    
  function void  build();
    super.build();
    c8 = new();
  endfunction
  
  virtual function void  connect();
    e0.g0 = c8;
    e0.connect();
  endfunction  
endclass
    
class test9 extends test;   //WRITE TO ODD AND READ FROM EVEN LOCATION
 write_odd_and_read_even_loc c9;
    
  function void  build();
    super.build();
    c9 = new();
  endfunction
  
 function void  connect();
    e0.g0 = c9;
    e0.connect();
  endfunction  
endclass
    
class test10 extends test;   //TEST FOR WRITE FIRST HALF MEM READ NEXT
 write_first_half_mem_read_next c10;
  
  function void  build();
    super.build();
    c10 = new();
  endfunction
  
  virtual function void  connect();
    e0.g0 = c10;
    e0.connect();
    
  endfunction  
endclass
    
class test11_for_driver extends test;   //CALL BACK
 driver1 c11;
  
  function  void build();
    super.build();
    c11 = new();
  endfunction
  
  virtual function void  connect();
    e0.d0 = c11;
    e0.connect();    
  endfunction  
endclass
    
class test12 extends test;   //WRITE SECOND HALF MEM AND READ NEXT
 write_second_half_mem_read_next c12;
  
  function void  build();
    super.build();
    c12 = new();
  endfunction
  
  virtual function void  connect();
    e0.g0 = c12;
    e0.connect();    
  endfunction  
endclass
    
    
///////////////// Testbench Top ////////////////////////////////////
module top();
  reg clk;
  test t0;
  test1 t1;
  test2 t2;
  test3 t3;
  test4 t4;
  test5 t5;
  test6 t6;
  test7 t7;
  test8 t8;
  test9 t9;
  test10 t10;
  test11_for_driver t11;
  test12 t12;
  
  
  always #10 clk = ~clk;
  interface_if _if(clk);
   
  SRAM dut (_if.DUT);
  
  task initialization();
    /*_if.MOD1.Design_cb.addr<= 0;
    _if.MOD1.Design_cb.wr_data<= 0;*/
    //_if.w_r_com <= 0;
    _if.addr<= 0;
    _if.wr_data<= 0;
  endtask
 
  task reset_mode();    
     /*_if.MOD1.Design_cb.rst<= 0;
    initialization();
    repeat(3)@(_if.MOD1.Design_cb);
    _if.MOD1.Design_cb.rst <= 1;
    repeat(3)@(_if.MOD1.Design_cb);*/
    _if.rst <= 0;
    initialization();
    repeat(3)@(posedge clk);
    _if.rst <= 1;
    repeat(3)@(posedge clk);
  endtask
  
  task treads();
    t0.build();
    t0.e0.vif = _if;
    t0.connect();
    t0.run();
  endtask
  
  initial begin    
    $dumpvars;
    $dumpfile("dump.vcd");
    clk <= 0;
    reset_mode();
    t0 = new();
    t1 = new();
    t2 = new();
    t3 = new();
    t4 = new();
    t5 = new();
    t6 = new();
    t7 = new();
    t8 = new();
    t9 = new();
    t10 = new();
    t11 = new();
    t12 = new();
   
    /*t0 = t1;         //WRITE FIRST READ NEXT
    treads(); 
    reset_mode();*/
    
    /*t0 = t2;        //WRITE ONLY INCREMENTAL ADDRESS   
    treads(); 
    reset_mode();*/
    
    t0 = t3;        //WRITE READ BACK TO BACK WITH RANDOM ADDRESS   // WRITE FOLLWED BY READ
    treads(); 
    reset_mode();
    
    /*t0 = t4;        //WRITE READ FROM EVEN LOCATIONS
    treads(); 
    reset_mode();*/
    
    /*t0 = t5;      //WRITE ONLY RANDOM ADDRESS
    treads(); 
    reset_mode();*/
    
    /*t0 = t6;      //READ ONLY INCREMENTAL ADDRESS
    treads(); 
    reset_mode();*/
    
    /*t0 = t7;        //WRITE READ BACK TO BACK WITH INCREMENTAL ADDRESS // WRITE FOLLWED BY READ
    treads(); 
    reset_mode();*/
    
    /*t0 = t8;         //WRITE TO EVEN AND READ FROM ODD LOCATION WITH INCREMENTAL ADDRESS
    treads(); 
    reset_mode();*/
    
    /*t0 = t9;         //WRITE TO ODD AND READ FROM EVEN LOCATION    
    treads(); 
    reset_mode();*/
    
    /*t0 = t10;          //WRITE FIRST HALF MEM READ NEXT    
    treads(); 
    reset_mode();*/
    
    /*t0 = new t11;        //CALL BACK
    treads(); 
    reset_mode();
    $display($time, " DIAPLAYING t11 = %0p",t11);*/
    
    /*t0 = t12;         //WRITE SECOND HALF MEM AND READ NEXT
    treads(); 
    reset_mode();*/
    
    
    
    #100 $finish;
  end
    
endmodule
