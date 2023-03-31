// simulates the reporting of snoop results by other caches 
// returns HIT, NOHIT or HITM
package GetSnoopResult; 
  import ParameterDefinitions::*;
	typedef enum logic [1:0] {HIT=2'b00, HITM=2'b01, NOHIT=2'b10}snoop_result;
	function snoop_result GetSnoopResult_funct(input logic [ADDRESS_SIZE-1:0] Address);
		if(Address[1:0] == 2'b00)
			GetSnoopResult_funct=HIT;
		else if(Address[1:0] == 2'b01)
			GetSnoopResult_funct=HITM;
		else GetSnoopResult_funct = NOHIT;
		
	endfunction
endpackage