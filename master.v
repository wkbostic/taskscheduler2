
`timescale 1 ns / 1 ps

module master
(

input CMD_RCVD,
input clk, 
input a_rst,
input [7:0] addr,
input [3:0] ctrl,
input [119:0] data15, 
input rw,
output mode, //0 for read, 1 for write

input AWREADY, 
input WREADY,
input BVALID,
input BRESP,

input ARREADY,
input RVALID,
input [7:0] RDATA,

output reg AWVALID, 
output reg WVALID,
output reg BREADY,
output reg [11:0] AWADDR, //storing 12-bit values, depth of 16
output reg [11:0] ARADDR,
output reg [7:0] WDATA,

output reg ARVALID,
output reg RREADY,

output reg [119:0] answer,
input RLAST,
output reg WLAST,
output reg [3:0] state
);

//reg [3:0] state; 
reg [3:0] I; //iterator
reg [3:0] N; //index through address
reg [3:0] N2; //second to last address
//reg [7:0] MEMORY[255:0]; 
//reg [7:0] ADDR; //8 bit address 
 
reg [4:0] L; //at most, 16
reg [3:0] L2; //at most, 15
reg flag;
wire BURST;
reg [119:0] preanswer;

localparam 
	IDLE = 4'b0000, 
	WADDR = 4'b0001, 
	WDATAST = 4'b0010,
	WRES = 4'b0011, 
	RADDR = 4'b0100, 
	RDATAST = 4'b0101,
	RRES = 4'b0110, 
	OK = 1'b1,  
	READ = 1'b0, 
	WRITE = 1'b1;   


//note that the testbench needs to deassert reset SYNC
always @(posedge clk, posedge a_rst) 
  begin
    if (a_rst) 
     begin 
			state <= IDLE; 
		 end 
		else 
	   begin
	   	case(mode)
	   		WRITE:
	   		 begin
			   	case(state)
			   		IDLE: 
			   		 begin
			   		 	N <= 0; 
			   		 	I <= 0;
			   		 	answer <= 0;
			   		 	if (CMD_RCVD)
			   		 		state <= WADDR; 
			   		 end 
			   		WADDR: 
			   		 begin
			   		 	N <= ctrl;
							N2 <= ctrl - 1; 
							AWADDR <= {addr,ctrl};
							AWVALID <= 1;
							if(AWREADY==1) begin
						    WDATA <= data15[I*8 +: 7];
						    I <= I + 1; // get this to run for the right number of times and youre good
						    WVALID <= 1;
						    AWADDR <= 0;
						    AWVALID <= 0;
						    BREADY <= 1;
						    if(~BURST)
						    	WLAST <= 1;
						  end

						  if(AWREADY)
			   		 		state <= WDATAST;
			   		 end 
			   		WDATAST: 
			   		 begin
			   		 	if(I == N) begin
						    WLAST <= 0;
						    WVALID <= 0;
						    WDATA <= 0;
						  end
							else if(I == N2) begin
						    WLAST <= 1;
						  end
							if(WREADY == 1) begin // only up for one clock so don?t need to worry about doing this twice on accident
						    I <= I + 1;
						    WDATA <= data15[I*8 +: 7];
						    WVALID <= 1;
    					end

			   		 	if (I == N)
			   		 		state <= WRES;
			   		 end
			   		WRES: 
			   		 begin
			   		 	if(BVALID == 1)
			   		 		BREADY <= 0;
			   		 	WLAST <= 0;
			   		 	
			   		 	if(BVALID == 1)
			   		 		state <= IDLE;
			   		 end
			   		default: state <= IDLE; 
			   	endcase 
			   end
			 	READ: 
			 	 begin
			 	 	case(state)
			 	 		IDLE:
			 	 		 begin
			 	 		 	N <= 0; 
			   		 	I <= 0;
			   		 	preanswer <= 0;
							if (CMD_RCVD)
								RREADY <= 1;
			 	 		 	if (CMD_RCVD)
			 	 		 		state <= RADDR;
			 	 		 end 
			 	 		RADDR:
			 	 		 begin
			 	 			ARADDR <= {addr,ctrl};
							ARVALID <= 1;
							N <= ctrl;
							if(ARREADY==1) begin
							    preanswer[I*8 +: 7] = RDATA; // timing on this is off
							    I <= I + 1;
							    ARADDR <= 0;
							    ARVALID <= 0;
							end

							if (ARREADY)
								state <= RDATAST;
							if ((RLAST == 1) & (RVALID == 1)) begin
								RREADY <= 0;
			 	 		 		answer <= preanswer;
			 	 		 	end
			 	 		 	if ((RLAST == 1) & (RVALID == 1))
			 	 		 		state <= IDLE; 
			 	 		 end
			 	 		RDATAST:
			 	 		 begin
			 	 		 	if(I == N)
							  RREADY <= 0;
							if (RVALID == 1) begin
						    I <= I + 1;
						    preanswer[I*8 +: 7] = RDATA;
						    RREADY <= 1;
						  end
						  if ((RLAST == 1) & (RVALID == 1))
						  	answer <= preanswer;

			 	 		 	if ((RLAST == 1) & (RVALID == 1))
			 	 		 		state <= IDLE; 
			 	 		 end
			 	 		 default: state <= IDLE;
			 	 	endcase
			 	 end
		   endcase
	   end 
  end

  // equate mode to rw from tb
  assign mode = rw;
  assign BURST = (ctrl != 1);
endmodule  



