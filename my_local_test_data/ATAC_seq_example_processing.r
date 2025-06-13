# Specify the directory containing peak and BAM files
peak_directory <- "/scratch/pavb5f/AFOS_ATAC_seq_samples/raw_peaks/"
bam_directory <- "/scratch/pavb5f/AFOS_ATAC_seq_samples/bams/"

with_interaction <- TRUE

# List all peak files
peak_files <- fs::dir_ls(peak_directory, regexp = "\\.csv$")

# Function to parse file names and extract metadata
# Improved function to parse filenames and extract metadata robustly
parse_filename <- function(filename) {
  base_filename <- str_remove(basename(filename), "\\..*$") # More robust extension removal
  
  # Pattern matching needs to cover all expected filename variations
  donor <- base_filename %>%
    str_extract("^[a-zA-Z0-9].") %>%   # Extracts "A1"
    str_remove("^[a-zA-Z]+")          # Removes "A", resulting in "1"
  
  # Extract cell type; examples need to be adjusted based on actual patterns
  celltype <- case_when(
    str_detect(base_filename, "TCM") ~ "TCM",
    str_detect(base_filename, "TEM") ~ "TEM",
    str_detect(base_filename, "N") ~ "N" # Ensuring 'n' stands alone
  )
  
  # Condition extraction with clear boundaries
  condition <- case_when(
    str_detect(base_filename, "0H_GFP") ~ "0H_GFP",
    str_detect(base_filename, "5H_GFP") ~ "5H_GFP",
    str_detect(base_filename, "5H_AFOS") ~ "5H_AFOS"
  )
  
  bam_file <- fs::path(bam_directory, str_replace(basename(filename), "csv", "bam"))
  
  sample_name <- tolower(paste("D", donor, celltype, str_remove(condition, "_"), sep = ""))
  
  list(
    Replicate = donor,
    Tissue = celltype,
    Condition = condition,
    bamReads = bam_file,
    SampleID = sample_name
  )
}

# Apply function to all peak files and create a dataframe
sample_data <- lapply(peak_files, parse_filename)
samples_info <- do.call(rbind.data.frame, sample_data)
samples_info$Peaks <- rownames(samples_info)
rownames(samples_info) <- NULL

if (with_interaction) {
  samples_info <- samples_info[c("SampleID",
                                 "Condition",
                                 "Tissue",
                                 "Replicate",
                                 "bamReads",
                                 "Peaks")]
} else {
  samples_info$Condition <- paste(samples_info$Tissue, samples_info$Condition, sep = "_")
  samples_info <- samples_info[c("SampleID", "Condition", "Replicate", "bamReads", "Peaks")]
}


correct_colnames <- c(
  "chr",
  "start",
  "end",
  "length",
  "abs_summit",
  "pileup",
  "log10_pvalue",
  "fold_enrichment",
  "log10_qvalue"
)

clean_peaks_dir <- "/scratch/pavb5f/AFOS_ATAC_seq_samples/cleaned_peaks"

# Recreate the destination directory
if (fs::dir_exists(clean_peaks_dir)) {
  fs::dir_delete(clean_peaks_dir)
}
fs::dir_create(clean_peaks_dir)

# Create a DiffBind data structure
# Apply the function to each peak file
samples_info$Peaks <- sapply(samples_info$Peaks, function(file) {
  # browser()
  # Read the CSV file with appropriate parameters
  data <- read.csv(
    file,
    skip = 24,
    sep = "\t",
    header = TRUE,
    stringsAsFactors = FALSE
  )
  
  # Assign new column names
  names(data) <- correct_colnames
  
  # Ensure 'pileup' (or appropriate column) is numeric
  data$pileup <- as.numeric(as.character(data$pileup))
  
  # Construct the new filename:
  # 1. Extract the base filename without extension
  base_name <- file_path_sans_ext(basename(file))
  
  # 2. Create the cleaned filename with the new directory
  cleaned_file <- file.path(clean_peaks_dir, paste0(base_name, "_cleaned.csv"))
  
  # Write the cleaned data to the new CSV file
  write.csv(data, cleaned_file, row.names = FALSE)
  
  # Return the path to the cleaned file
  cleaned_file
})
#
# cleaned_files <- dir_ls(peak_directory, regexp = "_cleaned\\.csv$")
# fs::file_move(cleaned_files, path(clean_peaks_dir, basename(cleaned_files)))
#
# samples_info$Peaks <- fs::path(clean_peaks_dir, basename(samples_info$Peaks))

samples_info$bamReads <- str_remove(samples_info$bamReads, "_macs_peaks")


