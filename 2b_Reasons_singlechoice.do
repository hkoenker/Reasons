***********	
**** Part 2b - surveys with a single net-level question with multiple answers
***********

***********
*** Senegal
***********
clear
clear mata
clear matrix
set maxvar 20000

	cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR"

use SNHR61FL.dta, clear
	gen filename="SNHR61"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh136d* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	* run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR61_netfile_reasons.dta", replace
	
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
	
	clonevar reasonnotused=sh136d_
	replace reasonnotused=55 if netused==1 
	label copy SH136D reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR61_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2011") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
		
		** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR61_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab reasonnotused if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)8 { // create scalars looping through the matrix results
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
		
		local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
		
		
***** Senegal SNHR6D
use SNHR6DFL.dta, clear

gen filename="SNHR6D"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135c_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR6D_netfile_reasons.dta", replace
	
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
	
	clonevar reasonnotused=sh135c_
	replace reasonnotused=55 if netused==1 
	label copy V4100_A reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR6D_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2012") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
		
		** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR6D_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	
				estpost svy: tab reasonnotused  netsupply, col per
			mat mat1=e(b)
			mat li mat1
			
			local row=4 
		* check total number of cells in the matrix and input below:
			foreach i of numlist 1/32 {
				scalar r`i'=round(mat1[1,`i'],0.1)
			}
		
		putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 ///
				 I4=r9 I5=r10 I6=r11 I7=r12 I8=r13 I9=r14 I10=r15 I11=r16  ///
				 J4=r17 J5=r18 J6=r19 J7=r20 J8=r21 J9=r22 J10=r21 J11=r22 
		
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
		
				local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
***** Senegal 2014 SNHR70
use SNHR70FL.dta, clear

gen filename="SNHR70"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135c_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR70_netfile_reasons.dta", replace
	
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
	
	clonevar reasonnotused=sh135c_
	replace reasonnotused=55 if netused==1 
	label copy SH135C_3 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR70_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2014") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
		
		** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR70_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	
				estpost svy: tab reasonnotused  netsupply, col per
			mat mat1=e(b)
			mat li mat1
			
			local row=4 
		* check total number of cells in the matrix and input below:
			foreach i of numlist 1/32 {
				scalar r`i'=round(mat1[1,`i'],0.1)
			}
		
		putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 ///
				 I4=r9 I5=r10 I6=r11 I7=r12 I8=r13 I9=r14 I10=r15 I11=r16  ///
				 J4=r17 J5=r18 J6=r19 J7=r20 J8=r21 J9=r22 J10=r21 J11=r22 
	
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
		
		local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
		
*** Senegal 2015
use SNHR7HFL.dta, clear

gen filename="SNHR7H"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135c_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR7H_netfile_reasons.dta", replace
	
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
	
	clonevar reasonnotused=sh135c_
	replace reasonnotused=55 if netused==1 
	label copy SH135C_3 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR7H_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2015") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
		
		** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR7H_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab reasonnotused if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)8 { // create scalars looping through the matrix results
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
		
		local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
**** SNHR7Q Senegal 2016
	use SNHR7QFL.dta, clear 


gen filename="SNHR7Q"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh135c_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR7Q_netfile_reasons.dta", replace
	
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
	
	clonevar reasonnotused=sh135c_
	replace reasonnotused=55 if netused==1 
	label copy V4487_A reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR7Q_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2016") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR7Q_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab reasonnotused if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)8 { // create scalars looping through the matrix results
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

				local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
** Senegal 2017
	
use SNHR7ZFL.dta, clear 


gen filename="SNHR7Z"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh137ac_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR7Z_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh137ac_, i(hhid) j(idx)
	
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
	
	label var sh137ac_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh137ac_
	replace reasonnotused=55 if netused==1 
	label copy V5709_A reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR7Z_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2017") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR7Z_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab reasonnotused if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)8 { // create scalars looping through the matrix results
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
		
				local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
** Senegal 2018
	
use SNHR80FL.dta, clear 


gen filename="SNHR80"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh137ac_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR80_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh137ac_, i(hhid) j(idx)
	
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
	
	label var sh137ac_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh137ac_
	replace reasonnotused=55 if netused==1 
	label copy SH137AC_ reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR80_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2018") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR80_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab reasonnotused if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)8 { // create scalars looping through the matrix results
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh137c
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
		
				local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
** Senegal 2019
	
use SNHR8AFL.dta, clear 


gen filename="SNHR8A"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh137ac_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	* run the do file that renames the Senegal net variables to remove 0 in 1-9
	* not needed for 61
	 run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Senegal rename net vars.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR8A_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh137ac_, i(hhid) j(idx)
	
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
	
	label var sh137ac_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh137ac_
	replace reasonnotused=55 if netused==1 
	label copy SH137AC_ reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/SNHR8A_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal2019") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)8 { 
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
		
		putexcel C4=("No mosquitoes") C5=("Heat") C6=("Torn") C7=("Not effective") C8=("Other") C9=("Don't know") C10=("Net was used") C11=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/SNHR8A_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J" // set the columns to loop through
		
		
		foreach x of local netsupplylv {
			estpost svy: tab reasonnotused if netsupply==`x', per
			mat mat1=e(b)
			mat mat4=e(obs)
		local row=4 // set the starting row (back again after loop)
			forvalues i=1(1)8 { // create scalars looping through the matrix results
				scalar r`i'=round(mat1[1,`i'],0.1)
				
				putexcel `1'`row'=(r`i') // put the result into tokenized column (`1') and looping row
				local row=`row'+1 
			} // go to next value of matrix/sh137c
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
		
				local row=4
		forvalues z = 4/10 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}		

***********
* NGHR61 sh37 1-7 problems with the loop on tab sh37 per ; row labels saved in macro e(labels), invalid syntax.
***********
	
	use NGHR61FL.dta, clear 


	gen filename="NGHR61"

	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh37_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR61_netfile_reasons.dta", replace
	
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
	replace sh37=96 if sh37==99 // put 99 responses as "other" to avoid looping problems later down. we don't know what 99 is.
	
	
	clonevar reasonnotused=sh37_
	replace reasonnotused=55 if netused==1 
	label copy sh37_7 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==.  
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR61_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Nigeria2010") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
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
		
		putexcel C4=("No mosquitoes") C5=("No malaria") C6=("Too hot") C7=("Difficult to hang") C8=("Don't like smell") C9=("Feel closed in") C10=("Net too old/torn") C11=("Net too dirty") C12=("Net not available (washing)") C13=("Feel ITN chemicals are unsafe") C14=("ITN provokes coughing") C15=("Usual user did not sleep here") C16=("Net not needed last night") C17=("Net was used") C18=("Other") C19=("Don't know") C20="Total"
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/NGHR61_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

		* levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		* tokenize "H I J" // set the columns to loop through
		
		* levelsof sh37_, local(reasonlvl) // create levels of the reason value labels to loop through
		
			
			estpost svy: tab reasonnotused  netsupply, col per
			mat mat1=e(b)
			mat li mat1
			
			local row=4 
		* check total number of cells in the matrix and input below:
			foreach i of numlist 1/68 {
				scalar r`i'=round(mat1[1,`i'],0.1)
			}
		
		putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 H12=r9 H13=r10 H14=r11 H15=r12 H16=r13 H17=r14 H18=r15 H19=r16 H20=r17 ///
				 I4=r18 I5=r19 I6=r20 I7=r21 I8=r22 I9=r23 I10=r24 I11=r25 I12=r26 I13=r27 I14=r28 I15=r29 I16=r30 I17=r31 I18=r32  I19=r33 I20=r34 ///
				 J4=r35 J5=r36 J6=r37 J7=r38 J8=r39 J9=r40 J10=r41 J11=r42 J12=r43 J13=r44 J14=r45 J15=r46 J16=r47 J17=r48 J18=r49 J19=r50 J20=r51
		
		
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
		
				local row=4
		forvalues z = 4/20 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR61_netfile_reasons.dta", replace
	
