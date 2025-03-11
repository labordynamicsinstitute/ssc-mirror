{smcl}
{* *! version 0.0.1 mar 09 2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax"          "cache##syntax"}{...}
{viewerjumpto "Description"     "cache##description"}{...}
{viewerjumpto "Subcommands"     "cache##subcommands"}{...}
{viewerjumpto "Options"         "cache##options"}{...}
{viewerjumpto "Remarks"         "cache##remarks"}{...}
{viewerjumpto "Examples"        "cache##examples"}{...}
{viewerjumpto "Stored results"  "cache##returns"}{...}
{viewerjumpto "Authors"         "cache##authors"}{...}
{viewerjumpto "Contact"         "cache##contact"}{...}
{viewerjumpto "How to cite"     "cache##howtocite"}{...}
{cmd:cache} {hline 2} A program to cache all other Stata commands
{right:{browse "https://github.com/randrescastaneda/cache/"}}

{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:cache} 
           [{it:{help cache##sbc_table:subcommand}}]{cmd:,}
           [{it:{help cache##opt_table:options}}]
		   [{cmd::} {help cache##command:{it:command}}]


{marker sbc_table}{...}
{synoptset 12 tabbed}{...}
{synopthdr:Subcommand}
{synoptline}
{synopt :{opt clean}}Cleans all previously cached commands and any saved elements.{p_end}
{synopt :{opt list}}Lists all currently cached commands{p_end}
{synoptline}
{pstd}

{marker opt_table}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt dir(string)}}Specifies the directory where cached contents of commands 
  will be saved to be restored later; default is {cmd:dir(_cache)}{p_end}
{synopt :{opt project(string)}}Specifies a sub-directory within {cmd:dir} 
  if further organisation of cached commands is desired{p_end}
{synopt :{opt prefix(string)}}Defines a prefix for all saved elements of a command; 
  default is _ch{p_end}
{synopt :{opt nodata}}Does not cache data if changes occur in data{p_end}
{synopt :{opt datacheck(string)}}Allows for data on disk to be checked to ensure command uniqueness{p_end}
{synopt :{opt framecheck(string)}}Allows for additional frames to be checked to ensure command uniqueness{p_end}
{synopt :{opt clear}}Allows command to proceed even if this saves over data currently in memory{p_end}
{synopt :{opt hidden}}Does not return hidden elements as visible stored results{p_end}
{synopt :{opt replace}}Re-runs command and saves over previously cached version{p_end}
{synopt :{opt keep:all}}Does not clear previous ereturn and sreturn lists, permitting future use{p_end}
{synoptline}
{p2colreset}{...}
{marker command}{...}
{p 4 6 2}
{it: command} is any native or user written command available in Stata.



{marker description}{...}
{title:Description}

{pstd}
The {cmd:cache} command allows for all output and returned elements of any
commands to be saved (cached), and reloaded in the future without re-running the 
command. When {cmd:cache} is used, it will check if the indicated command has been 
previously issued  and cached by the user, and if so reload all elements returned 
by the command, along  with command output, without re-running the command itself. 
Otherwise, if no previously cached result for the command exists, 
{cmd:cache} will run the command, and cache all output and returns for future uses.

{pstd}
{cmd:cache} is useful if slow or resource-intensive commands are run more than once, 
as after the first time they are run all output can be simply accessed from the 
previously saved version, saving on all processing time. {cmd:cache} works with all valid 
Stata commands and is issued as a {help prefix} before the desired command.

{pstd}
{cmd:cache} stores all command output for the future, or loads all elements returned 
or otherwise altered by the command including (where relevant): elements accessible after
the command in the ereturn, sreturn or return lists; graphical output; any alterations 
to data (unless {it:nodata} is specified); any alterations to {help frames} 
(unless {it:nodata} is specified).


{marker remarks}{...}
{title:Remarks}

{pstd}
One of either

{phang2}
{cmd:cache} [{cmd:,} {it:{help cache##opt_table:options}}] {cmd::} {help cache##command:{it:command}}

{pstd}
or

{phang2}
{cmd:cache} {it:{help cache##sbc_table:subcommand}} [{cmd:,} {it:{help cache##opt_table:options}}]

{pstd}
should be issued. The use of {help cache##sbc_table:subcommand}s is for general management 
of {cmd:cache} and should not be combined with individual commands to be cached.  Otherwise
the standard usage of {cmd:cache}{cmd::} {help cache##command:{it:command}} will cache or 
load the output of  {help cache##command:{it:command}}.


{marker subcommands}{...}
{title:Subcommands}


{phang}
{opt clean} Indicates that all contents of cached commands should be permanently removed from
the cache directory.  Typing {cmd:cache clean} will result in a confirmation message to which
the user must respond "y" if all contents of the cache directory should be cleared.  This option
should be used with care, as any contents of the cache directory will be permanently deleted.
To avoid issues with potential loss of important information, the {opt clean} sub-command does
NOT work recursively.  For example, if various projects are located within a main cache subfolder,
these must be cleaned individually by using the {opt dir()} and/or {opt project()} options.
 
{phang}
{opt list} Lists the full history of cached commands available for re-loading in the current
cache directory.  



{marker options}{...}
{title:Options}


{phang}
{opt dir(string)} Specifies the directory where cached command outputs will be saved 
for later retrieval. If not specified, the default location is a _cache subdirectory 
within the current working directory. To set a different default cache directory, 
define the path in the global macro {opt cache_dir} within your 
{help profile:profile.do} file or at the beginning of your do-file. The  _cache 
subdirectory will be created inside the directory specified in global 
{opt cache_dir}.

 
{phang}
{opt project(string)} Allows for sub-folders within the cache directory if further control of 
cached contents is desired.  This permits cached commands to be stored in groups of related 
commands.

{phang}
{opt prefix(string)} By default, all cached contents of a command will be saved with a prefix 
of _ch followed by the hash of the command as typed, along with the data signature of data in 
memory. The prefix option will replace _ch with the indicated string

{phang}
{opt nodata} If nodata is specified, {cmd:cache} will save all command returns, but will not 
save data if any changes in data are detected.  This may be desired if data in memory is
very large, and the command issued makes innocuous changes to the data that are not required
in the future.  Note that by default, any regression-based commands will save resulting data,
given that a variable is generated to store information about the estimation sample via
e(sample).  Thus, care should be taken if {opt nodata} is used with regression-based commands,
as the use of e(sample) will not be available.

{pmore} This option should be used with care, as in future calls to {cmd:cache} all command
output and results will be returned, but updates to data will not be produced.

{phang}
{opt datacheck(string)} By default {cmd:cache} tests data in memory and the command syntax,
and determines that a command has been cached if data in memory is identical and the command as
typed is identical.  However, at times external data files may be called which have identical names,
but altered contents.  In cases such as this, {opt datacheck} can be used to indicate that {cmd:cache}
should also ensure that any external data files necessary for the command are also included when 
generating a unique command identifier, or checking whether an identical command has previously
been cached.  As many data files can be indicated in {opt datacheck} as desired, and the name of each
Stata data file should simply be separated by white space.

{phang}
{opt framecheck(string)} Allows for identical behaviour as in {opt datacheck}, but now by testing
the precise contents of any frames indicated in {opt framecheck}.  As many frames can be indicated 
in {opt framecheck} as desired, and the name of each frame should simply be separated by white space.

{phang}
{opt clear} Allows command implementation to proceed even if this would unsaved changes in 
data (similar, for example, to {it: use, clear})

{phang}
{opt hidden} By default {cmd:cache} returns all stored results, including hidden results as standard 
stored results, and so hidden results will be visible following {cmd: cache}.  If you would like hidden  
elements to stay hidden, the {opt hidden} option should be specified.
 See
{mansection P returnRemarksandexamplesUsinghiddenandhistoricalstoredresults:{it:Using hidden and historical stored results}}
and
{mansection P returnRemarksandexamplesProgramminghiddenandhistoricalstoredresults:{it:Programming hidden and historical stored results}}
under {it:Remarks and examples} of {bf:[P] return} for more information. 

{phang}
{opt replace} Forces {cmd:cache} to re-run the command and re-cache results, even if a 
previously cached version of command output has been found. Such an example may be useful 
if commands are re-issued and command behaviour has changed.

{phang}
{opt keepall} Indicates that elements stored by previous commands in e(return) and s(return)
lists should not be cleared prior to invoking the command requested with {cmd:cache}.
By definition, {cmd:cache} will store all elements returned in ereturn, sreturn or return lists
following an issued command.  The default usage is to clear ereturn, sreturn and return
lists prior to issuing the requested command, so that only elements from the issued command
will be returned in future calls to the command from cache.  However, this implies that
elements of return lists not used by a specific command will not hold over from previous
commands, for example if an r-class command is issued, results from previous e-class commands
will be cleared to avoid being saved by {cmd:cache}.  If such behaviour is undesired, 
the {opt keepall} option should be used so that any previous return lists are maintained in
memory.


{marker examples}{...}
{title:Examples}

{pstd}
The examples below illustrate the idea of {cmd:cache}.  These are based on 
Stata's auto dataset.

{ul:Basic examples}

{phang}
Load Stata's auto dataset, and cache a command

{phang2}
{cmd:. sysuse auto}{p_end}
{phang2}
{cmd:. cache: regress price weight length}

{phang}
Now, inspect return list and ereturn list to see elements returned by the {help regress} command

{phang2}
{cmd:. return list}{p_end}
{phang2}
{cmd:. ereturn list}

{phang}
Now, issue alternative command so that return lists will be altered

{phang2}
{cmd:. cache: sum price weight length}

{phang}
Finally, call cache again, and confirm that cache has reloaded all original command output 
without re-running the command:


{phang2}
{cmd:. cache: regress price weight length}{p_end}
{phang2}
{cmd:. return list}

{txt}                 ({stata "cache_examples cache_ex01":click to run})

{ul:An example documenting time savings}

{phang}
Load Stata's auto dataset, set a timer, cache a command which will take considerable time to run
and then turn off the timer

{phang2}
{cmd:. sysuse auto}{p_end}
{phang2}
{cmd:. timer on 1}{p_end}
{phang2}
{cmd:. cache: bootstrap, reps(5000) dots(100): reg price mpg}{p_end}
{phang2}
{cmd:. timer off 1}

{phang}
Now, set a second timer and run the command from the cached version:

{phang2}
{cmd:. timer on 2}{p_end}
{phang2}
{cmd:. cache: bootstrap, reps(5000) dots(100): reg price mpg}{p_end}
{phang2}
{cmd:. timer off 2}{p_end}
{phang2}
{cmd:. timer list}

{txt}                 ({stata "cache_examples cache_ex02":click to run})

{marker return}{...}
{title:Stored results}{p 50 20 2}{p_end}

{pstd}
{cmd:cache} is itself an {helpb return:rclass} command, and along with all
elements returned from the requested command, additionally stores the 
following in {cmd: r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:r(call_hash)}} The {help mf_hash1:hash} of the command as issued by the user{p_end}
{synopt:{cmd:r(datasignature)}} The {help datasignature} of the data prior to command being invoked{p_end}
{synopt:{cmd:r(cmd_hash)}} The {help mf_hash1:hash} used by cache to uniquely identify the command{p_end}
{p2colreset}{...}


{marker authors}{...}
{title:Authors}

{p 4 4 4}R.Andres Castaneda, Data Group, Department of Development Economics, The World Bank{p_end}
{p 6 6 4}Email: {browse "mailto: acastanedaa@worldbank.org":  acastanedaa@worldbank.org}{p_end}
{p 6 6 4}GitHub:{browse "https://github.com/randrescastaneda": randrescastaneda }{p_end}

{p 4 4 4}Damian Clarke, Department of Economics, University of Chile & University of Exeter{p_end}
{p 6 6 4}Email: {browse "mailto: dclarke4@worldbank.org":  dclarke4@worldbank.org}{p_end}
{p 6 6 4}Email: {browse "mailto: dclarke@fen.uchile.cl":  dclarke@fen.uchile.cl}{p_end}
{p 6 6 4}GitHub:{browse "https://github.com/damiancclarke": damiancclarke }{p_end}


{marker contact}{...}
{title:Contact}

{pstd}
Any comments, suggestions, or bugs can be reported in the
{browse "https://github.com/randrescastaneda/cache/issues":GitHub issues page}.

{marker development}{...}
{title:Development}

{pstd}
The latest stable version of the {cmd: cache} package is always available in the most recent release of the main branch of the 
{browse "https://github.com/randrescastaneda/cache":randrescastaneda/cache} GitHub repository. You can install it using the 
{browse "https://github.com/haghish/github":github} Stata package by 
{browse "https://github.com/haghish":E. F. Haghish}.

{phang2}
{cmd:. net install github, from("https://haghish.github.io/github/")}{p_end}
{phang2}
{cmd:. github install randrescastaneda/cache}{p_end}

{pstd}
Pre-release versions are also available in the GitHub repository. These versions include new features still in testing and should be used at the user's discretion.


{marker howtocite}{...}
{title:Thanks for citing this Stata command as follows}

{p 4 8 2}Castaneda, R.Andres and Damian Clarke. (2025)
"cache: Stata Module to to cache all other Stata commands"
				(version 0.0.1). 
https://github.com/randrescastaneda/cache/ {p_end}
