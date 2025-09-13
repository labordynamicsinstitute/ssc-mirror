*! shapowen v1.1, 2025-09-11, P Van Kerm  
* shapowen v1.0, 2025-09-09, P Van Kerm  
pr def shapowen  , rclass
    version 16
	mata: _parse_colon("hascolon", "cmd")
	if (!`hascolon') {
		di as error "No command given"
		exit 198
	}
	syntax [anything(equalok)]  ///
		[ , ///
		SCalarexpressions(string asis) ///
		MATrixexpressions(string asis) ///
		SUBstitution(string) ///
		SEParator(string) ///
		EMPTYValue(string) ///
		EMPTYSubstitute(string) ///
		ERRorvalue(string) ///
		frame ///
		trace ///
		nodots ///
		shownodes /// undocumented -- for debugging
		]
	mata : StripBrackets(`"`anything'"' , "Stripped") 
	loc nelem : word count `Stripped'
	if (`"`substitute'"'!="") {
		loc nsub : word count `substitute'
		if (`nsub'!=`nelem') {
			di as error "Number of items in option substitute does not match length of items"
			exit 198
		}
	}
	if (strpos(`"`cmd'"',"@")==0) {
		di as error "Placeholder @ not found in Stata command"
		exit 198
	}
	if ((`: word count `scalarexpressions'' + `: word count `matrixexpressions'')==0) {
		di as error "Option scalars and/or vectors must be specified"
		exit 198
	}
	if (`: word count `emptyvalue' `emptysubstitute'' >1) {
		di as error "Options emptyvalue() and emptysubstitute() are mutually exclusive"
		exit 198
	}
	if ("`separator'"=="") loc separator = " "
	mata : ShapleyValueCalculation()
end

