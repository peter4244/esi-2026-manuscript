# Diagnostic (note esi-resp_r2): how does follow-up in the cause-of-death file compare with the
# vital-status file? The respiratory rerun stopped because cause-of-death follow-up exceeded
# vital-status follow-up for some participants. Reads only the two files; prints aggregates only
# (counts, quantiles, date ranges). Run from the clone root:  Rscript ctfree_diag_followup.R

source("config_paths.R")
rd <- function(p) {
  h <- readLines(p, n = 1, warn = FALSE)
  d <- read.delim(p, sep = if (grepl("\t", h)) "\t" else ",", stringsAsFactors = FALSE)
  names(d) <- sub("^﻿", "", names(d)); d
}
vs <- rd(VS_PATH); cod <- rd(COD_PATH)
cat("vital-status columns:", paste(names(vs), collapse = ", "), "\n")
cat("cause-of-death columns:", paste(names(cod), collapse = ", "), "\n")
need <- c("mortality_survival_vital_status", "censor_date", "days_followed")
if (!all(need %in% names(cod)))
  stop("cause-of-death file lacks: ", paste(setdiff(need, names(cod)), collapse = ", "))
cat("\n")
m <- merge(vs[, c(ID_COL, "vital_status", "days_followed")],
           cod[, c(ID_COL, "mortality_survival_vital_status", "censor_date", "days_followed")],
           by = ID_COL, suffixes = c("_vs", "_cod"))
cat("participants in both files:", nrow(m), " (vital status", nrow(vs), ", cause of death", nrow(cod), ")\n")
d <- (m$days_followed_cod - m$days_followed_vs) / 365.25
cat("NA days: vs", sum(is.na(m$days_followed_vs)), " cod", sum(is.na(m$days_followed_cod)), "\n")
cat("days_followed == 0: vs", sum(m$days_followed_vs == 0, na.rm = TRUE),
    " cod", sum(m$days_followed_cod == 0, na.rm = TRUE), "\n")
cat("cause-of-death follow-up longer than vital status by > 1 day:", sum(d > 1 / 365.25, na.rm = TRUE), "\n")
cat("  of those, vital-status days == 0:", sum(d > 1 / 365.25 & m$days_followed_vs == 0, na.rm = TRUE), "\n")
cat("  of those, vital-status days > 0:", sum(d > 1 / 365.25 & m$days_followed_vs > 0, na.rm = TRUE), "\n")
cat("  difference (years) quantiles among them:\n")
print(round(quantile(d[d > 1 / 365.25], c(0, .1, .5, .9, 1), na.rm = TRUE), 2))
cat("  status cross-tab among them (rows vital status, cols cause-of-death status):\n")
k <- which(d > 1 / 365.25)
print(table(vs = m$vital_status[k], cod = m$mortality_survival_vital_status[k], useNA = "ifany"))
cat("\nvital-status days == 0, by vital status:\n"); print(table(m$vital_status[m$days_followed_vs == 0]))
cat("cause-of-death days for them (years) quantiles:\n")
print(round(quantile(m$days_followed_cod[m$days_followed_vs == 0] / 365.25, c(0, .1, .5, .9, 1), na.rm = TRUE), 2))
cat("\nfollow-up (years) quantiles, all participants: vs\n")
print(round(quantile(m$days_followed_vs / 365.25, c(0, .1, .5, .9, 1), na.rm = TRUE), 2))
cat("cod\n"); print(round(quantile(m$days_followed_cod / 365.25, c(0, .1, .5, .9, 1), na.rm = TRUE), 2))
cat("\ncause-of-death censor_date: first 3 distinct formats seen:", paste(head(unique(nchar(m$censor_date)), 3), collapse = ", "),
    "characters; min and max as text:", min(m$censor_date, na.rm = TRUE), max(m$censor_date, na.rm = TRUE), "\n")
