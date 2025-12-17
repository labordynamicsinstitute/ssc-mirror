{smcl}
{* *! version 1.1  15dec2025}{...}
{vieweralsosee "[D] generate" "help generate"}{...}
{vieweralsosee "[D] encode" "help encode"}{...}
{viewerjumpto "Syntax" "sic_to_ff##syntax"}{...}
{viewerjumpto "Description" "sic_to_ff##description"}{...}
{viewerjumpto "Options" "sic_to_ff##options"}{...}
{viewerjumpto "Remarks" "sic_to_ff##remarks"}{...}
{viewerjumpto "Examples" "sic_to_ff##examples"}{...}
{viewerjumpto "Industry Schemes" "sic_to_ff##schemes"}{...}
{viewerjumpto "Technical Notes" "sic_to_ff##technical"}{...}
{viewerjumpto "Installation" "sic_to_ff##installation"}{...}
{viewerjumpto "References" "sic_to_ff##references"}{...}
{viewerjumpto "Author" "sic_to_ff##author"}{...}
{title:Title}

{phang}
{bf:sic_to_ff} {hline 2} Convert SIC codes to Fama-French industry classifications


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:sic_to_ff}
{varname}
[{varname}]
{ifin}
{cmd:,} {opth gen:erate(newvar)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth gen:erate(newvar)}}name of new variable to create{p_end}

