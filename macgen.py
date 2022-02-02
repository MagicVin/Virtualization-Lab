#!/usr/bin/env python3
import random

def randomMAC():
	mac = [ 0x00, 0x16, 0x3e,
		random.randint(0x00, 0x7f),
		random.randint(0x00,0xff),
		random.randint(0x00,0xff)]
	return ':'.join(map(lambda x: '%02x' % x, mac))
	#return ':'.join(map(lambda x: format(x, '02x'), mac))	

print(randomMAC())	
