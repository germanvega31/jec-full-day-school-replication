/**************************************************************************************************
Replication notes

This do-file starts from a cleaned analysis dataset (`data_clean.dta`). The raw Young Lives
Study data are not redistributed with this replication package and must be obtained from the
original data provider. The original data can be prepared following the procedure described
in the paper.

The analysis uses the younger cohort of the Young Lives Study for Peru. The Young Lives
child is referred to as the younger sibling and is identified in the code by `niñoM == 1`.
Older siblings are other household members linked to the Young Lives child and are identified
by `niñoM == 0` within the sibling sample.

The treatment is defined at the household level. A household is classified as a JEC household
if the younger sibling attended a Jornada Escolar Completa (JEC) school. JEC attendance is
identified using Round 5, which reports school attendance in 2015 and 2016, after the start
of the JEC program. The main treatment variable in the regressions is `JEC_niñoM`, the
interaction between younger-sibling status and JEC-household status.

The main outcome is higher education attainment. For younger siblings, this outcome is
measured in Round 6, when they were at least 18 years old. For older siblings, it is measured
using the earliest survey round in which they were 18 or older. The multinomial specifications
separate higher education into technical and university education.

Control variables are measured before potential exposure to JEC in secondary school. For
younger siblings, controls are mainly taken from Round 4, before they entered secondary
school; Round 3 is used only when Round 4 information is unavailable. For older siblings,
controls are taken from the latest available round up to Round 3 in which they were 12 years
old or younger. Since some siblings report inconsistent ages across survey rounds, age is
adjusted using the age reported in Round 1 and the year of each round. The regressions
control for siblings' age at both the outcome and control rounds.

The empirical strategy compares younger and older siblings within the same household and
then compares this sibling gap between JEC and non-JEC households. All main linear
specifications include household fixed effects and cluster standard errors at the Young Lives
satellite-site level. The reported confidence intervals are obtained using wild bootstrap
procedures.

Users should always verify that they are using the latest version of the code.

Required user-written Stata commands: reghdfe, boottest, estout/esttab, psmatch2,
stddiff, coefplot, and eret2. Please install these commands before running the do-file.
**************************************************************************************************/

clear all
set more off

*------------------------------------------------------------*
* 0. User settings
*------------------------------------------------------------*

* Define the project folder before running the do-file.
* Example: global project_folder "C:/Users/Name/Dropbox/JEC"
global project_folder ""

* Define the output folder. If left blank, the code creates/uses "output".
global output ""

if "$project_folder" != "" {
    cd "$project_folder"
}

if "$output" == "" {
    global output "output"
}

capture mkdir "$output"

*------------------------------------------------------------*
* 1. Initial settings and data loading
*------------------------------------------------------------*

graph set window fontface "Garamond"
set scheme modern

use "data_clean", clear
keep if obs_same_2 == 1 // Sample used, as described in the Data section of the paper

*------------------------------------------------------------*
* 2. Household counters
*------------------------------------------------------------*
rename N_hogar N_hogar_YLS
bysort CHILDCODE: gen N_hogar = _N

*------------------------------------------------------------*
* 3. Samples by type of older sibling
*------------------------------------------------------------*
* Closest older sibling 
gen hmM1  = rank_control_2 == 1 
gen sample_hmM1 =  (niñoM == 1 | hmM1 == 1) 

* Oldest older sibling   
gen hmM_lejano = rank_control_2 == N_hogar - 1
gen sample_hmM_lejano  =  (niñoM == 1| hmM_lejano  == 1) 

* Older siblings aged 18 or older in round 4 
gen sample_hmM_edu_lejos =  hogar_ronda4_18_2 == 1 & (niñoM == 1 | hmM_edu_lejos_2== 1)  


*------------------------------------------------------------*
* 4. Sample with school-hours information
*------------------------------------------------------------*
* Select households in which the younger sibling and at least one older sibling have school-hours data
gen niñoM_data_h = h_colegio_2 != . & niñoM == 1
gen hmM_data_h = h_colegio_2 !=. & niñoM == 0

bys CHILDCODE: egen hogar_niñoM_data_h = max(niñoM_data_h)
bys CHILDCODE: egen hogar_hmM_data_h = max(hmM_data_h)

gen hogar_data_h = hogar_niñoM_data_h == 1 & hogar_hmM_data_h == 1
gen sample_data_h = hogar_data_h == 1 & h_colegio_2 != .


* Differences in school hours between younger and older siblings
foreach sample in sample_data_h {
	gen aux_h_hmM = h_colegio_2 if niñoM==0 & `sample' == 1
 	gen aux_h_niñoM = h_colegio_2  if niñoM==1 & `sample' == 1
	
	bys CHILDCODE: egen h_niñoM = max(aux_h_niñoM)
	bys CHILDCODE: egen h_hmM = mean(aux_h_hmM)
	
	gen diff_`sample'=h_niñoM-h_hmM if `sample' == 1
	
	drop aux_h_hmM aux_h_niñoM h_niñoM h_hmM
} 


*------------------------------------------------------------*
* 5. Variable labels
*------------------------------------------------------------*
label var higher_18_2 "Higher education attainment"
label var JEC_miembro "Attended JEC school"
label var h_colegio_2 "Hours spent at school"
label var male "Male sibling"
label var edad_2 "Age (outcome round)"
label var edad_control_2 "Age (control round)"
label var orden_nacimiento_2 "Birth order"
label var N_2 "Members living in household"
label var N_hermanos_escolar_2 "Siblings in school age"
label var N_mayores_2 "Members aged 65 years or over"
label var N_pequeños_2 "Members under 5 years old "
label var N_higher_2 "Members with higher education"
label var dos_padres_2 "Live with both parents"
label var i_riqueza_2 "Wealth index"
label var madre_higher_2 "Mother attained higher education"
label var madre_edad_2 "Mother's age"

label var male_niñoM_ronda1 "Male younger child"
label var edad_niñoM_ronda1 "Age of younger child"
label var N_ronda1 "Members living in household"
label var N_hermanos_escolar_2_ronda1 "Siblings in school age"
label var N_mayores_2_ronda1 "Members aged 65 years or over"
label var N_pequeños_2_ronda1 "Members under 5 years old "
label var N_higher_2_ronda1 "Members with higher education"
label var dos_padres_ronda1 "Live with both parents"
label var riqueza_ronda1 "Wealth index"
label var p_riqueza_ronda1 "Wealth perception (out of 5)"
label var madre_edu_nada_ronda1 "Mother without any formal education"
label var madre_higher_ronda1 "Mother attained higher education"
label var madre_edad_2_ronda1 "Mother's age"
label var sv_ronda1 "Housing services index (0-1)"
label var ownhouse_ronda1 "House ownership"

*------------------------------------------------------------*
* 6. Matching variables
*------------------------------------------------------------*
* Within-household differences in control variables
local controles JEC_miembro higher_18_2  male edad_2 edad_control_2 orden_nacimiento_2 N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2
foreach var of varlist `controles' {
	gen aux_hmM_`var'= `var' if niñoM == 0
	bys CHILDCODE: egen hmM_`var' = mean(aux_hmM_`var')
	
	gen diffb_`var' = `var' - hmM_`var' if niñoM == 1
	local lbl : variable label `var'
	 label variable diffb_`var' `"`lbl'"'
}	

* Baseline (R1) measures for older siblings
gen edad_hmM_ronda1 = min_edad_2 if min_ronda == 1 & niñoM == 0
replace edad_hmM_ronda1 = min_edad_2 - 5 if min_ronda == 2 & niñoM == 0
bys CHILDCODE: egen edad_mean_hmM_ronda1 = mean(edad_hmM_ronda1)
label var edad_mean_hmM_ronda1 "Average age of older siblings"

gen aux_hmM_mean_male = male if niñoM == 0
bys CHILDCODE: egen  male_mean_hmM_ronda1 = mean(aux_hmM_mean_male)
label var male_mean_hmM_ronda1 "Share of male older siblings"

gen aux_hmM_mean_orden_nacimiento = orden_nacimiento_2 if niñoM == 0
bys CHILDCODE: egen orden_nacimiento_mean_hmM = mean(aux_hmM_mean_orden_nacimiento)
label var orden_nacimiento_mean_hmM "Average birth order of older siblings"

gen aux_niñoM_orden_nacimiento_2 = orden_nacimiento_2 if niñoM == 1
bys CHILDCODE: egen niñoM_orden_nacimiento_2 = max(aux_niñoM_orden_nacimiento_2)
label var niñoM_orden_nacimiento_2 "Birth order of younger child"

*------------------------------------------------------------*
* 7. Variable lists used in the analysis
*------------------------------------------------------------*
local var_d JEC_miembro higher_18_2 male edad_2 edad_control_2 orden_nacimiento_2 N_2 N_hermanos_escolar_2 ///
			N_mayores_2 N_pequeños_2 N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2
			
