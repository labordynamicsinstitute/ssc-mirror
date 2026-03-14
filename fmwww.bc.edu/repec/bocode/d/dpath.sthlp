{smcl}
{* dpath help file  Subir Hait, Michigan State University, 2026}{...}
{hline}
help for {hi:dpath}
{hline}

{title:Title}

{p 4 4 2}
{bf:dpath} — construct and audit longitudinal decision paths

{title:Syntax}

{p 4 8 2}
{cmd:dpath build} {varname} [{it:if}] [{it:in}] ,
    {opt id(idvar)} {opt time(timevar)}
    [{opt group(groupvar)} {opt outcome(outcomevar)}]

{p 4 8 2}
{cmd:dpath describe} ,
    {opt id(idvar)} {opt time(timevar)}
    [{opt by(groupvar)}]

{p 4 8 2}
{cmd:dpath dri} ,
    {opt id(idvar)} {opt time(timevar)}
    [{opt by(groupvar)}]

{p 4 8 2}
{cmd:dpath entropy} ,
    {opt id(idvar)} {opt time(timevar)}
    [{opt by(groupvar)} {opt mutualinfo}]

{p 4 8 2}
{cmd:dpath equity} ,
    {opt id(idvar)} {opt time(timevar)} {opt by(groupvar)}
    [{opt ref(reflevel)}]

{p 4 8 2}
{cmd:dpath audit} {varname} [{it:if}] [{it:in}] ,
    {opt id(idvar)} {opt time(timevar)}
    [{opt by(groupvar)} {opt ref(reflevel)} {opt outcome(outcomevar)}]


{title:Description}

{p 4 4 2}
{cmd:dpath} is a Stata package for constructing and auditing longitudinal
decision paths from panel data. It implements the Decision Infrastructure
Paradigm (Hait, 2026), which conceptualizes institutional AI systems 
as infrastructure generating time-ordered binary decision 
sequences — the decision path — as the primary empirical object.

{p 4 4 2}
The typical workflow is:

{p 8 8 2}
1. {cmd:dpath build} — compute decision-path variables from the panel dataset.{break}
2. {cmd:dpath describe} — summarise path descriptors per unit.{break}
3. {cmd:dpath dri} — compute the Decision Reliability Index.{break}
4. {cmd:dpath entropy} — compute Shannon path entropy.{break}
5. {cmd:dpath equity} — run equity diagnostics by group.{break}
   Or use {cmd:dpath audit} to run all five steps in sequence.


{title:Subcommands}

{dlgtab:dpath build}

{p 4 4 2}
Converts a long-format panel dataset into decision-path variables.
The decision variable must be binary (0/1). After running {cmd:dpath build},
the following new variables are added to the dataset:

{p 8 8 2}
{bf:_dp_path_str}   — decision path string, e.g. "0-1-1-0"{break}
{bf:_dp_dosage}     — proportion of waves with decision = 1{break}
{bf:_dp_switch}     — switching rate (proportion of changes){break}
{bf:_dp_onset}      — first wave with decision = 1{break}
{bf:_dp_duration}   — count of waves with decision = 1{break}
{bf:_dp_longest}    — longest consecutive run of decision = 1{break}
{bf:_dp_n_periods}  — number of observed waves per unit{break}
{bf:_dp_treat_count}— total count of treated waves

{dlgtab:dpath describe}

{p 4 4 2}
Displays summary statistics for all path descriptors at the unit level,
optionally stratified by a group variable. Requires {cmd:dpath build} to
have been run first.

{dlgtab:dpath dri}

{p 4 4 2}
Computes the Decision Reliability Index:

{p 8 8 2}
{bf:DRI = 1 - mean(switching_rate)}

{p 4 4 2}
DRI = 1.0 indicates perfectly consistent decisions (Type I infrastructure).
DRI = 0.0 indicates maximum instability (highly adaptive or human-overridden).

{p 4 4 2}
Interpretation thresholds (adapted from Nunnally, 1978):

{p 8 8 2}
DRI ≥ 0.90: High reliability (suggests Type I infrastructure){break}
DRI 0.70–0.89: Acceptable (Type II){break}
DRI 0.50–0.69: Questionable (Type III){break}
DRI < 0.50: Poor reliability (Type IV)

{dlgtab:dpath entropy}

{p 4 4 2}
Computes Shannon entropy H of the decision-path distribution:

{p 8 8 2}
{bf:H = −Σ p(ω) × log₂ p(ω)}  [bits]

{p 4 4 2}
where p(ω) is the proportion of units following path ω. The normalised
entropy H* = H / log₂(K) rescales to [0, 1] across systems with different
numbers of unique paths K.

{p 4 4 2}
The {opt mutualinfo} option additionally computes mutual information
I(path; group), which partitions total entropy into within-group and
between-group components.

{dlgtab:dpath equity}

{p 4 4 2}
Produces equity diagnostics via standardised mean differences (SMDs) across
path descriptors (dosage, switching rate, onset, duration, DRI) between
group levels and a reference group.

{p 4 4 2}
Interpretation of |SMD|:{break}
  < 0.10 : negligible — equity achieved{break}
  0.10–0.20 : small disparity{break}
  > 0.20 : meaningful inequity

{dlgtab:dpath audit}

