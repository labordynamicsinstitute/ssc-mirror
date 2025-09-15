{smcl}
{* *! version 1.0.0 15feb2025}
{help undid_init:undid_init}
{hline}

{title:undid}

{pstd}
undid - Estimate difference-in-differences with unpoolable data. {p_end}

{title:Command Description}

{phang}
{cmd:undid_init} Generates an initial CSV file (`init.csv`) specifying the silo names, start times, end times, and treatment times.

Required parameters:

- {bf:silo_names} : A string specifying the different silo names.

- {bf:start_times} : A string which indicates the starting time for the analysis at each silo.

- {bf:end_times} : A string which indicates the end time for the analysis at each silo.

- {bf:treatment_times} : A string which indicates the treatment time at each silo. Control silos should be labelled with the treatment time "control".

Optional parameters:

- {bf:covariates} : A string specifying covariates to be considered at each silo.

- {bf:filename} : A string specifying the outputted filename. Must end in ".csv". Defaults to "init.csv".

- {bf:filepath} : A string specifying the path to the folder in which to save the output file, e.g. "`c(pwd)'". Defaults to "`c(tempdir)'".


{title:Syntax}

{pstd}
{cmd:undid_init} silo_names(string) start_times(string) end_times(string) treatment_times(string)[{it:covariates(string)} {it:filename(string)} {it:filepath(string)}]{p_end}

{title:Examples}

{phang2}{cmd:undid_init, silo_names("71 73 58 46") start_times("1989") end_times("2000") treatment_times("1991 control 1993 control") covariates("asian black male")}

{phang2}init.csv saved to: C:\Users\ERICBR~1\AppData\Local\Temp\init.csv

{title:Author}

{pstd}
Eric Jamieson{p_end}

{pstd}
For more information about undid, visit the {browse "https://github.com/ebjamieson97/undid"} GitHub repository.{p_end}

{title:Citation}

{pstd}
Please cite: Sunny Karim, Matthew D. Webb, Nichole Austin, Erin Strumpf. 2024. Difference-in-Differenecs with Unpoolable Data. {browse "https://arxiv.org/abs/2403.15910"} {p_end}