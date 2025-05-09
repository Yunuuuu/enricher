gs_terms <- function(gs) {
    assert_s3_class(gs, "xbio_genesets")
    vapply(
        gs, function(geneset) {
            attr(geneset, "term") %||% NA_character_
        },
        character(1L),
        USE.NAMES = FALSE
    )
}

gs_descs <- function(gs) {
    assert_s3_class(gs, "xbio_genesets")
    vapply(
        gs, function(geneset) {
            attr(geneset, "description") %||% NA_character_
        },
        character(1L),
        USE.NAMES = FALSE
    )
}

gs_map <- function(gs, annodb, key_source, key_target, ...) {
    assert_s3_class(gs, "xbio_genesets")
    assert_string(key_source, allow_empty = FALSE)
    assert_string(key_target, allow_empty = FALSE)
    if (vec_size(gs) == 0L) return(gs) # styler: off

    # Infer the annodb ----------------------------
    if (is.character(annodb)) {
        check_bioc_installed(annodb)
        annodb <- getExportedValue(annodb, annodb)
    }

    # mapping the the genes in genesets into keytype
    gs_lapply(gs, function(geneset) {
        if (length(geneset) == 0L) return(geneset) # styler: off
        out <- AnnotationDbi::mapIds(
            x = annodb,
            keys = geneset,
            column = key_target,
            keytype = key_source,
            ...
        )
        out <- as.character(out) # out can be a list
        out[is.na(out) | out == ""] <- NA_character_
        out
    })
}

#' @keywords internal
#' @noRd
gs_trim <- function(gs) {
    assert_s3_class(gs, "xbio_genesets")
    gs <- gs_lapply(gs, function(geneset) {
        geneset[!is.na(geneset) & geneset != ""]
    })
    if (!all(keep <- list_sizes(gs) > 0L)) {
        cli::cli_warn(paste(
            "Removing {sum(!keep)} invalid gene set{?s}",
            "(all are empty string or missing value)"
        ))
        gs <- gs[keep]
    }
    gs
}

gs_filter <- function(gs, min_size = NULL, max_size = NULL) {
    assert_s3_class(gs, "xbio_genesets")
    assert_number_whole(min_size, min = 1, allow_null = TRUE)
    assert_number_whole(max_size, min = 1, allow_null = TRUE)
    if (is.null(min_size) && is.null(max_size)) {
        return(gs)
    }
    sizes <- list_sizes(gs)
    if (!is.null(min_size) && !is.null(max_size)) {
        keep <- sizes >= min_size & sizes <= max_size
        out_pattern <- sprintf("[%d, %d]", min_size, max_size)
    } else if (!is.null(min_size)) {
        keep <- sizes >= min_size
        out_pattern <- sprintf("[%d, Inf)", min_size)
    } else {
        keep <- sizes <= max_size
        out_pattern <- sprintf("(0, %d]", max_size)
    }
    if (!all(keep)) {
        cli::cli_inform(c(
            ">" = sprintf(
                "Removing {sum(!keep)} gene set{?s} with size out of %s",
                out_pattern
            )
        ))
        gs <- gs[keep]
    }
    gs
}

gs_lapply <- function(gs, ...) vec_restore(lapply(gs, ...), gs)
