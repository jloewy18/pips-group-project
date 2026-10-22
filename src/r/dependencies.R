# Install missing packages and attach the ones the project needs.
REQUIRED_PACKAGES = c("shiny", "ggplot2")

ensure_packages = function(pkgs = REQUIRED_PACKAGES) {
  # Check availability without attaching packages.
  missing = pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  
  if (length(missing) > 0)
    install.packages(missing)
  
  # Attach packages; suppress printing the returned list.
  invisible(lapply(pkgs, library, character.only = TRUE))
}