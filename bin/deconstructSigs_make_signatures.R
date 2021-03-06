#!/usr/bin/env Rscript
args <- commandArgs(T)

sampleID <- args[1] # for labeling
tsv_file <- args[2] # input file
signatures_output_file <- args[3] # output data file .Rds
signatures_plot_pdf <- args[4] # output main plot file .pdf
signatures_plot_Rds <- args[5] # output main plot file .Rds
signatures_pie_plot_pdf <- args[6] # output pie plot file .pdf
signatures_pie_plot_Rds <- args[7] # output pie plot file .Rds
weights_tsv <- args[8]

message(sprintf("tsv_file: %s", tsv_file))
message(sprintf("sampleID: %s", sampleID))

library("BSgenome.Hsapiens.UCSC.hg19")
library("deconstructSigs")

variants <- read.delim(file = tsv_file, 
                       header = TRUE, 
                       sep = '\t', 
                       stringsAsFactors = FALSE,
                       check.names = FALSE)

save.image(file = 'loaded.Rdata')

# add sample ID column
variants[["Sample"]] <- rep(sampleID, nrow(variants))

# keep only entries with chroms in the reference data
variants <- variants[which(as.character(variants[["CHROM"]]) %in% seqnames(BSgenome.Hsapiens.UCSC.hg19::Hsapiens)), ]


# need at least 55 variants per sample
if (nrow(variants) < 55) {
    message(sprintf('There are fewer than 55 variants for sample %s', sampleID))
    quit(status = 11)
}


# convert to signatures format
sigs.input <- mut.to.sigs.input(mut.ref = variants,
                                sample.id = "Sample",
                                chr = "CHROM",
                                pos = "POS",
                                ref = "REF",
                                alt = "ALT")

# make the signatures
signatures <- whichSignatures(tumor.ref = sigs.input,
                              signatures.ref = signatures.cosmic,
                              sample.id = sampleID,
                              contexts.needed = TRUE,
                              tri.counts.method = 'default')

# save signatures
saveRDS(object = signatures, file = signatures_output_file, compress = TRUE)
save.image(file = 'computed.Rdata')

# make plots
# https://stackoverflow.com/a/29583945/5359531
pdf(file = signatures_plot_pdf)
dev.control(displaylist="enable") 
print(plotSignatures(signatures, sub = 'signatures.cosmic'))
saveRDS(object = recordPlot(), file = signatures_plot_Rds)
dev.off()

pdf(file = signatures_pie_plot_pdf)
dev.control(displaylist="enable") 
print(makePie(signatures, sub = 'signatures.cosmic'))
saveRDS(object = recordPlot(), file = signatures_pie_plot_Rds)
dev.off()

# save signature weights to tsv
weights_df <- as.data.frame(signatures$weights)

write.table(x = weights_df, file = weights_tsv, sep = '\t', col.names = TRUE, row.names = FALSE)
# save session
save.image(file = "session.Rdata")