# samples_df <- samples_info
# samples_df <- samples_df[order(samples_df$Tissue,
#                                samples_df$Condition,
#                                samples_df$Replicate), ]

# as.numeric(rownames(samples_df))

desired_order <- as.numeric(
  c(
    1L,
    10L,
    19L,
    2L,
    11L,
    20L,
    3L,
    12L,
    21L,
    4L,
    13L,
    22L,
    5L,
    14L,
    23L,
    6L,
    15L,
    24L,
    7L,
    16L,
    25L,
    8L,
    17L,
    26L,
    9L,
    18L,
    27L
  )
)
samples_info <- samples_info[desired_order, ]
rownames(samples_info) <- 1:27

dba_data <- dba(
  sampleSheet = samples_info,
  peakFormat = "csv",
  peakCaller = "macs",
  scoreCol = 6
  # skipLines = 24
)

# Step 2: Derive consensus peaks by condition (requiring a peak in at least 2 samples)
# dba_consensus <- dba.peakset(dba_data, consensus = DBA_CONDITION, minOverlap = 2)
# or 3
dba_consensus <- dba.peakset(dba_data, consensus = DBA_CONDITION, minOverlap = 3)

dba_consensus <- dba(dba_consensus,
                     mask = dba_consensus$masks$Consensus,
                     minOverlap = 1)

consensus_peaks <- dba.peakset(dba_consensus, bRetrieve = TRUE, minOverlap = 1)

# Step 3: Reinitialize the dba object using the consensus mask.
# Here, we use the consensus mask (consensus$masks$Consensus) and reapply the minOverlap threshold (from args, if desired)

# Calculate peaks
dba_data <- dba.count(dba_data, peaks = consensus_peaks, minOverlap = 1)

# Perform the differential analysis using DESeq2
if (with_interaction) {
  dba_data <- dba.analyze(dba_data, method = DBA_DESEQ2, design = "~Condition*Tissue + Replicate")
} else {
  dba_data <- dba.analyze(dba_data, method = DBA_DESEQ2, design = "~Condition + Replicate")
}

dba.show(dba_data, bContrasts = TRUE)

if (!fs::dir_exists("Results/ATAC_seq")) {
  fs::dir_create("Results/ATAC_seq")
}

if (with_interaction) {
  saveRDS(dba_data,
          "Results/ATAC_seq/dba_data_deseq2_interaction.RDS")
} else {
  saveRDS(dba_data, "Results/ATAC_seq/dba_data_deseq2.RDS")
}
#
# count_reads <- function(bam_file) {
#   cmd <- paste("samtools view -c", bam_file)
#   read_count <- as.numeric(system(cmd, intern = TRUE))
#   return(read_count)
# }
#
# # Calculate the total amount of reads for each sample
# samples_info$TotalReads <- sapply(samples_info$bamReads, count_reads)
#
# # Display the dataframe with the new column
# read_count <- samples_info %>%
#   select(SampleID, TotalReads) %>%
#   rename(Sample = SampleID, Count = TotalReads) %>%
#   mutate(Sample = toupper(Sample))
#
# read_count <- read_count %>%
#   mutate(
#     Donor = factor(str_extract(Sample, "^D[0-9]+")),
#     CellType = factor(str_extract(Sample, "N|TCM|TEM")),
#     Condition = factor(str_extract(Sample, "0HGFP|5HGFP|5HAFOS"))
#   ) %>%
#   mutate(Condition = fct_relevel(factor(Condition), "0HGFP", "5HGFP", "5HAFOS")) %>%
#   dplyr::as_tibble() %>%
#   dplyr::arrange(CellType, Condition, Donor) %>%
#   tidyr::pivot_longer(cols = c(Count),
#                       names_to = "Statistic",
#                       values_to = "Count")
#
# stat_barchart <- ggplot(read_count, aes(x = interaction(Donor, Condition, CellType), y = Count)) +
#   geom_col(position = "dodge", fill = "blue") +
#   # facet_wrap(~CellType, scales = "free_x") +
#   labs(title = "Mapped Reads and Reads in Transcriptome by Sample",
#        x = "Sample",
#        y = "Count",
#        fill = "Statistic") +
#   theme_classic() +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1))
#
# ggsave(
#   "/scratch/pavb5f/AFOS_ATAC_seq_samples/Total_reads_barchart.png",
#   stat_barchart,
#   dpi = 400,
#   height = 3,
#   width = 10,
#   units = "in"
# )


dba_data_interaction <- readRDS("Results/ATAC_seq/dba_data_deseq2_interaction.RDS")
dba_data_interaction <- dba.count(dba_data_interaction, peaks = NULL, score = DBA_SCORE_RPKM)
# source("Scripts/Custom_theme.R")

