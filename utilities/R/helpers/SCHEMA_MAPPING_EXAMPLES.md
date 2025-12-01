# Schema-to-Dataset Mapping Examples

This document provides walk-through examples showing how the ARS JSON schema definitions are translated into class datasets, with traceability from schema → JSON instance → dataset record.

## Framework Process Overview

```
ARS Schema Definition → Class Definition → JSON Instance → Dataset Record
      (ars_ldm.json)   (get_class_slots)   (JSON data)    (tablepath/datapath)
```

---

## Example 1: Analysis Class

### 📋 **1. Schema Definition** (from `ars_ldm.json`)
```json
"Analysis": {
  "type": "object",
  "properties": {
    "id": {
      "description": "The assigned identifying value for the instance of the class.",
      "type": "string"
    },
    "name": {
      "description": "The name for the instance of the class.",
      "type": "string"
    },
    "description": {
      "description": "A textual description of the instance of the class.",
      "type": "string"
    },
    "methodId": {
      "description": "A reference to the set of one or more statistical operations performed for the analysis.",
      "type": "string"
    },
    "dataset": {
      "description": "The name of the analysis dataset.",
      "type": "string"
    },
    "variable": {
      "description": "The name of the variable.",
      "type": "string"
    }
  },
  "required": ["id", "name"]
}
```

### 🔄 **2. Automatic Class Definition** (via `get_class_slots()`)
```r
class_definition <- data.frame(
  parent_class = "Analysis",
  slot = c("id", "name", "description", "methodId", "dataset", "variable"),
  range = c("string", "string", "string", "string", "string", "string"),
  is_array = c(0, 0, 0, 0, 0, 0),
  stringsAsFactors = FALSE
)
```

### 📊 **3. JSON Instance** (from reporting event JSON)
```json
{
  "analyses": [
    {
      "id": "An_01_SAF_Summ_Age",
      "name": "Summary of Age",
      "description": "Summary statistics for age by treatment group",
      "methodId": "Mth_01_Summ_ByTrt",
      "dataset": "ADSL",
      "variable": "AGE"
    }
  ]
}
```

### 📈 **4. Generated Dataset Record**
```r
# Extraction Process:
# JSON Path: /analyses/0
# Class: Analysis
# Record Creation: create_record_from_object()

# Final Dataset Record:
Analysis_record <- data.frame(
  tablepath = "/root/analyses",           # Schema location (indices removed)
  datapath = "/analyses/0",               # Exact JSON instance path
  id = "An_01_SAF_Summ_Age",             # From JSON: analyses[0].id
  name = "Summary of Age",                # From JSON: analyses[0].name
  description = "Summary statistics for age by treatment group",  # From JSON
  methodId = "Mth_01_Summ_ByTrt",        # From JSON: analyses[0].methodId
  dataset = "ADSL",                       # From JSON: analyses[0].dataset
  variable = "AGE",                       # From JSON: analyses[0].variable
  stringsAsFactors = FALSE
)
```

**Traceability:** `tablepath` shows this is an Analysis class record, `datapath` shows it came from the first analysis in the JSON array.

---

## Example 2: Output Class

### 📋 **1. Schema Definition** (from `ars_ldm.json`)
```json
"Output": {
  "type": "object",
  "properties": {
    "id": {
      "description": "The assigned identifying value for the instance of the class.",
      "type": "string"
    },
    "name": {
      "description": "The name for the instance of the class.",
      "type": "string"
    },
    "description": {
      "description": "A textual description of the instance of the class.",
      "type": "string"
    },
    "fileSpecifications": {
      "description": "Specifications for the file containing the output.",
      "items": {
        "$ref": "#/$defs/OutputFileSpecification"
      },
      "type": "array"
    },
    "displays": {
      "description": "Tabular displays included in the output.",
      "items": {
        "$ref": "#/$defs/OutputDisplay"
      },
      "type": "array"
    }
  },
  "required": ["id", "name"]
}
```

### 🔄 **2. Automatic Class Definition** (via `get_class_slots()`)
```r
class_definition <- data.frame(
  parent_class = "Output",
  slot = c("id", "name", "description", "fileSpecifications", "displays"),
  range = c("string", "string", "string", "OutputFileSpecification", "OutputDisplay"),
  is_array = c(0, 0, 0, 1, 1),  # fileSpecifications and displays are arrays
  stringsAsFactors = FALSE
)
```

### 📊 **3. JSON Instance** (from reporting event JSON)
```json
{
  "outputs": [
    {
      "id": "Out_14_Summary",
      "name": "Table 14.1.1 Summary of Demographics",
      "description": "Demographic characteristics by treatment group",
      "fileSpecifications": [
        {
          "name": "demographics_summary.rtf",
          "fileType": {"controlledTerm": "rtf"}
        }
      ],
      "displays": [
        {
          "id": "Disp_14_1_Demographics",
          "name": "Demographics Display"
        }
      ]
    }
  ]
}
```

