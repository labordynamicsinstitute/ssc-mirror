{smcl}
{* *! version 1.1  20apr2026}{...}
{vieweralsosee "naics_to_ff" "help naics_to_ff"}{...}
{vieweralsosee "sic_to_ff" "help sic_to_ff"}{...}
{viewerjumpto "Syntax" "isic_to_ff##syntax"}{...}
{viewerjumpto "Description" "isic_to_ff##description"}{...}
{viewerjumpto "Options" "isic_to_ff##options"}{...}
{viewerjumpto "Stored results" "isic_to_ff##results"}{...}
{viewerjumpto "Remarks" "isic_to_ff##remarks"}{...}
{viewerjumpto "Examples" "isic_to_ff##examples"}{...}
{viewerjumpto "References" "isic_to_ff##references"}{...}
{viewerjumpto "Author" "isic_to_ff##author"}{...}

{title:Title}

{phang}
{bf:isic_to_ff} {hline 2} Convert ISIC codes to Fama-French industry classifications


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:isic_to_ff}
{varname}
{ifin}
{cmd:,} {opth gen:erate(newvar)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth gen:erate(newvar)}}name of new variable to create{p_end}

{syntab:Optional}
{synopt:{opt sch:eme(#)}}industry classification scheme: 5, 10, 12, 17, 30, 38, 48, or 49. The default is {bf:48}{p_end}
{synopt:{opt rev:ision(string)}}ISIC revision. The default is {bf:4}. Current release supports only {bf:revision(4)}{p_end}
{synopt:{opt lab:els}}apply value labels to the new variable{p_end}
{synopt:{opt replace}}overwrite existing variable{p_end}
{synopt:{opt diag:nostics}}display ISIC bridge diagnostics{p_end}
{synopt:{opth tie:gen(newvar)}}save tie indicator (1 if plurality tie blocked assignment){p_end}
{synopt:{opth unresolvedgen(newvar)}}save unresolved indicator (1 if no FF assignment){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:isic_to_ff} maps ISIC codes to Fama-French industries by bridging
ISIC Revision 4 to NAICS 2017 (official U.S. Census concordance), then
mapping to SIC/FF through the existing {helpb naics_to_ff}/{helpb sic_to_ff}
stack.

{pstd}
Input normalization is class-level: values are treated as valid Rev.4 classes
only when they normalize to numeric codes {bf:100-9999}. Leading-zero class
inputs (e.g., {bf:0111}) are accepted and normalized to {bf:111}. Group-level
artifacts (e.g., {bf:12}, {bf:14}) are excluded from assignment.

{pstd}
Fractional {it:numeric} ISIC inputs are rejected. If your data store formatted
codes with punctuation or leading zeros, keep them as strings and let the
string-cleaning path normalize them before class-level validation.

{pstd}
This release supports {bf:ISIC Revision 4 only}. The {opt revision()} option
is future-ready, but {opt revision(2)}, {opt revision(3)}, and {opt revision(3.1)}
return an explicit "planned for future release" message.

{pstd}
When one ISIC code links to NAICS codes in multiple FF industries, {cmd:isic_to_ff}
uses a {bf:plurality} rule:

{phang}
1. Assign the FF industry with the largest number of linked NAICS rows.{p_end}
{phang}
2. If the top count is tied, leave the result missing and flag the case as ambiguous.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opth generate(newvar)} specifies the name of the new variable to be created.

{phang}
{opt scheme(#)} selects the Fama-French scheme. Valid values are 5, 10, 12, 17,
30, 38, 48, and 49. The default is 48.

{phang}
{opt revision(string)} selects the ISIC revision. This version supports only
{bf:revision(4)}.

{phang}
{opt labels} attaches value labels to the output variable.

{phang}
{opt replace} permits overwriting existing variables.

{phang}
{opt diagnostics} reports bridge outcomes including plurality-resolved cases,
tie-blocked cases, and unresolved cases.

{phang}
{opth tiegen(newvar)} saves a tie indicator. The variable equals 1 when a
plurality tie prevented assignment.

{phang}
{opth unresolvedgen(newvar)} saves an unresolved indicator. The variable equals 1
when no FF assignment is available. This includes plurality ties and classes with
no FF link in the shipped bridge.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:isic_to_ff} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{synopthdr:Scalars}
{synoptline}
{synopt:{cmd:r(N)}}observations in sample{p_end}
{synopt:{cmd:r(N_isic)}}observations with valid ISIC code{p_end}
{synopt:{cmd:r(N_ff_mapped)}}observations mapped to FF industry{p_end}
{synopt:{cmd:r(N_tie)}}observations unresolved due to plurality tie{p_end}
{synopt:{cmd:r(N_unresolved)}}observations unresolved overall{p_end}
{synopt:{cmd:r(ff_map_rate)}}mapping rate among observations with ISIC code (percent){p_end}

{synopthdr:Macros}
{synoptline}
{synopt:{cmd:r(scheme)}}FF scheme used{p_end}
{synopt:{cmd:r(revision)}}ISIC revision used{p_end}
{synopt:{cmd:r(varname)}}name of generated variable{p_end}
{synoptline}
{p2colreset}{...}


{marker remarks}{...}
{title:Remarks}

{pstd}
The ISIC bridge dataset is distributed with the package as
{bf:isic4_naics17_bridge.dta}. The NAICS lookup is distributed as
{bf:naics_sic_lookup.dta}. Both files must be discoverable on {cmd:adopath}.

{pstd}
{cmd:isic_to_ff} requires {helpb sic_to_ff} version 1.1 or later. When
{opt labels} is requested, {helpb naics_to_ff} must also be discoverable on
{cmd:adopath} so the command can attach the shipped FF value labels.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. isic_to_ff isic4, gen(ff48)}{p_end}
{phang2}{cmd:. isic_to_ff isic4, gen(ff48) labels diagnostics tiegen(isic_tie) unresolvedgen(isic_unres)}{p_end}
{phang2}{cmd:. isic_to_ff isic4, gen(ff17) scheme(17) revision(4)}{p_end}


{marker references}{...}
{title:References}

{pstd}
U.S. Census Bureau. Concordances between NAICS and ISIC:
{browse "https://www.census.gov/naics/concordances/concordances.html"}.


{marker author}{...}
{title:Author}

{pstd}
Kelvin K.F. Law, Nanyang Business School, Nanyang Technological University, Singapore{p_end}

{pstd}
klaw@ntu.edu.sg{p_end}
