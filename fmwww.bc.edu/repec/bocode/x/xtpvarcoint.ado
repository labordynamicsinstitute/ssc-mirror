*! xtpvarcoint.ado — Panel VAR Modeling with Cointegration, Structural Breaks & CSD
*! Version 1.0.1 — 05 April 2026
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements panel cointegration rank tests, panel VAR/VECM estimators,
*! panel SVAR identification, specification tools, IRF/FEVD, and bootstrap
*! for heterogeneous panels with structural breaks and cross-sectional dependence.

capture program drop xtpvarcoint
program define xtpvarcoint, rclass
  version 14.0
  
  * ---- Load engine subroutines ----
  local subfiles "_xtpvarcoint_mata _xtpvarcoint_rscoef _xtpvarcoint_moments"
  foreach sf of local subfiles {
    capture findfile `sf'.ado
    if _rc {
      di in red "required file `sf'.ado not found"
      di in red "install it alongside xtpvarcoint.ado"
      exit 601
    }
    capture qui run "`r(fn)'"
  }
  
  * ---- Parse subcommand ----
  gettoken subcmd 0 : 0
  * Strip trailing comma (gettoken keeps it for "cmd, opts" syntax)
  local _had_comma = (strpos("`subcmd'", ",") > 0)
  local subcmd : subinstr local subcmd "," "", all
  local subcmd = strtrim(lower("`subcmd'"))
  * If subcmd had a comma, prepend comma to 0 for proper syntax parsing
  if `_had_comma' {
    local 0 ", `0'"
  }
  
  if "`subcmd'" == "pcoint" {
    capture findfile _xtpvarcoint_pcoint.ado
    if _rc {
      di in red "_xtpvarcoint_pcoint.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_pcoint `0'
  }
  else if "`subcmd'" == "coint" {
    capture findfile _xtpvarcoint_coint.ado
    if _rc {
      di in red "_xtpvarcoint_coint.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_coint `0'
  }
  else if "`subcmd'" == "pvar" {
    capture findfile _xtpvarcoint_pvar.ado
    if _rc {
      di in red "_xtpvarcoint_pvar.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_pvar `0'
  }
  else if "`subcmd'" == "pvec" {
    capture findfile _xtpvarcoint_pvar.ado
    if _rc {
      di in red "_xtpvarcoint_pvar.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_pvec `0'
  }
  else if "`subcmd'" == "vecm" {
    capture findfile _xtpvarcoint_pvar.ado
    if _rc {
      di in red "_xtpvarcoint_pvar.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_vecm `0'
  }
  else if "`subcmd'" == "pid" {
    capture findfile _xtpvarcoint_pid.ado
    if _rc {
      di in red "_xtpvarcoint_pid.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_pid `0'
  }
  else if "`subcmd'" == "speci" {
    capture findfile _xtpvarcoint_speci.ado
    if _rc {
      di in red "_xtpvarcoint_speci.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_speci `0'
  }
  else if "`subcmd'" == "irf" {
    capture findfile _xtpvarcoint_irf.ado
    if _rc {
      di in red "_xtpvarcoint_irf.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_irf `0'
  }
  else if "`subcmd'" == "fevd" {
    capture findfile _xtpvarcoint_irf.ado
    if _rc {
      di in red "_xtpvarcoint_irf.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_fevd `0'
  }
  else if "`subcmd'" == "sboot" {
    capture findfile _xtpvarcoint_sboot.ado
    if _rc {
      di in red "_xtpvarcoint_sboot.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_sboot `0'
  }
  else if "`subcmd'" == "plot" {
    capture findfile _xtpvarcoint_plot.ado
    if _rc {
      di in red "_xtpvarcoint_plot.ado not found"
      exit 601
    }
    capture qui run "`r(fn)'"
    _xpvc_plot `0'
  }
  else {
    di
    di in smcl in gr "{hline 78}"
    di in gr "{bf:xtpvarcoint} — Panel VAR Modeling with Cointegration" ///
      _col(60) in ye "v1.0.1"
    di in smcl in gr "{hline 78}"
    di
    di in gr "  {bf:Usage:} xtpvarcoint {it:subcommand} {it:varlist} [, {it:options}]"
    di
    di in gr "  {bf:Subcommands:}"
    di in ye "    pcoint" in gr "    Panel cointegration rank tests"
    di in gr "                  (Johansen, Breitung, Saikkonen-Luetkepohl, CAIN)"
    di in ye "    coint"  in gr "     Individual cointegration rank tests"
    di in ye "    pvar"   in gr "      Panel VAR estimation (Mean Group)"
    di in ye "    pvec"   in gr "      Panel VECM estimation (Pooled Mean Group)"
    di in ye "    vecm"   in gr "      Individual VECM estimation"
    di in ye "    pid"    in gr "       Panel SVAR identification"
    di in gr "                  (Cholesky, long-run/short-run, proxy/IV, DC, CVM)"
    di in ye "    speci"  in gr "     Specification tools (factors, lags, breaks)"
    di in ye "    irf"    in gr "       Impulse response functions"
    di in ye "    fevd"   in gr "      Forecast error variance decomposition"
    di in ye "    sboot"  in gr "     Bootstrap inference (panel moving-block)"
    di in ye "    plot"   in gr "      Publication-quality graphs"
    di
    di in smcl in gr "{hline 78}"
    di in gr "  Dr Merwan Roudane — merwanroudane920@gmail.com"
    di in smcl in gr "{hline 78}"
    di
    if "`subcmd'" != "" {
      di in red "unknown subcommand: `subcmd'"
      exit 198
    }
  }
  
end
