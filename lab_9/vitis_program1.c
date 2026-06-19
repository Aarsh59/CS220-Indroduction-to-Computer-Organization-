#include <stdio.h>
#include "xil_io.h"
#include "xil_printf.h"

#ifndef PROCESSOR_IP_BASEADDR
#error "Define PROCESSOR_IP_BASEADDR to your AXI peripheral base address."
#endif

#define base_addr PROCESSOR_IP_BASEADDR
#define MAX_POLL_COUNT 50000000U

static const unsigned program[] = {
    0x20020200, 0x3C034865, 0x34636C6C, 0xAC430000, 0x3C046F20,
    0x3484576F, 0xAC440004, 0x3C05726C, 0x34A56421, 0xAC450008,
    0x2006000A, 0xA046000C, 0x200103EC, 0x20070000, 0x28E8000D,
    0x11000005, 0x00474820, 0x912A0000, 0x002A000C, 0x20E70001,
    0x0800000E, 0x200103E9, 0x0020000C
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

static void flush_chars(void) {
    unsigned i;

    for (i = 0; i < 4; i++) {
        xil_printf("%c", (char)(read_reg(8 + i) & 0xff));
    }

    write_reg(4, 1);
    while (read_reg(14) != 0) {
    }
    write_reg(4, 0);
}

int main(void) {
    unsigned done;
    unsigned flush_io_regs;
    unsigned prev_flush = 0;
    unsigned total_cycles;
    unsigned proc_cycles;
    unsigned print_count;
    unsigned i;
    unsigned timeout = 0;

    load_program();

    while (1) {
        if (timeout++ > MAX_POLL_COUNT) {
            xil_printf("\n\rTimeout: processor did not finish.\n\r");
            break;
        }

        done = read_reg(7);
        flush_io_regs = read_reg(14);

        if ((flush_io_regs != 0) && (prev_flush == 0)) {
            flush_chars();
        }
        prev_flush = flush_io_regs;

        if (done != 0) {
            print_count = read_reg(15);
            for (i = 0; i < print_count; i++) {
                xil_printf("%c", (char)(read_reg(8 + i) & 0xff));
            }
            xil_printf("\n\r");
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
