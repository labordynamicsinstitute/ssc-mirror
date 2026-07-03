{smcl}
{* *! version 1.0.1  02jul2026}{...}
{vieweralsosee "wavenardl" "help wavenardl"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{viewerjumpto "Syntax" "wdenoise##syntax"}{...}
{viewerjumpto "Description" "wdenoise##description"}{...}
{viewerjumpto "Options" "wdenoise##options"}{...}
{viewerjumpto "Examples" "wdenoise##examples"}{...}
{viewerjumpto "Stored results" "wdenoise##results"}{...}
{viewerjumpto "References" "wdenoise##references"}{...}
{viewerjumpto "Author" "wdenoise##author"}{...}

{title:Title}

{phang}
{bf:wdenoise} {hline 2} Haar "a trous" wavelet denoising of time series


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:wdenoise}
{varlist}
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt gen:erate(stub)}}stub for the new denoised variables; default is
{cmd:generate(dn)}{p_end}
{synopt:{opt replace}}overwrite the original variables instead{p_end}
{synopt:{opt lev:els(#)}}number of decomposition levels J; default is
floor(log2(N)){p_end}
{synopt:{opt thr:eshold(string)}}{cmd:soft} (default) or {cmd:hard}
thresholding{p_end}
{synopt:{opt nog:raph}}suppress the before/after graphs{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:wdenoise} denoises one or more series with the non-decimated Haar
"a trous" wavelet transform (HTW) of Murtagh, Starck & Renaud (2004):

{p 8 8 2}
s(j+1)(t) = 0.5*(s(j)(t - 2{c 94}j) + s(j)(t)),
d(j+1)(t) = s(j)(t) - s(j+1)(t)

{pstd}
The detail coefficients d(j) are thresholded with the Donoho (1995)
universal threshold lambda = sigma*sqrt(2*ln(N)), where sigma is the
median absolute deviation (MAD) of the level-1 details divided by
0.6745, and the series is reconstructed as the coarse smooth plus the
thresholded details. This is the denoising step of the wavelet-based
NARDL model of Jammazi, Lahiani & Nguyen (2015); see {helpb wavenardl}.

{pstd}
By default a new variable {it:stub}{cmd:_}{it:varname} is created for
each input variable and a before/after graph is drawn.


{marker options}{...}
{title:Options}

{phang}
{opt generate(stub)} names the new denoised variables
{it:stub}{cmd:_}{it:varname}. Default stub is {cmd:dn}.

{phang}
{opt replace} writes the denoised values back into the original
variables. May not be combined with {opt generate()}.

{phang}
{opt levels(#)} sets the number of decomposition levels J. The default
(0) uses floor(log2(N)); larger values are capped at floor(log2(N)).

{phang}
{opt threshold(string)} chooses {cmd:soft} thresholding
(sign(d)*max(|d|-lambda,0), the default) or {cmd:hard} thresholding
(d*1{c 123}|d|>=lambda{c 125}).

{phang}
{opt nograph} suppresses the before/after graphs.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. wdenoise ln_inv ln_inc}{p_end}
{phang2}{cmd:. wdenoise ln_inv, generate(s) threshold(hard) levels(4)}{p_end}
{phang2}{cmd:. wdenoise ln_inv, replace nograph}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:wdenoise} stores the following in {cmd:r()} for each variable:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(J_}{it:var}{cmd:)}}number of decomposition levels used{p_end}
{synopt:{cmd:r(sigma_}{it:var}{cmd:)}}estimated noise standard deviation{p_end}
{synopt:{cmd:r(lambda_}{it:var}{cmd:)}}universal threshold{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Donoho, D. L. (1995). De-noising by soft-thresholding.
{it:IEEE Transactions on Information Theory}, 41, 613-627.

{phang}
Jammazi, R., Lahiani, A., & Nguyen, D. K. (2015). A wavelet-based
nonlinear ARDL model for assessing the exchange rate pass-through to
crude oil prices. {it:Journal of International Financial Markets,}
{it:Institutions and Money}, 34, 173-187.

{phang}
Murtagh, F., Starck, J. L., & Renaud, O. (2004). On neuro-wavelet
modeling. {it:Decision Support Systems}, 37, 475-484.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
