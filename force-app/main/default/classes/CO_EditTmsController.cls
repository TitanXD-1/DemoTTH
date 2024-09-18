/*
@Name : CO_EditTmsController
@Purpose : This is the controller class for coTmsData LWC component
@History                                                            
@VERSION    AUTHOR            DATE              DETAIL
 1.0        Venkatesh Varma   28-05-2023         Initial Development
*/
public with sharing class CO_EditTmsController {
    
    @AuraEnabled
    public static Boolean saveTmsData(String recordId, String tmsData, String accountType){
        try {
            Boolean saveDone = false;
            List<Customer_Request__c> crList = new List<Customer_Request__c>();
            Customer_Request__c cr = [SELECT Id, CO_Sold_To_TMS_Json_Data__c, CO_Ship_To_TMS_Json_Data__c FROM Customer_Request__c WHERE Id = :recordId WITH SECURITY_ENFORCED];
            setJSONContitionally(cr, tmsData, accountType);
            crList.add(cr);
            
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, crList);
            
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;
            
            List<Customer_Request__c> crListToUpdate = securityDecision.getRecords();
            if (!Schema.sObjectType.Customer_Request__c.isUpdateable()) {
                return saveDone;
            }
            
            Database.SaveResult[] srList = Database.update(crListToUpdate, dml);
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug(System.LoggingLevel.INFO,'Successfully updated CR. CR ID: ' + sr.getId());
                    saveDone = true;
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(System.LoggingLevel.INFO, err.getStatusCode() + ': ' + err.getMessage());
                        System.debug(System.LoggingLevel.INFO, 'CR fields that affected this error: ' + err.getFields());
                    }
                }
            }
            
            return saveDone;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //conditinal check for account type
    private static void setJSONContitionally(Customer_Request__c cr, String tmsData, String accountType) {
        if(cr != null && accountType=='Sold To') {
            cr.CO_Sold_To_TMS_Json_Data__c = tmsData;
        }else if(cr != null && accountType=='Ship To'){
            cr.CO_Ship_To_TMS_Json_Data__c = tmsData;
        }
    }
}