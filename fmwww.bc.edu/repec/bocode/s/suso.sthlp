{smcl}
{* *! version 1.6.4  18jun2026}{...}
{viewerdialog suso "dialog suso"}{...}
{vieweralsosee "[D] import" "help import"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "suso##syntax"}{...}
{viewerjumpto "Description" "suso##description"}{...}
{viewerjumpto "Setup" "suso##setup"}{...}
{viewerjumpto "Configuration options" "suso##configopts"}{...}
{viewerjumpto "Common options" "suso##common"}{...}
{viewerjumpto "Subcommands" "suso##subcommands"}{...}
{viewerjumpto "Pagination" "suso##pagination"}{...}
{viewerjumpto "Export workflow" "suso##export"}{...}
{viewerjumpto "Maps (GraphQL)" "suso##maps"}{...}
{viewerjumpto "Administration (workspace/settings/statistics)" "suso##admin"}{...}
{viewerjumpto "Destructive operations" "suso##destructive"}{...}
{viewerjumpto "Stored results" "suso##results"}{...}
{viewerjumpto "Examples" "suso##examples"}{...}
{viewerjumpto "Requirements" "suso##requirements"}{...}
{viewerjumpto "Author" "suso##author"}{...}
{title:Title}

{phang}
{bf:suso} {hline 2} Client for the Survey Solutions (SuSo) REST API

{marker syntax}{...}
{title:Syntax}

{pstd}
Configure the connection (once per session):

{p 8 15 2}
{cmd:suso config} {cmd:,} {opt server(url)} {opt w:orkspace(name)} {opt u:ser(apiuser)}
{opt p:assword(pw)} [{it:config_options}]

{pstd}
Run a command of the form:

{p 8 15 2}
{cmd:suso} {it:noun} {it:verb} [{cmd:,} {it:options}]

{pstd}
Quick utilities (no {it:verb}):

{p 8 15 2}
{cmd:suso} {opt ping}{p_end}
{p 8 15 2}
{cmd:suso} {opt doctor}{p_end}
{p 8 15 2}
{cmd:suso} {opt login}{p_end}
{p 8 15 2}
{cmd:suso} {opt config} [{cmd:, show}|{cmd:clear}]{p_end}
{p 8 15 2}
{cmd:suso} {opt examples}{p_end}
{p 8 15 2}
{cmd:suso} {opt endpoints}{p_end}
{p 8 15 2}
{cmd:suso} {opt about}{p_end}
{p 8 15 2}
{cmd:suso} {opt raw} {it:path} [{cmd:,} {opt method(verb)} {opt q:uery(string)} {opt body(json)} {opt todata} ...]

