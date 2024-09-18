/*****************************************************************************************
* Class Name   : PNR_MyCustomersController
* Purpose      : Display partner function assigned to user.
* Created Date : 29th May, 2019
* Created By   : Jyothsna Nagapudi
* Modified By  : Tanmoy Bardhan
******************************************************************************************/
public with sharing class PNR_MyCustomersController {
    public string staffValue='staff';
    
    @AuraEnabled
    //Method retrieve customer assigned to the users on My Customers Page load.
    public static List<PNR_Partner_Function__c> getPartnerFunctionList() {
        Set<Id> accountSet = new Set<Id>();
        List<PNR_Partner_Function__c> pFList = new List<PNR_Partner_Function__c>();
        List<PNR_Partner_Function__c> finalPFList = new List<PNR_Partner_Function__c>();
        PNR_MyCustomersController customerController = new PNR_MyCustomersController();
        //Retrieve Diageo Contact as logged in user.
        List<PNR_Diageo_Contact__c> diageoContacts = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Diageo_Rep__c FROM PNR_Diageo_Contact__c WHERE PNR_Diageo_Rep__c = : UserInfo.getUserId()];
        for(PNR_Diageo_Contact__c diageoContact : diageoContacts) {
            accountSet.add(diageoContact.PNR_Customer__c);    
        }
        //Retrieve only 'Payer and sold to' details from partner function table based on customers assigned to user.
        if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
            pFList = [SELECT Id, PNR_Customer_No__c, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__r.AccountNumber,PNR_Customer_No__r.Name 
                      FROM PNR_Partner_Function__c where PNR_Customer_No__c IN : accountSet AND (PNR_Type__c = 'Sold-To' OR PNR_Type__c = 'Payer') AND PNR_Customer_No__r.Sort__c !='staff' AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE 
                      AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE ORDER BY PNR_Customer_No__c ASC NULLS LAST];
        }
        finalPFList = customerController.uniqueRecords(pFList);
        finalPFList = customerController.sortRecords(finalPFList);
        return finalPFList;
        
    }
    
    @AuraEnabled
    //Method filter the customer based on customer number and customer name
    public static List<PNR_Partner_Function__c> filterPartnerFunctionList(String searchBy, String searchValue) {
        List<PNR_Partner_Function__c> finalPFList = new List <PNR_Partner_Function__c>();
        List<PNR_Partner_Function__c> sortedPFList = new List <PNR_Partner_Function__c>();
        List<PNR_Partner_Function__c> uniqueFinalPFList = new List <PNR_Partner_Function__c>();
        PNR_MyCustomersController customerController = new PNR_MyCustomersController();
        
        Set<Id> accountSet = new Set<Id>();
        if(Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
            List<PNR_Diageo_Contact__c> diageoContacts = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Diageo_Rep__c FROM PNR_Diageo_Contact__c WHERE PNR_Diageo_Rep__c = : UserInfo.getUserId()];
            for(PNR_Diageo_Contact__c diageoContact : diageoContacts) {
                accountSet.add(diageoContact.PNR_Customer__c);    
            }
        }
        
        //Search By Customer Number
        //If Customer is Sold To, only 'Sold to' Customer details has to be displayed
        //If Customer is Payer, only 'Payer' Customer details has to be 
        //If Customer is Bill to/Ship to , Corresponding Sold to and Payer details has to be displayed
        if(searchBy == 'Customer Number') {
            List<PNR_Partner_Function__c> accessiblePFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> soldToPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> unSoldToPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> payerPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> unPayerPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> billShiptoPFList = new List<PNR_Partner_Function__c>();
            Set<String> uniqueSetOfSalesOrgCustomers = new Set<String>();
            if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
                accessiblePFList = [SELECT Id, PNR_Customer_No__c, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__r.AccountNumber,PNR_Customer_No__r.Name,//changed here
                                    PNR_Sold_To__r.AccountNumber //changed here
                                    FROM PNR_Partner_Function__c where PNR_Customer_No__c IN : accountSet AND PNR_Customer_No__r.Sort__c !='staff' AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE
                                    AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE];   
            }
            //filtering only Sold to partner function
            if(!accessiblePFList.isEmpty() && accessiblePFList.size()>0){
                for(PNR_Partner_Function__c pFrecord : accessiblePFList) {
                    if(pFrecord.PNR_Type__c == 'Sold-To' && pFrecord.PNR_Customer_No__r.AccountNumber == searchValue) {//changed here
                        soldToPFList.add(pFrecord);    
                    }
                    else {
                        unSoldToPFList.add(pFrecord);
                    }
                    
                }
            }
            
            //filtering only Payer partner function
            if(!unSoldToPFList.isEmpty() && unSoldToPFList.size()>0){
                for(PNR_Partner_Function__c pFrecord : unSoldToPFList) {
                    if(pFrecord.PNR_Type__c == 'Payer' && pFrecord.PNR_Customer_No__r.AccountNumber == searchValue) { //changed here
                        payerPFList.add(pFrecord);    
                    }
                    else {
                        unPayerPFList.add(pFrecord);
                    }
                    
                } 
            }
            
            //Creating Unique key for combination of sold to and salesorg to fetch Soldto and Payer for corresponding billto and shipto
            if(!unPayerPFList.isEmpty() && unPayerPFList.size()>0){
                for(PNR_Partner_Function__c pFrecord : unPayerPFList) {
                    if((pFrecord.PNR_Type__c == 'Bill-To' || pFrecord.PNR_Type__c == 'Ship-To') && pFrecord.PNR_Customer_No__r.AccountNumber == SearchValue) {//changed here
                        uniqueSetOfSalesOrgCustomers.add(pFrecord.PNR_Sold_To__r.AccountNumber + '_' + pFrecord.PNR_Sales_Org__c); //changed here
                    }
                }
                //Creating Soldto and Payer list for corresponding billto and shipto
                for(PNR_Partner_Function__c pFrecord : unPayerPFList) {
                    for(String uniquestring : uniqueSetOfSalesOrgCustomers) {
                        if(uniquestring.substringBefore('_') == pFrecord.PNR_Sold_To__r.AccountNumber && uniquestring.substringAfter('_') == pFrecord.PNR_Sales_Org__c) {//changed here
                            if(pFrecord.PNR_Type__c == 'Sold-To' || pFrecord.PNR_Type__c == 'Payer') {
                                billShiptoPFList.add(pFrecord);	 
                            }
                        }
                        
                    }
                }
            }
            
            finalPFList.addAll(soldToPFList);
            finalPFList.addAll(payerPFList);
            finalPFList.addAll(billShiptoPFList);
            uniqueFinalPFList = customerController.uniqueRecords(finalPFList);
            sortedPFList = customerController.sortRecords(uniqueFinalPFList);
            return sortedPFList;
        }
        //Search By Customer Name
        else if(searchBy == 'Customer Name') {
            String searchText = '%' + searchValue + '%';
            /*finalPFList = [SELECT Id, PNR_Customer_No__c, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__r.Name,PNR_Customer_No__r.PNR_Customer_Name__c 
FROM PNR_Partner_Function__c WHERE PNR_Sold_To__c IN : accountSet AND (PNR_Customer_No__r.PNR_Customer_Name__c LIKE :searchText) AND (PNR_Type__c = 'Sold-To' OR PNR_Type__c = 'Payer') AND PNR_Customer_No__r.PNR_Is_Staff_Customer__c != TRUE ORDER BY PNR_Customer_No__c ASC NULLS LAST];*/ 
            finalPFList = [SELECT Id, PNR_Customer_No__c, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__r.AccountNumber,PNR_Customer_No__r.Name 
                           FROM PNR_Partner_Function__c WHERE PNR_Customer_No__c IN : accountSet AND (PNR_Customer_No__r.Name LIKE :searchText) AND (PNR_Type__c = 'Sold-To' OR PNR_Type__c = 'Payer') AND PNR_Customer_No__r.Sort__c !='staff' 
                           AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE
                           AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE ORDER BY PNR_Customer_No__c ASC NULLS LAST]; 
            uniqueFinalPFList = customerController.uniqueRecords(finalPFList);
            sortedPFList = customerController.sortRecords(uniqueFinalPFList);
            return sortedPFList;
        }
        return sortedPFList;    
    }
    @AuraEnabled
    //Method to retrieve Customer Id of Customer Number
    public static String getCustomerId(String customerName) {
        if(Schema.sObjectType.Account.isAccessible()){
            Account customer = [Select Id, AccountNumber FROM Account WHERE AccountNumber = :customerName];
            if(customer != null ) {
                System.debug('customerNameId:' + ':'+customer.Id+':');
                return customer.Id;
                
            }
        }
        return null;
    }
    @AuraEnabled
    //Method to retrieve attachments associated to customer Id
    public static List<ContentVersion> getAttachmentList(String customerId) {
        system.debug('customerId:' + customerId);
        Set<Id> contentDocumentIdSet = new Set<Id>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        if(Schema.sObjectType.ContentDocumentLink.isAccessible()){
            List<ContentDocumentLink> contentDocList = [SELECT ContentDocumentId, LinkedEntityId  
                                                        FROM ContentDocumentLink 
                                                        WHERE LinkedEntityId = : customerId];
            for(ContentDocumentLink docLink : contentDocList) {
                contentDocumentIdSet.add(docLink.ContentDocumentId);
            }
        }
        
        if(Schema.sObjectType.ContentVersion.isAccessible()){
            contentVersionList =  [SELECT Id, ContentDocumentId, Title, FileType 
                                   FROM ContentVersion 
                                   WHERE ContentDocumentId IN: contentDocumentIdSet];
        }
        return contentVersionList;
    }
    public List<PNR_Partner_Function__c> uniqueRecords(List<PNR_Partner_Function__c> pfList) {
        system.debug('pfList:' + pfList);
        Set<String> uniqueSetOfSalesOrgCustomers = new Set<String>();
        List<PNR_Partner_Function__c> uniquePFList = new List<PNR_Partner_Function__c>(); 
        if(!pfList.isEmpty() && pfList.size()>0){
            
            for(PNR_Partner_Function__c pFrecord : pfList) {
                system.debug('pFrecord:'+ pFrecord);
                //uniqueSetOfSalesOrgCustomers.add(pFrecord.PNR_Customer_No__r.Name + '_' + pFrecord.PNR_Sales_Org__c + '_' + pFrecord.PNR_Type__c); 
                uniqueSetOfSalesOrgCustomers.add(pFrecord.PNR_Customer_No__r.AccountNumber + '_' + pFrecord.PNR_Sales_Org__c + '_' + pFrecord.PNR_Type__c); 
            }
        }
        for(String uniqueRecord : uniqueSetOfSalesOrgCustomers) {
            system.debug('uniqueRecord:'+ uniqueRecord);
            boolean isFound = false;
            for(PNR_Partner_Function__c pFrecord : pfList) {
                if(uniqueRecord.substringBefore('_') == pFrecord.PNR_Customer_No__r.AccountNumber && (uniqueRecord.substringAfter('_')).substringBefore('_') == pFrecord.PNR_Sales_Org__c && //changed here
                   uniqueRecord.substringAfterLast('_') == pFrecord.PNR_Type__c && !isFound) {
                       system.debug('uniquepFrecord:'+ pFrecord);
                       uniquePFList.add(pFrecord); 
                       isFound = true; 
                   }      
            }
        } 
        system.debug('uniquePFList:' + uniquePFList);
        return uniquePFList;
    }
    public List<PNR_Partner_Function__c> sortRecords(List<PNR_Partner_Function__c> pfList) {
        system.debug('pfList before sort:' + pfList);
        Integer pFListsize = pfList.size();
        PNR_Partner_Function__c tempString;
        //Sorting result as ascending order of customer number.
        for(Integer i=0; i < pFListsize; i++){
            for(Integer j=1; j < (pFListsize-i); j++){
                
                if(pfList[j-1].PNR_Customer_No__r.AccountNumber > pfList[j].PNR_Customer_No__r.AccountNumber){//changed here
                    //swap the elements!
                    tempString = pfList[j-1];
                    pfList[j-1] = pfList[j];
                    pfList[j] = tempString;
                }
            }
        } 
        system.debug('pfList after sort:' + pfList);
        return pfList;
    }
    @AuraEnabled
    public static void deleteContentDocument(Id verid) {
        ContentDocument ver =new ContentDocument ();
        try{
            if(verid != null && Schema.sObjectType.ContentDocument.isAccessible() && Schema.SObjectType.ContentDocument.isDeletable()){
                ver = [select id from ContentDocument where Id = :verid]; 
                delete ver;
            }
        }catch(Exception ex){            
            system.debug('Error in deleteContentDocument in method deleteContentDocument-->'+ex.getMessage() + ' and Line Number is ->' +ex.getLineNUmber());
        }
        
    }
    @AuraEnabled
    public static Boolean checkTL(){
        Id userProfileId = UserInfo.getProfileId();
        Id reportingProfileId = [SELECT Id,Name FROM Profile WHERE Name = 'PNR_Reporting_Team'].Id;
        if(userProfileId != reportingProfileId){
            return true;
        }else{
            return false;
        }
    }
   @AuraEnabled
    public static Boolean checkPioneerTeamLead(){
        Id userProfileId = UserInfo.getProfileId();
        Id repProfileId = [SELECT Id,Name FROM Profile WHERE Name = 'PNR_PioneerAdmin'].Id;
        if(userProfileId == repProfileId){
            return true;
        }else{
            return false;
        }
    }
    
}