#' Test Runner for R Utilities
#'
#' Runs all unit and integration tests for the R utilities
#'
#' Usage: Rscript run_tests.R [test_type]
#'   test_type: "unit", "integration", or "all" (default: "all")

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
test_type <- if (length(args) > 0) args[1] else "all"

# Validate test type
valid_types <- c("unit", "integration", "all")
if (!test_type %in% valid_types) {
  cat("Error: Invalid test type '", test_type, "'\n", sep = "")
  cat("Valid options: ", paste(valid_types, collapse = ", "), "\n")
  quit(status = 1)
}

# Configuration - simple relative paths
test_dir <- paste0(getwd(), "/utilities/R/tests")
unit_test_dir <- file.path(test_dir, "unit")
integration_test_dir <- file.path(test_dir, "integration")

#' Run a test script and capture results
run_test_script <- function(script_path, script_name) {
  cat("Running", script_name, "...\n")

  script_dir <- dirname(script_path)

  tryCatch({
    # Run the test script
    result <- system2("Rscript", args = script_path,
                     stdout = TRUE, stderr = TRUE)

    # Check return status
    exit_status <- attr(result, "status")
    if (is.null(exit_status)) {
      exit_status <- 0  # No status means success
    }

    # Print output
    if (length(result) > 0) {
      cat(paste(result, collapse = "\n"), "\n")
    }

    return(list(
      name = script_name,
      status = exit_status,
      output = result
    ))

  }, error = function(e) {
    cat("ERROR running", script_name, ":", e$message, "\n")
    return(list(
      name = script_name,
      status = 1,
      output = paste("ERROR:", e$message)
    ))
  })
}

#' Discover test scripts in a directory
discover_tests <- function(test_directory) {
  if (!dir.exists(test_directory)) {
    return(character(0))
  }

  test_files <- list.files(test_directory, pattern = "^test_.*\\.R$", full.names = TRUE)
  return(test_files)
}

#' Main test execution
main <- function() {
  cat("=== R Utilities Test Runner ===\n")
  cat("Test type:", test_type, "\n")
  cat("Test directory:", test_dir, "\n\n")

  # Initialize results
  all_results <- list()

  # Run unit tests
  if (test_type %in% c("unit", "all")) {
    cat("=== UNIT TESTS ===\n")
    unit_tests <- discover_tests(unit_test_dir)

    if (length(unit_tests) == 0) {
      cat("No unit tests found in", unit_test_dir, "\n")
    } else {
      for (test_file in unit_tests) {
        test_name <- paste("Unit:", basename(test_file))
        result <- run_test_script(test_file, test_name)
        all_results[[test_name]] <- result
        cat("\n")
      }
    }
    cat("\n")
  }

  # Run integration tests
  if (test_type %in% c("integration", "all")) {
    cat("=== INTEGRATION TESTS ===\n")
    integration_tests <- discover_tests(integration_test_dir)

    if (length(integration_tests) == 0) {
      cat("No integration tests found in", integration_test_dir, "\n")
    } else {
      for (test_file in integration_tests) {
        test_name <- paste("Integration:", basename(test_file))
        result <- run_test_script(test_file, test_name)
        all_results[[test_name]] <- result
        cat("\n")
      }
    }
    cat("\n")
  }

  # Summary
  cat("=== TEST SUMMARY ===\n")

  if (length(all_results) == 0) {
    cat("No tests were run.\n")
    quit(status = 0)
  }

  # Count results
  total_tests <- length(all_results)
  passed_tests <- sum(sapply(all_results, function(r) r$status == 0))
  failed_tests <- total_tests - passed_tests

  # Print individual results
  for (result in all_results) {
    status_symbol <- if (result$status == 0) "✅" else "❌"
    cat(status_symbol, result$name, "\n")
  }

  cat("\n")
  cat("Total tests:", total_tests, "\n")
  cat("Passed:", passed_tests, "\n")
  cat("Failed:", failed_tests, "\n")

  # Overall result
  if (failed_tests == 0) {
    cat("\n🎉 ALL TESTS PASSED! 🎉\n")
    quit(status = 0)
  } else {
    cat("\n💥 SOME TESTS FAILED 💥\n")

    # List failed tests
    cat("\nFailed tests:\n")
    for (result in all_results) {
      if (result$status != 0) {
        cat("  ❌", result$name, "\n")
      }
    }

    quit(status = 1)
  }
}

# Run main function
main()