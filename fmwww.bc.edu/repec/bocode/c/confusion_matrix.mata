*! Part of package matrixtools v. 0.31
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2023-01-07 Created

* see https://en.wikipedia.org/wiki/Sensitivity_and_specificity
/*
mata mata clear
mata mata set matalnum on
*/
mata:
  struct nx
  {
    string scalar name1, name2  // name1 = rowname, name2 = roweq
    real scalar n, x
  }
  
  struct nx scalar nx_fill(real scalar n, x, |string scalar nm2, nm1)
  {
    struct nx scalar nx
    
    nx.n = n
    nx.x = x
    nx.name2 = nm2
    nx.name1 = nm1
    return(nx)
  }
  
  struct nx rowvector nx2rowvector(struct nx rowvector nx) return(nx)
end
/*
mata: // test struct nx and functions
  nx = nx_fill(10, 5, "rowname", "roweq")
  liststruct(nx)
  eltype(nx), orgtype(nx)
  nxv = nx2rowvector((nx, nx))
  eltype(nxv), orgtype(nxv)
end
exit
*/

mata:
  class confusion_matrix
  {
    real scalar tp, fp
    real scalar fn, tn
    void scalar_fill(), matrix_fill()
    real scalar n_c_p(), n_c_n(), n_p_p(), n_p_n(), n()
    struct nx scalar sensitivity(), specificity(), accuracy(), ppv(), npv(), prevalence() //, roc_area()
    struct nx rowvector get_all_nx()
  }
  
    void confusion_matrix::scalar_fill(real scalar tp, real scalar fp, real scalar fn, real scalar tn)
    /* tp, fp, fn, tn */
    {
      this.tp = tp
      this.fp = fp
      this.fn = fn
      this.tn = tn
    }
  
    void confusion_matrix::matrix_fill(real matrix m)
    /* tn, fp \ fn, tp (input from -tab condition(0/1) predicted(0/1)-, 1=+) */
    {
      this.tp = m[2,2]
      this.fn = m[2,1]
      this.fp = m[1,2]
      this.tn = m[1,1]
    }
  
    real scalar confusion_matrix::n_c_p() return(this.tp + this.fn)  // n condition positive
    real scalar confusion_matrix::n_c_n() return(this.fp + this.tn)  // n condition negative
    real scalar confusion_matrix::n_p_p() return(this.tp + this.fp)  // n predicted condition positive
    real scalar confusion_matrix::n_p_n() return(this.fn + this.tn)  // n predicted condition negative
    real scalar confusion_matrix::n() return(this.n_c_p() + this.n_c_n())  // n total
    
    struct nx scalar confusion_matrix::sensitivity()
    {
      return( nx_fill(this.n_c_p(), this.tp, "P(TP|C+)", "Sensitivity") )
    }
    
    struct nx scalar confusion_matrix::specificity()
    {
      return( nx_fill(this.n_c_n(), this.tn, "P(TN|C-)", "Specificity") )
    }
    
    struct nx scalar confusion_matrix::prevalence()
    {
      return( nx_fill(this.n(), this.tp + this.fn, "P(C+)", "Prevalence") )
    }
    
    struct nx scalar confusion_matrix::accuracy()
    {
      return( nx_fill(this.n(), this.tp + this.tn, "P(TP + TN)", "Accuracy") )
    }

    struct nx scalar confusion_matrix::ppv()
    /* Positive predicted value */
    {
      return( nx_fill(this.n_p_p(), this.tp, "P(TP|P+)", "PPV") )
    }

    struct nx scalar confusion_matrix::npv()
    /* Negative predicted value */
    {
      return( nx_fill(this.n_p_n(), this.tn, "P(TN|P-)", "NPV") )
    }
    
    struct nx rowvector confusion_matrix::get_all_nx()
    {
      return( nx2rowvector( (this.sensitivity(), this.specificity(), 
        this.prevalence(), this.accuracy(), this.ppv(), this.npv()) ) )
    }
end

/*
mata: // test confusion_matrix()
  cmm = confusion_matrix()
  /* tn, fn \ fp, tp (input from -tab condition(0/1) predicted(0/1)-, 1=+) */
  m = 1820, 180 \ 10, 20
  cmm.matrix_fill(m)
  liststruct(cmm.get_all_nx())
  cms = confusion_matrix()
  /* tp, fp, fn, tn */
  cms.scalar_fill(20, 10, 180, 1820)
  liststruct(cms.get_all_nx())
  //cmm == cms
end
exit
*/

