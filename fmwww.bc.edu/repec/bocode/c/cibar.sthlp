{smcl}
{* *! version 1.1.4, Alexander Staudt, 05nov2015}{...}
{* findalias asfradohelp}{...}
{* vieweralsosee "" "--"}{...}
{* vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "cibar##syntax"}{...}
{viewerjumpto "Description" "cibar##description"}{...}
{* viewerjumpto "Options" "cibar##options"}{...}
{viewerjumpto "Examples" "cibar##examples"}{...}
{viewerjumpto "Remarks" "cibar##remarks"}{...}
{viewerjumpto "Author" "cibar##author"}{...}
{title:Title}

{phang}
{bf:cibar} {hline 2} Plot bar graphs with confidence intervals.


{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:cibar:}
{it:varname} [{it:{help if}}] [{it:{help weight}}], {cmd: over1(}{it:varname}{cmd:)} [{it:options}]

{p2colreset}{...}
{p 4 6 2}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt over2(:}{it:varname}{opt ):}}additional over-variable{p_end}
{synopt:{opt over3(:}{it:varname}{opt ):}}additional over-variable. over3() can't be used without specifying over2().{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is 95.{p_end}

{syntab:Advanced}
{synopt:{opt barg:ap(#)}}specify gap within bargroups; default is 0.{p_end}
{synopt:{opt g:ap(#)}}specify gap between bargroups; default is 67 (i.e. 2/3 of a bar).{p_end}
{synopt:{opt barop:ts(...)}}specify the look of the bars. For more information, see {help barlook_options}.{p_end}
{synopt:{opt barc:olor(...)}}specify the color of the bars (see {help colorstyle}; RGB/CMYK/HSV values are not allowed).{p_end}
{synopt:{opt ci:opts(...)}}specify the look of the range plot (see {help twoway rcap}).{p_end}
{synopt:{opt gr:aphopts(...)}}specify additional graph options (see {help twoway_options}).{p_end}
{synopt:{opt barl:abel(...)}}specify if value of the means should be displayed; default is {it:off}.{p_end}
{synopt:{opt blf:mt(...)}}specify label display {help format}; default is %9.2f.{p_end}
{synopt:{opt blp:osition(...)}}specify label position (see {help compassdirstyle}); default is {it:n}.{p_end}
{synopt:{opt blo:rientation(...)}}specify whether label text should be horizontal or vertical (see {help orientationstyle}); default is horizontal.{p_end}
{synopt:{opt bls:ize(...)}}specify label text size (see {help textsizestyle}); default is {it:medsmall}.{p_end}
{synopt:{opt blc:olor(...)}}specify label text color (see {help colorstyle}); default is black.{p_end}
{synopt:{opt blg:ap(...)}}specify distance of barlabels from bars; default is 0.0.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} is not allowed; see {help by}.{p_end}
{p 4 6 2}
{cmd: aweights, fweights, iweights,} and {cmd: pweights} are allowed; see {help weight}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:cibar} creates a bar plot displaying the mean of a variable and its confidence intervals, grouped over different variables.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. cibar price, over1(foreign)}{p_end}
{phang}{cmd:. cibar price, over1(foreign) over2(turn)}{p_end}
{phang}{cmd:. cibar price, over1(foreign) over2(turn) level(90)}{p_end}
{phang}{cmd:. cibar price, over1(foreign) over2(turn) ciopts(lcolor(red)) graphopts(title("Price over 'foreign' over 'turn'") name(graph_1, replace)) }{p_end}

{phang}Using weights{p_end}
{phang}{cmd:. webuse total}{p_end}
{phang}{cmd:. cibar heartatk, over1(sex) over2(race)}{p_end}
{phang}{cmd:. cibar heartatk, over1(sex) over2(race) barcol(gs0 gs10) graphopts(ylabel(, nogrid) graphregion(color(white)))}{p_end}
{phang}{cmd:. cibar heartatk [pweight=swgt], over1(sex) over2(race) graphopts(name(graph_1, replace))}{p_end}
{phang}{cmd:. cibar heartatk [pweight=swgt], over1(sex) over2(race) graphopts(name(graph_2, replace)) barlabel(on) blf(%9.3f)}{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd: cibar} uses -graph twoway- to draw bar graphs with confidence intervals.

{pstd}
{cmd: cibar} is designed to draw vertical bars and confidence intervals. Theoretically, {it:horizontal} bars can be specified using baropts(), 
but this specification will lead to less useful graphs, as confidence intervals will still be displayed vertically. Furthermore, there will be issues concerning the x and y-axis.

{pstd}
The option {cmd: barcolor} sets the colors for the categories of -over1- (see examples).  

{pstd}
The option {cmd: blgap} sets the distance of the barlabels from its default position. The horizontal position of the barlabels is determined by the corresponding group means and the options passed to {cmd: blposition} and {cmd: blorientation}. 
To draw the bar height (group means), {cmd: cibar} uses Stata's {help added_text_options}. Hence, additional space of the barlabels from the bar needs to be defined on the same scale as the y-axis (real values).

{pstd} For the computation of confidence intervals using weights, {cmd: cibar} uses {help mean}.

{pstd}
The code for this .ado is inspired by a how-to of the {it:Institute for Digital Research and Education} (IDRE), that can be found at {browse "http://www.ats.ucla.edu/stat/stata/faq/barcap.htm"}.


{marker author}{...}
{title:Author}

{phang}Alexander Staudt, Universitaet Mannheim, astaudt@mail.uni-mannheim.de{p_end}
