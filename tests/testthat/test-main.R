patch_main_load_path <- function(main_copy, repo_root) {
  main_lines <- readLines(main_copy)
  main_lines <- gsub(
    'devtools::load_all("/code/MOSuite")',
    sprintf(
      'devtools::load_all("%s")',
      file.path(repo_root, "code", "MOSuite")
    ),
    main_lines,
    fixed = TRUE
  )
  writeLines(main_lines, main_copy)
}

test_that("code/run executes successfully with default CLI arguments", {
  setup <- setup_cli_workspace("mosuite_normalize_counts_test_")
  on.exit(unlink(setup$workspace, recursive = TRUE), add = TRUE)

  file.copy(
    file.path(setup$repo_root, "code", "main.R"),
    file.path(setup$code_dir, "main.R")
  )
  patch_main_load_path(file.path(setup$code_dir, "main.R"), setup$repo_root)
  file.copy(
    file.path(setup$repo_root, "code", "run"),
    file.path(setup$code_dir, "run")
  )

  old_wd <- getwd()
  setwd(setup$code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  exit_code <- system2("bash", args = c("run", default_cli_args))
  expect_equal(exit_code, 0, info = "run script should execute without error")

  expect_outputs_created(setup$results_dir)
})

test_that("code/run executes with custom CLI arguments", {
  setup <- setup_cli_workspace("mosuite_normalize_counts_custom_test_")
  on.exit(unlink(setup$workspace, recursive = TRUE), add = TRUE)

  file.copy(
    file.path(setup$repo_root, "code", "main.R"),
    file.path(setup$code_dir, "main.R")
  )
  patch_main_load_path(file.path(setup$code_dir, "main.R"), setup$repo_root)
  file.copy(
    file.path(setup$repo_root, "code", "run"),
    file.path(setup$code_dir, "run")
  )

  old_wd <- getwd()
  setwd(setup$code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  # Execute run script with custom CLI arguments
  exit_code <- system2(
    "bash",
    args = c(
      "run",
      "--count_type=filt",
      "--norm_type=voom",
      "--voom_normalization_method=none",
      "--principal_component_on_x_axis=1",
      "--principal_component_on_y_axis=3",
      "--plot_corr_matrix_heatmap=FALSE",
      "--interactive_plots=FALSE"
    )
  )

  # Check for successful execution
  expect_equal(
    exit_code,
    0,
    info = "run script with custom args should execute without error"
  )

  expect_outputs_created(setup$results_dir)
})

test_that("code/run accepts plotting CLI arguments", {
  workspace <- tempfile("mosuite_normalize_counts_plot_args_test_")
  dir.create(workspace)
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)

  code_dir <- file.path(workspace, "code")
  data_dir <- file.path(workspace, "data")
  results_dir <- file.path(code_dir, "..", "results")
  dir.create(code_dir)
  dir.create(data_dir)
  dir.create(results_dir)

  repo_root <- normalizePath(file.path(dirname(getwd()), ".."))
  test_data_file <- file.path(repo_root, "tests", "data", "moo-filt.rds")

  expect_true(
    file.exists(test_data_file),
    info = paste("Test data file should exist at", test_data_file)
  )
  file.copy(test_data_file, file.path(data_dir, "moo.rds"))

  file.copy(
    file.path(repo_root, "code", "main.R"),
    file.path(code_dir, "main.R")
  )
  patch_main_load_path(file.path(code_dir, "main.R"), repo_root)
  file.copy(
    file.path(repo_root, "code", "run"),
    file.path(code_dir, "run")
  )

  old_wd <- getwd()
  setwd(code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  exit_code <- system2(
    "bash",
    args = c(
      "run",
      "--count_type=filt",
      "--norm_type=voom",
      "--voom_normalization_method=quantile",
      "--principal_component_on_x_axis=1",
      "--principal_component_on_y_axis=2",
      "--legend_position_for_pca=bottom",
      "--point_size_for_pca=3",
      "--color_histogram_by_group=TRUE",
      "--legend_font_size_for_histogram=",
      "--legend_position_for_histogram=top",
      "--number_of_histogram_legend_columns=6",
      "--plot_corr_matrix_heatmap=FALSE",
      "--interactive_plots=FALSE"
    )
  )

  expect_equal(
    exit_code,
    0,
    info = "run script should accept plotting arguments"
  )
  expect_true(
    file.exists(file.path(results_dir, "moo", "moo-norm.rds")),
    info = "Output file moo-norm.rds should be created with plotting args"
  )

  moo <- readr::read_rds(file.path(results_dir, "moo", "moo-norm.rds"))
  expect_true(
    S7::S7_inherits(moo, MOSuite::multiOmicDataSet),
    info = "Output should be an S7 multiOmicDataSet object"
  )
  expect_true(
    "norm" %in% names(moo@counts),
    info = "Output should have norm counts in moo@counts"
  )
})
