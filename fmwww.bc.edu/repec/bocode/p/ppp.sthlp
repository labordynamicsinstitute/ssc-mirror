{smcl}
{* 25 Aug 2025}{...}
{hline}
{cmd:help ppp}
{hline}

{title:Title}
{pstd}
{cmd:ppp} — Plot pre- and post-test probabilities after diagnostic testing

{title:Syntax}
{p 8 12 2}
{cmd:ppp} prevalence LR+ LR−
[{cmd:,} {it:options}] 

{p 8 12 2}
or 

{p 8 12 2}
{cmd:ppp} prevalence sensitivity specificity
[{cmd:, nolr} {it:options}] 

{title:Description}
{pstd}
{cmd:ppp} is an immediate command to plot a nomogram-like graph showing how 
pre-test probability evolves to post-test probability after one or more 
diagnostic tests. The method is based on Bayes’ theorem and is similar in spirit to the 
{help fagan} plot, but allows sequential tests (“triages”).

{pstd}
The {cmd:ppp} command requires Stata 10.1 or later versions.

{pstd}
The first three arguments are; 

{p 12 12  2}
prevalence - The prior/pre-test probability (between 0 and 1),

{p 12 12  2}
lrp - The likelihood ratio for positive results (values >0),

{p 12 12  2}
lrn - The likelihood ratio for negative results (values >0).

{pstd}
or alternatively with the option {cmd:nolr};

{p 12 12  2}
prevalence - The prior/pre-test probability (between 0 and 1),

{p 12 12  2}
sensitivity - The diagnostic sensitivity of a the test (between 0 and 1),

{p 12 12  2}
specificity - The diagnostic specificity of a the test (between 0 and 1).

{pstd}
For each consequent triage, two to four more arguments are required in the following order {cmd: lrp2+ lrn2+ lrp2- lrn2-} where

{p 12 12  2}
lrp2+: - The likelihood ratio for positive results of the next test for the previous positives.

{p 12 12  2}
lrn2+: - The likelihood ratio for negative results of the next test for the previous positives.

{p 12 12  2}
lrp2-: - The likelihood ratio for positive results of the next test for the previous negatives.

{p 12 12  2}
lrn2-: - The likelihood ratio for negative results of the next test for the previous negatives.

{p 12 12  2}
With the option {cmd:nolr}, the conditional sensitivity and specificity for the positive and outcomes should be supplied i.e  {cmd: sensitivity2+ specificity2+ sensitivity2- specificity2-} 

{pstd}
Special values:

{p 12 16 2}
In lr mode, {bf:1} indicates “no sequential test” on that branch (connecting arrow shown in grey) i.e. 
when the next triage is done only on positive or negative outcomes. e.g. {cmd: lrp2+ lrn2+}{cmd: 1 1} or {cmd: 1 1}{cmd: lrp2- lrn2-} respectively.

{p 12 16 2}
In {cmd:nolr} mode, {bf:0.5} indicates “no sequential test” (connecting arrow shown in grey).

{p 12 16 2} 
Missing values (.) hide the corresponding arrow completely. e.g. {cmd: lrp2+ lrn2+}{cmd: . .} 

