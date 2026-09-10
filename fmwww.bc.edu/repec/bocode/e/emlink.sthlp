{smcl}
{* *! version 1.0.15  28aug2026}{...}
{vieweralsosee "[D] merge" "help merge"}{...}
{viewerjumpto "Syntax" "emlink##syntax"}{...}
{viewerjumpto "Data preparation" "emlink##prep"}{...}
{viewerjumpto "Description" "emlink##description"}{...}
{viewerjumpto "Options" "emlink##options"}{...}
{viewerjumpto "Remarks" "emlink##remarks"}{...}
{viewerjumpto "Examples" "emlink##examples"}{...}
{viewerjumpto "Stored results" "emlink##results"}{...}
{viewerjumpto "References" "emlink##refs"}{...}

{title:Title}

{phang}
{bf:emlink} {hline 2} Probabilistic record linkage (Fellegi-Sunter) with
unsupervised EM estimation


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:emlink} {cmd:using} {it:filename}{cmd:,}
{opth idm:aster(varname)}
{opt idu:sing(name)}
{opt str:vars(fieldlist)}
{opt clear}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth idm:aster(varname)}}record identifier in the master data{p_end}
{synopt:{opt idu:sing(name)}}record identifier in the using file{p_end}
{synopt:{opt str:vars(fieldlist)}}comparison fields as
{it:master}{cmd:=}{it:using} pairs{p_end}
{synopt:{opt ub:igeo(field)}}add one more comparison field (e.g. a geographic code){p_end}

{syntab:Blocking}
{synopt:{opt bl:ock(varlist)}}blocking key(s) in the master data; only records
sharing a key are compared{p_end}
{synopt:{opt blocku:sing(namelist)}}names of the same keys in the using file, if
they differ{p_end}

