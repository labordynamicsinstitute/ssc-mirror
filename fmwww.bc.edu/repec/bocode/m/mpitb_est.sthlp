{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb est##syntax"}{...}
{viewerjumpto "Description" "mpitb est##description"}{...}
{viewerjumpto "Options" "mpitb est##options"}{...}
{viewerjumpto "Remarks" "mpitb est##remarks"}{...}
{viewerjumpto "Examples" "mpitb est##examples"}{...}
{p2colset 1 14 16 2}{...}
{p2col:{bf:mpitb est} {hline 2}} estimates indices and subindices of multidimensional poverty{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb est} {ifin} [{cmd:,} {it:options}]

{synoptset 29 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:{help mpitb est##measures:Measures and parameters}}
{p2coldent :* {opt n:ame(mpiname)}}name of the MPI to be estimated{p_end}
{p2coldent :† {opth k:list(numlist)}}specifies the poverty cutoffs{p_end}
{p2coldent :† {opt w:eights(wgts [sopts])}}specifies the weighting scheme{p_end}
{synopt :{opt m:easures(mlist)}}(aggregate) measures of the AF framework to estimate{p_end}
{synopt :{opt indm:easures(imlist)}}indicator-specific measures of the AF framework to estimate{p_end}
{synopt :{opth indk:list(numlist)}}poverty cutoffs for indicator-specific measures{p_end}
{synopt :{opt aux(auxlist)}}auxiliary measures to be estimated{p_end}

{syntab:{help mpitb est##cot:Changes over time}}
{p2coldent :‡ {opt cotm:easures(mlist)}}measure list for COT estimation{p_end}
{synopt :{opt coto:ptions(olist)}}option list for COT estimation{p_end}
{synopt :{opth cotk(numlist)}}poverty cutoffs for COT estimation{p_end}
{p2coldent :‡ {opth coty:ear(varname)}}year variable for COT calculations{p_end}

{syntab:{help mpitb est##results:Results}}
{synopt :{opt dta:save(filename [,sopts])}}save micro data sets{p_end}
{synopt :{opt lfr:ame(name [,sopts])}}frame name to store (level) estimates{p_end}
{synopt :{opt lsa:ve(filename [,sopts])}}filename to save (level) estimates{p_end}
{synopt :{opt cotfr:ame(name [,sopts])}}frame name of to store COT estimates{p_end}
{synopt :{opt cotsa:ve(filename [,sopts])}}filename to save COT estimates into{p_end}

{syntab:{help mpitb est##other:Other}}
{synopt :{opt o:ver(varlist [,sopts])}}variables for disaggregation{p_end}
{p2coldent :‡ {opth tv:ar(varname)}}integer time variable (indicating survey rounds){p_end}
{synopt :{opt svy}}treat data as complex survey data{p_end}
{synopt :{opt addmeta(metalist)}}meta data to be added to each estimate{p_end}
{synopt :{opt skipgen}}skips the step of generating variables{p_end}
{synopt :{opt gen}}keeps the variables generated{p_end}
{synopt :{opt replace}}replaces potentially existing variables{p_end}
{synopt :{opt dou:ble}}generate non-{bf:byte} variables as {bf:double}; default is {bf:float}{p_end}
{synopt :{opt noestimate}}skip estimation{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}* required options; † required for all aggregate and dimensional measures; ‡ required option for estimation of changes over time (COT).{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb est} estimates indices and subindices of multidimensional poverty 
for one or more parametrizations. Deprivation indicators have to be declared by {helpb mpitb set}
beforehand.{p_end}

{pstd}
{cmd:mpitb est} estimates levels, levels over time, and changes over time at the 
aggregate level and for subgroups. {cmd:mpitb est} provides standard errors and 
confidence intervals for most quantities and may take complex survey design into
account.{p_end}

{pstd}
Results may be coherently saved to disk or collected in frames (see {helpb frames}).{p_end}

{pstd}{cmd:mpitb est} may create key variables for the Alkire-Foster (AF) framework and a 
variable identifying the underlying sample (which takes, e.g., item non-responses into account).{p_end}

{marker options}{...}
{title:Options}

{marker measures}
{dlgtab:Measures and Parameters}

{phang}
{opt n:ame(name)} name of the MPI to be estimated (which also serves as ID){p_end}

{phang}
{opth k:list(numlist)} specifies the (cross-dimensional) poverty cutoff(s) in percentage points.
Valid values are integers between 1 and 100. One or more values may be specified.{p_end}

{phang}
{opt m:easures(mlist)} the list of permitted measures may include {it:M0}, {it:H}, 
{it:A}, or {it:all}.{p_end}

{phang}
{opt w:eights(wgts [, sopts])} specifies the weighting scheme(s), where {it:wgts} may be one of
{p_end}

{p 8 11 2}
{opt equal} this option applies a equal-nested weighting scheme, which assigns equal 
weights to all dimensions and within dimensions equal weights to all indicators.
{p_end}

{p 8 11 2}
{opth dimw(numlist)} allows to set arbitrary weighting schemes for dimensions. 
Weighting schemes can be set using decimal numbers from 0-1. Naturally, the number 
of weights has to match the number of dimensions and weights must sum up to one.
The order of dimension corresponds to the order used in {cmd:mpitb set}.
Indicator weight within dimensions receive equal weights.
{p_end}

{p 8 11 2}
{opth indw(numlist)} allows to set arbitrary weighting schemes for indicators. 
Weighting schemes can be set using decimal numbers from 0-1. Naturally, the number 
of weights has to match the number of indicator and weights must sum up to one.
The order of indicators corresponds to the order used in {cmd:mpitb set}.
{p_end}

{p 8 11 2}
Moreover, {it:sopts} may be {opt name(wgtsname)}. This option allows to assign 
names to particular weighting schemes and is required for use with {opth ind(numlist)}
while being optional for the others.
{p_end}


{phang}
{opt indm:easures(imlist)} the list of indicator-specific measures may include 
{it:hdk} (censored headcount ratios), {it:actb} (absolute contributions), {it:pctb}
(percentage contribution), or {it:all}.

{phang}
{opth indk:list(numlist)} allows to choose a different set of poverty cutoffs for 
indicator-specific measures to avoid unnecessarily long estimations for numbers of lower
priority. Unless explicitly set, {opt indklist} equals {opt klist}.

{phang}
{opt aux(auxlist)} the list of auxiliary measures may include {it:hd}, the uncensored
deprivation headcount ratios, {it:mv}, {it:N} or {it:all}. {it:mv} includes the share of 
missing values on the indicator level and the retained sample at the aggregate level.
The retained sample will be reported with and without sampling weights (if {opt svy} is set).
{it:N} is the effective sample size, i.e. the number of observations with non-missing
information on all indicators.

{marker cot}
{dlgtab:Changes over time}

{phang}
{opt cotm:easures(mlist)} the changes over time (COT) measure list may include {it:M0} (the adjusted 
headcount ratio), {it:H} (the headcount ratio), {it:A} (the intensity), {it:hd} 
(uncensored headcount ratios), {it:hdk} (censored headcount ratios), or {it:all}.

{phang}
{opt coto:ptions(olist)} where {it:olist}, the option list for COT, may include

{p 8 11 2}
{opt tot:al} estimates change over total period of observation, i.e. from the first
year of observation to the last year of observation.
{p_end}

{p 8 11 2}
{opt inseq:uence} estimates all consecutive (i.e. year-to-year) changes. 
{p_end}

{p 8 11 2}
{opt ann} produces annualized changes over time. This option is activated by default.  
Specify {cmd:noann} to skip the estimation of annualized changes.{p_end}

{p 8 11 2}
{opt raw} produces the raw, i.e. non-annualized changes over time. This option is activated 
by default. Specify {cmd:noraw} to skip the estimation of raw changes.{p_end}

{phang}
{opth cotk(numlist)} specifies the poverty cutoffs for the COT estimation{p_end}

{phang}
{opth coty:ear(varname)} specifies the variable which is used for the annualization, 
which is usually a year variable, where decimal digits are permitted.{p_end}

{marker results}
{dlgtab:Results}

{phang}
{opt dta:save(filename [, sopts])} saves the micro data after creating the variables of 
the AF-framework. This can be particularly useful when {cmd:mpitb est} is run within 
a loop over countries. Available suboptions {it:sopts} are{p_end}

{phang2}
{opt replace} which replaces any potentially existing dataset.{p_end}

{phang}
{opt lfr:ame(name [, sopts])} stores the level estimates into a result frame under the specified 
name. This option can be useful for adding further custom estimates before saving 
all results to disk. See {helpb mpitb stores} for adding estimates of custom quantities 
to the result frame. Available suboptions {it:sopts} are{p_end}

{phang2}
{opt replace} which replaces any potentially existing frame{p_end}

{phang}
{opt lsa:ve(filename [, sopts])} saves the levels estimates into the specified dta file. 
Available suboptions {it:sopts} are{p_end}

{phang2}
{opt replace} which replaces any potentially existing dataset{p_end}

{phang}
{opt cotfr:ame(name [, sopts])} saves the change estimates into a result frame under the specified 
name. Note that a potentially existing frame will be replaced. This option can be 
useful for adding further custom estimates before saving all results to disk. See 
{helpb mpitb stores} for adding estimates of custom quantities to the result frame.
Available suboptions {it:sopts} are{p_end}

{phang2}
{opt replace} which replaces any potentially existing dataset{p_end}

{phang}
{opt cotsa:ve(filename[, sopts])} saves the change estimates into the specified dta file. 
Available suboptions {it:sopts} are{p_end}

{phang2}
{opt replace} which replaces any potentially existing dataset{p_end}

{marker other}
{dlgtab:Other}

{phang}
{opt o:ver(varlist [, sopts])} allows to disaggregate by several variables. By default 
quantities for the subgroups are estimated for the same measure and parameters as the 
aggregate quantities. Suboptions allow to avoid unnecessarily long estimations for 
numbers of lower priority. Available suboptions {it:sopts} are{p_end}

{phang2}
{opth k:list(numlist)} allows to choose a different set of poverty cutoffs for disaggregations.{p_end}

{phang2}
{opth indk:list(numlist)} allows to choose a different set of poverty cutoffs for 
disaggregations of indicator-specific measures.{p_end}

{phang2}
{opt nooverall} if this option is set aggregate (or national-level) estimates will not be 
produced. This option may be useful for organizing results across different files.

{phang}
{opt svy} estimation accounts for complex survey design of micro data as specified 
by {helpb svyset}. If {opt svy} is not set, the data is assumed to be obtained through
simple random sampling, which is rarely used in practice.{p_end}

{phang}
{opth addmeta(metalist)} allows to add meta data to every estimate produced. A common
application would be to add the ISO country code. {it:metalist} is used as follows {p_end}

{p 8 11 2}
{it:macname=content} [{it:macname2=content2} ...]
{p_end}

{phang}
{opt skipgen} this option allows to skip the step of generating all variables of 
the AF-framework. This can save runtime if variables have already been created by 
a {cmd:mpitb est} run previously. A common application is to save different results 
into a single file. However, it is up to the user to ensure that all needed 
variables do exist and that the results files are coherently augmented.{p_end}

{phang}
{opt gen} The default behavior of {cmd:mpitb est} is to remove all variables 
(e.g., deprivation scores or poverty status) generated upon completion of the estimations. 
Option {opt gen} allows to keep all variables for cross-checks or additional calculations.{p_end}

{phang}
{opt replace} will replace potentially existing variables.{p_end}

{phang}
{opt dou:ble} generates non-{bf:byte} variables as {bf:double}, which improves the 
precision with which, e.g., the deprivation score is stored as variable. The default 
is {bf:float}; see {helpb data types} for more details.{p_end}


{phang}
{opt noestimate} allows to skip the entire estimation process. This allows to 
save time if only the generated variables are of interest.{p_end}

{marker remarks}
{title:Remarks}

{phang}
(1) {cmd: mpitb est} is a high-level command and invokes several of the other 
rather low-level tools of {cmd:mpitb}, including {helpb mpitb setwgts}, {helpb gafvars}, 
{helpb rframe}, {helpb estcot}, {helpb mpitb stores}. Therefore, working only with 
{helpb mpitb set} and {cmd:mpitb est} may suffice in many instances.{p_end}

{phang}
(2) For further detail on the variables generated by the {cmd:gen} option, see 
{helpb mpitb gafvars##remarks:mpitb gafvars}.{p_end}

{phang}
(3) The default confidence level for confidence intervals is 95% and may be changed 
using {helpb set level}.{p_end}

{marker examples}
{title:Examples}

    {hline}
{pstd} 
Setup {p_end}
{pmore}
{cmd: use ...}{p_end}
{pmore}
{cmd: svyset ...}{p_end}
{pmore}
{cmd:mpitb set , name(mympi) ... }{p_end}

{pstd}
The following commands estimates {it:all} measures, i.e. H, M0, and A for the aggregate 
(i.e. national) level for k=33 and an equal-nested weighting scheme. Estimates are 
not automatically stored, but left behind in Stata's memory.{p_end}

{phang2}
{cmd: mpitb est , name(mympi) k(33) weights(equal) measures(all) ...}
{p_end}

{pstd}
Alternative weighting schemes can be obtained along the following lines. Note that 
seven decimal digits are required in this case, since the check for the weights
summing up to 1 applies float precision.{p_end}

{phang2}
{cmd: mpitb est , name(mympi) k(33) weights(dim(.3333333 .3333333 .3333333)) measures(all) ...}
{p_end}

{pstd}
Indicator weights can be specified in a similar fashion:{p_end}

{phang2}
{cmd: mpitb est , name(mympi) k(33) weights(ind(.1 .1 .1 .1 .1 .1 .1 .1 .1 .1)) measures(all) ...}
{p_end}

    {hline}



