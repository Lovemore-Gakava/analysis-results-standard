#' Unit Tests for get_class_slots.R
#'
#' Tests the functionality of extracting class/slot definitions from JSON schema
#'
#' Usage: Rscript test_get_class_slots.R

# Load required libraries
library(jsonlite)

# Set up relative paths based on current working directory
# This script should be run from the tests/unit directory or via the test runner

# Declare paths
  helpers_path <- file.path("utilities/R/helpers/")
  fixtures_path <- file.path("utilities/R/tests/fixtures")
  model_path <- file.path("model")

# Source the function under test
source(file.path(helpers_path, "get_class_slots.R"))

# Test configuration
test_schema_file <- file.path(fixtures_path, "test_schema.json")
real_schema_file <- file.path(model_path, "ars_ldm.json")

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

#' Test 1: Function exists and can be called
test_function_exists <- function() {
  return(exists("get_class_slots"))
}

#' Test 2: Function handles invalid file path
test_invalid_file <- function() {
  result <- tryCatch({
    get_class_slots("nonexistent_file.json")
    return(FALSE)  # Should have thrown an error
  }, error = function(e) {
    return(TRUE)   # Expected error
  })
  return(result)
}

#' Test 3: Function processes test schema correctly
test_test_schema <- function() {
  if (!file.exists(test_schema_file)) {
    cat("(SKIP - test schema not found) ")
    return(TRUE)
  }

  result <- get_class_slots(test_schema_file)

  # Should return a data frame
  if (!is.data.frame(result)) {
    return(FALSE)
  }

  # Should have required columns
  required_cols <- c("parent_class", "slot", "range", "is_array")
  if (!all(required_cols %in% names(result))) {
    return(FALSE)
  }

  # Should have rows for our test classes
  classes <- unique(result$parent_class[!is.na(result$parent_class)])
  expected_classes <- c("Analysis", "AnalysisReason", "Operation")

  if (!all(expected_classes %in% classes)) {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 4: Function processes real ARS schema
test_real_schema <- function() {
  if (!file.exists(real_schema_file)) {
    cat("(SKIP - real schema not found) ")
    return(TRUE)
  }

  result <- get_class_slots(real_schema_file)

  # Should return a data frame
  if (!is.data.frame(result)) {
    return(FALSE)
  }

  # Should have many rows (real schema is complex)
  if (nrow(result) < 100) {
    return(FALSE)
  }

  # Should include known ARS classes
  classes <- unique(result$parent_class[!is.na(result$parent_class)])
  expected_classes <- c("Analysis", "Operation", "ReportingEvent", "Output")

  if (!all(expected_classes %in% classes)) {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 5: Slot extraction works correctly
test_slot_extraction <- function() {
  if (!file.exists(test_schema_file)) {
    cat("(SKIP - test schema not found) ")
    return(TRUE)
  }

  result <- get_class_slots(test_schema_file)

  # Check Analysis class slots
  analysis_slots <- result[result$parent_class == "Analysis" & !is.na(result$parent_class), ]

  if (nrow(analysis_slots) == 0) {
    return(FALSE)
  }

  # Should include known slots
  expected_slots <- c("id", "name", "description", "order")
  found_slots <- analysis_slots$slot

  if (!all(expected_slots %in% found_slots)) {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 6: Array detection works
test_array_detection <- function() {
  if (!file.exists(test_schema_file)) {
    cat("(SKIP - test schema not found) ")
    return(TRUE)
  }

  result <- get_class_slots(test_schema_file)

  # The 'operations' field in AnalysisMethod should be detected as an array
  operations_entry <- result[result$slot == "operations" & !is.na(result$slot), ]

  if (nrow(operations_entry) == 0) {
    return(FALSE)
  }

  # Should be marked as array
  if (operations_entry$is_array[1] != 1) {
    return(FALSE)
  }

  return(TRUE)
}

# Run all tests
cat("=== Unit Tests for get_class_slots.R ===\n\n")

tests <- list(
  "Function exists" = test_function_exists,
  "Invalid file handling" = test_invalid_file,
  "Test schema processing" = test_test_schema,
  "Real schema processing" = test_real_schema,
  "Slot extraction" = test_slot_extraction,
  "Array detection" = test_array_detection
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