#' Modular Schema-Driven JSON Data Extractor
#'
#' This is the refactored modular version of the schema-driven extractor.
#' It loads and coordinates extraction modules for cleaner code organization.
#'
#' @export

# Get the directory where this script is located
get_script_dir <- function() {
  if (exists("sys.frame") && !is.null(sys.frame(1)$ofile)) {
    return(dirname(sys.frame(1)$ofile))
  } else {
    # Fallback for interactive mode or when sys.frame is not available
    return("utilities/R/helpers")
  }
}

#' Load all extraction modules
load_extractor_modules <- function() {
  script_dir <- get_script_dir()

  # Load all modules
  modules <- c(
    "extractor_record_utils.R",
    "extractor_analysis.R",
    "extractor_output.R",
    "extractor_reference.R",
    "extractor_metadata.R"
  )

  for (module in modules) {
    module_path <- file.path(script_dir, module)
    if (file.exists(module_path)) {
      source(module_path)
      cat("✓ Loaded module:", module, "\n")
    } else {
      warning("Module not found:", module_path)
    }
  }
}

#' Schema-Driven JSON Data Extractor (Modular Version)
#'
#' Extracts data from JSON based on ARS schema class definitions.
#' This modular version loads extraction functions from separate modules
#' for better code organization and maintainability.
#'
#' @param json_file Path to JSON file
#' @param class_slots Data frame with class/slot definitions from get_class_slots
#' @return List containing class datasets with actual data
#' @export
extract_schema_driven_datasets <- function(json_file, class_slots) {

  # Load required libraries
  library(jsonlite)
  library(dplyr)

  # Load extraction modules
  cat("=== Loading Extraction Modules ===\n")
  load_extractor_modules()

  # Load JSON
  json_data <- fromJSON(json_file, simplifyVector = FALSE)

  cat("=== Schema-Driven Data Extraction ===\n")

  # Initialize results
  class_datasets <- list()

  # Get all unique classes from schema
  all_classes <- unique(class_slots$parent_class[!is.na(class_slots$parent_class)])

  cat("Extracting data for", length(all_classes), "schema-defined classes...\n")

  # Extract data for each class based on known JSON paths and schema
  for (class_name in all_classes) {

    # Get slots for this class
    class_definition <- class_slots[class_slots$parent_class == class_name, ]

    # Extract data based on class type and expected JSON locations
    extracted_data <- extract_class_data(json_data, class_name, class_definition)

    if (!is.null(extracted_data) && nrow(extracted_data) > 0) {
      class_datasets[[class_name]] <- extracted_data
      cat("  ✓", class_name, ":", nrow(extracted_data), "records\n")
    } else {
      cat("  -", class_name, ": no data\n")
    }
  }

  cat("Schema extraction complete:", length(class_datasets), "classes with data\n")

  return(class_datasets)
}

