#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)

suppressMessages(library(argparse))
suppressMessages(library(EnhancedVolcano))


get_file_type <- function (filename) {
    ext = tools::file_ext(filename)
    separator = ","
    if (ext == "tsv"){
        separator = "\t"
    }
    return (separator)
}


load_data_set <- function(input_file, gene_labels, cutoff, param, log2fc) {
    data_set <- read.table(input_file, sep=get_file_type(input_file), header=TRUE, stringsAsFactors=FALSE)
    labels = c()
    pointsize = c()
    if (!is.null(gene_labels)){
        for (i in 1:nrow(data_set)) {
            genes = unlist(strsplit(data_set[i,"Gene_id"], ","))
            intersected_genes = intersect(genes, gene_labels)
            # if (length(intersected_genes) == 0 || data_set[i,param] > cutoff || data_set[i,"Fold"] < log2fc ){
            if (length(intersected_genes) == 0 || data_set[i,param] > cutoff || (data_set[i,"Fold"] < log2fc & data_set[i,"Fold"] > -log2fc) ){
                data_set[i, "Gene_id"] = ""
                pointsize = c(pointsize, 0.01)
            } else {
                new_gene_id = paste(intersected_genes, collapse=", ")
                data_set[i, "Gene_id"] = new_gene_id
                labels = c(labels, new_gene_id)
                pointsize = c(pointsize, 2)
            }
        }
        print("Remove duplicate genes")
        small_data_set <- data_set[data_set["Gene_id"] != "",]
        for (i in 1:nrow(small_data_set)) {
            target_gene_id = small_data_set[i, "Gene_id"]
            if (target_gene_id != "" & nrow(small_data_set[small_data_set["Gene_id"] == target_gene_id,]) > 1){
                print(paste("Found duplicates for gene(s): ", target_gene_id, sep=""))
                fold_changes = small_data_set[small_data_set["Gene_id"] == target_gene_id, "Fold"]
                print(fold_changes)
                max_abs_fold_change = max(abs(fold_changes))
                print(paste ("Max Abs Fold Change: ", max_abs_fold_change, sep=""))
                small_data_set[small_data_set["Gene_id"] == target_gene_id & abs(small_data_set["Fold"]) < max_abs_fold_change, "Gene_id"] = ""
                data_set[data_set["Gene_id"] == target_gene_id & abs(data_set["Fold"]) < max_abs_fold_change, "Gene_id"] = ""
            }
        }
    }
    return(list(data_set=data_set, labels=labels, pointsize=pointsize))
}


assert_args <- function(args){
    if (args$usefdr){
        args$yparam <- "FDR"
        args$ylabel <- bquote(~-Log[10]~italic(FDR))
        args$legend = c("Not significant", "Log2FC", "FDR", "FDR and Log2FC")
    } else {
        args$yparam <- "p.value"
        args$ylabel <- bquote(~-Log[10]~italic(P))
        args$legend = c("Not significant", "Log2FC", "P", "P and Log2FC")
    }
    return (args)
}


build_volcano_plot <- function(){
    EnhancedVolcano(raw_data,
                    title = "TSLP treated vs Untreated",
                    subtitle = "E115, E132, E134, E135, E137",
                    lab = raw_data[,"Gene_id"],
                    selectLab=labels,
                    x = "Fold",
                    ylim=c(0,6),
                    xlim=c(-3.5,3.5),
                    FCcutoff = args$log2fc,
                    y = args$yparam,
                    ylab=args$ylabel,
                    pCutoff = args$pvalue,
                    legend=args$legend,
                    boxedlabels=TRUE,
                    transcriptLabSize=3,
                    colAlpha=0.5,
                    shape=c(20,20,20,19),
                    transcriptLabFace="bold",
                    transcriptPointSize=raw$pointsize,
                    # lengthConnectors=unit(0.001, 'npc'),
                    drawConnectors=TRUE,
                    widthConnectors=0.2,
                    endsConnectors="last",
                    typeConnectors="open")
}





get_args <- function(){
    parser <- ArgumentParser(description='Build volcano plot from combined diffbind and iaintersect report file')
    parser$add_argument("--input",        help='Combined not filtered iaintersect and diffbind report file', type="character", required="True")
    parser$add_argument("--pvalue",       help='Pvalue (or FDR) cutoff. Default: 0.05', type="double", default=0.05)
    parser$add_argument("--log2fc",       help='Log2FC cutoff. Default: 1',             type="double", default=1)
    parser$add_argument("--usefdr",       help='Use FDR instead of pvalue. Default: false', action='store_true')
    parser$add_argument("--genelist",     help='Display labels for genes from the file. Headerless, 1 gene per line', type="character")
    parser$add_argument("--resolution",   help='Output png file resolution. Default: 300 dpi', type="integer", default=300)
    parser$add_argument("--width",        help='Output png file width. Default: 2000 px', type="integer", default=2000)
    parser$add_argument("--height",       help='Output png file height. Default: 2500 px', type="integer", default=2500)
    parser$add_argument("--output",       help='Output rootname. Default: volcano_plot', type="character", default="./volcano_plot")
    args <- assert_args(parser$parse_args(commandArgs(trailingOnly = TRUE)))
    return (args)
}


args <- get_args()


gene_labels <- NULL
if(!is.null(args$genelist)){
    gene_labels <- as.factor(read.table(args$genelist, sep=get_file_type(args$genelist), header=FALSE, stringsAsFactors=FALSE)[,1])
}


raw = load_data_set(args$input, gene_labels, args$pvalue, args$yparam, args$log2fc)
raw_data = raw$data_set
labels = raw$labels


png(filename=paste(args$output, ".png", sep=""), width=args$width, height=args$height, res=args$resolution)
build_volcano_plot()
dev.off()

pdf(file=paste(args$output, ".pdf", sep=""), width=round(args$width/args$resolution), height=round(args$height/args$resolution))
build_volcano_plot()
dev.off()
