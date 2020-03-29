`timescale 1ns / 1ps

`include "system.vh"
`include "iob-uart.vh"
`include "console.vh"

module system_tb;

   //clock
   reg clk = 1;
   always #5 clk = ~clk;

   //reset 
   reg reset = 1;

   //uart signals
   reg [7:0] 	rxread_reg = 8'b0;
   reg [2:0]    uart_addr;
   reg          uart_valid;
   reg          uart_wr;
   reg [31:0]   uart_di;
   reg [31:0]   uart_do;

   //cpu to receive getchar
   reg [7:0]    cpu_char = 0;
   
   integer      i;

     
   //
   // TEST PROCEDURE
   //
   initial begin

`ifdef VCD
      $dumpfile("system.vcd");
      $dumpvars();
`endif

      //init cpu bus signals
      uart_valid = 0;
      uart_wr = 0;
      
      // deassert rst
      repeat (100) @(posedge clk);
      reset <= 0;

      //sync up with reset 
      repeat (100) @(posedge clk) #1;

      //
      // CONFIGURE UART
      //
      cpu_inituart();
      
      do begin
         cpu_getchar(cpu_char);
         
         if (cpu_char == `STX) begin // Send file
            cpu_sendFile();
         end else if (cpu_char == `SRX) begin // Receive file
            $write("Please, insert a name for a file:");
            $write("out.bin\n");
            cpu_receiveFile();
         end else if (cpu_char == `EOT) begin // Finish
            $write("Bye, bye!\n");
         end else begin
            $write("%c", cpu_char);
         end
      end while (cpu_char != `EOT);

   end // test procedure
 

   //
   // INSTANTIATE COMPONENTS
   //
   
   wire       tester_txd, tester_rxd;       
   wire       tester_rts, tester_cts;       
   wire       trap;
  
`ifdef USE_DDR               
   //Write address
   wire [0:0] ddr_awid;
   wire [31:0] ddr_awaddr;
   wire [7:0]  ddr_awlen;
   wire [2:0]  ddr_awsize;
   wire [1:0]  ddr_awburst;
   wire        ddr_awlock;
   wire [3:0]  ddr_awcache;
   wire [2:0]  ddr_awprot;
   wire [3:0]  ddr_awqos;
   wire        ddr_awvalid;
   wire        ddr_awready;
   //Write data
   wire [31:0] ddr_wdata;
   wire [3:0]  ddr_wstrb;
   wire        ddr_wlast;
   wire        ddr_wvalid;
   wire        ddr_wready;
   //Write response
   wire [7:0]  ddr_bid;
   wire [1:0]  ddr_bresp;
   wire        ddr_bvalid;
   wire        ddr_bready;
   //Read address
   wire [0:0]  ddr_arid;
   wire [31:0] ddr_araddr;
   wire [7:0]  ddr_arlen;
   wire [2:0]  ddr_arsize;
   wire [1:0]  ddr_arburst;
   wire        ddr_arlock;
   wire [3:0]  ddr_arcache;
   wire [2:0]  ddr_arprot;
   wire [3:0]  ddr_arqos;
   wire        ddr_arvalid;
   wire        ddr_arready;
   //Read data
   wire [7:0]  ddr_rid;
   wire [31:0] ddr_rdata;
   wire [1:0]  ddr_rresp;
   wire        ddr_rlast;
   wire        ddr_rvalid;
   wire        ddr_rready;
`endif

   
   //
   // UNIT UNDER TEST
   //
   system uut (
	           .clk           (clk),
	           .reset         (reset),
               
               //.led         (led),
	           .trap          (trap),

`ifdef USE_DDR
               //DDR
               //address write
	           .m_axi_awid    (ddr_awid),
	           .m_axi_awaddr  (ddr_awaddr),
	           .m_axi_awlen   (ddr_awlen),
	           .m_axi_awsize  (ddr_awsize),
	           .m_axi_awburst (ddr_awburst),
	           .m_axi_awlock  (ddr_awlock),
	           .m_axi_awcache (ddr_awcache),
	           .m_axi_awprot  (ddr_awprot),
	           .m_axi_awqos   (ddr_awqos),
	           .m_axi_awvalid (ddr_awvalid),
	           .m_axi_awready (ddr_awready),
               
	           //write  
	           .m_axi_wdata   (ddr_wdata),
	           .m_axi_wstrb   (ddr_wstrb),
	           .m_axi_wlast   (ddr_wlast),
	           .m_axi_wvalid  (ddr_wvalid),
	           .m_axi_wready  (ddr_wready),
               
	           //write response
	           .m_axi_bid     (ddr_bid[0]),
	           .m_axi_bresp   (ddr_bresp),
	           .m_axi_bvalid  (ddr_bvalid),
	           .m_axi_bready  (ddr_bready),
               
	           //address read
	           .m_axi_arid    (ddr_arid),
	           .m_axi_araddr  (ddr_araddr),
	           .m_axi_arlen   (ddr_arlen),
	           .m_axi_arsize  (ddr_arsize),
	           .m_axi_arburst (ddr_arburst),
	           .m_axi_arlock  (ddr_arlock),
	           .m_axi_arcache (ddr_arcache),
	           .m_axi_arprot  (ddr_arprot),
	           .m_axi_arqos   (ddr_arqos),
	           .m_axi_arvalid (ddr_arvalid),
	           .m_axi_arready (ddr_arready),
               
	           //read   
	           .m_axi_rid     (ddr_rid[0]),
	           .m_axi_rdata   (ddr_rdata),
	           .m_axi_rresp   (ddr_rresp),
	           .m_axi_rlast   (ddr_rlast),
	           .m_axi_rvalid  (ddr_rvalid),
	           .m_axi_rready  (ddr_rready),	
`endif
               
               //UART
	           .uart_txd      (tester_rxd),
	           .uart_rxd      (tester_txd),
	           .uart_rts      (tester_cts),
	           .uart_cts      (tester_rts)
	           );


   //TESTER UART
   iob_uart test_uart (
		               .clk       (clk),
		               .rst       (reset),
                       
		               .valid     (uart_valid),
		               .address   (uart_addr),
		               .write     (uart_wr),
		               .data_in   (uart_di),
		               .data_out  (uart_do),
                       
		               .txd       (tester_txd),
		               .rxd       (tester_rxd),
		               .rts       (tester_rts),
		               .cts       (tester_cts)
		               );

