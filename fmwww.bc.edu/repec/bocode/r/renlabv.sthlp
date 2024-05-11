{smcl}
{* version 2.0.1  27april2024}{...}
{cmd:help renlabv}
{hline}

{title:Title}

{p 4 15 2}
    {hi:renlabv} {hline 2} Renames value labels to match the names of assigned variables{p_end}


{title:Syntax}

    {cmd:renlabv} [{varlist}] [, {it:options}]


{synoptset 20 tabbed}{...}
{marker comopt}{synopthdr:options}
{synoptline}
{synopt :{opt nod:rop}}do not drop original value labels{p_end}
{synoptline}


{title:Description}

{pstd}
As a wrapper of the SSC program {hi:elabel} by Daniel Klein, {cmd:renlabv} renames
value labels to match the name(s) of the assigned variable(s). Hence, the program
will require that {hi:elabel} is installed. After using {hi:renlabv} without
specifying any variable the names of all value labels of the data set will be
equal to the names of the assigned variables. By default {cmd:renlabv} will
drop the original value labels. Note that value labels not assigned to variables
will not be renamed or dropped.

{pstd}
Stata allows to attach a value label to several variables; this may be regarded
as a feature (see the PDF documentation [D] for {help label}). However, if for
example the sign (sense) of only some items (variables) of a scale have to be
recoded (e.g. reversed) such that all items correlate positively with each
other, their value labels should be recoded, as well. But if only one (or only
some) of the scale items have to be recoded (reversed) and the user is not aware
that their value label is shared with other items it may happen that recoding
this value label inadvertently recodes (reverses) the value label of the other
items, as well, resulting in improper value labels for some items and
consequently wrong conclusions from the analyses.

{pstd}
You could use {hi:elabel} (from SSC) to avoid this. As an example:

    {com}. sysuse auto, clear
    {txt}(1978 automobile data)
    {txt}
    {com}. keep foreign
    {txt}
    {com}. rename foreign item1
    {com}. clonevar item2 = item1
    {com}. clonevar item3 = item1
    {txt}
    {com}. // recode values of item1:
    {txt}
    {com}. recode item1 (0=1) (1=0)
    {txt}(74 changes made to {bf:item1})
    {txt}
    {com}. // define a new value label "item1" with the old value label recoded:
    {txt}
    {com}. elabel recode (item1) (0=1) (1=0), def(item1)
    {txt}
    {com}. // assign the new value label to variable "item1":
    {txt}
    {com}. lab val item1 item1
    {txt}
    {com}. fre item?  // requires -fre- from SSC
    {res}
    {txt}item1 {hline 2} Car origin
    {txt}{hline 18}{hline 1}{c TT}{hline 44}
    {txt}        {txt}           {c |}      Freq.    Percent      Valid       Cum.
    {txt}{hline 18}{hline 1}{c +}{hline 44}
    {txt}Valid   0 Foreign  {c |}{res}         22      29.73      29.73      29.73
    {txt}        1 Domestic {c |}{res}         52      70.27      70.27     100.00
    {txt}        Total      {c |}{res}         74     100.00     100.00           
    {txt}{hline 18}{hline 1}{c BT}{hline 44}
    {res}
    {txt}item2 {hline 2} Car origin
    {txt}{hline 18}{hline 1}{c TT}{hline 44}
    {txt}        {txt}           {c |}      Freq.    Percent      Valid       Cum.
    {txt}{hline 18}{hline 1}{c +}{hline 44}
    {txt}Valid   0 Domestic {c |}{res}         52      70.27      70.27      70.27
    {txt}        1 Foreign  {c |}{res}         22      29.73      29.73     100.00
    {txt}        Total      {c |}{res}         74     100.00     100.00           
    {txt}{hline 18}{hline 1}{c BT}{hline 44}
    {res}
    {txt}item3 {hline 2} Car origin
    {txt}{hline 18}{hline 1}{c TT}{hline 44}
    {txt}        {txt}           {c |}      Freq.    Percent      Valid       Cum.
    {txt}{hline 18}{hline 1}{c +}{hline 44}
    {txt}Valid   0 Domestic {c |}{res}         52      70.27      70.27      70.27
    {txt}        1 Foreign  {c |}{res}         22      29.73      29.73     100.00
    {txt}        Total      {c |}{res}         74     100.00     100.00           
    {txt}{hline 18}{hline 1}{c BT}{hline 44}

