#!/bin/bash
export_pwm() {

    if [ ! -d "$node" ]; then
        echo "## Export PWM $port on PWM Chip $chipnum to system"
        echo "$port" > /sys/class/pwm/pwmchip"$chipnum"/export
        sleep 2
    fi

    if [ ! -d "$node" ]; then
        echo "## Unable to export PWM $port on PWM Chip $chipnum"
        exit 1
    fi
    echo "Setting up period of $type chip$chipnum pwm$port to 1 sec"
    echo '1000000000' > "$node"/period
    echo "Setting up duty cycle to 0.5 sec"
    echo '500000000' > "$node"/duty_cycle
}

export_gpio() {

    if [ ! -d "$node" ]; then
        echo "## Export GPIO $port to system"
        echo "$port" > /sys/class/gpio/export
        sleep 2
    fi

    if [ ! -d "$node" ]; then
        echo "## Unable to export GPIO $port"
        exit 1
    fi

    direction=$(cat "$node"/direction)
    if [ "$direction" != "$direct" ]; then
        echo "$direct" > "$node"/direction
    fi
}

test_buzzer() {
    result_pre="Buzzer $name test"

    echo "## $type is activated"
    echo "## Start $type Buzzer $name test"
    echo "## Set $type $port to $enable"
    if [ "$type" == 'gpio' ]; then
        node="$node"/value
    else
        node="$node"/enable
    fi
    echo "$enable" > "$node"
    while true
    do
        echo "Do you hear the sound from buzzer $name? (y/n)"
        read -r result
        if [ "$result" == "n" ]; then
            echo "$result_pre: FAILED"
            exit 1
        elif [ "$result" == "y" ]; then
            break
        fi
    done

    echo "## Set $type $port to $disable"
    echo "$disable" > "$node"
    while true
    do
        echo "Is the buzzer $name stop? (y/n)"
        read -r result
        if [ "$result" == "n" ]; then
            echo "$result_pre: FAILED"
            exit 1
        elif [ "$result" == "y" ]; then
            break
        fi
    done
    echo "$result_pre: PASSED"
}

main() {
    if [ "$enable" == "1" ]; then
        disable=0
    else
        disable=1
    fi
    if [ "$type" == "gpio" ]; then
        node="/sys/class/gpio/gpio$port"
        direct="out"
        # Configure GPIO interface if needed
        export_gpio
    elif [ "$type" == "pwm" ]; then
        node="/sys/class/pwm/pwmchip$chipnum/pwm$port"
        direct="out"
        export_pwm
    else
        echo "Error: Unknown type!!"
        exit 1
    fi
    # Test buzzer
    test_buzzer
}

help_function() {
    echo "This script is uses for test GPIO/PWM buzzer"
    echo "Will change GPIO/PWM value to make a sound from buzzer"
    echo
    echo "Usage: button_test.sh -t type -n button_name -p gpio_port -e [0|1]"
    echo -e "\t-e    the state to make a sound from buzzer. [0|1]"
    echo -e "\t-n    button name."
    echo -e "\t-p    gpio or pwm port."
    echo -e "\t-c    pwm chip number"
    echo -e "\t-t    type of test target in gpio or pwm"
}

while getopts "n:p:e:t:c:" opt; do
    case "$opt" in
        n) name="$OPTARG" ;;
        p) port="$OPTARG" ;;
        e) enable="$OPTARG" ;;
        t) type="$OPTARG" ;;
        c) chipnum="$OPTARG" ;;
        ?) help_function ;;
    esac
done

if [[ -z $name || -z $port || -z $enable || -z $type ]]; then
    echo -e "Error: Button name, port number, type and enable-state is needed!\n"
    help_function
    exit 1
elif [ "$type" == 'pwm' ] && [ -z "$chipnum" ]; then
    echo -e "Error: Chip number is needed if type in PWM!\n"
    help_function
    exit 1
fi
main