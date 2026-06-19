module prime (
    input  [31:0] n,
    input         reset,
    input         clk,
    output reg    is_prime,
    output reg    done
);

  
    reg [3:0] state;
    localparam IDLE        = 4'd0,
               START_SQRT  = 4'd1,
               WAIT_SQRT   = 4'd2,
               INIT_DIV    = 4'd3,
               START_DIV   = 4'd4,
               WAIT_DIV    = 4'd5,
               CHECK_DIV   = 4'd6,
               FINISH      = 4'd7;

    
    reg        sqrt_reset;
    wire [31:0] sqrt_out;
    wire        sqrt_done;

    sqrt sqrt_inst (
        .n(n),
        .reset(sqrt_reset),
        .clk(clk),
        .sqr(sqrt_out),
        .done(sqrt_done)
    );

  
    reg        div_reset;
    reg [31:0] divisor;
    wire [31:0] quotient;
    wire [31:0] remainder;
    wire        div_done;

    divide div_inst (
        .a(n),
        .b(divisor),
        .reset(div_reset),
        .clk(clk),
        .q(quotient),
        .r(remainder),
        .done(div_done)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            sqrt_reset  <= 1'b1;
            div_reset   <= 1'b1;
            divisor     <= 32'd2;
            is_prime    <= 1'b0;
            done        <= 1'b0;
        end
        else begin
            case (state)

                IDLE: begin
                    done <= 1'b0;
                    if (n < 2) begin
                        is_prime <= 1'b0;
                        done     <= 1'b1;
                        state    <= FINISH;
                    end
                    else begin
                        sqrt_reset <= 1'b1;
                        state <= START_SQRT;
                    end
                end

                START_SQRT: begin
                    sqrt_reset <= 1'b0;
                    state <= WAIT_SQRT;
                end

                WAIT_SQRT: begin
                    if (sqrt_done)
                        state <= INIT_DIV;
                end

                INIT_DIV: begin
                    divisor   <= 32'd2;
                    div_reset <= 1'b1;
                    state     <= START_DIV;
                end

                START_DIV: begin
                    div_reset <= 1'b0;
                    state     <= WAIT_DIV;
                end

                WAIT_DIV: begin
                    if (div_done)
                        state <= CHECK_DIV;
                end

                CHECK_DIV: begin
                    if (remainder == 0) begin
                        is_prime <= 1'b0;
                        done     <= 1'b1;
                        state    <= FINISH;
                    end
                    else if (divisor >= sqrt_out) begin
                        is_prime <= 1'b1;
                        done     <= 1'b1;
                        state    <= FINISH;
                    end
                    else begin
                        divisor   <= divisor + 1;
                        div_reset <= 1'b1;
                        state     <= START_DIV;
                    end
                end

                FINISH: begin
                    state <= FINISH;
                end

            endcase
        end
    end

endmodule
