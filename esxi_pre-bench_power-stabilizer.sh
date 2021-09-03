if [ -z "$1" ]; then
    echo "call with either \"set\" or \"reset\" (to default)"; exit 0
fi

hwSupport=$(vsish -e get /power/hardwareSupport | sed -n 's/   CPU power management:\(ACPI P-states, ACPI C-states\)$/\1/p')

if [ -z "$hwSupport" ]; then
    echo "Check that BIOS is properly configured"; exit 0
fi

cpuSupport=$(vsish -e get /hardware/cpu/cpuList/0 | sed -n 's/   Name:\(GenuineIntel\)/\1/p')

if [ -z "$cpuSupport" ]; then
    echo "Only known to work on Intel"; exit 0
fi

case $1 in

	"set")  
		policy=4
		max=99
		min=99
		dc=0
		echo "disabled Turbo Boost and deep C-States, vote for P1/NF"
		;;
		
	"reset")
		policy=2
		max=100
		min=0
		dc=1
		echo "reset custom power options to system default and policy to balanced"
		;;

esac

vsish -e set /power/currentPolicy ${policy} 
vsish -e set /config/Power/intOpts/MaxFreqPct ${max} &>/dev/null
vsish -e set /config/Power/intOpts/MinFreqPct ${min} &>/dev/null
vsish -e set /config/Power/intOpts/UseCStates ${dc} &>/dev/null
