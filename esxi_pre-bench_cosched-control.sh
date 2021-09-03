if [ -z "$1" ]; then
    echo "call with either \"disable\", \"max\" or \"reset\" (to default)"; exit 0
fi

case $1 in

	"disable")  
		start=0
		stop=0
		echo "disabled cosched"
		;;

	"max")  
		start=99000
		stop=100000
		echo "maxed cosched"
		;;
		
	"reset")
		start=2000
		stop=3000
		echo "reset cosched to system defaults"
		;;

esac

vsish -e set /config/Cpu/intOpts/CoschedCostartThreshold ${start} &>/dev/null
vsish -e set /config/Cpu/intOpts/CoschedCostopThreshold ${stop} &>/dev/null
