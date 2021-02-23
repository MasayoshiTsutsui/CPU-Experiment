`timescale 1ns / 100ps
`default_nettype none

module fmul_p1  //overflow��?????�����͖���`�Bunderflow��?????0�ɂ����?????���K�����̊|���Z�ɂ͑Ή�???
    (input wire clk,
     input wire [31:0] x1,
     input wire [31:0] x2,
     output wire [31:0] y); //caution! not "reg" but "wire"!
    
    wire sign1; //x1�̕���bit
    wire sign2; //x2�̕���bit
    wire [7:0] exp1; //x1��????����
    wire [7:0] exp2; //x2��????����
    reg [7:0] exp1reg; //x1��????����
    reg [7:0] exp2reg; //x2��????����
    wire [22:0] mant1; //x1�̉�����
    wire [22:0] mant2; //x2�̉�����
    
    wire [12:0] mant1_hi;
    wire [10:0] mant1_lo;
    wire [12:0] mant2_hi;
    wire [10:0] mant2_lo;

    wire [25:0] hh;
    wire [23:0] hl;
    wire [23:0] lh;

    reg [25:0] hhreg;
    reg [23:0] hlreg;
    reg [23:0] lhreg;

    wire [8:0] exp_assumed; //underflow�ɔ�����1bit�g��
    reg [8:0] exp_assumedreg; //underflow�ɔ�����1bit�g��
    wire [8:0] exp_assumed_carried;
    wire [25:0] mant_assumed;

    wire ans_sign; //�����̕���
    reg ans_signreg;
    wire [7:0] ans_exp;
    wire [22:0] ans_mant;
    
    assign {sign1, exp1, mant1} = x1;
    assign {sign2, exp2, mant2} = x2;

    wire [8:0] exp_sum; //����?????��????������????.���オ���????������9????
    reg [8:0] exp_sumreg;

    assign {mant1_hi, mant1_lo} = {1'b1, mant1};
    assign {mant2_hi, mant2_lo} = {1'b1, mant2};

    assign exp_sum = {1'b0,exp1} + {1'b0,exp2};


    assign hh = {13'b0,mant1_hi} * mant2_hi;
    assign hl = {11'b0,mant1_hi} * mant2_lo;
    assign lh = {11'b0,mant2_hi} * mant1_lo;
    assign exp_assumed = exp_sum - 9'd127;
    assign ans_sign = sign1 ^ sign2;

    always @(posedge clk) begin
        hhreg <= hh;
        hlreg <= hl;
        lhreg <= lh;
        exp_assumedreg <= exp_assumed;
        ans_signreg <= ans_sign;
        exp_sumreg <= exp_sum;
        exp1reg <= exp1;
        exp2reg <= exp2;
    end 


    assign mant_assumed = hhreg + (hlreg >> 4'd11) + (lhreg >> 4'd11) + 2'd2;
    assign exp_assumed_carried = exp_assumedreg + 1'd1;


    wire [1:0] underflow; //????�����̘a��128�ȏ�ł����0(underflow����????��????), 127�ł����1(�����������carry������?????underflow�����ɍ�??), 127��????�ł����2(�m����underflow����)

    assign underflow = (exp_sumreg == 9'd127) ? 2'b01 : //????�����̘a��127��????
                       ((exp_sumreg[8] == 1'b1 || exp_sumreg[7] == 1'b1) ? 2'b00 : 2'b10); //????�����̘a�����オ�肵��????��Ƃ�?????,-127���Ă�underflow������????�̂�0.
    
    
    assign {ans_exp, ans_mant} = (exp1reg == 8'b0 || exp2reg == 8'b0) ? 31'b0 : //x1,x2�̂ǂ��炩��������????0��????0
                     ((underflow == 2'b01 && mant_assumed[25] == 1'b1) ? {exp_assumed_carried[7:0], mant_assumed[24:2]} : //????�����̘a��127�҂�����ŁA�����������carry������?????��?????�A���肬��underflow��?????��??
                     ((underflow == 2'b10 || underflow == 2'b01) ? {8'b0, 23'b0} : //underflow�m���Ȏ�?????0�Ŗ���????
                     ((mant_assumed[25] == 1'b1) ? {exp_assumed_carried[7:0], mant_assumed[24:2]} : //underflow�Ȃ��ŁAcarry�����鎞
                     {exp_assumedreg[7:0], mant_assumed[23:1]}))); //underflow�Ȃ�?????carry����????
    
    assign y = {ans_signreg, ans_exp, ans_mant};
    //always @(posedge clk) begin
        //y <= {ans_signreg, ans_exp, ans_mant};
    //end 


endmodule


`default_nettype wire