#!/usr/bin/env Rscript
# Figure 3: risk in the groups on which MD-COPD and the ESI classification agree
# or disagree, within each stratum of airflow limitation.
#
# Rows are strata and columns outcomes. Each panel shows the three groups either
# classification calls COPD, against that stratum's own reference: participants
# both classify as noCOPD with preserved spirometry, and as AFL-only with airflow
# limitation. Crude ratios only (Pete, 2026-09-11). Group colors follow the v15
# discordance figure: CT-only blue, Both gray, ESI-only red.
#
# Respiratory mortality is left out (Pete, 2026-09-11): too few deaths in the
# discordant groups and the airflow-limitation reference. Its totals go in the
# legend.
#
# The two rows have different references, so estimates compare within a row and
# not between rows. The x axis is free per outcome and shared down a column.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

cr <- read.csv(file.path(ASSETS, "discord_crude_strata.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(cr) == 18)
GRP  <- c("CT-only-COPD" = "CT-only", "ESI-only-COPD" = "ESI-only", "Both-COPD" = "Both-COPD")
GCOL <- c("CT-only" = "#1F77B4", "Both-COPD" = "#7F7F7F", "ESI-only" = "#D62728")
OUTC <- c(all = "All-cause mortality", exac = "Exacerbations")
STR  <- c("Preserved spirometry" = "Preserved\nspirometry",
          "Airflow limitation"   = "Airflow\nlimitation")

d <- cr %>% filter(outcome %in% names(OUTC)) %>%
  transmute(stratum, group, outcome, est = rr, lo, hi, events)
stopifnot(nrow(d) == 12, !anyNA(d$events))

# The event floor applies to the group and to its reference. Reference death
# counts come from the rate artifacts; exacerbation counts in every reference
# are in the hundreds.
MIN_EVENTS_FIG <- 10     # the analysis event floor (MIN_EVENTS in the Rmd)
rt <- rbind(cbind(stratum = "Preserved spirometry",
                  read.csv(file.path(ASSETS, "discord_rates.csv"))[, c("group", "deaths", "resp_deaths")]),
            cbind(stratum = "Airflow limitation",
                  read.csv(file.path(ASSETS, "discord_rates_afl.csv"))[, c("group", "deaths", "resp_deaths")]))
ref <- rt[rt$group %in% c("Both-noCOPD", "Both-AFL-only"), ]
stopifnot(nrow(ref) == 2)
ref_ev <- rbind(data.frame(stratum = ref$stratum, outcome = "all",  ref_events = ref$deaths),
                data.frame(stratum = ref$stratum, outcome = "exac", ref_events = Inf))
d <- left_join(d, ref_ev, by = c("stratum", "outcome"))
# With respiratory mortality out, every plotted cell clears the floor and has an interval.
stopifnot(!anyNA(d$ref_events), !anyNA(d$lo), !anyNA(d$hi),
          all(d$events >= MIN_EVENTS_FIG), all(d$ref_events >= MIN_EVENTS_FIG))

d$grp     <- factor(GRP[d$group], levels = rev(c("CT-only", "ESI-only", "Both-COPD")))
d$outcome <- factor(OUTC[d$outcome], levels = OUTC)
d$stratum <- factor(d$stratum, levels = names(STR))

p <- ggplot(d, aes(x = est, y = grp, colour = grp)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45", linewidth = 0.4) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.6) +
  geom_point(size = 2.6) +
  scale_colour_manual(values = GCOL, guide = "none") +
  scale_x_log10(breaks = c(1, 2, 3, 5),
                labels = scales::label_number(drop0trailing = TRUE),
                expand = expansion(mult = c(0.10, 0.14))) +
  facet_grid(stratum ~ outcome, scales = "free_x",
             labeller = labeller(stratum = STR)) +
  labs(x = "Crude ratio versus the stratum reference (log scale)", y = NULL) +
  theme_esi() +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        plot.margin = margin(4, 6, 2, 4))

out <- file.path(HERE, "figure3_discord_risk.png")
validate_layout(p, out)
ggsave(out, p, width = NATIVE_W, height = 3.8, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figure3_discord_risk.meta"))

writeLines(c(
  "**Figure 3. Risk in the COPD-diagnosed subjects grouped by agreement of MD-COPD and ESI classifications.**",
  "",
  paste("Crude rate ratios for all-cause mortality and exacerbations, with 95% confidence",
        "intervals, for the three groups either classification calls COPD, within each stratum",
        "of airflow limitation. Reference groups are the subjects classified as noCOPD by both",
        "methods among those with preserved spirometry (top row) and subjects classified as",
        "AFL-only by both methods among those with airflow limitation (bottom row). Intervals",
        "are exact Poisson intervals for deaths and subject-bootstrap intervals for",
        "exacerbations. CT-only = diagnosed as COPD under MD-COPD only; ESI-only = diagnosed",
        "as COPD under the ESI classification only; Both-COPD = diagnosed as COPD under both;",
        "AFL-only = airflow limitation without other criteria. Respiratory mortality is not",
        "shown because the numbers of respiratory deaths are too small for estimation.")),
  file.path(HERE, "figure3_discord_risk_legend.md"))
cat("wrote", out, "\n")
