public with sharing class FetchRecordType {
    
    @AuraEnabled
    public static List<RecordTypeWrapper> getRecordTypeList(String objectType){
         List<RecordTypeWrapper> recordTypeWrapperList = new List<RecordTypeWrapper>();
        if(Schema.SObjectType.RecordType.isAccessible()){
        List<RecordType> rtLIst = [SELECT Id, Name ,  sObjectType , Description  FROM RecordType WHERE sObjectType = :objectType AND IsActive = true]; 
        
       
        for(RecordType rt : rtList){
            RecordTypeWrapper tempRTWrapper = new RecordTypeWrapper(); 
            tempRTWrapper.recordTypeName = rt.Name;
            tempRTWrapper.recordTypeId = rt.Id;
            tempRTWrapper.Description = rt.Description;
            tempRTWrapper.rtObjectName = Schema.getGlobalDescribe().get(rt.sObjectType).getDescribe().getLabel();   //get the Label of the Object from API name
			tempRTWrapper.isDefault = Schema.getGlobalDescribe().get(rt.sObjectType).getDescribe().getRecordTypeInfosById().get(rt.Id).isDefaultRecordTypeMapping();   //get bool if the rt is default or not
            recordTypeWrapperList.add(tempRTWrapper);
        
            System.debug(tempRTWrapper);
        }
        }
        return recordTypeWrapperList.size() > 0 ? recordTypeWrapperList : null;
         
    }
    
    @AuraEnabled
    public static String getCreatedRecordName(String newRecordId,String objectType){
       	String query = 'SELECT Id,Name FROM '+objectType+' WHERE Id = :newRecordId';
        System.debug(query);
        sObject s = Database.query(query);
        String recordName = (String)s.get('Name');
        return recordName; 
    }
    
    
    public class RecordTypeWrapper { 
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public Id recordTypeId { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String rtObjectName {get; set; }
        @AuraEnabled public Boolean isDefault { get; set;}
    }

    
    
}