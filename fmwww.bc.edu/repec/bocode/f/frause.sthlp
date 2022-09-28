{smcl}
{* *! version 1.0 9/27/2022}{...}
{cmd:help frause}
{hline}

{title:Title}
{phang}
{bf: frause -- Access Wooldridge Stata datasets}

{title:Syntax}
{p 8 17 2}
{cmd:frause}
{it:filename} | {it:list}
[ 
{cmd:,}
{cmd:clear}
]

{title:Description}

{pstd}{cmd:frause} provides access to Stata-format datasets used
in "Introductory Econometrics: a Modern Approach" by Wooldridge.
This should contain all datasets that the book uses in their examples and exercises, and 
we will be using this for the Research Methods class at Levy.

{pstd}The command uses {cmd: webuse} in the background, and downloads data from Github, and my repository.
If you have problems downloading the data, it may be I exceeded my traffic allotment.

{pstd}The command and helpfile was based on -bcuse- by Prof. Baum


{title:Options}

{phang}{opt clear} specifies that you want to clear Stata's memory before loading 
the new dataset.

{title:Examples} 

{phang}{stata "frause crime1" : . frause crime1}{p_end}
{phang}{stata "frause crime1, clear" : . frause crime1, clear}{p_end}
{phang}{stata "frause econmath, clear" : . frause econmath, clear}{p_end}

{title:Author}
{phang}Fernando Rios-Avila{break} 
friosa@gmail.com{p_end}

{title:Also see} 
  
  help for {help use}, {help sysuse}, {help webuse}
