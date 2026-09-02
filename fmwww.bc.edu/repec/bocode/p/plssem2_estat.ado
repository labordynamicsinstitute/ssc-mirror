*! plssem2_estat version 1.0.0
*! Post-estimation dispatcher for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026
*!
*! plssem2 sets e(estat_cmd) = "plssem2_estat".  The individual estat_*
*! programs (estat_loadings, estat_weights, ...) are also provided as
*! separate ado-files so that both the e(estat_cmd) mechanism and the
*! direct estat_<subcommand> mechanism work.

program plssem2_estat
  version 15.1
  gettoken subcmd 0 : 0
  local subcmd : subinstr local subcmd "," "" , all
  if "`subcmd'" == "" {
    display as error "plssem2_estat subcommands:"
    display as error "    loadings, weights, reliability, htmt, effects,"
    display as error "    q2, vif, f2, summarize, group"
    exit 198
  }
  local known "loadings weights reliability htmt effects q2 vif f2 summarize group"
  if !`: list subcmd in known' {
    display as error "unknown subcommand: `subcmd'"
    exit 198
  }
  if "`e(cmd)'" != "plssem2" {
    display as error "last estimates not found; run plssem2 first"
    exit 301
  }
  if "`0'" != "" {
    estat_`subcmd' , `0'
  }
  else {
    estat_`subcmd'
  }
end