mata:    
  class binci
  {
    private:
      real scalar scale, level, showcode, addquietly
      string scalar citype
      class nhb_mt_labelmatrix scalar lm
    public:
      void set(), to_lm()
      class nhb_mt_labelmatrix table()
  }
  
    void binci::set(
      |real scalar scale,
      real scalar level,
      string scalar citype, // exact wald wilson agresti jeffreys
      real scalar showcode,
      real scalar addquietly
      )
    {
      this.scale = scale < . & scale > 0 ? scale : 1
      this.citype = citype == "" ? "exact" : citype
      this.level = level == . ? c("level") : level
      this.showcode = showcode
      this.addquietly = addquietly
    }
  
    void binci::to_lm(struct nx rowvector nx)
    {
      real scalar rc, c, C
      real matrix values
      string scalar statacode, per
      class nhb_mt_labelmatrix row
      
      this.lm.clear()
      C = cols(nx)
      for(c=1;c<=C;c++)
      {
        statacode = sprintf("cii proportions %f %f, level(%f) %s", 
          nx[c].n, nx[c].x, this.level, this.citype)
        rc = nhb_sae_logstatacode(statacode, this.showcode, this.addquietly)
        row = nhb_sae_stored_scalars()
        row = row.regex_select("^N|^p|^.b")
        values = row.values()
        values[2..4] = scale * values[2..4]
        row.values(values)
        row.column_equations(nx[c].name1)
        if (scale == 1 ) per = ""
        else if (scale == 100 ) per = "(%)"
        else per = sprintf(" (/%f)", scale)
        row.row_names(("N", sprintf("p%s", per), sprintf("[%f%% Conf.", level), "interval]")')
        row.column_names(nx[c].name2)
        row = row.transposed()
        this.lm.append(row)
      }
    }
    
    class nhb_mt_labelmatrix binci::table(
      |string scalar coleq, 
      real rowvector decimals, 
      real scalar show
      )
    {
      decimals = decimals == J(1,0,.) ? (0,4) : decimals 
      if ( coleq != "" ) this.lm.column_equations(coleq)
      if ( show != 0 ) this.lm.print("", decimals)
      else return(this.lm)
    }
end    

/* test binci()
mata:
  nx1 = nx_fill(96, 5, "rowname1", "roweq1")
  nx2 = nx_fill(196, 15, "rowname2", "roweq2")
  bci = binci()
  bci.set()
  bci.to_lm((nx1, nx2))
  bci.table()
  bci.set(100)
  bci.to_lm((nx1, nx2))  
  bci.table()
  bci.set(100, 95, "wald", 1, 1)
  bci.to_lm((nx1, nx2))  
  bci.table("Wald CI", (0,2))
  bci.set(100, 90, "wald", 1, 0)
  bci.to_lm((nx1, nx2))  
  bci.table("Wald CI", (0,2))
end
exit
*/

mata:    
  class bincmp
  {
    private:
      real scalar level, showcode, addquietly
      string scalar exact
      class nhb_mt_labelmatrix scalar lm
    public:
      void set(), to_lm()
      class nhb_mt_labelmatrix table()
  }
  
    void bincmp::set(
      |real scalar level,
      string scalar exact,
      real scalar showcode,
      real scalar addquietly
      )
    {
      this.exact = exact != "exact" ? "" : exact
      this.level = level == . ? c("level") : level
      this.showcode = showcode
      this.addquietly = addquietly
    }
  
    void bincmp::to_lm(
      struct nx rowvector nx1, 
      struct nx rowvector nx2,
      |string scalar cmptype  // rr, rd, or ""
      )
    {
      string scalar statacode
      real scalar rc, c, C
      string scalar test
      class nhb_mt_labelmatrix row
      
      C = cols(nx1)
      for(c=1;c<=C;c++) {
        statacode = sprintf("csi %f %f %f %f , %s level(%f)", 
          nx1[c].x, nx2[c].x, nx1[c].n - nx1[c].x, nx2[c].n - nx2[c].x, this.exact, this.level)
        rc = nhb_sae_logstatacode(statacode, this.showcode, this.addquietly)
        test = exact == "" ? "P(Chisquare)" : "P(Fisher exact)"
        if ( cmptype == "rr" | cmptype == "rd" ) {
          row = nhb_sae_stored_scalars(cmptype + "|^p$|^p_exact$")
          row.values(row.values()[(3,2,1,4)])
          row.column_names(sprintf("%s vs %s", nx1[c].name2, nx2[c].name2))
          row.row_names((strupper(cmptype), sprintf("[%f%% Conf.", level), "interval]", test)')
        row = row.transposed()
        }
        else {
          row = nhb_sae_stored_scalars("^p$|^p_exact$")
          row.column_names(test)
        } 
        this.lm.append(row)
      }
    }
    
    class nhb_mt_labelmatrix bincmp::table(|string scalar coleq, real scalar show)
    {
      if ( coleq != "" ) this.lm.column_equations(coleq)
      if ( show != 0 ) this.lm.print("", (2))
      else return(this.lm)
    }
end

/* test bincmp()
mata:
  nx1 = nx_fill(96, 5, "rowname1", "roweq1")
  nx2 = nx_fill(196, 15, "rowname2", "roweq2")
  bcm = bincmp()
  bcm.set(., "", 1, 0)
  bcm.to_lm(nx1, nx2)
  bcm.table()
  bcm = bincmp()
  bcm.set(., "", 1, 0)
  bcm.to_lm(nx1, nx2, "rr")
  bcm.table("test")
  bcm = bincmp()
  bcm.set(., "exact", 0, 1)
  bcm.to_lm(nx1, nx2, "rd")
  bcm.table("test")
end
exit
*/
