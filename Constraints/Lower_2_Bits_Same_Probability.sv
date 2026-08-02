class packet;
    /*
    Write uvm sv constraint on 4-bit variable such that 
    the probability of lower two bits being equal is 5%. Lower bits equal means x[1:0] is 00 or 11. 
    Remaining 95% covers patterns 01 and 10.
    */

  rand bit [3:0] x;
  rand bit choice;

  constraint c_main {
    choice dist {1'b1:=5,1'b0:=95};
  }
	
  constraint c_choice{
    if(choice)
      x[1:0] inside {0,3};
      else
      x[1:0] inside {1,2};
  } 
  
  function void post_randomize();
    $display("x[1:0] = %2b",x[1:0]);
    if(x[1]==x[0])
      $display("*********");
  endfunction
endclass

//without an Extra varibale
class packet;


  rand bit [3:0] x;

  constraint c_main {
    (x[0]==x[1]) dist {1'b1:=5,1'b0:=95};
  }
  
  function void post_randomize();
    $display("x[1:0] = %2b",x[1:0]);
    if(x[1]==x[0])
      $display("*********");
  endfunction
endclass

module tb;
  
  initial begin
    packet pkt;
    
    pkt = new();
    
    
    repeat(100) begin
      
      pkt.randomize();
    end
    
  end
  
endmodule



