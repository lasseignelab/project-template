#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00

cap_data_download \
  "https://raw.githubusercontent.com/nf-core/test-datasets/rnaseq/samplesheet/samplesheet.csv"

cap_data_download \
  "https://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.MT.fa.gz"
