{p 4 8 2}
{cmd:title(}<{it:string}>{cmd:)} may be used to specify a title for the table.
The {it:string} is printed at the top of the table unless {cmd:prehead()},
{cmd:posthead()}, {cmd:prefoot()}, or {cmd:postfoot()} is specified. In
the latter case, the variable {cmd:@title} can be used to insert the title.

{p 4 8 2}
{cmd:legend} adds a legend explaining the significance symbols and
thresholds.

{p 4 8 2}
{cmd:prehead(}{it:str_list}{cmd:)}, {cmd:posthead(}{it:str_list}{cmd:)},
{cmd:prefoot(}{it:str_list}{cmd:)}, and {cmd:postfoot(}{it:str_list}{cmd:)} may
be used to define lists of text lines to appear before and after the table
heading or the table footer. For example, the specification

{p 12 12 2}
{cmd:. estout ..., prehead("\S_DATE \S_TIME" "")}

{p 8 8 2} would add a line containing the current date and time followed 
by an empty line before the table. Various substitution functions can be 
used as part of the text lines specified in {it:str_list}, including 
{cmd:@span} to print the total number of physical columns in the table 
(including the left stub that holds the variable names), {cmd:@M} to print 
the number of models included, {cmd:@discrete} to print the contents of 
the {cmd:discrete()} option, {cmd:@starlegend} to print a legend 
explaining the significance symbols, and {cmd:@title} to print the 
contents of the {cmd:title()} option. For example, a table heading to be 
used with LaTeX might be formatted as follows:

{p 12 12 2}
{cmd:. estout ..., prehead(\begin{tabular}{l*{@M}{r}})}

{p 4 8 2}
{cmd:label} specifies that variable labels be displayed instead of variable
names in the left stub of the table.

{p 4 8 2}
{cmd:varlabels(}{it:matchlist}[{cmd:,} {it:suboptions}]{cmd:)} may be used to
relabel the regressors from the models, where {it:matchlist} is

{p 12 12 2}
{it:name} <{it:label}> [ {it:name} <{it:label}> ...]

{p 8 8 2}
For example, specify
{cmd:varlabels(_cons Constant)} to replace each occurrence of {cmd:_cons}
with {cmd:Constant}. Do not use equation names in the specification of the
variable names. The {it:suboptions} are:

{p 12 16 2}
  {cmd:blist(}{it:matchlist}{cmd:)} to assign specific prefixes to
  certain rows in the table body. Specify the {it:matchlist} as pairs of
  regressors and prefixes, that is:

{p 20 20 2}
  {it:name} <{it:prefix}> [ {it:name} <{it:prefix}> ...]

{p 16 16 2}
  A {it:name} is a variable name (e.g. {cmd:price}), an equation name
  followed by a colon (e.g. {cmd:mean:}), or a full name 
  (e.g. {cmd:mean:price}). Note that equation names cannot be used if the
  {cmd:unstack} option is specified. The prefix will include the total number
  of physical columns in the table if the {cmd:@span} token is used in its
  definition.

{p 12 16 2}
  {cmd:elist(}{it:matchlist}{cmd:)} to assign specific suffixes to
  certain rows in the table body (see the analogous {cmd:blist()} option
  above). This option may, for example, be useful for separating 
  thematic blocks of variables by
  adding vertical space at the end of each block. A LaTeX example:

{p 20 20 2}
{cmd:. estout ..., varlabels(,elist(price \addlinespace mpg \addlinespace))}

{p 16 16 2}
  (the  macro {cmd:\addlinespace} is provided by the
  {cmd:booktabs} package in LaTeX)

{p 12 16 2}
  {it:{help estout_label_subopts:label_subopts}}, which are 
  explained in their own section.

{p 4 8 2}
{cmd:mlabels(}{it:str_list}[{cmd:,} {it:suboptions}]{cmd:)} determines the
model captions printed in the table heading. The default is to use the names of
the stored the estimates (or their titles, if the {cmd:label} option is
specified and titles are available). The {it:suboptions} for use with
{cmd:mlabels} are:

{p 12 16 2}
  {cmd:numbers} to cause the model labels to be numbered consecutively.

{p 12 16 2}
  {cmd:depvars} to specify that the name (or label) of the (first) dependent
  variable of the model be used as model label.

{p 12 16 2}
  {it:{help estout_label_subopts:label_subopts}}, which are explained in their own section.

{p 4 8 2}
{cmd:collabels(}{it:str_list}[{cmd:,} {it:{help estout_label_subopts:label_subopts}}]{cmd:)} 
specifies
labels for the columns within models or equations. The default is to compose a
label from the names or labels of the statistics printed in the cells of that
column. The {it:label_subopts} are explained in their own section below.

{p 4 8 2}
{cmd:eqlabels(}{it:str_list}[{cmd:,} {it:{help estout_label_subopts:label_subopts}}]{cmd:)}
labels the
equations. The default is to use the equation names as stored by the estimation
command, or to use the variable labels if the equation names correspond to
individual variables and the {cmd:label} option is specified. The
{it:label_subopts} are explained in their own section below.

{p 4 8 2}
{cmd:mgroups(}{it:str_list}[{cmd:,} {it:suboptions}]{cmd:)} may be used to
labels groups of (consecutive) models at the top of the table heading. The
labels are placed in the first physical column of the output for the group of
models to which they apply. The {it:suboptions} for use with {cmd:mgroups}
are:

{p 12 16 2}
  {cmd:pattern(}{it:pattern}{cmd:)} to establish how the models are to be grouped.
  {it:pattern} should be a list of zeros and ones, with ones indicating the
  start of a new group of models. For example,
  
{p 20 20 2}
{cmd:. estout ..., mgroups("Group 1" "Group 2", pattern(1 0 0 1 0))}

{p 16 16 2}
  would group Models 1, 2, and 3 together and then groups Models 4 and 5
  together as well. Note that the first group will always start with the first
  model regardless of whether the first token of {it:pattern} is a one or a
  zero.

{p 12 16 2}
  {it:{help estout_label_subopts:label_subopts}}, which are explained 
  in their own section. In
  particular, the {cmd:span} suboption might be of interest here.
