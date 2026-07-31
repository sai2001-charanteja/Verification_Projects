/*
Write uvm sv constraint for 8-bit variable where next value parity depends on previous value: 
(1) If previous value was odd, next value is even with 75% probability, 
(2) If previous value was even, next value is even with 25% probability. 
Maintain state between randomizations.
*/


module tb;
  class temp;
  	  rand bit [7:0] val;
         bit [7:0] prev_val;

    function new();
        prev_val = 8'h00;      // initial previous value
    endfunction

    constraint parity_c {

        if ($countones(prev_val)%2)
            ($countones(val)%2) dist {0 := 75,
                                      1 := 25};

        else
            ($countones(val)%2) dist {0 := 25,
                                      1 := 75};
    }

    function void post_randomize();
        prev_val = val;
      $display("%0b - %0d",val,^val);
    endfunction
   
  endclass
  temp t;
  
  
  initial begin
    t = new;
    repeat(100)
  	  t.randomize();
    
  end
  
endmodule