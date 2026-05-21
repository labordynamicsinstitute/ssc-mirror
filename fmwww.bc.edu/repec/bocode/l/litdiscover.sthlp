{smcl}
{* *! version 1.0  17may2026}{...}
{cmd:help litdiscover}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{cmd:litdiscover} {hline 2}}LDA topic modelling with deductive
construct extraction for systematic literature reviews (SLRs){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:litdiscover}{cmd:,} {cmd:abstract(}{it:varname}{cmd:)}
[{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt abstract(varname)}}string variable containing the abstract text{p_end}

{syntab:Identification and stratification}
{synopt :{opt id(varname)}}study identifier; defaults to {bf:study_id} if it exists, otherwise auto-generated{p_end}
{synopt :{opt year(varname)}}publication year; enables year-stratified topic table{p_end}

{syntab:Construct fields (multi-valued, separator-split)}
{synopt :{opt theory(varname)}}theoretical perspective(s){p_end}
{synopt :{opt dv(varname)}}dependent variable(s){p_end}
{synopt :{opt iv(varname)}}independent variable(s) / antecedent(s){p_end}
{synopt :{opt mod(varname)}}moderator(s){p_end}
{synopt :{opt med(varname)}}mediator(s){p_end}
{synopt :{opt decision(varname)}}decision(s){p_end}
{synopt :{opt context(varname)}}empirical context(s){p_end}
{synopt :{opt method(varname)}}method(s){p_end}

{syntab:Construct fields (single-valued)}
{synopt :{opt journal(varname)}}journal name; rejected if it contains the separator{p_end}

