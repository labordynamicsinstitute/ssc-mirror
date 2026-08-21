{smcl}
{* *! version 0.1.0 14aug2026}{...}
{title:dbf2stata}

{p 4 4 2}
Batch-convert DBF files to Stata .dta format using the dbf2stata Python package.

{title:Syntax}

{p 8 8 2}
{cmd:dbf2stata}
[{cmd:,} {opt inputdir(path)} {opt outputdir(path)} {opt keepcase} {opt replace}]

{title:Description}

{pstd}
{cmd:dbf2stata} converts every .dbf or .DBF file in a folder to Stata .dta format.

{pstd}
With no options, {cmd:dbf2stata} opens a file chooser. Select any DBF file in
the folder to be converted. Every DBF file in that folder is then processed.

{pstd}
By default, .dta files are saved in the same folder as the source DBFs and
variable names are converted to lowercase.

{pstd}
The Stata command uses the public {cmd:dbf2stata} Python package as its
conversion engine.

{title:Requirements}

{pstd}
Stata 16 or newer with Python 3.10 or newer configured for Stata.

{pstd}
The {cmd:dbf2stata} Python package must be installed in the Python environment
used by Stata. The companion {help dbf2stata_setup:dbf2stata_setup} command can
install this dependency for the user.

{title:Installation}

{pstd}
Until the SSC package is published, install the current SSC candidate with:

{p 8 8 2}
{cmd:. net install dbf2stata, from("https://raw.githubusercontent.com/WilliamDormechele/dbf2stata/ssc-candidate-2026-08-14-r2/stata")}

{pstd}
After installation, start the command with:

{p 8 8 2}{cmd:. dbf2stata}

{pstd}
Before opening a DBF, {cmd:dbf2stata} checks whether its Python engine is
available. If the Python package is missing, the command stops with clear
instructions to run:

{p 8 8 2}{cmd:. dbf2stata_setup}

{pstd}
{cmd:dbf2stata_setup} uses the exact Python executable already being used by
Stata and installs the required Python package from PyPI. The main
{cmd:dbf2stata} command never silently installs or upgrades Python packages.

{pstd}
Users who want to check Stata's Python configuration can type:

{p 8 8 2}{cmd:. python query}

{pstd}
For setup details, see {help dbf2stata_setup}.

{title:SSC installation}

{pstd}
The package is being submitted to the Statistical Software Components (SSC)
Archive. After SSC accepts and publishes it, installation will be:

{p 8 8 2}{cmd:. ssc install dbf2stata}

{pstd}
After installation, type {cmd:dbf2stata}. If the external Python dependency is
not yet available, {cmd:dbf2stata} will direct the user to
{cmd:dbf2stata_setup}.

{title:Platform support}

{pstd}
The Python conversion engine is tested on Windows, Linux, macOS Apple Silicon,
and macOS Intel.

{pstd}
The Stata command uses Stata's Python integration, the Stata Function Interface,
the operating system's file dialog, and Python cross-platform path handling.

{pstd}
The setup command does not hard-code Windows, macOS, or Linux Python paths.
Instead, it invokes pip through {cmd:sys.executable}, which is the Python
interpreter currently running inside Stata.

{pstd}
The Windows licensed-Stata integration has been tested directly. A portable
licensed-Stata smoke test is included for additional Stata installations,
including Stata for Mac.

{title:Options}

{phang}
{opt inputdir(path)} specifies the folder containing the DBF files and bypasses
the file chooser.

{phang}
{opt outputdir(path)} specifies another output folder. If omitted, output is
saved in the DBF input folder.

{phang}
{opt keepcase} retains the field-name case stored in the DBF. If omitted,
variable names are converted to lowercase.

{phang}
{opt replace} overwrites existing .dta files. Without {cmd:replace}, existing
.dta files are protected from overwrite.

{title:Examples}

{pstd}
Open the file chooser:

{p 8 8 2}{cmd:. dbf2stata}

{pstd}
Specify the input folder:

{p 8 8 2}{cmd:. dbf2stata, inputdir("C:\data\dbfs")}

{pstd}
Specify another output folder:

{p 8 8 2}{cmd:. dbf2stata, inputdir("C:\data\dbfs") outputdir("C:\data\stata")}

{pstd}
Overwrite existing .dta files:

{p 8 8 2}{cmd:. dbf2stata, inputdir("C:\data\dbfs") replace}

{pstd}
Retain DBF field-name case:

{p 8 8 2}{cmd:. dbf2stata, inputdir("C:\data\dbfs") keepcase}

{title:Stored results}

{pstd}
{cmd:dbf2stata} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(files)}}number of DBF files found{p_end}
{synopt:{cmd:r(converted)}}number successfully converted{p_end}
{synopt:{cmd:r(failed)}}number that failed{p_end}
{synopt:{cmd:r(records)}}total records written{p_end}

{title:Author}

{pstd}
William Dormechele{p_end}

{pstd}
University of East Anglia, United Kingdom{p_end}

{title:Links}

{pstd}
Python package:
{browse "https://pypi.org/project/dbf2stata/":PyPI}{p_end}

{pstd}
Source code and issue tracker:
{browse "https://github.com/WilliamDormechele/dbf2stata":GitHub}{p_end}

{title:License}

{pstd}
MIT License.{p_end}

{title:Also see}

{psee}
{help dbf2stata_setup}