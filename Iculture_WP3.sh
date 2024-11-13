#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <database_fasta_file> <protein_fasta_file> <species_name>"
    exit 1
fi

# Input arguments
database_fasta="$1"
protein_fasta="$2"
species_name="$3"

# Modified protein FASTA file with species name in headers
modified_protein_fasta="modified_${protein_fasta}"

# Add species name to the headers in the protein FASTA file
awk -v species="$species_name" '/^>/ {print ">" species "$" substr($0, 2); next} {print}' "$protein_fasta" > "$modified_protein_fasta"

# Concatenated file
input_fasta="concatenated_protein.fasta"
cat "$database_fasta" "$modified_protein_fasta" > "$input_fasta"

# Temporary directory for MMseqs
tmp_dir="tmp"

# Output file for the final table
output_file="rep_seq_counts.tsv"

# Define identity and coverage thresholds as arrays
identities=(90 50)
coverages=(90 50)

# Write the header for the output table
echo -e "Identity\tCoverage\tRepresentative_Count" > "$output_file"

# Loop through each identity threshold
for id in "${identities[@]}"; do
    # Manually convert identity to decimal
    decimal_id=$(awk "BEGIN {print $id / 100}")
    
    # Loop through each coverage threshold
    for cov in "${coverages[@]}"; do
        # Manually convert coverage to decimal
        decimal_cov=$(awk "BEGIN {print $cov / 100}")

        # Define output directory for this combination
        output_dir="linclust_${id}c_${cov}i"

        # Debugging: print values to check if they are correct
        echo "Running MMseqs with identity=$decimal_id and coverage=$decimal_cov"

        # Run MMseqs clustering with the specified identity and coverage
        mmseqs easy-linclust "$input_fasta" "$output_dir" "$tmp_dir" --min-seq-id "$decimal_id" -c "$decimal_cov"

        # Count the representative sequences
        rep_count=$(grep -c ">" "${output_dir}_rep_seq.fasta")

        # Append the results to the output table
        echo -e "${id}\t${cov}\t${rep_count}" >> "$output_file"
    done
done

# Clean up temporary directory and modified protein FASTA file
rm -rf "$tmp_dir" "$modified_protein_fasta"

echo "Table with representative sequence counts has been saved to $output_file."