dds <- dba_data_interaction$DESeq2$DEdata
dds <- DESeq(dds, test = "LRT", reduced = ~1)

fdr_threshold = 0.001

# TEM
dds_lrt_res <-
  DESeq2::results(
    dds,
    alpha = fdr_threshold
  )

dds_res_df <- as_tibble(dds_lrt_res@listData) %>%
  mutate(
    RowNum = row_number(),
    padj = replace_na(padj, 1),
    signif = ifelse(padj < fdr_threshold, T, F)
  )

print(table(dds_res_df$signif))


significant_peaks <- which(dds_res_df$signif)

library(RColorBrewer)

# Define the RdBu palette with a high number of colors for smoothness
custom_palette <- colorRampPalette(rev(brewer.pal(n = 11, name = "RdBu")))(100)
# custom_palette <- colorRampPalette(c("blue", "white", "red"))(100)

as_tibble(dba_data_interaction$peaks[[7]]) %>%
  mutate(row_n = row_number()) %>%
  filter(start > 68160000, start < 68170000, seqnames == "chr12")
# IFNG coords: 68166454 68166854
# row_n: 90684

# If you want to ensure your DBA is counted properly:
interaction_peakset <- dba.peakset(dba_data_interaction, bRetrieve = TRUE)

# Columns 1-3 = CHR, START, END
# Columns 4+   = numeric data for each sample


# counts_mat <- dba_data_interaction$binding[, 4:ncol(dba_data_interaction$binding)]
# OR, but binding converts chr as it is so bc of the sorting logic Chr10 becomes Chr2 (like Chr1, Chr10 ... 1, 2)
counts_mat <- as.matrix(mcols(interaction_peakset))

# Give it row/col names
rownames(counts_mat) <- rownames(dba_data_interaction$binding)    # peak IDs
colnames(counts_mat) <- dba_data_interaction$samples$SampleID     # sample names

sub_counts <- counts_mat[significant_peaks, , drop = FALSE]

scale_min_max <- function(x,
                          min_range = -2,
                          max_range = 2) {
  min_val <- min(x)
  max_val <- max(x)
  scaled_x <-
    (x - min_val) / (max_val - min_val) * (max_range - min_range) + min_range
  return(scaled_x)
}

log2_sub_counts <- log2(sub_counts + 1)

scaled_sub_counts <-
  t(apply(
    log2_sub_counts,
    1,
    FUN = function(x) {
      scale_min_max(x)
    }
  ))

d <- dist(as.matrix(scaled_sub_counts))   # find distance matrix 
# Due to computational limitations
hc <- hclust(d)

# hopach_clusters <- hopach::hopach(scaled_sub_counts,
#                                   K = 3,
#                                   kmax = 7,
#                                   khigh = 7)

saveRDS(
  # hopach_clusters,
  hc,
  # "Results/ATAC_seq/LRT_DB_peaks_hopach_clustering_3_7.RDS"
  "Results/ATAC_seq/LRT_DB_peaks_hc_clustering.RDS"
)

## The way to the Hell bc of Chr10 -> Chr2 due to the wrong sorting logic:
## Do instead:
saveRDS(interaction_peakset[significant_peaks, ],
        "Results/ATAC_seq/LRT_DB_peaks_gainloss.RDS")


# Still have some differences between replicates so trying to get rid of it using limma
coldata <- select(dba_data_interaction$samples, SampleID, Condition, Tissue) %>%
  column_to_rownames("SampleID")

batch <- as.factor(dba_data_interaction$samples$Replicate)

design <- model.matrix(~ Condition + Tissue + Condition:Tissue, coldata)

limma_corrected_data <-
  removeBatchEffect(log2_sub_counts, batch = batch, design = design)

scaled_sub_counts_limma <-
  t(apply(
    limma_corrected_data,
    1,
    FUN = function(x) {
      scale_min_max(x)
    }
  ))

# hopach_clusters_limma <- hopach::hopach(scaled_sub_counts_limma,
#                                         K = 3,
#                                         kmax = 7,
#                                         khigh = 7)

d_limma <- dist(as.matrix(scaled_sub_counts_limma))   # find distance matrix 
# Due to computational limitations
hc_limma <- hclust(d_limma)

saveRDS(
  # hopach_clusters_limma,
  hc_limma,
  "Results/ATAC_seq/LRT_DB_peaks_hc_clustering_limma_corrected.RDS"
  # "Results/ATAC_seq/LRT_DB_peaks_hopach_clustering_limma_corrected_3_7.RDS"
)