# Polimi Logical Network Memory Query Project

## Overview

This project was developed as a final project for the "Logical Network" course at Politecnico di Milano. The main objective was to implement a hardware component defined by a given specification.

## Specifications

### General Description

The module to be implemented has two 1-bit inputs (W and START) with 4 8-bit outputs (Z0, Z1, Z2, Z3) and a 1-bit computation completion signal (Done). Additionally, the hardware should interface with an external memory component via a 16-bit signal (MemoryAddress) and two 1-bit signals (EN, WE). The component receives the channel and the memory address from the W input to retrieve data and outputs the data on the specified channel.

### Functionality

Upon receiving a reset signal, the machine must return to its initial state:
- Z0, Z1, Z2, Z3 = "0000 0000"
- Done = '0'

Input data is distributed to the module via a sequence of bits on the W signal:
- The first two input bits represent the output channel address:
  - "00" corresponds to Z0
  - "01" corresponds to Z1
  - "10" corresponds to Z2
  - "11" corresponds to Z3
- The remaining bits correspond to the memory address (MemoryAddress) for the memory request.

All bits are sampled on the rising edge of the clock cycle.

The W signal can vary from 2 to 18 bits. The channel bits are guaranteed, while the remaining portion of the input string does not have a specified length. If a memory address is not provided in its entirety, it must be extended with '0's in the most significant bits. The sequence is valid only when the START signal is '1'.

Once data is acquired from memory, it must be registered on the corresponding output channel. All outputs with previously registered values must be displayed only when the Done bit is set to '1', which occurs for a single clock cycle each time a request to the module is successfully completed.

The START signal is guaranteed to remain '0' until the next request (i.e., when Done is '1'). The maximum computation time from when START returns to '0' until the channel output must be 20 clock cycles.

## Implementation

The implementation of the hardware component is provided in the following VHDL file:

- [Implementation Code](module.vhd)

For a full documentation about the project, see the report:

- [Documentation](ProjectReport.pdf)

## Experimental Results

### Synthesis Report

The synthesis report includes utilization and timing reports generated by Vivado:

#### Utilization Report
```text
+-------------------------+------+-------+-----------+-------+
| Site Type               | Used | Fixed | Available | Util% |
+-------------------------+------+-------+-----------+-------+
| Slice LUTs*             |   86 |     0 |    134600 |  0.06 |
| LUT as Logic            |   86 |     0 |    134600 |  0.06 |
| LUT as Memory           |    0 |     0 |     46200 |  0.00 |
| Slice Registers         |   57 |     0 |    269200 |  0.02 |
| Register as Flip Flop   |   57 |     0 |    269200 |  0.02 |
| Register as Latch       |    0 |     0 |    269200 |  0.00 |
| F7 Muxes                |    0 |     0 |     67300 |  0.00 |
+-------------------------+------+-------+-----------+-------+
```

#### Timing Report
On a requirement of 100.000ns, the slack is 96.989ns, which means that the longest combinatorial path has a delay of 3.011ns, comfortably meeting the design specifications.

## Simulation

For testing the module, the testbenches located in the `testbenches` folder were used. All provided testbenches run correctly on the machine, both pre- and post-synthesis, within the required timing constraints.

## Conclusion

The component was developed according to the specified criteria. It meets all timing constraints for result creation, clock constraints, and synthesis. I analyzed the problem in detail, using multiple testbenches provided by various instructors and created by myself for edge cases, covering all scenarios I could think of. I tested and reworked the circuit several times to optimize its performance and address potential issues as much as possible.
