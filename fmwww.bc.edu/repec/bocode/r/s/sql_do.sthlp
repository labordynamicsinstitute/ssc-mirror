{smcl}
{* 2jul2014}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "sql" "sql"}{...}
{vieweralsosee "sql do script" "sql do script"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:sql do} {hline 2} Execute {help sql_do_script:sql-do script}

{title:Syntax}

{pmore}{cmd:sql do} {it:filename} [{cmd:,} {it:options}]

{synoptset 22}
{synopthdr:options}
{synoptline}
{synopt :{opt p:ath(sqlpath)}}a {help sql path} to use for this script only{p_end}
{synopt :{opt d:estination()}}the destination for the final table{p_end}
{synopt :{opt merge()}}merge the final result into an existing table{p_end}

{synopt :{opt o:nly()}}specify part of the script to execute{p_end}
{synopt :{opt not()}}specify part of the script to {bf:exclude}{p_end}

{synopt :{opt s:wap()}}specify values for {help sql_do_script##swap:swappable tags} {p_end}
{synopt :{opt test}}include test script{p_end}
{synopt :{opt up:load(write-path)}}upload tables to a different server{p_end}

{synopt :{opt pre:view}}do not execute; preview only{p_end}


{title:Description}

{pstd}{cmd:sql do} executes specially formatted {help sql_do_script:sql-do script}, and either downloads the result or places it remotely.
{cmd:sql do} also saves extended meta-data about the tables it creates.

{pstd}{it:file-path} is optional when the command is executed from the editor, using {cmd:fromEditor}. In that case, the script is read from the editor-file in memory.

{title:Options}

{phang}{opt p:ath(sqlpath)} specifies a {help sql path} to use instead of the current one.

{phang}{opt d:estination(name)} specifies where to place the table that results from the script. {it:name} will use the {help sql path} to fill in unspecified database & schema.
When {opt d:estination()} is not specified, the final {cmd:^t=}{it:name} in the script will be taken as {it:name}. When {it:name} is {cmd:*}, the results are downloaded into Stata.

{pmore}{opt d:estination()} cannot be specified with {opt merge()}.

{phang}{cmd:merge(}{it:table}{cmd::}{it:query-name}{cmd:)} merges the final results into {it:table}. {it:table} must have a clustered index, and the result of the script must include those index columns.

{pmore}You must supply a {it:query-name} which will identify the meta-data that came from this command.

{pmore}{opt merge()} cannot be specified with {opt destination()}.

{phang}{opt o:nly(details)} restricts execution to a subset of the script file. The syntax is:

{col 13}{cmdab:o:nly(}[{it:wrapper-id}{cmd::}] [{it:name list}]{cmd:)}

{pmore}You can specify either {it:wrapper-id} or {it:name list}, or both.

{pmore}{it:name list} works like a {it:{help varelist}}. When specified, only the {it:parts} with {cmd:^t=}{it:name} matching {it:name list} will be executed.

{pmore}{cmd:sql do} always executes script with one single {it:wrapper-id}. When none is specified in {opt o:nly()}, script with {bf:NO} {it:wrapper-id} is executed.

{phang}{opt not(name list)} excludes the selected tables from execution. {it:name list} works as it does in {opt only()}.

{phang}{cmd:swap(}{it:tag}{cmd:(}{it:value}{cmd:)} [...]{cmd:)} specifies {it:values} to use for the {it:tags} ({help sql_do_script##swap:swappable tags}) in the script. 

{phang}{opt test} will treat certain comments in the script as executable script; specifically:

{phang2}{cmd:/*test:}{it:executable test code}{cmd::test*/}

{phang}{opt up:load(write-path)} specifies a {help sql path} for uploading tables {hline 2} useful if you can't write to the server you're reading from.
{it:write-path} must be specified with an explicit {it:server} address, rather than a {it:dsn}.

{pmore}You'll need to ensure that {it:write-path} is readable from the server where the main query is running.

{phang}{opt pre:view} causes the {cmd:sql do} preview to display, without actually executing the script.
The preview shows all the tables and tags included in the script, and those selected for execution, and shows the final values assigned to each tag.

{title:Meta-data}

{pstd}{cmd:sql do} saves some extra meta-data about every table it creates or downloads:

{phang}o-{space 2}A query desciption{p_end}
{phang}o-{space 2}Execution time{p_end}
{phang}o-{space 2}The {hi:sql script} that was executed{p_end}
{phang}o-{space 2}The local filename where the {hi:sql-do} script originated{p_end}

{pstd}{bf:Note} that it is the actual, executed, {hi:sql} script that is saved with the metadata {hline 1} after all swaps and table-name resolutions.

{pstd}When results are merged into an existing table, the meta-data from each merge, and the merged columns, are also assigned a query name.{p_end}

{pstd}For results saved remotely, the meta-data is stored in the relevant database, and can be viewed with the {help sql##db:sql dbdescription} command.

{pstd}For results downloaded to stata, the meta-data is stored as {cmd:_dta} {help char:characteristics}.
If the data is later uploaded with one of the {help sql} commands, the meta-data will be written the same as if the table had been created with {cmd:sql do} directly.
The local {help char:characteristics} can be inspected in any of the usual ways.

