 #!/bin/bash
###############################################################################
# # CPU load script 

# This script generates a desired CPU load and forces it per each core on 
# machines running Ubuntu.

# It requires stress and cpulimit to be installed on the target machine:
#    sudo apt-get install stress
#    sudo apt-get install cpulimit

# Usage:
#    ./cpuload.sh [cpu load in percent] [duration in seconds]
#    ./cpuload.sh 25 10
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

clear
sudo echo

   # Parameters
   # Check if the entered CPU load is valid
if [[ $1 =~ ^-?[[:digit:]]+$ ]]
   then
      if [[ $1 -gt $((100)) ]] || [[ $1 -lt $((0)) ]]
         then
            echo "Entered CPU load value is not valid."
            echo "Valid range 0-100%." 
            exit
         else
            CPULIMIT=$1 
      fi
   else
      echo "Entered CPU load value is not a number."
      exit
fi

   # Check if the entered duration is valid
if [[ $2 =~ ^-?[[:digit:]]+$ ]]
   then
      if [[ $2 -lt $((0)) ]]
         then
            echo "Entered duration value is not valid."
            echo "The value must be greater than 0." 
            exit
         else
            CPU_LOAD_DURATION=$2 
      fi
   else
      echo "Entered duration value is not a number."
      exit
fi


CPU_LOAD_DURATION_MIN=$(($CPU_LOAD_DURATION/60))

NUMBER_OF_CORES=$(grep -c processor /proc/cpuinfo)          
CURRENT_CORE_NUMBER=0  #Count starts from 0, 1, 2...

DESCRIPTION="$CPULIMIT% CPU load for $CPU_LOAD_DURATION seconds"

TODAY=$(date)
NOW=$(date +"%Y%m%d_%H%M%S")
HOST=$(hostname)
FILE="CPU_Load_$HOST""__$NOW.log"
STARTUP_TIME=2


echo "-----------------------------------------------------------------------\
--------------------------------------" | tee -a $FILE

echo "CPU load script." | tee -a $FILE

echo "-----------------------------------------------------------------------\
--------------------------------------" | tee -a $FILE

echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Creating $FILE."  | tee -a $FILE

echo "-----------------------------------------------------------------------\
--------------------------------------" | tee -a $FILE

echo "Starting $DESCRIPTION." | tee -a $FILE

echo "Number of CPU cores: $NUMBER_OF_CORES." | tee -a $FILE

echo "CPU load per core: $CPULIMIT%." | tee -a $FILE

echo "CPU load duration: $CPU_LOAD_DURATION seconds." | tee -a $FILE

echo "-----------------------------------------------------------------------\
--------------------------------------" | tee -a $FILE

echo "Date: $TODAY                     Host: $HOST" | tee -a $FILE

echo "-----------------------------------------------------------------------\
--------------------------------------" | tee -a $FILE
echo "This script will run for $((CPU_LOAD_DURATION + STARTUP_TIME)) seconds.\
" | tee -a $FILE

echo

if [ $CPULIMIT -gt $((0)) ]
then
   echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Starting stress to impose the \
   CPU load on $HOST. It will take $STARTUP_TIME seconds." | tee -a $FILE

      # START stress HERE
      #Set the nice value to obtain a higher priority than other processes
   sudo nice -n -5 stress --cpu $NUMBER_OF_CORES --timeout $CPU_LOAD_DURATION &

      #stress needs a couple of seconds to start
      #otherwise stress processes PIDS will not be available for cpulimit
   countdown "00:00:$STARTUP_TIME"

      #Retrieve all the stress process PIDS and omit the last PID of the parent process 
   OMIT_PID=$(pidof stress | sed 's/^.* //')
   STRESS_PIDS=$(pidof stress -o $OMIT_PID)

   echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Current stress PIDS, after the \
   last stress PID has been removed: $STRESS_PIDS."

      #Set the affinity for each process to a separate core
      #Limit the CPU usage per stress process/PID
   array=(${STRESS_PIDS// / })

   for PID in "${array[@]}"
   do
      sudo taskset -pc $CURRENT_CORE_NUMBER $PID
      sudo cpulimit -p $PID -l $CPULIMIT & 
      
      echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Current core number:\
      $CURRENT_CORE_NUMBER." | tee -a $FILE
    
      if [ $CURRENT_CORE_NUMBER -eq $(($NUMBER_OF_CORES - 1)) ]
      then
         CURRENT_CORE_NUMBER=0
      else
          ((CURRENT_CORE_NUMBER++))
      fi
    
      echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Next core number:\
      $CURRENT_CORE_NUMBER." | tee -a $FILE
   done
fi

echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Running $CPULIMIT% CPU load for \
$CPU_LOAD_DURATION seconds." | tee -a $FILE

if [ $CPU_LOAD_DURATION -lt $((59)) ]
then
   countdown "00:00:$CPU_LOAD_DURATION"
else
   countdown "00:$CPU_LOAD_DURATION_MIN:00"
fi

   #TERMINATE stress HERE
   #Done automatically passing a --timeout parameter
echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Terminating stress on \
$HOST." | tee -a $FILE

echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => $DESCRIPTION has been \
completed." | tee -a $FILE

echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => Log data have been written \
into $FILE." | tee -a $FILE

echo "[$(date +"%Y-%m-%d--%H:%M:%S")] => THIS IS THE END!" | tee -a $FILE

