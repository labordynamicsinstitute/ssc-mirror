{smcl}
{hline}
help for {cmd:sysport}{right:(Roger Newson)}
{hline}


{title:Zip system directories for porting to another machine}

{p 8 21 2}
{cmd:sysport} , {cmd:saving(}{it:zipfilename}[{cmd:, replace}]{cmd:)} 
    [ {cmdab:d:irlist(}{it:sysdir_list}{cmd:)} ]

{pstd}
where {it:sysdir_list} is a list of one or more names with the patterns

{pstd}
{opt p:lus} | {opt pe:rsonal} | {opt s:ite} | {opt o:ldplace}


{title:Description}

{pstd}
{cmd:sysport} inputs a list of one or more {helpb sysdir} code words for system directories
and saves the corresponding directories to a zip file,
in which the system directories can be ported to another machine.
This is very useful if a user wants to port the user's add-on packages
to another machine, which may have no internet access or restricted internet access,
so the user may not be able to install add-on packages using {helpb net} or {helpb ssc}.


{title:Options for {cmd:sysport}}

{phang}	
{cmd:saving(}{it:zipfilename}[{cmd:, replace}]{cmd:)} is required.
It specifies the filename to be created or replaced.  If
{it:zipfilename} is specified without an extension, {cmd:.zip} will be assumed.

{phang}	
{cmd:dirlist(}{it:sysdir_list}) specifies a list of one or more code words,
recognised by {helpb sysdir} as identifying system directories used by Stata,
which {cmd:sysport} will zip to the file specified by the {cmd:saving()} option.
The code words may be in upper or lower case,
and must be {opt p:lus}, {opt pe:rsonal}, {opt s:ite},
or {opt o:ldplace}.
If {cmd:dirlist()} is not specified,
then it is set to {cmd:plus},
and the output zip file will contain the add-on packages
installed by the user.


{title:Examples}

{pstd}
Zip the user's PLUS folder:

{p 8 12 2}{cmd:. sysport, saving(myplus, replace)}{p_end}

{pstd}
Zip the user's PLUS, PERSONAL, and SITE folders:

{p 8 12 2}{cmd:. sysport, saving(myplus, replace) dir(plus personal site)}{p_end}


{title:Author}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[P] adopath},  {hi:[R] zipfile},  {hi:[R] net},  {hi:[R] ssc}
{p_end}
{p 4 13 2}
On-line: help for {helpb sysdir}, {helpb adopath}, {helpb zipfile}, {helpb net}, {helpb ssc}
{p_end}
