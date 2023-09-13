{smcl}
{* 2jul2014}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "sql" "sql"}{...}
{vieweralsosee "sql do" "sql do"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:sql-do script} {hline 2} Modified sql code for execution by {help sql do}

{title:Introduction}

{pstd}There are four things distinguishing {hi:sql-do script} from ordinary sql:

{phang}o-{space 2}It can {bf:only} include a series of table-creation statements {hline 1} no {cmd:declare}'s or similar (yet).{p_end}
{phang}o-{space 2}It can include data from local (non-DB, usually stata) files.{p_end}
{phang}o-{space 2}It can include 'stored script' from local files.{p_end}
{phang}o-{space 2}It can include 'swappable tags' that can have values supplied at runtime.{p_end}

{pstd}It also requires a 'wrapper', which delimits the {hi:sql_do} script from stata script in the same file.


{title:Example}

{p 5 21 2}{cmd:*---sql:}cheese{cmd:,} this script lists some world cheeses, and the animals that provide the milk.

{col 6}{cmd:^t=}british{cmd:,} cheeses in this table are made in Britain
{col 6}select name, odor, runnyness, {cmd:^m:}jfield
{col 6}from {cmd:^t:}worldcheese
{col 6}where nationality='britain'

{col 6}{cmd:^t=}animals
{col 6}select AA.*, BB.commonname
{col 6}from {cmd:^t:british} AA
{col 6}join milkgiving.animals BB
{col 6}on AA.{cmd:^m:}jfield=BB.animalid

{col 6}{cmd:*---/sql}

{col 6}sql do {it:thisfile.do}, destination(*)
{col 6}tab name order
{col 6}list name odor runnyness


{c 164}{hline 3} {ul:{bf:Wrapper}} {hline}

{p 5 5 3}The target file of a {help sql do} command can have many sections of {hi:sql-do script} mixed with other things, like so: 

{col 10}[{it:other things}]

{col 10}{cmd:*---sql:}[{it:wrapper-id}][ {cmd:,}{it:description}]
{col 14}{it:part 1}
{col 14}{space 3}.
{col 14}{space 3}.
{col 14}{it:part n}
{col 10}{cmd:*---/sql}

{col 10}[{it:other things}]

{p 5 5 3}Any number of {it:wrapper-ids} can be used, any number of times, in the same file. A single {help sql do} command will execute all, and only, the script with a matching {it:wrapper-id}.
When {help sql do} does not specify a {it:wrapper-id}, script with {bf:NO} {it:wrapper-id} is executed.

{p 5 5 3}{it:description} is only read from the first relevant wrapper in the file. It will be saved in the extended meta-data as the query description.


{c 164}{c 164}{hline 2} {ul:{bf:part}} {hline}

{p 5 5 3}Each {it:part} (above) is:

{col 10}{cmd:^t=}{it:table-name} [{cmd:,} {it:description}]
{col 10}{it:part definition}
{col 10}{it:blank line}

{p 5 5 3}where {it:blank line} is a blank line (no text).{p_end}


{c 164}{c 164}{c 164}{hline 1} {ul:{bf:part definition}} {hline}

{p 5 5 3}{it:part definition} can be one of:

{p 9 13 3}1){space 2}{it:sql statement}{p_end}
{p 9 13 3}2){space 2}{cmd:^use=} {it:filename} [{it:options}]{p_end}
{p 9 13 3}3){space 2}{cmd:^codex=} {it:filename} [{it:options}]{p_end}

{p 9 13 3}4){space 2}{cmd:^ssc=} {it:filename} [{it:options}]{p_end}


{c 164}{c 164}{c 164}{c 164} {ul:{bf:sql statement}} {hline}

