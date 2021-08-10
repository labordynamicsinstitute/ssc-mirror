{smcl}
{* 3sep2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "tstats" "tstats"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:tfreq} {hline 2} Tabulate

{title:Syntax}

{pmore}
{cmdab:t:freq} [{it:{help varelist}}] {ifin} [{it:fweight}] [{cmd:,}  {it:options}]

{synoptset 16}
{synopt:{help varelist##mods:Modifiers}}Description{p_end}
{synoptline}
{synopt:{opt (.)}}Collapse all {it:non-missing} values to a single value.

{synopthdr:options}
{synoptline}
{synopt:{opt r:ow}}display % of row-total{p_end}
{synopt:{opt c:ol}}display % of column-total{p_end}
{synopt:{opt cell}}display % of grand total{p_end}
{synopt:{opt nof:req}}do not display frequencies{p_end}
{synopt:{opt nom:issing}}do not display missing values{p_end}
{synopt:{opt all:rows}}display all combinations of row values{p_end}

{synopt:{opt val:cols}}arrange values of the final variable as columns{p_end}
{synopt:{opt nov:alcols}}arrange all combinations of values as rows{p_end}
{synopt:{cmdab:s:ort}[{opt (details)}]}sort the table{p_end}
{synopt:{opt v:ertical}}arrange dual statistics vertically rather than horizontally{p_end}

INCLUDE help tabel_options1

{title:Description}

{pstd}{cmd:tfreq} produces {bf:n-way} cross-tabulations. There are two main layouts: with and without value columns.

{pstd}In a (default) two-way cross-tab, values of the first variable define rows and values of the second variable define columns.
If you specify {opt nov:alcols}, every combination of values will define a row.

{pstd}When more than two variables are cross-tabulated, every combination of values will, by default, define a row. If you specify {opt val:cols}, the values of the {it:final} variable will define columns instead.

{title:Modifiers}

{pstd}The single available modifier, {cmd:(.)} will cause all non-missing values to be treated as the single value {cmd:non-missing}. Missing values will be treated normally; that is, they will be individually (cross-)tabulated.

{title:Options}

{phang}{opt r:ow}, {opt c:ol}, and {opt cell} add the relevant % to each cell of the display. These options also implicitly specify (and require) {opt val:cols}.

{phang}{opt nof:req} suppresses the display of frequencies; it is only valid in conjunction with {opt r:ow}, {opt c:ol}, and/or {opt cell}.

{phang}{opt nom:issing} restricts the display to cases in which {it:no} variables are missing.

{phang}{opt all:rows} includes 0-frequency rows in the display. This ensures that every row value-combination is displayed.

{phang}{opt val:cols} specifies that values of the final variable define columns, rather than being combined with the other values to define rows. This is the default when two variables are specified.

{phang}{opt nov:alcols} specifies that each combination of values define a row. This is the default when more than two variables are specified.

{phang}{cmdab:s:ort}[{opt (details)}] {hline 2} The full syntax is:

{pmore}{opt s:ort}

{pmore2}{it:or}

{pmore}{cmdab:s:ort(} [{opt f:req} | {opt l:abel} | {opt v:alue}] [{opt r:everse}] {cmd:)}

{pmore2}{it:where:}{p_end}
{p2colset 9 22 24 2}
{p2col:{opt f:req}}sorts by cell frequencies.{p_end}
{p2col:{opt l:abel}}sorts by labeled value{p_end}
{p2col:{opt v:alue}}sorts by unlabeled value{p_end}
{p2col:{opt r:everse}}sorts in descending rather than ascending order{p_end}

{phang2}o-{space 2}If {opt r:everse} is specified without an index, {opt f:req} is used.{p_end}
{phang2}o-{space 2}Similarly, {opt s:ort} is a shortcut for {cmdab:s:ort(}{cmdab:f:req)}.

{phang}{opt v:ertical} changes the arrangement of statistics within cells. When exactly two statistics per cell are specified, they are arranged side-by-side by default. This option changes the arrangement to above-and-below.

INCLUDE help tabel_options2n

{pmore}{it:nl1} governs the row-variable headings, and {it:nl2} governs the column-variable headings (if any).

INCLUDE help tabel_options2v

{pmore}{it:vl1} governs the row-value headings and {it:vl2} governs the column-value headings (if any).

INCLUDE help tabel_out2


{title:Weight}

{pstd}The weight syntax is (still) non-standard. It can be:

{pmore}{cmd:[} {cmdab:fw:eight=}{varname} {cmd:]}

{pstd}or just

{pmore}{cmd:[} {varname} {cmd:]}

