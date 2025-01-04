`timescale 1ns / 1ps
module mul_plus(
    //时钟信号
    input clk,
    //开始标志
    input start_i,
    //是否为有符号乘法
    input mul_sign,
    //操作数1
    input [31:0] opdata1_i,
    //操作数2
    input [31:0] opdata2_i,
    //结果
    output [63:0] result_o,
    //结束标志
    output        ready_o
    );
    //状态标志，计算时为1
    reg judge;
    //被乘数
    reg  [63:0] multiplicand;
    //乘数
    reg [31:0] multiplier;
    //存储被乘数的临时变量
    wire [63:0] temporary_value;
    //临时结果
    reg [63:0] mul_temporary;
    //结果符号
    reg result_sign;
    //更新状态
    always @(posedge clk) begin
        if (!start_i || ready_o) begin
            judge <= 1'b0;
        end
        else begin
            judge <= 1'b1;
        end
    end

    wire op1_sign;
    wire op2_sign;
    wire [31:0] op1_absolute;
    wire [31:0] op2_absolute;
    //判断两个操作数的符号，并获取其绝对值
    assign op1_sign = mul_sign & opdata1_i[31];
    assign op2_sign = mul_sign & opdata2_i[31];
    assign op1_absolute = op1_sign ? (~opdata1_i+1) : opdata1_i;
    assign op2_absolute = op2_sign ? (~opdata2_i+1) : opdata2_i;

    always @ (posedge clk) begin //处理被乘数
        if (judge) begin
            multiplicand <= {multiplicand[62:0],1'b0};  //左移1位
        end
        else if (start_i) begin
            multiplicand <= {32'd0,op1_absolute};
        end
    end
    
    always @ (posedge clk) begin //处理乘数
        if(judge) begin
            multiplier <= {1'b0,multiplier[31:1]};  //右移1位
        end
        else if(start_i) begin
            multiplier <= op2_absolute;
        end
    end
    //若当前时钟周期的乘数末位为1，则将当前时钟周期的被乘数加到临时结果上
    assign temporary_value = multiplier[0] ? multiplicand : 64'd0;
    always @ (posedge clk) begin
        if (judge) begin
            mul_temporary <= mul_temporary + temporary_value;
        end      
        else if (start_i) begin
            mul_temporary <= 64'd0;
        end
     end
     
    always @ (posedge clk) begin    //获取结果符号
        if (judge) begin
              result_sign <= op1_sign ^ op2_sign;
        end
    end 
    //计算结果
    assign result_o = result_sign ? (~mul_temporary+1) : mul_temporary;
    assign ready_o  = judge & multiplier == 32'b0;
endmodule
