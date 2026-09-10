`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 08:55:39
// Design Name: 
// Module Name: InsBenchmark
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


module InsBenchmark(

    );

    function check(input[31:0] pc,input[31:0] x1,input[31:0] x2,input[31:0] x3,input[31:0] pca,input[31:0] x1a,input[31:0] x2a,input[31:0] x3a);
    begin
        if((pc==pca)&&(x1==x1a)&&(x2==x2a)&&(x3==x3a)) 
            check=1'b1;
        else
            check=1'b0;
    end
    endfunction
    reg clk=1'b0;
    always #5
        clk=~clk;        
    
    reg test=1'b0;
    reg[4:0] count=5'b0;
    parameter allins=5'h1a;
    wire[31:0] pc,x1,x2,x3,pca,x1a,x2a,x3a;
    
    assign pc=t.addr;
    assign x1=t.mycpu.myrf.regs[1];
    assign x2=t.mycpu.myrf.regs[2];
    assign x3=t.mycpu.myrf.regs[3];
    
    testcase tc(
        .index(count),
        .pc(pca),
        .x1(x1a),
        .x2(x2a),
        .x3(x3a)
    );
    
    
    always @(posedge clk)
    begin
        if(pc>32'h00400000)  //从第二个周期开始测试，因为第一天指令要在下一个周期获取结果
        begin
            test=check(pc,x1,x2,x3,pca,x1a,x2a,x3a);
            if(test==1'b1) count=count+5'b1;else $finish;            
        end

        case (count)
            5'h1:$display($time,,"1. ori success!");
            5'h2:$display($time,,"2. lui success!");
            5'h4:$display($time,,"3. xori success!");
            5'h5:$display($time,,"4. slli success!");
            5'h6:$display($time,,"5. addi success!");
            5'h7:$display($time,,"6. sll success!");
            5'h8:$display($time,,"7. add success!");
            5'h9:$display($time,,"8. srli sucess!");
            5'ha:$display($time,,"9. srai sucess!");
            5'hb:$display($time,,"10. xor success!");
            5'hc:$display($time,,"11. srl success!");
            5'hd:$display($time,,"12. sra success!");
            5'he:$display($time,,"13. andi success!");
            5'hf:$display($time,,"14. beq not jump success!");
            5'h10:$display($time,,"15. or success!");
            5'h11:$display($time,,"16. beq jump success!");
            5'h12:$display($time,,"17. blt jump success!");
            5'h13:$display($time,,"18. sub success!");
            5'h14:$display($time,,"19. bltu not jump success!");
            5'h15:$display($time,,"20. bltu jump success!");
            5'h16:$display($time,,"21. blt not jump success!");
            5'h17:$display($time,,"22. and success!");
            5'h18:$display($time,,"23. sw success!");
            5'h19:$display($time,,"24. lw success!");
            5'h1a:$display($time,,"25. jal success!");
            default:$display($time,,"-------------");
        endcase
        if(count>=allins) 
        begin
            $display("Congratulations! all instructions passed the test!!!");
            $display("----------------------2023.9.10---------------------");
            $finish;
        end
    end
        
    reg rst=1'b0;
    initial
    begin
        #4 rst=1'b1;
        #2 rst=1'b0;
    end   
    
    top t(
        .clk(clk),
        .rst(rst)
    );

     


     
endmodule
