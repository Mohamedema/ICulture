import pandas as pd

# Step 1: Initial DataFrame construction
input_file = './linclust_80c_80i_cluster.tsv'
df = pd.read_csv(input_file, sep='\t', header=None, names=['Name1', 'Name2'])

print("Original DataFrame:")
print(df.head())

# Step 2: Extract species and gene information
# Split `Name1` and `Name2` to extract species and gene information separately
df['Species1'] = df['Name1'].str.split('_').str[0]  # Extract species from Name1
df['Gene1'] = df['Name1'].str.split('_prot_').str[-1]    # Extract gene identifier from Name1
df['Species2'] = df['Name2'].str.split('_').str[0]  # Extract species from Name2
df['Gene2'] = df['Name2'].str.split('_prot_').str[-1]    # Extract gene identifier from Name2


print("\nDataFrame with Species and Gene columns extracted:")
print(df.head())

# Combine species-gene pairs
species_gene_pairs = pd.concat([
    df[['Species1', 'Gene1']].rename(columns={'Species1': 'Species', 'Gene1': 'Gene'}),
    df[['Species2', 'Gene2']].rename(columns={'Species2': 'Species', 'Gene2': 'Gene'})
])

print("\nCombined Species-Gene Pairs:")
print(species_gene_pairs.drop_duplicates().head())

# Step 3: Create the presence-absence matrix
# Get unique species and genes
unique_species = species_gene_pairs['Species'].unique()
unique_genes = species_gene_pairs['Gene'].unique()

print("\nUnique Species:")
print(unique_species)
print("\nUnique Genes:")
print(unique_genes)

# Initialize an empty DataFrame for the presence-absence matrix
presence_df = pd.DataFrame(0, index=unique_genes, columns=unique_species)

# Fill the DataFrame with 1s where the gene is present in a species
for _, row in species_gene_pairs.drop_duplicates().iterrows():
    presence_df.at[row['Gene'], row['Species']] = 1

print("\nPresence-Absence Matrix (Partial):")
print(presence_df.head())

# Step 4: Save the final result into a file
output_file = './linclust_80.txt'
presence_df.to_csv(output_file, sep='\t')

print(f"\nThe merged result has been saved to {output_file}")

