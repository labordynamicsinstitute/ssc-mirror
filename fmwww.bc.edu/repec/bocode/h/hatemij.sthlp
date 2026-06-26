{smcl}
{* *! version 0.9.0 hatemij}{...}
{title:Title}

{phang}
{bf:hatemij} {hline 2} Hatemi-J test for cointegration with two unknown breaks


{title:Syntax}

{p 8 17 2}
{cmd:hatemij}
{depvar}
{indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt m:odel(string)}}deterministic specification: c = constant, ct = constant and trend, rs = regime shift; default {cmd:model(rs)}{p_end}
{synopt:{opt c:hoice(#)}}ADF lag selection: 1 = fixed (kmax), 2 = AIC, 3 = BIC, 4 = downward-t (1.96), 5 = downward-t (1.645), 6 = Breusch-Godfrey test based selection; default {cmd:choice(2)}{p_end}
{synopt:{opt k:max(#)}}maximum lag for the ADF test; default {cmd:kmax(12)}{p_end}
{synopt:{opt ker:nel(string)}}iid, bartlett, or qs; default {cmd:kernel(qs)}{p_end}
{synopt:{opt bwl(#)}}fixed bandwidth for the long-run variance; default is the Andrews (1991) automatic bandwidth{p_end}
{synopt:{opt tri:mming(#)}}trimming rate for the break search; default {cmd:trimming(0.15)}{p_end}
{synopt:{opt bgl:ags(#)}}Breusch-Godfrey test horizon{p_end}
{synopt:{opt reg(string)}}reports cointegrating regression and add D1, D2 and interaction terms to the dataset{p_end}
{synopt:{opt regnew:ey(string)}}as {opt reg()} but with Newey-West HAC standard errors ({cmd:newey}){p_end}
{synopt:{opt tsp:dlib}}compute the statistics with Gauss's TSPDLIB {cmd:coint_hatemiJ} routine instead of Hatemi-J's {cmd:coint2b} routine of Gauss{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
The data must be {help tsset:tsset}. {depvar} and {indepvars} must be numeric.
{indepvars} may contain at most four variables: Hatemi-J (2008) tabulates
critical values only for up to four regressors (m <= 4), so {cmd:hatemij} stops
with an error if more than four are specified.


{title:Description}

{pstd}
The {cmd:hatemij} command implements all three models of the Hatemi-J
cointegration test. It also provides a model-selection algorithm that chooses a
specification free from autocorrelation [{cmd:choice(6)} option]. This approach was previously used in the
{cmd:kapetanios} command and can also be applied through {cmd:hatemij}. The
algorithm is highly efficient and typically produces results within a few
seconds.

{pstd}
{cmd:hatemij} implements the residual-based tests for cointegration with two
unknown regime shifts proposed by Hatemi-J (2008). The deterministic part is
chosen with {opt model()}. Writing x(t) for the regressors and D1(t), D2(t) for
the two level-shift dummies (each equal to 0 before its break date and 1
afterwards, with both break dates chosen from the data), the three
specifications are:

{p 8 13 2}
{cmd:model(c)} (constant): y(t) = a0 + a1 D1(t) + a2 D2(t) + b'x(t) + u(t)

{p 8 13 2}
{cmd:model(ct)} (constant and trend): y(t) = a0 + a1 D1(t) + a2 D2(t) + g t + b'x(t) + u(t)

{p 8 13 2}
{cmd:model(rs)} (regime shift): y(t) = a0 + a1 D1(t) + a2 D2(t) + b0'x(t) + b1' D1(t) x(t) + b2' D2(t) x(t) + u(t)

{pstd}
In all three the intercept shifts at the two break dates through a1 and a2, so a
break in the level is always present. In {cmd:model(c)} that is the only break:
the constant shifts at each break date while the slope b stays the same across
the whole sample. {cmd:model(ct)} keeps the same level shifts and adds a linear
trend g t; the trend itself does not break (there is no trend-by-dummy term), so
the constant breaks but the trend does not. In {cmd:model(rs)} both the constant
and the slopes break: the interaction terms D1(t) x(t) and D2(t) x(t) move the
slope from b0 to b0 + b1 after the first break and to b0 + b1 + b2 after the
second, so each regime has its own intercept and its own slope. {cmd:model(rs)}
is the default and is the model in Hatemi-J (2008, equation 2).

{pstd}
These tests extend the single-regime-shift cointegration tests of Gregory and
Hansen (1996) to two unknown regime shifts. The three deterministic
specifications follow Gregory and Hansen's model taxonomy (level shift; level
shift with trend; regime shift), here with two breaks rather than one, while
Hatemi-J (2008) develops the regime-shift case in equation (2) and supplies new
critical values for the ADF*, Zt*, and Za* statistics.

{pstd}
Cointegration is assessed through the residual u(t) of the chosen regression.
ADF* is the t-statistic on the lagged residual in the augmented Dickey-Fuller
regression of that residual; Zt* and Za* are the Phillips (1987) statistics
built from the bias-corrected first-order autoregressive coefficient of the
residual, using a long-run-variance kernel. Each statistic is taken as the
minimum over all admissible break pairs, the null hypothesis is no
cointegration, and more negative values provide evidence against it. The
reported critical values are those of Hatemi-J (2008) and cover up to four
regressors.

{pstd}
This command is a Stata port of Hatemi-J's {cmd:coint2b} routine of Gauss.


{title:Options}

{phang}
{opt model(string)} sets the deterministic specification. {cmd:model(rs)} (regime
shift, the model in Hatemi-J 2008, eq. 2) is the default. {cmd:model(c)} uses a
constant with level shifts only; {cmd:model(ct)} adds a linear trend.

{phang}
{opt choice(#)} sets how the ADF lag length is chosen. {cmd:choice(2)} (AIC) is
the default, matching Hatemi-J's {cmd:coint2b} routine of Gauss. {cmd:choice(1)}
uses kmax lags; {cmd:choice(3)} uses BIC; {cmd:choice(4)} uses the downward-t
procedure with a 1.96 cutoff on the longest lag. {cmd:choice(5)} uses the same
downward t-stat procedure but with the 1.645 cutoff.

{pmore}
{cmd:choice(6)} selects the lag by a general-to-specific Breusch-Godfrey (BG)
procedure that targets the elimination of serial correlation: starting from kmax
and stepping down, the ADF auxiliary regression is fitted at each lag and its
residuals are tested for autocorrelation with the BG LM test of orders 1 to
{opt bglags()}; the shortest lag whose residuals are still free of
autocorrelation (smallest BG p-value at or above 0.05) is kept. If
autocorrelation cannot be removed even at kmax, kmax is used and a warning is
printed. The header reports the smallest BG p-value over orders 1 to {opt bglags()}
at the selected lag; a value at or above 0.05 indicates no autocorrelation. The
rationale is that the information-criterion rules {cmd:choice(2)} (AIC) and
{cmd:choice(3)} (BIC) minimize a fit-versus-parsimony criterion and give no
guarantee that the residuals of the selected model are free of serial
correlation, while {cmd:choice(4)} and {cmd:choice(5)} only check the
significance of the longest lag. The asymptotic distributions underlying ADF*,
Zt* and Za* require approximately white-noise residuals, so a lag chosen by AIC
or BIC can leave residual autocorrelation that distorts the test.
{cmd:choice(6)} instead selects the lag so that the Breusch-Godfrey test detects
no residual autocorrelation, making the white-noise requirement an explicit
selection target rather than a hoped-for by-product.

{phang}
{opt kmax(#)} sets the maximum number of lagged terms in the ADF
auxiliary regression. Default is 12.

{phang}
{opt kernel(string)} chooses the long-run variance estimator used for the Zt* and
Za* statistics. {cmd:kernel(qs)} (quadratic spectral) is the default for the
{cmd:coint2b} method and reproduces Hatemi-J's code; {cmd:kernel(iid)} applies no
autocovariance correction; {cmd:kernel(bartlett)} uses the Bartlett kernel.

{phang}
{opt bwl(#)} fixes the bandwidth (the number of autocovariance lags) used by the
{cmd:bartlett} and {cmd:qs} kernels. When it is not specified the default
bandwidth is the Andrews (1991) automatic value for the {cmd:coint2b} method
(1.3221(a*T)^(1/5) for {cmd:qs}, 1.1447(a*T)^(1/3) for {cmd:bartlett}, with a from
an AR(1) fit to the residuals) and round(4*(T/100)^(2/9)) for the {opt tspdlib}
method. Leaving {opt bwl()} unset therefore reproduces each reference exactly. The
option has no effect under {cmd:kernel(iid)}.

{phang}
{opt trimming(#)} sets the trimming rate t for the break search: the break dates
are searched over [t*T, (1-t)*T] and the two breaks must be at least t*T apart,
following Gregory and Hansen (1996). The default is 0.15, which reproduces
Hatemi-J's settings. The value must lie strictly between 0 and 0.5. This option
applies to both the default and the {opt tspdlib} method.

{phang}
{opt bglags(#)} sets the highest Breusch-Godfrey order tested by {cmd:choice(6)}
(BG orders 1 to {opt bglags()} are all tested and the smallest p-value is used).
It has no effect under other lag-selection rules. When it is not specified the
default follows the data frequency of {help tsset}, as in the {cmd:kapetanios}
command: 8 for quarterly, 24 for monthly, 52 for weekly, 100 for daily, and 2
otherwise (including annual series), capped at kmax*5.

{phang}
{opt reg(string)} re-runs the cointegrating regression with {cmd:regress} so the
OLS estimates can be inspected directly. {it:string} selects the break used:
{cmd:adf}, {cmd:zt}, or {cmd:za}; a bare {opt reg} uses zt. It adds the dummies
D1, D2 and, under model rs, the interactions D1_{it:var}, D2_{it:var} to the
data, overwriting any like-named variables. The {cmd:regress} command line is
printed.

{phang}
{opt regnewey(string)} is {opt reg()} with Newey-West HAC standard errors
({cmd:newey}) and truncation lag floor(4*(T/100)^(2/9)). The coefficients match
OLS; only the standard errors differ. The {cmd:newey} command line is printed.

{phang}
{opt tspdlib} computes the statistics with the TSPDLIB {cmd:coint_hatemiJ} routine
instead of {cmd:coint2b}.


{title:Examples}

{pstd}{bf:Example 1.} Replication of the output of Hatemi-J's {cmd:coint2b} routine of Gauss.{p_end}
{pstd}The data are the nelsonplosser series, regressing money on the bond yield:{p_end}
{phang2}{cmd:. use "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta", clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. hatemij m bnd, model(rs) choice(2) kmax(12)}{p_end}

{pstd}To reproduce the same numbers in Hatemi-J's GAUSS code, create a folder
named {cmd:gaussexample} on the C: drive (so its path is C:\gaussexample),
download the three files below into that folder, then open the .gss file in GAUSS
and run it (Run / F5). The GAUSS code is by Abdulnasser Hatemi-J (author of the
Hatemi-J test), available at
{browse "https://github.com/aptech/gauss-hatemij":https://github.com/aptech/gauss-hatemij}:{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/cItest2b.src":cItest2b.src}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta":nelsonplosser.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_check.gss":hatemij_gauss_check.gss}{p_end}

{pstd}Both produce the same results (model rs = regime shift, choice 2 = AIC,
kmax = 12):{p_end}

{p2colset 9 30 30 2}{...}
{p2col :{it:Statistic}}{it:Value}{p_end}
{p2col :ADF*}{cmd:-6.490912}  (lag 5; breaks 0.2676 / 0.4648){p_end}
{p2col :Zt*}{cmd:-4.389183}  (breaks 0.2394 / 0.4648){p_end}
{p2col :Za*}{cmd:-34.188667}  (breaks 0.2394 / 0.4648){p_end}
{p2colreset}{...}

{pstd}{cmd:hatemij} reproduces Hatemi-J's GAUSS output.{p_end}

{pstd}{bf:Example 2.} A four-regressor regime-shift model: Error Case{p_end}
{phang2}{cmd:. use "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta", clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. hatemij m bnd vel lrgnp lun, model(rs) choice(2) kmax(12)}{p_end}

{pstd}To reproduce the same numbers in Hatemi-J's GAUSS code, create a folder
named {cmd:gaussexample} on the C: drive (so its path is C:\gaussexample),
download the three files below into that folder, then open the .gss file in GAUSS
and run it (Run / F5). The GAUSS code is by Abdulnasser Hatemi-J (author of the
Hatemi-J test), available at
{browse "https://github.com/aptech/gauss-hatemij":https://github.com/aptech/gauss-hatemij}:{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/cItest2b.src":cItest2b.src}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta":nelsonplosser.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_error.gss":hatemij_gauss_error.gss}{p_end}

{pstd}The same test is implemented in the TSPDLIB library as {cmd:coint_hatemiJ}.
To run it, create a folder named {cmd:gaussexample} on the C: drive (so its path
is C:\gaussexample), download the two files below into that folder, then open the
.gss file in GAUSS and run it (Run / F5). This requires the TSPDLIB library to be
installed in GAUSS ({cmd:library tspdlib;}). The call uses model 3 (regime shift,
corresponding to {cmd:model(rs)} here), the Akaike criterion, twelve lags, and a
trimming rate of 0.15 (the 15 percent trimming of Hatemi-J's code; the TSPDLIB
default is 0.10):{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta":nelsonplosser.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_tspdlib.gss":hatemij_gauss_tspdlib.gss}{p_end}

{pstd}With the same 15 percent trimming, all three implementations search the
same grid and locate the same minimizing break pair, at observations 30 and 39.
Hatemi-J's GAUSS code ({cmd:coint2b}) and the TSPDLIB routine ({cmd:coint_hatemiJ})
both report the second break at observation 30, a value taken from the grid
column index rather than from the underlying break date; the two reported breaks
then coincide. For {cmd:coint2b} this makes the final cointegrating regression
singular (GAUSS returns a "matrix not positive definite" error). {cmd:hatemij}
reports the true second break at observation 39, so its cointegrating regression
is well defined and the command completes, returning ADF* = -7.985408,
Zt* = -8.051679, and Za* = -64.056591. The Zt* and Za* break locations agree
across the three implementations. The small differences in the Zt* and Za* values
come from the sample-size normalization each routine uses: {cmd:coint2b} forms
Za* as n times (rho-hat - 1) while TSPDLIB uses (n-1), and the two use n-1 versus
n-2 degrees of freedom in the Zt* variance. For this design the long-run-variance
correction is zero in both (the automatic bandwidth falls below one, so no
autocovariance terms enter), so the iid versus quadratic-spectral choice does not
contribute here.{p_end}

{pstd}{bf:Example 3.} The {opt tspdlib} option{p_end}
{phang2}{cmd:. use "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta", clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. hatemij m bnd vel lun, model(rs) choice(2) kmax(12) tspdlib}{p_end}

{pstd}To reproduce the same numbers with the TSPDLIB library, create a folder
named {cmd:gaussexample} on the C: drive (so its path is C:\gaussexample),
download the two files below into that folder, then open the .gss file in GAUSS
and run it (Run / F5). This requires the TSPDLIB library to be installed in GAUSS
({cmd:library tspdlib;}). The call uses model 3 (regime shift, corresponding to
{cmd:model(rs)} here), the Akaike criterion, twelve lags, the iid long-run
variance, and a trimming rate of 0.15 (the 15 percent trimming of Hatemi-J's
code; the TSPDLIB default is 0.10):{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta":nelsonplosser.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_tspdlib3.gss":hatemij_gauss_tspdlib3.gss}{p_end}

{pstd}Both produce the same statistics and break dates:{p_end}

{p2colset 9 30 30 2}{...}
{p2col :{it:Statistic}}{it:Value}{p_end}
{p2col :ADF*}{cmd:-7.178643}  (lag 6; breaks 1916 / 1931){p_end}
{p2col :Zt*}{cmd:-7.046005}  (breaks 1942 / 1945){p_end}
{p2col :Za*}{cmd:-58.417297}  (breaks 1942 / 1945){p_end}
{p2colreset}{...}

{pstd}{cmd:hatemij} prints ADF* = -7.178643, Zt* = -7.046005, and
Za* = -58.417297. The TSPDLIB routine prints these same statistics rounded to
three decimals (-7.179, -7.046, and -58.417) and reports the identical break
dates, so the {opt tspdlib} option reproduces TSPDLIB's {cmd:coint_hatemiJ}.{p_end}

{pstd}{bf:Example 4.} kernel and bwl options{p_end}
{phang2}{cmd:. hatemij m bnd vel lrgnp, kernel(iid)}{p_end}
{phang2}{cmd:. hatemij m bnd vel lrgnp, kernel(bartlett) bwl(8)}{p_end}
{phang2}{cmd:. hatemij m bnd vel lrgnp, trimming(0.20)}{p_end}

{pstd}Leaving {opt kernel()}, {opt bwl()}, and {opt trimming()} at their defaults
reproduces Hatemi-J's {cmd:coint2b}. The same options apply under {opt tspdlib},
where they reproduce TSPDLIB's {cmd:coint_hatemiJ} with the corresponding
{cmd:varm} and bandwidth; {opt trimming()} applies to both methods.{p_end}

{pstd}{bf:Example 5.} kernel and bwl options together with tspdlib option{p_end}
{phang2}{cmd:. use "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta", clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. hatemij m bnd vel lun, model(rs) choice(2) kmax(12) tspdlib kernel(bartlett) bwl(8)}{p_end}

{pstd}To reproduce the same numbers with the TSPDLIB library, create a folder
named {cmd:gaussexample} on the C: drive (so its path is C:\gaussexample),
download the two files below into that folder, then open the .gss file in GAUSS
and run it (Run / F5). This requires the TSPDLIB library to be installed in GAUSS
({cmd:library tspdlib;}). The call uses model 3 (regime shift, corresponding to
{cmd:model(rs)} here), the Akaike criterion, twelve lags, the Bartlett long-run
variance ({cmd:varm} = 2), a bandwidth of 8, and a trimming rate of 0.15:{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta":nelsonplosser.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_tspdlib_bart.gss":hatemij_gauss_tspdlib_bart.gss}{p_end}

{pstd}Both produce the same statistics and break dates:{p_end}

{p2colset 9 30 30 2}{...}
{p2col :{it:Statistic}}{it:Value}{p_end}
{p2col :ADF*}{cmd:-7.178643}  (lag 6; breaks 1916 / 1931){p_end}
{p2col :Zt*}{cmd:-7.043270}  (breaks 1942 / 1945){p_end}
{p2col :Za*}{cmd:-58.260282}  (breaks 1942 / 1945){p_end}
{p2colreset}{...}

{pstd}{cmd:hatemij} prints ADF* = -7.178643, Zt* = -7.043270, and
Za* = -58.260282. The TSPDLIB routine prints these same statistics rounded to
three decimals (-7.179, -7.043, and -58.260) and reports the identical break
dates. The ADF* statistic and its break dates are unchanged from the iid case
because the kernel affects only the Phillips statistics.{p_end}

{pstd}{bf:Example 6.} The quadratic spectral kernel{p_end}
{phang2}{cmd:. use "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta", clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. hatemij m bnd vel lun, model(rs) choice(2) kmax(12) tspdlib kernel(qs) bwl(8)}{p_end}

{pstd}To reproduce the same numbers with the TSPDLIB library, create a folder
named {cmd:gaussexample} on the C: drive (so its path is C:\gaussexample),
download the two files below into that folder, then open the .gss file in GAUSS
and run it (Run / F5). This requires the TSPDLIB library to be installed in GAUSS
({cmd:library tspdlib;}). The call uses model 3 (regime shift, corresponding to
{cmd:model(rs)} here), the Akaike criterion, twelve lags, the quadratic spectral
long-run variance ({cmd:varm} = 3), a bandwidth of 8, and a trimming rate of
0.15:{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/nelsonplosser.dta":nelsonplosser.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_tspdlib_qs.gss":hatemij_gauss_tspdlib_qs.gss}{p_end}

{pstd}Both produce the same statistics and break dates:{p_end}

{p2colset 9 30 30 2}{...}
{p2col :{it:Statistic}}{it:Value}{p_end}
{p2col :ADF*}{cmd:-7.178643}  (lag 6; breaks 1916 / 1931){p_end}
{p2col :Zt*}{cmd:-7.043502}  (breaks 1942 / 1945){p_end}
{p2col :Za*}{cmd:-58.273653}  (breaks 1942 / 1945){p_end}
{p2colreset}{...}

{pstd}To full precision the TSPDLIB values are -7.043502018541 and
-58.273652989658; {cmd:hatemij} agrees with them to about ten decimal places. The
break dates coincide and ADF* is unchanged from the iid case.{p_end}


{pstd}{bf:Example 7.} {cmd:choice(5)} option{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. hatemij ln_inv ln_inc, model(rs) choice(5) kmax(8) kernel(iid)}{p_end}

{pstd}{cmd:hatemij} reports:{p_end}

{p2colset 9 30 30 2}{...}
{p2col :{it:Statistic}}{it:Value}{p_end}
{p2col :ADF*}{cmd:-5.516255}  (lag 0; breaks 1966q3 / 1974q1, obs 27 / 57){p_end}
{p2col :Zt*}{cmd:-6.047909}  (breaks 1966q3 / 1973q4, obs 27 / 56){p_end}
{p2col :Za*}{cmd:-53.127385}  (breaks 1966q3 / 1973q4, obs 27 / 56){p_end}
{p2colreset}{...}

{pstd}ADF* and Za* match the TSPDLIB-style {it:n}-normalized results to the
precision those implementations report (-5.516 and -53.127).{p_end}

{pstd}{bf:A consistency check for Zt*.} The Zt* and Za* statistics are both
functions of the same estimated first-order autoregressive coefficient at the
selected break, so they must agree in sign and order of magnitude. A large
negative Za* (here -53.13) cannot occur together with a near-zero Zt* at the same
break; a pair like that (for instance Za* = -53.13 reported with Zt* = -0.53)
signals an error in the Zt* computation rather than weak evidence against the
null. {cmd:hatemij} returns Zt* = -6.047909, consistent with Za* = -53.127385.{p_end}


{pstd}{bf:Example 8.} {cmd:choice(6)} option: selecting the ADF model without autocorrelation{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. hatemij ln_inv ln_inc, model(rs) choice(6) kmax(8) kernel(iid)}{p_end}

{pstd}The header reports the lag rule and the Breusch-Godfrey result at the
selected lag, and {cmd:hatemij} returns:{p_end}
{phang2}{cmd:  Lag selection           Breusch-Godfrey GTS (bglags = 8)  (kmax = 8, selected lag = 0)}{p_end}
{phang2}{cmd:  Breusch-Godfrey         min p = 0.1905  (orders 1-8): no residual autocorrelation}{p_end}

{p2colset 9 30 30 2}{...}
{p2col :{it:Statistic}}{it:Value}{p_end}
{p2col :ADF*}{cmd:-5.548741}  (lag 0; breaks 1965q4 / 1973q4, obs 24 / 56){p_end}
{p2col :Zt*}{cmd:-6.047909}  (breaks 1966q3 / 1973q4, obs 27 / 56){p_end}
{p2col :Za*}{cmd:-53.127385}  (breaks 1966q3 / 1973q4, obs 27 / 56){p_end}
{p2colreset}{...}

{pstd}The reported min p is the smallest Breusch-Godfrey p-value over orders 1 to
{opt bglags()} at the selected lag, evaluated at the ADF* break; here it is 0.19,
so the residuals show no autocorrelation. If autocorrelation persisted at every
lag up to kmax, the largest lag would be used and a warning would be printed
alongside the (significant) min p. The value is also stored in {cmd:r(bgp)}.{p_end}


{pstd}{bf:Example 9.} AIC Lag selection{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. hatemij ln_inv ln_inc, model(rs) choice(2) kmax(12) tspdlib kernel(iid)}{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, maxlags(12) lagselection(aic)}{p_end}

{pstd}To reproduce the GAUSS results, create a folder named {cmd:gaussexample} on
the C: drive (path C:\gaussexample), download the two files below into it, and run
the .gss file in GAUSS (Run / F5) with the TSPDLIB library installed
({cmd:library tspdlib;}); the call uses model 3 (regime shift), the default
bandwidth, the Akaike criterion ({cmd:ic} = 1), twelve lags, the iid long-run
variance ({cmd:varm} = 1), and a trimming rate of 0.15:{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/lutkepohl2.dta":lutkepohl2.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_tspdlib5.gss":hatemij_gauss_tspdlib5.gss}{p_end}

{pstd}{cmd:hatemij} reports ADF* = -6.240, Zt* = -6.015 and Za* = -52.550.{p_end}
{pstd}{cmd:tspdlib} (GAUSS routine) reports ADF* = -6.240, Zt* = -6.015 and Za* = -52.550.{p_end}
{pstd}{cmd:hatemicoint} reports ADF* = -6.240, Zt* = -0.527 and Za* = -53.127.{p_end}

{pstd}{bf:Example 10.} The quadratic spectral kernel with bandwidth 8{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. hatemij ln_inv ln_inc, model(rs) choice(4) kmax(8) tspdlib kernel(qs) bwl(8)}{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, kernel(qs) bwl(8)}{p_end}

{pstd}To reproduce the GAUSS results, create a folder named {cmd:gaussexample} on
the C: drive (path C:\gaussexample), download the two files below into it, and run
the .gss file in GAUSS (Run / F5) with the TSPDLIB library installed
({cmd:library tspdlib;}); the call uses model 3 (regime shift), bandwidth 8, the
t-stat lag rule ({cmd:ic} = 3), eight lags, the quadratic spectral long-run
variance ({cmd:varm} = 3), and a trimming rate of 0.15:{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/lutkepohl2.dta":lutkepohl2.dta}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/hatemij/hatemij_gauss_tspdlib4.gss":hatemij_gauss_tspdlib4.gss}{p_end}

{pstd}{cmd:hatemij} reports ADF* = -5.516, Zt* = -6.207 and Za* = -58.690.{p_end}
{pstd}{cmd:tspdlib} (GAUSS routine) reports ADF* = -5.516, Zt* = -6.207 and Za* = -58.690.{p_end}
{pstd}{cmd:hatemicoint} reports ADF* = -5.516, Zt* = -0.525 and Za* = -53.123.{p_end}


{title:Stored results}

{pstd}{cmd:hatemij} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(adf)}}ADF* statistic (Modified ADF){p_end}
{synopt:{cmd:r(lag_adf)}}AR lag chosen at ADF*{p_end}
{synopt:{cmd:r(tb1_adf)}}first break fraction (ADF*){p_end}
{synopt:{cmd:r(tb2_adf)}}second break fraction (ADF*){p_end}
{synopt:{cmd:r(obs1_adf)}}first break observation number (ADF*){p_end}
{synopt:{cmd:r(obs2_adf)}}second break observation number (ADF*){p_end}
{synopt:{cmd:r(date1_adf)}}first break time-variable value (ADF*){p_end}
{synopt:{cmd:r(date2_adf)}}second break time-variable value (ADF*){p_end}
{synopt:{cmd:r(zt)}}Zt* statistic (Modified Phillips){p_end}
{synopt:{cmd:r(tb1_zt)}}first break fraction (Zt*){p_end}
{synopt:{cmd:r(tb2_zt)}}second break fraction (Zt*){p_end}
{synopt:{cmd:r(obs1_zt)}}first break observation number (Zt*){p_end}
{synopt:{cmd:r(obs2_zt)}}second break observation number (Zt*){p_end}
{synopt:{cmd:r(date1_zt)}}first break time-variable value (Zt*){p_end}
{synopt:{cmd:r(date2_zt)}}second break time-variable value (Zt*){p_end}
{synopt:{cmd:r(za)}}Za* statistic (Modified Phillips){p_end}
{synopt:{cmd:r(tb1_za)}}first break fraction (Za*){p_end}
{synopt:{cmd:r(tb2_za)}}second break fraction (Za*){p_end}
{synopt:{cmd:r(obs1_za)}}first break observation number (Za*){p_end}
{synopt:{cmd:r(obs2_za)}}second break observation number (Za*){p_end}
{synopt:{cmd:r(date1_za)}}first break time-variable value (Za*){p_end}
{synopt:{cmd:r(date2_za)}}second break time-variable value (Za*){p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(m)}}number of independent variables{p_end}
{synopt:{cmd:r(bgp)}}minimum Breusch-Godfrey p-value at the selected lag (choice(6) only){p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(ptable)}}parameter table (coef, std. err., t) at the Zt* break{p_end}
{synopt:{cmd:r(cv_adfzt)}}1%, 5%, 10% critical values for ADF*/Zt* (m <= 4){p_end}
{synopt:{cmd:r(cv_za)}}1%, 5%, 10% critical values for Za* (m <= 4){p_end}
{p2colreset}{...}


{title:References}

{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent
covariance matrix estimation. Econometrica 59: 817-858.

{phang}
Gregory, A. W., and B. E. Hansen. 1996. Residual-based tests for cointegration
in models with regime shifts. Journal of Econometrics 70: 99-126.

{phang}
Hatemi-J, A. 2008. Tests for cointegration with two unknown regime shifts with
an application to financial market integration. Empirical Economics 35: 497-505.

{phang}
Phillips, P. C. B. 1987. Time series regression with a unit root. Econometrica
55: 277-301.


{title:Author}

{pmore}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com":https://www.ozaneruygur.com}{break}
{browse "mailto:eruygur@gmail.com":eruygur@gmail.com}

{pmore}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{break}
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}{break}
{browse "mailto:eruygurakademi@gmail.com":eruygurakademi@gmail.com}

{pmore}
This command is a faithful Stata/Mata port of Hatemi-J's GAUSS code (coint2b).

{pmore}
hatemij v0.9.0 - June 2026

{pstd}
{ul:Please cite as:}

{phang}
Eruygur, H. O. 2026. {bf:hatemij}: Hatemi-J (2008) cointegration test with two unknown regime shifts.
Stata package version 0.9.0. Available from: {browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}
