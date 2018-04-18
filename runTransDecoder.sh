#!/bin/bash

# Additional information:
# =======================
#
# This scripts runs the Transrate tool with the given parameters
# The parameters are:
# 	$1: the assembly
#	$2: the left side reads
# 	$3: the right side reads
# 	$4: the number of threads to be used
# 	$5: boolean to keep or throw away the large BAM files that Transrate produces
#	$6: the name for the output directory

# Show usage information:
if [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || \
	 [ "$1" == "-help" ]
then
	GREEN='\033[0;32m'
	NC='\033[0m'
	echo -e "${GREEN}"
	echo "This script runs the Transrate tool and is part of the Transcritpome\
Quality Pipeline"
	echo "The script uses the given assembly and the given paired-end reads to\
calculate"
	echo "quality measures for the given assembly."
	echo ""
	echo "Way of usage:"
	echo ""
	echo "bash runTransrate.sh assembly reads_R1 reads_R2 threads keep_bam?\
Output_directory"
	echo ""
	echo "Example:"
	echo ""
	echo "/bin/bash runTransrate.sh assembly.fasta reads_R1.fastq reads_R2.fastq \
8 FALSE output_dir"
	echo ""
	echo "Please note: although this script can be used as a stand-alone tool, \
it is specifically designed to be part of the"
	echo "Transcriptome	Quality Pipeline. "
	echo ""
	echo -e "${NC}"

	exit
fi
workspace=${3}
assemblyname=$(basename "${1}" .fasta)
basename=${1##*/}
# Calculate ORFS
${workspace}/utils/TransDecoder-3.0.1/TransDecoder.LongOrfs -t "${1}" -m "${2}"
# Sort and uniq first column
cut -f 1 "${basename}.transdecoder_dir/longest_orfs.gff3" | sort | uniq > "${assemblyname}.names"
# Extract sequences from assembly file
${workspace}/utils/faSomeRecords ${1} "${assemblyname}.names" "${assemblyname}_${2}aa.fasta"
