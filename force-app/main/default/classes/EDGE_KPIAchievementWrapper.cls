/**
* @Name: EDGE_KPIAchivementOperations 
* @ES20-5482 - Batch KPI Calculation 
* @History                                                            
* 	@VERSION     AUTHOR              DATE              DETAIL
*	1.0        Joshraj Sen         04/01/2023        ES20-13672
*/
public class EDGE_KPIAchievementWrapper {

    public String kpiType{get;set;}
    public AggregateResult aggResult{get;set;}
    public Map<Id, Territory__c> territoryMap{get;set;}
    public Map<Id,Decimal> terrToOutletsCountMap{get;set;}
    public List<Market_Setting__c> marketSettingList{get;set;} 
    public Map<String, Id> kpiAchivementMap{get;set;} 
    public String targetFieldName{get;set;}
}