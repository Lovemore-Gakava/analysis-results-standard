#!/usr/bin/env Rscript

#' Integration Tests for create_class_datasets_for_json_reportingevent.R
#'
#' Tests the complete pipeline from JSON schema and data to class datasets
#'
#' Usage: Rscript test_create_class_datasets.R

# Load required libraries
library(jsonlite)
library(dplyr)

# Declare paths
main_script_path <- file.path("utilities/R/create_class_datasets_for_json_reportingevent.R")
fixtures_path <- file.path("utilities/R/tests/fixtures")
model_path <- file.path("model")
temp_base <- file.path("utilities/R/tests")

# Source the function under test
source(main_script_path)

# Test configuration
test_schema_file <- file.path(fixtures_path, "test_schema.json")
test_data_file <- file.path(fixtures_path, "test_data.json")
real_schema_file <- file.path(model_path, "ars_ldm.json")
real_data_file <- file.path("workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json")
test_output_dir <- file.path(temp_base, "temp_output")
test_temp_dir <- file.path(temp_base, "temp_temp")

#' Test helper function to run a test and report results
run_test <- function(test_name, test_func) {
  cat("Testing:", test_name, "... ")

  tryCatch({
    result <- test_func()
    if (result) {
      cat("✅ PASS\n")
      return(TRUE)
    } else {
      cat("❌ FAIL\n")
      return(FALSE)
    }
  }, error = function(e) {
    cat("❌ ERROR:", e$message, "\n")
    return(FALSE)
  })
}

#' Setup function to create test directories
setup_test_dirs <- function() {
  if (!dir.exists(test_output_dir)) {
    dir.create(test_output_dir, recursive = TRUE)
  }
  if (!dir.exists(test_temp_dir)) {
    dir.create(test_temp_dir, recursive = TRUE)
  }
}

#' Cleanup function to remove test directories
cleanup_test_dirs <- function() {
  if (dir.exists(test_output_dir)) {
    unlink(test_output_dir, recursive = TRUE)
  }
  if (dir.exists(test_temp_dir)) {
    unlink(test_temp_dir, recursive = TRUE)
  }
}

#' Test 1: Function exists
test_function_exists <- function() {
  return(exists("create_class_datasets_for_json_reportingevent"))
}

#' Test 2: Invalid input handling
test_invalid_inputs <- function() {
  setup_test_dirs()

  # Test with non-existent schema file
  result1 <- tryCatch({
    create_class_datasets_for_json_reportingevent(
      json_schema_file = "nonexistent.json",
      reporting_event_json_file = test_data_file,
      output_directory = test_output_dir,
      verbose = FALSE
    )
    return(FALSE)  # Should have thrown an error
  }, error = function(e) {
    return(TRUE)   # Expected error
  })

  # Test with non-existent data file
  result2 <- tryCatch({
    create_class_datasets_for_json_reportingevent(
      json_schema_file = test_schema_file,
      reporting_event_json_file = "nonexistent.json",
      output_directory = test_output_dir,
      verbose = FALSE
    )
    return(FALSE)  # Should have thrown an error
  }, error = function(e) {
    return(TRUE)   # Expected error
  })

  cleanup_test_dirs()
  return(result1 && result2)
}

#' Test 3: Complete pipeline with test fixtures
test_complete_pipeline_fixtures <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  setup_test_dirs()

  result <- create_class_datasets_for_json_reportingevent(
    json_schema_file = test_schema_file,
    reporting_event_json_file = test_data_file,
    output_directory = test_output_dir,
    temp_directory = test_temp_dir,
    verbose = FALSE
  )

  # Should return a list with expected structure
  if (!is.list(result)) {
    cleanup_test_dirs()
    return(FALSE)
  }

  expected_elements <- c("class_datasets", "classes_processed", "output_files", "summary")
  if (!all(expected_elements %in% names(result))) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Should have extracted some classes
  if (length(result$class_datasets) == 0) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Should have created output files
  if (length(result$output_files) == 0) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Files should actually exist
  for (file_path in result$output_files) {
    if (!file.exists(file_path)) {
      cleanup_test_dirs()
      return(FALSE)
    }
  }

  cleanup_test_dirs()
  return(TRUE)
}