`ifdef USE_DDR
   axi_ram 
 #(
              .DATA_WIDTH (`DATA_W),
              .ADDR_WIDTH (`MAINRAM_ADDR_W),
              .ID_WIDTH (1)
              )
   ddr_model_mem(
                 //address write
                 .clk            (clk),
                 .rst            (reset),
		 .s_axi_awid     ({8{ddr_awid}}),
		 .s_axi_awaddr   (ddr_awaddr[15:0]),
                 .s_axi_awlen    (ddr_awlen),
                 .s_axi_awsize   (ddr_awsize),
                 .s_axi_awburst  (ddr_awburst),
                 .s_axi_awlock   (ddr_awlock),
		 .s_axi_awprot   (ddr_awprot),
		 .s_axi_awcache  (ddr_awcache),
     		 .s_axi_awvalid  (ddr_awvalid),
		 .s_axi_awready  (ddr_awready),
                   
		 //write  
		 .s_axi_wvalid   (ddr_wvalid),
		 .s_axi_wready   (ddr_wready),
		 .s_axi_wdata    (ddr_wdata),
		 .s_axi_wstrb    (ddr_wstrb),
                 .s_axi_wlast    (ddr_wlast),
                 
		 //write response
		 .s_axi_bready   (ddr_bready),
                 .s_axi_bid      (ddr_bid),
                 .s_axi_bresp    (ddr_bresp),
		 .s_axi_bvalid   (ddr_bvalid),
                 
		 //address read
		 .s_axi_arid     ({8{ddr_arid}}),
		 .s_axi_araddr   (ddr_araddr[15:0]),
		 .s_axi_arlen    (ddr_arlen), 
		 .s_axi_arsize   (ddr_arsize),    
                 .s_axi_arburst  (ddr_arburst),
                 .s_axi_arlock   (ddr_arlock),
                 .s_axi_arcache  (ddr_arcache),
                 .s_axi_arprot   (ddr_arprot),
		 .s_axi_arvalid  (ddr_arvalid),
		 .s_axi_arready  (ddr_arready),
                 
		 //read   
		 .s_axi_rready   (ddr_rready),
		 .s_axi_rid      (ddr_rid),
		 .s_axi_rdata    (ddr_rdata),
		 .s_axi_rresp    (ddr_rresp),
                 .s_axi_rlast    (ddr_rlast),
		 .s_axi_rvalid   (ddr_rvalid)
                 );   
`endif   
   //
   // CPU TASKS
   //
   
   // 1-cycle write
   task cpu_uartwrite;
      input [3:0]  cpu_address;
      input [31:0] cpu_data;

      # 1 uart_addr = cpu_address;
      uart_valid = 1;
      uart_wr = 1;
      uart_di = cpu_data;
      @ (posedge clk) #1 uart_wr = 0;
      uart_valid = 0;
   endtask //cpu_uartwrite

   // 2-cycle read
   task cpu_uartread;
      input [3:0]   cpu_address;
      output [31:0] read_reg;

      # 1 uart_addr = cpu_address;
      uart_valid = 1;
      @ (posedge clk) #1 read_reg = uart_do;
      @ (posedge clk) #1 uart_valid = 0;
   endtask //cpu_uartread

   task cpu_sendFile;
      reg [`DATA_W-1:0] file_size;
      reg [7:0]         buffer [0:9*4096];
      integer           fp;
      integer           i, k;

      fp = $fopen("firmware.bin","rb");
      file_size = $fread(buffer, fp);
      $fclose(fp);
      
      $write("Starting File 'firmware.bin' Transfer...\n");
      $write("file_size = %d\n", file_size);

      // Wait for RISC-V
      do begin
         cpu_getchar(cpu_char);
      end while (cpu_char != `STR);
      
      // Send file size
      cpu_putchar(file_size[7:0]);
      cpu_putchar(file_size[15:8]);
      cpu_putchar(file_size[23:16]);
      cpu_putchar(file_size[31:24]);
      
      k = 0;
      for(i = 0; i < file_size; i++) begin
         cpu_putchar(buffer[i]);

         if(i/4 == (file_size/4*k/100)) begin
            $write("%d%%\n", k);
            k=k+10;
         end
      end
      $write("%d%%\n", 100);
      $write("UART transfer complete.\n");
   endtask

   task cpu_receiveFile;
      reg [`DATA_W-1:0] file_size;
      reg [31:0]        word;
      integer           fp;
      integer           idx;
      integer           i, k;

      fp = $fopen("out.bin", "wb");
      
      $write("Starting File 'out.bin' Transfer...\n");

      // Send Start to RISC-V
      cpu_putchar(`STR);
      
      // Send file size
      cpu_getchar(file_size[7:0]);
      cpu_getchar(file_size[15:8]);
      cpu_getchar(file_size[23:16]);
      cpu_getchar(file_size[31:24]);
      $write("file_size = %d\n", file_size);
      
      k = 0;
      idx = 0;
      for(i = 0; i < file_size; i++) begin
	     cpu_getchar(cpu_char);
         word[8*(idx++) +: 8] = cpu_char;

         if (idx == 4) begin
            idx = 0;
            $fwrite(fp, "%u", word);
         end

         if(i/4 == (file_size/4*k/100)) begin
            $write("%d%%\n", k);
            k=k+10;
         end
      end
      $write("%d%%\n", 100);
      $write("UART transfer complete.\n");

      //$fwrite(fp, buffer);
      $fclose(fp);
   endtask
   

   task cpu_inituart;
      //pulse reset uart 
      cpu_uartwrite(`UART_SOFT_RESET, 1);
      cpu_uartwrite(`UART_SOFT_RESET, 0);
      //config uart div factor
      cpu_uartwrite(`UART_DIV, `UART_CLK_FREQ/`UART_BAUD_RATE);
      //enable uart for receiving
      cpu_uartwrite(`UART_RXEN, 1);
   endtask

   task cpu_getchar;
      output [7:0] rcv_char;

      //wait until something is received
      do
	    cpu_uartread(`UART_READ_VALID, rxread_reg);
      while(!rxread_reg);

      //read the data 
      cpu_uartread(`UART_DATA, rxread_reg); 

      rcv_char = rxread_reg[7:0];
   endtask


   task cpu_putchar;
      input [7:0] send_char;
      //wait until tx ready
      do
	    cpu_uartread(`UART_WRITE_WAIT, rxread_reg);
      while(rxread_reg);
      //write the data 
      cpu_uartwrite(`UART_DATA, send_char); 

   endtask

   task cpu_getline;
      do begin 
         cpu_getchar(cpu_char);
         $write("%c", cpu_char);
      end while (cpu_char != "\n");
   endtask

   
   // finish simulation
   always @(posedge trap)   	 
     #500 $finish;
      
endmodule
