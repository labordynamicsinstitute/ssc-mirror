/*!
_littext_graph: produce figures from the current littext analysis.

Types:
  frequency     bar chart of top-k constructs by document frequency  (Stata)
  distribution  stacked bar of relationship-type distribution        (Stata)
  trend         construct frequency over publication year            (Stata)
  confidence    histogram of relationship confidence scores          (Stata)
  extraction    bar of relations by the extraction method            (Stata)
  map           UMAP concept map of construct embeddings             (matplotlib)
  network       force-directed relationship network                  (matplotlib)
  dendrogram    construct-cluster dendrogram                         (matplotlib)
  cooccurrence  pairwise NPMI heatmap of top-k constructs            (matplotlib)
  roles         construct x relation-type heatmap                    (matplotlib)

Options:
  top(#)        for heatmaps, the top-k constructs (by frequency) included
  outdir(path)  absolute path for output (REQUIRED; no default)
  weighted      for type(network): color edges by confidence rather than by
                relation type
  saving(stub)  file stub (default: littext_<type>)
  replace       overwrite existing files
*/

program define _littext_graph
    version 19.0
    syntax , [Type(string) Top(integer 20) Saving(string) OUTdir(string) WEighted Replace NAme(string) LEVel(string) FORMat(string) EMBed(string)]
    if "`type'" == "" local type "map"
    local ok_native = inlist("`type'", "frequency", "distribution", "trend", "confidence", "extraction")
    local ok_mpl = inlist("`type'", "map", "network", "dendrogram", "cooccurrence", "roles")
    if !`ok_native' & !`ok_mpl' {
        di as err "littext graph: type() must be one of:"
        di as err "  frequency, distribution, trend, confidence, extraction (Stata-native)"
        di as err "  map, network, dendrogram, cooccurrence, roles (matplotlib)"
        exit 198
    }
    
    if "`level'" == "" local level "leaf"
    if !inlist("`level'", "leaf", "root") {
        capture confirm integer number `level'
        if _rc {
            di as err "littext graph: level() must be 'leaf', 'root', or a non-negative integer"
            exit 198
        }
        if `level' < 0 {
            di as err "littext graph: level() must be non-negative"
            exit 198
        }
    }
    capture confirm frame lt_relations
    if _rc {
        di as err "littext: no analysis results found. Run -littext analyze- first."
        exit 198
    }
    
    if `"`outdir'"' == "" {
        di as err "littext graph: outdir() is required."
        di as txt `"        Pass an absolute path, e.g. outdir("D:/myproject/figures"),"'
        di as txt "        so the figure destination is explicit and predictable."
        exit 198
    }
    local first2 = substr(`"`outdir'"', 2, 1)
    local first1 = substr(`"`outdir'"', 1, 1)
    local is_abs = (`"`first2'"' == ":") | (`"`first1'"' == "/")
    if !`is_abs' {
        di as txt `"littext: WARNING -- outdir() looks relative; resolving against the current working directory ("`c(pwd)'")."'
        local outdir `"`c(pwd)'/`outdir'"'
    }
    capture mkdir `"`outdir'"'
    
    if `"`format'"' == "" local format "static"
    local format = lower(trim(`"`format'"'))
    if !inlist("`format'", "static", "html", "both") {
        di as err `"littext graph: format() must be static, html, or both (got "`format'")."'
        exit 198
    }
    if `"`embed'"' == "" local embed "selfcontained"
    local embed = lower(trim(`"`embed'"'))
    if !inlist("`embed'", "selfcontained", "cdn") {
        di as err `"littext graph: embed() must be selfcontained or cdn (got "`embed'")."'
        exit 198
    }
    /* Stata-native types */
    if inlist("`type'", "frequency", "distribution", "trend", "confidence", "extraction") {
        if "`format'" != "static" {
            di as txt "littext: NOTE -- format(`format') applies only to the matplotlib figure types"
            di as txt "        (map, network, dendrogram, cooccurrence, roles). type(`type') is"
            di as txt "        Stata-native and always produces a static graph; format() ignored."
        }
        _littext_graph_stata, type(`type') top(`top') saving(`"`saving'"') outdir(`"`outdir'"') `replace' name(`"`name'"') level(`level')
        exit
    }
    /* matplotlib types: dispatch to draw_figure in littext_viz.py. */
    _littext_resolve, subdir(python) name(littext_run.py)
    local pypath `"`r(dir)'"'
    if "`saving'" == "" local saving "littext_`type'"
    local outstub `"`outdir'/`saving'"'
    local weighted_flag = ("`weighted'" != "")
    python: import sys
    python: sys.path.insert(0, r"`pypath'")
    python: from littext_viz import draw_figure
    python: draw_figure(kind="`type'", top=`top', out_stub=r"`outstub'", weighted=bool(`weighted_flag'), level="`level'", fmt="`format'", embed="`embed'")
    if "`format'" == "static" {
        di as txt `"littext: figure saved to "`outstub'.png" and "`outstub'.pdf""'
    }
    else if "`format'" == "html" {
        di as txt `"littext: interactive figure saved to "`outstub'.html""'
    }
    else {
        di as txt `"littext: figures saved to "`outstub'.png", "`outstub'.pdf", and "`outstub'.html""'
    }
end

program define _littext_graph_stata
    version 19.0
    syntax , Type(string) [Top(integer 20) Saving(string) OUTdir(string) Replace NAme(string) LEVel(string)]
    if "`name'" == "" local name "littext_`type'"
    if "`level'" == "" local level "leaf"
    local repl = ("`replace'" != "")
    if `repl' local replopt "replace"
    else local replopt ""
    frame pwf
    local origfrm = r(currentframe)
    
    if "`level'" != "leaf" & !inlist("`type'", "frequency") {
        di as txt "littext: NOTE -- level(`level') has no effect on type(`type'); proceeding at leaf level."
    }
    
    if "`type'" == "frequency" {
        capture frame drop _lt_g_freq
        frame copy lt_constructs _lt_g_freq
        frame change _lt_g_freq
        /* v0.3: apply hierarchy roll-up to canonical_form before
           collapsing. _lt_remap_canonical computes the rolled form in
           place. If the constructs frame predates v0.3 (no
           hierarchy_depth column), the helper is a no-op. */
        if "`level'" != "leaf" {
            _lt_remap_canonical, level(`level')
        }
        collapse (sum) freq_doc, by(canonical_form)
        gsort -freq_doc
        if _N > `top' keep if _n <= `top'
        graph hbar (asis) freq_doc, over(canonical_form, sort(1) descending label(labsize(small))) ytitle("Document frequency (summed within canonical cluster)") title("Top constructs by document frequency") name(`name', `replopt')
        frame change `origfrm'
        frame drop _lt_g_freq
    }
    else if "`type'" == "distribution" {
        capture frame drop _lt_g_dist
        frame copy lt_relations _lt_g_dist
        frame change _lt_g_dist
        contract relation_type
        gsort -_freq
        graph hbar (asis) _freq, over(relation_type, sort(1) descending) ytitle("Number of candidate relationships") title("Distribution of relationship types") name(`name', `replopt')
        frame change `origfrm'
        frame drop _lt_g_dist
    }
    else if "`type'" == "extraction" {
        capture frame drop _lt_g_extr
        frame copy lt_relations _lt_g_extr
        frame change _lt_g_extr
        contract extraction_method
        gsort -_freq
        graph hbar (asis) _freq, over(extraction_method, sort(1) descending label(labsize(small))) ytitle("Number of candidate relationships") title("Distribution by extraction method") subtitle("cooccur = co-occurrence only (no syntactic pattern matched)") name(`name', `replopt')
        frame change `origfrm'
        frame drop _lt_g_extr
    }
    else if "`type'" == "trend" {
        capture frame drop _lt_g_trend
        frame copy lt_diag _lt_g_trend
        frame change _lt_g_trend
        capture confirm variable year
        if _rc {
            di as err "littext graph trend: no year variable in lt_diag"
            di as err "                     (did you pass year() to analyze?)"
            frame change `origfrm'
            frame drop _lt_g_trend
            exit 198
        }
        drop if missing(year)
        if _N == 0 {
            di as err "littext graph trend: no non-missing year values to plot."
            frame change `origfrm'
            frame drop _lt_g_trend
            exit 198
        }
        collapse (sum) n_constructs_extracted n_relations_extracted, by(year)
        twoway (line n_constructs_extracted year, lwidth(medthick)) (line n_relations_extracted year, lwidth(medthick) lpattern(dash)), legend(order(1 "Constructs" 2 "Relationships")) title("Extraction yield over time") xtitle("Year") ytitle("Count") name(`name', `replopt')
        frame change `origfrm'
        frame drop _lt_g_trend
    }
    else if "`type'" == "confidence" {
        capture frame drop _lt_g_conf
        frame copy lt_relations _lt_g_conf
        frame change _lt_g_conf
        histogram confidence, freq title("Distribution of candidate-relationship confidence") xtitle("Confidence") ytitle("Count") name(`name', `replopt')
        frame change `origfrm'
        frame drop _lt_g_conf
    }
    local outstub `"`outdir'/`name'"'
    quietly graph export `"`outstub'.png"', `replopt' width(1600)
    di as txt `"littext: figure saved to "`outstub'.png""'
end


program define _lt_remap_canonical
    version 19.0
    syntax , LEVel(string)
    capture confirm variable canonical_root
    if _rc {
        di as txt "littext: NOTE -- frame lacks canonical_root column; level() not applied."
        exit 0
    }
    if "`level'" == "root" {
        /* Fast path: substitute canonical_form with the precomputed root. */
        qui replace canonical_form = canonical_root
        exit 0
    }
    /* Slow path: arbitrary depth N. Walk parent_canonical chain
       N steps using repeated merges against a parent-lookup table
       built from lt_constructs. */
    capture confirm variable parent_canonical
    if _rc {
        di as txt "littext: NOTE -- frame lacks parent_canonical column; level() not applied."
        exit 0
    }
    capture confirm variable hierarchy_depth
    if _rc {
        di as txt "littext: NOTE -- frame lacks hierarchy_depth column; level() not applied."
        exit 0
    }
    local target_depth = `level'
    /* Build a one-row-per-canonical lookup table from lt_constructs. */
    tempfile lookup
    frame lt_constructs {
        preserve
        keep canonical_form parent_canonical
        bys canonical_form: keep if _n == 1
        rename canonical_form _from
        rename parent_canonical _parent
        qui save `"`lookup'"', replace
        restore
    }
    
    qui summarize hierarchy_depth, meanonly
    local max_iter = max(`r(max)' - `target_depth', 1)
    local iter = 0
    while `iter' < `max_iter' {
        qui count if hierarchy_depth > `target_depth' & canonical_form != ""
        if r(N) == 0 continue, break
        rename canonical_form _from
        qui merge m:1 _from using `"`lookup'"', keep(master match) nogenerate
        qui replace _from = _parent if hierarchy_depth > `target_depth' & _parent != ""
        rename _from canonical_form
        qui drop _parent
        qui replace hierarchy_depth = hierarchy_depth - 1 if hierarchy_depth > `target_depth'
        local ++iter
    }
end
