import os

def add_gca_to_header(fasta_file):
    """
    Modifies the header of a FASTA file by appending the GCA part of the filename.
    
    Args:
        fasta_file (str): Path to the input FASTA file.
    """
    try:
        # Extract GCA part from the filename (before the first dot)
        gca_part = os.path.basename(fasta_file).split('.')[0]

        # Open input and output files
        with open(fasta_file, 'r') as infile, open(f"{fasta_file[:-4]}_modified.fasta", 'w') as outfile:
            for line in infile:
                if line.startswith('>'):
                    header_parts = line.strip().split(' ')
                    header = header_parts[0]  # Keep header (first part)
                    description = ' '.join(header_parts[1:])  # Keep rest as description
                    # Modify header: Append GCA part and remove any ".1PROKKA"
                    new_header = f"{header}.{gca_part} {description}"
                    outfile.write(new_header + '\n')
                else:
                    outfile.write(line)
    except Exception as e:
        print(f"Error processing {fasta_file}: {e}")

def process_fasta_files(directory):
    """
    Processes all FASTA files in a directory, adding the GCA part to each header.
    
    Args:
        directory (str): Directory containing the FASTA files.
    """
    try:
        for filename in os.listdir(directory):
            if filename.endswith(".faa"):  # Only process .faa files
                fasta_file = os.path.join(directory, filename)
                print(f"Processing {fasta_file}")
                add_gca_to_header(fasta_file)
    except Exception as e:
        print(f"Error processing directory {directory}: {e}")

if __name__ == "__main__":
    # Customize the directory containing FASTA files
    fasta_directory = './'  # Replace with your directory path

    # Step 1: Modify the headers of all FASTA files
    process_fasta_files(fasta_directory)
    
    # Step 2: Merge all modified FASTA files
    os.system("cat *_modified.fasta > merged_dataset.fasta")
    
    # Step 3: Run MMseqs easy-linclust on the merged dataset
    # You can adjust parameters as needed, such as --min-seq-id and --cov-mode
    os.system("mmseqs easy-linclust merged_dataset.fasta clusterRes tmp --min-seq-id 0.8 --cov-mode 1")
