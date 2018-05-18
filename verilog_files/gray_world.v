////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 17/05/18
// Design Name: gray_world algorithm
////////////////////////////////////////////////////////////////////////////////

module gray_world#(
parameter Nline    = 349, //  amount of pixels in line
parameter Nscreen  = 349) //  amount of lines  in frame
(
    input  clk,
    input  rst,
// slave axi stream interface   
    input  s_axis_tvalid,
    input  s_axis_tuser,
    input  s_axis_tlast,
    input  [23 : 0] s_axis_tdata,
// master axi stream interface    
    output m_axis_tvalid,
    output m_axis_tuser,
    output m_axis_tlast,
    output [23 : 0] m_axis_tdata
    );
	
	reg  [11 : 0] line_counter;		// Lines Counter
	wire EOF; 						// End Of Frame 
	reg  [47 : 0] AccumR, AccumG, AccumB; 
	reg  [47 : 0] AccumR_out, AccumG_out, AccumB_out;
	
	wire [7   : 0] quotR, quotG, quotB;
	wire [7   : 0] quotAve;
	reg  [15  : 0] sum_Ip, sum_IIp;
	
	reg  [15  : 0] multR, multG, multB;
	
	wire [15  : 0] r_stream, g_stream, b_stream;
	

		function integer multiply;
			input integer a, b;
			multiply = a * b;
		endfunction
		
	localparam Nmult = multiply(Nline, Nscreen);
	
	/*************************************************************/
	/************** average for RGB channels ********************/
		div_uu	#(48) devR   (.clk(clk), .ena(1'b1), .z(AccumR_out), .d(Nmult), .q(quotR),   .s(), .div0(), .ovf());
		div_uu	#(48) devG   (.clk(clk), .ena(1'b1), .z(AccumG_out), .d(Nmult), .q(quotG),   .s(), .div0(), .ovf());
		div_uu	#(48) devB   (.clk(clk), .ena(1'b1), .z(AccumB_out), .d(Nmult), .q(quotB),   .s(), .div0(), .ovf());
		
		div_uu	#(16)  devAvr (.clk(clk), .ena(1'b1), .z(sum_IIp),    .d(8'h03),  .q(quotAve), .s(), .div0(), .ovf());


	always@(posedge clk) begin
		if(rst)begin
			sum_Ip  <= 0;
		    sum_IIp <= 0;
		end else begin
		    sum_Ip  <= quotR  + quotG;
			sum_IIp <= sum_Ip + quotB;	
		end // rst	
	end     // always
	
	/**********************************************************/
	/*********** Rm = R*Ave  *********************************/
	always@(posedge clk) begin
		if(rst)begin
			multR <= 0;
			multG <= 0;
		    multB <= 0;
		end else if (s_axis_tvalid) begin
		    multR <= s_axis_tdata[23 : 16] * quotAve;
			multG <= s_axis_tdata[15 :  8] * quotAve;
		    multB <= s_axis_tdata[7  :  0] * quotAve;
		end		// rst 
	end   		// always
	
	/**********************************************************/
	/*********** Rm = R*Ave/R_ave  ****************************/
	div_uu	#(16) devR_R   (.clk(clk), .ena(1'b1), .z(multR), .d(quotR), .q(r_stream),   .s(), .div0(), .ovf());
	div_uu	#(16) devG_G   (.clk(clk), .ena(1'b1), .z(multG), .d(quotG), .q(g_stream),   .s(), .div0(), .ovf());
	div_uu	#(16) devB_B   (.clk(clk), .ena(1'b1), .z(multB), .d(quotB), .q(b_stream),   .s(), .div0(), .ovf());
		
	/*********************************************************************************/
	/************************* calculating EOF signal *******************************/
	always@(posedge clk) begin
		if(rst)begin	               
				line_counter <= 0;
		end else if (s_axis_tlast) begin	
			if(line_counter == Nscreen - 1)begin
				line_counter <= 0;
			end else begin
				line_counter <= line_counter + 1;
			end // line_counter
		end     // rst
	end         // always
								
	assign EOF = (s_axis_tlast & line_counter == Nscreen - 1)? 1'b1: 1'b0;
	
	
	/*********************************************************************************/
	/******************* accumulate every RGB channel per frame**********************/
	always@(posedge clk)begin
		if(rst) begin 
			AccumR     <= 0;
			AccumR_out <= 0;
			
			AccumG     <= 0;
			AccumG_out <= 0;
			
			AccumB     <= 0;
			AccumB_out <= 0;
		end else if (s_axis_tvalid) begin 
			if(EOF)begin
			
				AccumR_out <= AccumR + s_axis_tdata[23 : 16];
				AccumR     <= 0;
				
				AccumG_out <= AccumG + s_axis_tdata[15 :  8];
				AccumG     <= 0;
				
				AccumB_out <= AccumB + s_axis_tdata[7  :  0];
				AccumB     <= 0;
				
			end else if (s_axis_tuser) begin
			
			    AccumR <= s_axis_tdata[23 : 16];
				
				AccumG <= s_axis_tdata[15 :  8];
				
				AccumB <= s_axis_tdata[7  : 0 ];
			
			end else begin
			
				AccumR <= AccumR + s_axis_tdata[23 : 16];
				
				AccumG <= AccumG + s_axis_tdata[15 :  8];
				
				AccumB <= AccumB + s_axis_tdata[7  : 0 ];
			end
		end  // rst
	end      // always
	
	reg [10 : 0] s_axis_tvalid_shift; // piplined s_axis_tvalid
	always @(posedge clk) 
	if(rst)s_axis_tvalid_shift <= 0;
	else   s_axis_tvalid_shift <= {s_axis_tvalid_shift[9 : 0], s_axis_tvalid};
	 
	reg [10 : 0] s_axis_tlast_shift; // piplined s_axis_tlast
	always @(posedge clk) 
	if(rst)s_axis_tlast_shift <= 0;
	else   s_axis_tlast_shift <= {s_axis_tlast_shift[9 : 0], s_axis_tlast};
	 
	reg [10 : 0] s_axis_tuser_shift; // piplined s_axis_tuser
	always @(posedge clk) 
	if(rst)s_axis_tuser_shift <= 0;
	else   s_axis_tuser_shift <= {s_axis_tuser_shift[9 : 0], s_axis_tuser};	 
	 
	 // piplined axi stream interface
	assign m_axis_tvalid   = s_axis_tvalid_shift[9];
	assign m_axis_tlast    = s_axis_tlast_shift [9];
	assign m_axis_tuser    = s_axis_tuser_shift [9];
	
	
	assign m_axis_tdata = {r_stream[7 : 0], g_stream[7 : 0], b_stream[7 : 0]};
	
	
			
			
	
	
	
	
	
	
endmodule
