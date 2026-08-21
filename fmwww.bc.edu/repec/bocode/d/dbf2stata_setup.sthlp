{smcl}
{* *! version 0.1.0 14aug2026}{...}
{title:dbf2stata_setup}

{p 4 4 2}
Check and, when necessary, install the Python dependency required by
{cmd:dbf2stata}.

{title:Syntax}

{p 8 8 2}
{cmd:dbf2stata_setup}
[{cmd:,} {opt upgrade}]

{title:Description}

{pstd}
{cmd:dbf2stata_setup} is the companion setup command for
{help dbf2stata:dbf2stata}.

{pstd}
The command identifies the exact Python interpreter currently used by Stata,
checks that Python 3.10 or newer is available, checks for pip, and verifies
whether the public {cmd:dbf2stata} Python package can be imported.

{pstd}
If the package is missing, {cmd:dbf2stata_setup} explicitly installs:

{p 8 8 2}
{cmd:dbf2stata>=0.1.0,<0.2.0}

{pstd}
from the Python Package Index (PyPI), using:

{p 8 8 2}
{cmd:sys.executable -m pip install ...}

{pstd}
This means the command uses the same Python environment that Stata is already
running. No Windows, macOS, or Linux Python path is hard-coded.

{pstd}
Running {cmd:dbf2stata} does not silently install software. If the dependency
is missing, {cmd:dbf2stata} tells the user to run {cmd:dbf2stata_setup}.
Installation therefore occurs only after the user explicitly invokes the setup
command.

{title:Option}

{phang}
{opt upgrade} asks pip to upgrade the installed {cmd:dbf2stata} Python package
within the supported 0.1.x series.

{title:Examples}

{pstd}
Normal one-time setup:

{p 8 8 2}{cmd:. dbf2stata_setup}

{pstd}
Check or upgrade the supported Python package:

{p 8 8 2}{cmd:. dbf2stata_setup, upgrade}

{pstd}
Then run:

{p 8 8 2}{cmd:. dbf2stata}

{title:If Python is not configured}

{pstd}
{cmd:dbf2stata_setup} itself requires Stata's Python integration. If Python is
not configured, type:

{p 8 8 2}{cmd:. python query}

{pstd}
Configure Python 3.10 or newer for Stata, then rerun
{cmd:dbf2stata_setup}.

{title:Stored results}

{pstd}
On successful setup, {cmd:dbf2stata_setup} stores:

{synoptset 24 tabbed}{...}
{synopt:{cmd:r(ready)}}1 when the Python dependency is ready{p_end}
{synopt:{cmd:r(python_version)}}Python version used by Stata{p_end}
{synopt:{cmd:r(python_executable)}}Python executable used by Stata{p_end}
{synopt:{cmd:r(package_version)}}installed dbf2stata Python package version{p_end}

{title:Platform support}

{pstd}
The setup mechanism is cross-platform because it uses Stata's active Python
interpreter rather than an operating-system-specific path. It is intended for
Windows, macOS, and Linux.

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
{help dbf2stata}