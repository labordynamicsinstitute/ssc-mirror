{smcl}
{hline}
help for {cmd:cprdhesutil}{right:(Roger Newson)}
{hline}


{title:Inputting {browse "http://www.cprd.com":Clinical Practice Research Datalink (CPRD)} HES-linkage datasets into Stata}

{p 8 21 12}{cmd:cprdhes_patient} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}

{p 8 21 12}{cmd:cprdhes_hospital} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}

{p 8 21 12}{cmd:cprdhes_episodes} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}

{p 8 21 12}{cmd:cprdhes_diagnosis_epi} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}

{p 8 21 12}{cmd:cprdhes_diagnosis_hosp} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}

{p 8 21 12}{cmd:cprdhes_primary_diag_hosp} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}

{p 8 21 12}{cmd:cprdhes_procedures_epi} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}

{p 8 21 12}{cmd:cprdhes_hrg} {cmd:using} {it:filename} [ , {cmd:clear} {cmdab::no}{cmdab:key} {cmdab:delim:iters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)} ]{p_end}


{title:Description}

{pstd}
The {cmd:cprdhesutil} package is designed for use with the {helpb cprdutil} package,
which creates Stata datasets from text data files
produced by the {browse "http://www.cprd.com":Clinical Practice Research Datalink (CPRD)}.
{cmd:cprdhesutil} is a suite of utility programs for inputting linkage text data files produced by CPRD
to contain data on the same patients form the Hospital Episodes System (HES),
and creating equivalent Stata datasets in the memory.
Each program in the suite imports into Stata a dataset type produced by a CPRD HES linkage retrieval,
with 1 observation for each of a set of things of a kind on which HES collects data,
such as patients, hospitalization events, or episodes within hospitalizations.
{cmd:cprdhesutil} uses the {help ssc:SSC} packages {helpb keyby} and {helpb lablist},
which need to be installed for {cmd:cprdhesutil} to work.


{title:Options}

{phang}
{cmd:clear} specifies that any existing dataset in memory will be replaced.

{phang}
{cmd:nokey} specifies that the dataset produced will not be {help sort:sorted} by a primary key of variables.
If {cmd:nokey} is not specified for a command that has a {cmd:nokey} option,
then the dataset will be sorted by a primary key of variables,
whose values will normally identify the observations uniquely,
with each value combination present in only one observation.

{phang}
{cmd:delimiters("}{it:chars}{cmd:"}[{cmd:, }{cmd:collapse}|{cmd:asstring}]{cmd:)}
specifies the delimiters used in the input text file.
This option functions as the option of the same name for {helpb import delimited}.


{title:Remarks}

{pstd}
The {browse "http://www.cprd.com":Clinical Practice Research Datalink (CPRD)} is a database of information
from primary-care practices in the British Health Service.
Tab-delimited text data files of various types can be produed by CPRD,
containing data on things known to these practices,
such as practices, patients, staff members, clinical events, additional details on clinical events,
consultations, immunisations, referrals, tests, and prescribed therapies.
These text datafiles can then be converted to Stata datasets using the {helpb ssc:SSC} package {helpb cprdutil}.

{pstd}
Researchers sometimes aim to answer questions about the incidence of events experienced by CPRD patients,
but recorded by data sources other than CPRD, such as the Hospital Episodes System (HES).
The {cmd:cprdhesutil} package allows users to do this.
It should be used in combination with the {helpb cprdlinkutil} package,
also downloadable from {help ssc:SSC}.

{title:Examples}

{p 8 12 2}{cmd:. cprdhes_patient using "./txtdata/HES_patient.txt", clear}{p_end}

{p 8 12 2}{cmd:. cprdhes_patient using "./txtdata/HES_patient.txt", clear nokey}{p_end}


{title:Author}

{pstd}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:Also see}

{psee}
{space 2}Help:  {browse "http://www.cprd.com":Clinical Practice Research Datalink (CPRD)}{break}
{helpb cprdutil}, {helpb cprdlinkutil} if installed
{p_end}