{pstd}
where {it:noun} is one of {cmd:assignment}, {cmd:interview}, {cmd:questionnaire},
{cmd:export}, {cmd:user}, {cmd:supervisor}, {cmd:interviewer}, {cmd:workspace},
{cmd:maps}, {cmd:settings}, or {cmd:statistics}; and {it:verb} is the action (for example,
{cmd:list}, {cmd:get}, {cmd:create}). See {it:{help suso##subcommands:Subcommands}}.

{pstd}
Most {cmd:list}/{cmd:get} commands that return rows load them into memory as the
current dataset, replacing any unsaved data. Scalar responses are returned in
{cmd:r()}; see {it:{help suso##results:Stored results}}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:suso} is a complete Stata client for the World Bank
{browse "https://docs.mysurvey.solutions/":Survey Solutions} REST API
(API v1 and v2). It lets you script fieldwork operations that otherwise require
the web interface: list and inspect assignments and interviews; approve, reject,
comment on, reassign and delete interviews; create and manage assignments and
users; start, monitor and download data exports; and administer workspaces and
server settings {hline 1} all from Stata do-files.

{pstd}
{cmd:suso} talks to the server through a small, dependency-free Java backend
({cmd:suso.jar}) using Stata's {helpb javacall}. The Java layer performs the
HTTPS requests (with proper {cmd:PATCH}/{cmd:PUT}/{cmd:DELETE}, optional proxy,
streaming file downloads, and redirect handling) and hands results back to
Stata. You never call Java directly; the {cmd:.ado} interface is the whole API.

{pstd}
List endpoints page through results automatically and load them as a Stata
dataset; commands that fetch a single object expose its fields in {cmd:r()}.
Operations that change or remove data on the server are guarded
(see {it:{help suso##destructive:Destructive operations}}).

{marker setup}{...}
{title:Setup}

{pstd}
Configure the server and workspace once per session. {opt user()} and
{opt password()} are {bf:optional} {hline 1} if you omit them, {cmd:suso} prompts
for the user name and a masked password the first time a command contacts the
server (or run {cmd:suso login} to enter them up front). Use a dedicated
{bf:API user}, not Headquarters or Administrator credentials.

{p 8 12 2}
{cmd:. suso config , server("https://your-server") workspace("myws")}{p_end}
{p 8 12 2}
{cmd:. suso ping}{p_end}

{pstd}
To supply credentials non-interactively, add {opt user()} (and optionally
{opt password()}); safer still, set the {cmd:SUSO_PASSWORD} environment variable
before launching Stata so the password never enters your command history.
Credentials are kept for the session only.

{pstd}
Optionally pin a default questionnaire so you can omit {opt guid()}/{opt qver()}:

{p 8 12 2}
{cmd:. suso config , guid("76732117-1b19-4c82-bd39-1e34a781a2e9") qver(11)}{p_end}

{pstd}
Settings live in {cmd:global} macros for the session only; nothing is written to
disk except the optional audit log. Review the current settings with
{cmd:suso config , show} (the password is masked) and clear them with
{cmd:suso config , clear}. Verify the Java runtime and the location of
{cmd:suso.jar} with {cmd:suso doctor}.

{marker configopts}{...}
{title:Configuration options}

{pstd}
For {cmd:suso config}:

{synoptset 26 tabbed}{...}
{synopthdr:config_option}
{synoptline}
{synopt :{opt server(url)}}base server URL, e.g. {cmd:https://demo.mysurvey.solutions}{p_end}
{synopt :{opt w:orkspace(name)}}workspace short name (path segment), e.g. {cmd:primary}{p_end}
{synopt :{opt u:ser(name)}}API user name{p_end}
{synopt :{opt p:assword(pw)}}API user password{p_end}
{synopt :{opt token(t)}}use a bearer token instead of user/password{p_end}
{synopt :{opt auth(type)}}authentication scheme: {cmd:basic} (default) or {cmd:bearer}{p_end}
{synopt :{opt jar(path)}}full path to {cmd:suso.jar} (only if not on the adopath){p_end}
{synopt :{opt guid(id)}}default questionnaire GUID for later commands{p_end}
{synopt :{opt qver(#)}}default questionnaire version{p_end}
{synopt :{opt proxyh:ost(h)}}proxy host (corporate networks){p_end}
{synopt :{opt proxyport(#)}}proxy port{p_end}
{synopt :{opt proxyuser(u)}}proxy user{p_end}
{synopt :{opt proxypass(p)}}proxy password{p_end}
{synopt :{opt insecure}}skip TLS certificate verification (use with care){p_end}
{synopt :{opt noinsecure}}re-enable TLS verification{p_end}
{synopt :{opt connt:imeout(ms)}}connection timeout in milliseconds (default 30000){p_end}
{synopt :{opt readt:imeout(ms)}}read timeout in milliseconds (default 300000){p_end}
{synopt :{opt max:rows(#)}}safety cap on rows fetched by paginated lists (default 100000){p_end}
{synopt :{opt audit:file(path)}}append destructive actions to this log file{p_end}
{synopt :{opt show}}display the current configuration (password masked){p_end}
{synopt :{opt clear}}clear all session configuration{p_end}
{synoptline}

{marker common}{...}
{title:Common options}

{phang}
{opt guid(id)} and {opt qver(#)} identify a questionnaire. They may be omitted
when a default has been set with {cmd:suso config , guid() qver()}.

{phang}
{opt all} on a {cmd:list} command fetches {bf:every} matching record by paging
through the server; without {opt all} only the first page is returned.
See {it:{help suso##pagination:Pagination}}.

{phang}
{opt saving(filename)} (with {opt replace}) writes a downloaded artifact
(export archive, interview/questionnaire PDF, statistics file). Relative paths
resolve against the Stata working directory ({helpb pwd}).

{phang}
{opt confirm} is required to proceed with most destructive verbs;
see {it:{help suso##destructive:Destructive operations}}.

{phang}
{opt verbose} prints the HTTP method, URL and status for the request {hline 1}
the first thing to add when a call behaves unexpectedly.

{marker subcommands}{...}
{title:Subcommands}

{pstd}{bf:Connection and utilities}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:suso ping}}test connectivity and credentials{p_end}
{synopt :{cmd:suso doctor}}check Java runtime and locate {cmd:suso.jar}{p_end}
{synopt :{cmd:suso login}}prompt for the API user and password (masked){p_end}
{synopt :{cmd:suso config}}set or {cmd:show}/{cmd:clear} the session configuration{p_end}
{synopt :{cmd:suso about}}show package version{p_end}
{synopt :{cmd:suso examples}}print copy-paste recipes{p_end}
{synopt :{cmd:suso endpoints}}print the full command list{p_end}
{synopt :{cmd:suso raw} {it:path}}call any endpoint not wrapped below{p_end}
{synoptline}

{pstd}{bf:assignment}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:list}}assignments; filters {opt searchby()} {opt resp:onsible()} {opt sup:ervisor()} {opt order()} {opt archived} {opt guid()} {opt qver()} {opt all}{p_end}
{synopt :{cmd:get} {opt id()}}one assignment{p_end}
{synopt :{cmd:history} {opt id()}}assignment history ({opt start()} {opt length()}){p_end}
{synopt :{cmd:quantitysettings} {opt id()}}quantity settings for an assignment{p_end}
{synopt :{cmd:create} {opt resp:onsible()}}create an assignment ({opt quant:ity()} {opt email()} {opt pass:word()} {opt webmode} {opt audio} {opt comm:ents()} {opt target:area()} {opt ident:ifying()}){p_end}
{synopt :{cmd:assign} {opt id()} {opt resp:onsible()}}reassign an assignment{p_end}
{synopt :{cmd:quantity} {opt id()} {opt n()}}change interview quantity{p_end}
{synopt :{cmd:close} {opt id()}}close an assignment{p_end}
{synopt :{cmd:archive} {opt id()}}archive an assignment{p_end}
{synopt :{cmd:unarchive} {opt id()}}unarchive an assignment{p_end}
{synopt :{cmd:audio} {opt id()} [{opt on} {opt off}]}get or set audio recording{p_end}
{synopt :{cmd:targetarea} {opt id()} {opt area()}}set the target area{p_end}
{synoptline}

{pstd}{bf:interview}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:list}}interviews; filters {opt status()} {opt guid()} {opt qver()} {opt id()} {opt all}{p_end}
{synopt :{cmd:get} {opt id()}}interview answers (loaded as data){p_end}
{synopt :{cmd:stats} {opt id()}}interview statistics{p_end}
{synopt :{cmd:history} {opt id()}}interview event history (loaded as data){p_end}
{synopt :{cmd:pdf} {opt id()} {opt saving()}}download the interview PDF{p_end}
{synopt :{cmd:approve} {opt id()}}supervisor approve ({opt comment()}){p_end}
{synopt :{cmd:reject} {opt id()}}supervisor reject ({opt comment()} {opt resp:onsible()}){p_end}
{synopt :{cmd:hqapprove} {opt id()}}HQ approve{p_end}
{synopt :{cmd:hqreject} {opt id()}}HQ reject{p_end}
{synopt :{cmd:hqunapprove} {opt id()}}HQ unapprove{p_end}
{synopt :{cmd:assign} {opt id()}}assign to an interviewer ({opt resp:onsible()}|{opt responsibleid()}|{opt responsiblename()}){p_end}
{synopt :{cmd:assignsupervisor} {opt id()}}assign to a supervisor{p_end}
{synopt :{cmd:comment} {opt id()} {opt question()} {opt comment()}}comment on a question{p_end}
{synopt :{cmd:commentbyvar} {opt id()} {opt var:iable()} {opt comment()}}comment by variable ({opt roster:vector()}){p_end}
{synopt :{cmd:delete} {opt id()}}delete an interview {it:(destructive)}{p_end}
{synoptline}

{pstd}{bf:questionnaire}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:list}}questionnaires on the server ({opt all}){p_end}
{synopt :{cmd:get}}details for {opt guid()} {opt qver()}{p_end}
{synopt :{cmd:document} {opt saving()}}download the questionnaire document (PDF){p_end}
{synopt :{cmd:interviews}}interviews for a questionnaire ({opt all}){p_end}
{synopt :{cmd:audio} [{opt get} {opt on} {opt off}]}get/set audio recording for a questionnaire{p_end}
{synopt :{cmd:criticality} [{opt get} {opt level()}]}get/set criticality level{p_end}
{synoptline}

{pstd}{bf:export}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:list}}existing export jobs ({opt type()} {opt istatus()} {opt estatus()} {opt hasfile} {opt all}){p_end}
{synopt :{cmd:start} {opt type()}}start an export ({opt istatus()} {opt guid()} {opt qver()} {opt from()} {opt to()} {opt meta}|{opt nometa} {opt paradatareduced}){p_end}
{synopt :{cmd:status} {opt id()}}poll an export job's status{p_end}
{synopt :{cmd:download} {opt id()} {opt saving()}}download a completed export archive; add {opt unzip} (or {opt unzipw(pw)} for password-protected archives, {opt unzipto(dir)} for the target folder) to extract it{p_end}
{synopt :{cmd:get} {opt type()} {opt saving()}}{bf:one-shot}: start, show progress, and auto-download when complete (accepts {opt unzip}/{opt unzipw()}/{opt unzipto()} and all {cmd:start} filters){p_end}
{synopt :{cmd:cancel} {opt id()}}cancel/delete an export job {it:(destructive)}{p_end}
{synoptline}

{pstd}
{opt type()} is one of {cmd:STATA}, {cmd:SPSS}, {cmd:Tabular}, {cmd:Binary},
{cmd:DDI}, {cmd:Paradata}. See {it:{help suso##export:Export workflow}}.

{pstd}{bf:maps} {it:(uploads/deletes via the GraphQL endpoint; see {help suso##maps:Maps})}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:list}}list maps on the server ({opt workspace()}){p_end}
{synopt :{cmd:upload} {opt file()}}upload a map file ({opt name()} to override the stored name){p_end}
{synopt :{cmd:delete} {opt name()}}delete one map {it:(destructive)}{p_end}
{synopt :{cmd:deleteall}}delete {bf:every} map in the workspace {it:(destructive; dry-run unless confirmed)}{p_end}
{p2colreset}{...}

{marker backup}{...}
{title:Backup}

{phang}
{cmd:suso backup ,} {opt dir(folder)} [{opt types(STATA Paradata ...)} {opt istatus(All)} {opt nometa}
{opt pollsecs(10)} {opt jobtimeout(3600)} {opt noe:xports} {opt noq:uestionnaires} {opt now:orkspace}]{p_end}

{pmore}
Archives a whole workspace into {it:folder} using the existing verbs: a questionnaire
list ({cmd:questionnaires_list.dta}) plus one JSON document per version; one export zip
per questionnaire-version per {opt types()} entry (start {it:->} poll {it:->} download, with
empty jobs skipped and per-job failures tolerated); and {cmd:assignments.dta} +
{cmd:supervisors.dta}. Returns {cmd:r(ok)}, {cmd:r(skipped)}, {cmd:r(failed)}. Your current
data is preserved/restored. Example: {cmd:suso backup , dir("C:/archive/srilanka") types(STATA Paradata)}.{p_end}
{synopt :{cmd:assign} {opt name()} {opt user()}}give an interviewer access to a map{p_end}
{synopt :{cmd:unassign} {opt name()} {opt user()}}remove an interviewer's access{p_end}
{synoptline}

{pstd}{bf:user}, {bf:supervisor}, {bf:interviewer}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:user get} {opt id()}}user details{p_end}
{synopt :{cmd:user create} {opt role()} {opt u:sername()} {opt p:assword()}}create a user ({opt full:name()} {opt phone()} {opt email()} {opt supervisor()}){p_end}
{synopt :{cmd:user archive} {opt id()}}archive a user{p_end}
{synopt :{cmd:user unarchive} {opt id()}}unarchive a user{p_end}
{synopt :{cmd:supervisor list}}supervisors ({opt all}){p_end}
{synopt :{cmd:supervisor get} {opt id()}}supervisor details{p_end}
{synopt :{cmd:supervisor interviewers} {opt id()}}interviewers under a supervisor ({opt all}){p_end}
{synopt :{cmd:interviewer get} {opt id()}}interviewer details{p_end}
{synopt :{cmd:interviewer actionslog} {opt id()}}interviewer action log ({opt start()} {opt end()}){p_end}
{synoptline}

{pstd}{bf:workspace}, {bf:settings}, {bf:statistics}{p_end}
{synoptset 30 tabbed}{...}
{synopt :{cmd:workspace list}}workspaces ({opt includedisabled}){p_end}
{synopt :{cmd:workspace get|status} {opt name()}}workspace details/status{p_end}
{synopt :{cmd:workspace create} {opt name()} {opt display:name()}}create a workspace{p_end}
{synopt :{cmd:workspace update} {opt name()} {opt display:name()}}rename a workspace{p_end}
{synopt :{cmd:workspace enable|disable} {opt name()}}enable/disable a workspace{p_end}
{synopt :{cmd:workspace delete} {opt name()}}delete a workspace {it:(destructive)}{p_end}
{synopt :{cmd:workspace assign} {opt userids()} {opt works:paces()}}assign users to workspaces ({opt mode()} {opt supervisor()}){p_end}
{synopt :{cmd:settings get}}server global notice{p_end}
{synopt :{cmd:settings set} {opt message()}}set the global notice{p_end}
{synopt :{cmd:settings clear}}clear the global notice{p_end}
{synopt :{cmd:statistics questionnaires}}questionnaires available for reporting{p_end}
{synopt :{cmd:statistics questions}}reportable questions for {opt guid()} {opt qver()}{p_end}
{synopt :{cmd:statistics report} {opt question()}}tabulation report ({opt exporttype()} {opt saving()} {opt query()}){p_end}
{synoptline}

{pstd}
Most {cmd:workspace} verbs require admin rights and accept {opt usews} to act
against the configured workspace context. See {help suso##admin:Administration}
below for worked examples of {cmd:workspace}, {cmd:settings} and {cmd:statistics}.

{marker pagination}{...}
{title:Pagination}

{pstd}
{cmd:list} commands fetch only the {bf:first page} by default. Add {opt all} to
page through and return every matching record. {cmd:suso} learns the server's
effective page size automatically (Survey Solutions caps some lists, e.g.
interviews at 40 per page) and keeps requesting pages until the reported total
is reached, so {opt all} is reliable even when the server returns fewer rows than
requested. The {opt maxrows()} configuration value is a safety ceiling on the
total number of rows a single {opt all} call will load.

{marker export}{...}
{title:Export workflow}

{pstd}
Exporting data is three steps: {cmd:start}, poll {cmd:status} until it reports
{cmd:Completed}, then {cmd:download}. To do all three at once, use the one-shot
{cmd:export get} (below) {hline 1} it starts the job, prints progress as it
climbs, and downloads automatically the moment it hits 100%.

{p 8 12 2}{cmd:. suso export start , type(STATA) qver(11) istatus(ApprovedBySupervisor)}{p_end}
{p 8 12 2}{cmd:. suso export status , id(`=r(jobid)')}{p_end}
{p 8 12 2}{cmd:. suso export download , id(`=r(jobid)') saving("data.zip") replace unzip}{p_end}

{pstd}
Or the same end to end in one command (no manual polling):

{p 8 12 2}{cmd:. suso export get , type(STATA) qver(11) istatus(ApprovedBySupervisor) saving("ses_v11.zip") replace}{p_end}
{p 8 12 2}{cmd:. suso export get , type(STATA) qver(11) saving("ses_v11.zip") replace unzipw("pw") unzipto("O:/.../extracted")}{p_end}

{pstd}
{cmd:get} takes the same filters as {cmd:start} ({opt type()}, {opt guid()},
{opt qver()}, {opt istatus()}, {opt meta}|{opt nometa}) plus the extraction
options of {cmd:download}. Polling cadence is {opt pollsecs()} (default 10s) and it
gives up after {opt jobtimeout()} (default 3600s). If the completed job has no data
for the filter, nothing is downloaded and {cmd:r(status)} is {cmd:NoFile}. Returns
{cmd:r(saved)}, {cmd:r(jobid)}, {cmd:r(status)} and (when extracting)
{cmd:r(unzipped)}/{cmd:r(unzipdir)}.

{pstd}
Add {opt unzip} to extract the archive after download (into a folder named after the zip, or {opt unzipto(}{it:dir}{cmd:)}). Survey Solutions can password-protect exports; for those, use {opt unzipw(}{it:password}{cmd:)}. Extraction is done by the bundled Java backend and supports the traditional ZipCrypto scheme SuSo uses, so no external unzip tool is required. {cmd:r(unzipped)} and {cmd:r(unzipdir)} report the result.

{pstd}
Extraction variants:

{p 8 12 2}{it:// plain archive {c 45}{c 45} extract beside the zip}{p_end}
{p 8 12 2}{cmd:. suso export download , id(`=r(jobid)') saving("ses_v11.zip") replace unzip}{p_end}
{p 8 12 2}{it:// password-protected archive}{p_end}
{p 8 12 2}{cmd:. suso export download , id(`=r(jobid)') saving("ses_v11.zip") replace unzipw("yourpassword")}{p_end}
{p 8 12 2}{it:// password-protected, extracting to a chosen folder}{p_end}
{p 8 12 2}{cmd:. suso export download , id(`=r(jobid)') saving("ses_v11.zip") replace unzipw("pw") unzipto("O:/.../2026-06-17/extracted")}{p_end}

{pstd}
{opt unzipw()} implies {opt unzip}, so you need not give both. The {opt unzipw()}
password is the {bf:archive} password set on the export, which is different from
your API {opt password()}.

{pstd}
{cmd:start} returns the job id in {cmd:r(jobid)}. A questionnaire {bf:version}
is required (the API identifies a questionnaire as {it:guid}${it:version}); set
{opt qver()} or a default via {cmd:suso config}. Immediately after a job reports
{cmd:Completed} the file endpoint can briefly return HTTP 403 while the archive
is finalized {hline 1} simply retry {cmd:download} (or poll {cmd:status} once
more). Downloads follow the server's redirect to storage and stream straight to
{opt saving()}.

{marker maps}{...}
{title:Maps (GraphQL)}

{pstd}
Unlike the rest of {cmd:suso}, map management uses Survey Solutions' {bf:GraphQL}
endpoint ({cmd:/graphql}), not the REST API. The {cmd:maps} subcommands wrap this
for you, so the workflow is the same as any other {cmd:suso} command:

{p 8 12 2}{cmd:. suso maps list}{p_end}
{p 8 12 2}{cmd:. suso maps upload , file("C:/maps/region.tpk")}{p_end}
{p 8 12 2}{cmd:. suso maps assign , name("region.tpk") user("FieldInt01")}{p_end}
{p 8 12 2}{cmd:. suso maps delete , name("region.tpk") confirm}{p_end}

{pstd}
{cmd:upload} sends a {bf:.zip} archive (containing a complete shapefile family
{cmd:.shp}+{cmd:.dbf}+{cmd:.shx}+{cmd:.prj}, and/or {cmd:.tif}/GeoTIFF or {cmd:.tpk}
basemaps) as a GraphQL multipart upload; one archive may carry several maps. {cmd:list} loads the maps into a
dataset (file name, size, import date, uploader). {cmd:delete} is irreversible and needs {opt confirm}. {cmd:deleteall} wipes the
whole library: by default it only lists what would go (a dry run); to actually
delete you confirm by typing the workspace name, e.g. {cmd:suso maps deleteall ,}
{cmd:iknowthis(srilankainf)}. It is throttled ({opt sleep()} ms between deletes,
default 200) and tolerant of per-map failures, reporting {cmd:r(deleted)}/{cmd:r(failed)}. {cmd:assign}/{cmd:unassign} control which interviewers
can download a given map to their tablet. If your server expects a workspace
argument on a map operation and rejects a call, the GraphQL error message is
shown verbatim so you can adjust.

{marker admin}{...}
{title:Administration: workspace, settings, statistics}

{pstd}
These verbs administer the {bf:server}, not survey data. Most default to the
server {bf:root} rather than your configured workspace; add {opt usews} only if
your deployment scopes them under the workspace path.

{pstd}
{bf:Who can run what.} Permission is set by the account in {cmd:suso config , user()}.
Running an admin-only verb with a plain API user returns HTTP 401/403 from the server.

{p2colset 9 32 34 2}{...}
{p2col :{bf:Any API user} {hline 1} read}{cmd:workspace list}, {cmd:workspace get}, {cmd:workspace status}, {cmd:settings get}, and all {cmd:statistics} verbs{p_end}
{p2col :{bf:Admin only} {hline 1} write}{cmd:workspace create}, {cmd:update}, {cmd:enable}, {cmd:disable}, {cmd:delete}, {cmd:assign}; and {cmd:settings set} / {cmd:clear}{p_end}
{p2colreset}{...}

{pstd}
Two of the admin-only verbs {hline 1} {cmd:workspace disable} and
{cmd:workspace delete} {hline 1} are also {bf:destructive} and carry extra
guards (see {help suso##destructive:Destructive operations}).

{marker admin_read}{...}
{dlgtab:Read (any API user)}

{pstd}{bf:Workspaces.} {cmd:list} loads a dataset; {cmd:get} and {cmd:status} return values in {cmd:r()}:

{p 8 12 2}{cmd:. suso workspace list , includedisabled}{p_end}
{p 8 12 2}{cmd:. suso workspace get    , name("srilankainf")}{space 3}{it:// r(name), r(displayname)}{p_end}
{p 8 12 2}{cmd:. suso workspace status , name("srilankainf")}{p_end}

{pstd}
{cmd:status} reports, and returns, {cmd:r(canbedeleted)} alongside
{cmd:r(existingquestionnairescount)}, {cmd:r(supervisorscount)},
{cmd:r(interviewerscount)} and {cmd:r(mapscount)} {hline 1} use it before a
{cmd:delete} to see what a workspace still holds.

{pstd}{bf:Settings.} {cmd:get} returns the server login banner in {cmd:r(message)}:

{p 8 12 2}{cmd:. suso settings get}{p_end}

{pstd}{bf:Statistics} are server-side tabulations, with no microdata pulled:

{p 8 12 2}{cmd:. suso statistics questionnaires}{space 3}{it:// dataset of reportable questionnaires}{p_end}
{p 8 12 2}{cmd:. suso statistics questions , guid(<guid>) qver(3)}{space 3}{it:// reportable questions}{p_end}
{p 8 12 2}{cmd:. suso statistics report , question(q14_sector) guid(<guid>) qver(3)}{p_end}
{p 8 12 2}{cmd:. suso statistics report , question(q14_sector) guid(<guid>) qver(3) exporttype(xlsx) saving("sector_tab.xlsx") replace}{p_end}

{pstd}
{cmd:report} needs the question's {bf:variable name} (for example {cmd:q14_sector}),
not a guid; it loads the tabulation into a dataset, or writes it to a file with
{opt saving()} ({opt exporttype()} = {cmd:csv}, {cmd:tab} or {cmd:xlsx}). Pass any
extra report parameters verbatim with {opt query()}. If {opt guid()}/{opt qver()}
are omitted they fall back to {cmd:suso config}. For case-level data use
{cmd:suso export} or {cmd:suso backup} instead.

{marker admin_write}{...}
{dlgtab:Admin only (write)}

{pstd}
{bf:These require an administrator account.} A plain API user cannot run them.

{pstd}{bf:Create / rename / enable.} {opt displayname()} is the human-readable label:

{p 8 12 2}{cmd:. suso workspace create , name("ises2026") displayname("ISES Sri Lanka 2026")}{p_end}
{p 8 12 2}{cmd:. suso workspace update , name("ises2026") displayname("ISES SL 2026 (field)")}{p_end}
{p 8 12 2}{cmd:. suso workspace enable  , name("ises2026")}{p_end}

{pstd}
{bf:Disable} (reversible, but destructive {hline 1} blocks the workspace) requires {opt confirm}:

{p 8 12 2}{cmd:. suso workspace disable , name("ises2026") confirm}{p_end}

{pstd}
{bf:Delete} (irreversible) is the most guarded command: retype the name in
{opt iknowthis()}, and it runs a pre-flight {cmd:status} check that refuses a
non-empty workspace unless you add {opt force}:

{p 8 12 2}{cmd:. suso workspace delete , name("ises2026") iknowthis("ises2026")}{p_end}
{p 8 12 2}{cmd:. suso workspace delete , name("ises2026") iknowthis("ises2026") force}{p_end}

{pstd}
{bf:Assign} maps users to workspaces. {opt userids()} and {opt workspaces()} are
{bf:space-separated} lists; {opt mode()} is {cmd:Assign} (replace; the default),
{cmd:Add} or {cmd:Remove}; {opt supervisor()} attaches interviewers to a
supervisor id:

{p 8 12 2}{cmd:. suso workspace assign , userids("11111111-id1 22222222-id2") workspaces("ises2026")}{p_end}
{p 8 12 2}{cmd:. suso workspace assign , userids("33333333-id3") workspaces("ises2026") mode(Add) supervisor("99999999-sup")}{p_end}

{pstd}{bf:Settings.} {cmd:set} writes the server-wide login banner; {cmd:clear} removes it:

{p 8 12 2}{cmd:. suso settings set , message("Fieldwork freeze 20-22 Jun for QC.")}{p_end}
{p 8 12 2}{cmd:. suso settings clear}{p_end}


{marker destructive}{...}
{title:Destructive operations}

{pstd}
Verbs that delete or irreversibly change server state {hline 1} for example
{cmd:interview delete}, {cmd:export cancel}, {cmd:workspace delete} {hline 1}
require the {opt confirm} option to proceed and are recorded in the audit log if
{opt auditfile()} is configured. {cmd:workspace delete} additionally requires
{opt iknowthis()} matching the workspace name. This guard is deliberate; review
the target before adding {opt confirm} in a do-file.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:suso} commands are {cmd:rclass}. After any command:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars and macros}{p_end}
{synopt:{cmd:r(http)}}HTTP status code of the last request{p_end}
{synopt:{cmd:r(nobs)}}number of rows loaded (list/get-as-data commands){p_end}
{synopt:{cmd:r(totalcount)}}server-reported total for a paginated list{p_end}
{synopt:{cmd:r(saved)}}path written by a download/{opt saving()} command{p_end}
{synopt:{cmd:r(bytes)}}bytes written by a download{p_end}
{synopt:{cmd:r(jobid)}}export job id (after {cmd:export start}){p_end}
{synopt:{cmd:r(}{it:field}{cmd:)}}each scalar field of a single-object response, lowercased{p_end}
{synoptline}

{pstd}
For a single-object response (for example {cmd:export status} or
{cmd:interview stats}), each top-level scalar field of the JSON is returned as
{cmd:r(}{it:field}{cmd:)} with the field name lowercased (e.g. {cmd:r(exportstatus)},
{cmd:r(progress)}). Rows are loaded as the current dataset and are not duplicated
in {cmd:r()}.

{marker examples}{...}
{title:Examples}

{pstd}
Every example below is a real command. {it:guid} is a questionnaire id and {it:qver}
its version; set them once with {cmd:suso config , guid() qver()} or pass them per
command. List/browse verbs replace the data in memory; single-record verbs fill {cmd:r()}.

{dlgtab:1. Set up and test the connection}

{pstd}
You only need {opt server()} and {opt workspace()}. {opt user()} and {opt password()}
are {bf:optional}: if you omit them, {cmd:suso} asks for the user name and a masked
password the first time a command contacts the server (or run {cmd:suso login} to enter
them up front). So the minimal setup is just:{p_end}
{p 8 12 2}{cmd:. suso config , server("https://demo.mysurvey.solutions") workspace("primary")}{p_end}
{p 8 12 2}{cmd:. suso ping}{space 6}{it:// prompts for user + password (masked), then checks auth}{p_end}

{pstd}
You may still supply them non-interactively with {opt user()} / {opt password()}, or
{hline 1} safer, keeping the password out of your command history {hline 1} set the
{cmd:SUSO_PASSWORD} environment variable before launching Stata:{p_end}
{p 8 12 2}{cmd:. suso config , server("https://demo.mysurvey.solutions") workspace("primary") user("API_USER")}{p_end}
{p 8 12 2}{cmd:. suso login}{space 5}{it:// enter / replace credentials at a masked prompt anytime}{p_end}
{p 8 12 2}{cmd:. suso doctor}{space 4}{it:// Java/JVM check + which suso.jar is in use}{p_end}
{p 8 12 2}{cmd:. suso config , show}{space 1}{it:// review current settings (password masked)}{p_end}

{dlgtab:2. Pull lists into a Stata dataset}

{pstd}Add {opt all} to fetch every page (auto-paginated):{p_end}
{p 8 12 2}{cmd:. suso assignment list , all}{p_end}
{p 8 12 2}{cmd:. suso assignment list , responsible("FieldInt01") guid(<guid>) qver(11)}{p_end}
{p 8 12 2}{cmd:. suso interview list , status(Completed) all}{p_end}
{p 8 12 2}{cmd:. suso questionnaire list , all}{p_end}
{p 8 12 2}{cmd:. suso supervisor list , all}{p_end}
{p 8 12 2}{cmd:. suso supervisor interviewers , id(<supervisor-id>) all}{p_end}
{p 8 12 2}{cmd:. suso export list}{p_end}

{dlgtab:3. Inspect one record (values land in r())}

{p 8 12 2}{cmd:. suso assignment get , id(123)}{p_end}
{p 8 12 2}{cmd:. suso interview get   , id(2e0ec4fa-9ec7-4849-ba6e-1e8a18995457)}{p_end}
{p 8 12 2}{cmd:. suso interview stats , id(2e0ec4fa-9ec7-4849-ba6e-1e8a18995457)}{p_end}
{p 8 12 2}{cmd:. return list}{space 2}{it:// see everything the call returned}{p_end}

{dlgtab:4. Interview QC workflow}

{pstd}Approve / reject (HQ variants escalate to headquarters):{p_end}
{p 8 12 2}{cmd:. suso interview approve   , id(<uuid>) comment("looks good")}{p_end}
{p 8 12 2}{cmd:. suso interview reject    , id(<uuid>) comment("GPS off-square; please revisit")}{p_end}
{p 8 12 2}{cmd:. suso interview hqapprove , id(<uuid>)}{p_end}
{p 8 12 2}{cmd:. suso interview hqreject  , id(<uuid>) comment("inconsistent roster")}{p_end}

{pstd}Comment on a specific question, by question id or by variable name:{p_end}
{p 8 12 2}{cmd:. suso interview comment      , id(<uuid>) question(<question-id>) comment("verify units")}{p_end}
{p 8 12 2}{cmd:. suso interview commentbyvar , id(<uuid>) variable(q14_sales) comment("seems too high")}{p_end}
{p 8 12 2}{cmd:. suso interview commentbyvar , id(<uuid>) variable(emp_name) rostervector(2) comment("typo")}{p_end}

{pstd}Reassign, save the PDF, or delete (delete needs {opt confirm}):{p_end}
{p 8 12 2}{cmd:. suso interview assign           , id(<uuid>) responsible("FieldInt07")}{p_end}
{p 8 12 2}{cmd:. suso interview assignsupervisor , id(<uuid>) responsible("Sup02")}{p_end}
{p 8 12 2}{cmd:. suso interview pdf    , id(<uuid>) saving("iv.pdf") replace}{p_end}
{p 8 12 2}{cmd:. suso interview delete , id(<uuid>) confirm}{p_end}

{dlgtab:5. Assignments}

{p 8 12 2}{cmd:. suso assignment create   , responsible("FieldInt01") guid(<guid>) qver(11) quantity(3)}{p_end}
{p 8 12 2}{cmd:. suso assignment assign   , id(123) responsible("FieldInt09")}{space 1}{it:// reassign}{p_end}
{p 8 12 2}{cmd:. suso assignment quantity , id(123) n(5)}{space 6}{it:// change target count}{p_end}
{p 8 12 2}{cmd:. suso assignment audio    , id(123) on}{space 9}{it:// audio audit on/off}{p_end}
{p 8 12 2}{cmd:. suso assignment close    , id(123)}{p_end}
{p 8 12 2}{cmd:. suso assignment archive  , id(123) confirm}{space 4}{it:// destructive}{p_end}

{dlgtab:6. Questionnaires}

{p 8 12 2}{cmd:. suso questionnaire document    , guid(<guid>) qver(11) saving("q.json") replace}{p_end}
{p 8 12 2}{cmd:. suso questionnaire interviews  , guid(<guid>) qver(11) all}{space 1}{it:// interviews for this version}{p_end}
{p 8 12 2}{cmd:. suso questionnaire audio       , guid(<guid>) qver(11) on}{space 4}{it:// require audio audit}{p_end}
{p 8 12 2}{cmd:. suso questionnaire criticality , guid(<guid>) qver(11) get}{p_end}

{dlgtab:7. Export data}

{pstd}{bf:One-shot} {hline 1} start, watch progress, and download automatically when done:{p_end}
{p 8 12 2}{cmd:. suso export get , type(STATA) guid(<guid>) qver(11) istatus(ApprovedBySupervisor) saving("ses_v11.zip") replace}{p_end}

{pstd}Same, but unzip on arrival (the archive password is {opt unzipw()}, not your API password):{p_end}
{p 8 12 2}{cmd:. suso export get , type(STATA) qver(11) saving("ses_v11.zip") replace unzipw("pw") unzipto("O:/ises/extracted")}{p_end}

{pstd}Or drive the three steps yourself (other types: {cmd:Tabular}, {cmd:SPSS}, {cmd:Binary}, {cmd:Paradata}, {cmd:DDI}):{p_end}
{p 8 12 2}{cmd:. suso export start    , type(SPSS) guid(<guid>) qver(11) istatus(All)}{p_end}
{p 8 12 2}{cmd:. suso export status   , id(`=r(jobid)')}{p_end}
{p 8 12 2}{cmd:. suso export download , id(`=r(jobid)') saving("data.zip") replace unzip}{p_end}

{dlgtab:8. Maps (GraphQL)}

{p 8 12 2}{cmd:. suso maps list}{space 3}{it:// all maps in the workspace (auto-paginated)}{p_end}
{p 8 12 2}{cmd:. suso maps upload , file("colombo_grid.zip")}{space 2}{it:// .zip of a shapefile family, or a .tif/.tpk}{p_end}
{p 8 12 2}{cmd:. suso maps assign , name("colombo_grid.tif") user("SL_Colombo_Ali01")}{p_end}
{p 8 12 2}{cmd:. suso maps delete , name("old_grid.tif") confirm}{space 4}{it:// one map (destructive)}{p_end}

{pstd}Wipe the whole map library {hline 1} dry-run first, then confirm by typing the workspace name:{p_end}
{p 8 12 2}{cmd:. suso maps deleteall}{space 24}{it:// DRY RUN: lists what would go, deletes nothing}{p_end}
{p 8 12 2}{cmd:. suso maps deleteall , iknowthis("srilankainf")}{space 1}{it:// actually deletes all}{p_end}

{dlgtab:9. Users (admin account required)}

{p 8 12 2}{cmd:. suso user get     , id(<user-id-or-name>)}{p_end}
{p 8 12 2}{cmd:. suso user create  , role(Interviewer) username("SL_Colombo_Ali01") password("Strong#123") fullname("Ali Khan")}{p_end}
{p 8 12 2}{cmd:. suso interviewer actionslog , id(<interviewer-id>) start("2026-06-01") end("2026-06-17")}{p_end}
{p 8 12 2}{cmd:. suso user archive , id(<user-id>) confirm}{space 2}{it:// destructive}{p_end}

{dlgtab:10. Workspaces (admin); see help suso##admin}

{p 8 12 2}{cmd:. suso workspace list , includedisabled}{p_end}
{p 8 12 2}{cmd:. suso workspace status , name("srilankainf")}{space 3}{it:// counts + r(canbedeleted)}{p_end}
{p 8 12 2}{cmd:. suso workspace create  , name("ises2026") displayname("ISES Sri Lanka 2026")}{p_end}
{p 8 12 2}{cmd:. suso workspace disable , name("ises2026") confirm}{p_end}
{p 8 12 2}{cmd:. suso workspace delete  , name("ises2026") iknowthis("ises2026")}{space 1}{it:// strongest guard}{p_end}
{p 8 12 2}{cmd:. suso workspace assign  , userids("id1 id2") workspaces("ises2026") mode(Add) supervisor("sup-id")}{p_end}

{dlgtab:11. Server settings and statistics}

{p 8 12 2}{cmd:. suso settings get}{p_end}
{p 8 12 2}{cmd:. suso settings set , message("Fieldwork freeze 20-22 Jun for QC.")}{space 1}{it:// admin}{p_end}
{p 8 12 2}{cmd:. suso settings clear}{p_end}
{p 8 12 2}{cmd:. suso statistics questionnaires}{p_end}
{p 8 12 2}{cmd:. suso statistics questions , guid(<guid>) qver(11)}{p_end}
{p 8 12 2}{cmd:. suso statistics report , question(q14_sector) guid(<guid>) qver(11) exporttype(xlsx) saving("tab.xlsx") replace}{p_end}

{dlgtab:12. Back up an entire workspace}

{pstd}One command archives questionnaires, exports (per type), and assignments/users:{p_end}
{p 8 12 2}{cmd:. suso backup , dir("C:/archive/srilanka")}{p_end}
{p 8 12 2}{cmd:. suso backup , dir("C:/archive/srilanka") types(STATA Paradata) jobtimeout(7200)}{p_end}

{dlgtab:13. Reach any endpoint with suso raw}

{p 8 12 2}{cmd:. suso raw /api/v1/settings/globalnotice}{space 6}{it:// GET, flatten to r()}{p_end}
{p 8 12 2}{cmd:. suso raw /api/v1/assignments , query(Limit=5&Offset=0) todata arraykey(Assignments)}{p_end}
{p 8 12 2}{cmd:. suso raw /api/v1/interviews/<uuid> , method(DELETE) allowdestructive}{p_end}

{pstd}
Tip: add {opt verbose} to any command to print the exact request it sends.
{cmd:suso examples} prints a short version of these inside Stata.


{marker requirements}{...}
{title:Requirements}

{pstd}
Stata 14.2 or later and a Java 11+ runtime. Stata ships a bundled Java; confirm
with {cmd:suso doctor}. The Java backend {cmd:suso.jar} is installed alongside
{cmd:suso.ado} and is found automatically on the adopath; if you keep it
elsewhere, point to it with {cmd:suso config , jar(}{it:path}{cmd:)}.

{pstd}
{cmd:suso} requires a Survey Solutions {bf:API user} (not Headquarters or
Administrator credentials). All settings are session-only globals; only the
optional audit log is written to disk.

{marker author}{...}
{title:Author}

{pstd}
{bf:Attique Ur Rehman}, Economist{break}
The World Bank {hline 1} Development Economics (DEC), Enterprise Surveys{break}
Email: {browse "mailto:attique@worldbank.org":attique@worldbank.org}{break}
Web: {browse "https://sites.google.com/view/attique-ur-rehman":https://sites.google.com/view/attique-ur-rehman}

{title:Acknowledgments}

{pstd}
Thanks to {bf:Fahad Mirza} (World Bank / CERP,
{browse "https://github.com/fahad-mirza":github.com/fahad-mirza}) for his insights
and guidance, and for his self-contained Stata tooling ({cmd:sparkta},
{cmd:wordcloud2}) that helped shape this package's design.

{pstd}
Built on the World Bank
{browse "https://docs.mysurvey.solutions/":Survey Solutions} platform and its
public REST API. This package is an independent client and is not an official
Survey Solutions product.

{title:Also see}

{pstd}
Online: {browse "https://docs.mysurvey.solutions/headquarters/api/api-r-package/":Survey Solutions API documentation}{p_end}
{pstd}
Help:  {helpb javacall}, {helpb import}, {helpb shell}{p_end}
