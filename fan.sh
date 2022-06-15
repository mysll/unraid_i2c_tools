#!/bin/bash
modprobe i2c-dev
echo $$ > /var/run/fan.pid
TEMP_HIGH=65
TEMP_LOW=35
PWM_HIGH=255
PWM_LOW=50
FAN_TEMP_INCREMENTS=$(($TEMP_HIGH-$TEMP_LOW))
FAN_PWM_INCREMENTS=$(($(($PWM_HIGH-$PWM_LOW))/$FAN_TEMP_INCREMENTS))
echo $FAN_TEMP_INCREMENTS, $FAN_PWM_INCREMENTS
while true
do
	cpu=$(sensors -A|awk 'BEGIN{cpu=""}{if (/^CPU Temp/) cpu=$3*1} END{print cpu}')
	mb=$(sensors -A|awk 'BEGIN{mb=""}{if (/^MB Temp/) mb=$3*1} END{print mb}')
	HIGHEST_TEMP=$mb
	if [[ $cpu -gt $mb ]]; then
		HIGHEST_TEMP=$cpu
	fi
	ADJUSTED_FAN_SPEED=$PWM_LOW
	if [[ $HIGHEST_TEMP -le $TEMP_LOW ]]; then
		ADJUSTED_FAN_SPEED=$PWM_LOW
	else
		if [[ $HIGHEST_TEMP -ge $TEMP_HIGH ]]; then
			ADJUSTED_FAN_SPEED=$PWM_HIGH
		else
			#echo $cpu, $mb, $HIGHEST_TEMP
			ADJUSTED_FAN_SPEED=$(($(($(($HIGHEST_TEMP-$TEMP_LOW))*$FAN_PWM_INCREMENTS))+$PWM_LOW))
			ADJUSTED_PERCENT_SPEED=$(($(($ADJUSTED_FAN_SPEED*100))/$PWM_HIGH))
			ADJUSTED_OUTPUT=$ADJUSTED_FAN_SPEED
		fi
	fi
	i2cset -y 0 0x54 0xF0 $ADJUSTED_FAN_SPEED
	#echo $ADJUSTED_OUTPUT
	sleep 60
done

exit
