

/*
Test Plan:
How will i prove that RTL is correct ?
How will i verify that RTL is correct ?

/////-------------------------------/////
.clk(clk),.rst(rst),.baud(baud),.tx_clk(tx_clk)
1. On reset the tx_clk should be zero
	@(posedge clk)
	disable iff(!reset)
	reset |=> !tx_clk
	
2. is the reset is synchrnous or asynchronous
3. Can we change the baud rate during the simulation
4. Check for the proper toggling / check for the internal counter
5. Reset and check for the toggle behaviour 
6. Reset during the tx_clk period
/////-------------------------------/////
*/

import uvm_pkg::*;
`include "uvm_macros.svh"

interface baud_interface(input clk);
	logic reset;
	logic [16:0] baud;
	logic tx_clk;


endinterface


typedef enum  {RESET= 0,REGULAR=1} transaction_type;

class transaction extends uvm_sequence_item;
	`uvm_object_utils(transaction)
	rand bit reset;
	rand bit [16:0] baud;
	rand transaction_type kind;
	real counter;
	
	function new(string name="transaction");
		super.new(name);
		counter = 0;
		
	endfunction
	
	constraint baud_c{
		baud inside {4800,9600,19200,38400};
	}
	
	function string covert2string();
		return $sformatf("[%0t] Reset = %0d, baud = %0d",$time,reset,baud);
	endfunction
	
	function void copy(transaction tr);
		this.reset = tr.reset;
		this.baud = tr.baud;
		this.counter = tr.counter;
		this.kind =tr.kind;
	endfunction
	
	
endclass

class reset_sequence extends uvm_sequence#(transaction);
	`uvm_object_utils(reset_sequence)
	
	//int reset_cycle_count;
	
	transaction tr;
	
	function new(string name="reset_sequence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	task pre_start();
		//uvm_config_db#(int)::get(get_sequencer(),"","reset_cycle_count",reset_cycle_count);
	endtask
	
	
	virtual task body();
		repeat(10) begin
			tr = transaction::type_id::create("tr");
			tr.kind = RESET;
			start_item(tr);
			finish_item(tr);
			`uvm_info("SEQ1",$sformatf("[%0t] Seqeunce completed",$time),UVM_MEDIUM)
		end
	endtask

endclass

class random_baudrate_sequence extends uvm_sequence#(transaction);
	`uvm_object_utils(random_baudrate_sequence)
	
	int sequence_count;
	
	transaction tr;
	
	function new(string name="random_baudrate_sequence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	task pre_start();
		if(!uvm_config_db#(int)::get(get_sequencer(),"","sequence_count",sequence_count)) begin
			sequence_count = 10;
			`uvm_error("CONFIG_DB","Unable to access sequence count")
		end
	endtask
	
	
	virtual task body();
		repeat(sequence_count) begin
			tr = transaction::type_id::create("tr");
			start_item(tr);
			tr.kind = REGULAR;
			assert(tr.randomize() with {reset == 1'b0;})
			else `uvm_error("SEQ","Randomization error")
			finish_item(tr);
			`uvm_info("SEQ2",$sformatf("[%0t] Seqeunce completed",$time),UVM_MEDIUM)
		end
	endtask

endclass

class reset_baudrate_sequence extends uvm_sequence#(transaction);
	`uvm_object_utils(reset_baudrate_sequence)
	
	int sequence_count;
	
	transaction tr;
	
	function new(string name="reset_baudrate_sequence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	task pre_start();
		if(!uvm_config_db#(int)::get(get_sequencer(),"","sequence_count",sequence_count)) begin
			sequence_count = 10;
			`uvm_error("CONFIG_DB","Unable to access sequence count")
		end
	endtask
	
	
	virtual task body();
		repeat(sequence_count) begin
			tr = transaction::type_id::create("tr");
			start_item(tr);
			tr.kind = REGULAR;
			assert(tr.randomize() with {reset == 1'b0;})
			else `uvm_error("SEQ","Randomization error")
			finish_item(tr);
			
			// Reset_packet
			tr = transaction::type_id::create("tr");
			start_item(tr);
			tr.kind = RESET;
			finish_item(tr);
			`uvm_info("SEQ3",$sformatf("[%0t] Seqeunce completed",$time),UVM_MEDIUM)
		end
	endtask

endclass

class virtual_seq extends uvm_sequence#(transaction);
	`uvm_object_utils(virtual_seq)
	reset_sequence rst_seq;
	random_baudrate_sequence rand_baud_seq;
	reset_baudrate_sequence rst_baud_seq;
	
	function new(string name="virtual_seq");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	task pre_start();
		rst_seq = reset_sequence::type_id::create("rst_seq");
		rand_baud_seq = random_baudrate_sequence::type_id::create("rand_baud_seq");
		rst_baud_seq = reset_baudrate_sequence::type_id::create("rst_baud_seq");
	endtask
	
	task body();
		//fork
			rst_seq.start(get_sequencer());
			rand_baud_seq.start(get_sequencer());
			rst_baud_seq.start(get_sequencer());
		//join
	endtask
	
endclass

class driver extends uvm_driver#(transaction);
	`uvm_component_utils(driver)
  
	virtual baud_interface bif;
	transaction tr;
	function new(string name="driver",uvm_component parent = null);
		super.new(name,parent);	
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual baud_interface)::get(this,"","bif",bif))
			`uvm_error("CONFIG_DB","Unable to access interface")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		tr = transaction::type_id::create("tr");
		forever begin
			seq_item_port.get_next_item(tr);
			drive(tr);
			
			seq_item_port.item_done();
		end
		
	endtask
	
	task drive(transaction tr);
		case(tr.kind)
			RESET:
				begin
					bif.reset <= 1'b1;
					bif.baud <= tr.baud;
					@(posedge bif.clk);
					//bif.reset <= !tr.reset;
				end
			REGULAR:
				begin
					bif.reset <= 1'b0;
					bif.baud <= tr.baud;
					@(posedge bif.clk);
					@(posedge bif.tx_clk);
					@(posedge bif.tx_clk);
				end
		endcase
	endtask
	
endclass

class monitor extends uvm_monitor;
	`uvm_component_utils(monitor)
	
	uvm_analysis_port#(transaction) send;
	
	virtual baud_interface bif;
	
	transaction tr;
	real start_time;
	real end_time;
	function new(string name="monitor",uvm_component parent=null);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual baud_interface)::get(this,"","bif",bif))
			`uvm_error("CONFIG_DB","Unable to access interface")
			
		send = new("send",this);
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		tr = transaction::type_id::create("tr");
		forever begin
			@(posedge bif.clk);
			if(bif.reset) begin
				tr.reset = bif.reset;
				tr.counter = 0;
				
			end else begin
				tr.reset = bif.reset;
				tr.baud = bif.baud;
				
              @(posedge bif.tx_clk);
				start_time = $realtime;
              @(posedge bif.tx_clk);
				end_time = $realtime;
				
				tr.counter = (end_time-start_time);
				`uvm_info("MONITOR",$sformatf("Counter %0p",tr.counter),UVM_MEDIUM)
			end
			`uvm_info("MONITOR",$sformatf("[%0t] Monitored transaction",$time),UVM_MEDIUM)
			send.write(tr);
		end
		
	endtask
	
endclass

class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)
	
	uvm_analysis_imp#(transaction,scoreboard) imp;
	transaction tr;
	int count;
	int exp_count;
	int matched ;
	int mis_matched ;
	
	function new(string name="scoreboard",uvm_component parent=null);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		tr = transaction::type_id::create("tr");
		matched = 0;
		mis_matched = 0;
		imp=new("imp",this);
	endfunction
	
	function void write(transaction cur_tr);
		`uvm_info("SCOREBOARD",$sformatf("[%0t] Recived transaction",$time),UVM_MEDIUM)
      	tr.copy(cur_tr);
		if(tr.reset) begin
          if(tr.counter == 0) matched++;
			else mis_matched++;
		end else begin
			count = (tr.counter)/2 - 2;
			case(tr.baud)
				4800: 	exp_count = 10416;
				9600: 	exp_count = 5208;
				19200:	exp_count = 2604;
				38400:	exp_count = 1302;
				default:exp_count = 0; 
			endcase
			
			if(count == exp_count)begin
				 matched++;
			end
			else begin mis_matched++;
				`uvm_info("SCB",$sformatf("[%0t] Miss Matched , count = %0d, expected count = %0d",$time,count,exp_count),UVM_MEDIUM)
			end
		end
	endfunction
	
	
	function void extract_phase(uvm_phase phase);
		super.extract_phase(phase);
		
		`uvm_info("SCOREBOARD",$sformatf("Matched transaction = %0d\n Mis Matched transaction = %0d",matched,mis_matched),UVM_NONE)
	endfunction
