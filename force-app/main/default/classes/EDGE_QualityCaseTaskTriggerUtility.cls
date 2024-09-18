/**
* @Name: EDGE_QualityCaseTaskTriggerUtility

* @Purpose: Upsert Kpi_Achievement records whenever casetask record is created or update with user assign

* @History                                                            
                                                           
* @VERSION       AUTHOR               DATE              DETAIL
*  1.0	        Sudipta Nandi	      30/10/2021	 	ES20-10839


*/
public without sharing class EDGE_QualityCaseTaskTriggerUtility {
	/**
    * @description :upsert KPI_Achivement__c(ES20-10839)
	* @return : Void
	* @param : List
	*/
    public static void createKpiAchievementRecords(List<KPI_Achivement__c> kpiAchievementList){
        upsert kpiAchievementList;
    }
}