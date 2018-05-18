`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 17/05/18
// Design Name: gray_world_tb
////////////////////////////////////////////////////////////////////////////////
`include "parameters.vh"

module gray_world_tb( );

    reg clk;
    reg rst;
// slave axi stream interface   
    wire s_axis_tvalid;
    wire s_axis_tuser;
    wire s_axis_tlast;
    wire [23 : 0] s_axis_tdata;
// master axi stream interface    
    wire m_axis_tvalid;
    wire m_axis_tuser;
    wire m_axis_tlast;
    wire [23 : 0] m_axis_tdata;
    wire read_done;
    `define PERIOD 5      // 100 MHz clock 
	

	initial begin
    clk       <= 0;                              
    forever #(`PERIOD)  clk =  ! clk; 
    end
	 
	event reset_trigger;
    event reset_done_trigger; 


  frame_generator #(Nrows, Ncol) dutA (.clk(clk), .rst(rst), .SOF(s_axis_tuser), .EOL(s_axis_tlast), .DVAL(s_axis_tvalid), .read_done(read_done), .pixel(s_axis_tdata)); 
  
  gray_world #(Nrows, Ncol)dutB (.clk(clk),.rst(rst),.s_axis_tvalid(s_axis_tvalid),.s_axis_tuser(s_axis_tuser),.s_axis_tlast(s_axis_tlast),.s_axis_tdata(s_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),.m_axis_tuser(m_axis_tuser),.m_axis_tlast(m_axis_tlast),.m_axis_tdata(m_axis_tdata));    

    integer fidR, fidG, fidB;
  
   initial begin 
     rst       <= 1;
	 frame_rst <= 1;
         @ (reset_trigger); 
         @ (posedge clk) rst <= 1;             
         repeat (20) begin
         @ (posedge clk); 
         end 
         rst = 0;
          -> reset_done_trigger;
    end 
	
	
	initial  begin    
     fidR = $fopen("Rs_out.txt","w");
     fidG = $fopen("Gs_out.txt","w");
     fidB = $fopen("Bs_out.txt","w");

          -> reset_trigger;
          @(reset_done_trigger);  
			   @(m_axis_tvalid);
			   @ (posedge clk);
			   @(!m_axis_tvalid); // wait until 1st frame (empty) is passed by
		while(!read_done )begin
				if(m_axis_tvalid)begin
					  @ (posedge clk); 		
					  $fwrite(fidR, "%d \n", m_axis_tdata[23 : 16]);
					  $fwrite(fidG, "%d \n", m_axis_tdata[15 : 8]);
					  $fwrite(fidB, "%d \n", m_axis_tdata[7  : 0]);
				end else begin
					  @ (posedge clk);
				end		  
		end	
		  $fclose(fidR);
		  $fclose(fidG);
		  $fclose(fidB); 
		  
	       
      #50000 $stop;                                                
    end                
  
endmodule
