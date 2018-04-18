#!/bin/bash
#Start Bellerophon v1.0 Pipeline

# Check dependencies
#	Needed deps:
#		- Transrate (in utils)
#		- TransDecoder (in utils)
#		- CDHIT-EST (should be installed)
#		- Trinity (in utils)
#		- BUSCO  (in utils)

# FUNCTIONS

# Show usage information:
if [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] ||\
 	 [ "$1" == "-help" ]
then
	GREEN='\033[0;32m'
	NC='\033[0m'
	echo -e "${GREEN}"
	echo "This script runs the Bellerophon Pipeline"
	echo "The script uses a transcriptome assembly and paired end reads to \
assess the quality of the transcriptome"
	echo ""
	echo "Way of usage:"
	echo ""
	echo "bash Bellerophon_startscript.sh -a assembly -l reads_R1 -r reads_R2"
	echo ""
	echo "Example:"
	echo ""
	echo "/bin/bash TQP_startscript.sh -a assembly.fasta -l reads_R1.fastq\
	 	-r reads_R2.fastq"
	echo ""
	echo "Mandatory parameters:"
	echo "	-a/--assembly		Transcriptome assembly"
	echo "	-l/--left		left side reads"
	echo "	-r/--right		right side reads"
	echo "Optional parameters:"
	echo "	-c/--cdhit_cutoff: cdhit identity cutoff. 0.95 by default"
	echo "	-t/--tpm_cutoff: expression cutoff. 1 by default"
	echo "	-o/--orf_cutoff: ORF length cutoff. 100 by default (not used in v5.0)"
	echo "	-T/--threads: number of threads to use software (4 by default)"
	echo "	-D/--debug: use debug mode (prints out info about parameters)"
	echo "		False by default"
	echo "	-O/--order: filtering order. 1 By default"
	echo "		Different filtering orders: "
  echo "      1) TPM; CDHIT"
  echo "      2) CDHIT; TPM"
	echo "			3) CDHIT; ORF; TPM"
	echo "			4) ORF; TPM; CDHIT"
	echo "			5) TPM; CDHIT; ORF"
	echo "			6) CDHIT; TPM; ORF"
	echo "			7) ORF; CDHIT; TPM"
	echo "			8) TPM; ORF; CDHIT"
	echo ""
	echo "Please refer to the user manual for more information"
	echo -e "${NC}"
	exit
fi
# TODO: check which function is executed when running pipeline. This one
# is prefered.
function runTransrate {
	outname="TRun_${2}"
	echo "TransRate on ${2}"
	${workspace}/runTransrate.sh "${1}" "${reads_1}" "${reads_2}" "${threads}" \
   "${keep}" "${outname}" "${workspace}" 1>"${outname}.log" 2>"${outname}.error"


}


# Function checkArg takes a flag value and a name and checks if the
# parameter is set. If not, it will exit with error message.
function checkArg {
	if ! $1; then
		echo "argument $2 is mandatory. Please provide it. For help use -h \
or --help"
		exit 1
		fi
}

# Function runCDHIT calls the CDHIT script. The workassembly name is updated
function runCDHIT {
	# Run CDHIT-EST
	# $1 assembly_clear
	# $2 output name
	# $3 identity cutoff
	# $4 number of threads
	echo "CDHIT-EST"
	assembly_PostCDHIT_temp=$(basename ${workassembly} .fasta)
	${workspace}/runCDHIT.sh "${workassembly}"\
   "${assembly_PostCDHIT_temp}_cdhit.fasta" "${cdhit_cutoff}" "${threads}" \
   1>CDHIT.log 2>CDHIT.error
	assembly_PostCDHIT="${assembly_PostCDHIT_temp}_cdhit.fasta"
	workassembly=${assembly_PostCDHIT}

}

# runs TransDecoder. This function is not executed in v5.0
# Instead, an error message is displayed. To use anyway, uncomment the
# commented lines. The function will then call the runTransDecoder tool
# with the given parameters and cutoff scores. The workassembly name
# is updated.
function runTransDecoder {
	# Run TransDecoder
	#echo "Run TransDecoder"
  echo "TransDecoder"
	assembly_postORF_temp=$(basename ${workassembly} .fasta)
	${workspace}/runTransDecoder.sh "${workassembly}" "${orfcutoff}" ${workspace} \
  1>TransDecoder.log 2>TransDecoder.error
	assembly_PostORF="${assembly_postORF_temp}_${orfcutoff}aa.fasta"
	workassembly="${assembly_PostORF}"
}
# Function runRSEM runs the runRSEM script with the given parameters to
# count expression rate. The workassembly name is updated.
function runRSEM {
	# Run RSEM
  echo "RSEM"
  workassembly_abs="$(basename ${workassembly} /)"
  echo ${workassembly}
	${workspace}/runRSEM.sh "${workassembly_abs}"  "${reads_1}" "${reads_2}"\
   "${threads}" "${tpmcutoff}" "${workspace}" 1>RSEM.log 2>RSEM.error
	assembly_PostTPM_temp=$(basename ${workassembly} .fasta)
	assembly_PostTPM="${assembly_PostTPM_temp}_TPM-${tpmcutoff}.fasta"
	workassembly=${assembly_PostTPM}
}