mata:
	// ---------------------------------------------------------------------
	// 1.  Convenience and parsing functions
	// ---------------------------------------------------------------------
	void StripBrackets (string scalar Entry, string scalar Local) {
		s = subinstr(subinstr(Entry,  "(" ,""),  ")" ,"")
		st_local(Local,s)
	}

	// receives a string and splits it in blocks separated by brackets 
	// parses on whitespace, or double quotes or ( )  
	string colvector   Parser(string scalar Entree) {
		t = tokeninit(" ", "", (`""""',"()"), 0, 0)
		tokenset(t, Entree)
		tokens = tokengetall(t)
		for (i=1; i<=cols(tokens); i++) {
			if (substr(tokens[i], 1, 1)=="(") {
				tokens[i] = substr(tokens[i], 2, strlen(tokens[i])-2)
			}
		}
		return(tokens')
	} 

	// Compose two matrices: Every row of Left is glued to every row of right so matrix axb et cxd become  a*c x (b+d)
	real matrix Compose(real matrix Left , real matrix Right) {
		M = J(0,cols(Left)+cols(Right),0)
		for (i=1;i<=rows(Left);i++) {
			for (j=1;j<=rows(Right);j++) {
				M  = M \  ( Left[i,] , Right[j,])
			}	
		}
		return(M)	
	}

	// elementwise product of first columns with last columns
	real matrix ElProduct(real matrix Input) {
		c = cols(Input)/2
		return(Input[,(1..c)] :* Input[,((c+1) .. cols(Input))])
	}
	
	// ---------------------------------------------------------------------
	// 2.  Define Shapley Class and Node Structure
	// ---------------------------------------------------------------------
	// Definition of structure for Nodes
	struct Node {
		string 							scalar		Content
		real 							scalar		Size
		real							colvector	Indices
		real 							colvector  	GridIndx
		real							colvector	GridInvIndx
		real							matrix		GridIn
		real							matrix		GridOut
		real							matrix		GridWeights
		real							matrix		ValIn
		real							matrix		ValOut
		real 							colvector	ShapVal
		real 							colvector	BanzVal
		real 							colvector	FirstVal
		real 							colvector	LastVal
		pointer(struct Node scalar)		colvector 	Branches
	}		
	
	class Shapley {
		private: 
		string 	scalar 	Cmd 				
		string 	scalar 	InputString, Separator, EmptySub, EmptyValue, ErrorValue		  
		string 	matrix 	MatRes, ScaRes, StatsLabels
		string 	scalar 	Candidates 
		string 	scalar 	Substitutes
		real 	scalar  Mode, Echo, ShowNodes, Shown, StatsLabelsSet, ShowDots
		real   	scalar 	K, NStats, NNodes  // Number of Items, Number of stats, Number of Nodes
		pointer(struct Node scalar)  scalar  Tree
		real 	matrix 	LookUp
		//
		void 								new()
		pointer(struct Node scalar) scalar 	GrowTree()
		void								GetIndices()
		real 	matrix						Build()
		void								BuildGrids()
		real	rowvector					Evaluate()
		void								EvaluateGrids()
		void								EvaluateShapley()
		void								StoreAndDisplay()
		void								DisplayResults()
		void								PostFrame()
		void								Traverse()
	}

	// The constructor reads arguments, builds tree, and launches the evaluation.
	void Shapley::new() {
		this.Cmd = st_local("cmd")
		this.Echo = strlen(st_local("trace"))==0 ? 1 : 0
		this.ShowNodes = strlen(st_local("shownodes"))==0 ? 0 : 1
		this.ShowDots = strlen(st_local("dots"))==0 ? 1 : 0 
		this.InputString = st_local("anything")
		this.Separator = st_local("separator")
		this.EmptySub = st_local("emptysubstitute")
		this.EmptyValue = st_local("emptyvalue")
		this.ErrorValue = st_local("errorvalue")
		this.Candidates = subinstr(subinstr(this.InputString,  "(" ,""),  ")" ,"")
		this.K = cols(tokens(this.Candidates))
		this.NNodes = 0
		this.StatsLabels = J(1,0,"")
		this.StatsLabelsSet = 0
		this.Substitutes = st_local("substitution")
		this.Mode = strlen(strtrim(this.Substitutes))==0 ? 0 : 1
		this.MatRes = tokens(st_local("matrixexpressions"))
		this.ScaRes = tokens(st_local("scalarexpressions"))
		this.LookUp = J(0,this.K,.)
		this.Shown = 0
		this.Tree = this.GrowTree(this.InputString)	
		this.GetIndices(this.Tree,0)
		this.BuildGrids(this.Tree, J(0,0,0), J(0,2,0), J(1,0,0))  
		this.EvaluateGrids(this.Tree)
		this.EvaluateShapley(this.Tree)
		this.StoreAndDisplay(this.Tree,0)
		if (strlen(st_local("frame"))>0)  this.PostFrame(this.Tree)
		if (this.ShowNodes)  this.Traverse(this.Tree)
	}
	
	// Tree creation -- receives string and returns pointer to tree (root node))
	pointer(struct Node scalar)  scalar  Shapley::GrowTree(string scalar Entree) {
		struct Node scalar Block
		this.NNodes = this.NNodes + 1 
		vecEntree = Parser(Entree) 
		Block.Content = Entree
		s = subinstr(subinstr(Entree,  "(" ,"") ,  ")" ,"")
		Block.Size = cols(tokens(s))
		Block.Branches = J(0,1,NULL) 
		if (rows(vecEntree)>1) {
			for (i=1; i<=rows(vecEntree); i++) {
				Block.Branches = Block.Branches \  this.GrowTree(vecEntree[i])
			}
		}  		
		return(&Block)	
	}

	// Determines the index vector of each element of each node in a tree (indices are according to initial unbracketed list of items) 
	void Shapley::GetIndices(pointer(struct Node scalar) Tree, real scalar Debut) {
		(*Tree).Indices = ( (Debut+1) .. (Debut+(*Tree).Size))
		DebutStart = Debut 
		for (i=1; i<=rows((*Tree).Branches); i++) {
			this.GetIndices((*Tree).Branches[i] , Debut)
			Debut = Debut + (*(*Tree).Branches[i]).Size
		}
		Debut = DebutStart    
	}		

	// Takes set of branches and returns a matrix with all possible combinations of in/out and the weight of each row
	real matrix Shapley::Build(pointer(struct Node scalar) colvector Branches) {
		real matrix Output
		Output = J(0,0, .) 
		n = rows(Branches)
		for (i=1; i<=rows(Branches); i++) {
			if (rows(Output)==0)  {
				Output = J(1,(*Branches[i]).Size,0) \ J(1,(*Branches[i]).Size,1)  
				Weights = (0 \ 1)  
			}	
			else {
				Output = Output , J(rows(Output),(*Branches[i]).Size,0) \ Output , J(rows(Output),(*Branches[i]).Size,1)
				Weights = ( Weights \ Weights:+1 )
			}	
		}
		// Banzhaf and Shapley weights
		Weights = ( J(rows(Weights), 1, 1/(2^n))  ,    (factorial(Weights):*(factorial( n :- Weights )):/factorial(n+1)) )
		return((Weights, Output)) 
	}
	
	void Shapley::BuildGrids(pointer(struct Node scalar) Tree , real matrix From, real matrix FromWeights, real rowvector FromIndx ) {
		// Set current node 
		if (cols(From)==0) {
			(*Tree).GridIn = J(1,(*Tree).Size,1)   
			(*Tree).GridOut = J(1,(*Tree).Size,0)   
			(*Tree).GridIndx = (*Tree).Indices   
			(*Tree).GridInvIndx = (*Tree).Indices   
			(*Tree).GridWeights = (1 , 1)
		}
		else {
			(*Tree).GridIn = Compose(J(1,(*Tree).Size,1) , From)
			(*Tree).GridOut = Compose(J(1,(*Tree).Size,0) , From)
			(*Tree).GridIndx = (*Tree).Indices ,   FromIndx
			(*Tree).GridInvIndx = J(1 , this.K, 0) 
			((*Tree).GridInvIndx)[,(*Tree).GridIndx] = (1..this.K)
			(*Tree).GridWeights = FromWeights
		}
		// Ensuite parcourt les branches
		for (i=1;i<=rows((*Tree).Branches); i++) {
			Autresindx = J(0,1,0) 
			AutresIndices = J(1,0,0) 
			for (j=1;j<=rows((*Tree).Branches); j++) {
				if (i!=j)  {
					Autresindx = Autresindx \ j
					AutresIndices = AutresIndices , (*(*Tree).Branches[j]).Indices 
				}	
			}	
			Autres = Build((*Tree).Branches[Autresindx])
			AutresWeights = Autres[,(1,2)]
			Autres = Autres[,(3 .. cols(Autres))]
			if (cols(From)==0) {
				this.BuildGrids((*Tree).Branches[i], Autres, AutresWeights, AutresIndices)
			}
			else {
				this.BuildGrids((*Tree).Branches[i], Compose(Autres,From), ElProduct(Compose(AutresWeights,FromWeights)) , (AutresIndices, FromIndx))
			}
		}
	}

	// This takes an instruction with @, a list of Candidates for @ substitution, a selector (a vector of 0 and 1) 
	// and evaluates stata instruction and return a rowvector with the returned results
	real rowvector Shapley::Evaluate(real rowvector Selector) {
		if (this.Mode==0) {
			items = select(tokens(this.Candidates), Selector)
		}
		else {
			items = J(1 , cols(tokens(this.Candidates)), "")
			items[1,selectindex(Selector)]    = select(tokens(this.Candidates),Selector)
			items[1,selectindex(1:-Selector)] = select(tokens(this.Substitutes),1:-Selector)
		}
		if ((rowsum(Selector)==0) & (this.EmptyValue!=""))  {
			results = J(1, this.NStats , strtoreal(this.EmptyValue) )	
		}
		else {
			newargs = invtokens(items, this.Separator) 
			newargs = (cols(items)==0) ? this.EmptySub : newargs 
			cmd =  subinstr(this.Cmd, "@" , newargs)
			if (this.ShowDots) printf("{res}%s", ".")
			rc = _stata(cmd, this.Echo)
			if (rc>0) {
				display("{break}{error}Execution of -- " + cmd + " -- failed (error " + strofreal(rc) + ")")
				if (this.ErrorValue != "") {
					display("{error}Set error value " + this.ErrorValue + " used")
					results = J(1, this.NStats , strtoreal(this.ErrorValue) )	
				}
				else exit(198)
			}
			else {
				results = J(1,0,.)
				for (i=1;i<=cols(this.ScaRes);i++) {
					stata("local RES = " + this.ScaRes[i]) 
					results = results , strtoreal(st_local("RES"))
					if (this.StatsLabelsSet==0) this.StatsLabels = this.StatsLabels , this.ScaRes[i]
				}
				for (i=1;i<=cols(this.MatRes);i++) {
					stata("mat def __SHAPMATEVAL = " + this.MatRes[i])  
					results = results , vec(st_matrix("__SHAPMATEVAL"))'
					if (this.StatsLabelsSet==0) {  // done just once!
						for (j=1;j<=rows(vec(st_matrix("__SHAPMATEVAL"))); j++) {
							for (k=1;k<=cols(vec(st_matrix("__SHAPMATEVAL"))); k++) {
								this.StatsLabels = this.StatsLabels , 
									(this.MatRes[i] + " [" + strofreal(j) + "," + strofreal(k) +"]")
							}		
						}
					}
					this.StatsLabelsSet = 1  // so done just once
				}
			}	
		}
		return(results)
	}

	// Run the evaluations 
	void Shapley::EvaluateGrids(pointer(struct Node scalar) Tree) {
		real scalar j 
		// in initial run LookUp is empty. collect info about length of output
		if (rows(this.LookUp)==0) {
			val = this.Evaluate((*Tree).GridIn[1,(*Tree).GridInvIndx])
			this.NStats = cols(val)
			this.LookUp = this.LookUp , J(0,this.NStats,.)  // add columns
			this.LookUp = ( this.LookUp \ ((*Tree).GridIn[j,(*Tree).GridInvIndx] , val ) )   // add val to LookUp
		}
		(*Tree).ValIn = J(0, this.NStats, .)
		(*Tree).ValOut = J(0, this.NStats, .)
		
		for (j=1; j<=rows((*Tree).GridIn); j++) {
			foundval = select(this.LookUp , rowsum(this.LookUp[,(1..this.K)]:==((*Tree).GridIn)[j,(*Tree).GridInvIndx]):==this.K )   
			if (rows(foundval)==0) { 
				val = this.Evaluate((*Tree).GridIn[j,(*Tree).GridInvIndx])
				this.LookUp = ( this.LookUp \ ((*Tree).GridIn[j,(*Tree).GridInvIndx] , val ) )  
				(*Tree).ValIn = (*Tree).ValIn  \ val  
			}
			else {
				 (*Tree).ValIn = (*Tree).ValIn  \  foundval[1,((this.K+1) .. cols(foundval))]
			}
			
			foundval = select(this.LookUp , rowsum(this.LookUp[,(1..this.K)]:==((*Tree).GridOut)[j,(*Tree).GridInvIndx]):==this.K )   
			if (rows(foundval)==0) {
				val = this.Evaluate((*Tree).GridOut[j,(*Tree).GridInvIndx])
				this.LookUp = ( this.LookUp \ ((*Tree).GridOut[j,(*Tree).GridInvIndx] , val ) )  
				(*Tree).ValOut = (*Tree).ValOut  \ val  
			}
			else {
				(*Tree).ValOut = (*Tree).ValOut  \  foundval[1,((this.K+1) .. cols(foundval))]  
			}

		}
		// iterate over branches
		for (i=1;i<=rows((*Tree).Branches); i++) {
			this.EvaluateGrids((*Tree).Branches[i])
		}
	}

	// Run Shapley-OWen and Banzhaf weights
	void Shapley::EvaluateShapley(pointer(struct Node scalar) Tree) {
		(*Tree).ShapVal = mean(((*Tree).ValIn :- (*Tree).ValOut) , (*Tree).GridWeights[,2])
		(*Tree).BanzVal = mean(((*Tree).ValIn :- (*Tree).ValOut) , (*Tree).GridWeights[,1])
		// First marginal weight
		min = min(rowsum((*Tree).GridIn))
		(*Tree).FirstVal = mean(((*Tree).ValIn :- (*Tree).ValOut) , (rowsum((*Tree).GridIn):==min) )
		// Last marginal weight 
		max = max(rowsum((*Tree).GridIn))
		(*Tree).LastVal = mean(((*Tree).ValIn :- (*Tree).ValOut) , (rowsum((*Tree).GridIn):==max) )
		// iterate over branches
		for (i=1;i<=rows((*Tree).Branches); i++) {
			this.EvaluateShapley((*Tree).Branches[i])
		}
	}

	void Shapley::StoreAndDisplay(pointer(struct Node scalar) Tree, real scalar InSize) {
		external CNT, MatShap , MatBanz , MatFirst, MatLast, MatRowNames, EmptySet, FullSet
		this.NStats = cols((*Tree).ShapVal)
		if (InSize==0) {
			CNT = 1
			MatRowNames = J(0,1,"")
			MatShap = J(0,this.NStats, .)
			MatBanz = J(0,this.NStats, .)
			MatFirst = J(0,this.NStats, .)
			MatLast = J(0,this.NStats, .)
			EmptySet = (*Tree).ValOut 
			FullSet = (*Tree).ValIn
		}
		MatRowNames = MatRowNames \ (*Tree).Content
		MatShap  = MatShap  \ (*Tree).ShapVal
		MatBanz  = MatBanz  \ (*Tree).BanzVal
		MatFirst = MatFirst \ (*Tree).FirstVal
		MatLast  = MatLast  \ (*Tree).LastVal
		for (i=1;i<=rows((*Tree).Branches); i++) {
			CNT = CNT+1
			StoreAndDisplay((*Tree).Branches[i], rows(MatShap))
		}
		// if at the end...
		if (CNT==this.NNodes & this.Shown==0) {
			this.Shown = 1
			// Display
	        ls = st_numscalar("c(linesize)") - 5
			max = max((15,max(strlen(abbrev(MatRowNames[|2,1 \ . , 1|],32)))))
			printf("\n")	
			display("{txt}Instruction:{space 2}{res}" + strtrim(this.Cmd))
			display("{txt}Items list:{space 3}{res}" + strtrim(this.InputString))
			for (i=1; i<=this.NStats; i++) {
				printf("\n")	
				printf("{txt}{bf: %-28s }", "---  " + this.StatsLabels[i] + " ---")	
				printf("{txt}{space 2}Empty set value: {res}%9.0g{space 18}" , EmptySet[1,i]  ) 
				printf("{txt}Full set value: {res}%9.0g\n" , FullSet[1,i] ) 
				printf("{txt}{hline " + strofreal(max+2) + "}{c TT}{hline " + strofreal(41) + "}{c TT}{hline " + strofreal(41) + "}\n")
				printf("{txt}{space " + strofreal(max+2) + "}{c |}%40s {c | } %40s \n" , "Nominal contribution", "Relative contribution")
				printf("{txt}{hline " + strofreal(max+2) + "}{c +}{hline " + strofreal(41) + "}{c +}{hline " + strofreal(41) + "}\n")
				printf("{txt}{space " + strofreal(max+2) + "}{c |} %9s %9s %9s %9s {c |} %9s %9s %9s %9s \n", "Shapley", "Banzhaf", "First", "Last", "Shapley", "Banzhaf", "First", "Last")
				printf("{txt}{space " + strofreal(max+2) + "}{c |} %9s %9s %9s %9s {c |} %9s %9s %9s %9s \n", "-Owen", "", "", "","-Owen", "", "", "")
				printf("{txt}{hline " + strofreal(max+2) + "}{c +}{hline " + strofreal(41) + "}{c +}{hline " + strofreal(41) + "}\n")
				for (j=1; j<=this.NNodes; j++) {
					if (j==1) {
						itemlabel = "FULL"
						printf("{txt}%" + strofreal(max+1) + "s {c |} {res}%9.0g %9s %9s %9s {c |} {res}%9.0g %9s %9s %9s\n", 
							itemlabel , MatShap[j,i], "", "", "" , MatShap[j,i]:/MatShap[1,i], "" , "", "")	
						printf("{txt}{hline " + strofreal(max+2) + "}{c +}{hline " + strofreal(41) + "}{c +}{hline " + strofreal(41) + "}\n")
					}
					else {
						itemlabel = abbrev(MatRowNames[j,1], 32) 
						printf("{txt}%" + strofreal(max+1) + "s {c |} {res}%9.0g %9.0g %9.0g %9.0g {c |} {res}%9.0g %9.0g %9.0g %9.0g\n", 
							itemlabel , 
							MatShap[j,i], MatBanz[j,i], MatFirst[j,i], MatLast[j,i], 
							MatShap[j,i]:/MatShap[1,i], MatBanz[j,i]:/MatBanz[1,i], MatFirst[j,i]:/MatFirst[1,i], MatLast[j,i]:/MatLast[1,i])
					}
				}	
				printf("{txt}{hline " + strofreal(max+2) + "}{c BT}{hline " + strofreal(41) + "}{c BT}{hline " + strofreal(41) + "}\n")
			}
			// Store
			resname = "ShapOw"
			st_matrix("r_"+resname , MatShap)
			stata("return matrix " + resname + "  r_" + resname)
				st_matrix("r_r"+resname , MatShap:/MatShap[1,])
				stata("return matrix rel" + resname + "  r_r" + resname)
			resname = "Banzhaf" 
			st_matrix("r_"+resname , MatBanz)
			stata("return matrix " + resname + "  r_" + resname)
				st_matrix("r_r"+resname , MatBanz:/MatBanz[1,])
				stata("return matrix rel" + resname + "  r_r" + resname)
			resname = "First" 
			st_matrix("r_"+resname , MatFirst)
			stata("return matrix " + resname + "  r_" + resname)
				st_matrix("r_r"+resname , MatFirst:/MatFirst[1,])
				stata("return matrix rel" + resname + "  r_r" + resname)
			resname = "Last" 
			st_matrix("r_"+resname , MatLast)
			stata("return matrix " + resname + "  r_" + resname)
				st_matrix("r_r"+resname , MatLast:/MatLast[1,])
				stata("return matrix rel" + resname + "  r_r" + resname)
			for (i=1; i<=this.NNodes; i++) {
				stata("return local item"+strofreal(i) + " " + MatRowNames[i])
			}
			stata("return local cmd " + this.Cmd)
			stata("return local items " + this.InputString)
			stata("return local stats " + invtokens(this.StatsLabels))
			stata("return scalar K = " + strofreal(this.K))
		}
	}
	
	void Shapley::PostFrame(pointer(struct Node scalar) Tree) {
		fname = st_framecurrent() 
		rc = _st_framecreate("ShapOwen", 0)
		if (rc!=0) {
			st_framedrop("ShapOwen")
			st_framecreate("ShapOwen")
		}	
		st_framecurrent("ShapOwen")
		st_addobs(rows(this.LookUp))
		names = J(1,0,"")
		for (i=1;i<=this.K;i++) {
			names = names , "item_" + strofreal(i)
		}
		tmp = st_addvar("byte", names)
		names = J(1,0,"")
		for (i=1;i<=(cols(this.LookUp)-(this.K));i++) {
			names = names , "res_" + strofreal(i)
		}
		tmp = st_addvar("double", names)
		st_store(. , . , this.LookUp)
		for (i=1;i<=(cols(tokens(this.Candidates)));i++) {
			st_varlabel("item_" + strofreal(i) , tokens(this.Candidates)[i])
		}
		for (i=1;i<=(cols(this.LookUp)-(this.K));i++) {
			st_varlabel("res_" + strofreal(i) , this.StatsLabels[i])
		}
		st_framecurrent(fname)
	}

	void Shapley::Traverse(pointer(struct Node scalar) Chose) {
		(*Chose).Content
		( ((*Chose).GridWeights \ (*Chose).GridWeights ) , ((*Chose).GridIn[,(*Chose).GridInvIndx] \ (*Chose).GridOut[,(*Chose).GridInvIndx] ) , (		(*Chose).ValIn \ (*Chose).ValOut   )) 
		for (i=1; i<=rows((*Chose).Branches); i++) {
			Traverse((*Chose).Branches[i]) 
		}	
	}	

	// creates and evaluates the shapley tree
	void ShapleyValueCalculation() {
		pointer(class Shapley scalar) myShap
		myShap = Shapley()	 
	}
	
end

exit 
