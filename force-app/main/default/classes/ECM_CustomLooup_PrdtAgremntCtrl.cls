/*
@Name: ECM_CustomLooup_PrdtAgremntCtrl
@Description: This Class is used for fetching required data for components "ECM_CustomLookup_ProductAgreement.cmp"
@History                                                            

VERSION         AUTHOR					        DATE				    DETAIL
1.0                                                                     initial development
1.2             Saurav Prasad/Doman Murmu       05/10/2023              146648 -  CM static code violation for the classes_SFDC_Global
*/
public with sharing class ECM_CustomLooup_PrdtAgremntCtrl {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String objectName, string geocode) {
        system.debug(LoggingLevel.INFO,'objectName@@' + objectName);
        String searchKey = searchKeyWord + '%';
        String geoVar = geocode + '%';
        system.debug(LoggingLevel.INFO,'searchKey@@' + searchKey);

        List < sObject > returnList = new List < sObject > ();
        List < sObject > lstOfRecords = new List < sObject > ();
        String sQuery;
        if(objectName == 'Market_Assortment_Product__c'){
            // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 
            if(geoVar !=Null){
                sQuery =  'select id, Name, Product__c, Product__r.Name,Market_Assortment__r.Code__c from ' +objectName + ' where Product__r.Name LIKE: searchKey AND Market_Assortment__r.Code__c LIKE: geoVar order by createdDate DESC limit 5';
            } 
        }
        else{
            sQuery =  'select id, Name,Geography__r.Code__c from ' +objectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
        }
        if(String.isNotBlank(sQuery)){
            lstOfRecords = Database.query(String.escapeSingleQuotes(sQuery));   //146648
        }
        if(lstOfRecords.size()>0){
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
            return returnList;
        }
        return Null;
    }
}