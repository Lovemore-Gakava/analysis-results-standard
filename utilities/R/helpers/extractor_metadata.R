#' Metadata-Related Data Extractors
#'
#' Extraction functions for metadata-related ARS classes including TerminologyExtension,
#' SponsorTerm, AnalysisOutputCategorization, and programming code classes.
#'
#' @export

# Terminology and Sponsor Classes

extract_terminology_extensions <- function(json_data, class_definition) {
  if (is.null(json_data$terminologyExtensions)) return(NULL)
  extract_array_objects(json_data$terminologyExtensions, class_definition, "/terminologyExtensions")
}

extract_sponsor_terms <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in terminologyExtensions/sponsorTerms
  if (!is.null(json_data$terminologyExtensions) && length(json_data$terminologyExtensions) > 0) {
    for (ext_idx in seq_along(json_data$terminologyExtensions)) {
      extension <- json_data$terminologyExtensions[[ext_idx]]
      if (!is.null(extension$sponsorTerms) && length(extension$sponsorTerms) > 0) {
        for (term_idx in seq_along(extension$sponsorTerms)) {
          term <- extension$sponsorTerms[[term_idx]]
          datapath <- paste0("/terminologyExtensions/", ext_idx-1, "/sponsorTerms/", term_idx-1)

          record <- create_record_from_object(term, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

# Analysis Output Categorization Classes

extract_analysis_output_categorizations <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract top-level categorizations
  if (!is.null(json_data$analysisOutputCategorizations) && length(json_data$analysisOutputCategorizations) > 0) {
    for (cat_idx in seq_along(json_data$analysisOutputCategorizations)) {
      categorization <- json_data$analysisOutputCategorizations[[cat_idx]]
      datapath <- paste0("/analysisOutputCategorizations/", cat_idx-1)

      record <- create_record_from_object(categorization, class_definition, datapath, record_idx)
      records[[record_idx]] <- record
      record_idx <- record_idx + 1

      # Also extract nested subCategorizations as AnalysisOutputCategorization records
      if (!is.null(categorization$categories) && length(categorization$categories) > 0) {
        for (category_idx in seq_along(categorization$categories)) {
          category <- categorization$categories[[category_idx]]
          if (!is.null(category$subCategorizations) && length(category$subCategorizations) > 0) {
            for (sub_idx in seq_along(category$subCategorizations)) {
              sub_cat <- category$subCategorizations[[sub_idx]]
              sub_datapath <- paste0("/analysisOutputCategorizations/", cat_idx-1, "/categories/", category_idx-1, "/subCategorizations/", sub_idx-1)

              record <- create_record_from_object(sub_cat, class_definition, sub_datapath, record_idx)
              records[[record_idx]] <- record
              record_idx <- record_idx + 1
            }
          }
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_analysis_output_categories <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in analysisOutputCategorizations/categories
  if (!is.null(json_data$analysisOutputCategorizations) && length(json_data$analysisOutputCategorizations) > 0) {
    for (cat_idx in seq_along(json_data$analysisOutputCategorizations)) {
      categorization <- json_data$analysisOutputCategorizations[[cat_idx]]
      if (!is.null(categorization$categories) && length(categorization$categories) > 0) {
        for (category_idx in seq_along(categorization$categories)) {
          category <- categorization$categories[[category_idx]]
          datapath <- paste0("/analysisOutputCategorizations/", cat_idx-1, "/categories/", category_idx-1)

          record <- create_record_from_object(category, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1

          # Also extract categories within subCategorizations
          if (!is.null(category$subCategorizations) && length(category$subCategorizations) > 0) {
            for (sub_idx in seq_along(category$subCategorizations)) {
              sub_cat <- category$subCategorizations[[sub_idx]]
              if (!is.null(sub_cat$categories) && length(sub_cat$categories) > 0) {
                for (sub_category_idx in seq_along(sub_cat$categories)) {
                  sub_category <- sub_cat$categories[[sub_category_idx]]
                  sub_datapath <- paste0("/analysisOutputCategorizations/", cat_idx-1, "/categories/", category_idx-1, "/subCategorizations/", sub_idx-1, "/categories/", sub_category_idx-1)

                  record <- create_record_from_object(sub_category, class_definition, sub_datapath, record_idx)
                  records[[record_idx]] <- record
                  record_idx <- record_idx + 1
                }
              }
            }
          }
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

# Programming Code Classes

extract_analysis_output_programming_code <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract programming code from analyses
  if (!is.null(json_data$analyses)) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$programmingCode)) {
        datapath <- sprintf("/analyses/%d/programmingCode", analysis_idx - 1)
        record <- create_record_from_object(analysis$programmingCode, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  # Extract programming code from outputs
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$programmingCode)) {
        datapath <- sprintf("/outputs/%d/programmingCode", output_idx - 1)
        record <- create_record_from_object(output$programmingCode, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

extract_analysis_programming_code_template <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract code templates from methods
  if (!is.null(json_data$methods)) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$codeTemplate)) {
        datapath <- sprintf("/methods/%d/codeTemplate", method_idx - 1)
        record <- create_record_from_object(method$codeTemplate, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

extract_template_code_parameter <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract template code parameters from methods
  if (!is.null(json_data$methods)) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$codeTemplate) && !is.null(method$codeTemplate$parameters)) {
        for (param_idx in seq_along(method$codeTemplate$parameters)) {
          param <- method$codeTemplate$parameters[[param_idx]]
          datapath <- sprintf("/methods/%d/codeTemplate/parameters/%d", method_idx - 1, param_idx - 1)
          record <- create_record_from_object(param, class_definition, datapath, record_idx)
          if (!is.null(record)) {
            records[[length(records) + 1]] <- record
            record_idx <- record_idx + 1
          }
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}