# set an initial value for the flags
buscoflag=false
debug=0
asflag=false
leftflag=false
rightflag=false
keep=false
threads=4
tpmcutoff=1
orfcutoff=50
cdhit_cutoff="0.95"
filter_order=1
reportflag=true
safeflag=false
pdfflag=true
outputdate=$(date +%y_%m_%d_%Hh_%M)
outputdir="Run_${outputdate}"
#TEMP=$(getopt -o a:kl:r:c:t:o:T:DO:sp\
#	--long assembly:,keep_bam,left:,right:,cdhit_cutoff:,tpm_cutoff:,orf_cutoff:\
#	,threads:,debug,order:,safe,nopdf -n 'TQP_startscript.sh' -- "$@")

TEMP=$(getopt -o a:k:l:r:c:bt:o:T:DO:sp\
	--long assembly:,keep_bam,left:,right:,cdhit_cutoff:,busco,tpm_cutoff:,orf_cutoff:,threads:,debug,order:safe,nopdf -n 'test.sh' -- "$@")

# read the options
eval set -- "$TEMP"
# Parameter legend:
#		-a/--assembly: assembly (mandatory)
# 	-k/--keep_bam: boolean to keep or throw out Transrate's alignment files
#									 False by default
#		-l/--left: left side reads (mandatory)
#		-r/--right: right side reads (mandatory)
#		-c/--cdhit_cutoff: cdhit identity cutoff. 0.95 by default
#		-t/--tpm_cutoff: expression cutoff. 1 by default
#		-o/--orf_cutoff: ORF length cutoff. 100 by default (not used in v5.0)
#		-T/--threads: number of threads to use software (4 by default)
#		-D/--debug: use debug mode (prints out info about parameters)
#								False by default
#		-O/--order: filtering order. 1 By default


# extract options and their arguments into variables.
while true ; do
    case "$1" in
		-t|--tpm_cutoff) tpmcutoff=$2; shift 2;;
		-o|--orf_cutoff) orfcutoff=$2; shift 2;;
		-l|--left) reads_1=$2; shift 2; leftflag=true;;
		-r|--right) reads_2=$2; shift 2; rightflag=true;;
        -k|--keep_bam) keep=true ; shift ;;
		-b|--busco) buscoflag=true; shift ;;
		-T|--threads) threads=$2; shift 2;;
		-D|--debug) debug=1; shift ;;
		-O|--order) filter_order=$2; shift 2;;
		-a|--assembly)
            case "$2" in
                "") shift 2 ;;
                *) assembly_clear=$2 ; shift 2 ;;
            esac
			asflag=true ;;
        -c|--cdhit_cutoff) cdhitcutoff=$2; shift 2;;

        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

# Check mandatory parameters
checkArg $leftflag "-l or --left"
checkArg $rightflag "-r or --right"
checkArg $asflag "-a or --assembly"


assembly_clear=$(readlink -f ${assembly_clear})
reads_1=$(readlink -f ${reads_1})
reads_2=$(readlink -f ${reads_2})

basename=$(basename "${assembly_clear}" .fasta)
workspace_rel=$(dirname $0)
workspace=$(readlink -f ${workspace_rel})


