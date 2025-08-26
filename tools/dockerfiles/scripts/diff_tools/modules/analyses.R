import("sva", attach=FALSE)
import("limma", attach=FALSE)
import("DESeq2", attach=FALSE)
import("hopach", attach=FALSE)
import("BiocParallel", attach=FALSE)
import("magrittr", `%>%`, attach=TRUE)

export(
    "get_combat_seq_counts",
    "get_limma_counts",
    "get_all_contrasts",
    "get_diff_expr_data",
    "get_clustered_data"
)

get_combat_seq_counts <- function(counts_data, metadata, batch, design_formula) {
    corrected_counts_data <- sva::ComBat_seq(
        counts=base::as.matrix(counts_data),
        batch=metadata[, batch],
        covar_mod=stats::model.matrix(design_formula, data=metadata)          # the design formula here should NOT include batch related terms
    )[, base::rownames(metadata)]                                     # just in case to make sure the column order correposnds to the sample metadata
    return(corrected_counts_data)
}

get_limma_counts <- function(counts_data, metadata, batch, design_formula) {
    limma_design <- stats::as.formula(
        base::paste0(
            "~",
            base::paste(
                base::grep(
                    batch,
                    base::unlist(
                        base::strsplit(
                            as.character(design_formula)[2],
                            "\\+"
                        )
                    ),
                    value=TRUE,
                    ignore.case=TRUE,
                    invert=TRUE
                ),
                collapse="+"
            )
        )
    )
    base::print(
        base::paste(
            "Temporary updated design formula:",
            as.character(limma_design)[2]
        )
    )
    corrected_counts_data <- limma::removeBatchEffect(
        counts_data,
        batch=metadata[, batch],
        design=stats::model.matrix(limma_design, data=metadata)
    )[, base::rownames(metadata)]                                         # just in case to make sure the column order correposnds to the sample metadata
    return (corrected_counts_data)
}

