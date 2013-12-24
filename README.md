# CPU load script 

This script generates a desired CPU load and forces it per each core on 
machines running Ubuntu.

It requires *stress* and *cpulimit* to be installed on the target machine:

	- sudo apt-get install stress
	- sudo apt-get install cpulimit

Usage: 

	- ./cpuload.sh [cpu load in percent] [duration in seconds]
	- ./cpuload.sh 25 10