{p 4 4 2}
Runs all five steps in sequence: build, describe, dri, entropy, equity.
Produces a full audit report and suggests an infrastructure type based on
DRI and normalised entropy.


{title:Options}

{p 4 8 2}
{opt id(idvar)} — unit identifier variable (required).

{p 4 8 2}
{opt time(timevar)} — time/wave variable (required).

{p 4 8 2}
{opt group(groupvar)} / {opt by(groupvar)} — grouping variable for
stratified analysis and equity diagnostics.

{p 4 8 2}
{opt outcome(outcomevar)} — outcome variable (stored for reference;
not used in path computations).

{p 4 8 2}
{opt ref(reflevel)} — reference category for equity SMD comparisons.
Defaults to the first level of the group variable.

{p 4 8 2}
{opt mutualinfo} — (entropy only) compute mutual information I(path; group).


{title:Examples}

{p 4 8 2}
* ── Minimal example ─────────────────────────────────────────────────────{p_end}
{p 4 8 2}
{cmd:. use panel_data.dta, clear}{p_end}
{p 4 8 2}
{cmd:. xtset studentid wave}{p_end}

{p 4 8 2}
* Step 1: Build decision-path variables{p_end}
{p 4 8 2}
{cmd:. dpath build ai_flag, id(studentid) time(wave) group(sesq)}{p_end}

{p 4 8 2}
* Step 2: Path descriptors{p_end}
{p 4 8 2}
{cmd:. dpath describe, id(studentid) time(wave) by(sesq)}{p_end}

{p 4 8 2}
* Step 3: Decision Reliability Index{p_end}
{p 4 8 2}
{cmd:. dpath dri, id(studentid) time(wave) by(sesq)}{p_end}

{p 4 8 2}
* Step 4: Shannon entropy{p_end}
{p 4 8 2}
{cmd:. dpath entropy, id(studentid) time(wave) by(sesq)}{p_end}

{p 4 8 2}
* Step 5: Equity diagnostics{p_end}
{p 4 8 2}
{cmd:. dpath equity, id(studentid) time(wave) by(sesq) ref(Q1)}{p_end}

{p 4 8 2}
* ── Full audit (all five steps) ─────────────────────────────────────────{p_end}
{p 4 8 2}
{cmd:. dpath audit ai_flag, id(studentid) time(wave) by(sesq) ref(Q1)}{p_end}

{p 4 8 2}
* ── Access stored results ───────────────────────────────────────────────{p_end}
{p 4 8 2}
{cmd:. dpath audit ai_flag, id(studentid) time(wave)}{p_end}
{p 4 8 2}
{cmd:. display r(DRI)}{p_end}
{p 4 8 2}
{cmd:. display r(entropy)}{p_end}


{title:Returned results}

{p 4 4 2}
{cmd:dpath audit} (and individual subcommands) store results in {cmd:r()}:

{p 8 8 2}
{bf:r(n_units)}            — number of units{break}
{bf:r(n_waves)}            — maximum number of waves{break}
{bf:r(balanced)}           — 1 if balanced panel{break}
{bf:r(mean_dosage)}        — mean dosage{break}
{bf:r(mean_switch)}        — mean switching rate{break}
{bf:r(DRI)}                — Decision Reliability Index{break}
{bf:r(entropy)}            — Shannon entropy H (bits){break}
{bf:r(normalized_entropy)} — normalised entropy H*{break}
{bf:r(n_unique_paths)}     — number of unique paths{break}
{bf:r(mutual_info)}        — mutual information (if requested)


{title:Infrastructure Typology}

{p 4 4 2}
The Decision Infrastructure Paradigm (Hait, 2026) defines four types:

{p 8 8 2}
{bf:Type I — Static}:          DRI ≈ 1.0, low entropy.
Decision rule fixed; paths rarely change.{break}
{bf:Type II — Periodic}:       DRI 0.70–0.95, medium entropy.
Recalibrated at fixed intervals.{break}
{bf:Type III — Continuous}:    DRI 0.40–0.70, high entropy.
Updates at every wave; fully adaptive.{break}
{bf:Type IV — Human-in-Loop}: DRI < 0.50, high entropy.
Algorithmic recommendations + human overrides.


{title:References}

{p 4 8 2}
Cronbach, L. J. (1951). Coefficient alpha and the internal structure of
tests. {it:Psychometrika}, 16(3), 297–334.

{p 4 8 2}
Hait, S. (2026). Artificial intelligence as decision infrastructure:
Rethinking institutional decision processes. Michigan State University.
https://github.com/causalfragility-lab/decisionpaths

{p 4 8 2}
Nunnally, J. C. (1978). {it:Psychometric theory} (2nd ed.). McGraw-Hill.

{p 4 8 2}
Shannon, C. E. (1948). A mathematical theory of communication.
{it:Bell System Technical Journal}, 27(3), 379–423.


{title:Author}

{p 4 4 2}
Subir Hait{break}
Michigan State University{break}
haitsubi@msu.edu{break}
ORCID: 0009-0004-9871-9677{break}
https://github.com/causalfragility-lab/dpath

{p 4 4 2}
Companion R package: {browse "https://github.com/causalfragility-lab/decisionpaths":decisionpaths}


{title:Also see}

{p 4 4 2}
{help xtset}, {help xtsum}, {help xtdes}

{hline}
