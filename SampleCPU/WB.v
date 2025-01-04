`include "lib/defines.vh"
module WB(
    //时钟信号
    input wire clk,
    //复位信号
    input wire rst,
    //暂停信号
    input wire [`StallBus-1:0] stall,
    //接收MEM段的值
    input wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    input wire[65:0] mem_to_wb1,
    //写回reg_array[31:0]的值
    output wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,
    //发送给ID段的值
    output wire [37:0] wb_to_id_bus,
    output wire[65:0] wb_to_id_2, 
    //发送给regfile的值
    output wire[65:0]wb_to_id_wf,
    
    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
    );

    reg [`MEM_TO_WB_WD-1:0] mem_to_wb_bus_r;
    reg [65:0] mem_to_wb1_r;

    always @ (posedge clk) begin
        if (rst) begin
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
            mem_to_wb1_r <= 66'b0;
        end
        else if (stall[4]==`Stop && stall[5]==`NoStop) begin    //暂停时刷新管道
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
            mem_to_wb1_r <= 66'b0;
        end
        else if (stall[4]==`NoStop) begin   //接收MEM段的值
            mem_to_wb_bus_r <= mem_to_wb_bus;
            mem_to_wb1_r <= mem_to_wb1;
        end
    end

    wire [31:0] wb_pc;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    //hi,lo寄存器的使能信号与值
    wire w_hi_we;
    wire w_lo_we;
    wire [31:0]hi_i;
    wire [31:0]lo_i;
     
    assign {
        wb_pc,
        rf_we,
        rf_waddr,
        rf_wdata
    } = mem_to_wb_bus_r;

    assign 
    {
        w_hi_we,
        w_lo_we,
        hi_i,
        lo_i
    } = mem_to_wb1_r;   //接收MEM段的值
    //包括了写hi,lo寄存器的使能信号，用于判断是否进行写寄存器的操作
    //以及将要写入hi,lo寄存器的值
    //如果不写，则此处为0，且使能信号为0
    assign wb_to_id_wf=
    {
        w_hi_we,
        w_lo_we,
        hi_i,
        lo_i
    };  //发送到regfile.v，内容同上
    assign wb_to_id_2=
    {
        w_hi_we,
        w_lo_we,
        hi_i,
        lo_i
    };  //发送到ID段
    //WB段要发送给ID段中的regfile.v
    //用于解决下一条指令要用到上一条指令存入hi,lo寄存器值的问题
    assign wb_to_rf_bus = {
        rf_we,
        rf_waddr,
        rf_wdata
    };
    assign wb_to_id_bus = {
        rf_we,
        rf_waddr,
        rf_wdata
    };  //发送到ID段
    //若当前指令需要取前面还未存入寄存器的值，则将指令由WB段提前发给ID段，
    //再由ID段发送到regfile.v文件中，进行赋给rs和rt所需要的寄存器的值
    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_wen = {4{rf_we}};
    assign debug_wb_rf_wnum = rf_waddr;
    assign debug_wb_rf_wdata = rf_wdata;
    
endmodule