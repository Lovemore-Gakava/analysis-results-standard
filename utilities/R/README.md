# ARS R Utilities

This directory contains R utilities for processing Analysis Results Standard (ARS) JSON files, providing R equivalents of the SAS macros with SAS compatibility.

## Main Orchestration Function

### `create_class_datasets_for_json_reportingevent.R`

The main entry point that orchestrates the ARS JSON processing pipeline. This R implementation matches SAS structure and content.

#### Usage

**R Function:**
```r
source("utilities/R/create_class_datasets_for_json_reportingevent.R")

result <- create_class_datasets_for_json_reportingevent(
  json_schema_file = "model/ars_ldm.json",
  reporting_event_json_file = "workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json",
  output_directory = tempdir(),  # or specify custom directory: "./output"
  temp_directory = tempdir(),    # or specify custom directory: "./temp" 
  verbose = TRUE
)
```

**Command Line:**
```bash
# Process FDA example reporting event using temporary directory
TEMP_DIR=$(Rscript -e "cat(tempdir())") && \
Rscript utilities/R/create_class_datasets_for_json_reportingevent.R \
  model/ars_ldm.json \
  "workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json" \
  "$TEMP_DIR"

# Or specify a custom output directory
Rscript utilities/R/create_class_datasets_for_json_reportingevent.R \
  model/ars_ldm.json \
  "workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json" \
  ./output
```


#### Processing Pipeline

The pipeline uses a **schema-driven approach** with **class-focused extraction**:

1. **Read Schema Definitions** - Extract ARS class/slot definitions from JSON schema
2. **Extract & Format Class Datasets** - Create SAS-compatible class datasets with:
   - Schema-driven field extraction (only scalar attributes per class)
- **26+ Class datasets** saved as CSV files (Analysis, Operation, OperationResult, etc.)
- **SAS-compatible structure** with proper TABLEPATH and DATAPATH variables
- **Processing summary** with statistics and timing
- **Record counts** matching SAS output
- **Output location**: Files saved to specified directory (temporary by default, or custom path)
#### Output

- **26+ Class datasets** saved as CSV files (Analysis, Operation, OperationResult, etc.)
- **SAS-compatible structure** with proper TABLEPATH and DATAPATH variables
- **Processing summary** with statistics and timing
- **Record counts** matching SAS output

## Core Helper Functions

Located in `helpers/` subdirectory:

### `get_class_slots.R`
Extracts ARS class and slot definitions from the JSON schema file (`ars_ldm.json`). Creates the foundation for schema-driven processing.

### `schema_driven_extractor.R`
Core extraction engine that:
- Processes JSON based on ARS schema class definitions
- Extracts only scalar attributes for each class (no nested objects)
- Applies SAS-compatible formatting (tablepath, array normalization)
- Ensures normalized dataset structure

## Key Features

### ✅ SAS Compatibility
- **Structure match** - Same column names, order, and data types as SAS
- **Record counts** - Analysis: 20, Operation: 14, OperationResult: 93, etc.
- **Path format** - `/root/analyses`, `/root/methods/operations` format
- **Array normalization** - `categoryIds` → `categoryIds1`, `categoryIds2`

### ✅ Schema-Driven Architecture
- **Class-focused extraction** - Each class extracts only its own scalar attributes
- **No over-extraction** - Complex nested objects handled by their respective classes
- **Relational separation** - Normalized datasets, not flattened structures

```bash
# Process FDA example reporting event (using temporary directory)
TEMP_DIR=$(Rscript -e "cat(tempdir())") && \
Rscript utilities/R/create_class_datasets_for_json_reportingevent.R \
  model/ars_ldm.json \
  "workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json" \
  "$TEMP_DIR"

# Creates: Analysis.csv, Operation.csv, OperationResult.csv, ResultGroup.csv, etc.
```P_DIR=$(Rscript -e "cat(tempdir())") && \
Rscript utilities/R/create_class_datasets_for_json_reportingevent.R \
  model/ars_ldm.json \
  "workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json" \
  "$TEMP_DIR"

# Creates: Analysis.csv, Operation.csv, OperationResult.csv, ResultGroup.csv, etc.
```

## Requirements

- R packages: `jsonlite`, `dplyr`
- ARS JSON schema file (`ars_ldm.json`)
- Valid ARS reporting event JSON file

## Data Reassembly

The DATAPATH variable uses JSON Pointer notation enabling reassembly of related data:

```r
# Example: Find ResultGroups that belong to each OperationResult
combined_results <- result$class_datasets$OperationResult %>%
  cross_join(result$class_datasets$ResultGroup) %>%
  filter(startsWith(datapath.y, datapath.x)) %>%
  select(-datapath.y) %>%
  rename(datapath = datapath.x)
```

This works because child object DATAPATH values (e.g., `/analyses/0/results/0/resultGroups/0`) contain their parent DATAPATH as a prefix (e.g., `/analyses/0/results/0`).
