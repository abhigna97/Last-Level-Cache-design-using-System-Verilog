//Simulate using teh following command
//vsim -voptargs=+acc work.CacheTB +TRACEFILE=TraceFile.txt +MODE=NORMAL
import GetSnoopResult::*; 
import ParameterDefinitions::*;
module CacheTB();
	
	// Inputs to DUT
	logic clock;
	logic reset;
	logic [ADDRESS_SIZE-1:0] Address;
	logic [FUNCTION_SIZE-1:0] n;
	logic PrRd_in;
	logic PrWr_in;
	logic BusUpgr_in;
	logic BusRd_in;
	logic BusRdX_in;
	snoop_result C_in;
	
	//outputs from DUT
	logic BusUpgr_out;
	logic BusRd_out;
	logic BusRdX_out;
	snoop_result C_out;
	logic Flush;
	logic done;

	bit [COUNTER_SIZE-1:0] hit_counter;
	bit [COUNTER_SIZE-1:0] miss_counter;
	bit [COUNTER_SIZE-1:0] read_counter;
	bit [COUNTER_SIZE-1:0] write_counter;
	
	
	//Internal variables for File Operations
	string var1,var2;
	string line;
	string mode;
	int file_obj;
	logic [FUNCTION_SIZE-1:0] val1;
	logic [ADDRESS_SIZE-1:0] val2;
	
	// Initializing file line number to 1
	int i =1;

	//Internal variables to hold the inputs to DUT before supplying
	logic PrRd;
	logic PrWr;
	logic BusUpgr;
	logic BusRd;
	logic BusRdX;
	snoop_result C;
	logic rst;
	
	//Instantiating the Design
	CacheDesign DUT(
		.clock(clock),
		.reset(reset),
		.Address(Address),
		.funct(n),
		.PrRd(PrRd_in),
		.PrWr(PrWr_in),
		.BusRd_in(BusRd_in),
		.BusRdX_in(BusRdX_in),
		.BusUpgr_in(BusUpgr_in),
		.C_in(C_in),
		.BusRd_out(BusRd_out),
		.BusRdX_out(BusRdX_out),
		.BusUpgr_out(BusUpgr_out),
		.C_out(C_out),
		.Flush(Flush),
		.done(done),
		.cache_hits(hit_counter),
		.cache_misses(miss_counter),
		.cache_reads(read_counter),
		.cache_writes(write_counter)
		);
	
	// Function to print the CacheStatistics  at the end of every trace file
	function void cache_statistics(	input bit [COUNTER_SIZE-1:0] hit_counter,
					input bit [COUNTER_SIZE-1:0] miss_counter,
					input bit [COUNTER_SIZE-1:0] read_counter,
					input bit [COUNTER_SIZE-1:0] write_counter);
		real hc_r,mc_r,rc_r,wc_r;
		real hit_ratio;
		hc_r = $itor(hit_counter);
		mc_r = $itor(miss_counter);
		rc_r = $itor(read_counter);
		wc_r = $itor(write_counter);
		hit_ratio = (hc_r / (rc_r + wc_r))*'d100;
		$display("*****L2(LLC) Cache Statistics****");
		$display("Number of Reads to L2 : %d\n", read_counter);
		$display("Number of Writes to L2: %d\n", write_counter);
		$display("Number of Hits to L2	: %d\n", hit_counter);
		$display("Number of Misses to L2: %d\n", miss_counter);
		$display("Hit Ratio of L2 is : %f %%\n", hit_ratio);
	endfunction
	
	function void supply_to_dut(	input logic [FUNCTION_SIZE-1:0]funct_trace, 
					input logic [ADDRESS_SIZE-1:0]Address_trace,
					output logic PrRd,
					output logic PrWr,
					output logic BusRd,
					output logic BusRdX,
					output logic BusUpgr,
					output snoop_result C,
					output logic rst);
		if(Address_trace[1:0] == 2'b00) C = HIT;
		else if(Address_trace[1:0]==2'b01) C = HITM;
		else C = NOHIT;
	case(funct_trace)
			0: begin 
				rst = 1'b0;
				PrRd = 1'b1;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b0;
				
			   end
			1: begin
				rst = 1'b0;
				PrRd = 1'b0;
				PrWr = 1'b1;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b0;
				end 
			2: begin 
				rst = 1'b0;
				PrRd = 1'b1;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b0;
				end 
			3: begin
				rst = 1'b0;
				PrRd = 1'b0;
				PrWr = 1'b0;
				BusUpgr = 1'b1;
				BusRd = 1'b0;
				BusRdX = 1'b0;
			   end
			4: begin 
				rst = 1'b0;
				PrRd = 1'b0;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b1;
				BusRdX = 1'b0;
				end
			5: begin 
				rst = 1'b0;
				PrRd = 1'b0;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b1;
				end
			6: begin 
				rst = 1'b0;
				PrRd = 1'b0;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b1;
				end
			8: begin
				rst = 1'b1;
				PrRd = 1'b0;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b0;
			   end
			9: begin
				rst = 1'b0;
				PrRd = 1'b0;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b0;
			   end
			default: begin
				rst = 1'b0;
				PrRd = 1'b0;
				PrWr = 1'b0;
				BusUpgr = 1'b0;
				BusRd = 1'b0;
				BusRdX = 1'b0;
        			$display("TB: Illegal Function Provided");
        			$stop;
			end
		endcase

	endfunction
	
	//logic for clock generation
	always #5 clock = !clock;
	

	// TestBench to supply the trace file values to DUT	
	initial begin
		clock = 1'b0;
		reset = 1'b1;
		if($value$plusargs("TRACEFILE=%0s",var1))           		// Trace_file gets stored in var1
			$display("Trace_file=%0s",var1);
		if($value$plusargs("MODE=%0s",var2))    
			$display("Mode is %0s",var2);
		file_obj = $fopen($sformatf("%0s",var1), "r");      		// opening the file
		@(negedge clock);
		@(negedge clock);
		while (i<1000) begin 
			if(i==1) begin
				$fscanf(file_obj,"%0d %0h",val1,val2);         			// parsing it into command and address
				supply_to_dut(val1,val2,PrRd,PrWr,BusRd,BusRdX,BusUpgr,C,rst);
				PrRd_in = PrRd;
				PrWr_in = PrWr;
				C_in = C;
				BusRd_in = BusRd;
				BusRdX_in = BusRdX;
				BusUpgr_in = BusUpgr;
				reset = rst;
				n = val1;
				Address = val2;
				i++;
				@(negedge clock); 
			end else begin 
				if(done) begin
					$fscanf(file_obj,"%0d %0h",val1,val2);         			// parsing it into command and address
					supply_to_dut(val1,val2,PrRd,PrWr,BusRd,BusRdX,BusUpgr,C,rst);
					PrRd_in = PrRd;
					PrWr_in = PrWr;
					C_in = C;
					BusRd_in = BusRd;
					BusRdX_in = BusRdX;
					BusUpgr_in = BusUpgr;
					reset = rst;
					n = val1;
					Address = val2;
					i++;
					@(negedge clock);
			    		if($feof(file_obj)) begin 
						supply_to_dut(val1,val2,PrRd,PrWr,BusRd,BusRdX,BusUpgr,C,rst);
						PrRd_in = PrRd;
						PrWr_in = PrWr;
						C_in = C;
						BusRd_in = BusRd;
						BusRdX_in = BusRdX;
						BusUpgr_in = BusUpgr;
						reset = rst;
						n = val1;
						Address = val2;	
						cache_statistics(hit_counter,miss_counter,read_counter,write_counter);
						break;
					end
				end
			end
		end
		$fclose(file_obj);                                  					// closing the file
		$stop;
	end	
	
	initial begin
		clock = 1'b0;
	end
endmodule