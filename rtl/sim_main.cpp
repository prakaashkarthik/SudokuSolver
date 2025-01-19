#include "Vtb_top.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>
#include <stdlib.h>

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char** argv) {
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;

    
    Vtb_top* top = new Vtb_top{contextp};
    top->trace(m_trace, 5);
    m_trace->open("sudoku.vcd");

    while (sim_time < MAX_SIM_TIME) {
        if (sim_time < 1) {
            top->rst_b = 0;
            top->clk = 0;
            sim_time++;
            continue;
        }

        top->rst_b = 1;
        top->clk ^= 1;
        top->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }


    m_trace->close(); 
    delete top;
    delete contextp;
    return 0;
}