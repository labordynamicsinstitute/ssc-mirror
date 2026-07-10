{smcl}
{* *! version 1.0.0  09jul2026}{...}
{vieweralsosee "urvol wbdf" "help urvol_wbdf"}{...}
{vieweralsosee "urvol beare" "help urvol_beare"}{...}
{vieweralsosee "urvol bzu" "help urvol_bzu"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "pperron" "help pperron"}{...}
{vieweralsosee "dfgls" "help dfgls"}{...}
{viewerjumpto "Syntax" "urvol##syntax"}{...}
{viewerjumpto "Description" "urvol##description"}{...}
{viewerjumpto "The three tests" "urvol##tests"}{...}
{viewerjumpto "Options" "urvol##options"}{...}
{viewerjumpto "Examples" "urvol##examples"}{...}
{viewerjumpto "Stored results" "urvol##results"}{...}
{viewerjumpto "References" "urvol##references"}{...}
{viewerjumpto "Author" "urvol##author"}{...}
{title:Title}

{phang}
{bf:urvol} {hline 2} Unit-root tests robust to non-stationary (time-varying) volatility

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:urvol} {it:subcommand} {varname} {ifin} {cmd:,} [{it:options}]

{synoptset 20}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb urvol_wbdf:wbdf}}wild-bootstrap (augmented) Dickey-Fuller / Phillips-Perron test{p_end}
{synopt:{helpb urvol_beare:beare}}Beare (2017) kernel-rescaled Phillips-Perron test{p_end}
{synopt:{helpb urvol_bzu:bzu}}Boswijk & Zu (2018) adaptive wild-bootstrap likelihood-ratio test{p_end}
{synopt:{opt all}}run the three tests and print a comparison table{p_end}
{synoptline}

{p 4 6 2}
{it:varname} must be a single time series that has been {helpb tsset}.  The data
must {ul:not} be {helpb xtset} as a panel.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:urvol} implements a family of unit-root tests designed to remain valid, and
to gain power, when the innovation variance is {it:not} constant over the sample
{it:{c 45}}{it:the "unstable" or "non-stationary" volatility} case.  Permanent
changes in variance (level shifts, trends in variance, smooth transitions,
integrated volatility) are pervasive in macroeconomic and financial time series
(exchange rates, interest rates, output, asset prices).  As Cavaliere (2004)
shows, such variance dynamics make the standard Dickey{c 45}Fuller (DF) and
Phillips{c 45}Perron (PP) tests {bf:size-distorted}: an early negative or late
positive variance change can push the empirical rejection frequency well above
(or below) the nominal level, invalidating the usual critical values.

{pstd}
The reference data-generating process is the heteroskedastic first-order
autoregression

{p 8 8 2}{it:X(t) = alpha X(t-1) + u(t)},{p_end}
{p 8 8 2}{it:u(t) = sigma(t) e(t)},{p_end}

{pstd}
where the {it:variance profile} obeys {it:sigma([sT]) = omega(s)} for a bounded,
square-integrable function {it:omega({c 46})} with finitely many jumps (Cavaliere
2004, Assumption V).  Under this profile the DF statistic converges to a functional
of a {it:variance-transformed} Brownian motion rather than a standard Brownian
motion {c 45} which is exactly why the classical tables fail.  The three
{cmd:urvol} subcommands are the three leading remedies in the literature.

{marker tests}{...}
{title:The three tests}

{synoptset 12 tabbed}{...}
{synopt:{helpb urvol_wbdf:wbdf}}{it:Wild-bootstrap (A)DF/PP} (Cavaliere & Taylor 2008, 2009).
Computes the usual (A)DF t- or coefficient statistic, then obtains its
{it:p}-value from a {bf:wild bootstrap} that reproduces the sample volatility
pattern.  Corrects the size distortion of DF/PP but does not reweight the data,
so power is similar to DF.  The robust {bf:baseline}.{p_end}

{synopt:{helpb urvol_beare:beare}}{it:Rescaled Phillips-Perron} (Beare 2017).
Rescales the increments by a Nadaraya{c 45}Watson kernel estimate of the
volatility path, {it:omega-hat(s/n)}, and applies a PP test to the cumulated,
rescaled series.  In the constant-mean case the rescaled statistic recovers the
{bf:standard} DF/PP null distribution, so ordinary critical values apply.{p_end}

