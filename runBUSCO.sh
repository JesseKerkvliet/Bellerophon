#!/bin/bash

# Additional information:
# =======================
# runBUSCO v1.0
# This scripts runs the BUSCO tool with the given parameters
# The parameters are:
# 	$1: the assembly
#	  $2: Output name
# 	$3: the number of threads to be used

# Show usage information:
if [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || \
 [ "$1" == "-help" ]
then
	GREEN='\033[0;32m'
	NC='\033[0m'
	echo -e "${GREEN}"
	echo "This script runs the BUSCO tool and is part of Bellerophon"
	echo "The script uses the given assembly and the given insects ortholog-set"
	echo "to find the number of orthologs that are found in the assembly."
  echo " Only one of each ortholog should be found."
	echo ""
	echo "Way of usage:"
	echo ""
	echo "bash runBUSCO.sh assembly output_dir threads"
	echo ""
	echo "Example:"
	echo ""
	echo "/bin/bash runTransrate.sh assembly.fasta Busco_output 8"
	echo ""
	echo "Please note: although this script can be used as a stand-alone tool, it\
is specifically designed to be part of the"
	echo "Bellerophon Pipeline. "
	echo -e "${NC}"

	exit
fi
workspace=${4}
python ${workspace}/utils/BUSCO.py -i ${1} -o ${2} -m tran -c ${3} -l ../BUSCO_insects9/ -f
