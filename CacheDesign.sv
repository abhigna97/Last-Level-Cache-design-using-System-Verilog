import ParameterDefinitions::*;
import CacheStructure::*;
import PLRU_Update::*;
import PLRU_Get::*;
import GetSnoopResult::*;
import PutSnoopResult::*;
import BusOperation::*;
import MessageToCache::*;


// 32 Bit Address Contains 11 15 6 => tag index byte_select
module CacheDesign (
    	input 	bit    [ADDRESS_SIZE-1:0] Address,
    	input  	bit  [FUNCTION_SIZE-1:0] funct,        				// funct - is obtained from trace file
    	input  	logic   clock,
    	input  	logic   reset,
    	input  	logic 	PrRd, 
   	input  	logic 	PrWr,
    	input  	logic 	BusRd_in,
    	input  	logic 	BusRdX_in,
    	input  	logic 	BusUpgr_in,
	input snoop_result C_in,
    	output  logic 	Flush,
    	output  logic 	BusRd_out, 
    	output  logic   BusRdX_out,
   	output  logic   BusUpgr_out,
	output snoop_result C_out,
    	output  bit [COUNTER_SIZE-1:0] cache_reads,
    	output  bit [COUNTER_SIZE-1:0] cache_writes,
    	output  bit [COUNTER_SIZE-1:0] cache_hits,
    	output  bit	[COUNTER_SIZE-1:0] cache_misses,
    	output  logic        done
);

  	// enum variables
  	MESI_states current_state,next_state;
  	snoop_result SnoopResult,SnoopResult1,SnoopResult2;

  	logic [TAG_SIZE-1:0] TAG;
  	logic [INDEX_SIZE-1:0] INDEX;
 	logic [BYTE_SELECT_SIZE-1:0]  BYTE_SELECT;

  	logic [TAG_SIZE-1:0] temp; 			// Temporary variable to store Tag
  	logic [PLRU_SIZE-1:0]  update_plru_temp; 	// Temporary variable to PLRU
 
  	logic [WAY_SIZE-1:0] global_way,matched_way;

 	string var1;					// To Store Mode Supplied from Command line
	logic hit;
	logic tag_match_cnt = 1'b1;
	logic [3:0] valid_ways = 4'b0000;

	//cache structure
  	set cache; 					

	//Address Mapping Logic
  	assign {TAG,INDEX,BYTE_SELECT} = Address;


	// Function to clear the contents of cache and reset all states
  	function void initialize_cache(input set cache);
		int x, y;
   	 	for (x = 0; x < LLC_SETS_COUNT; x++) begin
      			for (y = 0; y < ASSOCIATIVITY; y++) begin
        			cache[x].lines[y].MESI = INVALID;
        			cache[x].PLRU[y] = 7'b0000000;  					// Setting PLRU to 00000000 while initializing
      			end
    		end
  	endfunction

	// Prints the contents of each valid cache line.
  	function void print_cache(input set cache);
    		int i, j;
   		$display("-------Print-----Cache[SET][WAY] = [TAG BITS][MESI STATE]--------------------");	
    		for (i = 0; i < LLC_SETS_COUNT; i++) begin
      			for (j = 0; j < ASSOCIATIVITY; j++) begin
        			if(!(cache[i].lines[j].MESI == INVALID))				
					$display("Cache[%0d][%0d] = [%0h][%0s]",i,j,cache[i].lines[j].Tag,cache[i].lines[j].MESI.name);
     				end
   		 end
  	endfunction

// MESI Current State Logic
always_ff @(posedge clock, posedge reset) begin
	if(reset) begin 				// active high reset
		initialize_cache(cache);
    	end else begin
      		cache[INDEX].lines[global_way].MESI <= next_state;
		if(!hit) cache[INDEX].lines[global_way].Tag  <= TAG;
		cache[INDEX].PLRU <= update_plru_temp;
    	end
end

