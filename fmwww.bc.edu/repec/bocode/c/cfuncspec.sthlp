{smcl}
{* 11mar2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "tstats" "help tstats"}{...}
{vieweralsosee "collapsel" "help collapsel"}{...}
{vieweralsosee "elgen" "help elgen"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tlist" "help tlist"}{...}
{vieweralsosee "fromvars" "help fromvars"}{...}
INCLUDE help also_vlowy
{vieweralsosee "" "--"}{...}
{viewerjumpto "C-function spec" "cfuncspec"}{...}
{viewerjumpto "C-func" "cfuncspec##cfunc"}{...}
{viewerjumpto "Cfexp" "cfuncspec##cfexp"}{...}
{title:Title}

{pstd}{bf:C-function Specification}{p_end}


{title:Vars-by-Funcs Syntax}

{pstd}The most concise syntax, when it suffices, is:

{phang2}[{it:{help varelist}}] [{cmd::} {it:{help cfuncspec##cfunc:C-func}}{opt (VxF details)} [{it:{help cfuncspec##cfunc:C-func}}{opt (VxF details)} ...]]

{pstd}You specify a set of variables and a set of functions, and each function is applied to each variable.

{pstd}If {it:{help varelist}} is not specified, all variables are used.{p_end}
{pstd}If no functions are specified, a command-specific default is used.


{title:Explicit Syntax}

{pstd}You can also specify each result explicitly:

{phang2}{it:{help cfuncspec##cfunc:C-func}}{opt (exp details)} [{it:{help cfuncspec##cfunc:C-func}}{opt (exp details)} ...]

{pstd}Or, to save some typing, you can cross some variables and functions in an otherwise explicit list:

{phang2}{it:{help cfuncspec##cfunc:C-func}}{opt (exp details)} | {opt VxF(vars-by-funcs)} [...]

{pstd}where {it:vars-by-funcs} is the entire {bf:Vars-by-Funcs Syntax}, above.


{marker cfunc}{title:C-Func}

{pstd}{ul:{bf:Description}}

{pstd}The general theme of the {it:C-funcs} is that they act on a {bf:column} of data, in contrast with the standard {help functions}, which typically act row-by-row (ie, observation-by-observation). For example:

{phang}o-{space 2}The standard {help function} {cmd:min(a,b,c,d)} returns the minimum, in each observation, of {cmd:a}, {cmd:b}, {cmd:c}, and {cmd:d}.{p_end}
{phang}o-{space 2}The {it:C-func} {cmd:Min(a)} returns the minimum of {cmd:a} across {it:all} observations (the whole column).	

{pstd}No errors are generated for string or numeric data; however, as noted below some functions return missing for string data.{p_end}

{pstd}Except for {cmd:Nobs()} and {cmd:()}, all of the functions {it:exclude} missing values.{p_end}


{pstd}{bf:{ul:Syntax}} {hline 2} {it:Note the required {cmd:C}-apitalization}

{space 4}{it:Function{col 30}Description{col 55}String returns}
{space 4}{hline 70}
{space 4}{opt Mean(Cfexp [,options])}{col 30}mean{col 55}missing
{space 5}{opt Var(Cfexp [,options])}{col 30}variance{col 55}missing
{space 6}{opt SD(Cfexp [,options])}{col 30}standard deviation{col 55}missing
{space 5}{opt Sum(Cfexp [,options])}{col 30}sum{col 55}missing

{space 5}{opt Med(Cfexp [,options])}{col 30}median{col 55}string
{space 7}{opt P(Cfexp [,options])}{col 30}n{it:th} percentile{col 55}string
{space 5}{opt Min(Cfexp [,options])}{col 30}n{it:th} minimum{col 55}string
{space 5}{opt Max(Cfexp [,options])}{col 30}n{it:th} maximum{col 55}string

{space 7}{opt N(Cfexp [,options])}{col 30}count (ie, not missing){col 55}numeric
{space 4}{opt True(Cfexp [,options])}{col 30}not zero{col 55}missing
{space 4}{opt Uniq(Cfexp [,options])}{col 30}distinct values{col 55}numeric
{space 4}{hline 70}
{space 4}{cmd:Nobs(}{space 6}[{cmd:,}{it:options}]{cmd:)}{col 30}number of observations{col 55}{hline 2}
{space 8}{opt (Cfexp [,options])}{col 30}apply options only{col 55}string
{space 4}{hline 70}

{pstd}{opt Nobs()} takes no main parameter; it returns the relevant number of observations.
Depending on the context, that would be rows in the dataset, or in the subset selected by {ifin} and/or {opt by()} variables.

{pstd}{opt ()} can be used to apply options, such as {opt n:ame()} or {opt nl:abel()}, to a {it:Cfexp}.
Generally, if you supply a {it:Cfexp} outside of a function, it will be treated as {opt (Cfexp)} instead of causing an error.


{pstd}{bf:{ul:Standard Options}}

{phang}{opt w:eight(varname)} specifies a variable holding frequency weights.

{phang}{opt n:ame(newvarname)} specifies a variable name for the results of the function, when it will end up in a dataset (eg, {help collapsel}, {help elgen}).

{phang}{opt nl:abel(text)} specifies a variable label for the results of the function, when it will end up in a dataset (eg, {help collapsel}, {help elgen}).

{phang}{opt d:escription(text)} specifies a descriptive label for the results of the function, when it will be directly displayed (eg, {help tstats}, {help tlist}).

{phang}{opt f:ormat(format)} specifies either a standard stata {it:{help format}}, or the name of an existing variable in the dataset.
If a variable is specified, both that variable's format, and its value labels will be applied to the result, if possible.{p_end}

{pstd}All of the standard options except {opt w:eight()} are ignored when their {it:C-funcs} are nested inside other {it:C-funcs}.

{pstd}{bf:{ul:Option for Min() and Max()}}

{phang}{it:integer} specifies the position relative to the extreme. {cmd:1}, the default, is the absolute min or max. {cmd:Min(var,3)} would return the 3rd lowest value.{p_end}

{pstd}{bf:{ul:Option for P()}}

{phang}{it:integer} specifies the percentile. When not specified, it defaults to 50. {cmd:P(var,25)} would return the 25th percentile.

{pstd}{bf:{ul:Options for True() and Nobs()}}

{phang}{opt %} or {opt /} specify that the results be returned as percent or proportion, rather than count:

{phang2}For {opt True()}, the denominator is the number {ul:not missing in the cell}.

{phang2}For {opt Nobs()}, the denominator is the {ul:total number of observations for the command} {hline 1} ie, across all by-groups.



{marker cfexp}{title:Cfexp}

{pstd}A {it:Cfexp} (the main parameter for a {it:{help cfuncspec##cfunc:C-func}}) is an extension of the standard Stata {help expression}.
It can inlcude {help functions:standard functions}, nested {it:{help cfuncspec##cfunc:C-funcs}}, and the following {it:R-functions}:

{col 6}{cmd:Rsum(}{it:{help varelist}}{cmd:)}
{col 5}{cmd:Rmean(}{it:{help varelist}}{cmd:)}
{col 6}{cmd:Rmin(}{it:{help varelist}}{cmd:)}
{col 6}{cmd:Rmax(}{it:{help varelist}}{cmd:)}
{col 8}{cmd:Rn(}{it:{help varelist}}{cmd:)} {hline 2} number not missing
{col 5}{cmd:Rtrue(}{it:{help varelist}}{cmd:)} {hline 2} number not missing and not zero
{col 5}{cmd:Rvars(}{it:{help varelist}}{cmd:)} {hline 2} number of variables in {it:{help varelist}}

{pstd}{it:R-functions} act on a set of variables, row-by row. They are essentially just shortcuts;
eg, instead of writing {cmd:a1+a2+a3+a4+a5}, one might write {cmd:Rsum(a*)}.

{pstd}For evaluation, {it:R-functions} {it:are} converted into the corresponding standard expressions, and so  the usual restrictions would apply. For example, {cmd:Rmean()} of strings would cause an error.


{marker bydet}{pstd}{ul:{bf:Explicit vs VxF context}}

{pstd}The above description applies the {bf:explicit} context, in which the entire contents of the {it:{help cfuncspec##cfunc:C-func}} is specified.
In the {bf:VxF} context {hline 1} that is, after a {cmd::} {hline 1} The {it:Cfexp} must refer to the {it:{help varelist}} before the colon. It can do this in one of two ways:

{phang2}1){space 2}The {it:Cfexp} may be omitted entirely, or{p_end}
{phang2}2){space 2}a marker {hline 1} {cmd:#V} {hline 1} must be included to stand in for the actual variables.{p_end}

{pstd}For example, the {it:{help cfuncspec##cfunc:C-funcs}} below would be applied to each variable beginning with the letter {cmd:a}:

{col 9}{bf:mean and median:}{col 27}{cmd:a*: Mean() Med()}
{col 27}{cmd:a*: Mean(#V) Med(#V)}

{col 16}{bf:centered:}{col 27}{cmd:a*: #V-Mean()}
{col 27}{cmd:a*: #V-Mean(#V)}

{col 11}{bf:weighted mean:}{col 27}{cmd:a*: Mean(, weight(#V_wt))}
{col 27}{cmd:a*: Mean(#V, weight(#V_wt))}

{pstd}The last example assumes that, for each variable {cmd:aX}, the dataset includes a matching variable, {cmd:aX_wt}.

