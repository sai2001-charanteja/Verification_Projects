class packet;
  
  rand bit [7:0] data;
rand bit chance;
  rand bit [3:0] bit_pos;
  

  constraint c_main {
    $countones(data) == 5;
    chance dist {1:=80,0:=20};
    solve chance before data;
    if(chance){
      bit_pos inside {[0:3]};
      data[bit_pos+:5] == 5'b11111;
    }else{
			foreach (data[i]) {
      if (i <= 3)
        data[i +: 5] != 5'b11111;
    }

        }
    
  } 
        
  function void post_randomize();
    //$display("Actual count = %0d",temp);
      $display("Popcount = %10b - %0d",data,$countones(data));
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