get_all_contrasts <- function(metadata, design_formula) {
    all_design_vars <- base::unique(base::all.vars(design_formula))
    all_design_terms <- attr(stats::terms(design_formula), "term.labels")
    all_interaction_terms <- all_design_terms[base::grepl(":", all_design_terms)]               # can be empty vector if no interactions found
    main_effect_vars <- generics::setdiff(all_design_terms, all_interaction_terms)                  # main effect variables are the same as terms


    base::print(base::paste("Design formula:", as.character(design_formula)[2]))
    base::print(base::paste("   all variables:", base::paste(all_design_vars, collapse=", ")))
    base::print(base::paste("   all terms:", base::paste(all_design_terms, collapse=", ")))
    base::print(base::paste("   all interactions:", base::paste(all_interaction_terms, collapse=", ")))
    base::print(base::paste("   main effect variables:", base::paste(main_effect_vars, collapse=", ")))

    all_contrasts <- c()                                                                  # to keep all collected contrasts
    for (i in 1:length(main_effect_vars)) {                                               # we iterate over the main effect variables because
        current_main_effect_var <- main_effect_vars[i]                                    # DESeq doesn't estimate the main effect for only interaction variables
        current_main_effect_levels <- base::levels(metadata[[current_main_effect_var]])         # all columns in metadata are always vectors
        current_main_effect_values_pairs <- tidyr::crossing(                              # to get all possible combinations for pairwise comparisons
                                           numerator=current_main_effect_levels,
                                           denominator=current_main_effect_levels
                                       ) %>%
                                       dplyr::filter(numerator!=denominator) %>%
                                       base::as.data.frame()
        base::print(
            base::paste0(
                " -- main effect variable: ", current_main_effect_var,
                " (", base::paste(current_main_effect_levels, collapse=", "), ")"
            )
        )
        base::print("    all pairwise comparisons:")
        base::print(current_main_effect_values_pairs)

        current_interaction_vars <- NULL
        current_interaction_levels <- NULL
        current_interaction_terms <- all_interaction_terms[                               # can be empty vector if either all_interaction_terms is empty vector
            base::grepl(current_main_effect_var, all_interaction_terms)                         # or when the current main effect variable is not used in any interactions
        ]
        if (length(current_interaction_terms) > 0){                                      # found one or more variable with wich the current main effect variable interacts
            current_interaction_vars <- base::unique(
                base::unlist(
                    base::lapply(
                        current_interaction_terms,
                        function(term) generics::setdiff(base::strsplit(term, ":")[[1]], current_main_effect_var)
                    )
                )
            )
            current_interaction_vars_pos <- base::unlist(
                base::lapply(
                    seq_along(current_interaction_terms),
                    function(i) {
                        base::which(base::strsplit(current_interaction_terms[i], ":")[[1]] %in% current_interaction_vars)
                    }
                )
            )
            current_interaction_levels <- base::lapply(                                         # this should remain as a list, because we have vector of vectors
                current_interaction_vars,
                function(var) base::levels(metadata[[var]])
            )
            for (j in 1:length(current_interaction_vars)){
                base::print(
                    base::paste0(
                        "    interaction variable: ", current_interaction_vars[j],
                        " (", base::paste(current_interaction_levels[[j]], collapse=", "), ")",
                        " on position ", current_interaction_vars_pos[j]
                    )
                )
            }
        }

        all_contrasts <- base::append(
            all_contrasts,
            base::unlist(
                base::lapply(
                    base::unname(
                        base::split(
                            current_main_effect_values_pairs,
                            base::seq(base::nrow(current_main_effect_values_pairs))
                        )
                    ),
                    function(row){
                        current_numerator <- row$numerator
                        current_denominator <- row$denominator

                        main_effect_levels <- current_main_effect_levels                  # no reason to relevel the whole metadata as we need only the levels order
                        if (current_denominator != current_main_effect_levels[1]) {
                            main_effect_levels <- c(
                                current_denominator,
                                main_effect_levels[main_effect_levels != current_denominator]
                            )
                        }

                        base::print(
                            base::paste0(
                                " ---- numerator/denominator: ",
                                current_numerator, "/", current_denominator
                            )
                        )
                        sample_groups <- metadata %>%
                                         dplyr::filter(                                                      # selecting the rows that have numerator or denominator values
                                             !!rlang::sym(current_main_effect_var) %in%
                                                 c(current_numerator, current_denominator)
                                         ) %>%
                                         dplyr::select(tidyselect::all_of(current_interaction_vars)) %>%                  # may select 0 columns when current_interaction_vars is NULL
                                         tibble::rownames_to_column(var="sample") %>%
                                         dplyr::group_by(dplyr::across(tidyselect::all_of(current_interaction_vars))) %>%        # may create one group when current_interaction_vars is NULL
                                         dplyr::mutate(
                                             sample=base::paste(sample, collapse="@")
                                         ) %>%
                                         dplyr::ungroup() %>%
                                         dplyr::select(sample) %>%
                                         dplyr::distinct() %>%
                                         dplyr::pull(sample)
                        base::lapply(
                            sample_groups,
                            function(l){
                                selected_samples <- base::unlist(base::strsplit(l, "@"))
                                current_interaction_values <- metadata %>%                                         # will be "" if current_interaction_vars is NULL
                                                              tibble::rownames_to_column(var="sample") %>%
                                                              dplyr::filter(sample %in% selected_samples) %>%
                                                              dplyr::select(tidyselect::all_of(current_interaction_vars)) %>%         # these columns should be identical for all selected samples
                                                              dplyr::mutate(
                                                                  interaction = if (base::ncol(.) == 0)                  # when current_interaction_vars was NULL
                                                                                    ""                             # we can't have NULL here, because it's a data.frame so we use ""
                                                                                else
                                                                                    base::do.call(base::paste, c(., sep="@"))
                                                              ) %>%
                                                              dplyr::select(interaction) %>%
                                                              dplyr::distinct() %>%
                                                              dplyr::pull(interaction)                                    # should always be a character vector with length 1 (a.k.a string)
                                current_interaction_values <- base::unlist(base::strsplit(current_interaction_values, "@"))    # safe to run even on "" (will return vector of lenght 0)

                                collected_interaction_effects <- c()
                                if (length(current_interaction_values) > 0){
                                    for (k in 1:length(current_interaction_values)){
                                        interaction_value <- current_interaction_values[k]
                                        if (interaction_value == current_interaction_levels[[k]][1]){
                                            interaction_effect <- NULL
                                        } else {
                                            if (current_interaction_vars_pos[k] == 1){
                                                interaction_effect <- base::paste0(
                                                    current_interaction_vars[k], interaction_value, ".",
                                                    current_main_effect_var, current_numerator
                                                )
                                            } else {
                                                interaction_effect <- base::paste0(
                                                    current_main_effect_var, current_numerator, ".",
                                                    current_interaction_vars[k], interaction_value
                                                )
                                            }
                                            collected_interaction_effects <- c(collected_interaction_effects, interaction_effect)
                                        }
                                    }
                                }

                                current_main_effect <- base::paste(
                                                           current_main_effect_var,
                                                           current_numerator, "vs", current_denominator,
                                                           sep="_"
                                                       )
                                current_interaction_group <- base::paste(                                                     # safe to run even when current_interaction_vars is NULL
                                                                 base::mapply(                                                # and current_interaction_values is "" - will return ""
                                                                     function(var, val) base::paste0(var, ":", val),
                                                                     current_interaction_vars,
                                                                     current_interaction_values
                                                                 ),
                                                                 collapse=", "
                                                             )

                                base::print(base::paste(" -------- main effect:", current_main_effect))
                                base::print(base::paste("          main variable:", current_main_effect_var))
                                base::print(base::paste("          main levels:", base::paste(main_effect_levels, collapse=", ")))
                                base::print(base::paste("          interaction effects:", base::paste(collected_interaction_effects, collapse=", ") ))
                                base::print(base::paste("          interaction variables:", base::paste(current_interaction_vars, collapse=", ")))
                                base::print(base::paste("          interaction levels:", base::paste(
                                                                                 base::sapply(current_interaction_levels,
                                                                                 function(x) base::paste(x, collapse = ", ")),
                                                                                 collapse="; "
                                                                             )
                                           )
                                )
                                base::print(base::paste("          interaction group:", current_interaction_group))
                                base::print(base::paste("          samples:", base::paste(selected_samples, collapse=", ")))

                                list(
                                    id=base::paste(
                                        current_main_effect_var,
                                        base::paste(base::sort(c(current_numerator, current_denominator)), collapse="_"),
                                        base::tolower(
                                            base::gsub("'|\"|\\s|\\t|#|%|&|-|:|,", "_", current_interaction_group)
                                        ),
                                        sep="_"
                                    ),
                                    alias=base::paste0(
                                        current_main_effect_var, ":", current_numerator, "-", current_denominator,
                                        base::ifelse(
                                            !is.null(current_interaction_vars),
                                            base::paste0(" for ", current_interaction_group),
                                            ""
                                        )
                                    ),
                                    main_effect=current_main_effect,
                                    main_effect_var=current_main_effect_var,
                                    main_effect_levels=main_effect_levels,
                                    interaction_effects=collected_interaction_effects,        # can be empty vector
                                    interaction_effect_vars=current_interaction_vars,
                                    interaction_effect_levels=current_interaction_levels
                                )
                            }
                        )
                    }
                ),
            recursive=FALSE
            )
        )
    }

    all_contrasts <- all_contrasts[          # sorting by the main levels, so we can cache deseq object
        base::order(
            base::sapply(
                all_contrasts,
                function(x) base::paste(
                    x$main_effect_levels,
                    collapse=","
                )
            )
        )
    ]
    names(all_contrasts) <- base::paste0("c", seq_along(all_contrasts))    # adding the names, otherwise may extract wrong contrasts

    return(all_contrasts)
}

