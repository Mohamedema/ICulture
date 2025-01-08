# -*- coding: utf-8 -*-

import os
import argparse
import pandas as pd
from Bio import SearchIO
import matplotlib.pyplot as plt

# Set up argument parsing
parser = argparse.ArgumentParser(description="Process HMMER output and generate summary files and plots.")
parser.add_argument('--input', required=True, help="Path to the input HMMER file")
parser.add_argument('--output', required=True, help="Directory to save the output files")

args = parser.parse_args()

# Input and output paths
file_path = args.input
output_dir = args.output

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

data = []

for query_result in SearchIO.parse(file_path, 'hmmer3-tab'):
    for hit in query_result:
        for hsp in hit.hsps:
            data.append({
                'Target_Name': hit.id,
                'Target_Accession': hit.accession,
                'Query_Name': query_result.id,
                'Query_Accession': query_result.accession,
                'Full_E-value': hsp.evalue,
                'Full_Score': hsp.bitscore,
                'Full_Bias': hsp.bias,
                'Exp': hit.domain_exp_num,
                'Description': hit.description
            })

df = pd.DataFrame(data)
parsed_csv_path = os.path.join(output_dir, 'Parsed_hmmscan_tbl.csv')
df.to_csv(parsed_csv_path, index=False)

df['Species_Query_Name'] = df['Query_Name'].str.split('$').str[0]
Species_Genes = pd.DataFrame({'Species': df['Species_Query_Name'], 'Gene': df['Target_Name']})

GroubByGene = Species_Genes.groupby('Gene').size().sort_values(ascending=False)
gene_counts = Species_Genes.groupby('Species')['Gene'].count()

###### Figure 1 : Top-20-Protein-Domains-Count

plt.figure(figsize=(10, 6), dpi=400)
ax = GroubByGene.head(20).plot(kind='bar', color='#1f77b4', edgecolor='black')

plt.title('Top 20 Protein Domains Count', fontsize=16, fontweight='bold')
plt.xlabel('Protein Domains', fontsize=14, fontweight='bold')
plt.ylabel('Count', fontsize=14, fontweight='bold')
plt.xticks(rotation=45, ha='right')
plt.grid(axis='x', linestyle='--', alpha=0.7)

# Add vertical numbers inside bars with styling
for p in ax.patches:
    ax.annotate(f"{int(p.get_height())}",
                (p.get_x() + p.get_width() / 2., p.get_height() / 2),
                ha='center', va='center', fontsize=10, color='white', fontweight='bold',
                rotation=90,  # Rotated for vertical orientation
                bbox=dict(facecolor='black', alpha=0.7, edgecolor='none'))

plt.tight_layout()
top_20_Protein_Domains_path = os.path.join(output_dir, 'Top_20_Protein_Domains_count.png')
plt.savefig(top_20_Protein_Domains_path)
print(f"Figure saved: '{top_20_Protein_Domains_path}'")
plt.show()

###### Figure 2 : Protein-Domains-Count-by-Species

plt.figure(figsize=(20, 14), dpi=300)
ax = gene_counts.plot(kind='bar', color='#ff7f0e', edgecolor='black')

plt.title('Protein Domains Count by Species', fontsize=16, fontweight='bold')
plt.xlabel('Species', fontsize=14, fontweight='bold')
plt.ylabel('Number of Protein Domains', fontsize=14, fontweight='bold')
plt.xticks(rotation=45, ha='right')
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Add vertical numbers inside bars with styling
for p in ax.patches:
    ax.annotate(f"{int(p.get_height())}",
                (p.get_x() + p.get_width() / 2., p.get_height() / 2),
                ha='center', va='center', fontsize=10, color='white', fontweight='bold',
                rotation=90,  # Rotated for vertical orientation
                bbox=dict(facecolor='black', alpha=0.7, edgecolor='none'))

