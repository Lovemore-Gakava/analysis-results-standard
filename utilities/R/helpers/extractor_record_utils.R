#' Record Creation and Formatting Utilities
#'
#' Core utilities for creating data records from JSON objects and applying
#' SAS-compatible formatting.
#'
#' @export

#' Extract objects from JSON array
#' @param json_array Array of JSON objects
#' @param class_definition Class schema definition
#' @param base_path Base JSON path for this array
#' @return Data frame with extracted records
extract_array_objects <- function(json_array, class_definition, base_path) {
  if (is.null(json_array) || length(json_array) == 0) return(NULL)

  records <- list()
  for (i in seq_along(json_array)) {
    obj <- json_array[[i]]
    datapath <- paste0(base_path, "/", i-1)
    record <- create_record_from_object(obj, class_definition, datapath, i)
    records[[i]] <- record
  }

  do.call(rbind, records)
}

#' Create a record from JSON object based on class definition
#' @param json_obj JSON object to extract from
#' @param class_definition Schema definition for this class
#' @param datapath JSON path to this object
#' @param record_id Unique record identifier
#' @return Data frame with single record
create_record_from_object <- function(json_obj, class_definition, datapath, record_id) {

  # Initialize record list (safer than data.frame for dynamic creation)
  record_list <- list(
    tablepath = gsub("/[0-9]+", "", datapath),  # Remove indices for tablepath
    datapath = datapath
  )

  # Extract schema-defined fields
  for (i in seq_len(nrow(class_definition))) {
    slot_info <- class_definition[i, ]
    slot_name <- slot_info$slot

    # Get value from JSON object (with bounds checking)
    if (!is.null(json_obj) && slot_name %in% names(json_obj) && !is.null(json_obj[[slot_name]])) {
      value <- json_obj[[slot_name]]

      # Only extract scalar/simple attributes - skip complex nested objects
      # Include Enum types as they are scalar enumeration values
      if (slot_info$range %in% c("string", "integer", "number", "boolean") ||
          grepl("Enum$", slot_info$range)) {
        # Simple scalar types
        if (is.list(value) && slot_info$is_array == 1) {
          # Simple array of scalars - flatten to pipe-separated string
          tryCatch({
            flattened <- unlist(value)
            if (length(flattened) > 1) {
              record_list[[slot_name]] <- paste(as.character(flattened), collapse = "|")
            } else if (length(flattened) == 1) {
              record_list[[slot_name]] <- as.character(flattened)
            } else {
              record_list[[slot_name]] <- NA_character_
            }
          }, error = function(e) {
            record_list[[slot_name]] <- NA_character_
          })
        } else if (!is.list(value)) {
          # Simple scalar value
          tryCatch({
            if (slot_info$range == "integer" && is.numeric(value)) {
              record_list[[slot_name]] <- as.integer(value)
            } else {
              record_list[[slot_name]] <- as.character(value)[1]
            }
          }, error = function(e) {
            record_list[[slot_name]] <- NA_character_
          })
        } else {
          # Complex object for simple type - skip
          record_list[[slot_name]] <- NA_character_
        }
      } else {
        # Complex type (like OperationResult, OrderedGroupingFactor, etc.)
        # These should be handled by their own class datasets - skip here
        record_list[[slot_name]] <- NA_character_
      }
    } else {
      # Set missing values as NA
      record_list[[slot_name]] <- NA_character_
    }
  }

  # Convert list to data.frame
  tryCatch({
    record <- as.data.frame(record_list, stringsAsFactors = FALSE)
    return(record)
  }, error = function(e) {
    # If conversion fails, return a minimal record
    return(data.frame(
      tablepath = record_list$tablepath,
      datapath = record_list$datapath,
      error_message = paste("Failed to create record:", e$message),
      stringsAsFactors = FALSE
    ))
  })
}

#' Apply SAS-compatible formatting to extracted datasets
#'
#' Fixes tablepath, handles array fields as separate columns, removes extra columns
#' @param class_datasets List of extracted datasets
#' @param class_slots Schema class definitions
#' @return List of formatted datasets
apply_sas_compatible_formatting <- function(class_datasets, class_slots) {

  cat("Applying SAS-compatible formatting...\n")

  formatted_datasets <- list()

  for (class_name in names(class_datasets)) {
    dataset <- class_datasets[[class_name]]

    if (nrow(dataset) == 0) {
      formatted_datasets[[class_name]] <- dataset
      next
    }

    # Get class definition for array field handling
    class_definition <- class_slots[class_slots$parent_class == class_name, ]

    # 1. Fix tablepath - add /root prefix
    if ("tablepath" %in% names(dataset)) {
      dataset$tablepath <- ifelse(
        startsWith(dataset$tablepath, "/root"),
        dataset$tablepath,
        paste0("/root", dataset$tablepath)
      )
    }

    # 2. Handle array fields - convert pipe-separated to separate columns
    array_fields <- class_definition[class_definition$is_array == 1, ]

    for (i in seq_len(nrow(array_fields))) {
      field_name <- array_fields$slot[i]

      if (field_name %in% names(dataset)) {
        # Split pipe-separated values into separate columns
        for (row_idx in seq_len(nrow(dataset))) {
          value <- dataset[[field_name]][row_idx]

          if (!is.na(value) && value != "") {
            # Split by pipe
            parts <- strsplit(as.character(value), "\\|")[[1]]

            # Create separate columns
            for (j in seq_along(parts)) {
              col_name <- paste0(field_name, j)
              if (!col_name %in% names(dataset)) {
                dataset[[col_name]] <- NA_character_
              }
              dataset[[col_name]][row_idx] <- parts[j]
            }
          }
        }

        # Remove the original concatenated column
        dataset[[field_name]] <- NULL
      }
    }

    # 3. Remove unwanted columns
    # Remove NA columns, complex object columns that should be handled by other classes
    extra_cols <- grep("^NA\\.|^X\\.", names(dataset), value = TRUE)

    # Also remove complex object fields that were set to NA (they belong to other classes)
    complex_fields <- class_definition[!class_definition$range %in% c("string", "integer", "number", "boolean"), ]
    complex_col_names <- complex_fields$slot[complex_fields$slot %in% names(dataset)]

    # Check if these columns contain only NA values - if so, remove them
    for (col_name in complex_col_names) {
      if (all(is.na(dataset[[col_name]]))) {
        extra_cols <- c(extra_cols, col_name)
      }
    }

    # Remove duplicates and only keep columns that exist
    extra_cols <- unique(extra_cols)
    extra_cols <- extra_cols[extra_cols %in% names(dataset)]

    if (length(extra_cols) > 0) {
      dataset[extra_cols] <- NULL
    }

    # 4. Reorder columns to match SAS: tablepath, datapath, then alphabetical
    core_cols <- c("tablepath", "datapath")
    other_cols <- setdiff(names(dataset), core_cols)
    other_cols <- sort(other_cols)

    final_cols <- c(
      core_cols[core_cols %in% names(dataset)],
      other_cols
    )

    dataset <- dataset[final_cols]

    formatted_datasets[[class_name]] <- dataset
    cat("  ✓ Formatted", class_name, ":", nrow(dataset), "records\n")
  }

  return(formatted_datasets)
}