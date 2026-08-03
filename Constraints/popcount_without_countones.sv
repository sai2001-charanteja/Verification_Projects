class packet;
  
  rand bit [10]popcount;
  rand bit helper [10];
  rand bit [$clog2(10)-1:0] temp;

  constraint c_main {
    popcount inside {[1:$]}; // excluded countones == 0;
    temp dist {[1:10]:=10};
    helper.sum() with (int'(item)) == temp;
    
    foreach(helper[i])
      helper[i] == popcount[i];
    
  }
  
  function void post_randomize();
    $display("Actual count = %0d",temp);
    $display("Popcount = %10b - %0d",popcount,$countones(popcount));
  endfunction
  
endclass

module tb;
  
  initial begin
    packet pkt;
    pkt =new;
    
    repeat(10) begin
      pkt.randomize();
    end
  end
  
endmodule