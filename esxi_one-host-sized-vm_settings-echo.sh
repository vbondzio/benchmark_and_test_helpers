schedNcpus=$(sched-stats -t ncpus)
numPcpus=$(echo "${schedNcpus}" | sed -n 's/\([0-9]\+\) PCPUs$/\1/p')
numCores=$(echo "${schedNcpus}" | sed -n 's/\([0-9]\+\) cores$/\1/p')
numNumaNodes=$(echo "${schedNcpus}" | sed -n 's/\([0-9]\+\) NUMA nodes$/\1/p')
# don't care for package size / LLC etc.
schedDomainSize=$((${numPcpus} / ${numNumaNodes}))

echo "cpuid.coresPerSocket = ${schedDomainSize}"
echo "numa.vcpu.maxPerVirtualNode = ${schedDomainSize}"
# theoretically only necessary with > 2 NUMA nodes but lets be safe
# [ "$((${numPcpus} / ${numCores}))" -gt "1" -a "${numNumaNodes}" -gt "2" ]
if [ "$((${numPcpus} / ${numCores}))" -gt "1" ]; then
        echo "numa.vcpu.preferHT =  true"
fi
for i in $(seq 0 1 $((${numPcpus} -1)) )
        do echo -e "sched.vcpu${i}.affinity = ${i}"
done
