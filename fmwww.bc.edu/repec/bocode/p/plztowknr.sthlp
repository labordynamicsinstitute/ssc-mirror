{smcl}
{viewerjumpto "Syntax" "plztowknr##syn"}{...}
{viewerjumpto "Options" "plztowknr##opt"}{...}
{viewerjumpto "Description" "plztowknr##des"}{...}
{viewerjumpto "Examples" "plztowknr##exa"}{...}
{viewerjumpto "Acknowledgments" "plztowknr##ack"}{...}
{viewerjumpto "Notes" "plztowknr##not"}{...}
{viewerjumpto "References" "plztowknr##ref"}{...}
{viewerjumpto "Authors" "plztowknr##aut"}{...}
{viewerjumpto "Citation" "plztowknr##cit"}{...}

{title:Title}

{p 4 4 2}{hi:plztowknr} {hline 2} Stata module to translate German ZIP codes into electoral districts 

{marker syn}	
{title:Syntax}

{p 4 8 2}{cmd:plztowknr} {it:{help varname:varname}} [{it:{help if:if}}] [{it:{help in:in}}]
[{it:, }{it:{help plztowknr##opt:options}}]

{p 6 8 2}where {it:{help varname:varname}} has to be a numeric variable 

{synoptset 21 tabbed}{...}
{marker opt}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opth gen:erate(newvar)}}specifies the stub of the new variable(s) containing the electoral district(s){p_end}
{synopt :{opth year(real)}}specifies the election year for which ZIP codes are translated into electoral districts; valid years are 1998, 2002, 2005, 2009, 2013, 2017, 2021, or 2025{p_end}
{synopt :{opth mis:singcode(real)}}defines which values in {it:{help varname:varname}} are treated as missing{p_end}
{synopt :{opt eng:lish}}applies English value and variable labels to {it:newvar}; German labels are used by default{p_end}
{synopt :{opt nog:les}}suppresses the assignment of missing value labels in {it:newvar}; by default, missing value labels follow the scheme of the {browse "https://www.gesis.org/en/gles":German Longitudinal Election Study (GLES)}{p_end}
{synoptline}
{p2colreset}{...}

{marker des}
{title:Description}

{p 4 4 2} The {cmd:plztowknr} module translates German ZIP codes into federal electoral districts (Wahlkreise) for the Bundestag elections of 1998, 2002, 2005, 2009, 2013, 2017, 2021, or 2025.
It is important to note that a given ZIP code may correspond to more than one electoral district.
Accordingly, {cmd:plztowknr} generates a separate variable for each potential electoral district.
For example, a resident of ZIP code 01157 may belong to electoral district 158 or 159 in the 2025 election. In this case, {cmd:plztowknr} creates two additional variables—one for each possible district.
Each of these variables is named using the string specified in {opth gen:erate(newvar)}, followed by a numeric suffix.

{p 4 4 2} There are no official public datasets in Germany that directly link ZIP codes to electoral districts.
The dictionaries used by {cmd:plztowknr} are therefore constructed from multiple administrative sources.
Users should be aware that these dictionaries are not exhaustive and may contain inaccuracies.
Consequently, both the dictionaries and the output of {cmd:plztowknr} must be applied with caution and critically evaluated.

{p 4 4 2} The following section outlines the methodology used to construct the dictionaries for each election year.
The dictionaries for the 2009, 2013, and 2017 federal elections were developed as part of the data preparation for the {browse "https://www.gesis.org/en/gles":German Longitudinal Election Study (GLES)} and are thus more comprehensive than those for earlier years.
The dictionaries for the 2021 and 2025 federal elections were created using the {browse "https://kodaqs-toolbox.gesis.org/github.com/StefanJuenger/zipmatching/index/":AreaMatch tool} (Stroppe et al., 2024) from the KODAQS toolbox provided by {browse "https://www.gesis.org/en/home":GESIS – Leibniz Institute for the Social Sciences}.

{p 4 8 2} {ul:1998} Dictionary parsed from {it:Gemeindeverzeichnis} (directory of municipalities) that is provided by the Federal Statistical Office of Germany.

{p 4 8 2} {ul:2002} Dictionary parsed from {it:Gemeindeverzeichnis} (directory of municipalities) that is provided by the Federal Statistical Office of Germany.

{p 4 8 2} {ul:2005} Dictionary parsed from {it:Gemeindeverzeichnis} (directory of municipalities) that is provided by the Federal Statistical Office of Germany.

{p 4 8 2} {ul:2009} Dictionary parsed from {it:Gemeindeverzeichnis} (directory of municipalities) that is provided by the Federal Statistical Office of Germany and by the search tool provided by the German Bundestag. 

{p 4 8 2} {ul:2013} Dictionary parsed from {it:Gemeindeverzeichnis} (directory of municipalities) that is provided by the Federal Statistical Office of Germany and by the search tool provided by the German Bundestag.

{p 4 8 2} {ul:2017} Dictionary parsed from {it:Gemeindeverzeichnis} (directory of municipalities) that is provided by the Federal Statistical Office of Germany and by the search tool provided by the German Bundestag, using ZIP codes that are provided by the open data project suche-postleitzahl.org.

{p 4 8 2} {ul:2021} Shapefile of the electoral districts provided by {it:Die Bundeswahlleiterin} (Federal Statistical Office of Germany, 2024) and the shapefile of ZIP codes from the ESRI Open Data Portal (2024), combined using an areal matching procedure (see Stroppe et al., 2024).

{p 4 8 2} {ul:2025} Shapefile of the electoral districts provided by {it:Die Bundeswahlleiterin} (Federal Statistical Office of Germany, 2024) and the shapefile of ZIP codes from the ESRI Open Data Portal (2024), combined using an areal matching procedure (see Stroppe et al., 2024).

{marker exa}
{title:Example}

{p 4 4 2} The following command translates ZIP codes from the variable {it:plz} into electoral districts. The resulting districts are stored in newly generated variables named {it:elecdist}, {it:elecdist1}, {it:elecdist2}, etc.
In this example, {cmd:plztowknr} uses the correspondence list for the 2017 German federal election.
Existing missing values in {it:plz} (here: –98 and –99) are ignored when assigning electoral districts.
Since the {opt eng:lish} option is not specified, value and variable labels are generated in German.
Likewise, because {opt nog:les} is not specified, missing value codes are labeled according to the scheme developed by the {browse "https://www.gesis.org/en/gles":German Longitudinal Election Study}.
In the output window, {cmd:plztowknr} provides a summary of assigned, unknown, and ambiguous ZIP codes, as well as the number of missing values (if specified).

	{com}. plztowknr plz, generate(elecdist) year(2017) missingcode(-99 -98)
	{txt}

{p 4 4 2}  The number of system missings are always displayed in the output window; extended missings can be specified in {opt mis:singcode}:

	{com}. plztowknr plz, generate(elecdist) year(2017) missingcode(.a .b)
	{txt}
	
{marker ack}
{title:Acknowledgments}

{p 4 4 2}
The dictionaries for the 2009, 2013, and 2017 federal elections used in {cmd:plztowknr} were developed as part of the data preparation for the {browse "https://www.gesis.org/en/gles":German Longitudinal Election Study}, conducted by {browse "https://www.gesis.org/en/home":GESIS – Leibniz Institute for the Social Sciences}, and were generously made available for use in this Stata module.
The dictionaries for the 2021 and 2025 federal elections were created using the {browse "https://kodaqs-toolbox.gesis.org/github.com/StefanJuenger/zipmatching/index/":AreaMatch tool} (Stroppe et al., 2024) from the KODAQS toolbox provided by {browse "https://www.gesis.org/en/home":GESIS – Leibniz Institute for the Social Sciences}.
	
{marker not}
{title:Notes}

{p 4 4 2} The {cmd:plztowknr} module relies on dictionaries to translate ZIP codes into electoral districts.
To ensure you are using the most recent version, run {it:{help adoupdate:adoupdate}}.
The currently installed version is 3.0 (02 Jul 2025).

{marker ref}
{title:References}

{p 4 4 2} Stroppe, A., Jünger, S., & Straßegger, F. (2024). {browse "https://kodaqs-toolbox.gesis.org/github.com/StefanJuenger/zipmatching/index/":{it:AreaMatch – Assessing geospatial linking of incongruent units.}} KODAQS Toolbox, GESIS – Leibniz Institute for the Social Sciences.

{marker aut}
{title:Authors}

{p 4 4 2} Anne-Kathrin Stroppe, GESIS – Leibniz Institute for the Social Sciences, anne-kathrin.stroppe@gesis.org (corresponding author)

{p 4 4 2} Nils Jungmann, GESIS – Leibniz Institute for the Social Sciences, nils.jungmann@gesis.org

{p 4 4 2} Joss Roßmann, GESIS – Leibniz Institute for the Social Sciences, joss.roßmann@gesis.org 

{p 4 4 2} Malte Kaukal, Hessian State Statistical Office

{p 4 4 2} Konstantin Glinitzer, Austrian Court of Audit 

{p 4 4 2} Tobias Gummer, GESIS – Leibniz Institute for the Social Sciences, tobias.gummer@gesis.org 

{marker cit}
{title:Citation}

{p 4 4 2} Recommended citation (APA Style, 7th ed.): Stroppe, A., Jungmann, N., Roßmann, J., Kaukal, M., Glinitzer, K., & Gummer, T. (2025). {it:PLZTOWKNR: Stata module to translate German ZIP codes into electoral districts} (Version 3.0) [Computer software]. Boston College.

{p 4 4 2} This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

{p 4 4 2} This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details <http://www.gnu.org/licenses/>.
