#!/bin/bash
set -e

# Function to display usage instructions
usage() {
    echo "Usage: pipeline.sh -d <database_fasta_file> -s <sample_sheet_csv> -h <thresholds_csv> -p <pfam_hmm_db> -o <output_directory> [-t <hmmer_threads>] [-m <mmseqs_threads>]"
    echo
    echo "Required Parameters:"
    echo "  -d <database_fasta_file>   Path to the main database FASTA file containing reference sequences."
    echo "  -s <sample_sheet_csv>      Path to the CSV file containing species names and their corresponding protein FASTA file paths."
    echo "                             Format: species_name,protein_fasta_path"
    echo "  -h <thresholds_csv>        Path to the CSV file specifying identity and coverage thresholds for clustering."
    echo "                             Format: Identity,Coverage"
    echo "  -p <pfam_hmm_db>           Path to the Pfam HMM database file."
    echo "  -o <output_directory>      Path to the directory where output files will be saved."
    echo
    echo "Optional Parameters:"
    echo "  -t <hmmer_threads>         Number of threads for hmmscan using GNU parallel (default: 4)."
    echo "  -m <mmseqs_threads>        Number of threads for MMseqs easy-linclust (default: 32)."
    echo
    echo "Example:"
    echo "  bash pipeline.sh -d database.fasta -s sample_sheet.csv -h thresholds.csv -p dataset/Pfam-A.hmm -o results/ -t 30 -m 16"
    exit 0
}

# Default values for threads
hmmer_threads=4
mmseqs_threads=32

# Check if the --help flag is present
if [[ "$1" == "--help" ]]; then
    usage
fi

# Parse command-line arguments
while getopts "d:s:h:p:o:t:m:" opt; do
    case "$opt" in
        d) database_fasta="$OPTARG" ;;
        s) sample_sheet="$OPTARG" ;;
        h) thresholds_csv="$OPTARG" ;;
        p) pfam_hmm_db="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        t) hmmer_threads="$OPTARG" ;;
        m) mmseqs_threads="$OPTARG" ;;
        *) usage ;;
    esac
done

# Validate that all required arguments are provided
if [ -z "$database_fasta" ] || [ -z "$sample_sheet" ] || [ -z "$thresholds_csv" ] || [ -z "$pfam_hmm_db" ] || [ -z "$output_dir" ]; then
    usage
fi

# Validate the input files and directories
if ! [ -f "$database_fasta" ]; then
    echo "Error: Database FASTA file '$database_fasta' does not exist."
    exit 1
fi

if [ ! -d "$output_dir" ]; then
    echo "Creating output directory: $output_dir"
    mkdir -p "$output_dir"
fi

if ! [ -f "$sample_sheet" ]; then
    echo "Error: Sample sheet CSV file '$sample_sheet' does not exist."
    exit 1
fi

if ! [ -f "$thresholds_csv" ]; then
    echo "Error: Thresholds CSV file '$thresholds_csv' does not exist."
    exit 1
fi

if ! [ -f "$pfam_hmm_db" ]; then
    echo "Error: Pfam HMM database file '$pfam_hmm_db' does not exist."
    exit 1
fi

# Define the directory containing scripts
script_dir=$(dirname "$0")

# Step 1: Run the first script
echo "Running the first script for clustering and preprocessing with $mmseqs_threads threads..."
bash "$script_dir/preprocessing-clustering.sh" -d "$database_fasta" -s "$sample_sheet" -h "$thresholds_csv" -o "$output_dir" -t "$mmseqs_threads"

if [ $? -ne 0 ]; then
    echo "Error: The first script failed."
    exit 1
fi
echo "Clustering is completed successfully."

# Step 2: Locate all cluster files in the output directory
cluster_files=$(find "$output_dir" -type f -name "linclust_*_cluster.tsv")
if [ -z "$cluster_files" ]; then
    echo "Error: No cluster files (linclust_*_cluster.tsv) found in the output directory."
    exit 1
fi

# Step 3: Run the Python script for each cluster file
for cluster_file in $cluster_files; do
    echo "Processing cluster file: $cluster_file"
    docker run --rm \
        -v "$(pwd):/workspace" \
        -w /workspace \
        iculture-hmmscan-python:latest \
        bash -c "python /workspace/bin/presence_absence_matrix.py $cluster_file"

    if [ $? -ne 0 ]; then
        echo "Error: The Python script failed for file $cluster_file."
        exit 1
    fi
done

# Step 4: Split the concatenated FASTA file
concat_fasta="${output_dir}/concatenated_protein.fasta"
split_dir="${output_dir}/split_fasta"

mkdir -p "$split_dir"

echo "Splitting the concatenated FASTA file into $hmmer_threads parts..."
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    iculture-hmmscan-python:latest \
    bash -c "seqkit split -p $hmmer_threads -O $split_dir $concat_fasta"

if [ $? -ne 0 ]; then
    echo "Error: Failed to split the FASTA file."
    exit 1
fi
echo "FASTA file split successfully into $split_dir."

# Step 5: Run hmmscan with GNU parallel
parallel_dir="${output_dir}/parallel_results"
mkdir -p "$parallel_dir"
echo "Running HMMER annotation in parallel using GNU parallel..."
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    iculture-hmmscan-python:latest \
    bash -c "parallel --tmpdir $parallel_dir --jobs $hmmer_threads 'hmmscan --tblout $parallel_dir/results_{/.}.tbl $pfam_hmm_db {}' ::: ${split_dir}/*.fasta"

if [ $? -ne 0 ]; then
    echo "Error: GNU parallel or HMMER annotation failed."
    exit 1
fi
echo "HMMER annotation completed successfully."

# Step 6: Combine results
output_combined="${output_dir}/combined_results_1_to_${hmmer_threads}.tbl"
echo "Combining results into a single file: $output_combined..."
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    iculture-hmmscan-python:latest \
    bash -c "
    head -n -10 ${parallel_dir}/results_concatenated_protein.part_001.tbl > $output_combined
    for i in \$(seq -f '%03g' 2 $hmmer_threads); do
        tail -n +4 ${parallel_dir}/results_concatenated_protein.part_\${i}.tbl | head -n -10 >> $output_combined
    done
    tail -n +4 ${parallel_dir}/results_concatenated_protein.part_\$(printf '%03d' $hmmer_threads).tbl >> $output_combined
"

if [ $? -ne 0 ]; then
    echo "Error: Failed to combine results."
    exit 1
fi
echo "All results combined successfully into $output_combined."

# Step 7: Run Stats Visualization Python Script
visualization_output_dir="${output_dir}/visualization_results"
mkdir -p "$visualization_output_dir"

echo "Running Stats Visualization Python Script..."
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    iculture-hmmscan-python:latest \
    bash -c "python /workspace/bin/stats-visualisation.py --input $output_combined  --output $visualization_output_dir"

if [ $? -ne 0 ]; then
    echo "Error: Stats Visualization Python script failed."
    exit 1
fi

echo "Stats Visualization completed successfully. Results saved in $visualization_output_dir."
echo "Pipeline completed successfully."
