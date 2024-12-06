{smcl}
{* *! version 1.0.0}{...}
{vieweralsosee "stpp" "help stpp"}{...}
{vieweralsosee "standsurv" "help standsurv"}{...}
{viewerjumpto "Syntax" "genindweights##syntax"}{...}
{viewerjumpto "Description" "genindweights##description"}{...}
{viewerjumpto "Options" "genindweights##options"}{...}
{viewerjumpto "Examples" "genindweights##examples"}{...}
{viewerjumpto "Stored results" "genindweights##results"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:genindweights} {hline 2}}Generate individual weights for standardization{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:genindweights} {newvar} {ifin}
[{cmd:,} {it:options}]

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ageg:roup(varname)}}name of age group variable{p_end}
{synopt:{opt by(varlist)}}calculate weights separately by {it:varlist}{p_end}
{synopt:{opt obsp:roportion(newvar)}}save observed proportions{p_end}
{synopt:{opt refc:onditional(expression)}}reference weights defined by conditioning on data{p_end}
{synopt:{opt refext:ernal(string)}}reference weights defined externally{p_end}
{synopt:{opt reffr:ame(framename)}}reference weights stored in frame{p_end}
{synopt:{opt refp:roportion(framename)}}save reference proportion{p_end}
{synopt:{opt savereffr:ame(newframename)}}save reference weights to new frame{p_end}
{synopt:{opt stig:nore}}do not do survival data checks{p_end}
{synopt:{opt nosum:mary}}do not display summary table{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:genindweights} calculate individual weights that are needed for standardization
to a reference population. It will commonly be used for age standardization of
(relative) survival (Rutherford {it:et al. 2020}), but can also be used more generally.
Individuals are upweighted or downweighted relative to a reference population.

{pstd}
The reference population can be defined in three different ways.

{phang2}
(1) Using the {cmd:refexternal()} option for known external weights, such as the international cancer survival standard (ICSS) weights.

{phang2}
(2) Using the {cmd:refframe()} option for weights stored in a frame.

{phang2}
(3) Using the {cmd:refconditional()} option for weights calculated on a subset of the data.

{marker options}{...}
{title:Options}

{phang}
{opt agegroup(varname)} specifies name of the variable that defines age groups.
This option is compulsory when using {cmd:refexternal()}, 
but cannot be used when using {cmd:refframe()} or {cmd:refconditional()}.

{phang}
{opt by(varlist)} will calculate relative weights separately for each of the groups 
defined by {it:varlist}.

{phang}
{opt obsproportion(newvarname)} save the observed proportions in a new variable.

