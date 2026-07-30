 /////////////////////////////////////////////////////////////////////
interface uart_if(input clk);
 logic  rst;
 logic tx_start, rx_start;
 logic [7:0] tx_data;
 logic [16:0] baud;
 logic [3:0] length;
 logic parity_type, parity_en;
 logic stop2;
 logic tx_done,rx_done, tx_err,rx_err;
 logic [7:0] rx_out;   

endinterface

import uvm_pkg::*;
`include "uvm_macros.svh"


class transaction extends uvm_sequence_item;
	`uvm_object_utils(transaction)
	rand bit rst;
	rand bit tx_start, rx_start;
	rand bit [7:0] tx_data;
	rand bit [16:0] baud;
	rand bit [3:0] length;
	rand bit parity_type, parity_en;
	rand bit stop2;
	
	bit tx_done,rx_done, tx_err,rx_err;
	bit [7:0] rx_out;   
	
	int prev_baud;
	
	function new(string name="transaction");
		super.new(name);	
	endfunction
	
	constraint valid {
	
		tx_data inside {[0:$]};
	
		baud inside {4800,9600,14400,19200,38400,57600,115200,128000};
		//baud inside {57600,115200,128000};
		
		(baud != prev_baud);
		(tx_start == rx_start);
		tx_start == 1'b1;
		length >4;
		length <=8;
		
	}
	
	function void post_randomize();
		prev_baud = baud;
	endfunction
	
	function string convert2string();
		return $sformatf("TX_Start(%0d),RX_Start(%0d), data(%0d), rx_out(%0d), length(%0d), parity_type(%0d_%0d), stop2(%0d), rx_done(%0d), tx_done(%0d), tx_err(%0d), rx_err(%0d)",tx_start,rx_start,tx_data,rx_out,length,parity_en,parity_type,stop2,rx_done,tx_done,tx_err,rx_err);
	endfunction
	
	function bit compare_with_receiver_transaction(transaction tr);
      if(tr.rx_err === 1'b1) begin
			`uvm_info("COMP","Error in received transaction",UVM_NONE)
			return 1'b0;
		end
		
      return (tr.rx_out == this.tx_data);
		
	endfunction
	
	
	
	function void copy(transaction tr);
		this.rst = tr.rst;
		this.tx_start= tr.tx_start ;
		this.rx_start= tr.rx_start ;
		this.tx_data= tr.tx_data ;
		this.baud= tr.baud ;
		this.length= tr.length ;
		this.parity_type= tr.parity_type ;
		this.parity_en= tr.parity_en ;
		this.stop2= tr.stop2 ;
		this.tx_done= tr.tx_done ;
		this.rx_done= tr.rx_done ;
		this.tx_err= tr.tx_err ;
		this.rx_err= tr.rx_err ;
		this.rx_out= tr.rx_out ; 
	endfunction
	
endclass


class reset_sequence extends uvm_sequence#(transaction);
	`uvm_object_utils(reset_sequence)
	transaction tr;
	
	function new(string name="reset_sequence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	
	virtual task body();
		//`uvm_do(tr);
		repeat(10) begin
			tr = transaction::type_id::create("tr");
			start_item(tr);
			tr.rst = 1'b1;
			finish_item(tr);
		end
	endtask
	
endclass

class main_sequence extends uvm_sequence#(transaction);
	`uvm_object_utils(main_sequence)
	transaction tr;
	
	function new(string name="main_sequence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	virtual task pre_start();
		tr = transaction::type_id::create("tr");
	endtask
	
	virtual task body();
		//`uvm_do(tr);
		repeat(10) begin
			start_item(tr);
			assert(tr.randomize() with {rst == 1'b0;})
			else `uvm_error("MAIN_SEQ","Randomization Failed")
			finish_item(tr);
		end
	endtask
	
endclass


class driver extends uvm_driver#(transaction);
	`uvm_component_utils(driver)
	
	transaction tr;
	
	virtual uart_if uif;
	
	int transaction_id;
	
	function new(string name="driver",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual uart_if)::get(this,"","uif",uif))
			`uvm_error("DRVR","Unable to find in configdb")
		
		tr = transaction::type_id::create("tr");
		transaction_id = 0;
	endfunction
		
	virtual task run_phase(uvm_phase phase);
		forever begin
			seq_item_port.get_next_item(tr);
			drive(tr);
			seq_item_port.item_done();
		end
	endtask
	
	task drive(transaction tr);
		transaction_id++;
		if(tr.rst == 1'b1) begin
			`uvm_info("DRVR",$sformatf("[%0t] Driving of Reset transaction(%0d) is started",$time,transaction_id),UVM_MEDIUM)
			uif.rst <= 1'b1;
          repeat(2) @(posedge uif.clk);
			`uvm_info("DRVR",$sformatf("[%0t] Driving of Reset transaction(%0d) is completed",$time,transaction_id),UVM_MEDIUM)
		end
		else begin
			`uvm_info("DRVR",$sformatf("[%0t] Driving of transaction(%0d) is started",$time,transaction_id),UVM_MEDIUM)
			uif.rst <= 1'b0;
			uif.tx_start <= tr.tx_start;
			uif.rx_start <= tr.rx_start;
			uif.tx_data <= tr.tx_data;
			uif.baud <= tr.baud;
			uif.length <= tr.length;
			uif.parity_en <= tr.parity_en;
			uif.parity_type <= tr.parity_type;
			uif.stop2 <= tr.stop2;
			
			@(uif.tx_done);
			@(uif.rx_done);
			
			repeat(100) @(posedge uif.clk);
			
			`uvm_info("DRVR",$sformatf("[%0t] Driving of transaction(%0d) is completed",$time,transaction_id),UVM_MEDIUM)
		end
		
	endtask
	
endclass


class monitor extends uvm_monitor;
	`uvm_component_utils(monitor)
	uvm_analysis_port#(transaction) send;
	virtual uart_if uif;
	transaction tr;
	
	function new(string name="monitor",uvm_component parent= null);
		super.new(name,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!uvm_config_db#(virtual uart_if)::get(this,"","uif",uif))
			`uvm_error("MON","Unable to access interface")
		
		//tr = transaction::type_id::create("tr");
		send = new("send",this);
	endfunction

	virtual task run_phase(uvm_phase phase);
		bit temp_rx_error;
		bit temp_tx_error;
		forever begin
			temp_tx_error = 1'b0;
			temp_rx_error = 1'b0;
			tr = transaction::type_id::create("tr");
			@(uif.clk);
			if(uif.rst === 1'b1) begin
				tr.rst = uif.rst;
				tr.rx_out = uif.rx_out;
				tr.rx_err = uif.rx_err;
				tr.tx_err = uif.tx_err;
				tr.rx_done = uif.rx_done;
				tr.tx_done = uif.tx_done;
			end else begin
				tr.rst = uif.rst;
				wait(uif.tx_start == 1'b1);
				wait(uif.rx_start == 1'b1);
				if(uif.tx_start && uif.rx_start) begin
					//@(negedge tx);
					while(!uif.tx_done) begin
						if(!temp_tx_error) begin
							temp_tx_error = uif.tx_err;
						end else begin
							temp_tx_error = temp_tx_error;
							break;
						end
						
						@(uif.clk);
					end
					
					wait(uif.tx_done === 1'b1);
					
					tr.tx_start = uif.tx_start;
					tr.rx_start = uif.rx_start;
					tr.tx_data = uif.tx_data;
					tr.baud = uif.baud;
					tr.length = uif.length;
					tr.parity_type = uif.parity_type;
					tr.parity_en = uif.parity_en;
					tr.stop2 = uif.stop2;
					
					
					
					while(!uif.rx_done) begin
						if(!temp_rx_error) begin
							temp_rx_error = uif.rx_err;
						end else begin
							temp_rx_error = temp_rx_error;
							break;
						end
						
						@(uif.clk);
					end
					
					wait(uif.rx_done === 1'b1);
					
					//@(negedge uif.tx_done);
					tr.tx_err = temp_tx_error;
					tr.rx_err = temp_rx_error;
					tr.tx_done = uif.tx_done;
					tr.rx_done = uif.rx_done;
					tr.rx_out = uif.rx_out;
					@(negedge uif.rx_done);
					@(negedge uif.tx_done);
				end
			end
			send.write(tr);
		end
	
	endtask
endclass


class agent extends uvm_agent;
	`uvm_component_utils(agent)
	
	uvm_sequencer#(transaction) seqr;
	driver drvr;
	monitor mon;
	uvm_analysis_port#(transaction) pass_through_port;
	
	function new(string name = "agent",uvm_component parent= null);
		super.new(name,parent);	
	endfunction
	
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		seqr = uvm_sequencer#(transaction)::type_id::create("tr",this);
		drvr = driver::type_id::create("drvr",this);
		mon = monitor::type_id::create("mon",this);
		
		pass_through_port = new("pass_through_port",this);
	endfunction
	
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		drvr.seq_item_port.connect(seqr.seq_item_export);
		mon.send.connect(pass_through_port);
	endfunction
	
endclass


class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)
	
	uvm_analysis_imp#(transaction,scoreboard) imp;
	transaction tr;
	int matched;
	int mis_matched;
	function new(string name="scoreboard",uvm_component parent= null);
		super.new(name,parent);
	endfunction 
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		imp = new("imp",this);
		tr = transaction::type_id::create("tr");
		matched=0;
		mis_matched =0;
	endfunction
	
	function void write(transaction rec_tr);
		tr.copy(rec_tr);
		if(tr.rst) begin
			if((tr.rx_out  == 1'b0) &&
			(tr.rx_err  == 1'b0) &&
			(tr.tx_err  == 1'b0) &&
			(tr.rx_done == 1'b0) &&
			(tr.tx_done == 1'b0)) matched++;
				else begin
					`uvm_info("SCB","Reset Failed",UVM_NONE)
					mis_matched++;
				end
		end else begin
			
			if(tr.tx_err || tr.rx_err) begin
				`uvm_info("SCB","Received an error transaction",UVM_NONE)
				mis_matched++;
			end else begin
				if(tr.tx_done==1'b1 && tr.rx_done==1'b1) begin
					
					case(tr.length)
						5: if({3'd0,tr.tx_data[4:0]} == tr.rx_out) matched++;
							else begin
								mis_matched++;
								`uvm_info("SCB","Transmitted and received data is not matching",UVM_NONE)
							end
						6: if({2'd0,tr.tx_data[5:0]} == tr.rx_out) matched++;
							else begin
								mis_matched++;
								`uvm_info("SCB","Transmitted and received data is not matching",UVM_NONE)
							end
						7: if({1'b0,tr.tx_data[6:0]} == tr.rx_out) matched++;
							else begin
								mis_matched++;
								`uvm_info("SCB","Transmitted and received data is not matching",UVM_NONE)
							end
						8: if(tr.tx_data == tr.rx_out) matched++;
							else begin
								mis_matched++;
								`uvm_info("SCB","Transmitted and received data is not matching",UVM_NONE)
							end
					endcase
					
					
				end else begin
					`uvm_info("SCB","Received an unfinished transaction",UVM_NONE)
					mis_matched++;
				end
			end
		
		end
		
	endfunction
	
	
	function void extract_phase(uvm_phase phase);
		string temp = $sformatf("The number of Matched transaction = %0d\n \
								The number of Mis_matched transactions = %0d\n \
								****************** TEST %0s ************************",matched,mis_matched,(mis_matched==0)?"PASS":"FAIL");
		`uvm_info("SCB",temp,UVM_NONE)
	endfunction
	
endclass


class test extends uvm_test;
	`uvm_component_utils(test)
	
	agent agnt;
	
  	reset_sequence rst_seq;
  	main_sequence main_seq;
	
	scoreboard scb;
	
	function new(string name = "test",uvm_component parent=null);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agnt = agent::type_id::create("agnt",this);
	
      //uvm_config_db#(uvm_object_wrapper)::set(this,"agnt.seqr.reset_phase","default_sequence",reset_sequence::get_type());
      //uvm_config_db#(uvm_object_wrapper)::set(this,"agnt.seqr.main_phase","default_sequence",main_sequence::get_type());
      rst_seq = reset_sequence::type_id::create("rst_seq");
      main_seq = main_sequence::type_id::create("main_seq");
	  scb = scoreboard::type_id::create("scb",this);
    endfunction
  	
	function void connect_phase(uvm_phase phase);
		
		agnt.pass_through_port.connect(scb.imp);
	
	endfunction
	
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this,"Starting my sequence");
    rst_seq.start(agnt.seqr);
    main_seq.start(agnt.seqr);
	#10000
    phase.drop_objection(this,"finishing my sequence");
  endtask
  
	
endclass


module top;
	
	logic clk;
	
  uart_if uif(clk);
	
	
	always #1 clk = !clk;

    
	uart_top uart_top_inst
			(
			.clk(clk),
			.rst(uif.rst), 
			.tx_start(uif.tx_start),
			.rx_start(uif.rx_start),
			.tx_data(uif.tx_data),
			.baud(uif.baud),
			.length(uif.length),
			.parity_type(uif.parity_type),
			.parity_en(uif.parity_en),
			.stop2(uif.stop2),
			.tx_done(uif.tx_done),
			.rx_done(uif.rx_done),
            .tx_err(uif.tx_err),
			.rx_err(uif.rx_err),
			.rx_out(uif.rx_out)
			);
	
	initial begin
		clk = 0;
		
      	uvm_config_db#(virtual uart_if)::set(null,"","uif",uif);
		run_test("test");
		
	end
	
	initial begin
		$dumpfile("temp.vcd");
		$dumpvars(top);
	end
	

endmodule