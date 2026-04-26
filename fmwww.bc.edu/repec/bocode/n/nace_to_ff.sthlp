{smcl}
{* *! version 1.1  20apr2026}{...}
{vieweralsosee "naics_to_ff" "help naics_to_ff"}{...}
{vieweralsosee "isic_to_ff" "help isic_to_ff"}{...}
{vieweralsosee "sic_to_ff" "help sic_to_ff"}{...}
{viewerjumpto "Syntax" "nace_to_ff##syntax"}{...}
{viewerjumpto "Description" "nace_to_ff##description"}{...}
{viewerjumpto "Options" "nace_to_ff##options"}{...}
{viewerjumpto "Stored results" "nace_to_ff##results"}{...}
{viewerjumpto "Remarks" "nace_to_ff##remarks"}{...}
{viewerjumpto "Examples" "nace_to_ff##examples"}{...}
{viewerjumpto "References" "nace_to_ff##references"}{...}
{viewerjumpto "Author" "nace_to_ff##author"}{...}

{title:Title}

{phang}
{bf:nace_to_ff} {hline 2} Convert NACE Rev. 2 codes to Fama-French industry classifications


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:nace_to_ff}
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
{synopt:{opt lab:els}}apply value labels to the new variable{p_end}
{synopt:{opt replace}}overwrite existing variable{p_end}
{synopt:{opt diag:nostics}}display NACE bridge diagnostics{p_end}
{synopt:{opth tie:gen(newvar)}}save tie indicator (1 if plurality tie blocked assignment){p_end}
{synopt:{opth unresolvedgen(newvar)}}save unresolved indicator (1 if no FF assignment){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nace_to_ff} maps NACE Rev. 2 class codes to Fama-French industries by
first bridging NACE Rev. 2 to ISIC Revision 4 through an official correspondence
table and then delegating classification to {helpb isic_to_ff}.

{pstd}
Input normalization is class-level: values are treated as valid NACE Rev. 2
classes only when they normalize to numeric codes {bf:100-9999}. Leading-zero
and dotted class inputs (for example, {bf:01.11} or {bf:0111}) are accepted and
normalized to {bf:111}. Values outside the class range are excluded from assignment.

{pstd}
Fractional {it:numeric} NACE inputs are rejected. If your data store formatted
codes with dots, punctuation, or leading zeros, keep them as strings and let
the string-cleaning path normalize them before class-level validation.

{pstd}
The NACE-to-ISIC bridge is one-to-one at the 4-digit class level. Any ambiguity
in FF assignment arises only in the inherited ISIC-to-FF step, where
{cmd:isic_to_ff} applies a plurality rule across linked FF industries.

{pstd}
This version supports {bf:NACE Revision 2 only}. If support for later NACE
revisions is added, it will appear as a separate extension.


{marker options}{...}
{title:Options}

{phang}
{opth generate(newvar)} specifies the name of the new variable to be created.

{phang}
{opt scheme(#)} selects the Fama-French scheme. Valid values are 5, 10, 12, 17,
30, 38, 48, and 49. The default is 48.

{phang}
{opt labels} attaches value labels to the output variable.

{phang}
{opt replace} permits overwriting existing variables.

{phang}
{opt diagnostics} reports NACE bridge outcomes. These include cases that fail at
the NACE-to-ISIC step and cases that remain unresolved in the downstream ISIC step.

{phang}
{opth tiegen(newvar)} saves a tie indicator. The variable equals 1 when a
plurality tie prevented assignment in the inherited ISIC-to-FF step.

{phang}
{opth unresolvedgen(newvar)} saves an unresolved indicator. The variable equals 1
when no FF assignment is available after the NACE-to-ISIC and ISIC-to-FF steps.
This includes plurality ties inherited from the ISIC stage.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:nace_to_ff} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{synopthdr:Scalars}
{synoptline}
{synopt:{cmd:r(N)}}observations in sample{p_end}
{synopt:{cmd:r(N_nace)}}observations with valid normalized NACE code{p_end}
{synopt:{cmd:r(N_ff_mapped)}}observations mapped to FF industry{p_end}
{synopt:{cmd:r(N_tie)}}observations unresolved due to plurality tie{p_end}
{synopt:{cmd:r(N_unresolved)}}observations unresolved overall{p_end}
{synopt:{cmd:r(ff_map_rate)}}mapping rate among observations with valid NACE code (percent){p_end}

{synopthdr:Macros}
{synoptline}
{synopt:{cmd:r(scheme)}}FF scheme used{p_end}
{synopt:{cmd:r(revision)}}delegated ISIC revision used. Currently {bf:4}{p_end}
{synopt:{cmd:r(nace_revision)}}NACE revision used. Currently {bf:2}{p_end}
{synopt:{cmd:r(varname)}}name of generated variable{p_end}
{synoptline}
{p2colreset}{...}


{marker remarks}{...}
{title:Remarks}

{pstd}
The NACE bridge dataset is distributed with the package as
{bf:nace2_isic4_bridge.dta}. The delegated ISIC bridge dataset is distributed as
{bf:isic4_naics17_bridge.dta}. Both files must be discoverable on {cmd:adopath}.

{pstd}
{cmd:nace_to_ff} requires {helpb isic_to_ff} and its downstream dependency
{helpb sic_to_ff} version 1.1 or later. When {opt labels} is requested,
{helpb naics_to_ff} must also be discoverable on {cmd:adopath}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. nace_to_ff nace2, gen(ff48)}{p_end}
{phang2}{cmd:. nace_to_ff nace2, gen(ff48) labels diagnostics tiegen(nace_tie) unresolvedgen(nace_unres)}{p_end}
{phang2}{cmd:. nace_to_ff nace2, gen(ff17) scheme(17)}{p_end}


{marker references}{...}
{title:References}

{pstd}
United Nations Statistics Division. Correspondence table between ISIC Rev. 4 and
NACE Rev. 2:
{browse "https://unstats.un.org/unsd/classifications/Econ/tables/ISIC/ISIC4_NACE2/ISIC4_NACE2.txt"}.

{pstd}
Eurostat RAMON. NACE Rev. 2 correspondence tables:
{browse "https://ec.europa.eu/eurostat/ramon/relations/index.cfm?TargetUrl=LST_REL&StrLanguageCode=EN&IntCurrentPage=1&StrNomRelCode=ISIC4%20-%20NACE2"}.


{marker author}{...}
{title:Author}

{pstd}
Kelvin K.F. Law, Nanyang Business School, Nanyang Technological University, Singapore{p_end}

{pstd}
klaw@ntu.edu.sg{p_end}
