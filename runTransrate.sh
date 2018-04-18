#!/bin/bash

# Additional information:
# =======================
#
# This scripts runs the Transrate tool with the given parameters
# The parameters are:
# 	$1: the assembly
#		$2: the left side reads
# 	$3: the right side reads
# 	$4: the number of threads to be used
# 	$5: boolean to keep or throw away the large BAM files that Transrate
# 			produces
#		$6: the name for the output directory

# Show usage information:
if [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] ||\
 	 [ "$1" == "-help" ]
then
	GREEN='\033[0;32m'
	NC='\033[0m'
	echo -e "${GREEN}"
	echo "This script runs the Transrate tool and is part of the Bellerophon\
 Pipeline"
	echo "The script uses the given assembly and the given paired-end reads to calculate"
	echo "quality measures for the given assembly."
	echo ""
	echo "Way of usage:"
	echo ""
	echo "bash runTransrate.sh assembly reads_R1 reads_R2 threads keep_bam? \
Output_directory"
	echo ""
	echo "Example:"
	echo ""
	echo "/bin/bash runTransrate.sh assembly.fasta reads_R1.fastq reads_R2.fastq \
8 FALSE output_dir"
	echo ""
	echo "Please note: although this script can be used as a stand-alone tool, \
it is specifically designed to be part of the Bellerophon Pipeline. "
	echo -e "${NC}"
	exit
fi

basename=$(basename ${1} .fasta)
basename=${basename##*/}
workspace=${7}
${workspace}/utils/Transrate/transrate --assembly ${1} --left ${2} --right ${3} --threads ${4} --output ${6}

# Removes alignment files from TransRate output to save disk space
if [ "${5}" == false ]; then
	\rm ./${6}/${basename}/*.bam
fi
