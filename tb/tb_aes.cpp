#include <verilated.h>	
#include "Vtop.h"	
#include <verilated_vcd_c.h>
#include <iostream>
#include <fstream>
#include <svdpi.h>
#include <cstdlib> 
#include <time.h>

#include "aes.h"

int main(int argc, char** argv) {

    int exit_code = 0;

    srand(time(0));
    VerilatedContext* contextp = new VerilatedContext;
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    Vtop* top = new Vtop{contextp};


    top->rst_ni = 0;
    top->clk_i = 0;

    VerilatedVcdC* tfp = 0;
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);  // Trace 99 levels of hierarchy
    tfp->open("build/aes.vcd");
    
    while (contextp->time() < 10) {
        contextp->timeInc(1);
        top->clk_i = !top->clk_i;
        if (!top->clk_i) {
            top->rst_ni = 0;
        }
        top->eval();
        tfp->dump(contextp->time());
    }

    top->rst_ni = 1;
    
    while (contextp->time() < 20) {
        contextp->timeInc(1);
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(contextp->time());
    }

    //Reset over - now start testing
    //But first initialize RNG
    top->trivium_iv_i[0] = rand() & 0xffffffff;     //32 bit
    top->trivium_iv_i[1] = rand() & 0xffffffff;     //32 bit
    top->trivium_iv_i[2] = rand() & 0xffff;         //16 bit
    top->trivium_key_i[0] = rand() & 0xffffffff;     //32 bit
    top->trivium_key_i[1] = rand() & 0xffffffff;     //32 bit
    top->trivium_key_i[2] = rand() & 0xffff;         //16 bit
    
    
    //Wait for one cycle.
    contextp->timeInc(1);
    top->clk_i = !top->clk_i;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    top->clk_i = !top->clk_i;
    top->eval();
    tfp->dump(contextp->time());


    top->trivium_reseed_i = 1;

    //Wait for one cycle.
    contextp->timeInc(1);
    top->clk_i = !top->clk_i;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    top->clk_i = !top->clk_i;
    top->eval();
    tfp->dump(contextp->time());
    

    top->trivium_reseed_i = 0;
    //Wait until Trivium has been initialized.
    while (top->busy_o) {
            contextp->timeInc(1);
            top->clk_i = !top->clk_i;
            top->eval();
            tfp->dump(contextp->time());
    }
    contextp->timeInc(1);
    top->clk_i = !top->clk_i;
    top->eval();
    tfp->dump(contextp->time());

    int num_tests = 1000; //do {num_tests} encryptions computations



    for(int i = 0; i < 5; i++) {

        uint8_t key[16] = {0};
        uint8_t pt[16] = {0};
        uint8_t data[16] = {0};

        //Initialize tinyAES which is our reference model.
        //Choose a random key and plaintext. Encrypt it and store the result into ct*_test
        for(int i = 0; i < 16; i++)
        {
            key[i] = rand() & 0xff;
            pt[i] = rand() & 0xff;
            data[i] = pt[i];
        }

        struct AES_ctx ctx;
        AES_init_ctx(&ctx, key);
        AES_ECB_encrypt(&ctx, data);

        uint32_t ct0_test = (data[12]<<24) | (data[8]<<16) | (data[4]<<8) |  data[0];
        uint32_t ct1_test = (data[13]<<24) | (data[9]<<16) | (data[5]<<8) |  data[1];
        uint32_t ct2_test = (data[14]<<24) | (data[10]<<16) | (data[6]<<8) |  data[2];
        uint32_t ct3_test = (data[15]<<24) | (data[11]<<16) | (data[7]<<8) |  data[3];

        //---------------------------------

        uint32_t m0, m1;
        //Use the plaintext and key from above and split it into three shares.
        for(int i = 0; i < 4; i++) {
            m0 = rand();
            m1 = rand();
            top->aes_key_i[0][i] = ((key[i+12] << 24) | (key[i+8] << 16) | (key[i+4] << 8) | key[i+0]) ^m0^m1;
            top->aes_key_i[1][i] = m0;
            top->aes_key_i[2][i] = m1;
        }

        for(int i = 0; i < 4; i++) {
            m0 = rand();
            m1 = rand();
            top->aes_plain_i[0][i] = ((pt[i+12] << 24) | (pt[i+8] << 16) | (pt[i+4] << 8) | pt[i+0]) ^m0^m1;
            top->aes_plain_i[1][i] = m0;
            top->aes_plain_i[2][i] = m1;
        }
    
        //Start the encryption.
        top->start_i = 1;
     
        //Wait for one cycle.
        contextp->timeInc(1);
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(contextp->time());
        contextp->timeInc(1);
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(contextp->time());

        top->start_i = 0;
        //Wait until encryption has finished.
        while (top->busy_o) {
            contextp->timeInc(1);
            top->clk_i = !top->clk_i;
            top->eval();
            tfp->dump(contextp->time());
        }
        contextp->timeInc(1);
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(contextp->time());

        //Check if AES model and our masked AES returned the same result.
        uint32_t ct0 = top->aes_ct_o[0][0] ^  top->aes_ct_o[1][0] ^ top->aes_ct_o[2][0];
        uint32_t ct1 = top->aes_ct_o[0][1] ^  top->aes_ct_o[1][1] ^ top->aes_ct_o[2][1];
        uint32_t ct2 = top->aes_ct_o[0][2] ^  top->aes_ct_o[1][2] ^ top->aes_ct_o[2][2];
        uint32_t ct3 = top->aes_ct_o[0][3] ^  top->aes_ct_o[1][3] ^ top->aes_ct_o[2][3];

        if((ct0 != ct0_test) ||(ct1 != ct1_test) || (ct2 != ct2_test) || (ct3 != ct3_test)  )
        {
            std::cout << "ERROR! Detected incorrect ciphertext. " << std::endl;
            std::cout << std::hex << ct0 << " " << ct0_test << std::endl;
            std::cout << std::hex << ct1 << " " << ct1_test << std::endl;
            std::cout << std::hex << ct2 << " " << ct2_test << std::endl;
            std::cout << std::hex << ct3 << " " << ct3_test << std::endl;
            exit_code = -1;
            break;
        }

        //do a few idle cycles
        for(int j = 0; j < 10; j++) {
            contextp->timeInc(1);
            top->clk_i = !top->clk_i;
            top->eval();
            tfp->dump(contextp->time());
        }
    }


    if(!exit_code)
        std::cout << "Simulation successful." << std::endl;
    else
        std::cout << "Simulation failed." << std::endl;


    tfp->close();
    delete top;
    delete contextp;
    return exit_code;
}
