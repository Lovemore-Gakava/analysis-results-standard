#' Analysis-Related Data Extractors
#'
#' Extraction functions for analysis-related ARS classes including Analysis,
#' AnalysisMethod, Operation, AnalysisSet, DataSubset, and related classes.
#'
#' @export

# Core Analysis Classes

extract_analyses <- function(json_data, class_definition) {
  if (is.null(json_data$analyses) || length(json_data$analyses) == 0) return(NULL)

  records <- list()
  for (i in seq_along(json_data$analyses)) {
    analysis <- json_data$analyses[[i]]
    datapath <- paste0("/analyses/", i-1)
    record <- create_record_from_object(analysis, class_definition, datapath, i)
    records[[i]] <- record
  }

  do.call(rbind, records)
}

extract_analysis_methods <- function(json_data, class_definition) {
  if (is.null(json_data$methods) || length(json_data$methods) == 0) return(NULL)

  records <- list()
  record_idx <- 1

  for (i in seq_along(json_data$methods)) {
    method <- json_data$methods[[i]]
    datapath <- paste0("/methods/", i-1)
    record <- create_record_from_object(method, class_definition, datapath, record_idx)
    records[[record_idx]] <- record
    record_idx <- record_idx + 1
  }

  if (length(records) > 0) {
    do.call(rbind, records)
  } else {
    NULL
  }
}

extract_operations <- function(json_data, class_definition) {
  if (is.null(json_data$methods) || length(json_data$methods) == 0) return(NULL)

  records <- list()
  record_idx <- 1

  # Extract all operations from all methods
  for (method_idx in seq_along(json_data$methods)) {
    method <- json_data$methods[[method_idx]]

    if (!is.null(method$operations) && length(method$operations) > 0) {
      for (op_idx in seq_along(method$operations)) {
        operation <- method$operations[[op_idx]]
        datapath <- paste0("/methods/", method_idx-1, "/operations/", op_idx-1)
        tablepath <- "/root/methods/operations"

        record <- create_record_from_object(operation, class_definition, datapath, record_idx)

        records[[record_idx]] <- record
        record_idx <- record_idx + 1
      }
    }
  }

  if (length(records) > 0) {
    do.call(rbind, records)
  } else {
    NULL
  }
}

extract_operation_results <- function(json_data, class_definition) {
  if (is.null(json_data$analyses) || length(json_data$analyses) == 0) return(NULL)

  records <- list()
  record_idx <- 1

  # Extract results from all analyses
  for (analysis_idx in seq_along(json_data$analyses)) {
    analysis <- json_data$analyses[[analysis_idx]]

    if (!is.null(analysis$results) && length(analysis$results) > 0) {
      for (result_idx in seq_along(analysis$results)) {
        result <- analysis$results[[result_idx]]
        datapath <- paste0("/analyses/", analysis_idx-1, "/results/", result_idx-1)
        tablepath <- "/root/analyses/results"

        record <- create_record_from_object(result, class_definition, datapath, record_idx)

        records[[record_idx]] <- record
        record_idx <- record_idx + 1
      }
    }
  }

  if (length(records) > 0) {
    do.call(rbind, records)
  } else {
    NULL
  }
}

extract_result_groups <- function(json_data, class_definition) {
  if (is.null(json_data$analyses) || length(json_data$analyses) == 0) return(NULL)

  records <- list()
  record_idx <- 1

  # Extract result groups from all analyses/results
  for (analysis_idx in seq_along(json_data$analyses)) {
    analysis <- json_data$analyses[[analysis_idx]]

    if (!is.null(analysis$results) && length(analysis$results) > 0) {
      for (result_idx in seq_along(analysis$results)) {
        result <- analysis$results[[result_idx]]

        if (!is.null(result$resultGroups) && length(result$resultGroups) > 0) {
          for (group_idx in seq_along(result$resultGroups)) {
            group <- result$resultGroups[[group_idx]]
            datapath <- paste0("/analyses/", analysis_idx-1, "/results/", result_idx-1, "/resultGroups/", group_idx-1)
            tablepath <- "/root/analyses/results/resultGroups"

            record <- create_record_from_object(group, class_definition, datapath, record_idx)

            records[[record_idx]] <- record
            record_idx <- record_idx + 1
          }
        }
      }
    }
  }

  if (length(records) > 0) {
    do.call(rbind, records)
  } else {
    NULL
  }
}

# Analysis Sets and Data Subsets

