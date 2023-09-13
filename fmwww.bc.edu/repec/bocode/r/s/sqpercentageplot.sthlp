{smcl}
{* *! version März 31, 2016 @ 19:32:27}{...}
{* link to manual entries (really meant for stata to link to its own docs}{...}
{vieweralsosee "[G] twoway" "mansection [G] twoway"}{...}
{* a divider if needed}{...}
{vieweralsosee "" "--"}{...}
{* link to other help files which could be of use}{...}
{vieweralsosee "sqclusterdat" "help sqclusterdat "}{...}
{vieweralsosee "sqdes" "help sqdes "}{...}
{vieweralsosee "sqegen" "help sqegen "}{...}
{vieweralsosee "sqindexplot" "help sqindexplot "}{...}
{vieweralsosee "sqmdsadd" "help sqmdsadd "}{...}
{vieweralsosee "sqmodalplot" "help sqmodalplot "}{...}
{vieweralsosee "sqom" "help sqom "}{...}
{vieweralsosee "sqpercentageplot" "help sqpercentageplot "}{...}
{vieweralsosee "sqset" "help sqset "}{...}
{vieweralsosee "sqstat" "help sqstat "}{...}
{vieweralsosee "sqstrlev" "help sqstrlev "}{...}
{vieweralsosee "sqstrmerge" "help sqstrmerge "}{...}
{vieweralsosee "sqtab" "help sqtab "}{...}
{...}
{title:Title}

{phang}
{cmd:sqpercentageplot} {hline 2} Stacked Bar Chart for Percentages of Elements by Order (with Overlayed Entropy)
{p_end}

{marker syntax}{...}
{title:Syntax}

{* put the syntax in what follows. Don't forget to use [ ] around optional items}{...}
{p 8 17 2}
   {cmd: sqpercentageplot}
   {ifin}
   [{cmd:,}
   {it:options}
   ]
{p_end}

{* the new Stata help format of putting detail before generality}{...}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt ent:ropy}}Show Entropy by Ordervar{p_end}
{synopt:{opt nosecond}}Do not show 2nd Line for Entropy{p_end}
{synopt:{cmd:baropts(}{help barlook_options}{cmd:)}}Appearance of Stacked Bars{p_end}
{synopt:{cmd:lopts(}{help connect_options}{cmd:)}}Appearance of Line for Entropy{p_end}
{synopt:{cmd:l2opts(}{help connect_options}{cmd:)}}Appearance of 2nd Line for Entropy{p_end}
{synopt:{help twoway_options}}{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd} {cmd:sqpercentageplot} shows stacked bar charts of the
percentage distribution of elements by the ordervar. Option
{cmd:twoway} overlays a line for the entropy.{p_end}

{pstd} Note that this plot is not a sequence analysis method in the
strict sense, as it does not treat the sequence holistically. However,
percentage plots such as this one are frequently used in the context
of sequence analysis. {p_end}

{marker options}{...}
{title:Options}

{phang}{opt entropy} overlays a line plot for the entropy by position
{p_end}

{phang}{opt nosecond} erases the shadow line. By default,
{cmd:sqpercentageplot} displays a tiny white border around the the
line for the entropy in order to make the line more standout. This is
often useful when displaying the line in the foreground of stacked
bars that already have many colors. The option {cmd:nosecond} turns
this shadow line off.  {p_end}

{phang}{opt baropts()} Options to control the appearance of the
 bars. All options described under {cmd:help} {help barlook_options}
 are allowed.  {p_end}

{phang}{opt lopts()} Options to control the appearance of the entropy
line. All options described under {cmd:help} {help connect_options} are allowed.
 {p_end}

{phang}{opt l2opts()} Options to control the appearance of the shadow
 line. All options described under {cmd:help} {help connect_options}
 are allowed.  {p_end}

{phang}{it: twoway options} are any options allowed for {cmd:graph twoway};
 see {cmd:help} {help twoway_options}.  {p_end}

{marker examples}{...}
{title:Example(s)}{* Be sure to change Example(s) to either Example or Examples}

{phang}{cmd:. sqpercentageplot}{* an example with no explanation}
{p_end}
{phang}{cmd:. sqpercentageplot, entropy}{* an example with no explanation}
{p_end}
{phang}{cmd:. sqpercentageplot, entropy noshadow}{* an example with no explanation}
{p_end}

{marker acknowledgments}{...}
{title:Acknowledgements}

{pstd}
Christian Brzinsky-Fay provided an initial version of the program
{marker author}{...}

{title:Author}

{pstd}
Ulrich Kohler
email: {browse mailto:ukohler@uni-potsdam.de}
{p_end}

{marker references}{...}
{title:References}

{pstd}{* here is a shill example entry from the -regress- command}
{marker AP2009}{...}
{phang}
XXXX
