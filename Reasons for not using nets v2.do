




/*

**** ALL country % nets used by household net supply:
	use "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/percentnetsused 2018-8-8.dta", clear
	encode typeof, gen(misdhs)
	replace misdhs=. if misdhs==1
	* graph bar netsusedin*, over(surveyname, label(labsize(tiny))) ylabel(0(20)100) ytitle("% of nets used the previous night", size(med)) legend(label(1 "among hh with not enough nets") label(2 "among hh with just right nets") label(3 "among hh with too many nets") size(small)) bar(1, color(gs0)) bar(2, color(gs7)) bar(3, color(gs11))
	graph bar netsusedinhhwithnotenoug netsusedinhhwithjustrigh netsusedinhhwithtoomany
	
	graph bar netsusedinhhwithnotenoug netsusedinhhwithjustrigh netsusedinhhwithtoomany, over(mis)  ylabel(0(20)100) ytitle("% of nets used the previous night", size(med)) legend(label(1 "among hh with not enough nets") label(2 "among hh with 1 net for 2 people") label(3 "among hh with > 1 net for each person") size(vsmall)) bar(1, color(gs0)) bar(2, color(gs7)) bar(3, color(gs11))
	graph export "/Users/hannahkoenker/Dropbox/VectorWorks/OR/Reasons nets not used/bar_netsusedbysupply_survey.png", replace
	graph bar netsusedinhhwithnotenoug netsusedinhhwithjustrigh netsusedinhhwithtoomany, over(year)
	
	
		**** 5 country % nets used overall (scatter) and by hh supply (bar graph)
		import excel "/Users/hannahkoenker/Dropbox/VectorWorks/OR/Reasons nets not used/Reasons Excel Graphs.xlsx", firstrow case(lower) clear
		save "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/percentnetsused 4 countries", replace

			twoway  rcap pernlb pernub year, lcolor(gs13) || scatter pernetsused year, mlabel(country) mcolor(ebblue) mlabcolor(ebblue) ylabel(0(20)100) legend(off) ytitle("% of nets used the previous night")
			graph export "/Users/hannahkoenker/Dropbox/VectorWorks/OR/Reasons nets not used/natl per nets used 4 countries.png", replace

			graph bar notenough justright toomany, over(country, label(labsize(tiny))) ylabel(0(20)100) ytitle("% of nets used the previous night", size(med)) legend(label(1 "among hh with not enough nets") label(2 "among hh with just right nets") label(3 "among hh with too many nets") size(small)) bar(1, color(gs0)) bar(2, color(gs7)) bar(3, color(gs11))
			graph export "/Users/hannahkoenker/Dropbox/VectorWorks/OR/Reasons nets not used/natl per nets used 4 countries by supply bar.png", replace

			
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

*** subjective reasons: hot, smell, dirty, torn, no malaria, no mosquitoes, hard to hang, chemicals, coughing, closed in, not effective, witchcraft, child doesn't like, 
*** objective reasons: not needed, saving for later, usual user, no place to hang, washing/not avail, too small/bed size, 
*** mix: no mosquitoes, not hung up/stored away
