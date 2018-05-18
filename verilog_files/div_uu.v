/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Non-restoring unsigned divider                             ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: div_uu.v,v 1.3 2003-09-17 13:08:53 rherveille Exp $
//
//  $Date: 2003-09-17 13:08:53 $
//  $Revision: 1.3 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.2  2002/10/31 13:54:58  rherveille
//               Fixed a bug in the remainder output of div_su.v
//
//               Revision 1.1.1.1  2002/10/29 20:29:10  rherveille
//
//
//

//synopsys translate_off
`timescale 1ns / 1ps
//synopsys translate_on

module div_uu	#(
																	parameter  DIVIDENT_W  = 16
															)
															(clk, ena, z, d, q, s, div0, ovf);

	//
	// parameters
	//
	parameter DIVISOR_W = DIVIDENT_W /2;
	
	//
	// inputs & outputs
	//
	input clk;               // system clock
	input ena;               // clock enable

	input  [DIVIDENT_W -1:0] z; // divident
	input  [DIVISOR_W -1:0] d; // divisor
	output [DIVISOR_W -1:0] q; // quotient
	output [DIVISOR_W -1:0] s; // remainder
	output div0;
	output ovf;
	reg [DIVISOR_W-1:0] q;
	reg [DIVISOR_W-1:0] s;
	reg div0;
	reg ovf;

	//	
	// functions
	//
	function [DIVIDENT_W:0] gen_s;
		input [DIVIDENT_W:0] si;
		input [DIVIDENT_W:0] di;
	begin
	  if(si[DIVIDENT_W])
	    gen_s = {si[DIVIDENT_W-1:0], 1'b0} + di;
	  else
	    gen_s = {si[DIVIDENT_W-1:0], 1'b0} - di;
	end
	endfunction

	function [DIVISOR_W-1:0] gen_q;
		input [DIVISOR_W-1:0] qi;
		input [DIVIDENT_W:0] si;
	begin
	  gen_q = {qi[DIVISOR_W-2:0], ~si[DIVIDENT_W]};
	end
	endfunction

	function [DIVISOR_W-1:0] assign_s;
		input [DIVIDENT_W:0] si;
		input [DIVIDENT_W:0] di;
		reg [DIVIDENT_W:0] tmp;
	begin
	  if(si[DIVIDENT_W])
	    tmp = si + di;
	  else
	    tmp = si;

	  assign_s = tmp[DIVIDENT_W-1:DIVIDENT_W-DIVISOR_W];
	end
	endfunction

	//
	// variables
	//
	reg [DIVISOR_W-1:0] q_pipe  [DIVISOR_W-1:0];
	reg [DIVIDENT_W:0] s_pipe  [DIVISOR_W:0];
	reg [DIVIDENT_W:0] d_pipe  [DIVISOR_W:0];

	reg [DIVISOR_W:0] div0_pipe, ovf_pipe;
	//
	// perform parameter checks
	//
	// synopsys translate_off
	initial
	begin
	  if(DIVISOR_W !== DIVIDENT_W / 2)
	    $display("div.v parameter error (DIVISOR_W != DIVIDENT_W/2).");
	end
	// synopsys translate_on

	integer n0, n1, n2, n3;

	// generate divisor (d) pipe
	always @(d)
	  d_pipe[0] <= {1'b0, d, {(DIVIDENT_W-DIVISOR_W){1'b0}} };

	always @(posedge clk)
	  if(ena)
	    for(n0=1; n0 <= DIVISOR_W; n0=n0+1)
	       d_pipe[n0] <= #1 d_pipe[n0-1];

	// generate internal remainder pipe
	always @(z)
	  s_pipe[0] <= z;

	always @(posedge clk)
	  if(ena)
	    for(n1=1; n1 <= DIVISOR_W; n1=n1+1)
	       s_pipe[n1] <= #1 gen_s(s_pipe[n1-1], d_pipe[n1-1]);

	// generate quotient pipe
	always @(posedge clk)
	  q_pipe[0] <= #1 0;

	always @(posedge clk)
	  if(ena)
	    for(n2=1; n2 < DIVISOR_W; n2=n2+1)
	       q_pipe[n2] <= #1 gen_q(q_pipe[n2-1], s_pipe[n2]);


	// flags (divide_by_zero, overflow)
	always @(z or d)
	begin
	  ovf_pipe[0]  <= !(z[DIVIDENT_W-1:DIVISOR_W] < d);
	  div0_pipe[0] <= ~|d;
	end

	always @(posedge clk)
	  if(ena)
	    for(n3=1; n3 <= DIVISOR_W; n3=n3+1)
	    begin
	        ovf_pipe[n3] <= #1 ovf_pipe[n3-1];
	        div0_pipe[n3] <= #1 div0_pipe[n3-1];
	    end

	// assign outputs
	always @(posedge clk)
	  if(ena)
	    ovf <= #1 ovf_pipe[DIVISOR_W];

	always @(posedge clk)
	  if(ena)
	    div0 <= #1 div0_pipe[DIVISOR_W];

	always @(posedge clk)
	  if(ena)
	    q <= #1 gen_q(q_pipe[DIVISOR_W-1], s_pipe[DIVISOR_W]);

	always @(posedge clk)
	  if(ena)
	    s <= #1 assign_s(s_pipe[DIVISOR_W], d_pipe[DIVISOR_W]);
endmodule
