{smcl}
{* *! version 3.3  20aug2026}{...}

{vieweralsosee "loevh2" "help loevh2"}{...}
{vieweralsosee "loevh2_svy" "help loevh2_svy"}{...}
{viewerjumpto "Syntax" "loevh2_boot##syntax"}{...}
{viewerjumpto "Description" "loevh2_boot##description"}{...}
{viewerjumpto "Options" "loevh2_boot##options"}{...}
{viewerjumpto "Degenerate tables" "loevh2##degenerate"}{...}
{viewerjumpto "When to trust the results" "loevh2_boot##trust"}{...}
{viewerjumpto "Examples" "loevh2_boot##examples"}{...}
{viewerjumpto "Stored results" "loevh2_boot##results"}{...}
{title:Title}

{phang}
{bf:loevh2_boot} {hline 2} Bootstrap confidence intervals for Loevinger's {it:H}

{marker syntax}{...}
{title:Syntax}

{pstd}
Bootstrap confidence intervals for Loevinger's {it:H}

{p 8 17 2}
{cmdab:loevh2_boot} {varlist} {ifin} [{it:weight}] [{cmd:,} {it:options}]

{pstd}
Immediate command

{p 8 17 2}
{cmdab:loevh2_booti} {it:#a} {it:#b} [{cmd:\}] {it:#c} {it:#d} [{cmd:,} {it:immediate_options}]

{p 8 8 2}
where {it:#a}, {it:#b}, {it:#c}, and {it:#d} are the four (nonnegative
integer) cell frequencies of the 2×2 cross-tabulation of the two
variables, entered row by row (first row: {it:#a} {it:#b}; second row:
{it:#c} {it:#d}), exactly as for Stata's own {help tabi}. The backslash
separating the two rows is optional, e.g. {cmd:loevh2_booti 40 10 5 45} and
{cmd:loevh2_booti 40 10 \ 5 45} are equivalent.

{pstd}
Immediate command, comparing two or more 2×2 tables using the bootstrap ({opt c:ompare})

{p 8 17 2}
{cmdab:loevh2_booti} {it:label1} {it:#a1} {it:#b1} [{cmd:\}] {it:#c1} {it:#d1} {cmd:|} {it:label2} {it:#a2} {it:#b2} [{cmd:\}] {it:#c2} {it:#d2} [{cmd:| ...}] {cmd:,} {opt c:ompare} [{it:immediate_options}]

{p 8 8 2}
where each group consists of a {it:label} followed by that group's four
cell frequencies (entered exactly as above), and groups are separated
by the pipe character {cmd:|} (at least two groups are required). A
{it:label} may be a single unquoted word (e.g. {cmd:M}) or, if it
contains a space or could otherwise be mistaken for a number, must be
enclosed in double quotes (e.g. {cmd:"Kyiv Oblast"} or {cmd:"1"});
each label is limited to 32 characters.

{synoptset 17 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt r:eps(#)}}number of bootstrap replications; default is {cmd:reps(1000)}{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt s:eed(#)}}set random-number seed for reproducibility{p_end}
{synopt:{opt t:able}}display a 2×2 table with observed and expected counts, and cell percentages{p_end}
{synopt:{opt p:rogress}}display bootstrap progress bar{p_end}
{synopt:{opt maxt:ries(#)}}maximum number of resampling attempts per replication when a
resample yields a degenerate 2×2 table; default is {cmd:maxtries(50)}{p_end}
{p2coldent:† {opt c:ompare}}test equality of {it:H}s across sub-samples using the bootstrap (with
{cmd:loevh2_boot}, requires {cmd:by:}; with {cmd:loevh2_booti}, requires the multi-group
{cmd:label #a #b \ #c #d | label2 ...} syntax shown above instead of the single
{it:#a #b #c #d} syntax){p_end}
{synopt:{opt bc:correct}}also display the bootstrap bias-corrected point estimate and
its shift-recentered confidence interval; {cmd:r(boot_bc)}, {cmd:r(boot_bc_lb)}, and
{cmd:r(boot_bc_ub)} are always returned regardless of this option{p_end}
{synopt:{opt meta(filename, replace|append)}}save each valid sub-sample's
(label, {it:H}, {it:SE}, {it:N}) row to a persistent .dta file for later meta-analysis{p_end}

{syntab:Immediate command}
{synopt:{opt noTAB}}suppress display of any cross-tabulation{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 }
† {opt c:ompare} with {cmd:loevh2_booti} must not use {cmd:by:}.{p_end}
{p 4 6 2}
{cmd:by} is allowed with {cmd:loevh2_boot}, but not with {cmd:loevh2_booti}; see {manhelp by D}.{p_end}
{p 4 6 2}
{cmd:fweight}s are allowed with {cmd:loevh2_boot}, but not with
{cmd:loevh2_booti}; see {help weight}. For {cmd:pweight} (no bootstrapping) use {help loevh2_svy}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
Loevinger's {it:H} (Loevinger, 1947, pp. 29-31) is a measure of the positive association between two binary
variables that is not influenced by their base rates (marginal proportions) and can be interpreted
as the proportion of "overlap" of two positively associated binary variables, corrected for chance
and ceiling effects (for more details, see {help loevh2}).

{pstd}
{cmd:loevh2_boot} extends {help loevh2} to include bootstrap confidence intervals for Loevinger's {it:H}
coefficient. One genuine, narrower advantage of the bootstrap {it:CI} over {cmd:loevh2}'s default
large-sample (Wald) {it:CI} is that -- like {bf:loevh2}'s {help loevh2##small:{ul:s}mall} option -- it is asymmetric and
can respect the theoretical [{c -}1,1] bound on {it:H}, unlike the symmetric large-sample {it:CI}, which can
spill over 1. Beyond that, however, whether the bootstrap {it:CI} is actually an {it:improvement}
depends heavily on where {it:N} and |{it:H}-hat| fall: simulation evidence (see the
{help loevh2_boot##trust:"When to trust the results"} section below) shows the bootstrap {it:CI}'s own
coverage can degrade sharply in exactly the regime (small {it:N}, high |{it:H}-hat|) where users are most
tempted to reach for it instead of the default {it:CI} -- so it should not be assumed to be
"more robust" across the board. In that same small-{it:N}/high-|{it:H}| regime, {help loevh2_boot##bccorrect:{ul:bc}correct}
offers a more targeted remedy (bias correction of the point estimate and {it:CI}) than simply switching
{it:CI} methods.

{pstd}
The program first calculates Loevinger's {it:H} and its large-sample standard error according to Copas &
Loeber (1990, Eq. 11), then performs bootstrap resampling with {it:BCa} (bias-corrected and accelerated)
confidence intervals. This dual approach allows a comparison between the large-sample and bootstrap
confidence intervals. To make the bootstrap replicates exactly reproducible without disturbing other
random-number use in the same do-file/session, see the note on
{help loevh2_boot##rngstate:preserving/restoring the random-number state} below.

{pstd}
The bootstrap confidence intervals are based on the {it:BCa} method, which adjusts confidence
intervals (1) for systematic bias in the sampling distribution of {it:H} (BC = bias correction), and
(2) for non-constant variance and skewness (a = acceleration). This can be particularly
useful when assessing {it:H} in small samples or when the data structure deviates from conditions
assumed in the asymptotic theory (normal approximation) that is likely to happen for {it:H} in the
interval [{c -}1,1] -- but see the {help loevh2_boot##trust:"When to trust the results"} section below,
since this benefit is only realized within a specific, simulation-validated {it:N}/{it:H}/base-rate range.

{pstd}
Using the option {opt c:ompare} (requires {cmd:by:}), {cmd:loevh2_boot} performs a bootstrap-based
test of the equality of {it:H}s across the resulting sub-samples, analogous to {bf:loevh2}'s own
{help loevh2##compare:{ul:c}ompare} option (Copas & Loeber, 1990, Eq. 16), but using an empirical bootstrap reference
distribution instead of the chi2 distribution. The observed heterogeneity chi-square is computed
from each sub-sample's {it:H} and {it:SE}; the same statistic is then recomputed for each paired
bootstrap replicate across sub-samples, but with each sub-sample's replicate {it:H} first
{bf:null-recentered} onto the overall weighted average {it:H} (Hbar) -- replacing sub-sample i's
raw replicate H_i^(b) with H_i^(b) {c -} H_i + Hbar, where H_i is that sub-sample's own original
(non-bootstrapped) {it:H} -- holding each sub-sample's standard error fixed across replicates, so
only the recentered {it:H} varies by replicate. This recentering step is essential and is the
standard device for turning a bootstrap distribution into a valid null/reference distribution for a
hypothesis test (Efron & Tibshirani, 1993, pp. 223{c -}224; Hall & Wilson, 1991): without it,
each sub-sample's raw bootstrap replicates simply stay centered on its own (possibly very
different) observed {it:H}, so the replicate statistics would merely reproduce the same cross-group
spread that produced the observed heterogeneity chi-square in the first place, systematically and
substantially inflating the resulting p-value (in a real-data test case, an uncentered bootstrap
test gave Pr = 0.850 versus loevh2's Pr = 0.000 for the exact same observed statistic). The
bootstrap {it:p}-value is the proportion of (recentered) replicate heterogeneity chi-squares at
least as large as the observed heterogeneity chi-square.

{marker rngstate}{...}
{pstd}
{bf:Preserving/restoring the random-number state:} {opt s:eed(#)} (like Stata's own
{helpb set seed}) resets Stata's random-number generator to a fixed, reproducible starting
state -- convenient for a single, standalone {cmd:loevh2_boot} call, but this also means any
{it:subsequent} random-number use later in the same do-file/session (e.g. a second
{cmd:loevh2_boot} call, or an unrelated {cmd:bsample}/{cmd:generate ... runiform()}) will
continue from that same fixed state, rather than from wherever the random-number generator
happened to be beforehand. If this matters -- e.g. you want {cmd:loevh2_boot}'s bootstrap to
be reproducible without altering the random-number sequence used elsewhere in the same
do-file -- save and restore Stata's random-number state manually using
{help creturn:c(rngstate)} before and after the call, e.g.:

{p 6 60}{com}. local rngstate0 = c(rngstate){space 20}{txt}// save current RNG state{p_end}
{p 6 60}{com}. loevh2_boot item1 item2, reps(2000) seed(12345){space 2}{txt}// reproducible bootstrap{p_end}
{p 6 60}{com}. set rngstate `rngstate0'{space 25}{txt}// restore RNG state as if{p_end}
{p 6 60}{com}.{space 50}{txt}// loevh2_boot had not been called{p_end}

{pstd}
This pattern also allows re-running just the bootstrap later with bit-identical results,
without needing to re-run everything from the top of the do-file: save {cmd:c(rngstate)}
immediately before the {cmd:loevh2_boot} call (instead of, or in addition to, using
{opt s:eed()}), and {cmd:set rngstate} back to that saved value whenever the same replicates
should be reproduced again.


{marker options}{...}
{title:Options}

{phang}
{opt r:eps(#)} specifies the number of bootstrap replications to perform. The default
is {cmd:reps(1000)}. For the {it:BCa} method as used here 1,000 replications (better >= 2,000) are
generally recommended. More replications (and large samples) provide better estimates but
take longer to compute.

{phang}
{opt l:evel(#)} specifies the confidence level, as a percentage, for confidence intervals. The
default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt s:eed(#)} sets the random-number seed for reproducibility of bootstrap results. This
should be specified whenever you want to ensure the same results across different runs; see
{help loevh2_boot##rngstate:preserving/restoring the random-number state}.

{phang}
{marker table}{...}
{opt t:able} displays a 2×2 table of the two variables with observed and expected counts, and cell
percentages. With {cmd:loevh2_booti}, this detailed table replaces the simple frequency-only
table shown by default (see {help loevh2_boot##notab:noTAB} below). Additionally, it displays
the percent of "overlap" in cell 1/1 ({it:var1}=1 & {it:var2}=1), together with its
(non-bootstrapped) standard error ({cmd:sqrt(p*(1-p)/N)}) and an asymmetric, logit-transformed
Wald confidence interval. {cmd:r(overlap)}, {cmd:r(se_overlap)}, {cmd:r(lb_overlap)}, and
{cmd:r(ub_overlap)} are returned irrespective of {opt t:able}.

{phang}
{opt p:rogress} displays a progress bar during bootstrap replications. By default, no
progress information is shown.

{phang}
{opt maxt:ries(#)} specifies the maximum number of times a bootstrap replication will be
redrawn (resampled) if it produces a degenerate 2×2 table (i.e., a table with a zero
cell or a zero margin, which leaves {it:H} undefined). This can happen, e.g., in small samples
or with unbalanced items, when a resample happens to make one of the two variables (nearly)
constant. The default is {cmd:maxtries(50)}. If a replication still produces a degenerate
table after {opt maxt:ries()} attempts, it is excluded from the bootstrap distribution and
counted; a warning summarizing the number of excluded replications is displayed after the
bootstrap loop, and the bias-correction and percentile calculations of the {it:BCa} confidence
interval are based on the actual (possibly reduced) number of valid replications rather
than the nominal {cmd:reps()}. If the {it:original} (non-bootstrapped) sample itself
produces a degenerate table, {cmd:loevh2_boot} stops with an error, since bootstrapping
is not meaningful in that case.

{phang}
{marker compare}{...}
{opt c:ompare} performs a bootstrap-based test of the equality of {it:H}s across two or more
sub-samples/groups. With {cmd:loevh2_boot}, it requires {cmd:by:} (or {cmd:bysort:}); with
{cmd:loevh2_booti}, it instead requires the multi-group immediate-command syntax shown in
{help loevh2_boot##syntax:Syntax} above ({cmd:loevh2_booti} {it:label1 #a1 #b1 \ #c1 #d1}
{cmd:|} {it:label2 ...}{cmd:, compare}), i.e. at least two groups, each introduced by its own
label (a single unquoted word, or a double-quoted string if it contains a space or would
otherwise be mistaken for a number) followed by that group's four cell frequencies. The
results are stored in  {cmd:r(Hbar)}, {cmd:r(Hbar_se)},{cmd:r(Hbar_N)}, {cmd:r(chi2)},
{cmd:r(df)}, {cmd:r(p_boot)}, and (as a k×3 matrix of each sub-sample's {it:H}, {it:SE}, and {it:N},
row-named by sub-sample label) {cmd:r(H_SE_N)}. Together with the equality test,
{cmd:loevh2_boot} also returns {cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, {cmd:r(ub)}, and
{cmd:r(N)} for the {it:last valid sub-sample} processed (i.e., the last by-group with a
non-missing by-value and a non-degenerate 2×2 table), together with {cmd:r(lastgroup)}
(see {help loevh2##lastgroup:r(lastgroup)} in {cmd:loevh2}), to indicate which value or
category these specific results belong to.

{p 8 8}{cmd:by:}-based compare performs the bootstrap-based test of the equality of the
resulting sub-samples' {it:H}s described above, displayed after all sub-samples' bootstrap
results have been computed (immediately preceded by the "Categories of by: variable(s)"
frequency table of the by-variable(s), shown unconditionally whenever by: is used). The
on-screen output starts with a per-sub-sample table (Sub-sample, {it:H} Coeff, Std. err.,
{it:N} -- the same layout as {cmd:loevh2}'s own {help loevh2##compare:{ul:c}ompare}, though the
{it:SE} column here is the bootstrap standard error, boot_se, not the large-sample Eq. 11
{it:SE}), followed by a "Weighted average {it:H}" (Hbar) summary row showing Hbar, its
pooled bootstrap standard error {it:SE}(Hbar) = sqrt(1/sum(1/boot_se_i{c 178})), and the
total {it:N} summed across sub-samples. Sub-samples with a degenerate 2×2 table are
excluded. The bootstrap Chi2/Pr line and the underlying replicate count are shown on two
lines below the table, e.g.: "Bootstrap Chi2(20) = 21.7153{space 2}Pr= 0.348 | (348/1000
replicates >= observed statistic)." The results are stored in {cmd:r(Hbar)},
{cmd:r(Hbar_se)}, {cmd:r(chi2)}, {cmd:r(df)}, {cmd:r(p_boot)}, and {cmd:r(Hbar_N)}, and
the full per-sub-sample table in {cmd:r(H_SE_N)} (see {help loevh2_boot##results:Stored results}
below).

{phang}
{marker bccorrect}{...}
{opt bc:correct} displays one additional line after the main bootstrap results table: the bootstrap
bias-corrected point estimate for {it:H}, {cmd:2*r(loevh) {c -} r(boot_h)} (Efron & Tibshirani, 1993, ch. 10),
together with its bootstrap standard error, {cmd:r(boot_se)} (the same standard error shown for
the main, uncorrected bootstrap estimate directly above), and its correspondingly shift-recentered
{it:BCa} confidence interval. No {it:p}-value is shown for the bias-corrected estimate: unlike the
shift-recentered {it:CI}, there is no well-justified hypothesis test associated with a bias-corrected
point estimate, and {cmd:r(boot_se)} describes the spread of the (uncorrected) bootstrap replicates,
not something that should be paired with a {it:z}/{it:p} test of the corrected estimate against
zero. The three underlying values {cmd:r(boot_bc)}, {cmd:r(boot_bc_lb)}, and {cmd:r(boot_bc_ub)} are
always computed and returned in {cmd:r()} regardless of whether {opt bc:correct} is specified (see
{help loevh2_boot##results:Stored results}). This option is intended as a
{bf:supplementary remedy for the small-{it:N}/high-|{it:H}| corner, not a universal fix or a replacement for the main bootstrap {it:CI}}
-- see item 2 of the {help loevh2_boot##trust:"When to trust the results"} section below for when
this correction is actually useful.

{phang}
{marker meta}{...}
{opt meta(filename, replace|append)} saves each valid sub-sample's (label,
{it:H}, {it:SE}, {it:N}) row to a persistent Stata dataset {cmd:filename_boot.dta} (note
the automatically appended {cmd:_boot} suffix -- see {cmd:loevh2}'s own
{help loevh2##meta:meta()} option for the full rationale of
this suffix convention, which keeps bootstrap-sourced results from being
mixed with plain {help loevh2}- or {help loevh2_svy}-sourced results in
the same pooled file even when the SAME base filename is supplied to more
than one of these commands). The {it:SE} column saved here is the
{bf:bootstrap} standard error ({cmd:boot_se}), not the large-sample Eq. 11
{it:SE} -- see {help loevh2_boot##r(H_SE_N):r(H_SE_N)} below for the rationale of
this choice, and the {help loevh2_boot##trust:"When to trust the results"}
section for its Monte-Carlo-noise caveat at low {opt r:eps()}.

{p 8 8}Otherwise, {opt meta()} behaves exactly as documented for
{help loevh2##meta:loevh2}: without {opt c:ompare}, exactly one row is saved per call
(or per by-group, if {cmd:by:} is used without {opt c:ompare}); with {opt c:ompare},
all valid sub-samples' rows (matching {cmd:r(H_SE_N)}) are saved together, once, after
the last by-group has been processed. Exactly one of {cmd:replace} or {cmd:append}
must be specified, and a companion {cmd:filename_boot.do} pooling/{help meta}-setup
script is (re)written on every call -- see {cmd:loevh2}'s {help loevh2##meta:meta()}
option for full details on the saved columns, the companion script, and replace/append
semantics.

{p 8 8}{bf:NOTE:} Running the companion pooling script (the {cmd:.do} file written
alongside the {cmd:.dta} file, e.g. {cmd:myfile.do}) will {bf:replace the dataset}
{bf:currently in memory} with the pooled meta-analysis results (it begins with
{cmd:use "myfile.dta", clear}). If you run this script in the middle of a longer
analysis session, be sure to reload your own working dataset (and re-issue any
{help svyset}, if applicable) afterward before continuing, or enclose "{help do}
{bf:myfile.do}" between "{help preserve}" and "{cmd:restore}".

{phang}
{marker notab}{...}
{opt noTAB} (immediate command only; default) suppresses the display of any 2×2 table with
{cmd:loevh2_booti}. By default (when neither {opt notab} nor {opt t:able} is specified), {cmd:loevh2_booti}
displays a simple frequency-only 2×2 table of the entered cell frequencies. Specifying {opt t:able}
instead replaces this simple table with {cmd:loevh2_boot}'s own, more detailed 2×2 table showing
observed and expected counts together with cell percentages plus the percent of "overlap" in cell
1/1 ({it:var1}=1 & {it:var2}=1) (see {help loevh2_boot##table:table} above); the simple table is not shown in
that case. {opt notab} and {opt t:able} cannot be combined.


{marker examples}{...}
{title:Examples}

{p 4 6}Basic usage with 1,000 (default) replications{p_end}
{p 8 10}{cmd:. loevh2_boot item1 item2}{p_end}

{p 4 6}With random seed for reproducibility{p_end}
{p 8 10}{cmd:. loevh2_boot item1 item2, seed(123)}{p_end}

{p 4 6}Same as above with detailed cross-tabulation of items (and percent overlap)
using 99% confidence level{p_end}
{p 8 10}{cmd:. loevh2_boot item1 item2, table level(99) seed(123)}{p_end}

{p 4 6}With frequency weights, 2,000 replications, and progress display{p_end}
{p 8 10}{cmd:. loevh2_boot item1 item2 [fw=freq], reps(2000) progress}{p_end}

{p 4 6}By-group analysis{p_end}
{p 8 10}{cmd:. bysort group: loevh2_boot item1 item2}{p_end}

{p 4 6}By-group analysis, testing equality of {it:H}s across groups using the bootstrap{p_end}
{p 8 10}{cmd:. bysort group: loevh2_boot item1 item2, compare}{p_end}

{p 4 6}Same as above and saving {it:H}, {it:SE}, and {it:N} to loev_meta.dta{p_end}
{p 8 10}{cmd:. bysort group: loevh2_boot item1 item2, compare meta(loev_meta, replace)}{p_end}

{p 4 6}Immediate command, 2,000 replications, enter the four cell frequencies
of a 2×2 table directly{p_end}
{p 8 10}{cmd:. }{stata "loevh2_booti 40 10 \ 5 45, reps(2000) seed(123)"}{p_end}

{p 4 6}Immediate command, with additional bias-corrected point-estimate of {it:H} and suppressing the display of any 2×2 table{p_end}
{p 8 10}{cmd:. }{stata "loevh2_booti 40 10 \ 5 45, notab reps(2000) seed(123) bccorrect"}{p_end}

{p 4 6}Immediate command, comparing two groups using the bootstrap (unquoted single-word labels){p_end}
{p 8 10}{cmd:. }{stata "loevh2_booti M 40 10 \ 5 45 | F 30 20 \ 15 35, compare"}{p_end}

{p 4 6}Immediate command, comparing groups with multi-word labels (must be quoted){p_end}
{p 8 10}{cmd:. }{stata `"loevh2_booti "Kyiv Oblast" 874 282 \ 432 421 | "Kharkiv Oblast" 900 300 \ 400 450, compare"'}{p_end}

{p 4 6}Immediate command, comparing three or more groups{p_end}
{p 8 10}{cmd:. }{stata `"loevh2_booti "Sheffield" 274 200 \ 278 3951 | "Leicester" 19 2 \ 139 197 | "Homerton & Fulham" 1103 692 \ 1424 8207, compare"'}{p_end}

{p 4 6}Same as above, creating dta- and do-file "Yule_1912" {it:(must not exist)} to use Stata's
{help meta} suite for meta-analysis of these data{p_end}
{p 8 10}{cmd:. }{stata `"loevh2_booti "Sheffield" 274 200 \ 278 3951 | "Leicester" 19 2 \ 139 197 | "Homerton & Fulham" 1103 692 \ 1424 8207, c meta("Yule_1912", replace)"'}{p_end}
{p 8 10}{cmd:. }{stata "preserve"}{p_end}
{p 8 10}{cmd:. }{stata "   do Yule_1912_boot.do"}{p_end}
{p 8 10}{cmd:. }{stata "restore"}{p_end}

{p 4 6}Your dataset contains data for a meta-analyses of several studies (e.g. the string
variable "study" and the frequencies of the row cells as numeric variables "vn" (valid
negatives), "fn" (false negatives), "fp" (false positives), and "vp" (valid positives))
and you want to create a dta-file and do-file with filenames "rean_ld83_boot" to use Stata's
{help meta} suite for your meta-analysis of these data. For bootstrapping with a seed number
4 and 2,500 replications you can use the immediate command {cmd:loevh2_booti} with:{p_end}
{p 8 10}{bf:. stata `"local spec = `""`=study[1]'" `=vn[1]' `=fn[1]' `=fp[1]' `=vp[1]'"'}{p_end}
{p 8 10}{bf:. forvalues i = 2/`=_N' {c 123}}{p_end}
{p 8 10}{bf:.{space 4}local spec = `"`spec' | "`=study[`i']'" `=vn[`i']' `=fn[`i']' `=fp[`i']' `=vp[`i']'"'}{p_end}
{p 8 10}{bf:.{space 2}{c 125}}{p_end}
{p 8 10}{bf:. loevh2_booti `spec', s(4) r(2500) compare meta(rean_ld83_, replace)}{p_end}
{p 8 10}{bf:. perserve}{p_end}
{p 8 10}{bf:.{space 4}do rean__ld83_boot.do}{p_end}
{p 8 10}{bf:. restore}{p_end}

{p 4 6}Immediate command, showing detailed 2×2 table (and percent overlap) instead of the simple table{p_end}
{p 8 10}{cmd:. }{stata "loevh2_booti 40 10 \ 5 45, table"}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loevh2_boot} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Original results (scalars)}{p_end}
{synopt:{cmd:r(loevh)}}Loevinger's {it:H} coefficient (missing if 2×2 table is degenerate); with
{cmd:by:}, this {it:H} and the follwing r-returns until {bf:r(ub_overlap)} are for the sub-sample
identified by {cmd:r(lastgroup)}{p_end}
{synopt:{cmd:r(se)}}large-sample standard error{p_end}
{synopt:{cmd:r(lb)}}lower bound of asymptotic confidence interval{p_end}
{synopt:{cmd:r(ub)}}upper bound of asymptotic confidence interval{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(overlap)}}Percent overlap in cell 1/1 ({it:var1}=1 & {it:var2}=1){p_end}
{synopt:{cmd:r(se_overlap)}}Standard error{p_end}
{synopt:{cmd:r(lb_overlap)}}lower bound of confidence interval (logit-transformed){p_end}
{synopt:{cmd:r(ub_overlap)}}upper bound of confidence interval (logit-transformed){p_end}

{p2col 5 20 24 2: Bootstrap results (scalars)}{p_end}
{synopt:{cmd:r(boot_h)}}Loevinger's {it:H} coefficient, bootstrapped (mean of the bootstrap
replicates){p_end}
{synopt:{cmd:r(boot_se)}}bootstrap standard error{p_end}
{synopt:{cmd:r(boot_z)}}{it:z} statistic for testing {it:H} against zero, computed as
{cmd:r(loevh)}/{cmd:r(boot_se)} (i.e., the {it:original}, non-bootstrapped {it:H} divided
by the bootstrap standard error -- not the bootstrap mean {cmd:r(boot_h)}; see
{help loevh2_boot##description:Description} above){p_end}
{synopt:{cmd:r(boot_p)}}two-sided {it:p}-value corresponding to {cmd:r(boot_z)}{p_end}
{synopt:{cmd:r(boot_lb)}}bootstrap lower bound of confidence interval{p_end}
{synopt:{cmd:r(boot_ub)}}bootstrap upper bound of confidence interval{p_end}
{synopt:{cmd:r(Hbar)}}weighted average {it:H} across sub-samples (only with
{opt c:ompare}){p_end}
{synopt:{cmd:r(Hbar_se)}}pooled bootstrap standard error of {cmd:r(Hbar)},
sqrt(1/sum(1/boot_se_i{c 178})) (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(chi2)}}observed weighted heterogeneity chi-square (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(df)}}degrees of freedom (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(p_boot)}}bootstrap {it:p}-value for equality of {it:H}s across sub-samples
(only with {opt c:ompare}){p_end}
{synopt:{cmd:r(Hbar_N)}}total {it:N} summed across all valid sub-samples (only with
{opt c:ompare}){p_end}
{synopt:{cmd:r(boot_z0)}}bootstrap bias-correction constant ({it:BCa}'s internal z0,
not to be confused with {cmd:r(boot_bc)} below){p_end}
{synopt:{cmd:r(boot_a)}}bootstrap acceleration constant{p_end}
{synopt:{cmd:r(boot_bc)}}bootstrap bias-corrected point estimate for {it:H},
{cmd:2*r(loevh){c -}r(boot_h)} (always returned, regardless of {opt bc:correct};
see {help loevh2_boot##bccorrect:bccorrect} above and the
{help loevh2_boot##trust:"When to trust the results"} section below){p_end}
{synopt:{cmd:r(boot_bc_lb)}}lower bound of the shift-recentered confidence interval
corresponding to {cmd:r(boot_bc)} (always returned, regardless of {opt bc:correct}){p_end}
{synopt:{cmd:r(boot_bc_ub)}}upper bound of the shift-recentered confidence interval
corresponding to {cmd:r(boot_bc)} (always returned, regardless of {opt bc:correct}){p_end}
{synopt:{cmd:r(reps)}}number of bootstrap replications requested{p_end}
{synopt:{cmd:r(reps_valid)}}number of valid (non-degenerate) bootstrap replications used{p_end}
{synopt:{cmd:r(reps_failed)}}number of replications excluded due to a persistently
degenerate table{p_end}
{synopt:{cmd:r(maxtries)}}maximum number of times a bootstrap replication will be redrawn{p_end}
{synopt:{cmd:r(seed)}}random seed used (0 if not set){p_end}

{marker r(H_SE_N)}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(H_SE_N)}}k×3  matrix with one row per valid sub-sample and columns
{it:H}, {it:SE}, {it:N}; row names are the sub-sample labels (only with {opt c:ompare}). {it:H}
is the original, non-bootstrapped {it:H} (as in {cmd:r(loevh)}), and {it:N} is the sub-sample
size (as in {cmd:r(N)}) -- but, unlike {help loevh2}'s own {cmd:r(H_SE_N)}, the {it:SE} column
here is the {bf:bootstrap} standard error ({cmd:r(boot_se)}), not the large-sample Eq. 11
standard error ({cmd:r(se)}). This is a deliberate choice: {cmd:boot_se} reflects {it:H}'s
actual (possibly skewed/non-normal) sampling variability via resampling, which can make it a
more trustworthy standard error than the Eq. 11 large-sample formula, especially in small
sub-samples or when {it:H} is close to {c 177}1 (though see the
{help loevh2_boot##trust:"When to trust the results"} section below for the limits of this
benefit). Because {cmd:boot_se} is a simulation-based estimate, it carries some Monte Carlo
noise at low {opt r:eps()}; a higher {opt r:eps()} (1,000-2,000 or more) is recommended
whenever {cmd:r(H_SE_N)} will be used as input for subsequent meta-analysis across
sub-samples (e.g. via Stata's {help meta} suite, see option {opt meta} above).{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(var1)}}name of row variable{p_end}
{synopt:{cmd:r(var2)}}name of column variable{p_end}
{synopt:{cmd:r(se_type)}}type of standard error: {cmd:"large sample, bootstrap"} (identifying
that {cmd:r(se)} is the large-sample Eq. 11 standard error and {cmd:r(boot_se)} the bootstrap
standard error, unlike {help loevh2}'s own {cmd:r(se_type)}, which distinguishes between
{cmd:"large sample"}, {cmd:"Pearson Chi²"}, and {cmd:"small sample"}){p_end}
{synopt:{cmd:r(weight_type)}}weight type used (if weights were used){p_end}
{synopt:{cmd:r(weight)}}weight variable name (if weights were used){p_end}
{synopt:{cmd:r(group)}}by-group variables (if by: used){p_end}
{synopt:{cmd:r(lastgroup)}}if {cmd:by:} (loevh2_boot) or {cmd:c:ompare} {cmd:loevh2_booti} was
used: value or category label of the sub-sample to which {cmd:r(overlap)}
and its statistics (with option {opt t:able}), and {cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)},
{cmd:r(ub)}, and {cmd:r(N)} belong (see also {help loevh2##lastgroup:r(lastgroup)} in {cmd:loevh2}){p_end}
{synopt:{cmd:r(error)}}{cmd:"degenerate"} if the (original, non-bootstrapped) 2×2
table for this by-group has a zero cell or margin, so that {it:H} and its bootstrap {it:CI} are
undefined (see {cmd:loevh2}'s {help loevh2##degenerate:"Degenerate tables"} section for
background), or {cmd:"missing_byvar"} if this by-group was skipped because its
by-value is missing or the {cmd:if}/{cmd:in} condition left no observations for it. In
both cases, {cmd:r(lastgroup)} and the other scalars above still refer to the
last VALID by-group actually processed.{p_end}


{marker trust}{...}
{title:When to trust the results (guidance from simulation study)}

{pstd}
A large Monte Carlo simulation study examined the coverage of {help loevh2}'s default
large-sample confidence interval alongside {cmd:loevh2_boot}'s bootstrap {it:BCa} confidence interval,
across a wide grid of {it:N}, true {it:H}, and base-rate combinations. The main, actionable conclusions
for deciding {it:when the bootstrap {it:CI} is worth the extra computation, and when it is not}, are:

{phang2}1. {bf:N >= ~500-1,000 and |{it:H}-hat| not close to 1 (say < 0.7):} {help loevh2}'s default
large-sample {it:CI} is already close to nominal 95% coverage in this regime, and the bootstrap {it:CI}
typically performs no better (sometimes marginally worse, due to Monte Carlo noise at low
{opt r:eps()}). There is little practical benefit from {cmd:loevh2_boot} here -- the much faster
{help loevh2} is normally sufficient.{p_end}

{phang2}2. {bf:N small (< ~250) and/or |{it:H}-hat| large (> ~0.7-0.8):} {it:neither} the default
large-sample {it:CI} nor the bootstrap {it:BCa} {it:CI} can be trusted at face value in this corner. The
default {it:CI} tends to {it:over-cover} deceptively (its width happens to reach a badly biased {it:H}-hat
more or less by coincidence, not because it is well calibrated), while the bootstrap {it:BCa} {it:CI} can
{it:catastrophically under-cover} (down to 0.00 in the worst simulaton scenarios), because it anchors
tightly around the same badly biased point estimate it is resampling from.
{bf:loevh2_boot is not automatically "the safe choice" here just because it is a bootstrap.} The single
biggest remedy is increasing {it:N}. If {it:N} cannot be increased, a bootstrap bias-corrected point
estimate is automatically available as {cmd:r(boot_bc)} (= {cmd:2*r(loevh) - r(boot_h)}, computed with
no extra resampling; use the {help loevh2_boot##bccorrect:{ul:bc}correct} option to also display it and its recentered {it:CI}
on-screen) -- {it:not} the jackknife, which the simulation study shows worsens bias in this
same regime. This is a supplementary remedy, not a universal fix: report results from more than
one method side by side rather than relying on any single {it:CI}.{p_end}

{phang2}3. {bf:Concrete "safe zone" for the bootstrap {it:CI}:} the simulation grids for the
region where mean bootstrap {it:CI} coverage reaches >= 0.85 gave: |{it:H}-hat| <= ~0.85; {it:N} at least
~100-150 when the two variables' base rates are roughly balanced (ratio <= 3), rising to
~200-250 when the base-rate ratio is 3:1 or worse. Outside this zone, treat the bootstrap {it:CI}
with the same scepticism as the default {it:CI}, not as a guaranteed improvement.{p_end}

{phang2}4. {bf:{opt c:ompare}:} before trusting the {cmd:Hbar}/bootstrap {it:p}-value summary,
flag or exclude any sub-sample with {it:N} < ~250 or |{it:H}-hat| > ~0.7 -- both the observed weighted
chi-square statistic and the paired-replicate reference distribution implicitly assume each
sub-sample's {it:H}-hat is approximately unbiased, which is exactly what fails in this corner.{p_end}

{phang2}5. {bf:reps():} the simulation evidence above is based on {cmd:reps(1000)} or more; with
fewer replications (e.g. {bf:reps(100)}), Monte Carlo noise in the {it:BCa} bounds and {cmd:boot_se}
can itself meaningfully distort coverage, on top of the small-{it:N}/high-{it:H} issues described
above. Always use at least 1,000 replications -- the default of {opt r:eps()} -- or more (>= 2,000
preferred) before drawing substantive conclusions from the bootstrap {it:CI}, especially near the
boundary of the "safe zone" in item 3.{p_end}


{marker seealso}{...}
{title:See also}

{phang}
{help loevh2} provides (asymptotic) standard errors for Loevinger's {it:H} for large
and small samples.

{phang}
{help loevh2_svy} provides design-based (survey) standard errors and confidence intervals for
Loevinger's {it:H} under an active {help svyset} declaration ({cmd:pweight}/{cmd:iweight},
{cmd:cluster()}, and/or {cmd:strata()}) -- the recommended command for
weighted / clustered / stratified data.

{phang}
{help loevh} (if installed) by Jean-Benoit Hardouin provides Loevinger's {it:H} coefficient for multiple
items (see {stata ssc describe loevh}).

{phang}
{help rioc} (if installed) by Daniel Klein calculates the "relative improvement over chance" (RIOC)
coefficient according to Copas & Loeber (1990) together with additional statistics (see {stata ssc describe rioc}).

{phang}
{help rioci} by Daniel Klein is the immediate-command counterpart to {cmd:rioc} (see {stata ssc describe rioc}).


{marker author}{...}
{title:Author}

{pstd}Dirk Enzmann (University of Hamburg) with AI assistance (Claude/Anthropic){p_end}


{marker acknowledgements}{...}
{title:Acknowledgments}

{phang}
{cmd:loevhi_boot} leans heavily on {cmd:rioci} version 1.0.0 by Daniel Klein (see {stata ssc describe rioc}).{p_end}


{marker references}{...}
{title:References}

{phang}
Copas, J. B., & Loeber, R. (1990). Relative improvement over chance (RIOC) for 2×2
tables. {it:British Journal of Mathematical and Statistical Psychology}, 
{it:43}(2), 293–307. {browse "https://doi.org/10.1111/j.2044-8317.1990.tb00942.x":https://doi.org/10.1111/j.2044-8317.1990.tb00942.x}

{phang}
Efron, B., & Tibshirani, R. J. (1993). {it:An Introduction to the Bootstrap}. New York: Chapman & Hall/CRC.

{phang}
Hall, P., & Wilson, S. R. (1991). Two guidelines for bootstrap hypothesis testing. {it:Biometrics}, {it:47}(2),
757–762. {browse "https://doi.org/10.2307/2532163":https://doi.org/10.2307/2532163}

{phang}
Loevinger, J. A. (1947). A systematic approach to the construction and evaluation of
tests of ability. {it:Psychological Monographs}, {it:61}(4), i–49. {browse "https://doi.org/10.1037/h0093565":https://doi.org/10.1037/h0093565}
{phang}