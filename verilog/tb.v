`timescale 1ns/1ps

module prime_tb;

    reg  [31:0] n;
    reg         reset;
    reg         clk;

    wire        is_prime;
    wire        done;

    // Instantiate DUT
    prime uut (
        .n(n),
        .reset(reset),
        .clk(clk),
        .is_prime(is_prime),
        .done(done)
    );

    // Clock generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Simple behavioral prime checker (for verification)
    function is_prime_model;
        input [31:0] val;
        integer i;
        begin
            if (val < 2)
                is_prime_model = 0;
            else begin
                is_prime_model = 1;
                for (i = 2; i*i <= val; i = i + 1)
                    if (val % i == 0)
                        is_prime_model = 0;
            end
        end
    endfunction

    task run_test;
        input [31:0] test_val;
        reg expected;
        begin
            n = test_val;

            reset = 1;
            #20;
            reset = 0;

            wait(done == 1);
            #10;

            expected = is_prime_model(test_val);

            $display("--------------------------------------");
            $display("n = %0d", test_val);
            $display("Result   = %0d", is_prime);
            $display("Expected = %0d", expected);

            if (is_prime == expected)
                $display("PASS");
            else
                $display("FAIL");
        end
    endtask

    initial begin

        $dumpfile("prime_wave.vcd");
        $dumpvars(0, prime_tb);

        // Test small numbers
        run_test(0);
        run_test(1);
        run_test(2);
        run_test(3);
        run_test(4);
        run_test(5);
        run_test(7);
        run_test(9);
        run_test(11);
        run_test(15);
        run_test(17);
        run_test(19);
        run_test(21);

        $finish;
    end

endmodule
