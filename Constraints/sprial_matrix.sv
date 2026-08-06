class sprial_matrix;

    localparam int N = 5;
    localparam int M = 5;
    localparam int LAST = M*N;
    rand int arr[M][N];

    constraint c_arr{
        unique {arr};
        foreach(arr[i,j]) arr[i][j] inside {[1:LAST]};

        foreach(arr[i]){
            foreach(arr[j]){
                if(i<N/2 && j >i+1 && j < = N-1-i)
                    arr[i][j] = arr[i][j-1]+1;
            }
        }

    }

    function void post_randomize();
        foreach(arr[i]) begin
            foreach(arr[,j]) begin
               $write("%0d ",arr[i][j]); 
            end
            $display();
        end
    endfunction


endclass


module tb;

    initial begin
        sprial_matrix mat;

        mat = new();

        repeat(10) begin
            mat.radomize();
        end         

    end
endmodule