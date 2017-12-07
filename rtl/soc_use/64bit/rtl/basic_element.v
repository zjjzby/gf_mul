
module basc_element
	(
		input wire aj,
		input wire bj,
		input wire t_i1_j1,
		input wire t_i1_m1,
		input wire b_m1,
		input wire gj,
		output wire out_t_i1_m1,
		output wire out_b_m1,
		output wire out_aj,
		output wire out_bj,
	 	output wire t_i_j
		);
assign out_aj = aj;
assign out_bj = bj;
assign out_t_i1_m1 = t_i1_m1;
assign out_b_m1 = b_m1;

assign t_i_j = (b_m1&aj)^(t_i1_m1&gj)^t_i1_j1;
endmodule // basc_element
