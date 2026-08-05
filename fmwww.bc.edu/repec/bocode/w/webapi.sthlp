{smcl}
{* *! version 0.1.0  2026-07-04}{...}
{viewerjumpto "Syntax" "webapi##syntax"}{...}
{viewerjumpto "Description" "webapi##description"}{...}
{viewerjumpto "Options" "webapi##options"}{...}
{viewerjumpto "Authentication" "webapi##auth"}{...}
{viewerjumpto "Stored results" "webapi##results"}{...}
{viewerjumpto "Examples" "webapi##examples"}{...}
{viewerjumpto "Remarks" "webapi##remarks"}{...}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{cmd:webapi} {hline 2}}Fetch an authenticated JSON web API into Stata as a dataset{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:webapi get} {cmd:using} {it:"URL"} [{cmd:,} {it:options}]

{p 8 16 2}
{cmd:webapi post} {cmd:using} {it:"URL"} [{cmd:,} {cmd:body(}{it:text}{cmd:)} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Shape the reply}
{synopt :{cmd:records(}{it:path}{cmd:)}}dot-path to the JSON array of records; default is the whole reply{p_end}
{synopt :{cmd:stringall}}import every column as a string (skip type detection){p_end}
{synopt :{cmd:clear}}replace the data in memory (as {help import delimited}){p_end}

