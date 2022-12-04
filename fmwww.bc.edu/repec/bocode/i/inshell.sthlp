{smcl}
{* *! version 2.7  29 Nov 2022}{...}
{viewerjumpto "Syntax" "inshell##syntax"}{...}
{viewerjumpto "Description" "inshell##description"}{...}
{viewerjumpto "Remarks" "inshell##remarks"}{...}
{viewerjumpto "Notation" "inshell##notation"}{...}
{viewerjumpto "Environment" "inshell##env"}{...}
{viewerjumpto "Microsoft PowerShell" "inshell##pwsh"}{...}
{viewerjumpto "Technical notes" "inshell##tech"}{...}
{viewerjumpto "Suggestions" "inshell##suggestions"}{...}
{viewerjumpto "Changing directory" "inshell##cd"}{...}
{viewerjumpto "Return code" "inshell##returncode"}{...}
{viewerjumpto "S_SHELL" "inshell##sshell"}{...}
{viewerjumpto "Options" "inshell##options"}{...}
{viewerjumpto "Diagnostics" "inshell##diagnostics"}{...}
{viewerjumpto "Saved results" "inshell##savedresults"}{...}
{vieweralsosee "[D] shell" "help shell"}{...}
{vieweralsosee "[D] cd" "help cd"}{...}
{vieweralsosee "[D] pwd" "help pwd"}{...}
{vieweralsosee "[D] macro" "help macro"}{...}
{vieweralsosee "[D] quotes" "help quotes"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "ashell" "help ashell"}{...}
{title:Title}

{phang}
{cmd:inshell} {hline 2} An enhanced multi-platform shell wrapper that will send commands to the operating system's shell while capturing and printing their standard output, standard error, and native shell return codes.{p_end}

{marker syntax}{...}
{title:Syntax}
    {p 8 12 2}{cmd:inshell } {it:   operating_system_command} [{it:cmd_args}]{bind:                (1)}{p_end}
    {p 8 12 2}{cmd:inshell } {it:   /absolute/path/to/program} [{it:program_args}]{bind:           (2)}{p_end}
    {p 8 12 2}{cmd:inshell } {it: . /path/to/script/file} [{it:script_args}]{bind:               (3)}{p_end}
    {p 8 12 2}{cmd:inshell }{{cmd:cd}{c |}{cmd:chdir}} {it: [/directory/to/change/to]}{bind:               (4)}{p_end}

{marker description}{...}
{title:Description}

{p 6 4 3}
{cmd:inshell} is a shell wrapper that is designed to enhance both the interactive and the scripted use of the shell in Stata.
It can execute commands or scripts via the operating system's shell and will display the {it:{res:standard output}} in the {cmd:Results} window while capturing it into a series of local macros.
In the event of an error, it will also capture and display both the {it:{err:standard error}} and the shell's native return code.
Additionally, it contains an enhanced wrapper for {cmd:cd}. It runs on {bf:macOS}, {bf:Linux}, and {bf:Microsoft Windows Command} shells.
It also works with {bf:Microsoft PowerShell} on all operating systems, with some limitations.{p_end}

{marker remarks}{...}
{title:Remarks}

{p 6 4 3}
This help file and its examples are geared towards users of operating systems with Unix shells ({bf:macOS} and {bf:Linux}), but the same basic principles apply to those that use {bf:Microsoft Windows}.
These remarks also serve to detail advanced usage of Stata's existing {cmd:shell} command.{p_end}

{marker notation}{...}
{title:Notation}

{p 6 4 3}
It is important to note that commands sent directly to {cmd:inshell}, whether entered into the {cmd:Command} window or run as part of a do-file, will pass through Stata's command pre-processor before they are executed.

{p 6 4 3}
Because shell code uses the same dollar sign alphanumeric notation (and often the same bracing structure) for variable referencing that Stata uses for its own {cmd:global} macros,
and because all commands must pass through this pre-processor before they are executed, Stata will attempt to perform macro substitution upon each and every substring that could be a valid name for a Stata {cmd:global}.
This will happen regardless of whether commands are sent via {cmd:shell}, {cmd:inshell} or any other package.
Therefore if your code is intended to reference a variable within the shell's environment you will need to {it:escape} expressions of the form
{cmd:$var1} or {cmd:${var2}} to {cmd:\$var1} or {cmd:\${var2}}. For instance, to print the {bf:$PATH} variable on {bf:macOS} and {bf:Linux}:{p_end}

