#!/bin/bash
echo 0x00 0x16 0x3e $(($RANDOM%128)) $(($RANDOM%256)) $(($RANDOM%256)) | awk '{ i=1 ; while (i < NF) {printf("%02x:",$i); i++}} { printf "%02x\n", $NF }'
