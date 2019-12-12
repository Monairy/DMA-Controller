module processor(mode,databus,address,dec_en,write,read,clk);

inout [31:0] databus;

output reg [31:0] address;
input wire [1:0] mode;
output reg dec_en;
output reg write;
output reg read;
input clk;
reg [31:0] register [0:7];
reg [31:0] Dout;


assign databus=(write)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

initial
begin
register[0]=32'b0;
register[1]=32'b0;
register[7]=32'b00000000000000000000000000001111; //'h0f
end           

always @(posedge clk)
 case(mode)
	00:
          begin register [0]<=register[0]+1;
            register [1]<=register[1]+2; register [2]<=4+3;  register [3]<=4+4;  register [4]<=4+5; end

    2'b01: //read  io2
        begin 
          address<=32'b00000000000000000000000000000010;
          read<=1'b1;
          write<=1'b0;
          dec_en<=1'b1;
          register[6]<=databus; //read buffer of io1 and store in reg6
         end 
     2'b10: //write in io1
        begin 
          address<=32'b00000000000000000000000000000001;
          write<=1'b1;       
          read<=1'b0;  
          dec_en<=1'b1;
          Dout<=register[7]; //write in io1 buffer contents of reg7
         end 	
     2'b11: //read memory address 5
        begin 
          address<=32'b00000000000000000000000000000101;         
          read<=1'b1;
          write<=1'b0;
          dec_en<=1'b0;
          register[7]=databus; 
         end 	

	default:register[0]<=1;
 endcase



endmodule

module decoder(out,in,en);
    input  [1:0]in;
    output reg [3:0]out=4'b0000;
    input en;

always@(in)
begin
if (en)
begin
case (in)
 2'b00: out<=4'b0001;   //DMA
 2'b01: out<=4'b0010;  //i/0 1
 2'b10: out<=4'b0100; //i/0 2
 2'b11: out<=4'b1000; 
default: out<=4'b0000;
endcase
end
end

endmodule

module ram(Address,Memread,Memwrite,databus,en,clk);

input en;
input[31:0]Address;
input Memread;
input Memwrite;
input clk;

inout [31:0] databus;
reg [31:0] Dout;
assign databus=(Memread && en)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg[31:0]mem[0:50];

initial begin
mem[4]=32'b00000000000000000000000000000100;
mem[5]=32'b00000000000000000000000000000101;
end

always@(posedge clk)
begin
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



module io1(cs,write,read,databus);
input cs;
input write;
input read;

inout [31:0] databus;
reg [31:0] Dout;

assign databus=(read && cs)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer;
initial begin
buffer=32'b00000000000000000000000000000111; //'h07
end

always@(posedge cs)
begin
if (write)
begin
buffer<=databus;
end
if (read)
begin
Dout<=buffer;
end
end
endmodule


module io2(cs,write,read,databus);
input cs;
input write;
input read;

inout [31:0] databus;
reg [31:0] Dout;

assign databus=(read && cs)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer;
initial begin
buffer=32'b00000000000000000000000000011111; //'h1F
end

always@(posedge cs)
begin
if (write)
begin
buffer<=databus;
end
if (read)
begin
Dout<=buffer;
end
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
wire write,read,dec_enable;
wire [31:0] databus;
wire [31:0]address;
wire [3:0] cs;
decoder dec(cs,address[1:0],dec_enable);

io1 io(cs[1],write,read,databus);
io2 ioo(cs[2],write,read,databus);

ram ramm(address,read,write,databus,~dec_enable,clock1);

processor pro(2'b01,databus,address,dec_enable,write,read,clock1);


endmodule