local controles male edad_2 edad_control_2 orden_nacimiento_2 N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 ///
			N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2	
			
local control_r1 male_niñoM_ronda1 male_mean_hmM_ronda1 edad_niñoM_ronda1 edad_mean_hmM_ronda1 niñoM_orden_nacimiento_2 ///
				orden_nacimiento_mean_hmM N_ronda1 N_hermanos_escolar_2_ronda1 N_mayores_2_ronda1 N_pequeños_2_ronda1 N_higher_2_ronda1 ///
				dos_padres_ronda1 riqueza_ronda1 p_riqueza_ronda1 madre_edu_nada_ronda1 madre_higher_ronda1 madre_edad_2_ronda1 sv_ronda1 ownhouse_ronda1 
		
				
local diffb_controles diffb_male diffb_edad_2 diffb_edad_control_2 diffb_orden_nacimiento_2 diffb_N_2 diffb_N_hermanos_escolar_2 diffb_N_mayores_2 ///
				diffb_N_pequeños_2 diffb_N_higher_2 diffb_dos_padres_2 diffb_i_riqueza_2 diffb_madre_higher_2 diffb_madre_edad_2
				
local control_r1_smd male_niñoM_ronda1 male_mean_hmM_ronda1 edad_niñoM_ronda1 edad_mean_hmM_ronda1 orden_nacimiento_2 orden_nacimiento_mean_hmM ///
					N_ronda1 N_hermanos_escolar_2_ronda1 N_mayores_2_ronda1 N_pequeños_2_ronda1 N_higher_2_ronda1 dos_padres_ronda1 riqueza_ronda1 ///
					madre_higher_ronda1 madre_edad_2_ronda1				
				
local controles_mean male_mean edad_2_mean edad_control_2_mean orden_nacimiento_2_mean N_2_mean N_hermanos_escolar_2_mean N_mayores_2_mean ///
					N_pequeños_2_mean N_higher_2_mean dos_padres_2_mean i_riqueza_2_mean madre_higher_2_mean madre_edad_2_mean		
					
local controles_0 male edad_0 edad_control_0 orden_nacimiento_0 N_0 N_hermanos_escolar_0 N_mayores_0 N_pequeños_0 ///
				N_higher_0 dos_padres_0 i_riqueza_0 madre_higher_0 madre_edad_0		
				

local x_diffb_controles diffb_male diffb_edad_2 diffb_edad_control_2 diffb_orden_nacimiento_2 x_N_2 x_N_hermanos_escolar_2 ///
			x_N_mayores_2 x_N_pequeños_2 x_N_higher_2 x_dos_padres_2 x_i_riqueza_2 x_madre_higher_2 x_madre_edad_2


local x_control_r1 male_niñoM_ronda1 male_mean_hmM_ronda1 edad_niñoM_ronda1 edad_mean_hmM_ronda1 niñoM_orden_nacimiento_2 ///
              orden_nacimiento_mean_hmM x_N_2 x_N_hermanos_escolar_2 x_N_mayores_2 x_N_pequeños_2 x_N_higher_2 x_dos_padres_2 ///
			  x_i_riqueza_2 p_riqueza_ronda1 madre_edu_nada_ronda1 x_madre_higher_2 x_madre_edad_2 sv_ronda1 ownhouse_ronda1 
				
					
				
*------------------------------------------------------------*
* 8. Table 1: Descriptive statistics, JEC vs. non-JEC households
*------------------------------------------------------------*
local s = 1
foreach sample in all niñoM hmM{
	
	preserve
	
	if `s' == 1 keep if niñoM != . //Dummy condition
	if `s' == 2 keep if niñoM == 1
	if `s' == 3 keep if niñoM == 0
	
	
	foreach list_type in var_d{
		
		local numcol: list sizeof `list_type'
		
		qui: mean ``list_type''
		matrix aux = e(b)
		local colnames : colfullnames aux
	
		matrix N0 = J(1,1,0)  //All
		matrix colnames N0 = Obs
		matrix N1 = J(1,1,0)  //Group 1 is var == 1
		matrix colnames N1 = Obs
		matrix N2 = J(1,1,0)  //Group 2 is var == 0
		matrix colnames N2 = Obs
	
		
		matrix m0 = J(1,`numcol',0)  //All
		matrix colnames m0=`colnames'
		matrix m1 = J(1,`numcol',0)  //Group 1 is var == 1
		matrix colnames m1=`colnames'
		matrix m2 = J(1,`numcol',0)  //Group 2 is var == 0
		matrix colnames m2=`colnames'
		
		matrix se0 = J(1,`numcol',0)  //All
		matrix colnames se0=`colnames'
		matrix se1 = J(1,`numcol',0)  //Group 1 is var == 1
		matrix colnames se1=`colnames'
		matrix se2 = J(1,`numcol',0)  //Group 2 is var == 0
		matrix colnames se2=`colnames'
		
		
		local a = 1
		foreach var of varlist ``list_type''{
			forvalues j = 0 / 2 {
				
				if `j' == 0 local condition ""
				if `j' == 1 local condition "if hogar_JEC_niñoM == 1"
				if `j' == 2 local condition "if hogar_JEC_niñoM == 0"
				
				qui: sum `var' `condition'
				
				if `a' == 1 matrix N`j'[1,`a'] = r(N)
				matrix m`j'[1,`a'] = r(mean)
				matrix se`j'[1,`a'] = r(sd)
				
			}
			local ++a
			
		}
		
		eststo diff: estpost ttest ``list_type'' , by(hogar_JEC_niñoM)
		
		matrix pval = e(p)
		
		foreach n_matrix in N0 N1 N2 se0 se1 se2 m0 m1 m2 pval{
			eststo diff:estadd matrix `n_matrix'
		}

		
		esttab  diff  using "$output/table_descriptive_`sample'.tex", ///
		cells("m0(pattern(1 1 0) fmt(3)) se0(pattern(1 1 0) fmt(3))  m1(pattern(1 1 0) fmt(3)) se1(pattern(1 1 0) fmt(3)) m2(pattern(1 1 0) fmt(3)) se2(pattern(1 1 0) fmt(3))  pval(fmt(3))")  label   ///
		 replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)
		 
		 esttab  diff  using "$output/table_descriptive_N_`sample'.tex", ///
			cells("N0 c N1 c N2  c c") label ///
			replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)

		
	}
	
	
	restore
	
	local ++s
}


*------------------------------------------------------------*
* 9. Table 2: Main estimates
*------------------------------------------------------------*
* Column 1: younger sibling vs. all older siblings
* Column 2: younger sibling vs. closest older sibling
* Column 3: younger sibling vs. oldest older sibling
* Column 4: younger sibling vs. older siblings aged 18 or older in R4

* Panel A: without controls

forvalues i = 1 / 4{
	if `i' == 1 local sample ""
	if `i' == 2 local sample "if sample_hmM1 == 1 "
	if `i' == 3 local sample "if sample_hmM_lejano == 1 " 
	if `i' == 4 local sample "if sample_hmM_edu_lejos  == 1"


	reghdfe higher_18_2 niñoM JEC_niñoM   `sample', a(CHILDCODE) vce(cl SATELITE)

	eret2 scalar hogares = e(df_a_initial) 
	eret2 scalar n_cluster = e(N_clust)
	est store r`i'

	estadd local blank "": r`i'
	
	matrix define ci_lower = (.,.)
	matrix define ci_upper = (.,.)
	matrix define ci_end = (1,1)
	
	boottest  niñoM = 0,  seed(101124)  boot(wild) nograph
	matrix A = r(CI)
	matrix ci_lower[1,1] = A[1,1]
	matrix ci_upper[1,1] = A[1,2]
	
	boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
	matrix A = r(CI)
	matrix ci_lower[1,2] = A[1,1]
	matrix ci_upper[1,2] = A[1,2]

	qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM"
	qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM"
	qui matrix colnames  ci_end = "niñoM" "JEC_niñoM"
	
	qui est restore r`i' //To restore information of regression
	eststo r`i' : estadd matrix ci_lower
	eststo r`i' : estadd matrix ci_upper
	eststo r`i' : estadd matrix ci_end
	
}
label var niñoM "SIB (\$\beta_1\$)"
label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH (\$\beta_2\$)}}"


esttab r1 r2 r3 r4  using "$output/table_main_a.tex", ///
	keep(niñoM JEC_niñoM) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )   ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households" "N clusters" ) fmt(%9.0f %9.0f %9.0f  %9.0f ))  ///
	replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)

* Panel B: with controls
forvalues i = 1 / 4{
	if `i' == 1 local sample ""
	if `i' == 2 local sample "if sample_hmM1 == 1 "
	if `i' == 3 local sample "if sample_hmM_lejano == 1 " 
	if `i' == 4 local sample "if sample_hmM_edu_lejos  == 1"
	
	reghdfe higher_18_2 niñoM JEC_niñoM  `controles' `sample', a(CHILDCODE) vce(cl SATELITE)
	
	eret2 scalar hogares = e(df_a_initial) 
	eret2 scalar n_cluster = e(N_clust)
	est store r`i'

	estadd local blank "": r`i'
	
	matrix define ci_lower = (.,.)
	matrix define ci_upper = (.,.)
	matrix define ci_end = (1,1)
	
	boottest  niñoM = 0,  seed(101124)  boot(wild) nograph
	matrix A = r(CI)
	matrix ci_lower[1,1] = A[1,1]
	matrix ci_upper[1,1] = A[1,2]
	
	boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
	matrix A = r(CI)
	matrix ci_lower[1,2] = A[1,1]
	matrix ci_upper[1,2] = A[1,2]

	qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM"
	qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM"
	qui matrix colnames  ci_end = "niñoM" "JEC_niñoM"
	
	qui est restore r`i' //To restore information of regression
	eststo r`i' : estadd matrix ci_lower
	eststo r`i' : estadd matrix ci_upper
	eststo r`i' : estadd matrix ci_end
	
}

label var niñoM "SIB (\$\beta_1\$)"
label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH (\$\beta_2\$)}}"

esttab r1 r2 r3 r4 using "$output/table_main_b.tex", ///
	keep(niñoM JEC_niñoM) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )   ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households" "N clusters" ) fmt(%9.0f %9.0f %9.0f  %9.0f ))  ///
	replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)
	
