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
# Define general functions to be used by the script
###############################################################################
   
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
#clear
#sudo echo
echo "CPU_LOAD_DURATION"
echo $2 

echo "CPULIMIT"
echo $CPULIMIT 
# Set the required parameters
CPU_LOAD_DURATION_MIN=$(($CPU_LOAD_DURATION/60))

NUMBER_OF_CORES=$(grep -c processor /proc/cpuinfo)          
CURRENT_CORE_NUMBER=0  #Count starts from 0, 1, 2...

DESCRIPTION="CPU load script"

stress -c 1 -t $CPU_LOAD_DURATION  & cpulimit -p $( pidof -o $! stress ) -l $CPULIMIT
