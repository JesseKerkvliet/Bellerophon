# Bellerophon
Chimera removal pipeline

Bellerophon is a pipeline created to remove falsely assembled chimeric transcripts in de novo transcriptome assemblies.

## Installation with Vagrant VM
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


## Installation with conda
Bellerophon can also be installed locally. This is the preferred option for users without root permission and Vagrant, but with access to Conda.
The easies way for local installation is the use of Conda. 
After cloning this repository, run the following command to create the conda environment:
```
conda env create envs/Bellerophon.yml
```
After installation, run the following command to activate the conda environment:
```
conda activate Bellerophon
```

## Pending issues:
  - Custom order of filtering steps is disabled in this version
  - This document needs to be expanded
  
  