{p 8 8 2}
{cmd:. inshell echo \$PATH}{bind:        }{it:({stata inshell echo \$PATH:click to run})}{p_end}

{p 6 4 3}
In this case it is necessary to use the single backslash ({cmd:\}) to {it:escape} the dollar sign ({cmd:$}) otherwise Stata will look for a {cmd:global} macro named {cmd:PATH}.
If it does not exist, Stata will replace that part of the command with a zero-length string because the macro substitution will result in an empty value being passed to what Stata interprets as its own {cmd:global} variable.

{p 6 4 3}
However, any dollar signs ({cmd:$}) used for command substitution or in another setting {it:not} directly followed by a letter or an underscore ({cmd:_}) need {it:not} be escaped. To use command substitution:{p_end}

{p 8 8 2}
{cmd:. inshell echo $(date +%s) >> \${LOG_DIR}/logfile_$(date +%m%d%Y).log}{p_end}
{p 16 16 2}{it:or}{p_end}
{p 8 8 2}
{cmd:. inshell echo `date +%s` >> \${LOG_DIR}/logfile_`date +%m%d%Y`.log}{p_end}

{p 6 4 3}
Common shell parameters such as {cmd:$0} (the current shell), {cmd:$$} (the current shell's process ID), or {cmd:$?} (the previous command's return code) also need {it:not} be escaped.{p_end}