#' Extract Data for Specific Class (Modular Router)
#'
#' Routes extraction to appropriate module based on class type.
#' This function coordinates between the different extraction modules.
#'
#' @param json_data Parsed JSON object
#' @param class_name Name of the class to extract
#' @param class_definition Data frame with slot definitions for this class
#' @return Data frame with extracted records for this class
extract_class_data <- function(json_data, class_name, class_definition) {

  # Route to appropriate extraction module based on class type
  result <- switch(class_name,

    # CORE REPORTING
    "ReportingEvent" = extract_reporting_event(json_data, class_definition),

    # ANALYSIS MODULE (extractor_analysis.R)
    "Analysis" = extract_analyses(json_data, class_definition),
    "AnalysisMethod" = extract_analysis_methods(json_data, class_definition),
    "Operation" = extract_operations(json_data, class_definition),
    "OperationResult" = extract_operation_results(json_data, class_definition),
    "ResultGroup" = extract_result_groups(json_data, class_definition),
    "AnalysisSet" = extract_analysis_sets(json_data, class_definition),
    "DataSubset" = extract_data_subsets(json_data, class_definition),
    "Group" = extract_groups(json_data, class_definition),
    "OrderedGroupingFactor" = extract_ordered_grouping_factors(json_data, class_definition),
    "GroupingFactor" = extract_grouping_factors(json_data, class_definition),
    "WhereClause" = extract_where_clauses(json_data, class_definition),
    "WhereClauseCondition" = extract_where_clause_conditions(json_data, class_definition),
    "CompoundSetExpression" = extract_compound_set_expression(json_data, class_definition),
    "CompoundGroupExpression" = extract_compound_group_expression(json_data, class_definition),
    "CompoundSubsetExpression" = extract_compound_subset_expressions(json_data, class_definition),
    "AnalysisReason" = extract_analysis_reasons(json_data, class_definition),
    "AnalysisPurpose" = extract_analysis_purpose(json_data, class_definition),
    "ReferencedAnalysisOperation" = extract_referenced_analysis_operations(json_data, class_definition),
    "ReferencedDataSubset" = extract_referenced_data_subsets(json_data, class_definition),
    "ReferencedOperationRelationship" = extract_referenced_operation_relationships(json_data, class_definition),
    "OperationRole" = extract_operation_roles(json_data, class_definition),
    "ReferencedAnalysisSet" = extract_referenced_analysis_sets(json_data, class_definition),
    "SponsorAnalysisReason" = extract_sponsor_analysis_reasons(json_data, class_definition),
    "SponsorAnalysisPurpose" = extract_sponsor_analysis_purposes(json_data, class_definition),

    # OUTPUT MODULE (extractor_output.R)
    "Output" = extract_outputs(json_data, class_definition),
    "OutputDisplay" = extract_output_displays(json_data, class_definition),
    "OutputFile" = extract_output_file(json_data, class_definition),
    "OutputFileType" = extract_output_file_type(json_data, class_definition),
    "DisplaySection" = extract_display_sections(json_data, class_definition),
    "DisplaySubSection" = extract_display_subsections(json_data, class_definition),
    "GlobalDisplaySection" = extract_global_display_sections(json_data, class_definition),
    "OrderedSubSection" = extract_ordered_subsections(json_data, class_definition),
    "OrderedDisplay" = extract_ordered_displays(json_data, class_definition),
    "OrderedSubSectionRef" = extract_ordered_subsection_refs(json_data, class_definition),
    "ListOfContents" = extract_list_of_contents(json_data, class_definition),
    "NestedList" = extract_nested_lists(json_data, class_definition),
    "OrderedListItem" = extract_ordered_list_items(json_data, class_definition),

    # REFERENCE MODULE (extractor_reference.R)
    "DocumentReference" = extract_document_reference(json_data, class_definition),
    "ReferenceDocument" = extract_reference_document(json_data, class_definition),
    "PageNameRef" = extract_page_name_refs(json_data, class_definition),
    "PageNumberListRef" = extract_page_number_list_refs(json_data, class_definition),
    "PageNumberRangeRef" = extract_page_number_range_refs(json_data, class_definition),

    # METADATA MODULE (extractor_metadata.R)
    "TerminologyExtension" = extract_terminology_extensions(json_data, class_definition),
    "SponsorTerm" = extract_sponsor_terms(json_data, class_definition),
    "AnalysisOutputCategorization" = extract_analysis_output_categorizations(json_data, class_definition),
    "AnalysisOutputCategory" = extract_analysis_output_categories(json_data, class_definition),
    "AnalysisOutputProgrammingCode" = extract_analysis_output_programming_code(json_data, class_definition),
    "AnalysisProgrammingCodeTemplate" = extract_analysis_programming_code_template(json_data, class_definition),
    "TemplateCodeParameter" = extract_template_code_parameter(json_data, class_definition),

    # Default: return NULL for unknown classes
    NULL
  )

  return(result)
}

#' Extract root-level ReportingEvent
#' @param json_data Parsed JSON object
#' @param class_definition Schema definition for ReportingEvent
#' @return Data frame with ReportingEvent record
extract_reporting_event <- function(json_data, class_definition) {
  create_record_from_object(json_data, class_definition, "/", 1)
}

#' Apply SAS-compatible formatting wrapper
#' @param class_datasets List of extracted datasets
#' @param class_slots Schema class definitions
#' @return List of formatted datasets
apply_formatting <- function(class_datasets, class_slots) {
  apply_sas_compatible_formatting(class_datasets, class_slots)
}