
module fpga_gf2m
#(
	parameter DIGITAL = 32,
	parameter DATA_WIDTH = 163
)(
	input clk,    // Clock
	input rst,  // Asynchronous reset active low
	input wire start,
	input wire [DATA_WIDTH - 1 : 0] a,
	input wire [DATA_WIDTH - 1 : 0] g,
	input wire [BWIDTH - 1:0] b,
	output reg [DATA_WIDTH - 1 : 0] t_i_j,
	output reg done
);

parameter ITERATION_NUMBER = DATA_WIDTH / DIGITAL;
parameter BWIDTH = (ITERATION_NUMBER + 1)*DIGITAL;

parameter IDLE = 2'b00;
parameter CAL  = 2'b01;
parameter DONE = 2'b10;

reg state;
reg [12:0] counter;

reg [DATA_WIDTH - 1 : 0] reg_a;
reg [DATA_WIDTH - 1 : 0] reg_g;
reg [BWIDTH - 1:0] reg_b;

wire [DIGITAL - 1:0] b_in;
wire [DATA_WIDTH - 1 : 0] out_t_i_j;
wire wire_done;

gf2m fpgainst(
	.rst(rst),
	.clk(clk),
	.start(start),
	.a(reg_a),
	.g(reg_g),
	.b(b_in),
	.t_i_j(out_t_i_j),
	.done(wire_done)
);

// done
always @(posedge clk or negedge rst) begin : proc_done
	if(~rst) begin
		done <= 0;
	end else begin
		case (wire_done)
			1'b0: done <= done;
			1'b1: done <= 1'b1;	
			default : done <= done;
		endcase
	end
end

always @(posedge clk or negedge rst) begin : proc_t_i_j
	if(~rst) begin
		t_i_j <= 0;
	end else begin
		case (wire_done)
			1'b0: t_i_j <= t_i_j;
			1'b1: t_i_j <= out_t_i_j;
			default : t_i_j <= t_i_j;
		endcase
	end
end

// counter 
always @(posedge clk or negedge rst) begin : proc_counter
	if(~rst) begin
		counter <= 0;
	end else begin
		case (state)
			IDLE: begin 
				counter <= 12'd0;
			end
			CAL: begin 
				if(counter < ITERATION_NUMBER)
					counter <= counter + 1;
				else
					counter <= 12'd0;
			end
			default : counter <= 12'd0;
		endcase
	end
end

// reg_b_in
assign b_in = reg_b[(ITERATION_NUMBER + 1)*DIGITAL - 1  : (ITERATION_NUMBER )*DIGITAL];


// reg_a 
always @(posedge clk or negedge rst) begin : reg_a34
	if(~rst) begin
		reg_a <= 0;
	end else begin
		case (state)
			IDLE: begin 
				if(start)
					reg_a <= a;
				else
					reg_a <= 0;
			end		
			default : reg_a <= reg_a;
		endcase
	end
end

// reg_b
always @(posedge clk or negedge rst) begin : reg_b24
	if(~rst) begin
		reg_b <= 0;
	end else begin
		case (state)
			IDLE: begin 
				if(start)
					reg_b <= b;
				else
					reg_b <= 0;
			end
			CAL:begin
			     reg_b = reg_b <<< DIGITAL;
			end
					
			default : reg_b <= reg_b;
		endcase
	end
end


// reg_g
always @(posedge clk or negedge rst) begin : proc_reg_g32
	if(~rst) begin
		reg_g <= 0;
	end else begin
		case (state)
			IDLE: begin 
				if(start)
					reg_g <= g;
				else
					reg_g <= 0;
			end	 
		 	default : reg_g <= reg_g;
		 endcase 
	end
end




always @(posedge clk or negedge rst) begin : proc_state_machine
	if(~rst) begin
		state <= IDLE;
	end else begin
		 case (state)
		 	IDLE: begin 
		 		if(start) begin
		 			state <= CAL;
		 		end
		 		else begin 
		 			state <= state;
		 		end
		 	end
		 	CAL: begin 
		 		if (counter < ITERATION_NUMBER)
		 			state <= CAL;
		 		else 
		 			state <= DONE;
		 	end
		 	DONE: begin
		 		state <= DONE;
		 	end 
		 	default : state <= IDLE;
		 endcase
	end
end


endmodule
