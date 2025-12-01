#' Create Class Datasets for JSON ReportingEvent
#'
#' Reads in a JSON ReportEvent to create a separate dataset for each ARS class
#' referenced in the reporting event. This is the main orchestration function
#' that replicates the functionality of create_class_datasets_for_json_reportingevent.sas
#'
#' @description
#' In the created class datasets:
#' - There is one observation for each instance of the class.
#' - On each observation:
#'   * The TABLEPATH variable contains the path for source dataset mapped in the JSON file.
#'   * The DATAPATH variable contains a value (specified using JSON Pointer notation)
#'     indicating the location of the corresponding data in the input JSON reporting event file.
#' - Multiple atomic values (e.g., multiple strings or multiple numeric values) for a
#'   single attribute/slot are transposed into separate variables (e.g., value1, value2, etc.).
#'
#' @param json_schema_file Character string. Path to the JSON-Schema definition file
#'   for the ARS model (ars_ldm.json)
#' @param reporting_event_json_file Character string. Path to the JSON file containing
#'   the reporting event information to be converted to datasets
#' @param output_directory Character string. Path to the directory that will contain
#'   the class-specific datasets created from the JSON reporting event file
#' @param temp_directory Character string. Path to temporary directory for intermediate files.
#'   Defaults to "temp/class_datasets_pipeline"
#' @param class_library_name Character string. Name prefix for the class dataset library.
#'   Defaults to "classds"
#' @param verbose Logical. Whether to print detailed progress messages. Defaults to TRUE
#' @param clean_temp Logical. Whether to clean up temporary files after processing. Defaults to FALSE
#'
#' @return List containing:
#'   - class_datasets: List of data frames, one per class
#'   - classes_processed: Character vector of class names created
#'   - output_files: Character vector of output file paths
#'   - summary: List with processing statistics
#'   - temp_directory: Path to temporary files directory
#'
#' @details
#' This function orchestrates the complete ARS JSON processing pipeline using the modular
#' schema-driven extractor architecture:
#' 1. **get_class_slots**: Create dataset containing class/slot definitions from JSON-Schema file
#' 2. **extract_schema_driven_datasets**: Extract class-specific datasets using modular extractors
#' 3. **apply_sas_compatible_formatting**: Apply SAS-compatible formatting and structure
#'
#' The modular extractor uses specialized modules for different ARS class types:
#' - extractor_analysis.R: Analysis, Operation, AnalysisSet, DataSubset classes
#' - extractor_output.R: Output, DisplaySection, ListOfContents classes
#' - extractor_reference.R: DocumentReference, PageRef classes
#' - extractor_metadata.R: TerminologyExtension, SponsorTerm classes
#'
#' The DATAPATH values are '/' delimited lists of attribute/slot names and, for repeating
#' objects, zero-indexed ordinal values. For example, a DATAPATH value of
#' "/methods/1/operations/0" indicates the first item (ordinal = 0) in the list of items
#' specified for the "operations" attribute of the second item (ordinal = 1) in the list
#' of items specified for the "methods" attribute of the reporting event.
#'
#' The DATAPATH variable may be used to reassemble information that is split across
#' multiple class datasets. For example, OperationResult records can be combined with
#' corresponding ResultGroup records using data manipulation:
#'
#' ```r
#' combined_results <- operation_result %>%
#'   left_join(result_group,
#'             by = join_by(substr(result_group$datapath, 1, nchar(operation_result$datapath)) ==
#'                         operation_result$datapath))
#' ```
#'
#' This works because the first part of a child object's DATAPATH value matches the
#' DATAPATH value of its parent.
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' result <- create_class_datasets_for_json_reportingevent(
#'   json_schema_file = "model/ars_ldm.json",
#'   reporting_event_json_file = "workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json",
#'   output_directory = tempdir()
#' )
#'
#' # Access created class datasets
#' analysis_data <- result$class_datasets$Analysis
#' output_data <- result$class_datasets$Output
#'
#' result <- create_class_datasets_for_json_reportingevent(
#'   json_schema_file = "model/ars_ldm.json",
#'   reporting_event_json_file = "workfiles/examples/ARS v1/Common Safety Displays.json",
#'   output_directory = tempdir()
#' )
#'
#' # View processing summary
#' print(result$summary)
#' }
#'
#' @export
create_class_datasets_for_json_reportingevent <- function(
  json_schema_file,
  reporting_event_json_file,
  output_directory,
  temp_directory = tempdir(),
  class_library_name = "classds",
  verbose = TRUE,
  clean_temp = FALSE
) {
  # Input validation
  if (!file.exists(json_schema_file)) {
    stop("JSON schema file not found: ", json_schema_file)
  }

  if (!file.exists(reporting_event_json_file)) {
    stop("Reporting event JSON file not found: ", reporting_event_json_file)
  }

  if (!dir.exists(dirname(output_directory))) {
    stop("Output directory parent does not exist: ", dirname(output_directory))
  }

  # Create output and temp directories if they don't exist
  if (!dir.exists(output_directory)) {
    dir.create(output_directory, recursive = TRUE)
  }

  if (!dir.exists(temp_directory)) {
    dir.create(temp_directory, recursive = TRUE)
  }

  # Load required libraries
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required but not installed")
  }

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required but not installed")
  }

  # Load libraries for use by helper functions
  library(jsonlite)
  library(dplyr)

  # Source required helper functions
  helpers_dir <- file.path("utilities", "R", "helpers")

  required_helpers <- c(
    "get_class_slots.R",
    "schema_driven_extractor_modular.R"
  )

  for (helper in required_helpers) {
    helper_path <- file.path(helpers_dir, helper)
    if (file.exists(helper_path)) {
      source(helper_path)
    } else {
      stop("Required helper function not found: ", helper_path)
    }
  }

  if (verbose) {
    cat("=== ARS JSON REPORTING EVENT PROCESSING ===\n")
    cat("Schema file:", json_schema_file, "\n")
    cat("JSON file:", reporting_event_json_file, "\n")
    cat("Output directory:", output_directory, "\n")
    cat("Temp directory:", temp_directory, "\n\n")
  }

  start_time <- Sys.time()

  # =========================================================================
  # STEP 1: Create dataset containing class/slot definitions from JSON-Schema
  # =========================================================================

  if (verbose) {
    cat("Step 1: Reading class/slot definitions from JSON schema...\n")
  }

  class_slots <- get_class_slots(json_schema_file)

  if (verbose) {
    cat("  ✓ Found", nrow(class_slots), "class/slot definitions\n\n")
  }

  # =========================================================================
  # STEP 2: Extract and format class datasets from JSON using modular schema extractor
  # =========================================================================

  if (verbose) {
    cat("Step 2: Extracting and formatting class datasets using modular schema extractor...\n")
  }

  # Extract class datasets using modular schema-driven approach
  # This loads and uses specialized extraction modules
  class_datasets <- extract_schema_driven_datasets(reporting_event_json_file, class_slots)

  # Apply SAS-compatible formatting (tablepath, array normalization, column cleanup)
  class_datasets <- apply_sas_compatible_formatting(class_datasets, class_slots)

  # Write datasets to output directory
  output_files <- character(0)
  for (class_name in names(class_datasets)) {
    dataset <- class_datasets[[class_name]]
    if (nrow(dataset) > 0) {
      output_file <- file.path(output_directory, paste0(class_name, ".csv"))
      write.csv(dataset, output_file, row.names = FALSE)
      output_files <- c(output_files, output_file)
    }
  }

  class_result <- list(
    class_datasets = class_datasets,
    classes_processed = names(class_datasets),
    output_files = output_files
  )

  if (verbose) {
    cat("  ✓ Created", length(class_result$class_datasets), "ARS class datasets\n")
    cat("  ✓ Classes processed:", paste(class_result$classes_processed, collapse = ", "), "\n\n")
  }

  # =========================================================================
  # STEP 3: Generate summary and cleanup
  # =========================================================================

  end_time <- Sys.time()
  processing_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Create comprehensive summary
  summary_info <- list(
    processing_time_seconds = processing_time,
    json_schema_file = json_schema_file,
    reporting_event_json_file = reporting_event_json_file,
    output_directory = output_directory,
    temp_directory = temp_directory,
    class_datasets_created = length(class_result$class_datasets),
    classes_processed = class_result$classes_processed,
    total_observations = if (length(class_result$class_datasets) > 0) sum(sapply(class_result$class_datasets, nrow)) else 0,
    total_variables = if (length(class_result$class_datasets) > 0) sum(sapply(class_result$class_datasets, ncol)) else 0
  )

  if (verbose) {
    cat("=== PROCESSING COMPLETE ===\n")
    cat("Total processing time:", round(processing_time, 2), "seconds\n")
    cat("Classes created:", summary_info$class_datasets_created, "\n")
    cat("Total observations:", summary_info$total_observations, "\n")
    cat("Output saved to:", output_directory, "\n")

    if (!clean_temp) {
      cat("Temporary files retained in:", temp_directory, "\n")
    }
  }

  # Optional cleanup
  if (clean_temp && dir.exists(temp_directory)) {
    if (verbose) {
      cat("Cleaning up temporary files...\n")
    }
    unlink(temp_directory, recursive = TRUE)
  }

  # Return comprehensive results
  result <- list(
    class_datasets = class_result$class_datasets,
    classes_processed = class_result$classes_processed,
    output_files = class_result$output_files,
    summary = summary_info,
    temp_directory = if (!clean_temp) temp_directory else NULL
  )

  return(result)
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

#' Command Line Interface for ARS JSON Processing
#'
#' Provides a command-line interface similar to the SAS version
process_json_reportingevent_cli <- function() {
  # Parse command line arguments
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    return(invisible())
  }

  if (length(args) < 3) {
    stop("Error: At least 3 arguments required. Run with no arguments for usage.")
  }

  schema_file <- args[1]
  json_file <- args[2]
  output_dir <- args[3]
  temp_dir <- if (length(args) >= 4) args[4] else "temp/class_datasets_pipeline"

  # Run the processing
  cat("Starting ARS JSON ReportingEvent processing...\n")

  result <- create_class_datasets_for_json_reportingevent(
    json_schema_file = schema_file,
    reporting_event_json_file = json_file,
    output_directory = output_dir,
    temp_directory = temp_dir,
    verbose = TRUE
  )

  cat("\nProcessing completed successfully!\n")
  cat("Class datasets created:", length(result$class_datasets), "\n")
  cat("Output location:", output_dir, "\n")

  return(invisible(result))
}

# Run CLI if script is executed directly
if (!interactive()) {
  process_json_reportingevent_cli()
}
