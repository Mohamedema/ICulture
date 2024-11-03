# ICulture pipeline
The pipeline  allows the creation of a sparse matrix from the algae proteome database fasta files, allowing for new species to be eventually introduced into the output table matrix

# Requirement

MMseqs2 

Python > 3.8

Python Pandas 

Algea Speices protein database

The first step is to create representative protein seq using 90 and 95 identity and coverage

# Usage: 
Iculture_WP3.sh <database_fasta_file> <new species protein_fasta_file> 

# The second step is to perform pfam annotation

Using annotate_pfam.sh request three argument 

Representitive sequence FASTA_FILE, PFAM_HMM_DB, the path for the OUTPUT_FILE

# The third step is to create the table using utilities_make_table.py

Please, change the name of the input file for this script to match first_step_output_name_mmseq_table




