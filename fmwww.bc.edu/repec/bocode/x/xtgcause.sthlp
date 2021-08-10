{smcl}
{* *! 29jul2017}{...}
{cmd:help xtgcause}
{hline}


{title:Title}

{p 4 18 2}
{hi:xtgcause} {hline 2} Testing for Granger causality in panel data.
{p_end}


{title:Syntax}

{p 4 12 2}
{cmd:xtgcause} {varlist}
{ifin}{cmd:,} 
[{cmdab:l:ags(}{it:lags_spec}{cmd:)}
{cmdab:reg:ress}]



{title:Description}

{pstd}
{cmd:xtgcause} allows to test for Granger non-causality in heterogeneous panels
using the procedure proposed by Dumitrescu & Hurlin (2012).


{title:Options}

{phang}{cmd:lags(}{it:lags_spec}{cmd:)} specifies the lag structure to use for the 
regressions performed in computing the test statistic. 

{pmore}
{it:lag_spec} is either a positive integer or one of aic, bic, or hqic possibly 
followed by a positive integer. 
By default, {cmd:lags(}{it:lags_spec}{cmd:)} is set to {cmd:lags(}1{cmd:)}.

{pmore}
Specifying {cmd:lags(}{it:#}{cmd:)} requests that # lag(s) of the series 
be used in the regressions. The maximum authorized number of lags is such 
that T > 5+3#.

{pmore}
Specifying {cmd:lags(}{it:aic|bic|hqic [#]}{cmd:)} requests that the number of lags of the 
series be chosen such that the average Akaike/Bayesian/Hannan-Quinn information criterion (AIC/BIC/HQIC) 
for the set of regressions is minimized. Regressions with 1 to # lags will be conducted, 
restricting the number of observations to T-# for all estimations to make the models nested 
and therefore comparable. Displayed statistics come from the set of regressions for which 
the average AIC/BIC/HQIC is minimized (re-estimated using the total number of observations available). 
If {it:#} is not specified in {cmd:lags(}{it:aic|bic|hqic [#]}{cmd:)}, then the maximum 
authorized number of lags is used.

{phang}{cmd:regress} requests that the regression results be displayed.



{title:Saved results}

{pstd}{cmd:xtgcause} saves the following results in {cmd:r()}:
{synoptset 20 tabbed}{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(wbar)}}Average Wald statistic{p_end}
{synopt:{cmd:r(lags)}}Number of lags used for the test{p_end}
{synopt:{cmd:r(zbar)}}Z-bar statistic{p_end}
{synopt:{cmd:r(pvzbar)}}P-value of the Z-bar statistic{p_end}
{synopt:{cmd:r(zbart)}}Z-bar tilde statistic{p_end}
{synopt:{cmd:r(pvzbart)}}P-value of the Z-bar tilde statistic{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(Wi)}}Individual Wald statistics{p_end}
{synopt:{cmd:r(PVi)}}P-values of the individual Wald statistics{p_end}


{title:Example}

{phang} The dataset Data_demo.xls used in this example is provided by
Dumitrescu and Hurlin at {browse "http://www.runmycode.org/companion/view/42"},
along with a few results.

{phang2}{cmd:. import excel using Data_demo.xls, clear}{p_end}
{phang2}{cmd:. ren (A-J) x#, addnumber}{p_end}
{phang2}{cmd:. ren (K-T) y#, addnumber}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. reshape long x y, i(t) j(id)}{p_end}
{phang2}{cmd:. xtset id t}{p_end}
{phang2}{cmd:. xtgcause y x, lag(1)}{p_end}


{title:References}

{pstd}
Dumitrescu E-I & Hurlin C (2012): "Testing for Granger non-causality in heterogeneous panels", 
{it:Economic Modelling}, {bf:29}: 1450-1460.

{pstd}
Lopez L & Weber S (2017): "Testing for Granger causality in panel data", 
{it:IRENE Working Paper 17-03}, Institute of Economic Research, 
University of Neuchâtel, {browse "https://ideas.repec.org/p/irn/wpaper/17-03.html"}.


{title:Authors}

{pstd}
Luciano Lopez{break}
University of Neuchâtel{break}
Institute of Economic Research{break}
Neuchâtel, Switzerland{break}
{browse "mailto:luciano.lopez@unine.ch?subject=Question/remark about -xtgcause-&cc=sylvain.weber@unine.ch":luciano.lopez@unine.ch}

{pstd}
Sylvain Weber{break}
University of Neuchâtel{break}
Institute of Economic Research{break}
Neuchâtel, Switzerland{break}
{browse "mailto:sylvain.weber@unine.ch?subject=Question/remark about -xtgcause-&cc=luciano.lopez@unine.ch":sylvain.weber@unine.ch}


{title:Acknowledgement}

{pstd}
Special thanks to Gareth Thomas for suggestions 
that led to improvements of the command.
