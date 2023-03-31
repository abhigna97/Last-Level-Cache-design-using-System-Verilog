// Report the result of our snooping bus operations performed by other caches
package PutSnoopResult;
	import ParameterDefinitions::*;
	import GetSnoopResult::*;
   	string var1;
	function void PutSnoopResult_funct(input logic [ADDRESS_SIZE-1:0] Address,input snoop_result C_out,output snoop_result out_result);
		out_result= C_out;
    if($value$plusargs("MODE=%0s",var1))  
			if(var1 == "NORMAL")
		    $display("Address: %h, Snoop Result: %s\n",Address,out_result);
	endfunction
endpackage
