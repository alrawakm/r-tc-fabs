#include "Vskip_top.h"
#include "verilated.h"
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <cstdint>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    const unsigned expected_cycles = argc > 1 ? std::stoul(argv[1]) : 10116;
    std::ifstream inputs("generated/r_tc_fabs_nfbot/full_inputs.hex");
    std::ifstream labels("generated/r_tc_fabs_nfbot/full_expected_sparse.hex");
    if (!inputs || !labels) return 2;
    Vskip_top dut;
    auto tick = [&]() { dut.clk=0; dut.eval(); dut.clk=1; dut.eval(); dut.clk=0; dut.eval(); };
    dut.reset_n=0; dut.start=0;
    for (int i=0;i<13;++i) dut.features_q[i]=0;
    tick(); tick(); dut.reset_n=1; tick();
    unsigned count=0, failures=0; std::string hex,label;
    while (inputs >> hex) {
        if (!(labels >> label)) return 3;
        for (unsigned i=0;i<13;++i) {
            unsigned end=hex.size()>8*i ? hex.size()-8*i : 0;
            unsigned begin=end>8 ? end-8 : 0;
            dut.features_q[i]=end ? std::stoul(hex.substr(begin,end-begin),nullptr,16) : 0;
        }
        dut.start=1; tick(); dut.start=0;
        unsigned cycles=0;
        while (!dut.done && cycles<25000) { tick(); ++cycles; }
        unsigned expected=std::stoul(label,nullptr,16);
        if (!dut.done || dut.attack!=expected || cycles!=expected_cycles) {
            if (++failures<=10) std::cout << "MISMATCH index=" << count << " cycles=" << cycles << " prediction=" << unsigned(dut.attack) << " expected=" << expected << std::endl;
        }
        ++count;
        if (count%1000==0) std::cout << "PROGRESS checked=" << count << " mismatches=" << failures << std::endl;
    }
    if (labels >> label) return 4;
    dut.final();
    std::cout << (failures || count!=10000 ? "FAIL" : "PASS") << " vectors=" << count << " mismatches=" << failures << " cycles_per_inference=" << expected_cycles << std::endl;
    return failures || count!=10000 ? 1 : 0;
}
