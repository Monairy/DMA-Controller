module processor(mode,databus,address,write,read,dreq,dack,hreq,hack,cmd,int,clk);

inout [31:0] databus;
output reg [31:0] address;
input wire [2:0] mode;
output reg write;
output reg read=0;
output reg dreq=1'b0,hack=0;
input dack,hreq;
output reg [1:0]cmd;
input int; //interrupt from dma
input clk;
reg [31:0] register [0:7];
reg [31:0] Dout;
reg dd=0;

assign databus=(write || dd)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

initial
begin
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
          dreq<=1'b0;  //dma off 
          address<=32'b00000000000000000000000000000001; //1
          read<=1'b1; write<=1'b0;
          register[6]<=databus; //read buffer of io1 and store in reg6 -> reg6 = 07
         end 
     3'b010: //write in io1 buffer[2] -> buffer[2]=reg[7]=0f
        begin 
          dreq<=1'b0; //dma off
          address<=32'b00000000000000000000000000000010;
          write<=1'b1;  read<=1'b0;            
          Dout<=register[7]; // make io1 buffe[2] = reg7 = 'h0f
         end 	
     3'b011: //read memory address 5 via dma
         begin
        read<=1'b0; //3shan m7dsh yktb 3l bus
        Dout<=32'b00000100000000001000000000000000; //instruction to dma
        dreq<=1;       //dma request 
        if (hreq) //dma 3ayz el bus
          begin  
              hack<=1; //5od el bus
               dd<=1; //5od el instuction
           end
        if (dack) //dma: ana 5adt el bus w habda2 anafez
           begin   
             cmd<=0;
             Dout<=32'bz; read<=1'bz; address<= 32'bz; //processor leave bus
            end  

     /* begin 
          address<=32'b00000000000000000000000000000101;         
          read<=1'b1;
          write<=1'b0;
          register[7]=databus; // -> reg7= 5 
         end */	
     end
     3'b100:
       begin
        read<=1'b0; //3shan m7dsh yktb 3l bus
        Dout<=32'b00001000000000001000000000001000; //instruction to dma
            dreq<=1;address<= 32'bz;       //dma request 
        if (hreq) //dma 3ayz el bus
          begin  
              hack<=1; //5od el bus
               dd<=1; //5od el instuction
           end
        if (dack) //dma: ana 5adt el bus w habda2 anafez
           begin   
             cmd<=2'b10;
             Dout<=32'bz; read<=1'bz; //address<= 32'bz; //processor leave bus
            end 
      // if( dack==0) begin dreq=0; end 
        end	

default:register[0]<=1; // ay 7aga
endcase
if(int==1)  // dma finish -> next posedge
begin
dreq<=0;
hack<=0;
Dout<=32'b0;
cmd<=2'bz;
//register[6]=databus; 
end
end
always @(negedge clk) // dma finish -> store eldata ely gabha el dma in reg[6]
begin
if (int==1) begin register[6]=databus; end 
end
endmodule


module ram(Address,Memread,Memwrite,databus,clk);

input[31:0] Address;
input Memread;
input Memwrite;
input clk;

inout [31:0] databus;
reg [31:0] Dout;
assign databus=(Memread && Address>3) ? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg[31:0]mem[4:200];

initial begin
mem[4]=32'b00000000000000000000000000000100;
mem[5]=32'b00000000000000000000000000000101;
mem[6]=32'b00000000000000000000000000000110;
end

always@(negedge clk)
begin
if(Address>3)
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

assign databus=(read && address==1)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer [0:31];
initial begin
buffer[0]=32'b00000000000000000000000000000111; //'h07
buffer[1]=32'b00000000000000000000000000000111;
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

assign databus=(read && address==2)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

reg [31:0] buffer[0:31];
initial begin
buffer[0]=32'b00000000000000000000000000011111; //'h1F
end

always@(address)
begin
if (address>=32 && address<=63)
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




module dma(address,databus,read,write,hack,dreq,dack,cmd,hreq,reset,int,clk);
output reg [31:0] address=0;
inout [31:0] databus; //instruction
output reg read=0,write=0;
input hack,dreq;
output reg dack=0;
output reg hreq=0;
input [1:0] cmd;
input reset;
input clk;
output reg int=0; //interrupt
reg [31:0] buffer [0:10];
reg [31:0] Dout;


assign databus=(write && dreq)? Dout:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
always @(posedge clk) // lw msh 3ayz el dma y3ml 7aga (dreq=0)
begin if (dreq==0)
begin read<=1'bz; write<=1'bz; end end 

always @(posedge clk)
begin
if (int==1) //lama el process te5las wl interrupt ba2a 1, saffar el dma
begin
buffer[0]<=0; //source
buffer[1]<=0; //destination
buffer[2]<=0; //count
buffer[3]<=0; //counter
buffer[4]<=0; //temp 
hreq<=0;
dack<=0;
address<=32'bz;
int<=0;
end
end 

always @(posedge hack)
begin
 buffer[0]<=databus[25:13]; //source
 buffer[1]<=databus[12:0]; //destination
 buffer[2]<=databus[31:26]; //count
 buffer[3]<=0; //counter
end


always@(negedge clk)
begin
if(dreq==1)
begin hreq<=1; write<=0; end
if(hack==1)
begin dack<=1; end
end

always@(posedge clk , cmd)
begin
case(cmd)
2'b00:
begin   //read
address <= buffer[0];
read <=1;
buffer[3]<=buffer[3]+1;
if (buffer[3]==buffer[2])
begin int<=1; end
end

2'b10: //moving mode read in posedge (not working)
begin
address <= buffer[0];
read <=1;
buffer[4]=databus;
buffer[0]=buffer[0]+1; //next address
buffer[3]=buffer[3]+1; //counter
//if (buffer[3]==buffer[2])
//begin int<=0; end
end
default:address =32'bz;
endcase
end

always@(negedge clk , cmd) //in moving mode, write in negedge (not working
begin
case(cmd)
2'b10:
begin
//read<=0;
//write<=1;
//address<=buffer[1];

//Dout<=buffer[4];

end
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
wire write,read,hack,dreq,dack,hreq,reset,int;
wire [31:0] databus;
wire [31:0]address;
wire [1:0] cmd;
io1 io(address,write,read,databus);
io2 ioo(address,write,read,databus);
assign reset=0;
ram ramm(address,read,write,databus,clock1);

dma dma1(address,databus,read,write,hack,dreq,dack,cmd,hreq,reset,int,clock1);
processor pro(3'b100,databus,address,write,read,dreq,dack,hreq,hack,cmd,int,clock1);


endmodule
