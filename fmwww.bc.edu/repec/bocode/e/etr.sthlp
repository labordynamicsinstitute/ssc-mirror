{smcl}
{* *! version 1.0.0 26Jan2026}{...}
{viewerjumpto "Syntax" "etr##syntax"}{...}
{viewerjumpto "Menu" "etr##menu"}{...}
{viewerjumpto "Description" "etr##description"}{...}
{viewerjumpto "Macroeconomic Parameters" "etr##macro"}{...}
{viewerjumpto "General Tax Parameters" "etr##tax"}{...}
{viewerjumpto "Project-Specific Parameters" "etr##project"}{...}
{viewerjumpto "Pillar Two Parameters" "etr##pillar_two"}{...}
{viewerjumpto "Examples" "etr##examples"}{...}

{p2col:{bf:etr}}etr — Forward-looking effective tax rates on investment

{hline}
{marker menu}{...}
{title:Menu}

    {help etr##description:Description}
    {help etr##syntax:Syntax}
    {help etr##macro:Macroeconomic Parameters}
    {help etr##tax:General Tax Parameters}
    {help etr##project:Project-Specific Parameters}
    {help etr##pillar_two:Pillar Two Parameters}
    {help etr##examples:Examples}
    {help etr##reference:Reference}

{hline}
{marker description}{...}
{title:Description}

{pstd}
{cmd:etr} computes the cost of capital and the forward-looking average and
marginal effective tax rates (AETR and METR) for a stylized investment. It produces a dataset containing (at minimum)
{it:statutory_tax_rate} (the statutory corporate income tax rate),
{it:coc} (the cost of capital),
{it:aetr} (the average effective tax rate),
{it:metr} (the marginal effective tax rate with the cost of capital as the denominator),
and {it:metr2} (the marginal effective tax rate with the real interest rate as the denominator). The implementation follows Hebous and Mengistu (2026).

{pstd}
{cmd:etr} replaces the dataset in memory with a results dataset
(viewable in the Data Browser) and prints a parameter summary in the
Results window documenting the assumptions used in the computation. These assumptions can be modified via the command’s options.

{hline}
{marker syntax}{...}
{title:Syntax}

{p 4}
{cmd:etr}{cmd:,} [{it:options}]

{pstd}
{cmd:etr} may be run without any options. In that case, all parameters take their
default values. Users can override defaults through the options listed below.

{hline}
{marker macro}{...}
{title:Macroeconomic Parameters}

{pstd}
Unless otherwise stated, all rates should be entered in decimal form
(e.g., 15% = {bf:0.15}).

{synoptset 30 tabbed}
{synopthdr}
{synoptline}
{synopt:{opth inflation:(real)}} Inflation rate. Default: {bf:0.05}. {p_end}
{synopt:{opth realint:(real)}} Real interest rate. Default: {bf:0.05}. {p_end}

{hline}
{marker project}{...}
{title:Project-Specific Parameters}

{synoptset 30 tabbed}
{synopthdr}
{synoptline}
{synopt:{opth p:(real)}} Profitability of the investment (share of economic rent). Default: {bf:0.2}. {p_end}
{synopt:{opth debt:(real)}} Share of investment financed by debt (0–1). Default: {bf:0}. {p_end}
{synopt:{opth newequity:(real)}} Share financed by new equity (0–1). Default: {bf:0}. {p_end}
{synopt:{opth superdeduction:(real)}} Super-deduction applied to the acquisition cost of capital (e.g., 0.5 = 150% deduction). Default: {bf:0}. Valid range: 0–1.5. {p_end}
{synopt:{opth holiday:(real)}} Duration of tax holiday (years). Default: {bf:0}. {p_end}
{synopt:{opth credit:(real)}} Pre-tax credit in each period as a share of the original investment, independent of the tax rate (i.e., net-of-tax value equals the pre-tax amount). Default: {bf:0}. {p_end}
{synopt:{opth taxcredit:(real)}} Tax-rate-dependent credit in each period as a share of the original investment (i.e., post-tax value depends on the statutory tax rate). Default: {bf:0}. {p_end}


{hline}
{marker tax}{...}
{title:General Tax Parameters}

{synoptset 30 tabbed}
{synopthdr}
{synoptline}

{syntab:Corporate Income Tax}
{synopt:{opth system:(string)}} Corporate tax system:
{bf:cit} (default), {bf:cft} (cash-flow tax), or {bf:ace} (allowance for corporate equity). {p_end}
{synopt:{opth depreciation:(real)}} Statutory tax depreciation rate. Default: {bf:0.25}. {p_end}
{synopt:{opth delta:(real)}} Economic depreciation rate. Default: {bf:0.25}. {p_end}
{synopt:{opth deprtype:(string)}} Depreciation method.
{bf:db} (declining balance, default) or {bf:sl} (straight line).
If {bf:minimumtax=no}, the following additional methods are allowed:
{bf:initialDB} (initial allowance followed by declining balance),
{bf:initialSL} (initial allowance followed by straight line), and
{bf:SLorDB} (maximum of straight-line or declining-balance allowance).
If {bf:minimumtax=yes}, only {bf:db} and {bf:sl} are permitted. {p_end}
{synopt:{opth inal:(varname numeric)}} Initial allowance.
Required when {bf:deprtype} is {bf:initialSL} or {bf:initialDB} and {bf:minimumtax=no}.
The variable specified in {bf:inal()} represents the fraction of the asset’s cost that is immediately deductible in period 0 (0 ≤ inal ≤ 1).
If {bf:minimumtax=yes}, {bf:inal()} is not permitted and initial depreciation schemes are disallowed. {p_end}

{hline}
{marker pillar_two}{...}
{title:Pillar Two Parameters}

{synoptset 30 tabbed}
{synopthdr}
{synoptline}
{synopt:{opth minimumtax:(string)}} Include Pillar Two top-up? {bf:no} (default) or {bf:yes}. {p_end}
{synopt:{opth minrate:(real)}} Pillar Two minimum effective tax rate. Default: {bf:0.15}. {p_end}
{synopt:{opth carveout:(real)}} Carve-out rate applied to the SBIE base for tangible assets and payroll (e.g., 0.05 = 5%). Default: {bf:0.05}. {p_end}
{synopt:{opth qtil:(real)}} Qualified tax incentive expressed as a share of payroll. Must lie in the interval [0,1]. Default: {bf:0}. {p_end}
{synopt:{opth qtik:(real)}} Qualified tax incentive expressed as a share of capital depreciation. Must lie in the interval [0,1]. Default: {bf:0}. {p_end}
{synopt:{opth sl:(real)}} Maximum qualified tax incentive expressed as a multiple of payroll (e.g., 0.05 = 5%). Default: {bf:0.055}. {p_end}
{synopt:{opth slk:(real)}} Maximum qualified tax incentive expressed as a multiple of depreciation (e.g., 0.05 = 5%). Default: {bf:0.055}. {p_end}
{synopt:{opth beta:(real)}} Capital share in the Cobb–Douglas production function. Default: {bf:0.4}. {p_end}

{hline}

{syntab:Personal Income Tax}
{synopt:{opth pitint:(real)}} Personal tax rate on interest income. Default: {bf:0}. {p_end}
{synopt:{opth pitdiv:(real)}} Personal tax rate on dividend income. Default: {bf:0}. {p_end}
{synopt:{opth pitcgain:(real)}} Personal tax rate on capital gains. Default: {bf:0}. {p_end}



{hline}
{marker examples}{...}
{title:Examples}

* Example 1: Average and marginal effective tax rates for an equity-financed project
*            using default parameters
{pstd}{cmd:. etr}{p_end}

* Example 2: Average and marginal effective tax rates with non-default assumptions
*            on inflation, tax depreciation, economic depreciation, and financing
{pstd}{cmd:. etr, inflation(0.03) depreciation(0.1) delta(0.12) debt(0.5)}{p_end}

* Example 3: Average and marginal effective tax rates with non-default assumptions
*            on inflation, tax depreciation, economic depreciation, financing,
*            and personal income tax rates
{pstd}{cmd:.etr, inflation(0.03) depreciation(0.1) delta(0.12) debt(0.5) pitint(0.10) pitdiv(0.12) pitcgain(0.15)}{p_end}

* Example 4: Average and marginal effective tax rates for an equity-financed project
*            under a cash-flow tax system
{pstd}{cmd:.etr, system(cft)}{p_end}

* Example 5: Average and marginal effective tax rates for an equity-financed project
*            under a minimum tax regime with default parameters
{pstd}{cmd:.etr, minimumtax(yes)}{p_end}

* Example 6: Average and marginal effective tax rates under a minimum tax regime
*            with non-default assumptions on inflation, depreciation, and financing
{pstd}{cmd:.etr, inflation(0.04) depreciation(0.1) delta(0.12) debt(0.5) minimumtax(yes)}{p_end}

* Example 7: Average and marginal effective tax rates for an equity-financed project
*            under a minimum tax regime with a qualified tax incentive equal to
*            50% of payroll expense
{pstd}{cmd:.etr, minimumtax(yes) qtil(0.5)}{p_end}

* Example 8: Average and marginal effective tax rates for an equity-financed project
*            under a minimum tax regime with a qualified tax incentive equal to
*            50% of depreciation
{pstd}{cmd:.etr, minimumtax(yes) qtik(0.5)}{p_end}

{hline}
*Example: A routine to analyze how the Average Effective Tax Rate (ETR) varies with inflation


*First, compute the AETR for inflation rates of 1, 3, and 5 percent.

forval i=1(2)5 {
    local j = `i' / 100
    etr,  inflation(`j')
   
   rename (coc metr metr2 aetr) (coc_`i' metr_`i' metr2_`i' aetr_`i')
   tempfile etr`i'per
   save `etr`i'per.dta', replace
}

*Second, merge the files together to produce a single file containing AETR for all inflation rates.


tempfile mergedfile
use `etr1per.dta', clear
save `mergedfile', replace

forval i=3(2)5 {
    use `etr`i'per.dta', clear
    merge 1:1 statutory_tax_rate using `mergedfile', gen(_merge`i')
    save `mergedfile', replace
}

*Third, create a bar graph to visualize the AETR for the three inflation rates at a single statutory tax rate.

graph bar (asis) aetr_5 aetr_3 aetr_1  if statutory_tax_rate == 10, ///
        over(statutory_tax_rate, lab(nolab))  ytitle("AETR Values (%)") ylabel(0(3)12) ///
        title("AETR Comparison at Statutory Tax Rate = 10%") ///
        legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3)) note("Statutory Tax Rate: 10%")
        


*Fourth, create a line graph to visualize the AETR for the three inflation rates accross statutory tax rates.

twoway (line aetr_5 statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line aetr_3 statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line aetr_1 statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("AETR Values for Different Inflation Rates") ///
    legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3))


{hline}
*Example: A routine to analyze how the Average Effective Tax Rate (ETR) varies accross tax systems 
	
foreach var in cit cft ace { 
etr, system(`var')
rename aetr aetr_`var'
tempfile `var'
save  ``var'', replace
}
use `cit', clear
merge 1:1 statutory_tax_rate using `cft', gen(m1)
merge 1:1 statutory_tax_rate using `ace', gen(m2)

drop m*

twoway (line aetr_cit statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line aetr_cft statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line aetr_ace statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("Comparison of CIT, CFT, and ACE") ///
    legend(order(1 "CIT" 2 "CFT" 3 "ACE") position(3))


{hline}

{marker reference}{...}
{title:Reference}

{pstd}Shafik Hebous and Andualem Mengistu (2026). Forward-Looking Effective Tax Rates under the Global Minimum Corporate Tax.{p_end}

