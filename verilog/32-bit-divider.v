module divide (
    input  [31:0] a,
    input  [31:0] b,
    input         reset,
    input         clk,
    output reg [31:0] q,
    output reg [31:0] r,
    output reg        done
);

reg [31:0] counter;

wire [31:0] sub_out;
wire sign;


addsub sub_unit (
    .a(r),
    .b(b),
    .sub(1'b1),
    .sum(sub_out),
    .sign(sign)
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        r       <= a;
        q       <= 32'd0;
        done    <= 1'b0;
        counter <= 32'd0;
    end
    else if (!done) begin

        if (b == 32'd0) begin
            r    <= 32'd0;
            q    <= 32'hFFFFFFFF;
            done <= 1'b1;
        end

        else if (b == 32'd1) begin
            r    <= 32'd0;
            q    <= a;
            done <= 1'b1;
        end

        else begin
            if (sign == 1'b1) begin
                done <= 1'b1;
            end
            else begin
                r       <= sub_out;
                q       <= q + 32'd1;
                counter <= counter + 32'd1;
            end
        end

    end
end

endmodule
