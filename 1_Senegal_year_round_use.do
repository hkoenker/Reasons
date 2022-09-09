*** Part 1 Senegal ****
***********************

clear
clear mata
clear matrix
set maxvar 20000




*** Senegal reasons why not using nets all year round. This runs one survey to start (because it's different variable)
*** and then runs several surveys in a loop to compare trends over time

	cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/AllHRPR"
	
***********************		
*** 1a: Senegal do members of this house use nets all year round 
***********************
	
	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal Use All Year") modify 
		putexcel A1="Year" B1="% household that use nets year round" C1="lb" D1="ub" E1="dataset"
		
	global senyearall "SNHR5H SNHR61 SNHR6D SNHR70 SNHR7H SNHR7Q SNHR7Z SNHR80 SNHR8A"
	tokenize sh114b sh127b sh127b sh127b sh127b	sh127b sh128b sh128b sh128b 
	local row=2
	
	foreach c in $senyearall {
		use `c'FL, clear
		svyset hv001 [pw=hv005], strata(hv024)
		estpost svy: tab `1' if hml1>0 & hml1!=., per // restrict to hh with at least one net, no missing
		mat mat1=e(b)
		mat mat2=e(lb)
		mat mat3=e(ub)
		
		scalar py=mat1[1,2]
		scalar plb=mat2[1,2]
		scalar pub=mat3[1,2]
		
		putexcel A`row'=hv007 B`row'=py C`row'=plb D`row'=pub E`row'="`c'"
		local row=`row'+1
		mac shift
	}

***********************
*** 1b: Reasons for households not using nets all year round 
***********************	

		putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal Year-Round") modify
		putexcel A1=("Why do the members of this household not use nets year round?")
		putexcel A2=("reason nets not used year round") B2=("2008-9") C2=("2010-2011") D2=("2012-2013") E2=("2014") F2=("2015") G2=("2016") H2=("2017") I2="2018" J2="2019"
		
		local row=3
		
		use SNHR5HFL.dta, clear // Senegal 2008 special variable
		
		
			svyset hv001 [pw=hv005], strata(hv024)
			
			* levels and matrix locations won't match when value labels skip numbers
			* so you can either save each result as a separate scalar and putexcel them all at once
			* or recode the variable so that its levels are all sequential
			* or fix it afterwards in the Excel file, which is what we've done....but that's a pain too. see end of do-file.
			* also note that '100' will appear when it's really 0.
			
			replace sh114c=. if sh114c==9 // change unknown '9' value to missing, per DHS guidance
			
			levelsof sh114c, local(lvl)
			estpost svy: tab sh114c if hml1>0 & hml1!=., per
					
			mat mat1=e(b)
			scalar p1=round(mat1[1,1],0.1)
			scalar p2=round(mat1[1,2],0.1)
			scalar p3=round(mat1[1,3],0.1)
			scalar p4=round(mat1[1,4],0.1)
			scalar p6=round(mat1[1,5],0.1)
			scalar p8=round(mat1[1,6],0.1)
			*scalar p9=round(mat1[1,7],0.1)
				foreach x of local lvl {
					local rlab: label sh114c `x'
					scalar rlab="`rlab'"
					putexcel A`row'=(rlab) 
					local row = `row' + 1  
				}
			putexcel B3=(p1) B4=(p2) B5=(p3) B6=(p4) B7=(p6) B8=(p8) 
			scalar drop _all
			mat drop _all
			
			local row=3
		
		
			
	** Senegal 2010-2017 - single var sh127c with multiple answers, looping through different surveys
		
		
		tokenize "C D E F G" 
		global senyear "SNHR61 SNHR6D SNHR70 SNHR7H SNHR7Q"
		
		foreach c in $senyear {
			use "`c'FL.dta", clear	
			
			svyset hv001 [pw=hv005], strata(hv024)
			estpost svy: tab sh127c if hml1>0 & hml1!=., per
			
			mat mat1=e(b)
			scalar p1=round(mat1[1,1],0.1)
			scalar p2=round(mat1[1,2],0.1)
			scalar p3=round(mat1[1,3],0.1)
			scalar p4=round(mat1[1,4],0.1)
			scalar p6=round(mat1[1,5],0.1)
			scalar p8=round(mat1[1,6],0.1)
			*scalar p9=round(mat1[1,7],0.1)
			
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
			*local row=`row'+1
			*putexcel `1'`row'=(p9)
			
			mac shift 
		}
		
		** Senegal 2017, 2018, 2019 surveys: sh128c
		
			tokenize "H I J"
			foreach c in SNHR7Z SNHR80 SNHR8A {
			
		
				use `c'FL.dta, clear // Senegal 2017, 2018, 2019 // sh128c question
			
			
				svyset hv001 [pw=hv005], strata(hv024)
				
				* levels and matrix locations won't match when value labels skip numbers
				* so you can either save each result as a separate scalar and putexcel them all at once
				* or recode the variable so that its levels are all sequential
				* or fix it afterwards in the Excel file, which is what we've done....but that's a pain too. see end of do-file.
				* also note that '100' will appear when it's really 0.
				
				levelsof sh128c, local(lvl)
				estpost svy: tab sh128c if hml1>0 & hml1!=., per
						
				mat mat1=e(b)
				scalar p1=round(mat1[1,1],0.1)
				scalar p2=round(mat1[1,2],0.1)
				scalar p3=round(mat1[1,3],0.1)
				scalar p4=round(mat1[1,4],0.1)
				scalar p6=round(mat1[1,5],0.1)
				scalar p8=round(mat1[1,6],0.1)
				*scalar p9=round(mat1[1,7],0.1)
					
				putexcel `1'3=(p1) `1'4=(p2) `1'5=(p3) `1'6=(p4) `1'7=(p6) `1'8=(p8)  
				scalar drop _all
				mat drop _all
				mac shift
			}
		
		scalar drop _all	
		mat drop _all
		
		
***********************
*** 1c: Reasons for households not using nets all year round, denominator=ALL HOUSEHOLDS
***********************	

		putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal Year-Round ALLHH") modify
		putexcel A1=("Why do the members of this household not use nets year round?")
		putexcel A2=("reason nets not used year round") B2=("2008-9") C2=("2010-2011") D2=("2012-2013") E2=("2014") F2=("2015") G2=("2016") H2=("2017") I2="2018" J2="2019"
		
		local row=3
		
		use SNHR5HFL.dta, clear // Senegal 2008 special variable
		
		
			svyset hv001 [pw=hv005], strata(hv024)
			
			* levels and matrix locations won't match when value labels skip numbers
			* so you can either save each result as a separate scalar and putexcel them all at once
			* or recode the variable so that its levels are all sequential
			* or fix it afterwards in the Excel file, which is what we've done....but that's a pain too. see end of do-file.
			* also note that '100' will appear when it's really 0.
			
			replace sh114c=8 if sh114c==9 // change unknown '9' value to "DK"
			replace sh114c=0 if sh114c==. // change missing (we DO use nets all year) to 0
			label define sh114c 0 "use all year", modify
			
			levelsof sh114c, local(lvl)
			estpost svy: tab sh114c if hml1>0 & hml1!=., per
					
			mat mat1=e(b)
			scalar p1=round(mat1[1,1],0.1)
			scalar p2=round(mat1[1,2],0.1)
			scalar p3=round(mat1[1,3],0.1)
			scalar p4=round(mat1[1,4],0.1)
			scalar p6=round(mat1[1,5],0.1)
			scalar p8=round(mat1[1,6],0.1)
			scalar p9=round(mat1[1,7],0.1)
				foreach x of local lvl {
					local rlab: label sh114c `x'
					scalar rlab="`rlab'"
					putexcel A`row'=(rlab) 
					local row = `row' + 1  
				}
			putexcel B3=(p1) B4=(p2) B5=(p3) B6=(p4) B7=(p6) B8=(p8) B9=(p9) 
			scalar drop _all
			mat drop _all
			
			local row=3
		
		
			
	** Senegal 2010-2017 - single var sh127c with multiple answers, looping through different surveys
		
		
		tokenize "C D E F G" 
		global senyear "SNHR61 SNHR6D SNHR70 SNHR7H SNHR7Q"
		
		foreach c in $senyear {
			use "`c'FL.dta", clear	
			
			svyset hv001 [pw=hv005], strata(hv024)
			replace sh127c=0 if sh127c==. // change missing (we DO use nets all year) to 0
			label define SH127C 0 "use all year", modify
			estpost svy: tab sh127c if hml1>0 & hml1!=., per
			
			mat mat1=e(b)
			scalar p1=round(mat1[1,1],0.1)
			scalar p2=round(mat1[1,2],0.1)
			scalar p3=round(mat1[1,3],0.1)
			scalar p4=round(mat1[1,4],0.1)
			scalar p6=round(mat1[1,5],0.1)
			scalar p8=round(mat1[1,6],0.1)
			scalar p9=round(mat1[1,7],0.1)
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
			local row=`row'+1
			putexcel `1'`row'=(p9)
			mac shift 
		}
		
		** Senegal 2017, 2018, 2019 surveys: sh128c
		
			tokenize "H I J"
			foreach c in SNHR7Z SNHR80 SNHR8A {
			
		
				use `c'FL.dta, clear // Senegal 2017, 2018, 2019 // sh128c question
			
			
				svyset hv001 [pw=hv005], strata(hv024)
				
				* levels and matrix locations won't match when value labels skip numbers
				* so you can either save each result as a separate scalar and putexcel them all at once
				* or recode the variable so that its levels are all sequential
				* or fix it afterwards in the Excel file, which is what we've done....but that's a pain too. see end of do-file.
				* also note that '100' will appear when it's really 0.
				replace sh128c=0 if sh128c==. // change missing (we DO use nets all year) to 0
				label define SH128C 0 "use all year", modify
				
				levelsof sh128c, local(lvl)
				estpost svy: tab sh128c if hml1>0 & hml1!=., per
						
				mat mat1=e(b)
				scalar p1=round(mat1[1,1],0.1)
				scalar p2=round(mat1[1,2],0.1)
				scalar p3=round(mat1[1,3],0.1)
				scalar p4=round(mat1[1,4],0.1)
				scalar p6=round(mat1[1,5],0.1)
				scalar p8=round(mat1[1,6],0.1)
				scalar p9=round(mat1[1,7],0.1)
					
				putexcel `1'3=(p1) `1'4=(p2) `1'5=(p3) `1'6=(p4) `1'7=(p6) `1'8=(p8) `1'9=(p9) 
				scalar drop _all
				mat drop _all
				mac shift
			}
		
		scalar drop _all	
		mat drop _all
		
		
***********************
*** 1d: Seasonal Senegal reasons for households not using nets all year round, denominator=ALL HOUSEHOLDS
***********************	

		putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output/Reasons for not using nets.xlsx", sheet("Senegal Year-Round by month") modify
		putexcel A1=("Why do the members of this household not use nets year round?")
		putexcel A2="dataset" B2="year" C2="reason nets not used year round" D2="month" E2="pct"
		
		local row=3
		
		use SNHR5HFL.dta, clear // Senegal 2008 special variable
		
		
			svyset hv001 [pw=hv005], strata(hv024)
			
			* levels and matrix locations won't match when value labels skip numbers
			* so you can either save each result as a separate scalar and putexcel them all at once
			* or recode the variable so that its levels are all sequential
			* or fix it afterwards in the Excel file, which is what we've done....but that's a pain too. see end of do-file.
			* also note that '100' will appear when it's really 0.
			
			replace sh114c=8 if sh114c==9 // change unknown '9' value to "DK"
			replace sh114c=0 if sh114c==. // change missing (we DO use nets all year) to 0
			label define sh114c 0 "use all year", modify
			
			levelsof sh114c, local(lvl)
			levelsof hv006, local(monthlvl) 
			
			tab sh114c, gen(reason) // make dummy variables to make looping easier
			
			foreach var of varlist reason* {
				local rlab : variable label `var'
				di "`rlab'"
				foreach m of local monthlvl {
					levelsof `var' if hv006==`m', local(checklvl)
					
					if "`checklvl'"=="0" {
						scalar p=0
					}
					
					else if "`checklvl'"=="1" {
						scalar p=100
					}
					
					else {
						estpost svy: tab `var' if hv006==`m' & hml1>0 & hml1!=., per
						scalar p=round(e(b)[1,2],.1) // save the Yes % into a scalar
					}
					
					putexcel A`row'="SNHR5H" B`row'=hv007 C`row'="`rlab'" D`row'="`m'" E`row'=p
					local row=`row'+1
					
			} // end month loop 
			
			
			} // end reason1-8 loop
			
			
			
		
		
			
	** Senegal 2010-2017 - single var sh127c with multiple answers, looping through different surveys
		
		
		
		global senyear "SNHR61 SNHR6D SNHR70 SNHR7H SNHR7Q"
		
		foreach c in $senyear {
			use "`c'FL.dta", clear	
			
			svyset hv001 [pw=hv005], strata(hv024)
			replace sh127c=0 if sh127c==. // change missing (we DO use nets all year) to 0
			label define SH127C 0 "use all year", modify
			
			levelsof sh127c, local(lvl)
			levelsof hv006, local(monthlvl) 
			
			tab sh127c, gen(reason) // make dummy variables to make looping easier
			
			foreach var of varlist reason* {
				local rlab : variable label `var'
				di "`rlab'"
				foreach m of local monthlvl {
					levelsof `var' if hv006==`m', local(checklvl)
					
					if "`checklvl'"=="0" {
						scalar p=0
					}
					
					else if "`checklvl'"=="1" {
						scalar p=100
					}
					
					else {
						estpost svy: tab `var' if hv006==`m' & hml1>0 & hml1!=., per
						scalar p=round(e(b)[1,2],.1) // save the Yes % into a scalar
					}
					
					putexcel A`row'="`c'" B`row'=hv007 C`row'="`rlab'" D`row'="`m'" E`row'=p
					local row=`row'+1
					
			} // next month  
			
			
			} // next reason1-8 
			
		} // next survey
		
		
		** Senegal 2017, 2018, 2019 surveys: sh128c
		
			
			foreach c in SNHR7Z SNHR80 SNHR8A {
			
		
				use `c'FL.dta, clear // Senegal 2017, 2018, 2019 // sh128c question
			
			
				svyset hv001 [pw=hv005], strata(hv024)
				
				* levels and matrix locations won't match when value labels skip numbers
				* so you can either save each result as a separate scalar and putexcel them all at once
				* or recode the variable so that its levels are all sequential
				* or fix it afterwards in the Excel file, which is what we've done....but that's a pain too. see end of do-file.
				* also note that '100' will appear when it's really 0.
				replace sh128c=0 if sh128c==. // change missing (we DO use nets all year) to 0
				label define SH128C 0 "use all year", modify
				
				levelsof sh128c, local(lvl)
			levelsof hv006, local(monthlvl) 
			
			tab sh128c, gen(reason) // make dummy variables to make looping easier
			
			foreach var of varlist reason* {
				local rlab : variable label `var'
				di "`rlab'"
				foreach m of local monthlvl {
					levelsof `var' if hv006==`m', local(checklvl)
					
					if "`checklvl'"=="0" {
						scalar p=0
					}
					
					else if "`checklvl'"=="1" {
						scalar p=100
					}
					
					else {
						estpost svy: tab `var' if hv006==`m' & hml1>0 & hml1!=., per
						scalar p=round(e(b)[1,2],.1) // save the Yes % into a scalar
					}
					
					putexcel A`row'="`c'" B`row'=hv007 C`row'="`rlab'" D`row'="`m'" E`row'=p
					local row=`row'+1
					
			} // end month loop 
			
			
			} // end reason1-8 loop
		
		
		
			} // next survey 
		