mkdir ${outputdir}
cp ${assembly_clear} ${outputdir}
cd ${outputdir}
# Workassembly is set for the first time. Every filtering updates it
workassembly=${assembly_clear}
# Set filtering order
case "${filter_order}" in
		1) runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
      runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
      cp ./TRun_PostCDHIT/*/good*.fasta ./${basename}_BEL.fasta
      runTransrate ${basename}_BEL.fasta "PostBellerophon"
      runTransrate ${assembly_clear} "clear";;
    2) runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
      runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
      cp ./TRun_PostTPM/*/good*.fasta ./${basename}_BEL.fasta
      runTransrate ${basename}_BEL.fasta "PostBellerophon"
      runTransrate ${assembly_clear} "clear";;
    3) reportflag=false;
      runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
      runTransDecoder; runTransrate ${assembly_PostORF} "PostORF"
      runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
      cp ./TRun_PostTPM/*/good*.fasta ./${basename}_BEL.fasta
      runTransrate ${basename}_BEL.fasta "PostBellerophon"
      runTransrate ${assembly_clear} "clear";;
		4) reportflag=false
      runTransDecoder; runTransrate ${assembly_PostORF} "PostORF"
      runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
      runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
      cp ./TRun_PostCDHIT/*/good*.fasta ./${basename}_BEL.fasta
      runTransrate ${basename}_BEL.fasta "PostBellerophon"
      runTransrate ${assembly_clear} "clear";;
		5) runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
      runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
      runTransDecoder; runTransrate ${assembly_PostORF} "PostORF"
      cp ./TRun_PostORF/*/good*.fasta ./${basename}_BEL.fasta
      runTransrate ${basename}_BEL.fasta "PostBellerophon"
      runTransrate ${assembly_clear} "clear";;
		6) runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
    runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
    runTransDecoder; runTransrate ${assembly_PostORF} "PostORF"
    cp ./TRun_PostORF/*/good*.fasta ./${basename}_BEL.fasta
    runTransrate ${basename}_BEL.fasta "PostBellerophon"
    runTransrate ${assembly_clear} "clear";;
		7) runTransDecoder; runTransrate ${assembly_PostORF} "PostORF"
     runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
     runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
     cp ./TRun_PostTPM/*/good*.fasta ./${basename}_BEL.fasta
     runTransrate ${basename}_BEL.fasta "PostBellerophon"
     runTransrate ${assembly_clear} "clear";;
		8) runRSEM; runTransrate "${assembly_PostTPM}" "PostTPM"
    runTransDecoder; runTransrate ${assembly_PostORF} "PostORF"
    runCDHIT; runTransrate ${assembly_PostCDHIT} "PostCDHIT"
    cp ./TRun_PostCDHIT/*/good*.fasta ./${basename}_BEL.fasta
    runTransrate ${basename}_BEL.fasta "PostBellerophon"
    runTransrate ${assembly_clear} "clear" ;;
		*) echo "Filter order is invalid. For help use -h or --help"; exit 1 ;;

esac

# If debug mode is on, parameters are printed out. Starting time is also given
if [ ${debug} -eq 1 ];then
	echo "Debug mode is on"
	echo "TPM_cutoff: ${tpmcutoff}"
	echo "ORF_cutoff: ${orfcutoff}"
	echo "left reads: ${reads_1}"
	echo "right reads: ${reads_2}"
	echo "Assembly: ${assembly_clear}"
	echo "Threads: ${threads}"
	echo "Keep BAM files? ${keep}"
	echo "CDHIT cutoff: ${cdhit_cutoff}"
	echo "Starting time: $(date)"
fi




# Run the pre-filtering busco as ground level
echo "Beginning BUSCO-run"
${workspace}/runBUSCO.sh ${assembly_clear} "BUSCO_start" ${threads} ${workspace} \
1>BUSCO_start.log 2>BUSCO_start.error

# Run final BUSCO
echo "Final BUSCO-run"
${workspace}/runBUSCO.sh "${basename}_BEL.fasta"  "BUSCO_final" ${threads} ${workspace} \
1>BUSCO_final.log 2>BUSCO_final.error

# Parse TransRate results
echo -n > TransrateResults.csv
cat ./TRun_clear/assemblies.csv >> TransrateResults.csv
cat ./TRun_PostCDHIT/assemblies.csv | tail -1 >> TransrateResults.csv
cat ./TRun_PostORF/assemblies.csv | tail -1 >> TransrateResults.csv
cat ./TRun_PostTPM/assemblies.csv | tail -1 >> TransrateResults.csv
cat ./TRun_PostBellerophon/assemblies.csv | tail -1 >> TransrateResults.csv



echo "Cleaning up"
# Log files are stored in one folder
mkdir Log
mv *.log Log
mv *.error Log

# Bowtie files are stored in one folder
mkdir Bowtie2_files
mv *.ok Bowtie2_files

# Moving RSEM files to one folder
mkdir RSEM_files
assembly_cdhit_ORF=DD23_PGl-AdF_Transcriptome2.b_cdhit_100aa.fasta
mv *\.RSEM* RSEM_files

#Moving transrate folders
mkdir Transrate_output
mv TRun* Transrate_output

#Moving other output files
mkdir Misc_output
mv *.clstr Misc_output
mv *.names Misc_output
mv *transdecoder_dir Misc_output

#Moving Fasta files
mkdir Fasta_files
mv *.fasta Fasta_files


# Done, prints finish time if debug mode is on
echo "Done!"
if [ ${debug} -eq 1 ]; then echo "Finished: $(date)";fi
