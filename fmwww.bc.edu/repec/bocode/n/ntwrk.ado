*! ntwrk v1.0 (beta)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.0  (17 Jun 2026): first release (beta)


cap prog drop ntwrk

prog def ntwrk, sortpreserve

	version 15
	
		syntax varlist(max = 1 numeric) [if] [in], from(string) to(string)   	 												///     // from, to, value
		[ Measure(string) weighted directedclustering KATZALpha(real 0.1) ] 	///  	// node measures
		[ ITERations(real 100) TOLerance(real 1e-6) radius(real 5) ]   										///		// common parameters
		[ ARROWSize(string) ]													///		// arrow size
		[ layout(string) seed(numlist max=1 >=0) width(real 150) height(real 150) 	] 			///		// draw the graphs
		[ LQUANTile(numlist max=1 >=3) LColor(string) LWidth(string) LLABColor(string) LLABSize(string) LAlpha(real 80) reduce(real 0) lscale LSCALEFACtor(real 0.3333) lprop LPROPFACtor(real 0.3333) ] 		///		// link options
		[ arc arcn(real 40) ARCRADius(numlist max=1 >0)  ] 									///		// arc options
		[ MColor(string) MQUANTile(numlist max=1 >=3) mvar(string) MSize(string) MLABColor(string) MLABSize(string) malpha(real 80) mlalpha(real 100) MSYMbol(string) mscale  MSCALEFACtor(real 0.3333) MLColor(string) MLWIDth(string) mprop MPROPFACtor(real 0.3333) mpoints(numlist max=1 >=3) ]			///		// node options
		[ mrotate(real 0) save replace saveprefix(string) nograph lpalette(string) mpalette(string) NOVALues VALCONDition(real 0) format(string) * ]      // saving options


	// check dependencies
	cap findfile colorpalette.ado
	if _rc != 0 {
		display as error "The palettes package is missing. Install the {stata ssc install palettes, replace:palettes} and {stata ssc install colrspace, replace:colrspace} packages."
		exit
	}

	if "`arc'" != "" {
		cap findfile shapes.ado
		if _rc != 0 {
			display as error "The {cmd:shapes} command is required for the {opt arc} option. Install via {stata ssc install graphfunctions, replace:graphfunctions}."
			exit
		}
	}		
	
	local valid_layouts "star fr sphere grid random spectral kk bipartite shell spiral"
	if "`layout'" != "" & !regexm(" `valid_layouts' ", " `layout' ") {
		di as error "Valid options for {opt layout()} are {it:star}, {it:fr}, {it:sphere}, {it:grid}, {it:random}, {it:spectral}, {it:kk}, {it:bipartite}, {it:shell}, or {it:spiral}."
		exit
	}

	if "`lquantile'" == "" local lquantile 5
	local lcats = `lquantile'

	if `lcats' < 3 {
		di as error "{opt lquantile()} must be greater than or equal to 3."
		exit 198
	}

	if "`mquantile'" == "" local mquantile 5
	local mcats = `mquantile'

	if `mcats' < 3 {
		di as error "{opt mquantile()} must be greater than or equal to 3."
		exit 198
	}

	if `reduce' < 0 {
		di as error "{opt reduce()} must be non-negative."
		exit 198
	}

	if "`arrowsize'" 	== "" local arrowsize 1.2
	if "`llabsize'" 	== "" local llabsize 1.2
	if "`llabcolor'" 	== "" local llabcolor black
	if "`lwidth'" 		== "" local lwidth 0.5	

	if "`msize'" 		== "" local msize 5
	if "`mlabsize'" 	== "" local mlabsize 1.6
	if "`mlabcolor'" 	== "" local mlabcolor black	
	if "`mlwidth'" 		== "" local mlwidth 0.08

		
	capture confirm number `msize'
	if _rc {
		di as error "{opt msize()} must be numeric."
		exit 198
	}

	if "`save'" != "" & "`saveprefix'" == "" {
		local saveprefix "_network"
		noi di in yellow "Note: {opt saveprefix()} not specified. Using default: {it:`saveprefix'}"
	}

	if "`katzalpha'" != "" {
		if `katzalpha' <= 0 {
			di as error "{opt katzalpha()} must be greater than 0."
			exit 198
		}
	}

	local __raw_cmdline `"`0'"'	
	local __has_nograph = regexm(lower(`"`__raw_cmdline'"'), "(^|,|[ \t])nograph([ \t]|$)")

		

	local valid_measures "degree between indegree outdegree closeness harmonic clustering transitivity eccentricity eigenval eigenvec katz pagerank hits core reciprocity ancestors descendants"
	local measure_list = lower(strtrim("`measure'"))
	local measure_list : subinstr local measure_list "," " ", all
	local measure_list : list retok measure_list

	if "`measure_list'" == "" {
		foreach _m in between indegree outdegree closeness harmonic clustering transitivity eccentricity eigenval eigenvec katz pagerank hits core reciprocity ancestors descendants {
			if "``_m''" != "" {
				local measure_list "`measure_list' `_m'"
			}
		}
		if "`measure_list'" == "" {
			local measure_list "degree"
		}
		else {
			local measure_list "degree `measure_list'"
		}
	}

	local invalid_measures ""
	local measure_clean ""
	foreach _m of local measure_list {
		if !regexm(" `valid_measures' ", " `_m' ") {
			local invalid_measures "`invalid_measures' `_m'"
		}
		else if !regexm(" `measure_clean' ", " `_m' ") {
			local measure_clean "`measure_clean' `_m'"
		}
	}

	if "`invalid_measures'" != "" {
		di as error "Invalid name(s) in {opt measure()}:`invalid_measures'"
		di as error "Valid measure options are: `valid_measures'"
		exit 198
	}

	local measure_list : list retok measure_clean

	foreach _m in degree between indegree outdegree closeness harmonic clustering transitivity eccentricity eigenval eigenvec katz pagerank hits core reciprocity ancestors descendants {
		local use_`_m' = regexm(" `measure_list' ", " `_m' ")
	}

	local node_metric "degree"
	if !`use_degree' {
		local node_metric : word 1 of `measure_list'
		if "`node_metric'" == "transitivity" local node_metric "transit"
		if "`node_metric'" == "eccentricity" local node_metric "eccentric"
		if "`node_metric'" == "hits" local node_metric "hub"
	}
		
		
	marksample touse, strok	
	
	local f `from'  // from
	local t `to'  // to 
	local v `varlist'  // value

	
preserve
	qui {	
		// store original information in a copy
		if "`seed'" != "" set seed `seed'
		
		tempfile _network_copy _node_map
		qui keep if `touse'
		collapse (sum) `v', by(`f' `t')  // ensure uniqueness
		compress
		save `_network_copy'


		use `_network_copy', clear

	tempvar _fstr _tstr _key
	capture confirm string variable `f'
	if !_rc {
		local _fstr `f'
	}
	else {
		local __f_vallab : value label `f'
		if "`__f_vallab'" != "" {
			decode `f', gen(`_fstr')
		}
		else {
			tostring `f', gen(`_fstr') usedisplayformat force
		}
	}

	capture confirm string variable `t'
	if !_rc {
		local _tstr `t'	
	}
	else {
		local __t_vallab : value label `t'
		if "`__t_vallab'" != "" {
			decode `t', gen(`_tstr')
		}
		else {
			tostring `t', gen(`_tstr') usedisplayformat force
		}
	}

	keep `_fstr' `_tstr'
	ren `_fstr' _v1
	ren `_tstr' _v2
	gen long serial = _n
	reshape long _v, i(serial) j(layer)
	drop layer serial
	drop if missing(_v)
	duplicates drop _v, force
	sort _v
	encode _v, gen(_id)
	keep _id _v
	ren _v _label
	save `_node_map', replace

	use `_network_copy', clear
	capture confirm string variable `f'
	if !_rc {
		gen str `_key' = `f'
	}
	else {
		local __f_vallab : value label `f'
		if "`__f_vallab'" != "" {
			decode `f', gen(`_key')
		}
		else {
			tostring `f', gen(`_key') usedisplayformat force
		}
	}
	ren `_key' _label
	merge m:1 _label using `_node_map'
	keep if _m==3
	drop _m _label `f'
	ren _id `f'

	capture confirm string variable `t'
	if !_rc {
		gen str `_key' = `t'
	}
	else {
		local __t_vallab : value label `t'
		if "`__t_vallab'" != "" {
			decode `t', gen(`_key')
		}
		else {
			tostring `t', gen(`_key') usedisplayformat force
		}
	}
	ren `_key' _label
	merge m:1 _label using `_node_map'
	keep if _m==3
	drop _m _label `t'
	ren _id `t'

	order `f' `t'

	
	gen _lid = _n 
	
	save `_network_copy', replace
	
	// noi di "Check 2"

	****** pass to Mata
	mata: points = st_data(., (" `from' `to' `varlist'")); square = square(points); binary = binary(square); cost = edgecost(square)
	

	// prepare a matrix for storing results
	mata: exports = J(rows(binary), 0, .); mylist = ""
	
	
	// always compute degree; include it in output only when requested
		if "`weighted'" == "" {
			mata: degree     = degree(binary)
		}
		else {
			mata: degree     = degree(square)
		}
		if `use_degree' {
			mata: exports 	= exports , degree
			mata: mylist = mylist + " degree"
			mata: st_local("header", mylist)
		}
		
	
	
	if `use_between' {
		if "`weighted'" == "" {
			mata: between    = betweenness(binary, square, 0)
		}
		else {
			mata: between    = betweenness(binary, cost, 1)
		}
		mata: exports 	= exports , between
		mata: mylist = mylist + " between"
		mata: st_local("header", mylist)
	}

	
	if `use_indegree' {
		if "`weighted'" == "" {
			mata: indegree   = indegree(binary)
		}
		else {
			mata: indegree   = indegree(square)
		}
		mata: exports 	= exports , indegree
		mata: mylist = mylist + " indegree"
		mata: st_local("header", mylist)		
	}	
	

	if `use_outdegree' {
		if "`weighted'" == "" {
			mata: outdegree  = outdegree(binary)
		}
		else {
			mata: outdegree  = outdegree(square)
		}
		mata: exports 	= exports , outdegree
		mata: mylist = mylist + " outdegree"
		mata: st_local("header", mylist)		
	}	
	

	if `use_closeness' {
		if "`weighted'" == "" {
			mata: closeness  = closeness_centrality(binary)
		}
		else {
			mata: closeness  = closeness_centrality_w(binary, cost)
		}
		mata: exports 	= exports , closeness
		mata: mylist = mylist + " closeness"
		mata: st_local("header", mylist)			
	}

	
	if `use_harmonic' {
		if "`weighted'" == "" {
			mata: harmonic   = harmonic_centrality(binary)
		}
		else {
			mata: harmonic   = harmonic_centrality_w(binary, cost)
		}
		mata: exports 	= exports , harmonic
		mata: mylist = mylist + " harmonic"
		mata: st_local("header", mylist)			
	}

	
	if `use_clustering' {
		if "`directedclustering'" == "" {
			mata: clustering = clustering_coefficient(binary)
		}
		else {
			mata: clustering = clustering_coefficient_directed(binary)
		}
		mata: exports 	= exports , clustering
		mata: mylist = mylist + " clustering"
		mata: st_local("header", mylist)			
	}

	
	if `use_transitivity' {
		mata: transit    = transitivity(binary)
		mata: exports 	= exports , J(rows(binary), 1, transit)
		mata: mylist = mylist + " transitivity"
		mata: st_local("header", mylist)			
	}

	
	if `use_eccentricity' {
		if "`weighted'" == "" {
			mata: eccentric  = eccentricity(binary)
		}
		else {
			mata: eccentric  = eccentricity_w(binary, cost)
		}
		mata: exports 	= exports , eccentric
		mata: mylist = mylist + " eccentricity"
		mata: st_local("header", mylist)			
	}

	
	if `use_eigenval' {
		if "`weighted'" == "" {
			mata: eigenval   = eigenvalue_centrality(binary, `iterations', `tolerance')
		}
		else {
			mata: eigenval   = eigenvalue_centrality(square, `iterations', `tolerance')
		}
		mata: exports 	= exports , eigenval
		mata: mylist = mylist + " eigenval"
		mata: st_local("header", mylist)			
	}	
		
		
	if `use_eigenvec' {
		if "`weighted'" == "" {
			mata: eigenvec  = eigenvectorcent(binary)
		}
		else {
			mata: eigenvec  = eigenvectorcent(square)
		}
		mata: exports 	= exports , eigenvec
		mata: mylist    = mylist + " eigenvec"
		mata: st_local("header", mylist)			
	}
	
		
	if `use_katz' {
		if "`katzalpha'" == "" {
			mata: katz_alpha = 0.1
		}
		else {
			mata: katz_alpha = `katzalpha'
		}
		if "`weighted'" == "" {
			mata: katz  	= katz_centrality(binary, katz_alpha, 1)
		}
		else {
			mata: katz  	= katz_centrality(square, katz_alpha, 1)
		}
		mata: exports   = exports , katz
		mata: mylist    = mylist + " katz"
		mata: st_local("header", mylist)		
	}
	
	
	if `use_pagerank' {
		if "`weighted'" == "" {
			mata: pagerank  = pagerank(binary, 0.85, `iterations', `tolerance')
		}
		else {
			mata: pagerank  = pagerank(square, 0.85, `iterations', `tolerance')
		}
		mata: exports 	= exports , pagerank
		mata: mylist    = mylist + " pagerank"
		mata: st_local("header", mylist)			
	}

	
	if `use_hits' {
		if "`weighted'" == "" {
			mata: hits(binary, `iterations', `tolerance', hub=., authority=.)
		}
		else {
			mata: hits(square, `iterations', `tolerance', hub=., authority=.)
		}
		mata: exports 	= exports , hub, authority
		mata: mylist = mylist + " hub authority"
		mata: st_local("header", mylist)		
	}

	if `use_core' {
		mata: core = core_number_undirected(binary)
		mata: exports = exports , core
		mata: mylist = mylist + " core"
		mata: st_local("header", mylist)
	}

	if `use_reciprocity' {
		mata: reciprocity = reciprocity_node(binary)
		mata: exports = exports , reciprocity
		mata: mylist = mylist + " reciprocity"
		mata: st_local("header", mylist)
	}

	if `use_descendants' {
		mata: descendants = descendants_count(binary)
		mata: exports = exports , descendants
		mata: mylist = mylist + " descendants"
		mata: st_local("header", mylist)
	}

	if `use_ancestors' {
		mata: ancestors = ancestors_count(binary)
		mata: exports = exports , ancestors
		mata: mylist = mylist + " ancestors"
		mata: st_local("header", mylist)
	}


	// noi di "Check 3"

	*****************************
	*****      layouts		*****
	*****************************
	
	tempfile _layout_nodes
	
	drop `v'
	duplicates drop `f' `t', force  // reduce 1
	
	gen id = _n
	
	cap ren `f' _id1
	cap ren `t' _id2
	reshape long _id, i(id) j(node)
	duplicates drop _id, force  // reduce 2
	cap drop id node
	sort _id
	
	if "`layout'" == "" & !`__has_nograph' {
		noi di in yellow "Note: {opt layout()} not specified. Using {opt layout(fr)}."
	}
	
	if "`layout'" == "star"  {
		gen double angle = (_n * 2 * -_pi / _N)
		gen double _x = `radius' * cos(angle)
		gen double _y = `radius' * sin(angle)
		
	}
	
	
	if "`layout'" == "fr" | "`layout'"== "" {
		mata: positions = fr_layout(binary, `iterations', `width', `height')
		mata: st_matrix("positions", positions)
		mat colnames positions = "_check" "_x" "_y"
		svmat positions, n(col)
	}
	
	
	if "`layout'" == "sphere" {
		mata: sphere = layout_sphere(binary)
		mata: st_matrix("sphere", sphere)
		mat colnames sphere = "_check" "_x" "_y" "_z"
		svmat sphere, n(col)
		cap drop _z
	}


	if "`layout'" == "grid" {
		gen double _ncols = ceil(sqrt(_N))
		gen double _col   = mod(_n - 1, _ncols)
		gen double _row   = floor((_n - 1) / _ncols)
		gen double _nrows = ceil(_N / _ncols)
		gen double _x = cond(_ncols == 1, `width'  / 2, _col * `width'  / (_ncols - 1))
		gen double _y = cond(_nrows == 1, `height' / 2, _row * `height' / (_nrows - 1))
	}


	if "`layout'" == "random" {
		gen double _x = runiform() * `width'
		gen double _y = runiform() * `height'
	}


	if "`layout'" == "spectral" {
		mata: spectral = spectral_layout(binary, `width', `height')
		mata: st_matrix("spectral", spectral)
		mat colnames spectral = "_check" "_x" "_y"
		svmat spectral, n(col)
	}


	if "`layout'" == "kk" {
		mata: kkpos = kk_layout(binary, `width', `height', `iterations', `tolerance')
		mata: st_matrix("kkpos", kkpos)
		mat colnames kkpos = "_check" "_x" "_y"
		svmat kkpos, n(col)
	}


	if "`layout'" == "bipartite" {
		mata: bippos = bipartite_layout(binary, `width', `height')
		mata: st_matrix("bippos", bippos)
		mat colnames bippos = "_check" "_x" "_y"
		svmat bippos, n(col)
	}

	if "`layout'" == "shell" {
		mata: shellpos = shell_layout(binary, `width', `height')
		mata: st_matrix("shellpos", shellpos)
		mat colnames shellpos = "_check" "_x" "_y"
		svmat shellpos, n(col)
	}


	if "`layout'" == "spiral" {
		mata: spirpos = spiral_layout(binary, `width', `height')
		mata: st_matrix("spirpos", spirpos)
		mat colnames spirpos = "_check" "_x" "_y"
		svmat spirpos, n(col)
	}

	// rescale all layouts to a common coordinate frame
	quietly summarize _x, meanonly
		local xmin = r(min)
		local xmax = r(max)
	quietly summarize _y, meanonly
		local ymin = r(min)
		local ymax = r(max)

	local xspan = `xmax' - `xmin'
	local yspan = `ymax' - `ymin'
	local span = `xspan'
	if (`yspan' > `span') local span = `yspan'
	local xmid = (`xmax' + `xmin') / 2
	local ymid = (`ymax' + `ymin') / 2

	replace _x = ((_x - `xmid') / `span') * `width'  + (`width' / 2)	if (`span' > 0) 
	replace _y = ((_y - `ymid') / `span') * `height' + (`height' / 2)	if (`span' > 0) 
	replace _x = `width' / 2											if (`span' <= 0) 
	replace _y = `height' / 2											if (`span' <= 0) 

	keep _id _x _y
	merge 1:1 _id using `_node_map'
	keep if _m==3
	drop _m
	
	sort _id	
	compress

	save `_layout_nodes'
	

	*******************************
	*** get the links in order  ***
	*******************************
	
	use `_network_copy', clear
	
	cap ren `f' _id

	merge m:1 _id using `_layout_nodes'
	keep if _m==3
	cap drop _m
	cap ren _x _fx
	cap ren _y _fy

	cap ren _id `f'
	cap ren `t' _id

	merge m:1 _id using `_layout_nodes'
	keep if _m==3
	cap drop _m
	cap ren _x _tx
	cap ren _y _ty
	cap ren _id `t'

	gen _control = 0

	// replace own flows
	gen _ownflow = `f'==`t'
	
	
	// noi di "Check 5"
	
	// reduce the length of the links by  r    
	
	
	tempvar dx dy p1x p1y p2x p2y L rate
	gen double `p1x' = _fx
	gen double `p1y' = _fy
	
	gen double `p2x' = _tx
	gen double `p2y' = _ty
	
	
	// reduce by a fixed length
	gen double `dx' = `p2x' - `p1x'
	gen double `dy' = `p2y' - `p1y'
	
	gen double `L' = sqrt((`p2x' - `p1x')^2 + (`p2y' - `p1y')^2)  // hypotenuse
	local deltaL   = `reduce'
	gen double `rate' = 0
	replace `rate' = `deltaL' / `L' if `L' > 0
	
	
	replace _fx = ((1 - `rate') * `p2x') + (`rate' * `p1x')
	replace _fy = ((1 - `rate') * `p2y') + (`rate' * `p1y')
	replace _tx = ((1 - `rate') * `p1x') + (`rate' * `p2x')
	replace _ty = ((1 - `rate') * `p1y') + (`rate' * `p2y')		
	
	
	drop `dx' `dy' `p1x' `p1y' `p2x' `p2y' `L' `rate'

	// generate mid points
	gen double _midx = _fx + 0.5 * (_tx - _fx) 
	gen double _midy = _fy + 0.5 * (_ty - _fy) 
	
	sort `f' `t'
	save `_network_copy', replace
	*save _temp.dta, replace
	
	// noi di "Check 6"
	
	// add the nodes with attributes 
	
	// add node attributes back to Stata
	use `_layout_nodes', clear
	mata st_matrix("exports", exports)
	mat colnames exports = `header'
	svmat exports, n(col)
	
	save `_layout_nodes', replace
		

	
	// add node data
	use  `_network_copy', replace
	
	append using `_layout_nodes'
	recode _control (.=1)

	sort _control _id
	
	lab de _control 0 "Links" 1 "Nodes"
	lab val _control _control
	
	local workfile  ""

	if "`save'" != "" {
		compress 
		cap drop _check
		
		cap label var _control "Type (0=Link, 1=Node)"
		cap label var _id "Node ID"
		cap label var _x "Node: X Coordinate"
		cap label var _y "Node: Y Coordinate"
		cap label var _label "Node Label"
		cap label var _ownflow "Link: =1 if from==to (self-loop)"

		cap label var _midx "Link Midpoint X Coordinate"
		cap label var _midy "Link Midpoint Y Coordinate"

		cap label var _lid "Link ID"
		cap label var _fx "Link: From Node X Coordinate"
		cap label var _fy "Link: From Node Y Coordinate"
		cap label var _tx "Link: To Node X Coordinate"
		cap label var _ty "Link: To Node Y Coordinate"

		cap label var degree "Degree Centrality"
		cap label var between "Betweenness Centrality"
		cap label var indegree "Indegree Centrality"
		cap label var outdegree "Outdegree Centrality"
		cap label var closeness "Closeness Centrality"
		cap label var harmonic "Harmonic Centrality"
		cap label var clustering "Clustering Coefficient"
		cap label var transit "Transitivity"
		cap label var eccentric "Eccentricity"
		cap label var eigenval "Eigenvalue Centrality"
		cap label var eigenvec "Eigenvector Centrality"
		cap label var katz "Katz Centrality"
		cap label var pagerank "PageRank"
		cap label var hub "HITS Hub Score"
		cap label var authority "HITS Authority Score"
		cap label var core "Core Number (Undirected)"
		cap label var reciprocity "Node Reciprocity"
		cap label var descendants "Descendants Count"
		cap label var ancestors "Ancestors Count"		

		order _control
		save "`saveprefix'.dta", `replace'
		noi di in yellow "File `saveprefix'.dta sucessfully exported."

		local workfile "`saveprefix'.dta"
	}


	************
	*** plot ***
	************

	
	if !`__has_nograph' {

		if "`format'" == "" local format "%9.2f"
		format `v' `format'

		***** weighted the links
		qui count if _control==0 & !missing(`v')
		local lobs = r(N)
		local lcats_eff = `lcats'
		if `lobs' > 0 {
			local lcats_eff = min(`lcats', `lobs' + 1)
		}
		if `lcats_eff' < 1 local lcats_eff = 1
		xtile lquant = `v' if _control==0, n(`lcats_eff')   // tokenize
			
		///////////////////////////
		// line palette controls //
		///////////////////////////

		if "`lcolor'" 	== "" local lcolor emidblue
 	
		if "`lpalette'" == "" local lpalette viridis


		if "`lprop'" == "" {
			local lpalette "`lcolor'"
		}
		else {
			tokenize "`lpalette'", p(",")
			local lpalette `1'
			local lpoptions `3'
		}	
			
		colorpalette `lpalette', n(`lcats_eff') `lpoptions' nograph
		
		forval i = 1/`lcats_eff' {
			local j = `lcats_eff' + 1 - `i' // reverse order so higher values are darker
			local lclr`i' "`r(p`j')'"
		}

		/////////////////////////////
		// marker palette controls //
		/////////////////////////////

		***** weighted the nodes
		if "`mvar'" != "" {
			cap confirm variable `mvar'
			if _rc {
				di as error "Variable `mvar' not found for node scaling."
				exit 111
			}
			qui count if _control==1 & !missing(`mvar')
			local mobs = r(N)
			local mcats_eff = `mcats'
			if `mobs' > 0 {
				local mcats_eff = min(`mcats', `mobs' + 1)
			}
			if `mcats_eff' < 1 local mcats_eff = 1

			xtile mquant = `mvar' if _control==1, n(`mcats_eff')
			replace mquant = 1 if _control==1 & missing(mquant)
		}
		else {
			// Default node color mapping: use the selected node metric.
			qui count if _control==1 & !missing(`node_metric')
			local mobs = r(N)
			local mcats_eff = `mcats'
			if `mobs' > 0 {
				local mcats_eff = min(`mcats', `mobs' + 1)
			}
			if `mcats_eff' < 1 local mcats_eff = 1

			if !`__has_nograph' & "`mvar'" == "" & ("`mprop'" != "" | "`mscale'" != "") {
				noi di in yellow "Note: {opt mvar()} not specified. Using {opt mvar(degree)} for node size."
			}	

			xtile mquant = `node_metric' if _control==1, n(`mcats_eff')
			replace mquant = 1 if _control==1 & missing(mquant)

		}

		if "`mpalette'" == "" local mpalette cividis
		if "`mcolor'" 	== "" local mcolor khaki

		if "`mprop'" == "" {
			local mpalette "`mcolor'"
		}
		else {
			tokenize "`mpalette'", p(",")
			local mpalette `1'
			local mpoptions `3'
		}	

		colorpalette `mpalette', n(`mcats_eff') `mpoptions' nograph
		
		forval i = 1/`mcats_eff' {
			local j = `mcats_eff' + 1 - `i' // reverse order so higher values are darker
			local mclr`i' "`r(p`j')'"
		}

		
		// Calculate and store node circle radii (quantile-weighted by the selected node metric)

		if "`mpoints'" == "" local mpoints 50

		summ `node_metric' if _control==1, meanonly
		local degmax = cond(r(max) > 0, r(max), 1)
		
		gen double _node_radius = .
		gen double _frad = .
		gen double _trad = .
		gen int _circquant = .

		levelsof _id if _control==1, local(lvls)
		local items = `mcats_eff'
		if `items' < 1 local items = 1

		foreach x of local lvls {
			summ mquant if _id==`x' & _control==1, meanonly
			local mq = cond(r(N)==0 | missing(r(mean)), 1, r(mean))

			if "`mscale'" != "" {
				local rad = `msize' * (`mq' / `items')^`mscalefactor' 
			}
			else {
				local rad = `msize'
			}
			replace _node_radius = `rad' if _id==`x' & _control==1
			
			summ _x if _id==`x' & _control==1, meanonly
			local _xmean = r(mean)
			
			summ _y if _id==`x' & _control==1, meanonly
			local _ymean = r(mean)

			replace _frad = `rad' if _control==0 & abs(_fx - `_xmean') < 1e-8 & abs(_fy - `_ymean') < 1e-8
			replace _trad = `rad' if _control==0 & abs(_tx - `_xmean') < 1e-8 & abs(_ty - `_ymean') < 1e-8

			capture confirm variable _circid
			if _rc {
				local cid_before = 0
			}
			else {
				qui summ _circid, meanonly
				local cid_before = cond(r(N)==0 | missing(r(max)), 0, r(max))
			}

			shapes circle, radius(`rad') x0(`_xmean') y0(`_ymean') append genx(_circx) n(`mpoints') geny(_circy) genid(_circid) genorder(_circorder) rotate(`mrotate') 

			capture confirm variable _circid
			if _rc {
				local cid_after = `cid_before'
			}
			else {
				qui summ _circid, meanonly
				local cid_after = cond(r(N)==0 | missing(r(max)), `cid_before', r(max))
			}
			replace _circquant = `mq' if _circid > `cid_before' & _circid <= `cid_after'
		}
		
		replace _frad = 0.04 if _control==0 & missing(_frad)
		replace _trad = 0.04 if _control==0 & missing(_trad)
		
		// Trim link endpoints to circle boundaries using node radii
		gen double _ldx = _tx - _fx if _control==0
		gen double _ldy = _ty - _fy if _control==0
		gen double _llen = sqrt(_ldx^2 + _ldy^2) if _control==0
		gen double _cut = _frad + _trad if _control==0
		gen double _trim_ok = (_llen > _cut) if _control==0

		gen double _fx_edge = cond(_trim_ok, _fx + (_frad / _llen) * _ldx, (_fx + _tx) / 2) if _control==0
		gen double _fy_edge = cond(_trim_ok, _fy + (_frad / _llen) * _ldy, (_fy + _ty) / 2) if _control==0
		gen double _tx_edge = cond(_trim_ok, _tx - (_trad / _llen) * _ldx, (_fx + _tx) / 2) if _control==0
		gen double _ty_edge = cond(_trim_ok, _ty - (_trad / _llen) * _ldy, (_fy + _ty) / 2) if _control==0
		

		///////////
		// Plot  //
		///////////


		
		local arrowheads ""
		local circles ""
		
		// weighted lines
		if "`arc'" != "" {
			// generate arc coordinates for each link
			gen double _arcx    = .
			gen double _arcy    = .
			gen long   _arcid   = .
			gen long   _arcorder = .
			gen        _arcsize = .
			gen double _arclabel = -999
			
			local arccount = 1
			levelsof _lid if _control==0 & !_ownflow, local(lid_lvls)
			
			
			foreach lid of local lid_lvls {
				
				
				summ _fx_edge if _lid==`lid' & _control==0, meanonly
				local x1 = r(mean)
				summ _fy_edge if _lid==`lid' & _control==0, meanonly
				local y1 = r(mean)
				summ _tx_edge if _lid==`lid' & _control==0, meanonly
				local x2 = r(mean)
				summ _ty_edge if _lid==`lid' & _control==0, meanonly
				local y2 = r(mean)
				summ lquant if _lid==`lid' & _control==0, meanonly
				local lq = r(mean)
				summ `v' if _lid==`lid' & _control==0 , meanonly
				local vlab = r(mean)
				
				local arcopts ""
				if "`arcradius'" != "" local arcopts "radius(`arcradius')"
				arc, x1(`x2') y1(`y2') x2(`x1') y2(`y1') `arcopts' ///
					 genx(_arcx) geny(_arcy) genid(_arcid) genorder(_arcorder) ///
					 n(`arcn') append
				
				replace _arclabel = `vlab' if _arcid==`arccount' & missing(_arclabel) & `vlab' >= `valcondition'
				replace _arcsize = `lq' if _arcid==`arccount' & missing(_arcsize)

				local ++arccount
			}
			format _arclabel `format'
			
			// Extract arrowhead coordinates from last two arc points
			cap drop _arrow*
			cap drop _arclab_x _arclab_y
			
			gen double _arrow_prev_x = .
			gen double _arrow_prev_y = .
			gen double _arrow_last_x = .
			gen double _arrow_last_y = .
			gen double _arclab_x = .
			gen double _arclab_y = .
			local arclaborder = ceil(`arcn' / 2)
			
			replace _arrow_last_x = _arcx 		if _arcorder==`arcn'
			replace _arrow_last_y = _arcy 		if _arcorder==`arcn'
			replace _arrow_prev_x = _arcx[_n-1] if _arcorder==`arcn'
			replace _arrow_prev_y = _arcy[_n-1] if _arcorder==`arcn'
			replace _arclab_x = _arcx 		if _arcorder==`arclaborder' & _arclabel >= `valcondition'
			replace _arclab_y = _arcy 		if _arcorder==`arclaborder' & _arclabel >= `valcondition'
			
			// build line plots for each weighted category
			levelsof lquant if _control==0, local(lvls)
			local items = r(r)

			foreach x of local lvls {
				if "`lscale'" != "" {
					local lwgt = `lwidth' * (`x' / `items')^`lscalefactor' 
				}
				else {
					local lwgt = `lwidth'
				}
				local arrows `arrows' (line _arcy _arcx if _arcsize==`x', cmissing(n) lw(`lwgt') lc("`lclr`x''%`lalpha'"))

				local arrowheads `arrowheads' (pcarrow _arrow_prev_y _arrow_prev_x _arrow_last_y _arrow_last_x if _arcorder==`arcn' & _arcsize==`x', msize(`arrowsize') mcolor("`lclr`x''%`lalpha'") lw(`lwgt')  lc("`lclr`x''%`lalpha'"))

			}
			
			if "`novalues'" == ""  {
				levelsof lquant if _control==0 , local(lvls)
				foreach x of local lvls {
					local linkdots `linkdots' (scatter _arclab_y _arclab_x if _arcsize==`x' & _arcorder==`arclaborder' & _arclabel >= `valcondition', msymbol(none) msize(zero) mlabpos(0) mcolor(none) mlab(_arclabel) mlabsize(`llabsize') mlabcolor(`llabcolor'))
				}
			}
			

		}
		else {
			// straight pcarrow path (default) - using trimmed edges
			levelsof lquant, local(lvls)
			local items = r(r)

			foreach x of local lvls {
				if "`lscale'" != "" {
					local lwgt = `lwidth' * (`x' / `items')^`lscalefactor' 
				}
				else {
					local lwgt = `lwidth'
				}
				
				local arrows `arrows' (pcarrow _ty_edge _tx_edge _fy_edge _fx_edge  if !_ownflow & lquant==`x' & _control==0, msize(`arrowsize') lw(`lwgt') lc("`lclr`x''%`lalpha'") mc("`lclr`x''%`lalpha'")  ) 
				
				if "`novalues'" == "" {
					local linkdots `linkdots' (scatter _midy _midx if !_ownflow & lquant==`x' & _control==0 & `v' >= `valcondition', msymbol(none) msize(zero) mlabpos(0) mcolor(none) mlab(`v') mlabsize(`llabsize') mlabcolor(`llabcolor')  ) 
				}
			}
		}
	

		// draw circles via area shapes (sized by degree), colored by node quantiles
		forval x = 1/`mcats_eff' {

			if "`mlcolor'" != "" {
				if regexm("`mlcolor'", "%[0-9]+$") {
					local _mclr "`mlcolor'"
				}
				else {
					local _mclr "`mlcolor'%`mlalpha'"
				}
			}
			else {
				local _mclr "`mclr`x''%`mlalpha'"
			}

			local circles `circles' (area _circy _circx if _circquant==`x', nodropbase cmissing(no) fi(100) fc("`mclr`x''%`malpha'") lc("`_mclr'") lw(`mlwidth'))
		}

		// weighted nodes

		// labels only - circles drawn via area above
		local dots (scatter _y _x if _control, msymbol(none) mlabpos(0) mlab(_label) mlabsize(`mlabsize') mlabcolor(`mlabcolor') )
	
	
	
		// Calculate min/max bounds for equal axis scaling with aspect(1)
		quietly {
			summ _x, meanonly
			local xmin = r(min)
			local xmax = r(max)
			summ _y, meanonly
			local ymin = r(min)
			local ymax = r(max)
			
			// Expand to include edge coordinates
			summ _fx_edge, meanonly
			local xmin = min(`xmin', r(min))
			local xmax = max(`xmax', r(max))
			summ _tx_edge, meanonly
			local xmin = min(`xmin', r(min))
			local xmax = max(`xmax', r(max))
			summ _fy_edge, meanonly
			local ymin = min(`ymin', r(min))
			local ymax = max(`ymax', r(max))
			summ _ty_edge, meanonly
			local ymin = min(`ymin', r(min))
			local ymax = max(`ymax', r(max))
			
			// Expand to include circle coordinates
			summ _circx, meanonly
			local xmin = min(`xmin', r(min))
			local xmax = max(`xmax', r(max))
			summ _circy, meanonly
			local ymin = min(`ymin', r(min))
			local ymax = max(`ymax', r(max))
			
			// Set equal range for both axes
			local range_min = min(`xmin', `ymin')
			local range_max = max(`xmax', `ymax')
			local range_str `range_min' `range_max'
		}
	
	
	
	
		twoway ///
		`arrows'   /// 
		`arrowheads'   ///
		`circles'   ///
		`linkdots'   ///
		`dots'   /// 
		, ///
		legend(off) ///
			xscale(off range(`range_str')) yscale(off range(`range_str'))	///
			xlabel(, nogrid) ylabel(, nogrid) ///
			aspect(1) xsize(1) ysize(1) `options'
	

	

	}
	}
	
restore	
	
end


**** Shell layout ****

mata:

real matrix shell_layout(real matrix A, real scalar width, real scalar height)
{
	real scalar N, i, n_inner, n_outer, cx, cy, r_inner, r_outer
	real vector deg, order, inner_idx, outer_idx
	real matrix pos

	N = rows(A)
	if (N == 1) return((1, width/2, height/2))

	pos = J(N, 2, 0)
	cx = width / 2
	cy = height / 2

	// Build two shells using undirected degree: top half inner, rest outer.
	deg = rowsum(A :+ A')
	order = order(-deg, 1)
	n_inner = ceil(N / 2)
	n_outer = N - n_inner

	inner_idx = order[|1 \ n_inner|]
	if (n_outer > 0) outer_idx = order[|n_inner + 1 \ N|]
	else outer_idx = J(0, 1, .)

	r_inner = 0.35 * min((width, height))
	r_outer = 0.50 * min((width, height))

	for (i = 1; i <= n_inner; i++) {
		pos[inner_idx[i], 1] = cx + r_inner * cos(2 * pi() * (i - 1) / n_inner)
		pos[inner_idx[i], 2] = cy + r_inner * sin(2 * pi() * (i - 1) / n_inner)
	}

	for (i = 1; i <= n_outer; i++) {
		pos[outer_idx[i], 1] = cx + r_outer * cos(2 * pi() * (i - 1) / n_outer)
		pos[outer_idx[i], 2] = cy + r_outer * sin(2 * pi() * (i - 1) / n_outer)
	}

	return((1::N), pos)
}

end



**** Spiral layout ****

mata:

real matrix spiral_layout(real matrix A, real scalar width, real scalar height)
{
	real scalar N, i, cx, cy, tmax, t, rmax, r
	real matrix pos

	N = rows(A)
	if (N == 1) return((1, width/2, height/2))

	pos = J(N, 2, 0)
	cx = width / 2
	cy = height / 2
	tmax = 4 * pi()
	rmax = 0.5 * min((width, height))

	for (i = 1; i <= N; i++) {
		t = (i - 1) * tmax / (N - 1)
		r = rmax * (i - 1) / (N - 1)
		pos[i, 1] = cx + r * cos(t)
		pos[i, 2] = cy + r * sin(t)
	}

	return((1::N), pos)
}

end


*************************************************
*********	 Mata routines below 	   **********
*************************************************


*************************
// 	   square a list   //  
*************************

mata: // square()
real matrix square(real matrix X)
	{
		real scalar maxsize
		real matrix sqr
	
		maxsize = max(uniqrows(vec(X[.,1::2])))
		sqr =  J(maxsize, maxsize, .)

		for ( i=1; i<=maxsize; i++) {
		 	for ( j=1; j<=maxsize; j++) {
		 		sqr[i,j] = min(select(X[.,3], (X[.,1] :== i :& X[.,2] :== j)))
		 	}
		}

		sqr = editmissing(sqr, 0)
		return (sqr)
	}
end

*************************
// 	  binary matrix    //  
*************************

mata:  // binary()
real matrix binary(real matrix X)
	{
	return (X :> 0)
	}
end

mata:  // edgecost()
real matrix edgecost(real matrix X)
	{
		real scalar i, j
		real matrix C

		C = J(rows(X), cols(X), 0)
		for (i=1; i<=rows(X); i++) {
			for (j=1; j<=cols(X); j++) {
				if (X[i,j] > 0) C[i,j] = 1 / X[i,j]
			}
		}
		return (C)
	}
end


***************
// dequeue   //  // stacking function from nwcommands
***************

mata:

real scalar function dequeue(real vector A)
{
	a = A[1]
	for (i=1; i < cols(A); i++) { 
		A[i] = A[i+1]
	}
	if (cols(A) == 1) { 
		A = J(1,0,.)
	}
	else {
		A = A[1..cols(A) - 1]
	}
	return (a)
}

end



****************
//  between   // 
****************


mata:

real vector between(real matrix A)
{

	adjacencyList = J(rows(A), rows(A) - 1, .)
	
	for (m=1; m<=rows(A); m++) {
		k = 1
		for ( n=1; n<=rows(A); n++) {
			if ( m!=n & A[m,n]>0) adjacencyList[m, k++] = n
		}
    }
	
	betcen = J(1, rows(A),0)
	for (s=1; s<=rows(A); s++) {
		Stack = J(1,0,.)
		P     = J(rows(A),rows(A),.)
		nP    = J(rows(A),1,1)
		S     = J(1,rows(A),0)
		S[s]  = 1
		D     = J(1,rows(A),-1)
		D[s]  = 0
		Queue = J(1,0,.)
		Queue = (cols(Queue) ? Queue, s : s)
		
		while (cols(Queue)) {
			v 		= dequeue(Queue)
			Stack 	= (cols(Stack)? v,Stack : v)
			
			for (j=1; j<=sum(adjacencyList[v,.] :< .); j++) {
				
				w = adjacencyList[v,j]
				if (D[w] < 0) {
					Queue = (cols(Queue) ? Queue, w : w)
					D[w] = D[v] + 1
				}
				if (D[w] == D[v] + 1) {
					S[w]        = S[w] + S[v]
					P[w, nP[w]] = v;
					nP[w]       = nP[w]+1
				}     
			}	
		}
		
		Dd = J(1,rows(A),0)
		
		while (cols(Stack)) {
			w = dequeue(Stack)
  
			for (j=1; j<nP[w]; j++) {
				v     = P[w,j]
				Dd[v] = Dd[v] + (S[v] / S[w]) * (1 + Dd[w])
			}
			if (w != s) betcen[w] = betcen[w] + Dd[w]
		}
	}
	return (betcen')
}
end



mata:
real matrix betweenness(real matrix G, real matrix weighted, real scalar wgt)
{
	real scalar num, s
	real matrix between, P, sigma, D, S
	num = rows(G)

	between = J(num,1,0)
	S = D = sigma = P = .
	
	for (s=1; s<=num; s++) {
		
		if (wgt == 0) {
			_shortest_path(G, s,         S, D, sigma, P)
		}
		else {
			_dijkstra_path(G, s, weighted, S, D, sigma, P)
		}
				
		// accumulate
		between = _accumulate_basic(between, S, P, sigma, s)
		
	}
	
	between = _rescale(between, num, 1, 1, 0, 0) // between, nodes, normalized, directed, k, endpoints
	return (between)
		
}
end

*****************************
***** subroutines below *****
*****************************

mata:
void _shortest_path(real matrix G, real scalar s, real vector S, real vector D, real vector sigma, real matrix P)   
{
    real scalar n, currentNode, i, firstMissing, neighbor
    real matrix Q, neighbors
    
	n = rows(G)
    
    // 1. Initialization
    S = J(0, 1, .)   // visited nodes     
    P = J(n, n, .)   // path dictionary
	sigma = J(n, 1, 0)   // count of shortest paths
	D = J(n, 1, .)   // distance - initialized to missing
    
	sigma[s] = 1
    D[s] = 0     // source distance is 0
    Q = J(1, 1, s)  // queue with source
	
    // 2. BFS Traversal
    while (length(Q) > 0) {
        currentNode = Q[1]
		
		if (length(Q) > 1) {
			Q = Q[2..rows(Q), 1]
		} 
		else {
			Q = J(0, 1, .) 
		}

        S = S \ currentNode
		neighbors = selectindex(G[currentNode,.])

        for (i = 1; i <= length(neighbors); i++) {
            neighbor = neighbors[i]

			// Only process if not yet visited
			if (missing(D[neighbor])) {         					
				Q = Q \ neighbor
				D[neighbor] = D[currentNode] + 1
                sigma[neighbor] = sigma[currentNode]
				firstMissing = selectindex(P[neighbor, .] :== .)[1]
				P[neighbor, firstMissing] = currentNode
            }
			else if (D[neighbor] == D[currentNode] + 1) {
				// Multiple shortest paths to this node
				sigma[neighbor] = sigma[neighbor] + sigma[currentNode]				
				firstMissing = selectindex(P[neighbor, .] :== .)[1]
				P[neighbor, firstMissing] = currentNode
            }
		}        
    }
}
end


mata:
void _dijkstra_path(real matrix G, real scalar s, real matrix weighted, real vector S, real vector D, real vector sigma, real matrix P)
{
 
	real scalar idx, v, min_dist, dist, pred, w, vw_dist, firstMissing
	real matrix seen, Q
	real vector done
 
    D = J(rows(G), 1, .)  
    sigma = J(rows(G), 1, 0)
    S = J(0, 1, .)
	P = J(rows(G), rows(G), .)
    seen = J(cols(G), 1, .)
	done = J(rows(G), 1, 0)
    
    sigma[s] = 1
    seen[s] = 0     // Mark source as seen
    Q = (0, s, s)   // distance, node, node (pred not used initially)
    
    while (rows(Q)) {
        min_dist = min(Q[.,1])
        idx = (Q[.,1] :== min_dist)[1]
        dist = Q[idx, 1]
		v = Q[idx, 2]
        
        // Remove from Q
		if (rows(Q) == 1) {
			Q = J(0, 3, .)
		} 
		else if (idx == 1) {
			Q = Q[2::rows(Q), .]
		}
		else {
			Q = Q[1::idx-1, .] \ Q[idx+1::rows(Q), .]
		}
        
		// Skip if already finalized
		if (done[v]) {
            continue
        }
		done[v] = 1
		S = S \ v
        
        D[v] = dist
        
		for (w = 1; w <= cols(G); w++) {
			if (G[v, w] == 1) {
                vw_dist = dist + weighted[v, w]
                
				// If w not yet finalized
                if (!done[w]) {
                    
					// First time seeing this node or found shorter path
					if (missing(seen[w]) | vw_dist < seen[w]) {
                        seen[w] = vw_dist
                        sigma[w] = sigma[v]
                        Q = Q \ (vw_dist, w, v)
                        Q = sort(Q, 1)
                        firstMissing = selectindex(P[w, .] :== .)[1]
                        P[w, firstMissing] = v
					}
					// Equal cost path found
                    else if (vw_dist == seen[w]) {
                        sigma[w] = sigma[w] + sigma[v]
                        firstMissing = selectindex(P[w, .] :== .)[1]
                        P[w, firstMissing] = v
                    }
                }
            }
        }	
    }
}
end


cap mata mata drop _accumulate_basic()

mata:
real matrix _accumulate_basic(real matrix betweenness, real matrix S, real matrix P, real matrix sigma, real scalar s)
{
    real scalar w, coeff, v, i, num_preds
	real matrix delta
	
    delta = J(rows(P), 1, 0)

    while (rows(S)) {
        w = S[rows(S)]
        
		if (rows(S) > 1) {
			S = S[1..rows(S)-1]
		}
		else {
			S = J(0, 1, .)
		}

        // Check for zero sigma to avoid division by zero
		if (sigma[w] > 0) {
			coeff = (1 + delta[w]) / sigma[w]
		}
		else {
			coeff = 0
		}

        // Get predecessors: count non-missing values in row w of P
		num_preds = sum(P[w,.] :!= .)		
		
        for (i = 1; i <= num_preds; i++) {
			v = P[w, i]
			
			// Validate predecessor node index
			if (v > 0 & v <= rows(P) & sigma[v] > 0) {
				delta[v] = delta[v] + (sigma[v] * coeff)
			}
        }		

        if (w != s) {
            betweenness[w] = betweenness[w] + delta[w]
        }
    }
	
	return (betweenness)
}
end

mata
real matrix _rescale(real matrix betweenness, real scalar n, real scalar normalized, real scalar directed, real scalar k, real scalar endpoints)
{
    real scalar scale

    if (normalized) {
        if (endpoints) {
            if (n < 2) {
                scale = 1 
            }
            else {
                scale = 1 / (n * (n - 1))
            }
        }
        else if (n <= 2) {
            scale = 1
        }
        else {
            scale = 1 / ((n - 1) * (n - 2))
        }
		if (!directed) scale = 2 * scale
    }
    else {
        if (!directed) {
            scale = 0.5
        }
        else {
            scale = 1
        }
    }

    if (scale != 1) {
        if (k != 0) {
            scale = scale * n / k
        }
    }

	return (betweenness * scale)
}

end



////////////////////////
// undirected degree  //
////////////////////////


mata:
real vector degree(real matrix X) {
    num 	= rows(X)
    degree 	= J(num, 1, 0)
	
	for (i=1; i<=num; i++) { 
        degree[i] = colsum(X[.,i]) +  colsum(X'[.,i])   // indegree + outdegree
    }
    return (degree)
}
end

////////////////////////
// 		indegree  	  //
////////////////////////

mata:
real vector indegree(real matrix X) {
    num 		= rows(X)
    indegree 	= J(num, 1, 0)
	
	for (i=1; i<=num; i++) { 
        indegree[i] = colsum(X[.,i]) 
    }
    return (indegree)
}
end

////////////////////////
// 		outdegree  	  //
////////////////////////

cap mata: mata drop outdegree()

mata:
real vector outdegree(real matrix X) {
    num 		= rows(X)
    outdegree 	= J(num, 1, 0)
	
	for (i=1; i<=num; i++) { 
        outdegree[i] = colsum(X'[.,i]) 
    }
    return (outdegree)
}
end


////////////////////////////////////
// 		breadth first search 	  //  
////////////////////////////////////


cap mata: mata drop BFS()    // Breadth-First Search algorithm: https://en.wikipedia.org/wiki/Breadth-first_search

mata:

real vector BFS(real matrix G, real scalar source) 
{
    real scalar N, level
    real vector seen, dists
    real matrix thislevel, nextlevel

    N = rows(G)
    seen  = J(N, 1, .)  // Initialize with missing values
    dists = J(N, 1, .) // Distances initialized to missing
    level = 0
    thislevel = J(N, 1, 0)
    nextlevel = J(N, 1, 0)
    nextlevel[source] = 1

    while (sum(nextlevel) > 0) {
        thislevel = nextlevel
        nextlevel = J(N, 1, 0)

        for (i=1; i<=N; i++) {
            if (thislevel[i] == 1 & missing(seen[i])) {
                seen[i]  = 1
                dists[i] = level
                for (j=1; j<=N; j++) {
                    if (G[i,j] == 1 & missing(seen[j])) {
                        nextlevel[j] = 1
                    }
                }
            }
        }
        level++
    }
    return (dists)
}
end


mata:
real vector descendants_count(real matrix G) {

	real scalar N, i
	real vector out, d

	N = rows(G)
	out = J(N, 1, 0)

	for (i=1; i<=N; i++) {
		d = BFS(G, i)
		out[i] = sum(d :< .) - 1
	}

	return (out)
}
end


mata:
real vector ancestors_count(real matrix G) {

	real scalar N, i
	real vector out, d

	N = rows(G)
	out = J(N, 1, 0)

	for (i=1; i<=N; i++) {
		d = BFS(G', i)
		out[i] = sum(d :< .) - 1
	}

	return (out)
}
end


mata:
real vector reciprocity_node(real matrix G) {

	real scalar N, i, n_total, n_overlap
	real vector out
	real vector pred, succ

	N = rows(G)
	out = J(N, 1, 0)

	for (i=1; i<=N; i++) {
		pred = (G[., i] :> 0)
		succ = (G[i, .]' :> 0)
		n_total = sum(pred) + sum(succ)
		if (n_total > 0) {
			n_overlap = sum(pred :& succ)
			out[i] = (2 * n_overlap) / n_total
		}
		else {
			out[i] = 0
		}
	}

	return (out)
}
end


mata:
real vector core_number_undirected(real matrix G) {

	real scalar N, i, j, k, changed, remaining
	real vector core, deg, alive
	real matrix U

	N = rows(G)
	U = (G :+ G') :> 0
	core = J(N, 1, 0)
	alive = J(N, 1, 1)
	deg = rowsum(U)'
	remaining = N
	k = 0

	while (remaining > 0) {
		changed = 1
		while (changed) {
			changed = 0
			for (i=1; i<=N; i++) {
				if (alive[i] & deg[i] <= k) {
					alive[i] = 0
					core[i] = k
					remaining = remaining - 1
					for (j=1; j<=N; j++) {
						if (alive[j] & U[i, j] == 1) deg[j] = deg[j] - 1
					}
					changed = 1
				}
			}
		}
		if (remaining > 0) k = k + 1
	}

	return (core)
}
end


////////////////////////////////////
// 		dijkstra distances 	  //
////////////////////////////////////


mata:
real vector dijkstra_distances(real matrix G, real matrix W, real scalar source)
{
	real scalar N, iter, u, v, best, alt
	real vector dist, done

	N = rows(G)
	dist = J(N, 1, .)
	done = J(N, 1, 0)
	dist[source] = 0

	for (iter=1; iter<=N; iter++) {
		u = .
		best = .

		for (v=1; v<=N; v++) {
			if (!done[v] & !missing(dist[v])) {
				if (missing(best) | dist[v] < best) {
					best = dist[v]
					u = v
				}
			}
		}

		if (missing(u)) break
		done[u] = 1

		for (v=1; v<=N; v++) {
			if (G[u,v] == 1 & W[u,v] > 0) {
				alt = dist[u] + W[u,v]
				if (missing(dist[v]) | alt < dist[v]) dist[v] = alt
			}
		}
	}

	return (dist)
}
end


////////////////////////////////////
// 		closeness centrality  	  //  // failing for dangling nodes.
////////////////////////////////////


mata:
real vector closeness_centrality(real matrix G) {

    real matrix closeness, bfs_lengths, reachable
    real scalar nreach

    N = rows(G)
    closeness = J(N, 1, .)

    for (i=1; i<=N; i++) {
        // For directed graphs, use inward distances to match standard definition.
		bfs_lengths = BFS(G', i)
		reachable = select(bfs_lengths, bfs_lengths :< .)
		nreach = rows(reachable)
		if (nreach <= 1) {
			closeness[i] = 0
		}
		else {
			closeness[i] = ((nreach - 1) / sum(reachable)) * ((nreach - 1) / (N - 1))
		}
    }
	
    return (closeness)
}
end

////////////////////////////////////
// 		harmonic centrality  	  //
////////////////////////////////////


mata:
real vector harmonic_centrality(real matrix G) {

    real matrix harmonic, bfs_lengths, reachable

    N = rows(G)
    harmonic = J(N, 1, 0)

    for (i=1; i<=N; i++) {
		// For directed graphs, use inward distances to match standard definition.
		bfs_lengths = BFS(G', i)
		reachable = select(bfs_lengths, bfs_lengths :< .)
		reachable = select(reachable, reachable :> 0)
		if (rows(reachable) > 0) {
			harmonic[i] = sum(1 :/ reachable)
		}
    }
	
    return (harmonic)
}
end


mata:
real vector closeness_centrality_w(real matrix G, real matrix W) {

	real matrix closeness, d_lengths, reachable
	real scalar nreach

	N = rows(G)
	closeness = J(N, 1, .)

	for (i=1; i<=N; i++) {
		d_lengths = dijkstra_distances(G', W', i)
		reachable = select(d_lengths, d_lengths :< .)
		nreach = rows(reachable)
		if (nreach <= 1) {
			closeness[i] = 0
		}
		else {
			closeness[i] = ((nreach - 1) / sum(reachable)) * ((nreach - 1) / (N - 1))
		}
	}

	return (closeness)
}
end


mata:
real vector harmonic_centrality_w(real matrix G, real matrix W) {

	real matrix harmonic, d_lengths, reachable

	N = rows(G)
	harmonic = J(N, 1, 0)

	for (i=1; i<=N; i++) {
		d_lengths = dijkstra_distances(G', W', i)
		reachable = select(d_lengths, d_lengths :< .)
		reachable = select(reachable, reachable :> 0)
		if (rows(reachable) > 0) {
			harmonic[i] = sum(1 :/ reachable)
		}
	}

	return (harmonic)
}
end

////////////////////////////////////
// 	clustering coefficient 	  //
////////////////////////////////////

mata:
real vector clustering_coefficient(real matrix G) {

    real scalar N, i, j, k, possible, actual, m
    real vector clustering, neighbors

    N = rows(G)
    clustering = J(N, 1, 0)

    for (i=1; i<=N; i++) {
        neighbors = selectindex((G[i,.] :+ G[.,i]') :> 0)
		k = length(neighbors)
		
		if (k < 2) {
			clustering[i] = 0
		}
		else {
			possible = k * (k - 1)
			actual = 0
			
			for (j=1; j<=k-1; j++) {
				for (m=j+1; m<=k; m++) {
					if (G[neighbors[j], neighbors[m]] > 0 | G[neighbors[m], neighbors[j]] > 0) {
						actual = actual + 1
					}
				}
			}
			
			clustering[i] = (2 * actual) / possible
		}
    }
	
    return (clustering)
}
end


mata:
real vector clustering_coefficient_directed(real matrix G) {

	real scalar N, i, j, m, dt, db, denom, tri_count
	real scalar nij, nim, njm
	real vector clustering, neighbors

	N = rows(G)
	clustering = J(N, 1, 0)

	for (i=1; i<=N; i++) {
		neighbors = selectindex((G[i,.] :+ G[.,i]') :> 0)
		dt = length(neighbors)

		if (dt < 2) {
			clustering[i] = 0
			continue
		}

		db = 0
		for (j=1; j<=dt; j++) {
			if (G[i, neighbors[j]] > 0 & G[neighbors[j], i] > 0) db = db + 1
		}

		denom = 2 * (dt * (dt - 1) - 2 * db)
		if (denom <= 0) {
			clustering[i] = 0
			continue
		}

		tri_count = 0
		for (j=1; j<=dt; j++) {
			for (m=1; m<=dt; m++) {
				if (j != m) {
					nij = G[i, neighbors[j]] + G[neighbors[j], i]
					nim = G[i, neighbors[m]] + G[neighbors[m], i]
					njm = G[neighbors[j], neighbors[m]] + G[neighbors[m], neighbors[j]]
					tri_count = tri_count + (nij * nim * njm)
				}
			}
		}

		clustering[i] = tri_count / denom
	}

	return (clustering)
}
end

////////////////////////////////////
// 		transitivity  			  //
////////////////////////////////////

mata:
real scalar transitivity(real matrix G) {

    real scalar N, i, j, k, triangles, triples, m, possible
    real matrix U
    real vector neighbors

    N = rows(G)
    triangles = 0
    triples = 0
	U = (G :+ G') :> 0

    for (i=1; i<=N; i++) {
		neighbors = selectindex(U[i,.])
		k = length(neighbors)
		
		if (k >= 2) {
			possible = k * (k - 1) / 2
			triples = triples + possible
			
			for (j=1; j<=k-1; j++) {
				for (m=j+1; m<=k; m++) {
					if (U[neighbors[j], neighbors[m]] > 0) {
						triangles = triangles + 1
					}
				}
			}
		}
    }
	
	if (triples == 0) return(0)
    return (triangles / triples)
}
end

////////////////////////////////////
// 		eccentricity  			  //
////////////////////////////////////

mata:
real vector eccentricity(real matrix G) {

    real matrix eccentric, bfs_lengths, reachable
	real matrix U

    N = rows(G)
    eccentric = J(N, 1, .)
	U = (G :+ G') :> 0

    for (i=1; i<=N; i++) {
		// Eccentricity is computed on undirected connectivity to avoid direction-only inflation.
        bfs_lengths = BFS(U, i)
		reachable = select(bfs_lengths, bfs_lengths :< .)
		if (rows(reachable) <= 1) {
			eccentric[i] = .
		}
		else {
			eccentric[i] = max(reachable)
		}
    }
	
    return (eccentric)
}
end


mata:
real vector eccentricity_w(real matrix G, real matrix W) {

	real matrix eccentric, d_lengths, reachable
	real matrix U, UW

	N = rows(G)
	eccentric = J(N, 1, .)
	U = (G :+ G') :> 0
	UW = J(rows(W), cols(W), 0)

	for (i=1; i<=rows(W); i++) {
		for (j=1; j<=cols(W); j++) {
			if (U[i,j] == 1) {
				if (W[i,j] > 0 & W[j,i] > 0) {
					if (W[i,j] < W[j,i]) UW[i,j] = W[i,j]
					else UW[i,j] = W[j,i]
				}
				else if (W[i,j] > 0) UW[i,j] = W[i,j]
				else if (W[j,i] > 0) UW[i,j] = W[j,i]
			}
		}
	}

	for (i=1; i<=N; i++) {
		d_lengths = dijkstra_distances(U, UW, i)
		reachable = select(d_lengths, d_lengths :< .)
		if (rows(reachable) <= 1) {
			eccentric[i] = .
		}
		else {
			eccentric[i] = max(reachable)
		}
	}

	return (eccentric)
}
end


////////////////////////////////////
// 		eigenvalue centrality  	  //
////////////////////////////////////

mata:
real vector eigenvalue_centrality(real matrix G, real scalar max_iter, real scalar tol) {

    real vector x, x_new
	real scalar normx, normx_new, diff

    N = rows(G)
    x = J(N, 1, 1)
	normx = sqrt(sum(x:^2))
	if (normx > 0) x = x :/ normx

    for (i=1; i<=max_iter; i++) {
        x_new = G * x
		normx_new = sqrt(sum(x_new:^2))
		if (normx_new > 0) x_new = x_new :/ normx_new

        diff = sqrt(sum((x_new :- x):^2))
        if (diff < tol) break

        x = x_new
    }

    return (x)
}
end

////////////////////////////////////
// 		eigenvector centrality    //   // check. Not so sure about this.
////////////////////////////////////

 
mata: 
 
real vector eigenvectorcent(real matrix A)
{
    complex matrix X, L
	real vector ev
	real scalar idx, denom

    eigensystem(A, X=., L=.)
	idx = selectindex(Re(L) :== max(Re(L)))[1]
	ev = Re(X[., idx])
	denom = sum(abs(ev))
	if (denom > 0) ev = ev :/ denom

	return (ev)
}
end

////////////////////////////////
// 		katz centrality  	  //
////////////////////////////////

 
mata: 
 
real vector katz_centrality(real matrix G, real scalar alpha, real scalar beta)   // alpha and beta are open parameters
{
	real scalar norm_k
	// Use inbound influence for directed graphs: x = alpha * G' * x + beta.
	katz = beta * luinv(I(rows(G)) - alpha * G') * J(rows(G), 1, 1)
	norm_k = sqrt(sum(katz:^2))
	if (norm_k > 0) katz = katz :/ norm_k
    return (katz)
}

end

////////////////////////////////
// 		pagerank              //  // need more testing for dangling node: out degree = 0
////////////////////////////////
 
mata: 
 
real matrix pagerank(real matrix G, real scalar alpha, real scalar max_iter, real scalar tol)
{
    real scalar iter, n, nbr, wt, N
	real matrix W, x, p, dangling_weights, dangling_nodes, xlast, danglesum, row_sums
    
    N = rows(G)
	W = G
	
	row_sums = rowsum(W)
	dangling_nodes = selectindex(row_sums :== 0)
	row_sums = row_sums + (row_sums :== 0)
    W = W :/ row_sums
	
	x = J(N, 1, 1/N)
	p = J(N, 1, 1/N)
	dangling_weights = p
	
    for (iter=1; iter<=max_iter; iter++) {
        xlast = x
        x = J(N, 1, 0)

		danglesum = alpha * (rows(dangling_nodes) ? sum(xlast[dangling_nodes]) : 0)

        for (n=1; n<=N; n++) {
            for (nbr=1; nbr<=N; nbr++) {
                if (W[n, nbr] != 0) {
                    wt = W[n, nbr]
					x[nbr] = x[nbr] + alpha * xlast[n] * wt
                }
            }
            x[n] = x[n] + danglesum * dangling_weights[n] + (1 - alpha) * p[n]
        }

		if (sum(abs(x - xlast)) < (N * tol)) {
			return (x)
        }
    }
	return (x)
}
end


/////////////////////
// 		HITS       //
/////////////////////

 
mata: 
 
// Define the HITS function
    void hits(real matrix A, real scalar max_iter, real scalar tol, real vector hub, real vector aut)
    {
		complex matrix Xh, Lh, Xa, La
		real matrix Ah, Aa
		real scalar idxh, idxa, norm_h, norm_a

		// Principal right eigenvectors of A*A' (hubs) and A'*A (authorities).
		Ah = A * A'
		Aa = A' * A

		eigensystem(Ah, Xh=., Lh=.)
		eigensystem(Aa, Xa=., La=.)

		idxh = selectindex(Re(Lh) :== max(Re(Lh)))[1]
		idxa = selectindex(Re(La) :== max(Re(La)))[1]

		hub = abs(Re(Xh[., idxh]))
		aut = abs(Re(Xa[., idxa]))

		norm_h = sum(hub)
		norm_a = sum(aut)
		if (norm_h > 0) hub = hub :/ norm_h
		if (norm_a > 0) aut = aut :/ norm_a
}
end


***************************************************
**************** layout algorithms ****************
***************************************************

*** Fruchterman-Reingold algorithm

 
mata: 
 
real matrix fr_layout(real matrix A, real scalar iterations, real scalar width, real scalar height)
{
	real matrix pos, disp, delta, force, step
	real vector disp_norm
    real scalar k, t, area
    
    n = rows(A)
    pos = runiform(n, 2) :* (width, height) // initial random positions
    
	
    area = width * height
    k = sqrt(area/n)
    t = width/10

	
    for (iter=1; iter<=iterations; iter++) {
        disp = J(n, 2, 0)
        
        // Calculate repulsive forces (inverse square law)
        for (i=1; i<=n; i++) {
            for (j=i+1; j<=n; j++) {
                delta = pos[i,.] - pos[j,.]
                distance_val = sqrt(delta[1,1]^2 + delta[1,2]^2)
                
                if (distance_val > 0.01) {  // avoid singularities
                    force = (k^2 / distance_val^2) * (delta / distance_val)
                    disp[i,.] = disp[i,.] + force
                    disp[j,.] = disp[j,.] - force
                }
            }
        }
		
        
        // Calculate attractive forces (only for connected nodes)
        for (i=1; i<=n; i++) {
            for (j=i+1; j<=n; j++) {
                
				if (A[i,j] | A[j,i]) {
                    delta = pos[i,.] - pos[j,.]
                    distance_val = sqrt(delta[1,1]^2 + delta[1,2]^2)
                    
                    if (distance_val > 0) {
                        force = (distance_val / k) * (delta / distance_val)
                        disp[i,.] = disp[i,.] - force
                        disp[j,.] = disp[j,.] + force
                    }
                }
            }
        }
        
        // Update positions using row norms and an epsilon guard
		disp_norm = sqrt(rowsum(disp:^2))
		disp_norm = disp_norm :+ (disp_norm :== 0)
		step = disp :/ disp_norm
		pos = pos + step :* min((t, k))
        
       // Implement a cooling function
        t = cool(t, iter, iterations) 
    }
	index = (1::n)
	
	return (index, pos)
}

end


*** FR cooling function


mata:

real scalar cool(real scalar t, real scalar iter, real scalar max_iter)
{
    return (t * exp(-2 * iter / max_iter)) // Exponential cooling for better convergence
}
end



**** sphere ****
 
mata: 

real matrix layout_sphere(real matrix G)
{
	real scalar N, sqrN, phi
	real matrix res
	
	N = rows(G)
	
    sqrN = sqrt(N)
    phi = 0

    res = J(N, 3, .)


    for (i = 1; i <= N; i++) {
       
        if (i == 1) {    // Avoid division by zero or slightly negative 1-z*z
            z = -1
            r = 0
        } 
        else if (i == N) {
            z = 1
            r = 0
        }
        else { // compute z, r, and update phi
            z = -1 + 2 * (i - 1) / (N - 1)
            r = sqrt(1 - z^2)
            phi = phi + 3.6 / (sqrN * r)
        }
        
        // convert to Cartesian coordinates
        x = r * cos(phi)
        y = r * sin(phi)
        
        res[i, 1] = x
        res[i, 2] = y
        res[i, 3] = z
    }
	
	index = (1::N)
	
	return (index, res)
	
}

end


**** Bipartite layout ****
** Left column: nodes with outgoing edges (sources).
** Right column: pure-target nodes (no outgoing edges).
** If no pure targets exist, nodes are split by outdegree vs indegree.


mata:

real matrix bipartite_layout(real matrix A, real scalar width, real scalar height)
{
	real scalar N, n_left, n_right, i
	real vector row_sums, col_sums, is_left, left_idx, right_idx
	real matrix pos
	real scalar x_left, x_right

	N = rows(A)
	pos = J(N, 2, 0)

	if (N == 1) return((1, width/2, height/2))

	// Source nodes: any outgoing edge
	row_sums = rowsum(A)
	col_sums = colsum(A)'

	is_left   = (row_sums :> 0)
	left_idx  = selectindex(is_left)
	right_idx = selectindex(!is_left)  // pure targets (no outgoing edges)

	// Fallback: if no pure targets exist, split by outdegree vs indegree
	if (length(right_idx) == 0) {
		is_left   = (row_sums :>= col_sums)
		left_idx  = selectindex(is_left)
		right_idx = selectindex(!is_left)
	}

	n_left  = length(left_idx)
	n_right = length(right_idx)

	// 5 % padding from each edge to avoid marker clipping
	x_left  = 0.05 * width
	x_right = 0.95 * width

	for (i = 1; i <= n_left; i++) {
		pos[left_idx[i], 1] = x_left
		pos[left_idx[i], 2] = (n_left  == 1 ? height/2 : (i-1) * height / (n_left  - 1))
	}
	for (i = 1; i <= n_right; i++) {
		pos[right_idx[i], 1] = x_right
		pos[right_idx[i], 2] = (n_right == 1 ? height/2 : (i-1) * height / (n_right - 1))
	}

	return((1::N), pos)
}

end



** Positions nodes using the 2nd and 3rd eigenvectors of the graph Laplacian.

mata:

real matrix spectral_layout(real matrix A, real scalar width, real scalar height)
{
	real matrix Asym, D, L, X
	real vector vals, ev1, ev2
	real scalar N

	N = rows(A)

	if (N == 1) return((1, width/2, height/2))

	// Symmetrise A and build Laplacian: L = D - A
	Asym = (A + A') :/ 2
	D    = diag(rowsum(Asym))
	L    = D - Asym

	// Eigen-decomposition (symmetric -> real eigenvalues, ascending order)
	symeigensystem(L, X=., vals=.)

	ev1 = Re(X[., 2])   // Fiedler vector (2nd smallest eigenvalue)
	if (N >= 3) {
		ev2 = Re(X[., 3])
	}
	else {
		ev2 = J(N, 1, height / 2)
	}

	// Normalise each axis to [0, width] and [0, height]
	ev1 = ev1 :- min(ev1)
	if (max(ev1) > 0) ev1 = ev1 :/ max(ev1) :* width

	ev2 = ev2 :- min(ev2)
	if (max(ev2) > 0) {
		ev2 = ev2 :/ max(ev2) :* height
	}
	else {
		ev2 = J(N, 1, height / 2)
	}

	return((1::N), ev1, ev2)
}

end


**** All-pairs shortest-path via BFS (helper for Kamada-Kawai) ****

mata:

real matrix apsp_bfs(real matrix G)
{
	real scalar N, i
	real matrix D

	N = rows(G)
	D = J(N, N, .)

	for (i = 1; i <= N; i++) {
		D[i, .] = BFS(G, i)'
	}
	return(D)
}

end


**** Kamada-Kawai layout ****
** Spring-embedder using all-pairs shortest-path distances as ideal edge lengths.
** Reference: Kamada & Kawai (1989). An algorithm for drawing general undirected graphs.


mata:

real matrix kk_layout(real matrix A, real scalar width, real scalar height, ///
					   real scalar max_iter, real scalar tol)
{
	real scalar N, i, m, iter, denom, max_d, L_scale
	real matrix pos, dist, K_mat, L_mat
	real scalar dx, dy, dist_mi, k_mi, l_mi
	real scalar dE_dx, dE_dy, dE2_dx2, dE2_dy2, dE2_dxdy
	real scalar delta_m, max_delta, max_m
	real scalar sdE_dx, sdE_dy, sdE2_dx2, sdE2_dy2, sdE2_dxdy
	real scalar delta_x, delta_y
	real scalar min_x, max_x, min_y, max_y

	N = rows(A)

	if (N == 1) return((1, width/2, height/2))

	// Initialise node positions on a circle
	pos = J(N, 2, 0)
	for (i = 1; i <= N; i++) {
		pos[i, 1] = cos(2 * pi() * i / N) * width  / 2 + width  / 2
		pos[i, 2] = sin(2 * pi() * i / N) * height / 2 + height / 2
	}

	// All-pairs shortest-path distances
	dist = apsp_bfs(A)

	// Replace missing (disconnected pairs) with a large value
	max_d = max(select(vec(dist), vec(dist) :< .))
	if (missing(max_d)) max_d = N
	dist  = editmissing(dist, 2 * max_d + 1)

	// Ideal lengths and spring constants
	L_scale = min((width, height)) / 2
	K_mat   = J(N, N, 0)
	L_mat   = J(N, N, 0)
	for (i = 1; i <= N; i++) {
		for (m = 1; m <= N; m++) {
			if (i != m) {
				K_mat[i, m] = 1 / dist[i, m]^2
				L_mat[i, m] = L_scale * dist[i, m]
			}
		}
	}

	// Kamada-Kawai energy minimisation (Newton's method, one node per iteration)
	for (iter = 1; iter <= max_iter; iter++) {

		max_delta = -1
		max_m     = 1
		sdE_dx = sdE_dy = sdE2_dx2 = sdE2_dy2 = sdE2_dxdy = 0

		for (m = 1; m <= N; m++) {
			dE_dx = dE_dy = dE2_dx2 = dE2_dy2 = dE2_dxdy = 0

			for (i = 1; i <= N; i++) {
				if (i == m) continue

				dx      = pos[m, 1] - pos[i, 1]
				dy      = pos[m, 2] - pos[i, 2]
				dist_mi = sqrt(dx^2 + dy^2)
				if (dist_mi < 1e-6) dist_mi = 1e-6

				k_mi = K_mat[m, i]
				l_mi = L_mat[m, i]

				dE_dx    = dE_dx    + k_mi * (dx - l_mi * dx / dist_mi)
				dE_dy    = dE_dy    + k_mi * (dy - l_mi * dy / dist_mi)
				dE2_dx2  = dE2_dx2  + k_mi * (1  - l_mi * dy^2 / dist_mi^3)
				dE2_dy2  = dE2_dy2  + k_mi * (1  - l_mi * dx^2 / dist_mi^3)
				dE2_dxdy = dE2_dxdy + k_mi * (l_mi * dx * dy / dist_mi^3)
			}

			delta_m = sqrt(dE_dx^2 + dE_dy^2)
			if (delta_m > max_delta) {
				max_delta  = delta_m
				max_m      = m
				sdE_dx     = dE_dx
				sdE_dy     = dE_dy
				sdE2_dx2   = dE2_dx2
				sdE2_dy2   = dE2_dy2
				sdE2_dxdy  = dE2_dxdy
			}
		}

		if (max_delta < tol) break

		// Newton step for the node with the largest gradient magnitude
		denom = sdE2_dx2 * sdE2_dy2 - sdE2_dxdy^2
		if (abs(denom) < 1e-12) denom = (denom >= 0 ? 1 : -1) * 1e-12

		delta_x = (sdE2_dxdy * sdE_dy - sdE2_dy2  * sdE_dx) / denom
		delta_y = (sdE2_dxdy * sdE_dx - sdE2_dx2  * sdE_dy) / denom

		pos[max_m, 1] = pos[max_m, 1] + delta_x
		pos[max_m, 2] = pos[max_m, 2] + delta_y
	}

	// Normalise final positions to [0, width] x [0, height]
	min_x = min(pos[., 1]); max_x = max(pos[., 1])
	min_y = min(pos[., 2]); max_y = max(pos[., 2])
	if (max_x - min_x > 0) pos[., 1] = (pos[., 1] :- min_x) :/ (max_x - min_x) :* width
	if (max_y - min_y > 0) pos[., 2] = (pos[., 2] :- min_y) :/ (max_y - min_y) :* height

	return((1::N), pos)
}

end


