#' Reference-Related Data Extractors
#'
#' Extraction functions for reference-related ARS classes including DocumentReference,
#' ReferenceDocument, PageRef types, and other reference classes.
#'
#' @export

# Document Reference Classes

extract_document_reference <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract document references from analyses/documentRefs arrays
  if (!is.null(json_data$analyses)) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$documentRefs)) {
        for (ref_idx in seq_along(analysis$documentRefs)) {
          doc_ref <- analysis$documentRefs[[ref_idx]]
          datapath <- sprintf("/analyses/%d/documentRefs/%d", analysis_idx - 1, ref_idx - 1)
          record <- create_record_from_object(doc_ref, class_definition, datapath, record_idx)
          if (!is.null(record)) {
            records[[length(records) + 1]] <- record
            record_idx <- record_idx + 1
          }
        }
      }

      # Also extract from analyses programmingCode/documentRef
      if (!is.null(analysis$programmingCode) && !is.null(analysis$programmingCode$documentRef)) {
        datapath <- sprintf("/analyses/%d/programmingCode/documentRef", analysis_idx - 1)
        record <- create_record_from_object(analysis$programmingCode$documentRef, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  # Extract document references from methods/documentRefs arrays
  if (!is.null(json_data$methods)) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$documentRefs)) {
        for (ref_idx in seq_along(method$documentRefs)) {
          doc_ref <- method$documentRefs[[ref_idx]]
          datapath <- sprintf("/methods/%d/documentRefs/%d", method_idx - 1, ref_idx - 1)
          record <- create_record_from_object(doc_ref, class_definition, datapath, record_idx)
          if (!is.null(record)) {
            records[[length(records) + 1]] <- record
            record_idx <- record_idx + 1
          }
        }
      }
    }
  }

  # Extract document references from outputs/documentRefs arrays
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$documentRefs)) {
        for (ref_idx in seq_along(output$documentRefs)) {
          doc_ref <- output$documentRefs[[ref_idx]]
          datapath <- sprintf("/outputs/%d/documentRefs/%d", output_idx - 1, ref_idx - 1)
          record <- create_record_from_object(doc_ref, class_definition, datapath, record_idx)
          if (!is.null(record)) {
            records[[length(records) + 1]] <- record
            record_idx <- record_idx + 1
          }
        }
      }

      # Also extract from outputs programmingCode/documentRef
      if (!is.null(output$programmingCode) && !is.null(output$programmingCode$documentRef)) {
        datapath <- sprintf("/outputs/%d/programmingCode/documentRef", output_idx - 1)
        record <- create_record_from_object(output$programmingCode$documentRef, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

extract_reference_document <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract reference documents from root level
  if (!is.null(json_data$referenceDocuments)) {
    for (doc_idx in seq_along(json_data$referenceDocuments)) {
      document <- json_data$referenceDocuments[[doc_idx]]
      datapath <- sprintf("/referenceDocuments/%d", doc_idx - 1)
      record <- create_record_from_object(document, class_definition, datapath, record_idx)
      if (!is.null(record)) {
        records[[length(records) + 1]] <- record
        record_idx <- record_idx + 1
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

# Page Reference Classes

extract_page_name_refs <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Helper function to extract page name refs from document refs
  extract_page_name_refs_from_docrefs <- function(doc_refs, base_path) {
    page_records <- list()

    for (doc_idx in seq_along(doc_refs)) {
      doc_ref <- doc_refs[[doc_idx]]
      if (!is.null(doc_ref$pageRefs)) {
        for (page_idx in seq_along(doc_ref$pageRefs)) {
          page_ref <- doc_ref$pageRefs[[page_idx]]
          if (!is.null(page_ref$refType) && page_ref$refType == "NamedDestination" && !is.null(page_ref$pageNames)) {
            datapath <- sprintf("%s/%d/pageRefs/%d", base_path, doc_idx - 1, page_idx - 1)
            record <- create_record_from_object(page_ref, class_definition, datapath, record_idx)
            if (!is.null(record)) {
              page_records[[length(page_records) + 1]] <- record
              record_idx <<- record_idx + 1
            }
          }
        }
      }
    }

    return(page_records)
  }

  # Extract from analyses/documentRefs
  if (!is.null(json_data$analyses)) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$documentRefs)) {
        base_path <- sprintf("/analyses/%d/documentRefs", analysis_idx - 1)
        page_records <- extract_page_name_refs_from_docrefs(analysis$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  # Extract from outputs/documentRefs
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$documentRefs)) {
        base_path <- sprintf("/outputs/%d/documentRefs", output_idx - 1)
        page_records <- extract_page_name_refs_from_docrefs(output$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  # Extract from methods/documentRefs
  if (!is.null(json_data$methods)) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$documentRefs)) {
        base_path <- sprintf("/methods/%d/documentRefs", method_idx - 1)
        page_records <- extract_page_name_refs_from_docrefs(method$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

extract_page_number_list_refs <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Helper function to extract page number list refs from document refs
  extract_page_number_list_refs_from_docrefs <- function(doc_refs, base_path) {
    page_records <- list()

    for (doc_idx in seq_along(doc_refs)) {
      doc_ref <- doc_refs[[doc_idx]]
      if (!is.null(doc_ref$pageRefs)) {
        for (page_idx in seq_along(doc_ref$pageRefs)) {
          page_ref <- doc_ref$pageRefs[[page_idx]]
          if (!is.null(page_ref$refType) && page_ref$refType == "PhysicalRef" &&
              !is.null(page_ref$pageNumbers) && is.null(page_ref$firstPage) && is.null(page_ref$lastPage)) {
            datapath <- sprintf("%s/%d/pageRefs/%d", base_path, doc_idx - 1, page_idx - 1)
            record <- create_record_from_object(page_ref, class_definition, datapath, record_idx)
            if (!is.null(record)) {
              page_records[[length(page_records) + 1]] <- record
              record_idx <<- record_idx + 1
            }
          }
        }
      }
    }

    return(page_records)
  }

  # Extract from analyses/documentRefs
  if (!is.null(json_data$analyses)) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$documentRefs)) {
        base_path <- sprintf("/analyses/%d/documentRefs", analysis_idx - 1)
        page_records <- extract_page_number_list_refs_from_docrefs(analysis$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  # Extract from outputs/documentRefs
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$documentRefs)) {
        base_path <- sprintf("/outputs/%d/documentRefs", output_idx - 1)
        page_records <- extract_page_number_list_refs_from_docrefs(output$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  # Extract from methods/documentRefs
  if (!is.null(json_data$methods)) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$documentRefs)) {
        base_path <- sprintf("/methods/%d/documentRefs", method_idx - 1)
        page_records <- extract_page_number_list_refs_from_docrefs(method$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

extract_page_number_range_refs <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Helper function to extract page number range refs from document refs
  extract_page_number_range_refs_from_docrefs <- function(doc_refs, base_path) {
    page_records <- list()

    for (doc_idx in seq_along(doc_refs)) {
      doc_ref <- doc_refs[[doc_idx]]
      if (!is.null(doc_ref$pageRefs)) {
        for (page_idx in seq_along(doc_ref$pageRefs)) {
          page_ref <- doc_ref$pageRefs[[page_idx]]
          if (!is.null(page_ref$refType) && page_ref$refType == "PhysicalRef" &&
              !is.null(page_ref$firstPage) && !is.null(page_ref$lastPage)) {
            datapath <- sprintf("%s/%d/pageRefs/%d", base_path, doc_idx - 1, page_idx - 1)
            record <- create_record_from_object(page_ref, class_definition, datapath, record_idx)
            if (!is.null(record)) {
              page_records[[length(page_records) + 1]] <- record
              record_idx <<- record_idx + 1
            }
          }
        }
      }
    }

    return(page_records)
  }

  # Extract from analyses/documentRefs
  if (!is.null(json_data$analyses)) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$documentRefs)) {
        base_path <- sprintf("/analyses/%d/documentRefs", analysis_idx - 1)
        page_records <- extract_page_number_range_refs_from_docrefs(analysis$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  # Extract from outputs/documentRefs
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$documentRefs)) {
        base_path <- sprintf("/outputs/%d/documentRefs", output_idx - 1)
        page_records <- extract_page_number_range_refs_from_docrefs(output$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  # Extract from methods/documentRefs
  if (!is.null(json_data$methods)) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$documentRefs)) {
        base_path <- sprintf("/methods/%d/documentRefs", method_idx - 1)
        page_records <- extract_page_number_range_refs_from_docrefs(method$documentRefs, base_path)
        records <- c(records, page_records)
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}