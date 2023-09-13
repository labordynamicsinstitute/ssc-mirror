{smcl}
{* *!  version 1.0 2/27/2018}
{title:Title}

{p 4 15 2}
{cmd:sigreg} {hline 2} produces information for an interaction effect about the values of the moderator(s) for which a designated focal 
variable’s effect on the observed or modeled outcome is signficant. 

{title:Description}

{p 4 4 2}
{cmd:sigreg} produces an empirically-derived definition of the significance region of a focal variable's effect in tabular form. Also performs, if possible, a 
Johnson-Neyman boundary value analysis to find the values of the moderating variables for which the effect of the focal variable is significant. 
Must run {help intspec} before running {cmd:sigreg}. See Kaufman (2018) for detailed explanation and step-by-step examples of using this and other ICALC add-on commands. 


{title:Syntax}

{p 4 10 2}
{cmd:sigreg} {cmd:,} [ {opt sig:lev}(#, adjtype)  {opt effect}({it:type}({it:suboptions})) {opt save}({it: filepath}, {opt tab:le} {opt mat:rix})  
{opt ndig:its}(#) {opt concise} {opt nobva} {opt plot:jn}({it:graphname}, {opt skip#}) ] 

{p2colset 4 24 24 2}
{p2col: {it:options}}Description {p_end}
   {hline}
 
{p2col:{cmdab:sig:lev}(#, {it:adjtype})}# is nominal alpha-level for significance testing. {bf:Default is siglev(.05)}. {p_end}
{p2col: {cmd: }}{cmd:adjtype} keyword is  {it:bonferroni}, {it:sidak} or {it: potthoff} adjustment for multiple tests, 
can specify potthoff in combination with either bonferroni or sidak. 

{p2colset 4 24 26 2}
{p2col:{cmd:effect(type(suboptions))}}Type of coefficient value reported in significance region table for delta unit change in focal variable {p_end}
{p2colset 7 24 26 2}
{p2col:{cmd:type}}{ul:Keyword for coefficient type}.  {p_end}
{p2colset 7 25 25 2}
{p2col: {cmd: }}{cmd:b} for estimated coefficient {p_end}
{p2col: {cmd: }}{cmd:factor} for factor change coefficient {p_end}
{p2col: {cmd: }}{cmd:spost} for marginal/discrete change calculated by the SPOST13 {help mchange} command{p_end}
{p2col: {cmd: }}{bf:Default is effect(b)}. {p_end}
{p2colset 7 24 26 2}
{p2col:suboptions}{ul:b({it:delta}) or factor({it:delta}) where {it:delta} is} {p_end}
{p2colset 7 25 27 2}
{p2col: {cmd: }}{cmd:1} for 1 unit change. {bf:Default} {p_end}
{p2col: {cmd: }}{cmd:sd} for 1 standard deviation change {p_end}
{p2col: {cmd: }}{cmd:#} any non-zero real number change{p_end}
{p2col: {cmd: }}{cmd:sdy} for estimated effect scaled in standard deviation units of "modeled" outcome {p_end}
{p2col: {cmd: }}{cmd:sdyx} for sdy effect calculated for a 1 standard deviation change in focal variable{p_end}
{p2col: {cmd: }}{bf:Default is delta of 1}. {p_end}
{p2colset 7 24 26 2}
{p2col:suboptions}{ul:spost({it:amtopt( )} {it:atopt( ))} where}{p_end}
{p2colset 7 25 27 2}
{p2col: {cmd: }}{cmd:amtopt( )} specifies amount-of-change options for SPOST13 {help mchange} command ((see Long and Freese 2014).
 Must include amount( ) with a single entry. {bf:Default amtopt(amount(one)).} {p_end}
{p2col: {cmd: }}{cmd:atopt( )}specifies content for the at( ) option of the {help margins} command for predictors other than focal or moderators. 
{bf:Default is atopt((asobs) _all)} {p_end}
{p2colset 4 24 26 2}
{p2col:{cmd:save({opt filepath} {opt tab:le} {opt mat:rix})}} {p_end} 
{p2col 7 24 26 2:{it:table}}Keyword {it:table} saves formatted significance region table to name & location given by {it:filepath} {p_end}
{p2col 7 24 26 2:{it:matrix}}Keyword {it:matrix} saves formatted significance region table to name & location given by {it:filepath} {p_end}
{p2colset 4 24 26 2}
{p2col:{cmd:ndigits(#)}}# is an integer for # of digits in tables. {bf:Default ndig(2)} {p_end}
{p2col:{cmd:concise}}limit details in boundary value analysis report {p_end}
{p2col:{cmd:nobva}}no boundary value analysis if keyword {cmd:nobva} specified {p_end}
{p2colset 4 24 26 2}
{p2col:{cmd:plotjn(graphname, skip#)}}request plot of Johnson-Neyman boundary values if have 2 moderators {p_end} 
{p2col 7 24 26 2:{graphname}}save plot as memory graph named {it:graphname} {p_end}
{p2col 7 24 26 2:{it:matrix}}Specify an integer to improve plot readability to skip points between markers. {bf:Default is 10}{p_end}

{p2col:{cmd:pltopts(string)}}{it:string} contains {help twoway_options:two-way graph options} to customize appearance (e.g. line colors). These do not always work as expected. 
Use the graph editor if not. {p_end}

{p 2 8 2 } 
{bf:Note:} Moderator {cmd:range( )} specifications define points at which moderated effect is calculated for empirical significance region table. 
For nominal variables all categories define calculation points. For analysis with 2+ moderators, they define points at which boundary values found for other moderator.

{title:Example: two-way interaction}

{p 0 0 2}
For a model predicting poor mental health days ({it:pmhdays}) by the interaction of work-family conflict ({it:wfconflict}) and job status ({it:sei}), {cmd:intspec} 
specfies {it:wfconflict} as the focal variable and {it:sei} as its moderator.  {cmd:sigreg} produces an empirically-derived significance region table of {it:wfconflict}'s 
effect on {it:pmhdays} at values of sei = 17, 27, ..., 97. Also calculates Johnson-Neyman boundary values analysis to find the values of {it:sei} 
for which the effect of {it:wfconflict} changes significance.

{p 6 10 2}
nbreg pmhdays c.wfconflict##c.sei ... {p_end}
{p 6 10 2}
intspec, focal(c.wfconlifct) main( (c.sei name(JobStatus) range(17(10)97)) (c.wfconflict name(WorkFamConflict) range(1/4))) int2vars(c.wfconflict#c.sei) {p_end}
{p 6 10 2}
sigreg , ndigits(4)

{p 2 4 2} 
*** Calculate significance region for discrete change effect of {it:wfconflict} and suppress boundary value analysis

{p 6 4 2}
sigreg , ndigits(4)  effect(spost(amtopt(one))) nobva

{p 2 4 2}
*** Also save formatted table to Excel file named sigtable.xlsx

{p 6 4 2}
sigreg , ndigits(4)  effect(spost(amtopt(one))) nobva save(\output\sigtable.xlsx tab)


{title:Author and Citation}

{p 4 4 2}
I would appreciate users of this and other ICALC commands citing

{p 6 6 2}
Robert L. Kaufman.  2018. {it: Interaction Effects in Linear and Generalized Linear Models}, Sage Publcations. 

