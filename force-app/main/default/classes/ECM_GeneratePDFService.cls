/**
* @description :  ECM_GeneratePDFService
* @purpose : This is serviceclass,mobile is using it to generate PDF
* @since :
* Version      Developer            		Date          User Story/Purpose
*  1.0		   Saurav Paul					22/02/2022	  ECM-5225	Digital signature Mobile_POC story for upload_SFDC

*  2.0         Subhrojit Majumdar           03/10/2022    ECM-5309  Added logic for accessing pdfs linked to addendum records

*/

@RestResource(urlMapping='/GeneratePDFService/*')
global without sharing class ECM_GeneratePDFService{

    /*@Description: this method is used for httpget serivce 
     *@Param : blank
    */
    @HttpGet
    global static ContentVersion doGet(){
        Id contractId = Restcontext.request.params.get('contractId');
        ContentVersion cont = new ContentVersion();
        if(contractId!=null){ 
            ECM_Addendum__c[] addendumList = [SELECT Id,ECM_Contract__c,ECM_Addendum_Type__c,ECM_Contract__r.Name,
                                              ECM_Contract__r.Id,ECM_Status__c,ECM_Contract__r.Status 
                                              FROM ECM_Addendum__c where ECM_Contract__r.Id =: contractId
                                              AND ECM_Contract__r.Status='Approved' 
                                              AND ECM_Status__c='Approved' 
                                              AND ECM_Addendum_Type__c = 'T&C (Terms & Conditions)' 
                                              ORDER BY Id DESC];
            if(addendumList.size() > 0){
                ECM_Addendum__c addendum = addendumList[0];
                if(addendum != null){
       				ContentDocumentLink ContentDocscheck = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:addendum.Id limit 1];
					ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId =:ContentDocscheck.ContentDocumentId  AND IsLatest = true];
                    cont.VersionData = !test.isRunningTest()?cv.VersionData:Blob.valueOf('Unit.Test');
                    cont.Description ='Link';//Mobile is using this to get/generate the PDF
                }
            }else{
                PageReference pref = page.ECM_PDF_generation;
            	pref.getParameters().put('Id',contractId); 
                pref.getParameters().put('isApproval','false');
                pref.getParameters().put('addendumId','');
            	cont.VersionData = !test.isRunningTest()?pref.getContent():Blob.valueOf('Unit.Test');  
                cont.Description ='Data';//Mobile is using this to get/generate the PDF
            }
        }  
        return cont;

    }
}