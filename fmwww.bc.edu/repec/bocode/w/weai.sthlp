{smcl}

{* *! 1.0.0 2022}{...}
help {hi:weai}
{hline}

{title:Title}


{p2colset 5 17 19 2}{...}
{p 2 2 2} {hi:weai} {hline 2} Computes different versions of the Women's Empowerment in Agricultural Index (WEAI).
{p2colreset}{...}

{title:Syntax}

{p 8 11 2}{hi:weai} {cmd:d1(}{help varlist}{cmd:)} {cmd:d2(}{help varlist}{cmd:)}  
... [{cmd:w1(}{help numlist}{cmd:)} {cmd:w2(}{help numlist}{cmd:)} ...] {ifin} {weight}{cmd:,}
{cmdab:s:ex(}{help it:varname}{cmd:)}
{cmdab:f:emale(}{help it:integer}{cmd:)}
{cmdab:hh:id(}{help it:varname}{cmd:)}
[{cmdab:c:utoff(}{help it:real}{cmd:)}
{cmdab:d:etails}
{cmdab:sa:ve(}{it:filename}{cmd:)}
{cmdab:gr:aph(}{it:filename}{cmd:)}
{cmd:by(}{help varname}{cmd:)}]


{title:Description}

{p 2 2 2} The Women's Empowerment in Agriculture Index (WEAI) is a standardized, survey-based tool that 
has been widely used to track gender equality and measure empowerment, agency, and women's inclusion in 
the agricultural sector 
({browse "https://doi.org/10.1016/j.worlddev.2013.06.007":Alkire et al. 2013}). Since the WEAI's release 
in 2012, an abbreviated version of the WEAI (referred to as A-WEAI) and 
project-level version of the WEAI (referred to as pro-WEAI) have been developed 
({browse "https://www.ifpri.org/publication/abbreviated-womens-empowerment-agriculture-index-weai":Malapit et al. 2017}; 
{browse "https://doi.org/10.1016/j.worlddev.2019.06.018":Malapit et al. 2019}).{p_end} 
{p 2 2 2} Depending on the options specified by the user, {cmd:weai} is capable of computing all versions 
of the WEAI. {cmd:weai} allows for flexibility in the specification of the binary adequacy indicators, 
empowerment cutoff, and indicator weights. {cmd:weai} provides a decomposition by indicator and, when 
specified, by sub-groups. Note that because the WEAI requires data from women and men, users 
are required to specify a variable (and values) identifying the sex of respondents.{p_end}

{marker Outcomes}{...}
{p 2 2 2} Given a suitable set of adequacy indicators, empowerment cutoff, and gender 
variable, {hi:weai} computes the following output:{p_end}

{p 2 2 2}{title:Individual-/household-level indicators:}{p_end}

{phang}
{cmd: empowered}: Empowerment status, a binary indicator that reflects whether a person is empowered. A person 
is considered empowered if his/her empowerment score (the share of weighted indicators in which he/she achieves 
adequacy) is equal to or greater than the empowerment cutoff (see below for details).{p_end}

{phang}
{cmd: emp_score}: Empowerment score, the share of weighted indicators in which a person achieves 
adequacy. Higher values indicate higher levels of adequacy (i.e., empowerment).{p_end}

{phang}
{cmd: gender_parity}: Gender parity status, a binary indicator that reflects whether a 
household achieves gender parity.{p_end}

{phang}
{cmd: hh_ineq}: Intrahousehold inequality score, the difference between the empowerment 
scores of the male and female respondents within the same household. A positive score 
indicates that the man is more empowered than the woman; a negative score indicates that 
the woman is more empowered than the man.{p_end}

{p 2 2 2}{title:Aggregate indices:}{p_end}

