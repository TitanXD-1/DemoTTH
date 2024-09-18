/**
* @description C360_ForcastVolumeInputWrapper
*
* @history
* Version  	Developer              Date               Purpose
* 1.0      	Anamika            	10/16/2023      	Initial Development
* 2.0	   	Shivam Chauhan	  	07/02/2024	  		150059
* 3.0		Sudipta Nandy		16/09/2024			156152 -- API structure changes_SFDC
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class C360_ForcastVolumeInputWrapper {
    public String forecastVolume{get;set;}
    public String rebateUniqueId{get;set;}//150059
    public String rangingVolumeKegs{get;set;} //156152
    public String numberOfBrandsStocked{get;set;} //156152
}