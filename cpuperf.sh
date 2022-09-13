#!/bin/bash

# Sep 13, 2022
# v.xin.zhang@gmail.com
# v1.1

usage_msg=$(cat<<-EOF
  
  $0 pin -t [cpulist] -n [vmname] -m [mgmtcpu]    -- set cpu affinity for vmname
  $0 pin -t [cpulist] -p [vmpid]  -m [mgmtcpu]    -- set cpu affinity for vmpid

  $0 cgroup -t [cpulist] -n [vmname] -m [mgmtcpu] -r [memnode] -- set cgroup for vmname
  $0 cgroup -t [cpulist] -p [vmpid]  -m [mgmtcpu] -r [memnode] -- set cgroup for vmpid

  $0 uncorefreq -q [freq]     -- fix uncore frequency                      
  $0 cpufreq    -q [freq]     -- fix cpu core frequency
  $0 cpumax                   -- set maximum cpu performance
  $0 gpufreq    -q [freq]     -- set gpu frequency

  $0 print cpufreq   -- print current cpu frequency

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
	vmpid=`ps aux | sed -n "s/^[[:graph:]]*[[:space:]]*\([0-9]*\).*qemu.*-name [[:graph:]]*${name}[,].*$/\1/p"`
}

getname() {
	name=`pstree -a $vmpid | sed -n 's/^.*-name \([a-zA-Z0-9,-=]*\) -.*/\1/p' | sed 's/,//g;s/debug-threads=o[nf]*//g;s/[a-z]*=//g'`
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

init_cpufreq() {
	online_cpu=`cat /sys/devices/system/cpu/online`
	cpulist=(`lcpu $online_cpu`)

	[ -r /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq ] || {
		erro "Please enable \"Enhanced Intel SpeedStep(R) Tech(Pstate)\" on BIOS Setup"
		exit -1
	}

	cpu_min_freq=()
	cpu_max_freq=()
	cpu_power_policy=()
	cpu_cur_freq=()
	for i in ${cpulist[@]} ;{
		cpu_min_freq[i]=`cat /sys/devices/system/cpu/cpufreq/policy${i}/scaling_min_freq`
		cpu_max_freq[i]=`cat /sys/devices/system/cpu/cpufreq/policy${i}/scaling_max_freq`
		cpu_power_policy[i]=`cat /sys/devices/system/cpu/cpufreq/policy${i}/scaling_governor`
		cpu_cur_freq[i]=`cat /sys/devices/system/cpu/cpufreq/policy${i}/scaling_cur_freq`
	}
}

print_cpufreq() {
	init_cpufreq
	core_count=${#cpulist[@]}
	[[ ${#cpu_min_freq[@]}     -eq $core_count ]]     &&
	[[ ${#cpu_max_freq[@]}     -eq $core_count ]]     &&
	[[ ${#cpu_power_policy[@]} -eq $core_count ]]     &&
	[[ ${#cpu_cur_freq[@]}     -eq $core_count ]]     && {
		printf "%-4s %-10s %-10s %-10s %-10s\n" "id" "Cur/MHz" "Max/MHz" "Min/MHz" "PowerPolicy"
		for ((i=0;i<$core_count;i++)) ;{
			printf "%-4s %-10s %-10s %-10s %-10s\n" $i \
				$((${cpu_cur_freq[i]}/1000)) \
				$((${cpu_max_freq[i]}/1000)) \
				$((${cpu_min_freq[i]}/1000)) \
				${cpu_power_policy[i]}
		}
	}
}

set_cpu_power_max() {
	power_policy=performance
	online_cpu=`cat /sys/devices/system/cpu/online`
	cpulist=(`lcpu $online_cpu`)

	[ -r /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq ] || {
		erro "Please enable \"Enhanced Intel SpeedStep(R) Tech(Pstate)\" on BIOS Setup"
		exit -1
	}

	for c in ${cpulist[@]} ;{
		echo $power_policy > /sys/devices/system/cpu/cpufreq/policy${c}/scaling_governor
		echo $c `cat /sys/devices/system/cpu/cpufreq/policy${c}/scaling_governor`
	}
}

pin_initconf() {
	[[ $vmpid ]] || [[ $name ]] || msarg $FUNCNAME
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
	[ $# -eq 0 ] && msarg $FUNCNAME

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
			"print"     ) shift && action="print"                                   || msarg ;;
			*)                                                                         msarg ;;
		esac
	done

	case $action in
		"print")
			case $cmds in 
				"cpu") print_cpufreq  ;;
				*)     echo "ongoing" ;;
			esac
		;;
		*)
			case $cmds in
				"pin")
					pin_initconf && set_affinity
				;;
				"cmax")
					set_cpu_power_max
					#set_cpu_freq_max
				;;
				*)
					echo "ongoing"
				;;
			esac
		;;
	esac
}

main $@
