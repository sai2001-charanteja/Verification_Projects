// Code your testbench here
// or browse Examples
/* Magic Square*/

class packet;
  
  localparam int N = 6;
  localparam int MAX_SUM = N * (N*N + 1) / 2;
  
  rand bit [7:0] mat[N][N];
  rand bit [7:0] mat_column[N][N];
  rand bit [7:0] diagonal[N];
  rand bit [7:0] diagonal_t[N];
  
  function new();
    
  endfunction
  
  constraint c_valid {

  // Elements 1 ... N²
  foreach(mat[i,j])
    mat[i][j] inside {[1:N*N]};

  // All elements unique
  unique {mat};


  // Row sums
  foreach(mat[i])
  {
   mat[i].sum() with (int'(item)) == MAX_SUM;
    mat_column[i].sum() with (int'(item)) == MAX_SUM;
  }


  foreach(mat[i,j]) {
    mat[j][i] == mat_column[i][j];
   
  }


  // Main diagonal mapping
  foreach(diagonal[i])
    diagonal[i] == mat[i][i];

  diagonal.sum() with (int'(item)) == MAX_SUM;


  // Anti-diagonal mapping
  foreach(diagonal_t[i])
    diagonal_t[i] == mat[i][N-1-i];

  diagonal_t.sum() with (int'(item)) == MAX_SUM;

}
  
  function void pre_randomize();
    
  endfunction
  
  function void post_randomize();
    bit[31:0] column_sum[N];
    bit [31:0] temp_sum;
    //foreach(column_sum[i])
    foreach(mat[i]) begin
      temp_sum = 0;
      foreach(mat[,j]) begin
        $write("%3d ",mat[i][j]);
        column_sum[j] += mat[i][j];
        temp_sum += mat[i][j];
      end
      $display(" - %3d",temp_sum);
    end
    foreach(column_sum[i])
      $write("%3d ",column_sum[i]);
    $display();
    $display("-----------------------");
  endfunction
  
  
  
endclass


class test #(int N = 4);
  localparam int MAX_SUM = N * (N*N + 1) / 2;

  rand int arr[N][N];

  constraint c_range {
    foreach (arr[i,j])
      arr[i][j] inside {[1:N*N]};
  }

  constraint c_unique { unique {arr}; }

  constraint c_rows_cols {
    foreach (arr[i]) {                             // single index, not [i,j]
      arr[i].sum() with (int'(item))    == MAX_SUM; // row i
      arr.sum()    with (int'(item[i])) == MAX_SUM; // column i
    }
  }

  constraint c_diag {                               // no loop — each is one constraint
    arr.sum() with (int'(item[item.index]))     == MAX_SUM; // main diagonal
    arr.sum() with (int'(item[N-1-item.index])) == MAX_SUM; // anti-diagonal
  }
      
      
  function void post_randomize();
  bit[31:0] column_sum[N];
    bit [31:0] temp_sum;
    //foreach(column_sum[i])
    foreach(arr[i]) begin
      temp_sum = 0;
      foreach(arr[,j]) begin
        $write("%3d ",arr[i][j]);
        column_sum[j] += arr[i][j];
        temp_sum += arr[i][j];
      end
      $display(" - %3d",temp_sum);
    end
    foreach(column_sum[i])
      $write("%3d ",column_sum[i]);
    $display();
    $display("-----------------------");
  endfunction 
endclass


class sudoku;
	
	localparam int N = 9;
	localparam int M = 3;
	rand int arr[N][N];
	
	constraint cvalid{
		foreach(arr[i,j]) arr[i][j] inside {[1:N]};
		foreach(arr[i]){
			unique {arr[i]};
		}
		foreach(arr[i,j]){
			foreach(arr[k]){
				if(k>i)
					arr[i][j] != arr[k][j];
			}
		}
		
		foreach(arr[i,j])
			foreach(arr[k,l]){
				if((i!=k && j!=l) && i/3 == k/3 && j/3 == l/3)
					arr[i][j] != arr[k][l];
			}
				
		
	}
	
	function void post_randomize();
		$display("\n------------------------");
		foreach(arr[i]) begin
			$write("|");
			foreach(arr[,j]) begin
				$write("%1d ",arr[i][j]);
				
				if(j%3 == 2)
					$write("| ");
			end
			if(i%3==2)
				$display("\n------------------------");
			else
				$display();
		end
		
	endfunction

endclass
            
      
module tb;
  
  initial begin
    time start_time;
time end_time;
    packet pkt;
    test t;
	sudoku sud;
    t = new();
    pkt = new();
	sud = new();
    
    
    repeat(10) begin
      $display("Start Randoomization");

    //start_time = $time;
   // pkt.randomize();
     // t.randomize();
	  sud.randomize();
    //end_time = $time;

    //$display("Randomization time = %0t", end_time - start_time);
     
      
    end
    
  end
  
endmodule
