`timescale 1ns / 1ps
`include "bmu.v"
`include "pmu.v"
module viterbi(
clk,
rst,
codein, // input: code word; length: lenin = 10.
state_out, // input: state; length: 2^(k-1)*2*r = 16.
codeout, // output: decoded message; length: lenout = 5.
finish // output: 1 bit flag signal.
    );

parameter r=2; // Number of parity bits in each cycle.
parameter K=3; // Max convolutional window size.
parameter lenin=10; // Length of the input code word.
parameter lenout=5; // Length of the output decoded message.

parameter maskcode=(1<<r)-1; // 11.
parameter maskstate=(1<<(K-1))-1; // 11.
parameter maskpath=(1<<K)-1; // 111. take lower 3 bits.

input clk,rst;
input[lenin-1:0] codein;
input[(1<<(K-1))*2*r-1:0] state_out; // input: state; length: 2^(k-1)*2*r = 16.
output reg[lenout-1:0] codeout;
output reg finish;

reg[r-1:0] code; // code word in each cycle.
wire[(1<<(K-1))*2*r-1:0] dis_path_out; // length: 16.

// Branch Metric Unit
bmu #(.r(r),.K(K)) b0(
clk,
rst,
code,
state_out,
dis_path_out
    );

reg[lenout*K-1:0] paths[(1<<(K-1))-1:0]; //each K: [input dir 0/1: 1bit][last state: (K-1)bits]
// paths: 5*3 * 4

reg[(1<<(K-1))*8-1:0] dis[1:0]; // 4*8
wire[(1<<(K-1))*K-1:0] pmu_path_out;
wire[(1<<(K-1))*8-1:0] pmu_dis_out;

// Path Metric Unit
pmu #(.r(r),.K(K)) p0(
clk,
rst,
dis[1],
dis_path_out,
pmu_path_out,
pmu_dis_out
    );

reg[1:0] counter;
reg[2:0] code_idx;

parameter eo1_round=3; 	//end of 1 round, counter = 7
reg[7:0] smaller_num1;
reg[7:0] smaller_num2;
reg[7:0] smallest;
reg[1:0] pos1;
reg[1:0] pos2;
reg[1:0] pos;
reg[1:0] backtrack_pos;
reg[2:0] backtrack_cnt;

//comparator to choose the shortest path
	always @(*) begin
		if (dis[0][31:24] > dis[0][23:16]) begin
			pos1 = 2;
			smaller_num1 = dis[0][23:16];
			end
		else begin 
			pos1 = 3;
			smaller_num1 = dis[0][31:24];
		end
		if (dis[0][15:8] < dis[0][7:0]) begin
			pos2 = 1;
			smaller_num2 = dis[0][15:8];
		end
		else begin
			pos2 = 0;
			smaller_num2 = dis[0][7:0];
		end
		if (smaller_num1 < smaller_num2) begin 
			pos = pos1;
			smallest = smaller_num1;
		end
		else begin
			pos = pos2;
			smallest = smaller_num2;
		end
	end

	always@(posedge clk or negedge rst)begin
		if(~rst)begin
			// Start of your code
			code <=0;
			codeout <=0;
			finish <=0;
			dis[1] <= 32'hffffff00;
			dis[0] <= 32'hffffff00;
			paths[3] <=0;
			paths[2] <=0;
			paths[1] <=0;
			paths[0] <=0;
			counter <=0;
			code_idx <= 0;
			backtrack_cnt <=0;
			backtrack_pos <=0;
			// End of your code
		end
		else begin
			// Start of your code
			if (code_idx < 5) begin
				counter <= counter +1;
				if (counter == 0) begin
				code <= codein[(5-code_idx)*2-1 -:2]; 
				dis[1] <= dis[0];
				end
				if (counter == eo1_round) begin
				code_idx <= code_idx +1;
				dis[0] <= pmu_dis_out;
				paths[3][(5-code_idx)*3-1 -: 3] <= pmu_path_out[11:9];
				paths[2][(5-code_idx)*3-1 -: 3] <= pmu_path_out[8:6];
				paths[1][(5-code_idx)*3-1 -: 3] <= pmu_path_out[5:3];
				paths[0][(5-code_idx)*3-1 -: 3] <= pmu_path_out[2:0];
				end
			end
			else begin
				//backtrack
				if (backtrack_cnt == 0) begin
					backtrack_cnt <= backtrack_cnt+1;
					backtrack_pos <= pos;
				end
				else if (backtrack_cnt <6) begin
					backtrack_cnt <= backtrack_cnt +1;
					case (backtrack_pos)
						2'b00: begin
							if (paths[0][backtrack_cnt*3-3] == 0) begin
								codeout[backtrack_cnt-1] <= 0;	
								backtrack_pos <= 0;
							end
							else begin
								codeout[backtrack_cnt-1] <= 0;
								backtrack_pos <=1;
							end
						end
						2'b01: begin
							if (paths[1][backtrack_cnt*3-3] == 0) begin
								codeout[backtrack_cnt-1] <= 0;
								backtrack_pos <= 2;	
							end
							else begin 
								codeout[backtrack_cnt-1] <= 0;
								backtrack_pos <= 3;
							end
						end
						2'b10: begin
							if (paths[2][(backtrack_cnt)*3-3] == 0) begin
								codeout[backtrack_cnt-1] <= 1;	
								backtrack_pos <= 0;
							end
							else begin 
								codeout[backtrack_cnt-1] <= 1;
								backtrack_pos <= 1;
							end
						end
						2'b11: begin
							if (paths[3][(backtrack_cnt)*3-3] == 0) begin
								codeout[backtrack_cnt-1] <= 1;	
								backtrack_pos <= 2;
							end
							else begin 
								codeout[backtrack_cnt-1] <= 1;
								backtrack_pos <= 3;
							end
						end
					endcase
				end
				else begin
					finish <= 1;
				end
			end
			// End of your code
		end
	end

endmodule
