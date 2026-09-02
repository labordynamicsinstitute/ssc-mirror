*! test_plssem2.do - 在真实 Stata 18 中测试 plssem2
*! 每个测试块捕获错误并报告，便于定位问题
version 18
set more off
adopath + "E:\plssem2\ado"

capture log close _all
log using "E:\plssem2\do\plssem2_test.log", text replace

display _newline "=================================================="
display "TEST 0: 加载程序并检查版本"
display "=================================================="
which plssem2
which plssem2_estat
which plssem2_predict
which estat_loadings

display _newline "=================================================="
display "TEST 1: 简单反映型模型（boot + bca + blindfold）"
display "=================================================="
import delimited "E:\plssem2\results\esg_simdata.csv", clear
capture noisily {
    plssem2 (ESG > e1 e2 e3) (RA > ra1 ra2 ra3) (HQD > in1 in2 in3), ///
        structural(HQD RA ESG, RA ESG) boot(100) seed(20260819) bca blindfold(7)
}
display "TEST1 rc = " _rc
if _rc == 0 {
    display "TEST1: 估计成功，检查 e() 结果"
    ereturn list
    matrix list e(b), format(%9.4f)
}

display _newline "=================================================="
display "TEST 2: estat 子命令"
display "=================================================="
if _rc == 0 {
    capture noisily estat loadings
    display "estat loadings rc = " _rc
    capture noisily estat weights
    display "estat weights rc = " _rc
    capture noisily estat reliability
    display "estat reliability rc = " _rc
    capture noisily estat htmt
    display "estat htmt rc = " _rc
    capture noisily estat effects, indirect total
    display "estat effects rc = " _rc
    capture noisily estat q2
    display "estat q2 rc = " _rc
    capture noisily estat vif
    display "estat vif rc = " _rc
    capture noisily estat f2
    display "estat f2 rc = " _rc
}

display _newline "=================================================="
display "TEST 3: 形成型（Mode B）块"
display "=================================================="
capture noisily {
    plssem2 (ESGidx < e1 s1 g1) (RA > ra1-ra3) (HQD > in1-in3), ///
        structural(HQD RA ESGidx, RA ESGidx)
}
display "TEST3 rc = " _rc

display _newline "=================================================="
display "TEST 4: 课题全模型（两个高阶构念 + boot + bca + blindfold）"
display "=================================================="
capture noisily {
    plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) ///
            (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4) ///
            (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), ///
        structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG) ///
        higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective") ///
        boot(200) seed(20260819) bca blindfold(7) digits(4)
}
display "TEST4 rc = " _rc
if _rc == 0 {
    display "TEST4: e(b) ="
    matrix list e(b), format(%9.4f)
    display "e(higher) = `e(higher)'"
    display "Q2 (HQD): redundancy = " e(q2_redundancy)[1, 11] "  communality = " e(q2_communality)[1, 11]
    capture noisily estat effects, indirect
    display "estat effects rc = " _rc
}

display _newline "=================================================="
display "TEST 5: predict 潜变量得分"
display "=================================================="
if _rc == 0 {
    capture noisily predict sc_esg sc_hqd, lv(ESG HQD)
    display "predict rc = " _rc
    if _rc == 0 {
        summarize sc_esg sc_hqd
    }
}

display _newline "=================================================="
display "TEST 6: MGA 多组分析（置换检验）"
display "=================================================="
capture noisily {
    plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) ///
            (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4) ///
            (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), ///
        structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG) ///
        higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective") ///
        group(soe, method(permutation) reps(200) seed(20260819)) digits(4)
}
display "TEST6 rc = " _rc
if _rc == 0 {
    capture noisily estat group
    display "estat group rc = " _rc
}

display _newline "=================================================="
display "TEST 7: 重放（replay）"
display "=================================================="
capture noisily plssem2
display "replay rc = " _rc

display _newline "=================================================="
display "ALL TESTS COMPLETED"
display "=================================================="
log close
