{smcl}
{* *! version 1.1  2may2016}{...}
{cmd:help simarwilson} 
{hline}

{title:Title}

{p2colset 5 20 22 2}{...} {phang} {bf:simarwilson} {hline 2} Simar & Wilson (2007) efficiency analysis{p_end} {p2colreset}{...} 

{title:Syntax}

{p 8 17 2}
{cmd:simarwilson}
{it:{help varname:depvar}} {it:{help varname:indepvars}}  {ifin} {weight}, [{cmd:}{it:{help simarwilson##options:options}}]


{synoptset 28 tabbed}{...}
{marker DEA_socre_and_regressors}{...}
{synopthdr :DEA score and regressors}
{synoptline}
{syntab :Model}
{synopt :{it:{help varname:depvar}}}DEA efficiency scores estimated beforehand{p_end}
{synopt :{it:{help varname:indepvars}}}explanatory variables{p_end}

{synoptset 28 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{synopt :{opt {ul on}nounit{ul off}}}{it:depvar} > 1 indicates inefficiency{p_end}
{synopt :{opt {ul on}notwo{ul off}sided}}always use one-sided truncated regression{p_end}

{syntab :SE/Bootstrap}
{synopt :{opt {ul on}reps{ul off}(#)}}number of bootstrap replications{p_end}
{synopt :{opt {ul on}savea{ul off}ll(name)}}save all bootstrap estimates as mata matrix {it:name}{p_end}
{synopt :{opt dot:s}}display replication dots{p_end}

{syntab :Reporting}
{synopt :{opt {ul on}cin{ul off}ormal}}display normal-approximate confidence intervals{p_end}
{synopt :{opt {ul on}bboot{ul off}strap}}display mean bootstrap coefficient vector{p_end}
{synopt :{opt lev:el(#)}}set confidence level; default as set by set level{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}{help truncreg##maximize_options :{it:maximize_options}} are the same as for {cmd:truncreg}.{p_end}
{p 4 6 2}{cmd:bootstrap} is technically allowed, yet its use is counterproductive; {cmd:by} and {cmd:svy} are not allowed; see {help prefix}.{p_end}
{p 4 6 2}
{opt pweight}s and {opt iweight}s are allowed, with the former being the default. {opt fweight}s and {opt aweight}s are not allowed; see {help weight}.{p_end}



{title:Description}

{pstd} {cmd:simarwilson} implements the procedure proposed by Simar and Wilson (2007) for regression analysis of DEA (data envelopment analysis) 
efficiency scores. Unlike naive two-step approaches, the Simar and Wilson procedure accounts for (i) DEA efficiency scores being bounded - depending 
on how inefficiency is defined - from above or from below at the value of one, and (ii) for DEA generating a complex and generally unknown 
correlation pattern among estimated efficiency scores. In technical terms a multi-step procedure is pursued that involves (i) truncated regression 
analysis, (ii) simulating the unknown error correlation, and (iii) calculating bootstrap standard errors and CIs. One may interpret {cmd:simarwilson} 
as a procedure for correcting the standard errors one gets from using {cmd:truncreg} for regressing DEA scores on explanatory variables. DEA 
efficiency scores that enter the model as {it:depvar} have to be estimated prior to running {cmd:simarwilson}. The user-written commands {cmd:dea} 
(Ji and Lee, 2010) and {cmd:teradial}, as well as the accompanying commands {cmd:teradialbc} and {cmd:nptestrts}, (Badunenko and Mozharovskyi, 2016) 
allow for this using stata. Primarily, algorithm #1 (Simar and Wilson, 2007) is implemented by {cmd:simarwilson}. Yet, the command also allows for 
applying (the double-bootstrap) algorithm #2 (Simar and Wilson, 2007) by choosing bias-corrected efficiency estimates as {it:depvar}. The 
user-written command {cmd:teradialbc} (Badunenko and Mozharovskyi, 2016) allows for obtaining such estimates. With the (smoothed) heterogeneous 
option specified, {cmd:teradialbc} approximates the procedure suggested in Simar and Wilson (2007) to obtain bias-corrected efficiency estimates, 
which is one step in algorithm #2. 


{title:DEA efficiency scores and regressors}

{dlgtab:Model}

{phang} {opt depvar} specifies the efficiency measure (score) that enters the model as dependent variable. {cmd:simarwilson} expects {it:depvar} to 
be an DEA efficiency score that is either bounded to the (0,1] interval or to the [1,+inf) interval. If some values of {it:depvar} are smaller than 
one while other exceed one, {cmd:simarwilson} issues a warning and drops observations, depending on how {opt nounit} is specified.  This is likely to 
happen if the DEA is carried out using a reference set that does not include all observations for which efficiency scores are estimated.  
Non-positive values of {it:depvar} are not allowed. The DEA efficiency scores in {it:depvar} need to be estimated prior to running {cmd:simarwilson}. 

{phang} {opt indepvars} specifies the list of regressors. 


{marker options}{...}
{title:Options}

{dlgtab:Main}


{phang} {opt nounit} specifies whether inefficiency is indicated by {it:depvar} < 1 {opt unit} or by {it:depvar} > 1 {opt nounit}. If all 
observations of {it:depvar} are either in the the (0,1] interval or in the [1,+infinity) interval, specifying the {opt nounit} option is irrelevant, 
since {cmd:simarwilson} recognizes  observations as inefficient or as efficient. Otherwise {cmd:simarwilson} drops those observations for which 
either {it:depvar} > 1 ({opt unit}) or  {it:depvar} < 1 ({opt nounit}) holds. These observations can, where appropriate, be regarded as 
super-efficient. 

{phang} {opt notwosided} makes {cmd:simarwilson} apply a one-sided truncated regression model, irrespective of how {opt nounit} is specified. For 
{opt unit} the default ({opt twosided}) is to use a two-sided truncated regression model and to draw from the two-sided truncated normal 
distribution. With {opt twosided}, the procedure takes into account that (input oriented) efficiency scores are not only less than or equal to 1 but 
are also strictly positive. The latter is ignored with {opt notwosided}. Hence, with {opt notwosided}, {cmd:simarwilson} mirror-inverted applies the 
procedure suggested in Simar and Wilson (2007), which only considers {it:depvar} >= 1 ({opt nounit}), to {it:depvar} <= 1 ({opt unit}). With {opt nounit}, specifying {opt notwosided} has no effect. 

{dlgtab:SE/Bootstrap}

{phang} {opt reps(#)} specifies the number of bootstrap replications to be performed. The default is 1000. 

{phang} {opt saveall(name)} makes {cmd:simarwilson} save all bootstrap estimates to the ({it:reps x K}+1) mata matrix {it:name}. Any existing mata 
matrix {it:name} is replaced. 

{phang} {opt dots} makes {cmd:simarwilson} display one dot character for each bootstrap replication. 

{dlgtab:Reporting}

{phang} {opt cinormal} makes {cmd:simarwilson} display normal-approximated confidence intervals rather than percentiles based bootstrap CIs. One 
may change the reported type of CIs by retyping {cmd:simarwilson} without arguments and only specifying the option {opt cinormal}.

{phang} {opt bbootstrap} makes {cmd:simarwilson} display mean bootstrap coefficients rather than the original coefficients from estimating the 
truncated regression model. One may change the type of the reported coefficient vector by retyping {cmd:simarwilson} without 
arguments and only specifying the option {opt bbootstrap}.  

{phang} {opt level(#)}; see {helpb estimation options##level():[R] estimation options}. One may change the reported confidence level by retyping 
{cmd:simarwilson} without arguments and only specifying the option {opt level(#)}. For percentiles based CIs this requires {opt saveall(name)}. 


{title:Examples}

{pstd}Preceding data envelopment analysis (input oriented){p_end}
{phang2}{cmd:. teradial output1 output2 = input1 input2, rts(vrs) base(i) tename(score)}{p_end}

{pstd}Simar and Wilson (2007) analysis of dea scores (algorithm #1){p_end}
{phang2}{cmd:. simarwilson score size i.ownership, reps(2000) dots}{p_end}

{pstd}Preceding data envelopment analysis (bias corrected, output oriented, specified reference set){p_end}
{phang2}{cmd:. teradialbc output1 output2 = input1 input2, rts(vrs) base(o) reference(public) heterogeneous tebc(scorebc)}{p_end}
 
{pstd}Simar and Wilson (2007) analysis of dea scores (algorithm #2){p_end}
{phang2}{cmd:. simarwilson scorebc size i.ownership, nounit reps(2000) dots saveall(BBSTR)}{p_end} 

{title:Saved results}

{pstd}
{cmd:simarwilson} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_lim)}}number of limit observations (efficient DMUs){p_end}
{synopt:{cmd:e(N_nolim)}}number of non-limit observations (inefficient DMUs){p_end}
{synopt:{cmd:e(N_drop)}}number of dropped observations (super efficient DMUs){p_end}
{synopt:{cmd:e(sigma)}}estimate of sigma{p_end}
{synopt:{cmd:e(ll_pseudo)}}log likelihood (initial truncated regression){p_end}
{synopt:{cmd:e(ic)}}number of iterations (initial truncated regression){p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 otherwise (initial truncated regression){p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in e(b){p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(k_aux)}}number of auxiliary parameters{p_end}
{synopt:{cmd:e(chi2)}}model chi-squared{p_end}
{synopt:{cmd:e(p)}}model significance, p-value{p_end}
{synopt:{cmd:e(N_reps)}}number of complete replications{p_end}
{synopt:{cmd:e(N_misreps)}}number of incomplete replications{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(title)}}{cmd:Simar & Wilson (2007) eff. analysis}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmd)}}{cmd:simarwilson}{p_end}
{synopt:{cmd:e(unit)}}either {opt unit} or {opt nounit}{p_end}
{synopt:{cmd:e(truncation)}}either {opt onesided} or {opt twosided}{p_end}
{synopt:{cmd:e(wtype)}}either {opt pweight} or {opt iweight} (only saved if weights are specified){p_end}
{synopt:{cmd:e(wexp)}}= {it:exp} (only saved if weights are specified){p_end}
{synopt:{cmd:e(depvarname)}}{it:depvar}{p_end}
{synopt:{cmd:e(depvar)}}{opt efficiency}{p_end}
{synopt:{cmd:e(saveall)}}{it:name} if option saveall({it:name}) is specified{p_end}
{synopt:{cmd:e(cinormal)}}{opt cinormal} (if option cinormal is specified){p_end}
{synopt:{cmd:e(bbootstrap)}}{opt bbootstrap} (if option bbootstrap is specified){p_end}
{synopt:{cmd:e(properties)}}{opt b V}{p_end}

{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of estimated coefficients{p_end}
{synopt:{cmd:e(V)}}estimated coefficient variance-covariance matrix{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix (if constraints are specified){p_end}
{synopt:{cmd:e(b_bstr)}}bootstrap estimates of coefficients{p_end}
{synopt:{cmd:e(bias_bstr)}}bootstrap estimated biases{p_end}
{synopt:{cmd:e(ci_percentile)}}bootstrap percentile CIs{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:References}

{pstd} Badunenko, O. and Mozharovskyi, P. (2016). Nonparametric frontier analysis using Stata. {it: Stata Journal} 16(3), 550-589.

{pstd} Ji, Y. and Lee, C. (2010). Data envelopment analysis. {it: Stata Journal} 10(2), 267-280. 

{pstd} Simar, L. and Wilson, P. W. (2007). Estimation and inference in two-stage semi-parametric models of production processes. {it: Journal of Econometrics} 136, 31-64. 


{title:Also see}

{psee} Manual:  {manlink R truncreg} 

{psee} {space 2}Help:  {manhelp truncreg R:truncreg}{break} 

{psee} Online:  {helpb dea}, {helpb teradial}, {helpb teradialbc}, {helpb nptestrts}{p_end} 


{title:Author}

{psee} Harald Tauchmann{p_end}{psee} Friedrich-Alexander-Universit{c a:}t Erlangen-N{c u:}rnberg (FAU){p_end}{psee} N{c u:}rnberg, 
Germany{p_end}{psee}E-mail: harald.tauchmann@fau.de {p_end} 


{title:Disclaimer}
 
{pstd} This software is provided "as is" without warranty of any kind, either expressed or implied. The entire risk as to the quality and 
performance of the program is with you. Should the program prove defective, you assume the cost of all necessary servicing, repair or 
correction. In no event will the copyright holders or their employers, or any other party who may modify and/or redistribute this software, 
be liable to you for damages, including any general, special, incidental or consequential damages arising out of the use or inability to 
use the program.{p_end} 


{title:Acknowledgements}

{pstd} This work has been supported in part by the Collaborative Research Center "Statistical Modelling of Nonlinear Dynamic Processes" (SFB 823) of 
the German Research Foundation (DFG). I gratefully acknowledge the comments and suggestions of Ramon Christen, Oleg Badunenko, Rita Maria Ribeiro 
Bastiao, Akash Issar, Ana Claudia Sant'Anna, Jarmila Curtiss, Meir José Behar Mayerstain, Annika Herr, Hendrik Schmitz and participants of the German 
Stata Users Group Meeting 2016.{p_end} 