{synopt:{helpb urvol_bzu:bzu}}{it:Adaptive wild-bootstrap LR} (Boswijk & Zu 2018).
Non-parametrically estimates the volatility path {it:sigma-hat(t)} (double-sided
exponential kernel, window chosen by cross-validation), forms a
{bf:variance-weighted} GLS-detrended likelihood-ratio statistic that attains the
Gaussian {bf:power envelope}, and gets its {it:p}-value from the wild bootstrap.
The {bf:most powerful} member under non-stationary volatility.{p_end}
{synoptline}

{pstd}
All three share the null H0: {it:a unit root} (alpha = 1) and are lower-tailed
(reject for large negative statistics).  See {helpb dfuller}, {helpb pperron}
and {helpb dfgls} for the classical, homoskedastic counterparts.

{marker options}{...}
{title:Common options}

{phang}
{opt trend} includes a constant and a linear trend in the deterministic component
(the default is a constant only); {opt noconstant} removes the constant.

{phang}
{opt reps(#)} sets the number of bootstrap replications (default 999).

{phang}
{opt seed(#)} sets the random-number seed for reproducibility of the bootstrap.

{pstd}
Subcommand-specific options (lag order, kernel bandwidth, volatility window,
GLS constant, graphing) are documented on the individual help pages linked above.

{marker examples}{...}
{title:Examples}

{pstd}Set up a single time series:{p_end}
{phang2}{cmd:. webuse wpi1}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Run the whole family at once:{p_end}
{phang2}{cmd:. urvol all ln_wpi, trend}{p_end}

{pstd}Individual tests with graphs:{p_end}
{phang2}{cmd:. urvol wbdf ln_wpi, trend reps(999) graph}{p_end}
{phang2}{cmd:. urvol beare ln_wpi, trend bandwidth(0.1) graph}{p_end}
{phang2}{cmd:. urvol bzu ln_wpi, trend graph}{p_end}

{pstd}A financial series with obvious volatility clustering:{p_end}
{phang2}{cmd:. webuse sp500}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen lclose = ln(close)}{p_end}
{phang2}{cmd:. urvol all lclose}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
Each subcommand is {cmd:rclass} and returns its statistic and bootstrap
{it:p}-value; see the individual help pages for the full list.  {cmd:urvol all}
additionally returns:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}3 x 2 matrix of (statistic, p-value) for wbdf/beare/bzu{p_end}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(p_wbdf)}, {cmd:r(p_beare)}, {cmd:r(p_bzu)}}bootstrap p-values{p_end}

{marker references}{...}
{title:References}

{phang}
Beare, B. K. 2017. Unit root testing with unstable volatility.
{it:Journal of Time Series Analysis} 39(6): 816-835.
{browse "https://doi.org/10.1111/jtsa.12279":doi:10.1111/jtsa.12279}.

{phang}
Boswijk, H. P., and Y. Zu. 2018. Adaptive wild bootstrap tests for a unit root
with non-stationary volatility. {it:Econometrics Journal} 21(2): 87-113.
{browse "https://doi.org/10.1111/ectj.12100":doi:10.1111/ectj.12100}.

{phang}
Cavaliere, G. 2004. Unit root tests under time-varying variances.
{it:Econometric Reviews} 23(3): 259-292.
{browse "https://doi.org/10.1081/ETC-200028215":doi:10.1081/ETC-200028215}.

{phang}
Cavaliere, G., and A. M. R. Taylor. 2008. Bootstrap unit root tests for time
series with non-stationary volatility. {it:Econometric Theory} 24(1): 43-71.

{phang}
Cavaliere, G., and A. M. R. Taylor. 2009. Heteroskedastic time series with a
unit root. {it:Econometric Theory} 25(5): 1228-1276.

{phang}
Elliott, G., T. J. Rothenberg, and J. H. Stock. 1996. Efficient tests for an
autoregressive unit root. {it:Econometrica} 64(4): 813-836.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}{p_end}