// MESI Next State and Output Logic
always_comb begin
next_state = INVALID;
case(cache[INDEX].lines[global_way].MESI) 	// current_state of the cache line
      	MODIFIED: begin 			// Modified is the only one which has a copy, and will be written
        if(PrRd==1 || PrWr==1) begin		// When there is processor read or write, nothing should happen and should remain in modified state
          next_state  = MODIFIED;
          BusRd_out   = 1'b0;
          BusRdX_out  = 1'b0;
          BusUpgr_out = 1'b0;
        end else begin
          if(BusRd_in) begin			// when other processor cache snoops in and does a Bus read, cache line goes to shared state and flushes due to a valid copy 
            next_state = SHARED;
            Flush = 1'b1;
            C_out = HITM;
          end else if(BusRdX_in) begin		// when other processor cache snoops in and does a Bus read for ownership, cache line goes to Invalid state and flushes due to a valid copy
            next_state = INVALID;
            Flush = 1'b1;
            C_out = HITM;
          end else begin			// if nothing is taking place then cache line should be remain in the modified state
            next_state = MODIFIED;
          end
        end
      end

      EXCLUSIVE: begin  			// Exclusive is the only one whch has a copy, and will not be written
        if (PrRd) begin
          next_state = EXCLUSIVE;		// when there is a processor read, no other cache will be having a copy, so do nothing and remain in exclusive state
          BusRd_out = 1'b0;
          BusRdX_out = 1'b0;
          BusUpgr_out = 1'b0;
        end
	else begin				// When there is a processor write, cache line should go to modified state and should do nothing
          if (PrWr) begin
            next_state  = MODIFIED;
            BusRd_out   = 1'b0;
            BusRdX_out  = 1'b0;
            BusUpgr_out = 1'b0;
          end else if(BusRd_in) begin		// when other processor cache snoops in and does a Bus read go to shared state and assert cache signal high
            next_state = SHARED;
            Flush = 1'b0;
            C_out = HIT;
          end else if(BusRdX_in) begin 		// when other processor cache snoops in and does a Bus read with ownership, go to invalid state and assert cache signal low
            next_state = INVALID;
            Flush = 1'b0;
            C_out = NOHIT;
          end else begin
            next_state = EXCLUSIVE;		// if nothing is taking place then cache should be remain in the exclusive state
          end
        end
      end

      SHARED: 	begin				// No other state have written to the cache line, copy is shared to other processors too and also it is visible
        if(PrRd==1)begin			// If there is processor read, cache line should remain in shared state and do nothing
          next_state  = SHARED;
          BusRd_out   = 1'b0;
          BusRdX_out  = 1'b0;
          BusUpgr_out = 1'b0;
        end
        if(BusRd_in==1) begin			// when there is bus read, should remain in shared state and assert cache signal as high
          next_state = SHARED;
          Flush = 1'b0;
          C_out = HIT;
        end else begin
          if (PrWr) begin
            next_state = MODIFIED;		// when there is a processor write, should go to modified state and do a bus upgrade
            BusRd_out = 1'b0;
            BusRdX_out = 1'b0;
            BusUpgr_out = 1'b1;
          end else if(BusRdX_in==1'b1) begin	// when other processor snoops in and do a bus read for ownership, cache line should go to invalid state
            next_state = INVALID;
            Flush = 1'b0;
            C_out = NOHIT;
          end else if(BusUpgr_in==1'b1)begin	// when other processor snoops in and do a bus upgrade, it should move to invalid state 
            next_state = INVALID;
            Flush = 1'b0;
            C_out = NOHIT;
          end else begin
            next_state = SHARED;		// if nothing is taking place then cache line should be remain in the shared state
          end
        end
      end

      INVALID: begin
        if(PrRd) begin				// when there is processor read, cache line should go to shared state asserting cache signal as high			
          if (C_in == HIT) begin
            next_state  = SHARED;
            BusRd_out   = 1'b1;
            BusRdX_out  = 1'b0;
            BusUpgr_out = 1'b0;
          end else if (C_in == HITM)begin 
	   next_state = SHARED;
	   BusRd_out   = 1'b1;
           BusRdX_out  = 1'b0;
           BusUpgr_out = 1'b0;
	  end else begin
            next_state = EXCLUSIVE;		// when there is processor read, cache line should go to exclusive state asserting cache signal as low
            BusRd_out = 1'b1;
            BusRdX_out = 1'b0;
            BusUpgr_out = 1'b0;
          end
        end else if(PrWr) begin			// when there is processor write, cache line shoulf go to modified state and should do bus read for ownership
          next_state  = MODIFIED;
          BusRdX_out  = 1'b1;
          BusRd_out   = 1'b0;
          BusUpgr_out = 1'b0;
        end else begin				// if nothing is taking place then cache line should be remain in the invalid state
          next_state = INVALID;			
          Flush = 1'b0;
          C_out = NOHIT;
        end
      end

      default: begin				// if nothing is taking place then cache line should be remain in the invalid state
        next_state = INVALID;			
      end

endcase
end

// Bus Operation Messages and Messages to L1
always_comb begin
	if(BusRd_out) begin
		 	BusOperation_funct(READ,Address,SnoopResult1);
			MessageToCache_funct(SENDLINE,Address);
	end else if(BusRdX_out) begin
			BusOperation_funct(RWIM,Address,SnoopResult1);
			MessageToCache_funct(SENDLINE,Address);
	end else if(BusUpgr_out) begin
			BusOperation_funct(INVALIDATE,Address,SnoopResult1);
			MessageToCache_funct(GETLINE,Address);
	end else if(Flush)	begin
			BusOperation_funct(WRITE,Address,SnoopResult1);
			if(BusRd_in) begin
				MessageToCache_funct(GETLINE,Address);
			end
			if(BusRdX_in) begin
				MessageToCache_funct(GETLINE,Address);
				MessageToCache_funct(INVALIDATELINE,Address);
			end
	end else begin
	end
	
	if(BusUpgr_in)begin
			if(cache[INDEX].lines[global_way].MESI==SHARED) 
				MessageToCache_funct(GETLINE,Address);
			MessageToCache_funct(INVALIDATELINE,Address);
	end 
	if(BusRd_in) begin
			if((cache[INDEX].lines[global_way].MESI==EXCLUSIVE) ||(cache[INDEX].lines[global_way].MESI==SHARED))
				MessageToCache_funct(GETLINE,Address);
			if(C_out == HIT)	PutSnoopResult_funct(Address,C_out,SnoopResult2);
			else if(C_out == HITM) PutSnoopResult_funct(Address,C_out,SnoopResult2);
			else PutSnoopResult_funct(Address,C_out,SnoopResult2);
	end 
	
end

// READ,WRITE,HIT,MISS counters
always_ff@(posedge clock, posedge reset) begin
if(reset) begin
    	cache_reads  <= 'd0;
	cache_writes <= 'd0;
	cache_hits   <= 'd0;
	cache_misses <= 'd0;
	done <= 1'b0;
end else begin
	case(funct)
	0: begin  											//PrRd from L1 Data Cache
         	cache_reads <= cache_reads + 1;
		if(hit) begin
			cache_hits <= cache_hits + 1;
		end else begin
			cache_misses <= cache_misses + 1;
			if($value$plusargs("MODE=%0s",var1))begin 			
				if(var1 == "DEBUG") begin
          				$display("There is a READ MISS.");
       					$display("Calling PLRU Get");
          			   	$display("SnoopResult: %0s",SnoopResult);         
       					$display("After calling PLRU Get. PLRU: %0b Way to Evict is %0d",cache[INDEX].PLRU,global_way);
                  		end
               		end
		end
		if($value$plusargs("MODE=%0s",var1)) begin
			if(var1 == "DEBUG") begin
				$display("Calling PLRU Update");
       				$display("After calling PLRU Update. PLRU: %b",update_plru_temp);
			end 
		end
        	done <= 1'b1; 
   	end      

	1: begin  											// PrWr from L1 Data Cache
                cache_writes <= cache_writes + 1;
		if(hit)begin									//write hit
			cache_hits <= cache_hits + 1;		
		end else begin                          					// write miss
			cache_misses <= cache_misses + 1; 
			if($value$plusargs("MODE=%0s",var1)) begin 				// Mode gets stored in var1
			if(var1 == "DEBUG") begin
				$display("There is a WRITE MISS.");
         			$display("Calling PLRU Get");
				$display("After calling PLRU Get. PLRU: %b Way to Evict %d",cache[INDEX].PLRU,global_way);
         			$display("Performing WRITE ALLOCATE");
         			$display("Do a DRAM READ of entire cache line.");
				$display("OverWrite the selective bytes");
         			$display("SnoopResult: %0s",SnoopResult);
         			$display("Changing MESI State to MODIFIED");
         		end 
			end
		end
		if($value$plusargs("MODE=%0s",var1)) begin 
			if(var1 == "DEBUG") begin
				$display("Calling PLRU Update");
         			$display("After calling PLRU Update. PLRU: %b",update_plru_temp);
			end
		end
    		done <= 1'b1; 
   	end  

	2: begin  											//PrRd from L1 Data Cache
        	cache_reads <= cache_reads + 1;
 		if(hit) begin
			cache_hits <= cache_hits + 1;
		end else begin
			cache_misses <= cache_misses + 1;
		end
		if($value$plusargs("MODE=%0s",var1)) begin
			if(var1 == "DEBUG") begin
				$display("Calling PLRU Update");
       				$display("After calling PLRU Update. PLRU: %b",update_plru_temp);
			end 
		end
        	done <= 1'b1;  
	end

	3: begin 										// snooped BusUpgr
		done <= 1'b1;
   	end
	
	4: begin  										// snooped BusRd
		done <= 1'b1;
	 end

	5: begin  										// snooped BusWr
		done <= 1'b1;
	end

	6: begin  										// snooped BusRdX
		done <= 1'b1;
	end	

	8: begin 										// clear the cache and reset all states
		done <= 1'b1;
	end

	9: begin 										// print contents and state of each valid cache line
		print_cache(cache);
		done <= 1'b1;
	end
	default: begin
		done <= 1'b1;
	end
	endcase
end
done<=1'b1;
end

// Tag Matching & Evictline logic
always_comb begin
tag_match_cnt =1'b0;
if(reset) begin
	 hit = 1'b0;
end else begin


	if(PrRd || PrWr || BusRd_in || BusRdX_in || BusUpgr_in) begin
		for(int i=0;i<ASSOCIATIVITY;i++) begin
	   		if(cache[INDEX].lines[i].Tag == TAG) begin
				tag_match_cnt = tag_match_cnt+1;
				matched_way = i;
	       				begin
        					if($value$plusargs("MODE=%0s",var1)) begin
          						if(var1 == "DEBUG") begin 
              						$display("way %0d - HIT",i);
	  						end
         					end
         				end
      			end  
 		end
	end
		



	       	if(tag_match_cnt==1'b0) begin
			hit = 1'b0;
			valid_ways =4'd0;
			PLRU_Get_Function(cache[INDEX].PLRU,global_way);
			if(PrRd || PrWr) begin
				for(int i=0;i<ASSOCIATIVITY;i++) begin
	   				if((cache[INDEX].lines[i].MESI == SHARED)||(cache[INDEX].lines[i].MESI == MODIFIED)||(cache[INDEX].lines[i].MESI == EXCLUSIVE)) begin
					valid_ways = valid_ways+1;
		 			end
				end
			end

			if(valid_ways==4'd8) begin
				MessageToCache_funct(EVICTLINE,{cache[INDEX].lines[global_way].Tag,INDEX,BYTE_SELECT});
			end
			PLRU_Update_Function(cache[INDEX].PLRU,global_way,update_plru_temp);
		end

		else begin 
			hit = 1'b1;
			global_way = matched_way;
			PLRU_Update_Function(cache[INDEX].PLRU,global_way,update_plru_temp);
		end
		
	
	


end
end


endmodule



