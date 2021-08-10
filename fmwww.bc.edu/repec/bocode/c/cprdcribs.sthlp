{smcl}
{hline}
help for {cmd:cprdcribs}{right:(Roger Newson)}
{hline}


{title:Template do-files for inputting CPRD datasets into Stata}

{pstd}
The {cmd:cprdcribs} package is a set of template (or crib) do-files
for inputting text datasets
produced by the {browse "http://www.cprd.com":Clinical Practice Research Datalink (CPRD)},
and outputting a core set of Stata datasets for a CPRD database,
together with a {help do:do-file}
to create the full set of {help label:Stata value labels} for the database.
The core datasets are the {help cprdutil:non-XYZ-lookup datsets} for a CPRD database,
together with a dataset with 1 observation per practice,
a dataset with 1 observation per patient,
and a dataset with 1 observation per patient per calendar year of observation by CPRD.
The user may modify the template do-files for the user's own requirements,
and/or produce additional do-files to input other kinds of CPRD text datasets into Stata.
The template do-files may be modified by the user.
They include a do-file to produce the lookups,
a do-file to produce the practice dataset,
a do-file to produce the patient dataset,
a do-file to produce the patient-years dataset,
and a master do-file that calls the other do-files in a sensible order,
using the {help ssc:SSC} package {helpb dolog}.
The do-files of the {cmd:cprdcribs} package use the {help ssc:SSC} package {helpb cprdutil}.
It is probably a good idea to install all of Roger Newson's Stata packages before using these do-files.
This installation can be done using one of the {helpb instasisay} packages,
downloadable from Roger Newson's website.


{title:Template do-files distributed with {cmd:cprdcribs}}

{phang}
{cmd:lookups.do} inputs CPRD lookup tables from folders containing text files specifying these lookups.
There are two kinds of lookups,
namely {it:XYZ} lookups (each of which is converted into a {help label:Stata value label} of the same name),
and non-{it:XYZ} lookups (each of which is converted into a Stata dataset of the same name).
The value labels corresponding to the {it:XYZ} lookups are specified in an output {help do:Stata do-file}
named {cmd:xyzlookuplabs.do},
which can be run from other do-files to create the whole set of value labels.
The datasets corrsponding to the non-{it:XYZ} lookups
can be merged into other Stata datasets, using the {helpb merge} command of official Stata,
or the {help ssc:SSC} package {helpb addinby}.
The input text files for the {it:XYZ} lookups and non-{it:XYZ} lookups
must exist in folders specified by the user,
and the output Stata datasets specifying the non-{it:XYZ} lookups
are created in another folder specified by the user.
Usually, the user needs to modify {cmd:lookups.do},
so that the correct folders are specified.

{phang}
{cmd:practice.do} inputs a text dataset with 1 row per primary-care practice,
and outputs a Stata dataset with 1 observation per primary-care practice.
Both of these files must be specified by the user,
who must usually modify {cmd:practice.do}.

{phang}
{cmd:patient.do} inputs a text dataset with 1 row per patient,
and a Stata dataset with 1 observation per practice,
and outputs a Stata dataset with 1 observation per patient.
All of these files must be specified by the user,
who must usually modify {cmd:patient.do}.

{phang}
{cmd:patientyear.do} inputs a Stata dataset with 1 observation per patient,
which might be produced using {cmd:patient.do}.
It outputs a dataset with 1 observation per patient per calendar year
in which the patient was observed by CPRD,
and data on the age (in years) attained by that patient in that calendar year,
and on the exposure time (in days)
in which that patient was observed by CPRD in that calendar year.
This dataset is created using the {help ssc:SSC} package {helpb expgen}.
It might be enlarged by merging in datasets
with 1 observation per patient per calendar year
and data on event counts.
The user can then fit Poisson models, with event count as the outcome,
age as a possible covariate or factor,
and Huber variances clustered by patient or by practice.
Users may modify {cmd:patientyear.do}
to produce a dataset with 1 observation per United Kingdom fiscal year
(from 01 April to 31 March),
and/or to include patient age at the start of the year of observation
as a possible model covariate or factor.