{phang}
{opt refconditional([exp], strata(varlist)} defines the reference subpopulation based on expression {it:exp}.
For example, it is sometimes useful to age standardize to the most recent
calendar period when investigating time trends. 
The {cmd:strata()} option is compulsory and gives the variables that defines the groups
to standardize over. 

{phang}
{opt refexternal(external_weights)} gives the name of the external weights used for age
standardization. 

{phang2}
For the traditional ICSS five age groups (Corazziari {et al.} 2004) the weights, and correspnding options, are defined as follows:

                  {c |} ICSS1_5    ICSS2_5    ICSS3_5 
           {hline 7}{c +}{hline 30}
           15-44  {c |}  0.07       0.28         0.6
           45-54  {c |}  0.12       0.17         0.1
           55-64  {c |}  0.23       0.21         0.1
           65-74  {c |}  0.29       0.20         0.1
           75+    {c |}  0.29       0.14         0.1

{phang3}
Note that often the youngest group is defined for ages 18-44.           
           
{phang2}
For the adapted ICSS five age group weights used in the NORDCAN survival studies (Lundberg {it:et al.} 2020),
the weights, and corresponding options, are defined as follows:

                  {c |} ICSS1_5N      ICSS2_5N   
           {hline 7}{c +}{hline 30}
           18-49  {c |}  0.11906       0.36283       
           50-59  {c |}  0.16735       0.18611       
           60-69  {c |}  0.27593       0.22098       
           70-79  {c |}  0.28897       0.16262       
           80+    {c |}  0.14869       0.06746       

{phang2}           
Note that it is the responsibility of the user to define age groups appropriately.           
           
{phang}
{opt refframe(framename, strata(varlist) refwtname(varname))} gives the name of the frame where external weights are stored.
The {cmd:strata()} option is compulsory and gives the variables that defines the groups
to standardize over. These variables must exist in both the active frame and the
frame containing the weights. 
The {cmd:refwtname()} option gives the name of the variable containing the reference weights.
By default, this variable is named {cmd:refp}.

{phang}
{opt refproportion(newvarname)} save the reference proportions in a new variable.

{phang}
{opt saverefframe(newframename)}{bf:, [replace refwtname({it:varname}))} gives the name of a new frame to save the
external weights. This is useful when using the {cmd:refconditional()} option,
so that the weights can be applied to a different dataset.
The default name of the reference proportions is {cmd:refp}, but this can 
be changed with the {cmd:refwtname()} option.

{phang}
{opt nosummary} do not display summary table of weights.

{phang}
{opt stignore} do not do survival analysis checks. Although {cmd:genindweights} was
originally developed for use with survival data, it is also potentially useful in other contexts,
so this option will omit any checks that data has been {cmd:stset} and {cmd:_st=1}.

         
{marker examples}{...}
{title:Examples}

{pstd}
The examples here show the use of individual weights for standardization of non-parametric estimates
of relative survival using {help stpp}. However, these weights are useful in many contexts. 
For example, when using regression standardization using {help standsurv}. 

{phang}
You can run the code below without losing your data as each example is run
using {cmd:preserve} and {cmd:restore}.


{dlgtab:Example 1}

{pstd}
The {cmd:refexternal()} option uses some standard external reference weights.
In the example below the ICCS1 weights in 5 year age groups is used.
You need to define the age groups using the same definitions as used for ICSS1,
but note that this is the responsibility of the user. 
The use of the {cmd:by(sex)} option in {cmd:genindweights} calculates the 
reference weights separately in males and females.
This is necessary as the following {cmd:stpp} command calculates estimates
stratified by sex.

{cmd}{...}
{phang2}
. use https://pclambert.net/data/colon.dta , clear{p_end}
{phang2}
. stset surv_mm,f(status=1,2) id(id)  scale(12){p_end}
{phang2}
// Form ICSS age groups{p_end}
{phang2}
. recode age (min/44=1) (45/54=2) (55/64=3) (65/74=4) (75/max=5), gen(ICSSagegrp){p_end}
{phang2}
. genindweights wt1, by(sex) agegroup(ICSSagegrp) refexternal(ICSS1_5){p_end}
{pmore}
. stpp R_pp using "https://pclambert.net/data/popmort.dta",  ///{p_end}
{p 16 20 2}
agediag(age) datediag(dx) {bind:                          }///{p_end}
{p 16 20 2}
pmother(sex) list(1 5 )   {bind:                            }///{p_end}
{p 16 20 2}
by(sex)  {bind:                                           }       ///{p_end}
{p 16 20 2}
indweights(wt1){p_end}
{txt}{...}
{pmore}
{it:({stata genindweights_egs 1:click to run})}{p_end}

{dlgtab:Example 2}

{pstd}
This example illustrates the use of the {cmd:refframe()} option.
It will give identical estimates to Example 1, but the weights
are provided in a frame.

{cmd}{...}
{phang2}
. use https://pclambert.net/data/colon.dta , clear{p_end}
{phang2}
. stset surv_mm,f(status=1,2) id(id)  scale(12){p_end}
{phang2}
// Form ICSS age groups{p_end}
{phang2}
. recode age (min/44=1) (45/54=2) (55/64=3) (65/74=4) (75/max=5), gen(ICSSagegrp){p_end}
{phang2}
. frame create ageweights{p_end}
{phang2}
. frame ageweights {{p_end}
{phang3}
input ICSSagegrp wt{p_end}
{p 16 20 2}
      1 0.07{p_end}
{p 16 20 2}
      2 0.12{p_end}
{p 16 20 2}
      3 0.23{p_end}
{p 16 20 2}
      4 0.29{p_end}
{p 16 20 2}
      5 0.29{p_end}
{phang3}
end{p_end}
{phang2}
. }{p_end}
{phang2}
// These are ICSS1 weights so will give same estimate as above{p_end}
{phang2}
// strata gives the strata in the reference frame{p_end}
{phang2}
. genindweights wt2, by(sex) {bind:                              } ///{p_end}
{p 16 20 2}
refframe(ageweights, strata(ICSSagegrp) wtname(wt)){p_end}
{phang2}
. stpp R_pp using "https://pclambert.net/data/popmort.dta", ///{p_end}
{p 16 20 2}
agediag(age) datediag(dx){bind:text                       ///}{p_end}
{p 16 20 2}
pmother(sex) list(1 5){bind:text                          ///}{p_end}
{p 16 20 2}
by(sex){bind:text                                         ///}{p_end}
{p 16 20 2}
indweights(wt2){p_end}
{txt}{...}
{pmore}
{it:({stata genindweights_egs 2:click to run})}{p_end}

{dlgtab:Example 3}

{pstd}
This example illustrates the use of the {cmd:refconditional()} option.
The analysis age standardizes to the age distribution of males,
using 10 approximately equal sized age groups.
Note that the the reference probabilities are stratified by 
the {cmd:strata()} suboption of {cmd:refconditional()} and the
observed probabilities are stratified by the {cmd:by()} option.
The individual weights are the ratio of reference/observed probabilities. 

{cmd}{...}
{phang2}
. use https://pclambert.net/data/colon.dta , clear{p_end}
{phang2}
. stset surv_mm,f(status=1,2) id(id)  scale(12){p_end}
{phang2}
. egen agegrp10 = cut(age), group(10){p_end}
{phang2}
. genindweights wt3, by(sex) refconditional(sex==1, strata(agegrp10)){p_end}
{pmore}
. stpp R_pp using "https://pclambert.net/data/popmort.dta", ///{p_end}
{p 16 20 2}
agediag(age) datediag(dx){bind:                           }///{p_end}
{p 16 20 2}
pmother(sex) list(1 5 ){bind:                             }///{p_end}
{p 16 20 2}
by(sex){bind:                                             }///{p_end}
{p 16 20 2}
indweights(wt3){p_end}
{txt}{...}
{pmore}
{it:({stata genindweights_egs 3:click to run})}{p_end}

{dlgtab:Example 4}

{pstd}
This example is similar to above, but shows use of the
{cmd:obsproportion()}, {cmd:refproportion()} and {cmd:saverefframe()} options.
The {cmd:obsproportion()} and {cmd:refproportion()} options
saves in new variables the observerved and reference proportions respectively.
The {cmd:saverefframe()} option saves the reference proportions in a new
frame. This can later be used in a new dataset using the {cmd:refframe()} option.

{cmd}{...}
{phang2}
. use https://pclambert.net/data/colon.dta , clear{p_end}
{phang2}
. stset surv_mm,f(status=1,2) id(id)  scale(12){p_end}
{phang2}
. egen agegrp10 = cut(age), group(10){p_end}
{phang2}
. genindweights wt3, by(sex) refconditional(sex==1, strata(agegrp10)) ///{p_end}
{p 16 20 2}
obsproportion(obsp) refproportion(refp) {bind:               }     ///{p_end}
{p 16 20 2}
saverefframe(age10ref){p_end}
{phang2}
. summ obsp refp{p_end}
{phang2}
. frame age10ref: list, noobs abbrev(13){p_end}
{txt}{...}
{pmore}
{it:({stata genindweights_egs 4:click to run})}{p_end}

{title:Author}

{p 5 12 2}{bf:Paul C. Lambert}{p_end}        
{p 5 12 2}Cancer Registry of Norway{p_end}
{p 5 12 2}National Institute of Public Health{p_end}
{p 5 12 2}Oslo, Norway{p_end}
{p 5 12 2}{it: and}{p_end}
{p 5 12 2}Department of Medical Epidemiology and Biostatistics{p_end}
{p 5 12 2}Karolinska Institutet{p_end}
{p 5 12 2}Stockholm, Sweden{p_end}
{p 5 12 2}pclt@kreftregisteret.no{p_end}


{title:References}

{phang}
I. Corazziari, M. Quinn, R. Capocaccia. 
{browse "https://doi.org/10.1016/j.ejca.2004.07.002":Standard cancer patient population for age standardising survival ratios.}
{it:European Journal of Cancer} 2004;{bf:40}:2307-16. 

{phang}
F.E. Lundberg, T.M-L. Andersson, M. Lambe, G. Engholm, L. Steinrud Mørch, T.B. Johannesen, A. Virtanen, 
D. Pettersson, E.J. Ólafsdóttir, H. Birgisson, A.L.V. Johansson, P.C Lambert.
{browse "https://doi.org/10.1080/0284186X.2020.1822544":Trends in cancer survival in the Nordic countries 1990-2016:the NORDCAN survival studies.}
{it:Acta Oncologica} 2020;{bf:59}:1266–1274 

{phang}
M. Pohar Perme, J. Stare, J. Estève. {browse "https://doi.org/10.1111/j.1541-0420.2011.01640.x":On estimation in relative survival.} 
{it:Biometrics} 2012;{bf:68}:113-120 

{phang}
M.J. Rutherford, P.W. Dickman, E. Coviello, P.C. Lambert. {browse "https://doi.org/10.1016/j.canep.2020.101745":Estimation of age-standardized net survival, even when age-specific data are sparse.}
{it:Cancer Epidemiology} 2020;{bf:67}:101745. 






