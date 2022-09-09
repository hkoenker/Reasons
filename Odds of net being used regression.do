
******
****** Odds net was used the previous night regression
****** puts tables into separate tabs
****** creates graphs and then combines them

****** Created August 14, 2018
****** Modified: 
****** Last Run: Sept 11 2018
******
display "$S_TIME"

clear all
set maxvar 10000
set more off

* set the global macro. Won't run if it can't find datasets below.
run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/global HR PR lists.do"

grstyle init
grstyle set plain, horizontal compact grid dotted 
grstyle set color Dark2
*grstyle set mesh
*grstyle set plain, horizontal compact grid dotted 

* set the putexcel the first time to establish the file
putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/odds_net_used_regression v1.xlsx", replace
cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/"


** PUT EACH COUNTRY AS SEPARATE TAB in the set command above
 foreach c in $hrdatanetsusedodds {
	use "`c'_netsused.dta", clear	
	
	
	svyset [pw=hv005], psu(hv021) strata(hv024)
	
			
	* Naming Datasets
	run "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Naming_HRPR_Datasets.do"


	putexcel set "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/odds_net_used_regression v1.xlsx", sheet(`c') modify

	* putexcel the non-indicator data	
	putexcel A1="Datafile" B1="Dataset" C1="Country" D1="Year" E1="Survey Type"
	
		putexcel A2="`c'" A3="`c'" A4="`c'" A5="`c'" A6="`c'" A7="`c'" A8="`c'" A9="`c'"
		putexcel B2=dataset B3=dataset B4=dataset B5=dataset B6=dataset B7=dataset B8=dataset 
		putexcel C2=country C3=country C4=country C5=country C6=country C7=country C8=country 
		putexcel D2=hv007 D3=hv007 D4=hv007 D5=hv007 D6=hv007 D7=hv007 D8=hv007 
		putexcel E2=survey_type E3=survey_type E4=survey_type E5=survey_type E6=survey_type E7=survey_type E8=survey_type 
	
	egen netagey=cut(netagem), at(0,12,24,36,98) icodes
	label define netagey 0 "<12m" 1 "12-23m" 2 "24-35m" 3 "3+ yrs"
	label values netagey netagey
	label var netagey "age of net"
	
	 svy: logistic netused month region i.urban isitn brand i.netagey  i.ses ib3.netsupply 
		matrix results = r(table)
		matrix results = results[1..6,1...] 

	  putexcel F1 = matrix(results), names nformat(number_d2) hcenter
	
	 svy: logistic netused month region isitn brand i.netagey i.urban i.ses ib3.netsupply, base  
	 local gtitle=dataset
	* don't use a set xlabel axis range below:
	* cite using Ben Jann if kept in paper
	* set the graph size here?
	  coefplot, drop(_cons) xline(1) eform msymbol(o) xtitle("Odds ratio for net being used last night") baselevels title(`gtitle') headings(0.netagey = "{bf:Net Age}" 1.urban = "{bf:Residence}" 1.ses = "{bf:SES}" 1.netsupply = "{bf:ITN Supply}", labcolor(ebblue))
	* coefplot fem_age_bmi_reg_i, eform drop(_cons) xscale(log) xline(1, lwidth(vthin)) base coeflabels(female="Female" age="Age (years)" bmi="BMI" 1.region="Northeast" 2.region="Midwest" 3.region="South" 4.region="(reference cat) West") headings(1.region="{bf:Region}") order(bmi age female 4.region 1.region 2.region 3.region)
	 graph save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/OR Graphs/`c'_oddsnetwasused.gph", replace
	 graph export "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/OR Graphs/`c'_oddsnetwasused.png", replace
	matrix drop _all
}

				cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/OR Graphs"
 
                local ORlist: dir . files "*_oddsnetwasused.gph"
               local ORlist: list sort ORlist
                graph combine `ORlist'
                graph save "ORgraph.gph", replace
                graph export !_ORnetusedgraph.pdf, replace

***** Things that might theoretically go into a regression for net being used previous night:
* svy: logistic netused netsupply brand textile month region surveytype ses urban pfpr electricity fan floorimproved roofimproved wallsimproved recentmalariaepisode messageexposure onlymosqcausemalaria 'knowledge' nationallevelofaccess if year>2010
display "$S_TIME"
