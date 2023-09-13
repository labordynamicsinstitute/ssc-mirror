{smcl}
{* 13jun2014}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "sql path" "sql path"}{...}
{vieweralsosee "sql do" "sql do"}{...}
{vieweralsosee "sql do script" "sql do script"}{...}
{vieweralsosee "codex" "codex"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "recent" "recent"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:sql} {hline 2} Usq SQL over ODBC


{title:Overall Description}

{pstd}This set of commands if for working with remote odbc/sql databases.

{title:Contents}

{p2colset 5 25 28 2}{...}
{p2col:{ul:{it:Command}}}{ul:{it:Description}}

{p2col:{help sql_path:sql {ul:p}ath}}Set the odbc dsn/server, db, schema{p_end}

{p2col:{help sql##get:sql get}}Load (part of) one table into Stata{p_end}
{p2col:{help sql##put:sql put}}Place the Stata data as a remote table{p_end}
{p2col:{help sql##fin:sql {ul:fin}ish}}Place the Stata metadata on the server{p_end}
{p2col:{help sql##move:sql move}}Move or rename a table{p_end}
{p2col:{help sql##merge:sql merge}}Merge a table into another table{p_end}

{p2col:{help sql_write:sql {ul:wr}ite}}Write a bit of standard sql code (ie, SP){p_end}
{p2col:{help sql##sqli:sqli}}Execute any sql code, from the command line{p_end}
{p2col:{help sql do}}Execute {help sql do script} (specially formatted sql), from a file{p_end}

{p2col:{help sql##cols:sql cols}}Get a selection of column names{p_end}
{p2col:{help sql##tables:sql tables}}List tables from a schema{p_end}
{p2col:{help sql##db:sql {ul:dbd}escription}}Generate a description of a remote database{p_end}

{p2col:{help sql##clear:sql clear}}Drop a number of remote tables, and possibly their schema{p_end}


{marker get}{title:sql get}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql get} [{it:sqlpath}{cmd:.}]{it:table} [{cmd:,} {opt k:eep(varlist)} {opt q:uick(integer)} {opt d:istinct} {opt where(clause)}]{p_end}
{phang2}{cmd:sql get} [{cmd:<}]

{pstd}{ul:Description}

{pmore}{cmd:sql get} loads part of a remote table into Stata. Both {opt d:istinct} and {opt where(clause)} function exactly like they do in sql, but the other options provide some advantages:

{phang2}{opt k:eep(varlist)} accepts a standard {it:{help varelist}}; that is, you can use abbreviations and wildcards instead of exactly spelling out column names, and you can use
ranges if you know the remote table column order.

{phang2}{opt q:uick(integer)} returns just {it:integer} records from the table (quickly). For CDW 'fact' tables, it should return the first {it:integer} records from the most recent, complete, quarter (by the main date index).
For everything else, it's sql {cmd:TOP}.

{pmore}{cmd:sql get} with no parameters will reload the data if the {help recent##datasource:current data source} was set with {cmd:sql get} or {cmd:sqli}.
{cmd:sql get <} will re-run the most recent prior query created with {cmd:sql get} or {cmd:sqli}.

{pmore}If metadata has been placed with {help sql##fin:sql finish} {it:table}, it will be retrieved and set up appropriately, so things are labeled, formatted, etc.


{marker put}{title:sql put}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql put} [{it:sqlpath}{cmd:.}]{it:table} {ifin} [{cmd:,} {cmdab:k:eep(}{it:{help varelist}}{cmd:)}]

{pstd}{ul:Description}

{pmore}{cmd:sql put} places the (selected) Stata data on the remote server as {it:table}. Any metadata from {cmd:sql do} will also be uploaded.


{marker fin}{title:sql finish}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql {ul:fin}ish} {it:table}

{pstd}{ul:Description}

{pmore}{cmd:sql {ul:fin}ish} places the everything in the Stata datafile {it:except} the data onto the remote server, as a metadata blob. {help sql##get:sql get} {it:table} will retrieve it along with the data,
and create a complete Stata dataset, with labels, formats, etc. 


{marker move}{title:sql move}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql move} {it:original}, {opt to(moved)}

{pstd}{ul:Description}

{pmore}{cmd:sql move} moves or renames a table to another schema and/or table in the same database. Extended ({cmd:sql do}) meta-data will be updated as well. A new schema will be created, if necessary.


{marker merge}{title:sql merge}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql merge} {it:addition}, {cmd:into(}{it:master}{cmd::}{it:query-name}{cmd:)} [{opt k:eep}]

{pstd}{ul:Description}

{pmore}{cmd:sql merge} merges table {it:addition} into table {it:master}. {it:master} must have a clustered index, and {it:addition} must include those index columns.

{pmore}You must supply a {it:query-name} which will identify the meta-data that came from {it:addition} (eg, the original sql code and query description).

{pmore}{opt k:eep} keeps {it:addition} in the database as well. If {opt k:eep} is not specified, {it:addition} is deleted after being merged into {it:master}.


{marker sqli}{title:sqli}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sqli} {it:sql code}{p_end}
{phang2}{cmd:sqli} [{cmd:<}]{p_end}

{pstd}{ul:Description}

{pmore}{cmd:sqli} submits {it:sql code} to the remote server for execution.

{pmore}{cmd:sqli} cannot definitely identify table names in {it:sql code}, but words following " {cmd:from} " or " {cmd:join} " or " {cmd:table} " will be considered table names, and interpreted in light of the {help sql path}.

{pmore}If the first word in the final statement in {it:sql code} is {cmd:select}, {cmd:sqli} will attempt to download the results as Stata data. Otherwise, the code will simply be executed.

{pmore}{cmd:sqli} with no parameters will reload the data if the {help recent##datasource:current data source} was set with {cmd:sql get} or {cmd:sqli}.
{cmd:sqli <} will re-run the most recent prior query created with {cmd:sql get} or {cmd:sqli}.


{marker cols}{title:sql cols}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql cols} {it:table} [{it:columns}] [{cmd:,} {opt a:lias(prefix)}  {opt p:ath(sqlpath)}]

{pstd}{ul:Description}

{pmore}{cmd:sql cols} lists all columns matching {it:columns} from the specified table. The table is found in the current {help sql path}, or the sqlpath specified. {it:columns} matches like a {help varelist}, treating columns as variables.

{pmore}The results are listed twice: First as a normal 'paragraph', and then as a single line of comma-separated values.
If {opt a:lias(prefix)} is specified, the second display will prefix each name with the specified table-alias.

{pmore}The single-line display may be wider than the window, but it will be copy-able anyway, suitable for pasting elsewhere.


{marker tables}{title:sql tables}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql tables} [{it:tables}] [{cmd:,} {opt p:ath(sqlpath)}]

{pstd}{ul:Description}

{pmore}{cmd:sql tables} lists all tables matching {it:tables} from the current {help sql path}, or the sqlpath specified. {it:tables} matches like a {help varelist}, treating tables as variables.

{marker db}{title:sql dbdescription}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql }{cmdab:dbd:escription} [{it:schemas}] [{cmd:,} {opt p:ath(sqlpath)} {opt sav:ing(filepath)} {opt port:able}]

{pstd}{ul:Description}

{pmore}{cmd:sql dbd} creates an html page with metadata for (part of) one database {hline -} using the current {help sql path} or the one specified in {opt path(sqlpath)}. It includes the extended meta-data created by {help sql do}.
{it:schemas} matches like a {it:{help varelist}}, treating schemas as variables.

{phang2}{opt saving(filepath)} specifies the filepath for the html output. The default is the {help prjs:project settings} directory, and the {it:sqlpath} database-name.

{phang2}{opt port:able} writes the file so that it does not depend on anything in the Stata directories and will continue to function if, for example, it is emailed to someone else.

{pmore}All of the details (except {opt port:able}) are remembered, specific to the {help cdl##project:project}, and will be re-used as defaults in future invocations.


{marker clear}{title:sql clear}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:sql clear} {it:tables} [{cmd:,} {opt p:ath(sqlpath)} {opt s:chema}]

{pstd}{ul:Description}

{pmore}{cmd:sql clear} drops multiple remote tables, and possibly an empty schema.

{pmore}{cmd:sql clear} will first list all the tables in the relevant schema, highlighting the ones that would be deleted, and asks for confirmation before deleting anything.

{pmore}The schema is the one from the current {help sql path}, or the sqlpath specified. {it:tables} matches like a {help varelist}, treating tables as variables.

{pmore}Specifying the {opt s:chema} option will drop the schema after dropping the tables, if the schema is empty.

