

***** REASONS WHY NET WAS NOT USED THE PREVIOUS NIGHT *****
*** AND INVESTIGATION BY HOUSEHOLD NET SUPPLY ****

** DO FILE 0 - percent of nets used the previous night (2 minutes)
** This creates a putexcel document which is used later (modified) for the other analyses in the paper


clear
clear mata
clear matrix
set maxvar 20000

/*


**** Reasons why NET was not used - this is the main focus of the paper.
	* UGHR7I - sh128aa-ak ax az 1-7 INCLUDED BELOW
	* UGHR72 - sh128aa-af, ax az 1-7 INCLUDED BELOW 
	* UGHR5H sh131a-e_1=7  INCLUDED BELOW 
	* LBHR70 sh128aa-an 1-7 INCLUDED BELOW 
	* NGHR71 sh136 1-7 INCLUDED BELOW 
	* NGHR61 sh37 1-7 INCLUDED BELOW 
	** NGPR7A sh136a  INCLUDED BELOW 
	** GNHR81 sh130_1-7 -- CHECK
	** KEHR81 -- sh130 -- check
	
	
	** SNPR8A -- 137ac_01-25 series INCLUDED BELOW 
	** SNPR80 -- 137ac_01-25 series INCLUDED BELOW 
	** SNHR7Z 137ac INCLUDED BELOW 
	** SNPR7H sh135c INCLUDED BELOW 
	** SNHR6D sh135c_ 01-24 -- TO DO
	* SNHR61 sh136d_01-25 INCLUDED BELOW 
	* SNHR7Q sh135c_01-25  INCLUDED BELOW 
	** SNHR70 sh135c 01-30 INCLUDED BELOW 
	
	* TZHR7H, sh137aa_al 1-7 INCLUDED BELOW 
	* TZHR7Q, sh129ha-hl, xz 1-7 INCLUDED BELOW 
	** TZHR6A, sh125a-l, xz  INCLUDED BELOW 	
	** MZHR7A, sh128a 1-7 single question per net; multiple responses INCLUDED BELOW 
	** KEHR7H, sh126a1-7 INCLUDED BELOW 
	
	
	
*** Reasons why PERSON didn't use a net the previous night (we should probably explore this as well for the paper)
	* CDPR50 sh121aa-ag, incl don't have
	* MWPR6H, sh130aa-aj (<5)
	* MWPR71, sh130aa-aj (<5)
	* MDPR6H, sh41r
	* MDPR71, sh140
	* MDPR61, sh41r

	* BUPR6H, sh130ca-ce (alt use)
	
	
*** Does hh use nets all year round - Senegal sh127b HK TO EXPLORE/GRAPH

*** Reasons HOUSEHOLD not using nets all year (can explore in paper)
	* SNHR8A sh128c
	* SNHR80 sh128c
	** SNHR7Z sh128c (not used all year) 
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
	** SNPR7Z sh128da-e
	* SNHR80 sh128da-e
	* SNHR8A sh128da-e 
	

	* NGPR61 sh26a-d
	* NGPR71 sh122a-d

	* STPR50 sh128a
	* AOPR62 sh112a-d
	
	** MZHR7A sh127aa-ad x

*** Reasons net not hanging (correlates to first group of surveys but slightly different...probably ignore).
	* KEPR7H sh127cc1-5

************
*** Running estimates on datasets and putting into excel via putexcel
************

*** Part 0 Percent of nets used simple and by net supply ****
***********************

cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/output"

* set the global macro. Won't run if it can't find datasets below.
run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/global HR PR lists.do"

** Check to see how many nets are dropped when only "observed" nets are included:

putexcel set "Reasons for not using nets.xlsx", sheet("Observed Nets") replace
putexcel A1=("Country") B1=("Year") C1=("pct observed nets") D1="n not observed" E1="dataset", txtwrap
	local row=2
	
foreach c in $hrdatanetsused {
	use `c'_netsused.dta, clear
	
	estpost svy: tab seen, per 
	scalar pob=e(b)[1,2]
	scalar not=e(obs)[1,1]
	
	putexcel A`row'=country B`row'=hv007 C`row'=pob D`row'=not E`row'=dataset
	
	local row=`row'+1
} // next survey 

	
** DON"T REALLY NEED THIS AS WE USE A DIFFERENT NET_LEVEL FILE FOR PERCENT OF NETS USED...WHICH INCLUDES MICS. 


/*
putexcel set "Reasons for not using nets.xlsx", sheet("Percent Nets Used") replace
putexcel A1=("Country") B1=("Year") C1=("Perc nets used") D1=("lb") E1=("ub") F1=("N") G1="Dataset" H1=("among hh with not enough") I1=("among hh with just right") J1=("among hh with too many"), txtwrap
	local row=2
	
foreach c in $hrdatanetsused {
	use `c'_netsused.dta, clear
	

		estpost svy: tab netused, per 
		mat mat0 = e(b)
		mat mat1 = e(lb)
		mat mat2 = e(ub)
		mat mat3 = e(obs)
		
		scalar pnu = mat0[1,2]
		scalar nulb= mat1[1,2]
		scalar nuub= mat2[1,2]
		scalar nuobs=mat3[1,3]
		
		putexcel A`row'=country B`row'=hv007 C`row'=pnu D`row'=nulb E`row'=nuub F`row'=nuobs G`row'=dataset
	
		drop netsupply // get rid of old netsupply variable and label
		label drop netsupply
		
		gen netsupply=.
		replace netsupply=1 if netpers>0 & netpers<0.5

		replace netsupply=3 if netpers>=0.5 & netpers<.75
		replace netsupply=4 if netpers>=.75 & netpers!=.
		replace netsupply=3 if hv012==1 & hml1==1
		label var netsupply "household net supply"
		label define netsupply 1 "not enough" 3 "≥1 net per 2" 4 "≥2 net per 3"
		label values netsupply netsupply
		
		levelsof netsupply, local(netsupplylv) // create levels of the value labels for netsupply
		tokenize "H I J"
		
		
		foreach x of local netsupplylv {
		
				estpost svy: tab netused if netsupply==`x', per
				mat mat1=e(b)
				
				scalar nu`x'=mat1[1,2]
						
				putexcel `1'`row'=(nu`x') // put the result into tokenized column (`1') and looping row
				
				
			mac shift
			} // go to next level of netsupply
			
			
			scalar drop _all
			mat drop _all
		
		local row=`row'+1 
		
} 			
