`timescale  1ns / 1ps

module FP_tb2;

reg rst;
reg clk;

wire READY;
reg rw;
reg [1:0] dest;
reg [1:0] transID;
reg [4:0] OPCODE;
reg [7:0] WDATA;
wire [3:0] state;
wire [3:0] count; // temporary
reg [7:0] task_num;

localparam CLK_PERIOD = 20;


//OPCODE bit0:rw (0 for read, 1 for write), 
//bit1-2: IO/ALU/Memory (0,1,2)
//bit3-4: 4 different transaction ids

controller c(.OPCODE(OPCODE), .READY(READY), .WDATA(WDATA), .a_rst(rst), .state(state), .clk(clk), .count(count), .task_num(task_num));

initial begin : CLK_GENERATOR
    clk = 0;
    forever begin
        #(CLK_PERIOD / 2) clk = ~clk;
    end
end

initial begin
    rst = 1;
    #(2 * CLK_PERIOD) rst = 0;

    rw = {$random} %2;
    dest = {$random} %3;
    transID = {$random} %4;
    OPCODE = {transID,dest,rw};
    WDATA = {$random} %256;
    task_num = 0;
    //$display("%b, %b",OPCODE,WDATA);
end

always @(posedge clk) begin
    if(READY) begin
        rw = {$random} %2;
        dest = {$random} %3;
        transID = {$random} %4;
        OPCODE = {transID,dest,rw};
        WDATA = {$random} %256;
        task_num = task_num + 1;
        //$display("%b, %b",OPCODE,WDATA);
    end
end

endmodule
