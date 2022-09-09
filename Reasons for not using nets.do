**** Reasons why NET was not used - this is the main focus of the paper.
	* UGHR72 - sh128aa-af, ax az 1-7
	* LBHR70 sh128aa-an 1-7
	* NGHR71 sh136 1-7
	* NGHR61 sh37 1-7
	
	* UGHR5H sh131a-e_1=7
	* SNPR70 sh135c_01-25
	* SNHR61 sh136d_01-25
	* SNHR7Q sh135c_01-25
	* SNPR7H sh135c
	* TZHR7H, sh137aa_al 1-7
	
*** Reasons why PERSON didn't use a net the previous night (we should probably explore this as well for the paper)
	* CDPR50 sh121aa-ag, incl don't have
	* MWPR6H, sh130aa-aj (<5)
	* MWPR71, sh130aa-aj (<5)
	* MDPR6H, sh41r
	* MDPR71, sh140
	* MDPR61, sh41r

	* BUPR6H, sh130ca-ce (alt use)
	

*** Reasons HOUSEHOLD not using nets all year (can explore in paper)
	* SNHR70 sh127c (not used all year)
	* SNHR61 sh127c (not used all year)
	* SNHR7H sh127c
	* SNHR7Q sh127c
	* SNHR60 sh127c
	* SNHR5H sh114c

*** Reasons why HOUSEHOLD doesn't have any nets (less interesting)
	* cdhr50, sh121aa-ag
	* LBPR61, sh121a-f
	* LBPR70, sh119aa-ag
	* LBPR5A, sh111a-d

	* SNPR5H sh114da-de
	* SNPR61 sh127da-de
	* SNPR6D sh127da-de
	* SNPR70 sh127da-de
	* SNPR7H sh127da-de
	* SNPR7Q sh127da-de

	* NGPR61 sh26a-d
	* NGPR71 sh122a-d

	* STPR50 sh128a
	* AOPR62 sh112a-d

*** Reasons net not hanging (correlates to first group of surveys but slightly different...probably ignore).
	* KEPR7H sh127cc1-5

************
*** Running estimates on datasets and putting into excel via putexcel
************

*** Part 1 Senegal ****
***********************

*** Senegal reasons why not using nets all year round. This runs one survey to start (because it's different variable)
*** and then runs several surveys in a loop to compare trends over time

	cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR"

	*** Senegal - single var with multiple answers, one survey
	
		putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Senegal Year-Round") replace
		putexcel A1=("Why do the members of this household not use nets year round?")
		putexcel B2=("2008-9") C2=("2010-2011") D2=("2012-2013") E2=("2014") F2=("2015") G2=("2016")
		
		local row=3
		
		use SNPR5HFL.dta, clear

			svyset hv001 [pw=hv005], strata(hv024)
			
			* levels and matrix locations won't match when value labels skip numbers
			* so you can either save each result as a separate scalar and putexcel them all at once
			* or recode the variable so that its levels are all sequential
			
			levelsof sh114c, local(lvl)
			estpost svy: tab sh114c, per
					
			mat mat1=e(b)
			scalar p1=round(mat1[1,1],0.1)
			scalar p2=round(mat1[1,2],0.1)
			scalar p3=round(mat1[1,3],0.1)
			scalar p4=round(mat1[1,4],0.1)
			scalar p6=round(mat1[1,5],0.1)
			scalar p8=round(mat1[1,6],0.1)
			scalar p9=round(mat1[1,7],0.1)
				foreach x of local lvl {
					local l`y': label sh114c `x'
					scalar lab`y'="`l`y''"
					putexcel A`row'=(lab`y') 
					local row = `row' + 1  
				}
			putexcel B3=(p1) B4=(p2) B5=(p3) B6=(p4) B7=(p6) B8=(p8) B9=(p9) 
			scalar drop _all
			mat drop _all
			
		
	** Senegal 2010-2016 - single var with multiple answers, looping through different surveys
		
		
		tokenize "C D E F G" 
		global senyear "SNHR61 SNHR6D SNHR70 SNHR7H SNHR7Q"
		
		foreach c in $senyear {
			use "`c'FL.dta", clear	
			
			svyset hv001 [pw=hv005], strata(hv024)
			estpost svy: tab sh127c, per
			
			mat mat1=e(b)
			scalar p1=round(mat1[1,1],0.1)
			scalar p2=round(mat1[1,2],0.1)
			scalar p3=round(mat1[1,3],0.1)
			scalar p4=round(mat1[1,4],0.1)
			scalar p6=round(mat1[1,5],0.1)
			scalar p8=round(mat1[1,6],0.1)
			
			local row=3
			 
			putexcel `1'`row'=(p1) 
			local row= `row' + 1
			putexcel `1'`row'=(p2) 
			local row=`row'+1
			putexcel `1'`row'=(p3)
			local row=`row'+1
			putexcel `1'`row'=(p4) 
			local row=`row'+1
			putexcel `1'`row'=(p6) 
			local row=`row'+1
			putexcel `1'`row'=(p8)
			
			mac shift 
		}
			
		
		scalar drop _all	
		mat drop _all
	