{phang}
{cmd:create.do} is the master do-file.
It uses the {help ssc:SSC} package {helpb dolog}
to call the servant do-files
{cmd:lookups.do}, {cmd:practice.do}, {cmd:patient.do} and {cmd:patientyear.do},
in that order,
creating output Stata log files and output Stata datasets.
The order is important,
because {cmd:patientyear.do} uses output created by {cmd:patient.do},
which uses output created by {cmd:practice.do},
which uses output created by {cmd:lookups.do}.
The user may modify {cmd:create.do}
to use {helpb dolog} again,
calling other do-files to produce other CPRD datasets,
with observations corresponding to other CPRD things,
such as therapy prescriptions or clinical events.


{title:Remarks}

{pstd}
The {browse "http://www.cprd.com":Clinical Practice Research Datalink (CPRD)} is a data warehouse of information
from primary-care practices in the British National Health Service.
Tab-delimited text data files of various types can be retrieved,
containing data on things known to these practices,
such as practices, patients, staff members, clinical events, additional details on clinical events,
consultations, immunisations, referrals, tests, and prescribed therapies.

{pstd}
The {cmd:cprdcribs} package is intended to help the user to create sensible CPRD Stata databases,
using sensible do-files executed in a sensible order.
Usually, a do-file is called using the {help ssc:SSC} package {helpb dolog},
and produces a Stata log file of the same name in the same folder,
and a Stata dataset of the same name that may be in a sub-folder.
It is usually a good idea to have a master do-file like {cmd:create.do},
because do-files executed later may use output from do-files executed earlier,
and because a large and complicated CPRD database may take a long time to be created,
especially if it includes a large number of datasets,
with observations corresponding to things other than patients or practices.
It is not uncommon for a sequence of do-files creating a CPRD database
to be run overnight.
When this happens,
it is useful to be able to call the master do-file at the end of the working day,
so the master do-file can call the servant do-files overnight,
in the correct order at the correct times.

{pstd}
The master do-file is usually run using a {helpb do} command,
instead of the {helpb dolog} package.


{title:Examples}

{pstd}
The following example create a core CPRD Stata database,
including lookup datasets, a practice dataset, a patient dataset,
and a patient-year dataset.

{p 8 12 2}{cmd:. dolog lookups}{p_end}
{p 8 12 2}{cmd:. dolog practice}{p_end}
{p 8 12 2}{cmd:. dolog patient}{p_end}
{p 8 12 2}{cmd:. dolog patientyear}{p_end}

{pstd}
The following example does the same thing by calling {cmd:create.do} to call the other do-files.
It may do other things afterwards,
such as creating other datasets and maybe analysing the data,
if the user has modified {cmd:create.do} to run other do-files.

{p 8 12 2}{cmd:. do create}{p_end}

{title:Saved results}

{pstd}
The do-files {cmd:lookups.do}, {cmd:practice.do} and {cmd:patient.do}
all contain {helpb macro:global} commands,
which set global macros to specify the folders used for input
of a retrieval of CPRD text files.
Such retrievals usually are provided as a root folder,
containing subfilders {cmd:Data} and {cmd:Lookups}.
The {cmd:Data} folder usually contains the data files.
The {cmd:Lookups} folder usually contains the non-{it:XYZ} lookup files,
and also a sub-folder {cmd:TXTFILES},
containing the {it:XYZ} lookup files.
The do--files {cmd:lookups.do}, {cmd:practice.do} and {cmd:patient.do},
in their unmodified form,
attempt to create all Stata {cmd:.dta} files in the subfolder {cmd:./dta},
and set the values of the following global macros:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:CPRDDATA}}Root folder for the CPRD retrieval{p_end}
{p2colreset}{...}

{pstd}
It is usually good practice to store folder locations in macros.
This is because users frequently re-arrange databases,
implying that folder locations have to be changed.
This is easier to do if the folder location is only specified once per do-file,
near the top of the do-file.

{pstd}
{cmd:lookups.do} also creates an output do-file {cmd:xyzlookuplabs.do},
in the current directory,
which can then be run to create Stata value labels specified by the {it:XYZ} lookups.


{title:Author}

{pstd}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:Also see}

{psee}
{space 2}Help:  {browse "http://www.cprd.com":Clinical Practice Research Datalink (CPRD)}{break}
{helpb keyby}, {helpb addinby}, {helpb lablist}, {helpb chardef}, {helpb intext}, {helpb expgen},
{helpb cprdutil}, {helpb dolog}, {helpb instasisay} if installed
{p_end}
