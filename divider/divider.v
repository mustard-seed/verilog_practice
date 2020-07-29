`timescale 1ns/1ps

module divider(
		clk,
		rst,
		load,
		n,
		d,
		q,
		r,
		ready
	);
	//Width of the dividend, quotient
	parameter WIDTH_N = 16;
	//Width of the divisor, remainder
	parameter WIDTH_D = 16;

	input 					clk;
	input					rst;
	input					load;
	input	[WIDTH_N-1:0]	n;
	input	[WIDTH_D-1:0]	d;
	output	[WIDTH_N-1:0]	q;
	output  [WIDTH_D-1:0]	r;
	output 					ready;

	/**
	 * States
	 */
	localparam 	S_IDLE = 2'b00,
				S_COMP = 2'b01,
				S_DONE = 2'b10;

	/**
	 * Define internal registers
	 */
	reg [4:0] regCompCount;
	reg [1:0] regState;
	
	reg [WIDTH_D-1:0] regDivisor;
	reg [WIDTH_N-1:0] regDividend;
	reg [WIDTH_N-1:0] regQuotient;
	reg [WIDTH_D-1:0] regRemainder;

	/**
	 * Signal wires
	 */
	reg [7:0] nextCompCount;
	reg [1:0] nextState;
	wire [WIDTH_D-1:0] wireDiff;
	reg  miniQuotient;
	reg  [WIDTH_N-1:0] nextRemainder;

	/**
	 * DP: dividend register shift
	 */
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			regDividend <= {(WIDTH_N){1'b0}};
		end
		else begin
			if (regState == S_IDLE && load == 1'b1) begin
				regDividend <= n;
			end
			else if (regState == S_COMP) begin
				regDividend[WIDTH_N-1:0] <= {regDividend[WIDTH_N-2:0], 1'b0};
			end
		end
	end 

	/**
	 * DP: quotient register shift
	 */
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			regDividend <= {(WIDTH_N){1'b0}};
		end
		else begin
			if (regState == S_IDLE && load == 1'b1) begin
				regQuotient <= 0;
			end
			else if (regState == S_COMP) begin
				regQuotient[WIDTH_N-1:0] <= {regQuotient[WIDTH_N-2:0], miniQuotient};
			end
		end
	end 

	/**
	 * DP: Division logic, rad-2
	 */
	always @ (*) begin
		miniQuotient = 0;
		nextRemainder = 0;

		if (wireDiff < regDivisor) begin
			miniQuotient = 1'b0;
			nextRemainder = wireDiff;
		end
		else begin
			miniQuotient = 1'b1;
			nextRemainder = wireDiff - regDivisor;
		end
	end

	/**
	 * DP: register updates
	 */
	 always @(posedge clk) begin
	 	if(rst == 1'b1) begin
	 		 regRemainder <= 0;
	 		 regDivisor <= 0;
	 	end 
	 	else begin
	 		if (regState == S_COMP) begin
	 			regRemainder <= nextRemainder;
	 		end
	 		else if (regState == S_IDLE && load == 1'b1) begin
	 			regRemainder <= 0;
	 		end

	 		if (regState == S_IDLE && load == 1'b1) begin
	 			regDivisor <= d;
	 		end
	 	end
	 end

	 /**
	  * wireDiff logic
	  */
	  assign wireDiff [WIDTH_D-1:0] = {regRemainder[WIDTH_D-2:0], regDividend[WIDTH_N-1]};
	  assign ready = (regState == S_DONE || regState == S_IDLE) ? 1'b1 : 1'b0;
	  assign r = regRemainder;
	  assign q = regQuotient;

	 /**
	  * State update
	  */
	  always @(posedge clk) begin
	  	if(rst) begin
	  		 regState <= S_IDLE;
	  		 regCompCount <= 0;
	  	end 
	  	else begin
	  		case (regState)
	  			S_IDLE: begin
	  				if (load == 1'b1) begin
	  					regState <= S_COMP;
	  					regCompCount <= 0;
	  				end
	  			end
	  			S_COMP: begin
	  				if (regCompCount == (WIDTH_N-1)) begin
	  					regState <= S_DONE;
	  				end
	  				regCompCount <= regCompCount + 1;
	  			end
	  			default: begin
	  				regState <= S_IDLE;
	  			end
	  		endcase
	  	end
	  end
endmodule




	