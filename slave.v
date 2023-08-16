
`timescale 1 ns / 1 ps

module slave
(

input clk, 
input a_rst, 
input mode, //0 for read, 1 for write

input AWVALID, 
input WVALID,
input BREADY,
input [11:0] AWADDR, //storing 12-bit values, depth of 16
input [11:0] ARADDR,
input [7:0] WDATA,

input ARVALID,
input RREADY,

output reg AWREADY, 
output reg WREADY,
output reg BVALID,
output reg BRESP,

output reg ARREADY,
output reg RVALID,
output reg [7:0] RDATA,

input WLAST,
output reg RLAST,
output reg [3:0] state
);

//reg [3:0] state; 
reg [3:0] N; //index through address
reg [7:0] MEMORY[255:0]; 
reg [7:0] ADDR; //8 bit address 

reg [4:0] L; //at most, 16
reg [3:0] L2; //at most, 15
reg flag;
integer i;
wire BURST;


localparam 
	IDLE = 4'b0000, 
	WADDR = 4'b0001, 
	WDATAST = 4'b0010, 
	WREADYST = 4'b0011, 
	WRES = 4'b0100, 
	RADDR = 4'b0101, 
	RDATAST = 4'b0110, 
	RREADYST = 4'b0110, 
	RRES = 4'b1000, 
	OK = 1'b1,  
	READ = 1'b0, 
	WRITE = 1'b1;   


//note that the testbench needs to deassert reset SYNC
always @(posedge clk, posedge a_rst) 
  begin
    if (a_rst) 
     begin 
			state <= IDLE;
			for (i = 0; i < 256; i = i + 1) begin
        MEMORY[i] = 0;
      end
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
			   		 	flag <= 0; 
			   		 	BVALID <= 0;
			   		 	BRESP <= 0;
			   		 	if (AWVALID)
			   		 	 begin
			   		 		AWREADY <= 1; 
			   		 		ADDR <= AWADDR[11:4]; 
			   		 		//N <= N+1;// this one
			   		 	 end 
			   		 	if (AWVALID)
			   		 		state <= WADDR; 
			   		 end 
			   		WADDR: 
			   		 begin
			   		 	AWREADY <= 0; 
			   		 	state <= WDATAST;
			   		 end 
			   		WDATAST: 
			   		 begin
			   		 	if (WVALID)
			   		 	 begin
			   		 	 	if (ADDR == 255)
			   		 	 		flag <= 1; 
			   		 	 	if (!flag) 
			   		 	 		MEMORY[ADDR] <= WDATA;
			   		 		ADDR <= ADDR + 1;//AWADDR[11:4];
			   		 		N <= N+1; 
			   		 		WREADY <= 1; 
			   		 		if(WLAST)
			   		 			WREADY <= 0;
			   		 	 end
			   		 	if (WVALID)
			   		 	 begin
			   		 	 	if (WLAST)
			   		 	 		state <= WRES; 
			   		 	 	else begin
			   		 	 		state <= WREADYST;
			   		 	 	end
			   		 	 end
			   		 end
			   		WREADYST: 
			   		 begin
			   		 	WREADY <= 0;
			   		 	state <= WDATAST;
			   		 end
			   		WRES: 
			   		 begin
			   		 	BVALID <= 1; 
			   		 	BRESP <= OK; 
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
			 	 		 	flag <= 0;
			 	 		 	BVALID <= 0;
			   		 	BRESP <= 0;
			   		 	RDATA <= 0; ///// check this one
			 	 		 	if (ARVALID)
			 	 		 	 begin
			 	 		 	 	//ARREADY <= 1;
			 	 		 	 	ADDR = ARADDR[11:4]; 
			 	 		 	 	N <= N+1;
			 	 		 	 	L <= ARADDR[3:0]; 
			 	 		 	 	L2 <= ARADDR[3:0] - 1;
			 	 		 	 	if(~BURST)
			 	 		 	 		RDATA <= MEMORY[ADDR];
			 	 		 	 end 
			 	 		 	if (ARVALID)
			 	 		 		state <= RDATAST;//ADDR;
			 	 		 end 
			 	 		RADDR:
			 	 		 begin
			 	 			L2 <= L-1;
			 	 			state <= RDATAST;
			 	 		 end
			 	 		RDATAST:
			 	 		 begin
			 	 		  if (ADDR == 255)
			   		 	 	flag <= 1; 
			   		 	if (!flag) 
			 	 		 		RDATA <= MEMORY[ADDR]; 
			 	 		 	ADDR <= ADDR + 1;//ARADDR[11:4];
			 	 		 	ARREADY <= 1; 
			 	 		 	N <= N+1; 
			 	 		 	RVALID <= 1; 
			 	 		 	if (N==L2 || ~BURST) 
			 	 		 		RLAST <= 1; 
			 	 		 	else if (N==L) begin
			 	 		 		RLAST <= 0; 
			 	 		 		RVALID <= 0;
		 	 		 		end

		 	 		 		if(N == L)
		 	 		 			state <= RRES;
			 	 		 	else if (!RREADY)
			 	 		 		state <= RREADYST; 
			 	 		 end 
			 	 		RREADYST:
			 	 		 begin
			 	 		 	RVALID <= 0; 
			 	 		 	RLAST <= 0;
			 	 		 	if (N==L)
			 	 		 		state <= RRES; 
			 	 		 	else 
			 	 		 		state <= RDATA; 
			 	 		 end
			 	 		RRES:
			 	 		 begin
			 	 		 	BVALID <= 1; 
			 	 		 	BRESP <= OK; 
			 	 		 	RLAST <= 0;
			 	 		 	RVALID <= 0;
			 	 		 	ARREADY <= 0;
			 	 		 	state <= IDLE; 
			 	 		 end
			 	 	endcase
			 	 end
		   endcase
	   end 
  end

  // control signals
  assign BURST = (ARADDR[3:0] != 1);
endmodule  


