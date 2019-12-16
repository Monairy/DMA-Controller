module processor(mode,databus,address,write,read,dreq,cmd,ddone,clk);

inout [31:0] databus;
output reg [31:0] address;
input wire [2:0] mode;
output reg write;
output reg read;
output reg dreq;
output reg [1:0] cmd;
input ddone;
input clk;
reg dd;

reg [31:0] register [0:7];
reg [31:0] Dout;

assign databus=(write|| dd==1)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

initial
begin dreq<=0;
register[0]=32'b0;
register[1]=32'b0;
register[7]=32'b00000000000000000000000000001111; //'h0f
end           


always @(posedge clk)
begin 
 case(mode)
	00:   
         begin 
            register [0]<=register[0]+1;
            register [1]<=register[1]+2; register [2]<=4+3;  register [3]<=4+4;  register [4]<=4+5; end

    3'b001: //read io1 buffer-> reg[6] = 07
        begin 
  
          address<=32'b00000000000000000000000000000001; //1
          read<=1'b1; write<=1'b0;
          register[6]<=databus; //read buffer of io1 and store in reg6 -> reg6 = 07
         end 
     3'b010: //write in io1 buffer[2] -> buffer[2]=reg[7]=0f
        begin 
      
          address<=32'b00000000000000000000000000000010;
          write<=1'b1;  read<=1'b0;            
          Dout<=register[7]; // make io1 buffe[2] = reg7 = 'h0f
         end 	
     3'b011: //move 1 word from io1 buffer[2] to memory loc 70
         begin
          if (dreq==0)begin
             address<=32'bz;
             read<=1'b0; write<=1'b1; 
             dreq<=1'b1;              
             Dout<=32'b00000100000000000100000001000110;
             cmd<=2'b00; #10  Dout<=32'bz; dd<=1; read<=1'bz; write<=1'bz;  end     
        if (ddone)begin cmd<=2'bz; Dout<=32'bz; dreq<=0; dd<=0;end
         end
     3'b100:
       begin

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

always@(negedge clk)
begin
if(Address>63)
if(Memread)
begin
Dout <= mem[Address];
end
if (Memwrite)
begin
mem[Address] <= databus;
end

end
endmodule



module io1(address,write,read,databus); //address=1

input [31:0] address;
input write;
input read;
inout [31:0] databus;
reg [31:0] Dout;

assign databus=(read==1 && address<=31)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer [0:31];
initial begin
buffer[0]=32'b00000000000000000000000000000111; //'h07
buffer[1]=32'b00000000000000000000000000000111;
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


module io2(address,write,read,databus); //address=2
input [31:0] address;
input write;
input read;

inout [31:0] databus;
reg [31:0] Dout;

assign databus=(read && address>=32 && address<=63)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer[0:31];
initial begin
buffer[0]=32'b00000000000000000000000000010011; //'h1F
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
assign databus=(write)?Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

initial begin read<=1'bz; write<=1'b0;end

always@(posedge dreq)
begin
 buffer[0]=databus[25:13]; //source
 buffer[1]<=databus[12:0]; //destination
 buffer[2]<=databus[31:26]; //count

case (cmd)
2'b00:
begin
#20 address<=buffer[0]; read<=1'b1; write<=1'b0; #1 buffer[3]<=databus;
#10 write<=1'b1; Dout<=buffer[3]; address<=buffer[1];  read<=1'b0;
#20 ddone<=1; Dout<=32'bz; address<=32'bz; #10 ddone<=0;
 end
 default: ddone<=0;
endcase
end


endmodule

module tbb();
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


processor pro(3'b011,databus,address,write,read,dreq,cmd,ddone,clock1);

endmodule
