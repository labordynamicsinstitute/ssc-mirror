{smcl}
{* 23jun2015}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "sql" "sql"}{...}
{vieweralsosee "recent" "recent"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:sql path} {hline 2} Set the default remote server, database, schema

{title:Syntax}

{pmore}{cmdab:sql p:ath}

{pmore}{cmdab:sql p:ath <}

{pmore}{cmdab:sql p:ath} [{it:dsn}{cmd::}] [{it:db}] [{cmd:.}{it:schema}]

{pmore}{cmdab:sql p:ath} [{it:server}{cmd::}{it:db}] [{cmd:.}{it:schema}] [{cmd:,} {opt d:river(name)}]


{title:Description}

{pstd}{cmdab:sql p:ath} displays or sets the remote path, for odbc access to sql server. The {cmdab:sql p:ath} is used like the (local) current directory, to supply default location information:
When a table name is specified alone, the {cmdab:sql p:ath} database and schema are assumed. When a {it:schema.table} is supplied, the {cmdab:sql p:ath} database is assumed.

{pstd}{hline 20}

{pstd}With no parameters, {cmdab:sql p:ath} displays the current settings, which are remembered across Stata sessions.

{pstd}{cmdab:sql p:ath <} switches back to the prior {cmdab:sql p:ath}.

{pstd}The parameter before the {cmd::} can be either a {it:dsn} (data source name) or a {it:server} address. If a {it:server} is specified, a {opt driver()} can be specified as well;
the default {opt driver()} is listed by {stata "elfs sql, help":elfs sql}.

{pstd}A schema or database can be specified alone (or both together) without changing the 'higher level' settings.

{pstd}A {it:dsn} can be specified with no lower level info {hline 1} the default database specified when the {it:dsn} was created will be used. However, {it:server} cannot be specified without also specifying a database.

{pstd}If a database is specified with no schema, a default schema (listed by {stata "elfs sql, help":elfs sql}) will be used.


{title:Examples}

   {cmd:. sql path cdw:}
   
   {cmd:. sql path adatabase.}
   
   {cmd:. sql path .aschema}

