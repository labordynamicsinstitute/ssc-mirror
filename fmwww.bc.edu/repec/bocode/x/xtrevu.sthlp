{smcl}
{* *! version 1.1.2  07oct2022}{...}
{viewerjumpto "Syntax" "xtrevu##syntax"}{...}
{viewerjumpto "Syntax" "xtrevu##description"}{...}
{viewerjumpto "Examples" "xtrevu##examples"}{...}
{title:Title}

{phang}
{bf:xtrevu} {hline 2} Reverse the order of values of time series and panel data
variables and/or estimate a command on them and save prediction, residuals, etc.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtrevu}
[{varlist}]
{ifin}
[{cmd:,} {it:options}]
{cmd::} {it:stata_cmd}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Value order}
{synopt:{opt replace}}replace {it:{help varlist}}{p_end}
{synopt:{opth pre:fix(strings:string)}}generate new variables from
{it:{help varlist}} with the provided prefix{p_end}

{syntab:Postestimation}
{synopt:{opth t:ype(strings:string)}}new variable
{it:{help data_types:data type}} for {helpb predict}{p_end}
{synopt:{opth x:b(strings:string)}}existing or new variable for {helpb predict}
        [{it:{help data_types:type}}] {it:{help newvar}},
        {helpb predict##single_options:xb}{p_end}
{synopt:{opth r:esiduals(strings:string)}}existing or new variable for
        {helpb predict} [{it:{help data_types:type}}] {it:{help newvar}},
        {helpb predict##single_options:residuals}{p_end}
{synopt:{opth s:tdp(strings:string)}}existing or new variable for
        {helpb predict} [{it:{help data_types:type}}] {it:{help newvar}},
        {helpb predict##single_options:stdp}{p_end}
{synopt:{opt force}}replace existing variables, specified in {bf:xb()},
        {bf:residuals()}, or {bf:stdp()}{p_end}

{syntab:Wrapper}
{synopt:{opth pre:estimation(strings:string)}}any command or program, defined
        with {cmd:program define}, including a series of commands, which will
        run prior to the model estimation{p_end}
{synopt:{opth post:estimation(strings:string)}}any command or program, defined
        with {cmd:program define}, including a series of commands, which will
        run after the model estimation{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
The user must {opt tsset} or {opt xtset} the data before using {opt xtrevu};
see {manhelp tsset TS} and {manhelp xtset XT}.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtrevu} reverses the order of values of time series and/or panel data
variables, either by substituting the original values, see {bf:replace}, or by
creating new variables with a prefixed identifier, see {bf:prefix()}. If a
"colon" command is provided, see {it: : stata_cmd} and examples, an estimation
procedure is executed on the inverted variables. The results of this estimation,
including predictions, {bf:xb()}, residuals {bf:residuals()}, and others,
{bf:stdp()}, are stored as either existing variables or new ones. Additionally,
a comprehensive post-estimation command can be executed, see
{bf:preestimation()} and {bf:postestimation()}.

{marker examples}{...}
{title:Examples}

        time series (an AP(1) model!):
        {cmd:. sysuse gnp96.dta, clear}
        {cmd:. xtrevu gnp96, prefix(rv_): arima rv_gnp96, arima(1,0,0)}

        panel data:
        {cmd:. sysuse xtline1.dta, clear}
        {cmd:. xtrevu calories, prefix(rv_)}
        {cmd:. xtrevu calories: xtreg calories day}

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
    Thanks for citing this software and my works!
