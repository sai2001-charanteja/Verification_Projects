/* Sudoku 
  With and without unique keyword

  with O(n) and O(1) memory complexity
 */
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


class packet;
  
  localparam int N = 9;
  
  rand bit[3:0] mat[N][N];
  rand bit [3:0] mat_t[N][N];
  
  rand bit [3:0] sub_mat[N][N];
  
  
  constraint c_unique_rows {
    foreach(mat[i,j]) mat[i][j] inside {[0:N-1]};
    
    foreach(mat[i]) unique {mat[i]};
    
    foreach(mat[i]) unique {mat_t[i]};
    
    foreach(mat[i]) unique {sub_mat[i]};
    
    
  }
  
  constraint c_copy_equate{
    
    foreach(mat[i,j]) mat[i][j] == mat_t[j][i];
    
    foreach(mat[i,j]){
      sub_mat[(i/3)*3 + j/3][(i%3)*3 + j%3] == mat[i][j]; 
    }
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



class packet;
  
  localparam int N = 9;
  
  rand bit[3:0] mat[N][N];
  
  
  constraint c_unique_rows {
    
    
    foreach(mat[i,j]){
      mat[i][j] inside {[1:N]};
      foreach(mat[,k])
            if(j!=k)
              mat[i][j] != mat[i][k];
    }
      
    foreach(mat[i,j]){
      foreach(mat[k,])
        	if(i!=k)
              mat[i][j] != mat[k][j];
    }
      
      
      foreach(mat[i,j]){
        foreach(mat[k,l]){
          // Looks complex 
          if((k>=((i/3) *3)) && (k<(((i/3)+1) *3))&& ( l>= ((j/3) * 3)) && (l< ((j/3)+1)*3) && (i!=k) && (j!=l))
            mat[i][j] != mat[k][l];
        }
      }
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