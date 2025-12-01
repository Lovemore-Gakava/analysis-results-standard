#' Output-Related Data Extractors
#'
#' Extraction functions for output-related ARS classes including Output,
#' OutputDisplay, DisplaySection, ListOfContents, and related classes.
#'
#' @export

# Core Output Classes

extract_outputs <- function(json_data, class_definition) {
  if (is.null(json_data$outputs)) return(NULL)
  extract_array_objects(json_data$outputs, class_definition, "/outputs")
}

extract_output_displays <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  if (!is.null(json_data$outputs) && length(json_data$outputs) > 0) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]

      if (!is.null(output$displays) && length(output$displays) > 0) {
        for (display_idx in seq_along(output$displays)) {
          display <- output$displays[[display_idx]]
          datapath <- paste0("/outputs/", output_idx-1, "/displays/", display_idx-1)

          record <- create_record_from_object(display, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_output_file <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract file specifications from outputs
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$fileSpecifications)) {
        for (file_idx in seq_along(output$fileSpecifications)) {
          file_spec <- output$fileSpecifications[[file_idx]]
          datapath <- sprintf("/outputs/%d/fileSpecifications/%d", output_idx - 1, file_idx - 1)
          record <- create_record_from_object(file_spec, class_definition, datapath, record_idx)
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

extract_output_file_type <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Extract file types from output file specifications
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$fileSpecifications)) {
        for (file_idx in seq_along(output$fileSpecifications)) {
          file_spec <- output$fileSpecifications[[file_idx]]
          if (!is.null(file_spec$fileType)) {
            datapath <- sprintf("/outputs/%d/fileSpecifications/%d/fileType", output_idx - 1, file_idx - 1)
            record <- create_record_from_object(file_spec$fileType, class_definition, datapath, record_idx)
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

# Display Section Classes

extract_display_sections <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in outputs/displays/display/displaySections
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$displays)) {
        for (display_idx in seq_along(output$displays)) {
          display_obj <- output$displays[[display_idx]]
          if (!is.null(display_obj$display) && !is.null(display_obj$display$displaySections)) {
            for (section_idx in seq_along(display_obj$display$displaySections)) {
              section <- display_obj$display$displaySections[[section_idx]]
              datapath <- paste0("/outputs/", output_idx-1, "/displays/", display_idx-1, "/display/displaySections/", section_idx-1)

              record <- create_record_from_object(section, class_definition, datapath, record_idx)
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

extract_display_subsections <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in globalDisplaySections/subSections
  if (!is.null(json_data$globalDisplaySections)) {
    for (global_idx in seq_along(json_data$globalDisplaySections)) {
      global_section <- json_data$globalDisplaySections[[global_idx]]
      if (!is.null(global_section$subSections)) {
        for (sub_idx in seq_along(global_section$subSections)) {
          subsection <- global_section$subSections[[sub_idx]]
          datapath <- paste0("/globalDisplaySections/", global_idx-1, "/subSections/", sub_idx-1)

          record <- create_record_from_object(subsection, class_definition, datapath, record_idx)
          records[[record_idx]] <- record
          record_idx <- record_idx + 1
        }
      }
    }
  }

  # Also search in outputs/displays/display/displaySections/orderedSubSections/subSection
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$displays)) {
        for (display_idx in seq_along(output$displays)) {
          display_obj <- output$displays[[display_idx]]
          if (!is.null(display_obj$display) && !is.null(display_obj$display$displaySections)) {
            for (section_idx in seq_along(display_obj$display$displaySections)) {
              section <- display_obj$display$displaySections[[section_idx]]
              if (!is.null(section$orderedSubSections)) {
                for (ordered_idx in seq_along(section$orderedSubSections)) {
                  ordered_sub <- section$orderedSubSections[[ordered_idx]]
                  if (!is.null(ordered_sub$subSection)) {
                    datapath <- paste0("/outputs/", output_idx-1, "/displays/", display_idx-1, "/display/displaySections/", section_idx-1, "/orderedSubSections/", ordered_idx-1, "/subSection")

                    # Create the record first, then check if it has meaningful content
                    record <- create_record_from_object(ordered_sub$subSection, class_definition, datapath, record_idx)

                    # Only add if the record has meaningful content (not all NA except tablepath/datapath)
                    meaningful_cols <- setdiff(names(record), c("tablepath", "datapath"))
                    has_content <- any(!is.na(record[meaningful_cols]))

                    if (has_content) {
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
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_global_display_sections <- function(json_data, class_definition) {
  if (is.null(json_data$globalDisplaySections)) return(NULL)
  extract_array_objects(json_data$globalDisplaySections, class_definition, "/globalDisplaySections")
}

extract_ordered_subsections <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in various locations for orderedSubSections, but exclude ones with subSectionId (those are OrderedSubSectionRef)
  if (!is.null(json_data$outputs)) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$displays)) {
        for (display_idx in seq_along(output$displays)) {
          display_obj <- output$displays[[display_idx]]
          if (!is.null(display_obj$display) && !is.null(display_obj$display$displaySections)) {
            for (section_idx in seq_along(display_obj$display$displaySections)) {
              section <- display_obj$display$displaySections[[section_idx]]
              if (!is.null(section$orderedSubSections)) {
                for (ordered_idx in seq_along(section$orderedSubSections)) {
                  ordered_sub <- section$orderedSubSections[[ordered_idx]]

                  # Only extract if this orderedSubSection does NOT have a subSectionId (those are OrderedSubSectionRef)
                  if (is.null(ordered_sub$subSectionId)) {
                    datapath <- paste0("/outputs/", output_idx-1, "/displays/", display_idx-1, "/display/displaySections/", section_idx-1, "/orderedSubSections/", ordered_idx-1)

                    record <- create_record_from_object(ordered_sub, class_definition, datapath, record_idx)
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
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_ordered_displays <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in outputs/displays
  if (!is.null(json_data$outputs) && length(json_data$outputs) > 0) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$displays) && length(output$displays) > 0) {
        display <- output$displays[[1]]  # Assuming first display
        datapath <- paste0("/outputs/", output_idx-1, "/displays/0")

        record <- create_record_from_object(display, class_definition, datapath, record_idx)
        records[[record_idx]] <- record
        record_idx <- record_idx + 1
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_ordered_subsection_refs <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Search in outputs/displays/display/displaySections/orderedSubSections, but only for refs with subSectionId
  if (!is.null(json_data$outputs) && length(json_data$outputs) > 0) {
    for (output_idx in seq_along(json_data$outputs)) {
      output <- json_data$outputs[[output_idx]]
      if (!is.null(output$displays) && length(output$displays) > 0) {
        for (display_idx in seq_along(output$displays)) {
          display_obj <- output$displays[[display_idx]]
          if (!is.null(display_obj$display) && !is.null(display_obj$display$displaySections) && length(display_obj$display$displaySections) > 0) {
            for (section_idx in seq_along(display_obj$display$displaySections)) {
              section <- display_obj$display$displaySections[[section_idx]]
              if (!is.null(section$orderedSubSections) && length(section$orderedSubSections) > 0) {
                for (ordered_idx in seq_along(section$orderedSubSections)) {
                  ordered_sub <- section$orderedSubSections[[ordered_idx]]

                  # Only extract if this orderedSubSection has a subSectionId (making it a reference)
                  if (!is.null(ordered_sub$subSectionId)) {
                    datapath <- paste0("/outputs/", output_idx-1, "/displays/", display_idx-1, "/display/displaySections/", section_idx-1, "/orderedSubSections/", ordered_idx-1)

                    record <- create_record_from_object(ordered_sub, class_definition, datapath, record_idx)
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
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

# List of Contents Classes

extract_list_of_contents <- function(json_data, class_definition) {
  records <- list()

  # mainListOfContents
  if (!is.null(json_data$mainListOfContents)) {
    record <- create_record_from_object(json_data$mainListOfContents, class_definition, "/mainListOfContents", 1)
    records[[1]] <- record
  }

  # otherListsOfContents
  if (!is.null(json_data$otherListsOfContents) && length(json_data$otherListsOfContents) > 0) {
    for (i in seq_along(json_data$otherListsOfContents)) {
      other_list <- json_data$otherListsOfContents[[i]]
      datapath <- paste0("/otherListsOfContents/", i-1)
      record <- create_record_from_object(other_list, class_definition, datapath, length(records) + 1)
      records[[length(records) + 1]] <- record
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_nested_lists <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Helper function to recursively find all sublists
  extract_all_sublists <- function(list_items, base_path) {
    nested_records <- list()

    if (!is.null(list_items) && length(list_items) > 0) {
      for (item_idx in seq_along(list_items)) {
        item <- list_items[[item_idx]]

        # If this item has a sublist, extract it as a NestedList
        if (!is.null(item$sublist)) {
          sublist_path <- paste0(base_path, "/", item_idx-1, "/sublist")
          record <- create_record_from_object(item$sublist, class_definition, sublist_path, record_idx)
          nested_records[[length(nested_records) + 1]] <- record
          record_idx <<- record_idx + 1

          # Recursively extract deeper sublists
          if (!is.null(item$sublist$listItems)) {
            deeper_sublists <- extract_all_sublists(item$sublist$listItems, paste0(sublist_path, "/listItems"))
            nested_records <- c(nested_records, deeper_sublists)
          }
        }
      }
    }

    return(nested_records)
  }

  # Search in mainListOfContents/contentsList
  if (!is.null(json_data$mainListOfContents$contentsList)) {
    record <- create_record_from_object(json_data$mainListOfContents$contentsList, class_definition, "/mainListOfContents/contentsList", record_idx)
    records[[record_idx]] <- record
    record_idx <- record_idx + 1

    # Extract all sublists recursively
    if (!is.null(json_data$mainListOfContents$contentsList$listItems)) {
      sublist_records <- extract_all_sublists(json_data$mainListOfContents$contentsList$listItems, "/mainListOfContents/contentsList/listItems")
      records <- c(records, sublist_records)
    }
  }

  # Search in otherListsOfContents/contentsList
  if (!is.null(json_data$otherListsOfContents)) {
    for (i in seq_along(json_data$otherListsOfContents)) {
      other_list <- json_data$otherListsOfContents[[i]]
      if (!is.null(other_list$contentsList)) {
        datapath <- paste0("/otherListsOfContents/", i-1, "/contentsList")
        record <- create_record_from_object(other_list$contentsList, class_definition, datapath, record_idx)
        records[[record_idx]] <- record
        record_idx <- record_idx + 1

        # Extract all sublists recursively for otherListsOfContents too
        if (!is.null(other_list$contentsList$listItems)) {
          sublist_records <- extract_all_sublists(other_list$contentsList$listItems, paste0(datapath, "/listItems"))
          records <- c(records, sublist_records)
        }
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}

extract_ordered_list_items <- function(json_data, class_definition) {
  records <- list()
  record_idx <- 1

  # Helper function to recursively extract list items from nested sublists
  extract_nested_list_items <- function(list_items, base_path) {
    nested_records <- list()

    if (!is.null(list_items) && length(list_items) > 0) {
      for (item_idx in seq_along(list_items)) {
        item <- list_items[[item_idx]]
        datapath <- paste0(base_path, "/", item_idx-1)

        # Extract this list item
        record <- create_record_from_object(item, class_definition, datapath, record_idx)
        nested_records[[length(nested_records) + 1]] <- record
        record_idx <<- record_idx + 1

        # Recursively extract from sublists
        if (!is.null(item$sublist) && !is.null(item$sublist$listItems)) {
          sublist_path <- paste0(datapath, "/sublist/listItems")
          sublist_records <- extract_nested_list_items(item$sublist$listItems, sublist_path)
          nested_records <- c(nested_records, sublist_records)
        }
      }
    }

    return(nested_records)
  }

  # Search in mainListOfContents/contentsList/listItems
  if (!is.null(json_data$mainListOfContents) && !is.null(json_data$mainListOfContents$contentsList) && !is.null(json_data$mainListOfContents$contentsList$listItems)) {
    main_records <- extract_nested_list_items(json_data$mainListOfContents$contentsList$listItems, "/mainListOfContents/contentsList/listItems")
    records <- c(records, main_records)
  }

  # Also search in otherListsOfContents/contentsList/listItems
  if (!is.null(json_data$otherListsOfContents) && length(json_data$otherListsOfContents) > 0) {
    for (other_idx in seq_along(json_data$otherListsOfContents)) {
      other_list <- json_data$otherListsOfContents[[other_idx]]
      if (!is.null(other_list$contentsList) && !is.null(other_list$contentsList$listItems)) {
        other_base_path <- paste0("/otherListsOfContents/", other_idx-1, "/contentsList/listItems")
        other_records <- extract_nested_list_items(other_list$contentsList$listItems, other_base_path)
        records <- c(records, other_records)
      }
    }
  }

  if (length(records) > 0) do.call(rbind, records) else NULL
}