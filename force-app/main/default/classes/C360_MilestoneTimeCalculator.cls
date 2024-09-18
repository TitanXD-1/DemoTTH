/*
* @Name: C360_MilestoneTimeCalculator
* @description: This is class is to fetch minutes for the following milestone and used in C360 Entitlement Process
* @History                                                            

VERSION			AUTHOR					DATE					DETAIL
1.0			Saurav Prasad			04/04/2023				CUS-254 : Start SLA time on case creation_SFDC
*/ 

public without sharing class C360_MilestoneTimeCalculator implements Support.MilestoneTriggerTimeCalculator {   
/*
* @description	: This method is used to fetch minutes for triggered milestone
* @return		: Integer
* @param		: String ,String 
*/    
    public Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId){
        if(Schema.sObjectType.Case.isAccessible() || Schema.sObjectType.MilestoneType.isAccessible()){
            Case cs = [SELECT Id,caseNumber,RecordType.Name,type,D1_Subject__c, Country__c FROM Case WHERE Id=:caseId];
            MilestoneType mt = [SELECT Id,Name,Description FROM MilestoneType WHERE Id=:milestoneTypeId];
            for(Customer_360_Entitlement_Setting__mdt customMeta :
                Customer_360_Entitlement_Setting__mdt.getAll().values()){
                    if(customMeta.C360_IsActive__c &&
                       customMeta.C360_Country_Code__c.split('_').contains(cs.Country__c) && 
                       customMeta.C360_Milestone_Name__c.contains(mt.name) && 
                       customMeta.C360_Type_Sub_Type__c.contains(cs.Type + '-' + cs.D1_Subject__c)){
                           return Integer.valueOf(customMeta.C360_Milestone_Time_In_Minutes__c); 
                       }
                }
        }
        return 1;
    }

}