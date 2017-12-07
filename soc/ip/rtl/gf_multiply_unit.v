`timescale 1ns / 1ps

`define DEBUG

module gf_multiply_unit
#(
    parameter DIGITAL = 32,
    parameter DATA_WIDTH = 163
)(
`ifdef DEBUG
    output wire [162:0] tout,
`endif
    
    //Control Interface
    input wire        clk,
    input wire        rst_n,
    input wire        ap_start,
    output reg        ap_done,
    output reg [7:0]  ap_id,
    
    //AXI Lite Data Interface
    input wire        s_axil_awvalid,
    output reg        s_axil_awready,
    input wire [31:0] s_axil_awaddr,
    input wire [2:0]  s_axil_awprot,//no use

    input wire        s_axil_wvalid,
    output reg        s_axil_wready,
    input wire [31:0] s_axil_wdata,
    input wire [3:0]  s_axil_wstrb,//no use

    output reg        s_axil_bvalid,
    input wire        s_axil_bready,
    output reg [1:0]  s_axil_bresp,

    input wire        s_axil_arvalid,
    output reg        s_axil_arready,
    input wire [31:0] s_axil_araddr,
    input wire [2:0]  s_axil_arprot,//no use

    output reg        s_axil_rvalid,
    input wire        s_axil_rready,
    output reg [31:0] s_axil_rdata,
    output reg [1:0]  s_axil_rresp
);

////////////////////////////////////////////////////////////
//
// local param & reg & wire
//
////////////////////////////////////////////////////////////

localparam ITERATION_NUMBER = DATA_WIDTH / DIGITAL;
localparam BWIDTH = (ITERATION_NUMBER + 1)*DIGITAL;

localparam BASE_A0 = 8'h00,
           BASE_A1 = 8'h04,
           BASE_A2 = 8'h08,
           BASE_A3 = 8'h0C,
           BASE_A4 = 8'h10,
           BASE_A5 = 8'h14;
           
localparam BASE_B0 = 8'h20,
           BASE_B1 = 8'h24,
           BASE_B2 = 8'h28,
           BASE_B3 = 8'h2C,
           BASE_B4 = 8'h30,
           BASE_B5 = 8'h34;
           
localparam BASE_G0 = 8'h40,
           BASE_G1 = 8'h44,
           BASE_G2 = 8'h48,
           BASE_G3 = 8'h4C,
           BASE_G4 = 8'h50,
           BASE_G5 = 8'h54;

localparam BASE_TIJ0 = 8'hA0,
           BASE_TIJ1 = 8'hA4,
           BASE_TIJ2 = 8'hA8,
           BASE_TIJ3 = 8'hAC,
           BASE_TIJ4 = 8'hB0,
           BASE_TIJ5 = 8'hB4;

reg [DATA_WIDTH-1:0]  reg_a;
reg [BWIDTH-1:0]      reg_b;
reg [DATA_WIDTH-1:0]  reg_g;
wire [DATA_WIDTH-1:0] wire_tij;

`ifdef DEBUG
assign tout = wire_tij;
`endif

localparam IDLE  = 4'b0001,
           START = 4'b0010,
           CALCU = 4'b0100;

reg [3:0] state;
reg kernel_rst;
reg kernel_start;
wire kernel_done;

////////////////////////////////////////////////////////////
//
// main logic
//
////////////////////////////////////////////////////////////

always @(posedge clk)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        kernel_rst <= 1;
        kernel_start <= 0;
        ap_done <= 0;
        ap_id <= 8'h00;
    end
    else
    begin
        case(state)
        IDLE:
            begin
                if(ap_start)
                begin
                    kernel_rst <= 0;
                    ap_done <= 0;
                    state <= START;
                end
            end
        START:
            begin
                kernel_rst <= 1;
                kernel_start <= 1;
                state <= CALCU;
            end
        CALCU:
            begin
                kernel_start <= 0;
                if(kernel_done)
                begin
                    state <= IDLE;
                    ap_done <= 1;
                end
            end
        default:
            begin
                state <= IDLE;
            end
        endcase
    end
end

fpga_gf2m #(
    .DIGITAL(DIGITAL),
    .DATA_WIDTH(DATA_WIDTH)
) gf_multiply_kernel (
    .clk(clk),
    .rst(kernel_rst),
    .start(kernel_start),
    .done(kernel_done),
    .a(reg_a),
    .g(reg_g),
    .b(reg_b),
    .t_i_j(wire_tij)
);

////////////////////////////////////////////////////////////
//
// AXI Lite Logic
//
////////////////////////////////////////////////////////////

