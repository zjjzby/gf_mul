
module serial
#(
    parameter DATA_WIDTH = 163,
	parameter DIGITAL = 64
)(
	input wire [DIGITAL - 1:0] b,
	input wire [DATA_WIDTH - 1 : 0] a,
	input wire [DATA_WIDTH - 1 : 0] g,
	input wire [DATA_WIDTH - 1 : 0] t_i1_j1,

	output wire [DATA_WIDTH - 1 : 0] t_i_j
);

generate
	genvar j;
	for(j = 0; j< DIGITAL + 1; j = j + 1)
	begin : inter_wire
		wire [DATA_WIDTH - 1 : 0] t_wire_i_j;
	end
endgenerate

assign t_i_j = inter_wire[DIGITAL].t_wire_i_j;
assign inter_wire[0].t_wire_i_j = t_i1_j1;

generate
	genvar i;
	for(i = 0; i < DIGITAL; i = i + 1)
	begin: array
		one_bit
		#(
		  .DATA_WIDTH(DATA_WIDTH)
		) instone_bit(
			.b(b[DIGITAL - i - 1]),
			.a(a),
			.g(g),
			.t_i1_m1(inter_wire[i].t_wire_i_j[DATA_WIDTH - 1]),
			.t_i1_j1({inter_wire[i].t_wire_i_j[DATA_WIDTH - 2:0], 1'b0}),

			.t_i_j(inter_wire[i + 1].t_wire_i_j)
			);
	end
endgenerate
endmodule // serial
