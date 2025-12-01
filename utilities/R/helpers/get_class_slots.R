#' Get Class Slots from ARS JSON Schema
#'
#' Reads a JSON-Schema representation of the ARS Model to create a data frame
#' containing class attribute/slot properties. This is the R equivalent of the
#' SAS macro get_class_slots.sas.
#'
#' @param json_schema_file Path to the local copy of the JSON-Schema definition
#'   file for the ARS model (ars_ldm.json), which can be downloaded from the
#'   model folder of the ARS GitHub repository.
#' @param return_type Character string specifying the return format. Options are:
#'   "data.frame" (default) for a standard data frame, or "list" for a named list
#'   structure for easier programmatic access.
#' @param include_unused Logical indicating whether to include slots marked as
#'   "NOT USED" in the schema (default: FALSE).
#'
#' @return A data frame (or list if return_type="list") containing class/slot
#'   definitions with the following columns:
#'   \describe{
#'     \item{parent_class}{Character. The parent class that contains this slot}
#'     \item{slot}{Character. The name of the attribute/slot}
#'     \item{range}{Character. The data type or class that this slot references}
#'     \item{is_reqd}{Logical. Whether this slot is required in the parent class}
#'     \item{is_array}{Logical. Whether this slot can contain multiple values}
#'     \item{is_anyOf}{Logical. Whether this slot uses anyOf schema construct}
#'   }
#'
#' @details
#' This function processes the ARS JSON Schema to extract class and slot
#' definitions that describe the structure of ARS objects. It identifies:
#' \itemize{
#'   \item Parent-child relationships between classes
#'   \item Required vs. optional attributes
#'   \item Data types and references for each slot
#'   \item Array/list properties
#'   \item Unused slots (excluded by default)
#' }
#'
#' The function mimics the behavior of the SAS get_class_slots macro, providing
#' equivalent functionality for R-based ARS processing workflows.
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' schema_file <- "model/ars_ldm.json"
#' class_slots <- get_class_slots(schema_file)
#'
#' # Include unused slots
#' all_slots <- get_class_slots(schema_file, include_unused = TRUE)
#'
#' # Return as list for programmatic access
#' slots_list <- get_class_slots(schema_file, return_type = "list")
#' }
#'
#' @export
get_class_slots <- function(json_schema_file, return_type = "data.frame", include_unused = FALSE) {
  # Input validation
  if (!file.exists(json_schema_file)) {
    stop("JSON schema file not found: ", json_schema_file)
  }

  if (!return_type %in% c("data.frame", "list")) {
    stop("return_type must be 'data.frame' or 'list'")
  }

  # Load required packages
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required but not installed.")
  }

  # Read the JSON schema
  tryCatch(
    {
      schema <- jsonlite::fromJSON(json_schema_file, simplifyVector = FALSE)
    },
    error = function(e) {
      stop("Failed to read JSON schema file: ", e$message)
    }
  )

  # Check for required schema structure
  if (!"$defs" %in% names(schema)) {
    stop("Invalid ARS schema: Missing '$defs' section")
  }

  # Initialize result data frame with numeric flags (SAS compatibility: 1/0 instead of TRUE/FALSE)
  # Column order matches SAS CSV: parent_class, slot, is_reqd, is_array, is_anyOf, range
  result_df <- data.frame(
    parent_class = character(0),
    slot = character(0),
    is_reqd = integer(0),
    is_array = integer(0),
    is_anyOf = integer(0),
    range = character(0),
    stringsAsFactors = FALSE
  )

  # Extract unused slots (marked as "NOT USED")
  unused_slots <- character(0)
  if (!include_unused) {
    unused_slots <- find_unused_slots(schema)
  }

  # Process each class definition in $defs
  defs <- schema[["$defs"]]
  required_slots <- extract_required_slots(defs)

  for (class_name in names(defs)) {
    class_def <- defs[[class_name]]

    if (!"properties" %in% names(class_def)) {
      next
    }

    properties <- class_def[["properties"]]

    for (slot_name in names(properties)) {
      # Skip unused slots if not including them
      slot_key <- paste(class_name, slot_name, sep = ".")
      if (!include_unused && slot_key %in% unused_slots) {
        next
      }

      slot_def <- properties[[slot_name]]

      # Extract slot information
      slot_info <- parse_slot_definition(slot_def, class_name, slot_name)

      # Check if required
      is_required <- slot_key %in% required_slots

      # Handle anyOf options - create separate rows like SAS
      if (slot_info$is_anyOf && "anyOf_options" %in% names(slot_info) && length(slot_info$anyOf_options) > 0) {
        for (range_option in slot_info$anyOf_options) {
          result_df <- rbind(
            result_df,
            data.frame(
              parent_class = class_name,
              slot = slot_name,
              is_reqd = as.integer(is_required),
              is_array = as.integer(slot_info$is_array),
              is_anyOf = as.integer(slot_info$is_anyOf),
              range = range_option,
              stringsAsFactors = FALSE
            )
          )
        }
      } else {
        # Add single entry for non-anyOf slots
        result_df <- rbind(
          result_df,
          data.frame(
            parent_class = class_name,
            slot = slot_name,
            is_reqd = as.integer(is_required),
            is_array = as.integer(slot_info$is_array),
            is_anyOf = as.integer(slot_info$is_anyOf),
            range = slot_info$range,
            stringsAsFactors = FALSE
          )
        )
      }
    }
  }

  # Add the "root" entry (equivalent to SAS version)
  result_df <- rbind(
    result_df,
    data.frame(
      parent_class = NA_character_,
      slot = "root",
      is_reqd = 1L,
      is_array = 0L,
      is_anyOf = 0L,
      range = "ReportingEvent",
      stringsAsFactors = FALSE
    )
  )

  # Return in requested format
  if (return_type == "list") {
    return(convert_to_list_format(result_df))
  } else {
    return(result_df)
  }
}

