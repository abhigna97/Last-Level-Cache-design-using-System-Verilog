// Used to simulate communication to our upper level cache 
package MessageToCache;
import ParameterDefinitions::*;
	typedef enum logic [2:0] {GETLINE=3'd1, SENDLINE=3'd2, INVALIDATELINE=3'd3, EVICTLINE=3'd4}L2_to_L1;
	string var2;
	function void MessageToCache_funct(input L2_to_L1 Message, input logic [ADDRESS_SIZE-1:0] Address);
		if($value$plusargs("MODE=%0s",var2))  
			if(var2 == "NORMAL")
				$display("L2: %s %h\n",Message,Address);
	endfunction
endpackage
