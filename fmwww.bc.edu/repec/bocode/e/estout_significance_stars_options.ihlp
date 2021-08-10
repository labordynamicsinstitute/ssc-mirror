{p 4 8 2}
{cmd:starlevels(}{it:levelslist}{cmd:)} overrides the default thresholds and
symbols for "significance stars". For instance, 
{bind:{cmd:starlevels(+ 0.10 * 0.05)}} 
sets the following thresholds: {cmd:+} for p<.10 and {cmd:*} for
p<.05. Note that the thresholds must lie in the (0,1] interval and must be
specified in descending order. To, for example, denote insignificant results, type
{bind:{cmd:starlevels(* 1 "" 0.05)}}.

{p 4 8 2}
{cmd:stardetach} specifies that a delimiter be placed between the statistics
and the significance stars (i.e. that the stars are to be displayed in their
own column).
