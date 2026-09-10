`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/11 13:15:19
// Design Name: 
// Module Name: sim
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


module sim(

    );
    reg clk=1'b0,rst=1'b1;
    always #10
        clk=~clk;
        
    initial
    begin
        #11 rst=1'b0;
    end
    
    top t(
        .clk(clk),
        .rst(rst)
    );
        
endmodule
