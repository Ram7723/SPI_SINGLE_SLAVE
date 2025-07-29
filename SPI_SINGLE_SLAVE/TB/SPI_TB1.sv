// SINGLE SLAVE TEST CASE 1 :
		// MODE = 00 | CLOCK SPEED = 0 
		// {WRITE ADDRESS -> WRITE DATA } X20 CYCLES
		// CHECKING WHETHER THE DATA IS WRITTEN AT CORRECT ADDRESS THROUGH VERIFYING DATA @SPECIFIC LOCATIONS OF RAM


class write_address;			//odd addresses INSIDE 500
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
//---------------------TOP TB------------------------------------------
module spi_full_duplex_tb();
 
  logic sys_clock;
  logic reset_n;
  logic [1:0]spi_mode;
 
  logic tx_enable;
  logic [17:0]data_in;
  logic [1:0]clock_speed;
 

  integer j=0,k=0,a=0;
  integer counter=0;
  
  reg [15:0]checker_array[20];        	//stores the address in which data is writen
  reg [15:0]data_checker_array[20];		//stores the data that is written
 
  logic [17:0] master_out; //output of master
    
  logic mrx_data_valid;
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
 //-----------clk gen---------------
  always #10 sys_clock = ~sys_clock;
  
  
  //--------INITIALIZATION--------
  initial begin
    sys_clock = 0;
    tx_enable = 0;
    data_in = 18'b0;
    clock_speed = 2'b00;
    spi_mode = 2'b00; 
    reset_n = 0;
    #2;
    reset_n = 1;
  end
  //-----------------------------
  
  
    //WRITING 20 DATA AT 20 ADDRESS  20+20 = 40 CYCLES
  initial begin
    repeat(40)begin
      @(posedge mrx_data_valid) begin

        if (counter==0)begin
          obj1.randomize();
          data_in={2'b00,obj1.waddr};
          checker_array[j]=obj1.waddr;
          j++;
          #5;

          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
          counter++;
        end

        else if (counter==1)begin
          obj2.randomize();
          data_in={2'b01,obj2.wdata};
          data_checker_array[k]=obj2.wdata;
          k++;
          #5;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
          counter=0;
        end
      end
    end
    
    counter=0;
    
    
    //-----READING 20 DATA FROM 20 ADDRESSES WHERE THE DATA IS WRITTEN--------
    repeat(40)begin
      @(posedge mrx_data_valid) begin
        if (counter==0)begin
          data_in={2'b10,checker_array[a]};
          a++;
          #5;
          tx_enable =1; //master (fromcontroller)
          #15;
          tx_enable=0;
          counter++;
        end

        else if (counter==1)begin
          data_in={2'b11,16'b0};
          #5;
          tx_enable =1; //master (fromcontroller)
          #15;
          tx_enable=0;
          counter=0;
        end
      end
    end
  end

  
  

 // DUMP ,DISPLAY OF RAM , CHECKER CASE 
  initial begin
    
    $dumpfile("madan.vcd");
    $dumpvars;
     #100000 ;
    
    // display of RAM 
    for (int i=0;i<512;i++)begin
      $display(" DATA IN RAM @ [idx->%0d] = %0d",i,dut.ram.mem[i]);
    end
    $display("\n");
    // CHECKING WHETHER THE DATA IS WRITTEN AT THE CORRECT ADDRESS PERFECTLY WITH THE HELP OF THE  INPUT ADDRESSES AND DATAS THAT IS STORED IN THE RESPECTIVE CHECKER ARRAYS
    $display("--------------------------WRITE DATA TEST-----------------------------");
    $display(" SPI MODE -> %0d | CLOCK SPEED -> %0d " , spi_mode,clock_speed);
    for (int i=0;i<$size(checker_array);i++)begin
      if (dut.ram.mem[checker_array[i]]==data_checker_array[i])begin
        $display( " RAM [ IDX ADDR - %0d ] = %0d , EXPECTED DATA @ SAME ADDRESS =%0d TEST PASS !",checker_array[i],dut.ram.mem[checker_array[i]],data_checker_array[i]);
      end
      else begin
        $error(" RAM [ IDX ADDR - %0d ] = %0d , EXPECTED DATA @ SAME ADDRESS =%0d TEST FAIL !",checker_array[i],dut.ram.mem[checker_array[i]],data_checker_array[i]);
      end
    end
        
      $finish;  
    
  end
  
  
endmodule