***********
*** Nigeria 2015 NGHR71 sh136 1-7
***********
	
	use NGHR71FL.dta, clear 


gen filename="NGHR71"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh136_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR71_netfile_reasons.dta", replace
	
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
	
	clonevar reasonnotused=sh136_
	replace reasonnotused=55 if netused==1 
	label copy SH136_7 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR71_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Nigeria2015") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)18 { 
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
		
		putexcel C4=("No mosquitoes") C5=("No malaria") C6=("Too hot") C7=("Difficult to hang") C8=("Don't like smell") C9=("Feel closed in") C10=("Net too old/torn") C11=("Net too dirty") C12=("Net not available (washing)") C13=("Feel ITN chemicals are unsafe") C14=("ITN provokes coughing") C15=("Usual user did not sleep here") C16=("Net not needed last night") C17=("No space to hang") C18=("net was used") C19=("Other") C20=("Don't know") C21=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/NGHR71_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

					estpost svy: tab reasonnotused  netsupply, col per
					mat mat1=e(b)
					mat li mat1
					
					local row=4 
				* check total number of cells in the matrix and input below:
					foreach i of numlist 1/72 {
						scalar r`i'=round(mat1[1,`i'],0.1)
					}
				
				putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 H12=r9 H13=r10 H14=r11 H15=r12 H16=r13 H17=r14 H18=r15 H19=r16  H20=r17 H21=r18 ///
						 I4=r19 I5=r20 I6=r21 I7=r22 I8=r23 I9=r24 I10=r25 I11=r26 I12=r27 I13=r28 I14=r29 I15=r30 I16=r31 I17=r32 I18=r33 I19=r34  I20=r35 I21=r36 ///
						 J4=r37 J5=r38 J6=r39 J7=r40 J8=r41 J9=r42 J10=r43 J11=r44 J12=r45 J13=r46 J14=r47 J15=r48 J16=r49 J17=r50 J18=r51 J19=r52 J20=r53 J21=r54
			
			
		
		
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
		
						local row=4
		forvalues z = 4/21 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
	
		
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR71_netfile_reasons.dta", replace

