
module gf2m
#(
	parameter DIGITAL = 16,
	parameter DATA_WIDTH = 163
)(
	input wire rst,
	input wire clk,
	input wire start,
	input wire [DATA_WIDTH - 1 : 0] a,
	input wire [DATA_WIDTH - 1 : 0] g,
	input wire [DIGITAL - 1:0] b,
	output reg [DATA_WIDTH - 1 : 0] t_i_j,
	output reg done
);

parameter ITERATION_NUMBER = DATA_WIDTH / DIGITAL;

parameter IDLE = 1'b0;
parameter CAL  = 1'b1;

reg state;
reg [12:0] counter;

wire [DATA_WIDTH - 1 : 0] wire_t_i_j;

serial serial_8_bit(
	.b(b),
	.a(a),
	.g(g),
	.t_i1_j1(t_i_j),

	.t_i_j(wire_t_i_j)
);



always @(posedge clk or negedge rst) begin : proc_counter
	if(~rst) begin
		counter <= 0;
	end else begin
		case (state)
			IDLE: begin  
				counter <= 6'd0;
			end
			CAL: begin 
				if( counter < ITERATION_NUMBER) 
					counter <= counter + 1;
				else 
					counter <= 6'd0;
			end
		
			default : /* default */;
		endcase
	end
end


always @(posedge clk or negedge rst) begin : proc_t_i_j
	if(~rst) begin
		t_i_j <= 0;
	end else begin
		case (state)
			IDLE : t_i_j <= 0;
			CAL : t_i_j <= wire_t_i_j;
			default : t_i_j <= 0;
		endcase
	end
end

always @(posedge clk or negedge rst) begin : proc_done
	if(~rst) begin
		done <= 0;
	end else begin
		case (state)
			IDLE : done <= 0;
			CAL : begin 
				if( counter < ITERATION_NUMBER) 
					done <= 0;
				else 
					done <= 1'b1;
			end	
			default : done <= 0;
		endcase
	end
end

always @(posedge clk or negedge rst) begin : proc_state
	if(~rst) begin
		state <= IDLE;
	end else begin
		case (state)
			IDLE: begin : IDLE_STATE
				if (start)
					state <= CAL;
				else
					state <= state;
			end
			CAL: begin  : CAL_STATE
				if ( counter < ITERATION_NUMBER)
					state <= CAL;
				else
					state <= IDLE;
			end
			default : state <= IDLE;
		endcase
	end
end

endmodule
