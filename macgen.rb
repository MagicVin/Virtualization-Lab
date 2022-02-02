#!/usr/bin/env ruby

def randomMAC
  mac = [0x00, 0x16, 0x3e,
    Random.rand(0x00..0x7f),
    Random.rand(0x00..0xff),
    Random.rand(0x00..0xff)]
    
    mac.map { |x| '%02x' % x }.join(':')
end

puts randomMAC
	
