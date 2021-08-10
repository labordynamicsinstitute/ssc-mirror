{smcl}
{* 28jun2015}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:models} {hline 2} Summarize estimation results

{title:Syntax}

{phang2}{cmd:models clear} 

{phang2}{cmd:models add} [{it:model label}]

{phang2}{cmd:models label} {it:integer} [{it:model label}]

{phang2}{cmd:models} {opt di:splay} [{cmd:,} {it:display options}]

{phang2}{cmd:models all} [{it:model label}] [{cmd:,} {it:display options} ]


{title:Description}

{pstd}This suite of commands is for saving estimation results and displaying a summary table.

{phang}o-{space 2}{cmd:models clear} clears any existing saved results and prepares for {cmd:models add}.{p_end}

{phang}o-{space 2}{cmd:models add} adds the {bf:current} estimation results, as well as current name- and value- labels, to the set of saved results.

{phang}o-{space 2}{cmd:models label} lets you retrospectively set or remove the {it:model label} from any of the results. {it:integer} references the models by the order in which they were added, starting at {cmd:1}.

{phang}o-{space 2}{cmd:models} {opt di:splay} displays the table of summarized results.{p_end}

{phang}o-{space 2}{cmd:models all} is a shortcut for the other {cmd:models} sub-commands (in order): {cmd:models clear}, {cmd:models add}, {cmd:models display}.


{title:Display Options}

{phang}{opt inc:lude(result types)} allows you to specify the display for each variable in a model. The allowed {it:result types} are {cmd:beta}, {cmd:p}, and {cmd:ci}[{cmd:(}{it:percent}{cmd:)}].

{phang2}o-{space 2}When {opt inc:lude()} is not specified, {cmd:beta} and {cmd:p} are used.{p_end}
{phang2}o-{space 2}When {cmd:ci} is specified alone, a 95% confidence interval is used.{p_end}
{phang2}o-{space 2}{cmd:beta} actually displays the exponentiated coefficients, with the appropriate label.{p_end}

INCLUDE help tabel_options2n

{pmore}{it:nl1} governs the IVs, and {it:nl2} governs the DVs.

INCLUDE help tabel_options2v

INCLUDE help tabel_out2


{title:Remarks}

{pstd}Types of models currently supported are: linear, logistic, poisson, cox, and competing risk. Dummy variable notation ({cmd:i.}) is working, but interaction notation ({cmd:#}) isn't, yet.

{pstd}I believe it should be easy at this point to add more types of models or results. Let me know if something more would be useful...

