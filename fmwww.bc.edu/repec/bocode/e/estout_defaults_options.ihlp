{p 4 8 2}
{cmd:style(}{it:style}{cmd:)} specifies a "style" for the output
table. {cmdab:def:aults:(}{it:style}{cmd:)} is a synonym for
{cmd:style(}{it:style}{cmd:)}. A "style" is a named combination of options
that is saved in an auxiliary file called {cmd:estout_}{it:style}{cmd:.def}.
{cmd:estout} is already equipped with four such files. The four styles
and their particulars are:

            settings {col 38}styles
            {col 26}{cmd:tab}{col 34}{cmd:fixed}{col 42}{cmd:tex}{col 50}{cmd:html}
            {hline 47}
            {cmd:begin}     {col 50}{cmd:<tr><td>}
            {cmd:delimiter} {col 26}{cmd:_tab}{col 34}{cmd:" "}{col 42}{cmd:&}{col 50}{cmd:</td><td>}
            {cmd:end}       {col 42}{cmd:\\}{col 50}{cmd:</td></tr>}
            {cmd:varwidth}  {col 26}{cmd:0}{col 34}{cmd:12}{col 42}{cmd:12}{col 50}{cmd:12}
            {cmd:modelwidth}{col 26}{cmd:0}{col 34}{cmd:12}{col 42}{cmd:12}{col 50}{cmd:12}
            {cmd:abbrev}    {col 26}off{col 34}on{col 42}off{col 50}off

{p 8 8 2}
The {cmd:tab} style is the default. Use {help estoutdef} to
view or edit defaults files. To make available an own set
of default options, edit one of the existing
files and save it as {cmd:estout_}{it:newstyle}{cmd:.def}
somewhere in the ado path. To call the new options set, type
{bind:{cmd:estout ..., defaults(}{it:newstyle}{cmd:)}}.
