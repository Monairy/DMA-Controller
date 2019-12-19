module processor(instruction,databus,address,write,read,dreq,cmd,ddone,clk);

inout [31:0] databus;
output reg [31:0] address;
input [44:0]instruction;  //45 bit instruction from testbench
output reg write;
output reg read;
output reg dreq;
output reg [1:0] cmd;    // dma modes 1:copy 1 word, 2:copy more than one word
input ddone; //interrupt from DMA
input clk;
reg dd;

reg [31:0] register [0:9];
reg [31:0] Dout;

wire [2:0]  mode;          // mode of operation 0:read,1:write,2:copy 1 word,3:copy 1 word dma,4:copy more than 1 word dma
wire [31:0] instructionData;
wire [9:0]  instructionAddress;
///////////////////////////////////////////////
assign mode = instruction[44:42];
assign instructionData = instruction[41:10];
assign instructionAddress = instruction[9:0];
///////////////////////////////////////////////                   

assign databus=(write|| dd==1)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

initial
begin 
dreq<=0;cmd<=0;
read<=0;write<=0; register[0]<=0; 
end           


always @(posedge clk)
begin 
 case(mode)
	0:   //read directly from memory or from I/O device
         begin 
         read<=1'b1; dreq<=0; dd<=0;
	 write<=0;
	 address <= instructionAddress;
	 #1 register[6]<= databus;
	 end

	1: //write directly in memory or in I/O device
        begin 
          read <=0; write <=1;
          dreq <=0; dd <=0;
	  address <= instructionAddress;
	  Dout <= instructionData; 
         end 
	2:  //move 1 word by dma from io1 to mem70	
         begin
          if (dreq==0)   //there is no running dma command
		begin 
             dreq<=1'b1;    //dma req 
             read<=1'b0; write<=1'b1; //processor write on databus 
             address<=32'bz; //floating 
             Dout<=instructionData; //instruction to dma 
             cmd<=2'b01; //command to dma : MOVE 1 word
	    #10  Dout<=32'bz; dd<=1; read<=1'bz; write<=1'bz;  //after half cycle leave bus
                 end
        if (ddone) begin 
	cmd = 0; 
        Dout = 32'bz;
	dreq = 0;  end
        end
////////////////////////////////////////////////////
	3:  //move 3 words by dma from memory to memory
         begin register[0]=register[0]+1;
          if (dreq==0)   //there is no running dma command
		begin 
             dreq<=1'b1;    //dma req 
             read<=1'b0; write<=1'b1; //processor write on databus 
             address<=32'bz; //floating 
             Dout<=instructionData; //instruction to dma 
             cmd<=2'b01; //command to dma : MOVE 
	    #10  Dout<=32'bz; dd<=1; read<=1'bz; write<=1'bz;  //after half cycle leave bus
            
                 end
        if (ddone) begin 
	cmd = 0; 
        Dout = 32'bz;
	dreq = 0;  end
        end


default:register[0]<=1; // ay 7aga
endcase
end
endmodule

module ram(Address,Memread,Memwrite,databus,clk);

input[31:0] Address;
input Memread;
input Memwrite;
input clk;

inout [31:0] databus;
reg [31:0] Dout;
assign databus=(Memread && Address>63) ? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg[31:0]mem[64:500];

initial begin
mem[64]=32'b00000000000000000000000000000100;
mem[65]=32'b00000000000000000000000000000101;
mem[66]=32'b00000000000000000000000000000110;
end

always@(posedge clk)
#1
begin
if(Address>63)
if(Memread)
begin
Dout <= mem[Address];
end 
end

always @(negedge clk) 
begin
if(Address>63)
if (Memwrite)
begin
mem[Address] <= databus;
end
end

endmodule



module io1(address,write,read,databus); //address=0:31

input [31:0] address;
input write;
input read;
inout [31:0] databus;
reg [31:0] Dout;

assign databus=(read==1 && address<=31)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer [0:31];
initial begin
buffer[0]=32'b00000000000000000000000000000111; //'h07
buffer[1]=32'b00000000000000000000000000001111; //h'0f
buffer[2]=32'b00000000000000000000000000011111; //1f
end