{p 5 5 3}{it:sql statement} is generally any well-formed sql statement that creates a table (eg, {cmd:select}, {cmd:union}, {cmd:pivot}). It can include {help sql_do_script##swap:swappable tags}.            

{p 5 5 3}{it:sql statement} can be written across multiple lines, as long as no blank lines are included {hline 2} a blank line would be interpreted as the end of the {it:part}.


{marker use}{c 164}{c 164}{c 164}{c 164} {ul:{bf:^use=}} {hline}

{p 5 5 3}{cmd:^use=} {it:filename} {ifin} [{cmd:,} {opt k:eep(varelist)}]{p_end}


{p 5 5 3}{it:filename} is any local file that can be read as data by {help usel}, or {cmd:*} to use the data in memory.

{p 5 5 3}{opt keep()} and {ifin} function as in {help usel}.


{marker codex}{c 164}{c 164}{c 164}{c 164} {ul:{bf:^codex=}} {hline}

{p 5 5 3}{cmd:^codex=} {it:filename} [{cmd:,} {it:filter-option} {opt tag(name)}]{p_end}


{p 5 5 3}{it:filename} must refer to a {help codex} file.

{p 5 5 3}{it:filter-option} is one of those described in {help codex##review:codex review}.

{p 5 5 3}{opt tag(name)} specifies the {help sql_do_script##swap:swappable tag} to use for {bf:id} values.

{col 6}{hline 10}
{p 5 5 3}This {it:part definition} uploads data from a {help codex} file. It creates a table with the columns: {cmd:type}, {cmd:grp}, {cmd:id}, and either ({cmd:code}) or ({cmd:code1} and {cmd:code2}), depending on the nature of the codes.
It also specifies a swap for one {help sql_do_script##swap:swappable tag}; by default, the tag is {cmd:^g:cxids},
but you can specify a different {it:name} (with or without the {cmd:^g:}) in the {opt tag()} option.
The specified tag will be swapped out for the (comma separated) list of {bf:ids} retrieved from the {help codex}.

{p 5 9 3}{bf:[+]} The swap is useful for sql pivot statements: If a {help codex} defined 5 conditions, based on 50 icd9 codes, then after uploading the table of codes with {cmd:^codex=},
and selcting patients and conditions with a join on {cmd:code}, one could use a pivot statement with {cmd:^g:cxids} to return a table with one row per patient, and one column for each of the 5 conditions
(whether or not any of the conditions were actually found).


{c 164}{c 164}{c 164}{c 164} {ul:{bf:^ssc=}} {hline}

{col 6}{cmd:^ssc=}{it:filename} [{cmd:,} {opt d:ir(directory)} {cmd:swap(}{it:tag}{cmd:(}{it:value}{cmd:)} [...]{cmd:)} ]

{p 5 5 3}{it:filename} refers to a {hi:stored script} file; that is, a local file containing {hi:sql-do script}. It will use the default file-extension {cmd:.sql}.

{p 5 5 3}{opt d:ir(directory)} specifies a (super) directory for {it:filename}. This is a convenience option: The {it:filenames} can be kept more readable, and also {it:directory} can contain (or be) a stata macro
{hline 1} the only place in {hi:sql-do script} where a macro will function.

{p 5 5 3}{opt s:wap()} specfies any swaps to implement in the {it:sql statements} of {hi:stored script}: Each {it:tag} will be replaced with the corresponding {it:value}.
Note that {it:value} can specify another {help sql_do_script##swap:swappable tag}.

{col 6}{hline 10}
{p 5 5 3}When a {it:part definition} is an {cmd:^ssc=}, the original {it:part} (say, {hi:p1}) is replaced by {bf:all} the {it:parts} in the {hi:stored script} (say, {hi:pA}-{hi:pZ}),
and the final replacement {it:part} ({hi:pZ}) gets the original ({hi:p1}) {cmd:^t=}{it:table-name}.{p_end}


{marker swap}{title:Swappable Tags}

{pstd}{hi:swappable tags} are a sort of macro. They are marked bits of text which can be swapped out for other bits of text at runtime. The syntax is:

{pmore2}{cmd:^t:}{it:name}{p_end}
{pmore}or{p_end}
{pmore2}{cmd:^g:}{it:name}

{pmore}where {it:name} is a valid stata name.

{pstd}{cmd:^t:} tags will ultimately be interpreted as sql table names, while generic {cmd:^g:} tags will not. Replacement text can be specified in the {opt swap()} option of either a {cmd:^ssc=} {it:part definition}, or the {help sql do} command itself.

{pstd}If no swap is specified for a particular tag, the prefix is stripped and, for {cmd:^g:} tags, {it:name} is used in the final sql. For {cmd:^t:} tags, {it:name} is first interpreted as a table:
if it matches an earlier {cmd:^t=}{it:name} (one that hasn't been excluded by {opt only()}), that table will be referenced; otherwise, {it:name} is given the current schema accoring to the {help sql path}.

{pstd}Although you can specify tables withuot a {cmd:^t:} tag, it generally makes sense to use the tags when referring to your own tables.
For example, if you create {hi:tableA} early in your script and refer to it at a later point, you can have the unmodified script execute
using some {hi:alternate-tableA} by setting the {opt only()} and/or {opt not()} options on the command line. Handy for debugging.

{pstd}Also, note that uploads (ie, {cmd:^use=} and {cmd:^codex=}) are created on the server with temporary names, and using {cmd:^t:}{it:name} will reference the correct temporary table.

{pstd}All tags and their ultimate renditions (and the tables used & excluded by the script) are tracked by {help sql do},  and summarized in its {bf:preview}.

