*! atip_score.ado v1.0.0  Andres Talavera  INEI/DNCE  21jul2026
program define atip_score, rclass
    version 14
    syntax varname(numeric), GROUP(varlist) ///
        [RULES(string) SDTHRESH3(real 3) SDTHRESH2(real 2) ///
         ZTHRESH(real 2) ZSYMMETRIC MAHALTHRESH(real 8) ///
         GENSCORE(name) GENNREGLAS(name) CLASSIC]
    if "`genscore'"   == "" local genscore   "MAGNITUD_LOCAL"
    if "`gennreglas'" == "" local gennreglas "N_REGLAS"
    atip_reglas `varlist', group(`group') rules(`rules') ///
        sdthresh3(`sdthresh3') sdthresh2(`sdthresh2') zthresh(`zthresh') ///
        `zsymmetric' mahalthresh(`mahalthresh') `classic'
    capture drop `gennreglas'
    egen `gennreglas' = rowtotal(SD_MEAN_3 SD_MEAN_2 ZSCORE IQR MHLBS), missing
    replace `gennreglas' = 0 if missing(`gennreglas')
    label variable `gennreglas' "N de 5 reglas de outlier disparadas"
    capture confirm variable ZSCORE_I
    if _rc {
        di as err "no se pudo calcular ZSCORE_I (revisa rules() -- necesita zscore o mahal activo)"
        exit 198
    }
    capture drop `genscore'
    gen double `genscore' = abs(ZSCORE_I)
    label variable `genscore' "Magnitud local |z| = |(x-media)/DE|"
    quietly count if `gennreglas' >= 3
    di as text "Casos con evidencia fuerte (>=3 de 5 reglas): " as res r(N)
    return scalar n_evidencia_fuerte = r(N)
end