get_diff_expr_data <- function(
    counts_data, metadata, contrast, design_formula,
    padj, logfc, alternative_hypothesis="greaterAbs",
    cpus=1, cached_deseq_wald=NULL
){
    diff_expr_data <- NULL
    base::tryCatch(
        expr = {

            if (
                !is.null(cached_deseq_wald) &&
                base::identical(
                    base::levels(
                        base::as.data.frame(SummarizedExperiment::colData(cached_deseq_wald))[[contrast$main_effect_var]]
                    ),
                    contrast$main_effect_levels
                ) &&
                base::identical(                                                                 # checking design just in case
                    as.character(DESeq2::design(cached_deseq_wald))[2],
                    as.character(design_formula)[2]
                )
            ){
                base::print("Using cached DESeq object")
                deseq_wald <- cached_deseq_wald
            } else {
                base::print("Identifying differentially expressed features with DESeq")
                metadata[[contrast$main_effect_var]] <- base::factor(                            # need to relevel metadata so DESeq calculates correct contrasts
                    base::as.vector(metadata[[contrast$main_effect_var]]),
                    levels=contrast$main_effect_levels
                )
                deseq_data <- DESeq2::DESeqDataSetFromMatrix(
                    countData=counts_data,
                    colData=metadata,
                    design=design_formula
                )
                deseq_wald <- DESeq2::DESeq(
                    deseq_data,
                    test="Wald",
                    quiet=TRUE,
                    parallel=TRUE,
                    BPPARAM=BiocParallel::MulticoreParam(cpus)
                )
            }

            base::print(DESeq2::resultsNames(deseq_wald))
            current_results <- DESeq2::results(
                deseq_wald,
                contrast=list(c(contrast$main_effect, contrast$interaction_effects)),
                alpha=padj,
                lfcThreshold=logfc,
                altHypothesis=alternative_hypothesis,
                independentFiltering=TRUE,
                parallel=TRUE,
                BPPARAM=BiocParallel::MulticoreParam(cpus)
            )
            base::print(utils::head(current_results))
            diff_expr_data <- list(deseq_wald=deseq_wald, results=current_results)
        },
        error = function(e){
            base::print(
                base::paste(
                    "Failed to process the contrast",
                    contrast$alias, "with error -", e
                )
            )
        }
    )

    return(diff_expr_data)
}

