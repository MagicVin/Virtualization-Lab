#!/bin/bash

# Aug 24, 2022
# v.xin.zhang@gmail.com
# 

usage_msg=$(cat<<-EOF
  
  $0 pin -t [cpulist] -n [vmname] -m [mgmtcpu]    -- set cpu affinity for vmname
  $0 pin -t [cpulist] -p [vmpid]  -m [mgmtcpu]    -- set cpu affinity for vmpid

  $0 cgroup -t [cpulist] -n [vmname] -m [mgmtcpu] -r [memnode] -- set cgroup for vmname
  $0 cgroup -t [cpulist] -p [vmpid]  -m [mgmtcpu] -r [memnode] -- set cgroup for vmpid

  $0 uncorefreq -q [freq]     -- fix uncore frequency                      
  $0 cpufreq    -q [freq]     -- fix cpu core frequency
  $0 cpumax     -q [freq]     -- set maximum cpu performance
  $0 gpufreq    -q [freq]     -- set gpu frequency

  e.g.
    $0 pin -t 14-17,32-35 -n win10 -m 12-13   -- pin 14-17,32-35 for win10
    $0 pin -t 14-17,32-35 -p 2123 -m 12-13    -- pin 14-17,32-35 for 2123

EOF
)

erro() {
	echo "   error: $@"
}

stato() {
	echo "  status: $@"
}

msgo() {
	printf "    -- %-10s" $1 && shift && printf " %-4s" $@ && printf "\n"
}

msge() {
	echo "    -- $@"
}

runo() {
	$@ 2>&1 | sed 's/^/    -- /g'
}

msarg() {
	erro "$1 missing args"
	echo "$usage_msg"
	exit -1
}


lcpu() {
	cpuset=$1
	for cpus in ${cpuset//,/ } ;{
		[[ $cpus =~ "-" ]] && eval echo {${cpus//-/..}} || echo "$cpus"
	}
}

vcpulist() {
	vthread=(`pstree -pta $vmpid | awk -F ',' '/CPU.*KVM/ {print $NF}'`)
	mthread=(`pstree -pta $vmpid | awk -F',' -vpids=$vmpid 'NR>1 && !/CPU.*KVM/ { pids=pids" "$NF } END {print pids}'`)
}

getpid() {
	vmpid=`ps aux | sed -n "s/^root[[:space:]]*\([[:alnum:]]*\)[[:space:]].* qemu-system-x86_64 -name ${name}.*$/\1/p" | head -n1`
}

getname() {
	name=`pstree -a $vmpid | sed 's/-/\n/g' | sed -n 's/^name \([[:alnum:]]*\).*$/\1/p'`
}

set_affinity() {
	vthread_affinity && manage_affinity
}

vthread_affinity() {
	[[ ${#vthread[@]} -eq ${#pcpu[@]} ]] && {
		for ((i=0;i<${#vthread[@]};i++)) ;{
			msge taskset -pc ${pcpu[i]} ${vthread[i]} && runo taskset -pc ${pcpu[i]} ${vthread[i]}
		}
	}
}

manage_affinity() {
	for m in ${mthread[@]} ;{
		msge taskset -pc $mcpu $m && runo taskset -pc $mcpu $m
	}
}

initconf() {
	[[ ! $vmpid ]] && getpid
	[[ ! $name ]]  && getname

	[[ $vmpid ]] && [[ ${#pcpu[@]} -gt 0 ]] && [[ ${#mcpu} -gt 0 ]] && {
		vcpulist
		stato "$name -- $vmpid"
		msgo  "physical-thread:" ${pcpu[@]} 
		msgo  "virutal--thread:" ${vthread[@]} 
		echo
		msgo  "manage---thread:" ${mcpu[@]}
		msgo  "manage--vthread:" ${mthread[@]}
	} || {
		msarg $FUNCNAME
	} 
}


main() {
	while [ $# -gt 0 ]
	do
		case $1 in 
			"-t")         shift && [[ $1 ]]       && pcpu=(`lcpu $1`)      && shift || msarg ;;
			"-n")         shift && [[ $1 ]]       && name=$1               && shift || msarg ;;
			"-p")         shift && [[ $1 -gt 0 ]] && vmpid=$1              && shift || msarg ;;
			"-m")         shift && [[ $1 ]]       && mcpu=$1               && shift || msarg ;;
			"uncorefreq") shift && cmds="uncore"                                    || msarg ;;
			"cpufreq"   ) shift && cmds="cpu"                                       || msarg ;;
			"cpumax"    ) shift && cmds="cmax"                                      || msarg ;;       
			"gpufreq"   ) shift && cmds="gpu"                                       || msarg ;;
			"pin"       ) shift && cmds="pin"                                       || msarg ;;  
			"cgroup"    ) shift && cmds="cgroup"                                    || msarg ;;
			*)                                                                         msarg ;;
		esac
	done

	[[ $vmpid ]] || [[ $name ]] || msarg $FUNCNAME
	[[ "$cmds" == "pin" ]] && initconf && set_affinity 

}

main $@
