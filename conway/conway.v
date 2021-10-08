module top_module(
    input clk,
    input load,
    input [255:0] data,
    output [255:0] q ); 
    
    reg [255:0] state_reg;
    reg [255:0] state_reg_next;
    reg [7:0] neighbours [256];
    
    //State update logic instantiation
    genvar i;
    generate
        for (i=0; i<256; i=i+1) begin: state_update_loop
            state_update update (
                .old_state(state_reg[i]),
                .neighbours(neighbours[i]),
                .new_state(state_reg_next[i])
            );
        end
    endgenerate
        
    //state_reg logic
    always @ (posedge clk) begin
        if (load==1'b1) begin
            state_reg <= data;
        end
        else begin
            state_reg <= state_reg_next;
        end
    end
   
    //Wiring and structures
     localparam UPPER_LEFT = 0;
     localparam UPPER_CENTER = 1;
     localparam UPPER_RIGHT = 2;
     localparam MID_LEFT = 3;
     localparam MID_RIGHT = 4;
     localparam LOWER_LEFT = 5;
     localparam LOWER_CENTER = 6;
     localparam LOWER_RIGHT = 7;
     always @ (*) begin
         int i;
         int j;
         for (i=0; i<16; i=i+1) begin
             for (j=0; j<16; j=j+1) begin
                 int upper_i = (i == 0) ? 15 : i-1;
                 int middle_i = i;
                 int lower_i = (i == 15) ? 0 : i+1;
                 int left_j = (j==0) ? 15 : j-1;
                 int middle_j = j;
                 int right_j = (j==15) ? 0 : j+1;
                 
                 neighbours[i*16+j][UPPER_LEFT] = state_reg[upper_i*16 + left_j];
                 neighbours[i*16+j][UPPER_CENTER] = state_reg[upper_i*16 + middle_j];
                 neighbours[i*16+j][UPPER_RIGHT] = state_reg[upper_i*16 + right_j];
                 neighbours[i*16+j][MID_LEFT] = state_reg[middle_i*16 + left_j];
                 neighbours[i*16+j][MID_RIGHT] = state_reg[middle_i*16 + right_j];
                 neighbours[i*16+j][LOWER_LEFT] = state_reg[lower_i*16 + left_j];
                 neighbours[i*16+j][LOWER_CENTER] = state_reg[lower_i*16 + middle_j];
                 neighbours[i*16+j][LOWER_RIGHT] = state_reg[lower_i*16 + right_j];
             end             
         end
     end
    
    //Assign the final output
    assign q = state_reg;

endmodule

/*
  Compute the next state 
  COMB logic
*/
module state_update(
    input old_state,
    input wire [7:0] neighbours,
    output reg new_state
);
    //Count the number of ones, using an adder tree?
    /*
    	expanded_inputs[0]--
        					| -- level1[0] --						
        expanded_inputs[1]--				 |
                                             |--level2[0]        
        expanded_inputs[2]--                 | 
        					| -- level1[1] --						
        expanded_inputs[3]--				 
        
        expanded_inputs[4]--
        					| -- level1[2] --						
        expanded_inputs[5]--				 |
                                             |--level2[1]
        expanded_inputs[6]--                 |
        					| -- level1[3] --						
        expanded_inputs[7]--				        
    */
    reg unsigned [1:0] level1[4];
    reg unsigned [2:0] level2[2];
    reg unsigned [3:0] sum;
    //Summation logic
    genvar i;
    genvar level;
    generate 
        for (level=1; level<4; level=level+1) begin: genloop_stages
            if (level==1) begin
                for (i=0; i<4; i=i+1) begin: genloop_inner1
                    always @(*) begin
                		level1[i] = {1'b0, neighbours[2*i]} + {1'b0, neighbours[2*i+1]};
                    end
        		end
            end
            else if (level==2) begin
                for (i=0; i<2; i=i+1) begin: genloop_inner2
                    always @(*) begin
            			level2[i] = {1'b0, level1[i*2]} + {1'b0, level1[i*2+1]};
                    end
        		end
            end
            else begin
                always @(*) begin
                	sum = {1'b0, level2[0]} + {1'b0, level2[1]};
                    //sum = 4'h2;
                end
            end
        end  
    endgenerate 
    
    always @(*) begin
        //Perform comparison
        if (sum == 4'h0) begin
            new_state = 1'b0;
        end
        else if (sum == 4'h1) begin
            new_state = 1'b0;
        end
        else if (sum == 4'h2) begin
            new_state = old_state;;
        end
        else if (sum == 4'h3) begin
            new_state = 1'b1;
        end
        else begin
            new_state = 1'b0;
        end
    end
    
endmodule
