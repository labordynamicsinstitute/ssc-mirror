{smcl}
{* *! version 1.0.0 30Jun2017 MLB}{...}
{title:Title}

{phang}
{cmd:smclpres} {hline 2} Create a .smcl presentation from a .do file

{title:Syntax}

{p 8 17 2}
{cmd:smclpres}
{cmd:using} {it:{help filename}} [{cmd:,}
{it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt replace}}files created by {cmd:smclpres} will replace files with the
        same name if they already exist{p_end}
{synopt:{opt dir(directory_name)}}specifies the directory in which the presentation
        is to be stored. The default is the current working directory.{p_end}
{synopt:{opt nonav:bar}}suppresses the line at the top of the slides indicating
         the section and subsection.{p_end}
{synopt:{opt nosub:sec}}suppresses the subsection in the navigationbar at the top
of each slide{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Commands that can be used in the .do file. These commands have to be the first 
word on their line. 

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt //slide}}start a new slide{p_end}
{synopt:{opt //endslide}}ends that slide{p_end}
{synopt:{opt //section} {it:section_name}}Start a new section called 
{it:section_name}{p_end}
{synopt:{opt //subsection} {it:subsection_name}}Starts a new sub-section called
{it:subsection_name}{p_end}
{synopt:{opt //toctitle} {it:title}}The title that appears on the first slide,
which also contains the table of contents{p_end}
{synopt:{opt /*toctxt} and {opt toctxt*/}}lines between these two commands will 
be written on the first slide.{p_end}
{synopt:{opt //title} {it:title}}The title that appears on currently open 
slide{p_end}
{synopt:{opt //label} {it:label}}Each slide will contain a link to the next slide.
{it:label} will be used to refer to the currently open slide. The default is 
"next".{p_end}
{synopt:{opt //ex} and {opt //endex}}Lines between these two commands are an 
example. They will appear on the current slide bold and indented. In addition, a 
.do file will be created containing those lines. On the slide below the example
a link will be shown that wil do that .do file.{p_end}
{synopt:{opt //txt} {it:text}}will write {it:text} on the current slide{p_end}
{synopt:{opt /*txt} and {opt txt*/}}lines between these two commands will be 
written on the currently open slide.{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
A .smcl presentation is a series of linked .smcl files that open in the viewer
inside Stata (like help-files). They are particularly useful for talks that 
focus on how to do things in Stata, like a lecture on graphs in Stata or a talk
at a Stata Users' Group meeting. Preparing for such a talk typically starts with
preparing the examples using a .do file. The purpose of {cmd:smclpres} is to 
streamline the process of turning that .do file into a .smcl presentation. 


{title:Options}

{phang}
{opt replace} files created by {cmd:smclpres} will replace files with the
        same name if they already exist. 

{pmore}
        If the .do file is called 
        {cmd:presentation.do} then the following files will be created: 
        presentation.smcl, slide1.smcl, slide2.smcl, etc. presentation.smcl will
        be the first slide and contain the table of content. In addition, if 
        slide2.smcl contains two examples, then the following files will also be 
        created: slide2ex1.do and slide2ex2.do.

{phang}
{opt dir(directory_name)} specifies the directory in which the presentation is to 
        be stored. The default is the current working directory. 

{phang}
{opt nonav:bar} By default, each slide will start with the name of the section 
        and subsection, followed by a horizontal line. This may help the audience
        in keeping track of where in the presentation you currently are, but it
        may also distract. This option will suppress those two lines.

{phang}
{opt nosub:sec} This option will suppress the subsection in the navigation bar on
        top of each slide. The subsections will appear in the table of content. 


{title:Commands in .do file}

{phang}
{opt //slide} Starts a new slide. Anything appearing afterwards will be ignored.
        So one can specify {cmd://slide ------------} to indicate more clearly 
        in the .do file  where the new slides begin. However, notice the space 
        between {cmd://slide} and {cmd:-------}.

{phang}
{opt //endslide} Ends the slide. As with {cmd://slide} everything afterwards will
        be ignored.

{phang}
{opt //section} {it:section_name} Starts a new section named {it:section_name}. 
        This will appear in the table of content and on top of the slides in that
        section.

{phang}
{opt //subsection} {it:subsection_name} Starts a new subsection named 
        {it:subsection_name}. This will appear in the table of content and on 
        top of the slides in that section.

{phang}
{opt //toctitle} {it:title} The title that appears on the first slide, which also
        contains the table on contents

{phang}
{opt /*toctxt} and {opt toctxt*/} lines between these two commands will appear on
        the first slide

{phang}
{opt //title} {it:title} specifies the title that appears on the current slide

{phang}
{opt //label} each slide will contain a link to the next slide. {it:label} will 
        be used to refer to the current slide. The default is "next".

{phang}
{opt //ex} and {opt //endex} Lines between these two commands are an example. 
        They will appear on the current slide bold and indented. In addition, a 
        .do file will be created containing those lines. On the slide below the 
        example a link will be shown that wil do that .do file.

{phang}
{opt //txt} {it:text} will write {it:text} on the current slide. This text may 
       contain {help smcl:smcl directives}.

{phang}
{opt /*txt} and {opt txt*/} lines between these two commands will be written on 
        the currently open slide. This text may contain {help smcl:smcl directives}.


{title:Example}

{pstd}
Say if have a .do file called {cmd:minimalist.do} which contains the content 
below. We can now type {cmd: smclpres using minimalist.do}, to turn that into a 
.smcl presentation. 

{hline}
// This .do-file is intended to be compiled into a smcl presentation using:
// smclpres using minimalist.do
// =============================================================================

//toctitle A minimalist example presentation

/*toctxt

{c -(}center:Maarten Buis{c )-}
{c -(}center:maarten.buis@uni.kn{c )-}
toctxt*/

//section First section
//subsection First subsection

//slide ------------------------------------------------------------------------
//title First slide

/*txt
{c -(}pstd{c )-}Some interesting text about {c -(}help regress{c )-}{c -(}p_end{c )-}
txt*/

//ex
sysuse auto, clear
sum price
//endex
//endslide ---------------------------------------------------------------------

//subsection Second subsection
//slide ------------------------------------------------------------------------
//title Second slide

/*txt
{c -(}phang{c )-}Kwaak, kwaak, kikker kwaak. Als ik grote sprongen maak. Doe ik 
net zo gek als jij, en ik kwaak er ook nog bij.{c -(}p_end{c )-}
{c -(}phang{c )-}Kwaak, kwaak, kwaak maar door. Kom maar in het kikker koor. 
Kwaak van dit en kwaak van dat. Kikkers kwaken altijd wat.{c -(}p_end{c )-}
txt*/
//endslide ---------------------------------------------------------------------

//section Second section
//slide ------------------------------------------------------------------------
//title Third slide

/*txt
{c -(}phang{c )-}
Ia zegt het ezeltje, klim maar op mijn rug. Ik draag jou de hele weg, heen
end weer terug.

{c -(}phang{c )-}
Ia zegt het ezeltje. Ik loop van hier naar daar, en als je met me mee 
wil hoor ik graag, ia ia.
txt*/

//ex
reg price i.rep78 
//endex
//endslide ---------------------------------------------------------------------
{hline}

The ancillary files contain two further examples from real lectures.


{title:Author}

{pstd}Maarten Buis, University of Konstanz{break} 
      maarten.buis@uni.kn
