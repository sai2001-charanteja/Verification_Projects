// Code your testbench here
// or browse Examples
/*
Question 1:
Given an input array, randomly map elements to N output queues
 (N parameterized). Use UVM SystemVerilog constraints so that:
  (1) each input element appears in exactly one output queue, 
  (2) all N output queues are non-empty, and
   (3) feasibility requires N ≤ input_size.
*/
      
      
module tb;
  class temp;
  
    localparam int N = 20;
    localparam int M = 10;
    rand bit [7:0] arr[N];
    rand bit [$clog2(M)-1:0]que[N];
    bit [7:0] outp_que[M][$];

    constraint c_main {
        foreach(arr[i])
        arr[i] inside {[0:200]};

        foreach(que[i]){
        que[i] inside {[0:M-1]};
        if(i<M)
            que.sum() with (int'(item == i)) >= 1; 
        }
    }

    function void post_randomize();
        foreach(outp_que[i])
        outp_que[i].delete();

        foreach(que[i])begin
        outp_que[que[i]].push_back(arr[i]);
        end

        $display("que = %0p",que);
        $display("Actual array = %0p",t.arr);

        foreach (outp_que[i]) begin
        $display("Queue %0d (size=%0d): %p",
                i, outp_que[i].size(), outp_que[i]);
        end
  endfunction
endclass
  temp t;
  
  initial begin
    t = new;
    repeat(10)
    t.randomize();
  end
  
endmodule
