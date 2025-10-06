{smcl}
{* *! version 1.0.0  25sep2025}{...}
{bf:help tuplesget()}
{hline}

{phang}
{bf:tuplesget()} {hline 2} Obtain tuples, one at a time


{...}
{title:Syntax}

{p 8 12 2}
{bind:                }{it:t} {cmd:=}
{cmd:tuplessetup(}{it:transmorphic vector v}
[{cmd:,} {it:real vector k}]{cmd:)}


{p 8 12 2}
{it:transmorphic vector}
{cmd:tuplesget(}{it:t}{cmd:)}

{p 8 12 2}
{it:real scalar}{bind:        }
{cmd:tuplesdone(t)}

{p 8 12 2}
{it:real scalar}{bind:        }
{cmd:tupleskount(}{it:t}
[{cmd:,} {it:real scalar all}]{cmd:)}

{p 8 12 2}
{it:real scalar}{bind:        }
{cmd:tupleskountrest(}{it:t}
[{cmd:,} {it:real scalar all}]{cmd:)}


{pstd}
where {it:t} should be declared {it:transmorphic}


{...}
{title:Description}

{pstd}
These functions complement the {helpb tuples} command 
and implement a tuple-combination generator in Mata.

{pstd}
{cmd:tuplesget()}
returns all {it:k}-tuples of the elements of vector {it:v}, one at a time. 
Vector {it:v} is specified by calling {cmd:tuplessetup()} as

            {it:t} {cmd:= tuplessetup(}{it:v}{cmd:,} {it:k}{cmd:)}

{pstd}
and {it:t} is passed to {cmd:tuplesget()}. 
To obtain the tuples, {cmd:tuplesget()} is called repeatedly.
Omitting {it:k} from {cmd:tuplessetup()}
is equivalent to specifying {it:k}={cmd:(1..{helpb mf_length:length({it:v})})}. 

{pstd}
If {it:v} is a {it:rowvetor} or {it:scalar}, 
{cmd:tuplesget()}
returns 1 {it:x} {it:c} vectors;
if {it:v} is a {it:colvector}, 
{cmd:tuplesget()}
returns {it:r} {it:x} 1 vectors.
{cmd:tuplesget()}
returns {cmd:J(1,0,{helpb mf_missingof:missingof({it:v})})}
({it:v} a {it:rowvector} or {it:scalar})
or returns {cmd:J(0,1,{helpb mf_missingof:missingof({it:v})})}
({it:v} a {it:colvector})
after the last {it:k}-tuple has been obtained. 
{cmd:tuplesget()}
returns {cmd:J(0,0,{helpb mf_missingof:missingof({it:v})})}
when {it:k}<1 or {it:k}>{help mf_length:length({it:v})}.

{pstd}
{cmd:tuplesdone()}
returns 1 if all {it:k}-tuples have been obtained, and 0 otherwise.
{cmd:tuplesdone()}
is the recommended way to obtain all {it:k}-tuples:

            {it:t} {cmd:= tuplessetup(}{it:v}{cmd:,} {it:k}{cmd:)}
            {cmd:while ( !tuplesdone(t) ) {c -(} }
                {it:tuple} {cmd:= tuplesget(t)}
                {it:... tuple ...}
            {cmd:{c )-}}

{pstd}
{cmd:tupleskount()}
returns the sequence number of the most recently obtained tuple. 
If {it:all} is omitted or {it:all}!=0, the count includes all tuples, 
including missing tuples for {it:k}<1 or {it:k}>{help mf_length:length({it:v})}.
If {it:all}=0, the count only refers to non-missing tuples.

{pstd}
{cmd:tupleskountrest()}
returns the number of remaining tuples in {it:v}.
If {it:all} is omitted or {it:all}!=0, the count includes all tuples, 
including missing tuples for {it:k}<1 or {it:k}>{help mf_length:length({it:v})}.
If {it:all}=0, the count only refers to non-missing tuples.


