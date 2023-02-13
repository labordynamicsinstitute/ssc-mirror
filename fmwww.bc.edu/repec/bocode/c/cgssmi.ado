*! cgssm package v. 0.1
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2023-02-10	Created



* 2002 Brandon - Two Versions of the Contrasting-Groups Standard-Setting Method: A Review
/*
1 /(sqrt(2*pi)*s1)*exp(-0.5*(x-m1)^2 / s1^2) = 1 /(sqrt(2*pi)*s2)*exp(-0.5*(x-m2)^2 / s2^2)

1 /s1*exp(-0.5*(x-m1)^2 / s1^2) = 1 /s2*exp(-0.5*(x-m2)^2 / s2^2)

-log(s1) + -0.5*(x-m1)^2 / s1^2 = -log(s2) + -0.5*(x-m2)^2 / s2^2

0 = log(s1) + 0.5*(x-m1)^2 / s1^2 - log(s2) - 0.5*(x-m2)^2 / s2^2

0 = 2*log(s1/s2) + (x-m1)^2 / s1^2 - (x-m2)^2 / s2^2

0 = 2*log(s1/s2)*s1^2*s2^2 + s2^2*(x-m1)^2 - s1^2*(x-m2)^2

0 = (s2^2 - s1^2)*x^2 - 2*(m1*s2^2-m2*s1^2)*x + 2*log(s1/s2)*s1^2*s2^2 + m1^2*s2^2-m2^2*s1^2


same sigmas:
0 = s^2*(x-m1)^2 - s^2*(x-m2)^2

0 = (2*s^2*(m1-m2))*x - (m1^2-m2^2)*s^2

x = (m1^2-m2^2) / (m1-m2) / 2 = (m1+m2) / 2
*/
capture program drop cgssmi
program define cgssmi, rclass

  version 12
  
  syntax , MSDrowmatrix(string) /*
    */[ /*
      */Refname(string) /*
      */Compname(string) /*
      */Header(string) /*
      */CPFormat(string) /*
      */PFormat(string) /*
      */Graph /*
      */ * /*
    */]

  _get_gropts , graphopts(`options') gettwoway

  if "`cpformat'" != "" {
    capture confirm format `cpformat'
    if _rc mata: _error("Format for Cut-point is not a format")
  }
  else local cpformat %6.0f
  if "`pformat'" != "" {
    capture confirm format `pformat'
    if _rc mata: _error("Format for p-values is not a format")
  }
  else local pformat %5.1f
  
  capture matrix _msd = `msdrowmatrix' //First row is for references/experts
  if !_rc {
    local m1 = `=_msd[1,1]'
    local sd1 = `=_msd[1,2]'
    local m2 = `=_msd[2,1]' 
    local sd2 = `=_msd[2,2]'
  }
  else mata _error("Option msdrowmatrix is not a matrix")
  
  local lb = min(`m1'-3*`sd1', `m2'-3*`sd2')
  local ub = max(`m1'+3*`sd1', `m2'+3*`sd2')    
  
  if "`refname'" == "" local refname "Row 1 (ref.)"
  if "`compname'" == "" local compname "Row 2 (comp.)"
  if "`header'" != "" local header `"- "`header'""'

  *mata: ncut(`m1', `sd1', `m2', `sd2')
  mata: st_local("ncut", strofreal(ncut(`m1', `sd1', `m2', `sd2')))
  if "`ncut'" != "." {
    scalar fn = normal(`=(`ncut' - `m1') / `sd1'')
    scalar fp = 1 - normal(`=(`ncut' - `m2') / `sd2'')
    if `m1' < `m2' {
      scalar fp = normal(`=(`ncut' - `m2') / `sd2'')
      scalar fn = 1 - normal(`=(`ncut' - `m1') / `sd1'')
    }
    local xline xline(`ncut')
    local pfcut `""Pass-Fail cut-off = `=string(`ncut', "`cpformat'")'""'
    local fp `""Theoretical false positive = `=string(100*fp, "`pformat'")'%""'
    local fn `""Theoretical false negative  = `=string(100*fn, "`pformat'")'%""'
  }
  else {
      scalar fp = .
      scalar fn = .    
  }

  if "`graph'`options'" != "" | "`graph'" != "" {
    local gr_txt twoway (function y=normalden(x,`m1',`sd1'), range(`lb' `ub')) ///
      (function y=normalden(x,`m2',`sd2'), range(`lb' `ub')), `xline' ///
      subtitle(`pfcut' `fp' `fn', ring(0) position(11) size(small)) ///
      legend(order(`header' 1 "`refname'" 2 "`compname'")) ///
      yscale(off) `s(twowayopts)'
    `gr_txt'
    return local graph_text = `"`gr_txt'"'
  }
  return matrix meansd = _msd
  return scalar cutoff = `ncut'
  return scalar fn = fn
  return scalar fp = fp
end
  
capture mata mata drop ncut()
mata:
  function ncut(m1, sd1, m2, sd2){
    real scalar a, b, c, d
    
    if ( min((sd1, sd2)) <= 0 ) _error("SDs must be positive")
    if ( sd1 == sd2 ) return((m1 + m2) / 2)
    else {
      a = sd2 == sd1 ? 0.000001 : sd2^2 - sd1^2
      b = -2 * (m1 * sd2^2 - m2 * sd1^2)
      c = 2 * log(sd1/sd2) * sd1^2 * sd2^2 + m1^2 * sd2^2 - m2^2 * sd1^2
      d = b^2 - 4 * a * c
      if ( d < 0 ) _error("No solution")
      if (m1 < m2) return((-b + sqrt(d)) / 2 / a)
      else return((-b - sqrt(d)) / 2 / a)
    }
  }
end
