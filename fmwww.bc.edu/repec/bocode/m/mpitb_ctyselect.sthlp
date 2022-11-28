{smcl}
{* *! version 0.1.1  9 Jan 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_ctyselect##syntax"}{...}
{viewerjumpto "Description" "mpitb_ctyselect##description"}{...}
{viewerjumpto "Options" "mpitb_ctyselect##options"}{...}
{viewerjumpto "Examples" "mpitb_ctyselect##examples"}{...}
{viewerjumpto "Stored results" "mpitb_ctyselect##storedresults"}{...}
{p2colset 1 20 22 2}{...}
{p2col:{bf:mpitb ctyselect} {hline 2}} selects countries using the reference sheet{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb ctyselect} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt s:elect(ctylist)}}list of countries{p_end}
{synopt:{opt r:exp(regex)}}regular expression{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb ctyselect} selects one or countries from the reference sheet and returns 
their country codes in {cmd:r()}. {varname} is required and directs {cmd:ctyselect} 
to the variable containing the country codes.{p_end}

{pstd}
{cmd:ctyselect} can be used to conveniently control loops for estimations or other 
steps in the production process. Called without any option, {cmd:ctyselect} returns 
all country codes found in the reference sheet.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt s:elect(ctylist)} allows to manually select country codes. Technically, it 
simply refers to values of {varname}, which may be {it:string} or 
{it:numeric}.{p_end}

{phang}
{opt r:exp(regex)} allows to select country codes based on regular expressions 
applied to {varname}.{p_end}

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}1. Selecting all countries (as covered by the reference sheet) frame. Let the 
variable {it:ccty} contain the country code{p_end}

{phang2}{cmd:use refsheet , clear}

{phang2}{cmd:mpitb ctyselect ccty}

    {hline}
{pstd}2. Select specific countries {p_end}

{phang2}{cmd:mpitb ctyselect ccty , s(BGD IND UGA)}

    {hline}
{pstd}3. Select all countries with a country code starting with "I"{p_end}

{phang2}{cmd:mpitb ctyselect ccty ,  r(^[I])}

    {hline}

{marker storedresults}{...}
{title:Stored Results}

{pstd}
{cmd:ctyselect} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2:Macros}{p_end}
{synopt :{cmd:r(ctylist)}}list of countries{p_end}
{synopt :{cmd:r(Nctylist)}}number of  countries{p_end}
{p2colreset}{...}
