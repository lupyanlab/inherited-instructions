#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
landscape <- readr::read_csv(args[1])
pdf(args[2])
lattice::wireframe(score ~ x * y, data = landscape)
dev.off()