{p 6 4 3}
{cmd:local} macros also need not be escaped as they have a different structure {hline 2} formed between a back-tick ({cmd:`}) and a single apostrophe ({cmd:'})
{hline 2} than double back-tick command substitution, which is performed between two single back-ticks: ({cmd:`}){it: command }({cmd:`}).{p_end}

{p 6 4 3}
To use a Stata {cmd:local} or {cmd:global} macro, leave it {it:un-escaped}:{p_end}

{p 8 8 2}
{cmd:. global id{space 6}a5b7d9e4f1}{p_end}
{p 8 8 2}
{cmd:. local datetime $S_DATE $S_TIME}{p_end}
{p 8 8 2}
{cmd:. inshell echo id: $id{space 4}>> \${LOG_DIR}/results_${id}_`date +%m%d%Y`.log}{p_end}
{p 8 8 2}
{cmd:. inshell echo `datetime' >> \${LOG_DIR}/results_${id}_`date +%m%d%Y`.log}{p_end}

{p 6 4 3}
Note that in the example above, braces must be used around the {cmd:global} macro {cmd:id} as the underscore immediately following it would otherwise be included by Stata's macro parsing routine.{p_end}

{p 6 4 3}
{bf:Windows Command shell} uses double percent sign ({cmd:%}) notation which does not require escaping:{p_end}

{p 8 8 2}
{cmd:. inshell echo %PATH%}{bind:       ({bf:Windows Command shell})}{p_end}

{p 6 4 3}
As of the date of this printing, there are no other publicly available shell wrappers for {bf:Stata for Mac}, {bf:Stata for Linux},
or for users of {bf:Microsoft PowerShell} running on a {bf:Mac} or {bf:Linux} system that are able to access dollar sign alphanumeric notation shell variables.{p_end}

{marker env}{...}
{title:Environment}

{p 6 4 3}
Sourcing of shell configuration files to produce the shell's {browse "https://en.wikipedia.org/wiki/Environment_variable":environment} will differ across each Stata installation for several obvious reasons, however,
terminal-launched instances (also called {it:console} instances) of Stata will assemble their environments from a broader range of sources than those used by the GUI application.
This is because the Stata {cmd:Results} window in the GUI application does not support interactive functionality, unlike all modern terminal-emulators.
On {bf:macOS} using {bf:zsh} as the default shell, for instance, the {bf:.zshrc} configuration file is {it:not} sourced when using the GUI application,
but it will be sourced when using a console instance. In both cases {bf:.zshenv} is sourced.{p_end}

{p 6 4 3}
The user is advised to always check their {bf:$PATH} and other critical environment variables.
Any commands not found in the user's {bf:$PATH} will require {it:absolute paths} to function.
For instance, if the user wanted to use {bf:gsed}, the GNU version of the Unix stream editor {bf:sed}, even though the user may have installed the {bf:gsed} package to {it:/usr/local/bin},
for example, and the {bf:gsed} command functions as expected in the user's terminal or shell scripts, rather than using the {it:command} by name:{p_end}

{p 8 8 2}{cmd:. global pangram /// }{p_end}
{p 8 8 2}{cmd:.        "All questions asked by five watch experts amazed the judge."}{p_end}

{p 8 8 2}{cmd:. inshell echo "$pangram" | gsed -E 's/( .....[^a-z] ?)/\U\1/g'}{p_end}
{p 8 8 2}{error:{c TLC}{hline 34}{c TRC}{space 26}{c TLC}{hline 5}{c TRC}}{p_end}
{p 8 8 2}{error:{c |} zsh:1: command not found: gsed{space 3}{c |}{space 26}{c |} 127 {c |}}{p_end}
{p 8 8 2}{error:{c BLC} {it:stderr} {hline 26}{c BRC}{space 26}{c BLC}{hline 1} {it:rc} {c BRC}}{p_end}

{p 6 4 3}
use the {it:absolute path} of the command{p_end}

{p 8 8 4}{cmd:. inshell echo "$pangram" | /usr/local/bin/gsed -E 's/( .....[^a-z] ?)/\U\1/g'}{p_end}
{p 8 8 2}{result: All questions ASKED by five WATCH experts amazed the JUDGE.}{p_end}

{p 6 4 3}
If the desired executable is found along the paths listed using:{p_end}

{p 8 8 2}
{cmd:. inshell echo \$PATH }{p_end}

{p 16 16 2}
or {it:command} is successfully located by running{p_end}

{p 8 8 2}
{cmd:. inshell which} {it:command}{p_end}

{p 6 4 3}
then the function call will proceed. In this particular case {bf:echo} is a shell built-in and therefore has no direct path to the executable.
{cmd:inshell} allows the user to bypass this limitation with a {cmd:global} macro option that is discussed later in this manual ({help inshell##options:see Options}).{p_end}

{p 6 4 3}
Each time {cmd:inshell} (or {cmd:shell}) is invoked a new shell session is created, the line of commands sent to {cmd:inshell} is executed, and the session is then terminated.
Therefore, any changes made to the environment do not persist.
This limitation means that if the user would like to set a variable's value and then issue subsequent commands based on that variable, the user cannot do so with the following:{p_end}

{p 8 8 2}
{cmd:. inshell export var=123}{p_end}
{p 8 8 2}
{cmd:. inshell echo \$var}{p_end}

{p 6 4 3}
as the value of {bf:var} will have been lost before the second line is executed.
However, if the user wants to set or export variables to use immediately, they must issue all relevant commands on the same line, with each line of commands separated by semi-colons ({cmd:;}):{p_end}

{p 8 8 2}
{cmd:. inshell export var=123 ; echo \$var}{bind:             }{it:({stata inshell export var=123 ; echo \$var:click to run})}{p_end}

{p 8 8 2}{res: 123}{p_end}
{p 16 16 2}
for example, or{p_end}

{p 8 8 2}
{cmd:. global myvar 123}{p_end}
{p 8 8 2}
{cmd:. inshell export var=$myvar ; echo \$var}{p_end}

{p 8 8 2}
{res:123}{p_end}

{p 6 4 3}
In this fashion Stata macros can be exported to external scripts.
{cmd:inshell} contains two ancillary files to demonstrate this usage which are both {browse "https://en.wikipedia.org/wiki/POSIX":POSIX}-compatible shell scripts
and which must be installed separately from {cmd:inshell} itself into the {cmd:PERSONAL} system directory.
To install these files {it:({stata `"cd `c(sysdir_personal)'"' :click here})} and then {it:({stata `"if "`c(pwd)'`c(dirsep)'" == "`c(sysdir_personal)'" net get inshell"' :click here})}.{p_end}

{p 6 4 3}
Using the included shell script named {cmd:inshell_example1.sh}, the contents of which are:{p_end}

{space 8}{hline 18} {it:example shell script content} {hline 18}
{* example_start - file}{...}
{space 8}{text}{...}
{it:#!/bin/sh}
{cmd}{...}
{space 8}echo $var
{space 8}echo $((var*2))
{space 8}var2=$((var/4))
{space 8}echo $var2
{space 8}var3=$(date -r 119731017 +%Y-%m-%d)
{space 8}echo $var3
{text}{...}
{* example_end}{...}
{space 8}{hline 66}

{p 6 4 3}
the user could code:{p_end}

{p 8 8 2}
{cmd:. global myvar=65536}{p_end}
{p 8 8 2}
{cmd:. inshell export var=$myvar ; . "`: sysdir PERSONAL'"/inshell_example1.sh}{p_end}

{p 8 8 2}
{it:({stata `"inshell export var=65536 ; . "`: sysdir PERSONAL'"inshell_example1.sh"' :click to run})}{p_end}

{res}{...}
{p 8 8 2}65536{p_end}
{p 8 8 2}131072{p_end}
{p 8 8 2}16384{p_end}
{p 8 8 2}1973-10-17{p_end}
{text}{...}

{p 6 4 3}
Also included is another shell script named {cmd:inshell_example2.sh} ({stata `"view `: sysdir PERSONAL'/inshell_example2.sh"':{it:click to view}})
which is intended as a more sophisticated demonstration of shell scripting using {cmd:inshell}. It can be run using the following code:{p_end}

{p 8 8 2}
{cmd:. inshell export var1=123; export var2=\$var1 ; export var3=$((var1*var2)); export flavor=`= lower(c(edition_real))' ; export os=`c(os)' ; . "`: sysdir PERSONAL'/inshell_example2.sh"}{p_end}

{p 8 8 2}
({stata `"inshell export var1=123; export var2=\$var1 ; export var3=$((var1*var2)); export flavor=`= lower(c(edition_real))' ; export os=`c(os)' ; . "`: sysdir PERSONAL'/inshell_example2.sh""':{it:click to run}}){p_end}

{p 6 4 3}
Note that the termination of the shell session at the end of every {cmd:inshell} command implies that there is a syntax in use {ul:at all times}, namely:{p_end}

{p 8 12 2}{cmd:inshell } {it: cmd1 [; cmd2] [; cmd3]}{cmd: ; exit}{p_end}

{p 6 4 3}
The {cmd:exit} in the command above is neither of the Stata commands {helpb exit:[R] exit} nor {helpb exit_program:[P] exit}, but rather the shell's native {bf:exit} command.{p_end}

{marker pwsh}{...}
{title:Microsoft PowerShell}

{p 6 4 2}{cmd:inshell} will work with {bf:Microsoft PowerShell} but has not been thoroughly tested on {bf:Microsoft Windows}. The following are some considerations regarding its use.{p_end}

{p 6 4 2}When using {bf:PowerShell} on {bf:macOS} in {it:inline} mode, which is to say issuing commands to PowerShell when it is {ul:not} the default shell,
single quotes ({cmd:'}) are required to surround all dollar sign alphanumeric notation expressions, which as in all cases must also be escaped with a backslash ({cmd:\}).
For instance, to print the {bf:$PATH} variable:{p_end}

{p 8 8 2}{cmd}{...}
. inshell /usr/local/bin/pwsh -Command '\$ENV:PATH'{p_end}

{p 8 8 6}{res}{...}
/usr/local/microsoft/powershell/7:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Stata/utilities/java/macosx-x64/zulu-jdk17.0.4/bin{p_end}

{p 6 4 2}{txt}{...}
However, if {bf:PowerShell} is your {it:default shell} (set either by {cmd:global} shell macro {cmd:S_SHELL} or as your system's default shell) they are not required (nor is {bf:-Command} nor the path to the {bf:PowerShell} executable).
See {help inshell##sshell:S_SHELL global macro} for more details.{p_end}

{p 8 8 2}{cmd}{...}
. inshell \$ENV:PATH{p_end}

{p 8 8 6}{res}{...}
/usr/local/microsoft/powershell/7:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin{p_end}

{p 6 4 2}{txt}{...}
Some other special characters that do not form part of a single expression will often need to be surrounded by single quotes. For instance, to print the {bf:$PATH} variable and split it by parsing on a colon ({cmd::}):{p_end}

{p 8 8 2}{cmd}{...}
. inshell /usr/local/bin/pwsh -Command '\$ENV:PSModulePath' -split \':\'{p_end}
{p 16 16 2}{txt}{...}
{it:or}{p_end}
{p 8 8 2}{cmd}{...}
. inshell /usr/local/bin/pwsh -Command '[System.Environment]::GetEnvironmentVariable('\'PATH\'')' -split \':\'

{p 8 8 6}{res}{...}
/usr/local/microsoft/powershell/7{break}
/usr/bin{break}
/bin{break}
/usr/sbin{break}
/sbin{break}
/Applications/Stata/utilities/java/macosx-x64/zulu-jdk17.0.4/bin
{p_end}

{p 6 4 2}{txt}{...}
In the example above, the colon must be surrounded by single quotes, each of which must be escaped with a backslash.{p_end}

{p 6 4 2}{txt}{...}
The following are some examples on how to find the version of {bf:PowerShell} that is installed.{p_end}

{p 8 8 2}{cmd}{...}. inshell /usr/local/bin/pwsh -Command '(Get-Host).Version'{p_end}
{p 8 8 2}{cmd}{...}. inshell /usr/local/bin/pwsh -Command '\$host.Version'{p_end}
{p 8 8 2}{cmd}{...}. inshell /usr/local/bin/pwsh -Command '\$PSVersionTable.PSVersion'{p_end}

{p 6 4 2}{txt}{...}
After each of these commands the version number can be obtained like so:{p_end}

{p 8 8 2}{cmd:. display /// }{p_end}
{p 12 12 2}{cmd:"you are using version `:word 1 of `r(no3)''.`:word 2 of `r(no3)''.`:word 3 of `r(no3)'' of Microsoft PowerShell"}{p_end}

{p 8 8 6}{res}{...}
you are using version 7.2.6 of Microsoft PowerShell{p_end}

{p 6 4 2}{txt}{...}
Standalone pipes and Math class expressions also require single-quoting, like so:{p_end}

{p 8 8 2}{cmd}{...}
. inshell /usr/local/bin/pwsh -Command Get-Item env:TMPDIR '|' Select-Object -ExpandProperty Value{p_end}

{p 8 8 6}{res}{...}
{ccl tmpdir}{p_end}

{p 8 8 2}{cmd}{...}
. global result 429981696{p_end}
{p 8 8 2}{cmd}{...}
. inshell /usr/local/bin/pwsh -Command '[math]::Sqrt($result)'{p_end}

{p 8 8 6}{res}{...}
20736{p_end}

{p 6 4 2}{txt}{...}
There are likely numerous other potential command structures which also require quoting or escaping, so the user is advised to carefully test each and every {cmd:inshell} command.{p_end}

{p 6 4 2}{txt}{...}
Note that when using {bf:PowerShell} the return code will only reflect the {bf:True} or {bf:False} condition of the success of the last operation, which is represented as a boolean of {bf:0} or {bf:1}, respectively.{p_end}

{marker tech}{...}
{title:Technical Notes}

{p 6 4 2}{txt}{...}
The output from a shell command can contain control directives called {browse "https://en.wikipedia.org/wiki/ANSI_escape_code":ANSI escape sequences}
that are used to specify formatting components such as the color or font styling of text as well as special types of whitespace.{p_end}

{p 6 4 2}{txt}{...}
Because the Stata interface is not completely compatible with these sequences, the resulting text that is captured may be garbled or unprintable.
For instance, if {cmd:shell} were used to execute one of the {bf:PowerShell} commands found above that are used to obtain versioning information:{p_end}

{p 8 8 2}
{cmd:. shell /usr/local/bin/pwsh -Command '\$PSVersionTable.PSVersion'}{p_end}

{p 6 4 2}{txt}{...}
the result may look something like this:{p_end}

{p 8 8 6}{res:[32;1mMajor  Minor  Patch  PreReleaseLabel BuildLabel[0m}{p_end}
{p 8 8 6}{res:[32;1m-----  -----  -----  --------------- ----------[0m}{p_end}
{p 8 8 6}{res:7{space 6}2{space 6}6}{p_end}

{p 6 4 2}{txt}{...}
The cryptographic sequences at the beginning and end of the first two lines are in this case meant to display the output in bold and green font and should not be visible as text.{p_end}

{p 6 4 2}{txt}{...}
Stata does not process these directives as they are intended to be and instead will simply display the coding of the control sequences themselves, however even some of these cannot be printed visibly.
If these control sequences are not removed they will distort the ways in which the information is captured, copied, saved or displayed.{p_end}

{p 6 4 2}{txt}{...}
The {it:actual} output from the command above {it:does} contain invisible characters,
and if the user tries to select the text displayed in the {cmd:Results} window after running the above {cmd:shell} command they may witness the text visibly shift.
Because these control sequences can cause such pervasive aberrations {hline 2} in fact too many of them can garble output from subsequent unrelated commands, and can even crash Stata itself {hline 2}
{cmd:inshell} removes this formatting from all {res}{it:standard output}{txt} and {err}{it:standard error}{txt} results. The same command sent through {cmd:inshell} would look like this:{p_end}

{p 8 8 2}
{cmd:. inshell /usr/local/bin/pwsh -Command '\$PSVersionTable.PSVersion'}{p_end}

{p 8 8 6}{res:Major  Minor  Patch  PreReleaseLabel BuildLabel}{p_end}
{p 8 8 6}{res:-----  -----  -----  --------------- ----------}{p_end}
{p 8 8 6}{res:7{space 6}2{space 6}6}{p_end}

{p 6 4 2}{txt}{...}
Users should also be aware that lines of {cmd:inshell} commands should not contain any Stata comments as they will simply be included as part of the command sent to {cmd:inshell}.

{p 6 4 2}{txt}{...}
It is the author's goal to make {cmd:inshell} compatible with a wide variety of shells and operating systems.
At present (on {bf:macOS} and {bf:Linux}) it has been tested with {bf:bash}, {bf:dash}, {bf:ksh}, {bf:ksh93}, {bf:mksh}, {bf:oil/osh}, {bf:tcsh}, {bf:yash}, and {bf:zsh},
as well as {bf:Microsoft PowerShell}, and should also work with {bf:ash}, {bf:csh}, and {bf:sh}.
It is not fully compatible with {bf:fish}, the "friendly interactive shell."
Although it has not been extensively tested on {bf:Microsoft Windows} it will work with both {bf:Windows Command} shell {bf:(cmd.exe)} and {bf:Microsoft PowerShell}.{p_end}

{marker suggestions}{...}
{title:Suggestions}

{p 6 4 3}
Because of the various limitations noted above, the user is advised to store their commands in an external script and use {cmd:inshell} to execute that script as in {help inshell##syntax:syntax 3}.
Note that the script file need not be executable in order to function.{p_end}

{p 6 4 3}
When Stata is launched from a terminal emulator, it naturally exists at a level closer to the operating system,
and that fact is reflected in the relaxed requirements with regards to quoting and escaping as well as the sourcing of a wider range of configuration files.{p_end}

{p 6 4 3}
As noted above Stata's implementation of the shell has no interactive abilities and the information printed to the {cmd:Results} window may contain garbled or otherwise unprintable text.
This is because the shell is accessed through Stata's limited shell parser, and therefore the user should explicitly avoid any commands that involve any interactive or complicated display functionality.
{cmd:inshell} attempts to remove any hidden formatting directives that exist as ANSI escape sequences so that the output is clean and legible ({help inshell##tech:see Technical Notes}).{p_end}

{marker cd}{...}
{title:Changing directory}

{p 6 4 3}
{cmd:inshell} also contains a wrapper for {cmd:cd}, allowing the user to change directories while still using {cmd:inshell}.
It is necessary to use a wrapper program to do so because {bf:cd} operating system commands sent through Stata's {cmd:shell} command will not function.
It confirms the existence of the specified directory beforehand and it even also allows the use of the out-of-date command {cmd:chdir}.
Most importantly, it allows changing directory to paths referenced by variables set within the user's environment.
As in all cases, these variables must be referenced using escaped dollar signs ({cmd:\$}) ({help inshell##notation:see Notation}).
For example, if the user wanted to {cmd:cd} to the temporary directory, often set as the {bf:$TMPDIR} variable:{p_end}

{p 8 8 2}
{cmd:. inshell cd \$TMPDIR}{p_end}
{p 8 8 2}
{res:{ccl tmpdir}}{p_end}

{p 6 4 3}
{cmd:inshell} also respects the differences between the intended behavior of a {cmd:cd} command {it:without arguments} on {bf:macOS/Linux} and {bf:Microsoft Windows}.
Therefore using {cmd:inshell cd} or even {cmd:inshell chdir} on {bf:Windows} will simply display the present working directory, and is equivalent to {cmd:inshell pwd}.{p_end}

{p 6 4 3}
Users should note that when using an alternative shell set by {cmd:global} macro {cmd:S_SHELL},
changing directories to paths specified by shell variables may not function because the alternative shell's configuration files may not be sourced.{p_end}

{marker returncode}{...}
{title:Return code}

{p 6 4 3}
The shell's return code is a numeric code that is used to specify the type of error  produced by the commands sent to the shell. It is shell-specific and numerically unrelated to return codes generated by Stata itself.
It can be retrieved after every {cmd:inshell} command which results in an error, and is always an integer {bf:> 0}.
This value can subsequently be used in error handling routines within Stata do-files.
It is always returned in {cmd:r(rc)}, which is not to be confused with Stata's return code, which is always provided in {cmd:c(rc)} or the system variable {cmd:_rc}.{p_end}

{marker sshell}{...}
{title:S_SHELL global macro}

{p 6 4 3}
As of version 2.0 {cmd:inshell} allows the use of the {cmd:global} shell macro {cmd:S_SHELL}.
This macro allows users of {cmd:shell} in all its forms to specify an {it:alternative} shell when using {cmd:shell} and thus {cmd:inshell} in Stata.
For more information about {cmd:S_SHELL} {manpage D 800:{it:see page 793}} in the complete PDF manual.{p_end}

{marker options}{...}
{title:Options}

{p 6 4 3}
{cmd:inshell} allows its users to set several options that control its behavior through a series of {cmd:global} macros. These options are currently only available for users of {bf:macOS} and {bf:Linux} systems.
They can be safely set on {bf:Windows} systems but will not function. It is recommended to set these options within the user's {cmd:profile.do} file so that they persist across launches of Stata.{p_end}

{p 6 4 3}
{cmd:INSHELL_PATHEXT} {hline 2} this option allows the user to add a single directory to the beginning of their {bf:$PATH}.
{cmd:inshell} will check that the directory is valid and export the new {it:extended} {bf:$PATH} before each command that is issued.
Once this is set, absolute paths to commands found along the user's {it:extended} {bf:$PATH} are no longer necessary.{p_end}

{p 6 4 3}
{cmd:INSHELL_TERM} {hline 2} this option allows the user to specify an alternative {bf:$TERM} variable, as GUI instances often leave this variable unset.
Valid values for {bf:$TERM} are often found in {it:/usr/share/terminfo}. Some suggested values are "xterm" or "dumb".{p_end}

{p 6 4 3}
If {cmd:inshell} detects that the user is using {bf:Microsoft PowerShell} the two options above will automatically be disabled, though their values will remain set for future use.{p_end}

{p 6 4 3}
{cmd:INSHELL_BLOCKEDCMDS} {hline 2} this option allows the user to add commands to a block list to prevent them from running, as some commands designed for interactive shells will
require Stata to be force quit when they are executed, for example {bf:vim} or {bf:top}, which are both included as part of the default list.{p_end}

{p 6 4 3}
{bf:Toggle options} {hline 2}
The following options can be toggled on by setting the value of the corresponding {cmd:global} macro to {it:any} value.
If the option's name contains the word "{bf:ENABLE}" or "{bf:SET}" it will enable the option, whereas if it contains "{bf:DISABLE}", setting it will disable the option. All options are toggled off by default.{p_end}

{p 6 4 3}
To unset the option clear the macro.
Because {cmd:inshell} only checks whether or not the macro exists, setting the macro to "{bf:ON}", "{bf:Off}", "{bf:True}", "{bf:False}", {bf:1}, {bf:0}, or any other value will have the identical effect of toggling the option on.{p_end}

{p 6 4 3}
{cmd:INSHELL_ENABLE_AUTOCD} {hline 2} this option mimics {bf:zsh}'s AUTO_CD feature: if a command is issued that is the name of a sub-directory within the current working directory, it will perform the {cmd:cd} command to that sub-directory.
It is toggled off by default. If this option is set, its functionality will take precedence over otherwise legitimately issued commands.
For instance, if the option is toggled on and the current directory contains a sub-directory named "ls,"
if the user issues the command {cmd:inshell ls}, rather than listing the files in the current directory using the {bf:ls} command, {cmd:inshell} will issue the {cmd:cd} command to the directory named "ls".
Note that though this function will work in do-files, it is intended for interactive use.{p_end}

{p 6 4 3}
{cmd:INSHELL_DISABLE_REFOCUS} {hline 2} After each {cmd:inshell} command focus is redirected to the {cmd:Results} window.
This either may not perform as intended on all systems or may become a nuisance if it is unwanted and therefore this option is offered to disable it.{p_end}

{p 6 4 3}
{cmd:INSHELL_DISABLE_LONGCMDSMG} {hline 2} If a command is greater than 300 characters in length, {cmd:inshell} displays a suggestion to store that command as a script file. By setting this option this message will no longer be displayed.{p_end}

{p 6 4 3}
{cmd:INSHELL_ESCTAB_SIZE} {hline 2} This option allows the user to specify the number of spaces into which horizontal tabs (ASCII character code 9) are translated. The default is 4.{p_end}

{p 6 4 3}
{cmd:INSHELL_SETSHELL_CSH} {hline 2} This option {it:must} be set if the user's default shell is either {bf:csh} or {bf:tcsh}. However, if global macro {cmd:S_SHELL} is set to a {bf:csh}-type shell, this option is not required.{p_end}

{marker diagnostics}{...}
{title:Diagnostics}

{p 6 4 3}
{cmd:inshell} contains a program which performs a series of diagnostic routines and which can be run by typing {cmd:inshell} {cmdab:diag:nostics}.
The screen will be cleared and the current settings of the macro options will be displayed.
If it is set, it will also display the value of the {cmd:global} shell macro {cmd:S_SHELL}.
It will then display which shell is in use along with its version number and the absolute path to the shell.{p_end}

{p 6 4 3}
It will then display the value of your {bf:$PATH}, and if the {cmd:inshell} path extension macro option {cmd:INSHELL_PATHEXT} is set,
the path it contains will be verified and the {it:extended} {bf:$PATH} when using {cmd:inshell} will be displayed.
If the difference between the two {bf:$PATH}s is equal to the value of {cmd:INSHELL_PATHEXT}, a green check mark will appear.{p_end}

{p 6 4 3}
Though it is not included amongst the displayed option settings, the splash screen displayed at the top of the diagnostics output can be disabled by setting the {cmd:INSHELL_DISABLE_LOGO} macro option.{p_end}

{p 6 4 3}
This diagnostics routine is currently only available for users of {bf:macOS} or {bf:Linux}.{p_end}

{marker savedresults}{...}
{title:Saved results}

{p 6 4 3}
{cmd:inshell} stores the following in {cmd:r()}:{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(no)}}the total number of lines of {it:{res:standard output}} captured. This is {bf:0} when there is no {it:{res:standard output}} from the command{p_end}
{synopt:{cmd:r(no}{it:#}{cmd:)}}the captured {it:{res:standard output}} of line {it:#}{p_end}
{synopt:{cmd:r(err}{it:#}{cmd:)}}the captured {it:{err:standard error}} of line {it:#}{p_end}
{synopt:{cmd:r(errln)}}the total number of lines of {it:{err:standard error}} captured{p_end}
{synopt:{cmd:r(stderr)}}all of the lines of {it:{err:standard error}} condensed into a single line{p_end}
{synopt:{cmd:r(rc)}}the shell's native return code produced by {it:commands}, in the event of an error{p_end}
{p2colreset}{...}

{p 6 4 3}
Often lines of {it:{res:standard output}} or {it:{err:standard error}} can be blank and, because Stata cannot store empty macros, these blank lines cannot be stored in {cmd:r()}.
For that reason {cmd:inshell} preserves the sequential numerical ordering of the lines captured into {cmd:r(no1)} to {cmd:r(no{text}{it:m}{cmd:)}} or {cmd:r(err1)} to {cmd:r(err{text}{it:m}{cmd:)}}. If {cmd:r(no)} = {it:m}
there will exist {it:m} non-empty lines {cmd:r(no1)}, ... , {cmd:r(no}{it:(m-1)}{cmd:)}, {cmd:r(no}{it:m}{cmd:)}.
However, for completeness, the entire {it:{res:standard output}} and {it:{err:standard error}} including blank lines will be stored in the Mata string column vectors {bf:M} and {bf:N}, respectively.{p_end}

{title:Author}

{pstd}
Matthew Bryant Hall ({browse "mailto:mhall@wesleyan.edu":mhall@wesleyan.edu})

{marker alsosee}{...}
{title:Also see}

{psee}
Stata:
{help shell}
{p_end}

{psee}
SSC:
{stata "ssc desc ashell":ashell} (if installed), {stata "ssc desc windowsmonitor":windowsmonitor} (if installed)
{p_end}
