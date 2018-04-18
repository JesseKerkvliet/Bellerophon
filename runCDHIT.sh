#!/bin/bash

# Additional information:
# =======================
#
# This scripts runs the CDHIT-EST tool with the given parameters
# The parameters are:
# 	$1: the input assembly
#		$2: the output assembly
# 	$3: the identity score to cluster for
# 	$4: the number of threads to use


# Show usage information:
if [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] ||\
 [ "$1" == "-help" ]
then
	GREEN='\033[0;32m'
	NC='\033[0m'
	echo -e "${GREEN}"
	echo "This script runs the CDHIT-EST tool and is part of the Transcritpome \
Quality Pipeline"
	echo "The script uses the given assembly and the given identity cut-off to \
cluster"
	echo "similar transcripts. This is used to improve the transcriptome's \
assembly."
	echo ""
	echo "Way of usage:"
	echo ""
	echo "bash runCDHIT.sh assembly Output_directory identity-cutoff threads"
	echo ""
	echo "Example:"
	echo ""
	echo "/bin/bash runCDHIT.sh assembly.fasta output_dir 0.95 8"
	echo ""
	echo "Please note: although this script can be used as a stand-alone tool, it\
is specifically designed to be part of the"
	echo "Transcriptome	Quality Pipeline. "

	echo -e "${NC}"
	exit
fi

cdhit-est -i ${1} -o ${2} -c ${3} -T ${4}
