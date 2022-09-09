*** 3 Senegal seasonal reasons 

cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/" 
putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Sen_Season_Reason") modify
	putexcel A1=("dataset") B1=("Year") C1=("Reason net not used") D1=("overall ") E1=("95% CI") F1=("N") G1="month" I1=("among hh with not enough") J1=("among hh with just right") K1=("among hh with too many"), txtwrap
	
	local row=2

foreach c in SNHR61 SNHR6D SNHR70 SNHR7H SNHR7Q SNHR7Z SNHR80 SNHR8A {
	
	use `c'_netfile_reasons, clear
	
	
		** do % of nets used first
		
		
	
		
		tab reasonnotused, gen(sreason) // make dummy variables 
	
		foreach var of varlist sreason* {
			
			levelsof hv006 if `var'==1, local(monthlvl) // just get levels of month for which we have 1 responses in the dummy variable for reason 
			local rlab : variable label `var'
				di "`rlab'"
				
			foreach m of local monthlvl {
				estpost svy: tab `var' if hv006==`m', per
				scalar pp=round(e(b)[1,2],0.1)
				scalar lb=round(e(lb)[1,2],0.1)
				scalar ub=round(e(ub)[1,2],0.1)
				scalar obs=e(obs)[1,2]
			
				scalar lb_str = string(lb)
				scalar ub_str = string(ub)
				scalar CI =  lb_str + "-" + ub_str 
			
				putexcel A`row'="`c'" B`row'=hv007 C`row'="`rlab'" D`row'=pp E`row'=(CI) F`row'=(obs) G`row'="`m'"
				local row=`row'+1 
			
			} // next month
		} // next reason 
} // next survey
	
		
	
		
		/*
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
		