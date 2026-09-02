cd "D:/Stata18/ado/personal"
import delimited "esg_simdata.csv", clear
plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) ///
            (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4) ///
            (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), ///
        structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG) ///
        higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective") ///
        boot(200) seed(20260819) bca blindfold(7) digits(4)		
estimates store m1
esttab m1 using myplssem2.rtf, se star(* 0.10 ** 0.05 *** 0.01) ///
	title("PLS-SEM path coefficients") r
esttab m1 using myplssem2.tex, se star(* 0.10 ** 0.05 *** 0.01) ///
	title("PLS-SEM path coefficients") r