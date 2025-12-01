#!/usr/bin/env Rscript

#' Unit Tests for extractor_record_utils.R
#'
#' Tests the core record creation and formatting utilities
#'
#' Usage: Rscript test_extractor_record_utils.R

# Load required libraries
library(jsonlite)
library(dplyr)

# Specify the helpers path
  helpers_path <- file.path("utilities/R/helpers/")


# Source the functions under test
source(file.path(helpers_path, "extractor_record_utils.R"))

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

#' Test 1: create_record_from_object basic functionality
test_create_record_basic <- function() {
  # Mock class definition
  class_def <- data.frame(
    slot = c("id", "name", "description"),
    range = c("string", "string", "string"),
    is_array = c(0, 0, 0),
    stringsAsFactors = FALSE
  )

  # Mock JSON object
  json_obj <- list(
    id = "TEST_001",
    name = "Test Object",
    description = "A test object"
  )

  result <- create_record_from_object(json_obj, class_def, "/test/0", 1)

  # Should return a data frame
  if (!is.data.frame(result)) {
    return(FALSE)
  }

  # Should have expected columns
  expected_cols <- c("tablepath", "datapath", "id", "name", "description")
  if (!all(expected_cols %in% names(result))) {
    return(FALSE)
  }

  # Should have correct values
  if (result$id != "TEST_001" || result$name != "Test Object") {
    return(FALSE)
  }

  # Should have correct paths (tablepath removes numeric indices)
  if (result$tablepath != "/test" || result$datapath != "/test/0") {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 2: Array handling in create_record_from_object
test_create_record_arrays <- function() {
  # Mock class definition with array field
  class_def <- data.frame(
    slot = c("id", "tags"),
    range = c("string", "string"),
    is_array = c(0, 1),
    stringsAsFactors = FALSE
  )

  # Mock JSON object with array
  json_obj <- list(
    id = "TEST_002",
    tags = list("tag1", "tag2", "tag3")
  )

  result <- create_record_from_object(json_obj, class_def, "/test/path", 1)

  # Should return a data frame
  if (!is.data.frame(result)) {
    return(FALSE)
  }

  # Array should be pipe-separated
  if (result$tags != "tag1|tag2|tag3") {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 3: Missing fields handling
test_create_record_missing_fields <- function() {
  # Mock class definition
  class_def <- data.frame(
    slot = c("id", "name", "missing_field"),
    range = c("string", "string", "string"),
    is_array = c(0, 0, 0),
    stringsAsFactors = FALSE
  )

  # Mock JSON object (missing 'missing_field')
  json_obj <- list(
    id = "TEST_003",
    name = "Test Object"
  )

  result <- create_record_from_object(json_obj, class_def, "/test/path", 1)

  # Should return a data frame
  if (!is.data.frame(result)) {
    return(FALSE)
  }

  # Missing field should be NA
  if (!is.na(result$missing_field)) {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 4: extract_array_objects functionality
test_extract_array_objects <- function() {
  # Mock class definition
  class_def <- data.frame(
    slot = c("id", "name", "order"),
    range = c("string", "string", "integer"),
    is_array = c(0, 0, 0),
    stringsAsFactors = FALSE
  )

  # Mock JSON array
  json_array <- list(
    list(id = "OBJ_001", name = "Object 1", order = 1),
    list(id = "OBJ_002", name = "Object 2", order = 2),
    list(id = "OBJ_003", name = "Object 3", order = 3)
  )

  result <- extract_array_objects(json_array, class_def, "/test/objects")

  # Should return a data frame
  if (!is.data.frame(result)) {
    return(FALSE)
  }

  # Should have 3 rows
  if (nrow(result) != 3) {
    return(FALSE)
  }

  # Should have correct paths
  expected_paths <- c("/test/objects/0", "/test/objects/1", "/test/objects/2")
  if (!all(result$datapath %in% expected_paths)) {
    return(FALSE)
  }

  # Should have correct values
  if (result$id[1] != "OBJ_001" || result$name[2] != "Object 2" || result$order[3] != 3) {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 5: apply_sas_compatible_formatting basic functionality
test_sas_formatting_basic <- function() {
  # Create mock datasets
  dataset1 <- data.frame(
    tablepath = c("/methods/operations", "/methods/operations"),
    datapath = c("/methods/0/operations/0", "/methods/0/operations/1"),
    id = c("OP_001", "OP_002"),
    name = c("Operation 1", "Operation 2"),
    stringsAsFactors = FALSE
  )

  class_datasets <- list(Operation = dataset1)

  # Mock class slots
  class_slots <- data.frame(
    parent_class = c("Operation", "Operation", "Operation", "Operation"),
    slot = c("id", "name", "description", "tags"),
    range = c("string", "string", "string", "string"),
    is_array = c(0, 0, 0, 1),
    stringsAsFactors = FALSE
  )

  result <- apply_sas_compatible_formatting(class_datasets, class_slots)

  # Should return a list
  if (!is.list(result)) {
    return(FALSE)
  }

  # Should have Operation dataset
  if (!"Operation" %in% names(result)) {
    return(FALSE)
  }

  formatted_dataset <- result$Operation

  # Should have /root prefix in tablepath
  if (!all(startsWith(formatted_dataset$tablepath, "/root"))) {
    return(FALSE)
  }

  return(TRUE)
}

#' Test 6: Array splitting in SAS formatting
test_sas_formatting_arrays <- function() {
  # Create mock dataset with pipe-separated array
  dataset1 <- data.frame(
    tablepath = c("/test", "/test"),
    datapath = c("/test/0", "/test/1"),
    id = c("TEST_001", "TEST_002"),
    tags = c("tag1|tag2|tag3", "tagA|tagB"),
    stringsAsFactors = FALSE
  )

  class_datasets <- list(TestClass = dataset1)

  # Mock class slots with array field
  class_slots <- data.frame(
    parent_class = c("TestClass", "TestClass", "TestClass"),
    slot = c("id", "tags", "description"),
    range = c("string", "string", "string"),
    is_array = c(0, 1, 0),
    stringsAsFactors = FALSE
  )

  result <- apply_sas_compatible_formatting(class_datasets, class_slots)

  formatted_dataset <- result$TestClass

  # Should have split array columns
  expected_cols <- c("tablepath", "datapath", "id", "tags1", "tags2", "tags3")
  if (!all(expected_cols %in% names(formatted_dataset))) {
    return(FALSE)
  }

  # Should have correct values in split columns
  if (formatted_dataset$tags1[1] != "tag1" || formatted_dataset$tags2[1] != "tag2") {
    return(FALSE)
  }

  # Original tags column should be removed
  if ("tags" %in% names(formatted_dataset)) {
    return(FALSE)
  }

  return(TRUE)
}

# Run all tests
cat("=== Unit Tests for extractor_record_utils.R ===\n\n")

tests <- list(
  "create_record_from_object basic" = test_create_record_basic,
  "create_record_from_object arrays" = test_create_record_arrays,
  "create_record_from_object missing fields" = test_create_record_missing_fields,
  "extract_array_objects" = test_extract_array_objects,
  "SAS formatting basic" = test_sas_formatting_basic,
  "SAS formatting arrays" = test_sas_formatting_arrays
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