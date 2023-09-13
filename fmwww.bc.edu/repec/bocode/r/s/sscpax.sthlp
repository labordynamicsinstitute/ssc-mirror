{smcl}
{hline}
help for {cmd:sscpax}{right:(Roger Newson)}
{hline}


{title:Describe, install, or uninstall a list of {help ssc:SSC} packages}

{p 8 21 2}
{cmd:sscpax} {it:namelist} [ , {cmdab:a:ction}{cmd:(}{it:action}{cmd:)}
{opt so:rt} {opt replace} {opt all} ]

{pstd}
where {it:action} is

{pstd}
{opt d:escribe} | {opt i:nstall} | {opt u:ninstall}


{title:Description}

{pstd}
{cmd:sscpax} inputs a list of {help ssc:SSC} package names and either describes,
installs, or uninstalls the packages in the list that are present on {help ssc:SSC}.
{cmd:sscpax} is useful if the user wants to install a package,
and also to install other {help ssc:SSC} packages,
on which the first package is dependent.


{title:Options for {cmd:sscpax}}

{phang}
{cmdab:a:ction}{cmd:(}{it:action}{cmd:)} specifies that the packages in the {it:namelist}
will be described, installed, or uninstalled,
depending on whether the {it:action}
is {opt describe}, {opt install}. or {opt uninstall}. respectively.
If {cmd:action()} is not specified,
then {opt describe} is assumed.

{phang}
{opt sort} specifies that the SSC packages in the {it:namelist}
will be described, installed, or uninstalled
in alphanumeric order of package name.
If {opt sort} is not specified,
then the packages are described, installed, or uninstalled
in order of their first appearances in the {it:namelist}.

{phang}
{opt all} specifies that any ancillary files associated with the
packages named in the {it:namelist} will be downloaded to your current directory, in addition
to the program and help files being installed.
Ancillary files are files
that do not end in {opt .ado} or {opt .sthlp},
and typically contain
datasets or examples of the use of the new command.
If {cmd:action(install)} is not specified, then {cmd:all} is ignored.

{pmore}
You can find out which files are associated with the package by typing
{cmd:ssc describe} {it:pkgname} before or after installing,
or use {cmd:sscpax} with the option {cmd:action(describe)}.
If you install without using the {opt all} option and then want the ancillary files,
you can {opt ssc install} again,
or use {cmd:sscpax} with the option {cmd:action(install)}.

{phang}
{opt replace} specifies that that any files being downloaded that already exist
on your computer be replaced by the downloaded files.
If {opt replace} is not specified and any of the files for a package already exist,
then none of the files from the package is downloaded or installed.
If {cmd:action(install)} is not specified, then {cmd:replace} is ignored.

{pmore}
It is better not to specify the {opt replace} option and wait to see if
there is a problem.  If there is a problem, it is usually better to
uninstall the old package by using {opt ssc uninstall} or
{opt ado uninstall} (which are,  in fact, the same command),
or to use {cmd:sscpax} with the option {cmd:action(uninstall)}.


{title:Remarks}

{pstd}
{cmd:sscpax} should be used with caution by users of {help version:Stata versions}
other than the latest version.
This is because {help ssc:SSC} stores only the latest version of a package,
which may be written in a {help version:Stata version}
that the user does not have.
It is a good idea to use {cmd:sscpax}
with the default {cmd:action()} option {cmd:action(describe)},
to find out the {help version:Stata version}
in which each package is written,
before installing the packages.

{pstd}
If the packages are written by Roger Newson,
then an alternative possibility exists.
If the user types, in Stata,

{pstd}
{help instasisay:findit instasisay}

{pstd}
then the user will find a package of do-files {cmd:instasisay},
to describe, install, and uninstall all Roger Newson's {help ssc:SSC} packages
in their latest versions from {help ssc:SSC},
and also a series of packages of do-files, with names of the form {cmd:instasisay_}{it:k},
to describe, install, and uninstall from Roger Newson's website
the latest version of each of Roger Newson's packages
compatible with {help version:Version {it:k}} of Stata.
The do-files are install wizards,
generated automatically by the maintenance programs for Roger Newson's website
to enable users of obsolete versions of Stata
to continue to have access to obsolete versions of Roger Newson's packages.


{title:Examples}

{pstd}
The following examples involve a list of packages dependent on the {help ssc:SSC} packages
{helpb somersd} and {helpb expgen}.
The {helpb scsomersd} package depends on {helpb somersd} and {helpb expgen},
and the {helpb rcentile} package depends on {helpb scsomersd}.
The user can find out more about these packages in their online help
after installing them.

{pstd}
Describe packages dependent on {helpb somersd}:

{p 8 12 2}{cmd:. sscpax somersd expgen scsomersd rcentile}{p_end}

{pstd}
Describe packages dependent on {helpb somersd} in alphanumeric order:

{p 8 12 2}{cmd:. sscpax somersd expgen scsomersd rcentile, sort}{p_end}

{pstd}
Install packages dependent on {helpb somersd},
and check installation using the {helpb which} command::

{p 8 12 2}{cmd:. sscpax somersd expgen scsomersd rcentile, action(install) replace}{p_end}
{p 8 12 2}{cmd:. which somersd}{p_end}
{p 8 12 2}{cmd:. which expgen}{p_end}
{p 8 12 2}{cmd:. which scsomersd}{p_end}
{p 8 12 2}{cmd:. which rcentile}{p_end}


{pstd}
Uninstall packages dependent on {helpb somersd}:

{p 8 12 2}{cmd:. sscpax somersd expgen scsomersd rcentile, action(uninstall)}{p_end}

{pstd}
Re-install packages dependent on {helpb somersd} and download their {cmd:.pdf} documents to the current folder,
and check installation using the {helpb which} command
and downloads using the {helpb dir} command::

{p 8 12 2}{cmd:. sscpax somersd expgen scsomersd rcentile, action(install) all}{p_end}
{p 8 12 2}{cmd:. which somersd}{p_end}
{p 8 12 2}{cmd:. which expgen}{p_end}
{p 8 12 2}{cmd:. which scsomersd}{p_end}
{p 8 12 2}{cmd:. which rcentile}{p_end}
{p 8 12 2}{cmd:. dir *.pdf}{p_end}


{title:Saved results}

{pstd}
{cmd:sscpax} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(absent)}}input package names absent on {help ssc:SSC}{p_end}
{synopt:{cmd:r(present)}}input package names present on {help ssc:SSC}{p_end}
{p2colreset}{...}


{title:Author}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[R] ssc},  {hi:[R] which}, {hi:[D] dir} 
{p_end}
{p 4 13 2}
On-line: help for {helpb ssc}, {helpb which}, {helpb dir}
{break}
help for {helpb somersd}, {helpb expgen}, {helpb scsomersd}, {helpb rcentile} if installed
{p_end}