always@(address)
begin
if (address>=0 && address<=31)
begin
if (write)
begin
buffer[address]<=databus;
end
if (read)
begin
Dout<=buffer[address];
end
end
end

endmodule


module io2(address,write,read,databus); //address=32:63
input [31:0] address;
input write;
input read;

inout [31:0] databus;
reg [31:0] Dout;

assign databus=(read && address>=32 && address<=63)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer[0:31];
initial begin
buffer[0]=32'b00000000000000000000000010101011; //'ab
end

always@(address)
begin
if (address>=32 && address<=63)
begin
if (write)
begin
buffer[address-32]<=databus;
end
if (read)
begin
Dout<=buffer[address-32];
end
end
end
endmodule




module dma(address,databus,read,write,dreq,cmd,ddone,clk);
output reg [31:0] address;
inout [31:0] databus;
output reg read,write;
input dreq;
input [1:0] cmd;
output reg ddone=0;
input clk;
reg [31:0] buffer [0:10];
reg [31:0] Dout;
reg writee;
assign databus=(writee==1 && dreq==1 )?Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

initial begin read<=1'bz; write<=1'bz; address<=32'bz; writee<=0; end

always@(posedge dreq) //DMA req = 1 
begin //set internal registers
 buffer[0]=databus[25:13]; //source location 
 buffer[1]<=databus[12:0]; //destination location 
 buffer[2]<=databus[31:26]; //number of words to transfer
 buffer[3]<=32'b0; //counter 
case (cmd) //dma mode 00:move, 01:read, 10:write 
2'b00:
begin
#20 address<=buffer[0]; read<=1'b1; write<=1'b0; #1 buffer[3]<=databus; //read from io/ram
#10 write<=1'b1; writee<=1'b1; Dout<=buffer[3]; address<=buffer[1];  read<=1'b0; //write to io/ram
#20 ddone<=1; Dout<=32'bz; address<=32'bz; #10 ddone<=0; //interrupt processor & leave bus  
 end

 default: ddone<=0;
endcase
end
integer i=0;

always @(posedge clk)
begin
if (i==0) begin #20; end
if (dreq) begin
case (cmd) //dma mode 00:move, 01:read, 10:write 
2'b01:
begin
address<=buffer[0]+i;
read<=1'b1; write<=1'b0;
#2
buffer[4]<=databus;
#7 //write to io/ram
read<=1'b0; 
write<=1'b1; writee<=1'b1; 
Dout<=buffer[4]; 
address<=buffer[1]+i;   //write to io/ram
#3 Dout<=32'bz; //address<=32'bz;
i=i+1;

if (i==buffer[2]) begin #2 ddone<=1; Dout<=32'bz; address<=32'bz; #10 ddone<=0;  i<=0; end
 
end
default: ddone<=0;
endcase
end 
end



endmodule

module test();
reg clock1;
initial
begin
assign clock1=0;
end
always
begin
#5;
assign clock1=~clock1;
#5;
end
wire write,read,dreq,ddone;
wire [31:0] databus;
wire [31:0]address;
wire [1:0] cmd;
io1 io(address,write,read,databus);
io2 ioo(address,write,read,databus);
//assign reset=0;
ram ramm(address,read,write,databus,clock1);
dma dmaa(address,databus,read,write,dreq,cmd,ddone,clock1);

reg [44:0] instruction;


initial begin  
assign instruction =45'b000000000000000000000000000000000000000100000; //read io2 buffer[0] -> reg[6]=h'ab
#20 assign instruction= 45'b001000000000000000000000000110111010000000010; //write in io1 buffer[2] -> buffer[2]=h'dd
#20 assign instruction =45'b010000001000000000000100000010001100000000000; //move 1 word from io1 buffer[1] to memory loc 70 -> mem[70]=h'0f
#60 assign instruction = 45'b011000011000000100000000000010100000000000000; // move from mem[64-66] to mem[70-72]


end 

processor pro(instruction,databus,address,write,read,dreq,cmd,ddone,clock1);

endmodule
