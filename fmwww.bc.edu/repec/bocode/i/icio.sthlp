{smcl}
{* *! version 1.1.0  9mar2021}{...}
{cmd:help icio}{right: ({browse "https://doi.org/10.1177/1536867X221083931":SJ22-1: st0651_1})}
{hline}

{title:Title}

{p2colset 5 13 15 2}{...}
{p2col :{cmd:icio} {hline 2}}Economic analysis with intercountry input-output
tables{p_end}
{p2colreset}{...}


{title:Syntax}

{phang}
{ul:{hi:{help icio##load:Load an intercountry input-output (ICIO) table}}} (required to run {cmd:icio})

{p 8 16 2}
{cmd:icio_load,} [{it:{help icio##icioload_options:icio_load_options}}]

{phang}
Erase {cmd:icio}-related tables and ancillary files

{p 8 16 2}
{cmd:icio_clean}

{phang}
List of countries and sectors in the loaded ICIO table

{p 8 16 2}
{cmd:icio,} {opt info}

{phang}
{ul:{hi:{help icio##supplydemand:Supply, final demand, and supply-final demand linkages}}}

{p 8}
{hi: 1. Gross domestic product (GDP):}

{p 11 15 2}
{cmd:icio,} {cmd:origin(}{it:country_code} [{cmd:,} {it:sector_code}]{cmd:)} 
[{it:{help icio##icio_options:standard_options}}]

{p 8}
{hi: 2. Final demand:}

{p 11 15 2}
{cmd:icio,} {cmd:destination(}{it:country_code} [{cmd:,}
{it:sector_code}]{cmd:)}
[{it:{help icio##icio_options:standard_options}}]

{p 8}
{hi: 3. Value added by origin and final destination:}

{p 11 15 2}
{cmd:icio,} {cmd:origin(}{it:country_code} [{cmd:,} {it:sector_code}]{cmd:)} 
{cmd:destination(}{it:country_code} [{cmd:,} {it:sector_code}]{cmd:)} 
[{it:{help icio##icio_options:standard_options}}]

{phang}
{ul:{hi:{help icio##vatrade:Value-added decomposition of trade flows and global value chain (GVC) participation}}}

{p 8}
{hi: 1. Value added and GVC participation in total exports of a country:}

{p 11}
a. Value added and GVC participation in {cmd:total aggregate exports}:

{p 14 18 2}
{cmd:icio,} {cmdab:exp:orter(}{it:country_code}{cmd:)} 
[{it:{help icio##icio_1a_options:methods_1a}}] 
[{it:{help icio##icio_out_options:results_exports}}] 
[{it:{help icio##icio_ori_dest_options:origin_destination}}]
[{it:{help icio##icio_options:standard_options}}]

{p 11}
b. Value added and GVC participation in {cmd:total sectoral exports}:

{p 14 18 2}
{cmd:icio,} {cmdab:exp:orter(}{it:country_code} [{cmd:,} {it:sector_code}]{cmd:)} 
[{it:{help icio##icio_1b_options:methods_1b}}] 
[{it:{help icio##icio_out_options:results_exports}}] 
[{it:{help icio##icio_ori_dest_options:origin_destination}}]
[{it:{help icio##icio_options:standard_options}}]

{p 8}
{hi: 2. Value added and GVC participation in bilateral exports:}

{p 11 14}
a. Value added and GVC participation in {cmd:bilateral aggregate exports}:

{p 14 18 2}
{cmd:icio,} {cmdab:exp:orter(}{it:country_code}{cmd:)}
{cmdab:imp:orter(}{it:country_code}{cmd:)}
[{it:{help icio##icio_2a_options:methods_2a}}]
[{it:{help icio##icio_out_options:results_exports}}]
[{it:{help icio##icio_ori_dest_options:origin_destination}}]
[{it:{help icio##icio_options:standard_options}}]

{p 11 14}
b. Value added and GVC participation in {cmd:bilateral sectoral exports}:

{p 14 18 2}
{cmd:icio,} {cmdab:exp:orter(}{it:country_code} [{cmd:,} {it:sector_code}]{cmd:)} 
{cmdab:imp:orter(}{it:country_code}{cmd:)} 
[{it:{help icio##icio_2b_options:methods_2b}}] 
[{it:{help icio##icio_out_options:results_exports}}]
[{it:{help icio##icio_ori_dest_options:origin_destination}}] 
[{it:{help icio##icio_options:standard_options}}]

{p 8}
{hi: 3. Value added in total imports of a country:}

{p 11 14}
a. Value added in {cmd:total aggregate imports}:

{p 14 18 2}
{cmd:icio,} {cmdab:imp:orter(}{it:country_code}{cmd:)} 
[{it:{help icio##icio_3a_options:method_3a}}] 
[{it:{help icio##icio_out_options:results_imports}}] 
[{it:{help icio##icio_ori_dest_options:origin_destination}}]
[{it:{help icio##icio_options:standard_options}}]

{p 11 14}
b. Value added in {cmd:total sectoral imports}:

{p 14 18 4}
{cmd:icio,} {cmdab:imp:orter(}{it:country_code} [{cmd:,}
{it:sector_code}]{cmd:)} 
[{it:{help icio##icio_3b_options:method_3b}}] 
[{it:{help icio##icio_out_options:results_imports}}] 
[{it:{help icio##icio_ori_dest_options:origin_destination}}]
[{it:{help icio##icio_options:standard_options}}]


{title:Description}

{pstd}
{cmd:icio} is suited to measure trade in value added as well as participation
in GVCs of countries and sectors by exploiting ICIO tables.  It provides
decompositions of aggregate, bilateral, and sectoral exports, and it provides
imports according to the source and the destination of their value-added
content.

{pstd}
The {cmd:icio_load} command allows the user to work directly with the most
popular ICIO tables: the World Input-Output Database (WIOD) (Timmer et al.
2015), the Trade in Value-Added (TiVA) database (OECD 2018), the Eora Global
Supply Chain Database (Eora) (Lenzen et al. 2013), and the Asian Development
Bank (ADB) Multiregional Input-Output Table (MRIOT) Database.  In addition, any
other user-provided ICIO table can be loaded (see the option {opt user()} of
{cmd:icio_load}).  {cmd:icio} also allows the user to work with user-defined
groups of countries, which means that output measures can be computed for a
country group (for example, the "Euro area", "MERCOSUR", or "ASEAN") as a whole
while accounting for the specific supply/demand/trade structure of each member
of the group (see the option {opt groups()} for more details).

{pstd}
{cmd:icio} encompasses the most relevant measures of value added in exports and
imports at different levels of aggregation.  It closely follows the accounting
framework presented in Borin and Mancini (2019), which in turn extends,
refines, and reconciles the other main contributions in this strand of the
literature (see Johnson and Noguera [2012]; Wang, Wei, and Zhu [2013]; Koopman,
Wang, and Wei [2014]; Borin and Mancini [2015]; Los, Timmer, and de Vries
[2016]; Nagengast and Stehrer [2016]; Johnson [2018]; Miroudot and Ye [2018];
and Los and Timmer [2018]).  A key feature of the conceptual scheme proposed by
Borin and Mancini (2019) is that different empirical questions call for
distinct accounting methods, along with different levels of aggregation of
trade flows.  The {cmd:icio} command shares the same rationale.

{pstd}
According to the specific empirical application, the user should select the
following:

{p 8 8 2}
1) A certain type of {help icio##tradeflow:trade flow} (that is, aggregate
exports or imports, sectoral exports or imports, bilateral flows, and
sectoral-bilateral flows), through the option 
{opt exporter(country_code [, sector_code])} or 
{opt importer(country_code [, sector_code])}.

{p 8 8 2}
2) A certain {help icio##methodologies:accounting methodology} that can be
specified using the {opt perspective()} and {opt approach()} options;
otherwise, default options are applied.  These accounting methodologies differ
in the way double-counted components are computed.  "Double counted" refers to
items that are recorded several times in a given gross trade flow because of
the back-and-forth shipments that occur in a cross-national production process.
(See Borin and Mancini [2019] and the {help icio##examples:Examples} section
for a mapping of the questions under investigation and the accounting methods
needed to address them.)

{p 8 8 2}
3) The desired {help icio##icio_out_options:output measures}.  The
possibility to choose among different output measures allows the user to
address a wide range of empirical issues.

{pstd}
Moreover, the {opt origin(country_code [, sector_code])} and 
{opt destination(country_code [, sector_code])} options can always be specified
to select the country or sector where the trade value is produced (origin) and
the country or sector where it is absorbed by final demand (destination).

{pstd}
The {cmd:icio} command allows the user to reproduce many of the measures of
trade in value added proposed in the literature; however, they are not computed
using the original formulations whenever they have been found to be inexact or
imprecise.  For instance, a corrected version of the Koopman, Wang, and Wei
(2014) decomposition of aggregate exports can be computed as 
{cmd:icio, exporter(}{it:country_code}{cmd:)}
{cmd:perspective(world) approach(sink)}.

{pstd}
For export flows at different disaggregation levels, it is also possible to
compute the value of trade that is related to GVCs, that is, that crosses more
than one border.  The backward and forward GVC participation measures are based
on Borin and Mancini (2015, 2019), who consistently refine the vertical
specialization index proposed by Hummels, Ishii, and Yi (2001).

{pstd}
When neither the {opt exporter()} nor the {opt importer()} option is specified, the
{cmd:icio} command can be used to compute the GDP (that is, value added)
produced by a given country or industry ({opt origin()}), to measure final
demand in different countries and sectors ({opt destination()}), or a
combination of the two.


{title:Options}

{marker load}{...}
{pstd}
{ul:{hi:Load an ICIO table (required to run {cmd:icio}):}}{p_end}

{marker icioload_options}{...}
{synoptset 27}{...}
{synopthdr:icio_load_options}
{synoptline}
{synopt :{cmdab:iciot:able(}{it:{help icio##table_name:table_name}} [{cmd:,} {it:{help icio##usertable_options:usertable_options}}]{cmd:)}}{p_end}
{synopt :}specify the ICIO table to be used for the analysis; default is {opt wiodn},
the last WIOD release available{p_end}
{synopt :{cmdab:y:ear(}{it:#}{cmd:)}}set the year to be used for analysis; default is
the last available year: {cmd:year(2014)} for the WIOD tables ({opt wiodn}),
{cmd:year(2015)} for the TiVA tables ({opt tivan}),
{cmd:year(2015)} for the Eora Global Supply Chain Database tables ({opt eora}),
{cmd:year(2019)} for the ADB MRIOT Database ({opt adb}); not needed for
user-provided tables{p_end}
{synopt :{opt info}}show data sources and versions of the loadable ICIO
tables{p_end}
{synoptline}

{marker table_name}{...}
{synopthdr:table_name}
{synoptline}
{synopt :{opt wiodn}}WIOD, last version; see Timmer et al. (2015) and the {browse "http://www.wiod.org":WIOD website}{p_end}
{synopt :{opt tivan}}OECD TiVA tables, last version; see OECD (2018) and the dedicated {browse "http://oe.cd/tiva":OECD website}{p_end}
{synopt :{opt eora}}Eora tables; see Lenzen et al. (2013) and {browse "https://worldmrio.com/":https://worldmrio.com/}{p_end}
{synopt :{opt adb}}ADB MRIOT tables; see the ADB MRIOT Database at {browse "https://mrio.adbx.online/":https://mrio.adbx.online/}{p_end}
{synopt :{opt wiodo}}WIOD, previous version{p_end}
{synopt :{opt tivao}}OECD TiVA tables, previous versions{p_end}
{synopt :{opt user}}user-created tables; this option allows {cmd:icio} to work with tables that have been downloaded and formatted by the user; details on the required format are specified in the {help icio##usertables:remarks} below{p_end}
{synoptline}

{marker usertable_options}{...}
{synopthdr:usertable_options}
{synoptline}
{p2coldent:*{opt userp:ath(string)}}specify the full path to a folder containing
two {it: user-defined} files: the {it: user-defined} table and country-list
files{p_end}
{p2coldent:*{opt tablen:ame(string)}}specify the name of the {it: user-created}
table{p_end}
{p2coldent:*{opt countryl:istname(string)}}specify the name of the 
{it: user-created} country list{p_end}
{synoptline}
{phang}*
Only when {opt user} is specified in {cmd:icio_table()}{p_end}

{marker usertables}{...}
{pstd}
Remarks on user-provided tables:{p_end}

{pstd}
{cmd:icio} user-created tables and related country lists must be provided in
{cmd:.csv} format.  The table's {cmd:.csv} file must contain only one matrix
of dimension (GxN)x(GxN+GxU), where G is the number of countries, N is the
number of sectors, and U is the number of uses (that is, consumption,
investment, etc.).  As a purely illustrative example, consider the case of
importing an input-output table from the WIOD 2016 release.(+)  In this case,
the matrix dimension in the user-provided {cmd:.csv} file should be
(44x56)x(44x56+44X5) -- that is, 2464x2684 -- because G=44, N=56, and U=5.
Thus, considering a standard Excel file of a WIOD table (release 2016)
downloaded from the official website, the user-provided {cmd:.csv} should
include only data in the cell range E7 to CYJ2470.  More in general, country
and sector labels, total output, total consumption, and total value added must
not be included in the {cmd:.csv}.  The country list's {cmd:.csv} file must
only contain a vector (Gx1) of country names, reflecting the same order
adopted in the provided table's {cmd:.csv} file.{p_end}

{pstd}
(+) The user does not need to manually import
WIOD, TiVA, Eora, or ADB tables; they are already included in the {cmd:icio}
package and can be loaded using the {cmd:icio_load} command with the
appropriate options.  See {it:{help icio##icioload_options:icio_load_options}}.
{p_end}

{pstd}Remarks on {cmd:icio_clean}:{p_end}

{pstd}
{cmd:icio_clean} can be used to free space on the hard disk.  It deletes any
ICIO table or ancillary file downloaded by the user through the {cmd:icio_load}
command.  These files are stored automatically in the system directory
{cmd:../ado/plus/i}, which is also where the {cmd:icio} suite is stored.{p_end}

{marker supplydemand}{...}
{pstd}
{ul:{hi:Supply, final demand, and supply-final demand linkages:}}{p_end}

{pstd}
Through basic input-output accounting, {cmd:icio} can display the GDP (that
is, value added) produced by a given country or industry (origin of the value
added), the final demand in different countries and sectors (destination of
the value added), or a combination of the two.  The desired measure is
selected with the options 
{opt origin(country_code [, sector_code])} and 
{opt destination(country_code [, sector_code])}.  Results for all countries or
all sectors can be computed and displayed simultaneously, using the option
{opt all} for {it:country_code} or {it:sector_code}.  Note that within a
specific {opt origin()} or {opt destination()} option, {it:country_code} and
{it:sector_code} cannot both be {opt all} at the same time.

{pstd}
1. Gross domestic product (GDP):{p_end}

{pstd}
Display the value added produced in a selected country or sector.  All
countries or all sectors can be selected at once with the option {opt all}.
Examples are{p_end}

{phang2}{cmd:. icio, origin(usa)}{p_end}
{phang2}{cmd:. icio, origin(deu,18)}{p_end}
{phang2}{cmd:. icio, origin(all,18)}{p_end}
{phang2}{cmd:. icio, origin(deu,all)}{p_end}

{pstd}
2. Final demand:{p_end}

{pstd}
Display the final demand absorbed in a selected country or sector.  All
countries or all sectors can be selected at once with the option {opt all}.
Examples are{p_end}

{phang2}{cmd:. icio, destination(usa)}{p_end}
{phang2}{cmd:. icio, destination(deu,18)}{p_end}
{phang2}{cmd:. icio, destination(all,18)}{p_end}
{phang2}{cmd:. icio, destination(deu,all)}{p_end}

{pstd}
3. Value added by origin and final destination:{p_end}

{pstd}
Display the value added originated in a selected country or sector and
absorbed by the final demand of a selected country or sector.  All countries or
all sectors of origin as well as all countries or all sectors of final demand
can be selected at once with the option {opt all}.  Examples are{p_end}

{phang2}{cmd:. icio, origin(deu) destination(chn)}{p_end}
{phang2}{cmd:. icio, origin(all) destination(chn)}{p_end}
{phang2}{cmd:. icio, origin(deu,8) destination(chn,9)}{p_end}
{phang2}{cmd:. icio, origin(deu,all) destination(chn,all)}{p_end}

{marker vatrade}{...}
{pstd}
{ul:{hi:Value-added decomposition of trade flows and GVC participation in exports:}}{p_end}

{pstd}
Depending on the specific empirical application, the user can choose the
appropriate options to select i) the desired 
{help icio##tradeflow:trade flow}; ii) the best-suited 
{help icio##methodologies:accounting methodology} to single out double-counted
components, that is, items that are recorded several times in gross trade; or
iii) the appropriate 
{help icio##icio_out_options:output measures}.{p_end}

{marker tradeflow}{...}
{pstd}
{hi:i) Selection of trade flow:}{p_end}

{pstd}
Through the options {opt exporter(country_code [, sector_code])} and
{opt importer(country_code [, sector_code])}, the user chooses to retrieve
information on

{p 8}
1a. The total aggregate exports of a country{p_end}

{p 13}
Example: {cmd:icio, exporter(usa)}{p_end}

{p 8}
1b. The total sectoral exports of a country{p_end}

{p 13}
Example: {cmd:icio, exporter(deu,20)}{p_end}

{p 8 12 2}
2a. The bilateral aggregate exports of a country toward an importing
partner{p_end}

{p 13}
Example: {cmd:icio, exporter(chn) importer(usa)}{p_end}

{p 8 12 2}
2b. The bilateral sectoral exports of a country toward an importing
partner{p_end}

{p 13}
Example: {cmd:icio, exporter(deu,20) importer(usa)}{p_end}

{p 8 12}
3a. The total aggregate imports of a country{p_end}

{p 13}
Example: {cmd:icio, importer(usa)}{p_end}

{p 8}
3b. The total sectoral imports of a country{p_end}

{p 13}
Example: {cmd:icio, importer(usa,20)}{p_end}

{marker methodologies}{...}
{pstd}
{hi:ii) Accounting methodology:}{p_end}

{pstd}
The options {opt perspective()} and {opt approach()} can be used to select the
accounting methodology best suited to the specific phenomenon under
investigation.  In particular, the option {opt perspective()} defines the
"perimeter" according to which something is classified as value added or
double counted.  For instance, the boundaries may be defined at the level of
the exporting country (or the importing one), of a specific bilateral
relation, or of a single exporting sector within a bilateral flow.  The
perspective may differ from the level of disaggregation of trade flow that is
considered (that is, the perimeter that identifies the perspective can be set
at a more aggregate level compared with the selected trade flow).  For
instance, if the question is what part of a country's GDP is exported, it will
be necessary to select {opt exporter(country_code)} and
{cmd:perspective(exporter)} as options, such that the exporting country's
frontiers as a whole constitute the perimeter that matters in deciding whether
or not a certain item has to be classified as domestic value added (GDP) or
double counted.  The {cmd:perspective(exporter)} option must also be used when
one seeks a measure of value added in sectoral or bilateral exports that can
be added up to the exporter's GDP in its total exports.{p_end}

{pstd}
Alternative perspectives are better suited to address other issues.  For
instance, if we are interested in measuring the exporter's value added that is
exposed to a tariff imposed on a given sector from a certain partner, we want
to consider as value added the entire GDP that is involved in this
sectoral-bilateral relationship, even if part of that was previously exported
to other countries or sectors (that is, classified as domestic double counting
when {cmd:perspective(exporter)} is selected).  In this case, the option
{cmd:perspective(sectbil)} has to be chosen so that the specific
sectoral-bilateral relationship becomes the new relevant perimeter, and only
the items that enter multiple times in this trade flow are considered as
double counted.  Whenever an exporting country is specified, the {cmd:icio}
command always allows the user to select {cmd:perspective(exporter)} as an
option, while {cmd:perspective(sectexp)}, {cmd:perspective(bilateral)}, and
{cmd:perspective(sectbil)} are available only for sectoral, bilateral, and
sectoral-bilateral flows, respectively.{p_end}

{pstd}
For the aggregate exports of a country, 
{cmd:perspective(world)} is an option that is applied to the accounting of
foreign value added (FVA), as in Koopman, Wang, and Wei (2014) and Miroudot and
Ye (2018).  According to this perspective, a certain item is considered as FVA
only the first (or the last) time it crosses a foreign border, whereas all the
other times it crosses any foreign border, it is classified as double counted.
Thus, by using {cmd:perspective(exporter)}, a certain item is accounted for as
FVA only once in the total exports of a country, whereas
{cmd:perspective(world)} requires it to be accounted for as FVA only once in
total world exports.{p_end}

{pstd}
When {opt exporter()} is not specified, {cmd:icio} allows only
{cmd:perspective(importer)} for aggregate imports and
{cmd:perspective(sectimp)} for sectoral imports.  The former should be adopted
to compute the value added of a given country that enters, directly or
indirectly, in the total imports of a given country; the latter should be
adopted to compute the value added that enters in a specific sector of
import.{p_end}

{pstd}
Whenever the perspective is set at a more aggregate level compared with the
considered trade flow, the option {opt approach()} can also be defined to
choose in which disaggregated flow a certain item should be accounted for as
value added or double counted.  Suppose, for instance, that along the
production process a certain item is exported by country A first to country B
and then to country C.  By choosing {cmd:approach(source)}, the item is
classified as value added the first time it leaves the national border (that
is, in the exports toward B), whereas the sink-based approach considers it as
value added the last time it crosses the border (that is, in the exports
toward C).  The choice between the two approaches depends on the particular
empirical issue we want to address.  The source approach is designed to examine
the production linkages and the country or sector participation to different
types of production processes and to study the features of the production
processes in which export flows are involved.  Conversely, the value added in
the sink-based approach is recorded as closely as possible to the moment when
it is ultimately absorbed.  This makes it more suited to studying the
relationship between value added in exports and final demand.{p_end}

{pstd}
All the {opt perspective()} and {opt approach()} options available for the
different trade flows are reported here.{p_end}

{p 8}
{cmd:1. Value added and GVC participation in total exports of a country:}

{marker icio_1a_options}{...}
{p 11 14 2}
a. Value added and GVC participation in {cmd:total aggregate exports}:{p_end}

{synoptset 27}{...}
{synopthdr:methods_1a}
{synoptline}
{synopt :{cmd:perspective(exporter)}}the default{p_end}
{synopt :{cmd:perspective(world)}}world perspective for FVA accounting; this
perspective entails the selection of {cmd:approach(source)} (the default) or
{cmd:approach(sink)}{p_end}
{synoptline}

{marker icio_1b_options}{...}
{p 11 14 2}
b. Value added and GVC participation in {cmd:total sectoral exports}:{p_end}

{synopthdr:methods_1b}
{synoptline}
{synopt :{cmd:perspective(exporter)}}the default; allow the user to display
results for each exporting sector at once by setting {it:sector_code} as 
{opt all}{p_end}
{synopt :{cmd:perspective(sectexp)}}entail the selection of
{cmd:approach(source)} (the default) or {cmd:approach(sink)}{p_end}
{synoptline}

{p 8}
{cmd:2. Value added and GVC participation in bilateral exports:}

{marker icio_2a_options}{...}
{p 11 14 2}
a. Value added and GVC participation in {cmd:bilateral aggregate exports}:{p_end}

{synopthdr:methods_2a}
{synoptline}
{synopt :{cmd:perspective(exporter)}}the default{p_end}
{synopt :{cmd:perspective(bilateral)}}entail the selection of
{cmd:approach(source)} (the default) or {cmd:approach(sink)}{p_end}
{synoptline}

{marker icio_2b_options}{...}
{p 11 14 2}
b. Value added and GVC participation in {cmd:bilateral sectoral exports}:{p_end}

{synopthdr:methods_2b}
{synoptline}
{synopt :{cmd:perspective(exporter)}}the default; allow the user to display
results for each exporting sector at once by setting {it:sector_code} as 
{opt all}{p_end}
{synopt :{cmd:perspective(sectbil)}}entail the selection of
{cmd:approach(source)} (the default) or {cmd:approach(sink)}{p_end}
{synoptline}

{p 8}
{cmd:3. Value added in total imports of a country:}

{marker icio_3a_options}{...}
{p 11 14 2}
a. Value added in {cmd:total aggregate imports}:{p_end}

{synopthdr:method_3a}
{synoptline}
{synopt :{cmd:perspective(importer)}}the default{p_end}
{synoptline}

{marker icio_3b_options}{...}
{p 11 14 2}
b. Value added and GVC participation in {cmd:bilateral sectoral exports}:{p_end}

{synopthdr:method_3b}
{synoptline}
{synopt :{cmd:perspective(sectimp)}}the default{p_end}
{synoptline}

{marker icio_out_options}{...}
{pstd}
{hi:iii) Return and other options:}{p_end}

{pstd}
For the selected trade flow, {cmd:icio} allows the user to compute the main
indicators of gross trade and value added by specifying the {opt return()}
option.  For export flows, the default return option, {cmd:return(detailed)},
shows a complete value-added decomposition of the trade flows according to the
conceptual scheme proposed by Koopman, Wang, and Wei (2014) and refined by
Borin and Mancini (2019).  Gross trade, {opt gtrade}, is first split into the
part that is originally produced by the exporting country (domestic content,
{opt dc}) and the part that is produced abroad (foreign content, {opt fc}); in
turn, each of these components is broken down into part value-added item
(domestic value added, {opt dva}, and FVA, {opt fva}) and part 
double counting.  The methodology used to single out the value-added and
double-counted components changes according to the selected perspective or
approach options (while {opt gtrade}, {opt dc}, and {opt fc} measures are, by construction, the same for all the accounting methodologies).{p_end}

{pstd}
The detailed output also includes additional indicators of trade in value added
that have been singled out in the literature (for example, value added to gross
exports by Johnson and Noguera [2012]; reflection by Koopman, Wang, and Wei
[2014]; value added absorbed by bilateral importers and directly absorbed value
added in exports by Borin and Mancini [2015, 2019]).  The additional indicators
that are included in the detailed output vary consistently with the selected
perspective or approach.{p_end}

{pstd}
Instead of the whole detailed output, the user can compute only one of the main
trade indicators by choosing one of the following {opt return()} options: 
{opt gtrade}, {opt dc}, {opt dva}, {opt fc}, or {opt fva}.{p_end}

{pstd}
In addition to value-added and gross trade measures, for any export flow, it is
also possible to compute the value of trade that is related to GVCs, as
developed in Borin and Mancini (2015).  The GVC-related trade includes all
the traded items that cross at least two international borders, that is, that
are reexported at least once.  The backward and forward GVC participation
measures are based on Borin and Mancini (2019), which consistently refine the
vertical specialization index proposed by Hummels, Ishii, and Yi (2001).
GVC-related indicators that are subcomponents of the selected export flow are
shown in the detailed output by default (or when {cmd:perspective(exporter)}
and {cmd:approach(source)} are specified).  Alternatively, it is possible to
obtain a single measure of GVC trade by specifying {opt gvc}, {opt gvcb}, and
{opt gvcf} as arguments of the {opt return()} option for total, backward, and
forward GVC indicators, respectively.{p_end}

{pstd}
For value added and GVC indicators of the selected trade flow, it is also
possible to single out the country or sector where the goods and services were
originally produced by specifying the 
{opt origin(country_code [, sector_code])} option, as well as the market or
sector where it is absorbed in final demand by specifying the 
{opt destination(country_code [, sector_code])} option.  When one seeks a
measure of value added produced by a specific country or sector, the option
{cmd:return(va)} should be specified.  When the country in 
{opt origin()} corresponds to that specified in {opt exporter()}, {cmd:icio}
provides the same results when selecting {cmd:return(dva)} or
{cmd:return(va)}.{p_end}

{pstd}
{opt return()} options and the other options available for export and import
trade flows are reported here.

{synoptset 27}{...}
{synopt:Return options for}{p_end}
{synopt:decomposition of exports}Description{p_end}
{synoptline}
{synopt :{opt detailed}}request detailed decomposition; default
if {opt origin()} or {opt destination()} is not specified{p_end}
{synopt :{opt gtrade}}request gross trade; default if
{opt origin()} or {opt destination()} is specified{p_end}
{synopt :{opt va}}request value added{p_end}
{synopt :{opt dc}}request domestic content (dva+domestic double counting){p_end}
{synopt :{opt dva}}request domestic value added{p_end}
{synopt :{opt fc}}request foreign content (fva+foreign double counting){p_end}
{synopt :{opt fva}}request FVA{p_end}
{synopt :{opt gvc}}request GVC-related trade (gvcb+gvcf); can be computed
only if {cmd:perspective(exporter)} and {cmd:approach(source)} are selected{p_end}
{synopt :{opt gvcb}}request backward GVC-related trade; can be computed only
if {cmd:perspective(exporter)} and {cmd:approach(source)} are selected{p_end}
{synopt :{opt gvcf}}request forward GVC-related trade; can be computed only
if {cmd:perspective(exporter)} and {cmd:approach(source)} are selected{p_end}
{synoptline}

{synopt:Return options for}{p_end}
{synopt:decomposition of imports}Description{p_end}
{synoptline}
{synopt :{opt gtrade}}request gross trade; default{p_end}
{synopt :{opt va}}request value added{p_end}
{synoptline}

{marker icio_ori_dest_options}{...}
{synopt:Origin and destination of}{p_end}
{synopt:the decomposed trade flow}Description{p_end}
{synoptline}
{synopt :{cmdab:orig:in(}{it:country_code} [{cmd:,} {it:sector_code}]{cmd:)}}{p_end}
{synopt :}request the country or sector where the trade value is produced; 
use {cmd:all} for {it:country_code} or {it:sector_code} to display all countries or all sectors simultaneously{p_end}
{synopt :{cmdab:dest:ination(}{it:country_code} [{cmd:,} {it:sector_code}]{cmd:)}}{p_end}
{synopt:}request
the country or sector where the trade value is absorbed by final demand;
use {cmd:all} for {it:country_code} or {it:sector_code} to display all countries or all sectors simultaneously{p_end}
{synoptline}

{marker icio_options}{...}
{synopthdr:standard_options}
{synoptline}
{synopt :{cmd:save(}{it:{help filename}} [{cmd:,} {it:{help icio##icio_save_options:save_options}}]{cmd:)}}{p_end}
{synopt :}save {cmd:icio} output (scalar, vector, or matrix) to an Excel file (with {cmd:.xlsx} extension){p_end}
{synopt :{cmdab:gr:oups(}{it:grouping_rule} {it:group_name} [{cmd:,} ...]{cmd:)}}{p_end}
{synopt:}specify a user-defined grouping of countries to compute output
measures for a country group (for example, the "Euro area", "MERCOSUR", or
"ASEAN") as a whole while taking into account the specific supply/demand/trade
structure of each member of the group; to define one or more country groups,
list comma-separated country codes ({it:grouping_rule}) followed by a
user-defined {it:group_name}; for example, if 
{cmd:groups(prt, esp, ita, cyp, grc, mlt, tur "south_europe")} is specified,
the group "south_europe" will be created including Portugal, Spain, Italy,
Cyprus, Greece, Malta, and Turkey; the comma-separated list of country codes
{cmd:prt,esp,ita,cyp,grc,mlt, tur} is the {it:grouping_rule}, while
{cmd:"south_europe"} is the user defined {it:group_name}; run {cmd:icio, info}
for the list of available country codes for the currently loaded input-output
table{p_end} {synoptline}

{marker icio_save_options}{...}
{synopthdr:save_options}
{synoptline}
{synopt :{opt replace}}overwrite an existing Excel file{p_end}
{synopt :{opt modify}}modify an existing Excel file{p_end}
{synopt :{cmdab:s:heet(}{it:sheetname} [{cmd:,} replace]{cmd:)}}specify the
worksheet to use; default sheet name is {cmd:icio_out}{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}{cmd:Setup:}{p_end}
{synoptline}

{pstd}Load a specific year of the WIOD (last version) table{p_end}
{phang2}{cmd:. icio_load, iciotable(wiodn) year(2014)}{p_end}

{pstd}Display available country and sector codes for the loaded table{p_end}
{phang2}{cmd:. icio, info}{p_end}

{pstd}{cmd:Supply-final demand linkages:}{p_end}
{synoptline}

{pstd}What is the GDP (value added) produced by each country?{p_end}
{phang2}{cmd:. icio, origin(all)}{p_end}

{pstd}How much value added does each country produce in a given sector (for
example, sector code 19)?{p_end}
{phang2}{cmd:. icio, origin(all,19)}{p_end}

{pstd}What is the aggregate final demand of each country?{p_end}
{phang2}{cmd:. icio, destination(all)}{p_end}

{pstd}What is the value added originated in Germany and absorbed in
China?{p_end}
{phang2}{cmd:. icio, origin(deu) destination(chn)}{p_end}

{pstd}Where is the value added produced in the Italian sector 19
absorbed?{p_end}
{phang2}{cmd:. icio, origin(ita,19) destination(all)}{p_end}

{pstd}Which final-demand sectors in China are the most important for the
absorption of U.S.-made value added?{p_end}
{phang2}{cmd:. icio, origin(usa) destination(chn,all)}{p_end}

{pstd}Where is the GDP produced in each country absorbed (and save the output
as "{cmd:supply_demand}" Excel file in the current working directory)?{p_end}
{phang2}{cmd:. icio, origin(all) destination(all) save(supply_demand)}{p_end}

{pstd}How much is the U.S.-Mexico-Canada Agreement (formerly North
American Free Trade Agreement) countries' final demand in sector 20 satisfied
by Chinese productions?{p_end}
{phang2}{cmd:. icio, origin(chn) destination(usmca,20) groups(usa, mex, can, "usmca")}{p_end}

{pstd}{cmd:Value-added trade and GVC participation:}{p_end}
{synoptline}

{pstd}Which part of a country's total exports is home produced, that is, is
domestic GDP?{p_end}
{phang2}{cmd:. icio, exporter(deu) return(dva)}{p_end}

{pstd}Which part of a country's total exports can be traced back to other
countries' GDP?{p_end}
{phang2}{cmd:. icio, exporter(deu) return(fva)}{p_end}

{pstd}Where is the FVA in German exports produced?{p_end}
{phang2}{cmd:. icio, origin(all) exporter(deu) return(fva)}{p_end}

{pstd}Considering the bilateral exports from Italy to Germany, where is the
Italian GDP (domestic value added) reexported by Germany absorbed?{p_end}
{phang2}{cmd:. icio, exporter(ita) importer(deu) destination(all) return(dva)}{p_end}

{pstd}How can the complete breakdown by origin and destination of the value
added (both domestic and foreign) for Chinese exports to the U.S. be
obtained?{p_end}
{phang2}{cmd:. icio, origin(all) exporter(chn) importer(usa) destination(all) return(va) save(CHN_to_USA)}{p_end}

{pstd}How can the (corrected) Koopman, Wang, and Wei (2014) decomposition be
retrieved?{p_end}
{phang2}{cmd:. icio, exporter(deu) perspective(world) approach(sink)}{p_end}

{pstd}Which share of German exports is related to GVC, that is, cross more
than one border?{p_end}
{phang2}{cmd:. icio, exporter(deu) return(gvc)}{p_end}

{pstd}Which share of German exports is related to backward and forward
GVC?{p_end}
{phang2}{cmd:. icio, exporter(deu) return(gvcb)}{p_end}
{phang2}{cmd:. icio, exporter(deu) return(gvcf)}{p_end}

{pstd}It is possible to get a detailed assessment of trade in
value added and GVC participation regarding a certain trade flow by
running the following:{p_end}
{phang2}{cmd:. icio, exporter(deu)}{p_end}
{phang2}{cmd:. icio, exporter(usa) importer(chn)}{p_end}
{phang2}{cmd:. icio, exporter(deu,19) importer(chn)}{p_end}

{pstd}{cmd:Trade policy analysis:}{p_end}
{synoptline}

{pstd}What is the Chinese GDP that at any point in time passes through a
certain bilateral trade flow, say, Chinese exports to the U.S.? In other terms,
what is the Chinese GDP potentially exposed to U.S. tariffs on imports from
China?{p_end}
{phang2}{cmd:. icio, exporter(chn) importer(usa) perspective(bilateral) return(dva)}{p_end}

{pstd}What is the German GDP potentially exposed to U.S. tariffs on all
imports?{p_end}
{phang2}{cmd:. icio, origin(deu) importer(usa) perspective(importer) return(va)}{p_end}

{pstd}What is the German GDP that could be affected by U.S. tariffs on imports
in sector 20?{p_end}
{phang2}{cmd:. icio, origin(deu) importer(usa,20) perspective(sectimp) return(va)}{p_end}

{pstd}What is the exposure of U.S. GDP to a Chinese tariff on U.S. imports in
sector 17?{p_end}
{phang2}{cmd:. icio, exporter(usa,17) importer(chn) perspective(sectbil) return(dva)}{p_end}

{pstd}To what extent are Italian sectors exposed to a shock on Germany's exports
in sector 20?{p_end}
{phang2}{cmd:. icio, origin(ita,all) exporter(deu,20) perspective(sectexp) return(va)}{p_end}

{pstd}{cmd: Miscellaneous:}{p_end}
{synoptline}

{pstd}Store results in an Excel file{p_end}
{phang2}{cmd:. icio, exporter(usa,all) save(USA_exports_decomp.xls)}{p_end}

{pstd}Display (and save) large dimension results{p_end}
{phang2}{cmd:. icio, exporter(usa,all) save(USA_exports_decomp.xls)}{p_end}
{phang2}{cmd:. matlist r(detailed)}{p_end}
{phang2}{cmd:. icio, origin(all) destination(all) save(supply_demand.xls)}{p_end}
{phang2}{cmd:. matlist r(vby)}{p_end}

{pstd}Load a user-created table{p_end}
{phang2}{cmd:. icio_load, iciotable(user, userp(path_to_the_table_folder) tablename(ADB_2011.csv) countrylist(adb_countrylist.csv))}{p_end}

{pstd}Compute the detailed decomposition for a list of countries and store
the results in two matrices (dollar values and shares){p_end}
{phang2}{cmd:. loc countries "ita deu fra esp"}{p_end}
{phang2}{cmd:. foreach c of local countries {c -(}}{p_end}
{phang2}{cmd:. {space 4} quietly icio, exporter(`c')}{p_end}
{phang2}{cmd:. {space 4} mata st_matrix("total_exports", st_matrix("r(detailed)")[.,1])}{p_end}
{phang2}{cmd:. {space 4} mat results_dollars = nullmat(results_dollars), total_exports}{p_end}
{phang2}{cmd:. {space 4} mata st_matrix("total_exports_shares", st_matrix("r(detailed)")[.,2])}{p_end}
{phang2}{cmd:. {space 4} mat results_shares = nullmat(results_shares), total_exports_shares}{p_end}
{phang2}{cmd:. }}{p_end}
{phang2}{cmd:. matlist results_dollars}{p_end}
{phang2}{cmd:. matlist results_shares}{p_end}


{title:Stored results}

{pstd}
{cmd:icio} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:icio}{p_end}
{synopt:{cmd:r(table)}}name of the loaded table{p_end}
{synopt:{cmd:r(year)}}year of the loaded table{p_end}
{synopt:{cmd:r(version)}}vintage of the loaded table{p_end}
{synopt:{cmd:r(exporter)}}exporter country{p_end}
{synopt:{cmd:r(importer)}}importer country{p_end}
{synopt:{cmd:r(perspective)}}perspective{p_end}
{synopt:{cmd:r(approach)}}approach{p_end}
{synopt:{cmd:r(origin)}}origin country{p_end}
{synopt:{cmd:r(destination)}}destination country{p_end}
{synopt:{cmd:r(output)}}output detail{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(vby)}}matrix containing the results of the supply-final demand analysis{p_end}
{synopt:{cmd:r(detailed)}}matrix containing the detailed results of the value-added decomposition of trade{p_end}
{synopt:{cmd:r(gtrade)}}matrix containing the gross trade{p_end}
{synopt:{cmd:r(va)}}matrix containing the value added{p_end}
{synopt:{cmd:r(dc)}}matrix containing the domestic content{p_end}
{synopt:{cmd:r(dva)}}matrix containing the domestic value added{p_end}
{synopt:{cmd:r(fc)}}matrix containing the foreign content{p_end}
{synopt:{cmd:r(fva)}}matrix containing the FVA{p_end}
{synopt:{cmd:r(gvc)}}matrix containing the GVC-related exports{p_end}
{synopt:{cmd:r(gvcb)}}matrix containing the GVC-related exports, backward{p_end}
{synopt:{cmd:r(gvcf)}}matrix containing the GVC-related exports, forward{p_end}
{p2colreset}{...}


{marker remarks}{...}
{title:Remarks}

{pstd}
The {opt return()} option replaces the {opt output()} option available in
previous versions of {cmd:icio}.  Nonetheless, we leave the {opt output()}
option working for backward compatibility.{p_end}


{title:Citations}

{pstd}
{cmd:icio} is not an official Stata command.  It is a free contribution to the
research community.  See 
{browse "http://www.tradeconomics.com/icio/":tradeconomics.com/icio/} for
information on the latest updates.  Please cite it as follows:

{p 11 14 2}
Belotti, F., A. Borin, and M. Mancini.  2021.
icio: Economic analysis with intercountry input-output tables.
{it:Stata Journal} 21: 708-755.
{browse "https://doi.org/10.1177/1536867X211045573"}.{p_end}

{pstd}
When measures of value added in trade and GVC participation are used, please
also cite the following:

{p 11 14 2}
Borin, A., and M. Mancini.  2019.
Measuring what matters in global value chains and value-added trade.
Policy Research Working Paper WPS 8804;
WDR 2020 Background Paper,
World Bank Group, Washington, DC.
{browse "https://documents.worldbank.org/curated/en/639481554384583291/Measuring-What-Matters-in-Global-Value-Chains-and-Value-Added-Trade"}.

{phang}
Remember to cite the original reference of the ICIO database you are using
with {cmd:icio}.

{pstd}
Furthermore, you can cite the other works that have contributed to the
development of each specific measure (see Borin and Mancini [2019] for a
critical discussion of the different accounting methodologies proposed in the
literature).


{title:References}

{phang}
Borin, A., and M. Mancini.  2015.
Follow the value added: Bilateral gross export accounting.
Economic Working Papers 1026,
Bank of Italy.{p_end}

{phang}
------.  2019.
Measuring what matters in global value chains and value-added trade.
Policy Research Working Paper WPS 8804;
WDR 2020 Background Paper,
World Bank Group, Washington, DC.{p_end}

{phang}
Hummels, D., J. Ishii, and K. M. Yi.  2001.
The nature and growth of vertical specialization in world trade.
{it:Journal of International Economics} 54: 75-96.
{browse "https://doi.org/10.1016/S0022-1996(00)00093-3"}.{p_end}

{phang}
Johnson, R. C.  2018.
Measuring global value chains.
{it:Annual Review of Economics} 10: 207-236.
{browse "https://doi.org/10.1146/annurev-economics-080217-053600"}.{p_end}

{phang}
Johnson, R. C., and G. Noguera.  2012.
Accounting for intermediates: Production sharing and trade in value added.
{it:Journal of International Economics} 86: 224-236.
{browse "https://doi.org/10.1016/j.jinteco.2011.10.003"}.{p_end}

{phang}
Koopman, R., Z. Wang, and S. Wei.  2014.
Tracing value-added and double counting in gross exports.
{it:American Economic Review} 104: 459-494.
{browse "https://doi.org/10.1257/aer.104.2.459"}.{p_end}

{phang}
Lenzen, M., D. Moran, K. Kanemoto, and A. Geschke.  2013.
Building Eora: A global multiregion input-output database at high country and sector resolution.
{it:Economic Systems Research} 25: 20-49.
{browse "https://doi.org/10.1080/09535314.2013.769938"}.{p_end}

{phang}
Los, B., and M. P. Timmer.  2018.
Measuring bilateral exports of value added: A unified framework.
NBER Working Paper No. 24896,
The National Bureau of Economic Research.
{browse "https://doi.org/10.3386/w24896"}.{p_end}

{phang}
Los, B., M. P. Timmer, and G. J. de Vries.  2016.
Tracing value-added and double counting in gross exports: Comment.
{it:American Economic Review} 106: 1958-1966.
{browse "https://doi.org/10.1257/aer.20140883"}.{p_end}

{phang}
Miroudot, S., and M. Ye.  2018.
Tracing value-added and double counting in sales of foreign affiliates and domestic-owned companies.
MPRA Paper 85723,
University Library of Munich.
{browse "https://mpra.ub.uni-muenchen.de/85723/1/MPRA_paper_85723.pdf"}.{p_end}

{phang}
Nagengast, A. J., and R. Stehrer.  2016.
Accounting for the differences between gross and value-added trade balances.
{it:World Economy} 39: 1276-1306.
{browse "https://doi.org/10.1111/twec.12401"}.{p_end}

{phang}
OECD.  2018.
Trade in Value Added database.
{browse "oe.cd/tiva"} and
{browse "http://www.oecd.org/sti/ind/inter-country-input-output-tables.htm"}.{p_end}

{phang}
Timmer, M. P., E. Dietzenbacher, B. Los, R. Stehrer, and G. J. de Vries.  2015.
An illustrated user guide to the world input-output database: The case of global automotive production.
{it:Review of International Economics} 23: 575-605.
{browse "https://doi.org/10.1111/roie.12178"}.{p_end}

{phang}
Wang, Z., S.-J. Wei, and K. Zhu.  2013.
Quantifying international production sharing at the bilateral and sector levels.
NBER Working Paper No. 19677,
The National Bureau of Economic Research.
{browse "https://www.nber.org/papers/w19677"}.{p_end}


{title:Authors}

{pstd}Federico Belotti{p_end}
{pstd}Department of Economics and Finance{p_end}
{pstd}University of Rome Tor Vergata{p_end}
{pstd}Rome, Italy{p_end}
{pstd}federico.belotti@uniroma2.it{p_end}

{pstd}Alessandro Borin{p_end}
{pstd}Directorate General for Economics, Statistics, and Research{p_end}
{pstd}Bank of Italy{p_end}
{pstd}Rome, Italy{p_end}
{pstd}alessandro.borin@bancaditalia.it{p_end}

{pstd}Michele Mancini{p_end}
{pstd}Directorate General for Economics, Statistics, and Research{p_end}
{pstd}Bank of Italy{p_end}
{pstd}Rome, Italy{p_end}
{pstd}michele.mancini@bancaditalia.it{p_end}


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 22, number 1: {browse "https://doi.org/10.1177/1536867X221083931":st0651_1},{break}
          {it:Stata Journal}, volume 21, number 3: {browse "https://doi.org/10.1177/1536867X211045573":st0651}{p_end}
