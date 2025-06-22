{smcl}
{* *! version 1.0.0 20jun2025 by Gutama Girja Urago}
{hline}
help for {hi:ethiodate}
{hline}

{title:Title}

{pstd}
{bf:ethiodate} {hline 2} Ethiopian Date Conversion Utilities

{title:Description}

{pstd}
The {cmd:ethiodate} package offers a fast, reliable, and user-friendly solution for converting dates between the Gregorian and Ethiopian calendar systems directly within Stata. 

{pstd}
Built in Mata for maximum computational efficiency, it ensures seamless integration with Stata’s time and date functionalities. It provides the tools you need for precise calendar conversion—handling leap years, multiple time formats, and large datasets with ease.

{pstd}
The package includes two key commands:

{phang2}
{help to_ethiopian:{bf:to_ethiopian}} — Converts Gregorian dates (in Stata’s %td, %tc, or %tC formats) into Ethiopian calendar components: year, month, and day.

{phang2}
{help to_gregorian:{bf:to_gregorian}} — Converts Ethiopian calendar dates (entered as numeric year, month, and day) into properly formatted Gregorian dates (%td).

{pstd}
Both commands are vectorized for high performance and are designed to work seamlessly in both interactive use and automated do-file processing. With {cmd:ethiodate}, users no longer need to rely on external tools or manual calculations—Stata becomes fully capable of handling Ethiopian calendar data with precision and speed.

{title:Ethiopian Calendar}

{pstd}
The Ethiopian calendar is a solar calendar based on the ancient Coptic system, comprising 13 months: twelve months of 30 days each and a thirteenth month, Pagume, with 5 days (or 6 in a leap year). It is roughly seven to eight years behind the Gregorian calendar and marks the New Year on September 11 (or September 12 in Gregorian leap years).

{pstd}
Leap years in the Ethiopian calendar occur every four years, just like in the Gregorian system, but without exceptions for years divisible by 100 and not by 400. This results in consistent leap year patterns that simplify calendar calculations.

{pstd}
Because of its distinct structure and cultural importance, the Ethiopian calendar is widely used for official, religious, and civil purposes in Ethiopia. Accurate conversion between the Ethiopian and Gregorian systems is essential for longitudinal data analysis, survey work, policy evaluation, and any research or administrative activity involving Ethiopian dates.

{pstd}
The {cmd:ethiodate} package accounts for all these nuances, enabling Stata users to reliably convert and analyze dates across both systems.


{title:Author}

{pstd}
Gutama Girja Urago, Laterite Consulting PLC, gurago@laterite.com




