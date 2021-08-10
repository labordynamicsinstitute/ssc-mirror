{smcl}
{* *! version 1.22  Ross Harris, Sep 2003}{...}
{vieweralsosee "metan" "help metan"}{...}
{vieweralsosee "forestplot" "help forestplot"}{...}
{vieweralsosee "metani" "help metani"}{...}
{vieweralsosee "metannt" "help metannt"}{...}
{vieweralsosee "metabias" "help metabias"}{...}
{vieweralsosee "metatrim" "help metatrim"}{...}
{vieweralsosee "galbr" "help galbr"}{...}
{vieweralsosee "metafunnel" "help metafunnel"}{...}
{vieweralsosee "confunnel" "help confunnel"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "labbe##syntax"}{...}
{viewerjumpto "Options" "labbe##options"}{...}
{viewerjumpto "Remarks" "labbe##remarks"}{...}
{viewerjumpto "Example" "labbe##example"}{...}
{title:Title}

{phang}
{hi:labbe} {hline 2} Draw a L'Abbe plot for event data (proportion of successes in the two groups).


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:labbe} {varlist} {ifin} {weight} [{cmd:,} {opt nowt} {opt percent} {opt or(#)} {opt rr(#)} {opt rd(#)}
{opt null} {opt logit} {opt wgt(weightvar)} {opt symbol(symbolstyle)} {opt nolegend} {opt id(idvar)}
{opt textsize(#)} {opt clockvar(clockvar)} {opt gap(#)} {it:twoway_options}

{pstd}
where {varlist} is:

{pmore}{it:event_treat} {it:noevent_treat} {it:event_ctrl} {it:noevent_ctrl}

{pstd}
that is, the number of events and non-events in the treatment and control groups, in that order.


{marker options}{...}
{title:Options}

{p 4 8 2}
{cmd:nowt} declares that the plotted data points are to be the same size.

{p 4 8 2}
{cmd:percent} displays the event rates as percentages rather than proportions.

{p 4 8 2}
{cmd:null} draws a line corresponding to a null effect (ie p1=p2).

{p 4 8 2}
{cmd:or(}{it:#}{cmd:)} draws a line corresponding to a fixed odds ratio of
    {it:#}.

{p 4 8 2}
{cmd:rd(}{it:#}{cmd:)} draws a line corresponding to a fixed risk difference of
    {it:#}.

{p 4 8 2}
{cmd:rr(}{it:#}{cmd:)} draws a line corresponding to a fixed risk ratio
    of {it:#}. See also the {cmd:rrn()} option.

{p 4 8 2}
{cmd:rrn(}{it:#}{cmd:)} draws a line corresponding to a fixed risk ratio
    (for the non-event) of {it:#}.
    The {cmd:rr()} and {cmd:rrn()} options may require explanation.
    Whereas the OR and RD are invariant to the definition of which of
    the binary outcomes is the "event" and which is the "non-event",
    the RR is not.  That is, while the command {cmd:metan a b c d , or}
    gives the same result as {cmd:metan b a d c , or} (with direction
    changed), an RR analysis does not.  The L'Abbe plot allows the display
    of either or both to be superimposed risk difference.

{p 4 8 2}
{cmd:logit} is for use with the {cmd:or()} option; it displays the
    probabilities on the logit scale ie log(p/1-p). On the logit scale the  
    odds ratio is a linear effect, and so this makes it easier to assess the 
    "fit" of the line. 

{p 4 8 2}
{cmd:wgt(}{it:weightvar}{cmd:)} specifies alternative weighting by the specified variable
(default is sample size).

{p 4 8 2}
{cmd:symbol(}{it:symbolstyle}{cmd:)} allows the symbol to be changed (see help {help symbolstyle}) the
default being hollow circles (or points if weights are not used).

{p 4 8 2}
{cmd:nolegend} suppresses a legend being displayed (the default if more than one
line corresponding to effect measures are specified).

{p 4 8 2}
{cmd:id(}{it:idvar}{cmd:)} displays marker labels with the specified ID variable {it:idvar}.
{cmd:clockvar()} and {cmd:gap()} may be used to fine-tune the display, which may become
unreadable if studies are clustered together in the graph.

{p 4 8 2}
{cmd:textsize(}{it:#}{cmd:)} increases or decreases the text size of the id label by specifying
{it:#} to be more or less than unity. The default is usually satisfactory, but may need to be adjusted.

{p 4 8 2}
{cmd:clockvar(}{it:clockvar}{cmd:)} specifies the position of {it:idvar} around the
study point, as if it were a clock face (values must be integers- see {help clockposstyle}).
This may be used to organise labels where studies are clustered together. By default, labels are positioned
to the left (9 o'clock) if above the null and to the right (3 o'clock) if below. Missing values
in {it:clockvar} will be assigned the default position, so this need not be specified for all observations.

{p 4 8 2}
{cmd:gap(}{it:#}{cmd:)} increases or decreases the gap between the study marker and the id label by specifying
{it:#} to be more or less than unity. The default is usually satisfactory, but may need to be adjusted.

{p 4 8 2}
{it:twoway_options} are options to pass to the Stata {cmd:twoway} graph-drawing command (see help on {help twoway_options}).



{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
By default the size of the plotting symbol is proportional to the sample 
size of the study. If weights are specified the plotting size will be 
proportional to the weight variable. Note that {cmd:labbe} has now been updated to version 8 graphics.
All options work the same as in the previous version, and some minor graphics options have been added.



{marker example}{...}
{title:Example}

{p 4 8 2}
L'Abbe plot with labelled axes and display of risk ratio and risk difference.

{p 8 12 2}
{cmd:. labbe tdeath tnodeath cdeath cnodeath, }
{p_end}
{p 12 12 2}
{cmd:xlabel(0,0.25,0.5,0.75,1) ylabel(0,0.25,0.5,0.75,1) }
{p_end}
{p 12 12 2}
{cmd:rr(1.029) rd(0.014) null}
{p_end}
{p 12 12 2}
{it:({stata "metan_examples labbe_example":click to run})}



{title:Authors}

{p 4 4 0}
Michael J Bradburn, Jonathan J Deeks, Douglas G Altman.
Centre for Statistics in Medicine, University of Oxford,
Wolfson College Annexe, Linton Road, Oxford, OX2 6UD, UK

{title:Version 9 update}

{p 4 4 0}
Ross J Harris ({browse "mailto:rossharris1978@yahoo.co.uk":rossharris1978@yahoo.co.uk}), Roger M Harbord, Jonathan A C Sterne.
Department of Social Medicine, University of Bristol,
Canynge Hall, Whiteladies Road, Bristol BS8 2PR, UK

{title:Other updates and improvements to code and help file}

{p 4 4 0}
Patrick Royston. MRC Clinical Trials Unit, 222 Euston Road,
London, NW1 2DA

{title:Acknowledgements}

{p 4 4 0}
Thanks to Vince Wiggins, Kit Baum and Jeff Pitblado of Statacorp
who offered advice and helped facilitate the version 9 update.
Thanks also to all the people who helped with beta-testing and
made comments and suggested improvements.

