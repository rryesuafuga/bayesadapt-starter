test_that("sanitize_seed coerces messy inputs to a valid integer", {
  expect_identical(sanitize_seed(42), 42L)
  expect_identical(sanitize_seed(3.7), 4L)
  expect_identical(sanitize_seed(-5), 5L)
  expect_identical(sanitize_seed(NA), 1L)
  expect_identical(sanitize_seed(NULL), 1L)
  expect_identical(sanitize_seed(Inf), 1L)
  expect_identical(sanitize_seed(NA, default = 99), 99L)
})
