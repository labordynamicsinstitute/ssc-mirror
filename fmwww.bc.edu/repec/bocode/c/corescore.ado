capture program drop corescore

program define corescore, byable(recall)
    * set trace on

    display "Start of program execution..."

    version 16.1

    syntax [varlist] [if] [in], [idvar(varname) diagprfx(string) noshow]

    marksample touse, novarlist
    keep if `touse'
    
    display "Comorbid Operative Risk Evaluation (CORE) Score Macro"

    if "`show'" != "noshow" { 
        display "OPTIONS SELECTED: "
        if "`idvar'" != "" {
            display "OBSERVATIONAL UNIT: Patients"
        }
        else {
            display "OBSERVATIONAL UNIT: Visits"
        }
        display "ID VARIABLE NAME (Given only if Unit is Patients): `idvar'"
    }
	display "PREFIX of COMORBIDITY VARIABLES:  `diagprfx'" 

    set more off
    capture drop corecomp1-corecomp69
    capture drop COREscore

    display "Please wait. Thank you!"

    forvalues i=1/69 {
        gen comp`i'=0
    }

  if "`diagprfx'" != "" {
  	unab varlist: `diagprfx'*
  	}
	
    local n : word count `varlist'
    display "Program takes a few minutes - there are up to `n' ICD-10 codes per subject."
	
local ord = 1
while `ord' <= `n' {
	local tempcode: word `ord' of `varlist'
	display "	Iteration `ord' of `n' - Program is running - Please wait"
	display "		Coding BLD CCSR"

*BLD CCSR
	*BLD001 - Nutritional Anemia
	quietly replace comp1 = 1 if ///
		inlist(`tempcode', "D500", "D501", "D508", "D509", "D510", "D511", "D512", "D513") | ///
		inlist(`tempcode', "D518", "D519", "D520", "D528", "D529", "D530", "D531", "D538") | ///
		inlist(`tempcode', "D539")
	quietly replace comp1 = 1 if ///
		inlist(`tempcode', "D50.0", "D50.1", "D50.8", "D50.9", "D51.0", "D51.1", "D51.2", "D51.3") | ///
		inlist(`tempcode', "D51.8", "D51.9", "D52.0", "D52.8", "D52.9", "D53.0", "D53.1", "D53.8") | ///
		inlist(`tempcode', "D53.9")

	*BLD007 - Diseases of white blood cells
	quietly replace comp2 = 1 if ///
		inlist(`tempcode', "D71") | ///
		inlist(`tempcode', "D700", "D703", "D704", "D708", "D709", "D720", "D721", "D729") | ///
		inlist(`tempcode', "D761", "D763") | ///
		inlist(`tempcode', "D7289", "D7381") | ///
		inlist(`tempcode', "D72810", "D72818", "D72819", "D72820", "D72821", "D72822", "D72823", "D72825") | ///
		inlist(`tempcode', "D72828", "D72829")
	quietly replace comp2 = 1 if ///
		inlist(`tempcode', "D71") | ///
		inlist(`tempcode', "D70.0", "D70.3", "D70.4", "D70.8", "D70.9", "D72.0", "D72.1", "D72.9") | ///
		inlist(`tempcode', "D76.1", "D76.3") | ///
		inlist(`tempcode', "D72.89", "D73.81") | ///
		inlist(`tempcode', "D72.810", "D72.818", "D72.819", "D72.820", "D72.821", "D72.822", "D72.823", "D72.825") | ///
		inlist(`tempcode', "D72.828", "D72.829")
	
*CIR CCSR	
	display "		Coding CIR CCSR"
	*CIR003 - Nonrheumatic and unspecified valve disorders
	quietly replace comp3 = 1 if ///
		inlist(`tempcode', "I340", "I341", "I342", "I348", "I349", "I350", "I351", "I352") | ///
		inlist(`tempcode', "I358", "I359", "I360", "I361", "I362", "I368", "I369", "I370") | ///
		inlist(`tempcode', "I371", "I372", "I378", "I379")
	quietly replace comp3 = 1 if ///
		inlist(`tempcode', "I34.0", "I34.1", "I34.2", "I34.8", "I34.9", "I35.0", "I35.1", "I35.2") | ///
		inlist(`tempcode', "I35.8", "I35.9", "I36.0", "I36.1", "I36.2", "I36.8", "I36.9", "I37.0") | ///
		inlist(`tempcode', "I37.1", "I37.2", "I37.8", "I37.9")
	
	*CIR007 - Essential hypertension
	quietly replace comp4 = 1 if `tempcode' == "I10"

	*CIR008 - Hypertension with complications and secondary hypertension
	quietly replace comp5 = 1 if ///
		inlist(`tempcode', "I119", "I150", "I151", "I152", "I158", "I159", "I160", "I161") | ///
		inlist(`tempcode', "I169", "I674")
	quietly replace comp5 = 1 if ///
		inlist(`tempcode', "I11.9", "I15.0", "I15.1", "I15.2", "I15.8", "I15.9", "I16.0", "I16.1") | ///
		inlist(`tempcode', "I16.9", "I67.4")

	*CIR011 - Coronary atherosclerosis and other heart disease
	quietly replace comp6 = 1 if ///
		inlist(`tempcode', "I200", "I201", "I208", "I209", "I252", "I255", "I256", "I259") | ///
		inlist(`tempcode', "I2510", "I2589") | ///
		inlist(`tempcode', "I25110", "I25111", "I25118", "I25119", "I25700", "I25708", "I25709", "I25710") | ///
		inlist(`tempcode', "I25718", "I25719", "I25720", "I25721", "I25728", "I25729", "I25739", "I25750") | ///
		inlist(`tempcode', "I25758", "I25759", "I25769", "I25790", "I25799", "I25810", "I25811", "I25812")
	quietly replace comp6 = 1 if ///
		inlist(`tempcode', "I20.0", "I20.1", "I20.8", "I20.9", "I25.2", "I25.5", "I25.6", "I25.9") | ///
		inlist(`tempcode', "I25.10", "I25.89") | ///
		inlist(`tempcode', "I25.110", "I25.111", "I25.118", "I25.119", "I25.700", "I25.708", "I25.709", "I25.710") | ///
		inlist(`tempcode', "I25.718", "I25.719", "I25.720", "I25.721", "I25.728", "I25.729", "I25.739", "I25.750") | ///
		inlist(`tempcode', "I25.758", "I25.759", "I25.769", "I25.790", "I25.799", "I25.810", "I25.811", "I25.812")
	
	*CIR019 - Heart failure
	quietly replace comp7 = 1 if ///
		inlist(`tempcode', "I110", "I130", "I501", "I509") | ///
		inlist(`tempcode', "I0981", "I5020", "I5022", "I5023", "I5030", "I5032", "I5033", "I5040") | ///
		inlist(`tempcode', "I5042", "I5043", "I5082", "I5083", "I5084", "I5089") | ///
		inlist(`tempcode', "I50810", "I50812", "I50813", "I50814")
	quietly replace comp7 = 1 if ///
		inlist(`tempcode', "I11.0", "I13.0", "I50.1", "I50.9") | ///
		inlist(`tempcode', "I09.81", "I50.20", "I50.22", "I50.23", "I50.30", "I50.32", "I50.33", "I50.40") | ///
		inlist(`tempcode', "I50.42", "I50.43", "I50.82", "I50.83", "I50.84", "I50.89") | ///
		inlist(`tempcode', "I50.810", "I50.812", "I50.813", "I50.814")

	*CIR020 - Cerebral infarction
	quietly replace comp8 = 1 if ///
		inlist(`tempcode', "I636", "I639") | ///
		inlist(`tempcode', "I6302", "I6309", "I6310", "I6312", "I6319", "I6320", "I6322", "I6329") | ///
		inlist(`tempcode', "I6330", "I6339", "I6340", "I6349", "I6350", "I6359", "I6381", "I6389") | ///
		inlist(`tempcode', "I63011", "I63012", "I63013", "I63019", "I63031", "I63032", "I63033", "I63111") | ///
		inlist(`tempcode', "I63112", "I63113", "I63119", "I63131", "I63132", "I63133", "I63139", "I63211") | ///
		inlist(`tempcode', "I63212", "I63213", "I63219", "I63231", "I63232", "I63233", "I63239", "I63311") | ///
		inlist(`tempcode', "I63312", "I63313", "I63319", "I63321", "I63322", "I63323", "I63331", "I63332") | ///
		inlist(`tempcode', "I63341", "I63342", "I63343", "I63349", "I63411", "I63412", "I63413", "I63419") | ///
		inlist(`tempcode', "I63421", "I63422", "I63423", "I63429", "I63431", "I63432", "I63433", "I63439") | ///
		inlist(`tempcode', "I63441", "I63442", "I63443", "I63449", "I63511", "I63512", "I63513", "I63519") | ///
		inlist(`tempcode', "I63521", "I63522", "I63523", "I63529", "I63531", "I63532", "I63533", "I63539") | ///
		inlist(`tempcode', "I63541", "I63542", "I63543", "I63549")
	quietly replace comp8 = 1 if ///
		inlist(`tempcode', "I63.6", "I63.9") | ///
		inlist(`tempcode', "I63.02", "I63.09", "I63.10", "I63.12", "I63.19", "I63.20", "I63.22", "I63.29") | ///
		inlist(`tempcode', "I63.30", "I63.39", "I63.40", "I63.49", "I63.50", "I63.59", "I63.81", "I63.89") | ///
		inlist(`tempcode', "I63.011", "I63.012", "I63.013", "I63.019", "I63.031", "I63.032", "I63.033", "I63.111") | ///
		inlist(`tempcode', "I63.112", "I63.113", "I63.119", "I63.131", "I63.132", "I63.133", "I63.139", "I63.211") | ///
		inlist(`tempcode', "I63.212", "I63.213", "I63.219", "I63.231", "I63.232", "I63.233", "I63.239", "I63.311") | ///
		inlist(`tempcode', "I63.312", "I63.313", "I63.319", "I63.321", "I63.322", "I63.323", "I63.331", "I63.332") | ///
		inlist(`tempcode', "I63.341", "I63.342", "I63.343", "I63.349", "I63.411", "I63.412", "I63.413", "I63.419") | ///
		inlist(`tempcode', "I63.421", "I63.422", "I63.423", "I63.429", "I63.431", "I63.432", "I63.433", "I63.439") | ///
		inlist(`tempcode', "I63.441", "I63.442", "I63.443", "I63.449", "I63.511", "I63.512", "I63.513", "I63.519") | ///
		inlist(`tempcode', "I63.521", "I63.522", "I63.523", "I63.529", "I63.531", "I63.532", "I63.533", "I63.539") | ///
		inlist(`tempcode', "I63.541", "I63.542", "I63.543", "I63.549")

	*CIR023 - Occlusion or stenosis of precerebral or cerebral arteries without infarction
	quietly replace comp9 = 1 if ///
		inlist(`tempcode', "I651", "I658", "I659", "I663", "I668", "I669") | ///
		inlist(`tempcode', "I6501", "I6502", "I6503", "I6509", "I6521", "I6522", "I6523", "I6529") | ///
		inlist(`tempcode', "I6601", "I6602", "I6603", "I6609", "I6611", "I6612", "I6613", "I6619") | ///
		inlist(`tempcode', "I6621", "I6622", "I6623")
	quietly replace comp9 = 1 if ///
		inlist(`tempcode', "I65.1", "I65.8", "I65.9", "I66.3", "I66.8", "I66.9") | ///
		inlist(`tempcode', "I65.01", "I65.02", "I65.03", "I65.09", "I65.21", "I65.22", "I65.23", "I65.29") | ///
		inlist(`tempcode', "I66.01", "I66.02", "I66.03", "I66.09", "I66.11", "I66.12", "I66.13", "I66.19") | ///
		inlist(`tempcode', "I66.21", "I66.22", "I66.23")
	
	*CIR026 - Peripheral and visceral vascular disease
	quietly replace comp10 = 1 if ///
		inlist(`tempcode', "I700", "I701", "I708", "I731", "I739") | ///
		inlist(`tempcode', "I7025", "I7035", "I7045", "I7090", "I7091", "I7300", "I7301", "I7381") | ///
		inlist(`tempcode', "I7389") | ///
		inlist(`tempcode', "I70201", "I70202", "I70203", "I70208", "I70209", "I70211", "I70212", "I70213") | ///
		inlist(`tempcode', "I70218", "I70219", "I70221", "I70222", "I70223", "I70228", "I70229", "I70231") | ///
		inlist(`tempcode', "I70232", "I70233", "I70234", "I70235", "I70238", "I70239", "I70241", "I70242") | ///
		inlist(`tempcode', "I70243", "I70244", "I70245", "I70248", "I70249", "I70261", "I70262", "I70263") | ///
		inlist(`tempcode', "I70268", "I70269", "I70291", "I70292", "I70293", "I70298", "I70299", "I70301") | ///
		inlist(`tempcode', "I70302", "I70303", "I70308", "I70309", "I70311", "I70312", "I70313", "I70318") | ///
		inlist(`tempcode', "I70321", "I70322", "I70323", "I70332", "I70333", "I70334", "I70335", "I70338") | ///
		inlist(`tempcode', "I70339", "I70342", "I70343", "I70344", "I70345", "I70348", "I70349", "I70361") | ///
		inlist(`tempcode', "I70362", "I70363", "I70391", "I70392", "I70393", "I70401", "I70402", "I70403") | ///
		inlist(`tempcode', "I70409", "I70411", "I70412", "I70413", "I70419", "I70421", "I70422", "I70423") | ///
		inlist(`tempcode', "I70432", "I70433", "I70434", "I70435", "I70438", "I70439", "I70441", "I70442") | ///
		inlist(`tempcode', "I70443", "I70444", "I70445", "I70448", "I70449", "I70461", "I70462", "I70463") | ///
		inlist(`tempcode', "I70468", "I70491", "I70492", "I70493", "I70501", "I70502", "I70511", "I70512") | ///
		inlist(`tempcode', "I70521", "I70522", "I70523", "I70538", "I70543", "I70544", "I70545", "I70548") | ///
		inlist(`tempcode', "I70561", "I70562", "I70592", "I70601", "I70602", "I70603", "I70611", "I70612") | ///
		inlist(`tempcode', "I70613", "I70621", "I70622", "I70623", "I70634", "I70635", "I70638", "I70642") | ///
		inlist(`tempcode', "I70645", "I70648", "I70661", "I70662", "I70691", "I70692", "I70701", "I70702") | ///
		inlist(`tempcode', "I70708", "I70711", "I70712", "I70713", "I70718", "I70721", "I70722", "I70723") | ///
		inlist(`tempcode', "I70735", "I70738", "I70741", "I70744", "I70745", "I70748", "I70761", "I70762") | ///
		inlist(`tempcode', "I70791", "I70792", "I70793", "I70798")
	quietly replace comp10 = 1 if ///
		inlist(`tempcode', "I70.0", "I70.1", "I70.8", "I73.1", "I73.9") | ///
		inlist(`tempcode', "I70.25", "I70.35", "I70.45", "I70.90", "I70.91", "I73.00", "I73.01", "I73.81") | ///
		inlist(`tempcode', "I73.89") | ///
		inlist(`tempcode', "I70.201", "I70.202", "I70.203", "I70.208", "I70.209", "I70.211", "I70.212", "I70.213") | ///
		inlist(`tempcode', "I70.218", "I70.219", "I70.221", "I70.222", "I70.223", "I70.228", "I70.229", "I70.231") | ///
		inlist(`tempcode', "I70.232", "I70.233", "I70.234", "I70.235", "I70.238", "I70.239", "I70.241", "I70.242") | ///
		inlist(`tempcode', "I70.243", "I70.244", "I70.245", "I70.248", "I70.249", "I70.261", "I70.262", "I70.263") | ///
		inlist(`tempcode', "I70.268", "I70.269", "I70.291", "I70.292", "I70.293", "I70.298", "I70.299", "I70.301") | ///
		inlist(`tempcode', "I70.302", "I70.303", "I70.308", "I70.309", "I70.311", "I70.312", "I70.313", "I70.318") | ///
		inlist(`tempcode', "I70.321", "I70.322", "I70.323", "I70.332", "I70.333", "I70.334", "I70.335", "I70.338") | ///
		inlist(`tempcode', "I70.339", "I70.342", "I70.343", "I70.344", "I70.345", "I70.348", "I70.349", "I70.361") | ///
		inlist(`tempcode', "I70.362", "I70.363", "I70.391", "I70.392", "I70.393", "I70.401", "I70.402", "I70.403") | ///
		inlist(`tempcode', "I70.409", "I70.411", "I70.412", "I70.413", "I70.419", "I70.421", "I70.422", "I70.423") | ///
		inlist(`tempcode', "I70.432", "I70.433", "I70.434", "I70.435", "I70.438", "I70.439", "I70.441", "I70.442") | ///
		inlist(`tempcode', "I70.443", "I70.444", "I70.445", "I70.448", "I70.449", "I70.461", "I70.462", "I70.463") | ///
		inlist(`tempcode', "I70.468", "I70.491", "I70.492", "I70.493", "I70.501", "I70.502", "I70.511", "I70.512") | ///
		inlist(`tempcode', "I70.521", "I70.522", "I70.523", "I70.538", "I70.543", "I70.544", "I70.545", "I70.548") | ///
		inlist(`tempcode', "I70.561", "I70.562", "I70.592", "I70.601", "I70.602", "I70.603", "I70.611", "I70.612") | ///
		inlist(`tempcode', "I70.613", "I70.621", "I70.622", "I70.623", "I70.634", "I70.635", "I70.638", "I70.642") | ///
		inlist(`tempcode', "I70.645", "I70.648", "I70.661", "I70.662", "I70.691", "I70.692", "I70.701", "I70.702") | ///
		inlist(`tempcode', "I70.708", "I70.711", "I70.712", "I70.713", "I70.718", "I70.721", "I70.722", "I70.723") | ///
		inlist(`tempcode', "I70.735", "I70.738", "I70.741", "I70.744", "I70.745", "I70.748", "I70.761", "I70.762") | ///
		inlist(`tempcode', "I70.791", "I70.792", "I70.793", "I70.798")

	*CIR027 - Arterial dissections
	quietly replace comp11 = 1 if ///
		inlist(`tempcode', "I2542", "I7100", "I7101", "I7102", "I7103", "I7770", "I7771", "I7772") | ///
		inlist(`tempcode', "I7773", "I7774", "I7775", "I7776", "I7777", "I7779")
	quietly replace comp11 = 1 if ///
		inlist(`tempcode', "I25.42", "I71.00", "I71.01", "I71.02", "I71.03", "I77.70", "I77.71", "I77.72") | ///
		inlist(`tempcode', "I77.73", "I77.74", "I77.75", "I77.76", "I77.77", "I77.79")

	*CIR028 - Gangrene
	quietly replace comp12 = 1 if inlist(`tempcode', "I96", "J850", "J85.0")

	*CIR030 - Aortic and peripheral arterial embolism or thrombosis
	quietly replace comp13 = 1 if ///
		inlist(`tempcode', "I742", "I743", "I744", "I745", "I748", "I749") | ///
		inlist(`tempcode', "I7401", "I7409", "I7410", "I7411", "I7419", "I7581", "I7589") | ///
		inlist(`tempcode', "I75021", "I75022", "I75023", "I75029")
	quietly replace comp13 = 1 if ///
		inlist(`tempcode', "I74.2", "I74.3", "I74.4", "I74.5", "I74.8", "I74.9") | ///
		inlist(`tempcode', "I74.01", "I74.09", "I74.10", "I74.11", "I74.19", "I75.81", "I75.89") | ///
		inlist(`tempcode', "I75.021", "I75.022", "I75.023", "I75.029")
			
	*CIR032 - Other specified and unspecified circulatory disease
	quietly replace comp14 = 1 if ///
		inlist(`tempcode', "I770", "I771", "I772", "I773", "I774", "I775", "I776", "I779") | ///
		inlist(`tempcode', "I780", "I781", "I788", "I998", "I999") | ///
		inlist(`tempcode', "I7789") | ///
		inlist(`tempcode', "I77810", "I77811", "I77812", "I77819")
	quietly replace comp14 = 1 if ///
		inlist(`tempcode', "I77.0", "I77.1", "I77.2", "I77.3", "I77.4", "I77.5", "I77.6", "I77.9") | ///
		inlist(`tempcode', "I78.0", "I78.1", "I78.8", "I99.8", "I99.9") | ///
		inlist(`tempcode', "I77.89") | ///
		inlist(`tempcode', "I77.810", "I77.811", "I77.812", "I77.819")
	
*DIG CCSR
	display "		Coding DIG CCSR"
	*DIG004 - Esophageal disorders
	quietly replace comp15 = 1 if ///
		inlist(`tempcode', "K200", "K208", "K209", "K210", "K219", "K220", "K222", "K224") | ///
		inlist(`tempcode', "K225", "K226", "K228", "K229") | ///
		inlist(`tempcode', "B3781", "K2210", "K2211", "K2270") | ///
		inlist(`tempcode', "K22710", "K22711", "K22719")
	quietly replace comp15 = 1 if ///
		inlist(`tempcode', "K20.0", "K20.8", "K20.9", "K21.0", "K21.9", "K22.0", "K22.2", "K22.4") | ///
		inlist(`tempcode', "K22.5", "K22.6", "K22.8", "K22.9") | ///
		inlist(`tempcode', "B37.81", "K22.10", "K22.11", "K22.70") | ///
		inlist(`tempcode', "K22.710", "K22.711", "K22.719")

	*DIG006 - Gastrointestinal and biliary perforation
	quietly replace comp16 = 1 if ///
		inlist(`tempcode', "K223", "K631", "K822", "K832")
	quietly replace comp16 = 1 if ///
		inlist(`tempcode', "K22.3", "K63.1", "K82.2", "K83.2")
	
	*DIG007 - Gastritis and duodenitis
	quietly replace comp17 = 1 if ///
		inlist(`tempcode', "K2920", "K2921", "K2930", "K2931", "K2940", "K2941", "K2950", "K2951") | ///
		inlist(`tempcode', "K2960", "K2961", "K2970", "K2971", "K2980", "K2981", "K2990", "K2991")
	quietly replace comp17 = 1 if ///
		inlist(`tempcode', "K29.20", "K29.21", "K29.30", "K29.31", "K29.40", "K29.41", "K29.50", "K29.51") | ///
		inlist(`tempcode', "K29.60", "K29.61", "K29.70", "K29.71", "K29.80", "K29.81", "K29.90", "K29.91")
	
	*DIG009 - Appendicitis and other appendiceal conditions
	quietly replace comp18 = 1 if ///
		inlist(`tempcode', "K36", "K37") | ///
		inlist(`tempcode', "K380", "K381", "K382", "K383", "K388", "K389")
	quietly replace comp18 = 1 if ///
		inlist(`tempcode', "K36", "K37") | ///
		inlist(`tempcode', "K38.0", "K38.1", "K38.2", "K38.3", "K38.8", "K38.9")

	*DIG010 - Abdominal hernia
	quietly replace comp19 = 1 if ///
		inlist(`tempcode', "K420", "K421", "K429", "K430", "K431", "K432", "K433", "K434") | ///
		inlist(`tempcode', "K435", "K436", "K437", "K439", "K440", "K441", "K449", "K450") | ///
		inlist(`tempcode', "K451", "K458", "K460", "K461", "K469") | ///
		inlist(`tempcode', "K4000", "K4001", "K4020", "K4021", "K4030", "K4031", "K4040", "K4090") | ///
		inlist(`tempcode', "K4091", "K4120", "K4130", "K4131", "K4140", "K4190", "K4191")
	quietly replace comp19 = 1 if ///
		inlist(`tempcode', "K42.0", "K42.1", "K42.9", "K43.0", "K43.1", "K43.2", "K43.3", "K43.4") | ///
		inlist(`tempcode', "K43.5", "K43.6", "K43.7", "K43.9", "K44.0", "K44.1", "K44.9", "K45.0") | ///
		inlist(`tempcode', "K45.1", "K45.8", "K46.0", "K46.1", "K46.9") | ///
		inlist(`tempcode', "K40.00", "K40.01", "K40.20", "K40.21", "K40.30", "K40.31", "K40.40", "K40.90") | ///
		inlist(`tempcode', "K40.91", "K41.20", "K41.30", "K41.31", "K41.40", "K41.90", "K41.91")
	
	*DIG012 - Intestinal obstruction and ileus
	quietly replace comp20 = 1 if ///
		inlist(`tempcode', "K315", "K560", "K561", "K562", "K563", "K567") | ///
		inlist(`tempcode', "K5641", "K5649", "K5650", "K5651", "K5652") | ///
		inlist(`tempcode', "K56600", "K56601", "K56609", "K56690", "K56691", "K56699")
	quietly replace comp20 = 1 if ///
		inlist(`tempcode', "K31.5", "K56.0", "K56.1", "K56.2", "K56.3", "K56.7") | ///
		inlist(`tempcode', "K56.41", "K56.49", "K56.50", "K56.51", "K56.52") | ///
		inlist(`tempcode', "K56.600", "K56.601", "K56.609", "K56.690", "K56.691", "K56.699")
		
	*DIG013 - Diverticulosis and diverticulitis
	quietly replace comp21 = 1 if ///
		inlist(`tempcode', "K5700", "K5701", "K5710", "K5711", "K5712", "K5713", "K5720", "K5721") | ///
		inlist(`tempcode', "K5730", "K5731", "K5732", "K5733", "K5740", "K5741", "K5750", "K5751") | ///
		inlist(`tempcode', "K5752", "K5753", "K5780", "K5781", "K5790", "K5791", "K5792", "K5793")
	quietly replace comp21 = 1 if ///
		inlist(`tempcode', "K57.00", "K57.01", "K57.10", "K57.11", "K57.12", "K57.13", "K57.20", "K57.21") | ///
		inlist(`tempcode', "K57.30", "K57.31", "K57.32", "K57.33", "K57.40", "K57.41", "K57.50", "K57.51") | ///
		inlist(`tempcode', "K57.52", "K57.53", "K57.80", "K57.81", "K57.90", "K57.91", "K57.92", "K57.93")

	*DIG014 - Hemorrhoids
	quietly replace comp22 = 1 if ///
		inlist(`tempcode', "K640", "K641", "K642", "K643", "K644", "K645", "K648", "K649")
	quietly replace comp22 = 1 if ///
		inlist(`tempcode', "K64.0", "K64.1", "K64.2", "K64.3", "K64.4", "K64.5", "K64.8", "K64.9")

	*DIG016 - Peritonitis and intra-abdominal abscess
	quietly replace comp23 = 1 if ///
		inlist(`tempcode', "K610", "K611", "K612", "K615", "K630", "K651", "K652", "K653") | ///
		inlist(`tempcode', "K654", "K658", "K659", "K750") | ///
		inlist(`tempcode', "A7481", "K6131", "K6139", "K6811", "K6812", "K6819")
	quietly replace comp23 = 1 if ///
		inlist(`tempcode', "K61.0", "K61.1", "K61.2", "K61.5", "K63.0", "K65.1", "K65.2", "K65.3") | ///
		inlist(`tempcode', "K65.4", "K65.8", "K65.9", "K75.0") | ///
		inlist(`tempcode', "A74.81", "K61.31", "K61.39", "K68.11", "K68.12", "K68.19")
		
	*DIG017 - Biliary tract disease
	quietly replace comp24 = 1 if ///
		inlist(`tempcode', "K811", "K812", "K819", "K820", "K821", "K823", "K824", "K828") | ///
		inlist(`tempcode', "K829", "K831", "K833", "K834", "K835", "K838", "K839") | ///
		inlist(`tempcode', "K8010", "K8011", "K8012", "K8013", "K8018", "K8019", "K8020", "K8021") | ///
		inlist(`tempcode', "K8030", "K8031", "K8037", "K8040", "K8041", "K8044", "K8045", "K8046") | ///
		inlist(`tempcode', "K8047", "K8050", "K8051", "K8060", "K8061", "K8064", "K8065", "K8066") | ///
		inlist(`tempcode', "K8067", "K8070", "K8071", "K8080", "K8081", "K8301", "K8309")
	quietly replace comp24 = 1 if ///
		inlist(`tempcode', "K81.1", "K81.2", "K81.9", "K82.0", "K82.1", "K82.3", "K82.4", "K82.8") | ///
		inlist(`tempcode', "K82.9", "K83.1", "K83.3", "K83.4", "K83.5", "K83.8", "K83.9") | ///
		inlist(`tempcode', "K80.10", "K80.11", "K80.12", "K80.13", "K80.18", "K80.19", "K80.20", "K80.21") | ///
		inlist(`tempcode', "K80.30", "K80.31", "K80.37", "K80.40", "K80.41", "K80.44", "K80.45", "K80.46") | ///
		inlist(`tempcode', "K80.47", "K80.50", "K80.51", "K80.60", "K80.61", "K80.64", "K80.65", "K80.66") | ///
		inlist(`tempcode', "K80.67", "K80.70", "K80.71", "K80.80", "K80.81", "K83.01", "K83.09")

	*DIG021 - Gastrointestinal hemorrhage
	quietly replace comp25 = 1 if ///
		inlist(`tempcode', "K254", "K256", "K264", "K266", "K274", "K284", "K286", "K625") | ///
		inlist(`tempcode', "K920", "K921", "K922")
	quietly replace comp25 = 1 if ///
		inlist(`tempcode', "K25.4", "K25.6", "K26.4", "K26.6", "K27.4", "K28.4", "K28.6", "K62.5") | ///
		inlist(`tempcode', "K92.0", "K92.1", "K92.2")

	*DIG022 - Noninfectious gastroenteritis
	quietly replace comp26 = 1 if ///
		inlist(`tempcode', "K520", "K521", "K523", "K529") | ///
		inlist(`tempcode', "K5229", "K5281", "K5282", "K5289") | ///
		inlist(`tempcode', "K52831", "K52832", "K52839")
	quietly replace comp26 = 1 if ///
		inlist(`tempcode', "K52.0", "K52.1", "K52.3", "K52.9") | ///
		inlist(`tempcode', "K52.29", "K52.81", "K52.82", "K52.89") | ///
		inlist(`tempcode', "K52.831", "K52.832", "K52.839")

	*DIG025 - Other specified and unspecified gastrointestinal disorders
	quietly replace comp27 = 1 if ///
		inlist(`tempcode', "K551", "K558", "K559", "K580", "K581", "K582", "K588", "K589") | ///
		inlist(`tempcode', "K591", "K592", "K598", "K599", "K632", "K633", "K634", "K639") | ///
		inlist(`tempcode', "K660", "K661", "K668", "K669", "K689", "K900", "K902", "K909") | ///
		inlist(`tempcode', "K929") | ///
		inlist(`tempcode', "K5520", "K5521", "K5530", "K5531", "K5532", "K5533", "K5900", "K5901") | ///
		inlist(`tempcode', "K5902", "K5904", "K5909", "K5931", "K5939", "K6381", "K6389", "K9041") | ///
		inlist(`tempcode', "K9049", "K9081", "K9089", "K9281", "K9289")
	quietly replace comp27 = 1 if ///
		inlist(`tempcode', "K55.1", "K55.8", "K55.9", "K58.0", "K58.1", "K58.2", "K58.8", "K58.9") | ///
		inlist(`tempcode', "K59.1", "K59.2", "K59.8", "K59.9", "K63.2", "K63.3", "K63.4", "K63.9") | ///
		inlist(`tempcode', "K66.0", "K66.1", "K66.8", "K66.9", "K68.9", "K90.0", "K90.2", "K90.9") | ///
		inlist(`tempcode', "K92.9") | ///
		inlist(`tempcode', "K55.20", "K55.21", "K55.30", "K55.31", "K55.32", "K55.33", "K59.00", "K59.01") | ///
		inlist(`tempcode', "K59.02", "K59.04", "K59.09", "K59.31", "K59.39", "K63.81", "K63.89", "K90.41") | ///
		inlist(`tempcode', "K90.49", "K90.81", "K90.89", "K92.81", "K92.89")
	
*END CCSR
	display "		Coding END CCSR"
	*END003 - Diabetes mellitus with complication
	quietly replace comp28 = 1 if ///
		inlist(`tempcode', "E108", "E118", "E138") | ///
		inlist(`tempcode', "E0910", "E0921", "E0922", "E0936", "E0940", "E0942", "E0951", "E0959") | ///
		inlist(`tempcode', "E0965", "E0969", "E1010", "E1011", "E1021", "E1022", "E1029", "E1036") | ///
		inlist(`tempcode', "E1039", "E1040", "E1041", "E1042", "E1043", "E1044", "E1049", "E1051") | ///
		inlist(`tempcode', "E1052", "E1059", "E1065", "E1069", "E1100", "E1101", "E1110", "E1111") | ///
		inlist(`tempcode', "E1121", "E1122", "E1129", "E1136", "E1139", "E1140", "E1141", "E1142") | ///
		inlist(`tempcode', "E1143", "E1144", "E1149", "E1151", "E1152", "E1159", "E1165", "E1169") | ///
		inlist(`tempcode', "E1310", "E1311", "E1321", "E1322", "E1329", "E1339", "E1340", "E1341") | ///
		inlist(`tempcode', "E1342", "E1343", "E1351", "E1352", "E1359", "E1365", "E1369") | ///
		inlist(`tempcode', "E09610", "E09621", "E09622", "E09641", "E09649", "E10311", "E10319", "E10610") | ///
		inlist(`tempcode', "E10618", "E10620", "E10621", "E10622", "E10628", "E10641", "E10649", "E11311") | ///
		inlist(`tempcode', "E11319", "E11610", "E11618", "E11620", "E11621", "E11622", "E11628", "E11630") | ///
		inlist(`tempcode', "E11638", "E11641", "E11649", "E13319", "E13621", "E13628", "E13649") | ///
		inlist(`tempcode', "E093293", "E103212", "E103213", "E103219", "E103291", "E103292", "E103293", "E103299") | ///
		inlist(`tempcode', "E103319", "E103391", "E103393", "E103399", "E103411", "E103419", "E103511", "E103512") | ///
		inlist(`tempcode', "E103513", "E103519", "E103553", "E103559", "E103591", "E103592", "E103593", "E103599") | ///
		inlist(`tempcode', "E1037X3", "E113211", "E113212", "E113213", "E113219", "E113291", "E113292", "E113293") | ///
		inlist(`tempcode', "E113299", "E113311", "E113313", "E113319", "E113391", "E113392", "E113393", "E113399") | ///
		inlist(`tempcode', "E113411", "E113412", "E113413", "E113419", "E113491", "E113492", "E113493", "E113499") | ///
		inlist(`tempcode', "E113511", "E113512", "E113513", "E113519", "E113523", "E113529", "E113533", "E113543") | ///
		inlist(`tempcode', "E113551", "E113553", "E113559", "E113591", "E113592", "E113593", "E113599", "E1137X9") | ///
		inlist(`tempcode', "E133312", "E133391")
	quietly replace comp28 = 1 if ///
		inlist(`tempcode', "E10.8", "E11.8", "E13.8") | ///
		inlist(`tempcode', "E09.10", "E09.21", "E09.22", "E09.36", "E09.40", "E09.42", "E09.51", "E09.59") | ///
		inlist(`tempcode', "E09.65", "E09.69", "E10.10", "E10.11", "E10.21", "E10.22", "E10.29", "E10.36") | ///
		inlist(`tempcode', "E10.39", "E10.40", "E10.41", "E10.42", "E10.43", "E10.44", "E10.49", "E10.51") | ///
		inlist(`tempcode', "E10.52", "E10.59", "E10.65", "E10.69", "E11.00", "E11.01", "E11.10", "E11.11") | ///
		inlist(`tempcode', "E11.21", "E11.22", "E11.29", "E11.36", "E11.39", "E11.40", "E11.41", "E11.42") | ///
		inlist(`tempcode', "E11.43", "E11.44", "E11.49", "E11.51", "E11.52", "E11.59", "E11.65", "E11.69") | ///
		inlist(`tempcode', "E13.10", "E13.11", "E13.21", "E13.22", "E13.29", "E13.39", "E13.40", "E13.41") | ///
		inlist(`tempcode', "E13.42", "E13.43", "E13.51", "E13.52", "E13.59", "E13.65", "E13.69") | ///
		inlist(`tempcode', "E09.610", "E09.621", "E09.622", "E09.641", "E09.649", "E10.311", "E10.319", "E10.610") | ///
		inlist(`tempcode', "E10.618", "E10.620", "E10.621", "E10.622", "E10.628", "E10.641", "E10.649", "E11.311") | ///
		inlist(`tempcode', "E11.319", "E11.610", "E11.618", "E11.620", "E11.621", "E11.622", "E11.628", "E11.630") | ///
		inlist(`tempcode', "E11.638", "E11.641", "E11.649", "E13.319", "E13.621", "E13.628", "E13.649") | ///
		inlist(`tempcode', "E09.3293", "E10.3212", "E10.3213", "E10.3219", "E10.3291", "E10.3292", "E10.3293", "E10.3299") | ///
		inlist(`tempcode', "E10.3319", "E10.3391", "E10.3393", "E10.3399", "E10.3411", "E10.3419", "E10.3511", "E10.3512") | ///
		inlist(`tempcode', "E10.3513", "E10.3519", "E10.3553", "E10.3559", "E10.3591", "E10.3592", "E10.3593", "E10.3599") | ///
		inlist(`tempcode', "E10.37X3", "E11.3211", "E11.3212", "E11.3213", "E11.3219", "E11.3291", "E11.3292", "E11.3293") | ///
		inlist(`tempcode', "E11.3299", "E11.3311", "E11.3313", "E11.3319", "E11.3391", "E11.3392", "E11.3393", "E11.3399") | ///
		inlist(`tempcode', "E11.3411", "E11.3412", "E11.3413", "E11.3419", "E11.3491", "E11.3492", "E11.3493", "E11.3499") | ///
		inlist(`tempcode', "E11.3511", "E11.3512", "E11.3513", "E11.3519", "E11.3523", "E11.3529", "E11.3533", "E11.3543") | ///
		inlist(`tempcode', "E11.3551", "E11.3553", "E11.3559", "E11.3591", "E11.3592", "E11.3593", "E11.3599", "E11.37X9") | ///
		inlist(`tempcode', "E13.3312", "E13.3391")
	
	*END008 - Malnutrition
	quietly replace comp29 = 1 if ///
		inlist(`tempcode', "E40", "E41", "E42", "E43", "E46") | ///
		inlist(`tempcode', "E440", "E441")
	quietly replace comp29 = 1 if ///
		inlist(`tempcode', "E40", "E41", "E42", "E43", "E46") | ///
		inlist(`tempcode', "E44.0", "E44.1")

	*END009 - Obesity
	quietly replace comp30 = 1 if ///
		inlist(`tempcode', "E662", "E668", "E669") | ///
		inlist(`tempcode', "E6601", "E6609")
	quietly replace comp30 = 1 if ///
		inlist(`tempcode', "E66.2", "E66.8", "E66.9") | ///
		inlist(`tempcode', "E66.01", "E66.09")

	*END010 - Disorders of lipid metabolism
	quietly replace comp31 = 1 if ///
		inlist(`tempcode', "E781", "E782", "E783", "E785") | ///
		inlist(`tempcode', "E7800", "E7801", "E7841", "E7849")
	quietly replace comp31 = 1 if ///
		inlist(`tempcode', "E78.1", "E78.2", "E78.3", "E78.5") | ///
		inlist(`tempcode', "E78.00", "E78.01", "E78.41", "E78.49")

	*END011 - Fluid and electrolyte disorders
	quietly replace comp32 = 1 if ///
		inlist(`tempcode', "E860", "E861", "E869", "E870", "E871", "E872", "E873", "E874") | ///
		inlist(`tempcode', "E875", "E876", "E878") | ///
		inlist(`tempcode', "E8770", "E8771", "E8779")
	quietly replace comp32 = 1 if ///
		inlist(`tempcode', "E86.0", "E86.1", "E86.9", "E87.0", "E87.1", "E87.2", "E87.3", "E87.4") | ///
		inlist(`tempcode', "E87.5", "E87.6", "E87.8") | ///
		inlist(`tempcode', "E87.70", "E87.71", "E87.79")
	
*GEN CCSR
	display "		Coding GEN CCSR"
	*GEN003 - Chronic kidney disease
	quietly replace comp33 = 1 if ///
		inlist(`tempcode', "I120", "I129", "I132", "N181", "N182", "N183", "N184", "N185") | ///
		inlist(`tempcode', "N186", "N189") | ///
		inlist(`tempcode', "I1310", "I1311")
	quietly replace comp33 = 1 if ///
		inlist(`tempcode', "I12.0", "I12.9", "I13.2", "N18.1", "N18.2", "N18.3", "N18.4", "N18.5") | ///
		inlist(`tempcode', "N18.6", "N18.9") | ///
		inlist(`tempcode', "I13.10", "I13.11")

	*GEN004 - Urinary tract infections
	quietly replace comp34 = 1 if ///
		inlist(`tempcode', "N12") | ///
		inlist(`tempcode', "N110", "N111", "N118", "N119", "N136", "N151", "N340", "N342") | ///
		inlist(`tempcode', "N390") | ///
		inlist(`tempcode', "B3741", "B3749", "N3010", "N3011", "N3020", "N3021", "N3030", "N3031") | ///
		inlist(`tempcode', "N3040", "N3041", "N3080", "N3081", "N3090", "N3091")
	quietly replace comp34 = 1 if ///
		inlist(`tempcode', "N12") | ///
		inlist(`tempcode', "N11.0", "N11.1", "N11.8", "N11.9", "N13.6", "N15.1", "N34.0", "N34.2") | ///
		inlist(`tempcode', "N39.0") | ///
		inlist(`tempcode', "B37.41", "B37.49", "N30.10", "N30.11", "N30.20", "N30.21", "N30.30", "N30.31") | ///
		inlist(`tempcode', "N30.40", "N30.41", "N30.80", "N30.81", "N30.90", "N30.91")

	*GEN007 - Other specified and unspecified diseases of bladder and urethra
	quietly replace comp35 = 1 if ///
		inlist(`tempcode', "N310", "N311", "N312", "N318", "N319", "N320", "N321", "N322") | ///
		inlist(`tempcode', "N323", "N329", "N360", "N361", "N362", "N365", "N368", "N369") | ///
		inlist(`tempcode', "N3281", "N3289", "N3582", "N3592", "N3641", "N3642", "N3643", "N3644") | ///
		inlist(`tempcode', "N35010", "N35011", "N35012", "N35013", "N35014", "N35016", "N35114", "N35119") | ///
		inlist(`tempcode', "N35811", "N35812", "N35813", "N35814", "N35816", "N35819", "N35911", "N35912") | ///
		inlist(`tempcode', "N35913", "N35914", "N35916", "N35919")
	quietly replace comp35 = 1 if ///
		inlist(`tempcode', "N31.0", "N31.1", "N31.2", "N31.8", "N31.9", "N32.0", "N32.1", "N32.2") | ///
		inlist(`tempcode', "N32.3", "N32.9", "N36.0", "N36.1", "N36.2", "N36.5", "N36.8", "N36.9") | ///
		inlist(`tempcode', "N32.81", "N32.89", "N35.82", "N35.92", "N36.41", "N36.42", "N36.43", "N36.44") | ///
		inlist(`tempcode', "N35.010", "N35.011", "N35.012", "N35.013", "N35.014", "N35.016", "N35.114", "N35.119") | ///
		inlist(`tempcode', "N35.811", "N35.812", "N35.813", "N35.814", "N35.816", "N35.819", "N35.911", "N35.912") | ///
		inlist(`tempcode', "N35.913", "N35.914", "N35.916", "N35.919")

	*GEN009 - Hematuria
	quietly replace comp36 = 1 if ///
		inlist(`tempcode', "N020", "N022", "N028", "N029", "R310", "R311", "R319") | ///
		inlist(`tempcode', "R3121", "R3129")
	quietly replace comp36 = 1 if ///
		inlist(`tempcode', "N02.0", "N02.2", "N02.8", "N02.9", "R31.0", "R31.1", "R31.9") | ///
		inlist(`tempcode', "R31.21", "R31.29")

*MAL CCSR
	display "		Coding MAL CCSR"
	*MAL001 - Cardiac and circulatory congenital anomalies
	quietly replace comp37 = 1 if ///
		inlist(`tempcode', "Q200", "Q201", "Q203", "Q204", "Q205", "Q206", "Q208", "Q209") | ///
		inlist(`tempcode', "Q210", "Q211", "Q212", "Q213", "Q214", "Q218", "Q219", "Q220") | ///
		inlist(`tempcode', "Q221", "Q222", "Q223", "Q224", "Q225", "Q228", "Q230", "Q231") | ///
		inlist(`tempcode', "Q232", "Q233", "Q234", "Q238", "Q239", "Q240", "Q242", "Q243") | ///
		inlist(`tempcode', "Q244", "Q245", "Q246", "Q248", "Q249", "Q250", "Q251", "Q253") | ///
		inlist(`tempcode', "Q255", "Q256", "Q258", "Q260", "Q261", "Q262", "Q263", "Q264") | ///
		inlist(`tempcode', "Q268", "Q269", "Q270", "Q271", "Q272", "Q278", "Q279", "Q281") | ///
		inlist(`tempcode', "Q282", "Q283", "Q288") | ///
		inlist(`tempcode', "Q2540", "Q2542", "Q2543", "Q2544", "Q2545", "Q2546", "Q2547", "Q2548") | ///
		inlist(`tempcode', "Q2549", "Q2572", "Q2579", "Q2730", "Q2731", "Q2732", "Q2733", "Q2734") | ///
		inlist(`tempcode', "Q2739")
	quietly replace comp37 = 1 if ///
		inlist(`tempcode', "Q20.0", "Q20.1", "Q20.3", "Q20.4", "Q20.5", "Q20.6", "Q20.8", "Q20.9") | ///
		inlist(`tempcode', "Q21.0", "Q21.1", "Q21.2", "Q21.3", "Q21.4", "Q21.8", "Q21.9", "Q22.0") | ///
		inlist(`tempcode', "Q22.1", "Q22.2", "Q22.3", "Q22.4", "Q22.5", "Q22.8", "Q23.0", "Q23.1") | ///
		inlist(`tempcode', "Q23.2", "Q23.3", "Q23.4", "Q23.8", "Q23.9", "Q24.0", "Q24.2", "Q24.3") | ///
		inlist(`tempcode', "Q24.4", "Q24.5", "Q24.6", "Q24.8", "Q24.9", "Q25.0", "Q25.1", "Q25.3") | ///
		inlist(`tempcode', "Q25.5", "Q25.6", "Q25.8", "Q26.0", "Q26.1", "Q26.2", "Q26.3", "Q26.4") | ///
		inlist(`tempcode', "Q26.8", "Q26.9", "Q27.0", "Q27.1", "Q27.2", "Q27.8", "Q27.9", "Q28.1") | ///
		inlist(`tempcode', "Q28.2", "Q28.3", "Q28.8") | ///
		inlist(`tempcode', "Q25.40", "Q25.42", "Q25.43", "Q25.44", "Q25.45", "Q25.46", "Q25.47", "Q25.48") | ///
		inlist(`tempcode', "Q25.49", "Q25.72", "Q25.79", "Q27.30", "Q27.31", "Q27.32", "Q27.33", "Q27.34") | ///
		inlist(`tempcode', "Q27.39")

*MBD CCSR
	display "		Coding MBD CCSR"
	*MBD017 - Alcohol-related disorders
	quietly replace comp38 = 1 if ///
		inlist(`tempcode', "G312") | ///
		inlist(`tempcode', "F1010", "F1014", "F1019", "F1020", "F1024", "F1026", "F1027", "F1029") | ///
		inlist(`tempcode', "F1094", "F1096", "F1097", "F1099") | ///
		inlist(`tempcode', "F10120", "F10121", "F10129", "F10151", "F10159", "F10180", "F10188", "F10220") | ///
		inlist(`tempcode', "F10221", "F10229", "F10230", "F10231", "F10232", "F10239", "F10250", "F10251") | ///
		inlist(`tempcode', "F10259", "F10280", "F10282", "F10288", "F10920", "F10921", "F10929", "F10959") | ///
		inlist(`tempcode', "F10980", "F10988")
	quietly replace comp38 = 1 if ///
		inlist(`tempcode', "G31.2") | ///
		inlist(`tempcode', "F10.10", "F10.14", "F10.19", "F10.20", "F10.24", "F10.26", "F10.27", "F10.29") | ///
		inlist(`tempcode', "F10.94", "F10.96", "F10.97", "F10.99") | ///
		inlist(`tempcode', "F10.120", "F10.121", "F10.129", "F10.151", "F10.159", "F10.180", "F10.188", "F10.220") | ///
		inlist(`tempcode', "F10.221", "F10.229", "F10.230", "F10.231", "F10.232", "F10.239", "F10.250", "F10.251") | ///
		inlist(`tempcode', "F10.259", "F10.280", "F10.282", "F10.288", "F10.920", "F10.921", "F10.929", "F10.959") | ///
		inlist(`tempcode', "F10.980", "F10.988")

	*MBD019 - Cannabis-related disorders
	quietly replace comp39 = 1 if ///
		inlist(`tempcode', "F1210", "F1219", "F1220", "F1223", "F1290", "F1293", "F1299") | ///
		inlist(`tempcode', "F12129", "F12180", "F12188", "F12920", "F12929", "F12980", "F12988")
	quietly replace comp39 = 1 if ///
		inlist(`tempcode', "F12.10", "F12.19", "F12.20", "F12.23", "F12.90", "F12.93", "F12.99") | ///
		inlist(`tempcode', "F12.129", "F12.180", "F12.188", "F12.920", "F12.929", "F12.980", "F12.988")

	*MBD021 - Stimulant-related disorders
	quietly replace comp40 = 1 if ///
		inlist(`tempcode', "F1410", "F1414", "F1419", "F1420", "F1423", "F1424", "F1490", "F1494") | ///
		inlist(`tempcode', "F1499", "F1510", "F1514", "F1519", "F1520", "F1523", "F1529", "F1590") | ///
		inlist(`tempcode', "F1593", "F1599") | ///
		inlist(`tempcode', "F14120", "F14121", "F14122", "F14129", "F14159", "F14188", "F14229", "F14288") | ///
		inlist(`tempcode', "F14929", "F14950", "F14988", "F15120", "F15121", "F15129", "F15150", "F15159") | ///
		inlist(`tempcode', "F15188", "F15220", "F15229", "F15250", "F15251", "F15259", "F15280", "F15288") | ///
		inlist(`tempcode', "F15920", "F15921", "F15950", "F15959", "F15982")
	quietly replace comp40 = 1 if ///
		inlist(`tempcode', "F14.10", "F14.14", "F14.19", "F14.20", "F14.23", "F14.24", "F14.90", "F14.94") | ///
		inlist(`tempcode', "F14.99", "F15.10", "F15.14", "F15.19", "F15.20", "F15.23", "F15.29", "F15.90") | ///
		inlist(`tempcode', "F15.93", "F15.99") | ///
		inlist(`tempcode', "F14.120", "F14.121", "F14.122", "F14.129", "F14.159", "F14.188", "F14.229", "F14.288") | ///
		inlist(`tempcode', "F14.929", "F14.950", "F14.988", "F15.120", "F15.121", "F15.129", "F15.150", "F15.159") | ///
		inlist(`tempcode', "F15.188", "F15.220", "F15.229", "F15.250", "F15.251", "F15.259", "F15.280", "F15.288") | ///
		inlist(`tempcode', "F15.920", "F15.921", "F15.950", "F15.959", "F15.982")

*MUS CCSR
	display "		Coding MUS CCSR"
	*MUS002 - Osteomyelitis
	quietly replace comp41 = 1 if ///
		inlist(`tempcode', "A0224", "M4620", "M4621", "M4622", "M4623", "M4624", "M4625", "M4626") | ///
		inlist(`tempcode', "M4627", "M4628", "M8630", "M8638", "M8639", "M8640", "M8648", "M8649") | ///
		inlist(`tempcode', "M8660", "M8668", "M8669", "M869") | ///
		inlist(`tempcode', "M86351", "M86352", "M86361", "M86362", "M86371", "M86372", "M86451", "M86452") | ///
		inlist(`tempcode', "M86461", "M86462", "M86469", "M86471", "M86472", "M86479", "M86552", "M86562") | ///
		inlist(`tempcode', "M86571", "M86572", "M86611", "M86621", "M86622", "M86631", "M86632", "M86641") | ///
		inlist(`tempcode', "M86642", "M86651", "M86652", "M86659", "M86661", "M86662", "M86669", "M86671") | ///
		inlist(`tempcode', "M86672", "M86679", "M868X0", "M868X1", "M868X2", "M868X3", "M868X4", "M868X5") | ///
		inlist(`tempcode', "M868X6", "M868X7", "M868X8", "M868X9")
	quietly replace comp41 = 1 if ///
		inlist(`tempcode', "A02.24", "M46.20", "M46.21", "M46.22", "M46.23", "M46.24", "M46.25", "M46.26") | ///
		inlist(`tempcode', "M46.27", "M46.28", "M86.30", "M86.38", "M86.39", "M86.40", "M86.48", "M86.49") | ///
		inlist(`tempcode', "M86.60", "M86.68", "M86.69", "M86.9") | ///
		inlist(`tempcode', "M86.351", "M86.352", "M86.361", "M86.362", "M86.371", "M86.372", "M86.451", "M86.452") | ///
		inlist(`tempcode', "M86.461", "M86.462", "M86.469", "M86.471", "M86.472", "M86.479", "M86.552", "M86.562") | ///
		inlist(`tempcode', "M86.571", "M86.572", "M86.611", "M86.621", "M86.622", "M86.631", "M86.632", "M86.641") | ///
		inlist(`tempcode', "M86.642", "M86.651", "M86.652", "M86.659", "M86.661", "M86.662", "M86.669", "M86.671") | ///
		inlist(`tempcode', "M86.672", "M86.679", "M86.8X0", "M86.8X1", "M86.8X2", "M86.8X3", "M86.8X4", "M86.8X5") | ///
		inlist(`tempcode', "M86.8X6", "M86.8X7", "M86.8X8", "M86.8X9")

	*MUS006 - Osteoarthritis
	quietly replace comp42 = 1 if ///
		inlist(`tempcode', "M150", "M151", "M153", "M154", "M158", "M159", "M160", "M162") | ///
		inlist(`tempcode', "M164", "M166", "M167", "M169", "M170", "M172", "M174", "M175") | ///
		inlist(`tempcode', "M179", "M180", "M189") | ///
		inlist(`tempcode', "M1610", "M1611", "M1612", "M1630", "M1631", "M1632", "M1651", "M1652") | ///
		inlist(`tempcode', "M1710", "M1711", "M1712", "M1730", "M1731", "M1732", "M1810", "M1811") | ///
		inlist(`tempcode', "M1812", "M1831", "M1990", "M1991", "M1992", "M1993") | ///
		inlist(`tempcode', "M19011", "M19012", "M19019", "M19021", "M19022", "M19029", "M19031", "M19032") | ///
		inlist(`tempcode', "M19039", "M19041", "M19042", "M19049", "M19071", "M19072", "M19079", "M19111") | ///
		inlist(`tempcode', "M19112", "M19121", "M19131", "M19132", "M19139", "M19141", "M19142", "M19149") | ///
		inlist(`tempcode', "M19171", "M19172", "M19179", "M19211", "M19212", "M19219", "M19222", "M19231") | ///
		inlist(`tempcode', "M19239", "M19241", "M19242", "M19271", "M19272", "M19279")
	quietly replace comp42 = 1 if ///
		inlist(`tempcode', "M15.0", "M15.1", "M15.3", "M15.4", "M15.8", "M15.9", "M16.0", "M16.2") | ///
		inlist(`tempcode', "M16.4", "M16.6", "M16.7", "M16.9", "M17.0", "M17.2", "M17.4", "M17.5") | ///
		inlist(`tempcode', "M17.9", "M18.0", "M18.9") | ///
		inlist(`tempcode', "M16.10", "M16.11", "M16.12", "M16.30", "M16.31", "M16.32", "M16.51", "M16.52") | ///
		inlist(`tempcode', "M17.10", "M17.11", "M17.12", "M17.30", "M17.31", "M17.32", "M18.10", "M18.11") | ///
		inlist(`tempcode', "M18.12", "M18.31", "M19.90", "M19.91", "M19.92", "M19.93") | ///
		inlist(`tempcode', "M19.011", "M19.012", "M19.019", "M19.021", "M19.022", "M19.029", "M19.031", "M19.032") | ///
		inlist(`tempcode', "M19.039", "M19.041", "M19.042", "M19.049", "M19.071", "M19.072", "M19.079", "M19.111") | ///
		inlist(`tempcode', "M19.112", "M19.121", "M19.131", "M19.132", "M19.139", "M19.141", "M19.142", "M19.149") | ///
		inlist(`tempcode', "M19.171", "M19.172", "M19.179", "M19.211", "M19.212", "M19.219", "M19.222", "M19.231") | ///
		inlist(`tempcode', "M19.239", "M19.241", "M19.242", "M19.271", "M19.272", "M19.279")

	*MUS011 - Spondylopathies/spondyloarthropathy (including infective
	quietly replace comp43 = 1 if ///
		inlist(`tempcode', "M081", "M433", "M434", "M436", "M439", "M450", "M451", "M452") | ///
		inlist(`tempcode', "M453", "M454", "M455", "M456", "M457", "M458", "M459", "M461") | ///
		inlist(`tempcode', "M479", "M489", "M519", "M530", "M531", "M533", "M539", "M542") | ///
		inlist(`tempcode', "M4300", "M4302", "M4303", "M4304", "M4305", "M4306", "M4307", "M4308") | ///
		inlist(`tempcode', "M4310", "M4312", "M4313", "M4314", "M4315", "M4316", "M4317", "M4318") | ///
		inlist(`tempcode', "M4319", "M4320", "M4322", "M4323", "M4324", "M4325", "M4326", "M4327") | ///
		inlist(`tempcode', "M4328", "M4600", "M4601", "M4602", "M4603", "M4604", "M4606", "M4607") | ///
		inlist(`tempcode', "M4608", "M4609", "M4632", "M4633", "M4634", "M4635", "M4636", "M4637") | ///
		inlist(`tempcode', "M4639", "M4640", "M4642", "M4643", "M4644", "M4645", "M4646", "M4647") | ///
		inlist(`tempcode', "M4648", "M4649", "M4652", "M4653", "M4654", "M4655", "M4656", "M4657") | ///
		inlist(`tempcode', "M4658", "M4680", "M4682", "M4683", "M4684", "M4685", "M4686", "M4687") | ///
		inlist(`tempcode', "M4688", "M4689", "M4690", "M4692", "M4693", "M4694", "M4695", "M4696") | ///
		inlist(`tempcode', "M4697", "M4698", "M4699", "M4710", "M4711", "M4712", "M4713", "M4714") | ///
		inlist(`tempcode', "M4715", "M4716", "M4720", "M4721", "M4722", "M4723", "M4724", "M4725") | ///
		inlist(`tempcode', "M4726", "M4727", "M4728", "M4800", "M4801", "M4802", "M4803", "M4804") | ///
		inlist(`tempcode', "M4805", "M4807", "M4808", "M4810", "M4812", "M4813", "M4814", "M4815") | ///
		inlist(`tempcode', "M4816", "M4817", "M4819", "M4820", "M4826", "M4830", "M4832", "M4833") | ///
		inlist(`tempcode', "M4834", "M4835", "M4836", "M4837", "M5000", "M5001", "M5003", "M5010") | ///
		inlist(`tempcode', "M5011", "M5013", "M5020", "M5021", "M5023", "M5030", "M5031", "M5033") | ///
		inlist(`tempcode', "M5080", "M5081", "M5083", "M5090", "M5091", "M5093", "M5104", "M5105") | ///
		inlist(`tempcode', "M5106", "M5114", "M5115", "M5116", "M5117", "M5124", "M5125", "M5126") | ///
		inlist(`tempcode', "M5127", "M5134", "M5135", "M5136", "M5137", "M5144", "M5145", "M5146") | ///
		inlist(`tempcode', "M5147", "M5184", "M5185", "M5186", "M5187", "M5380", "M5382", "M5383") | ///
		inlist(`tempcode', "M5384", "M5385", "M5386", "M5387", "M5388", "M5410", "M5411", "M5412") | ///
		inlist(`tempcode', "M5413", "M5414", "M5415", "M5416", "M5417", "M5418", "M5430", "M5431") | ///
		inlist(`tempcode', "M5432", "M5440", "M5441", "M5442") | ///
		inlist(`tempcode', "M435X2", "M435X3", "M435X4", "M435X5", "M435X6", "M435X7", "M438X1", "M438X2") | ///
		inlist(`tempcode', "M438X3", "M438X4", "M438X5", "M438X6", "M438X7", "M438X8", "M438X9", "M47012") | ///
		inlist(`tempcode', "M47013", "M47014", "M47016", "M47019", "M47022", "M47811", "M47812", "M47813") | ///
		inlist(`tempcode', "M47814", "M47815", "M47816", "M47817", "M47818", "M47819", "M47892", "M47893") | ///
		inlist(`tempcode', "M47894", "M47895", "M47896", "M47897", "M47898", "M47899", "M48061", "M48062") | ///
		inlist(`tempcode', "M488X2", "M488X3", "M488X4", "M488X5", "M488X6", "M488X7", "M488X9", "M50020") | ///
		inlist(`tempcode', "M50021", "M50022", "M50023", "M50120", "M50121", "M50122", "M50123", "M50220") | ///
		inlist(`tempcode', "M50221", "M50222", "M50223", "M50320", "M50321", "M50322", "M50323", "M50821") | ///
		inlist(`tempcode', "M50822", "M50823", "M50920", "M50921", "M50922", "M50923", "M532X1", "M532X2") | ///
		inlist(`tempcode', "M532X3", "M532X4", "M532X5", "M532X6", "M532X7", "M532X8", "M532X9")
	quietly replace comp43 = 1 if ///
		inlist(`tempcode', "M08.1", "M43.3", "M43.4", "M43.6", "M43.9", "M45.0", "M45.1", "M45.2") | ///
		inlist(`tempcode', "M45.3", "M45.4", "M45.5", "M45.6", "M45.7", "M45.8", "M45.9", "M46.1") | ///
		inlist(`tempcode', "M47.9", "M48.9", "M51.9", "M53.0", "M53.1", "M53.3", "M53.9", "M54.2") | ///
		inlist(`tempcode', "M43.00", "M43.02", "M43.03", "M43.04", "M43.05", "M43.06", "M43.07", "M43.08") | ///
		inlist(`tempcode', "M43.10", "M43.12", "M43.13", "M43.14", "M43.15", "M43.16", "M43.17", "M43.18") | ///
		inlist(`tempcode', "M43.19", "M43.20", "M43.22", "M43.23", "M43.24", "M43.25", "M43.26", "M43.27") | ///
		inlist(`tempcode', "M43.28", "M46.00", "M46.01", "M46.02", "M46.03", "M46.04", "M46.06", "M46.07") | ///
		inlist(`tempcode', "M46.08", "M46.09", "M46.32", "M46.33", "M46.34", "M46.35", "M46.36", "M46.37") | ///
		inlist(`tempcode', "M46.39", "M46.40", "M46.42", "M46.43", "M46.44", "M46.45", "M46.46", "M46.47") | ///
		inlist(`tempcode', "M46.48", "M46.49", "M46.52", "M46.53", "M46.54", "M46.55", "M46.56", "M46.57") | ///
		inlist(`tempcode', "M46.58", "M46.80", "M46.82", "M46.83", "M46.84", "M46.85", "M46.86", "M46.87") | ///
		inlist(`tempcode', "M46.88", "M46.89", "M46.90", "M46.92", "M46.93", "M46.94", "M46.95", "M46.96") | ///
		inlist(`tempcode', "M46.97", "M46.98", "M46.99", "M47.10", "M47.11", "M47.12", "M47.13", "M47.14") | ///
		inlist(`tempcode', "M47.15", "M47.16", "M47.20", "M47.21", "M47.22", "M47.23", "M47.24", "M47.25") | ///
		inlist(`tempcode', "M47.26", "M47.27", "M47.28", "M48.00", "M48.01", "M48.02", "M48.03", "M48.04") | ///
		inlist(`tempcode', "M48.05", "M48.07", "M48.08", "M48.10", "M48.12", "M48.13", "M48.14", "M48.15") | ///
		inlist(`tempcode', "M48.16", "M48.17", "M48.19", "M48.20", "M48.26", "M48.30", "M48.32", "M48.33") | ///
		inlist(`tempcode', "M48.34", "M48.35", "M48.36", "M48.37", "M50.00", "M50.01", "M50.03", "M50.10") | ///
		inlist(`tempcode', "M50.11", "M50.13", "M50.20", "M50.21", "M50.23", "M50.30", "M50.31", "M50.33") | ///
		inlist(`tempcode', "M50.80", "M50.81", "M50.83", "M50.90", "M50.91", "M50.93", "M51.04", "M51.05") | ///
		inlist(`tempcode', "M51.06", "M51.14", "M51.15", "M51.16", "M51.17", "M51.24", "M51.25", "M51.26") | ///
		inlist(`tempcode', "M51.27", "M51.34", "M51.35", "M51.36", "M51.37", "M51.44", "M51.45", "M51.46") | ///
		inlist(`tempcode', "M51.47", "M51.84", "M51.85", "M51.86", "M51.87", "M53.80", "M53.82", "M53.83") | ///
		inlist(`tempcode', "M53.84", "M53.85", "M53.86", "M53.87", "M53.88", "M54.10", "M54.11", "M54.12") | ///
		inlist(`tempcode', "M54.13", "M54.14", "M54.15", "M54.16", "M54.17", "M54.18", "M54.30", "M54.31") | ///
		inlist(`tempcode', "M54.32", "M54.40", "M54.41", "M54.42") | ///
		inlist(`tempcode', "M43.5X2", "M43.5X3", "M43.5X4", "M43.5X5", "M43.5X6", "M43.5X7", "M43.8X1", "M43.8X2") | ///
		inlist(`tempcode', "M43.8X3", "M43.8X4", "M43.8X5", "M43.8X6", "M43.8X7", "M43.8X8", "M43.8X9", "M47.012") | ///
		inlist(`tempcode', "M47.013", "M47.014", "M47.016", "M47.019", "M47.022", "M47.811", "M47.812", "M47.813") | ///
		inlist(`tempcode', "M47.814", "M47.815", "M47.816", "M47.817", "M47.818", "M47.819", "M47.892", "M47.893") | ///
		inlist(`tempcode', "M47.894", "M47.895", "M47.896", "M47.897", "M47.898", "M47.899", "M48.061", "M48.062") | ///
		inlist(`tempcode', "M48.8X2", "M48.8X3", "M48.8X4", "M48.8X5", "M48.8X6", "M48.8X7", "M48.8X9", "M50.020") | ///
		inlist(`tempcode', "M50.021", "M50.022", "M50.023", "M50.120", "M50.121", "M50.122", "M50.123", "M50.220") | ///
		inlist(`tempcode', "M50.221", "M50.222", "M50.223", "M50.320", "M50.321", "M50.322", "M50.323", "M50.821") | ///
		inlist(`tempcode', "M50.822", "M50.823", "M50.920", "M50.921", "M50.922", "M50.923", "M53.2X1", "M53.2X2") | ///
		inlist(`tempcode', "M53.2X3", "M53.2X4", "M53.2X5", "M53.2X6", "M53.2X7", "M53.2X8", "M53.2X9")

	*MUS014 - Pathological fracture, initial encounter
	quietly replace comp44 = 1 if ///
		inlist(`tempcode', "M8440XA", "M84412A", "M84419A", "M84421A", "M84422A", "M84429A", "M84431A", "M84432A") | ///
		inlist(`tempcode', "M84442A", "M84443A", "M84445A", "M84451A", "M84452A", "M84453A", "M84454A", "M84459A") | ///
		inlist(`tempcode', "M84461A", "M84462A", "M84463A", "M84469A", "M84471A", "M84472A", "M84474A", "M84475A") | ///
		inlist(`tempcode', "M84477A", "M84478A", "M8448XA", "M84511A", "M84521A", "M84522A", "M84531A", "M84534A") | ///
		inlist(`tempcode', "M84542A", "M84550A", "M84551A", "M84552A", "M84559A", "M84561A", "M84562A" "M84563A") | ///
		inlist(`tempcode', "M84574A", "M8458XA", "M84621A", "M84650A", "M84651A", "M84652A", "M84659A", "M84661A") | ///
		inlist(`tempcode', "M84662A", "M84671A", "M84672A", "M84674A", "M84675A", "M8468XA")
	quietly replace comp44 = 1 if ///
		inlist(`tempcode', "M84.40XA", "M84.412A", "M84.419A", "M84.421A", "M84.422A", "M84.429A", "M84.431A", "M84.432A") | ///
		inlist(`tempcode', "M84.442A", "M84.443A", "M84.445A", "M84.451A", "M84.452A", "M84.453A", "M84.454A", "M84.459A") | ///
		inlist(`tempcode', "M84.461A", "M84.462A", "M84.463A", "M84.469A", "M84.471A", "M84.472A", "M84.474A", "M84.475A") | ///
		inlist(`tempcode', "M84.477A", "M84.478A", "M84.48XA", "M84.511A", "M84.521A", "M84.522A", "M84.531A", "M84.534A") | ///
		inlist(`tempcode', "M84.542A", "M84.550A", "M84.551A", "M84.552A", "M84.559A", "M84.561A", "M84.562A" "M84.563A") | ///
		inlist(`tempcode', "M84.574A", "M84.58XA", "M84.621A", "M84.650A", "M84.651A", "M84.652A", "M84.659A", "M84.661A") | ///
		inlist(`tempcode', "M84.662A", "M84.671A", "M84.672A", "M84.674A", "M84.675A", "M84.68XA")

	*MUS022 - Scoliosis and other postural dorsopathic deformities
	quietly replace comp45 = 1 if ///
		inlist(`tempcode', "M419", "M429") | ///
		inlist(`tempcode', "M4000", "M4003", "M4004", "M4005", "M4010", "M4012", "M4013", "M4014") | ///
		inlist(`tempcode', "M4015", "M4030", "M4035", "M4036", "M4037", "M4040", "M4045", "M4046") | ///
		inlist(`tempcode', "M4047", "M4050", "M4055", "M4056", "M4057", "M4103", "M4104", "M4105") | ///
		inlist(`tempcode', "M4106", "M4120", "M4122", "M4123", "M4124", "M4125", "M4126", "M4127") | ///
		inlist(`tempcode', "M4130", "M4134", "M4135", "M4140", "M4142", "M4143", "M4144", "M4145") | ///
		inlist(`tempcode', "M4146", "M4147", "M4150", "M4152", "M4153", "M4154", "M4155", "M4156") | ///
		inlist(`tempcode', "M4157", "M4180", "M4182", "M4183", "M4184", "M4185", "M4186", "M4187") | ///
		inlist(`tempcode', "M4200", "M4202", "M4203", "M4204", "M4205", "M4206", "M4209", "M4212") | ///
		inlist(`tempcode', "M4216", "M4217") | ///
		inlist(`tempcode', "M40202", "M40203", "M40204", "M40205", "M40209", "M40292", "M40293", "M40294") | ///
		inlist(`tempcode', "M40295", "M40299", "M41113", "M41114", "M41115", "M41116", "M41119", "M41122") | ///
		inlist(`tempcode', "M41124", "M41125", "M41126", "M41127", "M41129")
	quietly replace comp45 = 1 if ///
		inlist(`tempcode', "M41.9", "M42.9") | ///
		inlist(`tempcode', "M40.00", "M40.03", "M40.04", "M40.05", "M40.10", "M40.12", "M40.13", "M40.14") | ///
		inlist(`tempcode', "M40.15", "M40.30", "M40.35", "M40.36", "M40.37", "M40.40", "M40.45", "M40.46") | ///
		inlist(`tempcode', "M40.47", "M40.50", "M40.55", "M40.56", "M40.57", "M41.03", "M41.04", "M41.05") | ///
		inlist(`tempcode', "M41.06", "M41.20", "M41.22", "M41.23", "M41.24", "M41.25", "M41.26", "M41.27") | ///
		inlist(`tempcode', "M41.30", "M41.34", "M41.35", "M41.40", "M41.42", "M41.43", "M41.44", "M41.45") | ///
		inlist(`tempcode', "M41.46", "M41.47", "M41.50", "M41.52", "M41.53", "M41.54", "M41.55", "M41.56") | ///
		inlist(`tempcode', "M41.57", "M41.80", "M41.82", "M41.83", "M41.84", "M41.85", "M41.86", "M41.87") | ///
		inlist(`tempcode', "M42.00", "M42.02", "M42.03", "M42.04", "M42.05", "M42.06", "M42.09", "M42.12") | ///
		inlist(`tempcode', "M42.16", "M42.17") | ///
		inlist(`tempcode', "M40.202", "M40.203", "M40.204", "M40.205", "M40.209", "M40.292", "M40.293", "M40.294") | ///
		inlist(`tempcode', "M40.295", "M40.299", "M41.113", "M41.114", "M41.115", "M41.116", "M41.119", "M41.122") | ///
		inlist(`tempcode', "M41.124", "M41.125", "M41.126", "M41.127", "M41.129")

	*MUS029 - Disorders of jaw
	quietly replace comp46 = 1 if ///
		inlist(`tempcode', "M264", "M269", "M270", "M271", "M272", "M273", "M278", "M279") | ///
		inlist(`tempcode', "M2602", "M2603", "M2604", "M2606", "M2609", "M2612", "M2619", "M2624") | ///
		inlist(`tempcode', "M2629", "M2630", "M2634", "M2650", "M2652", "M2669", "M2681", "M2689") | ///
		inlist(`tempcode', "M2740", "M2751", "M2769") | ///
		inlist(`tempcode', "M26212", "M26213", "M26220", "M26601", "M26602", "M26603", "M26609", "M26613") | ///
		inlist(`tempcode', "M26619", "M26621", "M26622", "M26623", "M26629", "M26632")
	quietly replace comp46 = 1 if ///
		inlist(`tempcode', "M26.4", "M26.9", "M27.0", "M27.1", "M27.2", "M27.3", "M27.8", "M27.9") | ///
		inlist(`tempcode', "M26.02", "M26.03", "M26.04", "M26.06", "M26.09", "M26.12", "M26.19", "M26.24") | ///
		inlist(`tempcode', "M26.29", "M26.30", "M26.34", "M26.50", "M26.52", "M26.69", "M26.81", "M26.89") | ///
		inlist(`tempcode', "M27.40", "M27.51", "M27.69") | ///
		inlist(`tempcode', "M26.212", "M26.213", "M26.220", "M26.601", "M26.602", "M26.603", "M26.609", "M26.613") | ///
		inlist(`tempcode', "M26.619", "M26.621", "M26.622", "M26.623", "M26.629", "M26.632")

	*MUS030 - Aseptic necrosis and osteonecrosis
	quietly replace comp47 = 1 if ///
		inlist(`tempcode', "M879") | ///
		inlist(`tempcode', "M8700", "M8708", "M8709", "M8728", "M8730", "M8738", "M8780", "M8788") | ///
		inlist(`tempcode', "M8789") | ///
		inlist(`tempcode', "M87012", "M87022", "M87050", "M87051", "M87052", "M87059", "M87061", "M87062") | ///
		inlist(`tempcode', "M87071", "M87072", "M87075", "M87078", "M87250", "M87251", "M87252", "M87261") | ///
		inlist(`tempcode', "M87271", "M87272", "M87277", "M87311", "M87319", "M87321", "M87350", "M87351") | ///
		inlist(`tempcode', "M87352", "M87361", "M87362", "M87372", "M87374", "M87375", "M87377", "M87378") | ///
		inlist(`tempcode', "M87811", "M87812", "M87821", "M87822", "M87850", "M87851", "M87852", "M87859") | ///
		inlist(`tempcode', "M87861", "M87862", "M87864", "M87865", "M87871", "M87872", "M87874", "M87875") | ///
		inlist(`tempcode', "M87878")
	quietly replace comp47 = 1 if ///
		inlist(`tempcode', "M87.9") | ///
		inlist(`tempcode', "M87.00", "M87.08", "M87.09", "M87.28", "M87.30", "M87.38", "M87.80", "M87.88") | ///
		inlist(`tempcode', "M87.89") | ///
		inlist(`tempcode', "M87.012", "M87.022", "M87.050", "M87.051", "M87.052", "M87.059", "M87.061", "M87.062") | ///
		inlist(`tempcode', "M87.071", "M87.072", "M87.075", "M87.078", "M87.250", "M87.251", "M87.252", "M87.261") | ///
		inlist(`tempcode', "M87.271", "M87.272", "M87.277", "M87.311", "M87.319", "M87.321", "M87.350", "M87.351") | ///
		inlist(`tempcode', "M87.352", "M87.361", "M87.362", "M87.372", "M87.374", "M87.375", "M87.377", "M87.378") | ///
		inlist(`tempcode', "M87.811", "M87.812", "M87.821", "M87.822", "M87.850", "M87.851", "M87.852", "M87.859") | ///
		inlist(`tempcode', "M87.861", "M87.862", "M87.864", "M87.865", "M87.871", "M87.872", "M87.874", "M87.875") | ///
		inlist(`tempcode', "M87.878")

*NEO CCSR
	display "		Coding NEO CCSR"
	*NEO002 - Head and neck cancers - lip and oral cavity
	quietly replace comp48 = 1 if ///
		inlist(`tempcode', "C01") | ///
		inlist(`tempcode', "C000", "C001", "C003", "C004", "C006", "C008", "C009", "C020") | ///
		inlist(`tempcode', "C021", "C022", "C023", "C024", "C028", "C029", "C030", "C031") | ///
		inlist(`tempcode', "C039", "C040", "C041", "C048", "C049", "C050", "C051", "C052") | ///
		inlist(`tempcode', "C058", "C059", "C060", "C061", "C062", "C069") | ///
		inlist(`tempcode', "C0680", "C0689", "D0000", "D0001", "D0002", "D0003", "D0004", "D0006") | ///
		inlist(`tempcode', "D0007")
	quietly replace comp48 = 1 if ///
		inlist(`tempcode', "C01") | ///
		inlist(`tempcode', "C00.0", "C00.1", "C00.3", "C00.4", "C00.6", "C00.8", "C00.9", "C02.0") | ///
		inlist(`tempcode', "C02.1", "C02.2", "C02.3", "C02.4", "C02.8", "C02.9", "C03.0", "C03.1") | ///
		inlist(`tempcode', "C03.9", "C04.0", "C04.1", "C04.8", "C04.9", "C05.0", "C05.1", "C05.2") | ///
		inlist(`tempcode', "C05.8", "C05.9", "C06.0", "C06.1", "C06.2", "C06.9") | ///
		inlist(`tempcode', "C06.80", "C06.89", "D00.00", "D00.01", "D00.02", "D00.03", "D00.04", "D00.06") | ///
		inlist(`tempcode', "D00.07")

	*NEO015 - Gastrointestinal cancers - colorectal
	quietly replace comp49 = 1 if ///
		inlist(`tempcode', "C19", "C20") | ///
		inlist(`tempcode', "C180", "C181", "C182", "C183", "C184", "C185", "C186", "C187") | ///
		inlist(`tempcode', "C188", "C189", "C260", "D010", "D011", "D012") | ///
		inlist(`tempcode', "C49A4", "C49A5")
	quietly replace comp49 = 1 if ///
		inlist(`tempcode', "C19", "C20") | ///
		inlist(`tempcode', "C18.0", "C18.1", "C18.2", "C18.3", "C18.4", "C18.5", "C18.6", "C18.7") | ///
		inlist(`tempcode', "C18.8", "C18.9", "C26.0", "D01.0", "D01.1", "D01.2") | ///
		inlist(`tempcode', "C49.A4", "C49.A5")

	*NEO022 - Respiratory cancers
	quietly replace comp50 = 1 if ///
		inlist(`tempcode', "C33") | ///
		inlist(`tempcode', "C342", "C384", "C390", "C399", "D021", "D023") | ///
		inlist(`tempcode', "C3400", "C3401", "C3402", "C3410", "C3411", "C3412", "C3430", "C3431") | ///
		inlist(`tempcode', "C3432", "C3480", "C3481", "C3482", "C3490", "C3491", "C3492", "D0220") | ///
		inlist(`tempcode', "D0221", "D0222")
	quietly replace comp50 = 1 if ///
		inlist(`tempcode', "C33") | ///
		inlist(`tempcode', "C34.2", "C38.4", "C39.0", "C39.9", "D02.1", "D02.3") | ///
		inlist(`tempcode', "C34.00", "C34.01", "C34.02", "C34.10", "C34.11", "C34.12", "C34.30", "C34.31") | ///
		inlist(`tempcode', "C34.32", "C34.80", "C34.81", "C34.82", "C34.90", "C34.91", "C34.92", "D02.20") | ///
		inlist(`tempcode', "D02.21", "D02.22")

	*NEO039 - Male reproductive system cancers - prostate
	quietly replace comp51 = 1 if ///
		inlist(`tempcode', "C61", "D075", "D07.5")

	*NEO043 - Urinary system cancers - bladder
	quietly replace comp52 = 1 if ///
		inlist(`tempcode', "C670", "C671", "C672", "C673", "C674", "C675", "C676", "C677") | ///
		inlist(`tempcode', "C678", "C679", "D090")
	quietly replace comp52 = 1 if ///
		inlist(`tempcode', "C67.0", "C67.1", "C67.2", "C67.3", "C67.4", "C67.5", "C67.6", "C67.7") | ///
		inlist(`tempcode', "C67.8", "C67.9", "D09.0")

	*NEO045 - Urinary system cancers - kidney
	quietly replace comp53 = 1 if ///
		inlist(`tempcode', "C641", "C642", "C649")
	quietly replace comp53 = 1 if ///
		inlist(`tempcode', "C64.1", "C64.2", "C64.9")

	*NEO051 - Endocrine system cancers - pancreas
	quietly replace comp54 = 1 if ///
		inlist(`tempcode', "C250", "C251", "C252", "C253", "C254", "C257", "C258", "C259")
	quietly replace comp54 = 1 if ///
		inlist(`tempcode', "C25.0", "C25.1", "C25.2", "C25.3", "C25.4", "C25.7", "C25.8", "C25.9")

	*NEO070 - Secondary malignancies
	quietly replace comp55 = 1 if ///
		inlist(`tempcode', "C770", "C771", "C772", "C773", "C774", "C775", "C778", "C779") | ///
		inlist(`tempcode', "C781", "C782", "C784", "C785", "C786", "C787", "C792", "C799") | ///
		inlist(`tempcode', "C7800", "C7801", "C7802", "C7839", "C7880", "C7889", "C7900", "C7901") | ///
		inlist(`tempcode', "C7902", "C7910", "C7911", "C7919", "C7931", "C7932", "C7940", "C7949") | ///
		inlist(`tempcode', "C7951", "C7952", "C7960", "C7961", "C7962", "C7970", "C7971", "C7972") | ///
		inlist(`tempcode', "C7981", "C7982", "C7989")
	quietly replace comp55 = 1 if ///
		inlist(`tempcode', "C77.0", "C77.1", "C77.2", "C77.3", "C77.4", "C77.5", "C77.8", "C77.9") | ///
		inlist(`tempcode', "C78.1", "C78.2", "C78.4", "C78.5", "C78.6", "C78.7", "C79.2", "C79.9") | ///
		inlist(`tempcode', "C78.00", "C78.01", "C78.02", "C78.39", "C78.80", "C78.89", "C79.00", "C79.01") | ///
		inlist(`tempcode', "C79.02", "C79.10", "C79.11", "C79.19", "C79.31", "C79.32", "C79.40", "C79.49") | ///
		inlist(`tempcode', "C79.51", "C79.52", "C79.60", "C79.61", "C79.62", "C79.70", "C79.71", "C79.72") | ///
		inlist(`tempcode', "C79.81", "C79.82", "C79.89")

	*NEO073 - Benign neoplasms
	quietly replace comp56 = 1 if ///
		inlist(`tempcode', "D34") | ///
		inlist(`tempcode', "D100", "D101", "D102", "D104", "D105", "D106", "D107", "D109") | ///
		inlist(`tempcode', "D110", "D117", "D119", "D120", "D121", "D122", "D123", "D124") | ///
		inlist(`tempcode', "D125", "D126", "D127", "D128", "D129", "D130", "D131", "D132") | ///
		inlist(`tempcode', "D134", "D135", "D136", "D137", "D139", "D140", "D141", "D142") | ///
		inlist(`tempcode', "D144", "D150", "D151", "D152", "D159", "D164", "D165", "D166") | ///
		inlist(`tempcode', "D168", "D169", "D170", "D171", "D174", "D175", "D176", "D179") | ///
		inlist(`tempcode', "D181", "D190", "D191", "D197", "D199", "D200", "D201", "D210") | ///
		inlist(`tempcode', "D213", "D214", "D215", "D216", "D219", "D224", "D225", "D229") | ///
		inlist(`tempcode', "D234", "D235", "D239", "D241", "D242", "D249", "D250", "D251") | ///
		inlist(`tempcode', "D252", "D259", "D260", "D261", "D267", "D269", "D270", "D271") | ///
		inlist(`tempcode', "D279", "D280", "D281", "D282", "D287", "D291", "D294", "D298") | ///
		inlist(`tempcode', "D303", "D308", "D320", "D321", "D329", "D330", "D331", "D332") | ///
		inlist(`tempcode', "D333", "D334", "D337", "D339", "D351", "D352", "D353", "D354") | ///
		inlist(`tempcode', "D355", "D360", "D367", "D369", "D3A8", "K317", "K635") | ///
		inlist(`tempcode', "D1030", "D1039", "D1330", "D1339", "D1430", "D1431", "D1432", "D1601") | ///
		inlist(`tempcode', "D1602", "D1620", "D1621", "D1622", "D1631", "D1720", "D1721", "D1722") | ///
		inlist(`tempcode', "D1723", "D1724", "D1730", "D1739", "D1771", "D1772", "D1779", "D1800") | ///
		inlist(`tempcode', "D1801", "D1802", "D1803", "D1809", "D2111", "D2121", "D2122", "D2221") | ///
		inlist(`tempcode', "D2230", "D2239", "D2260", "D2270", "D2271", "D2272", "D2339", "D2371") | ///
		inlist(`tempcode', "D2372", "D3000", "D3001", "D3002", "D3011", "D3012", "D3020", "D3100") | ///
		inlist(`tempcode', "D3101", "D3102", "D3130", "D3131", "D3132", "D3500", "D3501", "D3502") | ///
		inlist(`tempcode', "D3610", "D3611", "D3612", "D3613", "D3614", "D3615", "D3616", "D3617") | ///
		inlist(`tempcode', "D3A00") | ///
		inlist(`tempcode', "D3A010", "D3A011", "D3A012", "D3A019", "D3A020", "D3A021", "D3A022", "D3A025") | ///
		inlist(`tempcode', "D3A026", "D3A029", "D3A090", "D3A092", "D3A093", "D3A096", "D3A098")
	quietly replace comp56 = 1 if ///
		inlist(`tempcode', "D34") | ///
		inlist(`tempcode', "D10.0", "D10.1", "D10.2", "D10.4", "D10.5", "D10.6", "D10.7", "D10.9") | ///
		inlist(`tempcode', "D11.0", "D11.7", "D11.9", "D12.0", "D12.1", "D12.2", "D12.3", "D12.4") | ///
		inlist(`tempcode', "D12.5", "D12.6", "D12.7", "D12.8", "D12.9", "D13.0", "D13.1", "D13.2") | ///
		inlist(`tempcode', "D13.4", "D13.5", "D13.6", "D13.7", "D13.9", "D14.0", "D14.1", "D14.2") | ///
		inlist(`tempcode', "D14.4", "D15.0", "D15.1", "D15.2", "D15.9", "D16.4", "D16.5", "D16.6") | ///
		inlist(`tempcode', "D16.8", "D16.9", "D17.0", "D17.1", "D17.4", "D17.5", "D17.6", "D17.9") | ///
		inlist(`tempcode', "D18.1", "D19.0", "D19.1", "D19.7", "D19.9", "D20.0", "D20.1", "D21.0") | ///
		inlist(`tempcode', "D21.3", "D21.4", "D21.5", "D21.6", "D21.9", "D22.4", "D22.5", "D22.9") | ///
		inlist(`tempcode', "D23.4", "D23.5", "D23.9", "D24.1", "D24.2", "D24.9", "D25.0", "D25.1") | ///
		inlist(`tempcode', "D25.2", "D25.9", "D26.0", "D26.1", "D26.7", "D26.9", "D27.0", "D27.1") | ///
		inlist(`tempcode', "D27.9", "D28.0", "D28.1", "D28.2", "D28.7", "D29.1", "D29.4", "D29.8") | ///
		inlist(`tempcode', "D30.3", "D30.8", "D32.0", "D32.1", "D32.9", "D33.0", "D33.1", "D33.2") | ///
		inlist(`tempcode', "D33.3", "D33.4", "D33.7", "D33.9", "D35.1", "D35.2", "D35.3", "D35.4") | ///
		inlist(`tempcode', "D35.5", "D36.0", "D36.7", "D36.9", "D3A.8", "K31.7", "K63.5") | ///
		inlist(`tempcode', "D10.30", "D10.39", "D13.30", "D13.39", "D14.30", "D14.31", "D14.32", "D16.01") | ///
		inlist(`tempcode', "D16.02", "D16.20", "D16.21", "D16.22", "D16.31", "D17.20", "D17.21", "D17.22") | ///
		inlist(`tempcode', "D17.23", "D17.24", "D17.30", "D17.39", "D17.71", "D17.72", "D17.79", "D18.00") | ///
		inlist(`tempcode', "D18.01", "D18.02", "D18.03", "D18.09", "D21.11", "D21.21", "D21.22", "D22.21") | ///
		inlist(`tempcode', "D22.30", "D22.39", "D22.60", "D22.70", "D22.71", "D22.72", "D23.39", "D23.71") | ///
		inlist(`tempcode', "D23.72", "D30.00", "D30.01", "D30.02", "D30.11", "D30.12", "D30.20", "D31.00") | ///
		inlist(`tempcode', "D31.01", "D31.02", "D31.30", "D31.31", "D31.32", "D35.00", "D35.01", "D35.02") | ///
		inlist(`tempcode', "D36.10", "D36.11", "D36.12", "D36.13", "D36.14", "D36.15", "D36.16", "D36.17") | ///
		inlist(`tempcode', "D3A.00") | ///
		inlist(`tempcode', "D3A.010", "D3A.011", "D3A.012", "D3A.019", "D3A.020", "D3A.021", "D3A.022", "D3A.025") | ///
		inlist(`tempcode', "D3A.026", "D3A.029", "D3A.090", "D3A.092", "D3A.093", "D3A.096", "D3A.098")

	*NEO074 - Conditions due to neoplasm or the treatment of neoplasm
	quietly replace comp57 = 1 if ///
		inlist(`tempcode', "D701", "E883", "G893", "R530") | ///
		inlist(`tempcode', "D6481", "H4742", "K1231", "N5236") | ///
		inlist(`tempcode', "D61810")
	quietly replace comp57 = 1 if ///
		inlist(`tempcode', "D70.1", "E88.3", "G89.3", "R53.0") | ///
		inlist(`tempcode', "D64.81", "H47.42", "K12.31", "N52.36") | ///
		inlist(`tempcode', "D61.810")
	
*NVS CCSR
	display "		Coding NVS CCSR"
	*NVS008 - Paralysis (other than cerebral palsy
	quietly replace comp58 = 1 if ///
		inlist(`tempcode', "G041", "G830", "G834", "G835", "G839") | ///
		inlist(`tempcode', "G8100", "G8101", "G8103", "G8104", "G8110", "G8111", "G8114", "G8190") | ///
		inlist(`tempcode', "G8191", "G8192", "G8193", "G8194", "G8220", "G8221", "G8222", "G8250") | ///
		inlist(`tempcode', "G8251", "G8252", "G8253", "G8254", "G8310", "G8311", "G8312", "G8313") | ///
		inlist(`tempcode', "G8314", "G8320", "G8321", "G8322", "G8323", "G8324", "G8330", "G8331") | ///
		inlist(`tempcode', "G8334", "G8381", "G8382", "G8383", "G8384", "G8389")
	quietly replace comp58 = 1 if ///
		inlist(`tempcode', "G04.1", "G83.0", "G83.4", "G83.5", "G83.9") | ///
		inlist(`tempcode', "G81.00", "G81.01", "G81.03", "G81.04", "G81.10", "G81.11", "G81.14", "G81.90") | ///
		inlist(`tempcode', "G81.91", "G81.92", "G81.93", "G81.94", "G82.20", "G82.21", "G82.22", "G82.50") | ///
		inlist(`tempcode', "G82.51", "G82.52", "G82.53", "G82.54", "G83.10", "G83.11", "G83.12", "G83.13") | ///
		inlist(`tempcode', "G83.14", "G83.20", "G83.21", "G83.22", "G83.23", "G83.24", "G83.30", "G83.31") | ///
		inlist(`tempcode', "G83.34", "G83.81", "G83.82", "G83.83", "G83.84", "G83.89")

	*NVS011 - Neurocognitive disorders
	quietly replace comp59 = 1 if ///
		inlist(`tempcode', "F04", "F05") | ///
		inlist(`tempcode', "F482", "G300", "G301", "G308", "G309", "G311", "G319") | ///
		inlist(`tempcode', "F0150", "F0151", "F0390", "F0391", "F0781", "G3101", "G3109", "G3183") | ///
		inlist(`tempcode', "G3184")
	quietly replace comp59 = 1 if ///
		inlist(`tempcode', "F04", "F05") | ///
		inlist(`tempcode', "F48.2", "G30.0", "G30.1", "G30.8", "G30.9", "G31.1", "G31.9") | ///
		inlist(`tempcode', "F01.50", "F01.51", "F03.90", "F03.91", "F07.81", "G31.01", "G31.09", "G31.83") | ///
		inlist(`tempcode', "G31.84")

	*NVS014 - CNS abscess
	quietly replace comp60 = 1 if ///
		inlist(`tempcode', "B431", "G060", "G061", "G062")
	quietly replace comp60 = 1 if ///
		inlist(`tempcode', "B43.1", "G06.0", "G06.1", "G06.2")

	*NVS016 - Sleep wake disorders
	quietly replace comp61 = 1 if ///
		inlist(`tempcode', "F513", "F514", "F515", "F518", "F519", "G478", "G479", "R063") | ///
		inlist(`tempcode', "F5101", "F5102", "F5103", "F5104", "F5105", "F5109", "F5111", "F5112") | ///
		inlist(`tempcode', "G2581", "G4700", "G4701", "G4709", "G4710", "G4711", "G4712", "G4713") | ///
		inlist(`tempcode', "G4714", "G4719", "G4720", "G4721", "G4722", "G4723", "G4725", "G4726") | ///
		inlist(`tempcode', "G4729", "G4730", "G4731", "G4733", "G4734", "G4735", "G4739", "G4750") | ///
		inlist(`tempcode', "G4751", "G4752", "G4753", "G4759", "G4761", "G4762", "G4763", "G4769") | ///
		inlist(`tempcode', "G47411", "G47419")
	quietly replace comp61 = 1 if ///
		inlist(`tempcode', "F51.3", "F51.4", "F51.5", "F51.8", "F51.9", "G47.8", "G47.9", "R06.3") | ///
		inlist(`tempcode', "F51.01", "F51.02", "F51.03", "F51.04", "F51.05", "F51.09", "F51.11", "F51.12") | ///
		inlist(`tempcode', "G25.81", "G47.00", "G47.01", "G47.09", "G47.10", "G47.11", "G47.12", "G47.13") | ///
		inlist(`tempcode', "G47.14", "G47.19", "G47.20", "G47.21", "G47.22", "G47.23", "G47.25", "G47.26") | ///
		inlist(`tempcode', "G47.29", "G47.30", "G47.31", "G47.33", "G47.34", "G47.35", "G47.39", "G47.50") | ///
		inlist(`tempcode', "G47.51", "G47.52", "G47.53", "G47.59", "G47.61", "G47.62", "G47.63", "G47.69") | ///
		inlist(`tempcode', "G47.411", "G47.419")

	*NVS020 - Other nervous system disorders (neither hereditary nor degenerative
	quietly replace comp62 = 1 if ///
		inlist(`tempcode', "G08", "G64", "G92") | ///
		inlist(`tempcode', "G360", "G371", "G372", "G378", "G379", "G460", "G462", "G463") | ///
		inlist(`tempcode', "G464", "G465", "G466", "G467", "G908", "G909", "G910", "G911") | ///
		inlist(`tempcode', "G912", "G913", "G918", "G919", "G930", "G932", "G933", "G935") | ///
		inlist(`tempcode', "G936", "G939", "G950", "G959", "G960", "G968", "G969", "G988") | ///
		inlist(`tempcode', "G9340", "G9341", "G9349", "G9381", "G9382", "G9389", "G9519", "G9520") | ///
		inlist(`tempcode', "G9529", "G9581", "G9589", "G9611", "G9612", "G9619")
	quietly replace comp62 = 1 if ///
		inlist(`tempcode', "G36.0", "G37.1", "G37.2", "G37.8", "G37.9", "G46.0", "G46.2", "G46.3") | ///
		inlist(`tempcode', "G46.4", "G46.5", "G46.6", "G46.7", "G90.8", "G90.9", "G91.0", "G91.1") | ///
		inlist(`tempcode', "G91.2", "G91.3", "G91.8", "G91.9", "G93.0", "G93.2", "G93.3", "G93.5") | ///
		inlist(`tempcode', "G93.6", "G93.9", "G95.0", "G95.9", "G96.0", "G96.8", "G96.9", "G98.8") | ///
		inlist(`tempcode', "G93.40", "G93.41", "G93.49", "G93.81", "G93.82", "G93.89", "G95.19", "G95.20") | ///
		inlist(`tempcode', "G95.29", "G95.81", "G95.89", "G96.11", "G96.12", "G96.19")
	
*RSP CCSR
	display "		Coding RSP CCSR"
	*RSP002 - Pneumonia (except that caused by tuberculosis
	quietly replace comp63 = 1 if ///
		inlist(`tempcode', "B59", "J13", "J14") | ///
		inlist(`tempcode', "A310", "A430", "A481", "B012", "B250", "B371", "B381", "B382") | ///
		inlist(`tempcode', "B391", "B392", "J120", "J121", "J122", "J123", "J129", "J150") | ///
		inlist(`tempcode', "J151", "J153", "J154", "J155", "J156", "J157", "J158", "J159") | ///
		inlist(`tempcode', "J160", "J168", "J180", "J181", "J188", "J189", "J851") | ///
		inlist(`tempcode', "J1281", "J1289", "J1520", "J1529") | ///
		inlist(`tempcode', "J15211", "J15212")
	quietly replace comp63 = 1 if ///
		inlist(`tempcode', "B59", "J13", "J14") | ///
		inlist(`tempcode', "A31.0", "A43.0", "A48.1", "B01.2", "B25.0", "B37.1", "B38.1", "B38.2") | ///
		inlist(`tempcode', "B39.1", "B39.2", "J12.0", "J12.1", "J12.2", "J12.3", "J12.9", "J15.0") | ///
		inlist(`tempcode', "J15.1", "J15.3", "J15.4", "J15.5", "J15.6", "J15.7", "J15.8", "J15.9") | ///
		inlist(`tempcode', "J16.0", "J16.8", "J18.0", "J18.1", "J18.8", "J18.9", "J85.1") | ///
		inlist(`tempcode', "J12.81", "J12.89", "J15.20", "J15.29") | ///
		inlist(`tempcode', "J15.211", "J15.212")

	*RSP010 - Aspiration pneumonitis
	quietly replace comp64 = 1 if ///
		inlist(`tempcode', "J690", "J691", "J698")
	quietly replace comp64 = 1 if ///
		inlist(`tempcode', "J69.0", "J69.1", "J69.8")

	*RSP012 - Respiratory failure; insufficiency; arrest
	quietly replace comp65 = 1 if ///
		inlist(`tempcode', "R092") | ///
		inlist(`tempcode', "J9610", "J9611", "J9612", "J9620", "J9621", "J9622", "J9690", "J9691") | ///
		inlist(`tempcode', "J9692")
	quietly replace comp65 = 1 if ///
		inlist(`tempcode', "R09.2") | ///
		inlist(`tempcode', "J96.10", "J96.11", "J96.12", "J96.20", "J96.21", "J96.22", "J96.90", "J96.91") | ///
		inlist(`tempcode', "J96.92")

	*RSP014 - Pneumothorax
	quietly replace comp66 = 1 if ///
		inlist(`tempcode', "J930", "J939") | ///
		inlist(`tempcode', "J9311", "J9381", "J9382", "J9383")
	quietly replace comp66 = 1 if ///
		inlist(`tempcode', "J93.0", "J93.9") | ///
		inlist(`tempcode', "J93.11", "J93.81", "J93.82", "J93.83")
	
*SKN CCSR
	display "		Coding SKN CCSR"
	*SKN001 - Skin and subcutaneous tissue infections
	quietly replace comp67 = 1 if ///
		inlist(`tempcode', "A46", "L00") | ///
		inlist(`tempcode', "A311", "A363", "A431", "L011", "L080", "L089", "L303") | ///
		inlist(`tempcode', "L0100", "L0101", "L0201", "L0202", "L0211", "L0231", "L0232", "L0233") | ///
		inlist(`tempcode', "L0291", "L0292", "L0293", "L0390", "L0501", "L0591", "L0592", "L0882") | ///
		inlist(`tempcode', "L0889") | ///
		inlist(`tempcode', "L02211", "L02212", "L02213", "L02214", "L02215", "L02216", "L02219", "L02221") | ///
		inlist(`tempcode', "L02222", "L02224", "L02231", "L02232", "L02411", "L02412", "L02413", "L02414") | ///
		inlist(`tempcode', "L02415", "L02416", "L02419", "L02421", "L02422", "L02423", "L02424", "L02425") | ///
		inlist(`tempcode', "L02426", "L02429", "L02435", "L02436", "L02439", "L02511", "L02512", "L02519") | ///
		inlist(`tempcode', "L02521", "L02611", "L02612", "L02619", "L02622", "L02811", "L02818", "L02821") | ///
		inlist(`tempcode', "L02828", "L02831", "L02838", "L03011", "L03012", "L03019", "L03031", "L03032") | ///
		inlist(`tempcode', "L03039", "L03111", "L03112", "L03113", "L03114", "L03115", "L03116", "L03119") | ///
		inlist(`tempcode', "L03211", "L03213", "L03221", "L03311", "L03312", "L03313", "L03314", "L03315") | ///
		inlist(`tempcode', "L03316", "L03317", "L03319", "L03811", "L03818")
	quietly replace comp67 = 1 if ///
		inlist(`tempcode', "A46", "L00") | ///
		inlist(`tempcode', "A31.1", "A36.3", "A43.1", "L01.1", "L08.0", "L08.9", "L30.3") | ///
		inlist(`tempcode', "L01.00", "L01.01", "L02.01", "L02.02", "L02.11", "L02.31", "L02.32", "L02.33") | ///
		inlist(`tempcode', "L02.91", "L02.92", "L02.93", "L03.90", "L05.01", "L05.91", "L05.92", "L08.82") | ///
		inlist(`tempcode', "L08.89") | ///
		inlist(`tempcode', "L02.211", "L02.212", "L02.213", "L02.214", "L02.215", "L02.216", "L02.219", "L02.221") | ///
		inlist(`tempcode', "L02.222", "L02.224", "L02.231", "L02.232", "L02.411", "L02.412", "L02.413", "L02.414") | ///
		inlist(`tempcode', "L02.415", "L02.416", "L02.419", "L02.421", "L02.422", "L02.423", "L02.424", "L02.425") | ///
		inlist(`tempcode', "L02.426", "L02.429", "L02.435", "L02.436", "L02.439", "L02.511", "L02.512", "L02.519") | ///
		inlist(`tempcode', "L02.521", "L02.611", "L02.612", "L02.619", "L02.622", "L02.811", "L02.818", "L02.821") | ///
		inlist(`tempcode', "L02.828", "L02.831", "L02.838", "L03.011", "L03.012", "L03.019", "L03.031", "L03.032") | ///
		inlist(`tempcode', "L03.039", "L03.111", "L03.112", "L03.113", "L03.114", "L03.115", "L03.116", "L03.119") | ///
		inlist(`tempcode', "L03.211", "L03.213", "L03.221", "L03.311", "L03.312", "L03.313", "L03.314", "L03.315") | ///
		inlist(`tempcode', "L03.316", "L03.317", "L03.319", "L03.811", "L03.818")

	*SKN003 - Pressure ulcer of skin
	quietly replace comp68 = 1 if ///
		inlist(`tempcode', "L8940", "L8941", "L8942", "L8943", "L8944", "L8945", "L8946", "L8990") | ///
		inlist(`tempcode', "L8991", "L8992", "L8993", "L8994", "L8995") | ///
		inlist(`tempcode', "L89000", "L89003", "L89009", "L89010", "L89011", "L89012", "L89013", "L89014") | ///
		inlist(`tempcode', "L89019", "L89020", "L89021", "L89022", "L89023", "L89024", "L89029", "L89100") | ///
		inlist(`tempcode', "L89101", "L89102", "L89103", "L89104", "L89106", "L89109", "L89110", "L89111") | ///
		inlist(`tempcode', "L89112", "L89113", "L89114", "L89116", "L89119", "L89120", "L89121", "L89122") | ///
		inlist(`tempcode', "L89123", "L89124", "L89126", "L89129", "L89130", "L89131", "L89132", "L89133") | ///
		inlist(`tempcode', "L89134", "L89139", "L89140", "L89142", "L89143", "L89144", "L89149", "L89150") | ///
		inlist(`tempcode', "L89151", "L89152", "L89153", "L89154", "L89156", "L89159", "L89203", "L89204") | ///
		inlist(`tempcode', "L89209", "L89210", "L89211", "L89212", "L89213", "L89214", "L89216", "L89219") | ///
		inlist(`tempcode', "L89220", "L89221", "L89222", "L89223", "L89224", "L89226", "L89229", "L89300") | ///
		inlist(`tempcode', "L89301", "L89302", "L89303", "L89304", "L89309", "L89310", "L89311", "L89312") | ///
		inlist(`tempcode', "L89313", "L89314", "L89316", "L89319", "L89320", "L89321", "L89322", "L89323") | ///
		inlist(`tempcode', "L89324", "L89326", "L89329", "L89500", "L89504", "L89509", "L89510", "L89511") | ///
		inlist(`tempcode', "L89512", "L89513", "L89514", "L89516", "L89519", "L89520", "L89521", "L89522") | ///
		inlist(`tempcode', "L89523", "L89524", "L89529", "L89600", "L89601", "L89602", "L89603", "L89606") | ///
		inlist(`tempcode', "L89609", "L89610", "L89611", "L89612", "L89613", "L89614", "L89616", "L89619") | ///
		inlist(`tempcode', "L89620", "L89621", "L89622", "L89623", "L89624", "L89626", "L89629", "L89810") | ///
		inlist(`tempcode', "L89811", "L89812", "L89813", "L89814", "L89816", "L89819", "L89890", "L89891") | ///
		inlist(`tempcode', "L89892", "L89893", "L89894", "L89896", "L89899")
	quietly replace comp68 = 1 if ///
		inlist(`tempcode', "L89.40", "L89.41", "L89.42", "L89.43", "L89.44", "L89.45", "L89.46", "L89.90") | ///
		inlist(`tempcode', "L89.91", "L89.92", "L89.93", "L89.94", "L89.95") | ///
		inlist(`tempcode', "L89.000", "L89.003", "L89.009", "L89.010", "L89.011", "L89.012", "L89.013", "L89.014") | ///
		inlist(`tempcode', "L89.019", "L89.020", "L89.021", "L89.022", "L89.023", "L89.024", "L89.029", "L89.100") | ///
		inlist(`tempcode', "L89.101", "L89.102", "L89.103", "L89.104", "L89.106", "L89.109", "L89.110", "L89.111") | ///
		inlist(`tempcode', "L89.112", "L89.113", "L89.114", "L89.116", "L89.119", "L89.120", "L89.121", "L89.122") | ///
		inlist(`tempcode', "L89.123", "L89.124", "L89.126", "L89.129", "L89.130", "L89.131", "L89.132", "L89.133") | ///
		inlist(`tempcode', "L89.134", "L89.139", "L89.140", "L89.142", "L89.143", "L89.144", "L89.149", "L89.150") | ///
		inlist(`tempcode', "L89.151", "L89.152", "L89.153", "L89.154", "L89.156", "L89.159", "L89.203", "L89.204") | ///
		inlist(`tempcode', "L89.209", "L89.210", "L89.211", "L89.212", "L89.213", "L89.214", "L89.216", "L89.219") | ///
		inlist(`tempcode', "L89.220", "L89.221", "L89.222", "L89.223", "L89.224", "L89.226", "L89.229", "L89.300") | ///
		inlist(`tempcode', "L89.301", "L89.302", "L89.303", "L89.304", "L89.309", "L89.310", "L89.311", "L89.312") | ///
		inlist(`tempcode', "L89.313", "L89.314", "L89.316", "L89.319", "L89.320", "L89.321", "L89.322", "L89.323") | ///
		inlist(`tempcode', "L89.324", "L89.326", "L89.329", "L89.500", "L89.504", "L89.509", "L89.510", "L89.511") | ///
		inlist(`tempcode', "L89.512", "L89.513", "L89.514", "L89.516", "L89.519", "L89.520", "L89.521", "L89.522") | ///
		inlist(`tempcode', "L89.523", "L89.524", "L89.529", "L89.600", "L89.601", "L89.602", "L89.603", "L89.606") | ///
		inlist(`tempcode', "L89.609", "L89.610", "L89.611", "L89.612", "L89.613", "L89.614", "L89.616", "L89.619") | ///
		inlist(`tempcode', "L89.620", "L89.621", "L89.622", "L89.623", "L89.624", "L89.626", "L89.629", "L89.810") | ///
		inlist(`tempcode', "L89.811", "L89.812", "L89.813", "L89.814", "L89.816", "L89.819", "L89.890", "L89.891") | ///
		inlist(`tempcode', "L89.892", "L89.893", "L89.894", "L89.896", "L89.899")

	*SKN004 - Non-pressure ulcer of skin
	quietly replace comp69 = 1 if ///
		inlist(`tempcode', "L97101", "L97109", "L97111", "L97112", "L97113", "L97114", "L97116", "L97118") | ///
		inlist(`tempcode', "L97119", "L97121", "L97122", "L97123", "L97124", "L97126", "L97128", "L97129") | ///
		inlist(`tempcode', "L97201", "L97209", "L97211", "L97212", "L97213", "L97214", "L97215", "L97216") | ///
		inlist(`tempcode', "L97218", "L97219", "L97221", "L97222", "L97223", "L97224", "L97225", "L97226") | ///
		inlist(`tempcode', "L97228", "L97229", "L97301", "L97302", "L97309", "L97311", "L97312", "L97313") | ///
		inlist(`tempcode', "L97314", "L97315", "L97316", "L97318", "L97319", "L97321", "L97322", "L97323") | ///
		inlist(`tempcode', "L97324", "L97325", "L97326", "L97328", "L97329", "L97401", "L97402", "L97403") | ///
		inlist(`tempcode', "L97404", "L97405", "L97406", "L97408", "L97409", "L97411", "L97412", "L97413") | ///
		inlist(`tempcode', "L97414", "L97415", "L97416", "L97418", "L97419", "L97421", "L97422", "L97423") | ///
		inlist(`tempcode', "L97424", "L97425", "L97426", "L97428", "L97429", "L97501", "L97502", "L97503") | ///
		inlist(`tempcode', "L97504", "L97506", "L97508", "L97509", "L97511", "L97512", "L97513", "L97514") | ///
		inlist(`tempcode', "L97515", "L97516", "L97518", "L97519", "L97521", "L97522", "L97523", "L97524") | ///
		inlist(`tempcode', "L97525", "L97526", "L97528", "L97529", "L97802", "L97806", "L97809", "L97811") | ///
		inlist(`tempcode', "L97812", "L97813", "L97814", "L97815", "L97816", "L97818", "L97819", "L97821") | ///
		inlist(`tempcode', "L97822", "L97823", "L97824", "L97825", "L97826", "L97828", "L97829", "L97901") | ///
		inlist(`tempcode', "L97903", "L97904", "L97908", "L97909", "L97911", "L97912", "L97913", "L97914") | ///
		inlist(`tempcode', "L97916", "L97918", "L97919", "L97921", "L97922", "L97923", "L97924", "L97925") | ///
		inlist(`tempcode', "L97926", "L97928", "L97929", "L98411", "L98412", "L98415", "L98418", "L98419") | ///
		inlist(`tempcode', "L98421", "L98428", "L98429", "L98491", "L98492", "L98493", "L98494", "L98495") | ///
		inlist(`tempcode', "L98496", "L98498", "L98499")
	quietly replace comp69 = 1 if ///
		inlist(`tempcode', "L97.101", "L97.109", "L97.111", "L97.112", "L97.113", "L97.114", "L97.116", "L97.118") | ///
		inlist(`tempcode', "L97.119", "L97.121", "L97.122", "L97.123", "L97.124", "L97.126", "L97.128", "L97.129") | ///
		inlist(`tempcode', "L97.201", "L97.209", "L97.211", "L97.212", "L97.213", "L97.214", "L97.215", "L97.216") | ///
		inlist(`tempcode', "L97.218", "L97.219", "L97.221", "L97.222", "L97.223", "L97.224", "L97.225", "L97.226") | ///
		inlist(`tempcode', "L97.228", "L97.229", "L97.301", "L97.302", "L97.309", "L97.311", "L97.312", "L97.313") | ///
		inlist(`tempcode', "L97.314", "L97.315", "L97.316", "L97.318", "L97.319", "L97.321", "L97.322", "L97.323") | ///
		inlist(`tempcode', "L97.324", "L97.325", "L97.326", "L97.328", "L97.329", "L97.401", "L97.402", "L97.403") | ///
		inlist(`tempcode', "L97.404", "L97.405", "L97.406", "L97.408", "L97.409", "L97.411", "L97.412", "L97.413") | ///
		inlist(`tempcode', "L97.414", "L97.415", "L97.416", "L97.418", "L97.419", "L97.421", "L97.422", "L97.423") | ///
		inlist(`tempcode', "L97.424", "L97.425", "L97.426", "L97.428", "L97.429", "L97.501", "L97.502", "L97.503") | ///
		inlist(`tempcode', "L97.504", "L97.506", "L97.508", "L97.509", "L97.511", "L97.512", "L97.513", "L97.514") | ///
		inlist(`tempcode', "L97.515", "L97.516", "L97.518", "L97.519", "L97.521", "L97.522", "L97.523", "L97.524") | ///
		inlist(`tempcode', "L97.525", "L97.526", "L97.528", "L97.529", "L97.802", "L97.806", "L97.809", "L97.811") | ///
		inlist(`tempcode', "L97.812", "L97.813", "L97.814", "L97.815", "L97.816", "L97.818", "L97.819", "L97.821") | ///
		inlist(`tempcode', "L97.822", "L97.823", "L97.824", "L97.825", "L97.826", "L97.828", "L97.829", "L97.901") | ///
		inlist(`tempcode', "L97.903", "L97.904", "L97.908", "L97.909", "L97.911", "L97.912", "L97.913", "L97.914") | ///
		inlist(`tempcode', "L97.916", "L97.918", "L97.919", "L97.921", "L97.922", "L97.923", "L97.924", "L97.925") | ///
		inlist(`tempcode', "L97.926", "L97.928", "L97.929", "L98.411", "L98.412", "L98.415", "L98.418", "L98.419") | ///
		inlist(`tempcode', "L98.421", "L98.428", "L98.429", "L98.491", "L98.492", "L98.493", "L98.494", "L98.495") | ///
		inlist(`tempcode', "L98.496", "L98.498", "L98.499")

	local ord=`ord'+1
}

*SUM THE FREQUENCIES of COMORBIDITIES over multiple patient records for each comorbidity group
*Each comp will be 0 or 1, indicating absence or presence of comorbidity
*If multiple patient records, i.e. idvar option present

if "`idvar'" != "" {
	forval i=1/69 {
		bysort `idvar': egen corecomp`i' = max(comp`i')
	}

	*RETAIN ONLY LAST OBSERVATION FOR EACH PATIENT  
	set output error /*To prevent statement re number of deleted observations being printed*/
	bysort `idvar':  keep if _n == _N
	set output proc /*Return to default messages*/
	keep `idvar' corecomp1-corecomp69
}
else {
	forvalues i=1/69 {
		rename comp`i' corecomp`i'
	}
}

label define corelab 0 "Absent" 1 "Present"
forvalues i=1/69 {
	label values corecomp`i' corelab
}

display "Total Number of Observational Units (Visits OR Patients): " _N 

*If multiple records per patient retains only newly created binary comorbidity variables
*Otherwise retains all input data as well

gen COREscore_raw = corecomp1*-18 + corecomp2*-20 + corecomp3*19 + corecomp4*5 + corecomp5*-27 + corecomp6*-16 + corecomp7*-22 + corecomp8*-26 + corecomp9*19 + corecomp10*-6 + corecomp11*-14 + corecomp12*-19 + corecomp13*-24 + corecomp14*-19 + corecomp15*15 + corecomp16*-23 + corecomp17*-18 + corecomp18*-15 + corecomp19*-15 + corecomp20*-53 + corecomp21*-23 + corecomp22*-15 + corecomp23*-31 + corecomp24*-80 + corecomp25*-22 + corecomp26*-16 + corecomp27*-10 + corecomp28*-16 + corecomp29*-31 + corecomp30*21 + corecomp31*5 + corecomp32*-34 + corecomp33*1 + corecomp34*-48 + corecomp35*5 + corecomp36*-3 + corecomp37*14 + corecomp38*-29 + corecomp39*-16 + corecomp40*-17 + corecomp41*-34 + corecomp42*64 + corecomp43*39 + corecomp44*-14 + corecomp45*14 + corecomp46*1 + corecomp47*13 + corecomp48*13 + corecomp49*27 + corecomp50*29 + corecomp51*38 + corecomp52*15 + corecomp53*34 + corecomp54*15 + corecomp55*22 + corecomp56*50 + corecomp57*-6 + corecomp58*-39 + corecomp59*-33 + corecomp60*-10 + corecomp61*19 + corecomp62*-53 + corecomp63*-39 + corecomp64*-21 + corecomp65*-26 + corecomp66*-4 + corecomp67*-62 + corecomp68*-22 + corecomp69*-35      

gen COREscore = 100/(1+exp((0.5047096365901993+(0.0218310259815653000*COREscore_raw))))

label var corecomp1 "BLD001 Nutritional anemia"
label var corecomp2 "BLD007 Diseases of white blood cells"
label var corecomp3 "CIR003 Nonrheumatic and unspecified valve disorders"
label var corecomp4 "CIR007 Essential hypertension"
label var corecomp5 "CIR008 Hypertension with complications and secondary hypertension"
label var corecomp6 "CIR011 Coronary atherosclerosis and other heart disease"
label var corecomp7 "CIR019 Heart failure"
label var corecomp8 "CIR020 Cerebral infarction"
label var corecomp9 "CIR023 Occlusion or stenosis of precerebral or cerebral arteries without infarction"
label var corecomp10 "CIR026 Peripheral and visceral vascular disease"
label var corecomp11 "CIR027 Arterial dissections"
label var corecomp12 "CIR028 Gangrene"
label var corecomp13 "CIR030 Aortic and peripheral arterial embolism or thrombosis"
label var corecomp14 "CIR032 Other specified and unspecified circulatory disease"
label var corecomp15 "DIG004 Esophageal disorders"
label var corecomp16 "DIG006 Gastrointestinal and biliary perforation"
label var corecomp17 "DIG007 Gastritis and duodenitis"
label var corecomp18 "DIG009 Appendicitis and other appendiceal conditions"
label var corecomp19 "DIG010 Abdominal hernia"
label var corecomp20 "DIG012 Intestinal obstruction and ileus"
label var corecomp21 "DIG013 Diverticulosis and diverticulitis"
label var corecomp22 "DIG014 Hemorrhoids"
label var corecomp23 "DIG016 Peritonitis and intra-abdominal abscess"
label var corecomp24 "DIG017 Biliary tract disease"
label var corecomp25 "DIG021 Gastrointestinal hemorrhage"
label var corecomp26 "DIG022 Noninfectious gastroenteritis"
label var corecomp27 "DIG025 Other specified and unspecified gastrointestinal disorders"
label var corecomp28 "END003 Diabetes mellitus with complication"
label var corecomp29 "END008 Malnutrition"
label var corecomp30 "END009 Obesity"
label var corecomp31 "END010 Disorders of lipid metabolism"
label var corecomp32 "END011 Fluid and electrolyte disorders"
label var corecomp33 "GEN003 Chronic kidney disease"
label var corecomp34 "GEN004 Urinary tract infections"
label var corecomp35 "GEN007 Other specified and unspecified diseases of bladder and urethra"
label var corecomp36 "GEN009 Hematuria"
label var corecomp37 "MAL001 Cardiac and circulatory congenital anomalies"
label var corecomp38 "MBD017 Alcohol-related disorders"
label var corecomp39 "MBD019 Cannabis-related disorders"
label var corecomp40 "MBD021 Stimulant-related disorders"
label var corecomp41 "MUS002 Osteomyelitis"
label var corecomp42 "MUS006 Osteoarthritis"
label var corecomp43 "MUS011 Spondylopathies/spondyloarthropathy (including infective)"
label var corecomp44 "MUS014 Pathological fracture, initial encounter"
label var corecomp45 "MUS022 Scoliosis and other postural dorsopathic deformities"
label var corecomp46 "MUS029 Disorders of jaw"
label var corecomp47 "MUS030 Aseptic necrosis and osteonecrosis"
label var corecomp48 "NEO002 Head and neck cancers - lip and oral cavity"
label var corecomp49 "NEO015 Gastrointestinal cancers - colorectal"
label var corecomp50 "NEO022 Respiratory cancers"
label var corecomp51 "NEO039 Male reproductive system cancers - prostate"
label var corecomp52 "NEO043 Urinary system cancers - bladder"
label var corecomp53 "NEO045 Urinary system cancers - kidney"
label var corecomp54 "NEO051 Endocrine system cancers - pancreas"
label var corecomp55 "NEO070 Secondary malignancies"
label var corecomp56 "NEO073 Benign neoplasms"
label var corecomp57 "NEO074 Conditions due to neoplasm or the treatment of neoplasm"
label var corecomp58 "NVS008 Paralysis (other than cerebral palsy)"
label var corecomp59 "NVS011 Neurocognitive disorders"
label var corecomp60 "NVS014 CNS abscess"
label var corecomp61 "NVS016 Sleep wake disorders"
label var corecomp62 "NVS020 Other nervous system disorders (neither hereditary nor degenerative)"
label var corecomp63 "RSP002 Pneumonia (except that caused by tuberculosis)"
label var corecomp64 "RSP010 Aspiration pneumonitis"
label var corecomp65 "RSP012 Respiratory failure; insufficiency; arrest"
label var corecomp66 "RSP014 Pneumothorax"
label var corecomp67 "SKN001 Skin and subcutaneous tissue infections"
label var corecomp68 "SKN003 Pressure ulcer of skin"
label var corecomp69 "SKN004 Non-pressure ulcer of skin"
  
label var COREscore "CORE Score"

display "End of program execution..."

end