{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

        {help tuples_mata##example:Example}
        {help tuples_mata##tuplesdone:Obtaining all {it:k}-tuples}
        {help tuples_mata##methods:Technical note}
        {help tuples_mata##methods:Methods and formulas}


{...}
{marker example}{...}
{title:Example}

        {cmd:: t = tuplessetup(("frog","toad","newt"))}
        {cmd:: while( !tuplesdone(t) ) {c -(}}
        {cmd:>     tuplesget(t)}
        {cmd:> {c )-}}
        {res:frog}
        {res:toad}
        {res:newt}
                1      2
          {c TLC}{hline 15}{c TRC}
        1 {c |}  {res}frog   toad  {txt}{c |}
          {c BLC}{hline 15}{c BRC}{txt}
                1      2
          {c TLC}{hline 15}{c TRC}
        1 {c |}  {res}frog   newt  {txt}{c |}
          {c BLC}{hline 15}{c BRC}{txt}
                1      2
          {c TLC}{hline 15}{c TRC}
        1 {c |}  {res}toad   newt  {txt}{c |}
          {c BLC}{hline 15}{c BRC}{txt}
                1      2      3
          {c TLC}{hline 22}{c TRC}
        1 {c |}  {res}frog   toad   newt  {txt}{c |}
          {c BLC}{hline 22}{c BRC}{txt}


{...}
{marker tuplesdone}{...}
{title:Obtaining all {it:k}-tuples}

{pstd}
Following

        {it:t} {cmd:= tuplessetup(}{it:v}{cmd:,} {it:k}{cmd:)}

{pstd}
the recommended way to obtain all {it:k}-tuples is {cmd:tuplesdone()}:

            {cmd:while ( !tuplesdone(t) ) {c -(} }
                {it:tuple} {cmd:= tuplesget(t)}
                {it:... tuple ...}
            {cmd:{c )-}}

{pstd}
Alternative approaches are often slightly slower or more error-prone. 
For example, 

            {cmd:while ( tupleskountrest(t) ) {c -(} }
                {it:tuple} {cmd:= tuplesget(t)}
                {it:... tuple ...}
            {cmd:{c )-}}

{pstd}
is functionally equivalent to {cmd:tuplesdone()}
but repeatedly counting the remaining tuples adds unnecessary overhead.

{pstd}
Another way to obtain all {it:k}-tuples is by checking for the empty tuple:

            {cmd:while ((}{it:tuple}{cmd:=tuplesget(t)) != J(1,0,"")) {c -(} }
                {it:... tuple ...}
            {cmd:{c )-}}

{pstd}
Unlike the previous two approaches, 
this one assigns the empty tuple, {cmd:J(1,0,"")}, 
to the variable {it:tuple} before the loop terminates. 
More importantly, there's a caveat: 
The empty tuple varies with the 
{help mf_eltype:{it:eltype}}
and
{help mf_eltype:{it:orgtype}}
of {it:v}, 
meaning that 
{cmd:tuplesget()}
may never return 
{cmd:J(1,0,"")},
creating an infinite loop.


{...}
{marker technical}{...}
{title:Technical note}

{pstd}
When you 
{cmd:tuplessetup(}{it:v}{cmd:,} {it:k}{cmd:)}, 
the contents of {it:v} and {it:k} are not stored.  
Instead, pointers to {it:v} and {it:k} are stored.  
This approach saves memory and time, 
but it means that if you change {it:v} or {it:k} after setting them, 
you will change the subsequent behavior of the other 
{cmd:tuples{it:*}()} 
functions.


{...}
{marker methods}{...}
{title:Methods and formulas}

{pstd}
{cmd:tuplesget()}
implements algorithm AS 88 (Gentleman, 1975).


{...}
{marker conformability}{...}
{title:Conformability}

{phang}
    {cmd:tuplessetup(}{it:v}{cmd:,} {it:k}{cmd:)}:
{p_end}
                 {it:v}: 1 {it:x} {it:c} or {it:r} {it:x} 1
                 {it:k}: 1 {it:x} {it:c} or {it:r} {it:x} 1  (optional)
            {it:result}: {it:transmorphic}

{phang}
    {cmd:tuplesget(}{it:t}{cmd:)}:
{p_end}
                 {it:t}: {it:transmorphic}
            {it:result}: 1 {it:x} {it:c} or {it:r} {it:x} 1 or 0 {it:x} 0

{phang}
    {cmd:tuplesdone(}{it:t}{cmd:)}:
{p_end}
                 {it:t}: {it:transmorphic}
            {it:result}: 1 {it:x} 1

{phang}
    {cmd:tupleskount(}{it:t}{cmd:)}:
{p_end}
                 {it:t}: {it:transmorphic}
            {it:result}: 1 {it:x} 1

{phang}
    {cmd:tupleskountrest(}{it:t}{cmd:)}:
{p_end}
                 {it:t}: {it:transmorphic}
            {it:result}: 1 {it:x} 1


{...}
{marker diagnostics}{...}
{title:Diagnostics}

{pstd}
{cmd:tuplesget()}
returns 
{cmd:J(1,0,{helpb mf_missingof:missingof({it:v})})}
({it:v} a rowvector or scalar)
or
{cmd:J(0,1,{helpb mf_missingof:missingof({it:v})})}
({it:v} a colvector)
when there are no more tuples.

{pstd}
{cmd:tuplesget()}
returns 
{cmd:J(0,0,{helpb mf_missingof:missingof({it:v})})}
when {it:k}<1 or {it:k}>{helpb mf_length:length({it:v})}.


{...}
{marker source}{...}
{title:Source code}

{pstd}
{view tuplesget.mata, adopath asis:tuplesget.mata} 
for all functions.
{p_end}


{...}
{title:References}

{pstd}
Gentleman, J. F. 1975. 
Algorithm AS 88: Generation of All NCR Combinations by Simulating Nested Fortran DO Loops. 
Journal of the Royal Statistical Society.
Series C (Applied Statistics), 24(3), pp. 374--376.


{title:Support}

{pstd}
Daniel Klein, German Centre for Higher Education Research and Science Studies{break}
klein.daniel.81@gmail.com

{pstd}
Joseph N. Luchman, Fors Marsh Group LLC{break}
jluchman@forsmarshgroup.com

{pstd}
Nicholas J. Cox, Durham University{break} 
n.j.cox@durham.ac.uk


{title:Also see}

{psee}
Online: {helpb mata}
{p_end}
{psee}
if installed: {help mf_mm_subset:mm_subset()} ({help moremata})
{p_end}
