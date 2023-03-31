// Used to simulate a bus operation and to capture the snoop results of last level caches of other processors
package BusOperation;
import ParameterDefinitions::*;
typedef enum logic [2:0] {READ=3'd1, WRITE=3'd2, INVALIDATE=3'd3, RWIM=3'd4}Bus_Op;
	import GetSnoopResult::*;
	string var1;
	function void BusOperation_funct(input Bus_Op BusOp, input logic [ADDRESS_SIZE-1:0] Address, output snoop_result out_result1);
		out_result1=GetSnoopResult_funct(Address);
		if($value$plusargs("MODE=%0s",var1))  
			if(var1 == "NORMAL")
				$display("BusOp: %s, Address: %h, Snoop Result: %s\n",BusOp,Address,out_result1);
	endfunction
endpackage
