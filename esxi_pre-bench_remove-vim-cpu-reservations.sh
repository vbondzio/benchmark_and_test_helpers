confBck="/tmp/esx.conf"
/bin/cp -f /etc/vmware/esx.conf ${confBck}

echo -e "removes CPU reservations for everything below host/vim: FOR TESTING ONLY\n"

group_unreserved()
{
    vsish -e get /sched/groups/$1/stats/capacity | sed -n 's/^   cpu-unreserved\:\([0-9]\+\).*MHz.*$/\1/p'
}

echo "host/user capacity in MHz before:" $(group_unreserved 4)

for schedGroup in $(sched-stats -t groups -z vmgid:amin 2> /dev/null | awk '$1 !~ /^(0|vmgid)$/ && $2 !~ /^0$/ {print $1}')
do 
    groupPath=$(vsish -e get /sched/groups/${schedGroup}/groupPathName | grep vim)
    if [ "${groupPath}" ]
    then
        groupAmin=$(vsish -e get /sched/groups/${schedGroup}/cpuAllocationInMHz | sed -n 's/^   min\:\([0-9]\+\)$/\1/p')
        echo "set reservation for ${groupPath} from ${groupAmin} to 0 MHz"
        reset="localcli --plugin-dir=/usr/lib/vmware/esxcli/int sched group setcpuconfig --group-path=${groupPath} --min=${groupAmin} --units=mhz"
        localcli --plugin-dir=/usr/lib/vmware/esxcli/int sched group setcpuconfig --group-path=${groupPath} --min=0 --units=mhz
        resetAll="${resetAll}\n${reset}"
    fi
done

echo "host/user capacity in MHz after:" $(group_unreserved 4)
echo -e "\nto adjust to boot defaults live, run: ${resetAll}" 

echo -e "\nto reset (any changes since execution, run:\n/bin/cp -f ${confBck} /etc/vmware/esx.conf && reboot"
