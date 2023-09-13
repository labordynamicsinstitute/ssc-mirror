{smcl}
{* *! version November 14, 2016 @ 17:39:56}{...}
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
{viewerjumpto "Syntax" "sqstrlev##syntax"}{...}
{viewerjumpto "Description" "sqstrlev##description"}{...}
{viewerjumpto "Options" "sqstrlev##options"}{...}
{viewerjumpto "Remarks" "sqstrlev##remarks"}{...}
{viewerjumpto "Examples" "sqstrlev##examples"}{...}
{viewerjumpto "Saved Results" "sqstrlev##saved_results"}{...}
{viewerjumpto "Acknowledgements" "sqstrlev##acknowledgements"}{...}
{viewerjumpto "Author" "sqstrlev##author"}{...}
{viewerjumpto "References" "sqstrlev##references"}{...}
{...}
{title:Title}

{phang}
{cmd:sqstrlev} {hline 2} title of command
{p_end}

{marker syntax}{...}
{title:Syntax}

{* put the syntax in what follows. Don't forget to use [ ] around optional items}{...}
{p 8 17 2}
   {cmd: sqstrlev}
   {varname}
   [{cmd:,}
   {it:options}
   ]
{p_end}

{* the new Stata help format of putting detail before generality}{...}
{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:sqom-options}
{synopt:{opt indel:cost(#)}}set indel costs to {it:#}{p_end}
{synopt:{cmdab:sub:cost(}{it:#}|{it:implied formula}|{it:matexp}|{it:matname}{cmd:)}}specify substitution costs{p_end}
{synopt:{cmdab:st:andard(}{it:#}|{cmd:cut}|{cmd:longer}|{cmd:longest}|{cmd:none)}}standardization of sequences of different length{p_end}
{synopt:{opt k(#)}}restrict indels (to save calculation time){p_end}
{syntab:additional options}
{synopt:{opt ignore:case}}ignore case of letter{p_end}
{synopt:{opt asciiletters:only}}set all non-ascii-letters to missing{p_end}
{synopt:{opt sound:ex}}caluculate distance on soundex transformed strings{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd} {cmd:sqstrlev} calculates the (n x n) Levensthein distances for
all pairwise comparisons of the strings in varname. The results are
written to SQdist and can be analysed by cluster analyis or related
methods {p_end}

{pstd} Users interesed to find the most similar string for each string
in varname are advised to use the egen function {cmd:sqstrnn()}; see {help sqegen}
{p_end}


{marker options}{...}
{title:Options}

{phang} {opt indelcost(#)} specifies the cost attached to an
insertion or deletion of an alignment. The default is {cmd:indelcost(1)}.

{phang} {cmdab:sub:cost(}#|{it:implied
formula}|{it:matexp}|{it:matname}} specifies the cost attached to a
substitution in an alignment. Substitution costs may be specified as
real number, or as full matrix.  Specifying
substitution cost as, for example, {cmd:subcost(3)} will attach the
cost of 3 to any substitution necessary in an alignment, regardless of
how similar the substituted values may be. The default is two times
the value specified as indel cost.  A full substitution cost matrix
can be specified either by specifying the name of a matrix containing
the substitution cost or by typing valid matrix syntax into the option
itself.  The matrix has to be a symmetric n*n matrix, where n is the
number of different elements in all sequences.

{phang}
{cmdab:st:andard(}#|{cmd:cut}|{cmd:longer}|{cmd:longest}|{cmd:none)}
is used to define the standardization of the resulting distances. With
{cmd:standard(#)} all sequences are cut to the length {it:#}.  The keyword
{cmd:cut} automatically cuts all sequences to the length of the
shortest sequence in the dataset. {cmd:standard(longer)} divides all
distances by the length of the longer sequence of the respective
alignment. {cmd:standard(longest)} divides all distances by the length
of the longest sequence in the dataset; this is the
default. {cmd:none} is specified if no standardization is needed.

{phang}{opt k(#)} is used to speed up the calculation of the
optimal matching algorithm. Within the parentheses, an integer
positive number between 1  and the number of positions of the longest
sequence can be given. The speed up will be higher with small numbers.
Very small numbers can have the effect that the algorithm doesn't find
the best alignment between some sequences, and this problem tends to
increase if substitution costs are high relative to indel
costs. The option is ignored when option {cmd:sadi()} is specified.

{p 8 8 2}Note: The implementation of the {cmd:k()} is based partly on the
source code of TDA, written by Goetz Rohwer and Ulrich Poetter. TDA is
a very powerful program for transitory data analysis. It is programmed
in C and distributed as freeware under the terms of the General
Public License. It is downloadable from
{browse "http://www.stat.ruhr-uni-bochum.de/tda.html"}.

{phang}{opt ignorecase} ignore case of letter so that a=A, b=B ... z=Z, and vice versa. {p_end}

{phang}{opt asciiletters:only}} All non-ascii-letters are removed from the string if this option is specified. {p_end}

{synopt:{opt sound:ex}}caluculate distance on soundex transformed strings. See {help soundex()} for an explanation of the soundex-transformation{p_end}


{marker examples}{...}
{title:Example(s)}{* Be sure to change Example(s) to either Example or Examples}

{phang}{cmd:. sqstrlev prename}{* an example with no explanation}
{p_end}

{phang}{cmd:. sqstrlev prename, indelcost(1) subcost(1.5) ignorecase asciilettersonly}
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Ulrich Kohler
email: {browse "mailto:ukohler@uni-potsdam.de":ukohler@uni-potsdam.de}
{p_end}


