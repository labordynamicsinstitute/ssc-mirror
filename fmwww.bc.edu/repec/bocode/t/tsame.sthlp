{smcl}
{* 23mar2012}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "drany (drop any)" "help drany"}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:tsame} {hline 2} Sets of records with the same values

{title:Syntax}

{pmore}{cmd:tsame} [{it:{help varelist}}] {ifin} [{cmd:,} {it:options}]

{synoptset 22}
{synopthdr}
{synoptline}
{synopt:{opt m:ultiple(varelist)}}Sets with multiple values of other vars{p_end}
{synopt:{opt h:eadings(details)}}Custom column headings{p_end}
INCLUDE help tabel_out1


{title:Description}

{pstd}{cmd:tsame} shows counts of records, sets, and records/set, where a {bf:set of records} is defined by having all the same values in {it:{help varelist}}. 

{pstd}With the {opt m:ultiple()} option, it will also show how many sets have multiple values of each of the vars in {opt m:ultiple()}.

{pstd}{cmd:tsame} {bf:may} generate a number of variables:{p_end}

{phang2}{cmd:_same} {hline 1} holding the count of records with the same values of {it:{help varelist}}{p_end}

{pmore2}and for each variable {it:Vn} in {opt m:ultiple(varelist)}

{phang2}{cmd:_}{it:Vn}{cmd:_2} and/or{p_end}
{phang2}{cmd:_}{it:Vn}{cmd:_m} {hline 1} both described under {opt m:ultiple()}.

{pstd}Each variable is only generated if it would be informative. For example, {cmd:_same} is only generated if the number of records per set is not uniform.
All generated variables can be dropped with {help drany}.


{title:Options}

{phang}{opt m:ultiple(varelist)} adds columns showing the number of sets that have multiple values of the specified variables. Consider the following dataset:
      
{cmd}{...}
{space 12} name   alias          
{space 12}{hline 24}
{space 12} Bob    Despair        
{space 12} Bob                   
{space 12} Ted    Ned            
{space 12} Ted    Ned            
{space 12} X      Missy          
{space 12} X      Little Miss    
{space 12} Carol  Alice          
{space 12} Carol  Carol the Great
{space 12} Carol  Navarth        
{txt}
{pmore}The output for {cmd:tsame name} would be:

{space 12}   {cmd:Records}{cmd: {c |} }  {cmd:Distinct}  {cmd: {c |} } {cmd:Total} {cmd:  }
{space 12}   {cmd:per Set}{cmd: {c |} }    {cmd:Sets}    {cmd: {c |} }{cmd:Records}{cmd:  }
{space 12}{cmd:{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}}
{space 12}         {cmd:2}{cmd: {c |} }           {cmd:3}{cmd: {c |} }      {cmd:6}{cmd:  }
{space 12}         {cmd:3}{cmd: {c |} }           {cmd:1}{cmd: {c |} }      {cmd:3}{cmd:  }
{space 12}{cmd:{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}}
{space 12}          {cmd:}{cmd: {c |} }           {cmd:4}{cmd: {c |} }      {cmd:9}{cmd:  }

{pmore2}indicating that 3 names are repeated twice, and one name is repeated 3 times.

{pmore}The output for {cmd:tsame name, mult(alias)} would be:

{space 12}   {cmd:Records}{cmd: {c |} }   {cmd:Distinct} {cmd: {c |} } {cmd:Total} {cmd:  }
{space 12}   {cmd:per Set}{cmd: {c |} }     {cmd:Sets}   {cmd: {c |} }{cmd:Records}{cmd:  }
{space 12}{cmd:           {c |}              {c |}         }
{space 12}          {cmd:}{cmd: {c |} }  {cmd:}{cmd:  }{cmd:Multiple}{cmd: {c |} }       {cmd:}{cmd:  }
{space 12}{cmd:           {c |}    {c TLC}---------{c RT}         }
{space 12}          {cmd:}{cmd: {c |} }  {cmd:}{cmd: {c 166} } {cmd:alias} {cmd: {c |} }       {cmd:}{cmd:  }
{space 12}          {cmd:}{cmd: {c |} }  {cmd:}{cmd: {c 166} }{cmd:p2+ p+m}{cmd: {c |} }       {cmd:}{cmd:  }
{space 12}{cmd:{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}}
{space 12}         {cmd:2}{cmd: {c |} } {cmd:3}{cmd: {c 166} }  {cmd:1}{cmd: }  {cmd:1}{cmd: {c |} }      {cmd:6}{cmd:  }
{space 12}         {cmd:3}{cmd: {c |} } {cmd:1}{cmd: {c 166} }  {cmd:1}{cmd: }  {cmd:0}{cmd: {c |} }      {cmd:3}{cmd:  }
{space 12}{cmd:{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}}
{space 12}          {cmd:}{cmd: {c |} } {cmd:4}{cmd: {c 166} }  {cmd:3}{cmd: }  {cmd:1}{cmd: {c |} }      {cmd:9}{cmd:  }

{pmore2}indicating that:

{phang3}o-{space 2}Of the 3 names repeated twice, one has multiple 'present' aliases ({cmd:p2+}), and one has both present and missing aliases ({cmd:p+m}).{p_end}
{phang3}o-{space 2}The 1 name repeated three times has multiple present aliases ({cmd:p2+}), and no missing aliases ({cmd:p+m}).

{pmore}Each column of the {opt m:ultiple()} display may be reflected in the data with a corresponding variable, which holds 0 or 1 depending on whether the relevant set of observations contains multiple values.

{pmore}The example above would result in the following dataset:

{cmd}{...}
{space 12} name   alias            _same  _alias_2  _alias_m  
{space 12}{hline 55}
{space 12} Bob    Despair              2         0         1  
{space 12} Bob                         2         0         1  
{space 12} Ted    Ned                  2         0         0  
{space 12} Ted    Ned                  2         0         0  
{space 12} X      Missy                2         1         0  
{space 12} X      Little Miss          2         1         0  
{space 12} Carol  Alice                3         1         0  
{space 12} Carol  Carol the Great      3         1         0  
{space 12} Carol  Navarth              3         1         0  

{txt}
{phang}{opt h:eadings(details)} allows you to substitute your own text for the top-most column headings {hline 1}
useful for displaying the meanings in a particular context. For example, 'Visits' and 'Patients' instead of 'Records per Set' and 'Distinct Sets'. The syntax is:

{pmore2}{cmdab:h:eadings(} [{it:text}] [{cmd:,}][{it:text}] [{cmd:,}][{it:text}] {cmd:)}

{pmore}where {it:text} before any commas will head the first column ({cmd:Records per Set}), text after the first comma will head the second column ({cmd:Distinct Sets}),
and text after the second column will head the third column ({cmd:Total Records}).

{phang}{it:{help outopt:out option}} specifies output style & destination.
             
