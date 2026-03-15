{smcl}
{* *! version 1.0  11mar2026}{...}
{viewerjumpto "Syntax" "fourierfffff##syntax"}{...}
{viewerjumpto "Description" "fourierfffff##description"}{...}
{viewerjumpto "Options" "fourierfffff##options"}{...}
{viewerjumpto "Methodology" "fourierfffff##methodology"}{...}
{viewerjumpto "Interpretation" "fourierfffff##interpretation"}{...}
{viewerjumpto "Stored results" "fourierfffff##stored"}{...}
{viewerjumpto "Examples" "fourierfffff##examples"}{...}
{viewerjumpto "References" "fourierfffff##references"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:fourierfffff} {hline 2}}Fractional Frequency Flexible Fourier Form DF test (FFFFF-DF){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fourierfffff}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:odel(#)}}deterministic specification: {cmd:1}=constant, {cmd:2}=constant+trend; default is {cmd:model(2)}{p_end}
{synopt:{opt kfmin(#)}}minimum fractional frequency; default is {cmd:kfmin(0.1)}{p_end}
{synopt:{opt kfmax(#)}}maximum fractional frequency; default is {cmd:kfmax(2.0)}{p_end}
{synopt:{opt kfstep(#)}}frequency grid step size; default is {cmd:kfstep(0.1)}{p_end}
{synopt:{opt kfr(#)}}fixed fractional frequency; default is {cmd:kfr(0)} (data-driven){p_end}
{synopt:{opt p:max(#)}}maximum lag order; default is {cmd:pmax(8)}{p_end}
{synopt:{opt ic(#)}}information criterion: {cmd:1}=AIC, {cmd:2}=SIC, {cmd:3}=t-stat; default is {cmd:ic(3)}{p_end}
{synopt:{opt notr:end}}equivalent to {cmd:model(1)}{p_end}
{synopt:{opt nof:test}}suppress the F-test for Fourier terms{p_end}
{synopt:{opt graph}}display observed vs. Fourier expansion plot{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fourierfffff} implements the Fractional Frequency Flexible Fourier Form
Dickey-Fuller (FFFFF-DF) unit root test proposed by {help fourierfffff##O2015:Omay (2015)}.
This test extends Enders and Lee (2012b) by allowing the Fourier frequency to
take {bf:fractional} (non-integer) values.

{pstd}
The key innovation is that fractional frequencies provide a more precise
approximation of the deterministic trend, leading to a better fit and increased
testing power. While integer frequencies restrict the Fourier component to complete
cycles within the sample, fractional frequencies allow partial cycles, providing
greater flexibility.

{pstd}
The data must be {cmd:tsset} before using this command.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} deterministic specification. Default is {cmd:model(2)}.

{phang}
{opt kfmin(#)} minimum value of the fractional frequency grid. Default is
{cmd:kfmin(0.1)}.

{phang}
{opt kfmax(#)} maximum value of the fractional frequency grid. Default is
{cmd:kfmax(2.0)}. Larger values allow higher-frequency cycles but may
capture noise rather than structural breaks.

{phang}
{opt kfstep(#)} step size for the frequency grid. Default is {cmd:kfstep(0.1)}.
Smaller values provide more precise frequency selection but increase computation
time.

{phang}
{opt kfr(#)} fixed fractional frequency. Default {cmd:kfr(0)} performs data-driven
selection.

{phang}
{opt pmax(#)} maximum lag order. Default is {cmd:pmax(8)}.

{phang}
{opt ic(#)} lag selection criterion. Default is {cmd:ic(3)}.

{phang}
{opt notrend} equivalent to {cmd:model(1)}.

{phang}
{opt noftest} suppresses the F-test for joint significance of Fourier terms.

{phang}
{opt graph} displays observed series vs. Fourier expansion plot.


{marker methodology}{...}
{title:Methodology}

{pstd}
The FFFFF-DF test extends the Fourier ADF framework to fractional frequencies.
The regression is identical to {cmd:fourierdf} but with k allowed to be non-integer:

{p 8 8 2}
Delta(y_t) = c_0 [+ c_1*t] + alpha*sin(2*pi*k_fr*t/T) + beta*cos(2*pi*k_fr*t/T)
             + rho*y_{t-1} + sum phi_j*Delta(y_{t-j}) + epsilon_t

{pstd}
where k_fr is a fractional frequency searched over the grid [kfmin, kfmax] with
step size kfstep. The optimal k_fr* minimizes the SSR.

{pstd}
{bf:Relationship to integer-frequency tests:} When k_fr is restricted to integers,
the FFFFF-DF test reduces to the standard Fourier ADF test. Omay (2015) shows
that relaxing this restriction can significantly improve power, especially when
the true DGP involves non-periodic smooth breaks.


{marker interpretation}{...}
{title:Interpretation}

{pstd}
{bf:Null hypothesis:} The series has a unit root.{break}
{bf:Alternative:} The series is stationary around a Fourier deterministic trend
with fractional frequency.

{pstd}
{bf:Decision rule:} Reject H0 if the FFFFF-ADF statistic is more negative than
the critical value.

{pstd}
{bf:Frequency interpretation:} k_fr < 1 indicates that the deterministic trend
involves less than one complete cycle over the sample period (a very slow shift).
k_fr = 0.5 represents a half-cycle (U-shape or inverted U-shape). Very small
values (k_fr near 0.1) approximate a monotonic smooth shift.

{pstd}
{ul:Cautions:}

{p 8 8 2}
{bf:1.} Critical values depend on the fractional frequency. Using standard ADF
or integer-frequency critical values is invalid.

{p 8 8 2}
{bf:2.} A fine grid (small kfstep) improves fit but lengthens computation. The
default kfstep(0.1) is recommended by Omay (2015).

{p 8 8 2}
{bf:3.} Check the F-test: if Fourier terms are not significant, use a standard
ADF test.


{marker stored}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ADFk)}}FFFFF-ADF test statistic{p_end}
{synopt:{cmd:r(kfr)}}optimal fractional frequency{p_end}
{synopt:{cmd:r(p)}}optimal lag order{p_end}
{synopt:{cmd:r(Fk)}}F-statistic for Fourier terms{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. sysuse gnp96, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}

{pstd}FFFFF-DF test with defaults{p_end}
{phang2}{cmd:. fourierfffff gnp96}{p_end}

{pstd}With finer frequency grid{p_end}
{phang2}{cmd:. fourierfffff gnp96, kfstep(0.05) kfmax(3)}{p_end}

{pstd}With graph{p_end}
{phang2}{cmd:. fourierfffff gnp96, graph}{p_end}


{marker references}{...}
{title:References}

{marker O2015}{...}
{phang}
Omay, T. (2015). Fractional frequency flexible Fourier form to approximate
smooth breaks in unit root testing. {it:Economics Letters}, 134, 123-126.
{p_end}

{phang}
Enders, W. and Lee, J. (2012b). The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters}, 117(1), 196-199.
{p_end}


{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}



{title:Also see}

{psee}
{space 2}Help:  {helpb fourierlm}, {helpb fourierdf}, {helpb fouriergls},
{helpb fourierkpss}, {helpb fourierdfdf}, {helpb fourierall}
{p_end}
