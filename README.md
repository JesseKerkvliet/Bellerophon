# Bellerophon
Chimera removal pipeline

Bellerophon is a pipeline created to remove falsely assembled chimeric transcripts in de novo transcriptome assemblies.

## Installation
The pipeline can be downloaded as a vragrant virtual machine (https://app.vagrantup.com/bellerophon/boxes/bellerophon). This is recommended, as it avoids backwards compatibility problems with TransRate.


## Running with Vagrant
To run Bellerophon with Vagrant, download vagrant and virtualbox. 

Download the Bellerophon vagrantfile

Run the following command:
```
vagrant init
```
When it's done downloading run:
```
vagrant up
```
And finally:
```
vagrant ssh
```

You are now in the virtual environment to run Bellerophon.
Shared data can be found at /vagrant/

You can now run the test run of Bellerophon in the Bellerophon folder:
```
python Bellerophon.py --assembly Demo.fasta --left All_R1_1000.fastq --right All_R2_1000.fastq --outdir /vagrant/testrun
```
Note that Bellerophon will make an output directory in the /vagrant/ directory. This is recommended as the disk size of Bellerophon is not large enough for most full transcriptome analyses. It also makes the results of the analysis available on the host system, rather than only on the virtual machine.


## Installation
Bellerophon can also be installed locally.
To install, make sure the following tools are available:
- BLAST
- HMMER
- Bowtie2
- RSEM
- Samtools
- Snakemake
- Salmon (version 0.6.0)
- Boost library version 1.60.0 (Conda)

The key tool in this pipeline (TransRate) is not actively maintained. It is therefore dependent on an old version of Salmon.
To circumvent this incompatibility, make sure to:
- Install Salmon version 0.6.0 from Bioconda
- Install the conda Boost library version 1.60.0
- Go into the Bellerophon/utils/TransRate/bin directory
- Delete the Salmon file and replace it with a symbolic link to the installation location of salmon.

## Pending issues:
  - Custom order of filtering steps is disabled in this version
  - A script checking dependencies and testing the pipeline will be provided
  - This document needs to be expanded
  
  


