schedNcpus=$(sched-stats -t ncpus)
numPcpus=$(echo "${schedNcpus}" | sed -n 's/\([0-9]\+\) PCPUs$/\1/p')
numCores=$(echo "${schedNcpus}" | sed -n 's/\([0-9]\+\) cores$/\1/p')
numNumaNodes=$(echo "${schedNcpus}" | sed -n 's/\([0-9]\+\) NUMA nodes$/\1/p')
# one free core per NUMA node for easier sizing
schedDomainSize=$(($((${numCores} / ${numNumaNodes})) -1))
numVcpus=$((${numCores} - ${numNumaNodes}))

echo "numvcpus = ${numVcpus}"
echo "sched.mem.pin = TRUE"
echo "sched.cpu.affinity.exclusive = TRUE"
echo "cpuid.coresPerSocket = ${schedDomainSize}"
echo "numa.vcpu.maxPerVirtualNode = ${schedDomainSize}"

htOn=$((${numPcpus} / ${numCores}))

vcpu=0
for node in $(vsish -e ls /hardware/numa/ | sort)
do
	firstPcpu=$(vsish -e ls /hardware/numa/${node}pcpus/ | head -1)
    lastPcpu=$(vsish -e ls /hardware/numa/${node}pcpus/ | tail -1)
    for i in $(seq $((${firstPcpu} + ${htOn})) ${htOn} $((${lastPcpu} - $((${htOn} - 1)) )) )
        do echo -e "sched.vcpu${vcpu}.affinity = ${i}"
    vcpu=$((${vcpu} +1))
    done
done

if [ $vcpu != $numVcpus ]
then
    echo "something is fucky"
    exit
fi

cpuSpeed=$(gzip -dc /var/log/boot.gz | sed -n "s/.*SMP.*measured cpu speed: \([0-9]\{4\}\).*$/\1/p")
cpuReservation=$((${cpuSpeed} * ${numVcpus}))
cpuUnreserved=$(vsish -e get /sched/groups/4/stats/capacity | sed -n 's/^   cpu-unreserved\:\([0-9]\+\).*MHz.*$/\1/p')

if [ ${cpuReservation} -gt ${cpuUnreserved} ]
then
    echo -e "\nNot enough unreserved capacity: ${cpuUnreserved} available vs. ${cpuReservation} required"    
else
    echo -e "\nFull VM CPU reservation: ${cpuReservation} MHz"
fi
