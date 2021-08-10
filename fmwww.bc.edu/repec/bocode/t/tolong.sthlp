{smcl}
{* *! version 1.0.1  09sep2020}{...}
{vieweralsosee "reshape" "reshape"}{...}
{viewerjumpto "Syntax" "tolong##syntax"}{...}
{viewerjumpto "Description" "tolong##description"}{...}
{viewerjumpto "Options" "tolong##options"}{...}
{viewerjumpto "Remarks" "tolong##remarks"}{...}
{viewerjumpto "Examples" "tolong##examples"}{...}
{viewerjumpto "Stored results" "tolong##results"}{...}
{p2colset 1 11 13 2}{...}
{p2col:{bf:tolong} {hline 2}}Faster {bf:reshape long}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Basic syntax

{p 8 12 2}
{cmd:tolong} {it:stubname} [{it:stubname} ...] [{cmd:,}
    {cmd:i(}{varlist}{cmd:)} {cmd:j(}{newvar}{cmd:)} {cmd:sort}]

{pstd}
Syntax with renaming

{p 8 12 2}
{cmd:tolong} {newvar}{cmd:=}{it:stubname}
    [{newvar}{cmd:=}{it:stubname} ...] [{cmd:,}
    {cmd:i(}{varlist}{cmd:)}
    {cmd:j(}{newvar}{cmd:)} {cmd:sort}]

{pstd}
where each {it:stubname} is one of the following:

{p2colset 9 23 25 2}{...}
{p2col :{it:stubname}}variables of the form {cmd:var}{it:j} with numeric
{it:j}, string {it:j}, or both{p_end}
{p2col :{it:stubname}{cmd:*}}same as above{p_end}
{p2col :{it:stubname}{cmd:#}}{cmd:var}{it:j} with numeric {it:j}{p_end}
{p2col :{it:stubname}{cmd:@}}{cmd:var}{it:j} with string {it:j}{p_end}
{p2colreset}{...}

{pstd}
and {bf:*}, {bf:#}, and {bf:@} characters may be specified at any place in
{it:stubname} to indicate the location of {it:j}; see the
{help tolong##examples:Examples}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tolong} converts data from wide to long form as follows:

                                            {it:long}
           {it:wide}                           {c TLC}{hline 12}{c TRC}
        {c TLC}{hline 16}{c TRC}                {c |} {it:i  j}  {it:stub} {c |}
        {c |} {it:i}  {it:stub}{bf:1} {it:stub}{bf:2} {c |}                {c |}{hline 12}{c |}
        {c |}{hline 16}{c |}     tolong     {c |} 1  {bf:1}   4.1 {c |}
        {c |} 1    4.1   4.5 {c |}   <{hline 8}>   {c |} 1  {bf:2}   4.5 {c |}
        {c |} 2    3.3   3.0 {c |}                {c |} 2  {bf:1}   3.3 {c |}
        {c BLC}{hline 16}{c BRC}                {c |} 2  {bf:2}   3.0 {c |}
                                          {c BLC}{hline 12}{c BRC}


{marker options}{...}
{title:Options}

{phang}
{opth i(varlist)}
    specifies the variables whose unique values denote a logical observation.
    If you omit this option, the {bf:i} variable is generated as the observation
	number and will be named {bf:_i} in the reshaped data.

{phang}
{cmd:j(}{newvar}{cmd:)}
    specifies the variable that will hold {it:j} values from the variable
    names that match {it:stubnames}.
    If you omit this option, the {bf:j} variable will be named {bf:_j}.

{phang}
{cmd:sort} specifies that the data be sorted on {bf:i()} and {bf:j()} variables
    after the reshape.
    The default is to keep the data arranged in the original order of the
    {bf:i()} variables.


{marker remarks}{...}
{title:Remarks}

{pstd}
Major differences between {bf:tolong} and {bf:reshape long} are as follows:

{phang2}
  1.  {bf:tolong} does not require or assert that observations are unique
      on {bf:i()}. You can confirm that the variables specified in {bf:i()}
	  uniquely identify the observations before using {bf:tolong} with the
	  {helpb isid} command.

{phang2}
  2.  When {it:varlist} contains variables that can be indexed by both
      numeric {it:j} and string {it:j} {bf:tolong} provides greater control.
	  The user can choose both (by default or with the {bf:*} wildcard),
	  numeric only ({bf:#} wildcard), or string only ({bf:@} wildcard).
	  {bf:reshape long} reshapes on numeric {it:j} only (default)
	  or both numeric and string values (with the {bf:string} option).
	  {bf:reshape long} uses the {bf:@} wildcard to control the location of
	  both numeric and string indexes, thus there is no way to isolate just
	  string indexes with {bf:reshape long}.

{phang2}
  3.  By default, {bf:tolong} does not sort the data on {bf:i()} and {bf:j()}
      variables after the data are reshaped. The reshaped data are ordered
      by the original sort order of {bf:i()} variables and within each {bf:i()}
      group the data are ordered by the new {bf:j()} variable. The user can
      specify option {bf:sort} to have the reshaped data sorted by {bf:i()}
      and {bf:j()}, which replicates the behavior of {bf:reshape long}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 2}{p_end}
{phang2}{cmd:. gen id = _n}{p_end}
{phang2}{cmd:. gen x1 = rnormal()}{p_end}
{phang2}{cmd:. gen x2 = rnormal()}{p_end}
{phang2}{cmd:. gen xm = rnormal()}{p_end}
{phang2}{cmd:. gen xf = rnormal()}{p_end}
{phang2}{cmd:. list}{p_end}

{pstd}
Convert data to long form; {bf:x#} matches {bf:x1} and {bf:x2}. Equivalent
to {bf:reshape long x, i(id)}
{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tolong x#, i(id)}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
Convert data to long form; {bf:x*} matches {bf:x1}, {bf:x2}, {bf:xm},
and {bf:xf}. Equivalent to {bf:reshape long x, i(id) string}
{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tolong x*, i(id)}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
Convert data to long form; {bf:x@} matches {bf:xm} and {bf:xf}.
{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tolong x@, i(id)}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
With renaming, reshape {bf:x1} and {bf:x2} into {bf:xnum}, and {bf:xm}
and {bf:xf} into {bf:xstr}.
{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tolong xnum=x# xstr=x@, i(id)}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. restore}{p_end}
{hline}

{pstd}
Rename {bf:x1 x2 xm xf} to {bf:x1x x2x xmx xfx}
{p_end}
{phang2}{cmd:. rename (x*) (x*x)}{p_end}

{pstd}
Convert data to long form, {bf:x#x} matches {bf:x1x} and {bf:x2x}. Equivalent
to {bf:reshape long x@x, i(id)}.
{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tolong x#x, i(id)}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
Convert data to long form, {bf:x*x} matches {bf:x1x}, {bf:x2x}, {bf:xmx},
and {bf:xfx}. Equivalent to {bf:reshape long x@x, i(id) string}.
{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tolong x*x, i(id)}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
Convert data to long form, {bf:x@x} matches {bf:xmx} and {bf:xfx}.
{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tolong x@x, i(id)}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. restore}{p_end}


{marker authors}{...}
{title:Author}

{pstd}Rafal Raciborski{p_end}
{pstd}rraciborski@gmail.com{p_end}

