#!/usr/bin/env Rscript
# Figure 6: risk in the groups on which MD-COPD and the ESI classification agree
# or disagree, within each stratum of airflow limitation.
#
# Rows are strata and columns outcomes. Each panel shows the three groups either
# classification calls COPD, against that stratum's own reference: participants
# both classify as noCOPD with preserved spirometry, and as AFL-only with airflow
# limitation. Crude open and adjusted filled, as in Figures 2 to 4. Group colors
# follow the v15 discordance figure: CT-only blue, Both gray, ESI-only red.
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
ad <- read.csv(file.path(ASSETS, "discord_adjusted_strata.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(cr) == 18, nrow(ad) == 6)
GRP  <- c("CT-only-COPD" = "CT-only", "ESI-only-COPD" = "ESI-only", "Both-COPD" = "Both-COPD")
GCOL <- c("CT-only" = "#1F77B4", "Both-COPD" = "#7F7F7F", "ESI-only" = "#D62728")
OUTC <- c(all = "All-cause mortality", resp = "Respiratory mortality", exac = "Exacerbations")
STR  <- c("Preserved spirometry" = "Preserved\nspirometry",
          "Airflow limitation"   = "Airflow\nlimitation")

adj <- bind_rows(
  transmute(ad, stratum, group, outcome = "all",  est = all_HR,   lo = all_LCI,  hi = all_UCI),
  transmute(ad, stratum, group, outcome = "resp", est = resp_HR,  lo = resp_LCI, hi = resp_UCI),
  transmute(ad, stratum, group, outcome = "exac", est = exac_IRR, lo = exac_LCI, hi = exac_UCI)) %>%
  left_join(select(cr, stratum, group, outcome, events), by = c("stratum", "group", "outcome"))
d <- bind_rows(
  transmute(cr, stratum, group, outcome, est = rr, lo, hi, events, type = "Crude"),
  mutate(adj, type = "Adjusted"))
stopifnot(!anyNA(d$events), nrow(d) == 36)
# Respiratory mortality is left out (Pete, 2026-09-11): too few deaths in the
# discordant groups and the airflow-limitation reference. Its totals go in the legend.
d <- d[d$outcome != "resp", ]
# Below the event floor the point stands without an interval; with no events
# there is no estimate at all, and the group is left out of that panel.
MIN_EVENTS_FIG <- 10     # the analysis event floor (MIN_EVENTS in the Rmd)
# The floor applies to the reference too: a ratio against a reference with two
# deaths is as unstable as one for a group with two. Reference death counts come
# from the rate artifacts; exacerbation counts in every reference are in the hundreds.
rt <- rbind(cbind(stratum = "Preserved spirometry",
                  read.csv(file.path(ASSETS, "discord_rates.csv"))[, c("group", "deaths", "resp_deaths")]),
            cbind(stratum = "Airflow limitation",
                  read.csv(file.path(ASSETS, "discord_rates_afl.csv"))[, c("group", "deaths", "resp_deaths")]))
rt_all <- rt
rt <- rt[rt$group %in% c("Both-noCOPD", "Both-AFL-only"), ]
stopifnot(nrow(rt) == 2)
ref_ev <- rbind(data.frame(stratum = rt$stratum, outcome = "all",  ref_events = rt$deaths),
                data.frame(stratum = rt$stratum, outcome = "resp", ref_events = rt$resp_deaths),
                data.frame(stratum = rt$stratum, outcome = "exac", ref_events = Inf))
d <- d %>% left_join(ref_ev, by = c("stratum", "outcome"))
stopifnot(!anyNA(d$ref_events))
low <- d$events < MIN_EVENTS_FIG | d$ref_events < MIN_EVENTS_FIG
d$lo[low] <- NA; d$hi[low] <- NA
d <- d %>%
  filter(events > 0, is.finite(est), est > 0)
d$grp     <- factor(GRP[d$group], levels = rev(c("CT-only", "ESI-only", "Both-COPD")))
d$outcome <- factor(OUTC[d$outcome], levels = OUTC[c("all", "exac")])
d$stratum <- factor(d$stratum, levels = names(STR))
d$type    <- factor(d$type, levels = c("Crude", "Adjusted"))
# With respiratory mortality out, every plotted cell clears the floor.
stopifnot(!any(is.na(d$lo)), all(d$events >= MIN_EVENTS_FIG), all(d$ref_events >= MIN_EVENTS_FIG))
RESP <- function(st, g) rt_all$resp_deaths[rt_all$stratum == st & rt_all$group == g]

pd <- position_dodge(width = 0.55)
d$dodge <- factor(d$type, levels = c("Adjusted", "Crude"))   # crude on top
p <- ggplot(d, aes(x = est, y = grp, colour = grp, shape = type, group = dodge)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45", linewidth = 0.4) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.6, position = pd, na.rm = TRUE) +
  geom_point(size = 2.6, position = pd, fill = "white", stroke = 0.9) +
  scale_shape_manual(values = c(Crude = 21, Adjusted = 19), name = NULL) +
  scale_colour_manual(values = GCOL, guide = "none") +
  scale_x_log10(breaks = c(1, 2, 3, 5),
                labels = scales::label_number(drop0trailing = TRUE),
                expand = expansion(mult = c(0.10, 0.14))) +
  facet_grid(stratum ~ outcome, scales = "free_x",
             labeller = labeller(stratum = STR)) +
  labs(x = "Ratio versus the stratum reference (log scale)", y = NULL) +
  theme_esi() +
  theme(legend.position = "bottom", legend.margin = margin(t = -2, b = 0),
        panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        plot.margin = margin(4, 6, 2, 4))

out <- file.path(HERE, "figure6_discord_risk.png")
validate_layout(p, out)
ggsave(out, p, width = NATIVE_W, height = 4.4, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figure6_discord_risk.meta"))

adj_note <- paste("Adjusted models carry age, sex, race, current smoking status, pack-years",
                  "and body mass index, with prior exacerbation frequency added for",
                  "exacerbations.")
writeLines(c(
  "**Figure 6. Risk in the groups on which MD-COPD and the ESI classification agree or disagree.**",
  "",
  paste("Crude (open circles) and adjusted (filled circles) ratios for the three groups either",
        "classification calls COPD, within each stratum of airflow limitation: against the",
        "participants both classify as noCOPD among those with preserved spirometry (top row),",
        "and against those both classify as AFL-only among those with airflow limitation",
        "(bottom row). The two rows have different references, so estimates are comparable",
        "within a row and not between rows. CT-only, COPD under MD-COPD only; ESI-only, COPD",
        "under the ESI classification only; Both-COPD, COPD under both.",
        "Respiratory mortality is not shown because the numbers of respiratory deaths are too",
        sprintf(paste("small for estimation: with preserved spirometry, %d in the reference, %d CT-only,",
                      "%d ESI-only and %d Both-COPD; with airflow limitation, %d in the reference, %d CT-only,",
                      "%d ESI-only and %d Both-COPD."),
                RESP("Preserved spirometry", "Both-noCOPD"), RESP("Preserved spirometry", "CT-only-COPD"),
                RESP("Preserved spirometry", "ESI-only-COPD"), RESP("Preserved spirometry", "Both-COPD"),
                RESP("Airflow limitation", "Both-AFL-only"), RESP("Airflow limitation", "CT-only-COPD"),
                RESP("Airflow limitation", "ESI-only-COPD"), RESP("Airflow limitation", "Both-COPD")),
        adj_note,
        "AFL-only, airflow limitation without other criteria.")),
  file.path(HERE, "figure6_discord_risk_legend.md"))
cat("wrote", out, "\n")