{syntab :Request}
{synopt :{cmd:params(}{it:k=v|k=v}{cmd:)}}pipe-delimited query-string parameters{p_end}
{synopt :{cmd:headers(}{it:H:V|H:V}{cmd:)}}pipe-delimited request headers{p_end}
{synopt :{cmd:body(}{it:text}{cmd:)}}request body for {cmd:post} (JSON content-type assumed){p_end}
{synopt :{cmd:every(}{it:#}{cmd:)}}poll every {it:#} seconds; snapshots stack into a panel{p_end}
{synopt :{cmd:times(}{it:#}{cmd:)}}number of polls (default 12 when {cmd:every()} is set){p_end}
{synopt :{cmd:timeout(}{it:#}{cmd:)}}seconds before giving up (default 30){p_end}
{synopt :{cmd:tsv(}{it:path}{cmd:)}}keep the intermediate TSV at this path{p_end}
{synopt :{cmd:verbose}}echo the underlying python invocation{p_end}

{syntab :Authentication}
{synopt :{cmd:bearer(}{it:token}{cmd:)}}send {cmd:Authorization: Bearer} {it:token}{p_end}
{synopt :{cmd:basicauth(}{it:user:pw}{cmd:)}}send HTTP basic authentication{p_end}
{synopt :{cmd:apikeyheader(}{it:H:V}{cmd:)}}send an API key as a header{p_end}
{synopt :{cmd:apikeyparam(}{it:k=v}{cmd:)}}send an API key as a query parameter{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:webapi} performs one HTTP request to a JSON web API, authenticates it,
and reads the reply back into Stata as variables and observations.  It is a
small, dependency-free generalisation of the pattern documented for
{help googlesheets} and {help googlechart}: a request to a URL, an
authentication step, and a JSON reply that must be parsed into memory.

{pstd}
The network and JSON work is done by a companion Python helper that uses only
the Python {bf:standard library} (no pip packages, no virtualenv), so the only
requirement is a working {cmd:python3} on the system PATH.  The helper selects the array of records named by {cmd:records()},
flattens each record's nested scalar fields into dotted column names, and
writes a tab-separated table that {cmd:webapi} imports with
{help import delimited}.

{pstd}
For JSON {it:parsing} outside a web-request context, see also
{stata ssc describe jsonio:jsonio} (Buchanan) and
{stata ssc describe insheetjson:insheetjson} / {bf:libjson} (Lindsley);
{cmd:webapi} focuses on the authenticated request-and-shape workflow rather
than on JSON parsing as such.


{marker options}{...}
{title:Options}

{phang}{cmd:records(}{it:path}{cmd:)} names the JSON array to turn into rows.
Use a dot path when the array is nested, for example {cmd:records("data")} or
{cmd:records("results.items")}.  Omit it (or pass {cmd:records("")}) when the
reply is itself the array of records.{p_end}

{phang}{cmd:params()} and {cmd:headers()} are pipe-delimited so that values may
contain spaces: {cmd:params("q=heart disease|limit=50")},
{cmd:headers("Accept:application/json|X-App-Token:abc")}.  Parameter values are
URL-encoded for you.{p_end}


{marker auth}{...}
{title:Authentication}

{pstd}
Pick whichever the API expects.  {cmd:bearer()} sets an
{cmd:Authorization: Bearer} header; {cmd:apikeyheader()} and
{cmd:apikeyparam()} carry an API key in a header or the query string;
{cmd:basicauth()} sends HTTP basic credentials.  A public API needs none of
these.  Store secrets in a global (for example {cmd:$API_TOKEN} set in your
{it:profile.do}) and pass {cmd:bearer("$API_TOKEN")} rather than pasting the
token into the do-file.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:webapi} stores in {cmd:r()}:{p_end}
{synoptset 14 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt :{cmd:r(nrows)}}number of records read; on a polling call, the total
rows accumulated across all polls{p_end}
{synopt :{cmd:r(ncols)}}number of columns (single-request calls only; not
returned when polling){p_end}
{synopt :{cmd:r(polls)}}number of polls completed (polling calls only){p_end}

{pstd}
Note: a polling call ({cmd:every()} with {cmd:times()}) always replaces the
data in memory, whether or not {cmd:clear} is specified.{p_end}
{synoptset 20 tabbed}{...}

{p2col 5 20 24 2: Macros}{p_end}
{synopt :{cmd:r(http)}}HTTP status code (of the last poll when polling){p_end}
{synopt :{cmd:r(url)}}the request URL{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}A public array of records (nested fields flatten automatically):{p_end}
{phang2}{cmd:. webapi get using "https://jsonplaceholder.typicode.com/users", clear}{p_end}

{pstd}A public health API (CDC NCHS leading causes of death, on Socrata), with
field filters and a header:{p_end}
{phang2}{cmd:. webapi get using "https://data.cdc.gov/resource/bi63-dtpu.json", ///}{p_end}
{phang2}{cmd:      params("year=2017|cause_name=All causes") headers("Accept:application/json") clear}{p_end}

{pstd}An authenticated API, with the token kept out of the script:{p_end}
{phang2}{cmd:. webapi get using "https://api.example.org/v1/series", ///}{p_end}
{phang2}{cmd:      bearer("$API_TOKEN") params("since=2026-01-01") records("data") clear}{p_end}

{pstd}Create a resource with {cmd:post}; the reply is the created object:{p_end}
{phang2}{cmd:. webapi post using "https://api.example.org/v1/items", ///}{p_end}
{phang2}{cmd:      body(`"{c -(}"name":"Texas","value":18.8{c )-}"') bearer("$API_TOKEN") records("") clear}{p_end}

{pstd}Poll a live endpoint on an interval; each snapshot stacks into a panel
keyed by {cmd:_poll} and {cmd:_polltime}:{p_end}
{phang2}{cmd:. webapi get using "https://api.example.org/v1/status", ///}{p_end}
{phang2}{cmd:      records("data") every(30) times(20) clear}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:A note on the dollar sign.}  Some APIs (Socrata's {cmd:$limit},
{cmd:$select}, {cmd:$where}) use parameters that begin with {cmd:$}, which
Stata reads as a global-macro reference.  Use plain field filters where you
can, or write the dollar sign as {cmd:`=char(36)'} inside {cmd:params()}.{p_end}

{pstd}
{bf:Privacy.}  Do not place secrets in URL query strings if a header will do,
and never commit a token to a public repository.{p_end}


{title:Author}

{pstd}
Eric A. Booth, Sr Researcher, Texas2036.org (eric.a.booth@gmail.com), 2026.
MIT-licensed.  A companion to {help googlesheets} and {help googlechart}.
