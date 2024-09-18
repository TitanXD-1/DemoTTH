/*
* Class Name : ECM_TaxCodeDropdownComponentController
* @description: Class used in ECM_TaxCodeDropDown component to fetch  values from pickup options object.
* @history
* AUTHOR            DATE              	DETAIL
* Pratik         	12/05/2022      	ECM-5624 : Intial Development
*/

public with sharing class ECM_TaxCodeDropdownComponentController {
       /*
* @description : This method fetches PickUpOption record based on record type
* @return : list of PickUpOption records
* @param : String String
*/
    @AuraEnabled
    public static list<Pick_Up_Options__c> getPickUpOptionType(String objectName, String recordType){
         id recordTypeId ;
         recordTypeId =getRecordTypeIdForObject(objectName, recordType);
         List<Pick_Up_Options__c> ecmPickUpOptionType = new list<Pick_Up_Options__c>();
         ecmPickUpOptionType = [SELECT id,Name FROM Pick_Up_Options__c where recordtypeid = :recordTypeId AND Status__c='Active' order by createdDate DESC];
         return ecmPickUpOptionType; 
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