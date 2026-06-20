/*!
_littext_analyze: run the construct/relationship pipeline on the current dataset.

Output: three Stata frames left in memory
  lt_constructs   - canonical constructs with frequency and cluster info
  lt_relations    - candidate construct relationships with confidence scores
  lt_diag         - per-document diagnostics
*/

program define _littext_analyze, eclass
    version 19.0
    local entry_frame = c(frame)
    syntax , Text(varname) [Id(varname) Year(varname) Journal(varname) Unit(string) EMBedmodel(string) MINFreq(string) MAXRelations(integer 100000) MINTextlen(string) KEEPEmpty ADDSentiment Quiet Saving(string) Replace TEXTtype(string)]
    local texttype_user = lower(trim("`texttype'"))
    if "`texttype_user'" == "" {
        local texttype "abstract"
        local texttype_explicit = 0
    }
    else {
        if !inlist("`texttype_user'", "abstract", "fulltext", "transcript", "review", "comment", "other") {
            di as err "littext: texttype() must be one of:"
            di as err "        abstract, fulltext, transcript, review, comment, other"
            exit 198
        }
        local texttype "`texttype_user'"
        local texttype_explicit = 1
    }
    /* Texttype-derived defaults for unit() and mintextlen(). These
       are honored only when the user has not passed the option
       explicitly. */
    if "`texttype'" == "abstract" {
        local tt_unit "sentence"
        local tt_mintextlen 50
    }
    if "`texttype'" == "fulltext" {
        local tt_unit "paragraph"
        local tt_mintextlen 500
    }
    if "`texttype'" == "transcript" {
        local tt_unit "sentence"
        local tt_mintextlen 30
    }
    if "`texttype'" == "review" {
        local tt_unit "sentence"
        local tt_mintextlen 20
    }
    if "`texttype'" == "comment" {
        local tt_unit "sentence"
        local tt_mintextlen 10
    }
    if "`texttype'" == "other" {
        local tt_unit "sentence"
        local tt_mintextlen 50
    }
    /* unit(): honour explicit user value; otherwise use the
       texttype-derived default. */
    if "`unit'" == "" {
        local unit "`tt_unit'"
        local unit_source "texttype default"
    }
    else {
        local unit_source "user-specified"
    }
    if !inlist("`unit'", "sentence", "abstract", "paragraph") {
        di as err "littext: unit() must be sentence, abstract, or paragraph"
        exit 198
    }
    if "`embedmodel'" == "" local embedmodel "all-MiniLM-L6-v2"
    local mintextlen_user = trim("`mintextlen'")
    if "`mintextlen_user'" == "" {
        local mintextlen = `tt_mintextlen'
        local mintextlen_source "texttype default"
    }
    else {
        capture confirm integer number `mintextlen_user'
        if _rc {
            di as err "littext: mintextlen() must be a non-negative integer"
            exit 198
        }
        local mintextlen = `mintextlen_user'
        local mintextlen_source "user-specified"
    }
    if `mintextlen' < 0 {
        di as err "littext: mintextlen() must be a non-negative integer"
        exit 198
    }
    local keepempty_flag = ("`keepempty'" != "")
    qui count
    local n_docs = r(N)
    local minfreq_user = "`minfreq'"
    if "`minfreq'" == "" {
        if `n_docs' < 50 local minfreq = 1
        else             local minfreq = 2
    }
    else {
        capture confirm integer number `minfreq'
        if _rc {
            di as err "littext: minfreq() must be a non-negative integer"
            exit 198
        }
        if `minfreq' < 1 {
            di as err "littext: minfreq() must be at least 1"
            exit 198
        }
    }
    local addsent = ("`addsentiment'" != "")
    local q = ("`quiet'" != "")
    if "`id'" == "" {
        tempvar autoid
        gen long `autoid' = _n
        local id "`autoid'"
        local id_autogen = 1
    }
    else {
        local id_autogen = 0
    }
    
    if _rc {
        di as err "littext: text() variable '`text'' is not a string variable."
        di as err "        Cast it to string first (decode/tostring), or supply a different variable."
        exit 109
    }
    /* Stage 1: cheap environment check (sub-millisecond; uses find_spec). */
    if !`q' di as txt "[1/5] littext: env check..."
    _littext_install, quiet
    /* Stage 2: resolve the package's Python directory (development or
       flattened-install layout) via the shared resolver. */
    if !`q' di as txt "[2/5] littext: resolving package path..."
    _littext_resolve, subdir(python) name(littext_run.py)
    local pypath `"`r(dir)'"'
    local runscript `"`r(path)'"'
    
    if !`q' {
        
        if !`texttype_explicit' {
            di as txt "littext: texttype not declared; defaulting to texttype(abstract)."
            di as txt "        For full-text corpora pass texttype(fulltext); for transcripts texttype(transcript);"
            di as txt "        for consumer reviews texttype(review); for social-media comments texttype(comment);"
            di as txt "        for anything else texttype(other) applies minimal cleaning only."
        }
        else {
            di as txt "littext: texttype=`texttype' (user-specified)."
        }
        di as txt "littext: unit=`unit' (`unit_source')"
        di as txt "littext: mintextlen=`mintextlen' (`mintextlen_source')"
        if `keepempty_flag' {
            di as txt "        keepempty set: empty and short rows will be retained (mintextlen ignored)."
        }
        if "`minfreq_user'" != "" {
            di as txt "littext: minfreq=`minfreq' (user-specified)"
        }
        else if `n_docs' < 50 {
            di as txt "littext: minfreq=1 (default for small corpora: `n_docs' documents < 50)"
            di as txt "        Single-document constructs are retained; suppress noise by passing minfreq(2)."
        }
        else {
            di as txt "littext: minfreq=2 (default for corpora of `n_docs' documents)"
        }
    }
    /* Stage 3: marshal the corpus to a temporary .dta. */
    if !`q' di as txt "[3/5] littext: marshalling corpus to temporary .dta..."
    tempfile corpus_dta
    preserve
    keep `id' `text' `year' `journal'
    rename `text' lt_text
    rename `id' lt_id

    if !`keepempty_flag' {
        local n_before = _N
        /* (1) Drop empty/whitespace-only text */
        qui drop if missing(lt_text)
        qui drop if trim(lt_text) == ""
        local n_after_empty = _N
        local n_drop_empty = `n_before' - `n_after_empty'
        /* (2) Drop missing id, only when id() was user-supplied */
        if !`id_autogen' {
            capture confirm string variable lt_id
            if _rc == 0 qui drop if missing(lt_id) | trim(lt_id) == ""
            else        qui drop if missing(lt_id)
        }
        local n_after_id = _N
        local n_drop_id = `n_after_empty' - `n_after_id'
        /* (3) Drop too-short text */
        if `mintextlen' > 0 qui drop if strlen(lt_text) < `mintextlen'
        local n_after_short = _N
        local n_drop_short = `n_after_id' - `n_after_short'
        local n_kept = _N
        if !`q' {
            di as txt "littext: row-drop summary"
            di as txt "        rows in:            `n_before'"
            if `n_drop_empty' > 0 di as txt "        dropped (empty):    `n_drop_empty'"
            if `n_drop_id' > 0    di as txt "        dropped (no id):    `n_drop_id'"
            if `n_drop_short' > 0 di as txt "        dropped (< `mintextlen' chr): `n_drop_short'"
            di as txt "        rows kept:          `n_kept'"
            /* Material-change warning: more than 25% of rows dropped */
            if `n_before' > 0 {
                local drop_share = (`n_before' - `n_kept') / `n_before'
                if `drop_share' > 0.25 {
                    local drop_pct = round(`drop_share' * 100)
                    di as txt ""
                    di as err "littext: WARNING -- `drop_pct'% of rows were dropped during row-drop."
                    di as err "        Verify that text() points at the intended column and that"
                    di as err "        mintextlen() (currently `mintextlen') is appropriate for this text kind."
                    di as err "        Pass keepempty to disable row-drop and retain all rows."
                }
            }
        }
        /* No-rows guardrail fires irrespective of quiet -- the user always
           needs to know why the pipeline cannot proceed. */
        if `n_kept' == 0 {
            di as err "littext: ERROR -- no rows remain after row-drop. Cannot proceed."
            di as err "        Common causes: text() points at a column that is mostly empty"
            di as err "        or whose entries are all shorter than mintextlen=`mintextlen'."
            restore
            exit 459
        }
    }
    capture confirm string variable lt_id
    if _rc tostring lt_id, replace force
    if "`year'" != "" rename `year' lt_year
    else gen lt_year = .
    if "`journal'" != "" rename `journal' lt_journal
    else gen str1 lt_journal = ""
    qui save "`corpus_dta'", replace
    restore
    /* Stage 4: create the three output frames so Python can populate them. */
    if !`q' di as txt "[4/5] littext: creating output frames..."
    
    if inlist("`entry_frame'", "lt_constructs", "lt_relations", "lt_diag") {
        local entry_frame "default"
    }
    frame change `entry_frame'
    capture frame drop lt_constructs
    capture frame drop lt_relations
    capture frame drop lt_diag
    frame create lt_constructs
    frame create lt_relations
    frame create lt_diag
    /* Stage 5: run the pipeline. This is a single bridge crossing.
       The Python script reads pypath, corpus_dta, unit, embedmodel, minfreq,
       maxrelations, addsent, and q from Stata locals via sfi.Macro. */
    if !`q' di as txt "[5/5] littext: running pipeline (single bridge crossing; spaCy + sentence-transformers load lazily on first run, ~30-120s)..."
    python script `"`runscript'"'
    if !`q' di as txt "littext: pipeline returned; finalising..."
    frame lt_relations: qui count
    local nrel = r(N)
    frame lt_constructs: qui count
    local ncon = r(N)
    if "`saving'" != "" {
        local repl = ("`replace'" != "") * 1
        if `repl' local replopt "replace"
        else local replopt ""
        frame lt_constructs: save "`saving'_constructs.dta", `replopt'
        frame lt_relations:  save "`saving'_relations.dta",  `replopt'
        frame lt_diag:       save "`saving'_diag.dta",       `replopt'
        if !`q' di as txt "littext: results also written to '`saving'_*.dta'"
    }
    frame change `entry_frame'
    if !`q' {
        di as txt ""
        di as txt "littext: analysis complete."
        di as txt "  Constructs extracted: `ncon'"
        di as txt "  Candidate relationships: `nrel'"
        di as txt "  Results are in frames lt_constructs, lt_relations, lt_diag."
        di as txt "  You remain in your data frame (`entry_frame')."
        di as txt ""
        di as txt "Try:  frame lt_relations: list source target relation_type confidence in 1/10"
        di as txt "      frame lt_relations: tab relation_type"
        di as txt `"      littext graph, type(map) outdir("...")"'
        di as txt `"      littext export, outdir("...")"'
    }
    ereturn local cmd = "littext analyze"
    ereturn local unit = "`unit'"
    ereturn local embed_model = "`embedmodel'"
    ereturn scalar n_constructs = `ncon'
    ereturn scalar n_relations  = `nrel'
end
