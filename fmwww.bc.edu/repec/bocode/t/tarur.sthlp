{smcl}
{* *! version 1.0.0  14may2026}{...}
{cmd:help tarur}
{hline}

{title:Title}

{phang}
{bf:tarur} {hline 2} Nonlinear unit-root, cointegration, and linearity tests
with embedded critical values and automatic decisions.

{title:Syntax}

{p 8 14 2}
{cmd:tarur} {it:subcommand} {it:varlist} [{cmd:if}] [{cmd:in}] [{cmd:,} {it:options}]

{title:Subcommands}

{pstd}{ul:Unit-root tests}{p_end}
{synoptset 22}{...}
{synopt:{opt kss}}            KSS (2003) ESTAR test            -- tNL      {p_end}
{synopt:{opt kruse}}          Kruse (2011) modified Wald       -- {it:tau}{p_end}
{synopt:{opt sollis2009}}     Sollis (2009) AESTAR             -- F_AE    {p_end}
{synopt:{opt sollis2004}}     Sollis (2004) ST-TAR             -- F_TAR   {p_end}
{synopt:{opt huchen}}         Hu & Chen (2016)                 -- {it:tau}(3p){p_end}
{synopt:{opt endersgranger}}  Enders & Granger (1998) MTAR     -- {it:Phi}{p_end}
{synopt:{opt lnv}}            Leybourne-Newbold-Vougas (1998)  -- t_ADF   {p_end}
{synopt:{opt vougas}}         Vougas (2006) -- 5 models        -- t_ADF   {p_end}
{synopt:{opt harveymills}}    Harvey & Mills (2002)            -- t_ADF   {p_end}
{synopt:{opt cookvougas}}     Cook & Vougas (2009) ST-MTAR     -- F_MTAR  {p_end}
{synopt:{opt kilic}}          Kilic (2011) inf-t (grid)        -- inf-t   {p_end}
{synopt:{opt parkshintani}}   Park & Shintani (2016) inf-t     -- inf-t   {p_end}
{synopt:{opt pascalau}}       Pascalau (2007) NLSTAR           -- F       {p_end}
{synopt:{opt cuestasgarratt}} Cuestas & Garratt (2011)         -- chi2    {p_end}
{synopt:{opt cuestasordonez}} Cuestas & Ordonez (2014)         -- tNL     {p_end}

{pstd}{ul:Cointegration tests}{p_end}
{synopt:{opt ksscoint}}       KSS (2006) nonlinear cointegration   -- tNL  {p_end}
{synopt:{opt enderssiklos}}   Enders & Siklos (2001) TAR cointegration -- {it:Phi}{p_end}

{pstd}{ul:Linearity and diagnostics}{p_end}
{synopt:{opt terasvirta}}     Terasvirta (1994) linearity         -- F     {p_end}
{synopt:{opt arch}}           Engle (1982) ARCH LM test           -- LM    {p_end}
{synopt:{opt mcleodli}}       McLeod-Li (1983) portmanteau        -- Q     {p_end}

{pstd}{ul:Battery}{p_end}
{synopt:{opt runall}}         Run 11 unit-root tests at once, return r(results) matrix{p_end}

{title:Common options}

