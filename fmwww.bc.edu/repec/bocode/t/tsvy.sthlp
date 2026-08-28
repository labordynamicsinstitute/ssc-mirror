{smcl}
{* *! version 1.6.0  26aug2026}{...}
{vieweralsosee "svylet" "help svylet"}{...}
{vieweralsosee "tsvy (en espanol)" "help tsvy_es"}{...}
{viewerjumpto "Syntax" "tsvy##syntax"}{...}
{viewerjumpto "Description" "tsvy##description"}{...}
{viewerjumpto "Options" "tsvy##options"}{...}
{viewerjumpto "Remarks" "tsvy##remarks"}{...}
{viewerjumpto "Examples" "tsvy##examples"}{...}
{viewerjumpto "Frame layout" "tsvy##frame"}{...}
{viewerjumpto "References" "tsvy##references"}{...}
{viewerjumpto "Author" "tsvy##author"}{...}
{viewerjumpto "Also see" "tsvy##also_see"}{...}
{hline}
{title:Title}

{phang}
{bf:tsvy} {hline 2} Point-estimate table and Wald/Bonferroni/CLD test,
by level of aggregation and year, using {helpb svylet} as the estimation
engine


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsvy}
{ifin}{cmd:,}
{cmdab:varn:ame(}{it:varname}{cmd:)}
{cmdab:years:(}{it:numlist}{cmd:)}
{cmdab:stat:(}{it:statname}{cmd:)}
[{it:options}]

