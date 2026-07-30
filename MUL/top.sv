`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
	`uvm_object_utils(transaction)
	
	rand bit[3:0] a,b;
	bit [7:0] res;
	
	function new(string name="tr");
		super.new(name);
	endfunction
	
	constraint valid{
		a inside {[1:10]};
		b inside {[1:10]};
	}
	
	function void print(string component,int display_mode,bit with_outp);
		if(with_outp)
			`uvm_info(component,$sformatf("a = %0d, b= %0d, res = %0d",this.a,this.b,this.res),display_mode)		
		else
			`uvm_info(component,$sformatf("a = %0d, b= %0d",this.a,this.b),display_mode)		
	endfunction

endclass

class generator extends uvm_sequence#(transaction);
	
	`uvm_object_utils(generator)
	
	transaction tr;
	
	function new(string name="seq");
		super.new(name);
		//uvm_raise_objection = 1;
		set_automatic_phase_objection(1);
	endfunction
	
	
	virtual task body();
		for(int idx=0;idx<100;idx++) begin
			tr = transaction::type_id::create("tr");
			start_item(tr);
			assert(tr.randomize());
			`uvm_info("SEQ",$sformatf("a = %0d, b= %0d",tr.a,tr.b),UVM_NONE)
			finish_item(tr);
			#5;
		end
	endtask
endclass


class driver extends uvm_driver#(transaction);

	`uvm_component_utils(driver)
	
	virtual mul_if mif;
	transaction tr;
	
	function new(string name,uvm_component parent);
		super.new(name,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!uvm_config_db#(virtual mul_if)::get(this,"","mif",mif)) begin
			`uvm_error("driver","Unable to access")
		end
		
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		tr = transaction::type_id::create("tr");
		while(1) begin
			seq_item_port.get_next_item(tr);
			drive_transaction(tr);
			tr.print("Driver",0,0);
			seq_item_port.item_done();
			//seq_item_port.item_done(tr);
		end
	endtask
	
	
	task drive_transaction(transaction tr);
		mif.a <= tr.a;
		mif.b <= tr.b;
	endtask
	
endclass

class sequencer extends uvm_sequencer#(transaction);
	`uvm_component_utils(sequencer)
	
	function new(string name,uvm_component parent);
		super.new(name,parent);
	endfunction

	
endclass


class monitor extends uvm_monitor;
	`uvm_component_utils(monitor)
	
	virtual mul_if mif;
	
	transaction tr;
	uvm_analysis_port#(transaction) ap;
	
	function new(string name= "mon",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual mul_if)::get(this,"","mif",mif))
			`uvm_error("MON","Unable to access the interface")
		ap = new("ap",this);
	endfunction
	
	
	
	virtual task run_phase(uvm_phase phase);
		tr = transaction::type_id::create("tr");
		forever begin
			//@(mif.a , mif.b);
			#5
			tr.a = mif.a;
			tr.b = mif.b;
			#0
			tr.res = mif.res;
			tr.print("MON",0,1);
			ap.write(tr);
		end
	endtask
	
endclass


class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)
	 
	uvm_analysis_imp#(transaction,scoreboard) imp;
	
	int matched = 0;
	int unmatched = 0;
	
	function new(string name= "scb",uvm_component parent);
		super.new(name,parent);
	endfunction
		
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		imp = new("imp",this);
	endfunction
	
	function void write(transaction tr);
		if(tr.a * tr. b == tr. res) matched++;
		else unmatched++;
	endfunction
	
	function void extract_phase(uvm_phase phase);
		
		`uvm_info("ScoreBoard",$sformatf("Matched = %0d, UnMatched = %0d",matched,unmatched),UVM_NONE);
		
	endfunction
	
	
endclass


class m_agent extends uvm_agent;
	`uvm_component_utils(m_agent)
	
	sequencer seqr;
	driver drvr;
	monitor mon;
	
	uvm_analysis_port#(transaction) pap;
	
	function new(string name,uvm_component parent);
		super.new(name,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seqr = sequencer::type_id::create("seqr",this);
		drvr = driver::type_id::create("drvr",this);
		mon = monitor::type_id::create("mon",this);
		pap = new("pap",this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		drvr.seq_item_port.connect(seqr.seq_item_export);
		mon.ap.connect(pap);
	endfunction
endclass


class environment extends uvm_env;
	`uvm_component_utils(environment)
	
	//Declare agents
	m_agent agent;
	scoreboard scb;
	function new(string name,uvm_component parent);
		super.new(name,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agent = m_agent::type_id::create("agent",this);
		scb = scoreboard::type_id:: create("scb",this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		agent.pap.connect(scb.imp);
	endfunction
	
endclass




class test extends uvm_test;
	`uvm_component_utils(test)
	
	virtual mul_if mif;
	environment env;
	
	
	function new(string name,uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);

		//phase.phase_done.set_drain_time(this, 100ns);
	endfunction
  
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		env = new("env",this);
		
		if(!uvm_config_db#(virtual mul_if)::get(this,"","mif",mif))
			`uvm_error("CONFIG_DB","Unable to access the ConfigDB variable")
		
		uvm_config_db#(virtual mul_if)::set(this,"","mif",mif);
		
		uvm_config_db#(uvm_object_wrapper)::set(this,"env.agent.seqr.main_phase","default_sequence",generator::get_type());
		
	endfunction
	
	
	task main_phase (uvm_phase phase);
		uvm_objection objection;
		super.main_phase(phase);
		objection=phase.get_objection();
		//The drain time is the amount of time to wait once all objections have been dropped
		//objection.set_drain_time(this,100ns);
	endtask
	
endclass


module top;
	mul_if mif();
	
	
	mul mul_inst(mif.a,mif.b,mif.res);
	
	initial begin
		uvm_config_db#(virtual mul_if)::set(null,"","mif",mif);
		run_test();
	end

endmodule