*------------------------------------------------------------*
* 10. Table 3: Robustness checks
*------------------------------------------------------------*
preserve
		
		
		
	local diffb_controles diffb_male diffb_edad_2 diffb_edad_control_2 diffb_orden_nacimiento_2 diffb_N_2 diffb_N_hermanos_escolar_2 diffb_N_mayores_2 ///
				diffb_N_pequeños_2 diffb_N_higher_2 diffb_dos_padres_2 diffb_i_riqueza_2 diffb_madre_higher_2 diffb_madre_edad_2	
	* Matching samples 
	psmatch2 hogar_JEC_niñoM `diffb_controles' if obs_same_2 == 1 & niñoM== 1, logit common n(1) caliper(0.1) noreplacement
	rename _pscore pscore_r4
	gen aux_sample_matched_r4 = _w!=.
	bys CHILDCODE: egen sample_matched_r4 = max(aux_sample_matched_r4)
	gen obs_sample_matched_r4 = sample_matched_r4 == 1 & obs_same_2 == 1
	label var pscore_r4 "Propensity score R4"
	
	psmatch2 hogar_JEC_niñoM `control_r1' if obs_same_2 == 1 & niñoM== 1, logit common n(1) caliper(0.1) noreplacement
	rename _pscore pscore_r1
	gen aux_sample_matched_r1 = _w!=.
	bys CHILDCODE: egen sample_matched_r1 = max(aux_sample_matched_r1)
	gen obs_sample_matched_r1 = sample_matched_r1 == 1 & obs_same_2 == 1
	label var pscore_r1 "Propensity score R1"
	
	
	* Additional sample indicators
	
	* Same public school throughout primary and secondary education
	gen obs_same_primary = hogar_niñoM_misma_escuela_14 == 1 & obs_same_2 == 1
	gen obs_same_always = hogar_niñoM_misma_escuela_always == 1 & obs_same_2 == 1
	
	bys departamento_ronda1: egen d_share_JEC = mean(JEC_niñoM)
	gen d_JEC = d_share_JEC> 0
	gen obs_d_JEC = d_JEC == 1 & obs_same_2 == 1
	
	
	* Column 1: matched sample based on within-household differences
	* Column 2: matched sample based on R1 baseline characteristics
	* Column 3: always attended public schools
	* Column 4: always attended the same public school
	* Column 5: only regions with JEC households
	* Column 6: excluding lagged students
	* Column 7 intentionally not used in final table
	
	
	forvalues i = 1 / 6{
		
		if `i' == 1 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_sample_matched_r4 == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 2 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_sample_matched_r1 == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 3 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_niñoMpublicoall_2 == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 4 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_same_always == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 5 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_d_JEC == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 6 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_hmMnonlagged_2 == 1, a(CHILDCODE) vce(cl SATELITE)

		
		
		eret2 scalar hogares = e(df_a_initial) 
		eret2 scalar n_cluster = e(N_clust)
		est store r`i'
		
		estadd local blank "": r`i'
		
		matrix define ci_lower = (.,.)
		matrix define ci_upper = (.,.)
		matrix define ci_end = (1,1)
		
		boottest niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		
		boottest JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,2] = A[1,1]
		matrix ci_upper[1,2] = A[1,2]
		
		qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM" 
		qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM" 
		qui matrix colnames  ci_end = "niñoM" "JEC_niñoM" 
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
	}
restore

label var niñoM "SIB (\$\beta_1\$)"
label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ JEC HH \\ (\$\beta_2\$)}}"

esttab r1 r2 r3 r4 r5 r6 using "$output/table_robust.tex", ///
	keep(niñoM JEC_niñoM) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )   ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households" "N clusters" ) fmt(%9.0f %9.0f %9.0f  %9.0f ))  ///
	replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)

*------------------------------------------------------------*
* 11. Table 4: Placebo tests using older siblings
*------------------------------------------------------------*	
* Column 1: placebo sample, younger vs. older siblings
* Column 2: closest older sibling vs. other older siblings
* Column 3: closest older sibling vs. second-closest older sibling
* Column 4: closest older sibling vs. oldest older sibling

preserve

	use "data_clean", clear
	
	keep if hogar_same_2 == 1 //Select no only the sample used, but also all the household members
	
	keep if obs_lejos_2==1 | (hogar_lejos_2 == 1 & niñoM==1 & obs_same_2 == 1 )
	
	gen dd_closest = hmM1_lejos_2*hogar_JEC_niñoM

	* Oldest sibling within the placebo sample
	bys CHILDCODE: egen total_lejos_2 = max(rank_lejos_2) 
	gen hmM_lejos_lejano = rank_lejos_2 == total_lejos_2
	gen sample_lejos_hmM_lejano  = obs_lejos_2==1  &  (hmM1_lejos_2 == 1| hmM_lejos_lejano  ==1)

	* Younger sibling specification
	reghdfe higher_18_2 niñoM JEC_niñoM  male edad_2 orden_nacimiento_2, a(CHILDCODE) vce(cl SATELITE)
	
	eret2 scalar hogares = e(df_a_initial) 
	eret2 scalar n_cluster = e(N_clust)
	est store r1

	estadd local blank "": r1
	
	matrix define ci_lower = (.,.)
	matrix define ci_upper = (.,.)
	matrix define ci_end = (1,1)
	
	boottest  niñoM = 0,  seed(101124)  boot(wild) nograph
	matrix A = r(CI)
	matrix ci_lower[1,1] = A[1,1]
	matrix ci_upper[1,1] = A[1,2]
	
	boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
	matrix A = r(CI)
	matrix ci_lower[1,2] = A[1,1]
	matrix ci_upper[1,2] = A[1,2]

	qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM"
	qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM"
	qui matrix colnames  ci_end = "niñoM" "JEC_niñoM"
	
	qui est restore r1 //To restore information of regression
	eststo r1 : estadd matrix ci_lower
	eststo r1 : estadd matrix ci_upper
	eststo r1 : estadd matrix ci_end
	
	local sample2 "if obs_lejos_2==1"
	local sample3 "if obs_lejos_2==1 & (hmM1_lejos_2==1|hmM2_lejos_2==1)"
	local sample4 "if sample_lejos_hmM_lejano == 1"

	forvalues i = 2 / 4{
		reghdfe higher_18_2 hmM1_lejos_2 dd_closest  male edad_2  orden_nacimiento_2  `sample`i'', a(CHILDCODE) vce(cl SATELITE)
		
		eret2 scalar hogares = e(df_a_initial) 
		eret2 scalar n_cluster = e(N_clust)
		est store r`i'

		estadd local blank "": r`i'
		estadd local t_fe "Yes": r`i'
		
		matrix define ci_lower = (.,.)
		matrix define ci_upper = (.,.)
		matrix define ci_end = (1,1)
		
		boottest hmM1_lejos_2 = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		
		boottest  dd_closest= 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,2] = A[1,1]
		matrix ci_upper[1,2] = A[1,2]

		qui matrix colnames  ci_lower = "hmM1_lejos_2" "dd_closest"
		qui matrix colnames  ci_upper = "hmM1_lejos_2" "dd_closest"
		qui matrix colnames  ci_end = "hmM1_lejos_2" "dd_closest"
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
		
	}
	
	label var niñoM "SIB"
	label var JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH }}"

	label var hmM1_lejos_2  "\multirow{2}{*}{\shortstack[l]{COS\$\\_\$SIB}}"
	label var  dd_closest  "\multirow{2}{*}{\shortstack[l]{COS\$\\_\$SIB \$\times\$\\ \,JEC HH}}"
	


	esttab r1 r2 r3 r4  using "$output/table_placebo.tex", ///
		keep(niñoM JEC_niñoM hmM1_lejos_2 dd_closest) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")") ) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  " ", ," ""  )  ///
stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households"  "N clusters"  ) fmt(%9.0f %9.0f  %9.0f %9.0f))    ///
		replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)
restore	

*------------------------------------------------------------*
* 12. Table 5: Multinomial logit estimates
*------------------------------------------------------------*
gen orden_nacimiento_2_aux = orden_nacimiento_2
replace orden_nacimiento_2_aux = 8 if orden_nacimiento_2>= 8 //To avoid singletons
tab orden_nacimiento_2_aux, gen(d_orden_nacimiento_2_)

* Bootstrap program
cap program drop bs_margins
	program bs_margins, eclass 
	
	local controles male edad_2 edad_control_2 orden_nacimiento_2 N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2
	local controles_mean male_mean edad_2_mean edad_control_2_mean orden_nacimiento_2_mean N_2_mean N_hermanos_escolar_2_mean N_mayores_2_mean N_pequeños_2_mean N_higher_2_mean dos_padres_2_mean i_riqueza_2_mean madre_higher_2_mean madre_edad_2_mean
	
	mlogit  higher_18_tipo_2 niñoM JEC_niñoM niñoM_mean JEC_niñoM_mean  `controles' `controles_mean'  , vce(cl SATELITE) base(0)
	margins, dydx(JEC_niñoM)  post
end

forvalues i = 1 / 4{
	if `i' == 1 local sample ""
	if `i' == 2 local sample "keep if sample_hmM1 == 1 "
	if `i' == 3 local sample "keep if sample_hmM_lejano == 1 " 
	if `i' == 4 local sample "keep if sample_hmM_edu_lejos  == 1"
	
	preserve
	
		`sample' 
		
		local var_mean "niñoM JEC_niñoM `controles'"
		foreach var of varlist `var_mean' {
		bys CHILDCODE: egen `var'_mean = mean(`var' )
		}
		
		matrix se_c = J(1,3,.)
		
		mlogit  higher_18_tipo_2 niñoM JEC_niñoM niñoM_mean JEC_niñoM_mean `controles' `controles_mean'  , base(0) vce(cl SATELITE) 
		
		margins, dydx(JEC_niñoM) post  vce(unconditional)
		eret2 scalar n_cluster = e(N_clust)
		count if niñoM == 1
		eret2 scalar hogares = r(N)
		
		estimates store r`i'
	
		estadd local blank "": r`i'
		
		matrix define ci_lower = (.,.,.)
		matrix define ci_upper = (.,.,.)
		matrix define ci_end = (1,1,1)
		
		bootstrap, reps(1000) cluster(SATELITE) seed(101124) : bs_margins
		
		matrix A = e(ci_normal)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[2,1]
		
		matrix ci_lower[1,2] = A[1,2]
		matrix ci_upper[1,2] = A[2,2]
		
		matrix A = e(ci_normal)
		matrix ci_lower[1,3] = A[1,3]
		matrix ci_upper[1,3] = A[2,3]
		
		qui matrix colnames se_c ="JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
		
		qui matrix colnames  ci_lower = "JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
		qui matrix colnames  ci_upper = "JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
		qui matrix colnames  ci_end = "JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
	restore
	
}

esttab r1 r2 r3 r4 using "$output/table_mlogit.tex", ///
	keep("JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict") b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ") ///
	substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )  ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households"  "N clusters"  ) fmt(%9.0f %9.0f  %9.0f %9.0f))    ///
	varlabel("JEC_niñoM:1._predict" "No higher education" "JEC_niñoM:2._predict" "Technical education" "JEC_niñoM:3._predict" "University education") ///
	replace nolabel fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers eqlabels(none) starlevels(* .1 ** .05 *** .01) collabels(none)
	
	
*------------------------------------------------------------*
* 13. Appendix Table A.9: Main estimates using household averages
*------------------------------------------------------------*
forvalues i = 1 / 4{
	if `i' == 1 local sample ""
	if `i' == 2 local sample "keep if sample_hmM1 == 1 "
	if `i' == 3 local sample "keep if sample_hmM_lejano == 1 " 
	if `i' == 4 local sample "keep if sample_hmM_edu_lejos  == 1"
		
	preserve
		
		`sample'
		
		local var_mean "niñoM JEC_niñoM `controles'"
			foreach var of varlist `var_mean' {
				bys CHILDCODE: egen `var'_mean = mean(`var' )
				}
		
		reg higher_18_2 niñoM niñoM_mean JEC_niñoM JEC_niñoM_mean `controles' `controles_mean' ,  vce(cl SATELITE)
		
		eret2 scalar n_cluster = e(N_clust)
		est store r`i'
		
		quietly count if niñoM == 1 & e(sample)
		local n_hogar = r(N)
		estadd scalar n_hogar = `n_hogar' : r`i'

		estadd local blank "": r`i'
		
		matrix define ci_lower = (.,.)
		matrix define ci_upper = (.,.)
		matrix define ci_end = (1,1)
		
		boottest  niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		
		boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,2] = A[1,1]
		matrix ci_upper[1,2] = A[1,2]

		qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM"
		qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM"
		qui matrix colnames  ci_end = "niñoM" "JEC_niñoM"
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end

	
	restore
}

label var niñoM "SIB (\$\beta_1\$)"
label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH (\$\beta_2\$)}}"

esttab r1 r2 r3 r4 using "$output/table_mlogit_device.tex", ///
	keep(niñoM JEC_niñoM) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )   ///
	stats(  blank N n_hogar n_cluster  , label( "\phantom{a}"  "Siblings" "Households"  "N clusters"  ) fmt(%9.0f %9.0f  %9.0f %9.0f))    ///
	replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)
	
*------------------------------------------------------------*
* 14. Appendix Table A.10: Multinomial logit placebo tests
*------------------------------------------------------------*
* Bootstrap program
* Younger-vs-older sibling comparison in the placebo sample
cap program drop bs_margins_JEC
	program bs_margins_JEC, eclass 
	
	mlogit  higher_18_tipo_2 niñoM JEC_niñoM  male edad_2 orden_nacimiento_2 niñoM_mean JEC_niñoM_mean male_mean edad_2_mean orden_nacimiento_2_mean  , vce(cl SATELITE) base(0)
	margins, dydx(JEC_niñoM)  post
end

preserve

	use "data_clean", clear
	
	keep if hogar_same_2 == 1
	
	keep if obs_lejos_2==1 | (hogar_lejos_2 == 1 & niñoM==1 & obs_same_2 == 1 )
	
	local var_mean "niñoM JEC_niñoM male edad_2 orden_nacimiento_2"
	foreach var of varlist `var_mean' {
		bys CHILDCODE: egen `var'_mean = mean(`var' )
	}
	
	gen dd_closest = hmM1_lejos_2*hogar_JEC_niñoM

	* Younger sibling specification
	mlogit higher_18_tipo_2 niñoM JEC_niñoM  male edad_2 orden_nacimiento_2 niñoM_mean JEC_niñoM_mean male_mean edad_2_mean orden_nacimiento_2_mean, vce(cl SATELITE) base(0)
	
	margins, dydx(JEC_niñoM) post  vce(unconditional)

	eret2 scalar n_cluster = e(N_clust)
	count if niñoM == 1
	eret2 scalar hogares = r(N)
	
	estimates store r1

	estadd local blank "": r1
	
	matrix se_c = J(1,3,.)
	matrix define ci_lower = (.,.,.)
	matrix define ci_upper = (.,.,.)
	matrix define ci_end = (1,1,1)
	
	bootstrap, reps(1000) cluster(SATELITE) seed(101124)  : bs_margins_JEC
	
	matrix A = e(ci_normal)
	matrix ci_lower[1,1] = A[1,1]
	matrix ci_upper[1,1] = A[2,1]
	
	matrix ci_lower[1,2] = A[1,2]
	matrix ci_upper[1,2] = A[2,2]
	
	matrix A = e(ci_normal)
	matrix ci_lower[1,3] = A[1,3]
	matrix ci_upper[1,3] = A[2,3]
	
	qui matrix colnames se_c ="JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
	
	qui matrix colnames  ci_lower = "JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
	qui matrix colnames  ci_upper = "JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
	qui matrix colnames  ci_end = "JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict"
	
	qui est restore r1 //To restore information of regression
	eststo r1 : estadd matrix ci_lower
	eststo r1 : estadd matrix ci_upper
	eststo r1 : estadd matrix ci_end
	
	esttab r1  using "$output/table_mlogit_placebo_1.tex", ///
