import pandas as pd
import os
import sys

def generate_presence_absence_matrix(input_path):
    # Read the input file into a DataFrame
    df = pd.read_csv(input_path, sep='\t', header=None)
    
    # Extract species names by splitting on the '$' symbol
    df_species = df.applymap(lambda x: x.split('$')[0])
    
    # Get unique species names to create columns
    unique_species = sorted(df_species.values.flatten().tolist())
    unique_species = list(dict.fromkeys(unique_species))  # Remove duplicates while preserving order
    
    # Initialize the presence-absence matrix
    presence_absence_matrix = pd.DataFrame(0, index=df.index, columns=unique_species)
    
    # Fill in the matrix with presence (1) and absence (0)
    for i, row in df_species.iterrows():
        for species in row:
            if species in presence_absence_matrix.columns:
                presence_absence_matrix.at[i, species] = 1
    
    # Add the gene names as the first column
    gene_names = df.iloc[:, 0]  # Assuming the gene identifier is in the first column
    presence_absence_matrix.insert(0, 'Gene', gene_names)
    
    # Define the output path in the same directory as the input file
    output_path = os.path.join(os.path.dirname(input_path), "species_presence_absence_matrix.tsv")
    
    # Save the result to a TSV file
    presence_absence_matrix.to_csv(output_path, sep='\t', index=False)
    print(f"Presence-absence matrix saved to {output_path}")

# Usage:
if __name__ == "__main__":
    # Check if the input file path is provided
    if len(sys.argv) != 2:
        print("Usage: python presence_absence_matrix.py <input_file_path>")
        sys.exit(1)

    input_file_path = sys.argv[1]
    generate_presence_absence_matrix(input_file_path)

