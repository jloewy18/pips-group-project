# Shared ggplot theme (requires ggplot2 to be loaded when called)
plot_theme = function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "none",
      plot.title = element_text(face = "bold")
    )
}