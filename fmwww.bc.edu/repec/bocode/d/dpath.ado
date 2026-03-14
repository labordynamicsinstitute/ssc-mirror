*! dpath: Construct and Audit Longitudinal Decision Paths
*! Version 1.0.0  Subir Hait, Michigan State University (2026)
*! ORCID: 0009-0004-9871-9677

/*
  dpath -- main dispatcher
  
  Subcommands:
    dpath build    -- compute decision-path variables from panel data
    dpath describe -- per-unit path descriptors
    dpath dri      -- Decision Reliability Index
    dpath entropy  -- Shannon path entropy
    dpath equity   -- distributive equity diagnostics
    dpath audit    -- full five-step integrated audit
*/

program define dpath
    version 14.0

    gettoken subcmd rest : 0, parse(" ,")
    local subcmd = strtrim(subinstr("`subcmd'", ",", "", .))

    if "`subcmd'" == "build" {
        dpath_build `rest'
    }
    else if "`subcmd'" == "describe" {
        dpath_describe `rest'
    }
    else if "`subcmd'" == "dri" {
        dpath_dri `rest'
    }
    else if "`subcmd'" == "entropy" {
        dpath_entropy `rest'
    }
    else if "`subcmd'" == "equity" {
        dpath_equity `rest'
    }
    else if "`subcmd'" == "audit" {
        dpath_audit `rest'
    }
    else {
        di as error "Unknown subcommand: `subcmd'"
        di as text  "Valid subcommands: build, describe, dri, entropy, equity, audit"
        di as text  "Type {stata help dpath} for documentation."
        exit 198
    }
end
