{smcl}
{* 20Jun2022, 13Sep2020 }{...}
{hline}
help for {hi:swexp} 
{hline}

{title:piecewise exponential}

{p 4 8 2}
{cmd:swexp} 
{it:varname x}
[{cmd:if} {it:exp}] [{cmd:in} {it:range}] 
{cmd:,} 
{cmdab:g:enerate(}{it:varname y}{cmd:)}
{cmdab:tim:epoints(}{it:numlist}{cmd:)}
{cmdab:sur:vivalpoints(}{it:numlist}{cmd:)} or {cmdab:h:azardpoints(}{it:numlist}{cmd:)}
[
{cmdab:f:type(}{it:pdf , cdf , inv , lmd or lambda}{cmd:)}
{cmdab:rhr(}{it:number}{cmd:) replace }
]

{title:Description}

{p 4 8 2}{cmd:swexp} piecewise exponential distribution function defined by the time change(s) and end points listed in 
{cmdab:tim:e(}{it:numlist}{cmd:)} with the corresponding survival values of {cmdab:sur:vival(}{it:numlist}{cmd:)} 
or the failure rates of {cmdab:h:azard(}{it:numlist}{cmd:)}. 
These together define the implied failure rate or survival of each defined time interval.

{title:Options}

{p 4 8 2}{cmdab:rhr()} Relative hazard ratio of the survival. This is equal to one, by default.

{p 4 8 2} One of the following {it:function types}:{break}

{p 4 8 2} {cmdab:f:type(}{it:pdf}{cmd:)} The default, Calculates pdf: the survival, {it:y}, as a function of time, {it:x}.

{p 4 8 2} {cmdab:f:type(}{it:cdf}{cmd:)} Calculates cdf: the cumulative survival, {it:y}, as a function of time, {it:x}.

{p 4 8 2} {cmdab:f:type(}{it:inv}{cmd:)} Calculates inv: the inverse or time, {it:y}, as a function of survival, {it:x}.

{p 4 8 2} {cmdab:f:type(}{it:lmd or lambda}{cmd:)} Calculates the failure rate lambda, {it:y}, as a function of time, {it:x}.

{title:Returned matrix}

{p 4 8 2} {cmd:r(itimeS)} This is a matrix containing the defined number, time, and survival or hazard defined by the time change(s), end points, and survival or hazard values input, for verification.

{title:Examples}
{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. set obs 1025}{p_end}
{p 4 8 2}{cmd:. gen time=((_n-1)/1024)*8}{p_end}
{p 4 8 2}{cmd:. }{p_end}
{p 4 8 2}{cmd:. local tlistA `"0 1(1)4 9"'}{p_end}
{p 4 8 2}{cmd:. local slistA `"1 .8 .6 .4 .2 0.02"'}{p_end}
{p 4 8 2}{cmd:. local hlistA `"0 .22314 .28768 .40547 .69314 .46052"'}{p_end}
{p 4 8 2}{cmd:. }{p_end}
{p 4 8 2}{cmd:. pwexp time , gen(S0h) time(`tlistA') haz(`hlistA') replace}{p_end}
{p 4 8 2}{cmd:. matrix list r(itimeS)}{p_end}
{p 4 8 2}{cmd:. }{p_end}
{p 4 8 2}{cmd:. pwexp time , gen(S0) time(`tlistA') sur(`slistA')}{p_end}
{p 4 8 2}{cmd:. matrix list r(itimeS)}{p_end}
{p 4 8 2}{cmd:. }{p_end}
{p 4 8 2}{cmd:. pwexp time , gen(lamda0) f(lmd) time(`tlistA') sur(`slistA')}{p_end}
{p 4 8 2}{cmd:. pwexp time , gen(S1) rhr(`=2/3') time(`tlistA') sur(`slistA')}{p_end}
{p 4 8 2}{cmd:. pwexp time , gen(lamda1) f(lambda) rhr(`=2/3') time(`tlistA') sur(`slistA') replace}{p_end}
{p 4 8 2}{cmd:. }{p_end}
{p 4 8 2}{cmd:. twoway ///}{p_end}
{p 4 8 2}{cmd:.  (line S0 time, sort lcolor(teal)) ///}{p_end}
{p 4 8 2}{cmd:.  (line S1 time, sort lcolor(green)) ///}{p_end}
{p 4 8 2}{cmd:.  (scatter lamda0 time, sort yaxis(2) msymbol(o) msize(vtiny) mcolor(teal%100) ) ///}{p_end}
{p 4 8 2}{cmd:.  (scatter lamda1 time, sort yaxis(2) msymbol(o) msize(vtiny) mcolor(green%100) ), ///}{p_end}
{p 4 8 2}{cmd:.  yscale(range(0 1)) ylabel(0(.2)1) ytitle(probabilty) ytitle(lambda, axis(2)) xscale(range(0 5)) legend(off)}{p_end}
{p 4 8 2}{cmd:. }{p_end}
{p 4 8 2}{cmd:. gsort lamda0 time}{p_end}
{p 4 8 2}{cmd:. by lamda0: keep if inlist(_n,1,_N)}{p_end}
{p 4 8 2}{cmd:. gsort time}{p_end}
{p 4 8 2}{cmd:. list , clean noobs}{p_end}

{title:Author} 

{p 4 4 2}Allen Buxton{break}
abuxton@childrensoncologygroup.org





