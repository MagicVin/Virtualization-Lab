# Different implementations for virtual MAC address generator

**Bash** - [macgen.sh](https://github.com/MagicVin/Virtualization-Lab/macgen.sh)
```
#!/bin/bash
echo 0x00 0x16 0x3e $(($RANDOM%128)) $(($RANDOM%256)) $(($RANDOM%256)) | awk '{ i=1 ; while (i < NF) {printf("%02x:",$i); i++}} { printf "%02x\n", $NF }'
```
Output:
```
./macgen.sh
00:16:3e:0e:d2:5a
```

**AWK** - [macgen.awk](https://github.com/MagicVin/Virtualization-Lab/macgen.awk)
```
#!/usr//bin/awk -f

function randint(n) { return 1 + int(rand() * n)}
BEGIN { 
  a="00"; b="16"; c="3e"
  srand()
  d=randint(127)
  srand(d)
  e=randint(255)
  srand()
  f=randint(255)

  printf("%s:%s:%s:%02x:%02x:%02x\n", a,b,c,d,e,f)
}
```
Output
```
./macgen.awk
00:16:3e:17:b3:2d
```

**Python3** - [macgen.py](https://github.com/MagicVin/Virtualization-Lab/macgen.py)
```
#!/usr/bin/env python3
import random

def randomMAC():
	mac = [ 0x00, 0x16, 0x3e,
		random.randint(0x00, 0x7f),
		random.randint(0x00,0xff),
		random.randint(0x00,0xff)]
	return ':'.join(map(lambda x: '%02x' % x, mac))

print(randomMAC())	
```
Output
```
./macgen.py 
00:16:3e:21:51:1b
```

**Ruby** - [macgen.rb](https://github.com/MagicVin/Virtualization-Lab/macgen.rb)
```
#!/usr/bin/env ruby

def randomMAC
  mac = [0x00, 0x16, 0x3e,
    Random.rand(0x00..0x7f),
    Random.rand(0x00..0xff),
    Random.rand(0x00..0xff)]
    
    mac.map { |x| '%02x' % x }.join(':')
end

puts randomMAC
```
Output
```
./macgen.rb
00:16:3e:19:80:c4
```

> Format string - '%02x'  
>  %  -- format tag  
>  x  -- return hexadecimal  
> 02  -- set at lease 2 digits, use 0 to pad it to length

