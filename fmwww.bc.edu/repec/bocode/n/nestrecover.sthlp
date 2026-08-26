{smcl}
{* *! version 1.0.0 23aug2026}{...}

{title:Title}

{phang}
{bf:nestrecover} {hline 2} Safely recover an abandoned checkpoint stack{p_end}

{title:Description}

{pstd}
The one-word command acts only when exactly one intact abandoned stack is
identified and its owner is proven dead. Live, ambiguous, corrupt, legacy, or
uncertain candidates are refused without changing data. Listing and inspection
are read-only; older recovery records require explicit confirmation.{p_end}

{pstd}
See {help nestpreserve} for examples, stored results, and safeguards.{p_end}

{title:Syntax}

{p 4 4 2}{cmd:nestrecover}{break}
Recover the latest checkpoint from one safely identifiable abandoned
stack.{p_end}

{p 4 4 2}{cmd:nestrecover} [{cmd:,} {opt list}]{break}
List available recovery records without changing data.{p_end}

{p 4 4 2}{cmd:nestrecover using} {it:manifest}{cmd:,} {opt inspect}{break}
Inspect one recovery record without adopting it.{p_end}

{p 4 4 2}{cmd:nestrecover using} {it:manifest}{cmd:,} {opt adopt}
{opt confirm(session-id)}{break}
Explicitly adopt a validated recovery record after confirming its session
identifier.{p_end}
