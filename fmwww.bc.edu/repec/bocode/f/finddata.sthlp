{smcl}
{* 12dec20114}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "recent" "recent"}{...}
INCLUDE help also_vlowy
{title:Title} 
 
{pstd}{bf:finddata} - find matching values in an external file; optionally copy data

{title:Syntax} 
 
{pmore}
{cmdab:findd:ata} {it:findvars} {cmd:using} {it:{help path_el}} {ifin} [{cmd:,} {it:options}]

{pstd}Where {it:findvars} is a {it:{help varelist}} that can also include:

{pmore}{it:varname_c}{cmd:=}{it:varname_e}

{pstd}Where:

{pmore}{it:varname_c} is a {varname} in the current data

{pmore}{it: varname_e} is the {varname} of a corresponding variable in the external file 


{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt c:opy(copyvars)}}copy variables into the current data from the external file{p_end}
{synopt :{cmdab:comp:lement}}add records from the external file that were {it:not} found{p_end}
{synopt :{cmdab:d:istinct}}use only distinct records from the external file{p_end}
{synopt :{cmdab:exp:and}}{help expand} current records to pair with all found records{p_end}
{synopt :{cmdab:one:find}}flag an error if more than one current record finds the same external record{p_end}
{synopt :{cmdab:norep:lace}}flag an error if an existing variable would be replaced{p_end}
{synopt :{cmdab:picky}}use the exact values of string {it:findvars}{p_end}
{synopt :{cmdab:pass()}}pass along import parameters{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}{cmdab:findd:ata} finds records in an external file, based on matching {it:findvars}. Where a variable is named differently in the current data and the external file, use 

{pmore}{it:varname_c}{cmd:=}{it:varname_e}

{pstd}When a {it:findvar} is string in one place, and numeric in the other, the string will be converted to a number before matching.
If the string contains non-numeric characters, it will cause an error.

{pstd}{cmdab:findd:ata} creates a variable named {cmd:_found} in the current data, replacing any previous versions. It holds, for each record in the current data, the number of records found in the external file.

{phang2}o-{space 2}Records excluded by {it:if}/{it:in} will have {cmd:_found}={cmd:.e}{p_end}
{phang2}o-{space 2}Records added by {opt comp:lement} will have {cmd:_found}={cmd:.c}{p_end}
{phang2}o-{space 2}Records expanded will have duplicate values of {cmd:_found}.

{pstd}{cmdab:findd:ata} also leaves three return values:

{phang2}o-{space 2}{cmd:r(complement)} holds the number of records in the external file that were {it:not} found.{p_end}
{phang2}o-{space 2}{cmd:r(added)} holds the names of variables added to the current data.{p_end}
{phang2}o-{space 2}{cmd:r(replaced)} holds the names of variables replaced by those from the external file.{p_end}

{title:Options}

{phang}{opt copy(copyvars)} specifies variables to copy into the current data from the external file, and optionally their names in the current data.
{it:copyvars} is a {it:{help varelist}} that can also include:

{pmore2}{it:varname_e}{cmd:->}{it:varname_c}

{pmore}to copy in (external) {it:varname_e} as (current data) {it:varname_c}.

{phang2}{bf:[+]} When a variable is copied in under the same name as an existing variable, the existing variable is {bf:replaced} with the external variable.

{phang}{opt d:istinct} filters the external file so that only distinct records are considered. That is, just one record for every combination of {it:findvars} and {it:copyvars}.

{pmore}The filtering happens {bf:before} comparisons with the current data, so {opt d:istinct} affects all record counts, including those in {cmd:_found}, {opt comp:lement}, {opt exp:and}, and {opt one:find}.

{phang}{opt comp:lement} adds records from the external file that did {bf:not} match on {it:findvars}.

{pmore}Note that the return value {cmd:r(complement)} holds the count of unmatched records, whether or not they are added.

{phang}{opt exp:and} allows one record in the current data to find more than one external record. Each current record will be {help expand:expanded} so that it can be paired with each external record.
If {opt exp:and} is not specified, any {cmd:_found}>1 will cause an error.

{phang}{opt one:find} requires that only one current record may find the same external record. 

{phang}{opt norep:lace} will force an error if an existing variable would be replaced by external data.

{phang}{opt picky} affects string matching. Ordinarily, {cmdab:findd:ata} ignores leading and trailing spaces, multiple internal spaces, and uppler/lower case. {opt picky} specifies matching on all of those things.

{phang}{opt pass()} passes import/export options along to the appropriate handler.

{phang2}o-{space 2}For file extensions {cmd:.txt} or {cmd:.csv}, the options are those for {help import delimited}.{p_end}
{phang2}o-{space 2}For file extensions  {cmd:.xl}, {cmd:.xls} or {cmd:.xlsx}, the options are described under {help portel xl}.{p_end}
{phang2}o-{space 2}For other file extensions (besides {cmd:.dta}), the options are those for {help callst}.{p_end}

