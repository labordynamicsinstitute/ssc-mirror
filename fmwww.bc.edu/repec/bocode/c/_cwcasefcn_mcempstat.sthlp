{smcl}
{* version 1.1.0  19aug2026}{...}
{hi:case.mcempstat()} {hline 2} Multilevel Socio-Economic Classes employment status case function

{title:Syntax}

        {cmd:case.mcempstat(}{help varname:{it:sempl}} [{help varname:{it:supvis}}]{cmd:)}

    {it:sempl}!=0 indicates that a respondent is self-employed
    if {it:sempl}==0: {it:supvis}>0 indicates that a respondent has supervisory status
    if {it:sempl}!=0: {it:supvis} specifies the number of employees

{title:Description}

{pstd}
    {helpb crosswalk} case function for use with the Multilevel Socio-Economic Classes translation
    tables. The function distinguishes the following cases:

        1 = employment status unknown ({it:sempl} missing, or {it:supvis}
            missing, negative, or not specified)
        2 = employed, without supervisory status
        3 = employed, with supervisory status
        4 = self-employed, no employees
        5 = self-employed, 1-9 employees
        6 = self-employed, 10 or more employees

{pstd}
    This uses the same 1-6 case numbering as
    {helpb _cwcasefcn_esec88:case.esec88()}, so either function can be used
    with the {cmd:mc.} tables. They are {bf:not} interchangeable, however,
    when {it:supvis} is missing, negative, or not specified:
    {cmd:case.esec88()} still defaults those to {it:supvis}=0, while
    {cmd:case.mcempstat()} codes them as unknown employment status (case 1);
    see below.

{pstd}
    Employees with supervisory status are employees who have formal
    responsibility for supervising the work of other employees. If the data
    does not contain a direct measure of supervisory status, Harrison and Rose
    (2006, section 4.7) suggest coding employees as supervisors if they are
    supervising at least three people.

{pstd}
    Missing data is treated as missing, not silently recoded. Missing or
    negative values in {it:supvis} are coded as unknown employment status
    (case 1), {bf:not} as {it:supvis}=0: the package never assumes that an
    unmeasured supervisor is a non-supervisor. If you want that assumption,
    make it explicitly by recoding {it:supvis} to 0 yourself before calling
    this function. If {it:supvis} is not specified at all, every observation
    is coded as unknown employment status (case 1), because supervisory
    status cannot be determined without it.

{pstd}
    Unlike ESeC, the Multilevel Socio-Economic Classes schemes have no simplified variant for unknown
    employment status: column 1 of every {cmd:mc.} table is {cmd:.}, so
    observations coded as case 1 -- whether because {it:sempl} is missing or
    because {it:supvis} is missing, negative, or not specified -- come back
    uncoded.

{title:Examples}

{phang2}{cmd:. crosswalk micro = mc.isco08_to_micro(isco08 case.mcempstat(selfemp nsuperv))}{p_end}
{phang2}{cmd:. crosswalk macro = mc.isco88com_to_macro(isco88 case.mcempstat(selfemp nsuperv))}{p_end}

{title:References}

{phang}
    Harrison, E., D. Rose. 2006. The European Socio-economic Classification
    (ESeC) User Guide. Institute for Social and Economic Research, University
    of Essex. Available from
    {browse "http://www.iser.essex.ac.uk/archives/esec/user-guide"}.
    {p_end}
{hline}
{asis}
// parse input
gettoken case   0 : 0
gettoken touse  0 : 0
gettoken sempl  0 : 0
gettoken supvis 0 : 0
if `"`0'"'!="" error 198
unab sempl: `sempl', min(1) max(1)
if `"`supvis'"'!="" {
    unab supvis: `supvis', min(1) max(1)
    count if `supvis'>=. & `sempl'<. & `touse'
    if r(N) noi di as txt "({cmd:`supvis'}: missing values treated as unknown employment status)"
    count if `supvis'<0 & `sempl'<. & `touse'
    if r(N) noi di as txt "({cmd:`supvis'}: negative values treated as unknown employment status)"
}
else noi di as txt "({it:supvis} not specified; employment status treated as unknown)"
// generate cases; default is 1 (unknown), which is also the outcome when
// sempl is missing or supvis is missing/negative/not specified
replace `case' = 1 if `touse'
if "`supvis'"!="" {
    replace `case' = 2 if `sempl'==0 & `touse' & `supvis'>=0 & `supvis'<.
    replace `case' = 4 if `sempl'!=0 & `sempl'<. & `touse' & `supvis'>=0 & `supvis'<.
    replace `case' = 3 if `supvis'>=1  & `supvis'<.  & `case'==2 & `touse'
    replace `case' = 5 if `supvis'>=1  & `supvis'<10 & `case'==4 & `touse'
    replace `case' = 6 if `supvis'>=10 & `supvis'<.  & `case'==4 & `touse'
}
