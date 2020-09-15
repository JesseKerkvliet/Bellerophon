configfile: "config_BEL.yml"

###
# BELLEROPHON v2.0
# This snakefile runs the Bellerophon pipeline for chimera removal in de novo transcriptome assemblies
# This script is accompanied by Bellerophon.py, which takes care of the preprocessing of the data.
# This version does not yet support multithreading. 
# This version runs BUSCO with the insect v9 set. This file can be manually adjusted to use other sets.
###

# Rule all states all in- and output files
rule all:
	input:
		config["assembly"],
		"{}/{}_postTPM.fasta".format(config["outdir"],config["basename"]),
		"{}/{}_postCDHIT.fasta".format(config["outdir"],config["basename"]),
		"{}/{}_postORF.fasta".format(config["outdir"],config["basename"]),
		"{}/{}_BEL.fasta".format(config["outdir"],config["basename"]),
		"{}/busco_report_clean.txt".format(config["outdir"]),
		"{}/busco_report_final.txt".format(config["outdir"])

# Rule TPM runs the expression filter
rule TPM:
	input:
		assembly=config["TPM_assembly"],
		left=config["left_reads"],
		right=config["right_reads"]
	params:
		cutoff=config["tpm_threshold"],	
		outdir=config["outdir"],
		workspace="."
	threads: config["threads"]
	output:
		output="{}/{}_postTPM.fasta".format(config["outdir"],config["basename"])
	shell:
		"""
		# Runs the RSEM script to calculate TPM
		perl {params.workspace}/utils/align_and_estimate_abundance.pl --transcripts {input.assembly} --left {input.left}\
				--right {input.right} --est_method RSEM --output_dir {params.outdir}/TPM_output --seqType fq \
				--aln_method bowtie2 --prep_reference --thread_count {threads}
		# Filters on the cutoff TPM
		cat {params.outdir}/TPM_output/RSEM.isoforms.results | awk -v cut={params.cutoff} '{{ if ($6 > cut ){{ print $1 }}}}' > {params.outdir}/TPM_names.txt
		
		basename=$(basename {input.assembly} .fasta)
		relname=$(readlink -f "{input.assembly}")
		# Removes all transcripts with low TPM
		{params.workspace}/utils/faSomeRecords "$relname" {params.outdir}/TPM_names.txt {output.output}
		# Relocates the output assembly
		mv {input.assembly}\.* {params.outdir} 
		"""

# Rule CDHIT runs the CDHIT clustering filter
rule CDHIT:
	input:
		assembly="{}/{}".format(config["outdir"],config["CDHIT_assembly"])
	params:
		cutoff=config["cdhit_cutoff"],
		outdir=config["outdir"]
	threads: config["threads"]
	output:
		output="{}/{}_postCDHIT.fasta".format(config["outdir"], config["basename"])
	shell:
		"""
		cd-hit-est -i {input.assembly} -o {output.output} -c {params.cutoff} -T {threads}
		"""

# Rule ORF runs the ORF length filter
rule ORF:
	input:
		assembly=config["ORF_assembly"] if config["ORF_assembly"] != 'None' else config["assembly"]
	params:
		cutoff=config["ORF_cutoff"],
		workspace=".",
		basename=config["basename"],
		clean_assembly =config["assembly"]
	output:
		output="{}/{}_postORF.fasta".format(config["outdir"],config["basename"])
	shell:
		"""	
		# ORF filtering is not always applied. If disabled, the input file will be the same name as the 
		# unfiltered main assembly. The ORF filter then doesn't run.
		if [ {input.assembly} != {params.clean_assembly} ]; then
		{params.workspace}/utils/TransDecoder-3.0.1/TransDecoder.LongOrfs -t {input.assembly} -m {params.cutoff}
		cut -f 1 "{input.assembly}.transdecoder_dir/longest_orfs.gff3" | sort | uniq > "{params.basename}.names"
		{params.workspace}/utils/faSomeRecords {input.assembly} "{params.basename}.names" {output.output}
		else
		# Snakemake needs an output file. This will only contain this string when ORF filtering is disabled.
		echo "ORF filtering was turned off" > {output.output}
		fi
		
		"""

