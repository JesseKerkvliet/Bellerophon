#!/usr/bin/python3
import subprocess
import argparse
import os.path
import sys
import textwrap
import datetime
"""
Startscript for the Bellerophon chimera removal pipeline.
The script parses the required arguments into a config file
and runs the snakemake rule file to execute the pipeline.
"""
def checkExistence(*args):
	"""
	Functions check if input files exist.
	Returns False if one or more files are missing
	Returns the list of missing files.
	"""
	errorlist = []
	for arg in args:
		if not os.path.isfile(arg):
			errorlist.append(arg)
	return(len(errorlist)==0,errorlist)

def paramparser():
	"""
	Function creates argparse object that takes all
	commandline arguments required.
	"""
	parser = argparse.ArgumentParser()
	# Mandatory arguments
	parser.add_argument("-a", "--assembly", required=True, help="Assembly file")
	parser.add_argument("-l","--left", required=True, help="Left reads")
	parser.add_argument("-r","--right", required=True, help="Right reads")
	# Optional arguments
	parser.add_argument("-c","--cdhit_cutoff", help="Cluster cutoff for CDHIT", default="0.95")
	parser.add_argument("-t","--tpm_cutoff", help="TPM expression cutoff", default=1)
	parser.add_argument("-o","--orf_cutoff", help="Length cutoff for ORF filtering", default=50)
	parser.add_argument("-T","--threads", help="Number of threads", default=4)
	parser.add_argument("-S","--order", help="Filtering order") # Disabled in this version
	parser.add_argument("-O","--outdir", help="Output directory")	
	args = parser.parse_args()
	return args

def determineAssemblies(args):
	"""
	Snakemake builds the order of the pipeline based on the input file names.
	This function creates a list of filenames that will be used as intermediate
	and output files. The names of the intermediate files depend on the chosen
	filtering order.
	In the default case, the TPM input file will be the clean unfiltered file.
	The CDHIT filter is the next default filter, being assigned as input file the output
	of the TPM filter. The ORF filter is not used in the default filter and is set to "None".
	//NOTE: in this version of Bellerophon, the order determination functionality is disabled.
	This will be re-enabled during a later update.
	"""

	basename = args.assembly.split(".fa")[0].split("/")[-1]
	tpm_name = args.assembly
	cdhit_name = "{}_postTPM.fasta".format(basename)
	transrate_name = "{}_postCDHIT.fasta".format(basename)
	orf_name = "None"
	return([tpm_name,cdhit_name,orf_name,transrate_name, basename])

def create_config(outputdir, args, assembly_names):
	"""
	Function creates the snakemake yml config file.
	It takes the commandline arguments and default parameters and returns a interpretable yml string.
	"""
	configstring=textwrap.dedent("""\
	assembly: {}
	final_assembly: {}
	TPM_assembly: {}
	CDHIT_assembly: {}
	ORF_assembly: {}
	left_reads: {}
	right_reads: {}
	tpm_threshold: {}
	cdhit_cutoff: {}
	ORF_cutoff: {}
	basename: {}
	outdir: {}
	threads: {}""".format(args.assembly,assembly_names[3],assembly_names[0],assembly_names[1],
			assembly_names[2],args.left, args.right, args.tpm_cutoff, args.cdhit_cutoff,
			args.orf_cutoff, assembly_names[4], outputdir, args.threads))
	return configstring

def main():
	"""
	Main function calls for argument parser, checks if provided files exist,
	creates a default output directory name based on the current date and time,
	retrieves the intermediate assembly names and retrieves the filled in YML config string.
	It writes the config string to a config file interpretable by the Bellerophon snakemake pipeline,
	and lastly calls the pipeline with the provided parameters.
	"""
	args = paramparser()
	existing = checkExistence(args.assembly, args.left, args.right)
	if not existing[0]:
		print("The following file(s) could not be found:\n\t-{}".format("\n\t-".join(existing[1])))
		sys.exit()

	now = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M")
	
	if args.outdir:
		outputdir = args.outdir
	else:
		outputdir= "{}_output".format(now)

	assembly_names = determineAssemblies(args)
	config = create_config(outputdir, args, assembly_names)
	configfile = open('config_BEL.yml','w')
	configfile.write(config)
	configfile.close()

	subprocess.call(["snakemake","--snakefile","Bellerophon.snakefile","--use-conda"])


if __name__ == "__main__":
	main()