keep("JEC_niñoM:1._predict" "JEC_niñoM:2._predict" "JEC_niñoM:3._predict")  ///
 b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ") ///
	substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )  ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households"  "N clusters"  ) fmt(%9.0f %9.0f  %9.0f %9.0f))    ///
	varlabel("JEC_niñoM:1._predict" "No higher education" "JEC_niñoM:2._predict" "Technical education" "JEC_niñoM:3._predict" "University education") ///
	replace nolabel fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers eqlabels(none) starlevels(* .1 ** .05 *** .01) collabels(none)	
restore	


* Older-sibling placebo comparisons
cap program drop bs_margins_placebo
	program bs_margins_placebo, eclass 
	mlogit  higher_18_tipo_2 hmM1_lejos_2 dd_closest  male edad_2  orden_nacimiento_2  hmM1_lejos_2_mean_placebo dd_closest_mean_placebo male_mean_placebo edad_2_mean_placebo orden_nacimiento_2_mean_placebo  , vce(cl SATELITE) base(0)
	margins, dydx(dd_closest)  post
end

forvalues i = 2/4{
	if `i' == 2 local sample "if obs_lejos_2==1"
	if `i' == 3 local sample "if obs_lejos_2==1 & (hmM1_lejos_2==1|hmM2_lejos_2==1)"
	if `i' == 4 local sample "if sample_lejos_hmM_lejano == 1"
	
	preserve

		use "data_clean", clear
		
		keep if hogar_same_2 == 1
		
		keep if obs_lejos_2==1 
		
		* Oldest sibling within the placebo sample
		if `i' == 4{
			bys CHILDCODE: egen total_lejos_2 = max(rank_lejos_2) 
			gen hmM_lejos_lejano = rank_lejos_2 == total_lejos_2
			gen sample_lejos_hmM_lejano  = obs_lejos_2==1  &  (hmM1_lejos_2 == 1| hmM_lejos_lejano  ==1)
		}
		
		if `i' > 2 keep `sample'
		
		gen dd_closest = hmM1_lejos_2*hogar_JEC_niñoM

		local var_mean "hmM1_lejos_2 dd_closest male edad_2 orden_nacimiento_2"
		foreach var of varlist `var_mean' {
			bys CHILDCODE: egen `var'_mean_placebo = mean(`var'  )
		}
			
		mlogit higher_18_tipo_2 hmM1_lejos_2 dd_closest  male edad_2  orden_nacimiento_2  hmM1_lejos_2_mean_placebo dd_closest_mean_placebo male_mean_placebo edad_2_mean_placebo orden_nacimiento_2_mean_placebo , vce(cl SATELITE) base(0)
			
			
		margins, dydx(dd_closest) post  vce(unconditional)
		
		eret2 scalar n_cluster = e(N_clust)
		count if niñoM == 1
		eret2 scalar hogares = r(N)
		
		estimates store r`i'
	
		estadd local blank "": r`i'
		
		matrix se_c = J(1,3,.)
		matrix define ci_lower = (.,.,.)
		matrix define ci_upper = (.,.,.)
		matrix define ci_end = (1,1,1)
		
		bootstrap, reps(1000) seed(101124) : bs_margins_placebo
		
		matrix A = e(ci_normal)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[2,1]
		
		matrix ci_lower[1,2] = A[1,2]
		matrix ci_upper[1,2] = A[2,2]
		
		matrix A = e(ci_normal)
		matrix ci_lower[1,3] = A[1,3]
		matrix ci_upper[1,3] = A[2,3]
		
		qui matrix colnames se_c ="dd_closest:1._predict" "dd_closest:2._predict" "dd_closest:3._predict"
		
		qui matrix colnames  ci_lower = "dd_closest:1._predict" "dd_closest:2._predict" "dd_closest:3._predict"
		qui matrix colnames  ci_upper = "dd_closest:1._predict" "dd_closest:2._predict" "dd_closest:3._predict"
		qui matrix colnames  ci_end = "dd_closest:1._predict" "dd_closest:2._predict" "dd_closest:3._predict"
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
		
	restore	
	
	}
	
esttab r2 r3 r4 using "$output/table_mlogit_placebo_2.tex", /// Need to combine with table_mlogit_placebo_1 to generate the table
keep("dd_closest:1._predict" "dd_closest:2._predict" "dd_closest:3._predict")  ///
 b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ") ///
	substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )  ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households"  "N clusters"  ) fmt(%9.0f %9.0f  %9.0f %9.0f))    ///
	varlabel("dd_closest:1._predict" "No higher education" "dd_closest:2._predict" "Technical education" "dd_closest:3._predict" "University education") ///
	replace nolabel fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers eqlabels(none) starlevels(* .1 ** .05 *** .01) collabels(none)	


*------------------------------------------------------------*
* 15. Table 6: Heterogeneous effects
*------------------------------------------------------------* 
preserve
		
		
	local controles male edad_2 edad_control_2 orden_nacimiento_2 N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 ///
			N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2		
		
	foreach var in QW1 rscorelang_cog  riqueza_ronda1 rural madre_higher_ronda1  {
		gen i_niñoM_`var' = niñoM * `var'
		gen i_JEC_niñoM_`var' = JEC_niñoM*`var'
	}
	
	local  i = 1
	foreach var in QW1 rscorelang_cog  riqueza_ronda1 madre_higher_ronda1     rural{
		
		if `i' == 4 reghdfe higher_18_2 niñoM JEC_niñoM i_niñoM_`var' i_JEC_niñoM_`var' male edad_2 edad_control_2 orden_nacimiento_2 N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 N_higher_2 dos_padres_2 i_riqueza_2 madre_edad_2, a(CHILDCODE) vce(cl SATELITE)
		
		if !inlist(`i',4) reghdfe higher_18_2 niñoM JEC_niñoM i_niñoM_`var' i_JEC_niñoM_`var' `controles', a(CHILDCODE) vce(cl SATELITE)

		eret2 scalar hogares = e(df_a_initial) 
		eret2 scalar n_cluster = e(N_clust)
		est store r`i'

		estadd local blank "": r`i'
		
		matrix define ci_lower = (.,.,.)
		matrix define ci_upper = (.,.,.)
		matrix define ci_end = (1,1,1)
		
		boottest  niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		
		boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,2] = A[1,1]
		matrix ci_upper[1,2] = A[1,2]
		
		boottest  i_JEC_niñoM_`var' = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,3] = A[1,1]
		matrix ci_upper[1,3] = A[1,2]

		qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM" "i_JEC_niñoM_`var'"
		qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM" "i_JEC_niñoM_`var'"
		qui matrix colnames  ci_end = "niñoM" "JEC_niñoM" "i_JEC_niñoM_`var'"
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
	
	local ++i
	}
	
	
	label var niñoM "SIB (\$\beta_1\$)"
	label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH (\$\beta_2\$)}}"
	
	local l_QW1  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH \$\times\$\\ Food program}}"
	local l_cog "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH \$\times\$\\ Cog. skills }}"
	local l_wi  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH \$\times\$\\ Wealth index }}"
	local l_m  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH \$\times\$\\ Mother higher educ. }}"
	local l_rural  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH \$\times\$\\ Rural }}"
	
	esttab r1 r2 r3 r4 r5 using "$output/table_heterogeneity.tex", ///
	keep(niñoM JEC_niñoM i_JEC_niñoM_QW1 i_JEC_niñoM_rscorelang_cog i_JEC_niñoM_riqueza_ronda1 i_JEC_niñoM_madre_higher_ronda1 i_JEC_niñoM_rural) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  " ", ," ""  ) ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households" "N clusters" ) fmt(%9.0f %9.0f %9.0f   %9.0f ))   ///
	 varlabels(i_JEC_niñoM_QW1 "`l_QW1'" i_JEC_niñoM_rscorelang_cog "`l_cog'" i_JEC_niñoM_riqueza_ronda1 "`l_wi'" i_JEC_niñoM_madre_higher_ronda1 "`l_m'" i_JEC_niñoM_rural "`l_rural'"  ) ///
	replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)
	
	
restore	

*------------------------------------------------------------*
* 16. Table 7: Mechanisms
*------------------------------------------------------------*
local controles male edad_2 edad_control_2 orden_nacimiento_2 N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 ///
			N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2	
