
# a60d 0001 04a9 0002

#x = 0x0001a60d
#y = 0x000204a9

# a60d 0001 fb6b 0002

x = 0x0001a60d 
y = 0x0002fb6b

print("%08x" % (x * y))

b = x & 0xffff
a = x >> 16
d = y & 0xffff
c = y >> 16


b3 = (a * c) >> 16
z= (((b * d) >> 16) + (((a*d)&0xffff) + ((b*c)&0xffff))) 


b2 = ((a * c) & 0xffff) + (((a*d)>>16)+((b*c)>>16) ) + (z >> 16)
b1 = z & 0xffff

b0 = (b*d) & 0xffff

print("%04x%04x%04x%04x" % (b3, b2, b1, b0))

