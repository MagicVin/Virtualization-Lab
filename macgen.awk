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