#' Find slots marked as "NOT USED" in the schema
#' @param schema The parsed JSON schema
#' @return Character vector of unused slot keys in format "class.slot"
#' @keywords internal
find_unused_slots <- function(schema) {
  unused <- character(0)

  if (!"$defs" %in% names(schema)) {
    return(unused)
  }

  defs <- schema[["$defs"]]

  for (class_name in names(defs)) {
    class_def <- defs[[class_name]]

    if (!"properties" %in% names(class_def)) {
      next
    }

    properties <- class_def[["properties"]]

    for (slot_name in names(properties)) {
      slot_def <- properties[[slot_name]]

      # Check if description indicates "NOT USED"
      if ("description" %in% names(slot_def)) {
        if (grepl("NOT USED", slot_def[["description"]], ignore.case = TRUE)) {
          unused <- c(unused, paste(class_name, slot_name, sep = "."))
        }
      }
    }
  }

  return(unused)
}

#' Extract required slots from schema definitions
#' @param defs The $defs section of the JSON schema
#' @return Character vector of required slot keys in format "class.slot"
#' @keywords internal
extract_required_slots <- function(defs) {
  required <- character(0)

  for (class_name in names(defs)) {
    class_def <- defs[[class_name]]

    if ("required" %in% names(class_def)) {
      required_props <- class_def[["required"]]
      # Convert list to character vector if needed (jsonlite parsing)
      if (is.list(required_props)) {
        required_props <- unlist(required_props)
      }
      if (is.character(required_props)) {
        required_keys <- paste(class_name, required_props, sep = ".")
        required <- c(required, required_keys)
      }
    }
  }

  return(required)
}

