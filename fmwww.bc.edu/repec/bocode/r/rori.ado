*! Package rori v. 0.12
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! Rewritten due to comments. Thanks to Eric Melse
* 2022-05-29 Version bug fixed
* 2022-05-23 created

*capture program drop rori
program define rori, rclass
    version 12
    syntax, /*
        */Targetpopulation(string)    /*ABCD[EF...] or AC[E...] or BC[F...]
        */Responsepopulation(string)  /*abcd[ef...] or ac[e...] or bc[e...]
        */[ /*
          */REFerence(integer 1) /*
          */]
      
    capture matrix _t = `targetpopulation'
    if _rc mata _error("Target is not a matrix or a matrix definition")
    capture matrix _r = `responsepopulation'
    if _rc mata _error("Response is not a matrix or a matrix definition")
    mata: rori(st_matrix("_t"), st_matrix("_r"), `reference') 
    return add
end


mata mata clear
mata
    real matrix ci(real matrix ln_m_se)
    {
      real scalar r, R, m, se, z
      real matrix out
      
      z = invnormal(0.5 + c("level") * 0.005)
      R = rows(ln_m_se)
      out = J(R,1,(1,.,.))
      for(r=1;r<=R;r++){
        if ( ln_m_se[r,.] == (.,.) ) out[r,1] = .
        se = ln_m_se[r,2]
        if ( se >= . ) continue
        m = ln_m_se[r,1]
        out[r,.] = exp((m, m - z * se, m + z * se))
      }
      return(out)
    }
  
    real matrix ln_mean_se_rsp_tgt(real matrix rsp, real matrix tgt)
    {
      real scalar r, R, m, se

      R = rows(rsp)
      m_se = J(R,2,.)
      for(r=1; r<=R; r++){
        se = sqrt(rsp[r,2]:^2 - tgt[r,2]:^2)
        if ( missing(se) ) continue
        m = rsp[r,1] - tgt[r,1]
        m_se[r,.] = m, se
      }
      return(m_se)
    }
    
    real matrix ln_p_se(real colvector n)
    {
      real colvector lnp, se_lnp
      
      lnp = log(n :/ colsum(n))
      se_lnp = sqrt(1 :/ n)
      return((lnp, se_lnp))
    }

    real matrix ln_or_se(real matrix m, | real scalar ref)
    {
      real scalar r, R
      real matrix tbl, m_se
      
      ref = missing(ref) ? 1 : ref
      R = rows(m)
      m_se = J(R, 1, (1,.))
      for(r=1; r<=R; r++) {
        if ( r == ref ) continue
        tbl = m[(ref,r), .]
        m_se[r,.] = (1, -1) * ln(tbl) * (1, -1)', sqrt(sum(1 :/ tbl))
      }
      return(m_se)
    }
    
    real scalar validate_target_respons(real matrix tgt, real matrix rsp)
    {
      if ( cols(tgt) != cols(rsp) | rows(tgt) != rows(rsp) ) _error("Target and response matrix must have same shape.")
      if ( cols(tgt) == 0 | cols(tgt) > 2 ) _error("Target matrix must have 1 or 2 columns")
      if ( cols(rsp) == 0 | cols(rsp) > 2 ) _error("respons matrix must have 1 or 2 columns")
      if ( rows(tgt) < 2 ) _error("Target matrix must have at least 2 rows")
      if ( rows(rsp) < 2 ) _error("response matrix must have at least 2 rows")
      if ( any(tgt :< rsp) ) _error("Target cells must be greater than response cells")
      
      return(cols(tgt) == 2)
    }
    
    void rori(real matrix tgt, real matrix rsp, | real scalar ref)
    {
      real scalar ror_rrf
      real matrix t_m_se1, r_m_se1, t_m_se2, r_m_se2, rrf, ror
      string scalar ci_txt
      
      st_rclear()
      ror_rrf = validate_target_respons(tgt, rsp)
      ci_txt = sprintf("[%2.0f%%", c("level"))
      if ( ror_rrf ) {
        r_m_se1 = ln_p_se(rsp[.,1])
        t_m_se1 = ln_p_se(tgt[.,1])
        r_m_se2 = ln_p_se(rsp[.,2])
        t_m_se2 = ln_p_se(tgt[.,2])
        rrf = ci(r_m_se1), ci(t_m_se1), ci(ln_mean_se_rsp_tgt(r_m_se1, t_m_se1)),
          ci(r_m_se2), ci(t_m_se2), ci(ln_mean_se_rsp_tgt(r_m_se2, t_m_se2))
        st_matrix("r(rrf)", rrf)
        st_matrixcolstripe("r(rrf)", 
          (J(1,3,"rsp(col1)"), J(1,3,"tgt(col1)"), J(1,3,"rsp(col1) vs tgt(col1)"), 
          J(1,3,"rsp(col2)"), J(1,3,"tgt(col2)"), J(1,3,"rsp(col2) vs tgt(col2)") 
          \ J(1,2, ("P", ci_txt, "CI]")), "RRF", ci_txt, "CI]",
          J(1,2, ("P", ci_txt, "CI]")), "RRF", ci_txt, "CI]")')
        st_matrixrowstripe("r(rrf)", st_matrixrowstripe("_t"))
        
        r_m_se1 = ln_or_se(rsp, ref)
        t_m_se1 = ln_or_se(tgt, ref)
        ror = ci(r_m_se1), ci(t_m_se1), ci(ln_mean_se_rsp_tgt(r_m_se1, t_m_se1))
        st_matrix("r(ror)", ror)
        st_matrixcolstripe("r(ror)", 
          (J(1,3,"rsp"), J(1,3,"tgt"), J(1,3,"rsp vs tgt") 
          \ J(1,2, ("OR", ci_txt, "CI]")), "ROR", ci_txt, "CI]")')
        st_matrixrowstripe("r(ror)", st_matrixrowstripe("_t"))
      } else {
        rrf = (ci(ln_p_se(rsp)), ci(ln_p_se(tgt)), 
          ci(ln_mean_se_rsp_tgt(ln_p_se(rsp), ln_p_se(tgt))))
        st_matrix("r(rrf)", rrf)
        st_matrixcolstripe("r(rrf)", 
          (J(1,3,"rsp"), J(1,3,"tgt"), J(1,3,"rsp vs tgt") 
          \ J(1,2, ("P", ci_txt, "CI]")), "RRF", ci_txt, "CI]")')
        st_matrixrowstripe("r(rrf)", st_matrixrowstripe("_t"))
      }
    }
end

exit


/*
cls
rori, t(22193 \ 17277 \ 9065) r(7719 \ 5297 \ 2291)
return list
matprint r(rrf)
rori, t(30, 401 \ 63, 2807) r(25, 347 \ 45, 2313)
return list
matprint r(rrf)
matprint r(ror)
*/


mata:
  real matrix rrfbs(
    real colvector n_target, 
    real colvector n_response,
    | real scalar reps
  )
  {
    real scalar median, ll, ul
    real colvector p_response, p_target, rvst
    real matrix bsrrf
    
    reps = missing(reps) ? 1000 : reps
    median = round(reps * 0.5)
    ll = round(reps * (0.5 - c("level") * 0.005))
    ul = round(reps * (0.5 + c("level") * 0.005))
    
    p_target = n_target :/ colsum(n_target)
    lnvar_p_target = 1 :/ n_target
    p_response = n_response :/ colsum(n_response)
    lnvar_p_response = 1 :/ n_response
    bsrrf = J(3,3,.)
    for(r=1;r<=3;r++) {
        rsp = rpoisson(reps, 1, n_response[r])
        // rsp < tgt
        rvst = (sort(rsp, 1) :/ colsum(n_response)) :/ 
            (sort(rpoisson(reps, 1, n_target[r]), 1) :/ colsum(n_target))
        bsrrf[r,.] = rvst[(median, ll, ul)]'
    }
    return(bsrrf)
  }
end