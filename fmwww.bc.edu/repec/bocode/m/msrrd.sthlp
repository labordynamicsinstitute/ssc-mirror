{smcl}
{title:msrrd — Risk Ratio and Risk Difference estimation using Marginal standardisation (G-computation) method}

{pstd}
Computes Risk Ratio (RR) and Risk Difference (RD) using Marginal standardisation (G-computation) method (see {help margins}).

{pstd}
Standard errors and 95% CI's are computed using the delta-method (see {help nlcom}).

{pstd}
The command will also displays n/N (%) by group (and for each subgroup if subgroup option selected).

{title:Syntax}

{pstd}
{cmd:msrrd} {it:varname}
{cmd:,}
{opt subgroup(subgroup_varname)}
{opt subtype(rr/rd/both)}
{opt rrdp(#)}
{opt rddpprop(#)}
{opt rddppct(#)}
{opt pdp(#)}
{opt pctdp(#)}
{opt vceuncond}


{title:Important notes/rules for command to run correctly}

{p 10 12}
{err: {cmd:{it:varname}} must be a binary variable coded 0/1 where 0=Comparator group and 1=Intervention group.}

{p 16 12}
For command {cmd:{it:msrrd}}, {it:varname} should not to be specifed as factor variable operator (e.g. {cmd:{it:i.varname}}) and instead just inputted as {it:varname}.

{p 16 12}
However, {it:varname} must be specified as factor variable operator (e.g. {cmd:{it:i.varname}}) in the fitted model.

{p 10 12}
{err: If {cmd:{it:subgroup}} option is selected, the fitted model must contain the interaction term {cmd:i.{it:varname}#i.{it:subgroup_varname}} or {cmd:i.{it:varname}##i.{it:subgroup_varname}} as factor variable operators.}

{p 16 12}
For command {cmd:{it:msrrd}}, {it:subgroup_varname} should not to be specifed specifed as factor variable operator (e.g. {cmd:{it:i.subgroup_varname}}) and instead just inputted as {it:subgroup_varname}.

{p 10 12}
{err: If {cmd:{it:vceuncond}} option is selected, this will calculate the SE's from {help margins} allowing for sampling of covariates}. 

{p 16 12}
{err: Note option {cmd:{it:vceuncond}} will only work if {cmd:{it:robust/cluster robust SE}}} was specified in fitted model (see {help vcetype}).


{p 6 12}
{err: The command {cmd:{it:msrrd}} will only work if a [{help logistic}] or [{help logit}] or [{help melogit}] or [{help glm} / {help meglm} {cmd:{it:with binomial family and logit link}}] is fitted first}.

{pstd}

{title:Options}

{dlgtab:Formatting}

{synopt:{opt rrdp(#)}} Number of decimal places for RR and CI.
[Default is {cmd:4}].{p_end}

{synopt:{opt rddpprop(#)}} Number of decimal places for RD (proportion) and CI.
[Default is {cmd:4}].{p_end}

{synopt:{opt rddppct(#)}} Number of decimal places for RD (percentage) and CI.
[Default is {cmd:2}].{p_end}

{synopt:{opt pdp(#)}} Number of decimal places for all p-values.
[Default is {cmd:4}].{p_end}

{synopt:{opt pctdp(#)}} Number of decimal places for percentage in statistic n/N (%).
[Default is {cmd:1}].{p_end}

{dlgtab:Subgroup analysis}

{synopt:{opt subgroup(subgroup_varname)}}
Compute subgroup-specific RR/RD using marginal standardisation for each level of {it:subgroup_varname}.

{synopt:{opt subtype(rr/rd/both)}} {cmd:rr} — risk ratio only;  {cmd:rd} — risk difference only; {cmd:both} — both RR and RD.   [Default is {cmd:both}].{p_end}

{dlgtab:vce(unconditional)}

{synopt:{opt vceuncond}} Specifies {help margins} to use vce(unconditional) so that to estimate SEs allowing for sampling of covariates.   [Default is vce(delta) if option vceuncond not included].{p_end}


{title:Description}

{pstd}
The command performs the following steps:

{p 4 8 2}
1. Runs {cmd:margins {it:varname}, post} [or {cmd:margins {it:varname}#{it:subgroup_varname}}, post when subgroup option selected]. 

{p 8 8 2}
If option {it:vceuncond} included then vce(unconditional) is added as an option in {cmd: margins} so that SE's are computed allowing for sampling of covariates.

{p 4 8 2}
2. Extracts predicted risks and their variance–covariance matrix from {cmd:r(b)} and {cmd:r(V)}.

{p 4 8 2}
3. Computes RR = p1 / p0 and its log–scale variance using the delta-method.

{p 4 8 2}
4. Computes RD = p1 – p0 and its variance using the delta-method.

{p 4 8 2}
5. Produces 95% confidence intervals, z–statistics, and p–values for both RR and RD.

{p 4 8 2}
RR is reported on the ratio scale. RD is reported on the proportion and percentage scale.

{p 6 8 2}
If {cmd:subgroup()} is specified:

{p 8 8 2}
An interaction test is performed using {cmd:testparm i.varname#i.subgroup}.  

{p 10 8 2}
{err:The fitted model must contain the interaction term {cmd:i.varname#i.subgroup} or {cmd:i.varname##i.subgroup} else command will output error message}.  

{p 8 8 2}
Subgroup-specific RR and RD are computed using the same delta-method formulas. 

{p 8 8 2}
Output is displayed per subgroup level according to {cmd:subtype()}.{p_end}


{title:Examples}

{p 4 8 2}Set-up dataset{p_end}

{phang2}{cmd:. webuse nhanes2d, clear}{p_end}

{p 4 8 2}Fit a logistic model and compute RR and RD (default dp):{p_end}

{phang2}{cmd:. logit highbp height weight age i.female i.race, vce(robust)}{p_end}

{phang2}{cmd:. msrrd female, vceuncond}{p_end}

{p 4 8 2}Specify RR to 3dp, RD proportion to 5dp, RD percentage to 3dp and P-values to 3dp::{p_end}

{phang2}{cmd:. msrrd female, rrdp(3) rddpprop(5) rddppct(3) pdp(3) vceuncond}

{p 4 8 2}Subgroup analysis (RR and RD):{p_end}

{phang2}{cmd:. logistic highbp height weight age i.female##i.race, vce(robust)}

{phang2}{cmd:. msrrd female, subgroup(race) subtype(both) vceuncond}


{title:Stored results}

{pstd}
{cmd:msrrd} stores the following in {cmd:r() {err:[Note: results of subgroups not stored]}}:

{dlgtab:Risk ratio}

{synopt:{cmd:r(rr)}}Risk ratio{p_end}
{synopt:{cmd:r(rr_lb)}}Lower 95% CI{p_end}
{synopt:{cmd:r(rr_ub)}}Upper 95% CI{p_end}
{synopt:{cmd:r(rr_z)}}z-statistic{p_end}
{synopt:{cmd:r(rr_p)}}p-value{p_end}

{dlgtab:Risk difference (proportion)}

{synopt:{cmd:r(rd)}}Risk difference (proportion){p_end}
{synopt:{cmd:r(rd_lb)}}Lower 95% CI{p_end}
{synopt:{cmd:r(rd_ub)}}Upper 95% CI{p_end}
{synopt:{cmd:r(rd_z)}}z-statistic{p_end}
{synopt:{cmd:r(rd_p)}}p-value{p_end}


{title:Author}

{pstd}Samir Mehta — Senior Medical Statistician{p_end}
{pstd}Birmingham Clinical Trials Unit (BCTU){p_end}
{pstd}University of Birmingham{p_end}
{pstd}s.mehta.1@bham.ac.uk{p_end}
