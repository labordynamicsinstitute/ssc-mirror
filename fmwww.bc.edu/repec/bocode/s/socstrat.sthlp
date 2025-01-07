{smcl}
{title:Title}
{phang}
    socstrat — Compute and analyze social stratification variables

{marker syntax}
{title:Syntax}
{p 8 17 2}
    {cmd:socstrat} {cmd:,} {opt socstatus(varlist min=2 max=2)} {opt generate(name)} [{opt float}] {opt version(str)} {opt strat(str)} [{opt nolabel}]

{marker description}
{title:Description}
{pstd}
    {cmd:socstrat} is designed to calculate and analyze social stratification variables based on two variables: the National Statistics Socio-Economic Classification (NS-SEC) or Registrar General's Social Class (RGSC). The command requires at least two variables to define the standard occupation classification (SOC) code and the employment status (via the {opt socstatus()} option) and generates a new variable that represents the computed social stratification variable.
	
{title:Remark}
{pstd}
	{opt socstatus} uses a range of sources to derive the eight-level NS-SEC full analytic class and seven-level full analytic RGSC class schemas based on SOC 1990, 2000, 2010, and 2020. Importantly, RGSC has not been updated for SOC 2020 level and as such, if a user attempts to generate RGSC based on that particular SOC, an appropriate error message will be provided. NS-SEC and RGSC SOC 90 derivation tables are produced by Lambert (2003). SOC 2000 and S0C 2010 derivation tables for RGSC are provided by Rose and Pevalin (2011) as part of a ERSC Review of Government Social Classifications and as part of a reserach grant from the British Academy. NS-SEC derivations for SOC 2000, 2010, and 2020 are provided by official SOC derivation guides produced by the Institue for Social and Economic Reserach (ISER) and the Office of National Statistics (ONS). 

{marker options}
{title:Options}
{dlgtab:Required}

    {opt socstatus(varlist min=2 max=2)} specifies two variables that define the SOC code and employment status for analysis. 

    {opt generate(name)} specifies the name of the new variable that will store the calculated stratification variable.

    {opt float} specifies that the generated variable will be stored as a floating-point variable.

    {opt version(str)} specifies the SOC version of the stratification variable calculation method to use. For example, 
	{cmd:version(90)} could be used to invoke the SOC 1990 implementation of the given social stratification variable.

    {opt strat(str)} allows you to specify a stratification variable. For example,
	{cmd:strat(nssec)} can be used to apply the "nssec" stratification variable.

    {opt nolabel} prevents the new variable from being assigned value labels.

{marker examples}
{title:Examples}
    Calculate a stratification variable:
    {cmd:socstrat}, socstatus(soc90 status) generate(nssec90) float version(90) strat(nssec)

    Calculate an alternative stratification variable:
    {cmd:socstrat}, socstatus(soc2010 status) generate(rgsc10) float version(10) strat(rgsc)
	
{title:References}
{pstd}
	Lambert, P.S. and Prandy, K. (2003) CAMSIS project webpages: Cambridge Social Interaction and Stratification Scales, Retreived 06/01/2025 from http://www.camsis.stir.ac.uk/ .
	
{pstd}
	Lambert, P.S. (2003) CAMSIS for Britain, SOC90 (electronic file, version 0.1, date of release: February 2003), Retrieved 06/01/2025 from http://www.camsis.stir.ac.uk/downloads/gb91soc2000.zip .
	
{pstd}
	Rose, D. and Pevalin, D. (2001) The National Statistics Socio-economic Classification: Unifying Official and Sociological Approaches to the Conceptualisation and Measurement of Social Class. ISER Working Papers. Paper 2001-4. Colchester: University of Essex. Available at: https://www.iser.essex.ac.uk/research/publications/working-papers/iser/2001-04
	
{pstd}
	Rose, D. and Pevalin, D. (2011) Derivations of Social Class, Retrieved 06/01/2025 from https://www.iser.essex.ac.uk/archives/nssec/derivations-of-social-class .
	
{pstd}
	SOC2010 Volume 3: the National Statistics Socio-economic classification (NS-SEC rebased on SOC2010). Retrieved 06/01/2025 Online at: https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/soc2010/soc2010volume3thenationalstatisticssocioeconomicclassificationnssecrebasedonsoc2010
	
{pstd}
	SOC 2020 Volume 3: the National Statistics Socio-economic Classification (NS-SEC rebased on the SOC 2020). Retrieved 06/01/2025 Online at: https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/soc2020/soc2020volume3thenationalstatisticssocioeconomicclassificationnssecrebasedonthesoc2020 


{marker author}
{title:Author}
Scott Oatley
Department of Sociology
University of Edinburgh
Edinburgh
Email: soatley@ed.ac.uk