{pstd}
where {it:statname} is one of {cmd:mean}, {cmd:total}, {cmd:proportion},
or {cmd:ratio}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt varn:ame(varname)}}analysis variable; required. The
numerator, when {cmd:stat(ratio)}{p_end}
{synopt:{opt years(numlist)}}calendar years actually present in {cmd:ANIO_}
in the current data, in ascending order; required{p_end}
{synopt:{opt stat(statname)}}statistic to estimate and test: {cmd:mean},
{cmd:total}, {cmd:proportion}, or {cmd:ratio}; required{p_end}
{synopt:{opt caida(varlist)}}variables defining the levels of aggregation
to loop over; default is {cmd:caida(NACIONAL REGION NOMBREDD_)}{p_end}
{synopt:{opt sexovar(varname)}}an extra crosscutting variable (for
example, sex); if given, every {cmd:caida()} x {it:sexovar} value
combination is estimated and tested separately{p_end}
{synopt:{opt l:evel(#)}}see {helpb svylet}; only matters for
{cmd:stat(proportion)}; default is {cmd:level(1)}{p_end}
{synopt:{opt d:enominator(varname)}}see {helpb svylet}; required with
{cmd:stat(ratio)}, ignored otherwise{p_end}
{synopt:{opt expectcats(numlist)}}categories {it:varname} is expected to
take; {cmd:tsvy} stops before estimating anything if the observed
categories do not match exactly{p_end}

{syntab:svylet passthrough}
{synopt:{opt a:lpha(#)}}see {helpb svylet}; default is {cmd:alpha(0.05)}{p_end}
{synopt:{opt boot(#)}}see {helpb svylet}; default is {cmd:boot(0)}{p_end}
{synopt:{opt bseed(#)}}see {helpb svylet}{p_end}

{syntab:Vs-a-reference (optional)}
{synopt:{opt refyear(#)}}calendar year (one of {cmd:years()}) to use as a
fixed baseline. Adds the {cmd:P_VS_REF}/{cmd:SIG_VS_REF} columns,
comparing EACH year against {cmd:refyear()} (Bonferroni over {it:k}-1
comparisons) -- a DIFFERENT question from {cmd:GRUPO} (all-pairs CLD);
see {help svylet##remarks_ref:Remarks in svylet.sthlp}{p_end}

{syntab:Output}
{synopt:{opt frame(name)}}accumulator frame; default is
{cmd:frame(ACUM_ALL)}{p_end}
{synopt:{opt threshold(#)}}CV(%) above which a row is flagged
{cmd:REF_ = "a/"}; default is {cmd:threshold(15)}{p_end}
{synopt:{opt replace}}drop and recreate the accumulator frame instead of
appending to it{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:varname} must exist in the current data; a variable literally named
{cmd:ANIO_} must also exist (the variable {cmd:tsvy} passes as
{cmd:over()} to every {cmd:svylet} call). The dataset must already be
{helpb svyset}, exactly as for {helpb svylet}.

{pstd}
{bf:Requires Stata 16.0 or later.} {cmd:tsvy} accumulates its output with
{helpb frame}s ({cmd:frame create}, {cmd:frame }{it:name}{cmd::}), a
feature introduced in Stata 16; it does not run on Stata 14 or 15.
{helpb svylet} itself has no frame dependency and runs on Stata 14 or
later.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsvy} builds, in one pass, the table that a researcher working
with repeated cross-sections or panel waves of a complex survey usually
needs: point estimates broken down by level of aggregation (national,
regional, local, ...) and by year, {it:together with} a test of whether
each level's estimate actually changed from year to year. It loops over
every level of aggregation named in {cmd:caida()}, running the same
omnibus-F/Bonferroni/CLD computation as {helpb svylet} once per (level x
value x [{cmd:sexovar} value]) combination, and accumulates one row per
year in a frame that is ready to {cmd:reshape wide} and export -- so the
point-estimate table and the F/Bonferroni/CLD test come from the very
same call, with no separate pass to keep aligned by hand. Whether that
per-block computation is a literal call to the {cmd:svylet} command, or
the same logic run inline, depends on which of {cmd:tsvy}'s two internal
code paths a given call takes -- see
{help tsvy##remarks_limits:Remarks} below.

{pstd}
{cmd:tsvy} is a companion to
{browse "https://github.com/atalaveracuya/tabsvy":tabsvy}/{cmd:tabsvyexport}
(a separate, general-purpose tool by the same author that follows the
same loop-and-accumulate design, but runs {cmd:svy: + parmby} at each
level instead -- point estimates only, no test across years). If you use
{cmd:tabsvy} and also need to know whether years are significantly
different from each other within each level, {cmd:tsvy} is the
same idea with {helpb svylet} as the engine; if you have never used
{cmd:tabsvy}, {cmd:tsvy} stands on its own and needs nothing from
that repository.

{pstd}
{cmd:tsvy} does {it:not} modify or depend on the internal code of
{cmd:tabsvy.ado} -- it lives in the {cmd:svylet} repository because
{helpb svylet} is the engine it needs. If it proves useful, folding it
into {cmd:tabsvy} itself as an alternate engine is a natural next step
(see {cmd:AUDIT.md} in the {cmd:svylet} repository), but that requires
write access to the {cmd:tabsvy} repository that this command does not
assume.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt varname(varname)} is the single analysis variable, exactly as in
{helpb svylet}: not a {it:varlist}. To tabulate several variables, call
{cmd:tsvy} once per variable, into the same {cmd:frame()} (see
{help tsvy##examples:Examples}).

{phang}
{opt years(numlist)} lists the real calendar years present in {cmd:ANIO_}
in the {it:current} data, in ascending chronological order -- not assumed
to run 1..k without gaps. {cmd:tsvy} reads the distinct codes actually
in {cmd:ANIO_} via {helpb levelsof} and maps them, by ascending position,
one-to-one onto {cmd:years()}; it stops with an error if the counts do not
match. This mirrors {cmd:tabsvy}'s own {cmd:years()} logic (from its
v1.3), so a base missing a year entirely (say, no 2020 round for this
variable) is handled by simply listing the years that {it:are} present,
without decoding {cmd:ANIO_}'s value label.

{phang}
{opt stat(statname)} is passed straight through to {helpb svylet}: {cmd:mean},
{cmd:total}, {cmd:proportion}, or {cmd:ratio}.

{phang}
{opt caida(varlist)} lists the variables whose distinct values define the
levels of aggregation to loop over -- for example, a constant
{cmd:NACIONAL} variable (see {help tsvy##remarks:Remarks}), a region
code, a department code. Default is {cmd:caida(NACIONAL REGION NOMBREDD_)},
matching {cmd:tabsvy}'s own default and the convention it documents (a
{cmd:NACIONAL} variable equal to 1 for every observation, standing for
"no breakdown"). Every distinct value of every variable in {cmd:caida()}
gets its own block of rows in the output.

{phang}
{opt sexovar(varname)} adds a second crosscutting variable: instead of one
{helpb svylet} call per {cmd:caida()} value, {cmd:tsvy} calls it once
per ({cmd:caida()} value, {it:sexovar} value) combination, and adds a
{cmd:SEXO} column to the accumulator frame.

{phang}
{opt level(#)}, {opt denominator(varname)}, and {opt alpha(#)} are passed
straight through to {helpb svylet}; see there. {opt denominator()} is
required with {cmd:stat(ratio)}.

{phang}
{opt expectcats(numlist)} declares, up front, which categories
{it:varname} should take (for example, {cmd:expectcats(1 2)} for a
dichotomous indicator). If the categories actually observed in the data do
not match exactly, {cmd:tsvy} stops before estimating anything, the
same fail-fast check {cmd:tabsvy} performs with its own
{cmd:expectcats()}.

{dlgtab:svylet passthrough}

{phang}
{opt boot(#)} and {opt bseed(#)} are passed straight through to every
{helpb svylet} call; see there, including the design requirements for
{cmd:boot()} (a PSU {it:and} a stratum must be declared in the current
{helpb svyset}).

{dlgtab:Output}

{phang}
{opt frame(name)} names the accumulator frame. If it does not already
exist, it is created; existing rows are kept (and new ones appended)
unless {opt replace} is also given.

{phang}
{opt threshold(#)} is the coefficient-of-variation cutoff (in percent)
above which a row's {cmd:REF_} column is set to {cmd:"a/"}, a common flag
for an estimate too imprecise (high sampling variability) to report with
confidence.

{phang}
{opt replace} drops and recreates {cmd:frame()} instead of appending to
whatever it already holds. Use it on the first call of a sequence (see
{help tsvy##examples:Examples}); omit it on subsequent calls that
should accumulate into the same frame.


{marker remarks}{...}
{title:Remarks and examples}

{pstd}
Remarks are presented under the following headings:

{phang2}{help tsvy##remarks_nacional:The NACIONAL convention}{p_end}
{phang2}{help tsvy##remarks_limits:Differences from tabsvy, and current limitations}{p_end}

{marker remarks_nacional}{...}
{pstd}{bf:The NACIONAL convention}

{pstd}
{cmd:tsvy}'s default {cmd:caida()} expects a variable literally named
{cmd:NACIONAL}, constant at 1 for every observation, exactly as
{cmd:tabsvy}'s own README documents ({cmd:gen NACIONAL = 1}). This is what
lets a single {cmd:caida("NACIONAL REGION NOMBREDD_")} loop produce a
"national" block (one value, no real breakdown) alongside genuine
region/department breakdowns, using the same mechanism for both.

{marker remarks_limits}{...}
{pstd}{bf:Differences from tabsvy, and current limitations}

{phang2}o each {helpb svylet} call inside {cmd:tsvy} needs at least 2
years of data to run the test (svylet's own requirement on {cmd:over()});
a {cmd:caida()} x [{cmd:sexovar}] block with only one year of data is
skipped with a warning and contributes no rows. {cmd:tabsvy} does not have
this restriction, because it does not need to compare years against each
other.{p_end}
{phang2}o {cmd:tsvy} does not (yet) have {cmd:tabsvy}'s
{cmd:keepcat()}/{cmd:tipo()} options for looping over a thematic block of
several 0/1 indicator variables at once. If a table needs that pattern,
either keep using {cmd:tabsvy} for it, or call {cmd:tsvy} once per
indicator into the same {cmd:frame()} and tag the block yourself (see
{help tsvy##examples:Examples}).{p_end}
{phang2}o {cmd:tsvy} requires the over() variable passed internally to
{helpb svylet} to be named exactly {cmd:ANIO_}; it is not configurable.{p_end}
{phang2}o (v1.4) when {cmd:boot()} is 0 (the default) and {cmd:sexovar()}
is not given, {cmd:tsvy} runs a single joint
{cmd:svy: STAT ..., over(caida_var ANIO_)} per {cmd:caida()} variable --
the same command you would run by hand to get a reference table -- instead
of filtering to one {cmd:caida()} value at a time and running
{cmd:over(ANIO_)} inside that filter. This matters for a level that pools
several strata of the underlying design (a region made of many
departments, say): on real production data, filtering first gave a
standard error systematically smaller than the one from the joint
{cmd:over()} call, even though the point estimate matched exactly either
way. {cmd:boot()>0} and {cmd:sexovar()} still use the old
filter-then-{cmd:over(ANIO_)} path.{p_end}
{phang2}o only the OLD path (the one just above --
{cmd:boot()>0}/{cmd:sexovar()}) makes a literal call to the
{cmd:svylet} command, once per ({cmd:caida()} value x [{cmd:sexovar}
value]). The default joint-{cmd:over()} path does NOT call
{cmd:svylet} -- it runs {cmd:svy:} directly and computes the omnibus
F-test/Bonferroni/CLD with its own copy of the same Mata engine, so
that {cmd:tsvy.ado} does not depend on {cmd:svylet} having been
invoked directly earlier in the same session for its subroutines to be
loaded (see the v1.4 note at the top of {cmd:tsvy.ado} for why). Both
paths implement the identical math and produce identical results --
this only matters if you are, say, tracing calls with {cmd:trace on}
or otherwise checking specifically whether {cmd:svylet} itself ran.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
The script below (setup + examples 1-5) is confirmed running start to
finish without error in real Stata. The leading {cmd:.} before a
single-line command is the command prompt (standard Stata help
convention, not part of the command, and safe to copy as-is); the lines
inside the {cmd:foreach} block in example 3 are shown without it, because
a {cmd:.} left on every line of a multi-line {cmd:foreach}/{cmd:forvalues}
block -- including the body and the closing brace -- breaks Stata's
parsing of the block when pasted into a do-file. Comment lines (starting
with {cmd:*}) need no prompt either way; they are shown here exactly as
you would keep them in your own do-file.

{pstd}
Every example below is self-contained and runs on {cmd:auto.dta}, one of
Stata's built-in example datasets -- {cmd:sysuse auto} is enough, no
external data needed. As with {helpb svylet}, {cmd:auto.dta} has no real
survey design, so the setup below is the minimal one that lets
{cmd:tsvy} run (each observation as its own PSU); see {helpb svylet}
for why {cmd:_n} is not passed to {cmd:svyset} directly, and for a bootstrap
example with a real multi-row cluster design. {cmd:auto.dta} also has no
year variable, so {cmd:ANIO_} is fabricated purely to exercise the
over-time mechanics -- in real use, {cmd:ANIO_} and the {cmd:NACIONAL}
convention come from the same setup already used before calling
{cmd:tabsvy} (see its README).

{phang2}{cmd:* Setup}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}
{phang2}{cmd:. gen byte NACIONAL = 1}{p_end}
{phang2}{cmd:. gen int ANIO_ = 2021 + mod(_n, 3)}{p_end}

{pstd}
{bf:Example 1: one call, several levels of aggregation.} {cmd:mean} of
{cmd:mpg}, three levels ({cmd:NACIONAL} and both values of {cmd:foreign}),
three years each -- point estimates plus the F/Bonferroni/CLD test across
years, all in one frame, one call:{p_end}
{phang2}{cmd:* Example 1: one call, several levels of aggregation}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    caida(NACIONAL foreign) frame(F1) replace}{p_end}
{phang2}{cmd:. frame F1: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:Example 2: {cmd:proportion}}, with {cmd:expectcats()} guarding the
coding of the analysis variable ({cmd:foreign} must take exactly 0/1, or
{cmd:tsvy} stops before estimating anything):{p_end}
{phang2}{cmd:* Example 2: proportion, with expectcats()}{p_end}
{phang2}{cmd:. tsvy, varname(foreign) stat(proportion) level(1) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) expectcats(0 1) ///}{p_end}
{phang2}{cmd:    caida(NACIONAL) frame(F2) replace}{p_end}
{phang2}{cmd:. frame F2: list NIVEL CAIDA ANIO ESTIMA CV REF_ F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Example 3: {cmd:total}}, several variables accumulated into the same
frame ({cmd:replace} only on the first call -- this is the pattern for
looping {cmd:tsvy} over many analysis variables, the way a real
pipeline loops it over many indicators). Note the {cmd:foreach} block
below has no leading {cmd:.} on any of its lines -- see the note at the
top of this section for why:{p_end}
{phang2}{cmd:* Example 3: total, several variables into the same frame}{p_end}
{phang2}{cmd:local variables mpg weight length}{p_end}
{phang2}{cmd:local i = 0}{p_end}
{phang2}{cmd:foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy, varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        caida(NACIONAL) frame(F3) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}
{phang2}{cmd:frame F3: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Example 4: a second crosscutting dimension} with {cmd:sexovar()} --
here, a price-based split stands in for a real demographic split like
sex:{p_end}
{phang2}{cmd:* Example 4: a second crosscutting dimension with sexovar()}{p_end}
{phang2}{cmd:. gen byte grupo_precio = (price > 6000)}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    caida(NACIONAL) sexovar(grupo_precio) frame(F4) replace}{p_end}
{phang2}{cmd:. frame F4: list NIVEL CAIDA SEXO ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA SEXO)}{p_end}

{pstd}
{bf:Example 5: {cmd:ratio}} -- {opt denominator()} is required, and is a
separate option from {opt varname()} (the numerator), not a
{cmd:num/den} expression:{p_end}
{phang2}{cmd:* Example 5: ratio -- denominator() is a separate option}{p_end}
{phang2}{cmd:. tsvy, varname(trunk) stat(ratio) denominator(length) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) caida(NACIONAL foreign) frame(F5) replace}{p_end}
{phang2}{cmd:. frame F5: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:Example 6: restricting the universe with {cmd:[if]}.} {cmd:tsvy}
takes a leading {cmd:if} exactly like {cmd:svy:} does, and passes it
through to every {helpb svylet} call the loop makes internally -- it is
not limited to the {cmd:caida()}/{cmd:sexovar()} split. Use it whenever
the estimation should run over a subpopulation rather than the whole
dataset (for example, only the records that pass an eligibility or
quality-control condition upstream). Below, {cmd:rep78} is missing for 5
cars in {cmd:auto.dta}; restricting to {cmd:rep78 < .} drops them from
the universe before estimating, the same way a real pipeline restricts to
records that pass its own filter before calling {cmd:svy: total}:{p_end}
{phang2}{cmd:* Example 6: restricting the universe with [if]}{p_end}
{phang2}{cmd:. tsvy if rep78 < ., varname(weight) stat(total) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) caida(NACIONAL foreign) frame(F6) replace}{p_end}
{phang2}{cmd:. frame F6: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:This {cmd:if} matters in every call of a loop, not just the first
one.} If your pipeline estimates several indicators, each one under its
own eligibility condition, put that condition on every {cmd:tsvy}
call inside the loop -- {cmd:replace} still belongs only on the first
call, but the {cmd:if} belongs on all of them:{p_end}
{phang2}{cmd:. foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy if elegible == 1 & control_calidad == 0, ///}{p_end}
{phang2}{cmd:        varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        caida(NACIONAL) frame(F7) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}

{pstd}
The same pattern scales directly to a real complex-survey pipeline: keep
the {cmd:forvalues}/{cmd:foreach} loop from example 3, replace
{cmd:mpg weight length} with your own list of indicator variables, add
the {cmd:if} condition your data actually needs (as in example 6), and
replace {cmd:caida(NACIONAL foreign)} with whatever aggregation-level
variables your data actually has (a national total plus however many
region/department-type variables apply).{p_end}

{pstd}
{bf:Example 7: {cmd:refyear()} -- comparing every year against ONE base
year.} {cmd:GRUPO} (used in every example above) answers "which years
differ from EACH OTHER" -- all pairs, Bonferroni over {it:k}(k-1)/2
comparisons. {cmd:refyear()} answers a narrower, DIFFERENT question --
"which years differ from THIS ONE base year" -- only {it:k}-1
comparisons, Bonferroni over {it:k}-1 (Dunn 1961) -- and adds
{cmd:P_VS_REF}/{cmd:SIG_VS_REF} to the frame alongside (not instead of)
{cmd:GRUPO}. The two can legitimately disagree on the same data because
they test different families of hypotheses; see
{help svylet##remarks_ref:Remarks in svylet.sthlp} for why, and for the
worked comparison that motivated adding {cmd:refyear()} in the first
place. Below, 2023 is the base year -- every other year gets a
{cmd:P_VS_REF} p-value against it, and 2023's own row stays missing (a
year is not tested against itself):{p_end}
{phang2}{cmd:* Example 7: refyear() -- vs a base year, not all pairs}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    caida(NACIONAL foreign) refyear(2023) frame(F8) replace}{p_end}
{phang2}{cmd:. frame F8: list NIVEL CAIDA ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:Example 8: {cmd:refyear()} together with {cmd:sexovar()}.}
{cmd:refyear()} is passed straight through to every {helpb svylet} call
the loop makes, so it works the same way whether {cmd:tsvy} takes the
single joint {cmd:over()} path (example 7 above) or the
filter-then-{cmd:over(ANIO_)} path that {cmd:sexovar()} and {cmd:boot()}
still use (see {help tsvy##remarks_limits:Remarks}) -- each
({cmd:caida()}, {it:sexovar}) block gets its own {cmd:refyear()}
baseline check and its own {cmd:P_VS_REF} column, exactly as if you had
called {cmd:svylet ..., ref()} by hand inside each block:{p_end}
{phang2}{cmd:* Example 8: refyear() + sexovar() together}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    caida(NACIONAL) sexovar(grupo_precio) refyear(2023) frame(F9) replace}{p_end}
{phang2}{cmd:. frame F9: list NIVEL CAIDA SEXO ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CAIDA SEXO)}{p_end}


{marker frame}{...}
{title:Frame layout}

{pstd}
{cmd:tsvy} leaves the following variables in {cmd:frame()}, one row
per (level of {cmd:caida()}, value, [{it:sexovar} value], year):

{synoptset 16 tabbed}{...}
{synopt:{cmd:NIVEL}}the {cmd:caida()} variable name for this row (with any
trailing {cmd:_} stripped, matching {cmd:tabsvy}'s convention -- e.g.
{cmd:NOMBREDD_} becomes {cmd:NOMBREDD}){p_end}
{synopt:{cmd:CAIDA}}the value of that variable{p_end}
{synopt:{cmd:SEXO}}value of {cmd:sexovar()}, if given{p_end}
{synopt:{cmd:var}}fixed at 1 (kept only for column-layout compatibility
with {cmd:tabsvy}'s own frame, where it identifies a category of a
categorical variable){p_end}
{synopt:{cmd:ANIO}}calendar year (mapped from {cmd:years()}){p_end}
{synopt:{cmd:ESTIMA}}point estimate{p_end}
{synopt:{cmd:ERROR_ST}}standard error{p_end}
{synopt:{cmd:CV}}coefficient of variation, percent{p_end}
{synopt:{cmd:LIM_INF LIM_SUP}}confidence limits{p_end}
{synopt:{cmd:N_SIN_PON N_PONDERA}}unweighted / weighted sample size{p_end}
{synopt:{cmd:REF_}}{cmd:"a/"} if {cmd:CV} exceeds {cmd:threshold()}{p_end}
{synopt:{cmd:F_WALD P_WALD}}omnibus Wald F-statistic and its analytic
p-value -- {it:constant across all years within the same block}, since the
test compares all years in that block at once{p_end}
{synopt:{cmd:GRUPO}}the Compact Letter Display code for {it:this row's}
year within its block -- varies by year{p_end}
{synopt:{cmd:P_VS_REF}}Bonferroni-adjusted ({it:k}-1 comparisons) p-value
of {it:this row's} year against {cmd:refyear()}; missing if
{cmd:refyear()} was not specified, and always missing on
{cmd:refyear()}'s own row -- a DIFFERENT comparison family from
{cmd:GRUPO}, see {help svylet##remarks_ref:Remarks in svylet.sthlp}{p_end}
{synopt:{cmd:SIG_VS_REF}}significance stars for {cmd:P_VS_REF}:
{cmd:"*"} p<0.10, {cmd:"**"} p<0.05, {cmd:"***"} p<0.01{p_end}
{p2colreset}{...}

{pstd}
Because {cmd:F_WALD}/{cmd:P_WALD} are constant within a block and
{cmd:GRUPO} varies by year, a subsequent {cmd:reshape wide} should list
{cmd:GRUPO} among the variables being reshaped (so it becomes
{cmd:GRUPO2023}, {cmd:GRUPO2024}, ...) but leave {cmd:F_WALD}/{cmd:P_WALD}
in {cmd:i()} instead, so they are carried along once per block rather than
needlessly repeated per year:

{phang2}{cmd:. reshape wide ESTIMA REF_ ERROR_ST LIM_INF LIM_SUP CV N_PONDERA N_SIN_PON GRUPO,}{p_end}
{phang2}{cmd:        i(NIVEL CAIDA var F_WALD P_WALD) j(ANIO)}{p_end}

{pstd}
This schema is otherwise compatible with the point-estimate half of
{cmd:tabsvyexport} ({cmd:ESTIMA}/{cmd:REF_} by year), since
{cmd:tabsvyexport} already discards every column it does not need before
its own reshape.


{marker references}{...}
{title:References}

{pstd}
See {helpb svylet} for the statistical references behind the F-test,
Bonferroni comparisons, and {cmd:boot()}. {cmd:refyear()}'s {it:k}-1
vs-baseline contrasts use the same Bonferroni correction as {cmd:GRUPO},
applied to a smaller, DIFFERENT family of comparisons (Dunn, O.J. 1961.
Multiple comparisons among means. {it:Journal of the American
Statistical Association} 56(293): 52-64).


{marker author}{...}
{title:Author}

{pstd}
Andres Talavera Cuya. Affiliation stated for identification purposes
only -- this software is not an official product of INEI and INEI bears
no responsibility for it. Distributed under the GNU General Public License
v3 (https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
Source, installation instructions, and the estimation engine
{helpb svylet}: {browse "https://github.com/atalaveracuya/svylet"}. This
is not (yet) an SSC package; download {cmd:tsvy.ado} and this help
file into a directory on your {stata "adopath"} (or clone the repository
and add it with {cmd:adopath ++ <path>}). Also requires
{stata "ssc install frameappend":frameappend} (SSC).

{pstd}
Suggested citation: Talavera Cuya, A. 2026. tsvy: Stata module to
build point-estimate tables with a year-over-year significance test
across levels of aggregation, for complex survey data. Available from
{browse "https://github.com/atalaveracuya/svylet"}.


{marker also_see}{...}
{title:Also see}

{psee}
Online: {helpb svylet}, {helpb svy}
{p_end}

{psee}
En espanol: {helpb tsvy_es}
{p_end}