{syntab:Optional}
{synopt:{opt sch:eme(#)}}industry classification scheme: 5, 10, 12, 17, 30, 38, 48, or 49; default is {bf:48}{p_end}
{synopt:{opt lab:els}}apply value labels to the new variable{p_end}
{synopt:{opt replace}}overwrite existing variable{p_end}
{synopt:{opt nomissing}}force all valid SICs into an industry (assign unmapped to Other){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
If two variables are specified, the first is used as the primary SIC and the 
second as a fallback when the primary is missing. This is useful for Compustat 
data where {bf:sich} (historical SIC) is preferred but {bf:sic} can fill gaps.


{marker description}{...}
{title:Description}

{pstd}
{cmd:sic_to_ff} converts Standard Industrial Classification (SIC) codes to 
Fama-French industry classifications. The command supports all major 
Fama-French industry classification schemes: FF5, FF10, FF12, FF17, FF30, 
FF38, FF48, and FF49.

{pstd}
The command accepts both numeric and string SIC codes. String SIC codes are 
automatically converted to numeric values. Non-numeric strings (e.g., "XXXX") 
are treated as missing.

{pstd}
The Fama-French industry classifications are widely used in empirical 
accounting and finance research to group firms by industry. These 
classifications are based on four-digit SIC codes and are maintained by 
Kenneth R. French on his data library website.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth generate(newvar)} specifies the name of the new variable to be created 
containing the Fama-French industry code.

{dlgtab:Optional}

{phang}
{opt scheme(#)} specifies which Fama-French industry classification scheme 
to use. Valid values are 5, 10, 12, 17, 30, 38, 48, or 49. The default is 48, 
which is the most commonly used classification in the literature.

{phang}
{opt labels} attaches value labels to the new variable, showing the standard 
Fama-French industry abbreviations (e.g., "Agric", "Food", "Hlth").

{phang}
{opt replace} permits {cmd:sic_to_ff} to overwrite an existing variable.

{phang}
{opt nomissing} forces all observations with valid SIC codes into an industry 
classification. Without this option, SIC codes that do not match any explicit 
range in Ken French's definitions remain missing for FF17, FF30, FF38, FF48, 
and FF49 schemes. With this option, unmapped SICs are assigned to "Other". 
FF5, FF10, and FF12 always use catch-all "Other" behavior regardless of this option.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Using sich and sic from Compustat}

{pstd}
In Compustat, there are two SIC variables:

{p2colset 5 12 14 2}{...}
{p2col:{bf:sich}}Standard Industrial Classification - Historical (numeric). 
Reflects the SIC code at the time of the fiscal year-end. Preferred for research 
but has more missing values.{p_end}
{p2col:{bf:sic}}Standard Industry Classification Code (string). 
Current/header SIC code. More complete but may not reflect historical classification.{p_end}
{p2colreset}{...}

{pstd}
Best practice is to use {bf:sich} as the primary variable with {bf:sic} as fallback:

{phang2}{cmd:. sic_to_ff sich sic, gen(ff48) labels}{p_end}

{pstd}
This uses {bf:sich} when available and falls back to {bf:sic} only when {bf:sich} 
is missing. The command reports how many observations were filled using the 
fallback variable.

{pstd}
{bf:Handling of unmapped SIC codes}

{pstd}
Ken French's industry classification files define "Other" using explicit SIC 
ranges for the 17, 30, 48, and 49 industry schemes. SIC codes outside these 
defined ranges are technically unclassified.

{pstd}
By default, {cmd:sic_to_ff} respects this behavior: for FF17/30/38/48/49, 
SIC codes that do not match any explicit range are left as missing. This 
matches Ken French's original methodology.

{pstd}
The {opt nomissing} option changes this behavior to assign all unmapped SICs 
to "Other", which is useful when you need complete industry coverage. This 
is similar to the behavior of some other implementations (e.g., {cmd:ffind} 
with the {opt nomiss} option).

{pstd}
For FF5, FF10, and FF12, all valid SICs are always assigned to some industry 
(including "Other" as a catch-all), regardless of the {opt nomissing} option.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage with FF48 (default):{p_end}
{phang2}{cmd:. sic_to_ff sic, gen(ff48)}{p_end}

{pstd}Using FF12 classification with labels:{p_end}
{phang2}{cmd:. sic_to_ff sic, gen(ff12) scheme(12) labels}{p_end}

{pstd}Using FF49 with Software industry:{p_end}
{phang2}{cmd:. sic_to_ff sic, gen(ff49) scheme(49) labels}{p_end}

{pstd}Force all SICs into industries (no missing):{p_end}
{phang2}{cmd:. sic_to_ff sic, gen(ff48_all) scheme(48) labels nomissing}{p_end}

{pstd}Replace existing variable:{p_end}
{phang2}{cmd:. sic_to_ff siccd, gen(ff_ind) scheme(48) labels replace}{p_end}

{pstd}Create multiple classifications:{p_end}
{phang2}{cmd:. sic_to_ff sic, gen(ff48) scheme(48) labels}{p_end}
{phang2}{cmd:. sic_to_ff sic, gen(ff12) scheme(12) labels}{p_end}
{phang2}{cmd:. sic_to_ff sic, gen(ff5) scheme(5) labels}{p_end}

{pstd}Use with Compustat data:{p_end}
{phang2}{cmd:. use compustat_annual, clear}{p_end}
{phang2}{cmd:. sic_to_ff sich, gen(ff48) labels}{p_end}

{pstd}Use sich as primary, sic as fallback when sich is missing:{p_end}
{phang2}{cmd:. sic_to_ff sich sic, gen(ff48) labels}{p_end}

{pstd}Works with string SIC codes too:{p_end}
{phang2}{cmd:. sic_to_ff sic_str, gen(ff48) labels}{p_end}


{marker schemes}{...}
{title:Industry Classification Schemes}

{pstd}
The following schemes are available:

{p2colset 5 15 17 2}{...}
{p2col:Scheme}Description{p_end}
{p2line}
{p2col:{bf:5}}Consumer, Manufacturing, High-Tech, Health, Other{p_end}
{p2col:{bf:10}}Consumer NonDurables, Consumer Durables, Manufacturing, Energy, 
High-Tech, Telecom, Shops, Health, Utilities, Other{p_end}
{p2col:{bf:12}}Adds Chemicals, Business Equipment, and Finance to FF10{p_end}
{p2col:{bf:17}}More granular breakdown including Food, Mining, Oil, Construction{p_end}
{p2col:{bf:30}}Detailed classification with 30 industries{p_end}
{p2col:{bf:38}}Simple 2-digit SIC-based classification (37 industries + Other){p_end}
{p2col:{bf:48}}Most commonly used comprehensive 48-industry classification{p_end}
{p2col:{bf:49}}FF48 plus Computer Software industry (industries renumbered){p_end}
{p2line}
{p2colreset}{...}

{pstd}
{bf:FF48 Industry Names}:

{p2colset 5 10 12 2}{...}
{p2col:1}Agric (Agriculture){p_end}
{p2col:2}Food (Food Products){p_end}
{p2col:3}Soda (Candy and Soda){p_end}
{p2col:4}Beer (Beer and Liquor){p_end}
{p2col:5}Smoke (Tobacco Products){p_end}
{p2col:6}Toys (Recreation){p_end}
{p2col:7}Fun (Entertainment){p_end}
{p2col:8}Books (Printing and Publishing){p_end}
{p2col:9}Hshld (Consumer Goods){p_end}
{p2col:10}Clths (Apparel){p_end}
{p2col:11}Hlth (Healthcare){p_end}
{p2col:12}MedEq (Medical Equipment){p_end}
{p2col:13}Drugs (Pharmaceutical Products){p_end}
{p2col:14}Chems (Chemicals){p_end}
{p2col:15}Rubbr (Rubber and Plastic Products){p_end}
{p2col:16}Txtls (Textiles){p_end}
{p2col:17}BldMt (Construction Materials){p_end}
{p2col:18}Cnstr (Construction){p_end}
{p2col:19}Steel (Steel Works){p_end}
{p2col:20}FabPr (Fabricated Products){p_end}
{p2col:21}Mach (Machinery){p_end}
{p2col:22}ElcEq (Electrical Equipment){p_end}
{p2col:23}Autos (Automobiles and Trucks){p_end}
{p2col:24}Aero (Aircraft){p_end}
{p2col:25}Ships (Shipbuilding, Railroad Equipment){p_end}
{p2col:26}Guns (Defense){p_end}
{p2col:27}Gold (Precious Metals){p_end}
{p2col:28}Mines (Non-Metallic Mining){p_end}
{p2col:29}Coal{p_end}
{p2col:30}Oil (Petroleum and Natural Gas){p_end}
{p2col:31}Util (Utilities){p_end}
{p2col:32}Telcm (Communication){p_end}
{p2col:33}PerSv (Personal Services){p_end}
{p2col:34}BusSv (Business Services){p_end}
{p2col:35}Comps (Computers){p_end}
{p2col:36}Chips (Electronic Equipment){p_end}
{p2col:37}LabEq (Measuring and Control Equipment){p_end}
{p2col:38}Paper (Business Supplies){p_end}
{p2col:39}Boxes (Shipping Containers){p_end}
{p2col:40}Trans (Transportation){p_end}
{p2col:41}Whlsl (Wholesale){p_end}
{p2col:42}Rtail (Retail){p_end}
{p2col:43}Meals (Restaurants, Hotels, Motels){p_end}
{p2col:44}Banks (Banking){p_end}
{p2col:45}Insur (Insurance){p_end}
{p2col:46}RlEst (Real Estate){p_end}
{p2col:47}Fin (Trading){p_end}
{p2col:48}Other{p_end}
{p2colreset}{...}

{pstd}
{bf:FF49 differs from FF48} by adding a Computer Software industry (Softw) at 
position 36, which includes SIC codes 7370-7373 and 7375 (carved out from 
BusSv and Comps). Note that SIC 7374 (Computer Processing) remains in BusSv. 
Industry 35 is relabeled from "Comps" to "Hardw" (Hardware) in FF49, reflecting 
that Software has been separated out. All subsequent industries are renumbered: 
Chips becomes 37, LabEq becomes 38, etc., and Other becomes industry 49.


{marker technical}{...}
{title:Technical Notes}

{pstd}
{bf:SIC code handling}

{phang}1. Both numeric and string SIC variables are accepted. String values are 
converted using Stata's {cmd:real()} function.{p_end}

{phang}2. SIC codes outside the valid range (0-9999), non-integer values, or 
non-numeric strings result in missing industry classifications.{p_end}

{pstd}
{bf:Notable classification decisions}

{phang}3. {bf:SIC 3622 (Industrial Controls)} handling varies by scheme: In FF5 
and FF10, 3622 is explicitly assigned to High-Tech (carved out from Manuf). 
In FF12, 3622 remains in Manufacturing per Ken French's definition. In FF48, 
3622 is assigned to Chips (Electronic Equipment).{p_end}

{phang}4. {bf:FF49 Software industry} includes SIC 7370-7373 and 7375. Note that 
SIC 7374 (Computer Processing) remains in Business Services per Ken French's 
specification.{p_end}

{phang}5. {bf:Unmapped SIC codes} are handled differently by scheme: FF5/10/12 
always assign unmapped codes to "Other", consistent with these being aggregate 
schemes. FF17/30/38/48/49 leave unmapped codes as missing by default (per Ken 
French's methodology), unless the {opt nomissing} option is specified.{p_end}

{phang}6. {bf:FF38} is Ken French's simple 2-digit SIC-based classification, 
where industries correspond roughly to SIC major groups (e.g., Food = 2000-2099, 
Chemicals = 2800-2899). This is distinct from the more detailed FF48 scheme 
that uses precise 4-digit SIC ranges.{p_end}


{marker installation}{...}
{title:Installation}

{pstd}
To install {cmd:sic_to_ff}, place both files in your personal ado directory:

{phang}1. Find your personal ado directory by typing in Stata:{p_end}
{phang2}{cmd:. sysdir}{p_end}

{pstd}
Look for the {bf:PLUS} or {bf:PERSONAL} directory path.

{phang}2. Copy the files to that directory:{p_end}
{phang3}{cmd:sic_to_ff.ado}{p_end}
{phang3}{cmd:sic_to_ff.sthlp}{p_end}

{pstd}
Typical locations:

{p2colset 5 20 22 2}{...}
{p2col:Windows}C:\ado\plus\s\{p_end}
{p2col:Mac}/Users/{it:username}/Library/Application Support/Stata/ado/plus/s/{p_end}
{p2col:Linux}~/ado/plus/s/{p_end}
{p2colreset}{...}

{pstd}
Note: Place files in the {bf:s} subdirectory (first letter of the command name). 
Create the subdirectory if it does not exist.

{phang}3. Verify installation:{p_end}
{phang2}{cmd:. which sic_to_ff}{p_end}
{phang2}{cmd:. help sic_to_ff}{p_end}


{marker references}{...}
{title:References}

{pstd}
Fama, Eugene F., and Kenneth R. French. 1997. "Industry Costs of Equity." 
{it:Journal of Financial Economics} 43(2): 153-193.

{pstd}
Kenneth R. French Data Library: 
{browse "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html"}


{marker author}{...}
{title:Author}

{pstd}
Kelvin Law{break}
Nanyang Business School{break}
Nanyang Technological University{break}
Singapore

{pstd}
Comments and suggestions are welcome.


{title:Also see}

{psee}
Manual: {manlink D generate}, {manlink D encode}

{psee}
Online: {helpb generate}, {helpb encode}, {helpb label}
{p_end}
