#include <stdio.h>
#include "xil_io.h"
#include "xil_printf.h"

#ifndef PROCESSOR_IP_BASEADDR
#error "Define PROCESSOR_IP_BASEADDR to your AXI peripheral base address."
#endif

#define base_addr PROCESSOR_IP_BASEADDR
#define MAX_POLL_COUNT 50000000U

static const unsigned program[] = {
    0x200103EB, 0x0022000C, 0x0023000C, 0x20040000, 0x200603EC,
    0x0083282A, 0x10A00012, 0x30870001, 0x14E00007, 0x20480000,
    0x20890000, 0x0C000017, 0x004A1020, 0x00C2000C, 0x20840001,
    0x08000005, 0x20480000, 0x20890000, 0x0C000017, 0x004A1022,
    0x00C2000C, 0x20840001, 0x08000005, 0x01095020, 0x03E00008,
    0x200603E9, 0x00C0000C
};

static void write_reg(unsigned offset, unsigned value) {
    Xil_Out32(base_addr + offset, value);
}

static unsigned read_reg(unsigned offset) {
    return Xil_In32(base_addr + offset);
}

static void load_program(void) {
    unsigned i;

    write_reg(0, 1);
    write_reg(3, 0);
    write_reg(4, 0);
    write_reg(6, 0);
    write_reg(0, 0);

    for (i = 0; i < (sizeof(program) / sizeof(program[0])); i++) {
        write_reg(1, i);
        write_reg(2, program[i]);
    }

    write_reg(3, 1);
}

static void send_input(int value) {
    write_reg(5, (unsigned)value);
    write_reg(6, 1);
    while (read_reg(16) != 0) {
    }
    write_reg(6, 0);
}

static void flush_outputs(unsigned *print_index) {
    unsigned i;

    for (i = 0; i < 4; i++) {
        int out = (int)read_reg(8 + i);
        xil_printf("out%d = %d\n\r", *print_index, out);
        (*print_index)++;
    }

    write_reg(4, 1);
    while (read_reg(14) != 0) {
    }
    write_reg(4, 0);
}

int main(void) {
    unsigned done;
    unsigned flush_io_regs;
    unsigned waiting_for_input;
    unsigned prev_flush = 0;
    unsigned print_index = 1;
    unsigned input_step = 0;
    unsigned total_cycles;
    unsigned proc_cycles;
    unsigned print_count;
    unsigned i;
    unsigned timeout = 0;

    load_program();

    while (1) {
        if (timeout++ > MAX_POLL_COUNT) {
            xil_printf("Timeout: processor did not finish.\n\r");
            break;
        }

        done = read_reg(7);
        flush_io_regs = read_reg(14);
        waiting_for_input = read_reg(16);

        if (waiting_for_input != 0) {
            if (input_step == 0) {
                xil_printf("Providing x = 10\n\r");
                send_input(10);
                input_step++;
            } else if (input_step == 1) {
                xil_printf("Providing N = 6\n\r");
                send_input(6);
                input_step++;
            }
        }

        if ((flush_io_regs != 0) && (prev_flush == 0)) {
            flush_outputs(&print_index);
        }
        prev_flush = flush_io_regs;

        if (done != 0) {
            print_count = read_reg(15);
            for (i = 0; i < print_count; i++) {
                int out = (int)read_reg(8 + i);
                xil_printf("out%d = %d\n\r", print_index, out);
                print_index++;
            }
            break;
        }
    }

    total_cycles = read_reg(12);
    proc_cycles = read_reg(13);
    xil_printf("Total cycles: %u, computation cycles: %u\n\r",
               total_cycles, proc_cycles);
    xil_printf("CPI: %d.%03d\n\r",
               (int)(proc_cycles / (sizeof(program) / sizeof(program[0]))),
               (int)((proc_cycles % (sizeof(program) / sizeof(program[0]))) * 1000 /
                     (sizeof(program) / sizeof(program[0]))));

    return 0;
}
