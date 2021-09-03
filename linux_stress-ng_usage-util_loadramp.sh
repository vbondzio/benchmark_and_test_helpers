if [ -z "$1" ]; then
    echo "call with runtime in minutes (default: 5)"
	# I usually select a duration that fits into realtime charts, so max. 60
	testDurationMinutes=5
else
	testDurationMinutes=$1
fi

# maybe include --cpu-load and change --cpu-method from loop to something else
cpuLoadMethod="loop"

cpus=$(nproc --all)
testDurationSeconds=$(($testDurationMinutes*60))
testIntervalSeconds=$(($testDurationSeconds / (($cpus / 2) + 1)))
initialTaskset=$(seq 0 2 $(($cpus - 1)) | paste -s -d ,)

# run stress-ng in background and quiet
# baseline -> half of the vCPUs, all of the cores
stress-ng --taskset $initialTaskset --cpu $(($cpus / 2)) --cpu-method $cpuLoadMethod -t $testDurationSeconds -q &

loop=0
for iterateTaskset in $(seq 1 2 $(($cpus - 1)))
do	
    loop=$(($loop + 1))
    sleep $testIntervalSeconds
    # add another worker to each hypertwin
    stress-ng --taskset $iterateTaskset --cpu 1 --cpu-method $cpuLoadMethod -t $(($testDurationSeconds - ($loop * $testIntervalSeconds))) -q &
done
