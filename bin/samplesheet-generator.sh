#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -i <input_directory> -o <output_csv>"
    echo
    echo "Required Parameters:"
    echo "  -i <input_directory>   Path to the directory containing subdirectories with _proteins.fa files."
    echo "  -o <output_csv>        Path to the output CSV file."
    echo
    echo "Example:"
    echo "  bash $0 -i data_directory -o sample_sheet.csv"
    exit 0
}

# Check for help flag
if [[ "$1" == "--help" ]]; then
    usage
fi

# Parse command-line arguments
while getopts "i:o:" opt; do
    case "$opt" in
        i) input_dir="$OPTARG" ;;
        o) output_csv="$OPTARG" ;;
        *) usage ;;
    esac
done

# Validate arguments
if [ -z "$input_dir" ] || [ -z "$output_csv" ]; then
    usage
fi

# Validate input directory
if ! [ -d "$input_dir" ]; then
    echo "Error: Input directory '$input_dir' does not exist."
    exit 1
fi

# Create or overwrite the output CSV file
echo "species_name,protein_fasta_path" > "$output_csv"

# Loop through subdirectories
find "$input_dir" -type f -name "*_proteins.fa" | while read -r fasta_file; do
    # Get the directory name (species name)
    species_name=$(basename "$(dirname "$fasta_file")")
    
    # Get the real path of the fasta file
    real_path=$(realpath "$fasta_file")
    
    # Add to the CSV
    echo "$species_name,$real_path" >> "$output_csv"
done

echo "Sample sheet has been saved to $output_csv"