### 📈 **4. Generated Dataset Record**
```r
# Extraction Process:
# JSON Path: /outputs/0
# Class: Output
# Record Creation: create_record_from_object()

# Final Dataset Record:
Output_record <- data.frame(
  tablepath = "/root/outputs",                    # Schema location
  datapath = "/outputs/0",                        # Exact JSON instance path
  id = "Out_14_Summary",                          # From JSON: outputs[0].id
  name = "Table 14.1.1 Summary of Demographics", # From JSON: outputs[0].name
  description = "Demographic characteristics by treatment group", # From JSON
  fileSpecifications = "[{\"name\":\"demographics_summary.rtf\",\"fileType\":{\"controlledTerm\":\"rtf\"}}]", # Array as JSON string
  displays = "[{\"id\":\"Disp_14_1_Demographics\",\"name\":\"Demographics Display\"}]", # Array as JSON string
  stringsAsFactors = FALSE
)
```

**Note:** Array fields (`fileSpecifications`, `displays`) are stored as JSON strings in the main Output dataset, but also extracted into separate class datasets (`OutputFileSpecification.csv`, `OutputDisplay.csv`).

---

## Example 3: DocumentReference Class

### 📋 **1. Schema Definition** (from `ars_ldm.json`)
```json
"DocumentReference": {
  "type": "object",
  "properties": {
    "id": {
      "description": "The assigned identifying value for the instance of the class.",
      "type": "string"
    },
    "referenceDocumentId": {
      "description": "The identifier of the referenced document.",
      "type": "string"
    },
    "pageRefs": {
      "description": "One or more references to specific parts of a document.",
      "items": {
        "$ref": "#/$defs/PageRef"
      },
      "type": "array"
    }
  },
  "required": ["id", "referenceDocumentId"]
}
```

### 🔄 **2. Automatic Class Definition** (via `get_class_slots()`)
```r
class_definition <- data.frame(
  parent_class = "DocumentReference",
  slot = c("id", "referenceDocumentId", "pageRefs"),
  range = c("string", "string", "PageRef"),
  is_array = c(0, 0, 1),  # pageRefs is an array
  stringsAsFactors = FALSE
)
```

### 📊 **3. JSON Instance** (from reporting event JSON)
```json
{
  "analyses": [
    {
      "id": "An_01_SAF_Summ_Age",
      "documentRefs": [
        {
          "id": "DocRef_SAP_Age",
          "referenceDocumentId": "SAP_v2.0",
          "pageRefs": [
            {
              "refType": "PhysicalRef",
              "label": "Section 9.1",
              "pageNames": ["Section_9_1"]
            }
          ]
        }
      ]
    }
  ]
}
```

### 📈 **4. Generated Dataset Record**
```r
# Extraction Process:
# JSON Path: /analyses/0/documentRefs/0
# Class: DocumentReference
# Record Creation: create_record_from_object()

# Final Dataset Record:
DocumentReference_record <- data.frame(
  tablepath = "/root/analyses/documentRefs",      # Schema location (indices removed)
  datapath = "/analyses/0/documentRefs/0",        # Exact JSON instance path
  id = "DocRef_SAP_Age",                          # From JSON: documentRefs[0].id
  referenceDocumentId = "SAP_v2.0",               # From JSON: documentRefs[0].referenceDocumentId
  pageRefs = "[{\"refType\":\"PhysicalRef\",\"label\":\"Section 9.1\",\"pageNames\":[\"Section_9_1\"]}]", # Array as JSON string
  stringsAsFactors = FALSE
)
```

**Path Traceability:** The `datapath` `/analyses/0/documentRefs/0` shows this DocumentReference came from the first documentRef of the first analysis, providing traceability through nested JSON structures.

---

## Schema-to-Dataset Mapping Summary

### 🎯 **Key Mapping Principles**

1. **Schema Definition** → **Class Definition**
   - JSON schema properties become class slots
   - Data types are preserved (`string`, `integer`, etc.)
   - Array indicators are detected (`"type": "array"`)

2. **JSON Instance** → **Dataset Record**
   - Each JSON object becomes one dataset record
   - All schema-defined properties are extracted
   - Missing properties become `NA` values

3. **Path Generation**
   - **`tablepath`**: Schema location with numeric indices removed (e.g., `/root/analyses`)
   - **`datapath`**: Exact JSON path to the instance (e.g., `/analyses/0/documentRefs/0`)

### 📊 **Array Handling**

Arrays in JSON are handled in two ways:
1. **Stored as JSON strings** in the parent class dataset (for reference)
2. **Extracted into separate class datasets** (for detailed analysis)

Example: `outputs[0].displays[]` creates records in both:
- `Output.csv` (with displays as JSON string)
- `OutputDisplay.csv` (with individual display records)

### 🔍 **Traceability**

Every generated record maintains traceability:
- **Which schema class** it represents (`tablepath`)
- **Where in the JSON** it originated (`datapath`)
- **What values** were extracted (all schema-defined slots)

This enables analysts to trace any dataset record back to its exact location in the original JSON reporting event and understand its structure from the ARS schema.