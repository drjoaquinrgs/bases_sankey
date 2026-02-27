required_packages <- c("ggplot2", "dplyr", "grid", "ragg", "tibble")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

library(ggplot2)
library(dplyr)
library(grid)
library(ragg)

# Datos (población cis)
df <- tibble::tibble(
  categoria = c("Hombre cis", "Mujer cis"),
  n = c(455, 881)
) %>%
  mutate(
    N_cis = sum(n),
    pct = n / N_cis * 100,
    etiqueta = sprintf("%.2f%%", pct),
    y = c(2, 1) # arriba hombre, abajo mujer
  )

# Colores (los que usted ya viene usando)
col_hombre <- "#4A5460"
col_mujer <- "#9C59D1"

# Helpers: convierten numéricos (npc) a unit y usan solo unit arithmetic
u <- function(val) unit(val, "npc")

draw_male <- function(x, y, col) {
  # x, y en [0,1] npc
  grid.circle(u(x), u(y) + u(0.06), r = u(0.035), gp = gpar(fill = col, col = NA))
  grid.rect(u(x), u(y) - u(0.01), width = u(0.08), height = u(0.12), gp = gpar(fill = col, col = NA))
  grid.rect(u(x - 0.02), u(y) - u(0.11), width = u(0.025), height = u(0.10), gp = gpar(fill = col, col = NA))
  grid.rect(u(x + 0.02), u(y) - u(0.11), width = u(0.025), height = u(0.10), gp = gpar(fill = col, col = NA))
}

draw_female <- function(x, y, col) {
  grid.circle(u(x), u(y) + u(0.06), r = u(0.035), gp = gpar(fill = col, col = NA))
  grid.polygon(
    x = unit(c(x - 0.05, x + 0.05, x), "npc"),
    y = unit(c(y - 0.02, y - 0.02, y - 0.16), "npc"),
    gp = gpar(fill = col, col = NA)
  )
}

# Plot base (sin ejes)
p <- ggplot(df, aes(y = y)) +
  geom_tile(aes(x = 0.62, width = 0.55, height = 0.55,
                fill = ifelse(categoria == "Hombre cis", "H", "M"))) +
  geom_text(aes(x = 0.62, label = etiqueta), color = "white", size = 8, fontface = "bold") +
  geom_text(aes(x = 0.20, label = categoria), hjust = 0, size = 5) +
  scale_fill_manual(values = c(H = col_hombre, M = col_mujer), guide = "none") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0.5, 2.5), expand = FALSE) +
  labs(
    title = "Distribución dentro de la población cis (N = 1,336)",
    subtitle = "Denominador: estudiantes cis (94.75% de respondedores)"
  ) +
  theme_void(base_size = 16) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0, size = 18),
    plot.subtitle = element_text(hjust = 0, size = 12),
    plot.margin = margin(20, 30, 20, 30)
  )

# Exportación institucional (PNG 300 dpi)
outfile <- "genero_cis_informe_anual.png"
ragg::agg_png(outfile, width = 2000, height = 900, res = 300)
print(p)

# Íconos: posiciones en npc (ajustadas para coincidir con los renglones)
draw_male(x = 0.12, y = 0.67, col = col_hombre)
draw_female(x = 0.12, y = 0.34, col = col_mujer)

dev.off()

message("Listo: ", normalizePath(outfile))