extract_analysis_sets <- function(json_data, class_definition) {
  if (is.null(json_data$analysisSets)) return(NULL)
  extract_array_objects(json_data$analysisSets, class_definition, "/analysisSets")
}

extract_data_subsets <- function(json_data, class_definition) {
  if (is.null(json_data$dataSubsets)) return(NULL)
  extract_array_objects(json_data$dataSubsets, class_definition, "/dataSubsets")
}

# Grouping-related classes

extract_groups <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in analysisGroupings/groups
  if (!is.null(json_data$analysisGroupings) && length(json_data$analysisGroupings) > 0) {
    for (grouping_idx in seq_along(json_data$analysisGroupings)) {
      grouping <- json_data$analysisGroupings[[grouping_idx]]
      if (!is.null(grouping$groups) && length(grouping$groups) > 0) {
        for (group_idx in seq_along(grouping$groups)) {
          group <- grouping$groups[[group_idx]]
          datapath <- paste0("/analysisGroupings/", grouping_idx-1, "/groups/", group_idx-1)

          record <- create_record_from_object(group, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_ordered_grouping_factors <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in analyses/orderedGroupings
  if (!is.null(json_data$analyses) && length(json_data$analyses) > 0) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$orderedGroupings) && length(analysis$orderedGroupings) > 0) {
        for (grouping_idx in seq_along(analysis$orderedGroupings)) {
          grouping <- analysis$orderedGroupings[[grouping_idx]]
          datapath <- paste0("/analyses/", analysis_idx-1, "/orderedGroupings/", grouping_idx-1)

          record <- create_record_from_object(grouping, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_grouping_factors <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in analysisGroupings (root level grouping factors)
  if (!is.null(json_data$analysisGroupings) && length(json_data$analysisGroupings) > 0) {
    for (grouping_idx in seq_along(json_data$analysisGroupings)) {
      grouping <- json_data$analysisGroupings[[grouping_idx]]
      datapath <- paste0("/analysisGroupings/", grouping_idx-1)

      record <- create_record_from_object(grouping, class_definition, datapath, record_idx)
      records[[record_idx]] <- record
      record_idx <- record_idx + 1
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

# Where Clause and Condition extractors

extract_where_clauses <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in dataSubsets/compoundExpression/whereClauses
  if (!is.null(json_data$dataSubsets) && length(json_data$dataSubsets) > 0) {
    for (subset_idx in seq_along(json_data$dataSubsets)) {
      subset <- json_data$dataSubsets[[subset_idx]]
      if (!is.null(subset$compoundExpression) && !is.null(subset$compoundExpression$whereClauses) && length(subset$compoundExpression$whereClauses) > 0) {
        for (clause_idx in seq_along(subset$compoundExpression$whereClauses)) {
          clause <- subset$compoundExpression$whereClauses[[clause_idx]]
          datapath <- paste0("/dataSubsets/", subset_idx-1, "/compoundExpression/whereClauses/", clause_idx-1)

          record <- create_record_from_object(clause, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_where_clause_conditions <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Helper function to extract conditions from an object
  extract_conditions_from_object <- function(obj, base_path) {
    conditions <- list()

    if (!is.null(obj$condition) && is.list(obj$condition)) {
      if (is.null(names(obj$condition))) {
        # Array of conditions
        for (i in seq_along(obj$condition)) {
          condition <- obj$condition[[i]]
          datapath <- paste0(base_path, "/condition/", i-1)
          record <- create_record_from_object(condition, class_definition, datapath, record_idx)
          conditions[[length(conditions) + 1]] <- record
          record_idx <<- record_idx + 1
        }
      } else {
        # Single condition object
        datapath <- paste0(base_path, "/condition")
        record <- create_record_from_object(obj$condition, class_definition, datapath, record_idx)
        conditions[[1]] <- record
        record_idx <<- record_idx + 1
      }
    }

    conditions
  }

  # Search in analysisSets
  if (!is.null(json_data$analysisSets) && length(json_data$analysisSets) > 0) {
    for (i in seq_along(json_data$analysisSets)) {
      set_conditions <- extract_conditions_from_object(json_data$analysisSets[[i]], paste0("/analysisSets/", i-1))
      records <- c(records, set_conditions)
    }
  }

  # Search in dataSubsets
  if (!is.null(json_data$dataSubsets) && length(json_data$dataSubsets) > 0) {
    for (i in seq_along(json_data$dataSubsets)) {
      # Direct condition in dataSubsets
      subset_conditions <- extract_conditions_from_object(json_data$dataSubsets[[i]], paste0("/dataSubsets/", i-1))
      records <- c(records, subset_conditions)

      # Conditions within compoundExpression/whereClauses
      subset <- json_data$dataSubsets[[i]]
      if (!is.null(subset$compoundExpression) && !is.null(subset$compoundExpression$whereClauses) && length(subset$compoundExpression$whereClauses) > 0) {
        for (clause_idx in seq_along(subset$compoundExpression$whereClauses)) {
          clause <- subset$compoundExpression$whereClauses[[clause_idx]]
          clause_conditions <- extract_conditions_from_object(clause, paste0("/dataSubsets/", i-1, "/compoundExpression/whereClauses/", clause_idx-1))
          records <- c(records, clause_conditions)

          # Also check for nested compound expressions within whereClauses
          if (!is.null(clause$compoundExpression) && !is.null(clause$compoundExpression$whereClauses)) {
            for (nested_idx in seq_along(clause$compoundExpression$whereClauses)) {
              nested_clause <- clause$compoundExpression$whereClauses[[nested_idx]]
              nested_conditions <- extract_conditions_from_object(nested_clause,
                paste0("/dataSubsets/", i-1, "/compoundExpression/whereClauses/", clause_idx-1, "/compoundExpression/whereClauses/", nested_idx-1))
              records <- c(records, nested_conditions)
            }
          }
        }
      }
    }
  }

  # Search in analysisGroupings/groups
  if (!is.null(json_data$analysisGroupings) && length(json_data$analysisGroupings) > 0) {
    for (grouping_idx in seq_along(json_data$analysisGroupings)) {
      grouping <- json_data$analysisGroupings[[grouping_idx]]
      if (!is.null(grouping$groups) && length(grouping$groups) > 0) {
        for (group_idx in seq_along(grouping$groups)) {
          group_conditions <- extract_conditions_from_object(grouping$groups[[group_idx]],
                                                            paste0("/analysisGroupings/", grouping_idx-1, "/groups/", group_idx-1))
          records <- c(records, group_conditions)
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

# Compound Expression extractors

extract_compound_subset_expressions <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in dataSubsets/compoundExpression
  if (!is.null(json_data$dataSubsets) && length(json_data$dataSubsets) > 0) {
    for (subset_idx in seq_along(json_data$dataSubsets)) {
      subset <- json_data$dataSubsets[[subset_idx]]
      if (!is.null(subset$compoundExpression)) {
        datapath <- paste0("/dataSubsets/", subset_idx-1, "/compoundExpression")

        record <- create_record_from_object(subset$compoundExpression, class_definition, datapath, record_idx)
        records[[record_idx]] <- record
        record_idx <- record_idx + 1
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_compound_set_expression <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract compound expressions from analysis sets
  if (!is.null(json_data$analysisSets)) {
    for (set_idx in seq_along(json_data$analysisSets)) {
      analysis_set <- json_data$analysisSets[[set_idx]]
      if (!is.null(analysis_set$compoundExpression)) {
        datapath <- sprintf("/analysisSets/%d/compoundExpression", set_idx - 1)
        record <- create_record_from_object(analysis_set$compoundExpression, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  # Also search nested compound expressions in data subsets
  if (!is.null(json_data$dataSubsets)) {
    for (subset_idx in seq_along(json_data$dataSubsets)) {
      subset <- json_data$dataSubsets[[subset_idx]]
      if (!is.null(subset$compoundExpression) && !is.null(subset$compoundExpression$whereClauses)) {
        for (clause_idx in seq_along(subset$compoundExpression$whereClauses)) {
          clause <- subset$compoundExpression$whereClauses[[clause_idx]]
          if (!is.null(clause$compoundExpression)) {
            datapath <- sprintf("/dataSubsets/%d/compoundExpression/whereClauses/%d/compoundExpression", subset_idx - 1, clause_idx - 1)
            record <- create_record_from_object(clause$compoundExpression, class_definition, datapath, record_idx)
            if (!is.null(record)) {
              records[[length(records) + 1]] <- record
              record_idx <- record_idx + 1
            }
          }
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

extract_compound_group_expression <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract compound expressions from grouping factors/groups
  if (!is.null(json_data$analysisGroupings)) {
    for (grouping_idx in seq_along(json_data$analysisGroupings)) {
      grouping <- json_data$analysisGroupings[[grouping_idx]]
      if (!is.null(grouping$groups)) {
        for (group_idx in seq_along(grouping$groups)) {
          group <- grouping$groups[[group_idx]]
          if (!is.null(group$compoundExpression)) {
            datapath <- sprintf("/analysisGroupings/%d/groups/%d/compoundExpression", grouping_idx - 1, group_idx - 1)
            record <- create_record_from_object(group$compoundExpression, class_definition, datapath, record_idx)
            if (!is.null(record)) {
              records[[length(records) + 1]] <- record
              record_idx <- record_idx + 1
            }
          }
        }
      }
    }
  }

  # Also search nested compound expressions in data subsets (same location as CompoundSetExpression)
  if (!is.null(json_data$dataSubsets)) {
    for (subset_idx in seq_along(json_data$dataSubsets)) {
      subset <- json_data$dataSubsets[[subset_idx]]
      if (!is.null(subset$compoundExpression) && !is.null(subset$compoundExpression$whereClauses)) {
        for (clause_idx in seq_along(subset$compoundExpression$whereClauses)) {
          clause <- subset$compoundExpression$whereClauses[[clause_idx]]
          if (!is.null(clause$compoundExpression)) {
            datapath <- sprintf("/dataSubsets/%d/compoundExpression/whereClauses/%d/compoundExpression", subset_idx - 1, clause_idx - 1)
            record <- create_record_from_object(clause$compoundExpression, class_definition, datapath, record_idx)
            if (!is.null(record)) {
              records[[length(records) + 1]] <- record
              record_idx <- record_idx + 1
            }
          }
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

# Analysis Purpose and Reason extractors

extract_analysis_reasons <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in analyses/reason - extract ONLY the controlledTerm reasons for AnalysisReason
  if (!is.null(json_data$analyses) && length(json_data$analyses) > 0) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$reason) && !is.null(analysis$reason$controlledTerm)) {
        # Only extract if this is a controlledTerm reason (not sponsorTermId)
        datapath <- paste0("/analyses/", analysis_idx-1, "/reason")
        record <- create_record_from_object(analysis$reason, class_definition, datapath, record_idx)
        records[[record_idx]] <- record
        record_idx <- record_idx + 1
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_analysis_purpose <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract purposes from analyses
  if (!is.null(json_data$analyses)) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$purpose)) {
        datapath <- sprintf("/analyses/%d/purpose", analysis_idx - 1)
        record <- create_record_from_object(analysis$purpose, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

extract_sponsor_analysis_purposes <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in analyses/purpose - but ONLY extract purposes that have sponsorTermId
  if (!is.null(json_data$analyses) && length(json_data$analyses) > 0) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$purpose) && !is.null(analysis$purpose$sponsorTermId)) {
        # Only extract if this is a sponsor purpose (not controlledTerm)
        datapath <- paste0("/analyses/", analysis_idx-1, "/purpose")
        record <- create_record_from_object(analysis$purpose, class_definition, datapath, record_idx)
        records[[record_idx]] <- record
        record_idx <- record_idx + 1
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_sponsor_analysis_reasons <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract sponsor reasons from analyses
  if (!is.null(json_data$analyses)) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$reason) && !is.null(analysis$reason$sponsorTermId)) {
        datapath <- sprintf("/analyses/%d/reason", analysis_idx - 1)
        record <- create_record_from_object(analysis$reason, class_definition, datapath, record_idx)
        if (!is.null(record)) {
          records[[length(records) + 1]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}

# Operation-related extractors

extract_operation_roles <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in methods/operations/referencedOperationRelationships/referencedOperationRole
  if (!is.null(json_data$methods) && length(json_data$methods) > 0) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$operations) && length(method$operations) > 0) {
        for (op_idx in seq_along(method$operations)) {
          operation <- method$operations[[op_idx]]
          if (!is.null(operation$referencedOperationRelationships) && length(operation$referencedOperationRelationships) > 0) {
            for (rel_idx in seq_along(operation$referencedOperationRelationships)) {
              relationship <- operation$referencedOperationRelationships[[rel_idx]]
              if (!is.null(relationship$referencedOperationRole)) {
                datapath <- paste0("/methods/", method_idx-1, "/operations/", op_idx-1, "/referencedOperationRelationships/", rel_idx-1, "/referencedOperationRole")
                record <- create_record_from_object(relationship$referencedOperationRole, class_definition, datapath, record_idx)
                records[[record_idx]] <- record
                record_idx <- record_idx + 1
              }
            }
          }
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_referenced_analysis_operations <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in analyses/referencedAnalysisOperations
  if (!is.null(json_data$analyses) && length(json_data$analyses) > 0) {
    for (analysis_idx in seq_along(json_data$analyses)) {
      analysis <- json_data$analyses[[analysis_idx]]
      if (!is.null(analysis$referencedAnalysisOperations) && length(analysis$referencedAnalysisOperations) > 0) {
        for (ref_idx in seq_along(analysis$referencedAnalysisOperations)) {
          ref_op <- analysis$referencedAnalysisOperations[[ref_idx]]
          datapath <- paste0("/analyses/", analysis_idx-1, "/referencedAnalysisOperations/", ref_idx-1)

          record <- create_record_from_object(ref_op, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_referenced_data_subsets <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in dataSubsets/compoundExpression/whereClauses (same as WhereClause based on SAS paths)
  if (!is.null(json_data$dataSubsets) && length(json_data$dataSubsets) > 0) {
    for (subset_idx in seq_along(json_data$dataSubsets)) {
      subset <- json_data$dataSubsets[[subset_idx]]
      if (!is.null(subset$compoundExpression) && !is.null(subset$compoundExpression$whereClauses) && length(subset$compoundExpression$whereClauses) > 0) {
        for (clause_idx in seq_along(subset$compoundExpression$whereClauses)) {
          clause <- subset$compoundExpression$whereClauses[[clause_idx]]
          datapath <- paste0("/dataSubsets/", subset_idx-1, "/compoundExpression/whereClauses/", clause_idx-1)

          record <- create_record_from_object(clause, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_referenced_operation_relationships <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in methods/operations/referencedOperationRelationships
  if (!is.null(json_data$methods) && length(json_data$methods) > 0) {
    for (method_idx in seq_along(json_data$methods)) {
      method <- json_data$methods[[method_idx]]
      if (!is.null(method$operations) && length(method$operations) > 0) {
        for (op_idx in seq_along(method$operations)) {
          operation <- method$operations[[op_idx]]
          if (!is.null(operation$referencedOperationRelationships) && length(operation$referencedOperationRelationships) > 0) {
            for (rel_idx in seq_along(operation$referencedOperationRelationships)) {
              relationship <- operation$referencedOperationRelationships[[rel_idx]]
              datapath <- paste0("/methods/", method_idx-1, "/operations/", op_idx-1, "/referencedOperationRelationships/", rel_idx-1)

              record <- create_record_from_object(relationship, class_definition, datapath, record_idx)
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

extract_referenced_analysis_sets <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Look for subClauseId references in data subsets compound expressions
  if (!is.null(json_data$dataSubsets)) {
    for (subset_idx in seq_along(json_data$dataSubsets)) {
      subset <- json_data$dataSubsets[[subset_idx]]
      if (!is.null(subset$compoundExpression) && !is.null(subset$compoundExpression$whereClauses)) {
        for (clause_idx in seq_along(subset$compoundExpression$whereClauses)) {
          clause <- subset$compoundExpression$whereClauses[[clause_idx]]

          # Check for direct subClauseId
          if (!is.null(clause$subClauseId)) {
            datapath <- sprintf("/dataSubsets/%d/compoundExpression/whereClauses/%d", subset_idx - 1, clause_idx - 1)
            record <- create_record_from_object(clause, class_definition, datapath, record_idx)
            if (!is.null(record)) {
              records[[length(records) + 1]] <- record
              record_idx <- record_idx + 1
            }
          }

          # Also check nested compound expression's whereClauses for subClauseId
          if (!is.null(clause$compoundExpression) && !is.null(clause$compoundExpression$whereClauses)) {
            for (nested_idx in seq_along(clause$compoundExpression$whereClauses)) {
              nested_clause <- clause$compoundExpression$whereClauses[[nested_idx]]
              datapath <- sprintf("/dataSubsets/%d/compoundExpression/whereClauses/%d/compoundExpression/whereClauses/%d",
                                subset_idx - 1, clause_idx - 1, nested_idx - 1)
              record <- create_record_from_object(nested_clause, class_definition, datapath, record_idx)
              if (!is.null(record)) {
                records[[length(records) + 1]] <- record
                record_idx <- record_idx + 1
              }
            }
          }
        }
      }
    }
  }

  return(if (length(records) > 0) do.call(rbind, records) else data.frame())
}