{syntab:TCCM framework options}
{synopt :{opt tccmclass(name)}}field label for the TCCM characteristic axis;
one of {bf:dv}, {bf:iv}, {bf:mod}, {bf:med}, {bf:decision}, {bf:journal};
default is {bf:dv} when {opt dv()} is supplied{p_end}
{synopt :{opt tccmminfreq(#)}}minimum cell frequency to retain in the TCCM table; default {bf:1}{p_end}

{syntab:Tokenisation and engine options}
{synopt :{opt sep(string)}}separator for multi-valued cells; default {bf:";"}{p_end}
{synopt :{opt topics(#)}}number of LDA topics; default {bf:5}{p_end}
{synopt :{opt seeds(#)}}number of random seeds for stability assessment; default {bf:1}{p_end}
{synopt :{opt coh:erence}}compute UMass topic coherence{p_end}
{synopt :{opt seed(#)}}primary random seed; default {bf:12345}{p_end}
{synopt :{opt minfreq(#)}}minimum document frequency for a term; default {bf:1}{p_end}
{synopt :{opt maxdf(#)}}maximum document frequency, in (0, 1]; default {bf:1.0}{p_end}
{synopt :{opt ngram(#)}}maximum n-gram length, in [1, 3]; default {bf:1}{p_end}

{syntab:File handling}
{synopt :{opt script(string)}}path to {bf:litdiscover.py}; if omitted, located via findfile{p_end}
{synopt :{opt export(string)}}flat output directory; default {bf:"output"};{...}
 mutually exclusive with {opt outdir()}{p_end}
{synopt :{opt outdir(string)}}root output directory with the subdirectory layout{...}
 {bf:./root/tables/}, {bf:./root/figures/}, {bf:./root/interactive/};{...}
 mutually exclusive with {opt export()}{p_end}
{synopt :{opt keeptemp}}retain the intermediate corpus CSV{p_end}

{syntab:Visualisation}
{synopt :{opt figures}}produce static figures (Stata-tier via {bf:heatplot}/{bf:palettes};{...}
 Python-tier via {bf:matplotlib}/{bf:seaborn}/{bf:wordcloud}){p_end}
{synopt :{opt interactive}}produce three interactive HTML deliverables (pyLDAvis, pyvis network, plotly Sankey){p_end}
{synopt :{opt sankeytopfreq(#)}}truncate theory nodes in the Sankey diagram to the top {it:#}{...}
 by total documents; default {bf:15}{p_end}
{synopt :{opt vizscript(string)}}path to {bf:litdiscover_viz.py}; if omitted, located via findfile{p_end}

{syntab:Network and exclusivity measures}
{synopt :{opt netmeasures}}compute network-analytic measures (degree centrality,{...}
 betweenness centrality, modularity, Louvain communities) over the within-field{...}
 and cross-field construct co-occurrence tables; requires at least one construct field{p_end}
{synopt :{opt frex}}add a {bf:frex} column to {bf:litdiscover_topicterms.dta}{...}
 containing the FREX (FRequency-EXclusivity) score per Roberts, Stewart, and Tingley (2019){p_end}
{synopt :{opt netscript(string)}}path to {bf:litdiscover_net.py}; if omitted, located via findfile{p_end}

{syntab:Interactive behaviour}
{synopt :{opt noautoload}}suppress the default of loading{...}
 {bf:litdiscover_topicterms.dta} into memory at the end of the run;{...}
 preserves the input dataset in memory instead{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:litdiscover} implements the analytic phase of a systematic literature
review. It combines an inductive component (latent Dirichlet allocation (LDA),
{help litdiscover##blei2003:Blei et al. 2003}) applied to abstract
text with a deductive component (researcher-coded construct fields) and
emits a set of crosswalk tables that align the two. The package also
produces summary tables aligned with the TCCM and ADO frameworks of
{help litdiscover##paul2024:Paul et al. (2024)}.

{pstd}
The LDA engine is implemented in Python (via the {cmd:python script}
command) using {bf:scikit-learn}. All construct extraction, tokenisation,
and crosswalk computation are performed in Stata. Multi-valued construct
cells are split on a user-specified separator (default {bf:";"});
single-valued cells (currently {opt journal()}) are validated to contain
no separator.

{pstd}
The deductive-inductive bridge is exposed primarily through
{bf:litdiscover_topic_by_field.dta}, which gives the mean topic share of
each topic within each (field, value) cell, along with the number of
documents contributing to that cell. The TCCM and ADO tables provide
complementary framework-oriented views aligned with current best practice
in business-school literature reviews.

{pstd}
The {opt figures} and {opt interactive} flags produce publication-ready visualisations: Stata-native graphs (.gph and
.png) via {bf:heatplot} ({help litdiscover##jann2018:Jann 2018};
{help litdiscover##jann2023:Jann 2023}), Python-side static figures
(.png), and three interactive HTML files for online supplementary
materials and project websites
({help litdiscover##sievert2014:Sievert and Shirley 2014};
{help litdiscover##donthu2021:Donthu et al. 2021}).


{title:Interactive behaviour (v1.0)}

{pstd}
For convenience at the Stata prompt, {cmd:litdiscover} loads
{bf:litdiscover_topicterms.dta} into memory at the end of the run by
default. The user can then immediately run {helpb list}, {helpb tabulate},
{helpb graph}, {helpb tabstat}, and similar commands on the top-term
table without first issuing a {helpb use} command. The original input
dataset is saved to {bf:_litdiscover_input_recovery.dta} in the tables
directory so the user can return to it with a single {helpb use}.

{pstd}
The end-of-run summary printed to the Results window lists every output
file produced, with copy-paste-ready {helpb use} commands for the
{bf:doctopic}, {bf:coherence}, {bf:topic_by_field}, and other tables.

{pstd}
For scripted workflows that need the input dataset to remain in memory,
the {opt noautoload} option suppresses the default loading.


{title:Output layout}

{pstd}
The package supports two output layouts.

{phang2}{bf:Flat layout (default}{p_end}
{p 8 8 2}
When {opt outdir()} is omitted, all outputs (tables, figures, and HTML
files) are written to a single flat directory named by {opt export()}.
{opt export()} defaults to {bf:"output"}.{p_end}

{phang2}{bf:Subdirectory layout}{p_end}
{p 8 8 2}
When {opt outdir(}{it:root}{cmd:)} is supplied, the package creates
{bf:./{it:root}/tables/}, {bf:./{it:root}/figures/}, and
{bf:./{it:root}/interactive/}, routing each kind of output to the
appropriate subdirectory. {opt outdir()} and {opt export()} are
mutually exclusive; supplying both raises an error.{p_end}


{title:Output files}

{pstd}
Engine outputs are produced for every call. Construct, framework, and
stratification outputs are produced only when the corresponding options
are supplied. Figure and HTML outputs are produced only when the
corresponding flags are supplied.

{phang2}{bf:Engine outputs (always produced)}

{p 8 8 2}
{bf:litdiscover_doctopic.dta}{break}
Columns: {bf:study_id}, {bf:topic_1}, ..., {bf:topic_K},
{bf:dominant_topic}, {bf:dominant_topic_share}. One row per processed
document.

{p 8 8 2}
{bf:litdiscover_topicterms.dta}{break}
Columns: {bf:topic}, {bf:rank}, {bf:term}, {bf:weight}. Top terms per topic
under the primary seed. When {opt frex} is supplied, an additional column
{bf:frex} contains the FREX score per
{help litdiscover##roberts2019:Roberts, Stewart, and Tingley (2019)},
balancing within-topic frequency and across-topic exclusivity (omega = 0.5,
the {bf:stm} default).

{p 8 8 2}
{bf:litdiscover_stability.dta} (only when {opt seeds()} > 1){break}
Columns: {bf:seed_a}, {bf:seed_b}, {bf:mean_jaccard}, {bf:min_jaccard},
{bf:n_topics}. Pairwise Jaccard overlap of top-term sets across seeds,
matched via the Hungarian algorithm.

{p 8 8 2}
{bf:litdiscover_topic_stability.dta} (only when {opt seeds()} > 1; v0.3.1){break}
Columns: {bf:topic}, {bf:mean_best_match}, {bf:min_best_match},
{bf:n_seed_pairs}. For each topic in the primary-seed run, the mean and
minimum Jaccard similarity of its best-matched counterpart across the
other seeds. Use together with {bf:litdiscover_coherence.dta} for a
combined per-topic quality assessment (high coherence and high
stability indicate a robust topic).

{p 8 8 2}
{bf:litdiscover_coherence.dta} (only with {opt coherence}){break}
Columns: {bf:topic}, {bf:umass}, {bf:topn}. UMass coherence score per
topic ({help litdiscover##mimno2011:Mimno et al. 2011}).

{phang2}{bf:Construct outputs (produced when any construct field is supplied)}

{p 8 8 2}
{bf:litdiscover_construct_freq.dta}{break}
Columns: {bf:field}, {bf:value}, {bf:n_docs}. Frequency of each unique
(field, value) pair across documents.

{p 8 8 2}
{bf:litdiscover_cooc_within.dta}{break}
Columns: {bf:field}, {bf:value_a}, {bf:value_b}, {bf:n_both}, {bf:n_a},
{bf:n_b}, {bf:jaccard}. Within-field co-occurrence of unordered value
pairs, with marginal counts and Jaccard similarity.

{p 8 8 2}
{bf:litdiscover_cooc_cross.dta}{break}
Columns: {bf:field_a}, {bf:value_a}, {bf:field_b}, {bf:value_b},
{bf:n_both}, {bf:n_a}, {bf:n_b}, {bf:jaccard}. Cross-field co-occurrence
of value pairs with field_a < field_b lexically.

{p 8 8 2}
{bf:litdiscover_topic_by_field.dta}{break}
Columns: {bf:field}, {bf:value}, {bf:topic}, {bf:mean_share}, {bf:n_docs}.
Mean LDA topic share within each (field, value) cell.

{phang2}{bf:Stratification output}

{p 8 8 2}
{bf:litdiscover_topic_by_year.dta} (only with {opt year()}){break}
Columns: {bf:year}, {bf:topic}, {bf:mean_share}, {bf:n_docs}.

{phang2}{bf:Network-analytic outputs (only with {opt netmeasures})}

{p 8 8 2}
{bf:litdiscover_network_measures.dta}{break}
One row per (field, value). Columns: {bf:field}, {bf:value}, {bf:n_nodes},
{bf:n_edges}, {bf:degree}, {bf:strength}, {bf:betweenness}, {bf:community},
{bf:modularity}. Per-field undirected weighted graphs with edge weight equal
to the Jaccard similarity from {bf:litdiscover_cooc_within.dta}. Betweenness
uses {it:1 - jaccard} as the distance form. Louvain community indices are
0-based within each network and are not comparable across networks.

{p 8 8 2}
{bf:litdiscover_network_measures_cross.dta}{break}
One row per (field_a, field_b, field, value). Columns: {bf:field_a},
{bf:field_b}, {bf:field}, {bf:value}, {bf:n_nodes}, {bf:n_edges},
{bf:degree}, {bf:strength}, {bf:betweenness}, {bf:community},
{bf:modularity}. Per-pair bipartite undirected weighted graphs from
{bf:litdiscover_cooc_cross.dta}, with node identifier internally namespaced
as {it:field::value} to keep field domains disjoint.

{phang2}{bf:Framework outputs}

{p 8 8 2}
{bf:litdiscover_tccm.dta} (produced when {opt theory()}, {opt context()},
{opt method()}, and the TCCM characteristic field are all supplied){break}
Columns: {bf:theory}, {bf:context}, {bf:method},
{it:tccm_class_field}, {bf:n}.

{p 8 8 2}
{bf:litdiscover_ado.dta} (produced when any of {opt iv()},
{opt decision()}, {opt dv()} is supplied){break}
Columns: {bf:study_id}, {bf:ado_class}, {bf:share_within_class}.

{phang2}{bf:Static figures (only with {opt figures})}

{p 8 8 2}
All figures are written at 300 DPI in PNG format. Stata-tier figures
are also saved as Stata-native {bf:.gph}.{break}{break}
Stata-tier (via {bf:heatplot} and {bf:palettes}):{break}
- {bf:litdiscover_fig_constructfreq_}{it:field}{bf:.{gph,png}} one per supplied field, top 15 values{break}
- {bf:litdiscover_fig_topicyear.{gph,png}} multi-line plot, when {opt year()} is set{break}
- {bf:litdiscover_fig_ado.{gph,png}} ADO class frequency, when ADO output exists{break}
- {bf:litdiscover_fig_tccm.{gph,png}} theory by characteristic heatmap, when TCCM output exists{break}
- {bf:litdiscover_fig_topicheatmap_}{it:field}{bf:.{gph,png}} one per supplied field, top 15 values{break}{break}
Python-tier (via {bf:matplotlib}, {bf:seaborn}, {bf:wordcloud}):{break}
- {bf:litdiscover_fig_coherence.png} per-topic UMass bar chart, when {opt coherence} was set{break}
- {bf:litdiscover_fig_topicterms.png} small multiples of top-10 terms per topic{break}
- {bf:litdiscover_fig_wordcloud_t}{it:k}{bf:.png} one wordcloud per topic

{phang2}{bf:Interactive HTML deliverables (only with {opt interactive})}

{p 8 8 2}
- {bf:litdiscover_topicvis.html} pyLDAvis topic explorer
({help litdiscover##sievert2014:Sievert and Shirley 2014}){break}
- {bf:litdiscover_network.html} pyvis force-directed graph of within-field
construct co-occurrences (edges with Jaccard >= 0.1; nodes coloured by
field, sized by log-document-count){break}
- {bf:litdiscover_sankey.html} plotly Sankey diagram of the theory-to-topic
flow. Theory nodes are truncated to the top {opt sankeytopfreq(#)} by
total documents (default 15). Topic labels include the top three terms.


{title:Returned scalars and macros}

{pstd}
{cmd:litdiscover} is rclass. The following are returned in every call:

{synoptset 26}{...}
{synopt :{bf:r(N_input)}}observations passed to the engine after {bf:if/in}{p_end}
{synopt :{bf:r(N_docs)}}documents retained after Python text cleaning{p_end}
{synopt :{bf:r(k_topics)}}number of LDA topics fitted{p_end}
{synopt :{bf:r(n_seeds)}}number of seeds used for stability{p_end}
{synopt :{bf:r(coherence)}}1 if UMass coherence was computed, 0 otherwise{p_end}
{synopt :{bf:r(fields_supplied)}}space-separated list of construct fields supplied{p_end}
{synopt :{bf:r(export)}}flat-mode export directory; empty under {opt outdir()}{p_end}
{synopt :{bf:r(outdir)}}{opt outdir()} root directory; empty in flat mode{p_end}
{synopt :{bf:r(tables_dir)}}directory where {bf:.dta} outputs were written{p_end}
{synopt :{bf:r(figures_dir)}}directory where figure files were written{p_end}
{synopt :{bf:r(interactive_dir)}}directory where HTML files were written{p_end}
{synopt :{bf:r(figures_n)}}number of figure files produced; 0 if {opt figures} not set{p_end}
{synopt :{bf:r(interactive_n)}}number of HTML files produced; 0 if {opt interactive} not set{p_end}
{synopt :{bf:r(figures_list)}}space-separated basenames of figure files produced{p_end}
{synopt :{bf:r(interactive_list)}}space-separated basenames of HTML files produced{p_end}
{p2colreset}{...}

{pstd}
Conditional returns:

{synoptset 60}{...}
{synopt :{bf:r(years_min)} / {bf:r(years_max)}}only when {opt year()} is supplied{p_end}
{synopt :{bf:r(N_}{it:field}{bf:)}}distinct values for each supplied construct field{p_end}
{synopt :{bf:r(tccm_cells)} / {bf:r(tccm_minfreq)}}only when TCCM is emitted{p_end}
{synopt :{bf:r(tccm_class_field)}}field label used as the TCCM characteristic{p_end}
{synopt :{bf:r(ado_a)} / {bf:r(ado_d)} / {bf:r(ado_o)}}row counts per ADO class{p_end}
{synopt :{bf:r(net_networks_within)} / {bf:r(net_networks_cross)}}counts of networks built;{...}
 only with {opt netmeasures}{p_end}
{synopt :{bf:r(net_nodes_within)} / {bf:r(net_nodes_cross)}}row counts of the two network-measures files{p_end}
{synopt :{bf:r(net_modularity_mean)} / {bf:r(net_modularity_min)} / {bf:r(net_modularity_max)}}{...}
 summary statistics of within-field network modularity{p_end}
{synopt :{bf:r(net_louvain_seed)}}seed used for Louvain community detection {p_end}
{synopt :{bf:r(network_measures_file)} / {bf:r(network_measures_cross_file)}}{...}
 absolute paths to the two output files{p_end}
{synopt :{bf:r(topic_stability_file)}}absolute path to {bf:litdiscover_topic_stability.dta}{...}
 (only when {opt seeds()} > 1){p_end}
{synopt :{bf:r(topicterms_file)}}absolute path to {bf:litdiscover_topicterms.dta}{...}
 (the table autoloaded into memory by default){p_end}
{synopt :{bf:r(input_recovery_file)}}absolute path to the saved copy of the input dataset;{...}
 use with {helpb use} to restore the input data {p_end}
{synopt :{bf:r(frex_omega)} / {bf:r(frex_epsilon)}}FREX parameters; only with {opt frex}{p_end}
{synopt :{bf:r(frex_topics)} / {bf:r(frex_vocab_size)}}counts used in the FREX ECDFs{p_end}
{p2colreset}{...}


{title:Examples}

{phang2}Minimal call (engine outputs only){p_end}
{phang3}{cmd:. litdiscover, abstract(abstract)}{p_end}

{phang2}Single construct field{p_end}
{phang3}{cmd:. litdiscover, abstract(abstract) theory(theory) topics(8)}{p_end}

{phang2}Full call with all construct fields, year stratification, and the subdirectory layout{p_end}
{phang3}{cmd:. litdiscover, abstract(abstract) id(study_id) year(year) theory(theory) dv(dv) iv(iv)}{p_end}
{phang3}{cmd:        mod(mod) med(med) decision(decision) journal(journal) context(context) method(method)}{p_end}
{phang3}{cmd:        topics(8) seeds(5) coherence outdir(review_2026)}{p_end}

{phang2}With static figures and interactive HTMLs in the subdirectory layout{p_end}
{phang3}{cmd:. litdiscover, abstract(abstract) theory(theory) dv(dv) iv(iv) context(context) method(method)}{p_end}
{phang3}{cmd:        year(year) coherence outdir(review_2026) figures interactive}{p_end}

{phang2}TCCM with a non-default characteristic axis{p_end}
{phang3}{cmd:. litdiscover, abstract(abstract) theory(theory) context(context) method(method) iv(iv)}{p_end}
{phang3}{cmd:        tccmclass(iv) tccmminfreq(2)}{p_end}

{phang2}Network-analytic measures and FREX{p_end}
{phang3}{cmd:. litdiscover, abstract(abstract) theory(theory) dv(dv) iv(iv) context(context) method(method)}{p_end}
{phang3}{cmd:        topics(8) netmeasures frex}{p_end}


{title:Requirements}

{pstd}
Stata 19 or later, with Python 3 configured for use via {help python}.

{pstd}
The base Python script {bf:litdiscover.py} requires {bf:pandas},
{bf:numpy}, {bf:scikit-learn}, and {bf:scipy}.

{pstd}
{opt figures} additionally requires SSC packages {bf:heatplot},
{bf:palettes}, and {bf:colrspace}:

        {cmd:. ssc install heatplot, replace}{break}
        {cmd:. ssc install palettes, replace}{break}
        {cmd:. ssc install colrspace, replace}

{pstd}
{opt figures} and {opt interactive} together additionally require the
Python packages {bf:matplotlib}, {bf:seaborn}, {bf:wordcloud},
{bf:pyLDAvis}, {bf:pyvis}, {bf:plotly}, and {bf:networkx}:

        {cmd:. pip install matplotlib seaborn wordcloud pyldavis pyvis plotly networkx}

{pstd}
{opt netmeasures} additionally requires the Python package
{bf:networkx} (also pulled in by {opt interactive}):

        {cmd:. pip install networkx}


{marker references}{...}
{title:References}

{marker blei2003}{...}
{phang}
Blei, D. M., Ng, A. Y., and Jordan, M. I. 2003. Latent Dirichlet
allocation. {it:Journal of Machine Learning Research} 3: 993-1022.

{marker donthu2021}{...}
{phang}
Donthu, N., Kumar, S., Mukherjee, D., Pandey, N., and Lim, W. M. 2021.
How to conduct a bibliometric analysis: An overview and guidelines.
{it:Journal of Business Research} 133: 285-296.
https://doi.org/10.1016/j.jbusres.2021.04.070

{marker greene2014}{...}
{phang}
Greene, D., O'Callaghan, D., and Cunningham, P. 2014. How many topics?
Stability analysis for topic models. In {it:Machine Learning and Knowledge Discovery in Databases (ECML PKDD 2014)},
Lecture Notes in Computer Science 8724, 498-513. Springer.
https://doi.org/10.1007/978-3-662-44848-9_32

{marker jann2018}{...}
{phang}
Jann, B. 2018. Color palettes for Stata graphics. {it:The Stata Journal}
18(4): 765-785. https://doi.org/10.1177/1536867X1801800402

{marker jann2023}{...}
{phang}
Jann, B. 2023. Color palettes for Stata graphics: An update.
{it:The Stata Journal} 23(2): 336-385.
https://doi.org/10.1177/1536867X231175264

{marker mimno2011}{...}
{phang}
Mimno, D., Wallach, H. M., Talley, E., Leenders, M., and McCallum, A.
2011. Optimizing semantic coherence in topic models. In
{it:Proceedings of the 2011 Conference on Empirical Methods in Natural Language Processing}, 262-272.

{marker paul2024}{...}
{phang}
Paul, J., Khatri, P. and Duggal, H. K. 2024. Frameworks for developing
impactful systematic literature reviews and theory building: What, Why
and How?
{it:Journal of Decision Systems} 33(4): 537–550.
https://doi.org/10.1080/12460125.2023.2197700

{marker roberts2019}{...}
{phang}
Roberts, M. E., Stewart, B. M., and Tingley, D. 2019. stm: An R package
for structural topic models. {it:Journal of Statistical Software}
91(2): 1-40. https://doi.org/10.18637/jss.v091.i02

{marker sievert2014}{...}
{phang}
Sievert, C., and Shirley, K. 2014. LDAvis: A method for visualizing and
interpreting topics. In {it:Proceedings of the Workshop on Interactive
Language Learning, Visualization, and Interfaces}, 63-70.
Association for Computational Linguistics.
https://aclanthology.org/W14-3110/


{title:Aliases}

{pstd}
{cmd:litdi} is provided as a short-form alias for {cmd:litdiscover}. It
forwards every argument and propagates returned scalars and macros.


{title:Author}

{pstd}
Nebojsa S. Davcik{break}
EM Normandie Business School, Oxford, UK{break}
ORCID: 0000-0003-1041-8788{break}
{browse "https://orcid.org/0000-0003-1041-8788":https://orcid.org/0000-0003-1041-8788}{break}
Email: {browse "mailto:davcik@live.com":davcik@live.com}


{title:Citation}

{pstd}
When citing {cmd:litdiscover} in academic work, please use:

{phang2}
Davcik, N. S. 2026. {it:litdiscover: A Stata package for theory-aware literature review, analysis, and discovery.}
Available at: {browse "https://github.com/Davcik/litdiscover":https://github.com/Davcik/litdiscover}


{title:Licence}

{pstd}
{cmd:litdiscover} is free software released under the
{browse "https://www.gnu.org/licenses/gpl-3.0.html":GNU General Public License version 3 or later} (GPL-3.0-or-later).
You may redistribute and modify it under the terms of that licence;
modified versions and larger works that incorporate {cmd:litdiscover}
must also be released under GPL-3 or later. See the LICENCE file in
the repository root for the full licence text.

{pstd}
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


{title:Also see}

{phang}Short-form alias: {helpb litdi}{p_end}
