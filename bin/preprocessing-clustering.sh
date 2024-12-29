#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: script.sh -d <database_fasta_file> -s <sample_sheet_csv> -h <thresholds_csv> -o <output_directory> [-t <threads>]"
    echo
    echo "Required Parameters:"
    echo "  -d <database_fasta_file>   Path to the main database FASTA file containing reference sequences."
    echo "  -s <sample_sheet_csv>      Path to the CSV file containing species names and their corresponding protein FASTA file paths."
    echo "                             Format: species_name,protein_fasta_path"
    echo "  -h <thresholds_csv>        Path to the CSV file specifying identity and coverage thresholds for clustering."
    echo "                             Format: Identity,Coverage"
    echo "  -o <output_directory>      Path to the directory where output files will be saved."
    echo
    echo "Optional Parameters:"
    echo "  -t <threads>               Number of threads for MMseqs easy-linclust (default: 8)."
    echo
    echo "Example:"
    echo "  bash script.sh -d database.fasta -s sample_sheet.csv -h thresholds.csv -o results/ -t 16"
    exit 0
}

# Default threads value
threads=8

# Parse command-line arguments
while getopts "d:s:h:o:t:" opt; do
    case "$opt" in
        d) database_fasta="$OPTARG" ;;
        s) sample_sheet="$OPTARG" ;;
        h) thresholds_csv="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        t) threads="$OPTARG" ;;
        *) usage ;;
    esac
done

# Validate that all required arguments are provided
if [ -z "$database_fasta" ] || [ -z "$sample_sheet" ] || [ -z "$thresholds_csv" ] || [ -z "$output_dir" ]; then
    usage
fi

# Validate the input files and directories
if ! [ -f "$database_fasta" ]; then
    echo "Error: Database FASTA file '$database_fasta' does not exist."
    exit 1
fi

if ! [ -f "$sample_sheet" ]; then
    echo "Error: Sample sheet CSV file '$sample_sheet' does not exist."
    exit 1
fi

if ! [ -f "$thresholds_csv" ]; then
    echo "Error: Thresholds CSV file '$thresholds_csv' does not exist."
    exit 1
fi

# Validate sample sheet entries
echo "Validating sample sheet file paths..."
while IFS=',' read -r species_name protein_fasta_path; do
    if [[ "$species_name" == "species_name" ]]; then
        continue
    fi

    # Convert relative paths to absolute
    if [[ ! "$protein_fasta_path" = /* ]]; then
        protein_fasta_path=$(realpath "$(dirname "$sample_sheet")/$protein_fasta_path")
    fi

    echo "Validating: $protein_fasta_path"

    if ! [ -f "$protein_fasta_path" ]; then
        echo "Error: FASTA file '$protein_fasta_path' does not exist. Stopping execution."
        exit 1
    fi
done < "$sample_sheet"

echo "All file paths in the sample sheet are valid."

# Create the output directory if it does not exist
mkdir -p "$output_dir"

# Temporary combined FASTA file
tmp_fasta="${output_dir}/tmp_combined.fasta"
> "$tmp_fasta"

# Read the sample sheet and process each line
while IFS=',' read -r species_name protein_fasta_path; do
    if [[ "$species_name" == "species_name" ]]; then
        continue
    fi
    modified_fasta="${output_dir}/modified_${species_name}.fasta"
    awk -v species="$species_name" '/^>/ {header=$0; protein_id=substr(header, 2); protein_id=substr(protein_id, 1, index(protein_id, " ") - 1); print ">" species "$" protein_id; next} {print}' "$protein_fasta_path" > "$modified_fasta"
    cat "$modified_fasta" >> "$tmp_fasta"
done < "$sample_sheet"

# Concatenate the database FASTA and the combined modified FASTA
input_fasta="${output_dir}/concatenated_protein.fasta"
cat "$database_fasta" "$tmp_fasta" > "$input_fasta"

# Temporary directory for MMseqs
tmp_dir="${output_dir}/tmp"

# Output file for the final table
output_file="${output_dir}/rep_seq_counts.tsv"
echo -e "Identity\tCoverage\tRepresentative_Count" > "$output_file"

# Read the thresholds CSV and process each combination
while IFS=',' read -r identity coverage; do
    if [[ "$identity" == "Identity" ]]; then
        continue
    fi
    decimal_id=$(awk "BEGIN {print $identity / 100}")
    decimal_cov=$(awk "BEGIN {print $coverage / 100}")
    combination_output_dir="${output_dir}/linclust_${identity}c_${coverage}i"
    docker run --rm \
        -v "$(pwd):/workspace" \
        -w /workspace \
        soedinglab/mmseqs2 \
        mmseqs easy-linclust "$input_fasta" "$combination_output_dir" "$tmp_dir" \
        --min-seq-id "$decimal_id" -c "$decimal_cov" --threads "$threads"
    rep_count=$(grep -c ">" "${combination_output_dir}_rep_seq.fasta" 2>/dev/null || echo "0")
    echo -e "${identity}\t${coverage}\t${rep_count}" >> "$output_file"
done < "$thresholds_csv"

rm -rf "$tmp_fasta" "${output_dir}/modified_*.fasta"
echo "Table with representative sequence counts has been saved to $output_file."
