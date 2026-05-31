{smcl}
{* *! version 3.0.0  29May2026}{...}
{* *! version 2.0.0  02Apr2026}{...}
{* *! version 1.0.0  12Mar2025}{...}



{title:Title}

{p2colset 5 17 18 2}{...}
{p2col :{hi:itsadgp} {hline 2}}Data generating process for interrupted time-series analysis{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:itsadgp}{cmd: ,}
{cmdab:nt:ime(}{it:integer}{cmd:)}
{cmdab:trp:eriod1(}{it:integer}{cmd:)}
{cmdab:int:ercept(}{it:#}{cmd:)}
{cmdab:pre:trend(}{it:#}{cmd:)}
{cmdab:post:trend1(}{it:#}{cmd:)}
{cmdab:st:ep1(}{it:#}{cmd:)}
{cmdab:rho1(}{it:#}{cmd:)}
[{cmdab:trp:eriod2(}{it:integer}{cmd:)}
{cmdab:trp:eriod3(}{it:integer}{cmd:)}
{cmdab:post:trend2(}{it:#}{cmd:)}
{cmdab:post:trend3(}{it:#}{cmd:)}
{cmdab:st:ep2(}{it:#}{cmd:)}
{cmdab:st:ep3(}{it:#}{cmd:)}
{cmdab:rho2(}{it:#}{cmd:)}
{cmdab:rho3(}{it:#}{cmd:)}
{cmdab:rho4(}{it:#}{cmd:)}
{cmdab:sd(}{it:#}{cmd:)}
{cmdab:seed(}{it:#}{cmd:)}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt nt:ime}{cmd:(}{it:integer}{cmd:)}}number of time periods in the series{p_end}
{p2coldent:* {opt trp:eriod1}{cmd:(}{it:integer}{cmd:)}}time period when the first intervention begins{p_end}
{p2coldent:* {opt int:ercept}{cmd:(}{it:#}{cmd:)}}starting value (intercept) of the time series{p_end}
{p2coldent:* {opt pre:trend}{cmd:(}{it:#}{cmd:)}}pre-intervention trend, expressed as a percentage of {cmd:intercept()}; see {it:Input conventions}{p_end}
{p2coldent:* {opt post:trend1}{cmd:(}{it:#}{cmd:)}}trend following the first intervention, expressed as a percentage of {cmd:intercept()}; see {it:Input conventions}{p_end}
{p2coldent:* {opt st:ep1}{cmd:(}{it:#}{cmd:)}}change in level immediately following the first intervention, expressed as a percentage of {cmd:intercept()}; see {it:Input conventions}{p_end}
{p2coldent:* {opt rho1}{cmd:(}{it:#}{cmd:)}}lag 1 autoregressive coefficient{p_end}
{synopt:{opt trp:eriod2}{cmd:(}{it:integer}{cmd:)}}time period when the second intervention begins; requires {cmd:trperiod1()}{p_end}
{synopt:{opt trp:eriod3}{cmd:(}{it:integer}{cmd:)}}time period when the third intervention begins; requires {cmd:trperiod1()} and {cmd:trperiod2()}{p_end}
{synopt:{opt post:trend2}{cmd:(}{it:#}{cmd:)}}trend following the second intervention, as a percentage of {cmd:intercept()}; requires {cmd:trperiod2()}{p_end}
{synopt:{opt post:trend3}{cmd:(}{it:#}{cmd:)}}trend following the third intervention, as a percentage of {cmd:intercept()}; requires {cmd:trperiod3()}{p_end}
{synopt:{opt st:ep2}{cmd:(}{it:#}{cmd:)}}change in level immediately following the second intervention, as a percentage of {cmd:intercept()}; requires {cmd:trperiod2()}{p_end}
{synopt:{opt st:ep3}{cmd:(}{it:#}{cmd:)}}change in level immediately following the third intervention, as a percentage of {cmd:intercept()}; requires {cmd:trperiod3()}{p_end}
{synopt:{opt rho2}{cmd:(}{it:#}{cmd:)}}lag 2 autoregressive coefficient; requires {cmd:rho1()}{p_end}
{synopt:{opt rho3}{cmd:(}{it:#}{cmd:)}}lag 3 autoregressive coefficient; requires {cmd:rho1()} and {cmd:rho2()}{p_end}
{synopt:{opt rho4}{cmd:(}{it:#}{cmd:)}}lag 4 autoregressive coefficient; requires {cmd:rho1()}, {cmd:rho2()}, and {cmd:rho3()}{p_end}
{synopt:{opt sd}{cmd:(}{it:#}{cmd:)}}standard deviation of the random error term; default is {cmd:sd(1)}{p_end}
{synopt:{opt seed}{cmd:(}{it:#}{cmd:)}}sets the random-number seed{p_end}
{synoptline}
{p 4 6 2}* {opt ntime()}, {opt trperiod1()}, {opt intercept()}, {opt pretrend()}, {opt posttrend1()}, {opt step1()}, {opt rho1()} are required.{p_end}
{p2colreset}{...}



{title:Description}

{pstd}
{cmd:itsadgp} generates a single artificial interrupted time series using the specifications provided by the user, including autoregressive 
error terms up to order 4. It supports up to three sequential intervention periods, following the single-group multiple-intervention model of Linden (2017).

{pstd}
{cmd:itsadgp} replaces the data in memory. Save your data before calling this command.



{title:Options}

{phang}
{cmd:ntime(}{it:integer}{cmd:)} specifies the total number of time periods; required.

{phang}
{cmd:trperiod1(}{it:integer}{cmd:)} specifies the time period at which the first intervention begins. The time variable is 0-indexed, 
so {cmd:trperiod1(30)} means the intervention starts at observation 31; required.

{phang}
{cmd:intercept(}{it:#}{cmd:)} specifies the starting value of the series. Corresponds to {it:β{subscript:0}}; required.

{phang}
{cmd:pretrend(}{it:#}{cmd:)} specifies the pre-intervention trend as a percentage of {cmd:intercept()}. The absolute 
slope is {cmd:intercept()} × {cmd:pretrend()} / 100; required.

{phang}
{cmd:step1(}{it:#}{cmd:)} specifies the immediate change in level at the first intervention as a percentage of 
{cmd:intercept()}. The absolute level jump is {cmd:intercept()} × {cmd:step1()} / 100. Use {cmd:step1(0)} for no immediate level change; required.

{phang}
{cmd:posttrend1(}{it:#}{cmd:)} specifies the trend in the period following the first intervention as a percentage 
of {cmd:intercept()}. The slope-change coefficient entered into the DGP is b_post1 − b_pre; required.

{phang}
{cmd:trperiod2(}{it:integer}{cmd:)} specifies the time period at which the second intervention begins. Must be greater 
than {cmd:trperiod1()} and less than {cmd:ntime()}.

{phang}
{cmd:trperiod3(}{it:integer}{cmd:)} specifies the time period at which the third intervention begins. Must be greater 
than {cmd:trperiod2()} and less than {cmd:ntime()}. Requires {cmd:trperiod2()}.

{phang}
{cmd:step2(}{it:#}{cmd:)}, {cmd:step3(}{it:#}{cmd:)} specify immediate level changes at the second and third 
interventions, as percentages of {cmd:intercept()}.

{phang}
{cmd:posttrend2(}{it:#}{cmd:)}, {cmd:posttrend3(}{it:#}{cmd:)} specify post-intervention trends at the second and third 
intervention periods, as percentages of {cmd:intercept()}.

{phang}
{cmd:rho1(}{it:#}{cmd:)} specifies the lag 1 autoregressive coefficient. All |{it:ρ}| must be < 1; required.

{phang}
{cmd:rho2(}{it:#}{cmd:)}, {cmd:rho3(}{it:#}{cmd:)}, {cmd:rho4(}{it:#}{cmd:)} extend the error process to AR(2), AR(3), 
and AR(4). Each requires the lower-order coefficients to also be specified. To include a zero coefficient at an intermediate lag, use (e.g.) {cmd:rho2(0)}.

{phang}
{cmd:sd(}{it:#}{cmd:)} specifies the standard deviation of the innovation {it:u{subscript:t}} ~ N(0, {cmd:sd}²). Default is {cmd:sd(1)}.

{phang}
{cmd:seed(}{it:#}{cmd:)} sets the random-number seed for replication.



{title:Examples}

{pstd}Single intervention, AR(1). Pre-trend 10% of intercept per period, flat post-trend (0%){p_end}

{phang2}{cmd:. itsadgp, ntime(100) trperiod1(50) intercept(10) pretrend(10) posttrend1(0) step1(0) rho1(0.5) sd(1) seed(12345)}{p_end}
{phang2}{cmd:. itsa y, single trperiod(50) posttrend lag(1) fig}{p_end}

{pstd}Single intervention, flat baseline then rising trend. pretrend(0); 2% posttrend {p_end}

{phang2}{cmd:. itsadgp, ntime(100) trperiod1(50) intercept(10) pretrend(0) posttrend1(2) step1(0) rho1(0.4) seed(12345)}{p_end}
{phang2}{cmd:. itsa y, single trperiod(50) posttrend lag(1) fig}{p_end}

{pstd}Two sequential interventions. Pre-slope = 5%, post1-slope = 10%, post2-slope = 20% (steep increase){p_end}

{phang2}{cmd:. itsadgp, ntime(90) trperiod1(30) trperiod2(60) intercept(10) pretrend(5) posttrend1(10) step1(0) posttrend2(20) step2(0) rho1(0.4) seed(12345)}{p_end}
{phang2}{cmd:. itsa y, single trperiod(30;60) posttrend lag(1) fig}{p_end}

{pstd}Complete washout design. Middle period flattens out, third period has steeper slope{p_end}

{phang2}{cmd:. itsadgp, ntime(90) trperiod1(30) trperiod2(60) intercept(10) pretrend(10) posttrend1(0) step1(0) posttrend2(10) step2(0) rho1(0.4) seed(12345)}{p_end}
{phang2}{cmd:. itsa y, single trperiod(30;60) posttrend lag(1) fig}{p_end}

{pstd}Level change at intervention. step1(30) gives an immediate jump of 3.0 units (i.e. 30% increase versus counterfactual at that timepoint){p_end}

{phang2}{cmd:. itsadgp, ntime(100) trperiod1(50) intercept(10) pretrend(5) posttrend1(5) step1(30) rho1(0.3) seed(12345)}{p_end}
{phang2}{cmd:. itsa y, single trperiod(50) posttrend lag(1) fig}{p_end}

{pstd}AR(2) error process{p_end}

{phang2}{cmd:. itsadgp, ntime(100) trperiod1(50) intercept(10) pretrend(5) posttrend1(15) step1(0) rho1(0.4) rho2(0.2) seed(12345)}{p_end}
{phang2}{cmd:. itsa y, single trperiod(50) posttrend lag(2) fig}{p_end}

{pstd}Multiple-group ITSA (treatment and control, two interventions){p_end}

{pmore2}{cmd:. itsadgp, ntime(90) trperiod1(30) trperiod2(60) intercept(10) pretrend(10) posttrend1(2) step1(0) posttrend2(20) step2(0) rho1(0.4) seed(12345)}{p_end}
{pmore2}{cmd:. gen z = 1}{p_end}
{pmore2}{cmd:. gen id = 1}{p_end}
{pmore2}{cmd:. tempfile treated}{p_end}
{pmore2}{cmd:. save `treated'}{p_end}
{pmore2}{cmd:. }{p_end}
{pmore2}{cmd:. itsadgp, ntime(90) trperiod1(30) trperiod2(60) intercept(10) pretrend(10) posttrend1(10) step1(0) posttrend2(10) step2(0) rho1(0.4)}{p_end}
{pmore2}{cmd:. gen z = 0}{p_end}
{pmore2}{cmd:. gen id = 2}{p_end}
{pmore2}{cmd:. append using `treated'}{p_end}
{pmore2}{cmd:. tsset id t}{p_end}
{pmore2}{cmd:. itsa y, treat(1) trperiod(30;60) posttrend lag(1) fig}{p_end}



{title:References}

{phang}
Linden, A. 2015.
{browse "http://www.stata-journal.com/article.html?article=st0389":Conducting interrupted time series analysis for single and multiple group comparisons}.
{it:Stata Journal}.
15: 480-500.

{phang}
---------. 2017.
{browse "http://www.stata-journal.com/article.html?article=st0389_3":A comprehensive set of postestimation measures to enrich interrupted time-series analysis}.
{it:Stata Journal}
17: 73-88.

{phang}
---------. 2022.
{browse "https://journals.sagepub.com/doi/full/10.1177/1536867X221083929":Erratum: A comprehensive set of postestimation measures to enrich interrupted time-series analysis}.
{it:Stata Journal}
22: 231-233. 

{phang}
---------. 2025. 
{browse "https://journals.sagepub.com/doi/10.1177/01632787251361514":A comprehensive simulation study to evaluate the effect size and study length relationship in single-group interrupted time series analysis}. 
{it:Evaluation & the Health Professions} 

{phang}
---------. 2026. 
{browse "https://journals.sagepub.com/doi/10.1177/01632787261428159?int.sj-abstract.similar-articles.4":Power considerations for multiple-group (controlled) interrupted time series analysis: A comprehensive simulation Study}.
{it:Evaluation & the Health Professions} 

{phang}
---------. 2026. 
{browse "https://doi.org/10.21203/rs.3.rs-8865851/v1":Adjustment for autocorrelation in multiple-group (controlled) interrupted time series analysis and its effect on power: A simulation study of the Newey-West and Prais-Winsten methods}. 
Preprint. Research Square. 

{phang}
---------. 2026.
{browse "https://arxiv.org/abs/2603.24814":Multiple-group (controlled) interrupted time series analysis with higher-order autoregressive errors: A simulation study comparing Newey–West and Prais–Winsten methods}. 
Preprint. arXiv 



{title:Citation of {cmd:itsadgp}}

{p 4 8 2}{cmd:itsadgp} is not an official Stata command. It is a free contribution to the research community, like a paper. Please cite it as such:{p_end}

{p 4 8 2}
Linden A. (2025). ITSADGP: Stata module to generate artificial data for interrupted time-series analysis. Statistical Software Components S459403, Boston College Department of Economics.



{title:Author}

{pstd}Ariel Linden{p_end}
{pstd}alinden@lindenconsulting.org{p_end}



{p 7 14 2}Help: {helpb itsa} (if installed), {helpb power_itsa} (if installed){p_end}