{pstd}
But you can use {cmd:renlabv} to avoid altogether the problem of inadvertently
recoding value labels when recoding only some items of a set of items originally
assigned to the same value label. After having run {cmd:renlabv} you can then
use the tandem of {help recode} and {cmd:elabel recode} -- without the option
{cmd:define()} -- to safely recode some of the scale items.

{pstd}
Of course, the issue {hi:renlabv} is intended so solve is not only restricted
to scale items but to any value label that is assigned to several variables, for
example dichotomous variables with values coded 0 for "no" and 1 for "yes", etc.

{pstd}
Another use of {hi:renlabv} might be that you import SPSS data containing variables
with value labels defined into Stata: Stata will automatically generate label
values named "labels0", "labels1", "labels2", etc. Running {hi:renlabv} will
rename them to better recognizable names since they will match the names of the
assigned variables.

{pstd}
The disadvantage of using {hi:renlabv} is that subsequently you cannot longer
use Stata's feature to relabel several variables simultaneously by redefining
their common value label. If this bothers you, you can call {hi:renlabv} by
specifying only those variables which you actually want to recode.


{title:Examples}

{pstd}
Use {hi:renlabv} to rename {bf:all} value labels to match the name(s) of
the assigned variable(s) and recode only one item and its value label:
    
    {com}. sysuse auto, clear
    {txt}(1978 automobile data)
    {txt}
    {com}. keep rep78 foreign
    {txt}
    {com}. label define notass 0 "no" 1 "yes"
    {txt}
    {com}. label define rep78 1 "poor" 5 "excellent"
    {com}. lab val rep78 rep78
    {txt}
    {com}. clonevar abroad = foreign
    {com}. clonevar item1 = foreign
    {com}. clonevar item2 = foreign
    {com}. clonevar item3 = foreign
    {txt}
    {com}. renlabv
    {com}. describe
    {txt}
    {txt}Contains data from {res}/usr/local/stata18/ado/base/a/auto.dta
    {txt} Observations:{res}            74                  1978 automobile data
    {txt}    Variables:{res}             6                  13 Apr 2022 17:45
                                                  (_dta has notes)
    {txt}{hline}
    Variable      Storage   Display    Value
        name         type    format    label      Variable label
    {hline}
    {txt}{res}{res}{bind:rep78          }{txt}{bind: int     }{bind:%9.0g     }{space 1}{bind:rep78    }{bind:  }{res}{res}Repair record 1978
    {txt}{res}{bind:foreign        }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:foreign  }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:abroad         }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:abroad   }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:item1          }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:item1    }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:item2          }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:item2    }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:item3          }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:item3    }{bind:  }{res}{res}Car origin
    {txt}{hline}
    Sorted by: {res}foreign
    {txt}     Note: {res}Dataset has changed since last saved.
    {txt}
    {com}. label dir
    {res}item3
    item2
    item1
    abroad
    foreign
    rep78
    notass
    {txt}
    {com}. // recode and relabel item1:
    {txt}. 
    {com}. recode item1 (0=1) (1=0)
    {txt}(74 changes made to {bf:item1})
    
    {com}. elabel recode item1 (0=1) (1=0)
    {txt}
    {com}. fre item?  // requires -fre- from SSC
    {res}
    {txt}item1 {hline 2} Car origin
    {txt}{hline 18}{hline 1}{c TT}{hline 44}
    {txt}        {txt}           {c |}      Freq.    Percent      Valid       Cum.
    {txt}{hline 18}{hline 1}{c +}{hline 44}
    {txt}Valid   0 Foreign  {c |}{res}         22      29.73      29.73      29.73
    {txt}        1 Domestic {c |}{res}         52      70.27      70.27     100.00
    {txt}        Total      {c |}{res}         74     100.00     100.00           
    {txt}{hline 18}{hline 1}{c BT}{hline 44}
    {res}
    {txt}item2 {hline 2} Car origin
    {txt}{hline 18}{hline 1}{c TT}{hline 44}
    {txt}        {txt}           {c |}      Freq.    Percent      Valid       Cum.
    {txt}{hline 18}{hline 1}{c +}{hline 44}
    {txt}Valid   0 Domestic {c |}{res}         52      70.27      70.27      70.27
    {txt}        1 Foreign  {c |}{res}         22      29.73      29.73     100.00
    {txt}        Total      {c |}{res}         74     100.00     100.00           
    {txt}{hline 18}{hline 1}{c BT}{hline 44}
    {res}
    {txt}item3 {hline 2} Car origin
    {txt}{hline 18}{hline 1}{c TT}{hline 44}
    {txt}        {txt}           {c |}      Freq.    Percent      Valid       Cum.
    {txt}{hline 18}{hline 1}{c +}{hline 44}
    {txt}Valid   0 Domestic {c |}{res}         52      70.27      70.27      70.27
    {txt}        1 Foreign  {c |}{res}         22      29.73      29.73     100.00
    {txt}        Total      {c |}{res}         74     100.00     100.00           
    {txt}{hline 18}{hline 1}{c BT}{hline 44}
    
