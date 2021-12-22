{smcl}
{hline}
help for {cmd:whichlist}{right:(Roger Newson)}
{hline}


{title:Input list of package file items and output lists of present and absent items}

{p 8 21 2}
{cmd:whichlist} {it:item_list} [ , {cmdab:p:ackagelist(}{it:packagename_list}{cmd:)} 
  {cmdab:noi:sily}
  ]

{pstd}
where {it:item_list} is a list of one or more items of form {it:filename}[{it:.filetype}]
valid for input to {helpb which},
and {it:packagename_list} is a list of names that might belong to Stata packages
that might contain the {it:item_list} items.

{title:Description}

{pstd}
{cmd:whichlist} inputs a list of one or more items that might be included in Stata packages
and/or input to the {helpb which} command,
and (optionally) a list of Stata package names
that might belong to packages including the input items.
It outputs lists of present and absent items
and (optionally) lists of complete and incomplete Stata packages.
It is useful for finding out which of a list of Stata packages the user has installed.


{title:Options for {cmd:whichlist}}

{phang}	
{cmd:packagelist(}{it:packagename_list}{cmd:)} specifies a list of one or more names,
which might belong to Stata packages
which might contain the input items in the {it:item_list}.
If it is at least as long as the {it:item_list},
then the {it:k}th item of the package list
is assumed to be the name of a package,
which should contain the {it:k}th item of the {it:item_list}.
If it is present, but shorter than the  {it:item_list},
then it is expanded to the same length as the {it:item_list}
by adding multiple copies of the last item of the input package name list.
Therefore, if only one package name is input in {cmd:packagelist()},
then that package name is assumed to belong to a Stata package
that should contain all items in the {it:item_list}.

{phang}	
{cmd:noisily} specifies that {cmd:whichlist}
will output all the log output from the {helpb which} command
for each item in the input item list,
describing the location and possibly description of the item (if the item is present in a file),
or stating that the item is absent or present as a built-in command (otherwise).


{title:Remarks}

{pstd}
{cmd:whichlist}, without a {cmd:packagelist()} option,
outputs a list of items present on the user's system
and a list of items absent on the user's system.
{cmd:whichlist}, with a {cmd:packagelist()} option,
also outputs a list of complete package names,
for which all input items with that package name are present on the user's system,
and a list of incomplete package names,
for which some input items with that package name are absent on the user's system.
The output package names tell the user which packages are completely installed on the user's system,
in the sense that all input items that the user thinks the package should contain
are present on the user's system.

{pstd}
It is the user's responsibility to specify the correct package for each input item.
It is not recommended, but not unknown, for users to download an incomplete subset of the files in a package.

{pstd}
Advanced users and develperso are hereby encouraged
to use and modify the internal code for {cmd:whichlist}
in their own packages,
to check the presence of files and commands on which their packages are dependent.


{title:Examples}

{pstd}
List the files belonging to the {help ssc:SSC} package {helpb parmest} if present:

{p 8 12 2}{cmd:. whichlist parmest parmby parmcip metaparm}{p_end}

{pstd}
List the files belonging to {helpb parmest} if present and check the presence of all of them:

{p 8 12 2}{cmd:. whichlist parmest parmby parmcip metaparm, package(parmest)}{p_end}

{pstd}
List the files belonging to the {help ssc:SSC} packages {helpb parmest} and {helpb somersd} if present,
checking the presence of all files in each package:

{p 8 12 2}{cmd:. whichlist parmest parmby parmcip metaparm somersd cendif censlope, package(parmest parmest parmest parmest somersd)}{p_end}

{pstd}
List the files belonging to the packages {helpb parmest}, {helpb somersd}, and {helpb nutztoyou} if present,
checking the presence of all files in each package;
and outputting information on each input item,
and then list rhe saved results:

{p 8 12 2}{cmd:. whichlist parmest parmby parmcip metaparm somersd nutztoyou, package(parmest parmest parmest parmest somersd nutztoyou) noisily}{p_end}
{p 8 12 2}{cmd:. return list}{p_end}

{pstd}
The packages {helpb parmest} and {helpb somersd} are downloadable from {help ssc:SSC}.
The package {helpb nutztoyou} could not be found using {helpb findit},
at the time of writing of this help file.


{title:Saved results}

{pstd}
{cmd:whichlist} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(present)}}List of input items present on the user's system{p_end}
{synopt:{cmd:r(absent)}}List of input items absent on the user's system{p_end}
{synopt:{cmd:r(complete)}}List of input package names complete on the user's system{p_end}
{synopt:{cmd:r(incomplete)}}List of input  package names incomplete on the user's system{p_end}
{p2colreset}{...}


{title:Author}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[R] which},  {hi:[R] net},  {hi:[R] ssc}
{p_end}
{p 4 13 2}
On-line: help for {helpb which}, {helpb net}, {helpb ssc}
{p_end}
