***********
**** Part 2a - Reasons why NET not used previous night
***********

cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR"
** 
** We take them one at a time because the varnames are not consistent from survey to survey. 

*******		
*** Uganda 5H
*******

	use UGHR5HFL.dta, clear
	gen filename="UGHR5H"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh131* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR5H_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused

	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh131a_ sh131b_ sh131c_ sh131d_ sh131e_ sh131x_ sh131z_, i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh131a "too hot"
	label var sh131b "don't like smell"
	label var sh131c "no mosquitoes"
	label var sh131d "too old/too many holes"
	label var sh131e "not hung"
	label var sh131x "other"
	label var sh131z "don't know"
	
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
			
	
	 foreach var of varlist sh131a_ sh131b_ sh131c_ sh131d_ sh131e_ sh131x_ sh131z_ {
		replace `var'=0 if netused==1
	}
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR5H_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Uganda2009") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh131a_ sh131b_ sh131c_ sh131d_ sh131e_ sh131x_ sh131z_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1)
		scalar `x'lb=round(mat2[1,2]*100,0.1)
		scalar `x'ub=round(mat3[1,2]*100,0.1)
		scalar `x'obs=mat4[1,2]
		
		** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/UGHR5H_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR5H_netfile_reasons.dta", replace
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh131a_ sh131b_ sh131c_ sh131d_ sh131e_ sh131x_ sh131z_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
			
**** 
*** Uganda 2014
****
	use UGHR72FL.dta, clear
	gen filename="UGHR72" // gen the filename in order to label the survey when putting into excel and to permit running of naming do file
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh128* filename // keep only the relevant variables
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR72_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, 
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ax_ sh128az_, i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh128aa_ "too hot"
	label var sh128ab_ "don't like smell"
	label var sh128ac_ "no mosquitoes"
	label var sh128ad_ "too old/torn"
	label var sh128ae_ "not hung"
	label var sh128af_ "extra net/for visitors"
	label var sh128ax_ "other"
	label var sh128az_ "don't know"
	
	foreach var of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ax_ sh128az_ {
		replace `var'=0 if netused==1
	}
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR72_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Uganda2014") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ax_ sh128az_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1) // save result as scalar, rounding
		scalar `x'lb=round(mat2[1,2]*100,0.1) // save lower bound as scalar, rounding
		scalar `x'ub=round(mat3[1,2]*100,0.1) // save upper bound as scalar, rounding
		scalar `x'obs=mat4[1,2] // save # of observations as scalar
		
		** combine the CIs into one scalar with a - between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/UGHR72_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR72_netfile_reasons.dta", replace
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ax_ sh128az_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
	
	**** 
*** Uganda 2018-19
****
	use UGHR7IFL.dta, clear
	gen filename="UGHR7I" // gen the filename in order to label the survey when putting into excel and to permit running of naming do file
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh128* filename // keep only the relevant variables
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR7I_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, 
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128ax_ sh128az_, i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh128aa_ "too hot"
	label var sh128ab_ "don't like smell"
	label var sh128ac_ "no mosquitoes"
	label var sh128ad_ "too old/torn"
	label var sh128ae_ "unable to hang"
	label var sh128af_ "no place to hang"
	label var sh128ag_ "chemicals not safe"
	label var sh128ah_ "saving for rainy season"
	label var sh128ai_ "saving to replace other net"
	label var sh128aj_ "material too hard/rough"
	label var sh128ak_ "usual user didn't sleep here"
	label var sh128ax_ "other reason"
	label var sh128az_ "don't know"
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	foreach var of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128ax_ sh128az_ {
		replace `var'=0 if netused==1
	}
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR7I_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Uganda2019") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128ax_ sh128az_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1) // save result as scalar, rounding
		scalar `x'lb=round(mat2[1,2]*100,0.1) // save lower bound as scalar, rounding
		scalar `x'ub=round(mat3[1,2]*100,0.1) // save upper bound as scalar, rounding
		scalar `x'obs=mat4[1,2] // save # of observations as scalar
		
		** combine the CIs into one scalar with a - between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/UGHR7I_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/UGHR7I_netfile_reasons.dta", replace
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128ax_ sh128az_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
			

*** Tanzania 2011-12

use TZHR6AFL.dta, clear
	gen filename="TZHR6A"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR6A_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, etc
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh135a_ sh135b_ sh135c_ sh135d_ sh135e_ sh135f_ sh135g_ sh135h_ sh135i_ sh135j_ sh135k_ sh135l_ sh135x_ sh135z_ , i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh135a_ "no mosquitoes"
	label var sh135b_ "no malaria now"
	label var sh135c_ "too hot"
	label var sh135d_ "don't like smell"
	label var sh135e_ "feel closed in/afraid"
	label var sh135f_ "too old/torn"
	label var sh135g_ "net too dirty"
	label var sh135h_ "net not available last night/washed"
	label var sh135i_ "usual user was not here"
	label var sh135j_ "net too small"
	label var sh135k_ "saving it for later"
	label var sh135l_ "no longer kills/repels mosquitoes"
	label var sh135x_ "other"
	label var sh135z_ "don't know"
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	 foreach var of varlist sh135a_ sh135b_ sh135c_ sh135d_ sh135e_ sh135f_ sh135g_ sh135h_ sh135i_ sh135j_ sh135k_ sh135l_ sh135x_ sh135z_ {
		replace `var'=0 if netused==1
	}
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR6A_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Tanzania2011") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh135a_ sh135b_ sh135c_ sh135d_ sh135e_ sh135f_ sh135g_ sh135h_ sh135i_ sh135j_ sh135k_ sh135l_ sh135x_ sh135z_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1)
		scalar `x'lb=round(mat2[1,2]*100,0.1)
		scalar `x'ub=round(mat3[1,2]*100,0.1)
		scalar `x'obs=mat4[1,2]
		
		** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/TZHR6A_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR6A_netfile_reasons.dta", replace
				
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh135a_ sh135b_ sh135c_ sh135d_ sh135e_ sh135f_ sh135g_ sh135h_ sh135i_ sh135j_ sh135k_ sh135l_ sh135x_ sh135z_ netused {
		levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
		
*** Tanzania 2015-16

use TZHR7HFL.dta, clear
	gen filename="TZHR7H"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh137* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR7H_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, etc
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh137aa_ sh137ab_ sh137ac_ sh137ad_ sh137ae_ sh137af_ sh137ag_ sh137ah_ sh137ai_ sh137aj_ sh137ak_ sh137al_ sh137ax_ sh137az_, i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh137aa_ "no mosquitoes"
	label var sh137ab_ "no malaria now"
	label var sh137ac_ "too hot"
	label var sh137ad_ "don't like smell"
	label var sh137ae_ "feel closed in/afraid"
	label var sh137af_ "too old/torn"
	label var sh137ag_ "net too dirty"
	label var sh137ah_ "net not available last night/washed"
	label var sh137ai_ "usual user was not here"
	label var sh137aj_ "net too small"
	label var sh137ak_ "saving it for later"
	label var sh137al_ "no longer kills/repels mosquitoes"
	label var sh137ax_ "other"
	label var sh137az_ "don't know"
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	 foreach var of varlist sh137aa_ sh137ab_ sh137ac_ sh137ad_ sh137ae_ sh137af_ sh137ag_ sh137ah_ sh137ai_ sh137aj_ sh137ak_ sh137al_ sh137ax_ sh137az_ {
		replace `var'=0 if netused==1
	}
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR7H_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Tanzania2015") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh137aa_ sh137ab_ sh137ac_ sh137ad_ sh137ae_ sh137af_ sh137ag_ sh137ah_ sh137ai_ sh137aj_ sh137ak_ sh137al_ sh137ax_ sh137az_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1)
		scalar `x'lb=round(mat2[1,2]*100,0.1)
		scalar `x'ub=round(mat3[1,2]*100,0.1)
		scalar `x'obs=mat4[1,2]
		
		** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/TZHR7H_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR7H_netfile_reasons.dta", replace
				
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh137aa_ sh137ab_ sh137ac_ sh137ad_ sh137ae_ sh137af_ sh137ag_ sh137ah_ sh137ai_ sh137aj_ sh137ak_ sh137al_ sh137ax_ sh137az_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
		
*** Tanzania 2017 ******

	use TZHR7QFL.dta, clear
	gen filename="TZHR7Q"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh129h* filename shreg2
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR7Q_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, etc
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh129ha_ sh129hb_ sh129hc_ sh129hd_ sh129he_ sh129hf_ sh129hg_ sh129hh_ sh129hi_ sh129hj_ sh129hk_ sh129hl_ sh129hx_ sh129hz_, i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh129ha_ "no mosquitoes"
	label var sh129hb_ "no malaria now"
	label var sh129hc_ "too hot"
	label var sh129hd_ "don't like smell"
	label var sh129he_ "feel closed in/afraid"
	label var sh129hf_ "too old/torn"
	label var sh129hg_ "net too dirty"
	label var sh129hh_ "net not available last night/washed"
	label var sh129hi_ "usual user was not here"
	label var sh129hj_ "net too small"
	label var sh129hk_ "saving it for later"
	label var sh129hl_ "no longer kills/repels mosquitoes"
	label var sh129hx_ "other"
	label var sh129hz_ "don't know"
	
	clonevar zone=shreg2
	label var zone "grouped regions"
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	* denominator is already all nets 
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR7Q_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Tanzania2017") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh129ha_ sh129hb_ sh129hc_ sh129hd_ sh129he_ sh129hf_ sh129hg_ sh129hh_ sh129hi_ sh129hj_ sh129hk_ sh129hl_ sh129hx_ sh129hz_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1)
		scalar `x'lb=round(mat2[1,2]*100,0.1)
		scalar `x'ub=round(mat3[1,2]*100,0.1)
		scalar `x'obs=mat4[1,2]
		
		** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/TZHR7Q_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/TZHR7Q_netfile_reasons.dta", replace
				
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh129ha_ sh129hb_ sh129hc_ sh129hd_ sh129he_ sh129hf_ sh129hg_ sh129hh_ sh129hi_ sh129hj_ sh129hk_ sh129hl_ sh129hx_ sh129hz_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
			
			
		*** ZONAL risk perception investigation
		putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Tanzania2017zonal") modify
		putexcel A1=("Country") B1=("Year") C1="Zone" D1=("Reason net not used") E1=("zpct ") F1=("95% CI") G1=("N"), txtwrap
	
			local row=2
			
	
	
		
		 
		
		foreach x of varlist sh129ha_ sh129hb_ sh129hc_ sh129hd_ sh129he_ sh129hf_ sh129hg_ sh129hh_ sh129hi_ sh129hj_ sh129hk_ sh129hl_ sh129hx_ sh129hz_ netused {
			levelsof zone if `x'==1, local(zlvl) // just get levels for 'yes' values, and loop through those
			
			foreach z of local zlvl {
				local `z'_lbl : label SHREG2 `z'
				
				estpost svy: tab `x' if zone==`z'
				mat mat1= e(b)
				mat mat2=e(lb)
				mat mat3=e(ub)
				mat mat4=e(obs)
				
				scalar `x'p= round(mat1[1,2]*100,0.1)
				scalar `x'lb=round(mat2[1,2]*100,0.1)
				scalar `x'ub=round(mat3[1,2]*100,0.1)
				scalar `x'obs=mat4[1,2]
				
				** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
				scalar `x'lb_str = string(`x'lb)
				scalar `x'ub_str = string(`x'ub)
				scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
				
				** create a scalar for the variable label to identify each line of the results
				local `x'_lbl : variable label `x'
				scalar `x'lbl="``x'_lbl'"
		
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'="``z'_lbl'" D`row'=(`x'lbl) E`row'=(`x'p) F`row'=(`x'CI) G`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		} // next zone
	} // next var
	
	
	scalar drop _all
	mat drop _all


***************				
*** Liberia
***************

	use LBHR70FL.dta, clear
	gen filename="LBHR70"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh128* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/LBHR70_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128al_ sh128am_ sh128an_ sh128ax_ sh128az_, i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh128aa_ "too hot"
	label var sh128ab_ "size of the bed"
	label var sh128ac_ "not hung up/stored away"
	label var sh128ad_ "not in good condition"
	label var sh128ae_ "materiall too hard/rough"
	label var sh128af_ "child doesn't like"
	label var sh128ag_ "skin irritation"
	label var sh128ah_ "bad for health"
	label var sh128ai_ "superstition/witchcraft"
	label var sh128aj_ "too weak to hang"
	label var sh128ak_ "chemical smell/toxic"
	label var sh128al_ "saving for later"
	label var sh128am_ "no mosquitoes"
	label var sh128an_ "usual user(s) didn't sleep here"
	label var sh128ax_ "other"
	label var sh128az_ "don't know"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	foreach var of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128al_ sh128am_ sh128an_ sh128ax_ sh128az_ {
		replace `var'=0 if netused==1
	}
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/LBHR70_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Liberia2016") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128al_ sh128am_ sh128an_ sh128ax_ sh128az_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1)
		scalar `x'lb=round(mat2[1,2]*100,0.1)
		scalar `x'ub=round(mat3[1,2]*100,0.1)
		scalar `x'obs=mat4[1,2]
		
		** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/LBHR70_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/LBHR70_netfile_reasons.dta", replace
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128al_ sh128am_ sh128an_ sh128ax_ sh128az_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
				
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
			
***************			
*** Kenya  2015 ******
***************

	use KEHR7HFL.dta, clear
	gen filename="KEHR7H"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh126a* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/KEHR7H_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, etc
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh126a1_ sh126a2_ sh126a3_ sh126a4_ sh126a5_ sh126a6_ sh126a7_ , i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh126a1_ "net never used"
	label var sh126a2_ "excess nets"
	label var sh126a3_ "too hot"
	label var sh126a4_ "no mosquitoes"
	label var sh126a5_ "net being washed"
	label var sh126a6_ "usual user not here"
	label var sh126a7_ "other"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	 foreach var of varlist sh126a1_ sh126a2_ sh126a3_ sh126a4_ sh126a5_ sh126a6_ sh126a7_ {
		replace `var'=0 if netused==1
	}
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/KEHR7H_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Kenya2015") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh126a1_ sh126a2_ sh126a3_ sh126a4_ sh126a5_ sh126a6_ sh126a7_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1)
		scalar `x'lb=round(mat2[1,2]*100,0.1)
		scalar `x'ub=round(mat3[1,2]*100,0.1)
		scalar `x'obs=mat4[1,2]
		
		** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/KEHR7H_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply
	
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/KEHR7H_netfile_reasons.dta", replace
				
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh126a1_ sh126a2_ sh126a3_ sh126a4_ sh126a5_ sh126a6_ sh126a7_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
		
***************			
*** Ghana  2019 ******
***************

	use GHHR82FL.dta, clear
	gen filename="GHHR82"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh129* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/GHHR82_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, etc
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh129aa_ sh129ab_ sh129ac_ sh129ad_ sh129ae_ sh129af_ sh129ag_ sh129ah_ sh129ai_ sh129aj_ sh129ak_ sh129al_ sh129am_ sh129an_ sh129ax_, i(hhid) j(idx)
	
	clonevar seen=hml3_
	clonevar netage=hml4_
	
	clonevar isitn=hml10_
	clonevar numusers=hml11_
	clonevar netused=hml21_
	
	label var seen "net observed"
	label var netage "age of net"
	label var isitn "net is ITN"
	label var numusers "number of users of the net"
	label var netused "net was used the previous night"
	
	label var sh129aa_ "too hot"
	label var sh129ab_ "no mosquitoes"
	label var sh129ac_ "no malaria"
	label var sh129ad_ "prefer other method"
	label var sh129ae_ "net too old/torn"
	label var sh129af_ "chemicals are unsafe"
	label var sh129ag_ "don't like smell"
	label var sh129ah_ "net too short/small"
	label var sh129ai_ "usual user not here"
	label var sh129aj_ "extra/saving for later"
	label var sh129ak_ "net was being washed"
	label var sh129al_ "slept outside"
	label var sh129am_ "net brought bugs"
	label var sh129an_ "don't like shape"
	label var sh129ax_ "other"
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	 foreach var of varlist sh129aa_ sh129ab_ sh129ac_ sh129ad_ sh129ae_ sh129af_ sh129ag_ sh129ah_ sh129ai_ sh129aj_ sh129ak_ sh129al_ sh129am_ sh129an_ sh129ax_ {
		replace `var'=0 if netused==1
	}
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/GHHR82_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Ghana2019") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh129aa_ sh129ab_ sh129ac_ sh129ad_ sh129ae_ sh129af_ sh129ag_ sh129ah_ sh129ai_ sh129aj_ sh129ak_ sh129al_ sh129am_ sh129an_ sh129ax_ netused {
		estpost svy: tab `x'
		mat mat1= e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		scalar `x'p= round(mat1[1,2]*100,0.1)
		scalar `x'lb=round(mat2[1,2]*100,0.1)
		scalar `x'ub=round(mat3[1,2]*100,0.1)
		scalar `x'obs=mat4[1,2]
		
		** combine the CIs into one scalar with a dash between them, no brackets (see crosstabs brownbag sample do file for more ways)
		scalar `x'lb_str = string(`x'lb)
		scalar `x'ub_str = string(`x'ub)
		scalar `x'CI =  `x'lb_str + "-" + `x'ub_str 
		
		** create a scalar for the variable label to identify each line of the results
		local `x'_lbl : variable label `x'
		scalar `x'lbl="``x'_lbl'"
		
		
		putexcel A`row'=(dataset) B`row'=(hv007) C`row'=(`x'lbl) D`row'=(`x'p) E`row'=(`x'CI) F`row'=(`x'obs)
		
		* go to next variable
		local row = `row' + 1  
		}
	
	scalar drop _all
	mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/GHHR82_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply
	
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/GHHR82_netfile_reasons.dta", replace
				
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh129aa_ sh129ab_ sh129ac_ sh129ad_ sh129ae_ sh129af_ sh129ag_ sh129ah_ sh129ai_ sh129aj_ sh129ak_ sh129al_ sh129am_ sh129an_ sh129ax_ netused {
		
				levelsof `y' if netsupply==`x', local(lvl)
				
				if "`lvl'"=="0" {
					scalar `y'`x'=0
				}
				
				else {
					estpost svy: tab `y' if netsupply==`x', per
					mat mat1=e(b)
				
					scalar `y'`x'=round(mat1[1,2],0.1)
				}
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
		
				
				
