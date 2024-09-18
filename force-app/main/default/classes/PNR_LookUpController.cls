public without sharing class PNR_LookUpController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String objectName) {
        system.debug('objectName-->' + objectName);
        String searchKey = searchKeyWord + '%';
        String objName='PNR_Diageo_Contact__c';        
        List < sObject > returnList = new List < sObject > ();
        Map<String,PNR_Diageo_Contact__c> diageoContactmap =new Map<String,PNR_Diageo_Contact__c>();
        // This is only for PNR_Diageo_Contact__c since it will have duplicate values for the same KAM.
        if(objName.equalsIgnoreCase(objectName)){
            List<PNR_Diageo_Contact__c> diageoContacts= new  List<PNR_Diageo_Contact__c>();
            List<PNR_Diageo_Contact__c> finaldgList= new  List<PNR_Diageo_Contact__c>();
            //retrieve accounts assigned to given service representative
            if(Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
                diageoContacts = [SELECT id,Name,PNR_Contact_Type__c,PNR_Customer__c,PNR_Name__c FROM PNR_Diageo_Contact__c WHERE PNR_Contact_Type__c='Account Manager'  AND PNR_Name__c LIKE :('%' + searchKey + '%') order by PNR_Name__c ASC LIMIT 5];              
            }
            if(!diageoContacts.isEmpty() && diageoContacts.size()>0){
                for(PNR_Diageo_Contact__c diageoContact : diageoContacts) {
                    if(!diageoContactmap.containsKey(diageoContact.PNR_Name__c)){
                        diageoContactmap.put(diageoContact.PNR_Name__c,diageoContact);
                    }
                }
            }
            return diageoContactmap.values();
            
        }
        String objNameAccount='Account'; 
        if(objNameAccount.equalsIgnoreCase(objectName)){
            // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
            String sQuery =  'select id, Name, AccountNumber from Account where (Name LIKE: searchKey OR AccountNumber LIKE: searchKey) AND Central_Billing_Block__c !=\'Blocked\' AND Central_Order_Block__c != \'Blocked\' order by createdDate DESC limit 5';
            List < sObject > lstOfRecords = Database.query(sQuery);
            
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
            return returnList;
        }
        String sQuery =  'select id, Name from ' +objectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
}