#' Parse individual slot definition from schema
#' @param slot_def The slot definition from the schema
#' @param class_name The parent class name
#' @param slot_name The slot name
#' @return List with parsed slot information
#' @keywords internal
parse_slot_definition <- function(slot_def, class_name, slot_name) {
  result <- list(
    range = "string", # default
    is_array = 0L,
    is_anyOf = 0L
  )

  # Check for $ref (reference to another class)
  if ("$ref" %in% names(slot_def)) {
    ref_path <- slot_def[["$ref"]]
    result$range <- extract_class_from_ref(ref_path)
  }

  # Check for type
  if ("type" %in% names(slot_def)) {
    slot_type <- slot_def[["type"]]
    if (slot_type == "array") {
      result$is_array <- 1L
      # For arrays, check the items definition
      if ("items" %in% names(slot_def)) {
        items_def <- slot_def[["items"]]
        if ("$ref" %in% names(items_def)) {
          result$range <- extract_class_from_ref(items_def[["$ref"]])
        } else if ("anyOf" %in% names(items_def)) {
          # Handle anyOf within array items
          result$is_anyOf <- 1L
          result$anyOf_options <- list()
          any_of_options <- items_def[["anyOf"]]
          for (option in any_of_options) {
            if ("$ref" %in% names(option)) {
              result$anyOf_options <- append(result$anyOf_options, extract_class_from_ref(option[["$ref"]]))
            } else if ("type" %in% names(option) && option[["type"]] != "null") {
              result$anyOf_options <- append(result$anyOf_options, option[["type"]])
            }
          }
          if (length(result$anyOf_options) > 0) {
            result$range <- result$anyOf_options[[1]]
          }
        } else if ("type" %in% names(items_def)) {
          result$range <- items_def[["type"]]
        }
      }
    } else {
      result$range <- slot_type
    }
  }

  # Check for anyOf - create separate entries for each option like SAS
  if ("anyOf" %in% names(slot_def)) {
    result$is_anyOf <- 1L
    result$anyOf_options <- list()
    any_of_options <- slot_def[["anyOf"]]
    for (option in any_of_options) {
      if ("$ref" %in% names(option)) {
        result$anyOf_options <- append(result$anyOf_options, extract_class_from_ref(option[["$ref"]]))
      } else if ("type" %in% names(option) && option[["type"]] != "null") {
        result$anyOf_options <- append(result$anyOf_options, option[["type"]])
      }
    }
    # Set range to first option for backward compatibility
    if (length(result$anyOf_options) > 0) {
      result$range <- result$anyOf_options[[1]]
    }
  }

  return(result)
}

#' Extract class name from JSON schema $ref path
#' @param ref_path The $ref path (e.g., "#/$defs/Analysis")
#' @return Character string with the class name
#' @keywords internal
extract_class_from_ref <- function(ref_path) {
  # Extract the last part after the final "/"
  parts <- strsplit(ref_path, "/")[[1]]
  return(parts[length(parts)])
}

#' Convert data frame result to list format
#' @param df The data frame to convert
#' @return Named list organized by parent class
#' @keywords internal
convert_to_list_format <- function(df) {
  result_list <- list()

  # Group by parent class
  classes <- unique(df$parent_class[!is.na(df$parent_class)])

  for (class_name in classes) {
    class_slots <- df[!is.na(df$parent_class) & df$parent_class == class_name, ]

    result_list[[class_name]] <- list(
      properties = setNames(
        lapply(seq_len(nrow(class_slots)), function(i) {
          list(
            range = class_slots$range[i],
            is_reqd = class_slots$is_reqd[i],
            is_array = class_slots$is_array[i],
            is_anyOf = class_slots$is_anyOf[i]
          )
        }),
        class_slots$slot
      )
    )
  }

  # Add root entry
  root_row <- df[!is.na(df$slot) & df$slot == "root", ]
  if (nrow(root_row) > 0) {
    result_list[["_root"]] <- list(
      slot = root_row$slot[1],
      range = root_row$range[1],
      is_reqd = root_row$is_reqd[1]
    )
  }

  return(result_list)
}
