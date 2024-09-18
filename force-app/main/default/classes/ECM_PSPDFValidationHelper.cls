/*
*@Name: ECM_PSPDFValidationHelper
*@Description: This is helper class for Vf page -"ECM_PS_PSFGeneration_Validation.vfp" and Aura component -"ECM_SaveAsInvoice.cmp"
*@History                                                                                                                       

VERSION			AUTHOR					DATE				DETAIL
*1.0		Tanishq Banerjee		  10/03/2023         ECM-6747 : Save As Invoice on Payment Summary Custom Screen_SFDC
*1.1		Rajarshi Lahiri			  16/03/2023		 ECM-6751 : Save As Invoice_Validation_SFDC
*/



public with sharing class ECM_PSPDFValidationHelper {

	public static Boolean pdfAccess{get; set;}
    public static List<String> allowedPsStatus{get;set;} 
    public static List<String> allowedPsTypes{get;set;}  
    public String paySumId{get; set;}
    
    
    public ECM_PSPDFValidationHelper() {
        //ECM-6750
        pdfAccess = false;
        allowedPsStatus = new List<string>();
        allowedPsTypes = new List<string>();
    }
    public ECM_PSPDFValidationHelper(ApexPages.standardController controller){
        
        pdfAccess = false;
        /*paySumStatusChk = false;
        paySumTypeChk = false;*/
                    
        //ECM-6750
        allowedPsStatus = new List<String>();
        allowedPsTypes = new List<string>();
        
        
        String paramid= System.currentPageReference().getParameters().get('id');
        //ECM-6750
        String loadPDF= System.currentPageReference().getParameters().get('loadPDF');
        paySumId = paramid;

		ECM_Payment_Summary__c paySumObj = ECM_PsPdfControllerHelper.getPsDetails(paySumId);
        
        if(loadPDF==null || loadPDF=='false'){
            //ECM-6750
            ECM_PSPDFValidationHelper.pdfValidationCtrls(paySumObj);
        }
    }
    
        /** 
    * @description	:	ECM-6750 : Validation on Payment Summary Custom Screen
    * @return		:	void
    * @param event	:	ECM_Payment_Summary__c
    **/    
    public static void pdfValidationCtrls(ECM_Payment_Summary__c psObj){
        Map<String,ECM_PS_PDF_Settings__mdt> getPsPdfSetting=new Map<String,ECM_PS_PDF_Settings__mdt>();
		for(ECM_PS_PDF_Settings__mdt pdfSett : ECM_PS_PDF_Settings__mdt.getAll().values()){
            getPsPdfSetting.put(pdfSett.ECM_CountryCode__c+'_'+pdfSett.ECM_Language_for_PDF__c,pdfSett);                
        }
        String psKey = psObj != null ?
            psObj.ECM_Contract__r.Account.Country_Code__c+'_'+(psObj.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c!=null
            ?psObj.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c:'')
            :'';
        if(!getPsPdfSetting.isEmpty() && getPsPdfSetting.containsKey(psKey)){
            pdfAccess = true;
            //ECM-6750
            allowedPsStatus = getPsPdfSetting.get(psKey).ECM_Allowed_Status__c.split(',');
            allowedPsTypes = getPsPdfSetting.get(psKey).ECM_PS_Type__c.split(',');
            System.debug(LoggingLevel.DEBUG,'allowedPsStatus:'+allowedPsStatus+'\nallowedPsTypes:'+allowedPsTypes);
        }
    }
    
    /** 
* @description	:	ECM-6750 : Validation on Payment Summary Custom Screen
* @purpose		:	wrapper class for ECM_SaveAsInvoice - aura definition bundle
**/
    public class CustomWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        public customWrapper(){
            isSuccess = false;
            message = '';
        } 
    }
    
    /** 
* @description	:	ECM-6750 : Validation on Payment Summary Custom Screen
* @return		:	Boolean
* @param event	:	String
**/
    @AuraEnabled
    public static CustomWrapper generatePsPDF(String recId){
        //ECM-6750
        //ECM_PsPdfController psPDF = new ECM_PsPdfController();
        Map<String,ECM_PS_PDF_Settings__mdt> getPsPdfSetting=new Map<String,ECM_PS_PDF_Settings__mdt>();
		for(ECM_PS_PDF_Settings__mdt pdfSett : ECM_PS_PDF_Settings__mdt.getAll().values()){
            getPsPdfSetting.put(pdfSett.ECM_CountryCode__c+'_'+pdfSett.ECM_Language_for_PDF__c,pdfSett);                
        }
        pdfAccess = false;
        ECM_Payment_Summary__c paySumObj = ECM_PsPdfControllerHelper.getPsDetails(recId);
        //validating PS PDF Generation
        pdfValidationCtrls(paySumObj);
        Integer x = !(pdfAccess)?1:!allowedPsTypes.contains(paySumObj.ECM_Type__c)
            ?2:!allowedPsStatus.contains(paySumObj.ECM_Payment_Summary_Status__c)?3:paySumObj.ECM_Invoice_Attachment__c?4:5;//ECM-6751
        CustomWrapper wrap = new CustomWrapper();
        switch on x {
            when 1 {
               wrap.message = System.Label.ECM_PS_PDF_MarketError; 
            }
            when 2{
                wrap.message = System.Label.ECM_PS_PDF_TypeError; 
            }
            when 3{
                wrap.message = System.Label.ECM_PS_PDF_StatusError; 
            }
            when 4{
                wrap.message = System.Label.ECM_InvoicePresentError;//ECM-6751 
            }
            when 5{                
                wrap.isSuccess = true; 
                wrap.message = System.Label.ECM_SaveAsInvoiceSuccess;
                savePsPdf(recId);//ECM-6747
            }
            when else {
                wrap.message = System.Label.ECM_Unknown_Error; 
            }
        }
        return wrap;
    }
    

        /** 
* @description	:	ECM-6747 : Save As Invoice on Payment Summary Custom Screen_SFDC
* @return		:	Void
* @param event	:	String
**/
    @Future(callout=true)
    public static void savePsPdf(String psId){
        
		PageReference pageRef = Page.ECM_PsPdfGeneration;        
        pageRef.getParameters().put('Id', psId);
        pageRef.getParameters().put('loadPDF', 'true');
		pageRef.setRedirect(true);

        Blob b;
        b = !test.isRunningTest()?pageRef.getContent():blob.valueOf('Unit.Test');
        
        Set<Id> cVersionIds = new Set<Id>();
        List<ContentVersion> cVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> cDocLinkList = new List<ContentDocumentLink>();
        
        Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('ECM_Payments').getRecordTypeId();
        ContentVersion cVersion = new ContentVersion();
        if(String.isNotEmpty(recordIdContentVersion)){
            cVersion.RecordTypeId = recordIdContentVersion;
        }
        cVersion.Content_Type__c = 'Invoice';
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = 'Invoice.pdf';//File name with extention
        cVersion.Title = 'Invoice';//Name of the file
        cVersion.VersionData = b;//File content
        cVersionList.add(cVersion);
        if(!cVersionList.isEmpty() && Schema.sObjectType.ContentVersion.isCreateable()){
            insert cVersionList;
        }   
        for(ContentVersion cVrsn : cVersionList){
            cVersionIds.add(cVrsn.Id);
        }
        for(ContentVersion contentDoc : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN:cVersionIds WITH SECURITY_ENFORCED]){
            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = contentDoc.ContentDocumentId;//Add ContentDocumentId
            cDocLink.LinkedEntityId =  psId;//Add attachment parentId
            cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
            cDocLinkList.add(cDocLink);
        }
        if(!cDocLinkList.isEmpty() && Schema.sObjectType.ContentDocumentLink.isCreateable()){
            insert cDocLinkList;
        }        
    }
}