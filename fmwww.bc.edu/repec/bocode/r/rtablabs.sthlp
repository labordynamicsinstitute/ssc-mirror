{smcl}
{hline}
help for {cmd:rtablabs}{right:(Roger Newson)}
{hline}

{title:Label variables in a {helpb xsvmat} dataset from a transposed {help ereturn:r(table)} matrix}

{p 8 21 2}
{cmd:rtablabs}


{title:Description}

{pstd}
{cmd:rtablabs} is intended for use in a {helpb xsvmat} resultsset from a transposed {help ereturn:r(table)} matrix
saved by an estimation command.
It allocates {help label:variable labels} to the numeric variables.
The packages {helpb xsvmat} and {helpb descsave}
can be downloaded from {help ssc:SSC}.


{title:Examples}

{pstd}
This example uses the {help ssc:SSC} package (helpb xauto} to load an extended version of the {cmd:auto} data,
and then fits a regression model for the {it:Y}-variable {cmd:npm}
with respect to the {help fvvarlist:factor variable} {cmd:us} and the quantitative variable {cmd:tons}.
We then save the transposed {cmd:r(table)} matrix in a {helpb xsvmat} resultsset in memory,
overwriting the original dataset.
We then list the variables in the resultsset, with their labels,
 using the {help ssc:SSC} package {helpb descsave},
and list the resultsset using the {helpb list} command.

{phang2}{cmd:. xauto, clear}{p_end}
{phang2}{cmd:. describe, full}{p_end}
{phang2}{cmd:. regress npm ib0.us tons}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. xsvmat, from(r(table)') rowlab(parm) roweq(eq) names(col) fast}{p_end}
{phang2}{cmd:. rtablabs}{p_end}
{phang2}{cmd:. descsave, list(, abbr(32))}{p_end}
{phang2}{cmd:. list eq parm b se ll ul pvalue, abbr(32)}{p_end}


{title:Author}

{pstd}
Roger Newson, Queen Mary University of London, UK.{break}
Email: {browse "mailto:r.newsn@qmul.ac.uk":r.newsn@qmul.ac.uk}


{title:Also see}

{p 4 13 2}
{bind: }Manual: {manlink P ereturn}
{p_end}
{p 4 13 2}
On-line:  help for {helpb xauto}, {helpb xsvmat}, {helpb descsave} if installed
{p_end}
