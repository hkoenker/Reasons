**** multivariate regression for odds of net being used

clear
global hrdatanetsused "AOHR51 AOHR62 AOHR71 BJHR51 BJHR61 BFHR62 BFHR70 BUHR61 BUHR70 BUHR6H CDHR50 CDHR61 CGHR51 CGHR60 CIHR62 CMHR61 GAHR60 GHHR5A GHHR72 GHHR7A GMHR60 GNHR52 GNHR62 HTHR61 KEHR52 KEHR7H KEHR71 KHHR51 KMHR61 LBHR5A LBHR6A LBHR61 LBHR70 MDHR51 MDHR61 MDHR6H MDHR71 MLHR53 MLHR60 MLHR6H MLHR70 MMHR71 MWHR6H MWHR7H MWHR61 MWHR71 MZHR62 MZHR71 NGHR53 NGHR6A NGHR61 NGHR71 NIHR51 NIHR61 NMHR51 NMHR61 RWHR5A RWHR61 RWHR6Q RWHR70 SLHR51 SLHR61 SLHR71 SNHR5H SNHR6D SNHR7H SNHR50 SNHR61 SNHR70 SNHR7Q STHR50 SZHR51 TDHR71 TGHR61 TLHR61 TZHR51 TZHR6A TZHR63 TZHR7H UGHR5H UGHR52 UGHR60 UGHR72 UGHR7H VNHR52 ZMHR51 ZMHR61 ZWHR52 ZWHR62 ZWHR71"

** Rwanda 70 and Uganda 61 both get stuck and you have to either break Stata to get it to continue, or take those surveys out of the global list above

cd "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/"

** erase the previous version of the outreg2 file:
	cap erase "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/netsusedregression.xls"
	cap erase "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/netsusedregression.txt"

foreach c in $hrdatanetsused {

	use "`c'_netsused.dta", clear	

****
* Step 5 and 6
****
	** multiv regress for netused, outputting into a separate excel file. 
	** File needs to be DELETED before running the do file, otherwise it will append the new results onto the old results ad infinitum.
		cap svy: logistic netused  ib3.netsupply netagem isitn month urban region age_h sex_h i.ses, base
		cap outreg2 using "/Users/hannahkoenker/Dropbox/A DHS MIS Datasets/Analysis/Reasons/netsusedregression.xls", ef nose ci auto(2) nocons label append ctitle (`c')
}
