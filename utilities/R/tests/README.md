# R Utilities Test Suite

Test suite for the R utilities in the OARS project, covering both unit tests for individual components and integration tests for complete workflows.

## Test Structure

```
tests/
├── run_tests.R                    # Main test runner script
├── README.md                      # This documentation
├── fixtures/                      # Test data and schemas
│   ├── test_schema.json          # Minimal ARS schema for testing
│   └── test_data.json            # Sample JSON data matching schema
├── unit/                         # Unit tests for individual components
│   ├── test_get_class_slots.R    # Tests for schema parsing
│   ├── test_extractor_record_utils.R  # Tests for record utilities
│   └── test_modular_extractor.R  # Tests for modular extractor system
└── integration/                  # Integration tests for complete workflows
    └── test_create_class_datasets.R  # Tests for main pipeline function
```

## Running Tests

### Quick Start
```bash
# Run all tests
Rscript tests/run_tests.R

# Run only unit tests
Rscript tests/run_tests.R unit

# Run only integration tests
Rscript tests/run_tests.R integration
```

### Individual Test Files
```bash
# Always run from project root directory (utilities/R/tests/run_tests.R expects this)
cd /path/to/oars  # Project root where dev/ directory is located

# Run specific test file
Rscript utilities/R/tests/unit/test_get_class_slots.R

# Or run via test runner (recommended)
Rscript utilities/R/tests/run_tests.R unit
```

## Test Coverage

### Unit Tests

#### `test_get_class_slots.R`
- ✅ Function exists and can be called
- ✅ Handles invalid file paths gracefully
- ✅ Processes test schema correctly
- ✅ Processes real ARS schema (if available)
- ✅ Extracts slots properly
- ✅ Detects array fields correctly

#### `test_extractor_record_utils.R`
- ✅ `create_record_from_object` basic functionality
- ✅ Array handling in record creation
- ✅ Missing field handling
- ✅ `extract_array_objects` functionality
- ✅ SAS-compatible formatting
- ✅ Array splitting in formatting

#### `test_modular_extractor.R`
- ✅ Main extractor function exists
- ✅ Module loading works
- ✅ Class data routing works
- ✅ Extraction with test fixtures
- ✅ Extraction with real data (if available)
- ✅ Data structure validation
- ✅ Analysis class extraction
- ✅ Operation extraction

### Integration Tests

#### `test_create_class_datasets.R`
- ✅ Function exists
- ✅ Invalid input handling
- ✅ Complete pipeline with test fixtures
- ✅ Real data processing (if available)
- ✅ Output file validation
- ✅ Summary information validation
- ✅ Verbose mode functionality

## Test Fixtures

The test suite includes minimal test fixtures to ensure tests can run independently:

### `test_schema.json`
- Simplified ARS schema with core classes: Analysis, Operation, AnalysisReason
- Includes proper type definitions and relationships
- Designed for fast, predictable testing

### `test_data.json`
- Sample reporting event with 2 analyses and 3 operations
- Matches the test schema structure
- Provides known data for validation

## Test Philosophy

### Unit Tests
- **Fast**: Each test runs in milliseconds
- **Isolated**: Tests individual functions without dependencies
- **Deterministic**: Same input always produces same output
- **Coverage**: Cover both success and error cases

### Integration Tests
- **Realistic**: Use actual workflow patterns
- **End-to-End**: Test complete pipelines
- **File I/O**: Validate actual file creation and content
- **Error Handling**: Test failure modes and recovery

## Expected Test Results

When running against the full OARS dataset:

- **36 ARS classes** extracted successfully
- **461 total observations** across all classes
- **Operation class**: 14 records (from 4 methods with different operation counts)
- **Analysis class**: 20 records
- **Processing time**: < 1 second

## Continuous Testing

### Before Commits
```bash
# Always run tests before committing changes
Rscript tests/run_tests.R
```

### After Refactoring
```bash
# Run full test suite after major changes
Rscript tests/run_tests.R all
```

### Development Workflow
```bash
# Run relevant unit tests during development
Rscript tests/run_tests.R unit

# Run integration tests before finalizing features
Rscript tests/run_tests.R integration
```

## Adding New Tests

### New Unit Test
1. Create `test_new_feature.R` in `unit/`
2. Follow existing patterns:
   - Use `run_test()` helper function
   - Include multiple test cases
   - Handle both success and error scenarios
3. Update this README

### New Integration Test
1. Create test in `integration/`
2. Include setup/cleanup functions
3. Test complete workflows
4. Validate file outputs

### Test Fixtures
- Add new fixtures to `fixtures/` directory
- Keep fixtures minimal but realistic
- Document expected behavior

## Troubleshooting

### Common Issues

#### Tests Skip with "fixtures not found"
- Ensure `fixtures/test_schema.json` and `fixtures/test_data.json` exist
- Check file paths are relative to test script location

#### Tests Skip with "real data not found"
- This is expected if `model/ars_ldm.json` or `workfiles/examples/ARS v1/FDA Standard Safety Tables and Figures.json` don't exist
- Tests will skip gracefully and still pass

#### Permission Errors
- Ensure test runner is executable: `chmod +x run_tests.R`
- Check write permissions for temporary directories

#### Module Loading Errors
- Verify all helper files exist in `../helpers/` relative to test
- Check that working directory is correctly set

## Test Maintenance

- **Review test coverage** when adding new features
- **Update fixtures** if schema changes significantly
- **Benchmark performance** to catch regressions
- **Document breaking changes** that affect test expectations
