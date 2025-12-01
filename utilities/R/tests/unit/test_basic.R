#!/usr/bin/env Rscript

#' Basic Test to Validate Test Infrastructure
#'
#' Simple test to ensure the test framework is working
#'
#' Usage: Rscript test_basic.R

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

#' Test 1: Basic R functionality
test_basic_r <- function() {
  # Simple arithmetic
  result <- 2 + 2
  return(result == 4)
}

#' Test 2: Data frame creation
test_data_frame <- function() {
  df <- data.frame(
    id = c(1, 2, 3),
    name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  return(nrow(df) == 3 && ncol(df) == 2)
}

#' Test 3: File path checking
test_file_paths <- function() {
  # Check if we can access relative paths from project root
  current_dir <- getwd()

  # Should have dev directory (indicating we're at project root)
  dev_exists <- dir.exists("utilities")
  unit_test_dir_exists <- dir.exists("utilities/R/tests/unit")

  return(dev_exists && unit_test_dir_exists)
}

#' Test 4: JSON handling
test_json_basic <- function() {
  tryCatch({
    library(jsonlite, quietly = TRUE)

    # Simple JSON parsing
    json_text <- '{"id": 1, "name": "test"}'
    parsed <- fromJSON(json_text)

    return(parsed$id == 1 && parsed$name == "test")
  }, error = function(e) {
    return(FALSE)
  })
}

# Run all tests
cat("=== Basic Infrastructure Tests ===\n\n")

tests <- list(
  "Basic R functionality" = test_basic_r,
  "Data frame creation" = test_data_frame,
  "File path checking" = test_file_paths,
  "JSON handling" = test_json_basic
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