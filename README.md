# Second-Order Hardware Masking of the AES with Low Randomness and Low Latency

## Directory structure
* `rtl/`: SystemVerilog code of our optimized AES implementation using COTG connected to a Trivium RNG.  It uses 3 200 random bits per encryption.
* `tb_sbox.cpp`: Verilator testbench written in C++.
* `Makefile`: Makefile used to build the Verilator model.
* `build/`: directory used to store build artifacts such as the Verilator model and the VCD trace file

## Simulation

In order to simulate the AES design with Verilator, the following steps are necessary:

1. Install the necessary software:
   - Verilator (5.014 2023-08-06 rev v5.014-35-ge6b0bdd4d). Build it from source by cloning
the [github repository](https://github.com/verilator/verilator) . Follow the build instructions there. Use commit e6b0bdd4d.
   - gcc/g++ 11.4.0
   - (Optional) [GtkWave](https://gtkwave.sourceforge.net/) for viewing the resulting VCD trace file
1. Set the environment variable `$VERILATOR HOME DIR` such that it points to the Verilator installation directory. For example, if you cloned the Verilator repository in `$HOME`, it should be set to `$HOME/verilator`, e.g.: 
`export VERILATOR_HOME_DIR = $HOME/verilator/`
1. Build the Verilator model by running `make`
1. Start the simulation by running `./build/aes`, which first initializes the Trivium RNG with a random key and IV, and then does 1000 AES encryption with a random key and plaintext. The ciphertext is compared with the output of the tinyAES128 implementation. The simulation trace file can be found in aes `build/aes.vcd`.
