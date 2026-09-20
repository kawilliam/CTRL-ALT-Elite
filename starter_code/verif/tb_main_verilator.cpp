#include "verilated.h"
#include "verilated_vcd_c.h"

// Two-layer expansion trick to stringify the macro value, not the macro name
#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#define TOP_HEADER TOSTRING(VL_TOP.h)

#include TOP_HEADER

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    VL_TOP* tb = new VL_TOP;
    VerilatedVcdC* tfp = new VerilatedVcdC;

    tb->trace(tfp, 99);

    // Safe VCD filename handling (prevents out-of-bounds access if no CLI argument is passed)
    const char* vcd_filename = "wave.vcd";
    for (int i = 1; i < argc; i++) {
        if (argv[i][0] != '+') { // Ignore +plusargs like +TEST_DIR
            vcd_filename = argv[i];
            break;
        }
    }

    tfp->open(vcd_filename);

    while (!Verilated::gotFinish()) {
        tb->eval();
        tfp->dump(Verilated::time());
        Verilated::timeInc(1);
    }

    tfp->close();
    delete tfp;
    delete tb;
    return 0;
}