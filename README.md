This repository is done with AXI-Lite Master interface and AXI-Lite Slave interface, which obey with AXI4-Lite protocol.


# Introduction
Collection of AXI4 Lite bus interfaces based on the function(master or slave).


# Documentation
## axil_master module
This module is designed for writing data to slave and reading data from slave based on axi4-lite protocol. 

The two processes can work in parallel when input signals "INIT_WRITE" and "INIT_READ" assert. Other relevant signals such as data and address information should input before or at the same time when "INIT_WRITE" or "INIT_READ" assert.

You can also use the error information by finding "W_ERROR" or "R_ERROR".

Note that the address information has been shifted according to the data width.

## axil_slave module
This module is designed for been written or read according to the master's instruction, which is also obey with axi4-lite protocol.

The two processes can work in parallel.

You can also use register written by master or change register to tell master. Example is shown as "I_USER_\*" and "O_USER_\*".

Note that the address information has been shifted according to the data width.