#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <FASTA_FILE> <PFAM_HMM_DB> <OUTPUT_FILE>"
    exit 1
fi

# Assign arguments to variables
FASTA_FILE="$1"
PFAM_HMM_DB="$2"
OUTPUT_FILE="$3"

# Run hmmscan
hmmscan --cpu 28 --domtblout "$OUTPUT_FILE" "$PFAM_HMM_DB" "$FASTA_FILE"

# Note:
# --cpu 28: Use 28 CPU cores (adjust this based on your system's CPU count)
# --domtblout: Save domain table output to a file
# $PFAM_HMM_DB: Path to the Pfam HMM database file
# $FASTA_FILE: Path to your input FASTA file

