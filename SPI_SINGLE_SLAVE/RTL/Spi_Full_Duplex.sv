module spi_full_duplex(
  input wire sys_clock,
  input wire reset_n,
  input wire [1:0]spi_mode,
  input wire tx_enable,
  input wire [17:0]data_in,
  input wire [1:0]clock_speed,
  output reg [17:0] master_out,	
  output reg mrx_data_valid 
  
);
  
  wire miso;
  wire mosi;
  wire ss_n;
  wire sclk;
  wire [17:0]slave_out_to_ram;
  wire rx_valid_slave_to_ram;
  wire [17:0]data_from_ram_to_slave;
  wire tx_valid_ram_to_slave;

 spi_master master(
   .sys_clock(sys_clock),
   .reset_n(reset_n),
   .tx_enable(tx_enable),
   .data_in(data_in),
   .clock_speed(clock_speed),
   .spi_mode(spi_mode),
   .miso(miso),//serial
   .ss_n(ss_n),
   .mosi(mosi),//serial
   .sclk(sclk), //serial clock
   .master_out(master_out),
   .mrx_data_valid(mrx_data_valid)
);
  
 spi_slave slave(
  .sys_clock(sys_clock),
  .reset_n(reset_n),
  .spi_mode(spi_mode),
  .mosi(mosi),//serial
  .ram_data_in(data_from_ram_to_slave),//from ram
  .ss_n(ss_n), 
  .sclk(sclk), //serial clock
  .tx_valid(tx_valid_ram_to_slave),
  .miso(miso),//serial
  .slave_out(slave_out_to_ram),
  .rx_valid(rx_valid_slave_to_ram)
);
  
  
  ram_1kB ram(
    .sys_clock(sys_clock),
    .reset_n(reset_n),
    .rx_valid(rx_valid_slave_to_ram),
    .data_in(slave_out_to_ram),
    .data_out(data_from_ram_to_slave),
    .tx_valid(tx_valid_ram_to_slave)
  );
  
  
 
  
  
  
endmodule
  