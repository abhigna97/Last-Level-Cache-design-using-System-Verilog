//outputs the least recently used way
package PLRU_Get;
import ParameterDefinitions::*;
function void PLRU_Get_Function(input logic [PLRU_SIZE-1:0] plru, output integer way);
   begin
    if (plru[0]==0) begin
      if (plru[2]==0) begin
        if (plru[6]==0) begin
          way=7; end
        else if (plru[6]==1) begin
          way=6; end
      end
      else if (plru[2]==1) begin
        if (plru[5]==0) begin
          way=5; end
        else if (plru[5]==1) begin
          way=4; end
      end
    end
    else if(plru[0]==1) begin
      if (plru[1]==0) begin
        if (plru[4]==0) begin
          way=3; end
        else if (plru[4]==1) begin
          way=2; end
      end
      else if (plru[1]==1) begin
        if (plru[3]==0) begin
          way=1; end
        else if (plru[3]==1) begin
          way=0; end
      end
    end
  end

endfunction
endpackage

