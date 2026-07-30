`timescale 10ns/1ns
module tb;
  	
	logic clk,rst;
	logic [31:0] baud;
	logic tx_clk;
	
  logic [3:0][31:0] baud_rates = {32'd4800,32'd9600,32'd19200,32'd38400}; 
	
	clk_generator c_gen(.clk(clk),.rst(rst),.baud(baud),.tx_clk(tx_clk));
	
	always #1 clk = !clk;
	
	int temp;
	
	initial begin
		clk = 0;
		rst = 1;
		repeat(2) @(posedge clk);
		rst = 0;
		
		repeat(10) begin
			
			baud = baud_rates[$urandom_range(0,3)];
          foreach(baud_rates[i]) begin
            $display("Baudrate %0d %0d",i,baud_rates[i]);
          end
          //$finish;
			//#10000;
			case(baud)
				4800: 	temp = 10416;
				9600: 	temp = 5208;
				19200:	temp = 2604;
				38400:	temp = 1302;
			endcase
          @(posedge tx_clk);
          repeat(temp/2)@(posedge clk);
          @(posedge clk);
          $display("Time = %0t" ,$time);
          assert(!tx_clk)
            else $display("Failed to toggle for baud %0d at time = %0t",baud,$time);
          repeat(temp/2+2)@(posedge clk);
		end
		
		$finish;
	end
	
	

  	initial begin
      $dumpfile("file.vcd");
      $dumpvars();
      
    end



	
	
	

endmodule