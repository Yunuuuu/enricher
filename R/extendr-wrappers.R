# Generated by extendr: Do not edit by hand

# nolint start

#
# This file was created with the following call:
#   .Call("wrap__make_xbio_wrappers", use_symbols = TRUE, package_name = "xbio")

#' @usage NULL
#' @useDynLib xbio, .registration = TRUE
NULL

gsea_gene_permutate <- function(identifiers, metrics, genesets, exponent, nperm, threads, seed) .Call(wrap__gsea_gene_permutate, identifiers, metrics, genesets, exponent, nperm, threads, seed)


# nolint end
