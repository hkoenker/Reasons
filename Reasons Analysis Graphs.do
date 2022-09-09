*** Reasons nets not used analysis and graphs


* Created: May 19 2020
* Modified:
* Author: Hannah Koenker

cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/"

**** All Country % nets used

 use "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/percentnetsused.dta", clear
 encode typeofsurvey, gen(surveytype)
 replace year="2018" if year=="2017-18"
 replace year="2016" if year=="2015-16"
 destring year, replace 
 
	twoway lfit netsused year  if surveytype==2 || lfit netsused year if surveytype==3 || lfit netsused year if surveytype==4 || scatter netsused year if surveytype==2, mlabel(country) mlabcolor(gs10) mlabsize(tiny) msymbol(s) || scatter netsused year if surveytype==3, mlabel(country) mlabcolor(gs10) mlabsize(tiny) msymbol(o)  || scatter netsused year if surveytype==4, mlabel(country) mlabcolor(gs10) mlabsize(tiny) msymbol(t) ytitle("Percent of nets used the previous night") xlabel(2002(2)2018) legend(label(1 "DHS linear fit") label(2 "MICS linear fit") label(3 "MIS linear fit") label(4 "DHS") label(5 "MICS") label(6 "MIS"))
	graph export netsusedbyyear.png, replace

	aaplot netsused year if surveytype // - no change
	regress netsused year if surveytype==2 // DHS, p=0.315
	regress netsused year if surveytype==3 // MICS, p=0.676
	regress netsused year if surveytype==4 // MIS, p=0.819

	rename netsusedinhhwithjustrigh justright
	rename netsusedinhhwithnotenoug notenough
	rename netsusedinhhwithtoomany toomany
	
	graph box notenough justright toomany,  over(surveytype) ylabel(0(20)100) ytitle("Percent of nets used the previous night") legend(label(1 "in hh with not enough nets") label(2 "in hh with ≥1 ITN for 2 people") label(3 "in hh with ≥1 ITN per person") col(3) size(vsmall)) // no big diffs by surveytype
	graph box notenough justright toomany,  ylabel(0(20)100) ytitle("Percent of nets used the previous night") legend(label(1 "in hh with not enough nets") label(2 "in hh with ≥1 ITN for 2 people") label(3 "in hh with ≥1 ITN per person") col(3) size(vsmall)) 
	graph export netused_bynetsupply.png, replace 
 	* twoway scatter netsused netsusedinhhwithnotenoug || scatter netsused netsusedinhhwithjustrigh || scatter netsused netsusedinhhwithtoomany

	*** see other do file, "odds of net being used regression" for individual country regressions
	

 *** percent of nets used the previous night simple
	 import excel "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Percent Nets Used") firstrow case(lower) clear
	 
	 label var lb "perc nets used lb"
	 label var ub "perc nets used ub"
	 label var percnets "percent of nets used the previous night"
	 
	 rename amonghhwithnotenough notenough
	 rename amonghhwithjustright justright
	 rename amonghhwithtoomany toomany
	 
	gen study=0
	replace study=1 if country=="Uganda"
	replace study=1 if country=="Tanzania"
	replace study=1 if country=="Senegal"
	replace study=1 if country=="Nigeria"
	replace study=1 if country=="Kenya"
	replace study=1 if country=="Mozambique"
	replace study=1 if country=="Liberia"

	graph bar notenough justright toomany if study==1,  over(country, lab(angle(45)) ) blabel(bar, format(%2.1f) size(vsmall)) bargap(2) ylabel(0(20)100) ytitle("Percent of nets used the previous night") legend(label(1 "in hh with not enough nets") label(2 "in hh with ≥1 ITN for 2 people") label(3 "in hh with ≥2 ITN per 3 persons") col(3) size(vsmall))
	graph export netsusedstudycountries.png, replace
 *** percent of nets used the previous night by household net supply
 
	 twoway scatter perc notenough || scatter perc justright || scatter perc toomany // is not really a scatter graph 
	 
	 graph bar notenough justright toomany, blabel(bar, format(%2.1f)) bargap(50) ylabel(0(10)100) legend(label(1 "in all households (hh)") label(2 "in hh with not enough nets") label(3 "in hh with ≥1 ITN for 2 people") label(4 "in hh with ≥2 ITN per 3 persons") col(2) size(vsmall))

	 graph bar notenough justright toomany, over(country, lab(angle(45) labsize(tiny))) bargap(2) // ugly. do over zone (central west southern eastern africa?)
	 
	 graph bar notenough justright toomany, over(year, lab(angle(45) labsize(tiny))) bargap(2) // meh, but sort of cyclical
 
 *** reasons for not using nets
 
 global reasonsfiles "Uganda2009 Uganda2014 Uganda2018 Tanzania2011 Tanzania2015 Tanzania2017 Liberia Kenya2015 Senegal2011 Senegal2012 Senegal2014 Senegal2015 Senegal2016 Senegal2017 Nigeria2010 Nigeria2015 Nigeria2018 Mozambique2018"
 
 foreach c in $reasonsfiles {
 
	import excel "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("`c'") firstrow case(lower) clear
		
		drop if reason==""
		drop if reason=="Total"
		gen file="`c'"
		
	tempfile temp`c'
	save "`temp`c''"
	
 }
 
 clear // to avoid having Mozambique in there twice
 
 foreach c in $reasonsfiles {
 	
	append using "`temp`c''"
		
 }
 
	drop g
 	 rename amonghhwithnotenough notenough
	 rename amonghhwithjustright justright
	 rename amonghhwithtoomany toomany
	 
	 replace toomany=0 if toomany==100
	 replace justright=0 if justright==100
	 replace notenough=0 if notenough==100
	 
	 
 save reasonsappend.dta, replace
 
 drop if reason=="net was used the previous night"
 drop if reason=="net was used"
 drop if reason=="Net was used"
 
	** data not set up for catplot; catplot is row that has two categorical variables further down the dataset, you are plotting those two cat vars against each other
	** 
	foreach c in $reasonsfiles {
	graph hbar overall if file=="`c'", over(reason)  graphregion(margin(40 0 0 0)) ylabel(0(10)50) title("`c'") legend(label(1 "in all households (hh)"))
	graph save `c'_overall_reasons.gph, replace
		graph export `c'_overall_reasons.png, replace
	}
	
	local glist: dir "." files "*overall_reasons.gph" 
	local glist: list sort glist
	graph combine `glist', col(3) ysize(10) altshrink
	graph export !overall_reasons_combo.png, replace
	graph export !overall_reasons_combo.pdf, replace
	
	 graph hbar overall notenough justright toomany if file=="Mozambique2018", over(reason) asyvar graphregion(margin(40 0 0 0)) ylabel(0(10)100) title("title") legend(label(1 "in all households (hh)") label(2 "in hh with not enough nets") label(3 "in hh with ≥1 ITN for 2 people") label(4 "in hh with ≥2 ITN per 3 persons") col(2) size(vsmall))

	foreach c in $reasonsfiles {
		
		graph hbar notenough justright toomany if file=="`c'", over(reason) asyvar graphregion(margin(40 0 0 0)) ylabel(0(10)50) title("`c'") legend(label(1 "in hh with not enough nets") label(2 "in hh with ≥1 ITN for 2 people") label(3 "in hh with ≥2 ITN per 3 persons") col(2) size(vsmall))
		graph save `c'_reasons_supp.gph, replace
		graph export `c'_reasons_supp.png, replace
		
	}
	
	local glist: dir "." files "*reasons_supp.gph" 
	local glist: list sort glist
	graph combine `glist', col(3) ysize(10) altshrink
	graph export !reasons_supp_combo.png, replace
	graph export !reasons_supp_combo.pdf, replace
 
 
 
 
 *** Senegal year-round reasons 
 cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/"

 
 	import excel "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets w graphs.xlsx", sheet("Senegal Year-Round") cellrange(J2:P9) firstrow case(lower) clear
	
	rename j year
	
	graph hbar nofewmosquitos heat dontlike fogetfulness other dontknow, over(year) blabel(bar, format(%2.0f) pos(center) size(vsmall)) stack  legend(label(1 "No/few mosquitoes") label(2 "Heat") label(3 "Don't like") label(4 "Forgetfulness") label(5 "Other") label(6 "Don't know")) title("Senegal: reported reasons for not using nets year round")
	graph export sen_yearround.png, replace
	
 *** year round net use yes/no vs pop access	
	import excel "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/Reasons for not using nets.xlsx", sheet("Senegal Use All Year") firstrow case(lower) clear
	rename household useallyear
	
	replace dataset="SNPR5H" if dataset=="SNHR5H"
	replace dataset="SNPR61" if dataset=="SNHR61"
	replace dataset="SNPR6D" if dataset=="SNHR6D"
	replace dataset="SNPR70" if dataset=="SNHR70"
	replace dataset="SNPR7H" if dataset=="SNHR7H"
	replace dataset="SNPR7Q" if dataset=="SNHR7Q"
	replace dataset="SNPR7Z" if dataset=="SNHR7Z"

	
	merge 1:1 dataset using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Analysis ITN Indicators Compiled/national_itn_indicators.dta"
	keep if _merge==3
	
	format useallyear %2.1f
	replace year=2010 if year==2011 // this survey is 2010-11, changed to match style for 2012-13 survey
	
	twoway rcap lb ub year, lcolor(gs13) || connected useallyear year, msymbol(O) lw(thick) mlabel(useallyear) mlabpos(12) mlabgap(4) || connected access_m year, msymbol(D) lw(thick) lp(dash) ylabel(0(10)100) xlabel(2008(1)2017) legend(label(2 "Households reporting year-round use of nets") label(3 "Proportion of population with access to an ITN") order(2 3) col(1)) ytitle("Percent of households reporting they use nets year round", size(small)) title(Senegal surveys 2008-2017)
	graph export sen_useallyear.png, replace
	
