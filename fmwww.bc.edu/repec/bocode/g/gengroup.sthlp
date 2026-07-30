{smcl}
{* 6May2013}{...}
{hline}
help for {hi:gengroup}{right:Jean-benoit Hardouin}
{hline}

{title:Module to generate group of individuals based on a ordinal or continuous variable}

{p 8 14 2}{cmd:gengroup} {it:varname} [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [{cmd:,} {cmdab:new:variable}({it:newvarname}) {cmdab:rep:lace} {cmdab:min:size}(#) {cmdab:det:ails} {cmdab:cont:inuous}]

{title:Description}

{p 4 8 2}{cmd:gengroup} creates groups of individuals by using the values of an ordinal or continuous variable.
The module creates groups by recoding several adjacent values of the variable, until obtaining groups with more than individuals than the number defined in the {cmd:minsize} option.


{title:Options}

{p 4 8 2}{cmd:newvariable} defines the name of the new variable ({it:group} by default).

{p 4 8 2}{cmd:replace} replaces the variable defined in the {cmd:newvariable} option if it already exists.

{p 4 8 2}{cmd:minsize} defines the minimal number of individuals in each group (30 by default).

{p 4 8 2}{cmd:details} diplays the composition of each group.

{p 4 8 2}{cmd:continuous} allows handling a continuous variable.

{title:Examples}

{p 4 8 2}{inp:. gengroup score}

{p 4 8 2}{inp:. gengroup score, newvariable(grouptocreate) replace minsize(80)}

{p 4 8 2}{inp:. gengroup score, details}

{title:Author}

{p 4 8 2}Jean-Benoit Hardouin, PhD, assistant professor{p_end}
{p 4 8 2}Team of Biostatistics, Clinical Research and Subjective Measures in Health Sciences{p_end}
{p 4 8 2}University of Nantes - Faculty of Pharmaceutical Sciences{p_end}
{p 4 8 2}1, rue Gaston Veil - BP 53508{p_end}
{p 4 8 2}44035 Nantes Cedex 1 - FRANCE{p_end}
{p 4 8 2}Email:
{browse "mailto:jean-benoit.hardouin@univ-nantes.fr":jean-benoit.hardouin@univ-nantes.fr}{p_end}
{p 4 8 2}Website {browse "http://www.anaqol.org":AnaQol}

{title:Also see}

{p 4 13 2}Online: help for {help egen}, {help generate} and {help genscore} if installed.{p_end}

