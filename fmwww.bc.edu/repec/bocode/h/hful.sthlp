{smcl}
{* *! version 2.0  Nov10.2021}{...}
{viewerjumpto "Syntax" "summarize##syntax"}{...}
{viewerjumpto "Description" "summarize##description"}{...}
{viewerjumpto "Options" "summarize##options"}{...}
{viewerjumpto "Examples" "summarize##examples"}{...}
{viewerjumpto "Reference" "summarize##reference"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col: {opt hful} {hline 2}}Heteroskedasticity robust version of the Fuller estimator{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:hful} {depvar} [{it:{help varlist:varlist1}}]
{cmd:(}{it:{help varlist:varlist2}} {cmd:=}
        {it:{help varlist:varlist_iv}}{cmd:)} {ifin}
[{cmd:,} {it:options}]

{phang}
{it:varlist1} is the list of exogenous variables.{p_end}

{phang}
{it:varlist2} is the list of endogenous variables.{p_end}

{phang}
{it:varlist_iv} is the list of exogenous variables used with {it:varlist1}
   as instruments for {it:varlist2}.

{synoptset 40 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt nocon:stant}}suppress constant term{p_end}
{synopt:{opt casesampling}}produce regular bootstrap results (also called nonparametric bootstrap results){p_end}
{synopt:{opt modelbased}}produce model-based bootstrap results{p_end}
{synopt:{opt wild}}produce model-based wild bootstrap results{p_end}
{synopt:{opt boots(#)}}specify the number of bootstrap replications, the defualt setting is 10,000{p_end}
{synoptline}



{marker description}{...}
{title:Description}

{pstd}
{opt hful} gives heteroskedasticity robust version of the Fuller estimator. It has moments and has mucher lower dispersion than HLIM with many weak instruments.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt noconstant}; see 
{helpb estimation options##noconstant:[R] estimation options}.

{phang}
{opt casesampling} conducts the regular nonparametric method for bootstrap process.

{phang}
{opt modelbased} conducts model-based method for bootstrap process (simulated values are generated from the fitted model, then treated like the original data).

{phang}
{opt wild} conducts model-based wild method for bootstrap process.

{phang}
{opt boots(#)} specifies the nuber of bootstrap replications. The deault is  {cmd:boots(10000)}, meaning that bootstrap program repeats 10000 times.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. hful v1 v2 (v3 v4 v5 = v6 v7 v8 v9) }{p_end}
{phang}{cmd:. hful v1 v2 (v3 v4 v5 = v6 v7 v8 v9), modelbased}{p_end}
{phang}{cmd:. hful v1 v2 (v3 v4 v5 = v6 v7 v8 v9), casesampling}{p_end}
{phang}{cmd:. hful v1 v2 (v3 v4 v5 = v6 v7 v8 v9), wild}{p_end}
{phang}{cmd:. hful v1 v2 (v3 v4 v5 = v6 v7 v8 v9), wild boots(1000)}{p_end}
{phang}{cmd:. hful v1 v2 (v3 v4 v5 = v6 v7 v8 v9) if v1>0, wild}{p_end}

{marker references}{...}
{title:References}

{marker A1991}{...}
{phang}
Hausman J A, Newey W K, Woutersen T, et al. Instrumental variable estimation with heteroskedasticity and many instruments. {it:Quantitative Economics}, 2012, 3(2): 211-255.
{p_end}



