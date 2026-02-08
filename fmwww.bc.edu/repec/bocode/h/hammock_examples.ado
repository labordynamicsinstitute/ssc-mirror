

cap program drop hammock_examples
capture program drop hammock_bp

program define hammock_examples
	if ("`1'" == "hammock_bp"){
		hammock_bp
	}
	else if ("`1'" == "hammock_cancer"){
		hammock_cancer
	}
	else if ("`1'" == "hammock_lifeexp"){
		hammock_lifeexp
	}
	else if ("`1'" == "hammock_lifeexp_missing"){
		hammock_lifeexp_missing
	}
	else if ("`1'" == "hammock_agegroup"){
		hammock_agegroup
	}
	else if ("`1'" == "hammock_agegroup2"){
		hammock_agegroup2
	}
end



program define hammock_bp
	clear 
	//set scheme s1mono
	sysuse bplong
	hammock sex agegrp when bp 
end 



program define hammock_cancer

	clear 
	sysuse cancer
	label var studytime "Study time (mths)"
	hammock died drug studytime  age, hivar(drug) hival(1) barwidth(.5) labelopt(size(small))
	
end 


program define hammock_lifeexp
	clear 
	sysuse lifeexp
	hammock popgrowth-safewater, graphregion(margin(l+3 r+5)) space(0)
end 

program define hammock_lifeexp_missing
	clear 
	sysuse lifeexp
	hammock popgrowth lexp gnp  safewater, graphregion(margin(l+3 r+5)) missing ///
	 hivar(gnp) hival(.) label_methodlist(min_dist all minmax min_dist) uni_fraction(.2)
end 


program define hammock_agegroup 
	version 17
	clear 
	set seed 8768
	set obs 100
	gen age=round(uniform()*18)

	egen agegroup= cut(age), at(1,2,6,12,16) 
	hammock age agegroup ,m  space(0.1) ///
	   hivar(agegroup) hival(1 2 6 12) ///
	   label_too_many(40) ///
	   colorlist(blue%50 orange%50 green red teal  yellow sand maroon olive)
end 


program define hammock_agegroup2 
	version 17
	clear 
	set seed 8768
	set obs 100
	gen age=round(uniform()*18)
	egen agegroup2= cut(age), at(0,1,2,6,12,16,19) 

	hammock age agegroup2 , missing ///
	   space(.1) ///
	   hivar(agegroup2) hival(0 1 2 6 12 16)  ///
	   graphregion(margin(l+2 r+3)) ///
	   uni_fraction(0) ///
	   label_too_many(40) ///
	   colorlist(blue%50 orange%50 green red teal  yellow sand maroon olive)
end
