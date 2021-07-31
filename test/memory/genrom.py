
filer = open("rom_image.mem", "w")
for i in range(0,32768):
	filer.write("%04x\n" % i)
filer.close()