wire s_axil_rden;
wire s_axil_wren;
assign s_axil_rden = s_axil_arvalid & s_axil_arready & ~s_axil_rvalid;
assign s_axil_wren = s_axil_wvalid & s_axil_wready & s_axil_awvalid & s_axil_awready;

always @(posedge clk)
begin
    if (!rst_n)
    begin
        s_axil_awready <= 1;
        s_axil_wready <= 1;
        s_axil_arready <= 1;
    end
    else
    begin
        s_axil_awready <= s_axil_awready;
        s_axil_wready <= s_axil_wready;
        s_axil_arready <= s_axil_arready;
    end
end

always @(posedge clk)
begin
    if (!rst_n)
    begin
        s_axil_bvalid <= 0;
        s_axil_bresp <= 0;
    end
    else if (s_axil_wvalid && s_axil_wready && ~s_axil_bvalid &&
             s_axil_awvalid && s_axil_awready)
    begin
        s_axil_bvalid <= 1;
        s_axil_bresp <= 0;
    end
    else if (s_axil_bvalid && s_axil_bready)
    begin
        s_axil_bvalid <= 0;
        s_axil_bresp <= 0;
    end
    else
    begin
        s_axil_bvalid <= s_axil_bvalid;
        s_axil_bresp <= s_axil_bresp;
    end
end

always @(posedge clk)
begin
    if (!rst_n)
    begin
        s_axil_rvalid <= 0;
        s_axil_rresp <= 0;
    end
    else if (s_axil_arvalid && s_axil_arready && ~s_axil_rvalid)
    begin
        s_axil_rvalid <= 1;
        s_axil_rresp <= 0;
    end
    else if (s_axil_rvalid && s_axil_rready)
    begin
        s_axil_rvalid <= 0;
        s_axil_rresp <= 0;
    end
    else
    begin
        s_axil_rvalid <= s_axil_rvalid;
        s_axil_rresp <= s_axil_rresp;
    end
end

always @(posedge clk)
begin
    if (!rst_n)
        s_axil_rdata <= 32'hFFFF_FFFF;
    else if (s_axil_rden)
        case (s_axil_araddr[7:0])
            BASE_TIJ0: s_axil_rdata <= wire_tij[31:0];
            BASE_TIJ1: s_axil_rdata <= wire_tij[63:32];
            BASE_TIJ2: s_axil_rdata <= wire_tij[95:64];
            BASE_TIJ3: s_axil_rdata <= wire_tij[127:96];
            BASE_TIJ4: s_axil_rdata <= wire_tij[159:128];
            BASE_TIJ5: s_axil_rdata <= wire_tij[DATA_WIDTH-1:160];
        endcase
    else
        s_axil_rdata <= s_axil_rdata;
end

always @(posedge clk)
begin
    if(!rst_n)
    begin
        reg_a <= 0;
        reg_b <= 0;
        reg_g <= 0;
    end
    else if(s_axil_wren)
    begin
        case(s_axil_awaddr[7:0])
            BASE_A0: reg_a[31:0]    <= s_axil_wdata;
            BASE_A1: reg_a[63:32]   <= s_axil_wdata;
            BASE_A2: reg_a[95:64]   <= s_axil_wdata;
            BASE_A3: reg_a[127:96]  <= s_axil_wdata;
            BASE_A4: reg_a[159:128] <= s_axil_wdata;
            BASE_A5: reg_a[DATA_WIDTH-1:160] <= s_axil_wdata;
                  
            BASE_B0: reg_b[31:0]    <= s_axil_wdata;
            BASE_B1: reg_b[63:32]   <= s_axil_wdata;
            BASE_B2: reg_b[95:64]   <= s_axil_wdata;
            BASE_B3: reg_b[127:96]  <= s_axil_wdata;
            BASE_B4: reg_b[159:128] <= s_axil_wdata;
            BASE_B5: reg_b[BWIDTH-1:160] <= s_axil_wdata;
                  
            BASE_G0: reg_g[31:0]    <= s_axil_wdata;
            BASE_G1: reg_g[63:32]   <= s_axil_wdata;
            BASE_G2: reg_g[95:64]   <= s_axil_wdata;
            BASE_G3: reg_g[127:96]  <= s_axil_wdata;
            BASE_G4: reg_g[159:128] <= s_axil_wdata;
            BASE_G5: reg_g[DATA_WIDTH-1:160] <= s_axil_wdata;
        endcase
    end
    else
    begin
        reg_a <= reg_a;
        reg_b <= reg_b;
        reg_g <= reg_g;
    end
end

endmodule
