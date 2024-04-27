{smcl}

{title:Title}

{phang}
{bf:sicff} {hline 2} Create Fama French Industry from Standard Industrial Classification (SIC) Code


{title:Syntax}

{p 8 17 2}
{cmd:sicff} {varname} {cmd:,} industry(#) [generate(newvar) longlabels]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth ind:ustry(#)}}choose which Fama French industry to create — 5, 10, 12, 17, 30, 38, 48, or 49{p_end}
{synopt:{opth gen:erate(newvar)}}create variable named {it:newvar}; default name for {it:newvar} is {it:ff_#}{p_end}
{synopt:{opt l:onglabels}}use long labels for the industries; default is short labels{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:sicff} takes a 4-digit numeric SIC code ({it:varname}) and creates a new variable that contains the specified Fama and French industry. By default, a short label is applied to the new variable. See Ken French's website for more details on the industry classifications: http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html

{title:The "Other" category}

{pstd}
SIC codes fall between 0100 and 9999. Any erroneous values outside this range will result in missing values for the new industry variable.

{pstd}
Some of the industries — 17, 30, 48, 49 — classify the "Other" category as explicit SIC code ranges. For these industries, SIC codes that fall outside any defined range will result in missing values for the new industry variable.

{pstd}
The remaining industries — 5, 10, 12, 38 — classify the "Other" category as a catch-all for the remaining SIC codes that are not explicitly defined. For these industries, SIC codes that fall outside any defined range will be classified as "Other." It is the user's responsibility to ensure that the SIC codes are valid.


{title:Examples}

{phang}{cmd:. sicff sic, ind(48)}{p_end}

{phang}{cmd:. sicff sic, ind(12) gen(ff12industry)}{p_end}

{phang}{cmd:. sicff sic, ind(49) l}{p_end}


{title:Author}

Tyson Van Alfen
Email: tyson.vanalfen@pm.me
Website: https://tysonvanalfen.com
