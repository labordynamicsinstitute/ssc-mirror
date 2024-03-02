*! Part of package matrixtools v. 0.31
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2023-02-04 Bug wrt include fixed
* 2023-01-07 Created
* TODO save count table
* TODO reverse order on count table
/*
cls
capture program drop confmat
mata mata clear
mata mata set matalnum on
*/
program define confmat, rclass
  syntax varlist(min=2 max=2) [if] [in] /* (input from -tab condition(0/1) predicted(0/1)-, 1=+) 
    */[,  /*
      */by(varlist min=1 max=1 numeric) /*
      */SCale(integer 100) /*
      */LEvel(cilevel) /*
      */CItype(string) /*
      */LAbels /*
      */NoQuietly /*
      */coleq(string) /*
      */CMPtype(string) /*
      */Exact /*
    */]
  tokenize `"`varlist'"'
  mata: conf_mat_is_binary("`1'")
  mata: conf_mat_is_binary("`2'")
  if !inlist(`"`citype'"', "", "exact", "wald", "wilson", "agresti", "jeffreys") ///
    mata _error(`"Option citype must be one of "", exact, wald, wilson, agresti or jeffreys. See: -help cii proportions-"')
  if !inlist(`"`cmptype'"', "", "rr", "rd") ///
    mata _error(`"Option citype must be one of "", rr or rd. See: -help csi-"')
   if `"`quietly'"' != "" mata _showcode = 1; _addquietly = 0
  else mata _showcode = 0; _addquietly = 1
  if "`by'" != "" {
    mata: conf_mat_is_binary("`by'")
  	mata: _by_1 = nhb_sae_unique_values("`by'", "", "", 1)[1]
    mata: _by_2 = nhb_sae_unique_values("`by'", "", "", 1)[2]
    mata: _if = "`if'" != "" ? "`if' &" : "if"
    mata st_local("if1", sprintf(" %s %s == %f", _if, "`by'", _by_1))
    mata st_local("if2", sprintf(" %s %s == %f", _if, "`by'", _by_2))
    if "`labels'" != "" {
      mata: _vn = (_vn = st_varlabel("`by'")) == "" ? "`by'" : _vn
      mata: _str_by_1 = nhb_sae_labelsof("`by'", _by_1)
      mata: _str_by_2 = nhb_sae_labelsof("`by'", _by_2)
    }
    else {
      mata: _vn = "`by'"
      mata: _str_by_1 = strofreal(_by_1)
      mata: _str_by_2 = strofreal(_by_2)
    }
    mata: st_local("lbl1", sprintf("%s(%s)", _vn, _str_by_1))
    mata: st_local("lbl2", sprintf("%s(%s)", _vn, _str_by_2))
    mata: st_local("lbl12", sprintf("%s(%s vs %s)", _vn, _str_by_1, _str_by_2))
    crossmat `1' `2' `if1' `in'
    matrix _m1 = r(counts)
    crossmat `1' `2' `if2' `in'
    matrix _m2 = r(counts)
    mata: _lm = conf_mat_to_tbl(st_matrix("_m1"), `scale', `level', "`citype'", ///
      _showcode, _addquietly, `"`lbl1'"', st_matrix("_m2"), `"`lbl2'"', `"`lbl12'"', ///
      "`cmptype'", "`exact'")
  } 
  else {
    crossmat `1' `2' `if' `in'
    matrix _m1 = r(counts)
    matprint r(counts), d(0)
    mata: _lm = conf_mat_to_tbl(st_matrix("_m1"), `scale', `level', "`citype'", ///
      _showcode, _addquietly, `"`coleq'"')
  }
  mata: st_rclear()
  mata: _lm.to_matrix("r(confmat)")
  matprint r(confmat), d((0, 2, 2, 2, 0, 2))
  return add
  *mata mata drop _* _*()
end

mata st_local( "__confusion_matrix_mata", findfile("confusion_matrix.mata"))
include `"`__confusion_matrix_mata'"'

mata:
	void conf_mat_is_binary(string scalar varname) 
	{
		if ( regexm(varname, ".+\.(.+)") ) varname = regexs(1)
		if ( cols(nhb_sae_unique_values(varname, "", "", 1)) != 2 ) {
			_error(sprintf("Variable %s must be binary", varname))
		}
	}

  class nhb_mt_labelmatrix scalar conf_mat_to_tbl(
    real matrix m1, 
    real scalar scale,
    |real scalar level,
    string scalar citype,
    real scalar showcode,
    real scalar addquietly,
    string scalar lbl1, 
    real matrix m2, 
    string scalar lbl2,
    string scalar lbl12,
    string scalar cmptype,
    string scalar exact
    )
  {
    class nhb_mt_labelmatrix scalar tbl
    class binci scalar bci
    class bincmp scalar bcmp
    class confusion_matrix scalar cm1, cm2
   
    cm1.matrix_fill(m1)
    bci.set(scale, level, citype, showcode, addquietly)
    bci.to_lm(cm1.get_all_nx())
    tbl.add_sideways(bci.table(lbl1, 0, 0))
    if ( m2 != J(0,0,.) ) {
      cm2.matrix_fill(m2)
      bci.set(scale, level, citype, showcode, addquietly)
      bci.to_lm(cm2.get_all_nx())
      tbl.add_sideways(bci.table(lbl2, 0, 0))
      bcmp.set(level, exact, showcode, addquietly)
      bcmp.to_lm(cm1.get_all_nx(), cm2.get_all_nx(), cmptype)
      tbl.add_sideways(bcmp.table(lbl12, 0))
    }
    return(tbl)
  }  
end

/* testconfmat
cls
clear
input actual test n
0 0 1820
0 1 180
1 0 10
1 1 20
end
expand n

diagt actual test
confmat actual test
return list
matprint r(confmat), decimals((0,2))

clear
input actual test n grp
0 0 1820 1
0 1 180 1
1 0 10 1
1 1 20 1
0 0 1620 2
0 1 150 2
1 0 18 2
1 1 40 2
end
expand n

confmat actual test if grp == 1

confmat actual test, by(grp) cmp("rr")
macro dir
mata mata describe

label variable grp "Group"
label define grp 1 "Poor" 2 "Rich"
label values grp grp
confmat actual test, by(grp) label
*/