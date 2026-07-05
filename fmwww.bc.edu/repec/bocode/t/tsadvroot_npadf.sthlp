{smcl}
{* *! version 1.0.0  03jul2026}{...}
{viewerjumpto "Syntax" "tsadvroot_npadf##syntax"}{...}
{viewerjumpto "Description" "tsadvroot_npadf##description"}{...}
{viewerjumpto "Options" "tsadvroot_npadf##options"}{...}
{viewerjumpto "Methods" "tsadvroot_npadf##methods"}{...}
{viewerjumpto "Source compatibility" "tsadvroot_npadf##compat"}{...}
{viewerjumpto "Stored results" "tsadvroot_npadf##results"}{...}
{viewerjumpto "Examples" "tsadvroot_npadf##examples"}{...}
{viewerjumpto "References" "tsadvroot_npadf##references"}{...}
{vieweralsosee "tsadvroot" "help tsadvroot"}{...}
{vieweralsosee "tsadvroot qadf" "help tsadvroot_qadf"}{...}
{vieweralsosee "tsadvroot fqadf" "help tsadvroot_fqadf"}{...}
{vieweralsosee "tsadvroot cisur" "help tsadvroot_cisur"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{title:Title}

{phang}
{bf:tsadvroot npadf} {hline 2} Unit-root test with two structural breaks at
unknown dates (Narayan and Popp 2010)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsadvroot} {cmd:npadf} {varname} {ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:odel(string)}}{cmd:1} (M1: two breaks in the level) or
{cmd:2} (M2: two breaks in level and slope); default {cmd:model(1)}{p_end}
{synopt:{opt pm:ax(#)}}maximum lag of D.{it:varname}; default
{cmd:pmax(8)}{p_end}
{synopt:{opt ic(string)}}lag selection per break pair: {cmd:aic}, {cmd:sic}
or {cmd:tstat} (default, the source default){p_end}
{synopt:{opt tr:im(real)}}trimming fraction for the break search; default
{cmd:trim(0.10)} (the source's coded default){p_end}
{synopt:{opt gr:aph}}plot the series with the estimated break dates{p_end}
{synopt:{opt na:me(string)}}graph name{p_end}
{synopt:{opt nopr:int}}suppress the results table{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb tsset}, contiguous within the sample.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsadvroot npadf} implements the Narayan and Popp (2010) ADF-type
unit-root test allowing for two structural breaks at unknown dates. Model M1
allows two breaks in the level of a trending series; model M2 allows two
breaks in both the level and the slope. The break dates are those that
minimize the ADF t-statistic over a two-dimensional grid, and the reported
statistic is the minimized t-ratio on y_t-1. Critical values are from
Narayan and Popp (2010, Table 3) and depend on the sample size.


{marker options}{...}
{title:Options}

{phang}
{opt model(1)} (aliases {cmd:a}, {cmd:level}, {cmd:m1}) or {opt model(2)}
(aliases {cmd:c}, {cmd:both}, {cmd:m2}).

{phang}
{opt ic()}: for {it:each} candidate break pair, the lag order is re-selected
by the chosen criterion, exactly as in the source ({cmd:aic}/{cmd:sic} with
the tspdlib (k+2) penalty, {cmd:tstat} = general-to-specific with
|t| > 1.645).

{phang}
{opt trim()}: the grid runs from max(3+pmax, ceil(trim x T)) to
min(T-3-pmax, floor((1-trim) x T)), with the second break at least 2
(model 1) or 3 (model 2) periods after the first.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
For each candidate pair (TB1, TB2) the test regression is

{p 8 8 2}
D.y_t = rho y_t-1 + z_t-1' gamma + sum_j phi_j D.y_t-j + e_t

{pstd}
with z = (1, t, DU1, DU2) in M1 and z = (1, t, DU1, DU2, DT1, DT2) in M2,
where DU_i,t = 1(t > TB_i) and DT_i,t = (t - TB_i) 1(t > TB_i). Note that
the deterministic terms enter {it:lagged} (z_t-1), following the NP test
equation derived from their innovational-outlier DGP. The statistic is the
t-ratio on rho at the break pair that minimizes it.


{marker compat}{...}
{title:Source compatibility (narayan pop.src)}

{pstd}The following source conventions are reproduced exactly:{p_end}
{phang2}- the linear trend is included in {it:both} models;{p_end}
{phang2}- deterministics enter lagged one period;{p_end}
{phang2}- default trimming is 0.10 (the coded {cmd:dynargsGet} default; the
source's comment header mentions 15%, but the code default is 10%);{p_end}
{phang2}- effective grid bounds: because GAUSS symbols are case-insensitive,
{cmd:T1}/{cmd:t1} and {cmd:T2}/{cmd:t2} in the source are the same
variables; the operative bounds are T1 = max(3+pmax, ceil(trim T)) (raised
to pmax+3 if below pmax+2) and T2 = min(T-3-pmax, floor((1-trim) T));{p_end}
{phang2}- minimum separation between breaks: 2 periods in M1, 3 in
M2;{p_end}
{phang2}- lag re-selected at every break pair; AIC/SIC use the (k+2)
penalty; the reported lag is the one at the minimizing pair;{p_end}
{phang2}- critical values switch at T = 50, 200, 400 (NP Table 3).{p_end}

{pstd}
The reported break dates TB1 and TB2 are the {it:last period of the
pre-break regime}: the break dummies switch on strictly after TB.


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}minimized ADF statistic{p_end}
{synopt:{cmd:r(tb1)}, {cmd:r(tb2)}}break dates (time-variable units){p_end}
{synopt:{cmd:r(tb1pos)}, {cmd:r(tb2pos)}}break positions (1..T){p_end}
{synopt:{cmd:r(frac1)}, {cmd:r(frac2)}}break fractions{p_end}
{synopt:{cmd:r(lags)}}selected lag order at the optimum{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}critical values{p_end}
{synopt:{cmd:r(T)}}sample size{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}, {cmd:r(varname)}, {cmd:r(model)}, {cmd:r(ic)},
{cmd:r(breakdates)}}{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{phang}{cmd:. webuse air2, clear}{p_end}
{phang}{cmd:. gen lair = ln(air)}{p_end}
{phang}{cmd:. tsadvroot npadf lair, model(1) graph}{p_end}
{phang}{cmd:. tsadvroot npadf lair, model(2) pmax(4) ic(sic) trim(0.15)}{p_end}
{phang}{cmd:. di r(stat) " breaks at " r(tb1) " and " r(tb2)}{p_end}


{marker references}{...}
{title:References}

{phang}
Narayan, P. K., and S. Popp. 2010. A new unit root test with two structural
breaks in level and slope at unknown time.
{it:Journal of Applied Statistics} 37: 1425-1438.

{phang}
Narayan, P. K., and S. Popp. 2013. Size and power properties of structural
break unit root tests. {it:Applied Economics} 45: 721-728.


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}


{title:Also see}

{psee}
Help: {helpb tsadvroot}, {helpb tsadvroot_qadf}, {helpb tsadvroot_fqadf},
{helpb tsadvroot_cisur}
{p_end}
