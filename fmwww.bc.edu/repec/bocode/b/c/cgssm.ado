*! version 0.2 2023-01-23 Niels Henrik Bruun
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2023-02-21 v0.2  Adding graph options are now working (Thank you to Eric Melse)
*! 2023-02-21 v0.2  functionality for weights added (Thank you to Eric Melse)
* 2023-02-10 v0.1   created
capture program drop cgssm
program define cgssm, rclass

  version 12

  syntax varlist(min=1 max= 2 numeric fv) [if] [in] [fw aw iw],  /*
    */[ /*
      */by(varname numeric fv) /*
      */Refname(passthru) /*
      */Compname(passthru) /*
      */Header(passthru) /*
      */CPFormat(passthru) /*
      */PFormat(passthru) /*
      */Graph /*
      */ * /*
    */]
    
    *local graph_opt `options'
    tempvar touse
    mark `touse' `if' `in'

    if "`:word count `varlist''" == "2" {
      tokenize "`varlist'"
      qui su `1' if `touse' [`weight'`exp']
      matrix _m_sd_rowmat = r(mean), r(sd)
      qui su `2' if `touse' [`weight'`exp']
      matrix _m_sd_rowmat = _m_sd_rowmat \ r(mean), r(sd)
      if "`refname'" == "" local refname refname(`1')
      if "`compname'" == "" local compname compname(`2')
    }
    else {
      if "`by'" == "" mata: _error("Option {bf:by} must be a variable, when only one variable in varlist")
      mata: by_binary = strofreal(select(vals=uniqrows(st_data(., "`by'")), vals :< .)' == (0,1))
      mata: st_local("by_binary", by_binary)
      if ! `by_binary' mata: _error("Option {bf:by} must be a 01-variable")
      qui su `varlist' if `by' == 1 & `touse' [`weight'`exp']
      matrix _m_sd_rowmat = r(mean), r(sd)
      qui su `varlist' if `by' == 0 & `touse' [`weight'`exp']
      matrix _m_sd_rowmat = _m_sd_rowmat \ r(mean), r(sd)
      if "`refname'" == "" local refname refname(`by' == 1)
      if "`compname'" == "" local compname compname(`by' == 0)
    }
    
    cgssmi,  msdrowmatrix("_m_sd_rowmat") `refname' `compname' `header' ///
      `cpformat' `pformat' `graph' `options'
   return add
end
