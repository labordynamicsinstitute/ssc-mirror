{smcl}
{* *! version 1.0.0 26 Jan 2026}{...}
{viewerjumpto "Syntax" "dietr##syntax"}{...}
{viewerjumpto "Menu" "dietr##menu"}{...}
{viewerjumpto "Description" "dietr##description"}{...}
{viewerjumpto "Required variables" "dietr##required"}{...}
{viewerjumpto "Optional variables" "dietr##optional"}{...}
{viewerjumpto "Project parameters" "dietr##parameters"}{...}
{viewerjumpto "Pillar Two parameters" "dietr##pillartwo"}{...}
{viewerjumpto "Examples" "dietr##examples"}{...}
{viewerjumpto "Reference" "dietr##reference"}{...}

{hline}
{marker menu}{...}
{title:Menu}

    {help dietr##description:Description}
    {help dietr##syntax:Syntax}
    {help dietr##required:Required variables}
    {help dietr##optional:Optional variables}
    {help dietr##parameters:Project parameters}
    {help dietr##pillartwo:Pillar Two parameters}
    {help dietr##examples:Examples}
    {help dietr##reference:Reference}


{hline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:dietr} calculates the user cost of capital and the forward-looking marginal and average effective tax rates (METR and AETR) for a hypothetical investment, based on the model in Hebous and Mengistu (2026). The command reads required variables from the dataset and combines them with user-specified parameters to compute the corresponding measures for each observation. It generates the variables {it:ucc} (cost of capital), {it:metr}, {it:metr2}, {it:aetr}, and {it:tax_system}. If any of these variable names already exist in the dataset, the ado-file stops and returns an error to avoid overwriting existing data.

{hline}

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:dietr} {cmd:,}
    id(varname) taxrate(varname) inflation(varname) ///
    depreciation(varname) deprtype(varname) delta(varname) ///
    [{it:options}]

{pstd}
{cmd:dietr} requires a unique identifier, the statutory tax rate, the inflation rate, the tax depreciation rate, the depreciation method (straight-line or declining-balance), and the economic depreciation rate. All other parameters have default values, which can be modified using the options listed below.

{hline}

{marker required}{...}
{title:Required variables}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opth id:(varname)}}Unit of analysis for the ETR (e.g., country). Useful when multiple records belong to the same ETR unit (e.g., firm-country pairs).{p_end}

{synopt:{opth taxrate:(varname)}}Statutory corporate income tax rate (decimal format, e.g., 0.05 = 5%).{p_end}

{synopt:{opth inflation:(varname)}}Inflation rate (decimal format, e.g., 0.05 = 5%).{p_end}

{synopt:{opth deprtype:(varname)}} Depreciation method.
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

{synopt:{opth depreciation:(varname)}}Tax depreciation rate (decimal format, e.g., 0.25 = 25%).{p_end}

{synopt:{opth delta:(varname)}}Economic depreciation rate (decimal format, e.g., 0.25 = 25%).{p_end}

{pstd}
The variable names in the dataset can be arbitrary. For example, if the tax rate is stored in variable {cmd:abc}, specify {cmd:taxrate(abc)} in the command.

{hline}

{marker optional}{...}
{title:Optional variables}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opth systemvar:(varname)}}Tax system specified in a variable: {cmd:cit}, {cmd:cft}, or {cmd:ace}.{p_end}

{synopt:{opth system:(string)}}Tax system as a parameter: {cmd:cit} (default), {cmd:cft}, or {cmd:ace}. If neither {cmd:system()} nor {cmd:systemvar()} is provided, the default system is the standard CIT.{p_end}

{synopt:{opth realint:(real)}}Real interest rate (decimal format). Default: 0.05.{p_end}

{synopt:{opth debt:(real)}}Share of investment financed with debt (decimal format). Default: 0.{p_end}

{synopt:{opth newequity:(real)}}Share financed with newly-issued equity (decimal). Default: 0. The combined share of {cmd:debt()} and {cmd:newequity()} may not exceed 1.{p_end}

{synopt:{opth holiday:(real)}}Years of tax holiday (zero statutory CIT rate). Default: 0.{p_end}

{syntab:{ul:{bf:Personal income tax}}}
{synopt:{opth pitint:(real)}}Tax rate on interest income (decimal). Default: 0.{p_end}
{synopt:{opth pitdiv:(real)}}Tax rate on dividend income (decimal). Default: 0.{p_end}
{synopt:{opth pitcgain:(real)}}Tax rate on capital gains (decimal). Default: 0.{p_end}

{hline}

{marker parameters}{...}
{title:Project parameters}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opth p:(real)}}Profitability of the investment (decimal format, e.g., 0.10 = 10%). Default: 0.10.{p_end}

{synopt:{opth superdeduction:(real)}}Super-deduction on the acquisition cost (decimal). A value of 0.5 implies 150% deductibility. Default: 0. Range: 0–1.5.{p_end}

{synopt:{opth beta:(real)}}Capital share in the Cobb–Douglas production function. Default: 0.4.{p_end}

{synopt:{opth credit:(real)}}Pre-tax credit (share of initial investment) independent of the statutory tax rate. Default: 0.{p_end}

{synopt:{opth taxcredit:(real)}} is a credit against tax liability (so its value scales with the statutory rate). It is expressed as a share of initial investment. Default: 0.{p_end}

{hline}


{marker pillartwo}{...}
{title:Pillar Two parameters}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opth minimumtax:(string)}}Specify {cmd:yes} to compute ETRs
including a Pillar Two top-up tax under the GloBE rules.
Default: {cmd:no}.{p_end}

