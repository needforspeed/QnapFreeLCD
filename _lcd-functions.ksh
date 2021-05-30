#!/usr/local/bin/ksh93
#
# function library sample for lcd-control 
# original author Dirk Brenken (dibdot@gmail.com)
#
#   LICENSE
#   ============
#   QnapFreeLcd Copyright (C) 2014 Dirk Brenken and Justin Duplessis
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# GET STARTED
# ============
# This is a sample script to gather and prepare system information for a QNAP TS-453A box with 2x16 LCD display.
# It's a helper script which will be automatically sourced by lcd-control.ksh during runtime as input.
# All query results have to fill up the "ROW" array and increment the array index accordingly.
# Please make sure, that the result sets match your LCD dimensions/rows,
# For most QNAP boxes (maybe all?) every single result set should consist of two rows.
# Please keep in mind, that this function library acts as a normal shell script,
# therefore it might be a good idea to test your queries and result sets stand alone before lcd-control.ksh integration.
# Feel free to build your own system queries and result sets (see examples below).
# Contributions for other QNAP boxes or better examples to enlarge this function library are very welcome!

# enable shell debug mode
#
#set -x

# treats unset variables as an error
#
set -u

# reset pre-defined message array
#
set -A ROW

#-------------------------------------------------------------------------------
# 1. network
# get host and ip address
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
HOST="$(hostname -s)"
IP=$(ifconfig igb1 | grep "inet " | cut -f 2 -d " " | grep -v "127.0.")
# result
ROW[${INDEX}]="${HOST}"
(( INDEX ++ ))
ROW[${INDEX}]="${IP}"

#-------------------------------------------------------------------------------
# 2. os/kernel
# get kernel and OS information
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
OS_LINE="Unknown";
if [ -f /etc/version ];then
	OS_LINE=$(cut -d' ' -f1 /etc/version)
else
	echo "Could not find proper file to retrieve OS info."
fi
#kernel info
KERNEL=$(uname -r)
# result
ROW[${INDEX}]=$OS_LINE
(( INDEX ++ ))
ROW[${INDEX}]="${KERNEL}"

#-------------------------------------------------------------------------------
# 4. Pool info (zfs)
# detect which is installed and how many pools are present
#-------------------------------------------------------------------------------
#
ZFS_POOLS=0
R_DEVICES=""

if (( $(whereis zfs | wc -w) != 1 ))
then
	ZFS_POOLS=$(zpool list -H | wc -l)
	echo "Found $ZFS_POOLS zfs pools !"
fi


#-------------------------------------------------------------------------------
# 4.1 Pool info zfs
# TODO add support for multiple pools ?
#-------------------------------------------------------------------------------
#
# get current index count as start value
if (( $ZFS_POOLS > 0 ))
then
	INDEX=${#ROW[@]}
	# query
	PREV_TOTAL=0
	PREV_IDLE=0
	FREE=$(zpool list -H data | cut -f 4)
	HEALTH=$(zpool list -H data | cut -f 10)
	CAP=$(zpool list -H data | cut -f 8)
	# result
	ROW[${INDEX}]="$(zpool list -H data | cut -f 1) $(zpool list -H data | cut -f 2)"
	(( INDEX ++ ))
	ROW[${INDEX}]="$FREE $HEALTH"
	(( INDEX ++ ))
	R_DEVICES=$(ls -l /dev/ada[0-9] | awk '{print$9}')
	echo $R_DEVICES
fi

#-------------------------------------------------------------------------------
# 5. HDD temps
# get hdd temperature (re-use device information from zfs)
#-------------------------------------------------------------------------------
#
# get current index count as start value
if [ "$R_DEVICES" != "" ]; then
	INDEX=${#ROW[@]}
	# query
	DEVICES="${R_DEVICES}"
	DRIVE_TEMPS=$(smartctl -A ${DEVICES} | grep Temperature_Celsius | awk '{print$10}')
	# result
	ROW[${INDEX}]="Drive Temps"
	(( INDEX ++ ))
	ROW[${INDEX}]="$DRIVE_TEMPS"
	(( INDEX ++ ))
else
	echo "No devices were found to probe for temperature !"
fi
#-------------------------------------------------------------------------------
# 6. CPU load
# get current cpu load
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
PREV_TOTAL=0
PREV_IDLE=0
# result
ROW[${INDEX}]="Load Average"
(( INDEX ++ ))
ROW[${INDEX}]=$(uptime | awk -F'load averages: ' '{ print $2 }')
(( INDEX ++ ))

#-------------------------------------------------------------------------------
# 7. update
# display uptime
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
PREV_TOTAL=0
PREV_IDLE=0
# result
ROW[${INDEX}]="Uptime"
(( INDEX ++ ))
ROW[${INDEX}]=$(uptime | grep -ohe 'up .*' | sed 's/,//g' | awk '{ print $2" "$3 }')
(( INDEX ++ ))

#-------------------------------------------------------------------------------
# 8. last update
# display the data update time
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
PREV_TOTAL=0
PREV_IDLE=0
# result
ROW[${INDEX}]="Last Updated"
(( INDEX ++ ))
ROW[${INDEX}]=$(date +"%H:%M %D")
(( INDEX ++ ))
