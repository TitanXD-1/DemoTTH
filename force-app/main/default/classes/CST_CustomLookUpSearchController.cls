/*
*  Class Name : CST_CustomLookUpSearchController
*  @description : This is Custom Lookup Search Controller
*  @history
*  ------------------------------------------------------------------------
*   1.0         CST Team              19/08/2021        Initial Development
*	1.1			Sayan Mullick		  21/01/2022		CST-605
*/
public class CST_CustomLookUpSearchController {
    /**
* @description fetchLookUpValues
* @param String, String, String, String
*/
    @AuraEnabled
    public static List <sObject> fetchLookUpValues(String searchKeyWord, String ObjectName, String selectedType, String claimId) {
        system.debug('ObjectName-->' + ObjectName);
        String searchKey = searchKeyWord + '%';
        system.debug('searchKey'+ searchKey);
        
        List < sObject > returnList = new List < sObject > ();
        
        CST_Claim__c claim_Rec = [SELECT Id, CST_Country__c, CST_Sales_Organisation__c,CST_Sales_Organisation__r.Ignore_CST_type_for_IOs__c,
                                  CST_Sales_Organisation__r.Ignore_CST_type_for_GL__c,CST_Sales_Organisation__r.Company_Code__c FROM CST_Claim__c WHERE Id =: claimId]; 

        String comCode = claim_Rec.CST_Sales_Organisation__r.Company_Code__c;
        String salesOrg = claim_Rec.CST_Sales_Organisation__c;
        String sQuery =  'SELECT id, Name FROM ' +ObjectName + ' WHERE Name LIKE: searchKey ';
        if(ObjectName.equalsIgnoreCase('General_Ledger__c')){
            if(claim_Rec.CST_Sales_Organisation__r.Ignore_CST_type_for_GL__c == false ){
                sQuery += ' AND Type__c =: selectedType ';
            }            
        }
        
        if(ObjectName.equalsIgnoreCase('ECM_Internal_Order__c')){
            if(claim_Rec.CST_Sales_Organisation__r.Ignore_CST_type_for_IOs__c == true ){
                sQuery += ' AND SAP_Company_Code__c =: comCode ';   
            }else{
                sQuery += ' AND CST_Type__c =: selectedType ';
                sQuery += ' AND SAP_Company_Code__c =: comCode ';  
            }
            
        }
        
        if(ObjectName.equalsIgnoreCase('Pick_Up_Options__c')){
            sQuery += ' AND CST_Type__c =: selectedType AND Type__c = \'Tax Code\'';
            sQuery += ' AND Sales_Organisation__c =: salesOrg ';
            sQuery += ' AND Status__c = \'Active\'';
        }
        
        sQuery += ' ORDER BY CreatedDate DESC LIMIT 5';
        
        system.debug('-----query----'+sQuery);
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    /**
* @description fetchLookUpValues
* @param String, String, String, String, List
*/
    @AuraEnabled
    public static String fetchLookUpTableValues(String searchKeyWord, String ObjectName, String selectedType, String claimId, List<String> extrafields) {
        system.debug('ObjectName-->' + ObjectName);
        system.debug('searchKeyWord-->' + searchKeyWord);
        String searchKey = String.escapeSingleQuotes(searchKeyWord);
        
        List < sObject > returnList = new List < sObject > ();
        Set<String> filedsToSearchInSet = new Set<String>();
        filedsToSearchInSet.add('Id');
        filedsToSearchInSet.add('Name');
        if (extrafields != null && !extrafields.isEmpty()) {
            for (String additionalFieldToUseInSearch : extrafields) {
                filedsToSearchInSet.add(additionalFieldToUseInSearch);
            }
        }
        
        CST_Claim__c claim_Rec = [SELECT Id, CST_Country__c, CST_Sales_Organisation__c, CST_Sales_Organisation__r.Company_Code__c,CST_Sales_Organisation__r.Ignore_CST_type_for_IOs__c,CST_Sales_Organisation__r.Ignore_CST_type_for_GL__c  FROM CST_Claim__c WHERE Id =: claimId]; 
 
        String comCode = claim_Rec.CST_Sales_Organisation__r.Company_Code__c;
   
        String salesOrg = claim_Rec.CST_Sales_Organisation__c;
  
        String searchFieldsString = '(' + String.join(new List<String>(filedsToSearchInSet), ',');
        
        String sQuery = 'FIND \'' + searchKey +'*'+ '\' IN ALL FIELDS RETURNING '+ ObjectName+ searchFieldsString.removeEnd(',');
  
        if(ObjectName.equalsIgnoreCase('General_Ledger__c')){
            if(claim_Rec.CST_Sales_Organisation__r.Ignore_CST_type_for_GL__c == false ){ 
                sQuery += ' WHERE Type__c =: selectedType';
            }
        }
        if(ObjectName.equalsIgnoreCase('ECM_Internal_Order__c')){
            if(claim_Rec.CST_Sales_Organisation__r.Ignore_CST_type_for_IOs__c == true ){ 
                sQuery += ' WHERE SAP_Company_Code__c =: comCode ';
            }else{
                sQuery += ' WHERE CST_Type__c =: selectedType ';
                sQuery += ' AND SAP_Company_Code__c =: comCode ';  
            }
            
        }
        
        if(ObjectName.equalsIgnoreCase('Pick_Up_Options__c')){
            sQuery += ' WHERE  CST_Type__c =: selectedType AND Type__c = \'Tax Code\'';
            sQuery += ' AND Sales_Organisation__c =: salesOrg ';
            sQuery += ' AND Status__c = \'Active\'';
        }
        sQuery += ' ORDER BY CreatedDate DESC LIMIT 500 ' + ') ';
        
        system.debug('-----query----'+sQuery);
        return JSON.serializePretty(search.query(sQuery)) ;
    }
}