{syntab:Estimation}
{synopt:{opt seeda:gree(#)}}fields that must agree to enter the
deterministic seed; default {cmd:seedagree(2)}{p_end}
{synopt:{opt tol:erance(#)}}EM convergence tolerance; default {cmd:1e-10}{p_end}
{synopt:{opt max:iter(#)}}maximum EM iterations; default {cmd:3000}{p_end}
{synopt:{opt swapn:ames}}also test the cross alignment of the two surname
fields{p_end}

{syntab:Classification}
{synopt:{opt t:hreshold(#)}}posterior cutoff for automatic links; if
omitted, calibrated from the data{p_end}
{synopt:{opt cler:ical(#)}}lower cutoff for the clerical-review zone{p_end}
{synopt:{opt gen:prefix(name)}}prefix for generated variables; default
{cmd:_ml}{p_end}
{synopt:{opt nowarn:ings}}suppress the few-fields warning{p_end}
{synopt:{opt clear}}required: the data in memory are replaced by the pair-level
results{p_end}
{synoptline}


{marker prep}{...}
{title:Data preparation {hline 2} read this first}

{pstd}
{bf:emlink assumes the comparison variables have already been normalized.}
The command does not clean strings for you. Accents, mixed case, digits and
stray punctuation create {it:artificial disagreements} that the EM reads as
evidence against a match, so normalization must happen first {bf:and must use
identical rules in both files}. A file that keeps accents linked against one
that strips them will link badly no matter how the model is specified.

{pstd}
A reasonable normalization for Latin American name data:

{p 8 12 2}{cmd:. foreach v of varlist nombre ape_paterno ape_materno {c -(}}{p_end}
{p 12 16 2}{cmd:. replace `v' = upper(`v')}{p_end}
{p 12 16 2}{cmd:. replace `v' = ustrto(ustrnormalize(`v',"nfd"), "ascii", 2)}{p_end}
{p 12 16 2}{cmd:. replace `v' = ustrregexra(`v', "[^A-Z ]", " ")}{p_end}
{p 12 16 2}{cmd:. replace `v' = strtrim(stritrim(`v'))}{p_end}
{p 8 12 2}{cmd:. {c )-}}{p_end}

{pstd}
Effect:

        {c TLC}{hline 30}{c -}{c TRC}
        {c |} {bf:Original}            {bf:Normalized}      {c |}
        {c |} Juan Perez-Lopez 12       JUAN PEREZ LOPEZ  {c |}
        {c |} Ma ROSA QUISPE            MA ROSA QUISPE    {c |}
        {c |} peña  flores              PENA FLORES       {c |}
        {c BLC}{hline 30}{c -}{c BRC}

{pstd}
Note that the ASCII step folds accented characters to their base letters,
including {bf:Ñ} to {bf:N}. This is intentional: it lets PEÑA in one file
match PENA in the other when only one source preserves the tilde, which is
the common case in administrative data. Apply the {it:same} rules to both
files so that any residual differences reflect genuine variation, not
inconsistent preprocessing.

{pstd}
{bf:Numeric fields} such as ubigeo must keep their digits. Pass them through
{opt ubigeo()} and normalize them separately -- the name-cleaning code above
would erase them entirely.


{marker description}{...}
{title:Description}

{pstd}
{cmd:emlink} links two files that share no reliable common identifier. It
implements the Fellegi-Sunter (1969) model: each candidate pair is compared
field by field on a three-level agreement scale (disagree / partial / agree),
and the weights attached to each agreement pattern are estimated by
unsupervised EM -- no labelled training pairs are required.

{pstd}
Each pair receives a posterior probability of being a match and is classified
as a link, a clerical-review case, or a non-link.

{pstd}
The EM iterates over {it:unique agreement patterns} rather than over
individual pairs. The number of distinct patterns is bounded by the number of
levels raised to the number of fields, not by the number of pairs, so the
estimation cost is essentially independent of file size once the patterns are
tabulated.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth idmaster(varname)}, {opt idusing(name)} identify records in each file so
that links can be traced back.

{phang}
{opt strvars(fieldlist)} lists the fuzzy comparison fields as
{it:master}{cmd:=}{it:using} pairs, for example
{cmd:strvars(nombre=nombre ape_paterno=ape_pat)}. If both files use the same
name, {cmd:strvars(nombre)} suffices.

{phang}
{opt ubigeo(field)} adds one further comparison field, intended for a highly
discriminating code such as a geographic identifier. The field is compared on
the same three-level agreement scale as the string fields, so near-matching
codes still contribute partial agreement; adding such a field sharply improves
identifiability and is strongly recommended (see {it:Remarks}).

{dlgtab:Blocking}

{phang}
{opt clear} is {bf:required}: {cmd:emlink} replaces the data in memory with one
observation per candidate pair, so save the master data first.

{phang}
{opt block(varlist)}, {opt blockusing(namelist)} restrict comparisons to records sharing a blocking key.
Without blocking the command forms all {it:nA}*{it:nB} pairs, which is
infeasible beyond modest file sizes. Blocking trades recall for tractability:
true matches that disagree on the key are never compared. Using two keys
(for example, prefixes of each surname) recovers most of that loss.

{dlgtab:Estimation}

{phang}
{opt seedagree(#)} sets how many fields must agree for a pair to enter the
deterministic seed used to initialize the EM. The default of 2 works well.
Raising it makes the seed purer but smaller.

{phang}
{opt swapnames} additionally evaluates the cross alignment of the two surname
fields and keeps whichever alignment agrees better. Use it when the files may
store paternal and maternal surnames in opposite order.

{dlgtab:Classification}

{phang}
{opt threshold(#)} sets the posterior cutoff for automatic links. If omitted,
{cmd:emlink} calibrates a cutoff from the estimated model. {bf:Do not assume a
conventional value such as 0.90 is attainable}: when the share of true matches
among candidate pairs is small, no pair reaches such a posterior even under
the true parameters. Inspect {cmd:{it:prefix}_weight} (the log2 match weight)
alongside the posterior when choosing a cutoff by hand.

{phang}
{opt clerical(#)} sets the lower bound of the clerical-review zone. Pairs
between {opt clerical()} and {opt threshold()} are flagged for manual review
rather than resolved automatically.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:How many fields do you need?}

{pstd}
This matters more than any tuning option. In a grid of 81 simulated scenarios,
mean F1 was about {bf:0.94 with four fields} and {bf:0.90 with three}, but fell
to about {bf:0.19 with two}, where recall collapses to roughly 0.11 because
homonyms cannot be separated. Precision stayed near 0.99 with three or four
fields even under high error and 30% missingness, so the binding constraint is
recall, bought with additional discriminating fields rather than with tuning.

{pstd}
{bf:Linking on one field.} {cmd:emlink} will run, relying on the multiple
agreement levels for signal, but homonyms are then {it:irresolvable by
construction}: several distinct people sharing a common name produce identical
agreement patterns and identical posteriors. They will populate the clerical
zone, and no threshold separates them. In populations where surnames such as
QUISPE, MAMANI or FLORES are frequent this is the dominant failure mode. Treat
single-field output as a deduplication aid, not as identity resolution.

{pstd}
{bf:What the clerical zone is for.} Pairs landing there are not failures of the
model; they are cases where the available fields genuinely do not decide. A
pair such as JUANA vs JUAN with identical surnames and ubigeo cannot be
resolved without a further field (birth date, document number). Reviewing that
zone by hand -- and, over time, using the reviewed cases as labelled data --
is part of the intended workflow.

{pstd}
{bf:Interpreting m and u.} The returned matrices give, per field, the
probability of each agreement level among matches ({cmd:m}) and among
non-matches ({cmd:u}). Agreement on a field with a low u-probability is strong
evidence; agreement on a frequent surname is weak. The EM learns this from the
data -- it does not need to be supplied.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Step 1.} Give each file a unique row identifier {bf:before} linking. This
identifier is what {cmd:emlink} returns, and it is what you merge on afterwards
to bring the names back, so it must be unique per row in each file:{p_end}

{phang2}{cmd:. use base_a, clear}{p_end}
{phang2}{cmd:. gen long id_a = _n}{p_end}
{phang2}{cmd:. save base_a, replace}{p_end}

{phang2}{cmd:. use base_b, clear}{p_end}
{phang2}{cmd:. gen long id_b = _n}{p_end}
{phang2}{cmd:. save base_b, replace}{p_end}

{pstd}
{bf:Step 2.} Normalize the comparison variables in both files (see
{it:Data preparation}), then run the link:{p_end}

{phang2}{cmd:. use base_a, clear}{p_end}
{phang2}{cmd:. emlink using base_b,}{break}
        {cmd:      idmaster(id_a) idusing(id_b)}{break}
        {cmd:      strvars(ape_pat=ape_pat ape_mat=ape_mat nombres=nombres anio=anio)}{break}
        {cmd:      block(blk) swapnames clear}{p_end}

{pstd}
{bf:Step 3.} Keep one link per master record and review the undecided cases:{p_end}

{phang2}{cmd:. keep if _ml_status==2 & _ml_best==1}{p_end}

{pstd}
{bf:Step 4 (important).} The results in memory hold only the identifiers and the
scores, {bf:not} the names. To produce a final table showing the names of both
files side by side, merge them back on the identifiers:{p_end}

{phang2}{cmd:. rename _ml_idmaster id_a}{p_end}
{phang2}{cmd:. merge m:1 id_a using base_a,}{break}
        {cmd:      keepusing(ape_pat ape_mat nombres anio) keep(match) nogen}{p_end}
{phang2}{cmd:. rename ape_pat a_apat}{p_end}
{phang2}{cmd:. rename ape_mat a_amat}{p_end}
{phang2}{cmd:. rename nombres a_nom}{p_end}

{phang2}{cmd:. rename _ml_idusing id_b}{p_end}
{phang2}{cmd:. merge m:1 id_b using base_b,}{break}
        {cmd:      keepusing(ape_pat ape_mat nombres anio) keep(match) nogen}{p_end}
{phang2}{cmd:. rename ape_pat b_apat}{p_end}
{phang2}{cmd:. rename ape_mat b_amat}{p_end}
{phang2}{cmd:. rename nombres b_nom}{p_end}

{phang2}{cmd:. sort _ml_post}{p_end}
{phang2}{cmd:. list a_apat a_amat a_nom b_apat b_amat b_nom _ml_post, noobs}{p_end}
{phang2}{cmd:. save enlaces_final, replace}{p_end}

{pstd}
Sorting by {cmd:_ml_post} puts the least certain links first: those are the ones
worth inspecting by eye, since they are usually correct links that survived a
spelling error. The highest-posterior links have identical fields in both files.


{title:Variables created}

{pstd}
The data in memory are replaced by one observation per candidate pair:

{synoptset 26 tabbed}{...}
{synopt:{it:prefix}{cmd:_idmaster}}master record identifier{p_end}
{synopt:{it:prefix}{cmd:_idusing}}using record identifier{p_end}
{synopt:{it:prefix}{cmd:_post}}posterior probability of a match{p_end}
{synopt:{it:prefix}{cmd:_weight}}Fellegi-Sunter match weight (log2 scale){p_end}
{synopt:{it:prefix}{cmd:_status}}0 non-link, 1 clerical, 2 link (labelled){p_end}
{synopt:{it:prefix}{cmd:_best}}1 if this is the highest-posterior pair for that
master record{p_end}

{pstd}
The comparison fields themselves are {bf:not} carried into the results, because
with millions of candidate pairs that would be prohibitively large. To see the
underlying names, merge them back on the identifiers, as shown in {it:Examples}
above. Always create a unique row id in each file ({cmd:gen long id = _n}) before
linking, so that this merge is one-to-one.

{pstd}
{bf:One-to-one linking.} Fellegi-Sunter scores each pair independently, so one
master record may exceed the cutoff against several using records. Use
{it:prefix}{cmd:_best} to keep a single link per master record:

{phang2}{cmd:. keep if _ml_status==2 & _ml_best==1}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:emlink} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N_master)}}records in master{p_end}
{synopt:{cmd:r(N_using)}}records in using file{p_end}
{synopt:{cmd:r(N_fields)}}number of comparison fields{p_end}
{synopt:{cmd:r(N_pairs)}}candidate pairs after blocking{p_end}
{synopt:{cmd:r(N_patterns)}}distinct agreement patterns{p_end}
{synopt:{cmd:r(N_links)}}pairs classified as links{p_end}
{synopt:{cmd:r(N_clerical)}}pairs in the clerical zone{p_end}
{synopt:{cmd:r(N_seed)}}seed pairs used to initialize the EM{p_end}
{synopt:{cmd:r(p_match)}}estimated share of matches among candidate pairs{p_end}
{synopt:{cmd:r(threshold)}}posterior cutoff used{p_end}
{synopt:{cmd:r(iterations)}}EM iterations to convergence{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(m_probs)}}agreement-level probabilities among matches{p_end}
{synopt:{cmd:r(u_probs)}}agreement-level probabilities among non-matches{p_end}


{marker refs}{...}
{title:References}

{phang}
Fellegi, I. P., and A. B. Sunter. 1969. A theory for record linkage.
{it:Journal of the American Statistical Association} 64: 1183-1210.

{phang}
Winkler, W. E. 2006. Overview of record linkage and current research
directions. Research Report Series, US Census Bureau.

{phang}
Enamorado, T., B. Fifield, and K. Imai. 2019. Using a probabilistic model to
assist merging of large-scale administrative records.
{it:American Political Science Review} 113: 353-371.


{title:Author}

{pstd}Mario Anderson Apaza Ñaupa{break}
rioma310@gmail.com{p_end}
