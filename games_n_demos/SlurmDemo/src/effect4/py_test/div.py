#!/usr/bin/python

#
#	binary division
#	
#

N = int(2.8 * 65536) & 0xffffff
Da = int(2.3 * 256) & 0xffff

# Long division




# Restoring

#R := N
#D := D << n            -- R and D need twice the word width of N and Q
#for i := n − 1 .. 0 do  -- For example 31..0 for 32 bits
#  R := 2 * R − D          -- Trial subtraction from shifted value (multiplication by 2 is a shift in binary representation)
#  if R >= 0 then
#    q(i) := 1          -- Result-bit 1
#  else
#    q(i) := 0          -- Result-bit 0
#    R := R + D         -- New partial remainder is (restored) shifted value
#  end
#end

R = N
D = Da << 32
q = 0

for i in range(0, 32): 
	q <<= 1
	R = 2*R - D
	if R >= 0:
		q |= 1
	else:
		R = R + D

print("Restoring: %x %f" % (q, q / 256.0))


# Non-restoring
# Wikipedia:
#R := N
#D := D << n            -- R and D need twice the word width of N and Q
#for i = n − 1 .. 0 do  -- for example 31..0 for 32 bits
#  if R >= 0 then
#    q(i) := +1
#    R := 2 * R − D
#  else
#    q(i) := −1
#    R := 2 * R + D
#  end if
#end

R = N
D = Da << 32
q = 0

for i in range(0, 32):
	q <<= 1
	if R >= 0:
		q |= 1	
		R = 2*R - D
	else:
		R = 2*R + D

qfin = q - ~q

if R < 0:
	qfin -= 1

qfin &= 0xffffffff

print("Non-restoring: %x %f" % (qfin, qfin / 256.0))
