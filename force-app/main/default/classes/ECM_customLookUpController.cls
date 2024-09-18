/*
@Name: ECM_customLookUpController
@Description: This Class is used for fetching required data for components "ECM_Dynamic_customLookup.cmp"
@History                                                            

VERSION         AUTHOR					       DATE				DETAIL
1.0                                                             initial development
1.2             Saurav Prasad/Doman Murmu      05/10/2023       146648 -  CM static code violation for the classes_SFDC_Global
*/
public with sharing class ECM_customLookUpController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String objectName , String recordType, Boolean esCheck) {
        system.debug(LoggingLevel.INFO,'ObjectName @@' + ObjectName);
        String searchKey = searchKeyWord + '%';
        id recordtypeid ;
        recordtypeid =getRecordTypeIdForObject(ObjectName, RecordType);
        system.debug(LoggingLevel.INFO,'searchKey @@'+searchKey);

        List < sObject > returnList = new List < sObject > ();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 
        String sQuery  ;
        string statustype='Active';
        system.debug(LoggingLevel.INFO,'statustype @@'+statustype);
      
        //Changes related to ECM-5453->Start
        if(esCheck == true)
        {
           if(RecordType !='' || RecordType !=null){
             sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey and recordtypeid=:recordtypeid and Status__c=:statustype and ECM_E_S__c=true order by createdDate DESC limit 5';
           }
            
            else{
                sQuery  =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey and recordtypeid=:recordtypeid and Status__c=: statustype and ECM_E_S__c=true order by createdDate DESC limit 5';
            }
        }
        //Changes related to ECM-5453->end
        else
        {   //query changes for ECM_E_S__c field-> ECM-5453
            if(RecordType !='' || RecordType !=null){
             sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey and recordtypeid=:recordtypeid and Status__c=:statustype and ECM_E_S__c=false order by createdDate DESC limit 5';
           }
            
            else{
                sQuery  =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey and recordtypeid=:recordtypeid and Status__c=: statustype and ECM_E_S__c=false order by createdDate DESC limit 5';
            }
        }
        List < sObject > lstOfRecords = Database.query(String.escapeSingleQuotes(sQuery));      //146648
        system.debug(LoggingLevel.DEBUG,'recordsTest @@' +lstOfRecords);
       
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    public static Id getRecordTypeIdForObject(String objName, String recTypeName) {
        return ((SObject)Type.forName(objName).newInstance())
            .getSObjectType()
            .getDescribe()
            .getRecordTypeInfosByName()
            .get(recTypeName)
            .getRecordTypeId();
    }
    
    
}