{title: Options}
{synoptset 20}
{synopt:{opt bands(numlist)}}A list specifying where the different bands appear. The numbers should be between 0 and 1.{p_end}
{synopt:{opt bandcolor(string)}}Specifies the colour of the bands. {p_end}
{synopt:{opt noLR}}Notifies the procedure to expect sensitivity and specificity as input instead of the LR+ and LR-.{p_end}
{synopt:{opt dp(#)}}Decimal places for annotation labels (default: 2).{p_end}
{synopt:{opt legendopts(str)}}Control legend display. {cmd:legendopts(on)} uses custom layout, {cmd:legendopts(off)} suppresses legend. Giving no options or {cmd:legends(all)} shows all the keys and their labels. {p_end}
{synopt:{opt skip(#)}}Skip vertical spacing between triages and rows in the legend, useful for combining graphs with different numbers of tests.{p_end}
{synopt:{opt options}}allow other two way graph options e.g xsize(3) ysize(7).{p_end}

{title:Examples}

{pstd}
One test.

{pmore}
{cmd:ppp 0.5 14.4 0.25,  legendopts(on)}
{it:({stata "ppp 0.5 14.4 0.25, legendopts(on)":click to run})}

{pstd}
One test with enlarged axis titles.

{pmore}
{cmd:ppp 0.5 14.4 0.25, bands(0.3 0.6)  ytitle(,size(5) axis(1)) ytitle(,size(5) axis(2)) legendopts(on)}
{it:({stata "ppp 0.5 14.4 0.25, bands(0.3 0.6)  ytitle(,size(5) axis(1)) ytitle(,size(5) axis(2)) legendopts(on)":click to run})}

{pstd}
Two tests, second applied only to negatives

{pmore}
{cmd:ppp 0.5 14.4 0.45 1 1 10 0.05, bands(0.3 0.6) legendopts(on)}
{it:({stata "ppp 0.5 14.4 0.45 1 1 10 0.05, bands(0.3 0.6) legendopts(on)":click to run})}

{pstd}
Two tests, second applied only to positives

{pmore}
{cmd:ppp 0.5 1.5 0.25 10 0.05 1 1 , bands(0.3 0.6) legendopts(on)}
{it:({stata "ppp 0.5 1.5 0.25 10 0.05 1 1 , bands(0.3 0.6) legendopts(on)":click to run})}

{pstd}
Two tests, hide the negative branch of the second test

{pmore}
{cmd:ppp 0.5 1.5 0.25 10 0.05 . . , bands(0.3 0.6) legendopts(on)}
{it:({stata "ppp 0.5 1.5 0.25 10 0.05 . . , bands(0.3 0.6) legendopts(on)":click to run})}

{pstd}
Two tests, second applied only to positives, sensitivity and specificity as input.

{pmore}
{cmd:ppp 0.5 0.9 0.6 0.9 0.6, bands(0.3 0.6) nolr legendopts(on)}
{it:({stata "ppp 0.5 0.9 0.6 0.9 0.6, bands(0.3 0.6) nolr legendopts(on)":click to run})}

{pstd}
Three tests with legend.

{pmore}
{cmd:ppp 0.5 14.4 0.35 11 0.05 1 1 1 1 10 0.05 1 1, bands(0.3 0.6 ) bandcolor(blue*0.3 brown*0.3 red*0.3) legendopts(on)}
{it:({stata "ppp 0.5 14.4 0.35 11 0.05 1 1 1 1 10 0.05 1 1, bands(0.3 0.6) bandcolor(blue*0.3 brown*0.3 red*0.3) legendopts(on)":click to run})}

{pstd}
Three tests without legend.

{pmore}
{cmd:ppp 0.5 14.4 0.35 11 0.05 1 1 1 1 10 0.05 1 1, bands(0.3 0.6 ) bandcolor( green*0.3 orange*0.3 red*0.3) legendopts(off)}
{it:({stata "ppp 0.5 14.4 0.35 11 0.05 1 1 1 1 10 0.05 1 1, bands(0.3 0.6) bandcolor( green*0.3 orange*0.3 red*0.3) legendopts(off)":click to run})}

{title:Author}
{pmore}
Victoria N. Nyaga ({it:Victoria.NyawiraNyaga@sciensano.be}) {p_end}
{pmore}
Belgian Cancer Center/Unit of Cancer Epidemiology, {p_end}
{pmore}
Sciensano,{p_end}
{pmore} 
Juliette Wytsmanstraat 14, {p_end}
{pmore}
B1050 Brussels, {p_end}
{pmore}
Belgium.{p_end}

{title:Also see}

{psee}
Online:  {help fagan} (if installed)
		 

