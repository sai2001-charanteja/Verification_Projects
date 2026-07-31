module tb;
  class temp;
    
  rand bit [7:0] arr1[];
  rand bit [7:0] arr2[];
    
  constraint c_main {
    arr1.size() inside {[6:9]};
    arr2.size() == arr1.size();
    foreach(arr1[i]){
      if(i>0)
        arr1[i] >= arr1[i-1];
      arr2[i] inside {arr1};
    }
    
  }

    function void post_randomize();
      $display("Arr1 = %0p",arr1);
      $display("Arr2 = %0p",arr2);
    endfunction
endclass
  temp t;
  
  
  initial begin
    t = new;
    repeat(10)
    t.randomize();
  end
  
endmodule