preserve

	* Estimations
	* Secondary school completion
	reghdfe secundaria_fin_18_2 JEC_niñoM  `controles' ,  a(CHILDCODE) vce(cl SATELITE)
	
	eret2 scalar n_sib = e(N)
	eret2 scalar hogares = e(df_a_initial) 
	eret2 scalar n_cluster = e(N_clust)
	est store r1
	
	quietly sum secundaria_fin_18_2 if e(sample)
	local meany = r(mean)
	estadd scalar meany = `meany': r1

	estadd local blank "": r1
	estadd local sib "X": r1
	
	matrix define ci_lower = (.)
	matrix define ci_upper = (.)
	matrix define ci_end = (1)
	
	boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
	matrix A = r(CI)
	matrix ci_lower[1,1] = A[1,1]
	matrix ci_upper[1,1] = A[1,2]

	qui matrix colnames  ci_lower = "JEC_niñoM"
	qui matrix colnames  ci_upper = "JEC_niñoM"
	qui matrix colnames  ci_end =  "JEC_niñoM"
	
	qui est restore r1 //To restore information of regression
	eststo r1 : estadd matrix ci_lower
	eststo r1 : estadd matrix ci_upper
	eststo r1 : estadd matrix ci_end
		

	* R5 test scores among younger siblings

	local i = 2
	foreach yvar in maths reading{
		reg `yvar'_perco maths_R3 reading_R3 niñoM JEC_niñoM `controles' if niñoM == 1,  vce(cl SATELITE)
		
		eret2 scalar n_sib = e(N)
		eret2 scalar hogares = e(N)
		eret2 scalar n_cluster = e(N_clust)
		est store r`i'
		
		quietly sum `yvar'_perco if e(sample)
		local meany = r(mean)
		estadd scalar meany = `meany': r`i'

		estadd local skills "X": r`i'
	
		matrix define ci_lower = (.)
		matrix define ci_upper = (.)
		matrix define ci_end = (1)
		
		boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		

		qui matrix colnames  ci_lower = "JEC_niñoM"
		qui matrix colnames  ci_upper = "JEC_niñoM"
		qui matrix colnames  ci_end =  "JEC_niñoM"
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
		local ++i
	}
	
	* Other R5 mechanisms among younger siblings
	foreach var in missed p_homework teacher_most_quality  {
		reg `var'_r5 `var'_r4 JEC_niñoM `controles' if niñoM == 1,  vce(cl SATELITE)
		
		eret2 scalar n_sib = e(N)
		eret2 scalar hogares = e(N)
		eret2 scalar n_cluster = e(N_clust)
		est store r`i'
		
		quietly sum `var'_r5 if e(sample)
		local meany = r(mean)
		estadd scalar meany = `meany': r`i'

		estadd local control_r4 "X": r`i'
	
		matrix define ci_lower = (.)
		matrix define ci_upper = (.)
		matrix define ci_end = (1)
		
		boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		

		qui matrix colnames  ci_lower = "JEC_niñoM"
		qui matrix colnames  ci_upper = "JEC_niñoM"
		qui matrix colnames  ci_end =  "JEC_niñoM"
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
		local ++i
		
	}
	
	label var niñoM "SIB (\$\beta_1\$)"
	label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH (\$\beta_2\$)}}"
	
	esttab r1 r2 r3 r4 r5 r6 using "$output/table_mechanisms.tex", ///
	keep(JEC_niñoM) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )   ///
	stats(  blank sib skills control_r4 blank n_sib hogares n_cluster meany , label( "\phantom{a}" "Control for type of sibling" "Control for R3 skills" "Control for R4 value" "\phantom{a}" "Siblings" "Households" "N clusters" "Mean dep var." ) fmt(%9.0f %9.0f %9.0f %9.0f %9.0f %9.0f  %9.0f %9.0f %9.2f))    ///
	replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)


restore

*------------------------------------------------------------*
* 17. Figure 2 and auxiliary table: Time distribution
*------------------------------------------------------------*
preserve
	local i = 1
	foreach var in h_colegio_2 h_estudiar_2 h_jugar_2  h_dormir_2 h_tdomestico_2  h_trabajo{

	
		reghdfe `var' niñoM JEC_niñoM `controles' edad_h_colegio_2 if sample_data_h == 1 & obs_same_2==1, a(CHILDCODE) vce(cl SATELITE)
		
		eret2 scalar n_cluster = e(N_clust)
		eret2 scalar hogares = e(df_a_initial) 
		est store r`i'
		
		* Store coefficient matrix for the figure
		matrix b = e(b)[1, 1..2]

		estadd local blank "": r`i'
		
		* Matrices for table output
		matrix define ci_lower = (.,.)
		matrix define ci_upper = (.,.)
		matrix define ci_end = (1,1)
		
		* Matrix for bootstrapped confidence intervals in the figure
		matrix define ci_boot = J(2, 2, .) // Even when I only bootstrap for the second coefficient, I need to create a matrix with same dimension than b
		
		boottest  niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		
		boottest  JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		* Store confidence intervals for the table
		matrix ci_lower[1,2] = A[1,1]
		matrix ci_upper[1,2] = A[1,2]
		* Store confidence intervals for the figure
		matrix ci_boot[1, 2] = A[1,1] 
        matrix ci_boot[2, 2] = A[1,2]

		qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM"
		qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM"
		qui matrix colnames  ci_end = "niñoM" "JEC_niñoM"
		qui matrix colnames  b = "niñoM" "JEC_niñoM"
		
		* Matrices for plotting
        matrix ci_boot_`i' = ci_boot
        matrix b_`i' = b
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
		local ++i
		
	}
	
	label var niñoM "SIB (\$\beta_1\$)"
	label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ \,JEC HH (\$\beta_2\$)}}"

	esttab r1 r2 r3 r4 r5 r6 using "$output/table_time_ys.tex", ///
		keep(niñoM JEC_niñoM) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )  ///
		stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households" "N clusters" ) fmt(%9.0f %9.0f %9.0f  %9.0f ))    ///
		replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)


	 coefplot ///
        (matrix(b_1), ci((ci_boot_1[1] ci_boot_1[2])) aseq(School)) ///
		(matrix(b_2), ci((ci_boot_2[1] ci_boot_2[2])) aseq(Study at home)) ///
        (matrix(b_3), ci((ci_boot_3[1] ci_boot_3[2])) aseq(Leisure)) ///
        (matrix(b_4), ci((ci_boot_4[1] ci_boot_4[2])) aseq(Sleep)) ///
        (matrix(b_5), ci((ci_boot_5[1] ci_boot_5[2])) aseq(Domestic tasks)) ///
        (matrix(b_6), ci((ci_boot_6[1] ci_boot_6[2])) aseq(Unpaid and paid work)), ///
        keep(JEC_niñoM) xline(0) swapnames /// 
        ciopts(recast(rcap) lwidth(0.4) color(black)) ///
        format(%9.1f) ylabel(, labsize(medium)) xlabel(, labsize(medium)) ///
        msize(medium) msymbol(O) mcolor(black) legend(off) offset(0)
	graph export "$output/f_time_ys.pdf", replace
 
restore


*------------------------------------------------------------*
* 18. Other appendix tables
*------------------------------------------------------------*
* Appendix Table A.4: Included vs. excluded households
preserve

	use "data_clean", clear
	
	local control  male_niñoM_ronda1 edad_niñoM_ronda1 orden_nacimiento_2 N_ronda1 N_hermanos_escolar_2_ronda1 N_mayores_2_ronda1 N_pequeños_2_ronda1 N_higher_2_ronda1 dos_padres_ronda1 riqueza_ronda1 madre_higher_ronda1 madre_edad_2_ronda1 
	
	label var male_niñoM_ronda1 "Male younger child"
	label var edad_niñoM_ronda1 "Age of younger child"
	label var orden_nacimiento_2 "Birth order of younger child" // Same than niñoM_orden_nacimiento_2 because I will only use niñoM
	label var N_ronda1 "Members living in household"
	label var N_hermanos_escolar_2_ronda1 "Siblings in school age"
	label var N_mayores_2_ronda1 "Members aged 65 years or over"
	label var N_pequeños_2_ronda1 "Members under 5 years old "
	label var N_higher_2_ronda1 "Members with higher education"
	label var dos_padres_ronda1 "Live with both parents"
	label var riqueza_ronda1 "Wealth index"
	label var madre_higher_ronda1 "Mother attained higher education"
	label var madre_edad_2_ronda1 "Mother's age"
	
	keep if RONDA == 1
	keep if niñoM == 1
	
	
	foreach list_type in control{
			
			local numcol: list sizeof `list_type'
			
			qui: mean ``list_type''
			matrix aux = e(b)
			local colnames : colfullnames aux
		
			matrix N1 = J(1,1,0)  //Group 1 is var == 1
			matrix colnames N1 = Obs
			matrix N2 = J(1,1,0)  //Group 2 is var == 0
			matrix colnames N2 = Obs
		
			matrix m1 = J(1,`numcol',0)  //Group 1 is var == 1
			matrix colnames m1=`colnames'
			matrix m2 = J(1,`numcol',0)  //Group 2 is var == 0
			matrix colnames m2=`colnames'
			
			matrix se1 = J(1,`numcol',0)  //Group 1 is var == 1
			matrix colnames se1=`colnames'
			matrix se2 = J(1,`numcol',0)  //Group 2 is var == 0
			matrix colnames se2=`colnames'
			
			
			local a = 1
			foreach var of varlist ``list_type''{
				forvalues j = 1 / 2 {
					
					if `j' == 1 local condition "if hogar_same_2 == 1"
					if `j' == 2 local condition "if hogar_same_2 == 0"
					
					qui: sum `var' `condition'
					
					if `a' == 1 matrix N`j'[1,`a'] = r(N)
					matrix m`j'[1,`a'] = r(mean)
					matrix se`j'[1,`a'] = r(sd)
					
				}
				local ++a
				
			}
			
			stddiff ``list_type'', by(hogar_same_2)
			matrix diff_norm =   -r(stddiff)'
			matrix colnames diff_norm =`colnames'
			
			eststo diff: estpost ttest ``list_type'' , by(hogar_same_2)
			matrix pval = e(p)
			
			
			foreach n_matrix in N1 N2 se1 se2 m1 m2 pval diff_norm {
				eststo diff:estadd matrix `n_matrix'
			}

			
			esttab  diff  using "$output/table_compare_selected.tex", ///
			cells("m1(pattern(1 1 0) fmt(3)) se1(pattern(1 1 0) fmt(3)) m2(pattern(1 1 0) fmt(3)) se2(pattern(1 1 0) fmt(3))  pval(fmt(3)) diff_norm(fmt(3)) ")  label   ///
			 replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)
			 
			 esttab  diff  using "$output/table_compare_selected_N.tex", ///
				cells("N1 c N2  c c c") label ///
				replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)

			
		}

