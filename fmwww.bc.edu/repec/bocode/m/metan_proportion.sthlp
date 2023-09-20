{smcl}
{* *! version 4.07  David Fisher  15sep2023}{...}
{vieweralsosee "metan" "help metan"}{...}
{vieweralsosee "metan_model" "help metan_model"}{...}
{vieweralsosee "metan_binary" "help metan_binary"}{...}
{vieweralsosee "metan_continuous" "help metan_continuous"}{...}
{vieweralsosee "forestplot" "help forestplot"}{...}
{vieweralsosee "metani" "help metani"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "ipdmetan" "help ipdmetan"}{...}
{vieweralsosee "ipdover" "help ipdover"}{...}
{vieweralsosee "metabias" "help metabias"}{...}
{vieweralsosee "metatrim" "help metatrim"}{...}
{vieweralsosee "metaan" "help metaan"}{...}
{vieweralsosee "metandi" "help metandi"}{...}
{vieweralsosee "metaprop_one" "help metaprop_one"}{...}
{hi:help metan_proportion}
{hline}

{title:Title}

{phang}
{hi:metan} {hline 2} Perform meta-analysis of single-group proportion data


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:metan} {it:n_events} {it:n_total} {ifin} , {opt pr:oportion}
[{it:{help metan_model:model_spec}} {it:{help metan_proportion##options:options_proportion}} {it:{help metan##options_main:options_main}}]


{marker options_proportion}{...}
{synoptset 24 tabbed}{...}
{synopthdr :options_proportion}
{synoptline}
{syntab :Options}
{synopt :{opt pr:oportion}}(Required) pool proportions from a single group{p_end}

{synopt :{opt cc(#)}}use continuity correction value other than 0.5 for zero cells{p_end}
{synopt :{opt nocc}}suppress continuity correction entirely{p_end}
{synopt :{opt citype(ci_type)}}method of constructing confidence intervals for reporting of individual studies ({ul:not} pooled results){p_end}
{synopt :{opt denom:inator(#)}}specify a denominator for presentation of proportion data{p_end}
{synopt :{opt noint:eger}}allow cell counts to be non-integers{p_end}
{synopt :{opt tr:ansform(tr_method)}}specify a transformation for analysis of proportion data{p_end}
{synopt :{opt nopr}}report effect sizes on transformed scale, not as proportions{p_end}

{syntab :Forest plot and/or saved data}
{synopt :{opt co:unts}}display data counts ({it:n}/{it:N}){p_end}
{synopt :{opt group1(string)}}specify title text for the column created by {opt counts}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:metan} performs meta-analysis of aggregate data; that is, data in which each observation represents a summary of a larger study.
This page describes options specific to a meta-analysis of proportions within a single group.
Option {opt proportion} {ul:must} be supplied in this context, in order to disambiguate {it:n_events} {it:n_total}
from {cmd:metan}'s other two-variable syntax of {it:ES} {it:seES}.

{pstd}
{help metan:Click here} to return to the main {bf:{help metan}} help page
and to find documentation for {it:{help metan_model:model_spec}} and {it:{help metan##options_main:options_main}}.


{dlgtab:Options}

{phang}
{opt cc(#)} controls continuity correction in the case where studies contain zero cells.

{pmore}
By default, {cmd:metan} adds 0.5 to each cell of a trial where a zero is encountered, to enable finite variance estimators to be calculated.
The exception to this is if {cmd:transform(ftukey)} is used; in this case, continuity correction is unnecessary.
Note that corrections are applied during computation only; the original data are not modified.
However, the {help metan##saved_results:new variable} {cmd:_CC} may be added to the dataset or {help metan##saved_datasets:results set},
to indicate the studies to which a correction was applied. See also the {opt nointeger} option.

{pmore}
{it:#} is the correction factor.  The default is 0.5, but other factors may also be used, including zero.
In that case, studies containing zero cells may be excluded from the analysis.

{phang}
{opt nocc} is synonymous with {cmd:cc(0)} and suppresses continuity correction.
Studies containing zero cells may be excluded from the analysis.

{phang}
{opt citype(ci_type)} specifies how confidence limits for individual studies should be constructed for display purposes.
This option acts independently of how confidence limits for {ul:pooled} results are constructed
(which will depend upon {it:{help metan_model:model_spec}}). See also {bf:{help metan##options_main:level(#)}}

{pmore}
For proportion data, the default {it:ci_type} is {opt wilson}, but can also be {opt exact} (a.k.a. Clopper-Pearson),
or any of the alternatives listed under {bf:{help ci}} for proportions.
If option {opt transform()} is specified, {it:ci_type} may also be {opt transform},
meaning that individual study confidence limits should be derived via back-transformation as well as the pooled estimate.

{phang2}
If {opt nointeger} is specified, a Wald-type interval will be constructed and {opt citype()} may not be specified.

{phang}
{opt denominator(#)} specifies a denominator for presenting proportion data, with a default value of 1.
For example, specifying {cmd:denominator(100)} would present the data as percentages between 0 and 100. 
Specifying {cmd:denominator(1000)} would present the data as the number of events per 1000 observations.
Note that this option has no effect upon the analysis; it simply scales the results.

{phang}
{opt nointeger} allows cell counts or sample sizes to be non-integers.

{phang}
{opt transform(tr_method)} specifies a method of transforming proportion data to create a distribution closer to normality
and to stabilise variances.  The following transformations are available using {it:tr_method}:

{pmore}
{opt logit} specifies the Logit transform. Estimates and variances are undefined if the proportion is zero or one,
so by default a continuity correction of 0.5 is applied; see {opt cc()}

{pmore}
{opt ar:csine} specifies the Arcsine transform, for which continuity correction is not required.

{pmore}
{opt ft:ukey} specifies the Freeman-Tukey double-arcsine transform. Again, continuity correction is not required.
{help metan##refs:Schwarzer et al (2019)} show that the standard back-transformation using the harmonic mean
can sometimes give misleading results. Hence, sensitivity analyses may be carried out using the extended syntax
{cmd:transform(}{opt ft:ukey} [{cmd:, }{opt a:rithmetic}|{opt g:eometric}]{cmd:)} to specify an alternative mean.
{help metan##refs:Barendregt et al (2013)} suggest another alternative back-transformation based on the inverse-variance
of the pooled transformed effects, which may be specified using {cmd:transform(}{opt ft:ukey}{cmd:, }{opt iv:ariance}{cmd:)}.

{phang}
{opt nopr} requests that effect sizes are reported on the transformed scale.
In other words, back-transformation to the proportion scale is not performed.


{dlgtab:Forest plot and/or saved data}

{phang}
{opt counts} displays data counts {it:n}/{it:N} for each group in columns to the left of the forest plot.

{pmore}
{opt group1(string)} specifies a column heading for the {opt counts} column.



{title:Authors}

{pstd}
Original authors:
Michael J Bradburn, Jonathan J Deeks, Douglas G Altman.
Centre for Statistics in Medicine, University of Oxford, Oxford, UK

{pstd}
{cmd:metan} v3.04 for Stata v9:
Ross J Harris, Roger M Harbord, Jonathan A C Sterne.
Department of Social Medicine, University of Bristol, Bristol, UK

{pstd}
{cmd:metan} v4.00 and later (including current version):
David Fisher, MRC Clinical Trials Unit at UCL, London, UK.

{pstd}
Email {browse "mailto:d.fisher@ucl.ac.uk":d.fisher@ucl.ac.uk}



{title:Acknowledgments}

{pstd}
Thanks to Patrick Royston (MRC Clinical Trials Unit at UCL, London, UK) for suggestions of improvements to the code and help file.

{pstd}
Thanks to Vince Wiggins, Kit Baum and Jeff Pitblado of Statacorp who offered advice and helped facilitate the version 9 update.

{pstd}
Thanks to Julian Higgins and Jonathan A C Sterne (University of Bristol, Bristol, UK) who offered advice and helped facilitate this latest update,
and thanks to Daniel Klein (Universit{c a:}t Kassel, Germany) for assistance with testing under older Stata versions.

{pstd}
The "click to run" element of the examples in this document is handled using an idea originally developed by Robert Picard.



{marker refs}{...}
{title:References}

{phang}
Barendregt JJ, Doi SA, Lee YY, Norman RE, Vos T. 2013.
Meta-analysis of prevalence.
J Epidemiol Community Health 67: 974–978. doi:10.1136/jech-2013-203104

{phang}
Schwarzer G, Chemaitelly H, Abu-Raddad LJ, R{c u:}cker G. 2019.
Seriously misleading results using inverse of Freeman-Tukey double arcsine transformation
in meta-analysis of single proportions.
Research Synthesis Methods 10: 476–483. doi: 10.1002/jrsm.1348

