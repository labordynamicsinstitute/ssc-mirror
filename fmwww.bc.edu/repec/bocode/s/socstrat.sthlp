{smcl}
{title:Title}
{phang}
    socstrat — Compute and analyse social stratification variables

{marker syntax}
{title:Syntax}
{p 8 17 2}
    {cmd:socstrat} {cmd:,} {opt socstatus(varlist min=2 max=2)} {opt generate(name)} {opt version(str)} {opt strat(str)} [{opt nolabel}]

{marker description}
{title:Description}
{pstd}
    {cmd:socstrat} is designed to produce and recode specific social stratification variables related to the context of UK social class measures. It accomplishes this by recoding and aggregating detailed occupational codes and employment status into broader social class schemes. Two UK-based social class measures can be constructed: the National Statistics Socio-Economic Classification (NS-SEC) and the Registrar General's Social Class (RGSC). RGSC used to be the UK's official categorisation of social class before being superseded by NS-SEC. Both measures require Standard Occupational Classification (SOC) codes and employment status variables. Manual coding of SOC and employment status into a social class measure is cumbersome. {cmd:socstrat} automates this process to minimise human error in the recoding phase of analytical work. SOC codes are updated every 10 years by the Office for National Statistics (ONS). SOC codes have existed since 1990, and there currently exist four distinct SOC codes: 1990, 2000, 2010, and 2020. Every 10 years, SOC codes are updated, with occupational title codes being removed, replaced, added, or updated. The SOC codes used to construct social class measures will alter the frequencies of class membership composition. 

{pstd}
	The command requires at least two variables to produce a social class measure: SOC codes and employment status (via the {opt socstatus()} option). The combination of these two variables generates a measure of social class that represents the computed social stratification variable of the user's choice.
	
{title:Remark}
{pstd}
	{opt socstrat} uses a range of sources to derive the eight-level NS-SEC full analytic class and seven-level full analytic RGSC class schemas based on SOC 1990, 2000, 2010, and 2020. Importantly, RGSC has not been updated for the SOC 2020 level and, as such, if a user attempts to generate RGSC based on that particular SOC, an appropriate error message will be provided. NS-SEC and RGSC SOC 90 derivation tables are produced by Lambert (2003). SOC 2000 and SOC 2010 derivation tables for RGSC are provided by Rose and Pevalin (2011) as part of an ESRC Review of Government Social Classifications and as part of a research grant from the British Academy. NS-SEC derivations for SOC 2000, 2010, and 2020 are provided by official SOC derivation guides produced by the Institute for Social and Economic Research (ISER) and the Office for National Statistics (ONS). Differences in class membership frequencies within the same stratification measure but using different SOC codes are entirely based on the differences outlined by the above-mentioned derivation matrices and are intentional. 

{pstd}
	It is important that the user selects the correct SOC version that corresponds with the one documented in their given dataset or data documentation. Each SOC version has a different number of SOC codes and uses a different range of numbers. For example, SOC 2000 uses SOC codes in the range 1111 to 9259, with 353 codes in total. SOC 2020, on the other hand, uses 412 SOC codes in total and ranges from 1111 to 9269.

{marker options}
{title:Options}
{dlgtab:Required}

    {opt socstatus(varlist min=2 max=2)} specifies two variables that define the SOC code and employment status for analysis. 

    {opt generate(name)} specifies the name of the new variable that will store the calculated stratification variable.

{pstd}
    {opt version(str)} specifies the SOC version of the stratification variable to use. For example, 
	{cmd:version(90)} could be used to invoke the SOC 1990 implementation of the given social stratification variable. Oftentimes, most social surveys will typically offer only one SOC code to use in the construction of social class variables. In instances where multiple SOC codes are offered, user discretion is advised in selecting which SOC code to use. This command allows you to construct multiple measures of NS-SEC or RGSC and compare membership deviations by SOC code date. 

{pstd}
    {opt strat(str)} allows you to specify a stratification variable. For example,
	{cmd:strat(nssec)} can be used to apply the "nssec" stratification variable. RGSC and NS-SEC are available for {cmd:socstrat}.

{pstd}
    {opt nolabel} prevents the new variable from being assigned value labels. By default, labels are provided. Some users may wish to further collapse the schemas into their collapsed variants. In this instance, users would not wish for a label, and so the option is provided to not generate and apply one.

{marker examples}
{title:Examples}
    Calculate a stratification variable:
    {cmd:socstrat}, socstatus(soc90 status) generate(nssec90) float version(90) strat(nssec)

    Calculate an alternative stratification variable:
    {cmd:socstrat}, socstatus(soc2010 status) generate(rgsc10) float version(10) strat(rgsc)
	
{title:References}
{pstd}
	Lambert, P.S. and Prandy, K. (2003) CAMSIS project webpages: Cambridge Social Interaction and Stratification Scales. Retrieved 06/01/2025 from http://www.camsis.stir.ac.uk/.
	
{pstd}
	Lambert, P.S. (2003) CAMSIS for Britain, SOC90 (electronic file, version 0.1, date of release: February 2003). Retrieved 06/01/2025 from https://www.camsis.stir.ac.uk/Data/Britain91.html.
	
{pstd}
	Rose, D. and Pevalin, D. (2001) The National Statistics Socio-economic Classification: Unifying Official and Sociological Approaches to the Conceptualisation and Measurement of Social Class. ISER Working Papers, Paper 2001-4. Colchester: University of Essex. Available at: https://www.iser.essex.ac.uk/research/publications/working-papers/iser/2001-04.
	
{pstd}
	Rose, D. and Pevalin, D. (2011) Derivations of Social Class. Retrieved 06/01/2025 from https://www.iser.essex.ac.uk/archives/nssec/derivations-of-social-class.
	
{pstd}
	SOC 2010 Volume 3: The National Statistics Socio-economic Classification (NS-SEC rebased on SOC 2010). Retrieved 06/01/2025 online at: https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/soc2010/soc2010volume3thenationalstatisticssocioeconomicclassificationnssecrebasedonsoc2010.
	
{pstd}
	SOC 2020 Volume 3: The National Statistics Socio-economic Classification (NS-SEC rebased on SOC 2020). Retrieved 06/01/2025 online at: https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/soc2020/soc2020volume3thenationalstatisticssocioeconomicclassificationnssecrebasedonthesoc2020.

{marker author}
{title:Author}
Scott Oatley
Department of Sociology
University of Manchester
Manchester
Email: scott.oatley@manchester.ac.uk
