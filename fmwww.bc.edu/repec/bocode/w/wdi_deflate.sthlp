{smcl}
{* *! version 2.2.0  2026-04-03}{...}
{viewerjumpto "Syntax" "wdi_deflate##syntax"}{...}
{viewerjumpto "Description" "wdi_deflate##description"}{...}
{viewerjumpto "Formulas" "wdi_deflate##formulas"}{...}
{viewerjumpto "Examples" "wdi_deflate##examples"}{...}
{viewerjumpto "Notes" "wdi_deflate##notes"}{...}
{viewerjumpto "Stored results" "wdi_deflate##results"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:wdi_deflate} {hline 2}}Convert monetary values across PPP,
USD, and LCU using WDI deflators{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Build deflator dataset from WDI

{p 8 16 2}
{cmd:wdi_deflate build}
{cmd:,} {opt sav:ing(filename)} [{opt replace} {opt gdp} {opt count:ries(codelist)} {opt snapshot(dirname)}]


{pstd}
Convert monetary variables

{p 8 16 2}
{cmd:wdi_deflate} {varlist} [{it:if}] [{it:in}]
{cmd:,} {opt c:ountry(varname)} {opt from(#|varname)} {opt to(#)}
[{opt us:ing(filename)} {opt gdp} {opt usd} {opt def:late}
{opt fromp:pp} {opt fromu:sd}
{opt suf:fix(string)} {opt replace} {opt quiet}]


{pstd}
Describe a deflator dataset

{p 8 16 2}
{cmd:wdi_deflate describe}
{cmd:,} {opt us:ing(filename)}


{synoptset 24 tabbed}{...}
{synopthdr:build options}
{synoptline}
{p2coldent:* {opt sav:ing(filename)}}path to save the deflator .dta
file{p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synopt:{opt gdp}}use GDP PPP factor (PA.NUS.PPP) instead of private
consumption (PA.NUS.PRVT.PP){p_end}
{synopt:{opt count:ries(codelist)}}space-separated ISO3 codes to download
(e.g. {cmd:countries(ETH TZA USA)}); if omitted, downloads all
countries{p_end}
{synopt:{opt snapshot(dirname)}}save individual WDI indicator files
(ppp_factor.dta, cpi.dta, xr.dta) to {it:dirname} for archival{p_end}
{synoptline}

{synoptset 24 tabbed}{...}
{synopthdr:convert options}
{synoptline}
{p2coldent:* {opt c:ountry(varname)}}string variable containing ISO
3166-1 alpha-3 country codes (e.g. ETH, TZA, SOM){p_end}
{p2coldent:* {opt from(#|varname)}}source year of input values; an
integer for fixed year or a numeric variable for panel data{p_end}
{p2coldent:* {opt to(#)}}target reference year (e.g. 2017){p_end}
{synopt:{opt us:ing(filename)}}path to deflator dataset built by
{cmd:wdi_deflate build}; if omitted, downloads current WDI data
automatically{p_end}
{synopt:{opt gdp}}use GDP PPP factor (PA.NUS.PPP) instead of private
consumption; only relevant when {opt using()} is omitted{p_end}
{synopt:{opt usd}}convert to nominal US dollars instead of PPP
international dollars{p_end}
{synopt:{opt def:late}}deflate to constant LCU (CPI adjustment only, no
spatial conversion){p_end}
{synopt:{opt fromp:pp}}input values are already in PPP international
dollars (year {opt from()}).  With default mode, rebases to PPP$ in
year {opt to()}.  With {opt deflate}, converts to constant LCU{p_end}
{synopt:{opt fromu:sd}}input values are already in nominal USD
(year {opt from()}).  With {opt usd}, rebases to USD in year {opt to()}.
With {opt deflate}, converts to constant LCU{p_end}
{synopt:{opt suf:fix(string)}}suffix for new variables; defaults are
{bf:_ppp}{it:YYYY}, {bf:_usd}{it:YYYY}, or {bf:_real}{it:YYYY}{p_end}
{synopt:{opt replace}}replace {varlist} in place instead of generating
new variables{p_end}
{synopt:{opt quiet}}suppress diagnostic output{p_end}
{synoptline}
{p 4 6 2}* required{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:wdi_deflate} converts monetary variables between local currency
units (LCU), PPP international dollars, and nominal US dollars,
adjusting for inflation using World Development Indicators (WDI) data.
It creates new variables (or replaces existing ones) containing the
converted values.  The command handles both cross-sectional data with a
fixed source year and panel data where the source year varies by
observation.

{pstd}
By default, {cmd:wdi_deflate} downloads current WDI data automatically,
so a single command is all you need.  For replicability, use
{cmd:wdi_deflate build} to save a deflator snapshot and pass it via
{opt using()}.  Seven conversion paths are available:

{p 8 12 2}
{bf:LCU -> PPP} (default): applies temporal deflation (CPI) and spatial
conversion (PPP factor).

{p 8 12 2}
{bf:LCU -> USD} ({opt usd}): applies temporal deflation (CPI) and
converts at the official exchange rate.

{p 8 12 2}
{bf:LCU -> constant LCU} ({opt def:late}): applies CPI deflation only.

{p 8 12 2}
{bf:PPP -> PPP} ({opt fromp:pp}): rebases PPP international dollars from
one ICP round to another.  Reverses through LCU, applies CPI, then
reconverts.

{p 8 12 2}
{bf:USD -> USD} ({opt usd} {opt fromu:sd}): rebases nominal USD from one
year to another.  Reverses through LCU, applies CPI, then reconverts.

{p 8 12 2}
{bf:PPP -> LCU} ({opt fromp:pp} {opt def:late}): converts PPP
international dollars back to local currency, then deflates to constant
LCU.

{p 8 12 2}
{bf:USD -> LCU} ({opt fromu:sd} {opt def:late}): converts nominal USD
back to local currency using the exchange rate, then deflates to
constant LCU.

{pstd}
{bf:One-step} (default): {cmd:wdi_deflate} {varlist} downloads current
WDI data automatically and performs the conversion in a single command.

{pstd}
{bf:Two-step} (for replicability): {cmd:wdi_deflate build} downloads
three WDI indicators via {cmd:wbopendata} — the PPP conversion factor
(PA.NUS.PRVT.PP or PA.NUS.PPP), the consumer price index (FP.CPI.TOTL),
and the official exchange rate (PA.NUS.FCRF) — and saves them as a
snapshot.  Then {cmd:wdi_deflate} {varlist}{cmd:, using(}{it:filename}{cmd:)}
uses that snapshot for conversion, ensuring exact reproducibility even
if WDI data are later revised.


{marker formulas}{...}
{title:Formulas}

{pstd}
{ul:LCU -> PPP (default)}

{p 8 8 2}
PPP$_{it:y} = LCU x (CPI_{it:y} / CPI_{it:x}) / PPP_{it:y}

{pstd}
{ul:LCU -> USD}

{p 8 8 2}
USD_{it:y} = LCU x (CPI_{it:y} / CPI_{it:x}) / XR_{it:y}

{pstd}
{ul:LCU -> constant LCU}

{p 8 8 2}
LCU' = LCU x (CPI_{it:y} / CPI_{it:x})

{pstd}
{ul:PPP -> PPP (fromppp)}

{p 8 8 2}
PPP$_{it:y} = PPP$_{it:x} x PPP_{it:x} x (CPI_{it:y} / CPI_{it:x}) / PPP_{it:y}

{pstd}
{ul:USD -> USD (fromusd)}

{p 8 8 2}
USD_{it:y} = USD_{it:x} x XR_{it:x} x (CPI_{it:y} / CPI_{it:x}) / XR_{it:y}

{pstd}
{ul:PPP -> LCU (fromppp deflate)}

{p 8 8 2}
LCU_{it:y} = PPP$_{it:x} x PPP_{it:x} x (CPI_{it:y} / CPI_{it:x})

{pstd}
{ul:USD -> LCU (fromusd deflate)}

{p 8 8 2}
LCU_{it:y} = USD_{it:x} x XR_{it:x} x (CPI_{it:y} / CPI_{it:x})

{pstd}
where {it:x} is the source year ({opt from()}) and {it:y} is the target
year ({opt to()}), CPI is the WDI consumer price index (FP.CPI.TOTL,
base 2010=100), PPP is the conversion factor in LCU per international
dollar, and XR is the official exchange rate in LCU per US dollar
(PA.NUS.FCRF, period average).  The {opt fromppp} and {opt fromusd}
paths multiply by the source-year factor to recover LCU before applying
the standard conversion.


{marker examples}{...}
{title:Examples}

{pstd}
{ul:LCU -> 2017 PPP $ (one-step, auto-downloads WDI data)}

        {cmd:wdi_deflate consumption,}
            {cmd:country(iso3) from(2016) to(2017)}

        * Creates: consumption_ppp2017

{pstd}
{ul:LCU -> nominal USD (one-step)}

        {cmd:wdi_deflate consumption,}
            {cmd:country(iso3) from(2016) to(2017) usd}

        * Creates: consumption_usd2017

{pstd}
{ul:Build deflator for specific countries only (faster)}

        {cmd:wdi_deflate build, saving("data/deflator.dta") countries(ETH TZA USA) replace}

{pstd}
{ul:Two-step workflow for replicability}

        * Step 1: build and save a deflator snapshot
        {cmd:wdi_deflate build, saving("data/deflator.dta") replace}

        * Step 2: convert using the saved snapshot
        {cmd:wdi_deflate consumption,}
            {cmd:country(iso3) from(2016) to(2017)}
            {cmd:using("data/deflator.dta")}

{pstd}
{ul:Deflate to constant LCU}

        {cmd:wdi_deflate consumption,}
            {cmd:country(iso3) from(year) to(2017)}
            {cmd:using("data/deflator.dta") deflate}

        * Creates: consumption_real2017

{pstd}
{ul:Rebase 2011 PPP $ to 2017 PPP $}

        {cmd:wdi_deflate pov_line consumption,}
            {cmd:country(iso3) from(2011) to(2017)}
            {cmd:using("data/deflator.dta") fromppp}

        * Creates: pov_line_ppp2017, consumption_ppp2017

{pstd}
{ul:Rebase 2015 USD to 2020 USD}

        {cmd:wdi_deflate cost_usd,}
            {cmd:country(iso3) from(2015) to(2020)}
            {cmd:using("data/deflator.dta") usd fromusd}

        * Creates: cost_usd_usd2020

{pstd}
{ul:PPP international dollars -> constant LCU}

        {cmd:wdi_deflate consumption_ppp,}
            {cmd:country(iso3) from(2017) to(2020)}
            {cmd:using("data/deflator.dta") fromppp deflate}

        * Creates: consumption_ppp_real2020

{pstd}
{ul:Nominal USD -> constant LCU}

        {cmd:wdi_deflate cost_usd,}
            {cmd:country(iso3) from(2020) to(2022)}
            {cmd:using("data/deflator.dta") fromusd deflate}

        * Creates: cost_usd_real2022

{pstd}
{ul:Panel data with variable source year}

        {cmd:wdi_deflate income,}
            {cmd:country(iso3) from(year) to(2017)}
            {cmd:using("data/deflator.dta") suffix(_ppp17)}

{pstd}
{ul:Replace in place}

        {cmd:wdi_deflate consumption,}
            {cmd:country(countrycode) from(2011) to(2017)}
            {cmd:using("data/deflator.dta") fromppp replace}

{pstd}
{ul:Convert only rural observations}

        {cmd:wdi_deflate consumption if urban==0,}
            {cmd:country(iso3) from(year) to(2017)}
            {cmd:using("data/deflator.dta")}


{marker notes}{...}
{title:Notes}

{pstd}
{bf:Country codes}: {opt country()} must contain ISO 3166-1 alpha-3 codes
(e.g. ETH, TZA, SOM).  Convert with {cmd:kountry} if needed
({stata ssc install kountry}).

{pstd}
{bf:Exchange rate caveat}: The {opt usd} option uses the WDI official
exchange rate (PA.NUS.FCRF, period average).  For countries with parallel
or black-market rates, this may diverge substantially from market rates.

{pstd}
{bf:PPP rebasing}: {opt fromppp} is useful for rebasing values expressed
in PPP dollars from one ICP round to another — for example, harmonizing
cost-effectiveness thresholds or program cost benchmarks across studies
that use different PPP vintages.

{pstd}
{bf:Applying international poverty lines to survey data}: To apply a
PPP-denominated threshold (e.g. $2.15/day in 2017 PPP) to household
survey data in local currency, combine {opt fromppp} with {opt deflate}
to convert the line to constant LCU for each country.  Note that the
World Bank's international poverty lines ($1.90, $2.15, $3.00) are
independently derived as the median of national poverty lines at each
ICP round — they are not mechanical CPI/PPP rebases of one another.
Use {opt fromppp} for rebasing your own PPP$ values across ICP rounds,
not for replicating the Bank's poverty line updates.

{pstd}
{bf:Missing values}: Observations whose country-year is not found in WDI
will have missing converted values.  The diagnostic output reports the
count of such cases.

{pstd}
{bf:CPI base year}: The WDI CPI uses 2010 = 100, but since the formula
uses a CPI {it:ratio}, the base year cancels out.

{pstd}
{bf:Replicability}: The deflator .dta file is a snapshot of WDI data at
the time {cmd:build} was run.  Archive it alongside your do-file for
exact reproducibility, since re-running {cmd:build} may pull revised WDI
data (e.g., after CPI rebasing or currency reforms).  The
{opt snapshot()} option saves the raw indicator files (ppp_factor.dta,
cpi.dta, xr.dta) separately for archival.  The convert output displays
the deflator build date and data signature so you can verify which
vintage was used.

{pstd}
{bf:Country filtering}: The {opt countries()} option on {cmd:build} limits
the download to specified countries, which is much faster than a full-world
download.  When {opt using()} is omitted, the auto-download path
automatically extracts unique country codes from your data and downloads
only those countries.  If you later merge the deflator with data containing
countries not in the original download, the diagnostic output will identify
which missing countries need to be added.

{pstd}
{bf:Dependency}: {cmd:wdi_deflate build} and auto-download both require
{cmd:wbopendata}.  When {opt using()} is specified, the convert step has
no dependencies beyond the saved .dta file.


{marker indicators}{...}
{title:WDI indicators used}

{p 8 12 2}
PA.NUS.PRVT.PP — PPP conversion factor, private consumption (LCU per intl $)

{p 8 12 2}
PA.NUS.PPP — PPP conversion factor, GDP (LCU per intl $) [{opt gdp} option]

{p 8 12 2}
FP.CPI.TOTL — Consumer price index (2010 = 100)

{p 8 12 2}
PA.NUS.FCRF — Official exchange rate (LCU per US$, period average)


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:wdi_deflate} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations in scope{p_end}
{synopt:{cmd:r(miss_src)}}observations missing source-year CPI{p_end}
{synopt:{cmd:r(miss_tgt)}}observations missing target-year divisor{p_end}
{synopt:{cmd:r(to)}}target year{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(mode)}}conversion mode ({bf:ppp}, {bf:usd}, or
{bf:deflate}){p_end}
{synopt:{cmd:r(newvars)}}names of created or modified variables{p_end}


{title:References}

{pstd}
Azevedo, J.P. (2011) "wbopendata: Stata module to access World Bank
databases," Statistical Software Components S457234, Boston College
Department of Economics.
{browse "http://ideas.repec.org/c/boc/bocode/s457234.html"}


{title:Author}

{pstd}
Kalle Hirvonen, International Food Policy Research Institute (IFPRI).
{browse "mailto:k.hirvonen@cgiar.org":k.hirvonen@cgiar.org}
{p_end}
