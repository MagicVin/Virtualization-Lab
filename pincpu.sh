#!/bin/bash

cpuset=14-17,22,32-35;for cpus in ${cpuset//,/ };do [[ $cpus =~ "-" ]] && eval echo -n {${cpus//-/..}} || echo -n " $cpus ";done
