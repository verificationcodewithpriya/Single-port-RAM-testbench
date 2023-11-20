// Code your design here
///////////// Design /////////////////////////////////////////////

module SRAM #(parameter M=3,parameter N=8) //M=address width N=Data width
  (interface_if ifh);  
  reg[0:N-1]mem[0:(2**M)-1];//Representing memory with 2**M rows and N columns
  
  always @(posedge ifh.clk)
    begin
      if(ifh.rst==0)
        begin
          for(int i=0; i<2**M; i=i+1) mem[i] <= 'h0;
           ifh.re_data <= 'h0;
        end
      
      else if(ifh.rst==1)begin
        if(ifh.w_r_com == 1)begin
          mem[ifh.addr]<=ifh.wr_data;
        end
        else if(ifh.w_r_com == 0)begin
              ifh.re_data <= mem[ifh.addr];
        end
        else
            ifh.re_data <= ifh.re_data;
      end
   end  
endmodule