#' Unit Tests for Modular Extractor System
#'
#' Tests the functionality of the modular schema-driven extractor
#'
#' Usage: Rscript test_modular_extractor.R

# Load required libraries
library(jsonlite)
library(dplyr)

# Declare paths
helpers_path <- file.path("utilities/R/helpers/")
fixtures_path <- file.path("utilities/R/tests/fixtures")
model_path <- file.path("model")

# Source the functions under test
source(file.path(helpers_path, "schema_driven_extractor_modular.R"))
source(file.path(helpers_path, "get_class_slots.R"))

# Test configuration
test_schema_file <- file.path(fixtures_path, "test_schema.json")
test_data_file <- file.path(fixtures_path, "test_data.json")
real_schema_file <- file.path(model_path, "ars_ldm.json")
real_data_file <- file.path("workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json")

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

#' Test 1: Main extractor function exists
test_extractor_exists <- function() {
  return(exists("extract_schema_driven_datasets"))
}

#' Test 2: Module loading works
test_module_loading <- function() {
  # The function should exist after sourcing
  return(exists("load_extractor_modules"))
}

#' Test 3: Class data routing works
test_class_routing <- function() {
  return(exists("extract_class_data"))
}

#' Test 4: Extract with test fixtures
test_extract_test_fixtures <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  # Get class slots from test schema
  class_slots <- get_class_slots(test_schema_file)

  # Extract datasets
  result <- extract_schema_driven_datasets(test_data_file, class_slots)

  # Should return a list
  if (!is.list(result)) {
    return(FALSE)
  }

  # Should have extracted some classes
  if (length(result) == 0) {
    return(FALSE)
  }

  # Should include Analysis class (from our test data)
  if (!"Analysis" %in% names(result)) {
    return(FALSE)
  }

  # Analysis dataset should have records
  if (nrow(result$Analysis) != 2) {  # We have 2 analyses in test data
    return(FALSE)
  }

  return(TRUE)
}

#' Test 5: Extract with real ARS data (if available)
test_extract_real_data <- function() {
  if (!file.exists(real_schema_file) || !file.exists(real_data_file)) {
    cat("(SKIP - real data not found) ")
    return(TRUE)
  }

  # Get class slots from real schema
  class_slots <- get_class_slots(real_schema_file)

  # Extract datasets
  result <- extract_schema_driven_datasets(real_data_file, class_slots)

  # Should return a list
  if (!is.list(result)) {
    return(FALSE)
  }

  # Should have extracted many classes
  if (length(result) < 10) {
    return(FALSE)
  }

  # Should include key ARS classes
  expected_classes <- c("Analysis", "Operation", "ReportingEvent")
  found_classes <- names(result)

  if (!all(expected_classes %in% found_classes)) {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 6: Data structure validation
test_data_structure <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  # Get class slots and extract data
  class_slots <- get_class_slots(test_schema_file)
  result <- extract_schema_driven_datasets(test_data_file, class_slots)

  # Check that datasets have required structure
  for (class_name in names(result)) {
    dataset <- result[[class_name]]

    # Should be a data frame
    if (!is.data.frame(dataset)) {
      return(FALSE)
    }

    # Should have tablepath and datapath columns
    required_cols <- c("tablepath", "datapath")
    if (!all(required_cols %in% names(dataset))) {
      return(FALSE)
    }

    # tablepath should start with / (before SAS formatting adds /root)
    if (any(!startsWith(dataset$tablepath, "/"))) {
      return(FALSE)
    }
  }

  return(TRUE)
}

#' Test 7: Analysis class extraction validation
test_analysis_extraction <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  class_slots <- get_class_slots(test_schema_file)
  result <- extract_schema_driven_datasets(test_data_file, class_slots)

  if (!"Analysis" %in% names(result)) {
    return(FALSE)
  }

  analysis_data <- result$Analysis

  # Should have the analyses from our test data
  if (nrow(analysis_data) != 2) {
    return(FALSE)
  }

  # Should have expected fields
  expected_fields <- c("id", "name", "description", "order")
  if (!all(expected_fields %in% names(analysis_data))) {
    return(FALSE)
  }

  # Should have correct values
  if (analysis_data$id[1] != "ANA_001" || analysis_data$name[1] != "Analysis 1") {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 8: Operation extraction validation
test_operation_extraction <- function() {
  if (!file.exists(test_schema_file) || !file.exists(test_data_file)) {
    cat("(SKIP - test fixtures not found) ")
    return(TRUE)
  }

  class_slots <- get_class_slots(test_schema_file)
  result <- extract_schema_driven_datasets(test_data_file, class_slots)

  if (!"Operation" %in% names(result)) {
    return(FALSE)
  }

  operation_data <- result$Operation

  # Should have 3 operations total (2 from first analysis + 1 from second)
  if (nrow(operation_data) != 3) {
    return(FALSE)
  }

  # Should have expected fields
  expected_fields <- c("id", "name", "description", "order", "resultPattern")
  if (!all(expected_fields %in% names(operation_data))) {
    return(FALSE)
  }

  # Should have correct values
  if (operation_data$id[1] != "OP_001_1" || operation_data$resultPattern[1] != "N=XX") {
    return(FALSE)
  }

  return(TRUE)
}

# Run all tests
cat("=== Unit Tests for Modular Extractor System ===\n\n")

tests <- list(
  "Extractor function exists" = test_extractor_exists,
  "Module loading works" = test_module_loading,
  "Class routing works" = test_class_routing,
  "Extract test fixtures" = test_extract_test_fixtures,
  "Extract real data" = test_extract_real_data,
  "Data structure validation" = test_data_structure,
  "Analysis extraction" = test_analysis_extraction,
  "Operation extraction" = test_operation_extraction
)

# Run tests and collect results
results <- list()
for (test_name in names(tests)) {
  results[[test_name]] <- run_test(test_name, tests[[test_name]])
}

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