# Load necessary libraries
library(ggplot2)
library(viridis)  # for a fancy color scale

# Read in the data
rep_seq_data <- read.table("/home/labpc6c/Documents/Toby_and_me_data/red_phoexplorer/rep_seq_counts.tsv", header = TRUE, sep = "\t")

rep_seq_data <- read.table("/home/labpc6c/Documents/Toby_and_me_data/Phaeoexplorer_mmseq2/brown_rep_seq_counts.tsv", header = TRUE, sep = "\t")

# Convert Identity and Coverage columns to factors to maintain ordering in the plot
rep_seq_data$Identity <- as.factor(rep_seq_data$Identity)
rep_seq_data$Coverage <- as.factor(rep_seq_data$Coverage)

# Create a heatmap with text labels
ggplot(rep_seq_data, aes(x = Coverage, y = Identity, fill = Representative_Count)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Representative_Count), color = "white", fontface = "bold", size = 4) +  # Add count labels
  scale_fill_viridis(name = "Rep Seq Count", option = "magma", direction = -1) +  # Fancy color scheme
  labs(title = "Representative Sequence Counts for Brown Algae",
       x = "Coverage (%)", y = "Identity (%)") +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold")
  )

