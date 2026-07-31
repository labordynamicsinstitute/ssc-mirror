{smcl}
{* *! version 1.1.2 24may2026 Author: Eric A. Booth}{...}
{vieweralsosee "[D] import" "help import"}{...}
{vieweralsosee "[D] use" "help use"}{...}
{viewerjumpto "Syntax" "convertanything##syntax"}{...}
{viewerjumpto "Description" "convertanything##description"}{...}
{viewerjumpto "Options" "convertanything##options"}{...}
{viewerjumpto "Examples" "convertanything##examples"}{...}
{viewerjumpto "Author" "convertanything##author"}{...}
{title:Title}

{phang}
{bf:convertanything} {hline 2} Multi-format importer and converter for Stata. Detects file types and converts them to .dta format.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{bf:convertanything} {cmd:using} {it:path} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt sav:ing(dir)}}destination directory for .dta output{p_end}
{synopt:{opt recur:sive}}recurse into subdirectories; mirrors tree into {opt saving()}{p_end}
{synopt:{opt skip(namelist)}}subdir names to skip when recursive (default: {cmd:_converted _archive}){p_end}
{synopt:{opt all:sheets}}export every Excel worksheet as a separate .dta{p_end}
{synopt:{opt replace}}overwrite existing .dta files{p_end}
{synopt:{opt clear}}clear memory before each import{p_end}
{synopt:{opt ex:tension(list)}}restrict to these extensions (e.g., {cmd:"csv xlsx"}){p_end}
{synopt:{opt ver:bose}}show per-file progress{p_end}
{synopt:{opt comp:ress}}compress every converted dataset{p_end}
{synopt:{opt clean:names}}lowercase + Stata-legal variable names{p_end}
{synopt:{opt destr:ing}}auto-destring with {cmd:ignore("$,%")} and {cmd:percent}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:convertanything} is a utility for Stata data ingestion that automatically determines the correct 
command ({cmd:import excel}, {cmd:import delimited}, {cmd:use}, etc.) based on the file extension.

{pstd}
It includes "bulletproof" features to ensure messy raw data are converted into clean, optimized
Stata datasets.  Paths with spaces (e.g., Google Drive's "Shared drives/Data and Research Team") are handled safely throughout.

{pstd}
When {opt recursive} and {opt saving()} are both specified, the source directory tree is
{it:mirrored} into the destination: {cmd:src/2019/file.xls} → {cmd:saving/2019/file.dta}.
Without {opt saving()}, converted files are written next to their source.
Subdirectories named in {opt skip()} are not entered (default protects {cmd:_converted} and
{cmd:_archive} from re-processing or infinite recursion).


{marker options}{...}
{title:Options}

{phang}
{opt saving(path)} specifies the destination folder. If omitted, converted files are saved in the same directory as the source files.

{phang}
{opt recursive} triggers a deep search of subdirectories.

{phang}
{opt allsheets} is specific to {bf:.xls} and {bf:.xlsx} files. It saves each worksheet as {it:filename_sheetname.dta}.

{phang}
{opt compress} applies Stata's {help compress} command to every dataset before saving.

{phang}
{opt cleannames} ensures all variable names are lowercase and pass Stata's naming conventions.

{phang}
{opt destring} runs {help destring} with {cmd:ignore("$,%")} and {cmd:percent} options.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic file conversion with cleaning}

{phang2}{cmd:. convertanything using "mydata.csv", replace clear cleannames destring compress}{p_end}

{pstd}
{bf:Example 2: Pass 0 bulk-convert for a datashare project (standard pattern)}

{phang2}{cmd:. dswipe "${converted}"}{p_end}
{phang2}{cmd:. convertanything using "${raw}", recursive saving("${converted}") ///}{p_end}
{phang2}{cmd:      skip("_converted _archive") allsheets cleannames destring compress clear replace}{p_end}

{pstd}
{bf:Example 3: Batch convert a folder, flat output}

{phang2}{cmd:. convertanything using "C:/Data/Comptroller/", extension(csv) saving("C:/Stata_Data/") replace clear}{p_end}

{pstd}
{bf:Example 4: Recursive deep-clean with verbose output}

{phang2}{cmd:. convertanything using "Downloads/Raw_Data/", recursive verbose replace clear compress destring}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Eric A. Booth{break}
Texas 2036{break}
Email: {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{break}
GitHub: {browse "https://www.github.com/ericabooth":www.github.com/ericabooth}
{p_end}
