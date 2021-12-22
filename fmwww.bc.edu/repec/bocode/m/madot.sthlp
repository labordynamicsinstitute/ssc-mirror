{smcl}
{* *! madot version 1.0 01Sep2021}{...}
{cmd:help madot}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col :{cmd:madot} {hline 2} Dot plot for summary data (pooled estimates) from meta-analysis for multiple outocmes in systematic reviews.}{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
	{cmdab:madot}{cmd:,} {opth outcome(varname)} {opth dot1(varname)} {opth dot2(varname)} {opth poolest(varname)} {opth n(varname)} {opth cil(varname)} {opth ciu(varname)} {opth textcol1(varname)} {opth textcol2(varname)} {opth textcol3(varname)} {opth textcol4(varname)} {opth textcol5(varname)} {opth textcol6(varname)} [{it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}

{p2coldent:* {opth outcome(varname)}}variable indicating outcomes in the dataset{p_end}
{p2coldent:* {opth dot1(varname)}}variable to plot as a dot; e.g. proportion of event out of total sample size in treatment grp, or weighted mean of treatment group at baseline (must be numeric){p_end}
{p2coldent:* {opth dot2(varname)}}variable to plot as a dot; e.g. proportion of event out of total sample size in control grp, or weighted mean of control group at baseline (must be numeric){p_end}
{p2coldent:* {opth poolest(varname)}}pooled estimates from meta-analysis (MA), e.g. relative risks from MA for dichotomous outcomes, or mean differences from MA for continuous outcomes (must be numeric){p_end}
{p2coldent:* {opth n(varname)}}order of outcomes or other variable for sorting{p_end}
{p2coldent:* {opth cil(varname)}}lower bound of 95% CI of pooled estimates (must be numeric){p_end}
{p2coldent:* {opth ciu(varname)}}upper bound of 95% CI of pooled estimates (must be numeric){p_end}
{p2coldent:* {opth textcol1(varname)}}variable to show in the 1st text column{p_end}
{p2coldent:* {opth textcol2(varname)}}variable to show in the 2nd text column{p_end}
{p2coldent:* {opth textcol3(varname)}}variable to show in the 3rd text column{p_end}
{p2coldent:* {opth textcol4(varname)}}variable to show in the 4th text column{p_end}
{p2coldent:* {opth textcol5(varname)}}variable to show in the 5th text column{p_end}
{p2coldent:* {opth textcol6(varname)}}variable to show in the 6th text column{p_end}

{synopt:{opt clear}}if specified the newly created dataset is stored in memory. Without {cmd:clear} the original dataset is retained in memory{p_end}
{synopt:{opt logoff(#)}}specify whether using log-scale for x axis in right scatter plot - default is {cmd:logoff(0)} using log-scale for dichotomous outcomes{p_end}

{synopt:{opt leftxtitle(string)}}title for x axis (reversed y axis) of left dot plot - the default is {it:"Proportion"} for dichotomous outcomes or {it:"Weighted baseline means"} for continuous outcomes{p_end}
{synopt:{opt rightxtitle(string)}}title for x axis of right scatter plot{p_end}
{synopt:{opth leftcolor1(colorstyle)}}color of dot fill and outline on left dot plot for 1st group - default is {cmd:leftcolor1(red)}{p_end}
{synopt:{opt leftcolsat1(#)}}marker color saturation of 1st group for left dot plot - default is {cmd:leftcolsat1(50)}{p_end}
{synopt:{opth leftsymb1(symbolstyle)}}marker symbol for first group value on left dot plot symbol - default is {cmd:leftsymb1(triangle)}{p_end}
{synopt:{opth leftcolor2((colorstyle)}}color of dot fill and outline on left dot plot for 2nd group - default is {cmd:leftcolor2(blue)}{p_end}
{synopt:{opt leftcolsat2(#)}}marker color saturation of 2nd group for left for dot plot - default is {cmd:leftcolsat2(50)}{p_end}
{synopt:{opth leftsymb2(symbolstyle)}}marker symbol for second group value on left dot plot symbol - default is {cmd:leftsymb2(circle)}{p_end}
{synopt:{opt rightxlinepat(string)}}style of vertical line on right scatter plot - default is dash{p_end}
{synopt:{opth rightxlinecolor(colorstyle)}}color of vertical line on right scatter plot - default is {cmd:rightxlinecolor(bluishgray)}{p_end}
{synopt:{opth rightxlabel(numlist)}}specify x axis tick labels on right scatter plot - default is 0.5 1 2 900{p_end}

{synopt:{opt legendleftyn(#)}}indicates whether legend turned on for left dot plot - default is 1 for legend on{p_end}
{synopt:{opt legendleft1(string)}}legend of first group on left dot plot - default is {it:"Treatment"}{p_end}
{synopt:{opt legendleft2(string)}}legend of second group on left dot plot - default is {it:"Control"}{p_end}
{synopt:{opt legendleftpos(#)}}position of legend on on left dot plot - default is {cmd: legendleftpos(6)}{p_end}
{synopt:{opt legendleftcol(#)}}number of columns of legend in left dot plot - default is {cmd: legendleftcol(2)}{p_end}
{synopt:{opt legendleftrow(#)}}number of rows of legend in left dot plot - default is {cmd: legendleftrow(1)}{p_end}
{synopt:{opt legendrightyn(#)}}indicates whether legend turned on for right scatter plot - default is 1 for legend on{p_end}
{synopt:{opt legendright1(string)}}text of the legend in right scatterplot - default is {it:"RR from MA"} for dichotomous outcomes or {it:"MD"} for continuous outcomes{p_end}
{synopt:{opt legendright2(string)}}text of the legend in right scatter plot - default is {it:"95% CI"}{p_end}
{synopt:{opt legendrightpos(#)}}position of legend in right scatter plot- default is {cmd: legendrightpos(6)}{p_end}
{synopt:{opt legendrightcol(#)}}number of columns of legend in right scatter plot - default is {cmd: legendrightcol(2)}{p_end}
{synopt:{opt legendrightrow(#)}}number of columns of legend in right scatter plot - default is {cmd: legendrightrow(1)}{p_end}

{synopt:{opt textcol1pos(#)}}x axis position to place the 1st text column{p_end}
{synopt:{opt textcol2pos(#)}}x axis position to place the 2nd text column{p_end}
{synopt:{opt textcol3pos(#)}}x axis position to place the 3rd text column{p_end}
{synopt:{opt textcol4pos(#)}}x axis position to place the 4th text column{p_end}
{synopt:{opt textcol5pos(#)}}x axis position to place the 5th text column{p_end}
{synopt:{opt textcol6pos(#)}}x axis position to place the 6th text column{p_end}
{synopt:{opt textcolposy(#)}}y axis position to place the labels of text columns - default is {cmd:textcolposy(0.1)}{p_end}
{synopt:{opt textcol1name(string)}}label for the 1st text column - default is {it:"RR (95% CI)"} for dichotomous outcomes or {it:"MD (95% CI)"} for continuous outcomes{p_end}
{synopt:{opt textcol2name(string)}}label for the 2nd text column - default is {it:"Trt n/N"} for dichotomous outcomes or {it:"Trt BL mean"} for continuous outcomes{p_end}
{synopt:{opt textcol3name(string)}}label for the 3rd text column - default is {it:"ctrl n/N"} for dichotomous outcomes or {it:"Ctrl BL mean"} for continuous outcomes{p_end}
{synopt:{opt textcol4name(string)}}label for the 4th text column - default is {it:"NTials"}, meaning number of trials{p_end}
{synopt:{opt textcol5name(string)}}label for the 5th text column - default is {it:"I-squared"}{p_end}
{synopt:{opt textcol6name(string)}}label for the 6th text column - default is {it:"SOE"}{p_end}

{synopt:{opth grphcol(colorstyle)}}graph background color - default is {cmd:grphcol(white)}{p_end}
{synopt:{opth plotcol(colorstyle)}}plot background color - default is {cmd:plotcol(white)}{p_end} 
{synopt:{opt title(string)}}title for the overall graph{p_end}
{synopt:{opt subtitle(string)}}subtitle for the overall graph{p_end} 
{synopt:{opt graphwidth(#)}}width of overall graph - default is {cmd:graphwidth(10)}{p_end}
{synopt:{opt graphheight(#)}}height of overall graph - default is{cmd:graphheight(5)}{p_end}
{synopt:{opt iscale(#)}}adjust size of text and markers - default is{cmd:iscale(0.55)}{p_end}
{synopt:{opt margin(#)}}set the percentage increase of space to be added when nummargin(1) - default is {cmd:margin(0)}. See {it:{help marginstyle}} for further details.
{p_end}

{synoptline}
{p2colreset}{...}
{pstd}*   {cmd:outcome}, {cmd:dot1}, {cmd:dot2}, {cmd:poolest}, {cmd:n}, {cmd:cil}, {cmd:ciu}, {cmd:textcol1}, {cmd:textcol2}, {cmd:textcol3}, {cmd:textcol4}, {cmd:textcol5}, and {cmd:textcol6} are required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:madot} creates a figure to summarize pooled estimates from meta-analysis for multiple outcomes in systematic reviews.  This figure presents two plots adjacent to each other.  For dichotomous outcomes, the figure shows for each outcome the pooled absolute rate of events in each treatment arm in the left dot plot, as well as the pooled relative risk and 95% confidence interval in right scatter plot. The figure also includes 6 columns that display relative risk and 95% confidence interval, the total number of events and total sample size for each treatment group, the number of trials, the heterogeneity statistic (I-square), and the strength of evidence grade. For continuous outcomes, the left dot plot shows for each outcome the baseline pooled weighted mean in both treatment groups and the right scatter plot shows the pooled mean difference and 95% confidence interval, as well as the baseline pooled weighted means of both groups, number of trials, I-square, and strength of evidence grade.  The content to be included in the 6 text columns can be customized.


{marker options}{...}
{title:Options}

{dlgtab:Required options}

{phang}{opth outcome(varname)} variable indicating outcomes in the dataset

{phang}{opth dot1(varname)} variable to plot as dot; e.g. proportion of event out of total sample size in treatment group, or weighted mean of treatment group at baseline (must be numeric)

{phang}{opth dot2(varname)} variable to plot as dot; e.g. proportion of event out of total sample size in control group, or weighted mean of control group at baseline (must be numeric)

{phang}{opth poolest(varname)} pooled estimates from meta-analysis, e.g. relative risks from MA for dichotomous outcomes, or mean differences from MA for continuous outcomes (must be numeric)

{phang}{opth n(varname)} order of outcomes or other variable for sorting

{phang}{opth cil(varname)} lower bound of 95% CI of pooled estimates (must be numeric)

{phang}{opth ciu(varname)} upper bound of 95% CI of pooled estimates (must be numeric)

{phang}{opth textcol1(varname)} variable to show in the 1st text column

{phang}{opth textcol2(varname)} variable to show in the 2nd text column

{phang}{opth textcol3(varname)} variable to show in the 3rd text column

{phang}{opth textcol4(varname)} variable to show in the 4th text column

{phang}{opth textcol5(varname)} variable to show in the 5th text column

{phang}{opth textcol6(varname)} variable to show in the 6th text column


{dlgtab:Left plot options}

{phang}{opt leftxtitle(string)} title for x axis (reversed y axis) of left dot plot - the default is {it:"Proportion"} for dichotomous outcomes or {it:"Baseline weighted means"} for continuous outcomes

{phang}{opth leftcolor1(colorstyle)} color of dot fill and outline on left dot plot for 1st group, must be one of Stata's {it:{help colorstyle}} - default is {cmd:leftcolor1(red)}

{phang}{opt leftcolsat1(#)}} marker color saturation of 1st group for left dot plot - default is {cmd:leftcolsat1(50)}

{phang}{opth leftsymb1(symbolstyle)} marker symbol for first group value on left dot plot symbol, must be one of Stata's {it:{help symbolstyle}} - default is {cmd:leftsymb1(triangle)}

{phang}{opth leftcolor2(colorstyle)} color of dot fill and outline on left dot plot for 2nd group, must be one of Stata's {it:{help colorstyle}} - default is {cmd:leftcolor2(blue)}

{phang}{opt leftcolsat2(#)} marker color saturation of 2nd group for left for dot plot - default is {cmd:leftcolsat2(50)}

{phang}{opth leftsymb2(symbolstyle)} marker symbol for second group value on left dot plot symbol, must be one of Stata's {it:{help symbolstyle}} - default is {cmd:leftsymb2(circle)}

{phang}{opt legendleftyn(#)} indicates whether legend turned on for left dot plot, can only take values 0 or 1 - default is 1 for legend on

{phang}{opt legendleft1(string)} legend of first group on left dot plot - default is {it:"Treatment"}

{phang}{opt legendleft2(string)} legend of second group on left dot plot - default is {it:"Control"}

{phang}{opt legendleftpos(#)} position of legend on left dot plot, can only take integer values from 1 to 12 - default is {cmd: legendleftpos(6)}
    
{phang}{opt legendleftcol(#)} number of columns of legend in left dot plot, can only take integer values - default is {cmd: legendleftcol(2)}

{phang}{opt legendleftrow(#)} number of rows of legend in left dot plot, can only take integer values - default is {cmd: legendleftrow(1)}


{dlgtab:Right plot options}

{phang}{opt logoff(#)} specify whether using logarithmic scale for x axis in right scatter plot, can only take values 0 or 1 - default is {cmd:logoff(0)} using logarithmic scale for x axis in right scatter plot for dichotomous outcomes. {cmd:logoff(1)} is recommended for continuous outcomes to display a linear x axis.

{phang}{opt rightxtitle(string)} title for x axis of right scatter plot

{phang}{opt rightxlinepat(string)} style of vertical line on right scatter plot, must be one of Stata's {it:{help linepattern}} - default is {cmd:rightxlinepat(dash)}

{phang}{opth rightxlinecolor(colorstyle)} color of vertical line on right scatter plot, must be one of Stata's {it:{help colorstyle}} - default is {cmd:rightxlinecolor(bluishgray)}

{phang}{opth rightxlabel(numlist)} specify x axis tick labels on right scatter plot - default is {cmd:rightxlabel(0.5 1 2 900)}

{phang}{opt legendrightyn(#)} indicates whether legend turned on for right scatter plot, can only take values 0 or 1 - default is 1 for legend on

{phang}{opt legendright1(string)} text of the legend in right scatterplot - default is {it:"RR from MA"} for dichotomous outcomes or {it:"MD"} for continuous outcomes

{phang}{opt legendright2(string)} text of the legend in right scatter plot - default is {it:"95% CI"}

{phang}{opt legendrightpos(#)} position of legend in right scatter plot, can only take integer values from 1 to 12 - default is {cmd:legendrightpos(6)}

{phang}{opt legendrightcol(#)} number of columns of legend in right scatter plot, can only take integer values - default is {cmd:legendrightcol(2)}

{phang}{opt legendrightrow(#)} number of columns of legend in right scatter plot, can only take integer values - default is {cmd:legendrightrow(1)}


{dlgtab:Text column options}
{phang}{opt textcol1pos(#)} x axis position to place the 1st text column - default is {cmd:textcol1pos(5)}

{phang}{opt textcol2pos(#)} x axis position to place the 2nd text column - default is {cmd:textcol2pos(18)}

{phang}{opt textcol3pos(#)} x axis position to place the 3rd text column - default is {cmd:textcol3pos(55)}

{phang}{opt textcol4pos(#)} x axis position to place the 4th text column - default is {cmd:textcol4pos(120)}

{phang}{opt textcol5pos(#)} x axis position to place the 5th text column - default is {cmd:textcol5pos(240)}

{phang}{opt textcol6pos(#)} x axis position to place the 6th text column - default is {cmd:textcol6pos(450)}

{phang}{opt textcolposy(#)} y axis position to place the labels of text columns, adjust this value to align outcomes in left and right plots - default is {cmd:textcolposy(0.1)}

{phang}{opt textcol1name(string)} label for the 1st text column - default is {it:"RR (95% CI)"} for dichotomous outcomes or {it:"MD (95% CI)"} for continuous outcomes

{phang}{opt textcol2name(string)} label for the 2nd text column - default is {it:"Trt n/N"} for dichotomous outcomes or {it:"Trt BL mean"} for continuous outcomes

{phang}{opt textcol3name(string)} label for the 3rd text column - default is {it:"ctrl n/N"} for dichotomous outcomes or {it:"Ctrl BL mean"} for continuous outcomes

{phang}{opt textcol4name(string)} label for the 4th text column - default is {it:"NTials"}, meaning number of trials

{phang}{opt textcol5name(string)} label for the 5th text column - default is {it:"I-squared"}

{phang}{opt textcol6name(string)} label for the 6th text column - default is {it:"SOE"}, meaning strength of evidence


{dlgtab:Overall graph options}

{phang}{opt clear} if specified the newly created dataset is stored in memory. If clear not specified, the original dataset is retained in memory.

{phang}{opth grphcol(colorstyle)} graph background color, must be one of Stata's {it:{help colorstyle}} - default is {cmd:grphcol(white)}

{phang}{opth plotcol(colorstyle)} plot background color, must be one of Stata's {it:{help colorstyle}} - default is {cmd:plotcol(white)}

{phang}{opt title(string)} title for the overall graph

{phang}{opt subtitle(string)} subtitle for the overall graph

{phang}{opt graphwidth(#)} width of overall graph - default is {cmd:graphwidth(10)}

{phang}{opt graphheight(#)} height of overall graph - default is {cmd:graphheight(5)}

{phang}{opt iscale(#)} adjust size of text and markers - default is {cmd:iscale(0.55)}

{phang}{opt margin(#)} set the percentage increase of space to be added - default is {cmd:margin(0)}. See {it:{help marginstyle}} for further details.


{marker remarks}{...}
{title:Remarks}

{pstd}
(1) Dataset is required in a format of one row per outcome.

{pstd}
(2) Generating a variable for sorting is required. For example: {cmd:gen order = _n}

{pstd}
(3) Logarithmic scale of x-axis using option {cmd:logoff(0)} in the right scatter plot is recommended for displaying pooled relative risk of dichotomous outcomes; while linear scale of x-axis using option {cmd:logoff(1)} is appropriate for displaying pooled mean difference of continuous outcomes in the right scatter plot.


{marker examples}{...}
{title:Examples}

{p 4 4 2}Creating dot plot for dichotomous outcomes using default settings:{p_end}

{phang2}{cmd:. madot, outcome(Outcome) dot1(prop1) dot2(prop2) poolest(RR) n(order) cil(cil) ciu(ciu) textcol1(sRR) textcol2(trt_n_N) textcol3(ctrl_n_N) textcol4(NoofTrials) textcol5(sIsquared) textcol6(SOE)}{p_end}


{p 4 4 2}Creating dot plot for dichotomous outcomes using customized settings -- {break}
using the {cmd:legendleft1} and {cmd: textcol2name} options to assign treatment group names; {break}
using the {cmd:rightxlabel} option to change ticker markders of right x-axis; {break}
using the {cmd:textcol1pos} to {cmd:textcol6pos} options to adjust positions of text columns:{p_end}

{phang2}{cmd:. madot, outcome(Outcome) dot1(prop1) dot2(prop2) poolest(RR) n(order) cil(cil) ciu(ciu) textcol1(sRR) textcol2(trt_n_N) textcol3(ctrl_n_N) textcol4(NoofTrials) textcol5(sIsquared) textcol6(SOE) legendleft1("TRT group name") textcol2name("TRT group n/N") rightxlabel(0.8 1 2 4 900) textcol1pos(10) textcol2pos(35) textcol3pos(80) textcol4pos(150) textcol5pos(250) textcol6pos(500)}{p_end}


{p 4 4 2}Creating dot plot for continuous outcomes using the {cmd:logoff(1)} option -- {break}
using the {cmd:textcolposy} option to adjust height of text columns for better alignment;{break}
using the {cmd:legendleft1}, {cmd:legendleft2}, {cmd:textcol2name} and {cmd:textcol3name} options to assign;{break}
using the {cmd:rightxlabel} option to change ticker markers of right x-axis;{break}
using the {cmd:textcol1pos} to {cmd:textcol6pos} options to adjust positions of text columns:{p_end}

{phang2}{cmd:. madot, outcome(Outcome) dot1(trt_bl_mean)  dot2(ctrl_bl_mean) poolest(MD) n(order) cil(cil) ciu(ciu) textcol1(sMD2) textcol2(trt_N) textcol3(ctrl_N) textcol4(NoofTrials) textcol5(sIsquared) textcol6(SOE) logoff(1) textcolposy(0.5) textcol2name("Trt (N)") textcol3name("Ctrl (N)") rightxlabel( -8 -6 -4 -2 0 2 19) textcol1pos(5) textcol2pos(8.7) textcol3pos(11) textcol4pos(13.5) textcol5pos(15) textcol6pos(17) graphheight(3) graphwidth(8.5) iscale(0.8)}{p_end}


{title:Acknowledgments}
{pstd}
This module is adopped from the aedots package.  We thank Dr. Rachel Phillips and Dr. Suzie Cro (Imperial College London, UK) for their contributions on developing the aedots package.

{marker references}{...}
{title:References}

{marker R2008}{...}
{phang}
Amit, O. , Heiberger, R. M. and Lane, P. W. 2008. Graphical approaches to the analysis of safety data from clinical trials. 
{it:Pharmaceut. Statist.} 7: 20-35. doi:10.1002/pst.254 

{marker R2020}{...}
{phang}
Cornelius, V., Cro, S. & Phillips, R. 2020. Advantages of visualisations to evaluate and communicate adverse event information in randomised controlled trials. 
{it:Trials.} 21: 1028. doi.org/10.1186/s13063-020-04903-0 PMID: 33353566.


{title:Authors}

{pstd}
Yun Yu{break}
Pacific Northwest Evidence-based Practice Center, Portland, OR US
{break}
email: yuy@ohsu.edu

{pstd}
Rongwei Fu, Pacific Northwest Evidence-based Practice Center, Portland, OR US {break}
Jesse Wagner, Pacific Northwest Evidence-based Practice Center, Portland, OR US  {break}
Azrah Ahmed, Pacific Northwest Evidence-based Practice Center, Portland, OR US  {break}
Connor Smith, Pacific Northwest Evidence-based Practice Center, Portland, OR US  {break}
Roger Chou, Pacific Northwest Evidence-based Practice Center, Portland, OR US  {break}


{asis}