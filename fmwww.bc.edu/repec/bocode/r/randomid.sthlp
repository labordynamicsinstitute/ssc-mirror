{smcl}
{* *! version 1.2  june2013}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:Title}

{phang}
{bf:randomid} {hline 2} Creates a unique, random, alphanumeric identifier of chosen length

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:randomid}
{newvar}
{cmd:,} [length({help integer})]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth len:gth(integer)}}desired character length. (Default is 8.){p_end}
        
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:randomid} creates a new variable that uniquely identifies every observation in the dataset with random alphanumeric characters.



{marker remarks}{...}
{title:Remarks}

{pstd}
It's recommended to {help set seed} before this command for replicability.

{marker example}{...}
{title:Example}

{phang} {cmd:. randomid} myid, length(10) {p_end}

