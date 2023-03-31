package CacheStructure;
import ParameterDefinitions::*;

typedef enum bit[1:0] {INVALID = 2'b00, SHARED=2'b01, MODIFIED=2'b10, EXCLUSIVE=2'b11} MESI_states;

typedef struct{
MESI_states  MESI;
logic [TAG_SIZE-1:0] Tag;                       // lower tag bit - inL1bit
}line[ASSOCIATIVITY-1:0];             		// 2(MESI bits) + 11(Tag bits)

typedef struct{
bit [ASSOCIATIVITY-2:0] PLRU;
line lines;
}set[LLC_SETS_COUNT-1:0];

endpackage