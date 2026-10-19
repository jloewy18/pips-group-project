# Installs missing packages and attaches the ones the project needs
REQUIRED_PACKAGES = c("shiny", "ggplot2")

ensure_packages = function(pkgs = REQUIRED_PACKAGES) {
  missing = pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0)
    install.packages(missing)
  invisible(lapply(pkgs, library, character.only = TRUE))
}