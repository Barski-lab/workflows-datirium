#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)


suppressMessages(library(argparse))
suppressMessages(library(GeneOverlap))


get_file_type <- function (filename) {
    ext = tools::file_ext(filename)
    separator = ","
    if (ext == "tsv"){
        separator = "\t"
    }
    return (separator)
}


load_data_set <- function(input_file) {
    data_set <- read.table(input_file, sep=get_file_type(input_file), header=TRUE, stringsAsFactors=FALSE)
    data_list <- lapply(as.list(data_set), function(x) x[x != ""])
    return (data_list)
}


get_args <- function(){
    parser <- ArgumentParser(description='Build gene overlap heatmap usings Fisher’s exact test to find the statistical significance')
    parser$add_argument("--generows",     help="TSV/CSV file with genes to display heatmap rows. Usually ChIP-Seq genes. Vertical orientation", type="character", required="True")
    parser$add_argument("--genecols",     help="TSV/CSV file with genes to display heatmap cols. Usually RNA-Seq genes. Vertical orientation", type="character", required="True")
    parser$add_argument("--genecount",    help="Number of genes in the genome", type="integer", required="True")
    parser$add_argument("--output",       help='Output filename. Default: gene_overlap_heatmap.png', type="character", default="./gene_overlap_heatmap.png")
    args <- parser$parse_args(commandArgs(trailingOnly = TRUE))
    return (args)
}


args <- get_args()
png(filename=args$output, width=800, height=800)

rows_data = load_data_set(args$generows)
cols_data = load_data_set(args$genecols)

gene_overlap <- newGOM(rows_data, cols_data, args$genecount)
drawHeatmap(gene_overlap)
