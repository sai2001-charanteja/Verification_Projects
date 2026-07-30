`include "uvm_macros.svh"
import uvm_pkg::*;

interface dff_if(input clk);
	logic reset;
	logic din;
	logic dout;
endinterface

class transaction extends uvm_sequence_item;
	
	
	rand bit reset;
	rand bit din;
	bit dout;
	
	function new(string name="transaction");
		super.new(name);
	endfunction

	`uvm_object_utils_begin(transaction)
		`uvm_field_int(reset,UVM_ALL_ON)
		`uvm_field_int(din,UVM_ALL_ON)
		`uvm_field_int(dout,UVM_ALL_ON)
	`uvm_object_utils_end
	

	
	virtual function string convert2string();
  return  $sformatf("[%0t] reset=%0d din=%0d dout=%0d",
                 $time,reset, din, dout);
endfunction
endclass


class reset_seqeuence extends uvm_sequence#(transaction);
	`uvm_object_utils(reset_seqeuence)
	
	transaction tr;
	
	function new(string name="reset_seqeuence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	task body();
		repeat(10) begin
			tr = transaction::type_id::create("tr");
			start_item(tr);
			assert(tr.randomize());
			tr.reset = 1;
			finish_item(tr);
		end
	endtask
endclass


class reset_din_seqeuence extends uvm_sequence#(transaction);
	`uvm_object_utils(reset_din_seqeuence)
	
	transaction tr;
	
	function new(string name="reset_din_seqeuence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	task body();
		repeat(10) begin
			tr = transaction::type_id::create("tr");
			start_item(tr);
			assert(tr.randomize() with {reset == 0;});
			finish_item(tr);
		end
		
	endtask
endclass

class main_seq extends uvm_sequence#(transaction);
	`uvm_object_utils(main_seq)
	
	reset_seqeuence r_seq;
	reset_din_seqeuence rd_seq;
	
	function new(string name="reset_din_seqeuence");
		super.new(name);
		set_automatic_phase_objection(1);
	endfunction
	
	task pre_start();
		r_seq = reset_seqeuence::type_id::create("r_seq");
		rd_seq = reset_din_seqeuence::type_id::create("rd_seq");
	endtask
	
	task body();
		r_seq.start(get_sequencer());
		rd_seq.start(get_sequencer());
		
	endtask
endclass


class sequencer extends uvm_sequencer#(transaction);
	`uvm_component_utils(sequencer)
	
	function new(string name = "sequencer",uvm_component parent = null);
		super.new(name,parent);
	endfunction
	
endclass


class driver extends uvm_driver#(transaction);
	`uvm_component_utils(driver)

	transaction tr;
	virtual dff_if dif;

	function new(string name = "driver",uvm_component parent = null);
		super.new(name,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(virtual dff_if)::get(this,"","dif",dif))
			`uvm_error("CONFIG_DB","Unable to access the interface for driver")
		
		tr = transaction::type_id::create("tr");
	endfunction

	virtual task run_phase(uvm_phase phase);
		
		forever begin
			seq_item_port.get_next_item(tr);
			
			
			`uvm_info("DRVR",$sformatf("Driving the packet %0s",tr.convert2string()),UVM_MEDIUM)
			drive(tr);
			seq_item_port.item_done();
		end
	endtask

	task drive(transaction tr);
		@(posedge dif.clk);
		dif.reset<= tr.reset;
		dif.din <= tr.din;
	endtask

endclass


class monitor extends uvm_monitor;
	`uvm_component_utils(monitor)
	
	transaction tr;
	virtual dff_if dif;
	uvm_analysis_port#(transaction) send;

	function new(string name = "monitor",uvm_component parent = null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual dff_if)::get(this,"","dif",dif))
			`uvm_error("CONFIG_DB","Unable to access the interface for monitor")
		
		tr = transaction::type_id::create("tr");
		send = new("send",this);
	endfunction

	virtual task run_phase(uvm_phase phase);
		forever begin
			@(posedge dif.clk);
			tr.reset = dif.reset;
			tr.din = dif.din;
			tr.dout = dif.dout;
			`uvm_info("MON",$sformatf("Monitor Collected packet %0s",tr.convert2string()),UVM_MEDIUM)
			
			send.write(tr);
		end
	endtask
	
endclass


class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)

	uvm_analysis_imp#(transaction,scoreboard) imp;
	transaction pas_tr,pre_tr;
	bit flag = 0;

	int matched;
	int mis_matched;
	
	function new(string name="scoreboard",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		imp = new("imp",this);
		pre_tr = transaction::type_id::create("pre_tr");
		
		pas_tr = transaction::type_id::create("pas_tr");
		
		matched = 0;
		mis_matched = 0;

	endfunction


	function void write(transaction tr);
	
		pre_tr.dout = tr.dout;
		pre_tr.reset = tr.reset;
		pre_tr.din = tr.din;
		if(flag) begin
			`uvm_info("SCB","Scoreboard received packet ",UVM_MEDIUM)
			`uvm_info("SCB",$sformatf("PAST_TR = %0s",pas_tr.convert2string()),UVM_MEDIUM)
			`uvm_info("SCB",$sformatf("PRESENT_TR = %0s",pre_tr.convert2string()),UVM_MEDIUM)
			
			
			if(pas_tr.reset) begin
				if(pre_tr.dout === 1'b0) matched++;
				else begin
					//pre_tr.convert2string();
					//pas_tr.convert2string();
					`uvm_info("SCB","Missmatched",UVM_MEDIUM)
					mis_matched ++;
				end
			end else begin
				if(pas_tr.din === pre_tr.dout) matched++;
				else begin
					`uvm_info("SCB","Missmatched",UVM_MEDIUM)
					mis_matched ++;
				end
			end
			
			
		end

		pas_tr.copy(pre_tr);

		if(!flag) flag = 1;
		

	endfunction
	
	function void extract_phase(uvm_phase phase);
		`uvm_info("SCB",$sformatf("Matched = %0d, Miss Matched = %0d",matched,mis_matched),UVM_NONE)
	endfunction

endclass


class agent extends uvm_agent;
	`uvm_component_utils(agent)
	sequencer seqr;
	driver drvr;
	monitor mon;

	uvm_analysis_port#(transaction) pass_through_port;

	function new(string name="agent",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seqr = sequencer::type_id::create("seqr",this);
		drvr = driver::type_id::create("drvr",this);
		mon = monitor::type_id::create("mon",this);

		pass_through_port = new("pass_through_port",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		mon.send.connect(pass_through_port);
		drvr.seq_item_port.connect(seqr.seq_item_export);
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
	virtual dff_if dif;
	environment env;
	function new(string name="test",uvm_component parent = null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = environment::type_id::create("env",this);
		if(!uvm_config_db#(virtual dff_if)::get(this,"","dif",dif))
			`uvm_error("CONFIG_DB","Unable to access the interface from environment")
		uvm_config_db#(virtual dff_if)::set(this,"","dif",dif);
		
		uvm_config_db#(uvm_object_wrapper)::set(this,"env.agnt.seqr.main_phase","default_sequence",main_seq::get_type());
	endfunction



endclass
module top;
	reg clk;
	always #5 clk = !clk;
	dff_if dif(clk);
	
	dff dff_inst(clk,dif.reset,dif.din,dif.dout);
	
	initial begin
		clk  = 0;

		uvm_config_db#(virtual dff_if)::set(null,"","dif",dif);
		run_test();
	end
	
endmodule