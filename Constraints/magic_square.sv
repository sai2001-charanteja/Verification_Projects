/* Magic square */
class packet;
  
  localparam int N = 5;
  localparam int MAX_SUM = 10;
  
  rand bit[7:0] mat[N][N];
  rand bit[7:0] mat_t[N][N]; // transpose
  rand bit[7:0] diag[N];
  rand bit[7:0] diag_t[N];
  constraint c_row_col_diag_sum {
    
    foreach(mat[i]) mat[i].sum() with (int'(item)) == MAX_SUM;

    foreach(mat_t[i]) mat_t[i].sum() with (int'(item)) == MAX_SUM;

    diag.sum() with (int'(item)) == MAX_SUM;

    diag_t.sum() with (int'(item)) == MAX_SUM;
  }
  
  constraint c_equate{

    foreach(mat[i,j]) mat[i][j] == mat_t[j][i];
    
    foreach(mat[i]) mat[i][i] == diag[i];
    
    foreach(mat[i]) mat[i][N-1-i] == diag_t[i];
  }

  function void post_randomize();
    foreach(mat[i])
      $display("%0p",mat[i]);
    $display("--");
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