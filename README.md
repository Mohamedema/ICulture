# iCulture Parallelised and Dockerized Workflow

This repository hosts the **iCulture pipeline**, a fully automated, parallelised and Dockerized solution for the analysis of protein sequences. The pipeline enables efficient clustering, domain annotation, and statistical analysis of datasets, with built-in reproducibility using Docker containers.

---

## Pipeline Overview

1. **Preprocessing and Clustering**  
   - The pipeline begins by clustering sequences using **MMseqs2 easy-linclust** for deduplication and grouping similar sequences.
   - This step generates representative sequences and cluster files based on user-defined thresholds for identity and coverage.

2. **Domain Annotation**  
   - Representative sequences are annotated using **HMMER** with the **Pfam-A.hmm** database. 
   - Sequences are split into smaller chunks for parallel processing using **GNU parallel**, dramatically improving runtime for large datasets.

3. **Statistical Analysis and Visualization**  
   - Parsed annotation results are used to generate:
     - Statistics on total and unique genes.
     - Gene distribution across species.
     - Presence/absence matrices for species and genes.
   - Visualizations include:
     - Top genes counts.
     - Gene counts by species.
     - Distribution of common genes across species.

4. **Output**
   - Results include tables and visualizations saved in user-specified output directories.

---

## How to Acquire and Use Docker Images

### 1. MMseqs2 Docker Image
- **Required for clustering in step 1.**
- Acquire from [MMseqs2 Docker Hub](https://hub.docker.com/r/soedinglab/mmseqs2) using:  
  ```bash
  docker pull soedinglab/mmseqs2

### 2. iCulture HMMER + Python Image

The iCulture HMMER + Python Docker image is prebuilt for annotation, visualization, and statistical analysis in steps 2 and 3 of the pipeline. It includes:

- **HMMER (v3.9)** for domain annotation.
- **SeqKit (v2.9)** for sequence splitting.
- **Python (v3.9)** with necessary libraries such as Biopython, Matplotlib, and Pandas.

#### Acquire the Image
You can pull the prebuilt image from Docker Hub using the following command:
```bash
docker pull mahmoudbassyouni/iculture-hmmscan-python:v1
```
**For more information on how to install Docker, if you don't have it, visit here**: [Docker Website](https://docs.docker.com/engine/install/)

---
## Datasets

The main dataset for the pipeline is the **Brown Algae dataset**, sourced from the [Phaeoexplorer Project](https://phycoweb.net/). Due to size constraints, the dataset is hosted externally and can be downloaded from **Zenodo**:

- **Dataset Download Link:**  
  [Brown-Algae Dataset](https://zenodo.org/records/14578162/files/Brown-Algae.dataset.tar.gz?download=1)

### Instructions for Downloading and Extracting
To include the dataset in your workflow, download and extract it into a `dataset/` folder within the root directory of the cloned repository:

```bash
wget -O Brown-Algae.dataset.tar.gz https://zenodo.org/records/14578162/files/Brown-Algae.dataset.tar.gz?download=1
mkdir dataset
tar -xzvf Brown-Algae.dataset.tar.gz -C dataset/
```
Once extracted, the dataset/ folder will contain the necessary FASTA and HMMER files for pipeline execution.

---
## Test Species

The repository includes two test species, which are subsets of the Brown Algae dataset, used to test and validate the reproducibility of the pipeline. These species are included in the `test-species/` folder and are provided as example input data for the pipeline.

### Included Test Species
1. **Sphaerotrichia firma**
2. **Sphacelaria rigidula**

### Usage
These test species can be replaced with any other FASTA files if you wish to run the pipeline on a different dataset. Ensure that the new FASTA files are correctly referenced in the `samplesheet.csv` file, which defines the species and their respective input files.

### Additional Notes
To facilitate the creation of a `samplesheet.csv` file for the input data, use the `bin/samplesheet-generator.sh` script. Similarly, thresholds for clustering can be defined using the `bin/thresholds-generator.sh` script.

---
## Usage Instructions

Follow these steps to run the pipeline:

### 1. Clone the Repository
```bash
git clone https://github.com/Mohamedema/ICulture.git
cd ICulture
```
### 2. Download the Dataset
The dataset is hosted on Zenodo and can be downloaded using the link below:
  [Download Brown Algae Dataset](https://zenodo.org/records/14578162/files/Brown-Algae.dataset.tar.gz?download=1)

Extract the dataset into your working directory:
```bash
mkdir dataset
tar -xvzf Brown-Algae.dataset.tar.gz -C dataset
```
### 3. Pull Required Docker Images
1.Pull the iCulture HMMER + Python image:
```bash
docker pull mahmoudbassyouni/iculture-hmmscan-python:v1
```
2.Pull the MMseqs2 image from Docker Hub:
```bash
docker pull soedinglab/mmseqs2
```
4. Generate Required Input Files
- Generate samplesheet.csv:
```bash
./bin/samplesheet-generator.sh
```
- Generate thresholds.csv:
```bash
./bin/thresholds-generator.sh
```
5. Run the Pipeline
Run the main pipeline script with the required inputs:
```bash
./bin/iculture-pipeline-parallel.sh -d dataset/brown-algae_dataset.fa \
                                    -s samplesheet.csv \
                                    -h thresholds.csv \
                                    -p dataset/Pfam-A.hmm \
                                    -o results/ \
                                    -t 30 -m 24
```
6. View Results
- Output files, tables, and visualizations are stored in the results/ directory.
---
## Pipeline Parameters

The pipeline script accepts the following parameters:

### Required Parameters
1. **`-d <database_fasta_file>`**  
   Path to the main database FASTA file containing reference sequences.

2. **`-s <sample_sheet_csv>`**  
   Path to the CSV file containing species names and their corresponding protein FASTA file paths.  
   **Format:** species_name,protein_fasta_path
3. **`-h <thresholds_csv>`**  
Path to the CSV file specifying identity and coverage thresholds for clustering.  
**Format:**  Identity,Coverage
4. **`-p <pfam_hmm_db>`**  
Path to the Pfam HMM database file, which will be used for HMMER annotation.

5. **`-o <output_directory>`**  
Path to the directory where output files will be saved.

### Optional Parameters
1. **`-t <hmmer_threads>`**  
Number of threads for HMMER annotation using GNU Parallel.  
**Default:** 4  

2. **`-m <mmseqs_threads>`**  
Number of threads for MMseqs easy-linclust.  
**Default:** 32

	•	Make sure all input files (e.g., Pfam-A.hmm) are correctly formatted and paths are accurate.
   
---
## Acknowledgments
This pipeline was developed as part of the **iCulture Project** to facilitate the reproducible analysis of protein sequences in brown algae datasets. It leverages tools like **MMseqs2**, **HMMER**, and **Python** for scalable bioinformatics workflows.
