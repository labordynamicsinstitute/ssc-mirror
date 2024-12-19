{smcl}
{* *! version 15.0 11July2024}{...}
{viewerdialog etr "dialog aetr"}{...}
{viewerjumpto "Syntax" "etr##syntax"}{...}
{viewerjumpto "Menu" "etr##menu"}{...}
{viewerjumpto "Description" "etr##description"}{...}
{viewerjumpto "Macroeconomic Parameters" "etr##macro"}{...}
{viewerjumpto "Tax parameters" "etr##tax"}{...}
{viewerjumpto "Project specific parameters" "etr##project"}{...}
{viewerjumpto "Examples" "etr##examples"}{...}

{p2col:{bf:etr}}etr : Effective tax rate 


{hline}
{marker menu}{...}
{title:Menu}
   
 	{help etr##description:Model description}
	{help etr##syntax:Syntax} 
	{help etr##macro:Macroeconomic Parameters}		
	{help etr##tax:Tax parameters}
	{help etr##project:Project specific parameters}
	{help etr##examples:Examples}
	{help etr##reference:Reference}

{hline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:etr} calculates the cost of capital and the forward-looking average and
marginal effective tax rates on a hypothetical investment for specified parameters based 
on Hebous and Mengistu (2024). 


{hline}

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:etr} {cmd:,}  [ {it:options} ]

{pstd}
{cmd:etr} can run without user-specified parameters using default values. The user can change the default values as described in the options below. 


{hline}
{marker required}{...}
{title:Macroeconomic Parameters}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth inflation:(real:real)}} The inflation rate in decimal format (e.g., 0.05 if inflaiton is 5%). The default is 5%. {p_end}

{synopt :{opth  realint:(real:real)}} The real interest rate in decimal format (e.g., 0.05 if real interest rate is 5%). The default is 5%. {p_end}

{hline}
{marker tax}{...}
{title:Tax parameters}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Corporate Income Tax}
{synopt :{opth system:(strings:string)}} The standard corporate income tax ('cit') is the default option. Specify 'cft' for a cashflow tax or 'ace' for the alllowance for equity system. {p_end}

{synopt :{opth depreciation:(real:real)}} The depreciation rate for tax purposes in decimal format (e.g., 0.25 if tax depreciation is 25%). The default is 25%. {p_end}

{synopt :{opth delta:(real:real)}} The economic depreciation rate in decimal format (e.g., 0.25 if economic depreciation is 25%). The default is 25%. {p_end}

{synopt :{opth deprtype:(strings:string)}} Specify 'sl' to generate the ETR with a straight line depreciaiton method. Otherwise, specify 'db' for a declining balance depreciation method, which is the default option if no option is specified.

{synopt :{opth refund:(strings:string)}} Specify 'no' to generate the ETR under a system without a full loss-offset that allows for loss carry-forward but without interest
(without cash refund of the tax value of losses for loss making companies). Otherwise, 'yes' is the default, that is, full loss offset is assumed. {p_end}

{synopt :{opth holiday:(real:real)}} The number of years the project benefits from a zero statutory corporate income tax rate (that is, the number of years of the "tax holiday"). The default value is zero. {p_end}

{synopt :{opth minimumtax:(strings:string)}} Specify 'yes' to generate the ETR with a top-up tax following the Pillar Two minimum tax GLoBE rules. Otherwise, 'no' is the default, assuming no top-up tax. {p_end}

{synopt :{opth minrate:(real:real)}} The minimum tax rate following the GLoBE rules in decimal format (e.g., 0.2 if the minimum tax rate is 20%). The default is 15% as it is currently the case in Pillar Two. {p_end}

{syntab:Personal Income Tax}
{synopt :{opth pitint:(real:real)}} The tax rate on interest income at the individual level, in decimal format (e.g., 0.2 if the tax rate is 20%). The default is 0%. {p_end}

{synopt :{opth pitdiv:(real:real)}} The tax rate on dividend income at the individual level, in decimal format (e.g., 0.2 if the tax rate is 20%). The default is 0%. {p_end}

{synopt :{opth pitcgain:(real:real)}} The tax rate on capital gains income at the individual level, in decimal format (e.g., 0.2 if the tax rate is 20%). The default is 0%. {p_end}
{hline}

{marker project}{...}
{title:Project specific parameters}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth p:(real:real)}} The profitability of the investment in decimal format (e.g., 0.1 if profit is 10%). The default is 10%. {p_end}

{synopt :{opth debt:(real:real)}} The proportion of investment financed with debt in decimal format (e.g., 0.5 if  50% of the investment is fianced with debt). The default is 0%. {p_end}

{synopt :{opth newequity:(real:real)}}  The proportion of the investment financed with the issuance of new equity, in decimal format 
(e.g., 0.5 if 50% of the investment is fianced with new equity). The default is 0%. The combined share of project financing through debt and new equity can not exceed 100%. {p_end}



{synopt :{opth sbie:(real:real)}} The amount of the substance based income exclusion (SBIE) as percentage of the book value of total capital in deminal fomrat 
(e.g., 1.5 if sbie is 150% of the value of the book value of capital), which means 50% reflects payroll and 100% reflects tangible capital. 
If, for example, sbie is specified to be 80%, this means the mix of tangible capital and payroll is 80% of the book value of total capital.  If the user does not specify a value, the default is set to 1.5. {p_end}

{synopt :{opth qrtc:(real:real)}} The amount of a qualified domestic refundable tax credit, under Pillar Two rules, as a percentage of the book value of capital
(e.g., 0.02 if it is 2%). The default is zero. If this option is specified without the minimumtax(yes), then it computes the ETRs with a standard refundable tax credit. {p_end}

{synopt :{opth nqrtc:(real:real)}} The amount of non-qualified domestic refundable tax credit, under Pillar Two, as a percentage of the book value of capital 
(e.g., 0.02 if it is 2%). The default is zero. If this option is specified without the minimumtax(yes), then it computes the ETRs with a standard non-refundable tax credit 
(that is, reduction in the tax liabilities only in periods when the investment is not making losses). {p_end}


{hline}

{marker examples}{...}
{title:Examples}

	
{phang} Calacualte the ETR of an equity financed project without a top-up tax, default parameters {p_end}
	
	{cmd:. etr} 
 
{phang} Calacualte the ETR of an equity financed project without a top-up tax, Cashflow tax system and default parameters {p_end}
	
	{cmd:. etr, system(cft)}  

{phang} Calacualte the ETR of an equity financed project without a top-up tax, allowance for equity tax system and default parameters {p_end}
	
	{cmd:. etr, system(ace)}  

{phang} Calacualte the ETR of an equity financed project without a top-up tax, if tax losses are not refundable  ​ {p_end}
	
	{cmd:. etr, refund(no)} 

{phang} Calacualte the ETR of an equity financed project without a top-up tax, user supplied parameters​ {p_end}
	
	{cmd:. etr, inflation(0.02) realint(0.03) p(0.1) debt(0) depreciation(0.25) delta(0.25)} 

{phang} Calacualte the ETR of a project that is financed with 70% equity and 30% debt, without a top-up tax  ​ {p_end}

	{cmd:. etr, inflation(0.02) realint(0.03) p(0.1) debt(0.3) depreciation(0.25) delta(0.25)}

{hline}
{syntab:Incorporating personal income taxes}
{hline}
	
{phang} Calculate the ETR of an equity-financed project without a top-up tax, with a tax rate of 10% on interest, 12% on dividends, and 15% on capital gains. {p_end}
	
	{cmd:. etr, pitint(0.1)	pitdiv(0.12) pitcgain(0.15)}

{hline}
{syntab:Incorporating the top-up tax}
{hline}
	

{phang} Calculate the ETR of an equity financed project with a top-up tax and default parameters ​ {p_end}

	{cmd:. etr,  minimumtax(yes)}

{phang} Calculate the ETR of an equity financed project with a top-up tax and default parameters, with a minium tax rate of 25%. ​ {p_end}

	{cmd:. etr,  minimumtax(yes) minrate(0.25)}

{phang} Calculate the ETR of an equity financed project with a top-up tax ​ {p_end}

	{cmd:. etr,  inflation(0.02) realint(0.03) p(0.1) depreciation(0.25) delta(0.25) sbie(1.5) minimumtax(yes)}

{phang} Calculate the ETR of a project with financing mix of 70% equity and 30% debt with a top-up tax ​ {p_end}

	{cmd:. etr,  inflation(0.02) realint(0.03) p(0.1) debt(0.3) depreciation(0.25) delta(0.25) sbie(1.5) minimumtax(yes)}

{phang} Calculate the ETR with a top-up tax and a qualified refundable tax credit ​ {p_end}

	{cmd:. etr,  inflation(0.02) realint(0.03) p(0.1) debt(0) depreciation(0.25) delta(0.25) sbie(1.5) qrtc(1) minimumtax(yes)}

{phang} Calculate the ETR with a top-up tax and a non-qualified refundable tax credit ​ {p_end}

	{cmd:. etr,  inflation(0.02) realint(0.03) p(0.1) depreciation(0.25) delta(0.25) sbie(1.5) nqrtc(1) minimumtax(yes)}

{hline}

.


*First example: A routine to analyze how the Average Effective Tax Rate (ETR) varies with inflation

quietly {
*First, compute the AETR for inflation rates of 1, 3, and 5 percent.
forval i=1(2)5 {
    local j = `i' / 100
    etr,  inflation(`j')
    rename AETR AETR`i'per
    rename METR METR`i'per
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

graph bar (asis) AETR5per AETR3per AETR1per  if statutory_tax_rate == 10, ///
        over(statutory_tax_rate, lab(nolab))  ytitle("AETR Values (%)") ylabel(0(3)12) ///
        title("AETR Comparison at Statutory Tax Rate = 10%") ///
        legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3)) note("Statutory Tax Rate: 10%")
        
}     // closes quitely      

