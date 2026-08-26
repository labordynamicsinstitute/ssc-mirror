{smcl}
{* *! version 1.0.0 23aug2026}{...}

{title:Title}

{phang}
{bf:nestrestore} {hline 2} Restore the newest dataset-state checkpoint{p_end}

{title:Description}

{pstd}
Restoration is last-in, first-out and must occur in the frame that created the
checkpoint. After {cmd:nestrestore, preserve}, the next {cmd:nestrestore}
restores the same checkpoint and removes it.{p_end}

{pstd}
A failed load does not pop the stack. If deletion fails after successful
restoration, the logical pop remains valid and the file is registered for
later cleanup.{p_end}

{pstd}
See {help nestpreserve} for examples, stored results, and safeguards.{p_end}

{title:Syntax}

{p 4 4 2}{cmd:nestrestore} [{cmd:,} {opt preserve} {opt quiet}]{break}
Restore and remove the newest checkpoint. {opt preserve} restores it without
removing it; {opt quiet} suppresses confirmation.{p_end}
