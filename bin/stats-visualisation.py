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

##### Figure 1 : Top-50-Genes-Count

plt.figure(figsize=(10, 6), dpi=400)
ax = GroubByGene.head(50).plot(kind='bar', color='skyblue', edgecolor='black')

plt.title('Top 50 Genes Count', fontsize=16)
plt.xlabel('Genes', fontsize=14)
plt.ylabel('Genes Count', fontsize=14)
plt.xticks(rotation=45, ha='right')

# Add numbers inside bars
for p in ax.patches:
    ax.annotate(f"{int(p.get_height())}", (p.get_x() + p.get_width() / 2., p.get_height() / 2),
                ha='center', va='center', fontsize=10, color='black')

plt.tight_layout()
top_50_genes_path = os.path.join(output_dir, 'Top_50_genes_count.png')
plt.savefig(top_50_genes_path)
print(f"Figure saved: '{top_50_genes_path}'")
plt.show()

##### Figure 2 : Genes-Count-by-Species

plt.figure(figsize=(10, 6), dpi=400)
ax = gene_counts.plot(kind='bar', color='skyblue', edgecolor='black')

plt.title('Genes Count by Species', fontsize=16)
plt.xlabel('Species', fontsize=14)
plt.ylabel('Number of Genes', fontsize=14)
plt.xticks(rotation=45, ha='right')

# Add numbers above bars
for p in ax.patches:
    ax.annotate(f"{int(p.get_height())}", (p.get_x() + p.get_width() / 2., p.get_height() + 1),
                ha='center', va='bottom', fontsize=10, color='black')

plt.tight_layout()
gene_counts_by_species_path = os.path.join(output_dir, 'Genes_count_by_species.png')
plt.savefig(gene_counts_by_species_path)
print(f"Figure saved: '{gene_counts_by_species_path}'")
plt.show()

##### Figure 3: Top10-Species-Genes-Count

plt.figure(figsize=(10, 6), dpi=400)
plt.title('Top 10 Species Genes Count', fontsize=16)

top_species = gene_counts.sort_values(ascending=False).head(10)
ax = top_species.plot(kind='bar', color='skyblue', edgecolor='black')

plt.ylabel('Number of Genes', fontsize=14)

# Add numbers inside bars
for p in ax.patches:
    ax.annotate(f"{int(p.get_height())}", (p.get_x() + p.get_width() / 2., p.get_height() / 2),
                ha='center', va='center', fontsize=10, color='black')

plt.tight_layout()
top_10_species_genes_path = os.path.join(output_dir, 'Top_10_Species_Genes_Count.png')
plt.savefig(top_10_species_genes_path)
print(f"Figure saved: '{top_10_species_genes_path}'")
plt.show()

############## Summary ################

print(f"Total number Genes: {len(Species_Genes)} gene")
print(f"Total number of Unique Genes: {Species_Genes['Gene'].nunique()} gene")

Total_Number_of_species = Species_Genes[["Species"]].nunique().iloc[0]
print(f"Total number of Species: {Total_Number_of_species}")

species_gene_counts = Species_Genes.groupby('Species')['Gene'].nunique().sort_values(ascending=False)

print(f"'{species_gene_counts.index[0]}' is the Species with the most number of genes: {species_gene_counts.iloc[0]} gene")
print(f"'{species_gene_counts.index[-1]}' is the Species with the lowest number of genes: {species_gene_counts.iloc[-1]} gene")

gene_species_counts = Species_Genes.groupby('Gene')['Species'].nunique()
print(f"Number of Unique Genes Common across all Species: {gene_species_counts[gene_species_counts == Total_Number_of_species].size} gene")

# Save csv file: Table Genes Found In All Species
Result_Merge_innerJoin = (pd.merge(Species_Genes, gene_species_counts[gene_species_counts == Total_Number_of_species], on='Gene', how='inner')[['Gene', 'Species_x']])
Result_Merge_innerJoin = Result_Merge_innerJoin.rename(columns={'Species_x': 'Species'})
result_Table = pd.crosstab(Result_Merge_innerJoin['Gene'], Result_Merge_innerJoin['Species'])
all_species_table_path = os.path.join(output_dir, 'Table_Genes_Count_Found_In_All_Species.csv')
print("... Saving csv Table Genes Found Across All Species")
result_Table.to_csv(all_species_table_path, index_label='Gene')

# Save csv file: Table Genes Found In One Species Only
Result_Merge_innerJoin = (pd.merge(Species_Genes, gene_species_counts[gene_species_counts == 1], on='Gene', how='inner')[['Gene', 'Species_x']])
Result_Merge_innerJoin = Result_Merge_innerJoin.rename(columns={'Species_x': 'Species'})
result_Table = pd.crosstab(Result_Merge_innerJoin['Gene'], Result_Merge_innerJoin['Species'])
one_species_table_path = os.path.join(output_dir, 'Table_Genes_Count_Found_In_One_Species_Only.csv')
print("... Saving csv Table Genes Found In One Species Only")
result_Table.to_csv(one_species_table_path, index_label='Gene')