`timescale  1ns / 1ps

module controller
(

input [4:0] OPCODE,
output reg READY,
input [7:0] WDATA,
input a_rst,
output reg [3:0] state,
input clk,
output reg [3:0] count,
input [7:0] task_num
);
// main buffer
reg[20:0] buffer[15:0]; // {task_num(20:13),transID(12:11),dest(10:9),rw(8),WDATA(0:7)}
reg[3:0] rp; // used to first populate the FIFO
reg[3:0] wp;
reg[3:0] p0; // these are set when a tID FIFO is populated, moves on to next position when task is complete
reg[3:0] p1;
reg[3:0] p2;
reg[3:0] p3; 
reg[3:0] p_empty; // position of the unfilled buffer position to be filled
// use the wp or rp designated by the priority wires

// position FIFO for transaction ID 0
reg[3:0] buffer0[15:0];
reg[4:0] rp0;
reg[4:0] wp0;

// position FIFO for transaction ID 1
reg[3:0] buffer1[15:0];
reg[4:0] rp1;
reg[4:0] wp1;

// position FIFO for transaction ID 2
reg[3:0] buffer2[15:0];
reg[4:0] rp2;
reg[4:0] wp2;

// position FIFO for transaction ID 3
reg[3:0] buffer3[15:0];
reg[4:0] rp3;
reg[4:0] wp3;

// variables for keeping track of which component is available
// IO/ALU/Memory (0,1,2)
reg IO_ready, ALU_ready, MEM_ready;
reg[3:0] IO_pos, ALU_pos, MEM_pos; // designates what FIFO holds the task being worked on
reg[4:0] IO_count, MEM_count; // 30 clock delay, 20 clock delay
reg[3:0] ALU_count; // 10 clock delay

// variables for keeping track of which position in the buffer has been vacated
reg ready0, ready1, ready2, ready3; // indicates if the buffer contains anything
reg[3:0] comp0, comp1, comp2, comp3; // indicates which component the first commmand in each FIFO is
reg[7:0] task_num0, task_num1, task_num2, task_num3; // task numbers to help determine FIFO priority

// variables for priorities
wire[2:0] priority0, priority1, priority2, priority3;

// state variables
localparam 
	IDLE = 2'b00, 
	NOT_FULL = 2'b01,
	FULL = 2'b10;

// random other variables
integer i;
//reg [3:0] count;
reg FLAG = 1;
wire[3:0] comps_IO;
wire[3:0] comps_ALU;
wire[3:0] comps_MEM;

// IO module stuff
reg rw0;
reg [7:0] addr0;
reg [3:0] ctrl0;
reg [119:0] data150;
reg CMD_RCVD0;
wire [119:0] answer0;

wire mode0; //0 for read, 1 for write

wire AWREADY0;
wire WREADY0;
wire BVALID0;
wire BRESP0;

wire WLAST0;
wire RLAST0;
wire ARREADY0;
wire RVALID0;
wire [7:0] RDATA0;

wire AWVALID0;
wire WVALID0;
wire BREADY0;
wire [11:0] AWADDR0; //storing 12-bit values, depth of 16
wire [11:0] ARADDR0;
wire [7:0] WDATA0;

wire ARVALID0;
wire RREADY0;

wire [3:0] state0;
wire [3:0] state20;

master m_IO(.CMD_RCVD(CMD_RCVD0), .clk(clk), .a_rst(a_rst), .addr(addr0), .ctrl(ctrl0), .data15(data150), .rw(rw0), .mode(mode0), 
    .AWREADY(AWREADY0), .WREADY(WREADY0), .BVALID(BVALID0), .BRESP(BRESP0), .ARREADY(ARREADY0), .RVALID(RVALID0), .RDATA(RDATA0), 
    .AWVALID(AWVALID0), .WVALID(WVALID0), .BREADY(BREADY0), .AWADDR(AWADDR0), .ARADDR(ARADDR0), .WDATA(WDATA0), .ARVALID(ARVALID0), 
    .RREADY(RREADY0), .answer(answer0),  .WLAST(WLAST0), .RLAST(RLAST0), .state(state0));
slave s_IO(.clk(clk), .a_rst(a_rst), .mode(mode0), .AWVALID(AWVALID0), .WVALID(WVALID0), .BREADY(BREADY0), .AWADDR(AWADDR0), .ARADDR(ARADDR0),
    .WDATA(WDATA0), .ARVALID(ARVALID0), .RREADY(RREADY0), .AWREADY(AWREADY0), .WREADY(WREADY0), .BVALID(BVALID0), .BRESP(BRESP0), 
    .ARREADY(ARREADY0), .RVALID(RVALID0), .RDATA(RDATA0), .WLAST(WLAST0), .RLAST(RLAST0), .state(state20));
// end IO module stuff

// ALU module stuff
reg rw1;
reg [7:0] addr1;
reg [3:0] ctrl1;
reg [119:0] data151;
reg CMD_RCVD1;
wire [119:0] answer1;

wire mode1; //0 for read, 1 for write

wire AWREADY1;
wire WREADY1;
wire BVALID1;
wire BRESP1;

wire WLAST1;
wire RLAST1;
wire ARREADY1;
wire RVALID1;
wire [7:0] RDATA1;

wire AWVALID1;
wire WVALID1;
wire BREADY1;
wire [11:0] AWADDR1; //storing 12-bit values, depth of 16
wire [11:0] ARADDR1;
wire [7:0] WDATA1;

wire ARVALID1;
wire RREADY1;

wire [3:0] state1;
wire [3:0] state21;

master m_ALU(.CMD_RCVD(CMD_RCVD1), .clk(clk), .a_rst(a_rst), .addr(addr1), .ctrl(ctrl1), .data15(data151), .rw(rw1), .mode(mode1), 
    .AWREADY(AWREADY1), .WREADY(WREADY1), .BVALID(BVALID1), .BRESP(BRESP1), .ARREADY(ARREADY1), .RVALID(RVALID1), .RDATA(RDATA1), 
    .AWVALID(AWVALID1), .WVALID(WVALID1), .BREADY(BREADY1), .AWADDR(AWADDR1), .ARADDR(ARADDR1), .WDATA(WDATA1), .ARVALID(ARVALID1), 
    .RREADY(RREADY1), .answer(answer1),  .WLAST(WLAST1), .RLAST(RLAST1), .state(state1));
slave s_ALU(.clk(clk), .a_rst(a_rst), .mode(mode1), .AWVALID(AWVALID1), .WVALID(WVALID1), .BREADY(BREADY1), .AWADDR(AWADDR1), .ARADDR(ARADDR1),
    .WDATA(WDATA1), .ARVALID(ARVALID1), .RREADY(RREADY1), .AWREADY(AWREADY1), .WREADY(WREADY1), .BVALID(BVALID1), .BRESP(BRESP1), 
    .ARREADY(ARREADY1), .RVALID(RVALID1), .RDATA(RDATA1), .WLAST(WLAST1), .RLAST(RLAST1), .state(state21));
// end ALU module stuff

// MEM module stuff
reg rw2;
reg [7:0] addr2;
reg [3:0] ctrl2;
reg [119:0] data152;
reg CMD_RCVD2;
wire [119:0] answer2;

wire mode2; //0 for read, 1 for write

wire AWREADY2;
wire WREADY2;
wire BVALID2;
wire BRESP2;

wire WLAST2;
wire RLAST2;
wire ARREADY2;
wire RVALID2;
wire [7:0] RDATA2;

wire AWVALID2;
wire WVALID2;
wire BREADY2;
wire [11:0] AWADDR2; //storing 12-bit values, depth of 16
wire [11:0] ARADDR2;
wire [7:0] WDATA2;

wire ARVALID2;
wire RREADY2;

wire [3:0] state2;
wire [3:0] state22;

master m_MEM(.CMD_RCVD(CMD_RCVD2), .clk(clk), .a_rst(a_rst), .addr(addr2), .ctrl(ctrl2), .data15(data152), .rw(rw2), .mode(mode2), 
    .AWREADY(AWREADY2), .WREADY(WREADY2), .BVALID(BVALID2), .BRESP(BRESP2), .ARREADY(ARREADY2), .RVALID(RVALID2), .RDATA(RDATA2), 
    .AWVALID(AWVALID2), .WVALID(WVALID2), .BREADY(BREADY2), .AWADDR(AWADDR2), .ARADDR(ARADDR2), .WDATA(WDATA2), .ARVALID(ARVALID2), 
    .RREADY(RREADY2), .answer(answer2),  .WLAST(WLAST2), .RLAST(RLAST2), .state(state2));
slave s_MEM(.clk(clk), .a_rst(a_rst), .mode(mode2), .AWVALID(AWVALID2), .WVALID(WVALID2), .BREADY(BREADY2), .AWADDR(AWADDR2), .ARADDR(ARADDR2),
    .WDATA(WDATA2), .ARVALID(ARVALID2), .RREADY(RREADY2), .AWREADY(AWREADY2), .WREADY(WREADY2), .BVALID(BVALID2), .BRESP(BRESP2), 
    .ARREADY(ARREADY2), .RVALID(RVALID2), .RDATA(RDATA2), .WLAST(WLAST2), .RLAST(RLAST2), .state(state22));
// end MEM module stuff

always @(posedge clk, posedge a_rst) begin
	count <= count + 1; // temp
	if (a_rst) begin 
		count <= 0; // temp
		state <= IDLE; 
		READY <= 0;
		// set everything to 0
		// main buffer
		for (i = 0; i < 16; i = i + 1) begin
        	buffer[i] = 0;
      	end
      	rp <= 4'b0000;
      	wp <= 4'b0000;
      	p0 <= 4'b0000;
      	p1 <= 4'b0000;
      	p2 <= 4'b0000;
      	p3 <= 4'b0000;
      	p_empty <= 4'b0000;

		// position FIFO for transaction ID 0
		for (i = 0; i < 16; i = i + 1) begin
        	buffer0[i] = 0;
      	end
      	rp0 <= 5'b00000; // n+1 bit pointers to make my life easier....
      	wp0 <= 5'b00000;

		// position FIFO for transaction ID 1
		for (i = 0; i < 16; i = i + 1) begin
        	buffer1[i] = 0;
      	end
      	rp1 <= 5'b00000;
      	wp1 <= 5'b00000;

		// position FIFO for transaction ID 2
		for (i = 0; i < 16; i = i + 1) begin
        	buffer2[i] = 0;
      	end
      	rp2 <= 5'b00000;
      	wp2 <= 5'b00000;

		// position FIFO for transaction ID 3
		for (i = 0; i < 16; i = i + 1) begin
        	buffer3[i] = 0;
      	end
      	rp3 <= 5'b00000;
      	wp3 <= 5'b00000;

		// variables for keeping track of which component is available and which FIFO currently holds the task being worked on by each component
		
		IO_ready <= 1;
		ALU_ready <= 1;
		MEM_ready <= 1;
		IO_pos <= 4'b0000;
		ALU_pos <= 4'b0000; 
		MEM_pos <= 4'b0000;
		IO_count <= 5'b00000; 
		MEM_count <= 5'b00000;
		ALU_count <= 4'b0000;

		ready0 <= 0;
		ready1 <= 0;
		ready2 <= 0;
		ready3 <= 0;

		comp0 <= 0;
		comp1 <= 0;
		comp2 <= 0;
		comp3 <= 0;

		task_num0 = 0; 
		task_num1 = 0;
		task_num2 = 0;
		task_num3 = 0;
	end 
	else begin
		case(state)
			IDLE: begin
				READY <= 1;
				state <= NOT_FULL;
			end
			NOT_FULL: begin // only have to increment wp by 1 when filling since it hasn't been filled yet, continue until buffer is full
				// integrate task
				buffer[wp] = {task_num, OPCODE, WDATA};
				wp <= wp + 1;

				// integrate into subFIFOs
				case(OPCODE[4:3])
					0: begin
						buffer0[wp0] <= wp;
						wp0 <= wp0 + 1;
						ready0 <= 1;
						if(ready0 == 0) // set component for the first object in the FIFO
							comp0 <= OPCODE[2:1];
					end
					1: begin
						buffer1[wp1] <= wp;
						wp1 <= wp1 + 1;
						ready1 <= 1;
						if(ready1 == 0)
							comp1 <= OPCODE[2:1];
					end
					2: begin
						buffer2[wp2] <= wp;
						wp2 <= wp2 + 1;
						ready2 <= 1;
						if(ready2 == 0)
							comp2 <= OPCODE[2:1];
					end
					3: begin
						buffer3[wp3] <= wp;
						wp3 <= wp3 + 1;
						ready3 <= 1;
						if(ready3 == 0)
							comp3 <= OPCODE[2:1];
					end
				endcase

				if(rp - wp == 4'b0001) begin
					READY <= 0; 
					$display("Task buffer full");

					// place p0-3
					if(wp0[3:0] - rp0[3:0] > 0)
						p0 <= buffer0[0];
					if(wp1[3:0] - rp1[3:0] > 0)
						p1 <= buffer1[0];
					if(wp2[3:0] - rp2[3:0] > 0)
						p2 <= buffer2[0];
					if(wp3[3:0] - rp3[3:0] > 0)
						p3 <= buffer3[0];
				end

				if(rp - wp == 4'b0001)
					state <= FULL;
			end
			FULL: begin  // should remain here unless reset since it is always assumed that the tb is providing new commands 
			// if tasks are projected to finish simultaneously, delays any tasks that might finish at the same time
			// don't need to worry about multiple tasks finishing simultaneously becaue of the extra delay
				// print whole array
      			READY <= 0;
      			/*if(FLAG == 1) begin
      				FLAG <= 0;
	      			for (i = 0; i < 16; i = i + 1) begin
	      				if(i == p0)
	      					$display("p0");
      					if(i == p1)
	      					$display("p1");
      					if(i == p2)
	      					$display("p2");
      					if(i == p3)
	      					$display("p3");
	        			$display("%d: %b",i,buffer[i]);
		      		end
		      		$display("");
		      		for (i = 0; i < 16; i = i + 1) begin
	        			$display("%d: %b",i,buffer0[i]);
		      		end
	      		end*/
      			/*if(count == 0) begin 
      				READY <= 1;
      				rp <= rp + 1;
      				buffer[wp] = {task_num, OPCODE, WDATA};
					wp <= wp + 1;
					for (i = 0; i < 16; i = i + 1) begin
	        			$display("%d: %b",i,buffer[i]);
	      			end
      			end*/

      			// assign task if components are ready and there is a task that can be executed
      			// designate the position FIFO as not ready if a task is asigned to the task in the front
      			CMD_RCVD0 <= 0;
      			CMD_RCVD1 <= 0;
      			CMD_RCVD2 <= 0;
      			if(IO_ready) begin
      				$display("IO module ready");
      				if((({priority0 == 3'b000,priority1 == 3'b000,priority2 == 3'b000,priority3 == 3'b000}) & comps_IO) != 0) begin // use FIFO tID 0
						IO_ready <= 0;
						$display("IO running task %d",buffer[buffer0[rp0[3:0]]][20:13]);
						IO_pos <= 0;
						comp0 <= 0;
						task_num0 <= buffer[buffer0[rp0[3:0]]][20:13];
						ready0 <= 0;

						// send command
						CMD_RCVD0 <= 1;
					    rw0 <= buffer[buffer0[rp0[3:0]]][8];
					    addr0 <= buffer[buffer0[rp0[3:0]]][7:0];
					    ctrl0 <= 1;
					    data150 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011010,buffer[buffer0[rp0]][7:0]};
					end
					else if((({priority0 == 3'b001,priority1 == 3'b001,priority2 == 3'b001,priority3 == 3'b001}) & comps_IO) != 0) begin // use FIFO tID 1
						IO_ready <= 0;
						$display("IO running task %d",buffer[buffer1[rp1[3:0]]][20:13]);
						IO_pos <= 1;
						comp1 <= 0;
						task_num1 <= buffer[buffer1[rp1[3:0]]][20:13];
						ready1 <= 0;

						// send command
						CMD_RCVD0 <= 1;
					    rw0 <= buffer[buffer1[rp1[3:0]]][8];
					    addr0 <= buffer[buffer1[rp1[3:0]]][7:0];
					    ctrl0 <= 1;
					    data150 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer1[rp1]][7:0]};
					end
					else if((({priority0 == 3'b010,priority1 == 3'b010,priority2 == 3'b010,priority3 == 3'b010}) & comps_IO) != 0) begin // use FIFO tID 2
						IO_ready <= 0;
						$display("IO running task %d",buffer[buffer2[rp2[3:0]]][20:13]);
						IO_pos <= 2;
						comp2 <= 0;
						task_num2 <= buffer[buffer2[rp2[3:0]]][20:13];
						ready2 <= 0;

						// send command
						CMD_RCVD0 <= 1;
					    rw0 <= buffer[buffer2[rp2[3:0]]][8];
					    addr0 <= buffer[buffer2[rp2[3:0]]][7:0];
					    ctrl0 <= 1;
					    data150 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer2[rp2]][7:0]};
					end
					else if((({priority0 == 3'b011,priority1 == 3'b011,priority2 == 3'b011,priority3 == 3'b011}) & comps_IO) != 0) begin // use FIFO tID 3
						IO_ready <= 0;
						$display("IO running task %d",buffer[buffer3[rp3[3:0]]][20:13]);
						IO_pos <= 3;
						comp3 <= 0;
						task_num3 <= buffer[buffer3[rp3[3:0]]][20:13];
						ready3 <= 0;

						// send command
						CMD_RCVD0 <= 1;
					    rw0 <= buffer[buffer3[rp3[3:0]]][8];
					    addr0 <= buffer[buffer3[rp3[3:0]]][7:0];
					    ctrl0 <= 1;
					    data150 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer3[rp3]][7:0]};
					end
      			end
      			if(ALU_ready) begin //delay IO_count and MEM_count by 1 if they will finish simultaneously
      				$display("ALU module ready");
      				if((({priority0 == 3'b000,priority1 == 3'b000,priority2 == 3'b000,priority3 == 3'b000}) & comps_ALU) != 0) begin // use FIFO tID 0
						ALU_ready <= 0;
						$display("ALU running task %d",buffer[buffer0[rp0[3:0]]][20:13]);
						IO_pos <= 0;
						comp0 <= 0;
						task_num0 <= buffer[buffer0[rp0[3:0]]][20:13];
						ready0 <= 0;

						// send command
						CMD_RCVD1 <= 1;
					    rw1 <= buffer[buffer0[rp0[3:0]]][8];
					    addr1 <= buffer[buffer0[rp0[3:0]]][7:0];
					    ctrl1 <= 1;
					    data151 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011010,buffer[buffer0[rp0]][7:0]};
					end
					else if((({priority0 == 3'b001,priority1 == 3'b001,priority2 == 3'b001,priority3 == 3'b001}) & comps_ALU) != 0) begin // use FIFO tID 1
						ALU_ready <= 0;
						$display("ALU running task %d",buffer[buffer1[rp1[3:0]]][20:13]);
						IO_pos <= 1;
						comp1 <= 0;
						task_num1 <= buffer[buffer1[rp1[3:0]]][20:13];
						ready1 <= 0;

						// send command
						CMD_RCVD1 <= 1;
					    rw1 <= buffer[buffer1[rp1[3:0]]][8];
					    addr1 <= buffer[buffer1[rp1[3:0]]][7:0];
					    ctrl1 <= 1;
					    data151 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer1[rp1]][7:0]};
					end
					else if((({priority0 == 3'b010,priority1 == 3'b010,priority2 == 3'b010,priority3 == 3'b010}) & comps_ALU) != 0) begin // use FIFO tID 2
						ALU_ready <= 0;
						$display("ALU running task %d",buffer[buffer2[rp2[3:0]]][20:13]);
						IO_pos <= 2;
						comp2 <= 0;
						task_num2 <= buffer[buffer2[rp2[3:0]]][20:13];
						ready2 <= 0;

						// send command
						CMD_RCVD1 <= 1;
					    rw1 <= buffer[buffer2[rp2[3:0]]][8];
					    addr1 <= buffer[buffer2[rp2[3:0]]][7:0];
					    ctrl1 <= 1;
					    data151 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer2[rp2]][7:0]};
					end
					else if((({priority0 == 3'b011,priority1 == 3'b011,priority2 == 3'b011,priority3 == 3'b011}) & comps_ALU) != 0) begin // use FIFO tID 3
						ALU_ready <= 0;
						$display("ALU running task %d",buffer[buffer3[rp3[3:0]]][20:13]);
						IO_pos <= 3;
						comp3 <= 0;
						task_num3 <= buffer[buffer3[rp3[3:0]]][20:13];
						ready3 <= 0;

						// send command
						CMD_RCVD1 <= 1;
					    rw1 <= buffer[buffer3[rp3[3:0]]][8];
					    addr1 <= buffer[buffer3[rp3[3:0]]][7:0];
					    ctrl1 <= 1;
					    data151 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer3[rp3]][7:0]};
					end
      			end
      			if(MEM_ready) begin // delay IO_count by 1 if they will finish simultaneously
      				$display("MEM module ready");
      				if((({priority0 == 3'b000,priority1 == 3'b000,priority2 == 3'b000,priority3 == 3'b000}) & comps_MEM) != 0) begin // use FIFO tID 0
						MEM_ready <= 0;
						$display("MEM running task %d",buffer[buffer0[rp0[3:0]]][20:13]);
						IO_pos <= 0;
						comp0 <= 0;
						task_num0 <= buffer[buffer0[rp0[3:0]]][20:13];
						ready0 <= 0;

						// send command
						CMD_RCVD2 <= 1;
					    rw2 <= buffer[buffer0[rp0[3:0]]][8];
					    addr2 <= buffer[buffer0[rp0[3:0]]][7:0];
					    ctrl2 <= 1;
					    data152 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011010,buffer[buffer0[rp0]][7:0]};
					end
					else if((({priority0 == 3'b001,priority1 == 3'b001,priority2 == 3'b001,priority3 == 3'b001}) & comps_MEM) != 0) begin // use FIFO tID 1
						MEM_ready <= 0;
						$display("MEM running task %d",buffer[buffer1[rp1[3:0]]][20:13]);
						IO_pos <= 1;
						comp1 <= 0;
						task_num1 <= buffer[buffer1[rp1[3:0]]][20:13];
						ready1 <= 0;

						// send command
						CMD_RCVD2 <= 1;
					    rw2 <= buffer[buffer1[rp1[3:0]]][8];
					    addr2 <= buffer[buffer1[rp1[3:0]]][7:0];
					    ctrl2 <= 1;
					    data152 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer1[rp1]][7:0]};
					end
					else if((({priority0 == 3'b010,priority1 == 3'b010,priority2 == 3'b010,priority3 == 3'b010}) & comps_MEM) != 0) begin // use FIFO tID 2
						MEM_ready <= 0;
						$display("MEM running task %d",buffer[buffer2[rp2[3:0]]][20:13]);
						IO_pos <= 2;
						comp2 <= 0;
						task_num2 <= buffer[buffer2[rp2[3:0]]][20:13];
						ready2 <= 0;

						// send command
						CMD_RCVD2 <= 1;
					    rw2 <= buffer[buffer2[rp2[3:0]]][8];
					    addr2 <= buffer[buffer2[rp2[3:0]]][7:0];
					    ctrl2 <= 1;
					    data152 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer2[rp2]][7:0]};
					end
					else if((({priority0 == 3'b011,priority1 == 3'b011,priority2 == 3'b011,priority3 == 3'b011}) & comps_MEM) != 0) begin // use FIFO tID 3
						MEM_ready <= 0;
						$display("MEM running task %d",buffer[buffer3[rp3[3:0]]][20:13]);
						IO_pos <= 3;
						comp3 <= 0;
						task_num3 <= buffer[buffer3[rp3[3:0]]][20:13];
						ready3 <= 0;

						// send command
						CMD_RCVD2 <= 1;
					    rw2 <= buffer[buffer3[rp3[3:0]]][8];
					    addr2 <= buffer[buffer3[rp3[3:0]]][7:0];
					    ctrl2 <= 1;
					    data152 <= {112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,buffer[buffer3[rp3]][7:0]};
					end
      			end

      			// increment counts
      			if(!IO_ready) begin
      				IO_count <= IO_count + 1;
      				if(IO_count == 29) begin // count reset will never happen simultaneously because of delays in earlier code block
      					IO_count <= 0;
      					IO_ready <= 1;
      					// free up FIFO space
      					case(IO_pos)
      						0: begin
      							$display("IO completing task %d", buffer[buffer0[rp0[3:0]]][20:13]);
      							rp0 <= rp0 + 1;
      							p0 <= buffer0[rp0[3:0] + 1];
      							p_empty = buffer0[rp0[3:0]];
      							ready0 <= 1;
      							if(rp0 + 1 == wp0) // position FIFO is now empty
      								ready0 <= 0;
      							else begin
      								comp0 <= buffer[p0][10:9];
      							end
      						end
      						1: begin
      							$display("IO completing task %d", buffer[buffer1[rp1[3:0]]][20:13]);
      							rp1 <= rp1 + 1;
      							p1 <= buffer1[rp1[3:0] + 1];
      							p_empty = buffer1[rp1[3:0]];
      							ready1 <= 1;
      							if(rp1 + 1 == wp1)
      								ready1 <= 0;
  								else begin
      								comp1 <= buffer[p1][10:9];
      							end
      						end
      						2: begin
      							$display("IO completing task %d", buffer[buffer2[rp2[3:0]]][20:13]);
      							rp2 <= rp2 + 1;
      							p2 <= buffer2[rp2[3:0] + 1];
      							p_empty = buffer2[rp2[3:0]];
      							ready2<= 1;
      							if(rp2 + 1 == wp2)
      								ready2 <= 0;
  								else begin
      								comp2 <= buffer[p2][10:9];
      							end
      						end
      						3: begin
      							$display("IO completing task %d", buffer[buffer3[rp3[3:0]]][20:13]);
      							rp3 <= rp3 + 1;
      							p3 <= buffer3[rp3[3:0] + 1];
      							p_empty = buffer3[rp3[3:0]];
      							if(rp3 + 1 == wp3)
      								ready3 <= 0;
  								else begin
      								comp3 <= buffer[p3][10:9];
      							end
      						end
      					endcase
      				end
      			end
      			if(!ALU_ready) begin
      				ALU_count <= ALU_count + 1;
      				if(ALU_count == 9) begin // count reset will never happen simultaneously because of delays in earlier code block
      					ALU_count <= 0;
      					ALU_ready <= 1;
      					// free up FIFO space
      					case(ALU_pos)
      						0: begin
      							$display("ALU completing task %d", buffer[buffer0[rp0[3:0]]][20:13]);
      							rp0 <= rp0 + 1;
      							p0 <= buffer0[rp0[3:0] + 1];
      							p_empty = buffer0[rp0[3:0]];
      							if(rp0 + 1 == wp0) // position FIFO is now empty
      								ready0 <= 0;
      							else begin
      								comp0 <= buffer[p0][10:9];
      							end
      						end
      						1: begin
      							$display("ALU completing task %d", buffer[buffer1[rp1[3:0]]][20:13]);
      							rp1 <= rp1 + 1;
      							p1 <= buffer1[rp1[3:0] + 1];
      							p_empty = buffer1[rp1[3:0]];
      							if(rp1 + 1 == wp1)
      								ready1 <= 0;
  								else begin
      								comp1 <= buffer[p1][10:9];
      							end
      						end
      						2: begin
      							$display("ALU completing task %d", buffer[buffer2[rp2[3:0]]][20:13]);
      							rp2 <= rp2 + 1;
      							p2 <= buffer2[rp2[3:0] + 1];
      							p_empty = buffer2[rp2[3:0]];
      							if(rp2 + 1 == wp2)
      								ready2 <= 0;
  								else begin
      								comp2 <= buffer[p2][10:9];
      							end
      						end
      						3: begin
      							$display("ALU completing task %d", buffer[buffer3[rp3[3:0]]][20:13]);
      							rp3 <= rp3 + 1;
      							p3 <= buffer3[rp3[3:0] + 1];
      							p_empty = buffer3[rp3[3:0]];
      							if(rp3 + 1 == wp3)
      								ready3 <= 0;
  								else begin
      								comp3 <= buffer[p3][10:9];
      							end
      						end
      					endcase
      				end
      			end
      			if(!MEM_ready) begin
      				MEM_count <= MEM_count + 1;
      				if(MEM_count == 19) begin // count reset will never happen simultaneously because of delays in earlier code block
      					MEM_count <= 0;
      					MEM_ready <= 1;
      					// free up FIFO space
      					case(MEM_pos)
      						0: begin
      							$display("MEM completing task %d", buffer[buffer0[rp0[3:0]]][20:13]);
      							rp0 <= rp0 + 1;
      							p0 <= buffer0[rp0[3:0] + 1];
      							p_empty = buffer0[rp0[3:0]];
      							if(rp0 + 1 == wp0) // position FIFO is now empty
      								ready0 <= 0;
      							else begin
      								comp0 <= buffer[p0][10:9];
      							end
      						end
      						1: begin
      							$display("MEM completing task %d", buffer[buffer1[rp1[3:0]]][20:13]);
      							rp1 <= rp1 + 1;
      							p1 <= buffer1[rp1[3:0] + 1];
      							p_empty = buffer1[rp1[3:0]];
      							if(rp1 + 1 == wp1)
      								ready1 <= 0;
  								else begin
      								comp1 <= buffer[p1][10:9];
      							end
      						end
      						2: begin
      							$display("MEM completing task %d", buffer[buffer2[rp2[3:0]]][20:13]);
      							rp2 <= rp2 + 1;
      							p2 <= buffer2[rp2[3:0] + 1];
      							p_empty = buffer2[rp2[3:0]];
      							if(rp2 + 1 == wp2)
      								ready2 <= 0;
  								else begin
      								comp2 <= buffer[p2][10:9];
      							end
      						end
      						3: begin
      							$display("MEM completing task %d", buffer[buffer3[rp3[3:0]]][20:13]);
      							rp3 <= rp3 + 1;
      							p3 <= buffer3[rp3[3:0] + 1];
      							p_empty = buffer3[rp3[3:0]];
      							if(rp3 + 1 == wp3)
      								ready3 <= 0;
  								else begin
      								comp3 <= buffer[p3][10:9];
      							end
      						end
      					endcase
      				end
      			end
      			if((!IO_ready && (IO_count == 29)) || (!ALU_ready && (ALU_count == 9)) || (!MEM_ready && (MEM_count == 19))) begin
      				buffer[p_empty] <= {task_num, OPCODE, WDATA};
      				READY <= 1; // move tb  to next command

      				case(OPCODE[12:11]) // populate position FIFOs
						0: begin
							buffer0[wp0[3:0]] <= wp;
							wp0 <= wp0 + 1;
							ready0 <= 1;
							if(ready0 == 0) begin // set component for the first object in the FIFO
								p0 <= buffer0[wp0[3:0]]; // p0 is now a valid pointer again, can be used to send commands
								comp0 <= OPCODE[2:1];
							end
						end
						1: begin
							buffer1[wp1[3:0]] <= wp;
							wp1 <= wp1 + 1;
							ready1 <= 1;
							if(ready1 == 0) begin
								p1 <= buffer1[wp1[3:0]];
								comp1 <= OPCODE[2:1];
							end
						end
						2: begin
							buffer2[wp2[3:0]] <= wp;
							wp2 <= wp2 + 1;
							ready2 <= 1;
							if(ready2 == 0) begin
								p2 <= buffer2[wp2[3:0]];
								comp2 <= OPCODE[2:1];
							end
						end
						3: begin
							buffer3[wp3[3:0]] <= wp;
							wp3 <= wp3 + 1;
							ready3 <= 1;
							if(ready3 == 0) begin
								p3 <= buffer3[wp3[3:0]];
								comp3 <= OPCODE[2:1];
							end
						end
					endcase
      			end
			end
		endcase
	end
end

// wires for determining which position FIFO has priority, 0 is highest, 3 is lowest, 4 means FIFO is not ready
assign priority0 = ready0 ? ({1'b0,((task_num1-task_num0)>task_num1)&ready1} + {1'b0,((task_num2-task_num0)>task_num2)&ready2} + {1'b0,((task_num3-task_num0)>task_num3)&ready3}) : 4; // FIFO ID 0
assign priority1 = ready1 ? ({1'b0,((task_num0-task_num1)>task_num0)&ready0} + {1'b0,((task_num2-task_num1)>task_num2)&ready2} + {1'b0,((task_num3-task_num1)>task_num3)&ready3}) : 4;
assign priority2 = ready2 ? ({1'b0,((task_num0-task_num2)>task_num0)&ready0} + {1'b0,((task_num1-task_num2)>task_num1)&ready1} + {1'b0,((task_num3-task_num2)>task_num3)&ready3}) : 4;
assign priority3 = ready3 ? ({1'b0,((task_num0-task_num3)>task_num0)&ready0} + {1'b0,((task_num1-task_num3)>task_num1)&ready1} + {1'b0,((task_num2-task_num3)>task_num2)&ready2}) : 4;

// concatenated comp values, 1 if they are a command from the right component
assign comps_IO = {comp0 == 0,comp1 == 0,comp2 == 0,comp3 == 0};
assign comps_ALU = {comp0 == 1,comp1 == 1,comp2 == 1,comp3 == 1};
assign comps_MEM = {comp0 == 2,comp1 == 2,comp2 == 2,comp3 == 2};

endmodule