***********
**** Part 2 - Reasons why NET not used previous night
***********

** Surveys that have a net-level variable of any kind: UGHR72 LBHR70 NGHR71 NGHR61 UGHR5H SNPR70 SNHR61 SNHR7Q TZHR7H
** We take them one at a time because the varnames are not consistent from survey to survey. 

**** 
*** Uganda 2014
****
	use UGHR72FL.dta, clear
	gen filename="UGHR72" // gen the filename in order to label the survey when putting into excel and to permit running of naming do file
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh128* filename // keep only the relevant variables
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/UGHR72_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, 
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_, i(hhid) j(idx)
	
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
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	drop sh128ax* sh128az* // drop 'other' and 'Don't know' answers
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/UGHR72_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Uganda 2014") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ netused {
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

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/UGHR72_netfile_reasons.dta", replace
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ netused {
		
				estpost svy: tab `y' if netsupply==`x', per
				mat mat1=e(b)
				
				scalar `y'`x'=round(mat1[1,2],0.1)
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
		
*******		
*** Uganda 5H
*******

	use UGHR5HFL.dta, clear
	gen filename="UGHR5H"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh131* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/UGHR5H_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused

	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh131a_ sh131b_ sh131c_ sh131d_ sh131e_ sh131x_, i(hhid) j(idx)
	
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
	
	
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/UGHR5H_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Uganda 2009") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh131a_ sh131b_ sh131c_ sh131d_ sh131e_ sh131x_ netused {
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

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/UGHR5H_netfile_reasons.dta", replace
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh131a_ sh131b_ sh131c_ sh131d_ sh131e_ sh131x_ netused {
		
				estpost svy: tab `y' if netsupply==`x', per
				mat mat1=e(b)
				
				scalar `y'`x'=round(mat1[1,2],0.1)
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
				
*** Liberia

	use LBHR70FL.dta, clear
	gen filename="LBHR70"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh128* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/LBHR70_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, etc
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128al_ sh128am_ sh128an_ sh128ax_, i(hhid) j(idx)
	
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
	
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	drop sh128az*
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/LBHR70_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Liberia") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128al_ sh128am_ sh128an_ sh128ax_ netused {
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

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/LBHR70_netfile_reasons.dta", replace
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh128aa_ sh128ab_ sh128ac_ sh128ad_ sh128ae_ sh128af_ sh128ag_ sh128ah_ sh128ai_ sh128aj_ sh128ak_ sh128al_ sh128am_ sh128an_ sh128ax_ netused {
		
				estpost svy: tab `y' if netsupply==`x', per
				mat mat1=e(b)
				
				scalar `y'`x'=round(mat1[1,2],0.1)
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
			
*** Tanzania 
use TZHR7HFL.dta, clear
	gen filename="TZHR7H"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh137* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/TZHR7H_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also aa too hot, ab don't like smell, ac no mosq, ad too old/torn, ae not hung, af extra, etc
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh137aa_ sh137ab_ sh137ac_ sh137ad_ sh137ae_ sh137af_ sh137ag_ sh137ah_ sh137ai_ sh137aj_ sh137ak_ sh137al_ sh137ax_, i(hhid) j(idx)
	
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
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/TZHR7H_netfile_reasons.dta", replace
	
	** Putexcel looping through variables
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Tanzana 2015-16") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	foreach x of varlist sh137aa_ sh137ab_ sh137ac_ sh137ad_ sh137ae_ sh137af_ sh137ag_ sh137ah_ sh137ai_ sh137aj_ sh137ak_ sh137al_ sh137ax_ netused {
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

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/TZHR7H_netfile_reasons.dta", replace
				
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		foreach x of local netsupplylv {
		local row=2
			foreach y of varlist sh137aa_ sh137ab_ sh137ac_ sh137ad_ sh137ae_ sh137af_ sh137ag_ sh137ah_ sh137ai_ sh137aj_ sh137ak_ sh137al_ sh137ax_ netused {
		
				estpost svy: tab `y' if netsupply==`x', per
				mat mat1=e(b)
				
				scalar `y'`x'=round(mat1[1,2],0.1)
						
				putexcel `1'`row'=(`y'`x') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
				} // go to next variable
			mac shift
			} // go to next level of netsupply
			
			scalar drop _all
			mat drop _all
		
		

***********	
**** Part 3 - surveys with a single net-level question with multiple answers
***********


*** Senegal

use SNHR61FL.dta, clear
	gen filename="SNHR61"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh136d* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	* run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR61_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh136d, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh136d_, i(hhid) j(idx)
	
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
	
	label var sh136d_ "reason why net was not used"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR61_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Senegal 2011") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("% nets used in hh with not enough") I1=("% nets used in hh with just right") J1=("% nets used in hh with too many"), txtwrap
	
		** do % of nets used first
		
		local row=2
	foreach x of varlist netused {
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
	
	* next, run the single question with multiple non-sequential answers 
	
	
	local row=4
	
		estpost svy: tab sh136d_, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)7 { 
			scalar r`i'=round(mat1[1,`i'],0.1)
			scalar lb`i'=round(mat2[1,`i'],0.1)
			scalar ub`i'=round(mat3[1,`i'],0.1)
			scalar obs`i'=mat4[1,`i']
			
			scalar lb_str`i' = string(lb`i')
			scalar ub_str`i' = string(ub`i')
			scalar CI`i' =  lb_str`i' + "-" + ub_str`i' 
			
			putexcel D`row'=(r`i') E`row'=(CI`i') F`row'=(obs`i')
			local row=`row'+1
		}
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Total")
				
		
		scalar drop _all
		mat drop _all
		
		** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR61_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab sh136d_ if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)7 { // create scalars looping through the matrix results
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh135c
		mac shift // go to next column
		} // go to next level of netsupply
		
		scalar drop _all
		mat drop _all
		
		estpost svy: tab netsupply netused, row per
		mat mat1=e(b)
		scalar na=round(mat1[1,5],0.1)
		scalar nb=round(mat1[1,6],0.1)
		scalar nc=round(mat1[1,7],0.1)
		
		putexcel H2=(na) I2=(nb) J2=(nc)
		
		scalar drop _all
		mat drop _all
		
***** Senegal 
use SNHR70FL.dta, clear

gen filename="SNHR70"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135c_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR70_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh135c_, i(hhid) j(idx)
	
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
	
	label var sh135c_ "reason nobody slept in this net"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR70_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Senegal 2014") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("% nets used in hh with not enough") I1=("% nets used in hh with just right") J1=("% nets used in hh with too many"), txtwrap
	
		** do % of nets used first
		
		local row=2
	foreach x of varlist netused {
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
	
	* next, run the single question with multiple non-sequential answers 
	
		* levels and matrix locations won't match when value labels skip numbers
		* so you can either save each result as a separate scalar and putexcel them all at once
		* or recode the variable so that its levels are all sequential
	local row=4
	
		estpost svy: tab sh135c_, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)7 { 
			scalar r`i'=round(mat1[1,`i'],0.1)
			scalar lb`i'=round(mat2[1,`i'],0.1)
			scalar ub`i'=round(mat3[1,`i'],0.1)
			scalar obs`i'=mat4[1,`i']
			
			scalar lb_str`i' = string(lb`i')
			scalar ub_str`i' = string(ub`i')
			scalar CI`i' =  lb_str`i' + "-" + ub_str`i' 
			
			putexcel D`row'=(r`i') E`row'=(CI`i') F`row'=(obs`i')
			local row=`row'+1
		}
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Total")
				
		
		scalar drop _all
		mat drop _all
		
		** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR70_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

	
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab sh135c_ if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)7 { // create scalars looping through the matrix results
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh135c
		mac shift // go to next column
		} // go to next level of netsupply
		
		scalar drop _all
		mat drop _all
		
		estpost svy: tab netsupply netused, row per
		mat mat1=e(b)
		scalar na=round(mat1[1,5],0.1)
		scalar nb=round(mat1[1,6],0.1)
		scalar nc=round(mat1[1,7],0.1)
		
		putexcel H2=(na) I2=(nb) J2=(nc)
		
		scalar drop _all
		mat drop _all
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR70_netfile_reasons.dta", replace
	
*** Senegal 2015
use SNHR7HFL.dta, clear

gen filename="SNHR7H"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135c_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR7H_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh135c_, i(hhid) j(idx)
	
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
	
	label var sh135c_ "reason nobody slept in this net"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR7H_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Senegal 2015") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("% nets used in hh with not enough") I1=("% nets used in hh with just right") J1=("% nets used in hh with too many"), txtwrap
	
		** do % of nets used first
		
		local row=2
	foreach x of varlist netused {
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
	
	* next, run the single question with multiple non-sequential answers 
	
		* levels and matrix locations won't match when value labels skip numbers
		* so you can either save each result as a separate scalar and putexcel them all at once
		* or recode the variable so that its levels are all sequential
	local row=4
	
		estpost svy: tab sh135c_, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)7 { 
			scalar r`i'=round(mat1[1,`i'],0.1)
			scalar lb`i'=round(mat2[1,`i'],0.1)
			scalar ub`i'=round(mat3[1,`i'],0.1)
			scalar obs`i'=mat4[1,`i']
			
			scalar lb_str`i' = string(lb`i')
			scalar ub_str`i' = string(ub`i')
			scalar CI`i' =  lb_str`i' + "-" + ub_str`i' 
			
			putexcel D`row'=(r`i') E`row'=(CI`i') F`row'=(obs`i')
			local row=`row'+1
		}
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Total")
				
		
		scalar drop _all
		mat drop _all
		
		** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR7H_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab sh135c_ if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)7 { // create scalars looping through the matrix results
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh135c
		mac shift // go to next column
		} // go to next level of netsupply
		
		scalar drop _all
		mat drop _all
		
		estpost svy: tab netsupply netused, row per
		mat mat1=e(b)
		scalar na=round(mat1[1,5],0.1)
		scalar nb=round(mat1[1,6],0.1)
		scalar nc=round(mat1[1,7],0.1)
		
		putexcel H2=(na) I2=(nb) J2=(nc)
		
		scalar drop _all
		mat drop _all
		
** Senegal
	
use SNHR7QFL.dta, clear 


gen filename="SNHR7Q"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135c_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR7Q_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh135c_, i(hhid) j(idx)
	
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
	
	label var sh135c_ "reason nobody slept in this net"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/SNHR7Q_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Senegal 2016") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("% nets used in hh with not enough") I1=("% nets used in hh with just right") J1=("% nets used in hh with too many"), txtwrap
	
		** do % of nets used first
		
		local row=2
	foreach x of varlist netused {
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
	
	
	* next, run the single question with multiple non-sequential answers 
	
	
	local row=4
	
		estpost svy: tab sh135c_, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)7 { 
			scalar r`i'=round(mat1[1,`i'],0.1)
			scalar lb`i'=round(mat2[1,`i'],0.1)
			scalar ub`i'=round(mat3[1,`i'],0.1)
			scalar obs`i'=mat4[1,`i']
			
			scalar lb_str`i' = string(lb`i')
			scalar ub_str`i' = string(ub`i')
			scalar CI`i' =  lb_str`i' + "-" + ub_str`i' 
			
			putexcel D`row'=(r`i') E`row'=(CI`i') F`row'=(obs`i')
			local row=`row'+1
		}
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR7Q_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab sh135c_ if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)7 { // create scalars looping through the matrix results
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh135c
		mac shift // go to next column
		} // go to next level of netsupply
		
		scalar drop _all
		mat drop _all
		
		estpost svy: tab netsupply netused, row per
		mat mat1=e(b)
		scalar na=round(mat1[1,5],0.1)
		scalar nb=round(mat1[1,6],0.1)
		scalar nc=round(mat1[1,7],0.1)
		
		putexcel H2=(na) I2=(nb) J2=(nc)
		
		scalar drop _all
		mat drop _all

*** NGHR71 sh136 1-7
	
	use NGHR71FL.dta, clear 


gen filename="NGHR71"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh136_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/NGHR71_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh136_, i(hhid) j(idx)
	
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
	
	label var sh136_ "reason nobody slept in this net"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/NGHR71_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Nigeria 2015") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("% nets used in hh with not enough") I1=("% nets used in hh with just right") J1=("% nets used in hh with too many"), txtwrap
	
		** do % of nets used first
		
		local row=2
	foreach x of varlist netused {
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
	
	
	* next, run the single question with multiple non-sequential answers 
	
	
	local row=4
	
		estpost svy: tab sh136_, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)17 { 
			scalar r`i'=round(mat1[1,`i'],0.1)
			scalar lb`i'=round(mat2[1,`i'],0.1)
			scalar ub`i'=round(mat3[1,`i'],0.1)
			scalar obs`i'=mat4[1,`i']
			
			scalar lb_str`i' = string(lb`i')
			scalar ub_str`i' = string(ub`i')
			scalar CI`i' =  lb_str`i' + "-" + ub_str`i' 
			
			putexcel D`row'=(r`i') E`row'=(CI`i') F`row'=(obs`i')
			local row=`row'+1
		}
		
		putexcel C4=("No mosquitoes") C5=("No malaria") C6=("Too hot") C7=("Difficult to hang") C8=("Don't like smell") C9=("Feel closed in") C10=("Net too old/torn") C11=("Net too dirty") C12=("Net not available (washing)") C13=("Feel ITN chemicals are unsafe") C14=("ITN provokes coughing") C15=("Usual user did not sleep here") C16=("Net not needed last night") C17=("No place to hang") C18=("Other") C19=("Don't know") C20=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/NGHR71_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab sh136_ if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)17 { // create scalars looping through the matrix results
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh136
		mac shift // go to next column
		} // go to next level of netsupply
		
		scalar drop _all
		mat drop _all
		
		estpost svy: tab netsupply netused, row per
		mat mat1=e(b)
		scalar na=round(mat1[1,5],0.1)
		scalar nb=round(mat1[1,6],0.1)
		scalar nc=round(mat1[1,7],0.1)
		
		putexcel H2=(na) I2=(nb) J2=(nc)
		
		scalar drop _all
		mat drop _all
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/NGHR71_netfile_reasons.dta", replace
	

* NGHR61 sh37 1-7
	
	use NGHR61FL.dta, clear 


	gen filename="NGHR61"

	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh37_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/NGHR61_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh37_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh37_, i(hhid) j(idx)
	
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
	
	label var sh37_ "reason nobody slept in this net"
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/NGHR61_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Nigeria 2010") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("% (in nets) ") E1=("95% CI") F1=("N") H1=("% nets used in hh with not enough") I1=("% nets used in hh with just right") J1=("% nets used in hh with too many"), txtwrap
	
		** do % of nets used first
		
		local row=2
	foreach x of varlist netused {
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
	
	
	* next, run the single question with multiple non-sequential answers 
	
	
	local row=4
	
		estpost svy: tab sh37_, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)17 { 
			scalar r`i'=round(mat1[1,`i'],0.1)
			scalar lb`i'=round(mat2[1,`i'],0.1)
			scalar ub`i'=round(mat3[1,`i'],0.1)
			scalar obs`i'=mat4[1,`i']
			
			scalar lb_str`i' = string(lb`i')
			scalar ub_str`i' = string(ub`i')
			scalar CI`i' =  lb_str`i' + "-" + ub_str`i' 
			
			putexcel D`row'=(r`i') E`row'=(CI`i') F`row'=(obs`i')
			local row=`row'+1
		}
		
		putexcel C4=("No mosquitoes") C5=("No malaria") C6=("Too hot") C7=("Difficult to hang") C8=("Don't like smell") C9=("Feel closed in") C10=("Net too old/torn") C11=("Net too dirty") C12=("Net not available (washing)") C13=("Feel ITN chemicals are unsafe") C14=("ITN provokes coughing") C15=("Usual user did not sleep here") C16=("Net not needed last night") C17=("Other") C18=("Don't know") C19=("99") C20=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/NGHR61_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<1
		replace netsupply=4 if netpers>=1 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "just right" 4 "too many"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab sh37_ if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)17 { // create scalars looping through the matrix results ...foreach y of local reasonlvl 
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh37
		mac shift // go to next column
		} // go to next level of netsupply
		
		scalar drop _all
		mat drop _all
		
		estpost svy: tab netsupply netused, row per
		mat mat1=e(b)
		scalar na=round(mat1[1,5],0.1)
		scalar nb=round(mat1[1,6],0.1)
		scalar nc=round(mat1[1,7],0.1)
		
		putexcel H2=(na) I2=(nb) J2=(nc)
		
		scalar drop _all 
		mat drop _all
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/NGHR61_netfile_reasons.dta", replace
	

** Tanzania 2017 MIS - will be released after July 18th



*** END OF DO FILE

****
*** IMPORTANT: manually adjust the results for netsupply==4 (too many) for Senegal 2014, Nigeria 2010 and Nigeria 2015 because this netsupply category doesn't include all response
***				options for reason net not used. See below:
***
***		Senegal 2014 - 0 is for 'Don't know'
***		Nigeria 2015 - 0 is for "ITN provokes coughing"
***		Nigeria 2010 - 0 is for "No malaria", "Don't like smell", and "Net too dirty"
****

**** Other notes: DHS coding convention is for 9, 99, 999, 9999 to mean 'answer should have been provided but it is missing'. https://dhsprogram.com/pubs/pdf/DHSG4/Recode4DHS.pdf (2008)
*** We could therefore recode those answers as missing. But I haven't done so.