endclass


class agent extends uvm_agent;
	`uvm_component_utils(agent)
	
	uvm_sequencer#(transaction) seqr;
	driver drvr;
	monitor mon;
	
	uvm_analysis_port#(transaction) pass_through_port;
	
	
	function new(string name="agent",uvm_component parent=null);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
      seqr = uvm_sequencer#(transaction)::type_id::create("seqr",this);
      drvr = driver::type_id::create("drvr",this);
      mon = monitor::type_id::create("mon",this);
      pass_through_port = new("pass_through_port",this);
	endfunction
	
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		drvr.seq_item_port.connect(seqr.seq_item_export);
		mon.send.connect(pass_through_port);
	endfunction
	
endclass


class environment extends uvm_env;
	`uvm_component_utils(environment)
	
	agent agnt;
	scoreboard scb;
	function new(string name="environment",uvm_component parent=null);
		super.new(name,parent);
	endfunction
	
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
      agnt = agent::type_id::create("agnt",this);
      scb = scoreboard::type_id::create("scb",this);
	endfunction
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		agnt.pass_through_port.connect(scb.imp);
		
	endfunction
	
	
endclass

class test extends uvm_test;
	
	`uvm_component_utils(test)
	environment env;
	
	virtual baud_interface bif;
	
	function new(string name="test",uvm_component parent=null);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
      env = environment::type_id::create("env",this);
		
		if(!uvm_config_db#(virtual baud_interface)::get(this,"","bif",bif))
			`uvm_error("CONFIG_DB","Unable to access interface")
		
          uvm_config_db#(virtual baud_interface)::set(this,"","bif",bif);
		
		uvm_config_db#(uvm_object_wrapper)::set(this,"env.agnt.seqr.main_phase","default_sequence",virtual_seq::get_type());
      
      `uvm_info("TEST","Build_phase completed",UVM_MEDIUM);
	endfunction
	
endclass


module top;

	logic clk;
	
  	baud_interface bif(clk);
	
	clk_generator c_gen(.clk(clk),.rst(bif.reset),.baud(bif.baud),.tx_clk(bif.tx_clk));

	always #1 clk = !clk;
	
	initial begin
		clk = 0;
		
      uvm_config_db#(virtual baud_interface)::set(null,"","bif",bif);
		//uvm_config_db_options::turn_on_tracing();
		run_test("test");
	end
	
 initial begin
    $dumpfile("top.vcd");
    $dumpvars(0, top);
end
endmodule
