
module one_bit
#(
	parameter DATA_WIDTH = 163
)(
	input wire b,
	input wire [DATA_WIDTH - 1 : 0] a,
	input wire [DATA_WIDTH - 1 : 0] g,
	input wire t_i1_m1,
	input wire [DATA_WIDTH - 1 : 0] t_i1_j1,

	output wire [DATA_WIDTH - 1 : 0] t_i_j,
	output wire [DATA_WIDTH - 1 : 0] out_a,
	output wire [DATA_WIDTH - 1 : 0] out_b
);


generate
	genvar i;
	for(i = DATA_WIDTH - 1; i >= 0; i = i - 1)
	begin: basic
		basc_element inst(
			.aj(a[i]),
			.bj(b),
			.t_i1_j1(t_i1_j1[i]),
			.t_i1_m1(t_i1_m1),
			.b_m1(b),
			.gj(g[i]),

			.out_t_i1_m1(),
			.out_b_m1(),
			.out_aj(out_a[i]),
			.out_bj(out_b[i]),
	 		.t_i_j(t_i_j[i])
			);
	end
endgenerate
endmodule
