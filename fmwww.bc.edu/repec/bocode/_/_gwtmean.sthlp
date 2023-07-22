{smcl}
{* 2023july18,21}
{hline}
help for {hi:_gwtmean}
{hline}

{p 4 4 2}User-written {help egen} function wtmean(), to calculate a weighted mean.

{hline}

{title:Syntax}

{p 6 6 2}
{cmd:egen} {dtype} {newvar} {cmd:= wtmean(}{it:{help exp}}{cmd:)} {ifin}
[{cmd:, }{opt weight(weightexp)} {opt by(varlist)}]

{p 4 4 2}
Creates a constant (within {it:varlist}) containing the mean of {it:exp}.
With the {cmd:weight} option, it is weighted by {it:weightexp}; otherwise, it produces
an unweighted mean {c -} the same as the egen {cmd:mean} function.

{p 4 4 2}
{it:weightexp} may be an {help expression} (e.g., {cmd:1/prob}); it is not limited to variables.

{p 4 4 2}
{cmd:wtmean} may be combined with {help by}, either as a prefix or an option.

{hline}

{title:Author}
{p 4 4 2}
David Kantor; email {browse "mailto:kantor.d@att.net":kantor.d@att.net}{p_end}
{p 4 4 2}
Please include {cmd:stata} in the subject field.
