#!/bin/bash

cap_data_download \
  "https://raw.githubusercontent.com/nf-core/test-datasets/rnaseq/samplesheet/samplesheet.csv"

cap_data_download \
  --unzip \
  "https://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.MT.fa.gz"
