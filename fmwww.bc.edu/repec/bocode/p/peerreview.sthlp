{smcl}
{* *! version 1.1.1  14dec2020}{...}
{viewerjumpto "Syntax" "peerreview##syntax"}{...}
{viewerjumpto "Description" "peerreview##description"}{...}
{viewerjumpto "Options" "peerreview##options"}{...}
{viewerjumpto "Examples" "peerreview##examples"}{...}
{title:Title}

{phang}
{bf:peerreview} {hline 2} Randomly assign papers to peers for review


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:peerreview} {varname} {ifin}
{cmd:,} 
{cmdab:r:eview(}{it:#} [{cmd:,} {it:name_suboption}]{cmd:)}
[{opth by(varlist)}]

{p 4 4 2}{cmd:by} is allowed; see {manhelp by D}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:peerreview} randomly assigns papers to peers for review, based on the 
principle of assignment without replacement which ensures that each paper is 
assigned an equal number of times. Assignment is carried out with two 
constraints: Reviewers cannot review their own paper and reviewers cannot 
read papers more than once.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{cmd:review(}{it:#} [{cmd:,} {it:name_suboption}]{cmd:)} expects number of reviews; integer

{phang}
{opth by(varlist)} carries out assignment within each group

{dlgtab:name_suboption}

{phang}
{opth name(newvar)} specifies the stub for new variables to be generated, or the variable name in case of a single variable
{break}The default is {it:review}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang}{cmd:. clear}{p_end}
{phang}{cmd:. set obs 12}{p_end}
{phang}{cmd:. gen studentname = word("`c(ALPHA)'", _n)}{p_end}
{phang}{cmd:. gen studentid = _n}{p_end}
{phang}{cmd:. gen group = ceil(_n / 4)}{p_end}

{pstd}Assign 2 papers to each student based on student names{p_end}
{phang}{cmd:. set seed 1234}{p_end}
{phang}{cmd:. peerreview studentname, review(2)}{p_end}

{pstd}Assign 3 papers to each student based on student id, name variables paper#{p_end}
{phang}{cmd:. set seed 2020}{p_end}
{phang}{cmd:. peerreview studentid, review(3, name(paper))}{p_end}

{pstd}Assign 2 papers to each student based on student id within groups, name variables rev#{p_end}
{phang}{cmd:. set seed 10000}{p_end}
{phang}{cmd:. peerreview studentid, review(2, name(rev)) by(group)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Wouter Wakker, wouter.wakker@outlook.com
