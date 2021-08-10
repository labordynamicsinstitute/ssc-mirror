{smcl}
{* 3may2015}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "usel" "usel"}{...}
{vieweralsosee "savel" "savel"}{...}
{vieweralsosee "finddata" "findd"}{...}
{vieweralsosee "collect" "collect"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:portel xl} {c -} port ms excel files


{title:On Export}

{phang}o-{space 2}The data is written to the first sheet.{p_end}
{phang}o-{space 2}Variable names are placed in the first row{p_end}
{phang}o-{space 2}Variables with value labels are written to two columns: {it:varname}, holding the numeric value; and {it:varname}{cmd:_vl}, holding the labeled value.{p_end}
{phang}o-{space 2}Variable (name) labels, formats, and characteristics are written to a second sheet, named {cmd:characteristics}.
The first row has variable names; the first column has characteristic names, and the cells hold characteristic values.

{pstd}{ul:{bf:Options}}

{phang}{opt xls} specifies writing the file in {cmd:xls} rather than {cmd:xlsx} format. The actual file extension triggering the port can be {cmd:.xl}, {cmd:.xls}, or {cmd:.xlsx},
but the file will be written as {cmd:.xlsx} unless {opt xls} is specified.

{phang}{opt color:s} specifies using certain data columns to set text and/or background colors, rather than exporting those columns as data:

{pmore}For pairs of variables named {it:varname} and {it:varname}{cmd:_bc}, {it:varname}{cmd:_bc} will be used to set the background colors for {it:varname}, on the assumption that {it:varname}{cmd:_bc} holds rgb values.

{pmore}The same goes for pairs of variables named {it:varname} and {it:varname}{cmd:_tc}, except that {it:varname}{cmd:_tc} will be used to set the text colors for {it:varname}.

{phang}{opt datestring()}, {opt missing()} and {opt locale()} can all be used as described in {help export excel}.


{title:On Import}

{phang}o-{space 2}The file extension {cmd:.xl} can be used as a synonym for {cmd:.xlsx}.{p_end}
{phang}o-{space 2}If a file is not found with the specified extension (ie, {cmd:.xlsx} or {cmd:.xls}), the alternate will be tried. If neither is found, an error will be generated.

{phang}o-{space 2}Data is read from the first sheet, by default.{p_end}
{phang}o-{space 2}Variable names are read from the first row, by default.{p_end}
{phang}o-{space 2}Variable names are converted to lowercase, by default.{p_end}
{phang}o-{space 2}For pairs of numeric and string variables named {it:varname} and  {it:varname}{cmd:_vl}, respectively, {it:varname}{cmd:_vl} will be used to create value labels for {it:varname}, and will not be imported as data.{p_end}
{phang}o-{space 2}If a sheet named {cmd:characteristics} is present, and is configured properly and matches the dataset variables, it will be used to set variable characteristics, including labels and formats.{p_end}

{pstd}{ul:{bf:Options}}

{phang}{opt non:ames} specifies treating the first row as data, rather than variable names.

{phang}{opt color:s} specifies importing the colors of cell text and backgrounds, as data columns of rgb values.

{pmore}For each column ({it:varname}) with colored text and/or background, one or two additional data columns will be created:
One named {it:varname}{cmd:_bc} holding the background colors, and one named {it:varname}{cmd:_tc} holding the text colors.

{phang}{opt sh:eet()}, {opt cellra:nge()}, {opt case()}, {opt all:string}, and {opt locale()} can all be used as described under {help import excel}. (But, as noted above, the default for {opt case()} is {opt l:ower})

{title:Remarks}

{pstd}Reading or writing colors could take an extremely long time for any substantial dataset. In the contexts in which it's likely to arise, however, it should be fine. 

