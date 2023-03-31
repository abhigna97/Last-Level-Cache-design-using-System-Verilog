package PLRU_Update;
import ParameterDefinitions::*;
function void PLRU_Update_Function (input logic [PLRU_SIZE-1:0] plru, input logic [WAY_SIZE-1:0] way, output logic [PLRU_SIZE-1:0] plru_out);
  
   begin
    case(way)
      0: plru_out= (plru & 7'b1110100) | 7'b0000000;
      1: plru_out= (plru & 7'b1110100) | 7'b0001000;
      2: plru_out= (plru & 7'b1101100) | 7'b0000010;
      3: plru_out= (plru & 7'b1101100) | 7'b0010010;
      4: plru_out= (plru & 7'b1011010) | 7'b0000001;
      5: plru_out= (plru & 7'b1011010) | 7'b0100001;
      6: plru_out= (plru & 7'b0111010) | 7'b0000101;
      7: plru_out= (plru & 7'b0111010) | 7'b1000101;
    endcase
  end

endfunction

endpackage