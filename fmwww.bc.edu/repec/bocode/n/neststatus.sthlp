{smcl}
{* *! version 1.0.0 23aug2026}{...}

{title:Title}

{phang}
{bf:neststatus} {hline 2} Inspect checkpoints, data changes, and transaction history{p_end}

{title:Description}

{pstd}
{cmd:neststatus} identifies the next checkpoint to be restored and reports
whether active metadata and snapshot files are valid. Machine-readable status
is returned in {cmd:r()}.{p_end}

{pstd}
See {help nestpreserve} for examples, stored results, and safeguards.{p_end}

{title:Syntax}

{p 4 4 2}{cmd:neststatus} [{cmd:,} {opt detail}]{break}
Show stack health, sample and variable changes, and transaction history.
{opt detail} adds frames, dimensions, paths, and file status.{p_end}
