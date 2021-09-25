from PIL import Image

im = Image.open("Pac-Man_Comparable_Sprite_Sheet_256.png")

#pixel = im.getpixel((20,20))

colors = []

for i in range(0,3):	# sprite frame
	for x in range(0, 16):	# sprite x
		for y in range(0, 16):	# sprite y
			color = im.getpixel((x + i*16, y))
			colors.append("0%01x%01x%01x" % (color[0] >> 4, color[1] >> 4, color[2]>>4))



with open("pacman_sprite_rom.v","w") as theRomFile:

	theRomFile.write("/* rom.v : rom */\n")
	theRomFile.write("\n")
	theRomFile.write("module rom\n")
	theRomFile.write("#(parameter BITS = 16, ADDRESS_BITS = 9)\n")
	theRomFile.write("(\n")
	theRomFile.write("	input CLK,\n")
	theRomFile.write("	input [ADDRESS_BITS - 1 : 0]  ADDRESS,\n")
	theRomFile.write("	output [BITS - 1 : 0] DATA_OUT,\n")
	theRomFile.write(");\n")
	theRomFile.write("\n")
	theRomFile.write("localparam ROM_ADDRESS_BITS = 12;\n")
	theRomFile.write("\n")
	theRomFile.write("reg [BITS - 1:0] mem [(1 << ROM_ADDRESS_BITS) - 1:0];\n")
	theRomFile.write("reg [BITS - 1:0] dout;\n")
	theRomFile.write("assign DATA_OUT = dout;\n")

	for i in range(0, 768):
		theRomFile.write("initial mem[%d] = 16'h%s;\n" % (i, colors[i]))

	theRomFile.write("always @(posedge CLK)\n")
	theRomFile.write("begin\n")
	theRomFile.write("       dout <= mem[ADDRESS];\n")
	theRomFile.write("end\n")
	theRomFile.write("endmodule\n")


  
