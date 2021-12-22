{smcl}
{* *! version 0.2 28oct2021}{...}
{vieweralsosee "Main artbin help page" "artbin"}{...}
{title:Title}

{phang}
{bf:What's new in artbin} {hline 2} Changes from {cmd:artbin} version 1.1.2 to version 2.0

{title:New features}

{pstd}
A {opt margin(#)} option for 2-arm trials has been included.
{p_end}
{pstd}
The user can now specify whether the outcome is {opt favourable} or {opt unfavourable} for a
2-arm trial.
{p_end}
{pstd}
The {opt wald} option has also been included for the Wald test.
{p_end}
{pstd}
The {opt local} option has been included for local alternatives, otherwise the default distant
will be used.
{p_end}
{pstd}
Sample size per group is now reported, and rounding up to the nearest integer is performed
per group.
{p_end}
{pstd}
A {opt noround} option has been included for the case when the user does not want {cmd:artbin}
to round the calculated sample size.
{p_end}
{pstd}
A loss to follow-up option is now available ({opt ltfu(#)}).
{p_end}


{title:New syntax}

{pstd} Some improvements have been made to {cmd:artbin}.  The user will need to alter previous coding using {cmd:artbin} to
accomodate the following changes. 

{pstd}  The syntax for {cmd: artbin} has been updated to include a {opt margin(#)} option for 2-
arm trials. For a non-inferiority/substantial-superiority trial the program will use {cmd:pr(p1 p2)} AND the new
option {opt margin(#)}.  For example, in the previous version ({cmd:artbin 1.1.2}) the syntax {cmd:artbin, pr(.2 .3) ni(1)} 
will now be specified as {cmd:artbin, pr(.2 .2) margin(.1)}. The option {opt ni()} is now redundant.

{pstd} Previously {opt local} was taken as the default in superiority trials, now it is {ul:distant}: the {opt distant(#)} option has been replaced by {opt local} in the syntax. Previous syntax (up to version 1.1.2) will need to be altered
so that {cmd:artbin, pr(.1 .2) distant(1)} will now be {cmd:artbin, pr(.1 .2)} and {cmd:artbin, pr(.1 .2) distant(0)} 
will now be {cmd:artbin, pr(.1 .2) local}, for example.

{pstd} The user is to identify whether the outcome is {opt favourable} or {opt unfavourable} in the context of a trial.  With this information
plus the {opt margin} the program will then determine the type of trial (i.e. non-inferiority/substantial-superiority/superiority). If the user does
specify {opt favourable/unfavourable} the program will check the assumptions, the not then the program will infer it.  The {opt force} 
option can be used to override the program's inference of the favourability status, for example in the design of observational studies.

{pstd} The {opt wald} option has also been included for the Wald test, as an alternative to the default score test.

{pstd} Sample size per group is now reported, and rounding up to the nearest integer is performed per group. A {opt noround} option has been included for the case when the user does not want {cmd: artbin} to round the calculated sample size. 
A loss to follow-up option is now available ({opt ltfu(#)}).

{pstd} The option {opt conditional} always implies the {opt local} option as there is no conditional distant option available in {cmd:artbin}. If the {opt conditional} option is selected then the default non-local alternatives will 
be changed to {opt local}.

{pstd} The allocation ratio calculation has been adjusted as sample size per group is now reported, and the expected number of events is calculated using the rounded sample size (unless the {opt noround} option for 
calculated sample size is used).

{pstd} Earlier versions of {cmd: artbin} required a number of yes/no options to be specified numerically,
e.g. {opt onesided(1)} or {opt onesided(0)}. In updating the syntax, we have enabled the more standard options e.g. 
{opt onesided} and {opt ccorrect}, but the numerical version of the syntax is retained if the user wishes to use it.

{pstd} The number of groups is taken as the number of proportions in all cases and the {opt ngroups(#)} option is now redundant. 
The mandatory option {opt pr()} is now a numlist instead of a string.

{pstd} Changes have been made to the output table: now included in the description
is whether the trial is non-inferiority, substantial-superiority or superiority,
the trial outcome type, the statistical test assumed (including score or wald), whether local or distant 
alternatives were used and the hypothesis tests and whether the continutity correction was used. 
Minor formatting was also made to the existing allocation ratio, alpha, linear trend output and 
version numbering output. Sample size per group is reported, and the returned values 
have been streamlined to only include results as opposed to user-inputted options.

{pstd} The text output has been changed from {it:p0} and {it:p1} to {it:p1} and {it:p2}.
Therefore the control group event probability for non-inferiority trials is {it:p1}.  

{title:Program structure}

{pstd}
{cmd:artbin} calls a subroutine {cmd:art2bin} for all 2-arm trials, which also allows for substantial-superiority
trials. Previously {cmd:art2bin} was only called for non-inferiority trials in {cmd:artbin},
now it is called for all 2-arm trials. {cmd:art2bin} can be used as a standalone but we do not
recommend this.

{title:Authors}

{pstd}Abdel Babiker, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:a.babiker@ucl.ac.uk":Ab Babiker}

{pstd}Friederike Maria-Sophie Barthel, formerly MRC Clinical Trials Unit{break}
{browse "mailto:sophie@fm-sbarthel.de":Sophie Barthel}

{pstd}Babak Choodari-Oskooei, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:b.choodari-oskooei@ucl.ac.uk":Babak Oskooei}

{pstd}Patrick Royston, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:j.royston@ucl.ac.uk":Patrick Royston}

{pstd}Ella Marley-Zagar, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:e.marley-zagar@ucl.ac.uk":Ella Marley-Zagar}

{pstd}Ian White, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:ian.white@ucl.ac.uk":Ian White}