# rule AllTransrates runs TransRate on all (intermediate) assemblies
rule AllTransrates:
	input:
		clean=config["assembly"],
		TPM="{}/{}_postTPM.fasta".format(config["outdir"],config["basename"]),
		CDHIT="{}/{}_postCDHIT.fasta".format(config["outdir"],config["basename"]),
		ORF="{}/{}_postORF.fasta".format(config["outdir"],config["basename"]) if config["ORF_assembly"] != 'None' else config["assembly"],
		final="{}/{}".format(config["outdir"],config["final_assembly"]),
		left=config["left_reads"],
		right=config["right_reads"]
	params:
		keep="false",
		workspace=".",
		outdir=config["outdir"],
		basename=config["basename"]
	threads: config["threads"]
	conda: "envs/transrate.yaml"
	output:
		"{}/{}_BEL.fasta".format(config["outdir"],config["basename"])
	shell:
		"""
		{params.workspace}/utils/Transrate/transrate --assembly {input.clean} --left {input.left} --right {input.right} --output {params.outdir}/TRun_clean --threads {threads}
		{params.workspace}/utils/Transrate/transrate --assembly {input.TPM} --left {input.left} --right {input.right} --output {params.outdir}/TRun_TPM --threads {threads} 
		{params.workspace}/utils/Transrate/transrate --assembly {input.CDHIT} --left {input.left} --right {input.right} --output {params.outdir}/TRun_CDHIT --threads {threads}
		#transrate --assembly {input.clean} --left {input.left} --right {input.right} --output {params.outdir}/TRun_clean --threads {threads}
		#transrate --assembly {input.TPM} --left {input.left} --right {input.right} --output {params.outdir}/TRun_TPM --threads {threads} 
		#transrate --assembly {input.CDHIT} --left {input.left} --right {input.right} --output {params.outdir}/TRun_CDHIT --threads {threads}
		# If ORF filtering is disabled, TransRate won't be called on that output file
		if [ {input.clean} != {input.ORF} ]; then
		{params.workspace}/utils/Transrate/transrate --assembly {input.ORF} --left {input.left} --right {input.right} --output {params.outdir}/TRun_ORF  --threads {threads}
		fi
		# The final assembly is created here. 
		{params.workspace}/utils/Transrate/transrate --assembly {input.final} --left {input.left} --right {input.right} --output {params.outdir}/TRun_PostBellerophon --threads {threads}
		final_basename=$(basename {input.final} .fasta)
		cp {params.outdir}/TRun_PostBellerophon/$final_basename/good.$final_basename.fasta {output}
		"""

# Rule Busco runs BUSCO on the clean and final assemblies.
# The parameter buscoset can be altered to the name of a different busco set,
# this set should be a directory in the /utils/ folder.
rule BUSCO:
	input:
		clean=config["assembly"],
		final="{}/{}_BEL.fasta".format(config["outdir"], config["basename"])
	output:
		report_clean="{}/busco_report_clean.txt".format(config["outdir"]),
		report_final="{}/busco_report_final.txt".format(config["outdir"])
	params:
		workspace=".",
		buscoset="BUSCO_insects9", 
		outdir=config["outdir"],
		clean="clean_Busco",
		final="final_Busco"
	shell:
		"""
		python {params.workspace}/utils/BUSCO.py -i {input.clean} -o {params.clean} -m tran -l {params.workspace}/utils/{params.buscoset} -f
		python {params.workspace}/utils/BUSCO.py -i {input.final} -o {params.final} -m tran -l {params.workspace}/utils/{params.buscoset} -f
		cp run_{params.clean}/short_summary_{params.clean}.txt {output.report_clean}
		cp run_{params.final}/short_summary_{params.final}.txt {output.report_final}
		mv run_{params.clean} {params.outdir}
		mv run_{params.final} {params.outdir}

		"""





