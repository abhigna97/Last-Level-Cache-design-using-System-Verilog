package ParameterDefinitions;

parameter LLC_LINE_SIZE=64;  			// in bytes
parameter ASSOCIATIVITY=8;
parameter LLC_SETS_COUNT=2**15;
parameter ADDRESS_SIZE=32;
parameter LLC_LINES_COUNT=LLC_SETS_COUNT*ASSOCIATIVITY;
parameter BYTE_SELECT_SIZE=$clog2(LLC_LINE_SIZE);
parameter INDEX_SIZE=$clog2(LLC_SETS_COUNT);
parameter TAG_SIZE= ADDRESS_SIZE - (BYTE_SELECT_SIZE + INDEX_SIZE);
parameter WAY_SIZE=$clog2(ASSOCIATIVITY);
parameter PLRU_SIZE = 7;
parameter FUNCTION_SIZE = 4;
parameter COUNTER_SIZE = 16;
  
endpackage
