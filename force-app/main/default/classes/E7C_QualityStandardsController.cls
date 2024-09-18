global without sharing class E7C_QualityStandardsController {
	
    @AuraEnabled
    global static List<E7C_Media__c> fetchQualityRecords(String location)
    {
        if(String.isEmpty(location))
        {
            location ='Ireland';
        }
        List<E7C_Media__c> qualityRecordsList = new List<E7C_Media__c>();
        qualityRecordsList = [SELECT Criteria__c,E7C_Description__c,E7C_Market__c,E7C_Youtube_URL__c,Id,Name,User_Type__c FROM E7C_Media__c where E7C_Market__c =: location
                              ORDER BY Criteria__c ASC];
        
        if(qualityRecordsList.size()>0)
            return qualityRecordsList;
        else 
            return null;
    }
}