restore

* Appendix Tables A.5 and A.6: Balance diagnostics

preserve
	keep if niñoM == 1
	
	* Matching based on within-household control differences
	psmatch2 hogar_JEC_niñoM `diffb_controles', logit common n(1) caliper(0.1) noreplacement
	rename _pscore pscore_c
	
	gen sample_matched_c = _w!=.
	label var pscore_c "Propensity score controls"
	
	* Matching based on R1 baseline characteristics
	psmatch2 hogar_JEC_niñoM `control_r1', logit common n(1) caliper(0.1) noreplacement
	rename _pscore pscore_r1
	
	gen sample_matched_r1 = _w!=.
	label var pscore_r1 "Propensity score R1"
	
	
	* Balance measures for control variables
	local lists "diffb_controles control_r1_smd"
	
	
	foreach L in `lists' {
		
		if "`L'" == "diffb_controles" local term "controles"
		if "`L'" == "control_r1_smd" local term "r1"
		
		local vars ``L''
	
		local numcol : word count `vars'

		qui: mean `vars'
		matrix aux = e(b)
		local colnames : colfullnames aux

		matrix N1 = J(1,1,0)  //Group 1 is var == 1
		matrix colnames N1 = Obs
		matrix N2 = J(1,1,0)  //Group 2 is var == 0
		matrix colnames N2 = Obs

		matrix m1 = J(1,`numcol',0)  //Group 1 is var == 1
		matrix colnames m1=`colnames'
		matrix m2 = J(1,`numcol',0)  //Group 2 is var == 0
		matrix colnames m2=`colnames'
		
		matrix se1 = J(1,`numcol',0)  //Group 1 is var == 1
		matrix colnames se1=`colnames'
		matrix se2 = J(1,`numcol',0)  //Group 2 is var == 0
		matrix colnames se2=`colnames'
		
		matrix lse_ratio = J(1,`numcol',0) 
		matrix colnames lse_ratio=`colnames'
		
		
		local a = 1
		foreach var of varlist `vars'{
			forvalues j = 1 / 2 {
				if `j' == 1 local condition "if hogar_JEC_niñoM == 1"
				if `j' == 2 local condition "if hogar_JEC_niñoM == 0"
				
				qui: sum `var' `condition'
				
				if `a' == 1 matrix N`j'[1,`a'] = r(N) //Only for first variable because all variable have the same number of observations
				matrix m`j'[1,`a'] = r(mean)
				matrix se`j'[1,`a'] = r(sd)
				scalar se_`j' = r(sd)
			
				if `j' == 2 matrix lse_ratio[1,`a'] =  ln(se_1) - ln(se_2)
				
			}
			local ++a
			
		}
		
		stddiff `vars', by(hogar_JEC_niñoM)
		matrix diff_norm =   -r(stddiff)'
		matrix colnames diff_norm =`colnames'
		
		eststo diff_`term': estpost ttest `vars' , by(hogar_JEC_niñoM)
		
		foreach n_matrix in N1 N2 se1 se2 m1 m2 diff_norm lse_ratio {
			eststo diff_`term':estadd matrix `n_matrix'
		}

		esttab  diff_`term'  using "$output/table_balance_`term'.tex", ///
		cells("m1(pattern(1 1 0) fmt(3)) se1(pattern(1 1 0) fmt(3)) m2(pattern(1 1 0) fmt(3)) se2(pattern(1 1 0) fmt(3)) diff_norm(fmt(3))  lse_ratio(fmt(3)) ")  label   ///
		 replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)
		 
	
	}
	
	* Multivariate and propensity-score balance measures
	
	matrix score_m1 = J(1,1,0)  //Group 1 is var == 1
	matrix colnames score_m1= pscore_c
	matrix score_m2 = J(1,1,0)  //Group 2 is var == 0
	matrix colnames score_m2= pscore_c
	
	matrix score_se1 = J(1,1,0)  //Group 1 is var == 1
	matrix colnames score_se1= pscore_c
	matrix score_se2 = J(1,1,0)  //Group 2 is var == 0
	matrix colnames score_se2= pscore_c
	
	matrix score_lse_ratio = J(1,1,0) 
	matrix colnames score_lse_ratio= pscore_c
	
	matrix multi = J(1,1,0)  
	matrix colnames multi = "Mulivariate measure"

	
	local a = 1
	foreach var of varlist pscore_c {
		forvalues j = 1 / 2 {
			if `j' == 1 local condition "if hogar_JEC_niñoM == 1"
			if `j' == 2 local condition "if hogar_JEC_niñoM == 0"
			
			qui: sum `var' `condition'
			
			matrix score_m`j'[1,`a'] = r(mean)
			matrix score_se`j'[1,`a'] = r(sd)
			scalar score_se_`j' = r(sd)
		
			if `j' == 2 matrix score_lse_ratio[1,`a'] =  ln(score_se_1) - ln(score_se_2)
			
		}
		local ++a
		
	}
	* Normalized difference of the propensity score
	stddiff pscore_c, by(hogar_JEC_niñoM)
	matrix score_diff_norm =   -r(stddiff)'
	matrix colnames score_diff_norm = pscore_c
	 
	* Multivariate normalized difference 
	discrim lda `diffb_controles', group(hogar_JEC_niñoM)
	estat grdistances, all
	matrix G = r(gsqdist)
	scalar D2 = G[1,2]
	scalar D  = sqrt(D2)
	matrix multi[1,1] = (D)
		
	eststo diff_score: estpost ttest pscore_c  , by(hogar_JEC_niñoM)	
	
	foreach n_matrix in  score_se1 score_se2 score_m1 score_m2 score_diff_norm score_lse_ratio multi {
		eststo diff_score:estadd matrix `n_matrix'
	}
	 
	 esttab  diff_score  using "$output/table_balance_score.tex", ///
		cells("score_m1(pattern(1 1 0) fmt(3)) score_se1(pattern(1 1 0) fmt(3)) score_m2(pattern(1 1 0) fmt(3)) score_se2(pattern(1 1 0) fmt(3)) score_diff_norm(fmt(3)) score_lse_ratio(fmt(3)) ")  label   ///
	 replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)
	 
	  esttab diff_score using "$output/table_balance_score_multi.tex", ///
		cells("c c c c multi(fmt(3))") label ///
		replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)	
		
		
	* Normalized differences before and after matching
	
	qui: mean `diffb_controles'
	matrix aux = e(b)
	local colnames : colfullnames aux
	
	stddiff `diffb_controles' if niñoM == 1, by(JEC_niñoM)
	matrix diff_norm =   -r(stddiff)'
	matrix colnames diff_norm = `colnames'
	
	stddiff `diffb_controles' if sample_matched_c == 1 &  niñoM == 1, by(JEC_niñoM)
	matrix score_diff_norm =   -r(stddiff)'
	matrix colnames score_diff_norm = `colnames'


	eststo diff: estpost ttest `diffb_controles' if niñoM == 1 , by(hogar_JEC_niñoM)	
	
	foreach n_matrix in  diff_norm score_diff_norm  {
		eststo diff:estadd matrix `n_matrix'
	}
	 
	 esttab  diff  using "$output/table_balance_after_matching.tex", ///
		cells("diff_norm(fmt(3)) score_diff_norm(fmt(3)) ")  label   ///
	 replace noobs nolines  fragment compress plain nomtitles  nodepvars  nonumbers  nonotes nonumbers  starlevels(* .1 ** .05 *** .01)  collabels(none)
	
restore



*  Appendix Table A.1: Additional robustness checks
* Robustness checks: stable JEC status, reported age, similar control age, switchers, and time-use sample
preserve
	use "data_clean", clear
	
	replace edad_control_0 = edad_control_2 if edad_control_0 == . //One with age missing

	gen desde_2015_JEC_niñoM = JEC_niñoM_2015 == 1 & JEC_niñoM_2016 == 1 & niñoM == 1
	bys CHILDCODE: egen hogar_desde_2015 = max(desde_2015_JEC_niñoM)
	gen sample_desde_2015 = (hogar_desde_2015 == 1 | hogar_JEC_niñoM ==0) & sample_same_2 == 1
	gen obs_desde_2015 = sample_desde_2015 == 1 & obs_same_2 == 1
	
	* Sample with time-use data in the main sample
	gen niñoM_data_h = h_colegio_2 != . & niñoM == 1 & sample_same_2 == 1
	gen hmM_data_h = h_colegio_2 !=. & niñoM == 0 & sample_same_2 == 1

	bys CHILDCODE: egen hogar_niñoM_data_h = max(niñoM_data_h)
	bys CHILDCODE: egen hogar_hmM_data_h = max(hmM_data_h)

	gen hogar_data_h = hogar_niñoM_data_h == 1 & hogar_hmM_data_h == 1 & hogar_same_2 == 1
	gen sample_data_h = hogar_data_h == 1 & h_colegio_2 != . & sample_same_2 == 1
	gen obs_data_h = sample_data_h == 1 & h_colegio_2 != . & obs_same_2 == 1
	
	
	* Younger and older siblings with similar age at the control round
	* Identify age for the younger sibling
	gen aux_niñoM_edad = edad_control_2  if niñoM ==1 & sample_same_2 == 1
	bys CHILDCODE: egen niñoM_edad = max(aux_niñoM_edad)

	* Identify older siblings with similar age
	gen hmM_edad =  hmM_2 == 1 & abs(edad_control_2 -niñoM_edad)<=1 & sample_same_2 == 1

	* Identify households with at least one eligible older sibling
	bys CHILDCODE: egen hogar_edad = max(hmM_edad)

	* Select sample
	gen sample_edad = hogar_edad == 1 & (niñoM == 1 | hmM_edad == 1)
	gen obs_edad = sample_edad == 1 & obs_same_2 == 1
	
	
	* Switchers and non-switchers
	gen switcher = obs_same_2 == 0 & obs_niñoMpublico_2 == 1 & niñoM == 1
	gen i_switcher = niñoM*switcher
	
	forvalues i = 1 / 5{
		
		if `i' == 1 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_desde_2015 == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 2 reghdfe higher_18_0 niñoM JEC_niñoM  `controles_0' if obs_same_0 == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 3 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_edad == 1, a(CHILDCODE) vce(cl SATELITE)
		if `i' == 4 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_niñoMpublico_2 == 1, a(CHILDCODE) vce(cl SATELITE) // Including non-switcher
		if `i' == 5 reghdfe higher_18_2 niñoM JEC_niñoM  `controles' if obs_data_h == 1, a(CHILDCODE) vce(cl SATELITE)
		
		eret2 scalar hogares = e(df_a_initial) 
		eret2 scalar n_cluster = e(N_clust)
		est store r`i'
		
		estadd local blank "": r`i'
		
		matrix define ci_lower = (.,.)
		matrix define ci_upper = (.,.)
		matrix define ci_end = (1,1)
		
		boottest niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,1] = A[1,1]
		matrix ci_upper[1,1] = A[1,2]
		
		boottest JEC_niñoM = 0,  seed(101124)  boot(wild) nograph
		matrix A = r(CI)
		matrix ci_lower[1,2] = A[1,1]
		matrix ci_upper[1,2] = A[1,2]
		
		qui matrix colnames  ci_lower = "niñoM" "JEC_niñoM" 
		qui matrix colnames  ci_upper = "niñoM" "JEC_niñoM" 
		qui matrix colnames  ci_end = "niñoM" "JEC_niñoM" 
		
		qui est restore r`i' //To restore information of regression
		eststo r`i' : estadd matrix ci_lower
		eststo r`i' : estadd matrix ci_upper
		eststo r`i' : estadd matrix ci_end
		
		
	}
