`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////////////////////////
// Engineer: Don
// Module Name: axil_master.v
// Description: This File is designed for AXI-Lite Master interface,  
//              and you can use input signals "Write Data Signals" to begin a write process,
//              or use input signals "Read Data Signals" to begin a read process.
// Revision:
// Revision 0.01 - File Created
// Additional Comments:   Notice that the parameter C_S_AXI_ADDR_WIDTH is set as 6
//                        for the reason that C_S_AXI_DATA_WIDTH is 32-bits.
//                        Only the former 4-bits [5:2] are designed for selecting slave's 16 slv_regs.
//                        If C_S_AXI_DATA_WIDTH = 64, then C_S_AXI_ADDR_WIDTH should be 7.
//                        And [6:3] are designed for selecting the 16 slv_regs.
//
//                        In this module, you can use (W_BASE_ADDR + W_OFFT_ADDR) for selecting 
//                        which slv_reg you want to. 
//                        For example, 0 is slv_reg0, 1 is slv_reg1.
//                        "C_M_AXI_ADDR_SHIFT" will do the data width shift for address.
//
//                        Of course, you can not use the shift width if master and slave are designed
//                        in the same way.
//////////////////////////////////////////////////////////////////////////////////////////////////////

// < Write State Machine
`define WR_IDLE  2'b01
`define WR_WRITE 2'b10
//   Write State Machine >

// < Read  State Machine
`define RD_IDLE  2'b01
`define RD_READ  2'b10
//   Read  State Machine >

module axil_master # (
  // Users to add parameters here

  // User parameters ends
  // Do not modify the parameters beyond this line

  // Width of M_AXI address bus. 
  // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
  parameter integer C_M_AXI_ADDR_WIDTH  = 6   ,
  // Width of M_AXI data bus. 
  // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
  parameter integer C_M_AXI_DATA_WIDTH  = 32  ,
  // Width of M_AXI address shift width.
  // The master can not use the SHIFT width if master and slave are designed in the same way.
  parameter integer C_M_AXI_ADDR_SHIFT  = C_M_AXI_DATA_WIDTH == 32 ? 2 : ( C_M_AXI_DATA_WIDTH == 64 ? 3 : 0)
) (
  // Users to add ports here

  // < Write Data Signals
  input   wire                              INIT_WRITE  ,
  input   wire [C_M_AXI_ADDR_WIDTH-1 : 0]   W_BASE_ADDR ,
  input   wire [C_M_AXI_ADDR_WIDTH-1 : 0]   W_OFFT_ADDR ,
  input   wire [C_M_AXI_DATA_WIDTH-1 : 0]   W_DATA      ,
  output  wire                              W_RESP      ,
  //  Write Data Signals >

  // < Read Data Signals
  input   wire                              INIT_READ   ,
  input   wire [C_M_AXI_ADDR_WIDTH-1 : 0]   R_BASE_ADDR ,
  input   wire [C_M_AXI_ADDR_WIDTH-1 : 0]   R_OFFT_ADDR ,
  output  wire [C_M_AXI_DATA_WIDTH-1 : 0]   R_DATA      ,
  output  wire                              R_RESP      ,
  //   Read Data Signals >
  
  // User ports ends
  // Do not modify the ports beyond this line


  // AXI clock signal
  input   wire                              M_AXI_ACLK    ,
  // AXI active low reset signal
  input   wire                              M_AXI_ARESETN ,
  // Master Interface Write Address Channel ports. Write address (issued by master)
  output  wire [C_M_AXI_ADDR_WIDTH-1 : 0]   M_AXI_AWADDR  ,
  // Write channel Protection type.
  // This signal indicates the privilege and security level of the transaction,
  // and whether the transaction is a data access or an instruction access.
  output  wire [2 : 0]                      M_AXI_AWPROT  ,
  // Write address valid. 
  // This signal indicates that the master signaling valid write address and control information.
  output  wire                              M_AXI_AWVALID ,
  // Write address ready. 
  // This signal indicates that the slave is ready to accept an address and associated control signals.
  input   wire                              M_AXI_AWREADY ,
  // Master Interface Write Data Channel ports. Write data (issued by master)
  output  wire [C_M_AXI_DATA_WIDTH-1 : 0]   M_AXI_WDATA   ,
  // Write strobes. 
  // This signal indicates which byte lanes hold valid data.
  // There is one write strobe bit for each eight bits of the write data bus.
  output  wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB   ,
  // Write valid. This signal indicates that valid write data and strobes are available.
  output  wire                              M_AXI_WVALID  ,
  // Write ready. This signal indicates that the slave can accept the write data.
  input   wire                              M_AXI_WREADY  ,
  // Master Interface Write Response Channel ports. 
  // This signal indicates the status of the write transaction.
  input   wire [1 : 0]                      M_AXI_BRESP   ,
  // Write response valid. 
  // This signal indicates that the channel is signaling a valid write response
  input   wire                              M_AXI_BVALID  ,
  // Response ready. This signal indicates that the master can accept a write response.
  output  wire                              M_AXI_BREADY  ,
  // Master Interface Read Address Channel ports. Read address (issued by master)
  output  wire [C_M_AXI_ADDR_WIDTH-1 : 0]   M_AXI_ARADDR  ,
  // Protection type. 
  // This signal indicates the privilege and security level of the transaction, 
  // and whether the transaction is a data access or an instruction access.
  output  wire [2 : 0]                      M_AXI_ARPROT  ,
  // Read address valid. 
  // This signal indicates that the channel is signaling valid read address and control information.
  output  wire                              M_AXI_ARVALID ,
  // Read address ready. 
  // This signal indicates that the slave is ready to accept an address and associated control signals.
  input   wire                              M_AXI_ARREADY ,
  // Master Interface Read Data Channel ports. Read data (issued by slave)
  input   wire [C_M_AXI_DATA_WIDTH-1 : 0]   M_AXI_RDATA   ,
  // Read response. This signal indicates the status of the read transfer.
  input   wire [1 : 0]                      M_AXI_RRESP   ,
  // Read valid. This signal indicates that the channel is signaling the required read data.
  input   wire                              M_AXI_RVALID  ,
  // Read ready. This signal indicates that the master can accept the read data and response information.
  output  wire                              M_AXI_RREADY
);

reg   [1:0] wr_state = `WR_IDLE, wr_next = `WR_IDLE ;
reg   [1:0] rd_state = `RD_IDLE, rd_next = `RD_IDLE ;

// AXI4LITE signals
//write address valid
reg                               axi_awvalid        = 1'b0   ;
//write data valid  
reg                               axi_wvalid         = 1'b0   ;
//read address valid
reg                               axi_arvalid        = 1'b0   ;
//read data acceptance
reg                               axi_rready         = 1'b0   ;
//write response acceptance
reg                               axi_bready         = 1'b0   ;
//write address
reg   [C_M_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr         = {C_M_AXI_ADDR_WIDTH{1'b0}};
//write data
reg   [C_M_AXI_DATA_WIDTH-1 : 0]  axi_wdata          = {C_M_AXI_DATA_WIDTH{1'b0}};
//read addresss
reg   [C_M_AXI_ADDR_WIDTH-1 : 0]  axi_araddr         = {C_M_AXI_ADDR_WIDTH{1'b0}};

//A pulse to initiate a write transaction
reg                               start_single_write = 1'b0   ;
//A pulse to initiate a read transaction
reg                               start_single_read  = 1'b0   ;
//flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
reg                               write_done         = 1'b0   ;
//flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
reg                               read_done          = 1'b0   ;


reg   rInitWrite   = 1'b0, _rInitWrite = 1'b0 ;
reg   rInitRead    = 1'b0, _rInitRead  = 1'b0 ;

reg   read_issued  = 1'b0;
reg   write_issued = 1'b0;

reg   [C_M_AXI_DATA_WIDTH-1 : 0] rData = {C_M_AXI_DATA_WIDTH{1'b0}};

wire  init_wr_pulse       ;
wire  init_rd_pulse       ;

//Adding the offset address to the base addr of the slave
assign M_AXI_AWADDR  = axi_awaddr ;
//AXI 4 write data
assign M_AXI_WDATA   = axi_wdata  ;
assign M_AXI_AWPROT  = 3'b000     ;
assign M_AXI_AWVALID = axi_awvalid;
//Write Data(W)
assign M_AXI_WVALID  = axi_wvalid ;
//Set all byte strobes in this example
assign M_AXI_WSTRB   = 4'b1111    ;
//Write Response (B)
assign M_AXI_BREADY  = axi_bready ;
//Read Address (AR)
assign M_AXI_ARADDR  = axi_araddr ;
assign M_AXI_ARVALID = axi_arvalid;
assign M_AXI_ARPROT  = 3'b001     ;
//Read and Read Response (R)
assign M_AXI_RREADY  = axi_rready ;

assign W_RESP        = write_done ;
assign R_DATA        = rData      ;
assign R_RESP        = read_done  ;

assign init_wr_pulse = ( !_rInitWrite ) & rInitWrite  ;
assign init_rd_pulse = ( !_rInitRead  ) & rInitRead   ;

// Flag errors
// assign W_ERROR = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);
// assign R_ERROR = (axi_rready & M_AXI_RVALID & M_AXI_RRESP[1]);

//Generate a pulse to initiate write transaction.
always @(posedge M_AXI_ACLK) begin
  if ( M_AXI_ARESETN == 0 ) begin
    rInitWrite  <= 1'b0 ;
    _rInitWrite <= 1'b0 ;
  end
  else begin
    rInitWrite  <= INIT_WRITE ;
    _rInitWrite <= rInitWrite ;
  end
end

//Generate a pulse to initiate read transaction.
always @(posedge M_AXI_ACLK) begin
  if ( M_AXI_ARESETN == 0 ) begin
    rInitRead  <= 1'b0 ;
    _rInitRead <= 1'b0 ;
  end
  else begin
    rInitRead  <= INIT_READ ;
    _rInitRead <= rInitRead ;
  end
end

// < Write Process

//--------------------
//Write Address Channel
//--------------------
always @(posedge M_AXI_ACLK) begin
  //Only VALID signals must be deasserted during reset per AXI spec          
  //Consider inverting then registering active-low reset for higher fmax     
  if (M_AXI_ARESETN == 0 || init_wr_pulse == 1'b1)
    axi_awvalid <= 1'b0;
  //Signal a new address/data command is available by user logic
  else if (start_single_write)
    axi_awvalid <= 1'b1;
  //Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
  else if (M_AXI_AWREADY && axi_awvalid)
    axi_awvalid <= 1'b0;
  else
    axi_awvalid <= axi_awvalid;
end

//--------------------
//Write Data Address
//--------------------
always @(posedge M_AXI_ACLK) begin
  if (M_AXI_ARESETN == 0  || init_wr_pulse == 1'b1)
    axi_awaddr <= 0;
  // Signals a new write address/ write data is         
  // available by user logic                            
  else if (start_single_write)
    axi_awaddr <= (W_BASE_ADDR + W_OFFT_ADDR) << C_M_AXI_ADDR_SHIFT ;
  else
    axi_awaddr <= axi_awaddr                ;
end


//--------------------
//Write Data Channel
//--------------------
always @(posedge M_AXI_ACLK) begin 
  if (M_AXI_ARESETN == 0  || init_wr_pulse == 1'b1)
    axi_wvalid <= 1'b0;
     //Signal a new address/data command is available by user logic              
  else if (start_single_write)                                                                                                        
    axi_wvalid <= 1'b1;                                                                                                                       
  //Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)      
  else if (M_AXI_WREADY && axi_wvalid)                                        
    axi_wvalid <= 1'b0;
end 

//--------------------
//Write Data Information
//--------------------
// Write data generation
always @(posedge M_AXI_ACLK) begin
  if (M_AXI_ARESETN == 0 || init_wr_pulse == 1'b1 )
    axi_wdata <= 0        ;
  // Signals a new write address/ write data is
  // available by user logic
  else if (start_single_write)
    axi_wdata <= W_DATA   ;
end

//----------------------------
//Write Response (B) Channel
//----------------------------
always @(posedge M_AXI_ACLK) begin
  if (M_AXI_ARESETN == 0 || init_wr_pulse == 1'b1)
    axi_bready <= 1'b0;
  // accept/acknowledge bresp with axi_bready by the master
  // when M_AXI_BVALID is asserted by slave 
  else if (M_AXI_BVALID && ~axi_bready)
    axi_bready <= 1'b1;
  // deassert after one clock cycle
  else if (axi_bready)
    axi_bready <= 1'b0;
  // retain the previous value
  else
    axi_bready <= axi_bready;
end


// < Write State Machine
always @( posedge M_AXI_ACLK ) begin
  if ( M_AXI_ARESETN == 1'b0 )
    wr_state <= `WR_IDLE;
  else
    wr_state <= wr_next;
