module Register_File(
    input logic clk,reset,reg_wr,
    input logic [4:0] raddr1,raddr2,waddr,
    input logic [31:0] wdata,
    output logic [31:0] rdata1,rdata2
    ); 
    logic [31:0] registers [0:31];

    always_ff @ (negedge clk or posedge reset) begin
        if (reset) begin
            registers[0] <= 32'd0;
            registers[1] <= 32'd10;
            registers[2] <= 32'd20;
            registers[3] <= 32'd30;
            registers[4] <= 32'd40;
            registers[5] <= 32'd50;
            registers[6] <= 32'd60;
            registers[7] <= 32'd70;
            registers[8] <= 32'd80;
            registers[9] <= 32'd90;
            registers[10] <= 32'd100;
            registers[11] <= 32'd110;
            registers[12] <= 32'd120;
            registers[13] <= 32'd130;
            registers[14] <= 32'd140;
            registers[15] <= 32'd150;
            registers[16] <= 32'd160;
            registers[17] <= 32'd170;
            registers[18] <= 32'd180;
            registers[19] <= 32'd190;
            registers[20] <= 32'd200;
            registers[21] <= 32'd210;
            registers[22] <= 32'd220;
            registers[23] <= 32'd230;
            registers[24] <= 32'd240;
            registers[25] <= 32'd250;
            registers[26] <= 32'd260;
            registers[27] <= 32'd270;
            registers[28] <= 32'd280;
            registers[29] <= 32'd290;
            registers[30] <= 32'd300;
            registers[31] <= 32'd310;
        end
        else begin
            if(reg_wr)  
                registers[waddr] <= wdata;
            registers[0] <= 32'b0;
        end
    end

    always_comb begin
            rdata1 = registers[raddr1];
            rdata2 = registers[raddr2];
        end

    endmodule