{synoptset 22}{...}
{synopt:{opt c:ase(string)}}   {cmd:raw} | {cmd:demeaned} | {cmd:detrended}  (default {cmd:demeaned}){p_end}
{synopt:{opt maxl:ags(#)}}     maximum augmenting lag order (default {cmd:8}){p_end}
{synopt:{opt lagm:ethod(s)}}   {cmd:aic} | {cmd:bic} | {cmd:tstat}  (default {cmd:aic}){p_end}
{synopt:{opt mod:el(letter)}}  letter model for LNV (A-C), Vougas (A-E), HM (A-C), Sollis2004 (A-C), CookVougas (A-D){p_end}
{synopt:{opt quietly}}         suppress the formatted table; still return all r() scalars{p_end}

{title:Description}

{pstd}
{cmd:tarur} provides a unified Stata interface to 20+ nonlinear unit-root,
cointegration, and linearity tests. Every test embeds the original paper's
critical values, computes automatic reject/fail-to-reject decisions at the
1%, 5%, and 10% levels, and prints a publication-style summary. The
{cmd:tarur} command is a dispatcher to one ado-file per test; you can also
call the individual commands directly (e.g.,
{cmd:tarur_kss} {it:varname}{cmd:, case(demeaned)} works the same as
{cmd:tarur kss} {it:varname}{cmd:, case(demeaned)}).
{p_end}

{pstd}
This is the Stata port of the Python {cmd:tarur} library
({browse "https://pypi.org/project/tarur/"}). Algorithms are
line-for-line ports; results match the Python reference for the
polynomial-regressor tests. NLS-based detrending (LNV, Vougas, Harvey-Mills,
Sollis 2004, Cook-Vougas, Cuestas-Ordonez) uses a fixed smooth-transition
fit in Stata rather than full nonlinear least squares.
{p_end}

{title:Saved results}

{pstd}
Every unit-root and cointegration test saves the following in {cmd:r()}:
{p_end}

{synoptset 22}{...}
{synopt:{cmd:r(stat)}}      test statistic{p_end}
{synopt:{cmd:r(cv1) r(cv5) r(cv10)}}   critical values at 1, 5, 10 %{p_end}
{synopt:{cmd:r(reject1) r(reject5) r(reject10)}}   0/1 decision flags{p_end}
{synopt:{cmd:r(lag)}}       lag order selected{p_end}
{synopt:{cmd:r(case)}}      deterministic specification used (macro){p_end}
{synopt:{cmd:r(test)}}      test name (macro){p_end}

{pstd}
Test-specific extras: {cmd:tarur kruse} returns {cmd:r(beta1)},
{cmd:r(beta2)}; {cmd:tarur sollis2009} returns {cmd:r(phi1)}, {cmd:r(phi2)},
{cmd:r(Fas)}, {cmd:r(Fas_p)}; {cmd:tarur endersgranger} returns
{cmd:r(rho_pos)}, {cmd:r(rho_neg)}, {cmd:r(F_sym)}, {cmd:r(F_sym_p)};
{cmd:tarur kilic}/{cmd:parkshintani} return {cmd:r(gamma)};
{cmd:tarur huchen} returns {cmd:r(beta3)}; etc.
{cmd:tarur runall} returns an 11-row matrix {cmd:r(results)} with columns
{it:statistic | cv1 | cv5 | cv10 | lag | r5 | r10}.
{p_end}

{title:Examples}

{phang}Create a 200-observation random walk and run KSS:{p_end}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. set seed 42}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. gen y = sum(rnormal())}{p_end}
{phang2}{cmd:. tarur kss y, case(demeaned)}{p_end}

{phang}Full nonlinear battery:{p_end}
{phang2}{cmd:. tarur runall y, case(demeaned) maxlags(12) lagmethod(aic)}{p_end}

{phang}Specific tests:{p_end}
{phang2}{cmd:. tarur kruse        y, case(demeaned)}{p_end}
{phang2}{cmd:. tarur sollis2009   y}{p_end}
{phang2}{cmd:. tarur huchen       y, case(demeaned)}{p_end}
{phang2}{cmd:. tarur vougas       y, model(C) maxlags(12)}{p_end}
{phang2}{cmd:. tarur harveymills  y, model(A)}{p_end}
{phang2}{cmd:. tarur kilic        y}{p_end}

{phang}Linearity diagnostic before running ESTAR tests:{p_end}
{phang2}{cmd:. tarur terasvirta   y}{p_end}

{phang}Cointegration tests:{p_end}
{phang2}{cmd:. gen x       = sum(rnormal())}{p_end}
{phang2}{cmd:. gen y_coint = 0.7*x + rnormal()}{p_end}
{phang2}{cmd:. tarur ksscoint     y_coint x, case(demeaned)}{p_end}
{phang2}{cmd:. tarur enderssiklos y_coint x}{p_end}

{title:Stata version}

{phang}Stata 14.0 or later.{p_end}

{title:Installation}

{pstd}{ul:From SSC (recommended once accepted)}{p_end}
{phang2}{cmd:. ssc install tarur, replace}{p_end}
{phang2}{cmd:. help tarur}{p_end}

{pstd}
SSC routes every file in the package to the user's PLUS adopath, with
files binned by their first character: the {cmd:tarur*} ado-files and
help file land in {cmd:~/ado/plus/t/}, and the Mata helper
{cmd:_tarur_mata.do} lands in {cmd:~/ado/plus/_/}. {cmd:findfile} walks
the adopath, so {cmd:tarur_init} locates the Mata helper automatically.
No manual {cmd:adopath} setup is required for SSC users.
{p_end}

{pstd}{ul:Local / development use}{p_end}
{phang2}{cmd:. adopath + "C:/path/to/tarur"}{p_end}
{phang2}{cmd:. tarur kss y, case(demeaned)}{p_end}

{pstd}
The {cmd:+} form appends to the end of the adopath, so an SSC-installed
copy in PLUS would still win — this is intentional and follows the best
practice in Baum (Stata tip on "A walk on the adopath"). Do NOT use
{cmd:adopath ++} or copy the files into PERSONAL: PERSONAL occludes PLUS,
which means an older copy in PERSONAL would shadow any
{cmd:ssc install tarur, replace} you run later. To diagnose which copy
of a {cmd:tarur} command Stata is actually using, type {cmd:which tarur}
(or {cmd:which tarur_kss}).
{p_end}

{pstd}{ul:After editing the source}{p_end}
{phang}
After modifying any {cmd:tarur_*.ado} or {cmd:_tarur_mata.do} file
in-place, run {cmd:mata: mata clear} (or {cmd:tarur_init, force}) once.
Stata's {cmd:discard} clears compiled programs but NOT Mata, so newly
edited Mata functions otherwise stay unloaded.
{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
{cmd:merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane/tarur":github.com/merwanroudane/tarur}{p_end}

{title:Citation}

{phang}
Roudane, M. (2026). TARUR: Nonlinear Unit Root Testing Library.
{browse "https://github.com/merwanroudane/tarur"}.{p_end}

{title:References}

{pstd}
Cook, S. & Vougas, D. (2009). {it:Applied Economics}, 41(11), 1397-1404.{p_end}
{pstd}
Cuestas, J.C. & Garratt, D. (2011). {it:Applied Economics}, 43(11), 1431-1437.{p_end}
{pstd}
Cuestas, J.C. & Ordonez, J. (2014). {it:Applied Economics Letters}, 21(14), 969-972.{p_end}
{pstd}
Enders, W. & Granger, C.W.J. (1998). {it:JBES}, 16(3), 304-311.{p_end}
{pstd}
Enders, W. & Siklos, P.L. (2001). {it:JBES}, 19(2), 166-176.{p_end}
{pstd}
Engle, R. (1982). {it:Econometrica}, 50(4), 987-1007.{p_end}
{pstd}
Harvey, D.I. & Mills, T.C. (2002). {it:J. Applied Statistics}, 29(5), 675-683.{p_end}
{pstd}
Hu, J. & Chen, Z. (2016). {it:Economics Letters}, 146, 89-94.{p_end}
{pstd}
Kapetanios, G., Shin, Y. & Snell, A. (2003). {it:J. Econometrics}, 112(2), 359-379.{p_end}
{pstd}
Kapetanios, G., Shin, Y. & Snell, A. (2006). {it:Econometric Theory}, 22(2), 279-303.{p_end}
{pstd}
Kilic, R. (2011). {it:Econometric Reviews}, 30(3), 274-302.{p_end}
{pstd}
Kruse, R. (2011). {it:Statistical Papers}, 52(1), 71-85.{p_end}
{pstd}
Leybourne, S., Newbold, P. & Vougas, D. (1998). {it:JTSA}, 19(1), 83-97.{p_end}
{pstd}
McLeod, A.I. & Li, W.K. (1983). {it:JTSA}, 4(4), 269-273.{p_end}
{pstd}
Park, J.Y. & Shintani, M. (2016). {it:Int. Economic Review}, 57(2), 635-664.{p_end}
{pstd}
Pascalau, R. (2007). Working paper.{p_end}
{pstd}
Sollis, R. (2004). {it:J. Time Series Analysis}, 25(3), 409-417.{p_end}
{pstd}
Sollis, R. (2009). {it:Economic Modelling}, 26(1), 118-125.{p_end}
{pstd}
Terasvirta, T. (1994). {it:JASA}, 89(425), 208-218.{p_end}
{pstd}
Vougas, D. (2006). {it:Computational Statistics & Data Analysis}, 51(2), 797-800.{p_end}