get_clustered_data <- function(expression_data, zscore, dist, depth, branches, transpose) {

    if (transpose){
        base::print("Transposing expression data")
        expression_data <- base::t(expression_data)
    }

    if (!is.null(zscore) && zscore) {
        base::print("Converting to z-scores before HOPACH clustering")
        expression_data <- base::t(base::scale(base::t(expression_data), center=TRUE, scale=TRUE))
    }

    base::print("Creating distance matrix")
    distance_matrix <- hopach::distancematrix(expression_data, dist)
    base::print("Running HOPACH")
    hopach_results <- hopach::hopach(
        expression_data,
        dmat=distance_matrix,
        K=depth,
        kmax=branches,
        khigh=branches
    )

    if (transpose){
        base::print("Transposing expression data")
        expression_data = base::t(expression_data)
    }

    base::print("Parsing cluster labels")
    base::options(scipen=999)                                           # need to temporary disable scientific notation, because nchar gives wrong answer
    clusters = base::as.data.frame(hopach_results$clustering$labels)
    base::colnames(clusters) = "label"
    clusters = base::cbind(
        clusters,
        "HCL"=base::outer(
            clusters$label,
            10^c((base::nchar(trunc(clusters$label))[1]-1):0),
            function(a, b) {
                base::paste0("c", a %/% b)
            }
        )
    )
    clusters = clusters[, c(-1), drop=FALSE]
    base::options(scipen=0)                                            # setting back to the default value

    return (
        list(
            order=base::as.vector(hopach_results$clustering$order),
            expression=expression_data,
            clusters=clusters
        )
    )
}