

with open("rom.v","w") as theRomFile:

	theRomFile.write("/* rom.v : rom */\n")
	theRomFile.write("\n")
	theRomFile.write("module rom\n")
	theRomFile.write("#(parameter BITS = 16, ADDRESS_BITS = 8)\n")
	theRomFile.write("(\n")
	theRomFile.write("	input CLK,\n")
	theRomFile.write("	input [ADDRESS_BITS - 1 : 0]  ADDRESS,\n")
	theRomFile.write("	output [BITS - 1 : 0] DATA_OUT,\n")
	theRomFile.write(");\n")
	theRomFile.write("\n")
	theRomFile.write("localparam ROM_ADDRESS_BITS = 8;\n")
	theRomFile.write("\n")
	theRomFile.write("reg [BITS - 1:0] mem [(1 << ROM_ADDRESS_BITS) - 1:0];\n")
	theRomFile.write("reg [BITS - 1:0] dout;\n")
	theRomFile.write("assign DATA_OUT = dout;\n")

	with open("rom_image.mem", "r") as theRomIn:
		for i in range(0, 256):
			theStr = theRomIn.readline()
			theRomFile.write("initial mem[%d] = 16'h%s;\n" % (i, str(theStr.strip())))
 
	theRomFile.write("always @(posedge CLK)\n")
	theRomFile.write("begin\n")
	theRomFile.write("       dout <= mem[ADDRESS];\n")
	theRomFile.write("end\n")
	theRomFile.write("endmodule\n")

