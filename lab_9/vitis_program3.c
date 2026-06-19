#include <stdio.h>
#include "xil_io.h"
#include "xil_printf.h"

#ifndef PROCESSOR_IP_BASEADDR
#error "Define PROCESSOR_IP_BASEADDR to your AXI peripheral base address."
#endif

#define base_addr PROCESSOR_IP_BASEADDR
#define MAX_POLL_COUNT 50000000U

static const unsigned program[] = {
    0x201D0400, 0x200103EB, 0x0022000C, 0x04400004, 0x0C00000C,
    0x200603EC, 0x00C2000C, 0x08000019, 0x2002FFFF, 0x200603EC,
    0x00C2000C, 0x08000019, 0x23BDFFF8, 0xAFBF0004, 0xAFA20000,
    0x10400005, 0x2042FFFF, 0x0C00000C, 0x8FA30000, 0x00431020,
    0x08000016, 0x20020000, 0x8FBF0004, 0x23BD0008, 0x03E00008,
    0x200103E9, 0x0020000C
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

int main(void) {
    unsigned done;
    unsigned waiting_for_input;
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
        waiting_for_input = read_reg(16);

        if (waiting_for_input != 0) {
            xil_printf("Providing n = 10\n\r");
            send_input(10);
        }

        if (done != 0) {
            print_count = read_reg(15);
            for (i = 0; i < print_count; i++) {
                int out = (int)read_reg(8 + i);
                xil_printf("out%d = %d\n\r", i + 1, out);
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
