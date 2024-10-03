{smcl}
{* *! version 1.0.0   02feb2024  Maximilian Sprengholz & Maik Hamjediers}{...}
{vieweralsosee "kmatch" "kmatch"}{...}
{vieweralsosee "nopomatch" "nopomatch"}{...}
{viewerjumpto "Syntax" "nopo##syntax"}{...}
{viewerjumpto "Postestimation" "nopo##postest"}{...}
{viewerjumpto "Description" "nopo##desc"}{...}
{viewerjumpto "Options" "nopo##opts"}{...}
{viewerjumpto "Examples" "nopo##ex"}{...}
{title:Title}

{phang}{hi:nopo} {hline 2} Matching-based decomposition analysis of differences in outcomes between two groups following {c N~}opo (2008)

{marker:dep}{...}
{title:Dependencies}

{phang} Requires {help kmatch:{it:kmatch}} (Jann, 2017) to be installed, which has
{help moremata:{it:moremata}} as dependency.

{marker:syntax}{...}
{title:Syntax}

        {cmd:nopo decomp} {depvar} {varlist} {ifin} {weight} {cmd:, by(}varname{cmd:)} [{help nopo##comopt:{it:options}}]
   
   
    As postestimation to a matching via {help kmatch:{it:kmatch}}:
   
        {cmd:nopo decomp} [{cmd:,} {cmdab:kmpass:thru(}{it:string}{cmdab:)} {cmdab:kmkeep:gen}]


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
    General
{synopt :{cmdab:by(}{help varname:{it:varname}}{cmdab:)}}Group variable by which to estimate and decompose gaps in {depvar:} (required) {p_end}{...}
{synopt :{cmdab:swap}}Swap groups{p_end}{...}
{synopt :{cmdab:xref(}{varname}{it: == #}{cmdab:)}}Set reference group in terms of characteristics {p_end}{...}
{synopt :{cmdab:bref(}{varname}{it: == #}{cmdab:)}}Set reference group in terms of returns {p_end}{...}

    Matching procedure 
{synopt :{cmdab:km:atch(}em|md|ps{cmdab:)}}Choose between exact (em, default), multivariate-distance (md), and propensity score (ps) matching{p_end}{...}
{synopt :{cmdab:kmo:pts(}{it:string}{cmdab:)}}Matching-specific options according to {help kmatch:{it:kmatch}} {p_end}{...}

    Reporting
{synopt :{cmdab:norm:alize}}Normalize estimates by mean outcome of group {it:A} {p_end}{...}
{synopt :{cmdab:kmnois:ily}}Display output from internal kmatch call{p_end}{...}
{synopt :{cmdab:kmpass:thru(}{it:string}{cmdab:)}}Adds results of interal kmatch to the {help nopo##returns:stored results} of {cmd:nopo decomp}{p_end}{...}
{synopt :{cmdab:kmkeep:gen}}Keep matching and weight variables generated by kmatch{p_end}{...}
{synoptline}
{phang}{it:fweights}, {it:pweights}, and {it:iweights} are allowed.{p_end}
{phang} Allows for the {cmd:bootstrap} and {cmd:jackknife} prefix for standard errors.{p_end}
{phang} See {help nopo_postestimation:{bf:nopo postestimation}} for three available features after estimation ({cmd:nopo summarize}, {cmd:nopo gapoverdist}, {cmd:nopo dadb}).{p_end}
{p2colreset}

{marker desc}{...}
{title:Description}

{pstd}
{hi:nopo decomp} provides a {c N~}opo-style (2008) decomposition of the gap {it:D} in the average outcome {it:Y} 
between two groups {it:A} and {it:B} by matching them on a set of characteristics {it:X} predictive of {it:Y}.

{p 6 6 2}{it:D = YB - YA}{p_end}
{p 8 8 2}{it:  = D0 + DX + DA + DB  , where}{p_end}

{p 4 6 2}
{it:- D0} is the part of the gap not attributable to compositional differences between {it:A} and {it:B} in {it:X} among matched units (classic {it:unexplained} component){p_end}
{p 4 6 2}
{it:- DX} is the part of the gap attributable to compositional differences between {it:A} and {it:B} in {it:X} among matched units (classic {it:explained} component){p_end}
{p 4 6 2}
{it:- DA} is the part of the gap attributable to unmatched units in {it:A}{p_end}
{p 4 6 2}
{it:- DB} is the part of the gap attributable to unmatched units in {it:B}{p_end}

{pstd}
For this decomposition, the matching generates counterfactual group {it:A^B} by weighting all matched observations of group {it:A} in order to provide the exact same distribution in {it:X} as matched units of group {it:B}. The outcome of this counterfactual group can be interpreted in two ways: (1) as the average outcome of group {it:A} if it had the same characteristics as group {it:B} (for which we denote group {it:B} as {cmd:xref}) and (2) as the average outcome of group {it:B} if it had the same returns to characteristics as group {it:A} (for which we denote group {it:A} as {cmd:bref}). One can easily change this interpretation, by switching the matching direction and producing the counterfactual group {it:B^A} using the {cmd:xref()} or {cmd:bref()} option. 

{pstd}
Note that positive values for {it:DA} reflect unmatched units having {it:lower} values in {it:Y} than matched units among group {it:A}, whereas positive values of {it:DB} reflect unmatched units having {it:higher} values in {it:Y} than matched units among group {it:B}.

{pstd}    
A detailed explanation of the methodology is provided in an {browse "https://github.com/mhamjediers/nopo_decomposition/blob/main/te.md":online documentation}. 

{pstd}{ul:Matching approaches:} 

{pstd}
{c N~}opo's original proposition used exact matching but extends to other matching approaches, 
two of which are additionally available in {cmd:nopo decomp}: multivariate-distance and propensity-score matching. 

{pstd}
An exact matching ensures that the interpretation of the unexplained {it:D0} and explained {it:DX} components 
directly refer to the characteristics {it:X} (e.g., {it:D0} being the remaining gap if both groups had the same
characteristics as group {it:B}). 
This interpretation changes slightly in the case of multivariate-distance and propensity-score matching, as {it:D0} 
then refers to both groups having an equal likelihood to be the group specified as {cmd:xref} based on the characteristics {it:X}.
Note that the results of the decomposition may hinge on the specifics of either matching procedure 
(e.g., the extent of coarsening of continuous variables before exact matching, or the bandwidth selection 
for determining matches in terms of the propensity-score or multivariate-distance).

{pstd}
To implement each matching procedure, {cmd:nopo decomp} either internally calls {cmd:kmatch} or it can be used 
as a postestimation to a previous matching via {cmd:kmatch}. While {cmd:kmatch} provides average treatment
effects on the treated (ATT) or controls (ATC) that are equal to the unexplained component {it:D0}, {cmd:nopo decomp}
additionally estimates the other three decomposition-components {it:DX}, {it:DA}, and {it:DB}. 

{pstd}{ul:Standard errors:}

{pstd}Please use the {cmd:bootstrap} or {cmd:jackknife} prefix to obtain standard errors (see {help nopo##examples:{it:Examples}}). 
We are working out how the analytical SEs as detailed by {c N~}opo (2008) for {it:D0} 
(and implemented in {help nopomatch:{it:nopomatch}) extend to the full set of components in the 
presence of covariance. If you can help, please reach out to us via 
{browse "https://github.com/mhamjediers/nopo_decomposition/issues/14":GitHub}.

{pstd}{ul:Postestimation:}

{pstd} See {help nopo_postestimation:{bf:nopo postestimation}} for available features after estimation.

{marker opts}{...}
{title:Options}

{dlgtab:General}

{phang}
{cmdab:by(}{help varname:{it:varname}}{cmdab:)} specifies the groups between which we estimate and 
decompose the gap in {depvar:} (required). Needs to be numeric with two levels. By default, the gap is 
definied as the mean value of the first {cmd:by} group is substracted from the second group, and
the first group is matched to the second group via a one-to-many matching.
Use {cmd:xref()}/{cmd:bref()} to adjust the matching direction or {cmd:swap} to change.

{phang}
{cmdab:swap} groups {it:A} and {it:B}, so that the sign of {it:D} is reversed and and the respective reference 
for characteristics and returns is switched.

{phang}
{cmdab:xref(}{varname}{it: == #}{cmd:)} allows to adjust the matching direction and thereby 
manually set the reference group for the counteractual group in terms of {it:characteristics}. 
Naturally, {cmd:xref()} and {cmd:bref()} cannot be the same.

{phang}
{cmdab:bref(}{varname}{it: == #}{cmd:)} allows to adjust the matching direction and thereby 
manually set the reference group for the counteractual group in terms of {it:returns}. 
Naturally, {cmd:bref()} and {cmd:xref()} cannot be the same.


{dlgtab:Matching procedure}

{phang}
{cmdab:km:atch(}em|md|ps{cmdab:)} lets you choose the measure how both groups are matched, while the
decomposition always relays on a one-to-many matching procedure. The default is to use 
{it:exact matching} {cmd:kmatch(em)}, in which case all variables in {varlist} are treated as 
factors. For multivariate-distance {cmd:kmatch(md)} and propensity score {cmd:kmatch(ps)} 
matching, make sure to indicate via factor notation which variables are factors and which are
continuous (everything is passed through to the internal kmatch call as is). To further tweak the
matching, you can use {cmd:kmopts()} or, for maximum flexibility, call {cmd:nopo decomp} after a
manual {cmd:kmatch} call with all the necessary options.

{phang}
{cmdab:kmo:pts(}string{cmdab:)} are options passed on to {help kmatch:{it:kmatch}} when 
called internally. See {help kmatch##goptions:{it:general_options}}, 
{help kmatch##matchoptions:{it:matching_options}} and the matching-type specific options
{help kmatch##emoptions:{it:em_options}}, 
{help kmatch##mdoptions:{it:md_options}}, or {help kmatch##psoptions:{it:ps_options}}.

{dlgtab:Reporting}

{phang}
{cmdab:norm:alize} estimates by the {depvar} mean of group {it: A}. Coefficients can then be interpreted in a 
relative manner, e.g. that group {it:B} earns on average {it:x percent} wages relative to group {it:A}. 
The comparison group can be changed by using the option {cmdab:swap}.
Generates {bf:_{depvar}_norm}.

{phang}
{cmdab:kmnois:ily} Show output of internal kmatch call.

{phang}
{cmdab:kmpass:thru(}string{cmdab:)} lets you pass through further
{help kmatch##eret:{it:kmatch stored results}} to the {help nopo##returns:stored results} of {cmd:nopo decomp}. 
For example: {cmd:kmpassthru(df_r metric)} would add {it:residual degrees of freedom} and 
{it:type of multivariate distance metric} as stored macros to the sored results of {cmd:nopo decomp}.

{phang}
{cmdab:kmkeep:gen} keeps the matching and weight variables {help kmatch##gen:{it:generated by kmatch}}, 
which are dropped by default. In the standalone call, these variables are prefixed by {bf:_KM_}). 
Note that some of the kmatch variables contain the same information as the variables returned by 
{cmd:nopo decomp} (prefixed by {bf:_nopo_}).


{marker examples}{...}
{title:Examples}

{pstd}Example data ({stata "nopo_ex 1":{it:click to run}}){p_end}
{phang}. {stata "use http://fmwww.bc.edu/RePEc/bocode/o/oaxaca.dta , clear"}{p_end}
{phang}. {stata "for any exper tenure: gen X_c = round(X,5)"}{p_end}
{phang}. {stata gen educ_c = round(educ,1)}{p_end}
{phang}. {stata lab var educ_c "years of educational attainment (rounded)"}{p_end}
{phang}. {stata lab var exper_c "years of work experience (5-year intervalls)"}{p_end}
{phang}. {stata lab var tenure_c "years of job tenure (5-year intervalls)"}{p_end}
{phang}. {stata lab def female 0 "Men" 1 "Women"}{p_end}
{phang}. {stata lab val female female}{p_end}

{pstd}Decomposition - Standalone{p_end}
{phang}. {stata nopo decomp lnwage educ_c exper_c tenure_c, by(female)}{p_end}

{pstd}Decomposition - After {help kmatch:{it:kmatch}}{p_end}
{phang}. {stata kmatch em female educ_c exper_c tenure_c (lnwage), att}{p_end}
{phang}. {stata nopo decomp}{p_end}

{pstd}Decomposition - Using propensity-score or multivariate-distance matching}{p_end}
{phang}. {stata nopo decomp lnwage educ_c exper_c tenure_c, by(female) kmatch(ps)}{p_end}
{phang}. {stata nopo decomp lnwage educ_c exper_c tenure_c, by(female) kmatch(md)}{p_end}

{pstd}Standard errors{p_end}
{phang}. {stata "bootstrap, reps(100): nopo decomp lnwage educ_c exper_c tenure_c, by(female)"}{p_end}

{pstd}Obtain the same results as {help nopomatch:{it:nopomatch}}{p_end}
{phang}. {stata nopomatch educ_c exper_c tenure_c, outcome(lnwage) by(female)}{p_end}
{phang}. {stata nopo decomp lnwage educ_c exper_c tenure_c, by(female) xref(0) normalize}{p_end}

{pstd}Comparison to twofold regression-based decomposition via {help oaxaca:{it:oaxaca}}{p_end}
{phang}. {stata oaxaca lnwage educ exper tenure, by(female) weight(0) nodetail}{p_end}
{phang}. {stata nopo decomp lnwage educ_c exper_c tenure_c, by(female) swap}{p_end}


{marker returns}{...}
{title:Stored results}

{pstd}
{cmdab:nopo decomp} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(nstrata)}}number of strata (or undefined){p_end}
{synopt:{cmd:e(nstrata_matched)}}number of matched strata (or undefined){p_end}
{synopt:{cmd:e(nn)}}number of requested neighbors (or undefined){p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(nA)}}number of observations of group {it:A} {p_end}
{synopt:{cmd:e(mshareA)}}percentage of matched units among group {it:A} {p_end}
{synopt:{cmd:e(msharewA)}}weighted percentage of matched units among group {it:A} {p_end}
{synopt:{cmd:e(mgapA)}}mean difference in {depvar} between matched and unmatched units of group {it:A} {p_end}
{synopt:{cmd:e(nB)}}number of observations of group {it:B} {p_end}
{synopt:{cmd:e(mshareB)}}percentage of matched units among group {it:B} {p_end}
{synopt:{cmd:e(msharewB)}}weighted percentage of matched units among group {it:B} {p_end}
{synopt:{cmd:e(mgapB)}}mean difference in {depvar} between matched and unmatched units of group {it:B} {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(kmatch_cmdline)}}command line of interal {cmd:kmatch} call{p_end}
{synopt:{cmd:e(kmatch_subcmd)}}type of matching ({cmd:md}, {cmd:ps}, or {cmd:em}{p_end}
{synopt:{cmd:e(strata)}}name of variable that denotes matching stratum{p_end}
{synopt:{cmd:e(mweight)}}name of variable that denotes matching weight{p_end}
{synopt:{cmd:e(matched)}}name of variable that denotes matching indicator{p_end}
{synopt:{cmd:e(matchset)}}list of variables on which groups are matched{p_end}
{synopt:{cmd:e(groupA)}}expression that defines group {it:A} in terms of group-variable{p_end}
{synopt:{cmd:e(groupB)}}expression that defines group {it:B} in terms of group-variable{p_end}
{synopt:{cmd:e(xref)}}expression for the reference group in terms of {it:characteristics}{p_end}
{synopt:{cmd:e(bref)}}expression for the reference group in terms of {it:returns}{p_end}
{synopt:{cmd:e(cval)}}list of variables on which groups are matched{p_end}
{synopt:{cmd:e(tval)}}list of variables on which groups are matched{p_end}
{synopt:{cmd:e(tvar)}}name of group variable{p_end}
{synopt:{cmd:e(teffect)}}matching direction ({bf:ATT} or {bf:ATC}){p_end}
{synopt:{cmd:e(wexp)}}weight expression (if weights are applied){p_end}
{synopt:{cmd:e(wtype)}}{it:fweights}, {it:pweights}, and {it:iweights} (if weights are applied){p_end}
{synopt:{cmd:e(cmd)}}{cmd:nopo}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vectors of all gap-estimates{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{pstd}
Additional to the above, the following is stored in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}matrix of the descriptive matching block (upper table in output){p_end}

{pstd}
{cmd:nopo decomp} generates the following variables:

{p2colset 5 20 24 2}{...}
{p2col:{bf:_nopo_matched}} Matching indicator (dummy){p_end}
{p2col:{bf:_nopo_mweight}} Matching weight{p_end}
{p2col:{bf:_nopo_strata}} Matching stratum ({it:kmatch(em)} only){p_end}
{p2col:{bf:_nopo_ps}} Matching propensity score ({it:kmatch(ps)} only){p_end}
{p2col:{bf:_{depvar}_norm}} Normalized {depvar} (if {cmd:normalize} was specified){p_end}

{pstd}
Any results from the internal kmatch call can be added to {cmd:e()} via the {cmdab:kmpass:thru()} option.

{pstd}
If {cmd:bootstrap}- or {cmd:jackknife}-prefix is used, additional results as described in help 
	{helpb bootstrap} and {helpb jackknife} are stored in {cmd:e()}.


{title:References}

{phang}
Jann, B. (2017). kmatch: Stata module for multivariate-distance and propensity-score matching,
including entropy balancing, inverse probability weighting, (coarsened) exact matching, and
regression adjustment. Available from {browse https://ideas.repec.org/c/boc/bocode/s458346.html}.

{phang}
{c N~}opo, H. (2008). Matching as a Tool to Decompose Wage Gaps. The Review of Economics 
and Statistics, 90(2), 290–299. {browse "https://doi.org/10/b6tqwq"}


{title:Acknowledgements}

{pstd}
Special thanks to Carla Rowold for stress testing and many helpful comments.


{title:Authors}

{pstd}
Maximilian Sprengholz,  {browse "mailto:maximilian.sprengholz@hu-berlin.de":maximilian.sprengholz@hu-berlin.de}{p_end}
{pstd}
Maik Hamjediers, {browse "mailto:maik.hamjediers@hu-berlin.de":maik.hamjediers@hu-berlin.de}{p_end}
{pstd}
Department of Social Sciences,{p_end}
{pstd}
Humboldt-Universität zu Berlin{p_end}

