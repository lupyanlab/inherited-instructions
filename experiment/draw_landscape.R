#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
simple_hill <- readr::read_csv(args[1])
pdf(args[2])
lattice::wireframe(score ~ x * y, data = simple_hill)
dev.off()