{pstd}
Use {hi:renlabv} for renaming value labels to match the name(s)
of {bf:only some} assigned variable(s):

    {com}. sysuse auto, clear
    {txt}(1978 automobile data)
    {txt}
    {com}. keep rep78 foreign
    {txt}
    {com}. label define notass 0 "no" 1 "yes"
    {txt}
    {com}. label define rep78 1 "poor" 5 "excellent"
    {com}. lab val rep78 rep78
    {txt}
    {com}. clonevar abroad = foreign
    {com}. clonevar item1 = foreign
    {com}. clonevar item2 = foreign
    {com}. clonevar item3 = foreign
    {txt}
    {com}. renlabv item1 item2 item3
    {txt}
    {com}. describe
    
    {txt}Contains data from {res}/usr/local/stata18/ado/base/a/auto.dta
    {txt} Observations:{res}            74                  1978 automobile data
    {txt}    Variables:{res}             6                  13 Apr 2022 17:45
                                                  (_dta has notes)
    {txt}{hline}
    Variable      Storage   Display    Value
        name         type    format    label      Variable label
    {hline}
    {txt}{res}{res}{bind:rep78          }{txt}{bind: int     }{bind:%9.0g     }{space 1}{bind:rep78    }{bind:  }{res}{res}Repair record 1978
    {txt}{res}{bind:foreign        }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:origin   }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:abroad         }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:origin   }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:item1          }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:item1    }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:item2          }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:item2    }{bind:  }{res}{res}Car origin
    {txt}{res}{bind:item3          }{txt}{bind: byte    }{bind:%8.0g     }{space 1}{bind:item3    }{bind:  }{res}{res}Car origin
    {txt}{hline}
    Sorted by: {res}foreign
    {txt}     Note: {res}Dataset has changed since last saved.
    {txt}
    {com}. label dir
    {res}item3
    item2
    item1
    rep78
    notass
    origin{txt}


{title:Returned results}

{pstd} Macros:

       {cmd:r(dvl)}    dropped value labels (if value labels have been dropped)


{title:Author}

    Dirk Enzmann
    {browse "https://www.wiso.uni-hamburg.de/fachbereich-sowi/ueber-den-fachbereich/personen/enzmann-dirk.html"}
    dirk.enzmann@uni-hamburg.de


{title:Acknowlegements}

    Thanks to Daniel Klein for assistance in solving my problems using {hi:elabel}.


{title:Also see}

{psee}Online: {help label}, {help recode}{p_end}
{psee}SSC package {hi:elabel}: ({net "describe elabel, from(http://fmwww.bc.edu/repec/bocode/e)":click here}){p_end}
