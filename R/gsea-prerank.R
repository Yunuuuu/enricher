# Used to extract the `prerank` statistics
gseaPrerank0 <- new_class("gseaPrerank0")

method(gsea0, list(class_any, gseaPrerank0)) <- function(
    object, method, ..., gs) {
    cli::cli_abort(paste(
        "Cannot extract ranking statistics from",
        "{.obj_type_friendly {object}}"
    ))
}

method(gsea0, list(class_numeric, gseaPrerank0)) <- function(
    object, method, ..., gs) {
    if (!rlang::is_named2(object)) {
        cli::cli_abort("{.arg object} must be a named numeric")
    }
    object
}

method(gsea0, list(class_data.frame, gseaPrerank0)) <- function(
    object, method, ..., gs) {
    if (ncol(object) < 2L) {
        cli::cli_abort(
            "{.arg object} must be a data frame of at least 2 columns"
        )
    }
    nms <- vec_cast(object[[1L]], character(), x_arg = "the 1st column")
    if (vec_any_missing(nms) || any(nms == "")) {
        cli::cli_abort(
            "the 1st column cannot have missing value or empty string"
        )
    }
    statistics <- vec_cast(object[[2L]], numeric(), x_arg = "the 2nd column")
    names(statistics) <- nms
    statistics
}

# prerank method ---------------------------------------
gseaPrerank <- new_class("gseaPrerank", gseaPrerank0,
    properties = list(
        nperm = prop_number_whole(
            min = 1,
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.integer(value)
                prop(self, "nperm") <- value
                self
            },
            default = 1L
        ),
        exponential = prop_number_decimal(
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.double(value)
                prop(self, "exponential") <- value
                self
            },
            default = 1,
            allow_infinite = FALSE
        ),
        threads = prop_number_whole(
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.integer(value)
                prop(self, "threads") <- value
                self
            },
            min = 1,
            max = quote(as.double(parallel::detectCores())),
            default = 1L
        )
    )
)

method(gsea0, list(class_any, gseaPrerank)) <- function(
    object, method, ..., gs) {
    object <- gsea0(object, super(method, gseaPrerank0), ..., gs = gs)
    # To-DO: use rust to implement
    call_rust_fn(
        "gsea",
        gs, object,
        nperm = method@nperm,
        threads = method@threads,
        gseaParam = method@exponential
    )
}

# fgsea method -----------------------------------------
#' @include utils-S7.R
gseaSimple <- new_class(
    "gseaSimple", gseaPrerank0,
    properties = list(
        nperm = prop_number_whole(
            min = 1,
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.integer(value)
                prop(self, "nperm") <- value
                self
            },
            default = 1L
        ),
        score_type = prop_match(c("std", "pos", "neg")),
        threads = prop_number_whole(
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.integer(value)
                prop(self, "threads") <- value
                self
            },
            min = 1,
            max = quote(as.double(parallel::detectCores())),
            default = 1L
        ),
        exponential = prop_number_decimal(
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.double(value)
                prop(self, "exponential") <- value
                self
            },
            default = 1,
            allow_infinite = FALSE
        )
    )
)

method(gsea0, list(class_any, gseaSimple)) <- function(
    object, method, ..., gs) {
    check_bioc_installed("fgsea", "to use {.field gseaSimple} method")
    object <- gsea0(object, super(method, gseaPrerank0), ..., gs = gs)
    fgsea::fgseaSimple(
        gs,
        object,
        minSize = 1,
        maxSize = length(object),
        scoreType = method@score_type,
        nperm = method@nperm,
        nproc = method@threads,
        gseaParam = method@exponential
    )
}

gseaMultilevel <- new_class(
    "gseaMultilevel",
    gseaSimple,
    properties = list(
        sample_size = prop_number_whole(
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.integer(value)
                prop(self, "sample_size") <- value
                self
            },
            min = 1,
            default = 101L
        ),
        eps = prop_number_decimal(
            setter = function(self, value) {
                if (is.numeric(value)) value <- as.double(value)
                prop(self, "eps") <- value
                self
            },
            default = 1e-50,
            allow_infinite = FALSE
        )
    ),
    constructor = function(sample_size = 101L, eps = 1e-50,
                           nperm = 1L, score_type = "std", threads = 1L, exponential = 1) {
        new_object(
            gseaSimple(
                nperm = nperm, score_type = score_type,
                threads = threads, exponential = exponential
            ),
            sample_size = sample_size,
            eps = eps
        )
    }
)

method(gsea0, list(class_any, gseaMultilevel)) <- function(
    object, method, ..., gs) {
    check_bioc_installed("fgsea", "to use {.field gseaMultilevel} method")
    object <- gsea0(object, super(method, gseaPrerank0), ..., gs = gs)
    fgsea::fgseaMultilevel(
        gs,
        object,
        minSize = 1,
        maxSize = length(object),
        sampleSize = method@sample_size,
        eps = method@eps,
        scoreType = method@score_type,
        nPermSimple = method@nperm,
        nproc = method@threads,
        gseaParam = method@exponential
    )
}