***********	
*** Nigeria 2018 NGHR7A sh136a 1-7
***********
	
	use NGHR7AFL.dta, clear 


gen filename="NGHR7A"
	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh136a_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR7A_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh135c_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh136a_, i(hhid) j(idx)
	
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
	
	label var sh136a_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh136a_
	replace reasonnotused=55 if netused==1 
	label copy SH136A_7 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	

	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR7A_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Nigeria2018") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		forvalues i=1(1)18 { 
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
		
		putexcel C4=("No mosquitoes") C5=("No malaria") C6=("Too hot") C7=("Difficult to hang") C8=("Don't like smell") C9=("Feel closed in") C10=("Net too old/torn") C11=("Net too dirty") C12=("Net not available (washing)") C13=("Feel ITN chemicals are unsafe") C14=("ITN provokes coughing") C15=("Usual user did not sleep here") C16=("Net not needed last night") C17=("no space to hang") C18=("net was used") C19=("Other") C20=("Don't know") C21=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/NGHR7A_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply
	
		
				estpost svy: tab reasonnotused  netsupply, col per
					mat mat1=e(b)
					mat li mat1
					
					local row=4 
				* check total number of cells in the matrix and input below:
					foreach i of numlist 1/72 {
						scalar r`i'=round(mat1[1,`i'],0.1)
					}
				
				putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 H12=r9 H13=r10 H14=r11 H15=r12 H16=r13 H17=r14 H18=r15 H19=r16  H20=r17 H21=r18 ///
						 I4=r19 I5=r20 I6=r21 I7=r22 I8=r23 I9=r24 I10=r25 I11=r26 I12=r27 I13=r28 I14=r29 I15=r30 I16=r31 I17=r32 I18=r33 I19=r34  I20=r35 I21=r36 ///
						 J4=r37 J5=r38 J6=r39 J7=r40 J8=r41 J9=r42 J10=r43 J11=r44 J12=r45 J13=r46 J14=r47 J15=r48 J16=r49 J17=r50 J18=r51 J19=r52 J20=r53 J21=r54
			
			
		
		
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
		
		local row=4
		forvalues z = 4/21 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
	
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/NGHR7A_netfile_reasons.dta", replace
	

