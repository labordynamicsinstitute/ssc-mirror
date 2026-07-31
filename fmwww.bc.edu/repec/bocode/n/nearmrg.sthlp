{smcl}
{* Feb 2024} {...}
{hline}
help for {hi:nearmrg}
{hline}

{title:Title}

{p 4 8 2}{hi:nearmrg} {hline 2} Nearest match merging of datasets


{title:Syntax}

{p 4 8 2}
{cmd:nearmrg} [{it:varlist}] {cmd:using} {it:filename} {cmd:,}
{cmdab:n:earvar(}{it:nearvar_spec}{cmd:)} 
[{it:options}]

{p 4 8 2}
where {it:nearvar_spec} is {it:master_var} [{cmd:=}{it:using_var}].


{title:Description}

{p}{cmd:nearmrg} performs nearest match merging of two datasets on the values of the numeric variable {it:nearvar}. It is particularly useful for matching datasets where the merge key is not exact, such as dates, times, or rounded measurements. {p_end}

{p}The command finds the closest value in the using dataset for each observation in the master dataset, optionally within subsets defined by {it:varlist} (exact match variables). Once the nearest match is identified, it performs a standard Stata {help merge}. {p_end}


{title:Options}

{p 0 4}{cmdab:n:earvar(}{it:master_var} [{cmd:=}{it:using_var}]{cmd:)} is required. It specifies the numeric variable in the master and using datasets to be matched. If the variable has different names in the two datasets, use the {it:master_var = using_var} syntax. {p_end}

{p 0 4}{cmdab:lim:it(}{it:real}{cmd:)} specifies the maximum allowable absolute difference between the master and using values. If the nearest value exceeds this limit, no match is made for that observation. {p_end}

{p 0 4}{cmdab:low:er} matches to the closest value in the using dataset that is {it:less than or equal to} the master value. {p_end}

{p 0 4}{cmdab:up:per} matches to the closest value in the using dataset that is {it:greater than or equal to} the master value. {p_end}

{p 0 4}{cmdab:ro:undup} breaks distance ties by selecting the higher value. By default, ties are broken by selecting the lower value. {p_end}

{p 0 4}{cmdab:dist:ance(}{it:newvarname}{cmd:)} creates a new variable containing the absolute difference between the master value and the matched using value. {p_end}

{p 0 4}{cmdab:g:enmatch(}{it:newvarname}{cmd:)} creates a new variable in the master dataset containing the specific value from the using dataset that was matched. {p_end}

{p 0 4}{cmdab:type:(}{it:mergetype}{cmd:)} specifies the type of merge (1:1, m:1, 1:m, or m:m). The default is {cmd:m:1}. {p_end}

{p 0 4}{cmdab:nokeep} drops observations from the master dataset that do not find a match in the using dataset (equivalent to keeping only {cmd:_merge==3}). {p_end}

{p 0 4}{it:mergeoptions} allows any standard {help merge} options (e.g., {cmd:keepusing()}, {cmd:update}, {cmd:replace}). {p_end}


{title:Examples}

{p 4 8 2}1. Basic nearest match on price:{p_end}
{p 8 12 2}{cmd:. sysuse auto, clear}{p_end}
{p 8 12 2}{cmd:. tempfile using}{p_end}
{p 8 12 2}{cmd:. preserve}{p_end}
{p 8 12 2}{cmd:. keep if _n <= 10}{p_end}
{p 8 12 2}{cmd:. replace price = price + 10}{p_end}
{p 8 12 2}{cmd:. save `using'}{p_end}
{p 8 12 2}{cmd:. restore}{p_end}
{p 8 12 2}{cmd:. nearmrg using `using', nearvar(price) genmatch(p_matched) distance(diff)}{p_end}

{p 4 8 2}2. Nearest match within categories (exact match on foreign):{p_end}
{p 8 12 2}{cmd:. nearmrg foreign using `using', nearvar(price) limit(50)}{p_end}

{p 4 8 2}3. Different variable names in master and using:{p_end}
{p 8 12 2}{cmd:. nearmrg using "other_data.dta", nearvar(date = event_date) lower}{p_end}


{title:Author}

{p 4 4 2}Eric A. Booth{p_end}
{p 4 4 2}eric.a.booth@gmail.com{p_end}
{p 4 4 2}https://github.com/ericbooth/nearmrg-stata{p_end}

{title:Also See}

{p 4 4 2}Manual: {hi:[D] merge}{p_end}
{p 4 4 2}Online: {help merge}, {help joinby}{p_end}
