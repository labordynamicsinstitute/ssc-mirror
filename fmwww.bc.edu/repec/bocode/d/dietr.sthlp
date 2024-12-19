{smcl}
{* *! version 15.0 11July2024}{...}
{viewerdialog dietr "dialog dietr"}{...}
{viewerjumpto "Syntax" "dietr##syntax"}{...}
{viewerjumpto "Menu" "dietr##menu"}{...}
{viewerjumpto "Description" "dietr##description"}{...}
{viewerjumpto "Required variables" "dietr##required"}{...}
{viewerjumpto "Optional Variables" "dietr##optional"}{...}
{viewerjumpto "Project specific parameters" "dietr##Parameters"}{...}
{viewerjumpto "Examples" "dietr##examples"}{...}


{hline}
{marker menu}{...}
{title:Menu}
   
 	{help dietr##description:Model description}
	{help dietr##syntax:Syntax} 
	{help dietr##required:Required Variables}		
	{help dietr##optional:Optional Variables}
	{help dietr##Parameters:Project specific parameters}
	{help dietr##examples:Examples}
	{help dietr##reference:Reference}

{hline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:dietr} calculates the cost of capital and the forward-looking average and marginal effective tax rates on a hypothetical investment for specified parameters in a dataset based on Hebous and Mengistu (2024). 


{hline}

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:dietr} {cmd:,} id(varname) taxrate(varname) inflation(varname) depreciation(varname) deprtype(varname) delta(varname) [{it:options} ]

{pstd}
{cmd:dietr}  requires five variables: a unique identifier, statutory tax rate, inflation rate, depreciation rate for tax purposes, depreciation type (straight-line or declining balance), and the economic depreciation rate. 
All other variables and parameters have default values, which users can modify as described below.


{hline}
{marker required}{...}
{title:Required Variables}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth taxrate:(real:real)}} The tax rate in decimal format (e.g., 0.05 if the tax rate is 5% ).  {p_end}

{synopt :{opth inflation:(real:real)}} The inflation rate in decimal format (e.g., 0.05  if the inflation rate is 5%). {p_end}

{synopt :{opth deprtype:(string:string)}} The depreciation system ('sl' for straight-line and 'db' for declining balance depreciation method). {p_end}

{synopt :{opth depreciation:(real:real)}}  The depreciation rate for tax purposes in decimal format (e.g., 0.25 if tax depreciation is 25%). {p_end}

{synopt :{opth delta:(real:real)}}  The economic depreciation rate in decimal format (e.g., 0.25 if economic depreciation is 25%). {p_end}

{pstd}
The user can assign any name to the tax rate, inflation, deprtype, depreciation, and delta variables in the dataset, provided that the variables in the dataset aer referenced in the correct variable holder in the dietr command. 
For example,  if the taxrate variable is named xyz in the dataset, it should be included in the dietr command as dietr, taxrate(xyz).

{hline}

{marker optional}{...}
{title:Optional Variables}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth system:(strings:string)}} The standard corporate income tax ('cit') is the default option. Specify 'cft' for a cashflow tax or 'ace' for the alllowance for equity system. {p_end}

{synopt :{opth realint:(real:real)}}   The real interest rate in decimal format (e.g., 0.05 if real interest rate is 5%). The default is 5%. {p_end}

{synopt :{opth debt:(real:real)}}  The proportion of the investment financed with debt, in decimal format (e.g., 0.5 if 50% of the investment is fianced with debt). The default is 0%. {p_end}

{synopt :{opth newequity:(real:real)}}  The proportion of the investment financed with the issuance of new equity, in decimal format 
(e.g., 0.5 if 50% of the investment is fianced with new equity). The default is 0%. The combined share of project financing through debt and new equity can not exceed 100%. {p_end}

{synopt :{opth holiday:(real:real)}} The number of years the project benefits from a zero statutory corporate income tax rate (that is, the number of years of the "tax holiday"). The default value is zero. {p_end}

{syntab:Personal Income Tax}
{synopt :{opth pitint:(real:real)}} The tax rate on interest income at the individual level, in decimal format (e.g., 0.2 if the tax rate is 20%). The default is 0%. {p_end}

{synopt :{opth pitdiv:(real:real)}} The tax rate on dividend income at the individual level, in decimal format (e.g., 0.2 if the tax rate is 20%). The default is 0%. {p_end}

{synopt :{opth pitcgain:(real:real)}} The tax rate on capital gains income at the individual, level, in decimal format (e.g., 0.2 if the tax rate is 20%). The default is 0%. {p_end}
{hline}


{marker Parameters}{...}
{title: Parameters}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opth p:(real:real)}}  The profitability of the investment in decimal format (e.g., 0.1 if profit is 10%). The default is 10%. {p_end}

