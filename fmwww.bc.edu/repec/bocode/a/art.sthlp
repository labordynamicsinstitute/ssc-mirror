{smcl}
{* *! version 0.5 28oct2021}{...}
{vieweralsosee "sampsi (if installed)" "sampsi"}{...}
{vieweralsosee "power (if installed)" "power"}{...}
{vieweralsosee "artbinwhatsnew" "artbin_whatsnew"}{...}
{viewerjumpto "Description" "art##description"}{...}
{viewerjumpto "Changes from artbin version 1.1.2 to version 2.0" "art##whatsnew"}{...}
{viewerjumpto "References" "art##refs"}{...}
{viewerjumpto "Author and updates" "art##updates"}{...}
{viewerjumpto "Also see" "art##also_see"}{...}
{title:Title}

{phang}
{bf:ART} {hline 2} {hi:A}NALYSIS OF {hi:R}ESOURCES FOR {hi:T}RIALS. Suite of commands for complex sample size calculations in randomized controlled trials with
a survival or a binary outcome.

{p2colset 7 20 20 0}{...}
{p2col:{bf:{help artbin:artbin}}}calculation of sample size or power in trials with a binary outcome, including non-inferiority / substantial-superiority trials and superiority trials with {it:k} groups.

{p2col:{bf:{help artsurv:artsurv}}}calculation of sample size or power in trials with a survival outcome.

{marker description}{...}
{title:Description}

{pstd}
{bf:ART} is a suite of programs for the calculation of sample size or power for complex clinical trial designs under a
survival time or binary outcome.  The package is able to handle noninferiority/substantial-superiority 2-arm designs and superiority trials
with {it:k}-groups.


{title:Changes from {bf:{help artbin:artbin}} version 1.1.2 to version 2.0}{marker whatsnew}

{pstd} For the complete list of changes please see {bf:{help artbin_whatsnew:artbin_whatsnew}}.  The main changes are listed below.

{phang}
{bf: New features:}

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

{phang}
{bf: New syntax:}

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


{title:References}{marker refs}

{phang}
Royston, P., & Barthel, F. M. S. (2010). Projection of power and events in clinical trials with a time-to-event outcome. Stata Journal, 10 (3), 386-394. 

{phang}
Barthel, F. M. S., Royston, P., & Parmar, M. K. B. (2009). A menu-driven facility for sample-size calculation in novel multiarm, multistage randomized controlled trials with a time-to-event outcome. Stata Journal, 9 (4), 505-523. 

{phang}
Barthel, F. M. S., Royston, P., & Babiker, A. (2005). A menu-driven facility for complex sample size calculation in randomized controlled trials with a survival or a binary outcome: Update. Stata Journal, 5 (1), 123-129. 

{phang}
Marley-Zagar E, White IR, Royston P, Barthel F M-S, Parmar M, Babiker AG. 
{cmd: artbin}: Extended sample size for randomised trials with binary outcomes.
Stata Journal, in preparation.


{title:Author and updates}{marker updates}

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

{marker also_see}{...}
{title:Also see}

    Manual:  {hi:[R] sampsi}
    Manual:  {hi:[R] power}

{p 4 13 2}
Online:  help for {help artmenu}, {help artbin}, {help artbindlg}