{phang}
{cmd: 5/3DE}: Five/Three Domains of Empowerment Index. Based on the Alkire-Foster methodology 
({browse "https://doi.org/10.1016/j.jpubeco.2010.11.006":Alkire and Foster 2011}), the 5/3DE measures 
the prevalence of empowerment and intensity of disempowerment at the individual-level in the sample 
population. It is calculated using the formula: 5/3DE = 1 - (H*A).{p_end}

{phang}
{cmd: H}: Percentage of individuals not achieving empowerment, or the disempowerment headcount ratio. Reflects the 
prevalence of (dis)empowerment among women/men in the sample population. It is the proportion of persons in the 
sample considered to be disempowered based on the empowerment cutoff.{p_end}

{phang}
{cmd: A}: Mean disempowerment score. Reflects the intensity of (dis)empowerment among women/men in the sample 
population. It is the mean share of weighted indicators in which a person does not achieve adequacy, calculated 
only for persons considered to be disempowered based on the empowerment cutoff.{p_end}

{phang}
{cmd: GPI}: Gender Parity Index. The GPI measures two aspects of empowerment at the household-level in the 
sample population: the proportion of households that achieve gender parity and the average empowerment gap 
among households that lack gender parity. A household achieves gender parity if either of the following 
conditions are true: the woman is considered empowered or the woman's empowerment score is equal to or 
greater than the man's empowerment score. It is calculated using the formula: GPI = 1 - (HGPI*IGPI).{p_end}

{phang}
{cmd: HGPI}: Percentage of households not achieving gender parity. Reflects the prevalence of gender parity among 
households in the sample population. It is the proportion of households in the sample considered 
not to have achieved gender parity.{p_end}

{phang}
{cmd: IGPI}: Mean empowerment gap. Reflects the average percentage shortfall that women without gender parity 
experience relative to men in their households. It is the mean (normalized) difference between the empowerment scores of 
the man and woman in a household, calculated among only households that do not achieve gender parity.{p_end}

{phang}
{cmd: WEAI/A-WEAI/pro-WEAI}: Women's Empowerment in Agriculture Index/Abbreviated Women's Empowerment in 
Agriculture Index/Project-level Women's Empowerment in Agriculture Index. The WEAI/A-WEAI/pro-WEAI measures 
women's empowerment in the sample population. It is the weighted average of the 5/3DE and GPI, 
in which the 5/3DE receives 0.9 weight and the GPI receives 0.1 weight.{p_end}


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}

{synopt:{opth d1(varlist)} ...}List of empowerment domains, each domain must be 
composed of at least 1 indicator and at least 3 domains must be specified.{p_end}
{synopt:{opth s:ex(varname)}}Variable identifying the gender of respondents.{p_end}
{synopt:{opth f:emale(integer)}}Value assigned to female respondents.{p_end}
{synopt:{opth hh:id(varname)}}Variable uniquely identifying households.{p_end}

{syntab:Optional}

{synopt:{opth w1(numlist)} ...}List of weights to be applied to the list of indicators.{p_end}
{synopt:{opth c:utoff(real)}}Empowerment cutoff, a value between 0 and 1, denoting 
the share of weighted indicators in which a person must be adequate to be considered 
empowered; default value is 0.80 (or 80% of the weighted indicators).{p_end}
{synopt:{cmdab:d:etails}}Displays optional results tables.{p_end}
{synopt:{cmdab:sa:ve(}{it:filename}{cmd:)}}Saves results tables using {it:filename}.{p_end}
{synopt:{cmdab:gr:aph(}{it:filename}{cmd:)}}Displays and saves optional figure(s) using {it:filename}.{p_end}
{synopt:{opth by(varname)}}Decomposition of all output measures by categories of {help varname}.{p_end}

{cmdab:sa:ve(}{help it:string}{cmd:)}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:pweight} and {it:fweight} are allowed; see {help weight}.


{title:Options}

