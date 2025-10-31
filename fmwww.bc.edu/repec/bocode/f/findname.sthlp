{smcl}
{* 30mar2010/25may2015/12feb2020/14sep2023/30oct2025}{...}
{cmd:help findname}{right: ({browse "???":SJ25-4: dm0048_6})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{hi:findname} {hline 2}}List variables matching name
	patterns or other properties{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:findname} [{varlist}] {ifin} [{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Control}
{synopt :{opt inse:nsitive}}perform case-insensitive pattern matching{p_end}
{synopt :{opt loc:al(macname)}}put list of variable names in local macro {it:macname}{p_end}
{synopt :{opt csloc:al(macname)}}put comma-separated list of variable names in local macro {it:macname}{p_end}
{synopt :{opt not}}list variable names not in {varlist}{p_end}
{synopt :{opt place:holder(symbol)}}specify alternative to {cmd:@}{p_end}

{syntab :Display}
{synopt :{opt a:lpha}}list variable names in alphabetical order{p_end}
{synopt :{opt d:etail}}display additional details{p_end}
{synopt :{opt indent(#)}}indent output{p_end}
{synopt :{opt s:kip(#)}}gap between variables; default is {cmd:skip(2)}{p_end}
{synopt :{opt v:arwidth(#)}}display width for variable names; default is {cmd:varwidth(12)}{p_end}

{syntab :Selection by column position in dataset} 
{synopt :{opt col:umns(numlist)}}select variables according to column position{p_end}

{syntab :Selection by data types, values, and formats}
{synopt :{opt t:ype(typelist)}}has specified type{p_end}
{synopt :{opt all(condition)}}has all values satisfying {it:condition}{p_end}
{synopt :{opt any(condition)}}has any values satisfying {it:condition}{p_end}
{synopt :{opt f:ormat(patternlist)}}has display format matching {it:patternlist}{p_end}

{syntab :Selection by variable and value labels}
{synopt :{opt varl:abel}}has variable label{p_end}
{synopt :{opt varl:abeltext(patternlist)}}has variable label with text matching {it:patternlist}{p_end}
{synopt :{opt vall:abel}}has value label{p_end}
{synopt :{opt vall:abelname(patternlist)}}has value label with name matching {it:patternlist}{p_end}
{synopt :{opt vallabeltextd:ef(patternlist)}}has value label defined with text matching {it:patternlist}{p_end}
{synopt :{opt vallabeltextu:se(patternlist)}}has value label used with text matching {it:patternlist}{p_end}
{synopt :{opt vallabelcountd:ef(#1 [#2])}}has value label defined with designated number of labels{p_end}
{synopt :{opt vallabelcountu:se(#1 [#2])}}has value label used with designated number of labels{p_end}

{syntab :Selection by characteristics}
{synopt :{opt c:har}}has characteristic(s){p_end}
{synopt :{opt c:harname(patternlist)}}has characteristic(s) with name matching {it:patternlist}{p_end}
{synopt :{opt chart:ext(patternlist)}}has characteristic(s) with text matching {it:patternlist}{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{it:typelist} used in {cmd:type(}{it:typelist}{cmd:)} is a list of one
or more {help datatype:types}, each of which may be {cmd:numeric},
{cmd:string}, {cmd:byte}, {cmd:int}, {cmd:long}, {cmd:float}, or
{cmd:double}, 
may be {cmd:strL} (Stata 13 up), 
or may be a {it:{help numlist}}, such as {cmd:1/8} to mean
{bind:{cmd:str1} {cmd:str2} ... {cmd:str8}}.  Examples include{p_end}
{p2colset 13 43 45 2}
{p2col :{cmd:type(int)}}is of type {opt int}{p_end}
{p2col :{cmd:type(byte int long)}}is of integer {opt type}{p_end}
{p2col :{cmd:type(numeric)}}is a numeric variable{p_end}
{p2col :{cmd:type(strL)}}is of type {opt strL}{p_end}
{p2col :{cmd:type(1/40)}}is {opt str1}, {opt str2}, ..., {opt str40}{p_end}
{p2col :{cmd:type(numeric 1/2)}}is numeric or {opt str1} or {opt str2}{p_end}
{p2colreset}{...}

{phang}
{it:patternlist} used in, for example, {cmd:format(}{it:patternlist}{cmd:)}, is
a list of one or more patterns.  A pattern is the expected name or text
with the likely addition of the characters {cmd:*} and {cmd:?}.  {cmd:*}
indicates 0 or more characters go here and {cmd:?} indicates exactly 1
character goes here.  Examples include{p_end}

{p2colset 13 43 45 2}
{p2col :{cmd:format(*f)}}format is %{it:#}.{it:#}{cmd:f}{p_end}
{p2col :{cmd:format(%t*)}}has time or date format{p_end}
{p2col :{cmd:format(%-*s)}}is a left-justified string{p_end}
{p2col :{cmd:varl(*weight*)}}variable label includes word {opt weight}{p_end}
{p2col :{cmd:varl(*weight* *Weight*)}}variable label includes word {opt weight} or {opt Weight}{p_end}
{p2colreset}{...}

{phang}
To match a phrase, it is important to enclose the entire phrase in quotes.

	    {cmd:varl("*some phrase*")}    variable label has {opt some phrase}

{phang}
If instead you used {cmd:varl(*some phrase*)}, then only variables having
labels ending in {opt some} or starting with {opt phrase} would be listed.

{phang}
{it:condition} used in {cmd:all()} or {cmd:any()} is a true-or-false condition 
defined by an expression in which variable names are represented by {cmd:@}.
For example, {cmd:any(@ < 0)} selects numeric variables in which any values 
are negative.


{title:Description}

{pstd}
{cmd:findname} lists variable names of the dataset currently in memory
in a compact or detailed format and lets you specify subsets of
variables to be listed, either by name or by properties (for example, the
variables are numeric).  In addition, {cmd:findname} leaves behind in
{opth r(varlist)} the names of variables selected so that you can use
them in a subsequent command.

{pstd}
{cmd:findname}, typed without arguments, lists all variable names of the
dataset currently in memory in a compact form.

{pstd}
If two or more options specifying properties of variables are specified,
{cmd:findname} identifies only those variables that satisfy all the option
specifications, that is, the intersection of all the subsets identified.  The
{cmd:not} option provides a direct way to identify the complementary set.  Two
or more calls to {cmd:findname} with results saved in local macros using the
{cmd:local()} option may be used together with macro operations to produce the
union, set difference, etc., of different subsets.

{pstd}
{cmd:if} and {cmd:in} when specified only affect the operation of {cmd:any()}, 
{cmd:all()}, {cmd:vallabeltextuse()}, or {cmd:vallabelcountuse()}.


{title:Options}

{dlgtab:Control}

{phang}
{opt insensitive} specifies that the matching of any pattern in 
{it:patternlist} be case-insensitive.  For example, 
{cmd:varl(*weight*) inse} is an alternative to, and more inclusive than, 
{cmd:varl(*weight* *Weight*)}.

{phang}
{opt local(macname)} puts the resulting list of variable names into 
local macro {it:macname}.

{phang}
{opt cslocal(macname)} puts the resulting list of variable names, 
separated by commas, into local macro {it:macname}. This option may 
be preferred, for example, if output is to be fed to a function needing
that form of input.

{p 8 8 2}These options may be specified together. However, if the 
same macro name is specified to both options, {opt cslocal()} overwrites
the result of {opt local()}.

{phang}
{opt not} specifies that {varlist} or the specifications given define the set
of variables not to be listed.  For instance, {bind:{cmd:findname pop*, not}}
specifies that all variables not starting with the letters {opt pop} be
listed.  The default is to list all the variables in the dataset or, if
{it:varlist} or particular properties are specified, to list the variable
names so defined.

{phang}
{opt placeholder(symbol)} specifies an alternative to {cmd:@} to use in the
{cmd:any()} or {cmd:all()} option.  This should only be necessary for making
string comparisons involving {cmd:@} as a literal character (or if your {cmd:@}
key is somehow unavailable).

{dlgtab:Display} 

{phang}
{opt alpha} specifies that the variable names be listed in alphabetical
order.

{phang}
{opt detail} specifies that detailed output identical to that of 
{helpb describe} be produced.  If {opt detail} is specified, 
{opt indent()}, {opt skip()}, and {opt varwidth()} are ignored.

{phang}
{opt indent(#)} specifies the amount the lines are indented.

{phang}
{opt skip(#)} specifies the number of spaces between variable names; the
default is {cmd:skip(2)}.

{phang}
{opt varwidth(#)} specifies the display width of the variable names; the
default is {cmd:varwidth(12)}.

{dlgtab:Selection by column position in dataset} 

{phang} 
{opt columns(numlist)} selects variables according to column position.
For example, {cmd:columns(1)} selects the first variable in the dataset, and
{cmd:columns(1/3)} selects the first three variables in the dataset.  Negative
numbers count from the end of the dataset, so {cmd:columns(-1)} selects the
last variable in the dataset, and {cmd:columns(-3/-1)} selects the last three
variables in the dataset.  {cmd:columns(0)} would be ignored, as would be any
column positions that do not correspond to variables.  (Note: If you specify
this option, any {it:varlist} is ignored.) 

{dlgtab:Selection by data types, values, and formats}

{phang}
{opt type(typelist)} selects variables of the specified {it:typelist}.
Typing {cmd:findname, type(string)} would list all the names of string variables in
the dataset, and typing {bind:{cmd:findname pop*, type(string)}} would
list all the names of string variables beginning with the letters {opt pop}.

{phang}
{opt all(condition)} selects variables that have all values 
satisfying {it:condition}.  If either {cmd:if} or {cmd:in} is specified, 
attention is restricted to the observations specified.

{phang} 
{opt any(condition)} selects variables that have any values 
satisfying {it:condition}.  If either {cmd:if} or {cmd:in} is specified, 
attention is restricted to the observations specified.

{phang}
With either {cmd:all()} or {cmd:any()}, {it:condition}s that mismatch type are ignored.

{phang} 
{opt format(patternlist)} selects variables whose {help format}
matches any of the patterns in {it:patternlist}.  {cmd:format(*f)} would
select all variables with formats ending in {cmd:f}, which presumably
would be all {cmd:%}{it:#}{cmd:.}{it:#}{cmd:f},
{cmd:%0}{it:#}{cmd:.}{it:#}{cmd:f}, and
{cmd:%-}{it:#}{cmd:.}{it:#}{cmd:f} formats.  {cmd:format(*f *fc)} would
select all formats ending in {opt f} or {opt fc}.

{dlgtab:Selection by variable and value labels}

{phang}
{opt varlabel} selects variables with defined {help label:variable labels}.

{phang} 
{opt varlabeltext(patternlist)} selects variables with variable-label text
matching any of the words or phrases in {it:patternlist}.

{phang}
{opt vallabel} selects variables with defined {help label:value labels}.

{phang} 
{opt vallabelname(patternlist)} selects variables with value-label names
matching any of the words in {it:patternlist}.

{phang} 
{opt vallabeltextdef(patternlist)} selects variables with value-label text 
defined matching any of the words or phrases in {it:patternlist}.

{phang} 
{opt vallabeltextuse(patternlist)} selects variables with value-label text
defined and used matching any of the words or phrases in {it:patternlist}.
For example, a value label may be defined for value 42 as "answer" and
associated with a variable.  In that case, the previous option would find it
if prompted to search for such text.  But if the value 42 does not in fact
occur in that variable, this option would not find it.  If either {cmd:if} or
{cmd:in} is specified, attention is restricted to the observations specified.

{phang} 
{opt vallabelcountdef(#1 [#2])} selects variables with the designated
number of value labels defined.

{p 8 8 2}
If just one number {it:#1} is specified (for example,
{cmd:vallabelcountdef(2)}), then a variable must have precisely that many
labels defined.  If two numbers are specified, then a variable must have
between {it:#1} and {it:#2} labels defined, the limits being inclusive, unless
the second argument is system missing.  Thus, if {cmd:vallabelcountdef(2 4)}
is specified, there must be 2, 3, or 4 value labels defined.  Two numbers may
be given in any order.  Note that missing is allowed, so that
{cmd:vallabelcountdef(5 .)} would mean 5 or more value labels defined.
Note that you may specify {cmd:vallabelcountdef(0)} to find variables with
value label sets attached but no value labels defined.  

{phang} 
{opt vallabelcountuse(#1 [#2])} selects variables with the designated
number of value labels defined and used.  For example, a value label may
be defined for value 42 as "answer" and associated with a variable.  In
that case, the previous option would count it if prompted.  But if the
value 42 does not in fact occur in that variable, this option would not
count it.

{p 8 8 2}
If just one number {it:#1} is specified (for example, {cmd:vallabeluse(2)}),
then a variable must have precisely that many labels defined and used.  If two
numbers are specified, then a variable must have between {it:#1} and {it:#2}
labels defined and used, the limits being inclusive, unless the second
argument is system missing.  Thus, if {cmd:vallabelcountuse(2 4)} is
specified, there must be 2, 3, or 4 value labels defined and used.  Two
numbers may be given in any order.  Note that missing is allowed, so that
{cmd:vallabelcountuse(5 .)} would mean 5 or more value labels defined and
used.  If either {cmd:if} or {cmd:in} is specified, attention is restricted to
the observations specified. Note that you may specify
{cmd:vallabelcountuse(0)} to find variables with value label sets attached but
no value labels defined.  

{dlgtab:Selection by characteristics}

{phang}
{opt char} selects variables with defined {help char:characteristics}.
Notes in the sense of {help notes} are characteristics.

{phang} 
{opt charname(patternlist)} selects variables with characteristic names matching
any of the words in {it:patternlist}.

{phang} 
{opt chartext(patternlist)} selects variables with characteristic text matching
any of the words or phrases in {it:patternlist}.


{title:Examples}

{pstd}
Sandbox dataset{p_end}
{phang2}{cmd: . sysuse auto, clear}{p_end}

{pstd}
All variables{p_end}
{phang2}{cmd:. findname}{p_end}

{pstd}
First and last variables{p_end}
{phang2}{cmd:. findname, col(1 -1)}{p_end}

{pstd}All string variables{p_end}
{phang2}{cmd:. findname, type(string)}{p_end}
{phang2}{cmd:. edit `r(varlist)'}{p_end}

{pstd}All {cmd:str1}, {cmd:str2}, {cmd:str3}, {cmd:str4} variables{p_end}
{phang2}{cmd:. findname, type(1/4)}

{p 4 4 2}All numeric variables{p_end}
{phang2}{cmd:. findname, type(numeric)}{p_end}
{phang2}{cmd:. order `r(varlist)'}{p_end}

{phang2}{cmd:. findname, type(numeric)}{p_end}
{phang2}{cmd:. summarize `r(varlist)'}{p_end}

{p 4 4 2}
All {cmd:byte} or {cmd:int} variables{p_end}
{phang2}{cmd:. findname, type(byte int)}{p_end}

{p 4 4 2}
All {cmd:float} variables{p_end}
{phang2}{cmd:. findname, type(float)}{p_end}

{p 4 4 2}
All variables that are not {cmd:float}{p_end}
{phang2}{cmd:. findname, type(float) not}{p_end}

{p 4 4 2}
All date variables, that is, those with formats {cmd:%t*} or {cmd:%-t*}{p_end}
{phang2}{cmd:. findname, format(%t* %-t*)}{p_end}

{p 4 4 2}
All variables with only integer values {p_end}
{phang2}{cmd:. findname, all(@ == int(@))}{p_end}

{p 4 4 2}
All variables with any missing values {p_end}
{phang2}{cmd:. findname, any(missing(@))}{p_end}

{p 4 4 2}
All variables with any extended missing values {cmd:.a} to {cmd:.z} {p_end}
{phang2}{cmd:. findname, any(inrange(@, .a, .z))}{p_end}

{p 4 4 2}
All indicator or dummy variables with all values 0, 1, or missing {p_end}
{phang2}{cmd:. findname, all(inlist(@, 0, 1) | missing(@))}{p_end}

{p 4 4 2}
All variables with any negative values {p_end}
{phang2}{cmd:. findname, any(@ < 0)}{p_end}

{p 4 4 2}
All variables that are constants {p_end}
{phang2}{cmd:. findname, all(@ == @[1])}{p_end}

{p 4 4 2}
Variables with left-justified string formats{p_end}
{phang2}{cmd:. findname, format(%-*s)}{p_end}

{p 4 4 2}
Variables with comma formats{p_end}
{phang2}{cmd:. findname, format(*c)}{p_end}

{p 4 4 2}
All variables with value labels attached{p_end}
{phang2}{cmd:. findname, vallabel}{p_end}

{p 4 4 2}
All variables with the value label {cmd:origin} attached{p_end}
{phang2}{cmd:. findname, vallabelname(origin)}{p_end}

{p 4 4 2}
All variables with precisely two value labels defined{p_end}
{phang2}{cmd:. findname, vallabelcountdef(2)}{p_end}

{p 4 4 2}
Variables with characteristics defined{p_end}
{phang2}{cmd:. findname, char}{p_end}

{p 4 4 2}
Variables with notes {p_end}
{phang2}{cmd:. findname, charname(note*)} {p_end}

{p 4 4 2} 
Find text in characteristics{p_end}
{phang2}{cmd:. notes mpg: hidden treasure}{p_end}
{phang2}{cmd:. findname, chartext(*treasure*)}{p_end}


{title:Author} 

{p 4 4 2}Nicholas J. Cox{p_end}
{p 4 4 2}Durham University{p_end}
{p 4 4 2}Durham City, U.K.{p_end}
{p 4 4 2}n.j.cox@durham.ac.uk{p_end}


{title:Acknowledgments} 

{p 4 4 2}{cmd:findname} owes a major debt to {helpb ds}.  {cmd:ds} and its
relatives under differing names have had a complicated history in various
official and community-contributed versions (for example, Anonymous [1992]; Cox [2000,
2001]; Weiss [2008]; and {cmd:ds2}, {cmd:ds3}, and {cmd:ds5} on SSC).  My
earlier work was aided by suggestions from Richard Goldstein, William Gould,
Jay Kaufman, and Fred Wolfe.  More recently, Maarten Buis, Martin Weiss, Vince
Wiggins, and several members of Statalist provided helpful comments both
directly and indirectly.  Stephen Okiya suggested the problem of counting 
value labels on Statalist: Google Statalist 1429068.  Daniel Klein's
comments around value-label options and {cmd:columns()} were very helpful.
Andreas Fabian Fischer posed the problem of finding variables with 
attached value label sets that are empty or not used. 


{title:References} 

{p 4 8 2}Anonymous.  1992.  Short describes, finding variables, and codebooks.
{browse "http://www.stata.com/products/stb/journals/stb8.pdf":{it:Stata Technical Bulletin} 8: 3-5}.  Reprinted in 
{it:Stata Technical Bulletin Reprints}, vol. 2, pp. 11-14.  College Station,
TX: Stata Press.

{p 4 8 2}Cox, N. J.  2000.  dm78: Describing variables in memory.
{browse "http://www.stata.com/products/stb/journals/stb56.pdf":{it:Stata Technical Bulletin} 56: 2-4}.  Reprinted in 
{it:Stata Technical Bulletin Reprints}, vol. 10, pp. 15-17.  College Station,
TX: Stata Press.

{p 4 8 2}-----.  2001.  dm78.1: Describing variables in memory: update to
Stata 7.  
{browse "http://www.stata.com/products/stb/journals/stb60.pdf":{it:Stata Technical Bulletin} 60: 3}.  Reprinted in 
{it:Stata Technical Bulletin Reprints}, vol. 10, pp. 17.  College Station, TX:
Stata Press.

{p 4 8 2}Weiss, M. 2008.  Stata tip 66: ds--A hidden gem.
{browse "http://www.stata-journal.com/article.html?article=dm0040":{it:Stata Journal} 8: 448-449}.


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 23, number 4: {browse "https://doi.org/10.1177/1536867X231212454":dm0048_5},{break}
          {it:Stata Journal}, volume 20, number 2: {browse "https://doi.org/10.1177/1536867X20931029":dm0048_4},{break}
          {it:Stata Journal}, volume 15, number 2: {browse "http://www.stata-journal.com/article.html?article=up0047":dm0048_3},{break}
          {it:Stata Journal}, volume 12, number 1: {browse "http://www.stata-journal.com/article.html?article=up0035":dm0048_2},{break}
          {it:Stata Journal}, volume 10, number 4: {browse "http://www.stata-journal.com/article.html?article=up0030":dm0048_1},{break}
          {it:Stata Journal}, volume 10, number 2: {browse "http://www.stata-journal.com/article.html?article=dm0048":dm0048}

{p 5 14 2}
Manual:  {bf:[D] ds}

{p 7 14 2}
Help:  {manhelp compress D}, {manhelp codebook D},
         {manhelp describe D}, {manhelp format D},
	 {manhelp label D}, {manhelp lookfor D}, {manhelp notes D},
	 {manhelp order D}, {manhelp rename D}
{p_end}
