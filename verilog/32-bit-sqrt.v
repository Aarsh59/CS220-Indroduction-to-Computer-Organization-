module sqrt (
    input  [31:0] n,
    input         reset,
    input         clk,
    output reg [31:0] sqr,
    output reg        done
);

  
    reg [2:0] state;
    localparam IDLE      = 3'd0,
               START_MUL = 3'd1,
               WAIT_MUL  = 3'd2,
               CHECK     = 3'd3,
               FINISH    = 3'd4;

    reg [31:0] m;
    reg        mul_reset;

    wire [31:0] p_low;
    wire [31:0] p_hi;
    wire        mul_done;

   
    mul multiplier (
        .a(m),
        .b(m),
        .reset(mul_reset),
        .clk(clk),
        .p_low(p_low),
        .p_hi(p_hi),
        .done(mul_done)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            m         <= 32'd0;
            sqr       <= 32'd0;
            done      <= 1'b0;
            mul_reset <= 1'b1;
        end
        else begin
            case (state)

                IDLE: begin
                    done      <= 1'b0;
                    m         <= 32'd0;
                    mul_reset <= 1'b1;
                    state     <= START_MUL;
                end

                START_MUL: begin
                    mul_reset <= 1'b0;   
                    state     <= WAIT_MUL;
                end

                WAIT_MUL: begin
                    if (mul_done)
                        state <= CHECK;
                end

                CHECK: begin
                   
                    if (p_hi != 0 || p_low > n) begin
                        sqr  <= m - 1;
                        done <= 1'b1;
                        state <= FINISH;
                    end
                    else begin
                        m <= m + 1;
                        mul_reset <= 1'b1;   
                        state <= START_MUL;
                    end
                end

                FINISH: begin
                   
                    state <= FINISH;
                end

            endcase
        end
    end

endmodule