{phang}
{cmd:d1(}{help varlist}{cmd:)} {cmd:d2(}{help varlist}{cmd:)} {cmd:d3(}{help varlist}{cmd:)} ... : denote the empowerment 
domains. At least 1 indicator must be specified for each domain and at least 3 domains must 
be specified. The indicators should be binary variables (1 = adequate; 0 = inadequate). Respondents with missing values 
for any indicator are excluded from the estimation sample. The tables below show the domains, 
indicators, and weights for pro-WEAI, WEAI, and A-WEAI, respectively. Pro-WEAI is comprised of 
10 indicators across 3 domains (intrinsic agency, instrumental agency, and collective 
agency). WEAI is comprised of 10 indicators across 5 domains (production, resources, income, 
leadership, and time). A-WEAI is comprised on 6 indicators across the same 5 domains. Users 
must follow these guidelines in order to correctly calculate the indices. Guidance and 
background information on the construction of the indicators, as well as Stata .do files, 
can be accessed on the {browse "https://weai.ifpri.info/":WEAI Resource Center}.{p_end}

	 {bf:Pro-WEAI}
	{c TLC}{hline 63}{c TRC}
	{c |}  Domain         Indicator                             Weight  {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Intrinsic      Autonomy in income                    1/10    {c |}
	{c |}   agency        Self-efficacy                         1/10    {c |}
	{c |}                 Attitudes about intimate partner      1/10    {c |}
	{c |}                  violence against women                       {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Instrumental   Input in livelihood decisions         1/10    {c |}
	{c |}   agency        Ownership of land and other assets    1/10    {c |}
	{c |}                 Access to and decisions on            1/10    {c |}
	{c |}                  financial services                           {c |}
	{c |}                 Control over use of income            1/10    {c |}
	{c |}                 Work balance                          1/10    {c |}
	{c |}                 Visiting important locations          1/10    {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Collective     Group membership                      1/10    {c |}
	{c |}   agency                                                      {c |}
	{c BLC}{hline 63}{c BRC}

	 {bf:WEAI}
	{c TLC}{hline 63}{c TRC}
	{c |}  Domain       Indicator                               Weight  {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Production   Input in productive decisions           1/10    {c |}
	{c |}               Autonomy in production                  1/10    {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Resources    Ownership of assets                     1/15*   {c |}
	{c |}               Purchase, sale, or transfer of assets   1/15*   {c |}
	{c |}               Access to and decisions about credit    1/15*   {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Income       Control over use of income              1/5     {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Leadership   Group membership                        1/10    {c |}
	{c |}               Speaking in public                      1/10    {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Time         Workload                                1/10    {c |}
	{c |}               Leisure                                 1/10    {c |}
	{c BLC}{hline 63}{c BRC}
	 {bf:NOTE:} * Weights should be specified as w2(0.06667 0.06666 0.06667).
	
	 {bf:A-WEAI}
	{c TLC}{hline 63}{c TRC}
	{c |}  Domain       Indicator                               Weight  {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Production   Input in productive decisions           1/5     {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Resources    Ownership of assets                     2/15**  {c |}
	{c |}               Access to and decisions about credit    1/15**  {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Income       Control over use of income              1/5     {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Leadership   Group membership                        1/5     {c |}
	{c LT}{hline 63}{c RT}
	{c |}  Time         Workload                                1/5     {c |}
	{c BLC}{hline 63}{c BRC}
	 {bf:NOTE:} ** Weights should be specified as w2(0.13333 0.06667).

{phang}
{cmd:w1(}{help numlist}{cmd:)} {cmd:w2(}{help numlist}{cmd:)} {cmd:w3(}{help numlist}{cmd:)} ... : denote 
the weights used when summing indicators to calculate the empowerment score. 
If indicator weights are unspecified by the user, all indicators receive equal weight if 3 domains are specified (that is, the weighting structure used by pro-WEAI). If indicator weights are unspecified and 5 domains are specified, indicators are weighted equally within each domain.{p_end}

{pmore}
If weights are specified by the user, the following 
requirements apply: (i) weights must be values between 
0 and 1 and must sum to 1; (ii) the number of weights 
must equal the number of indicators; and (iii) weights and indicators must 
be listed in the same order to ensure proper correspondence.{p_end}

{phang}
{opth s:ex(varname)} and {opth f:emale(integer)} : are required and, respectively, 
specify a variable and value that identify female respondents.{p_end}

{phang}
{opth hh:id(varname)} : is required and specifies a variable that uniquely identifies households.{p_end}

{phang}
{opth c:utoff(real)} : denotes the empowerment cutoff, or the minimum empowerment score required for 
a person to be considered empowered. The empowerment cutoff should be a value 
between 0 and 1. For each person {cmd:weai} computes an empowerment score, i.e., the share of weighted 
indicators in which he/she achieves adequacy. A person is considered empowered only if his/her resulting 
score is equal to or greater than the specified empowerment cutoff. If unspecified by the 
user, a default value of 0.80 (or 80% of the weighted indicators) is used, which reflects the 
cutoff used when calculating WEAI, A-WEAI, and pro-WEAI.{p_end}

{pmore}
A modified version of pro-WEAI may be calculated if at least 8 of 10 indicators, 
including at least 1 from each domain, are present in the index. For a modified version 
of pro-WEAI calculated with 8 or 9 indicators, the empowerment cutoff should be 
set at 0.75.{p_end}

{phang}
{cmdab:d:etails} : displays additional tables and figures showing: (i) the uncensored 
inadequcy headcount ratio, i.e., the proportion of women/men in the sample who 
are inadequate in an indicator, regardless of whether they are empowered or disempowered; 
(ii) the censored inadequcy headcount ratio, i.e., the proportion of women/men in 
the sample who are disempowered and simultaneously inadequate in an indicator; and 
(iii) the relative contribution of each indicator to disempowerment, calculated 
by multiplying the censored inadequcy headcount ratio by the indicator weight and 
dividing by the disempowerment index (1 - 3/5DE). {p_end} 

{phang}
{cmdab:sa:ve(}{it:filename}{cmd:)} : saves the results tables in Microsoft Word format (.docx) using {it:filename}.
{p_end} 

{phang}
{cmdab:gr:aph(}{it:filename}{cmd:)} : displays a bar graph showing the absolute contribution of each 
indicator to disempowerment, calculated by multiplying the censored inadequacy 
headcount ratio by the indicator weight. Saves graph in Stata .gph format using {it:filename}. To reproduce the color scheme
used in {browse "https://doi.org/10.1016/j.worlddev.2019.06.018":Malapit et al. (2019)} use the {cmd: weai} scheme, provided in the 
ancillary files of the {cmd:weai} package. Note 
that labels for the binary indicator variables should 
be no longer than 80 characters to avoid an error. {p_end} 

{phang}
{opth by(varname)} : decomposes all of the output measures by categories of {help varname}. Must 
be numeric. Missing values are excluded from the estimation sample.{p_end}
 
{title:Examples using "WEAI_examples.dta"}

{p 2 2 2} Pro-WEAI with {cmdab:d:etails} option: 

{pmore}{cmd: weai} d1(autonomy_inc selfeff never_violence) d2(feelinputdecagr assetownership credit_accdec incomecontrol work_balance mobility) 
d3(groupmember), sex(sex) female(2) hhid(hhid) details{p_end}

{p 2 2 2} Pro-WEAI with 8 indicators and {cmdab:gr:aph} option using {cmd:weai} scheme:{p_end}

{pmore} {cmd: set scheme} weai{p_end}
{pmore} {cmd: weai} d1(autonomy_inc never_violence) d2(feelinputdecagr assetownership credit_accdec incomecontrol work_balance) d3(groupmember), 
cutoff(0.75) sex(sex) female(2) hhid(ID) graph{p_end}

{p 2 2 2} Pro-WEAI, disagreggated by group:{p_end}
 
{pmore}{cmd: egen} project = group(group){p_end}
{pmore}{cmd:label variable} project "Project"{p_end}
{pmore}{cmd:tabulate} project{p_end}
{pmore}{cmd: weai} d1(autonomy_inc selfeff never_violence) d2(feelinputdecagr assetownership credit_accdec incomecontrol work_balance mobility) 
d3(groupmember), sex(sex) female(2) hhid(hhid) by(project){p_end}

{p 2 2 2} A-WEAI:{p_end}

{pmore} {cmd: weai} d1(feelinputdecagr) d2(assetownership credit_accdec) d3(incomecontrol) d4(work_balance) d5(groupmember) 
w1(0.2) w2(0.13333 0.06667) w3(0.2) w4(0.2) w5(0.2), sex(sex) female(2) hhid(hhid){p_end}

{title:Stored results}

{p 2 2 2} The individual-/household-level indicators ({cmd:empowered}, {cmd:emp_score}, 
{cmd:gender_parity}, and {cmd:hh_ineq}) are saved as new variables in the dataset. Aggregate indices 
({cmd:emp_index}, {cmd:gpi}, and {cmd:weai}) reflecting the 5/3DE, GPI, and WEAI/A-WEAI/pro-WEAI, 
respectively, are also saved as new variables in the dataset. Additionally, the aggregate 
indices and related tables are displayed in table format and optionally saved as a Microsoft Word document 
(.docx). Related figures are optionally generated and 
saved in Stata .gph format.


{title:References}

{p 2 2 2} Alkire, S., & Foster, J. (2011). Counting and multidimensional poverty measurement. 
{it:Journal of Public Economics}, 95(7–8), 476–487. {browse "https://doi.org/10.1016/j.jpubeco.2010.11.006"} {p_end} 
{p 2 2 2}  
Alkire, S., Meinzen-Dick, R., Peterman, A., Quisumbing, A., Seymour, G., & Vaz, A. (2013). The 
Women's Empowerment in Agriculture Index. {it:World Development}, 52, 
71–91. {browse "https://doi.org/10.1016/j.worlddev.2013.06.007"} {p_end}

{p 2 2 2} Malapit, H., Quisumbing, A., Meinzen-Dick, R., Seymour, G., Martinez, E., Heckert, J., 
Rubin, D., Vaz, A., & Yount, K. (2019). Development of the project-level Women's Empowerment 
in Agriculture Index (pro-WEAI). {it:World Development}, 122, 675–692. 
{browse "https://doi.org/10.1016/j.worlddev.2019.06.018"}{p_end}

{p 2 2 2} Malapit, H., Pinkstaff, C., Sproule, K., Kovarik, C., Quisumbing, A., & Meinzen-Dick, R. 
(2017). The Abbreviated Women's Empowerment in Agriculture Index (A-WEAI). 
IFPRI Discussion Paper, No. 1647. Washington, DC: International Food Policy Research 
Institute 
(IFPRI). {browse "https://www.ifpri.org/publication/abbreviated-womens-empowerment-agriculture-index-weai"}{p_end}


{title:Authors}

{p 2 2 2} 
Malick Dione, International Food Policy Research Institute{p_end}

{p 2 2 2} 
Greg Seymour, United States Census Bureau{p_end}

{p 2 2 2} 
Nathaniel Ferguson, International Food Policy Research Institute{p_end}

{p 2 2 2} 
Hazel Malapit, International Food Policy Research Institute{p_end}


{title:For more information visit the WEAI Resource Center}

{p 2 2 2}  
{browse "https://weai.ifpri.info/":https://weai.ifpri.info/}{p_end}


{title:Contact us}

{p 2 2 2} 
{browse "mailto:IFPRI-WEAI@cgiar.org":IFPRI-WEAI@cgiar.org}{p_end}