restore

label var niñoM "SIB (\$\beta_1\$)"
label var  JEC_niñoM  "\multirow{2}{*}{\shortstack[l]{SIB \$\times\$\\ JEC HH \\ (\$\beta_2\$)}}"

esttab r1 r2 r3 r4 r5  using "$output/table_main_appendix.tex", ///
	keep(niñoM JEC_niñoM) r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")")) ci_lower(par("["))&ci_upper&ci_end(par("]")) ) incelldelimiter(", ")  substitute (", ]1.000" "]" "\_" "_" "[1em]" "\noalign{\vskip 1mm}  "  )   ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households"  "N clusters" ) fmt(%9.0f %9.0f %9.0f ))   ///
	replace label fragment gaps compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)
	


*  Appendix Table A.7: Main estimates with all controls
forvalues i = 1 / 4{
	if `i' == 1 local sample ""
	if `i' == 2 local sample "if sample_hmM1 == 1 "
	if `i' == 3 local sample "if sample_hmM_lejano == 1 " 
	if `i' == 4 local sample "if sample_hmM_edu_lejos  == 1"
	
	reghdfe higher_18_2 niñoM JEC_niñoM  `controles' `sample', a(CHILDCODE) vce(cl SATELITE)
	
	eret2 scalar hogares = e(df_a_initial) 
	eret2 scalar n_cluster = e(N_clust)
	est store r`i'

	estadd local blank "": r`i'
	
	
}

label var niñoM "SIB (\$\beta_1\$)"
label var  JEC_niñoM  "SIB \$\times\$ JEC HH (\$\beta_2\$)"

esttab r1 r2 r3 r4 using "$output/table_main_b_controls.tex", ///
	 r2 se b(3) cells(b(fmt(%9.3f) s) se(fmt(%9.3f) par("(" ")") ) )   ///
	stats(  blank N hogares n_cluster  , label( "\phantom{a}"  "Siblings" "Households"  "N clusters" ) fmt(%9.0f %9.0f %9.0f ))   ///
	replace label fragment compress plain noobs nolines nomtitles nonumbers nonotes nonumbers  starlevels(* .1 ** .05 *** .01) collabels(none)	


*  Appendix Table A.8: Propensity-score estimation
preserve

	keep if niñoM == 1
	
	rename N_ronda1 N_2_ronda1
	rename riqueza_ronda1 i_riqueza_2_ronda1
	rename dos_padres_ronda1 dos_padres_2_ronda1
	rename madre_higher_ronda1 madre_higher_2_ronda1

	* Common variables
	foreach var in N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2 {
		gen x_`var' = diffb_`var'
		local lbl : variable label  diffb_`var'
		label variable x_`var' `"`lbl'"'
	}
	* Matching based on within-household control differences
	logit hogar_JEC_niñoM `x_diffb_controles', vce(cl SATELITE)
	est store r1
	
	
	* Common variables
	foreach var in N_2 N_hermanos_escolar_2 N_mayores_2 N_pequeños_2 N_higher_2 dos_padres_2 i_riqueza_2 madre_higher_2 madre_edad_2 {
		replace x_`var' = `var'_ronda1
	}
	
	* Matching based on R1 baseline characteristics
	logit hogar_JEC_niñoM `x_control_r1', vce(cl SATELITE)
	est store r2
	

 
esttab r1 r2 using "$output/table_logit_matching.tex", ///
  drop(_cons) ///
  cells(b(fmt(%9.3f) star) se(fmt(%9.3f) par("(" ")") ) )   ///
  order(diffb_male  male_niñoM_ronda1 male_mean_hmM_ronda1 diffb_edad_2 diffb_edad_control_2 edad_niñoM_ronda1 edad_mean_hmM_ronda1 diffb_orden_nacimiento_2 niñoM_orden_nacimiento_2 orden_nacimiento_mean_hmM x_N_2 x_N_hermanos_escolar_2 x_N_mayores_2 x_N_pequeños_2 x_N_higher_2 x_dos_padres_2 x_i_riqueza_2 p_riqueza_ronda1 madre_edu_nada_ronda1 x_madre_higher_2 x_madre_edad_2 sv_ronda1 ownhouse_ronda1 ) ///
	stats(  blank  N , label( "\phantom{a}"  "Households"  ) fmt(%9.0f %9.0f  ))   ///
	replace label fragment compress plain noobs nolines nomtitles nonumbers nonotes nonumbers eqlabels(none) starlevels(* .1 ** .05 *** .01) collabels(none)

restore
