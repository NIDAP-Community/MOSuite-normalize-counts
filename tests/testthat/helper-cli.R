setup_cli_workspace <- function(prefix = "mosuite_normalize_counts_test_") {
  workspace <- tempfile(prefix)
  dir.create(workspace)

  code_dir <- file.path(workspace, "code")
  data_dir <- file.path(workspace, "data")
  results_dir <- file.path(workspace, "results")
  dir.create(code_dir, recursive = TRUE)
  dir.create(data_dir, recursive = TRUE)
  dir.create(file.path(results_dir, "figures"), recursive = TRUE)
  dir.create(file.path(results_dir, "moo"), recursive = TRUE)

  repo_root <- normalizePath(
    file.path(testthat::test_path(), "..", ".."),
    mustWork = TRUE
  )

  test_data_file <- file.path(repo_root, "tests", "data", "moo-filt.rds")

  expect_true(
    file.exists(test_data_file),
    info = paste("Test data file should exist at", test_data_file)
  )

  file.copy(
    test_data_file,
    file.path(data_dir, "moo.rds"),
    overwrite = TRUE
  )

  file.copy(
    file.path(repo_root, "code", "main.R"),
    file.path(code_dir, "main.R"),
    overwrite = TRUE
  )

  # Patch the hardcoded /code/MOSuite path so it works outside CodeOcean.
  main_copy <- file.path(code_dir, "main.R")
  main_lines <- readLines(main_copy)
  mosuite_path <- file.path(repo_root, "code", "MOSuite")
  main_lines <- gsub(
    'devtools::load_all("/code/MOSuite")',
    sprintf(
      "devtools::load_all('%s')",
      mosuite_path
    ),
    main_lines,
    fixed = TRUE
  )
  writeLines(main_lines, main_copy)

  list(
    workspace = workspace,
    code_dir = code_dir,
    results_dir = results_dir,
    repo_root = repo_root
  )
}

is_compatible_multiOmicDataSet <- function(moo) {
  moo_classes <- class(moo)
  has_moo_class_label <-
    inherits(moo, "multiOmicDataSet") ||
    any(grepl("(^|::)multiOmicDataSet$", moo_classes))

  is_current_s7_moo <- tryCatch(
    S7::S7_inherits(moo, MOSuite::multiOmicDataSet),
    error = function(e) FALSE
  )

  return(is_current_s7_moo || has_moo_class_label)
}

expect_outputs_created <- function(results_dir) {
  moo_path <- file.path(results_dir, "moo", "moo-norm.rds")

  expect_true(
    file.exists(moo_path),
    info = "Normalized MOO output should be created"
  )
  expect_true(
    file.info(moo_path)$size > 0,
    info = "Normalized MOO output should be non-empty"
  )

  moo <- readr::read_rds(moo_path)

  expect_true(
    is_compatible_multiOmicDataSet(moo),
    info = "Output should be an S7 multiOmicDataSet object"
  )

  expect_true(
    "norm" %in% names(moo@counts),
    info = "Output should have norm counts in moo@counts"
  )
}

default_cli_args <- c(
  "--count_type=filt",
  "--norm_type=voom",
  "--voom_normalization_method=quantile",
  "--plot_corr_matrix_heatmap=FALSE",
  "--interactive_plots=FALSE"
)

custom_cli_args <- c(
  "--count_type=filt",
  "--norm_type=voom",
  "--voom_normalization_method=none",
  "--add_label_to_pca=FALSE",
  "--principal_component_on_x_axis=1",
  "--principal_component_on_y_axis=3",
  "--plot_corr_matrix_heatmap=FALSE",
  "--interactive_plots=FALSE"
)