*Fourth, create a line graph to visualize the AETR for the three inflation rates accross statutory tax rates.

twoway (line AETR5per statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line AETR3per statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line AETR1per statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("AETR Values for Different Inflation Rates") ///
    legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3))

}


*Second example: A routine to analyze how the Average Effective Tax Rate (ETR) varies accross tax systems (non-refundable)
quietly {
	
foreach var in cit cft ace { 
etr, system(`var') refund(no)
rename AETR AETR_`var'
tempfile `var'
save  ``var'', replace
}
use `cit', clear
merge 1:1 statutory_tax_rate using `cft', gen(m1)
merge 1:1 statutory_tax_rate using `ace', gen(m2)

drop m*

twoway (line AETR_cit statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line AETR_cft statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line AETR_ace statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("Comparison of CIT, CFT, and ACE") ///
    legend(order(1 "CIT" 2 "CFT" 3 "ACE") position(3))
}

{hline}

{marker reference}{...}
{title:Reference}

Shafik Hebous and Andualem Mengistu (2024). Efficient Economic Rent Taxation under a Global 
Minimum Corporate Tax. Oxford University Centre for Business Taxation Working Paper 2024-10.
{browse "https://oxfordtax.sbs.ox.ac.uk/sitefiles/wp2410-hebous-shafik.pdf"}