{synopt:{opth minrate:(real)}}Minimum tax rate under the GloBE rules
(decimal). Default: 0.15.{p_end}

{synopt:{opth carveout:(real)}}Carve-out rate applied to the SBIE base for
tangible assets and payroll. Default: 0.05.{p_end}

{synopt:{opth qtil:(real)}}Qualified tax incentive expressed as a share of
payroll. Must lie in [0,1]. Default: {bf:0}.{p_end}

{synopt:{opth qtik:(real)}}Qualified tax incentive expressed as a share of
capital depreciation. Must lie in [0,1]. Default: {bf:0}.{p_end}

{synopt:{opth sl:(real)}}Maximum qualified tax incentive expressed as a
multiple of payroll (e.g., 0.05 = 5%). Default: {bf:0.055}.{p_end}

{synopt:{opth slk:(real)}}Maximum qualified tax incentive expressed as a
multiple of depreciation (e.g., 0.05 = 5%). Default: {bf:0.055}.{p_end}





{marker examples}{...}
{title:Examples}

{pstd}
Suppose a dataset contains the variables {it:x}, {it:z}, {it:a}, {it:b}, {it:c}, and {it:k}, where:
{break}
{it:x} uniquely identifies each observation,
{break}
{it:z} is the statutory corporate tax rate,
{break}
{it:a} is the inflation rate,
{break}
{it:b} specifies the tax depreciation method ({cmd:sl} or {cmd:db}),
{break}
{it:c} is the tax depreciation rate, and
{break}
{it:k} is the economic depreciation rate of the asset.
{break}
{it:inal} is the initial tax depreciation rate of the asset.

{phang}
{bf:Example 1:} Calculate the METR and AETR of an equity-financed project using default parameters and no top-up tax:
{p_end}
{cmd:. dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) inal(inal) delta(k)}

{phang}
{bf:Example 2:} Specify a higher rate of return on the investment (profitability {cmd:p(0.3)}):
{p_end}
{cmd:. dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) inal(inal) delta(k) p(0.3)}

{phang}
{bf:Example 3:} Calculate METR and AETR for a project with debt financing using variable {it:loan}:
{p_end}
{cmd:. dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) inal(inal) delta(k) debt(loan)}

{phang}
{bf:Example 4:} Calculate ETRs assuming a cash-flow tax system:
{p_end}
{cmd:. dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cft)}

{phang}
{bf:Example 5:} Calculate ETRs assuming an ACE tax system:
{p_end}
{cmd:. dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) inal(inal) delta(k) system(ace)}

{phang}
{bf:Example 6:} Calculate ETRs for a debt-financed project with personal income tax on interest, dividends, and capital gains:
{p_end}
{cmd:. dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) inal(inal) delta(k) debt(loan) pitint(pitint) pitdiv(pitdiv) pitcgain(pitcgain)}

{hline}

{phang}
{bf:Example 7:} Calculate METR and AETR under a standard cit with a Pillar Two top-up tax:
{p_end}
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cit) minimumtax(yes)}

{phang}
{bf:Example 8:} Calculate METR and AETR under a cash-flow tax with a Pillar Two top-up tax:
{p_end}
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cft) minimumtax(yes)}

{phang}
{bf:Example 9:} Apply a Pillar Two minimum tax rate of 20%:
{p_end}
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cit) minimumtax(yes)  minrate(0.20)}

{phang}
{bf:Example 10:} Apply a qualified tax incentive equivalent to 50 percent of
payroll as a refundable tax credit under Pillar Two.
{p_end}
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cit) minimumtax(yes) qtil(0.5)}

{phang}
{bf:Example 11:} Change the payroll tax incentive coefficient from 5.5 percent
to 4 percent and apply a qualified tax incentive equivalent to 50 percent of
payroll under Pillar Two.
{p_end}
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cit) minimumtax(yes) qtil(0.5) sl(0.04)}

{phang}
{bf:Example 12:} Apply a qualified tax incentive equivalent to 50 percent of depreciation under Pillar Two.
{p_end}
{cmd:. dietr, id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) system(cit) minimumtax(yes) qtik(0.5)}


{hline}

{marker reference}{...}
{title:Reference}

{pstd}
Shafik Hebous and Andualem Mengistu (2026). Forward-Looking Effective Tax Rates under the Global Minimum Corporate Tax.{p_end}

