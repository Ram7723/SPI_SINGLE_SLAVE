// SINGLE SLAVE TEST CASE 5 :
		// MODE = 3 | CLOCK SPEED = 3 
		// SUDDEN RESET TRIGGERED DURING READ OPERATION 
		// CHECKING RAM AND MASTER OUT 

class write_address;			//odd addresses
  rand bit [15:0] waddr;
  constraint c1{
    waddr inside {[0:500]};
    waddr %2==1;}
endclass

class write_data;			//even data, under 500
  rand bit [15:0] wdata;
  constraint c1{
    wdata inside {[0:500]};
    wdata %2==0;}
endclass


module reset_tb();
  logic sys_clock;
  logic reset_n;
  logic [1:0]spi_mode;
 
  logic tx_enable;
  logic [17:0]data_in;
  logic [1:0]clock_speed;
 

  integer j=0,k=0,a=0;
  integer counter=0;
  
  reg [16]checker_array[20];        	//stores the address in which data is writen
  reg [16]data_checker_array[20]; //stores the data that is written
  reg [16]read_data_arr[20]; //stores the read data that is read
 
  logic [17:0] master_out; //output of master
    
  logic mrx_data_valid;
  
  logic ram_check_flag=1;
  //-----------creating objects-----------
  write_address obj1 = new();
  write_data obj2=new();
  //----------port mapping----------------
  spi_full_duplex dut(
    .sys_clock(sys_clock),
    .reset_n(reset_n),
    .spi_mode(spi_mode),
    .tx_enable(tx_enable),
    .data_in(data_in),
    .clock_speed(clock_speed),   
    .master_out(master_out),
    .mrx_data_valid(mrx_data_valid)
  );
  
   always #10 sys_clock = ~sys_clock;
  
  function  bit signal_checker(logic [17:0]a ,logic [17:0]b);
    return (a==b);
  endfunction
  
  
  //--------INITIALIZATION--------
  initial begin
    sys_clock = 0;
    tx_enable = 0;
    data_in = 18'b0;
    clock_speed = 2'b11; 			// CLOCK SPEED = 3
    spi_mode = 2'b10; 				// SPI MODE = 2
    reset_n = 0;
    #2;
    reset_n = 1;
    //------sudden reset inbetween transaction--------
     #500000; //500000 because of the clock speed 3
//	   #185000; //185000 because of the clock speed 2
//     #100000; //100000 because of the clock speed 1
//	   #45000;	//45000 because of the clock speed 0
    reset_n=0;
    
    
    $display(">>>>>>>>>>>>SUDDEN RESET TRIGGERED @ TIME[%0t]<<<<<<<<<<<<<<<",$time);
    #1;

    // RAM RESET CHECK
     for (int i=0;i<512;i++)begin
       if (dut.ram.mem[i]!=0)begin
         $error("RESET FOR RAM FAILED @ RAM[%0d]-> ACTUAL DATA=%0d | EXPECTED DATA = 0",i,dut.ram.mem[i]);
         ram_check_flag*=0;
       end
    end
      
    if(ram_check_flag) $display("-------------RAM RESET TEST PASSED-----------");
    else $display("-------------RAM RESET TEST FAILED-----------");
    
   

    //SLAVE OUT RESET CHECK WHEN WRITE DONE
    if(signal_checker(master_out,18'h3ffff)) $display(" -------------MASTER OUT RESET PASSED [expected = 3ffff | actual  = %0h] -------------",master_out);
    else $error(" MASTER OUT RESET FAILED  MASTER_OUT=%0h EXPECTED =3ffff",master_out);
    

   end
  
  initial begin
    $display(" WRITING IN RAM @ TIME[%0T]" , $time);
    repeat (40) begin
      @(posedge mrx_data_valid) begin
        if (counter == 0) begin
          obj1.randomize();
          data_in = {2'b00, obj1.waddr};
          checker_array[j] = obj1.waddr;
          j++;
          #5;
          tx_enable = 1; // master (from controller)
          #15;
          tx_enable = 0;
          counter++;
        end

        else if (counter == 1) begin
          obj2.randomize();
          data_in = {2'b01, obj2.wdata};
          data_checker_array[k] = obj2.wdata;
          k++;
          #5;
          tx_enable = 1; // master (from controller)
          #15;
          tx_enable = 0;
          counter = 0;
        end
      end
    end

    counter = 0;
    
    
    $display(" READING IN RAM @ TIME[%0T]" , $time);

    //-----READING 20 DATA FROM 20 ADDRESSES WHERE THE DATA IS WRITTEN (20+20=40 CYCLES)--------
    repeat (42) begin // extra 2 cycles for last data transaction being in process to complete
      @(posedge mrx_data_valid) begin
        if (counter == 0) begin
          if (a >= 20)
            data_in = {2'b10, 16'b0};
          else
            data_in = {2'b10, checker_array[a]};
          a++;
          #5;
          tx_enable = 1; // master (from controller)
          #15;
          tx_enable = 0;
          counter++;
        end

        else if (counter == 1) begin
          if (a > 20)
            data_in = {2'b10, 16'b0};
          else
            data_in = {2'b11, 16'b0};
          #5;
          tx_enable = 1; // master (from controller)
          #15;
          tx_enable = 0;
          counter = 0;

          if (a > 1) begin
            read_data_arr[a - 2] = master_out;
          end
          // The data corresponding to previous read command will be received 
          // in the calling of the next read command (36 clk cycles)
        end
      end
    end
  end


  

  
  initial begin
    $display(" RESET TEST | SPI MODE -> %0d | CLOCK SPEED -> %0d " , spi_mode,clock_speed);
    $dumpfile("madan.vcd");
    $dumpvars;
     #700000 ;
    $finish;  
  end
  
  
endmodule
  