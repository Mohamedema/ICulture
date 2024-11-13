# ICulture pipeline
The ICulture pipeline creates a sparse matrix from algae proteome database FASTA files, enabling the eventual addition of new species to the output table matrix.

# Requirement

MMseqs2 

Python > 3.8

Python Pandas 

Algae Species Protein Database

The first step is to generate representative protein sequences using 90% and 95% identity and coverage thresholds.

# Usage: 

# The first step is to perform MMSEQ easy cluster using 90 and 50
Iculture_WP3.sh <database_fasta_file> <protein_fasta_file> <species_name>"

# The second step is to perform pfam annotation

Use annotate_pfam.sh, which requires three arguments:

Representative Sequence FASTA File
Pfam HMM Database File
Output File Path

# The third step is to create the table using utilities_make_table.py

Run presence_absence_matrix.py to generate the final table. Ensure that the input file name for this script matches the output name of the MMseqs2 table from the first step.
example: python presence_absence_matrix.py ./linclust_80c_80i_cluster.tsv




