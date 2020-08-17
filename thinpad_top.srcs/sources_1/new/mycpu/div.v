`timescale 1ns / 1ps
`include "defines.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/06/25 13:51:28
// Design Name: 
// Module Name: div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module div(
	input wire rst,							//��λ
	input wire clk,							//ʱ��
	input wire signed_div_i,						//�Ƿ�Ϊ�з��ų������㣬1λ�з���
	input wire[`RegBus] opdata1_i,				//������
	input wire[`RegBus] opdata2_i,				//����
	input wire start_i,						//�Ƿ�ʼ��������
	input wire annul_i,						//�Ƿ�ȡ���������㣬1λȡ��
	output reg[`DoubleRegBus] result_o,		//����������
	output reg ready_o		//���������Ƿ����
	
);
	
	wire [32:0] div_temp;
	reg [5:0] cnt;							//��¼���̷������˼���
	reg[64:0] dividend;						//��32λ����������м�������k�ε���������ʱ��dividend[k:0]����ľ��ǵ�ǰ�õ����м�����
											//dividend[31:k+1]������Ǳ�����û�в�������Ĳ��֣�dividend[63:32]��ÿ�ε���ʱ�ı�����
	reg [1:0] state;						//���������ڵ�״̬	
	reg[31:0] divisor;
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	
	assign div_temp = {1'b0, dividend[63: 32]} - {1'b0, divisor};
	
	
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			result_o <= {`ZeroWord,`ZeroWord};
			ready_o <= `DivResultNotReady;
		end else begin
			case(state)
			
				`DivFree: begin			//����������
					if (start_i == `DivStart && annul_i == 1'b0) begin
						if(opdata2_i == `ZeroWord) begin			//�������Ϊ0
							state <= `DivByZero;
						end else begin
							state <= `DivOn;					//������Ϊ0
							cnt <= 6'b000000;
							if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) begin			//������Ϊ����
								temp_op1 = ~opdata1_i + 1;
							end else begin
								temp_op1 = opdata1_i;
							end
							if (signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin			//����Ϊ����
								temp_op2 = ~opdata2_i + 1;
							end else begin
								temp_op2 = opdata2_i;
							end
							dividend <= {`ZeroWord, `ZeroWord};
							dividend[32: 1] <= temp_op1;
							divisor <= temp_op2;
						end
					end else begin
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
				`DivByZero: begin			//����Ϊ0
					dividend <= {`ZeroWord, `ZeroWord};
					state <= `DivEnd;
				end
				
				`DivOn: begin				//������Ϊ0
					if(annul_i == 1'b0) begin			//���г�������
						if(cnt != 6'b100000) begin
							if (div_temp[32] == 1'b1) begin
								dividend <= {dividend[63:0],1'b0};
							end else begin
								dividend <= {div_temp[31:0],dividend[31:0], 1'b1};
							end
							cnt <= cnt +1;		//�����������
						end	else begin
							if ((signed_div_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
								dividend[31:0] <= (~dividend[31:0] + 1);
							end
							if ((signed_div_i == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin
								dividend[64:33] <= (~dividend[64:33] + 1);
							end
							state <= `DivEnd;
							cnt <= 6'b000000;
						end
					end else begin	
						state <= `DivFree;
					end
				end
				
				`DivEnd: begin			//��������
					result_o <= {dividend[64:33], dividend[31:0]};
					ready_o <= `DivResultReady;
					if (start_i == `DivStop) begin
						state <= `DivFree;
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
			endcase
		end
	end


endmodule