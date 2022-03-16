
{smcl}
{* *! version 1.0  15dec2021}{...}
{cmd:help inshell}{right:Version 1.0}
{hline}

{title:Title}

{phang}
{cmd:inshell} {hline 2} Send commands to the shell as well as capture and print their standard output, standard error, and native shell return codes.{p_end}

{marker syntax}{...}
{title:Syntax}

    {p 8 12 2}{cmd: inshell  }  {it:  operating_system_command} [{it:args}]

    {p 8 12 2}{cmd: inshell  }  {it:  /path/to/cmd} [{it:program_args}]

    {p 8 12 2}{cmd: inshell  } {it:   . /path/to/script/file} [{it:cmd_args}]


{marker description}{...}
{title:Description}

{p 6 4 2}
{cmd:inshell} will execute commands or scripts as a shell wrapper and print the output to the Results window. It will also capture and print the standard error and native shell return code in the event of an error.{p_end}


{title:Remarks}

{p 6 4 2}
This help file is geared towards users of Unix-like shells (including Macs), but the same basic principles apply to those of Microsoft Windows. These remarks also serve to detail advanced usage of Stata's existing {cmd:shell} command.{p_end}

{p 6 4 2}
It is important to note that all commands will be sent through Stata's shell pre-processor before executing. Shell code uses the same dollar sign alphanumeric notation for variables that Stata uses for its global variables
 and consequently will attempt to interpret them as such. Therefore if your code is intended to
 reference a shell variable you will need to escape expressions of the form {cmd:$var1} or {cmd:${var2}} to {cmd:\$var1} or {cmd:\${var2}}. However, any {cmd:$} symbols used for command substitution need not be escaped. 
 For instance, to {it:echo} the {it:PATH} variable on Unix-like shells:{p_end}

{p 8 8 2}
{cmd:inshell echo \$PATH}

{p 6 4 2}
In this case, it is necessary to use the {cmd:\} to {it:escape} the {cmd:$} otherwise Stata will look for a global variable named {cmd:PATH}. If it does not exist,
 Stata will remove that part of the command. To use command substitution:{p_end}

{p 8 8 2}
{cmd:inshell echo $(date) >> logfile.log}

{p 16 16 2}{it:or}

{p 8 8 2}
{cmd:inshell echo `date` >> logfile.log}

{p 6 4 2}
Also note that Stata locals need not be escaped as shells generally use either dollar sign parentheses notation {it:$( cmd )} or double back-ticks {it:` cmd `} for command substitution, whereas local substitution is performed between 
a back-tick {cmd:`} and a single apostrophe {cmd:'}. To use a Stata local or global, leave it un-escaped:{p_end}

{p 8 8 2}
{cmd: global date "31dec2021"}{p_end}

{p 8 8 2}
{cmd: local time "12:30:00"}{p_end}

{p 8 8 2}
{cmd: inshell echo $date >> logfile.log}{p_end}

{p 8 8 2}
{cmd: inshell echo `time' >> logfile.log}{p_end}

{p 8 8 2}
{cmd: inshell cat logfile.log}{p_end}

{p 6 4 2}
However, note that Stata local and global variables will {it:not} be passed to external scripts.{p_end}

{p 6 4 2}
Note that some instances of Stata may not inherit the full {it:$PATH} variable that may have been set or extended within the user's various shell configuration files {it:(.bash_profile, .zshrc, etc)},
 which their existing terminal emulators may source. The GUI versions of Stata tend not to source these files, while terminal-launched instances do, so the user is advised to check their {it:$PATH} and other environment variables.
  Any commands not found in the user's {it:$PATH} will need explicit full paths, which is a good practice to use when writing portable shell code. For instance, if the user wanted to use {it:gsed}, the GNU version of the 
  Unix stream editor {it:sed}, even though the user may have installed the {it:gsed} package and it may function as expected in the user's interactive terminal or shell scripts, rather than using:{p_end}

{p 8 8 2}
{cmd:inshell echo "abcdefg" |  gsed 's/a/A/g'}{p_end}

{p 16 16 2}
{it:use}{p_end}

{p 8 8 2}
{cmd:inshell echo "abcdefg"  |  /usr/local/bin/gsed 's/a/A/g'}{p_end}

{p 6 4 2}
If the correct path to the desired executable is found when you enter:{p_end}

{p 8 8 2}
{cmd:inshell echo \$PATH }{p_end}

{p 16 16 2}
or {it:command} is successfully located by running{p_end}

{p 8 8 2}
{cmd:inshell which} {it:command}{p_end}

{p 6 4 2}
then the function call will proceed. In this particular case {it:echo} is a shell built-in and therefore has no direct path to the executable.{p_end}

{p 6 4 2}
Also note that Stata's implementation of the shell has no interactive abilities and the information printed to the Stata Results window may contain garbled or otherwise unprintable text.
This is because the shell is accessed through Stata's limited shell parser, and therefore the user should explicitly avoid any commands that involve any interactive functionality.{p_end}

{p 6 4 2}
The shell's native return code is the return code produced by the shell, and generally  exists in the form of an integer. This can be retrieved after each {cmd:inshell} command. The return code is always 0 on success 
and some other integer > 0 in the event of a failure. It is always returned in {cmd:r(rc)}, which is not to be confused with Stata's return code, which is always provided 
in {cmd:c(rc)} or the system variable {cmd:_rc}. This number can be retrieved and later used in conditional expressions to "interact" with the results from the shell.{p_end}

{title:Saved results}

{p 6 4 2}
{cmd:inshell} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(no)}}the total number of lines of output captured. This is 0 when there is no standard output from the command{p_end}
{synopt:{cmd:r(no}{it:#}{cmd:)}}the captured output of line #{p_end}
{synopt:{cmd:r(rc)}}the native shell return code produced by {it:commands}, which is equal to 0 in the event of no errors{p_end}
{p2colreset}{...}

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
{stata "ssc desc ashell":ashell}
{p_end}
