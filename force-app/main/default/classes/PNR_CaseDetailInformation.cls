/**********************************************************************
Name: PNR_CaseDetailInformation
=======================================================================
Purpose: This is the Controller class for PNR_CaseDetailInformation
=======================================================================
History                                                            
------------------------------------------------------------------------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0        Sudipta Nandi     12-07-2019        Initial Development

***********************************************************************/
public with sharing class PNR_CaseDetailInformation {
    /***************************************
* Name : fetchCaseDetailInfo
* Description : This method is used to fetch case Data 
****************************************/
    @AuraEnabled
    public static Case fetchCaseDetailInfo(String caseId) {
        //This methd is for getting cases from Case Object based on caseId
        system.debug('caseId===>:' + caseId);
        Case caseInfo;
        try{
            if(Schema.sObjectType.Case.isAccessible()){
                caseInfo = [SELECT AccountId,Account.AccountNumber,Account.Name,CaseNumber,Case_Age__c,
                            ContactEmail,Description,Id,Origin,Owner.Name,Claimed_Amount__c,Dispute_Breakdown__c,
                            Dispute_Sub_type__c,Multiple_Reference__c,Reference_Invoice__r.SAP_Invoice_Number__c,
                            Rejection_Reason__c,Priority,Status,Type,Subject,CurrencyIsoCode FROM Case WHERE Id = :caseId];
            }
        }
        catch(Exception ex){
            system.debug('===Exception in fetchCaseDetailInfo ===> : ' + ex);
            caseInfo = null;
        }
        system.debug('caseInfo===>:' + caseInfo);
        return caseInfo;
        
    }
    //This will get Customer Type
    @AuraEnabled
    public static String isActiveCust(String caseId, Boolean isSingleRef){
        String errorMsg ='';
        Set<String> accExtIdSet = new Set<String>();
        if(String.isNotBlank(caseId)){
            if(!isSingleRef){
                Case caseRec = [SELECT Id, AccountId,Account.Central_Billing_Block__c,Account.Central_Order_Block__c,Account.KUNNR__c
                                FROM Case 
                                WHERE Id =: caseId];
                if(caseRec!= null && caseRec.AccountId != null){
                    if(String.isNotBlank(caseRec.Account.Central_Billing_Block__c) && caseRec.Account.Central_Billing_Block__c.equalsIgnoreCase('Blocked')){
                        errorMsg = Label.Inactive_Customer_Error;
                        errorMsg = errorMsg.replace('XXXXX', String.valueOf(caseRec.Account.KUNNR__c)) ;
                        errorMsg = errorMsg.replace('YYYYY', 'billing') ;    
                    }else if(String.isNotBlank(caseRec.Account.Central_Order_Block__c) && caseRec.Account.Central_Order_Block__c.equalsIgnoreCase('Blocked')){
                        errorMsg = Label.Inactive_Customer_Error;
                        errorMsg = errorMsg.replace('XXXXX', String.valueOf(caseRec.Account.KUNNR__c)) ;
                        errorMsg = errorMsg.replace('YYYYY', 'Order') ;
                    }
                }
            }else{
                Case caseRecRef = [SELECT Reference_Invoice__c,Reference_Invoice__r.Account__r.Kunnr__c,
                                        Reference_Invoice__r.Payer_Number__r.Kunnr__c,Reference_Invoice__r.Bill_To_Number__c,
                                        Reference_Invoice__r.Ship_To_Number__c 
                                        FROM Case WHERE Id =: caseId];
                if(caseRecRef != null && String.isNotBlank(caseRecRef.Reference_Invoice__c)){
                    if(caseRecRef.Reference_Invoice__r.Account__r.Kunnr__c != null){
                        accExtIdSet.add(caseRecRef.Reference_Invoice__r.Account__r.Kunnr__c);
                    }
                    if(caseRecRef.Reference_Invoice__r.Payer_Number__r.Kunnr__c != null){
                        accExtIdSet.add(caseRecRef.Reference_Invoice__r.Payer_Number__r.Kunnr__c);
                    }
                    if(caseRecRef.Reference_Invoice__r.Bill_To_Number__c != null){
                        accExtIdSet.add(caseRecRef.Reference_Invoice__r.Bill_To_Number__c);
                    }
                    if(caseRecRef.Reference_Invoice__r.Ship_To_Number__c != null){
                        accExtIdSet.add(caseRecRef.Reference_Invoice__r.Ship_To_Number__c);
                    }
                    if(!accExtIdSet.isEmpty()){
                        List<Account> accList = new List<Account>();
                        if(Schema.sObjectType.Account.isAccessible()){
                        accList = [SELECT Id,Central_Billing_Block__c,Central_Order_Block__c,KUNNR__c 
                                   FROM Account
                                   WHERE KUNNR__c IN :accExtIdSet];
                        }
                        if(!accList.isEmpty()){
                            Boolean isBlocked = false;
                            for(Account accObj : accList){
                                if(String.isNotBlank(accObj.Central_Billing_Block__c) && accObj.Central_Billing_Block__c.equalsIgnoreCase('Blocked')){
                                    errorMsg = Label.Inactive_Customer_Error;
                                    errorMsg = errorMsg.replace('XXXXX', String.valueOf(accObj.KUNNR__c)) ;
                                    errorMsg = errorMsg.replace('YYYYY', 'billing') ; 
                                    break;
                                }else if(String.isNotBlank(accObj.Central_Order_Block__c) && accObj.Central_Order_Block__c.equalsIgnoreCase('Blocked')){
                                    errorMsg = Label.Inactive_Customer_Error;
                                    errorMsg = errorMsg.replace('XXXXX', String.valueOf(accObj.KUNNR__c)) ;
                                    errorMsg = errorMsg.replace('YYYYY', 'Order') ;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        System.debug('===errorMsg==='+errorMsg);
        return errorMsg;
    }
    // To Check if Correction Document exists for the case.
    @AuraEnabled
    public static Boolean isCorrectionExist(String caseId){
        system.debug('caseId===>:' + caseId);
        Boolean isCorrDocument = false;
        List<Correction_Document__c> cdInfoList=new List<Correction_Document__c>();
        if(String.isNotBlank(caseId)  && Schema.sObjectType.Correction_Document__c.isAccessible()){
            cdInfoList = [SELECT Id,Name,Case__c FROM Correction_Document__c WHERE Case__c = :caseId];
        }
        if(!cdInfoList.isEmpty()){
            isCorrDocument = true;
            system.debug('====exist===='+isCorrDocument);
        }
        else{
            isCorrDocument = false;
            system.debug('====does not exist===='+isCorrDocument);
        }
        return isCorrDocument;
    }
    //Added for PION-1649
    // @description To Check if Invoice condition met or not.
    @AuraEnabled
    public static Boolean invoiceCheck(String caseId){
        system.debug('caseId===>:' + caseId);
        Boolean invCheck = false;
        list<Case> caseRec = new list<Case>();
        if(String.isNotBlank(caseId)  && Schema.sObjectType.Case.isAccessible()){
            caseRec = [select id, Reference_Invoice__c, Reference_Invoice__r.Due_Type__c, Reference_Invoice__r.Document_Type__c from case where id =: caseId];
        }
        if(caseRec.size()>0 && caseRec[0].Reference_Invoice__c !=null){
            if(caseRec[0].Reference_Invoice__r.Document_Type__c == NULL){
                invCheck = true;
            }
            else if((String.isNotBlank(caseRec[0].Reference_Invoice__r.Due_Type__c) && caseRec[0].Reference_Invoice__r.Due_Type__c.equalsIgnoreCase('Cancelled'))  || !caseRec[0].Reference_Invoice__r.Document_Type__c.equalsIgnoreCase('YF2')
              ) {
                invCheck = true;
            }
        }
        return invCheck;
    }
    
     // To Check if Correction Document exists for the same invoiceNumber.
    @AuraEnabled
    public static String isCorrectionExistWithInvNumber(String caseId){
        system.debug('caseId===>:' + caseId);
        String corrDocumentResponse;
        Case caseRecord = new Case();
        List<Correction_Document__c> cdInfoList  = new List<Correction_Document__c>();
        if(String.isNotBlank(caseId)  && Schema.sObjectType.Case.isAccessible()){
            caseRecord = [SELECT Id,Reference_Invoice__c,Type FROM Case WHERE Id = :caseId];
        }
        if(String.isNotBlank(caseRecord.Reference_Invoice__c) && String.isNotEmpty(caseRecord.Reference_Invoice__c)
           && Schema.sObjectType.Case.isAccessible()){
            cdInfoList = [SELECT Id,Name, Case__r.Type, Reference_invoice__c,Case__r.Status FROM Correction_Document__c WHERE Reference_invoice__c = :caseRecord.Reference_Invoice__c 
                          AND Case__r.Type = :caseRecord.Type AND Case__r.Status !='Closed' AND
                          Case__r.Status !='Rejected'];
        }
        if(!cdInfoList.isEmpty()){
            corrDocumentResponse = 'true|';
            system.debug('====exist===='+corrDocumentResponse);
        }
        else{
            corrDocumentResponse = 'false|';
            system.debug('====does not exist===='+corrDocumentResponse);
        }
        corrDocumentResponse = corrDocumentResponse + caseRecord.Type;
        return corrDocumentResponse;
    }
}