***********
* Mozambique 2018 - MZHR7A sh128a 1-7
***********
	
	use MZHR7AFL.dta, clear 


	gen filename="MZHR7A"

	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh128a_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/MZHR7A_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh37_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh128a_, i(hhid) j(idx)
	
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
	
	label var sh128a_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh128a_
	replace reasonnotused=55 if netused==1 
	label copy SH128A_7 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/MZHR7A_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Mozambique2018") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		* number loop below = # of responses in label, including other, dk.
		forvalues i=1(1)21 { 
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
		
		putexcel C4=("No mosquitoes") C5=("No malaria") C6=("Too hot") C7=("Difficult to hang") C8=("Don't like smell") C9=("Feel closed in") C10=("Net too old/torn") C11=("Net too dirty") C12=("Net not available (washing)") C13=("Causes itching") C14=("Usual user not here") C15=("Not needed last night") C16=("No hanging space") C17=("Reserved-for future use-new") C18=("net was used") C19=("Other") C20=("Don't know") C21=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/MZHR7A_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	/*	levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J K L M" // set the columns to loop through
		
		levelsof sh128a_, local(reasonlvl) // create levels of the reason value labels to loop through
	 estpost svy: tab sh128a_ if netsupply==1, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel H4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==3, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel J4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==4, per
	*esttab using mz18_netsupplyreasons.csv,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') 
	putexcel L4=matrix(r(table)), names
*/	
	
		
			estpost svy: tab reasonnotused  netsupply, col per
			mat mat1=e(b)
			mat li mat1
			
			local row=4 
		* check total number of cells in the matrix and input below:Tanzania2017
			foreach i of numlist 1/72 {
				scalar r`i'=round(mat1[1,`i'],0.1)
			}
		
				putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 H12=r9 H13=r10 H14=r11 H15=r12 H16=r13 H17=r14 H18=r15 H19=r16  H20=r17 H21=r18 ///
						 I4=r19 I5=r20 I6=r21 I7=r22 I8=r23 I9=r24 I10=r25 I11=r26 I12=r27 I13=r28 I14=r29 I15=r30 I16=r31 I17=r32 I18=r33 I19=r34  I20=r35 I21=r36 ///
						 J4=r37 J5=r38 J6=r39 J7=r40 J8=r41 J9=r42 J10=r43 J11=r44 J12=r45 J13=r46 J14=r47 J15=r48 J16=r49 J17=r50 J18=r51 J19=r52 J20=r53 J21=r54
			
		
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
		local row=4
		forvalues z = 4/21 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
	
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/MZHR7A_netfile_reasons.dta", replace
	
***********
* GUINEA 2021 - GNHR81 sh130_ 1-7
***********
	
	use GNHR81FL.dta, clear 


	gen filename="GNHR81"

	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh130_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/GNHR81_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh37_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh130_, i(hhid) j(idx)
	
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
	
	label var sh130_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh130_
	replace reasonnotused=55 if netused==1 
	label copy SH130_7 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/GNHR81_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Guinea2021") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		
		* number loop below = # of responses in label, including other, dk, netused, total.
		forvalues i=1(1)13 { 
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
		
		putexcel C4=("Too hot") C5=("Don't like shape/color/size") C6=("Don't like smell") C7=("Unable to hang") C8=("Slept outside") C9=("Usual user not here") C10=("No mosquitoes / no malaria") C11=("Extra/saved for later") C12=("Dirty/being washed") C13=("Used/perforated") C14=("Net used") C15="Other" C16=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/GNHR81_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	/*	levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J K L M" // set the columns to loop through
		
		levelsof sh128a_, local(reasonlvl) // create levels of the reason value labels to loop through
	 estpost svy: tab sh128a_ if netsupply==1, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel H4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==3, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel J4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==4, per
	*esttab using mz18_netsupplyreasons.csv,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') 
	putexcel L4=matrix(r(table)), names
*/	
	
		
			estpost svy: tab reasonnotused  netsupply, col per
			mat mat1=e(b)
			mat li mat1
			
			local row=4 
		* check total number of cells in the matrix and input below: Guinea 2020
			foreach i of numlist 1/52 {
				scalar r`i'=round(mat1[1,`i'],0.1)
			}
		
				putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 H12=r9 H13=r10 H14=r11 H15=r12 H16=r13 ///
						 I4=r14 I5=r15 I6=r16 I7=r17 I8=r18 I9=r19 I10=r20 I11=r21 I12=r22 I13=r23 I14=r24 I15=r25 I16=r26 ///
						 J4=r27 J5=r28 J6=r29 J7=r30 J8=r31 J9=r32 J10=r33 J11=r34 J12=r35 J13=r36 J14=r37 J15=r38 J16=r39
			
		
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
		local row=4
		forvalues z = 4/16 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
	
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/GNHR81_netfile_reasons.dta", replace
	
	
***********
* KENYA 2020 - KEHR81 sh130_ 1-7
***********
	
	use KEHR81FL.dta, clear 


	gen filename="KEHR81"

	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh130_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/KEHR81_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh37_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh130_, i(hhid) j(idx)
	
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
	
	label var sh130_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh130_
	replace reasonnotused=55 if netused==1 
	label copy SH130_7 reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/KEHR81_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Kenya2020") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		* number loop below = # of responses in label, including other, dk, netused, and +1 for Total.
		forvalues i=1(1)14 { 
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
		
		putexcel C4=("Too hot") C5=("Don't like shape/color/size") C6=("Don't like smell") C7=("Unable to hang") C8=("Slept outdoors") C9=("Usual user not here") C10=("No mosquitoes/no malaria") C11=("Extra/saving for later") C12=("Net too small/short") C13=("Net brought bedbugs") C14=("Net in poor condition") C15=("Net used") C16=("Other")  C17=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/KEHR81_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	/*	levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J K L M" // set the columns to loop through
		
		levelsof sh128a_, local(reasonlvl) // create levels of the reason value labels to loop through
	 estpost svy: tab sh128a_ if netsupply==1, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel H4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==3, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel J4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==4, per
	*esttab using mz18_netsupplyreasons.csv,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') 
	putexcel L4=matrix(r(table)), names
*/	
	
		
			estpost svy: tab reasonnotused  netsupply, col per
			mat mat1=e(b)
			mat li mat1
			
			local row=4 
		* check total number of cells in the matrix and input below: Kenya 2020
			foreach i of numlist 1/56 {
				scalar r`i'=round(mat1[1,`i'],0.1)
			}
		
				putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 H12=r9 H13=r10 H14=r11 H15=r12 H16=r13 H17=r14  ///
						 I4=r15 I5=r16 I6=r17 I7=r18 I8=r19 I9=r20 I10=r21 I11=r22 I12=r23 I13=r24 I14=r25 I15=r26 I16=r27 I17=r28  ///
						 J4=r29 J5=r30 J6=r31 J7=r32 J8=r33 J9=r34 J10=r35 J11=r36 J12=r37 J13=r38 J14=r39 J15=r40 J16=r41 J17=r42 
			
		
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
		local row=4
		forvalues z = 4/17 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
	
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/KEHR81_netfile_reasons.dta", replace
	
***********
* Madagascar 2021- MDHR80 sh137ab_
***********
	
	use MDHR80FL.dta, clear 


	gen filename="MDHR80"

	keep hhid hv000-hv025 hv270 hml3_* hml4_* hml7_* hml10_* hml11_* hml21_* sh137ab_* filename
	
	* Run the do file that names the datasets, to generate country name ("dataset") and survey_type info
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"
	
	
	
		
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/MDHR80_netfile_reasons.dta", replace
	
	* Reshaping the dataset to a long format, keeping seen, age, brand, isitn, numusers, netused
	* keep also sh37_, 'reasons nobody slept in this net'
	
	reshape long hml3_ hml4_ hml7_ hml10_ hml11_ hml21_ sh137ab_, i(hhid) j(idx)
	
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
	
	label var sh137ab_ "reason nobody slept in this net"
	
	clonevar reasonnotused=sh137ab_
	replace reasonnotused=55 if netused==1 
	label copy V2137_A reasonnotused 
	label define reasonnotused 55 "net was used", modify
	label values reasonnotused reasonnotused 
	replace reasonnotused=. if netused==.
	tab reasonnotused, m
	
	* drop reshaped obs that aren't needed - we just want the rows that are about nets
	drop if seen==. 
	
	
	svyset hv001 [pw=hv005], strata(hv024)
	
	save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/MDHR80_netfile_reasons.dta", replace
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Madagascar2021") modify
	putexcel A1=("Country") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	
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
	
		estpost svy: tab reasonnotused, per
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		mat mat4=e(obs)
		
		* number loop below = # of responses in label, including other, dk, netused, and +1 for Total.
		forvalues i=1(1)14 { 
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
		
		putexcel C4=("Too hot") C5="Don't like shape" C6="Don't like color" C7="Don't like size" C8=("Don't like smell") C9=("Unable to hang") C10=("Slept outside") C11=("Usual user not here") C12=("No mosquitoes/no malaria") C13=("Extra/saving for later") C14=("Net used") C15=("Other")  C16=("Total")
				
		
		scalar drop _all
		mat drop _all
	
	** investigate itnsupply for nets that have 'other' response
		merge m:1 hv001 hv002 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR/MDHR80_nitn.dta"
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & nnet==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply

	/*	levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J K L M" // set the columns to loop through
		
		levelsof sh128a_, local(reasonlvl) // create levels of the reason value labels to loop through
	 estpost svy: tab sh128a_ if netsupply==1, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel H4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==3, per
	*esttab,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') using mz18_netsupplyreasons.csv, replace
	putexcel J4=matrix(r(table)), names
	
	estpost svy: tab sh128a_ if netsupply==4, per
	*esttab using mz18_netsupplyreasons.csv,  not noobs nomtitle nonumber nostar varlabels(`e(labels)') 
	putexcel L4=matrix(r(table)), names
*/	
	
		
			estpost svy: tab reasonnotused  netsupply, col per
			mat mat1=e(b)
			mat li mat1
			
			local row=4 
		* check total number of cells in the matrix and input below: Mada 2021
			foreach i of numlist 1/52 {
				scalar r`i'=round(mat1[1,`i'],0.1)
			}
		
				putexcel H4=r1 H5=r2 H6=r3 H7=r4 H8=r5 H9=r6 H10=r7 H11=r8 H12=r9 H13=r10 H14=r11 H15=r12 H16=r13  ///
						 I4=r14 I5=r15 I6=r16 I7=r17 I8=r18 I9=r19 I10=r20 I11=r21 I12=r22 I13=r23 I14=r24 I15=r25 I16=r26   ///
						 J4=r27 J5=r28 J6=r29 J7=r30 J8=r31 J9=r32 J10=r33 J11=r34 J12=r35 J13=r36 J14=r37 J15=r38 J16=r39 
			
		
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
		local row=4
		forvalues z = 4/16 {
			putexcel A`row'=(dataset) B`row'=(hv007)
			local row=`row'+1
		}
	
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/MDHR80_netfile_reasons.dta", replace
	