{synopt :{opth sbie:(real:real)}} The amount of the substance based income exclusion (SBIE) as percentage of the book value of capital in decimal format (e.g., 1.5 if sbie is 150% of the book value of capital), 
which means 50% reflects payroll and 100% reflects tangible capital.  If, for example, sbie is specified to be 80%, this means the mix of tangible capital and payroll is 80% of the book value of total capital. 
If the user does not specify a value, the default is 1.5. {p_end}

{synopt :{opth qrtc:(real:real)}} The amount of a qualified domestic refundable tax credit, under Pillar Two rules, as a percentage of the book value of capital (e.g., 0.02 if it is 2%). The default is zero. 
If this option is specified without the minimumtax(yes) option, then it computes the ETRs with a standard refundable tax credit.  {p_end}

{synopt :{opth nqrtc:(real:real)}}  The amount of non-qualified domestic refundable tax credit, under Pillar Two, as a percentage of the book value of capital (e.g., 0.02 if it is 2%). The default is zero. 
If this option is specified without the minimumtax(yes) option, then it computes the ETRs with a standard non-refundable tax credit (that is, reduction in the tax liabilities only in periods when the investment is not making losses). {p_end}

{synopt :{opth refund:(strings:string)}} Specify 'no' to generate the ETR under a system without a full loss-offset that allows for loss carry-forward without interest
(without cash refund of the tax value of losses for loss making companies). 'yes' is the default, that is, full loss offset is assumed. {p_end}

{synopt :{opth minimumtax:(strings:string)}} Specify 'yes' to generate the ETR with a top-up tax following the Pillar Two minimum tax GLoBE rules. Otherwise, 'no' is the default, assuming no top-up tax. {p_end}

{synopt :{opth minrate:(real:real)}}  The minimum tax rate following the GLoBE rules in decimal format (e.g., 0.2 if the minimum tax rate is 20%). The default is 15% as it is currently the case in Pillar Two. {p_end}

{hline}

{marker examples}{...}
{title:Examples}
Consider a dataset containing the following variables: 𝑥,𝑧,𝑎,𝑏,𝑐,and 𝑘. Here, 
𝑥 uniquely identifies each observation, 
𝑧 denotes the statutory tax rate, 
𝑎 is the preferred measure of inflation, 
𝑏 specifies the type of depreciation system, 
𝑐 indicates the depreciation rate for tax purposes, and 
𝑘 represents the economic depreciation rate of the asset.

{phang} **Example 1: Calculate the METR and AETR of an equity-financed project without a top-up tax, using default parameters:** 
{p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)}

{phang} **Example 2: Calculate the METR and AETR of an equity-financed project without a top-up tax and with default parameters, assuming tax losses are non-refundable:** 
{p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) refund(no)}

{phang} **Example 3: Calculate the METR and AETR of a project without a top-up tax and with default parameters, assuming a debt variable called 'loan':** 
{p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) debt(loan)}

{phang} **Example 4: Calculate the METR and AETR of an equity-financed project without a top-up tax, using user-defined parameters:** 
{p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) p(0.2)}

{phang} **Example 5: Calculate the METR and AETR of an equity-financed project without a top-up tax, assuming the system is a cash flow tax:** 
{p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cft)}

{phang} **Example 6: Calculate the METR and AETR of an equity-financed project with a top-up tax:** 
{p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cft) minimumtax(yes)}

{phang} **Example 7: Calculate the METR and AETR with a top-up tax and a qualified refundable tax credit:** {p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cft) minimumtax(yes) qrtc(1)}

{phang} **Example 8: Calculate the METR and AETR with a top-up tax and a minimum tax rate of 20%:** {p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cft) minimumtax(yes) minrate(0.2)}

{phang} **Example 9: Calculate the METR and AETR of a debt financed project with personal income tax:** {p_end}  
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) debt(loan) pitint(pitint) pitdiv(pitdiv) pitcgain(pitcgain) }


{hline}

{marker reference}{...}
{title:Reference}

Shafik Hebous and Andualem Mengistu (2024). Efficient Economic Rent Taxation under a Global 
Minimum Corporate Tax. Oxford University Centre for Business Taxation Working Paper 2024-10.
{browse "https://oxfordtax.sbs.ox.ac.uk/sitefiles/wp2410-hebous-shafik.pdf"}
