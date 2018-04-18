#!/bin/bash

# Additional information:
# =======================
# runRSEM v1.0
# This scripts runs the RSEM tool of Trinity with the given parameters
# The parameters are:
# 	$1: the assembly
#		$2: the left side reads
# 	$3: the right side reads
# 	$4: the number of threads to be used
#		$5: cut-off score

#Global variable [ Workspace ]

# Show usage information:
if [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] ||\
 [ "$1" == "-help" ]
then
	GREEN='\033[0;32m'
	NC='\033[0m'
	echo -e "${GREEN}"
	echo "This script runs the RSEM tool in Trinity and is part of the \
Bellerophon Pipeline"
	echo "The script uses the given assembly and the given paired-end reads to \
calculate"
	echo "expression scores and then filters for (for now) a TPM score of 1"
	echo ""
	echo "Way of usage:"
	echo ""
	echo "bash runRSEM.sh assembly reads_R1 reads_R2 threads"
	echo ""
	echo "Example:"
	echo ""
	echo "/bin/bash runTransrate.sh assembly.fasta reads_R1.fastq reads_R2.fastq 8"
	echo ""
	echo "Please note: although this script can be used as a stand-alone tool,\
it is specifically designed to be part of the"
	echo "Bellerophon Pipeline. "

	echo -e "${NC}"
	exit
fi

# Function TPM calculates the expression scores for the given asesmbly and the
#	given reads.
function TPM {

perl ${workspace}/utils/align_and_estimate_abundance.pl --transcripts ${1} --left ${2} \
		  --right ${3} --est_method RSEM --output_dir TPM_output  --seqType fq \
			--aln_method bowtie2  --prep_reference


}
# Function filter filters the results of function TPM for TPM values.
# Only transcripts with expression > the cutoff are kept
function filter {

cd TPM_output
cat RSEM.isoforms.results | awk -v cut=${2} '{ if( $6 > cut ){ print $1 }}' > TPM_names.txt
basename=$(basename $1 .fasta)
relname=$(readlink -f ../"${1}")
echo ${relname}
${workspace}/utils/faSomeRecords "${relname}" TPM_names.txt "../${basename}_TPM-1.fasta"
cd ..

}
workspace=${6}
# Call functions TPM and filter
TPM $1 $2 $3 $4 ${workspace}
filter $1 $5 ${workspace}