plt.tight_layout()
Protein_Domains_counts_by_species_path = os.path.join(output_dir, 'Protein_Domains_count_by_species.png')
plt.savefig(Protein_Domains_counts_by_species_path)
print(f"Figure saved: '{Protein_Domains_counts_by_species_path}'")
plt.show()

##### Figure 3: Top10-Species-Protein-Domains-Count

plt.figure(figsize=(10, 6), dpi=400)
top_species = gene_counts.sort_values(ascending=False).head(10)
ax = top_species.plot(kind='bar', color='#2ca02c', edgecolor='black')

plt.title('Top 10 Species Protein Domains Count', fontsize=16, fontweight='bold')
plt.ylabel('Number of Protein Domains', fontsize=14, fontweight='bold')
plt.xticks(rotation=45, ha='right')

# Add vertical numbers inside bars with styling
for p in ax.patches:
    ax.annotate(f"{int(p.get_height())}",
                (p.get_x() + p.get_width() / 2., p.get_height() / 2),
                ha='center', va='center', fontsize=10, color='white', fontweight='bold',
                rotation=90,  # Rotated for vertical orientation
                bbox=dict(facecolor='black', alpha=0.7, edgecolor='none'))

plt.grid(axis='y', linestyle='--', alpha=0.5)
plt.tight_layout()
top_10_species_Protein_Domains_path = os.path.join(output_dir, 'Top_10_Species_Protein_Domains_Count.png')
plt.savefig(top_10_species_Protein_Domains_path)
print(f"Figure saved: '{top_10_species_Protein_Domains_path}'")
plt.show()

############## Summary ################

print(f"Total number Protein Domains: {len(Species_Genes)} Domain")
print(f"Total number of Unique Protein Domains: {Species_Genes['Gene'].nunique()} Domain")

Total_Number_of_species = Species_Genes[["Species"]].nunique().iloc[0]
print(f"Total number of Species: {Total_Number_of_species}")

species_gene_counts = Species_Genes.groupby('Species')['Gene'].nunique().sort_values(ascending=False)

print(f"'{species_gene_counts.index[0]}' is the Species with the most number of Protein Domains: {species_gene_counts.iloc[0]} Domain")
print(f"'{species_gene_counts.index[-1]}' is the Species with the lowest number of Protein Domains: {species_gene_counts.iloc[-1]} Domain")

gene_species_counts = Species_Genes.groupby('Gene')['Species'].nunique()
print(f"Number of Unique Protein Domains Common across all Species: {gene_species_counts[gene_species_counts == Total_Number_of_species].size} Domain")

# Save csv file: Table Protein Domains Found In All Species
Result_Merge_innerJoin = (pd.merge(Species_Genes, gene_species_counts[gene_species_counts == Total_Number_of_species], on='Gene', how='inner')[['Gene', 'Species_x']])
Result_Merge_innerJoin = Result_Merge_innerJoin.rename(columns={'Species_x': 'Species'})
result_Table = pd.crosstab(Result_Merge_innerJoin['Gene'], Result_Merge_innerJoin['Species'])
all_species_table_path = os.path.join(output_dir, 'Table_Protein_Domains_Count_Found_In_All_Species.csv')
print("... Saving csv Table Protein Domains Found Across All Species")
result_Table.to_csv(all_species_table_path, index_label='Gene')

# Save csv file: Table Protein Domains Found In One Species Only
Result_Merge_innerJoin = (pd.merge(Species_Genes, gene_species_counts[gene_species_counts == 1], on='Gene', how='inner')[['Gene', 'Species_x']])
Result_Merge_innerJoin = Result_Merge_innerJoin.rename(columns={'Species_x': 'Species'})
result_Table = pd.crosstab(Result_Merge_innerJoin['Gene'], Result_Merge_innerJoin['Species'])
one_species_table_path = os.path.join(output_dir, 'Table_Protein_Domains_Count_Found_In_One_Species_Only.csv')
print("... Saving csv Table Protein Domains Found In One Species Only")
result_Table.to_csv(one_species_table_path, index_label='Gene')