end

always @(*) begin
  if ( M_AXI_ARESETN == 1'b0 )
    wr_next = `WR_IDLE;
  else begin
    wr_next = wr_state;
    case (wr_state)
      `WR_IDLE:
        if ( init_wr_pulse == 1'b1 )
          wr_next = `WR_WRITE;
      `WR_WRITE:
        if ( M_AXI_BVALID && axi_bready )
          wr_next = `WR_IDLE ;
    endcase
  end
end
// Write State Machine >

always @(posedge M_AXI_ACLK) begin
  if ( M_AXI_ARESETN == 0 || init_wr_pulse == 1'b1 )
    write_done <= 1'b0;
  //The writes_done should be associated with a bready response
  else if ( M_AXI_BVALID && axi_bready && wr_state == `WR_WRITE )
    write_done <= 1'b1;
  else
    write_done <= 1'b0;
end

always @(posedge M_AXI_ACLK) begin
  if ( M_AXI_ARESETN == 0 )
    start_single_write <= 1'b0;
  else if ( wr_state == `WR_IDLE )
    start_single_write <= 1'b0;
  else if ( wr_state == `WR_WRITE ) begin
    if ( ~axi_awvalid && ~axi_wvalid && ~M_AXI_BVALID && ~start_single_write && ~write_issued )
      start_single_write <= 1'b1;
    else
      start_single_write <= 1'b0; //Negate to generate a pulse
  end
end


always @( posedge M_AXI_ACLK ) begin
  if ( M_AXI_ARESETN == 0 || init_wr_pulse == 1'b1 )
    write_issued <= 1'b0;
  else if ( wr_state == `WR_IDLE )
    write_issued <= 1'b0;
  else if ( wr_state == `WR_WRITE ) begin
    if ( ~axi_awvalid && ~axi_wvalid && ~M_AXI_BVALID && ~start_single_write && ~write_issued )
      write_issued <= 1'b1;
    else if ( axi_bready )
      write_issued <= 1'b0;
  end
end

//   Write Process >



// < Read Process

//----------------------------
//Read Address Channel
//----------------------------
always @(posedge M_AXI_ACLK) begin
  if (M_AXI_ARESETN == 0 || init_rd_pulse == 1'b1)
    axi_arvalid <= 1'b0;
  //Signal a new read address command is available by user logic
  else if (start_single_read)
    axi_arvalid <= 1'b1;
  //RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)
  else if (M_AXI_ARREADY && axi_arvalid)
    axi_arvalid <= 1'b0;
  else
    axi_arvalid <= axi_arvalid;
end

//--------------------------------
//Read Data (and Response) Channel
//--------------------------------
always @(posedge M_AXI_ACLK)  begin
  if (M_AXI_ARESETN == 0 || init_rd_pulse == 1'b1)
    axi_rready <= 1'b0;
  // accept/acknowledge rdata/rresp with axi_rready by the master
  // when M_AXI_RVALID is asserted by slave
  else if (M_AXI_RVALID && ~axi_rready)
    axi_rready <= 1'b1;
  // deassert after one clock cycle 
  else if (axi_rready)
    axi_rready <= 1'b0;
  else
    axi_rready <= axi_rready  ;
end

//Read Addresses                                              
always @(posedge M_AXI_ACLK) begin
  if (M_AXI_ARESETN == 0  || init_rd_pulse == 1'b1)
    axi_araddr <= 0;
  // Signals a new write address/ write data is
  // available by user logic
  else if ( start_single_read ) 
    axi_araddr <= ( R_BASE_ADDR + R_OFFT_ADDR ) << C_M_AXI_ADDR_SHIFT ;                                                       
end


// < Read State Machine
always @( posedge M_AXI_ACLK ) begin
  if ( M_AXI_ARESETN == 1'b0 )
    rd_state <= `RD_IDLE;
  else
    rd_state <= rd_next;
end

always @(*) begin
  if ( M_AXI_ARESETN == 1'b0 )
    rd_next = `RD_IDLE;
  else begin
    rd_next = rd_state;
    case (rd_state)
      `RD_IDLE:
        if ( init_rd_pulse == 1'b1 )
          rd_next = `RD_READ;
      `RD_READ:
        if ( M_AXI_RVALID && axi_rready )
          rd_next = `RD_IDLE;
    endcase
  end
end
//   Read State Machine >

always @( posedge M_AXI_ACLK ) begin
  if ( M_AXI_ARESETN == 0 || init_rd_pulse == 1'b1 )
    start_single_read <= 1'b0;
  else if ( rd_state == `RD_IDLE )
    start_single_read <= 1'b0;
  else if ( rd_state == `RD_READ ) begin        
    if (~axi_arvalid && ~M_AXI_RVALID && ~start_single_read && ~read_issued)
      start_single_read <= 1'b1;
    else
      start_single_read <= 1'b0; //Negate to generate a pulse
  end
end


always @( posedge M_AXI_ACLK ) begin
  if ( M_AXI_ARESETN == 0 || init_rd_pulse == 1'b1 )
    read_issued <= 1'b0;
  else if ( rd_state == `RD_IDLE )
    read_issued <= 1'b0;
  else if ( rd_state == `RD_READ ) begin
    if ( ~axi_arvalid && ~M_AXI_RVALID && ~start_single_read && ~read_issued )
      read_issued <= 1'b1;
    else if ( axi_rready )
      read_issued <= 1'b0;
  end
end

always @(posedge M_AXI_ACLK) begin
  if (M_AXI_ARESETN == 0 || init_rd_pulse == 1'b1)
    read_done <= 1'b0;
  //The reads_done should be associated with a read ready response
  else if (M_AXI_RVALID && axi_rready && rd_state == `RD_READ)
    read_done <= 1'b1;
  else
    read_done <= 1'b0;
end

always @(posedge M_AXI_ACLK) begin
  if (M_AXI_ARESETN == 0 || init_rd_pulse == 1'b1)
    rData <= 0;
  else if (M_AXI_RVALID && axi_rready)
    rData <= M_AXI_RDATA;
end

//  Read Process >



endmodule