// Apr  4 2018 22:25:19
// Calculates Elzinga's turbulence measure. Agrees with TraMineR's version.
program turbulence
syntax, STAtevars(string)  LENgthvars(string) NSPells(string) NSTates(real) gen(string)

tempname phi vardur maxvar
ndsub, statevars("`statevars'") nspells(`nspells') nstates(`nstates') gen(`phi')

qui gen `vardur' = .
qui gen `maxvar' = .
mata: vardur("`lengthvars'", "`nspells'", "`maxvar'", "`vardur'")

qui gen `gen' = log(`phi'*(`maxvar'+1)/(`vardur'+1))/log(2)
qui replace `gen' = 1 if `phi'==2

end


mata:
  void function vardur(string durationnames, string nspells, string maxvarv, string vardurv) {
    st_view(durations = .,.,(durationnames))
    st_view(l = .,.,(nspells))
    st_view(maxvar = ., ., (maxvarv))
    st_view(vardur = ., ., (vardurv))
    for (i=1; i<=rows(durations); i++) {
      if (l[i]>1) vardur[i] = variance(transposeonly(durations[i,1..l[i]]))*(l[i]-1)/l[i]
    }
    bart = rowsum(durations[1,.]) :/ l
    maxvar[.] = (l:-1) :* (1 :- bart) :^ 2
  }
end
