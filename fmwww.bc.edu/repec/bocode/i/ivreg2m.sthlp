{smcl}
{* *! version 1.0 02july2022}{...}
{hline}
help for {hi:ivreg2m}
{hline}
{viewerjumpto "Syntax" "ivreg2m##syntax"}{...}
{viewerjumpto "Description" "ivreg2m##description"}{...}
{viewerjumpto "Options" "ivreg2m##options"}{...}
{viewerjumpto "Examples" "ivreg2m##examples"}{...}
{viewerjumpto "Stored results" "ivreg2m##results"}{...}
{viewerjumpto "References" "ivreg2m##references"}{...}
{p}
{title:Instrumental variable method to identify treatment-effects estimates with potentially misreported and endogenous program participation}

{marker syntax}{...}

{title:Syntax}

{p 6 14 0 0}{cmd:ivreg2m} {it:depvar} [{it:varlist}] ({cmd:treatment}={it:varlist_iv}) [{it:weight}] [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [{cmd:,} {cmd:ta}({it:string}) {cmd:tb}({it:string}) {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr :Required:}
{synoptline}
{syntab:Model}
{synopt :{cmd:treatment}} specifies the name of the endogenous misclassified treatment variable.{p_end}
{synopt :{cmd:ta}({it:string})} specifies the numeric value(s) of the variable {cmd:treatment} defining the treatment group. The default is ta(1).{p_end}
{synopt :{cmd:tb}({it:string})} specifies the numeric value(s) of the variable {cmd:treatment} defining the control group. The default is tb(-1).{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ivreg2m} can be invoked to estimate the average causal effect for compliers (Imbens and Angrist, 1994) in a traditionally identified single equation when both non-compliance and 
misreporting of treatment status are present. The approach follows the estimation procedure developed in Calvi, Lewbel and Tommasi (2021) and Tommasi and Zhang (2022).

{pstd}
The implementation has been built using the frameworks of the existing {cmd:xtivreg2} (Schaffer, 2020) and {cmd:ivreg2} (Baum, Schaffer, Stillman, 2015) routines. As {cmd:ivreg2m} is a variant of {cmd:ivreg2}, 
almost all of the features and options of ivreg2 are available in {cmd:ivreg2m}. For that reason, you should consult help {cmd:ivreg2} for details of the available options.

{pstd}
There are three major differences between {cmd:ivreg2m} and {cmd:ivreg2}. First, the {cmd:ivreg2m} command gives an error message if the user utilizes a continuous variable in {cmd:treatment}.
Hence, before running the command, the user must generate a discrete {cmd:treatment} variable taking (at least) three values: (at least) one defining the treatment group (specified in {cmd:ta}), 
(at least) one defining the control group (specified in {cmd:tb}), and the rest defining the missing, mismeasured, or unknown status. 
Second, there can be one or more instrumental variables, but they must take binary or discrete (integer) values. 
Third, only one-way clustering of the VCE is supported.

{pstd}
The {cmd:ivreg2} and {cmd:ranktest} packages must be installed from the SSC Archive. Earlier versions of ivreg2 should not be used.


{marker examples}{...}
{title:Examples}

{pstd}Clear memory and load the 401ksubs dataset{p_end}
{p 8 12}{stata "bcuse 401ksubs, clear" : . bcuse 401ksubs, clear}

{pstd}Generate a treatment variable taking (at least) three values:{p_end}
{p 8 12}{stata "generate treat = (p401k & pira)" : . generate treat = (p401k & pira)}{p_end}
{p 8 12}{stata "replace treat = -1 if (p401k==0 & pira==0)" : . replace treat = -1 if (p401k==0 & pira==0)}

{pstd}ivreg2m estimation including misclassified treatment taking 3 values and a binary instrument{p_end}
{p 8 12}{stata "ivreg2m nettfa (treat = e401k), ta(1) tb(-1)" : . ivreg2m nettfa (treat = e401k), ta(1) tb(-1)}

{pstd}ivreg2m estimation including covariates and robust VCE {p_end}
{p 8 12}{stata "ivreg2m nettfa (treat = e401k) inc, robust ta(1) tb(-1)" : . ivreg2m nettfa (treat = e401k) inc, robust ta(1) tb(-1)}

{pstd}ivreg2m estimation including multiple instruments and cluster-robust VCE {p_end}
{p 8 12}{stata "ivreg2m nettfa (treat = e401k pira) inc, cluster(age) ta(1) tb(-1)" : . ivreg2m nettfa (treat = e401k pira) inc, cluster(age) ta(1) tb(-1)}


{marker references}{...}
{title:References}


{phang}
Baum, C., M. Schaffer, and S. Stillman. 2007. ivreg2: Stata module for extended instrumental variables/2SLS and GMM and AC/HAC, LIML and k-class regression. http://ideas.repec.org/c/boc/bocode/s425401.html {p_end}

{phang}
Calvi, R., A. Lewbel, and D. Tommasi. 2021. LATE With Missing or Mismeasured Treatment. Journal of Business & Economic Statistics, forthcoming. https://doi.org/10.1080/07350015.2021.1970573

{phang}
Imbens, G. W., and J. D. Angrist. 1994. Identification and Estimation of Local Average Treatment Effects. Econometrica 62(2): 467-475.

{phang}
Schaffer, M. 2020. XTIVREG2: Stata module to perform extended IV/2SLS, GMM and AC/HAC, LIML and k-class regression for panel data models.  http://ideas.repec.org/c/boc/bocode/s456501.html

{phang}
Tommasi, D., and L. Zhang. 2022. Identifying Program Benefits When Participation Is Misreported. IZA Discussion Paper 13430. https://docs.iza.org/dp13430.pdf


{marker remarks}{...}
{title:Remarks}

{phang}
If you use this command in your work, please cite Calvi, Lewbel and Tommasi (2021) and Tommasi and Zhang (2022).


{marker authors}{...}
{title:Authors}

Christopher F Baum
Boston College, USA
{browse "mailto:kit.baum@bc.edu":kit.baum@bc.edu}

Denni Tommasi
University of Bologna, Italy
{browse "mailto:denni.tommasi@monash.edu":denni.tommasi@monash.edu}

Lina Zhang
University of Amsterdam, The Netherlands
{browse "mailto:l.zhang5@uva.nl":l.zhang5@uva.nl}
