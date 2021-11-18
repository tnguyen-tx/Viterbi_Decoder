`timescale 1ns / 1ps

module pmu(
clk,
rst,
dis,
dis_path,
path_out,
dis_out
    );

parameter r=2;
parameter K=3;

parameter ns=1<<(K-1); // ns = 4.
parameter mask=ns-1; // mask = 3 = 'b11.

input clk,rst;

input[(1<<(K-1))*8-1:0] dis;//...[second state curr dis 15:8][first state curr dis 7:0]
input[(1<<(K-1))*2*r-1:0] dis_path; // length: 16. represents 8 hamming distances.
output reg[(1<<(K-1))*K-1:0] path_out;
output reg[(1<<(K-1))*8-1:0] dis_out;

wire[(1<<(K-1))*8-1:0] dis_outw;
wire[(1<<(K-1))*K-1:0] path_outw; // length = 12.

genvar gi;
wire [(1<<(K-1))-1:0] path_sele;

generate
    for(gi=0;gi<(1<<(K-1));gi=gi+1)begin : gencomp // gi from 0 to 3.
        comp #(.r(r)) c0(
        dis[8*(((gi<<1)&mask)+1)-1:8*((gi<<1)&mask)], // dis0.
        dis_path[2*r*(((gi<<1)&mask))+r*(gi>>(K-2))+r-1:2*r*((gi<<1)&mask)+r*(gi>>(K-2))], // path0.
        dis[8*(((gi<<1)&mask)+1+1)-1:8*(((gi<<1)&mask)+1)], // dis1.
        dis_path[2*r*(((gi<<1)&mask)+1)+r*(gi>>(K-2))+r-1:2*r*(((gi<<1)&mask)+1)+r*(gi>>(K-2))], // path1.
        path_sele[gi], // path_out.
        dis_outw[8*(gi+1)-1:8*gi]); // dis_out.
        assign path_outw[K*(gi+1)-1:K*gi]=(((gi>>(K-2))<<(K-1))|(((gi<<1)&mask)+path_sele[gi]));//path_sele[gi]?:(((gi>>(K-1))<<K)|((gi<<1)&mask));
    end
endgenerate

always@(posedge clk or negedge rst)begin
    if(~rst)begin
        dis_out<=0;
        path_out<=0;
    end
    else begin
        dis_out<=dis_outw;
        path_out<=path_outw;
    end
end

endmodule
