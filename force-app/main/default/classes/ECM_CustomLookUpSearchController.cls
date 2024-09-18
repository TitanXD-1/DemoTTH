/*
* @Name: ECM_CustomLookUpSearchController
* @description: This Class fetches required data for component "ECM_customLookupSearch"
* @History                                                            

VERSION    AUTHOR      DATE				DETAIL
1.0        Keshav	   24/03/2022		ECM-5363 : Legal Name of Operators on Contract header page_GLO
*/
public class ECM_CustomLookUpSearchController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName) {
        List < sObject > returnList = new List < sObject > ();
        String escapedStr = String.escapeSingleQuotes(searchKeyWord);
        String searchKey = '\'%' + escapedStr + '%\'';
        String loggedInUser = UserInfo.getUserId();
        String groupRecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        String sQuery =  'SELECT id, Name,ECM_Legal_Name__c FROM Account WHERE Name LIKE '+searchKey+' AND Person_Responsible__c=\'' +loggedInUser+'\' AND recordTypeId=\''+groupRecordTypeID+'\' ORDER BY createdDate DESC ';
        List < sObject > lstOfRecords = Database.query(sQuery);
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
}