#' Test 4: Real data processing (if available)
test_real_data_processing <- function() {
  if (!file.exists(real_schema_file) || !file.exists(real_data_file)) {
    cat("(SKIP - real data not found) ")
    return(TRUE)
  }

  setup_test_dirs()

  result <- create_class_datasets_for_json_reportingevent(
    json_schema_file = real_schema_file,
    reporting_event_json_file = real_data_file,
    output_directory = test_output_dir,
    temp_directory = test_temp_dir,
    verbose = FALSE
  )

  # Should have processed many classes
  if (length(result$class_datasets) < 10) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Should include key ARS classes
  expected_classes <- c("Analysis", "Operation", "ReportingEvent")
  found_classes <- names(result$class_datasets)

  if (!all(expected_classes %in% found_classes)) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Should have meaningful data
  if (result$summary$total_observations < 100) {
    cleanup_test_dirs()
    return(FALSE)
  }

  cleanup_test_dirs()
  return(TRUE)
}

#' Test 5: Output file validation
test_output_file_validation <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  setup_test_dirs()

  result <- create_class_datasets_for_json_reportingevent(
    json_schema_file = test_schema_file,
    reporting_event_json_file = test_data_file,
    output_directory = test_output_dir,
    verbose = FALSE
  )

  # Check that output files have correct structure
  for (file_path in result$output_files) {
    # Read the CSV file
    tryCatch({
      data <- read.csv(file_path, stringsAsFactors = FALSE)

      # Should have tablepath and datapath columns
      required_cols <- c("tablepath", "datapath")
      if (!all(required_cols %in% names(data))) {
        cleanup_test_dirs()
        return(FALSE)
      }

      # Should have at least one row
      if (nrow(data) == 0) {
        cleanup_test_dirs()
        return(FALSE)
      }

    }, error = function(e) {
      cleanup_test_dirs()
      return(FALSE)
    })
  }

  cleanup_test_dirs()
  return(TRUE)
}

#' Test 6: Summary information validation
test_summary_validation <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  setup_test_dirs()

  result <- create_class_datasets_for_json_reportingevent(
    json_schema_file = test_schema_file,
    reporting_event_json_file = test_data_file,
    output_directory = test_output_dir,
    verbose = FALSE
  )

  summary_info <- result$summary

  # Should have expected summary fields
  expected_fields <- c(
    "processing_time_seconds",
    "json_schema_file",
    "reporting_event_json_file",
    "output_directory",
    "class_datasets_created",
    "total_observations",
    "total_variables"
  )

  if (!all(expected_fields %in% names(summary_info))) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Processing time should be positive
  if (summary_info$processing_time_seconds <= 0) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Should have created some datasets
  if (summary_info$class_datasets_created == 0) {
    cleanup_test_dirs()
    return(FALSE)
  }

  cleanup_test_dirs()
  return(TRUE)
}

#' Test 7: Verbose mode functionality
test_verbose_mode <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  setup_test_dirs()

  # Capture output from verbose mode
  output <- capture.output({
    result <- create_class_datasets_for_json_reportingevent(
      json_schema_file = test_schema_file,
      reporting_event_json_file = test_data_file,
      output_directory = test_output_dir,
      verbose = TRUE
    )
  })

  # Should have produced some output
  if (length(output) == 0) {
    cleanup_test_dirs()
    return(FALSE)
  }

  # Should mention key steps
  output_text <- paste(output, collapse = " ")
  expected_phrases <- c("Step 1", "Step 2", "PROCESSING COMPLETE")

  if (!all(sapply(expected_phrases, function(phrase) grepl(phrase, output_text)))) {
    cleanup_test_dirs()
    return(FALSE)
  }

  cleanup_test_dirs()
  return(TRUE)
}

# Run all tests
cat("=== Integration Tests for create_class_datasets_for_json_reportingevent.R ===\n\n")

tests <- list(
  "Function exists" = test_function_exists,
  "Invalid input handling" = test_invalid_inputs,
  "Complete pipeline (fixtures)" = test_complete_pipeline_fixtures,
  "Real data processing" = test_real_data_processing,
  "Output file validation" = test_output_file_validation,
  "Summary validation" = test_summary_validation,
  "Verbose mode" = test_verbose_mode
)

# Run tests and collect results
results <- list()
for (test_name in names(tests)) {
  results[[test_name]] <- run_test(test_name, tests[[test_name]])
}

# Final cleanup
cleanup_test_dirs()

# Summary
cat("\n=== Test Summary ===\n")
passed <- sum(unlist(results))
total <- length(results)
cat("Passed:", passed, "/", total, "tests\n")

if (passed == total) {
  cat("✅ All tests PASSED!\n")
  quit(status = 0)
} else {
  cat("❌ Some tests FAILED!\n")
  quit(status = 1)
}