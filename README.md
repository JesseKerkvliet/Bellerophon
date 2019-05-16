# Bellerophon
Chimera removal pipeline

Bellerophon is a pipeline created to remove falsely assembled chimeric transcripts in de novo transcriptome assemblies.

## Installation
The pipeline can be downloaded as a vragrant virtual machine. This is recommended, as it avoids backwards compatibility problems with TransRate.
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

Pending issues:
  - Custom order of filtering steps is disabled in this version
  - A script checking dependencies and testing the pipeline will be provided
  - This document needs to be expanded
  
  
