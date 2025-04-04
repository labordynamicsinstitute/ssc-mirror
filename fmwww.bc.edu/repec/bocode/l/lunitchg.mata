version 18

mata: 
	mata clear
	mata set matastrict on
		
	void unitchg(
		string scalar unit,
		string scalar from,
		string scalar to) {

		// Declaration
		string matrix converter
		string scalar rescale
		string scalar toname
		string scalar fromname
		string scalar totemp
		string scalar toK
		
		if (unit == "temperature") {
			converter = unitchg_temperatures()
			
			toK = select(converter, rowsum(strmatch(converter,from)))[1,3]
			totemp = select(unitchg_totemp(), rowsum(strmatch(unitchg_totemp(),to)))[1,3]
			st_local("toK",toK)
			st_local("totemp",totemp)
		}
		else {
			if (unit == "length") converter = unitchg_lengths()
			else if (unit == "area") converter = unitchg_areas()
			else if (unit == "volume") converter = unitchg_volumes()
			else if (unit == "mass") converter = unitchg_masses()
			else if (unit == "angle") converter = unitchg_angles()
			else if (unit == "datatransfer") converter = unitchg_datatransfers()
			else if (unit == "datastorage") converter = unitchg_datastorages()
			else if (unit == "time") converter = unitchg_times()

			rescale = strtoreal(select(converter, rowsum(strmatch(converter,from)))[1,3]) *
		   1/strtoreal(select(converter, rowsum(strmatch(converter,to)))[1,3])

			st_numscalar("unitchg_rescale",rescale)
		}

	
			
		toname = select(converter, rowsum(strmatch(converter,to)))[1,2]
		fromname = select(converter, rowsum(strmatch(converter,from)))[1,2
]
		st_local("toname",toname)
		st_local("fromname",fromname)
	}
	
	// Length-List
	// https://www.translatorscafe.com/unit-converter/en-US/
	string matrix unitchg_lengths() {
		string matrix lengths
		lengths = (
			"m","meter","1" \
			"dm","decimeter","0.1" \ 
			"cm","centimeter","0.01" \
			"mm","millimeter","0.001" \
			"mym","micrometer","0.000001" \
			"nm","nanometer","0.000000001" \
			"pm","picometer","0.000000000001" \
			"dam","decameter","10" \
			"hm","hectometer","100" \
			"km","kilometer","1000" \
			"100 km","100 kilometer","100000" \
			"Mm","megameter","1000000" \
			"in","inch","0.0254" \
			"in_USsvy","US survey inch","0.0254000508001" \
			"ft","foot","0.3048" \
			"ft_USsvy","US survey foot","0.3048006096012" \
			"yd","yard","0.91440" \
			"mi","mile","1609.347218694" \
			"nmi","nauticmile","1852" \
			"nmi_UK","UK nauticmile","1853.184" \
			"lea","league","4828.032" \
			"mi_ROME","mile(Roman)","1479.804" \
			"fur","furlong","201.168" \
			"fur_USsvy","US survey furlong","201.1684023368" \
			"chain","chain","20.1168" \
			"chain_USsvy","US survey chain","20.11684023368" \
			"rope","rope","6.096" \
			"rod","rod","5.0292" \
			"rod_USsvy","US survey rod","5.029210058419" \
			"perch","perch","5.0292" \
			"pole","pole","5.0292" \
			"ftm","fathom","1.8288" \
			"ftm_USsvy","US survey fathom","1.828803657607" \
			"ell","ell","1.143" \
			"lnk","link","0.201168" \
			"lnk_USsvy","US survey link","0.2011684023368" \
			"cubit","cubit","0.4572" \
			"hand","hand","0.1016" \
			"span","span","0.2286" \
			"finger","finger","0.1143" \
			"nail","nail","0.05715" \
			"barleycorn","barleycorn","0.008466666666667" \
			"mil","mil","0.0000254" \
			"arpent","arpent","58.5216" \
			"aln","aln","0.5937777777778"
			)
			
		lengths = lengths \
		"famn","famn","1.781333333333" \
		"ci","caliber","0.000254" \
		"ken","ken","2.11836" \
		"arshin","arshin","0.7112" \
		"actus","actus","35.47872" \
		"varadetarea","varadetarea","2.505456" \
		"varaconuquera","varaconuquera","2.505456" \
		"varacastellana","varacastellana","0.835152" \
		"cubig_GR","cubit(Greek)","0.462788" \
		"longreed","longreed","3.2004" \
		"reed","reed","2.7432" \
		"longcubit","longcubit","0.5334" \
		"handbreath","handbreath","0.0762" \
		"fingerbreath","fingerbreth","0.01905" \
		"equatorialradius","Earth's equatorialradius","6378160" \
		"polarradius","Earth's polarradius","6356777" \
		"distancefromthesun","Earth's distancefromthesun","149600000000" \
		"sunsradius","Sun's radius","696000000" \
		"light-nanosecond","light-nanosecond","0.299792458" \
		"ligth-microsecond","light-microsecond","299.792458" \
		"light-millisecond","light-millisecond","299792.458" \
		"light-second","light-second","299792458" \
		"light-minute","light-minute","17987547480" \
		"lunardistance","lunardistance","384000098.304" \
		"cablelength","cablelength","185.2" \
		"cablelength_UK","UK cablelength","185.3184" \
		"cablelength_US","US cablelength","219.456" \
		"ru","rackunit","0.04445" \
		"hp","horizontalpitch","0.00508" \
		"pica","pica (computer)","0.004233333333333" \
		"pica_p","pica (Printer)","0.0042175176" \
		"pt","point (DTP, computer)","0.0003527777777777" \
		"pt_p","point (Printer)","0.0003514598035146" \
		"twip","twip","0.00001763888888889" \
      "didot","Didot point", "0.0004" \
		"cicero","cicero","0.0045" \
		"pixel","pixel","0.0002645833333333" \
		"liniya","liniya","0.00254" \
		"diuym","diuym","0.0254" \
		"vershok","vershok","0.04445" \
		"pyad","pyad","0.1778" \
		"fut","foot(RU)","0.3048" \
		"sazhem","fathom(RU)","2.1336" \
		"kosayasazhem","kosayasazhem","2.48" \
		"versta","versta","1066.8" \
		"mezhevayaversta","mezhevayaversta","2133.6"

		return(lengths)
	}		
			
	
	// Areas-List
	// https://www.translatorscafe.com/unit-converter/en-US/
	string matrix unitchg_areas() {
		string matrix lengths
		real scalar rows
		string matrix areas
		lengths=unitchg_lengths()
		rows = rows(lengths)
		areas = lengths[1..rows,1]:+"^2", lengths[1..rows,2]:+"^2", strofreal(strtoreal(lengths[1..rows,3]):^2) 
		areas = areas \ 
		"soccer","soccer field", "7115.4438" \  
		"ftball_UK","UK football field", "7115.4438" \  
		"ftball_US","US football field", "4456.5588" \
		"A0","A0 paper", "1" \
		"A1","A1 paper", ".5" \
		"A2","A2 paper", ".25" \
		"A3","A3 paper", ".125" \
		"A4","A4 paper", ".0625" \
		"A5","A5 paper", ".03125" \
		"A6","A6 paper", ".015625" \
		"A7","A7 paper", ".0078125" \
		"A8","A8 paper", ".00390625" \
		"A9","A9 paper", ".00195313" \
		"A10","A10 paper",".00097656" \
		"A11","A11 paper",".00048828" \ 
		"A12","A12 paper",".00024414" \
		"A13","A13 paper",".00012207" \
		"letter","Letter paper",".060264" \
		"legal","Legal paper",".076896" \
		"tabloid","Tabloid paper",".120528" \
		"junior Legal","Junior Legal paper",".025781" \
		"half Letter","Half Letter paper",".03024"  \
		"gov_letter","Government Letter paper",".051562" \
		"gov_legal","Government Legal paper",".07128" \
 		"saarland","saarland", "2569690000" \  
		"h","hectare", "10000" \
		"a","are", "100" \
		"circular inch","circular inch", "0.0005067074790975" \
		"township","township", "93239571.9721" \
		"section","section", "2589988.110336" \
		"ac","acre", "4046.8564224" \
		"ac_USsvy","US survey acre", "4046.872609874" \
		"rood","rood", "1011.7141056" \
		"homestead","homestead", "647497.027584" \
		"sapin","sapin", "0.09290304" \
		"arpent","arpent", "3418.740000066" \
		"cuerda","cuerda", "3930.395625" \
		"desyatina1","state desyatina", "10925.4" \
		"desyatina2","farmer desyatina", "16388.1" 
		
		return(areas)
	}
	
	// Volumes List
	// https://www.translatorscafe.com/unit-converter/en-US/
	string matrix unitchg_volumes() {
		real scalar rows
		string matrix lengths
		string matrix volumes
		lengths=unitchg_lengths()
		rows = rows(lengths)
		volumes = lengths[1..rows,1]:+"^3", lengths[1..rows,2]:+"^3", strofreal(strtoreal(lengths[1..rows,3]):^3) 
		volumes = volumes \ 
		"l","liter", "0.001" \
		"Pl","petaliter", "1000000000000" \
		"Tl","teraliter", "1000000000" \
		"Gl","gigaliter", "1000000" \
		"Ml","megaliter", "1000" \
		"kl","kiloliter", "1" \
		"hl","hectaliter", "0.1" \
		"dal","dekaliter", "0.01" \
		"dl","deciliter", "0.0001" \
		"cl","centiliter", "0.00001" \
		"ml","milliliter", "0.000001" \
		"myl","microliter", "0.000000001" \
		"cc","cubic centimeter", "0.000001" \
		"drop","drop", "0.00000005" \
		"brl","barrel", "0.158987294928" \
		"bl_US","US barrel", "0.119240471196" \
		"bl_UK","UK barrel", "0.16365924" \
		"gal_US","US gallon", "0.003785411784" \
		"gal_UK","UK gallon", "0.00454609" \
		"qt_US","US quart", "0.000946352946" \
		"qt_UK","UK quart", "0.0011365225" \
		"pt_US","US pint", "0.000473176473" \
		"pt_UK","UK pint", "0.00056826125" \
		"cup_US","US cup", "0.0002365882365" \
		"cup","cup", "0.00025" \
		"cup_UK","UK cup", "0.000284130625" \
		"floz_US","US fluid ounce", "0.0000295735295625" \
		"floz_UK","UK fluid once", "0.0000284130625" \
		"tbsp_US","US table spoon", "0.00001478676478125" \
		"tbsp","table spoon", "0.000015" \
		"tbsp_UK","UK table spoon", "0.0000177581640625" \
		"dstspn_US","US dessertspoon", "0.0000098578431875" \
		"dstspn_UK","US dessertspoon", "0.00001183877604167" \
		"tsp_US","US teaspoon", "0.00000492892159375" \
		"tsp","teaspoon", "0.000005" \
		"tsp_UK","UK teaspoon", "0.000005919388020833" \
		"gil_US","US gil", "0.00011829411825" \
		"gil_UK","UK gil", "0.0001420653125" \
		"rt","register ton", "2.8316846592" \
		"ccf","100 cubic feet", "2.8316846592" \
		"acft","acre-foot", "1233.481837548" \
		"acft_US","US acre-foot", "1233.489238468" \
		"acre-inch","acre-inch", "102.790153129" \
		"dekastere","dekastere", "10" \
		"stere","stere", "1" \
		"decistere","decistere", "0.1" \
		"cord","cord", "3.624556363776" \
		"tun","tun", "0.953923769568" \
		"hogshead","hogshead", "0.238480942392" \
		"FBM","board foot", "0.002359737216" \
		"dr","fluid dram", "0.000003696691195312" \
		"cor","cor", "0.22" \
		"homer","homer", "0.22" \
		"bath","bath", "0.022" \
		"hin","hin", "0.003666666666666" \
		"cab","cab", "0.001222222222222" \
		"log","log", "0.0003055555555555" \
		"taza","taza", "0.0002365882365" \
		"bocka","bochka", "0.4919764" \
		"vedro","vedro", "0.01229941" \
		"shtoff","shtoff", "0.001229941" \
		"chetvert","chetvert", "0.0030748525" \
		"wine bottle","wine bottle (RU)", "0.000768713125" \
		"vodka bottle","vodka bottle (RU)", "0.0006149705" \
		"stakan","stakan", "0.0002733202222222" \
		"charka","charka", "0.0001229941" \
		"shkalik","shkalik", "0.00006149705"

		return(volumes)
	}
	
	// Masses List
	// https://www.translatorscafe.com/unit-converter/en-US/
	string matrix unitchg_masses() {
	string matrix masses
		masses =  (
			"g","gram", "1" \
			"dg","decigram", "0.1" \
			"cg","centigram", "0.01" \
			"mg","milligram", "0.001" \
			"myg","mircogram", "0.000001" \
			"ng","nanogram", "0.000000001" \
			"pg","picogram", "0.000000000001" \
			"dag","decagram", "10" \
			"hg","hectogram", "100" \
			"kg","kilogram", "1000" \
			"Mg","megagram", "1000000" \
			"t","ton", "1000000" \
			"kgf*s^2/m","kilogram force in s^2/m", "9806.65" \
			"kip","kilopound", "453592.37" \
			"slug","slug", "14593.9029372" \
			"lbf*s^2/ft","pound force in s2^2/ft", "14593.90293721" \
			"lb","pound", "453.59237" \
			"troy lb","troy pound", "373.2417216" \
			"oz","ounce", "28.349523125" \
			"troy oz","troy ounce", "31.1034768" \
			"metric oz","metric ounce", "25" \
			"short t","short ton", "907184.74" \
			"long t","long ton", "1016046.9088" \
			"t_US","US ton", "29.16667" \
			"t_UK","UK ton", "32.66666666667" \
			"kt","kiloton", "1000000000" \
			"q","quintal", "100000" \
			"ztr","zentner", "50000" \
			"cwt_US","US centum weight", "45359.237" \
			"cwt_UK","UK centum weight", "50802.34544" \
			"quarter_US","US quarter", "11339.80925" \
			"quarter_UK","UK quarter", "12700.58636" \
			"st_US","US stone", "5669.904625" \
			"st_UK","UK stone", "6350.29318" \
			"pwt","pennyweight", "1.555173840004" \
			"s.ap","apothecary scruble", "1.295978200003" \
			"ct","carat", "0.2" \
			"gr","grain", "0.06479891000017" \
			"gamma","gamma", "0.000001" \
			"talent_bh","Biblical Hebrew talent", "34200" \
			"mna_bh","Biblical Hebrew mina", "570" \
			"shekel_bh","Biblical Hebrew shekel", "11.4" \
			"bekan_bh","Biblical Hebrew bekan", "5.7" \
			"gerah_bh","Biblical Hebrew gerah", "0.57" \
			"talent_GR","Biblical Greek talent", "20400" \
			"mna_GR","Biblical Greek mina", "340" \
			"tetradrachma","Biblical Greek tetadrachma", "13.6" \
			"diddrachma","Biblical Greek tetadrachma", "6.8" \
			"drachma","Biblical Greek drchma", "3.4" \
			"denarius","Biblical Roman denarius", "3.85" \
			"assarion","Biblical Roman assarion", "0.240625" \
			"quadrans","Biblical Roman quadrans", "0.06015625" \
			"lepton","Biblical Roman lepton", "0.030078125" \
			"m_p","Planck mass", "0.0000217671" \
			"berkovets","berkovets", "163804.964" \
			"pood","pood", "16380.4964" \
			"funt","funt", "409.51241" \
			"lot","lot", "12.7972628125" \
			"zolotnik","zolotnik", "4.265754270833" \
			"dolya","dolya", "0.04443494032118" \
			"livre","livre", "489.5"  \
			"fir","firkin","40823.3133"
			)
		
		return(masses)
	}


	// Angles List
	// https://www.calculatorsoup.com/calculators/conversions/angle.php
	string matrix unitchg_angles() {
	string matrix angles
		angles =  (
			"rad","radian", "1" \
			"deg","degree", "0.01745329251994" \
			"grad", "gradian", "0.01570796326795" \
			"gon", "gon", "0.01570796326795" \
			"'","minute", "0.0002908882086657" \
			"''", "second", "0.000004848136811095" \
			"sign", "sign", "0.5235987755983" \
			"mil","mil","0.0009817477042468" \
			"rev","revolution", "6.28318530718" \
			"circ","circle" , "6.28318530718" \
			"turn","turn","6.28318530718" \
			"quad","quadrant","1.570796326795" \
			"r-ang", "right angle", "1.570796326795" \
			"sext","sextant","1.047197551197" 
			)
		
		return(angles)
	}

	
	string matrix unitchg_temperatures() {
		string matrix temperatures
		temperatures =  (
			"K", "Kelvin",  "x"   \
			"C", "Celsius", "(x + 273.15)"   \
			"F", "Fahrenheit", "(x + 459.67) * 5/9"  \
         "Ra", "Rankine", "x * 5/9" \
			"Re", "Réaumur", "(x * 1.25 + 273.15)"  \
			"Ro", "Rømer"," ((x - 7.5)*40/21 + 273.15)" \
			"De", "Delisle","(373.15 - x * 2/3)" \
			"N", "Newton","(x * 100/33 + 273.15)" 
			)
		return(temperatures)
	}
	
	string matrix unitchg_totemp() {
		string matrix totemp
		totemp = (
			"K", "Kelvin", "x"  \
			"C", "Celsius", "x - 273.15"  \
			"F", "Fahrenheit", "x * 1.8 - 459.67" \
			"Ra", "Rankine", "x * 9/5"        \
			"Re", "Réaumur", "(x - 273.15) * 0.8" \
			"Ro", "Rømer","(x - 273.15) * 21/40 + 7.5" \
			"De", "Delisle","(373.15 - x) * 3/2" \
			"N", "Newton","(x - 273.15) * 33/100" 
			)
		return(totemp)
	}


	// Time-List
	// https://en.wikipedia.org/wiki/Unit_of_time
	// Hindu times from: https://en.wikipedia.org/wiki/Hindu_units_of_time 
	string matrix unitchg_times() {
		string matrix times
		times = (
			"s", "second", "1" \
			"ds", "decisecond","0.1" \
			"cs","centisecond","0.01" \
			"ms","millisecond","0.001" \
			"mys","microsecond","0.000001" \
			"ns","nanosecond","0.000000001" \
			"ps","picosecond","0.000000000001" \
			"das","decaseond", "10" \
			"hs","hectosecond","100" \
			"ks","kilosecond", "1000" \
			"Ms","megasecond", "1000000" \
			"Ts","terasecond", "1000000000" \
			"Ps","petasecond", "1000000000000" \
			"min","minute","60" \
			"h","hour","3600" \
			"d","day","86400" \
			"dd","deciday","8640.0" \
			"cd","centiday","864.00" \
			"md","milliday","86.400" \
			"myd","microday","0.086400" \
			"nd","nanoday","0.000086400" \
			"pd","picoday","0.000000086400" \
			"dad","decaday","864000" \
			"hd","hectoday","8640000" \
			"kd","kiloday", "86400000" \
			"Md","Megaday", "86400000000" \
			"Td","teraday", "86400000000000" \
			"Pd","petaday", "86400000000000000" \
			"w","week","604800" \
   		"mon","month","2629800" \
			"y","year","31557600" \
			"y_common","common year","31536000" \
			"y_tropical","tropical year","31556925.216" \
         "y_gregorian","gregorian year"," 31556952" \
         "y_sidereal","sidereal year","31558149.76635456" \
         "y_leap","leap year","31622400" \
			"decade","decade","315576000" \
			"century","century","3155760000" \
			"millenium","millenium","31557600000" \
			"fortnight","fortnight","1209600" \
			"lunar year","lunar year","30617568" \
			"lunar phase","lunar phase","2551442.976" \
			"lunation","lunation","2551442.976" \
         "moment","moment","90" \
			"quarantine","quarantine","3456000" \
			"sem","semester","10886400" \
			"lustrum","lustrum","157788000" \
			"indiction","indiction","473364000" \
			"milliday","milliday","86.4" \
			".beat","Swatch Internet Time","86.4" \
			"truti","truti","0.000000308" \
			"renu","renu",".000018"  \
			"lava","lava",".001111" \
			"liksaka","liksaka",".06666" \
			"lipta","lipta","0.4" \
			"vipala","vipala","0.4" \
			"prana","prana","4" \
			"pala","pala","24" \
			"vighati","vighati","24" \
         "vinadi","vinadi","24" \
			"ghati","ghati","1440" \
			"nadi","nadi","1440" \
			"danda","danda","1440" \
			"muhurta","muhurta","2880" \
			"nak aho","naksatra ahoratram","86400" 
			)
		return(times)
	}
	
	
	// Datatransfer-List
	// https://www.translatorscafe.com/unit-converter/en-US/
	string matrix unitchg_datastorages() {
		string matrix todstore
		todstore = (
			"b","bit","0.125" \
			"nibble","nibble","0.5" \
			"B","byte","1" \
			"char","character","1" \
			"word","word","2" \
			"mapm","MAPM-word","4" \
			"quad-word","quadruple-word","8" \
			"block","block","512" \
			"kibib","kibibit","128" \
			"kb","kilobit","125" \
			"kibiB","kibibyte","1024" \
			"kB","kilobyte","1000" \
			"mebib","mebibit","131072" \
			"Mb","megabit","125000" \
			"mebiB","mebiB","1048576" \
			"MB","megabyte","1000000" \
			"gibib","gibibit","134217728" \
			"Gb","gigabit","125000000" \
			"gibiB","gibibyte","1073741824" \
			"GB","gigabyte","1000000000" \
			"tebib","tebibit","137438953472" \
			"Tb","terabit","125000000000" \
			"TB","terabyte","1000000000000" \
			"floppy3.5DD","floppy disk (3.5 DD)","728832" \
			"floppy3.5HD","floppy disk (3.5 HD)","1457664" \
			"floppy3.5ED","floppy disk (3.5 ED)","2915328" \
			"floppy5.25DD","floppy disk (5.25 DD)","364416" \
			"floppy5.25HD","floppy disk (5.25 HD)","1213952" \
			"zip100","Zip 100","100431872" \
			"zip250","Zip 250","251079680" \
			"jaz1","Jaz 1GB","1073741824" \
			"jaz2","Jaz 2GB","2147483648" \
			"cd74","CD (74 minutes)","681058304" \
			"cd80","CD (80 minutes)","736279247" \
			"dvd11","DVD (1 layer 1 side)","5046586572.8" \
			"dvd21","DVD (2 layer 1 side)","9126805504" \
			"dvd12","DVD (1 layer 2 sides)","10093173145.6" \
			"dvd22","DVD (2 layers 2 sides)","18253611008" \
			"bd1","Blu-ray disc (single-layer)","26843545600" \
			"bd2","Blu-ray disc (double-layer)","53687091200" 
			)
		return(todstore)
	}
	
	// Datatransfer-List
	// https://www.translatorscafe.com/unit-converter/en-US/
	string matrix unitchg_datatransfers() {
		string matrix todtrans
		todtrans = (
			"B/s","byte/second","1" \
			"b/s","bit/second","0.125" \
			"kb/s","kilobit/second (SI def.)","125" \
			"kB/s","kilobyte/second (SI def.)","1000" \
			"kibib/s","kibibit/second","128" \
			"kibiB/s","kibibyte/second","1024" \
			"Mb/s","megabit/second (SI def.)","125000" \
			"MB/s","megabyte/second (SI def.)","1000000" \
			"mebib/s","mebibit/second","131072" \
			"mebiB/s","mebibyte/second","1048576" \
			"Gb/s","gigabit/second (SI def.)","125000000" \
			"GB/s","gigabyte/second (SI def.)","1000000000" \
			"gibib/s","gibibit/second","134217728" \
			"gibiB/s","gibibyte/second","1073741824" \
			"terab/s","terabit/second (SI def.)","125000000000" \
			"teraB/s","terabyte/second (SI def.)","1000000000000" \
			"tebib/s","tebibit/second","137438953472" \
			"ethernet","ethernet","1250000" \
			"ethernet_f","ethernet (fast)","12500000" \
			"ethernet_Gb","ethernet (gigabit)","125000000" \
			"oc1","OC1","6480000" \
			"oc3","OC3","19440000" \
			"oc12","OC12","77760000" \
			"oc48","OC48","311040000" \
			"oc24","OC24","155520000" \
			"oc12","OC12","77760000" \
			"oc192","OC192","1244160000" \
			"oc768","OC768","4976640000" \
			"isdn_single","ISDN (single channel)","8000" \
			"isdn_dual","ISDN (dual channel)","16000" \
			"modem110","modem (110)","13.75" \
			"modem300","modem (300)","37.5" \
			"modem1200","modem (1200)","150" \
			"modem2400","modem (2400)","300" \
			"modem9600","modem (9600)","1200" \
			"modem14.4k","modem (14.4k)","1800" \
			"modem28.8k","modem (28.8k)","3600" \
			"modem33.6k","modem (33.6k)","4200" \
			"modem56k","modem (56k)","7000" 
			)
			
		todtrans = todtrans \
			"scsi_async","SCSI (Async)","1500000" \
			"scsi_sync","SCSI (Sync)","5000000" \
			"scsi_f","SCSI (Fast)","10000000" \
			"scsi_fu","SCSI (Fast Ultra)","20000000" \
			"scsi_fw","SCSI (Fast Wide)","20000000" \
			"scsi_fuw","SCSI (Fast Ultra Wide)","40000000" \
			"scsi_u2","SCSI (Ultra-2)","80000000" \
			"scsi_u3","SCSI (Ultra-3)","160000000" \
			"scsi_lvdu80","SCSI (LVD Ultra80)","80000000" \
			"scsi_lvdu160","SCSI (LVD Ultra160)","160000000" \
			"ide_pio0","IDE (PIO mode 0)","3300000" \
			"ide_pio1","IDE (PIO mode 1)","5200000" \
			"ide_pio2","IDE (PIO mode 2)","8300000" \
			"ide_pio3","IDE (PIO mode 3)","11100000" \
			"ide_pio4","IDE (PIO mode 4)","16600000" \
			"ide_dma0","IDE (DMA mode 0)","4200000" \
			"ide_dma1","IDE (DMA mode 1)","13300000" \
			"ide_dma2","IDE (DMA mode 2)","16600000" \
			"ide_udma0","IDE (UDMA mode 0)","16600000" \
			"ide_udma1","IDE (UDMA mode 1)","25000000" \
			"ide_udma2","IDE (UDMA mode 2)","33000000" \
			"ide_udma3","IDE (UDMA mode 3)","50000000" \
			"ide_udma4","IDE (UDMA mode 4)","66000000" \
			"ide_udma33","IDE (UDMA-33)","33000000" \
			"ide_udma66","IDE (UDMA-66)","66000000" \
			"usb 1","USB 1.X","1500000" \
			"firewire400","FireWire 400 (IEEE 1394-1995)","50000000" \
			"t0p","T0 (payload)","7000" \
			"t0_b8zs","T0 (B8ZS payload)","8000" \
			"t1s","T1 (signal)","193000" \
			"t1p","T1 (payload)","168000" \
			"t1zp","T1Z (payload)","193000" \
			"t1cs","T1C (signal)","394000" \
			"t1cp","T1C (payload)","336000" \
			"t2s","T2 (signal)","789000" \
			"t3p","T3 (payload)","4704000" \
			"t3s","T3 (signal)","5592000" \
			"t3zp","T3Z (payload)","5376000" \
			"t4s","T4 (signal)","34272000" \
			"vt1s","Virtual Tributary 1 (signal)","216000" \
			"vt1p","Virtual Tributary 1 (payload)","193000" \
			"vt2s","Virtual Tributary 2 (signal)","288000" \
			"vt2p","Virtual Tributary 2 (payload)","256000" \
			"vt6s","Virtual Tributary 6 (signal)","789000" \
			"vt6p","Virtual Tributary 6 (payload)","750000" \
			"sts1s","STS1 (signal)","6480000" \
			"sts1p","STS1 (payload)","6187500" \
			"sts3s","STS3 (signal)","19440000" \
			"sts3p","STS3 (payload)","18792000" \
			"sts3cs","STS3c (signal)","19440000" \
			"sts12s","STS12 (signal)","77760000" \
			"sts24s","STS24 (signal)","155520000" \
			"sts48s","STS48 (signal)","311040000" \
			"sts192s","STS192 (signal)","1244160000" \
			"stm1s","STM-1 (signal)","19440000" \
			"stm4s","STM-4 (signal)","77760000" \
			"stm16s","STM-16 (signal)","311040000" \
			"stm64s","STM-64 (signal)","1244160000" \
			"usb2","USB 2.X","35000000" \
			"usb3.1","USB 3.1","1250000000" \
			"firewire800","FireWire 800 (IEEE 1394b-2002)","100000000"

		return(todtrans)
	}

	
	// Compile into a libary
	mata mlib create lunitchg, replace
	mata mlib add lunitchg           ///
	  unitchg()  ///
	  unitchg_angles()              ///
	  unitchg_lengths()             ///
	  unitchg_areas()              ///
	  unitchg_volumes()          ///
	  unitchg_masses()           ///
	  unitchg_datatransfers() ///
	  unitchg_datastorages() ///
	  unitchg_temperatures() ///
	  unitchg_times() ///
	  unitchg_totemp()  
	
	mata mlib index

end
exit


