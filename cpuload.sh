 #!/bin/bash
###############################################################################
# # CPU load script 

# This script generates a desired CPU load and forces it per each core on 
# machines running Ubuntu.

# It requires stress and cpulimit to be installed on the target machine:
#    sudo apt-get install stress cpulimit

# Usage:
#    ./cpuload.sh [cpu load in percent] [duration in seconds]
#    ./cpuload.sh 25 10
###############################################################################


###############################################################################
# Define general functions to used by the script
###############################################################################
   
   # Usage: countdown "00:07:55"
function countdown {

   local OLD_IFS="${IFS}"
   IFS=":"
   local ARR=( $1 )
   local SECONDS=$((  (ARR[0] * 60 * 60) + (ARR[1] * 60) + ARR[2]  ))
   local START=$(date +%s)
   local END=$((START + SECONDS))
   local CUR=$START

   while [[ $CUR -lt $END ]]
   do
      CUR=$(date +%s)
      LEFT=$((END-CUR))

      printf "\rTime left: %02d:%02d:%02d" \
            $((LEFT/3600)) $(( (LEFT/60)%60)) $((LEFT%60))

      sleep 1
   done
   IFS="${OLD_IFS}"
   echo "        "
   
}

# Get current data and time
function get_current_time {
    local output
    output=$(date +"%Y-%m-%d--%H:%M:%S")
    echo $output
}

   # Validate the input arguments
function validate_cpu_load_value {
      # Check if the entered CPU load is valid
   if [[ $@ =~ ^-?[[:digit:]]+$ ]]
      then
         if [[ $@ -gt $((100)) ]] || [[ $@ -lt $((0)) ]]
            then
               echo "Error: Entered CPU load value is not valid."
               echo "Valid range 0-100%." 
               exit
            else
               CPULIMIT=$@ 
         fi
      else
         echo "Error: Entered CPU load value is not a number."
         exit
   fi
}

function validate_duration_value {
      # Check if the entered duration is valid
   if [[ $@ =~ ^-?[[:digit:]]+$ ]]
      then
         if [[ $@ -lt $((0)) ]]
            then
               echo "Error: Entered duration value is not valid."
               echo "The value must be greater than 0." 
               exit
            else
               CPU_LOAD_DURATION=$@ 
         fi
      else
         echo "Error: Entered duration value is not a number."
         exit
   fi
}

###############################################################################
# Start the script
###############################################################################
USAGE="Usage: `basename $0` [cpu load in percent] [duration in seconds]"

   # Print usage
if [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
  echo $USAGE
  exit 0
fi

# Check if there are two arguments
if [ $# -eq 2 ]; then

   # Validate input parameters.
   validate_cpu_load_value $1
   validate_duration_value $2
else
   echo "Error: the number of input arguments is incorrect!"
   echo $USAGE
   exit 1
fi

# Clean the terminal screen and sudo
clear
sudo echo

# Set the required parameters
CPU_LOAD_DURATION_MIN=$(($CPU_LOAD_DURATION/60))

NUMBER_OF_CORES=$(grep -c processor /proc/cpuinfo)          
CURRENT_CORE_NUMBER=0  #Count starts from 0, 1, 2...

DESCRIPTION="CPU load script"

TODAY=$(date)
NOW=$(date +"%Y%m%d_%H%M%S")
HOST=$(hostname)
FILE="CPU_Load_$HOST""__$NOW.log"
STARTUP_TIME=2

# Print log messages about the script progress
echo "---------------------------------------------------------" | tee -a $FILE
echo "$DESCRIPTION."                                             | tee -a $FILE
echo "---------------------------------------------------------" | tee -a $FILE
echo "Date: $TODAY"                                              | tee -a $FILE
echo "---------------------------------------------------------" | tee -a $FILE
echo "Host: $HOST"                                               | tee -a $FILE
echo "Number of CPU cores: $NUMBER_OF_CORES."                    | tee -a $FILE
echo "CPU load per core: $CPULIMIT%."                            | tee -a $FILE
echo "CPU load duration: $CPU_LOAD_DURATION seconds."            | tee -a $FILE
echo "---------------------------------------------------------" | tee -a $FILE
echo "This script will run for $((CPU_LOAD_DURATION + STARTUP_TIME)) seconds."\
      | tee -a $FILE
echo "---------------------------------------------------------" | tee -a $FILE
echo "[$(get_current_time)] => Creating $FILE."                  | tee -a $FILE

   # Start stress id CPU load is greater than 0.
if [ $CPULIMIT -gt $((0)) ]
then
   echo "[$(get_current_time)] => Starting stress for $STARTUP_TIME seconds."\
         | tee -a $FILE

      # START stress HERE
      #Set the nice value to obtain a higher priority than other processes
   sudo nice -n -5 stress --cpu $NUMBER_OF_CORES --timeout $CPU_LOAD_DURATION --quiet & 

      #stress needs a couple of seconds to start
      #otherwise stress processes PIDS will not be available for cpulimit
   countdown "00:00:$STARTUP_TIME"

      #Retrieve all the stress process PIDS and omit the last PID of the parent process 
   OMIT_PID=$(pidof stress | sed 's/^.* //')
   STRESS_PIDS=$(pidof stress -o $OMIT_PID)

   # echo "[$(get_current_time)] => Current stress PIDS, after the
   # last stress PID has been removed: $STRESS_PIDS." | tee -a $FILE

      #Set the affinity for each process to a separate core
      #Limit the CPU usage per stress process/PID
   array=(${STRESS_PIDS// / })

   for PID in "${array[@]}"
   do
      #Send standard output and error messages to the null device (bit bucket)
      sudo taskset -pc $CURRENT_CORE_NUMBER $PID >/dev/null 2>&1
      sudo cpulimit -p $PID -l $CPULIMIT -b >/dev/null 2>&1
      
      # echo "[$(get_current_time)] => Current core number: $CURRENT_CORE_NUMBER."\
      #       | tee -a $FILE
    
      if [ $CURRENT_CORE_NUMBER -eq $(($NUMBER_OF_CORES - 1)) ]
      then
         CURRENT_CORE_NUMBER=0
      else
          ((CURRENT_CORE_NUMBER++))
      fi
    
      # echo "[$(get_current_time)] => Next core number: $CURRENT_CORE_NUMBER."\
      #       | tee -a $FILE
   done
fi

echo "[$(get_current_time)] => Running $CPULIMIT% CPU load for $CPU_LOAD_DURATION seconds."\
      | tee -a $FILE

if [ $CPU_LOAD_DURATION -lt $((59)) ]
then
   countdown "00:00:$CPU_LOAD_DURATION"
else
   countdown "00:$CPU_LOAD_DURATION_MIN:00"
fi

   #TERMINATE stress HERE
   #Done automatically passing a --timeout parameter
echo "[$(get_current_time)] => Log data saved in $FILE."         | tee -a $FILE
echo "[$(get_current_time)] => This is the end!"                 | tee -a $FILE
echo "---------------------------------------------------------" | tee -a $FILE

