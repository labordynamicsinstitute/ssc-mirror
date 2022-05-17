{smcl}
{* 09mar2017}{...}
{cmd:help mkomega}{right: ({browse "http://www.stata-journal.com/article.html?article=st0499":SJ17-4: st0499})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{cmd:mkomega} {hline 2}}Similarity matrix generation for use with the community-contributed command {help ntreatreg}{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:mkomega}
{it:treatment} 
{it:varlist}
{ifin}{cmd:,}
{cmd:sim_measure}{cmd:(}{it:{help mkomega##type:type}}{cmd:)}
{cmd:out}{cmd:(}{it:outcome}{cmd:)}

{phang}
{it:treatment} is a binary variable taking a value of 1 for treated units and
0 for untreated ones.  It is the same treatment variable that the user is
going to specify in {helpb ntreatreg}.

{phang}
{it:varlist} is a list of numeric variables on which to build the distance
measure.  These variables should be of numeric significance, not categorical.
Some of these variables might be specified as confounders in {cmd:ntreatreg}.


{title:Description}

{pstd}
{cmd:mkomega} computes a unit's similarity matrix using the variables declared
in {it:varlist} to be later used in the command {helpb ntreatreg}.  Two types
of similarity matrices are optionally allowed by this command: the correlation
matrix and the inverse Euclidean distance matrix.


{title:Options}
  
{phang}
{opt sim_measure(type)} specifies the similarity matrix to use.
{cmd:sim_measure()} is required.  {it:type} may be {opt corr}, for the
correlation matrix, or {opt L2}, for the inverse Euclidean distance matrix.

{phang} 
{cmd:out}{cmd:(}{it:outcome}{cmd:)} specifies the outcome variable one is
going to use in {cmd:ntreatreg}. {cmd:out()} is required.


{title:Remarks}

{pstd}
For the sake of full consistency across {cmd:mkomega} and {cmd:ntreatreg}, you
must prepare your data as follows:

{phang2}
1. Only use cross-section datasets.{p_end}

{phang2}
2. Eliminate common missing values in the variables used in {cmd:mkomega} and
{cmd:ntreatreg}.{p_end}

{phang2}
3. Sort the treatment in decreasing order (1s first and 0s after).{p_end}

{pstd}
See example 2. 
	 
{pstd}
Please remember to use the {cmdab:update query} command before running this
program to make sure you have an up-to-date version of Stata installed.


{title:Examples}

    {title:Example 1. Use of mkomega}

{phang2}{cmd:. mkomega w x1 x2 x3, out(y) sim_measure(corr)}

    {title:Example 2. Use of mkomega and ntreatreg}

{pstd}
Preserve the current dataset{p_end}
{phang2}{cmd:. preserve}

{pstd}
Generate the nonmissing value indicator {cmd:sample}{p_end}
{phang2}{cmd:. generate sample=missing(y,w,x1,x2,x3)}

{pstd}
Eliminate common missing values from the dataset{p_end}
{phang2}{cmd:. keep if sample==0}

{pstd}
Sort treatment by decreasing order (treated first){p_end}
{phang2}{cmd:. gsort - w}

{pstd}
Run {cmd:mkomega} to obtain the similarity matrix stored in {cmd:r(M)}{p_end}
{phang2}{cmd:. mkomega w x1 x2 x3, out(y) sim_measure(L2)}

{pstd}
Put the similarity matrix into a Stata matrix called {cmd:omega}{p_end}
{phang2}{cmd:. matrix omega = r(M)}

{pstd}
Run {cmd:ntreatreg} using {cmd:omega} as similarity matrix{p_end}
{phang2}{cmd:. ntreatreg y w x1 x2, hetero(x1) spill(omega)}

{pstd}
Restore the starting dataset{p_end}
{phang2}{cmd:. restore}


{title:Stored results}

{pstd}
{cmd:mkomega} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt :{cmd:r(N1)}}number of treated units{p_end}
{synopt :{cmd:r(N0)}}number of untreated units{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt :{cmd:r(M)}}similarity matrix{p_end}


{title:Author}

{pstd}Giovanni Cerulli{p_end}
{pstd}IRCrES-CNR{p_end}
{pstd}National Research Council of Italy{p_end}
{pstd}Research Institute for Sustainable Economic Growth{p_end}
{pstd}Rome, Italy{p_end}
{pstd}{browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 4: {browse "http://www.stata-journal.com/article.html?article=st0499":st0499}{p_end}

{p 7 14 2}
Help:  {manhelp matrix_dissimilarity P:matrix dissimilarity}{p_end}
