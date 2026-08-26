{smcl}
{* *! version 1.0.0 23aug2026}{...}

{title:Title}

{phang}
{bf:nestclear} {hline 2} Safely discard owned dataset-state checkpoints{p_end}

{title:Description}

{pstd}
With an active stack, {cmd:nestclear} deletes its registered snapshots and
metadata. With no active stack, the one-word command cleans only one safely
identifiable abandoned stack whose owner is proven dead. Multiple, live,
legacy, corrupt, or uncertain candidates are refused without deleting files.{p_end}

{pstd}
{cmd:nestclear} never deliberately deletes checkpoints it cannot verify as
owned by NESTPRESERVE. See {help nestpreserve} for examples and safeguards.{p_end}

{title:Syntax}

{p 4 4 2}{cmd:nestclear} [{cmd:,} {opt force} {opt quiet}]{break}
Delete owned checkpoints without restoring them. {opt force} clears current
stack metadata even when a registered file cannot be deleted; {opt quiet}
suppresses confirmation.{p_end}
