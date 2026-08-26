{smcl}
{* *! version 1.0.0 23aug2026}{...}

{title:Title}

{phang}
{bf:nesttransaction} {hline 2} Run a command and roll back its dataset changes{p_end}

{title:Description}

{pstd}
After successful rollback, {cmd:nesttransaction:} propagates the command's
return code. {cmd:neststatus} reports the command and rollback results.{p_end}

{pstd}
The guarantee covers the dataset in the transaction's starting frame. It does
not promise rollback of scalars, matrices, macros, estimates, graphs, other
frames, or transparent preservation of arbitrary {cmd:r()}, {cmd:e()}, and
{cmd:s()} results.{p_end}

{pstd}
See {help nestpreserve} for examples, stored results, and safeguards.{p_end}

{title:Syntax}

{p 4 4 2}{cmd:nesttransaction} [{cmd:,} {opt quiet}]{cmd::} {it:command}{break}
Run one command and restore the preceding dataset state after success or
failure. {opt quiet} runs the command quietly.{p_end}
