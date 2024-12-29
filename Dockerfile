# Use an official Ubuntu base image
FROM ubuntu:20.04

# Add maintainer information as a label
LABEL maintainer="Mahmoud Bassyouni <mabdallah@ciimar.up.pt>"
LABEL description="Image for Python and HMMER tools for iCulture Project"

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update and install essential tools and libraries
RUN apt-get update && \
    apt-get install -y \
    wget \
    bzip2 \
    parallel \
    ca-certificates \
    curl \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /miniconda.sh && \
    bash /miniconda.sh -b -p /miniconda && \
    rm /miniconda.sh
ENV PATH="/miniconda/bin:${PATH}"

# Install Python >3.8 and HMMER using Conda
RUN conda update -y -n base -c defaults conda && \
    conda install -y python=3.9 pandas biopython scikit-learn matplotlib && \
    conda install -c bioconda hmmer && \
    conda install -c bioconda seqkit

# Set PATH for all installed tools
ENV PATH="/miniconda/bin:${PATH}"

# Set working directory
WORKDIR /workspace

# Make tools globally executable
RUN chmod +x /miniconda/bin/python /miniconda/bin/hmmscan

# Remove the problematic ENTRYPOINT
CMD ["/bin/bash"]
