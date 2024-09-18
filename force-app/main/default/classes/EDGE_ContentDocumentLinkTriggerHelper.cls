/*
KB: PLEASE MAINTAIN INDENTATION. WITHOUT HAVING PROPER INDENTATION ITS VERY DIFFICULT TO GO THROUGH CODE

* @description :  EDGE_ContentDocumentLinkTriggerHelper
* @purpose : This is the test class for ContentDocumentLink Trigger, EDGE_ContentDocumentLinkTriggerHelper and ContentDocumentLinkTriggerHandler 
* @since :
* Version      Developer            Date          User Story/Purpose
*  1.1       Monalisa Halder      18/03/2019        ES20-198
*  1.2       Preyanka Ghosh       01/04/2019        ES20-676
*  1.3       Preyanka Ghosh       24/04/2019        As per design proposed, refactor the code
*  1.4       Monalisa Halder      26/06/2019        ES20-2618
*  1.5       Monalisa Halder      22/08/2019        ES20-4029,4062
*  1.6       Sudipta Nandi        09/10/2019        Pioneer project Record Type
*  1.7       Preyanka Ghosh       11/02/2020        ES20-6620
*  1.8       Sandip Ghosh         23/03/2020        ES20-7490
*  1.9       Ajay Krishna         05/02/2021        NCP-744
* 	1.10	  Chandrakanth Suram   18/02/2021        ECM-3950
*  1.11      Anivesh Muppa	       18/03/2021	     ECM-4157,4064
*  1.12      Aparajita            10/05/2021        ES20-9665
*  1.13      Pravalika            03/06/2021        ECM-4429
*  1.14	  Anshu Prakash		   17/06/2021		 ECM-4529
*  1.15	  Monalisa Halder	   27/07/2021		 ES20-9662
*  1.16      Anivesh Muppa		   16/08/2021		 ECM-4686- add error message when contract is signed off
*  2.0       Kapil Baliyan        23/10/2021        NCP-5031   
*  2.1       Keshav               09/11/2021	     ECM-4938 - Update Invoice & Evidence Attachment fields on PaymentSummary
*  2.2       Saurav Prasad        09/11/2021        ECM-4924 - Placeholder to upload the T&C pdf in Market Setting_Customer Approval Mail  
*  2.3       Saurav Paul          31/12/2021        ECM-4992 - Code merge and DML inside for loop remove

*  2.4 	  Md Ahmed			   12/01/2022		 ECM-4959 - Checking for Contract RecordType is having more than one Approval Mail Attachment ContentType.
*  2.5		  Wribhu Bose		   26/08/2022		 ECM-5901 - added method onAddingSignedPDF
*  2.6		  Wribhu Bose		   09/09/2022		 ECM-5900 - added methods onAddingContractAttachment, sendMailForAttachments, createTemplateMap, fetchEmailTemplate, createMailingLists, createMail, removed method onAddingSignedPDF
*  2.7		  Wribhu Bose		   23/09/2022		 ECM-6107 - modified method sendMailForAttachments so that Signed Contract mails get saved as activity
*  2.7		  Suvendu Roy 		   28/09/2022		 ECM-6149 - modified method onAddingContractAttachment so that Signed Contract Only create and send mails if it is a Signed Contract PDF & ECM_Digitally_Signed__c has 'OTP Sent' or 'OTP Used' value
*  2.8		  Vinay Tummala 	   08/11/2022		 ECM-6291 - Logic to validate the Customer Signed date_SFDC_Compliance for signed Contract PDF upload
*  2.9       Pratik Kumar         29/12/2022        ECM-6466 - Issue with attachment upload for non-English users. Replacing RecordType name with DeveloperName
*  3.0       Pratik Somani		   10/03/2022        ECM-6787 - Logic to uncheck Invoice and Evidence attachment_Payment Summary Attachment_SFDC
*  3.1		  Saurav Prasad		   31/08/2023		 145098   - Optimize the ContentDocumentTrigger_SFDC_Technical Debt
* 	3.2		  Saurav Prasad		   16/11/2023		 148321	  - D1 _Guest user not able to upload file
*  3.3       Shivam Chauhan       24/01/2023        148873  - CRG: Prevent CRG Contract to move from Approved to Inactive/Active_Tech_SFDC
*  3.4		 Shivam Chauhan		  19/03/2024		151377	- CRG Enhancements_No validation for number of attachments in "Approval mail attachments"_ SFDC 
*  3.5       Saikiran			  09/05/2024        153713  - Added null check for D1 guest user profile
*/
public with sharing class EDGE_ContentDocumentLinkTriggerHelper {
    
    private static sObject existingRecord;
    private static Map<String, File_Setting__mdt> mapObjectFileSetting = new Map<String, File_Setting__mdt>();
    private static String notificationObjApiNameStr = 'Notification__c';
    private static String imageStr = 'Image';
    private static String documentStr = 'Document';
    private static String contentStr = 'Content';
    private static boolean displayErrorMessage=false;
    // NCP-744 START
    private static String d1settingsObjApiNameStr = 'D1_Setting__c';
    private static String digitalAssetBrandNameStr = 'Digital Asset Brand';
    private static String digitalAssetOccasionNameStr = 'Digital Asset Occasion';
    private static String digitalAssetAllAssetTypeNameStr = 'All Asset Types';
    private static String brandNameStr = 'Brand';
    private static String occasionNameStr = 'Occasion';
    private static String allAssetTypeStr = 'Asset_Type';
    // NCP-744 END
    
    // 145098
    private static final String CASE_RECORD_TYPE_TECHNICAL_ISSUE = 'Technical Issue';
    private static final String INTEGRATION_USER_PROFILE_NAME = 'Integration User Profile';
    private static final String FEED_VISIBILITY = 'AllUsers';
    private static final String FEED_ATTACHMENT_TYPE = 'CONTENT';
    private static final String PAYMENT_SUMMARY_RECORD_TYPE = 'ECM_Payments';
    private static final String LEGAL_USER_PROFILE_ID = [SELECT Id FROM Profile WHERE Name =: Label.ECM_Legal_User_Profile].Id;
    private static final List<Market_Setting__c> MARKET_SETTING_LIST = new List<Market_Setting__c>([SELECT Id, Name__c,Geography__r.Code__c,ECM_Mandatory_field_for_Contract__c,ECM_Contract_Creation_Page__c FROM Market_Setting__c where ECM_Contract_Management_Market__c=true]);
    //148321
    private static final String CONTRACT_OBJ = 'Contract';
    private static final List<ContentWorkspace> CONTRACT_WORKSPACE = new List<ContentWorkspace>([SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE (DeveloperName =:CONTRACT_OBJ OR Name =:CONTRACT_OBJ)]);
    
    
    /*
@description : getFileSetting - This methods used to get details for each object
@return : void
@param : none
*/
    public static void getFileSetting(){
        //145098
        for(File_Setting__mdt objFile : File_Setting__mdt.getAll().values()){
            //mapObjectFileSetting.put(objFile.MasterLabel, objFile);
            mapObjectFileSetting.put(objFile.Object_Api_Name__c, objFile);
            
        }        
    }
    
    /*
@description : checkRecordTypePerObject - This methods used to check that there should be one pdf per promotion
@return : void
@param : List<ContentDocumentLink>
*/
    public static void checkRecordTypePerObject(List<ContentDocumentLink> newItems){
        Set<Id> setConDocLinkId = new Set<Id>();
        Map<Id, ContentDocument> mapContentDoc;
        List<ContentDocumentLink> lstConDocLink = new List<ContentDocumentLink>();
        
        //Query File_Setting__mdt if already not present
        if(!(mapObjectFileSetting != null && mapObjectFileSetting.size()>0)){
            getFileSetting();            
        } 
        
        // New documents to be inserted in the promotion records
        for(ContentDocumentLink  conDocLnkObj : newItems){
            if(conDocLnkObj.LinkedEntityId != null){
                String sobjectName = (conDocLnkObj.LinkedEntityId).getSObjectType().getDescribe().getName();
                if(mapObjectFileSetting.containsKey(sobjectName) && conDocLnkObj.LinkedEntityId.getSObjectType() == Schema.getGlobalDescribe().get(mapObjectFileSetting.get(sobjectName).Object_Api_Name__c)){
                    setConDocLinkId.add(conDocLnkObj.ContentDocumentId);
                    lstConDocLink.add(conDocLnkObj); 
                }
            }            
        }
        
        if(setConDocLinkId != null && setConDocLinkId.size()>0){
            mapContentDoc = new Map<Id, ContentDocument>([SELECT Id, LatestPublishedVersionId, LatestPublishedVersion.RecordTypeId, LatestPublishedVersion.RecordType.Name, LatestPublishedVersion.RecordType.DeveloperName, Title FROM ContentDocument WHERE Id IN :setConDocLinkId]);            
        }
        
        for(ContentDocumentLink  conDocLnkObj : lstConDocLink){
            if(mapContentDoc != null && mapContentDoc.containsKey(conDocLnkObj.ContentDocumentId) && conDocLnkObj.LinkedEntityId != null){
                ContentDocument objContentDoc = mapContentDoc.get(conDocLnkObj.ContentDocumentId);
                String sobjectName = (conDocLnkObj.LinkedEntityId).getSObjectType().getDescribe().getName();
                
                //Changes for Pioneer Project Record Type.PION-955 //* ECM-change for Contract management record types =='Contracts' AND 'Payments'*//
                if(!(objContentDoc.LatestPublishedVersion.RecordType.DeveloperName == null || objContentDoc.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVDirectCustomerRecType || objContentDoc.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVContractsRecType || objContentDoc.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVPaymentsRecType)){
                    if(mapObjectFileSetting.containsKey(sobjectName) && objContentDoc.LatestPublishedVersion.RecordType.DeveloperName != mapObjectFileSetting.get(sobjectName).DeveloperName){
                        if(!(conDocLnkObj.LinkedEntityId.getSObjectType() == Account.sObjectType && objContentDoc.LatestPublishedVersion.RecordType.DeveloperName == Label.Notes_Library)){
                            conDocLnkObj.addError(Label.Files_Record_Type_Message); 
                        }                      
                    } 
                }
            } 
        }
    }
    
    /*
@description : updateContentVersionId - This methods used to update Content Document Id and Content Version Id
@return : void
@param : Map<Id,SObject>
*/
    public static void updateContentVersionId(Map<Id,SObject> newItems) {
        Map<Id,ContentDocumentLink> mapContentDoc = new Map<Id,ContentDocumentLink>();
        Set<Id> setContentDoc = new Set<Id>();
        
        String contentWorkSpaceName;
        Map<Id,List<Id>> mapLinkedEntityId = new Map<Id,List<Id>>();
        Id linkedEntityId;
        //contract managemnet
        Map<Id,ContentDocumentLink>  contractContentDocument = new Map<Id,ContentDocumentLink>();
        Map<Id, Contract> mapUpdateContract = new Map<Id, Contract>();
        //Map<String,ECM_Contract_Type__c> contractAgreementTypes = new Map<String,ECM_Contract_Type__c>();
        Boolean errormessage = false;
        List<ContentDocumentLink> cdlUpertList = new List<ContentDocumentLink>();
        
        try{
            if(newItems != null && newItems.size()>0){
                setContentDoc = newItems.keySet();                              
                //To get the Record Type Name need to do the query
                for(ContentDocumentLink objConDocLink :[Select Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId, 
                                                        ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.RecordTypeId, 
                                                        ContentDocument.LatestPublishedVersion.RecordType.Name, ContentDocument.LatestPublishedVersion.RecordType.DeveloperName, ContentDocument.LatestPublishedVersion.CreatedDate,ContentDocument.LatestPublishedVersion.Content_Type__c
                                                        FROM ContentDocumentLink 
                                                        WHERE Id IN :setContentDoc WITH SECURITY_ENFORCED])
                {
                    //Changes for Pioneer Project Recordtype.PION-955
                    if(objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVDirectCustomerRecType){
                        if((objConDocLink.LinkedEntityId).getSObjectType().getDescribe().getName() != 'Library'){
                            mapContentDoc.put(objConDocLink.ContentDocumentId, objConDocLink); 
                            contentWorkSpaceName = objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName;  
                            linkedEntityId = objConDocLink.LinkedEntityId;
                        }
                    } else{
                        if(objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName != System.Label.ECM_CVOthersRecType && objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c != 'Other')
                        {
                            String sobjectName = (objConDocLink.LinkedEntityId).getSObjectType().getDescribe().getName();
                            if(mapObjectFileSetting.containsKey(sobjectName) && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == mapObjectFileSetting.get(sobjectName).DeveloperName && 
                               ((objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVAccountRecType && (objConDocLink.ContentDocument.Title).contains('OutletImage_')) ||
                                ((objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVProductRecType && (objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c).contains('Product Image'))) ||
                                (objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName != System.Label.ECM_CVAccountRecType && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName != System.Label.ECM_CVProductRecType)))
                            {
                                mapContentDoc.put(objConDocLink.ContentDocumentId, objConDocLink); 
                                contentWorkSpaceName = objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName; 
                                if(mapLinkedEntityId.containsKey(objConDocLink.ContentDocumentId)){
                                    mapLinkedEntityId.get(objConDocLink.ContentDocumentId).add(objConDocLink.LinkedEntityId);
                                } else {
                                    mapLinkedEntityId.put(objConDocLink.ContentDocumentId, new List<Id> {objConDocLink.LinkedEntityId});
                                } 
                            }
                        }
                    }
                    
                    //start of Changes for contract management Project ECM-3
                    if(objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVContractsRecType){
                        contractContentDocument.put(objConDocLink.LinkedEntityId,objConDocLink);    
                        List<ContentWorkspaceDoc> lstContentWorkDoc;
                        lstContentWorkDoc = new List<ContentWorkspaceDoc>();
                        String contractobj = objConDocLink.LinkedEntityId.getSObjectType().getDescribe().getName();
                        //148321
                        if(contractobj == 'Contract' && !CONTRACT_WORKSPACE.isEmpty() && CONTRACT_WORKSPACE[0].Id!=Null){
                            //ContentWorkspace ws = contractWorkspace;
                            //145098
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.ContentDocumentId = objConDocLink.ContentDocumentId;
                            cdl.LinkedEntityId = CONTRACT_WORKSPACE[0].Id; //148321
                            //Database.upsert(cdl); //CM Team has to fix this DML which is inside For Loop
                            cdlUpertList.add(cdl);
                        }   
                    }
                }
                //Added part of ECM-4992
                if(!cdlUpertList.isEmpty()){
                    Database.upsert(cdlUpertList);
                }
                if(contractContentDocument.size()>0){
                    Map<String,Market_Setting__c> mapMarketSetting = new Map<String,Market_Setting__c>();
                    //changes related to ECM-4686
                    //145098
                    for(Market_Setting__c marketObj: MARKET_SETTING_LIST){
                        mapMarketSetting.put(marketObj.Geography__r.Code__c,marketObj);
                    }
                    //Changes related to ECM-4452
                    Map<Id,ECM_Contract_Type__c> mapAgreementType =new Map<Id,ECM_Contract_Type__c>([SELECT id, Geography__r.Code__c, Name, ECM_Automatic_approval_amount_threshold__c,
                                                                                                     ECM_Re_Investment_Rate_Approve_Threshold__c,ECM_Mandatory_Fields_Check__c
                                                                                                     FROM ECM_Contract_Type__c where Id IN(Select ECM_Agreement_Type__c From Contract Where Id IN:contractContentDocument.Keyset())]);
                    
                    string crgRecordType = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();//148873
                    
                    for(Contract contractRec: [Select Id, Name, StartDate, Contract_End_Date__c, Status, ECM_Agreement_Type__c,OwnerId,Owner.Email,
                                               Account.Country_Code__c,Account.VAT_Number__c,Account.SAP_Sold_to__c,Account.New_VAT__c,
                                               Account.ECM_Legal_Name__c,Account.SAP_Ship_to__c,Account.Email_for_contracts_payments__c,Account.Sales_Org__c
                                               From Contract Where Id IN:contractContentDocument.Keyset() AND Status ='Approved' and RecordTypeId != :crgRecordType with SECURITY_ENFORCED])
                    {
                        // changes as part of ECM-4157 bug
                        if(contractContentDocument.containskey(contractRec.Id) && contractContentDocument.get(contractRec.Id).ContentDocument.LatestPublishedVersion.Content_Type__c == 'Signed Contract'){
                            //changes related to ECM-4686
                            if(!String.isBlank(mapAgreementType.get(contractRec.ECM_Agreement_Type__c).ECM_Mandatory_Fields_Check__c) && mapAgreementType.get(contractRec.ECM_Agreement_Type__c).ECM_Mandatory_Fields_Check__c.equals('After Customer Signed') && mapMarketSetting.containskey(contractRec.Account.Country_Code__c)){            
                                string marketValues = mapMarketSetting.get(contractRec.Account.Country_Code__c).ECM_Mandatory_field_for_Contract__c;
                                //start to ECM-4573
                                if(!String.isBlank(marketValues)){
                                    // errormessage='Hi <br/><br/>';
                                    if (marketValues.contains('SAP Sold to')){ 
                                        if(string.isBlank(contractRec.Account.SAP_Sold_to__c)){
                                            errormessage=true;// System.Label.ECM_SAP_Number_Validation.replace(':', '<br/>');//'customer SAP number is missing from customer record, cannot submit for approval';
                                        }
                                    }
                                    if (marketValues.contains('VAT number')){
                                        if(String.isBlank(contractRec.Account.New_VAT__c)){
                                            errormessage =true;// System.Label.ECM_VAT_number.replace(':', '<br/>');//':Tax registration number is missing from customer record, cannot submit for approval';
                                        }
                                    }
                                    if (marketValues.contains('Legal Name')){ 
                                        if(String.isBlank(contractRec.Account.ECM_Legal_Name__c)){
                                            errormessage =true;// System.Label.ECM_Legal_Name_Validation.replace(':', '<br/>');            
                                        }
                                    }
                                    if(marketValues.contains('SAP Ship to')){
                                        if(String.isBlank(contractRec.Account.SAP_Ship_to__c)){
                                            errormessage =true;// System.Label.ECM_SAP_Ship_To.replace(':', '<br/>');                 
                                        }
                                    }
                                    if(marketValues.contains('Customer email for Contract')){
                                        if(String.isBlank(contractRec.Account.Email_for_contracts_payments__c)){
                                            errormessage =true;// System.Label.ECM_Email_for_contracts_payments_Validation.replace(':', '<br/>') ;                 
                                        }
                                    }
                                    if(marketValues.contains('Sales org')){ 
                                        if(String.isBlank(contractRec.Account.Sales_Org__c)){
                                            errormessage =true;// System.Label.ECM_Sales_Org.replace(':', '<br/>') ;                 
                                        }
                                    }
                                    if(marketValues.contains('Tax Identification number')){ 
                                        if(String.isBlank(contractRec.Account.VAT_Number__c)){
                                            errormessage =true;//System.Label.ECM_Tax_Registration_Number_Validation.replace(':', '<br/>');                 
                                        }
                                    }
                                }
                                //end of ECM-4686
                            }
                            if(!errormessage){
                                if(contractRec.StartDate > contractContentDocument.get(contractRec.Id).ContentDocument.LatestPublishedVersion.CreatedDate.date()){
                                    contractRec.status = 'InActive';
                                }else if(contractRec.StartDate <= contractContentDocument.get(contractRec.Id).ContentDocument.LatestPublishedVersion.CreatedDate.date()){
                                    contractRec.status = 'Active';                             
                                }      
                            }else{//changes related to ECM-4686
                                newItems.get(contractContentDocument.get(contractRec.Id).Id).addError(System.Label.ECM_MandatoryFieldsMissing); 
                            }
                            mapUpdateContract.put(contractRec.Id,contractRec); 
                        }
                    }
                }
                
                If(mapUpdateContract!=Null && mapUpdateContract.size()>0 && Schema.sObjectType.Contract.isAccessible() && Schema.sObjectType.Contract.isUpdateable())
                {
                    Update mapUpdateContract.values();
                }  
                //End of Changes for contract management Project ECM-3
                if((String.isNotBlank(linkedEntityId) || (mapLinkedEntityId != null && mapLinkedEntityId.size()>0)) && String.isNotBlank(contentWorkSpaceName)){
                    //Pioneer project Record type checking.PION-955
                    if(contentWorkSpaceName == System.Label.ECM_CVDirectCustomerRecType) {
                        upsertDirectCustomerData(mapContentDoc, contentWorkSpaceName, linkedEntityId, true,false);                              
                    } else {
                        upsertSobjectData(mapContentDoc, contentWorkSpaceName, mapLinkedEntityId, true,false);                           
                    }                    
                }
            }
        } catch(Exception excption){
            System.debug(LoggingLevel.Debug,'Exception updateContentVersionId in CDLT::::'+excption.getLineNumber()+'::'+excption.getMessage()+excption.getCause());            
        }
    }
    /*
@description : updatePaymentFields - This methods used to update Invoice and Evidence checkbox in Payment Summary - ECM-4429
@return : void
@param : Map<Id,SObject>
*/
    public static void updatePaymentFields(Map<Id,SObject> newItems) {
        // Map<Id,ContentDocumentLink> mapContentDoc;
        // mapContentDoc = new Map<Id,ContentDocumentLink>();
        // Set<Id> setContentDoc;
        // setContentDoc = new Set<Id>();
        
        //String contentWorkSpaceName;
        // Map<Id,List<Id>> mapLinkedEntityId;
        // mapLinkedEntityId = new Map<Id,List<Id>>();
        Id linkedEntityId;
        map<id,ContentDocumentLink>  paymentContentDocument= new map<id,ContentDocumentLink>();
        Map<Id, ECM_Payment_Summary__c> mapUpdatePayment = new Map<Id, ECM_Payment_Summary__c>();       
        
        try{
            if(newItems != null && newItems.size()>0){
                //To get the Record Type Name need to do the query
                for(ContentDocumentLink objConDocLink :[Select Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId, 
                                                        ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.RecordTypeId, 
                                                        ContentDocument.LatestPublishedVersion.RecordType.Name, ContentDocument.LatestPublishedVersion.RecordType.DeveloperName, ContentDocument.LatestPublishedVersion.CreatedDate,ContentDocument.LatestPublishedVersion.Content_Type__c
                                                        FROM ContentDocumentLink 
                                                        WHERE Id IN :newItems.keySet() with SECURITY_ENFORCED]
                   ){
                       System.debug(LoggingLevel.Debug,objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName+'@@@@'+System.Label.ECM_CVPaymentsRecType);
                       if(objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVPaymentsRecType ){
                           paymentContentDocument.put(objConDocLink.LinkedEntityId,objConDocLink);
                       }
                   }
                if(paymentContentDocument.size()>0){
                    for(ECM_Payment_Summary__c payRec: [Select Id From ECM_Payment_Summary__c Where Id IN:paymentContentDocument.Keyset() with SECURITY_ENFORCED]){
                        if(paymentContentDocument.containskey(payRec.Id) && (paymentContentDocument.get(payRec.Id).ContentDocument.LatestPublishedVersion.Content_Type__c == 'Invoice' || 
                                                                             paymentContentDocument.get(payRec.Id).ContentDocument.LatestPublishedVersion.Content_Type__c == 'Customer Emails') && 
                           paymentContentDocument.get(payRec.Id).ContentDocument.FileExtension != 'eml'){
                               payRec.ECM_Invoice_Attachment__c = true;
                           }else if(paymentContentDocument.containskey(payRec.Id) &&  paymentContentDocument.get(payRec.Id).ContentDocument.LatestPublishedVersion.Content_Type__c == 'Evidence'){
                               payRec.ECM_Evidence_Attachment__c = true;                            
                           }                            
                        mapUpdatePayment.put(payRec.Id,payRec); 
                    }
                    
                }
                if(mapUpdatePayment!=Null && mapUpdatePayment.size()>0){
                    //ECM-4938 : Added method to update Invoice & Evidence Attachment fields on PaymentSummary
                    ECM_PaymentSummaryController.updatePsFields(mapUpdatePayment);
                    //Update mapUpdatePayment.values();
                }
            }
        }
        catch(Exception excption){
            System.debug(LoggingLevel.Debug,'Exception updatePaymentContentType ::::'+excption.getLineNumber()+'::'+excption.getMessage()+excption.getCause());            
        }
    }
    
    /*
@description : changeVisiblityPublic - This is used so that we should be able to access the contracts of my account so that we can see the contract in Diageo One - PDF version - ECM-4529
@return : void
@param : List<ContentDocumentLink>
*/
    public static void changeVisiblityPublic(List<ContentDocumentLink> newConDocumentLinkList){    
        try{
            for(ContentDocumentLink contDcLObj : newConDocumentLinkList){            
                //145098
                if(contDcLObj.LinkedEntityId.getSObjectType() == Contract.sObjectType){    
                    contDcLObj.ShareType = 'V';                
                    contDcLObj.Visibility = 'AllUsers';
                }
            }
        }
        catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Exception updateContentDocLink ::::'+ex.getLineNumber()+'::'+ex.getMessage()+ex.getCause());  
        } 
    }
    
    /*
@description : upsertSobjectData - This is used to create the list and upsert sobject data
@return : void
@param : Map<Id,ContentDocumentLink>
*/
    public static void upsertSobjectData(Map<Id,ContentDocumentLink> mapContentDoc, String contentWorkSpaceName, Map<Id,List<Id>> mapLinkedEntityId, Boolean insertWorkspace, Boolean isDelete){
        List<ContentWorkspaceDoc> lstContentWorkDoc = new List<ContentWorkspaceDoc>();
        Map<Id,sObject> mapContent = new Map<Id,sObject>();
        ContentWorkspace contentWorkSpc = new ContentWorkspace();
        try{
            if(mapContentDoc != null && mapContentDoc.size()>0 && Schema.sObjectType.ContentWorkspace.isAccessible() 
               && Schema.sObjectType.ContentWorkspace.isCreateable() && Schema.sObjectType.ContentWorkspace.isUpdateable()
               && Schema.sObjectType.File_Setting__mdt.isAccessible())
            {
                contentWorkSpc = [SELECT Id FROM ContentWorkspace where name =:contentWorkSpaceName OR DeveloperName=:contentWorkSpaceName  LIMIT 1];
                //Used 2 queries on metadata since OR is not supported in metadata query
                List<File_Setting__mdt> fileSettingDetails = new List<File_Setting__mdt>();//145098
                for(File_Setting__mdt fileSetting : File_Setting__mdt.getAll().values()){
                    if(fileSetting.MasterLabel == contentWorkSpaceName || fileSetting.DeveloperName == contentWorkSpaceName){
                        fileSettingDetails.add(fileSetting);
                        break;
                    }
                }//END of 145098
                if(fileSettingDetails[0] != null && fileSettingDetails[0].Multiple_Image_Allowed__c != null && fileSettingDetails[0].Multiple_Image_Allowed__c){
                    List<String> lstTempLinkedEntityId = new List<String>();
                    Id tmpEntityId;
                    for(Id contentDocId : mapLinkedEntityId.keySet()){
                        //lstTempLinkedEntityId.addAll(mapLinkedEntityId.get(contentDocId));
                        for(Id linkedId : mapLinkedEntityId.get(contentDocId)){
                            tmpEntityId = linkedId;
                            lstTempLinkedEntityId.add('\''+linkedId+'\'');
                        }
                    }
                    
                    Schema.SObjectType sobjectType = tmpEntityId.getSObjectType();
                    String sobjectName = sobjectType.getDescribe().getName();
                    List<String> splitString = (fileSettingDetails[0].File_Field_Details__c).split(';');
                    String strQuery = 'SELECT Id';
                    for(String fieldDetails : splitString){
                        strQuery += ', '+String.escapeSingleQuotes(fieldDetails);
                    }
                    strQuery += ' FROM '+ sobjectName + ' WHERE Id IN '+ lstTempLinkedEntityId + ' LIMIT 1';
                    existingRecord = Database.query(strQuery);
                }
                
                for(Id contentDocId : mapContentDoc.keySet()){                     
                    if(insertWorkspace && contentWorkSpc.Id !=null){
                        //Create ContentWorkSpaceDoc to create the Link between the Library and Content Document
                        ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();
                        newWorkspaceDoc.ContentWorkspaceId = contentWorkSpc.Id; 
                        newWorkspaceDoc.ContentDocumentId = contentDocId;
                        lstContentWorkDoc.add(newWorkspaceDoc); 
                        
                    }
                    
                    //Create SObject Map to be updated the object with Content Document Id and Version Id
                    ContentDocumentLink objConDocLink = mapContentDoc.get(contentDocId);
                    List<Id> lstLinkedEntityId;
                    if(mapLinkedEntityId.containsKey(contentDocId)){
                        lstLinkedEntityId = mapLinkedEntityId.get(contentDocId);
                    }
                    if(lstLinkedEntityId != null && lstLinkedEntityId.size()>0){
                        for(Id linkedEntity : lstLinkedEntityId){
                            mapContent.put(linkedEntity, createSObject(linkedEntity, objConDocLink, fileSettingDetails[0], isDelete)); 
                        }                          
                    } else {
                        mapContent.put(objConDocLink.LinkedEntityId, createSObject(objConDocLink.LinkedEntityId, objConDocLink, fileSettingDetails[0], isDelete));                          
                    } 
                }
                
                if(mapContent != null && mapContent.size()>0){                        
                    Database.update(mapContent.values());
                    if(insertWorkspace && !lstContentWorkDoc.isEmpty()){
                        Database.upsert(lstContentWorkDoc);
                    }                    
                }
            }
        } catch(Exception excption){
            System.debug(LoggingLevel.Debug,'Exception upsertSobjectData in SDLT::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
        }
    }
    
    /*
@description : createSobject - This is used to create the single sobject data
@return : sObject
@param : Id, ContentDocumentLink, File_Setting__mdt, Boolean 
*/
    public static sObject createSObject(Id linkedEntityId, ContentDocumentLink objConDocLink, File_Setting__mdt fileSettingDetails, Boolean isDelete){
        sObject sObj;
        String contentDocumentId;
        String contentVersionId;
        try{
            if(String.isNotBlank(linkedEntityId) && objConDocLink!=null && fileSettingDetails != null){
                //To get the Object Name from Linked Entity Id
                Schema.SObjectType sobjectType = linkedEntityId.getSObjectType();
                String sobjectName = sobjectType.getDescribe().getName();
                sObj = Schema.getGlobalDescribe().get(sobjectName).newSObject();
                
                //Split Field to save the ID in each field from Metadata
                String fieldName = fileSettingDetails.File_Field_Details__c;
                List<String> splitString = fieldName.split(';');
                
                //Put data in sobject field
                sObj.put('Id' , linkedEntityId);
                if(sobjectName == 'Opportunity_Template__c'){
                    String acceptedExtension = Label.Accepted_Image_Extensions_In_OppTemp;
                    List<String> acceptedExtensions = acceptedExtension.split(';');
                    //Only for Image type file need to update the Id in Thumbnail image
                    if(acceptedExtensions.contains(objConDocLink.ContentDocument.FileExtension)){
                        for(String fieldDetails : splitString){
                            if(fieldDetails.contains('Thumbnail')){
                                if(isDelete){
                                    sObj.put(fieldDetails , '');
                                } else {
                                    if(fieldDetails.contains('Document')){                                    
                                        sObj.put(fieldDetails , objConDocLink.ContentDocumentId);
                                    } else {
                                        sObj.put(fieldDetails , objConDocLink.ContentDocument.LatestPublishedVersionId);
                                    }
                                }
                            } 
                        }
                    } else {
                        for(String fieldDetails : splitString){
                            if(fieldDetails.contains('Presenter')){
                                if(isDelete){
                                    sObj.put(fieldDetails , '');
                                } else {
                                    if(fieldDetails.contains('Document')){
                                        sObj.put(fieldDetails , objConDocLink.ContentDocumentId);
                                    } else {
                                        sObj.put(fieldDetails , objConDocLink.ContentDocument.LatestPublishedVersionId);
                                    }
                                }
                            } 
                        }                        
                    }
                }else if(sobjectName == notificationObjApiNameStr){
                    String acceptedExtension = Label.EDGE_Accepted_Image_Extensions_In_Notification;
                    List<String> acceptedImageExtensions = acceptedExtension.split(';');
                    //Handle the Image type file need to update the Id in Thumbnail image
                    if(acceptedImageExtensions.contains(objConDocLink.ContentDocument.FileExtension)){
                        
                        for(String fieldDetails : splitString){
                            if(fieldDetails.contains(imageStr)){
                                updateContentVersionDetails(sObj, fieldDetails, objConDocLink, isDelete);
                            }
                        }
                    } else {
                        for(String fieldDetails : splitString){
                            if(fieldDetails.contains(contentStr)){
                                updateContentVersionDetails(sObj, fieldDetails, objConDocLink, isDelete);                                
                            }
                        }
                    }
                }else if(sobjectName == d1settingsObjApiNameStr){// NCP-744
                    //Handle the Image type file need to update the Id in Thumbnail image
                    if(objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c == digitalAssetBrandNameStr){
                        
                        for(String fieldDetails : splitString){
                            if(fieldDetails.contains(brandNameStr)){
                                updateContentVersionDetails(sObj, fieldDetails, objConDocLink, isDelete);
                            }
                        }
                    } else if(objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c == digitalAssetOccasionNameStr){
                        for(String fieldDetails : splitString){
                            if(fieldDetails.contains(occasionNameStr)){
                                updateContentVersionDetails(sObj, fieldDetails, objConDocLink, isDelete);                                
                            }
                        }
                    } else if(objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c == digitalAssetAllAssetTypeNameStr){
                        for(String fieldDetails : splitString){
                            if(fieldDetails.contains(allAssetTypeStr)){
                                updateContentVersionDetails(sObj, fieldDetails, objConDocLink, isDelete);                                
                            }
                        }
                    }
                }else{
                    for(String fieldDetails : splitString){                        
                        if(fieldDetails.contains('Document')){
                            //If multiple image is allowed put the data in contentDocumentId variable to concatenate in one field
                            if(fileSettingDetails.Multiple_Image_Allowed__c != null && fileSettingDetails.Multiple_Image_Allowed__c && existingRecord != null && existingRecord.get(fieldDetails) != null){
                                if(isDelete){
                                    String existRecord = (String)existingRecord.get(fieldDetails);
                                    List<String> lstExistDocId = existRecord.split(';');
                                    contentDocumentId = '';
                                    for(String existDocId : lstExistDocId){
                                        if(existDocId != objConDocLink.ContentDocumentId){
                                            contentDocumentId += existDocId + ';';
                                        }
                                    }
                                    if(String.isNotBlank(contentDocumentId) && contentDocumentId.endsWith(';')){
                                        contentDocumentId = contentDocumentId.removeEnd(';');
                                    }
                                    sObj.put(fieldDetails , contentDocumentId);
                                    
                                } else{
                                    String existingValue =(String)existingRecord.get(fieldDetails);
                                    if(!existingValue.containsIgnoreCase( objConDocLink.ContentDocumentId)){
                                        contentDocumentId = existingRecord.get(fieldDetails) + ';' + objConDocLink.ContentDocumentId;
                                        sObj.put(fieldDetails , contentDocumentId);
                                    }
                                }                                
                            } else {
                                if(isDelete){
                                    sObj.put(fieldDetails , '');
                                } else {
                                    sObj.put(fieldDetails , objConDocLink.ContentDocumentId);
                                }
                            }
                        } else {
                            //If multiple image is allowed put the data in contentVersionId String variable to concatenate in one field
                            if(fileSettingDetails.Multiple_Image_Allowed__c != null && fileSettingDetails.Multiple_Image_Allowed__c && existingRecord != null && existingRecord.get(fieldDetails) != null){
                                if(isDelete){
                                    String existRecord = (String)existingRecord.get(fieldDetails);
                                    List<String> lstExistVerId = existRecord.split(';');
                                    contentVersionId = '';
                                    for(String existDocId : lstExistVerId){
                                        if(existDocId != objConDocLink.ContentDocument.LatestPublishedVersionId){
                                            contentVersionId += existDocId + ';';
                                        }
                                    }
                                    if(String.isNotBlank(contentVersionId) && contentVersionId.endsWith(';')){
                                        contentVersionId = contentVersionId.removeEnd(';');
                                    }
                                    sObj.put(fieldDetails , contentVersionId);
                                    
                                } else {
                                    String existingValue =(String)existingRecord.get(fieldDetails);
                                    if(!existingValue.containsIgnoreCase( objConDocLink.ContentDocument.LatestPublishedVersionId)){
                                        contentVersionId = existingRecord.get(fieldDetails) + ';' + objConDocLink.ContentDocument.LatestPublishedVersionId;
                                        sObj.put(fieldDetails , contentVersionId);
                                    }                                                                        
                                }
                            } else {
                                if(isDelete){
                                    sObj.put(fieldDetails , '');
                                } else {
                                    sObj.put(fieldDetails , objConDocLink.ContentDocument.LatestPublishedVersionId); 
                                }
                            }                            
                        }
                    }                    
                }
            }
        } catch (Exception excption){
            System.debug(LoggingLevel.Debug,'Exception createSObject CDLT::::'+excption.getLineNumber()+'::'+excption.getMessage()+excption.getCause());
        }
        return sObj;
    }
    
    /*
@param sObj 
@param fieldDetails 
@param objConDocLink 
@param isDelete 
*/
    @TestVisible
    private static void updateContentVersionDetails(sObject sObj, String fieldDetails, ContentDocumentLink objConDocLink, Boolean isDelete){ 
        if(isDelete){
            sObj.put(fieldDetails , '');
        } else {
            if(fieldDetails.contains(documentStr)){
                sObj.put(fieldDetails , objConDocLink.ContentDocumentId);
            } else {
                sObj.put(fieldDetails , objConDocLink.ContentDocument.LatestPublishedVersionId);
            }
        }
    }
    
    /*
@description : checkNoOfFile - This methods used to check that there should be one pdf per promotion
@return : void
@param newItems 
*/
    public static void checkNoOfFile(List<ContentDocumentLink> newItems){
        Set<Id> setLinkedEntityId = new Set<Id>();
        Set<Id> setDocumentId = new Set<Id>();
        Set<Id> contractLinkedEntityId = new Set<Id>();//151377
        Set<Id> contractIdCrgType = new Set<Id>();//151377
        Map<Id, List<ContentDocumentLink>> mapConDocLink = new Map<Id, List<ContentDocumentLink>>();
        Map<Id,ContentDocument> mapNewContentDoc;   
        List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
        
        // New documents to be inserted in the promotion records
        // Change for updating Product image details-- added Product__c.sObjectType (ES20-2618)
        // Adding Market Setting Object related check (ECM-4924)
        // Adding Contract Object related check (ECM-4959)
        for(ContentDocumentLink  objConDocLink : newItems) {
            if(objConDocLink.LinkedEntityId != null && 
               (objConDocLink.LinkedEntityId.getSObjectType() == Promotion__c.sObjectType ||
                objConDocLink.LinkedEntityId.getSObjectType() == Opportunity_Template__c.sObjectType || 
                objConDocLink.LinkedEntityId.getSObjectType() == Account.sObjectType ||
                objConDocLink.LinkedEntityId.getSObjectType() == Product__c.sObjectType ||
                objConDocLink.LinkedEntityId.getSObjectType() == Order_Item__c.sObjectType||
                objConDocLink.LinkedEntityId.getSObjectType() == ECM_Addendum__c.sObjectType||
                objConDocLink.LinkedEntityId.getSObjectType() == Market_Setting__c.sObjectType|| //ECM-4924
                objConDocLink.LinkedEntityId.getSObjectType() == Contract.sObjectType //ECM-4959
               ))
            {
                setLinkedEntityId.add(objConDocLink.LinkedEntityId);
                setDocumentId.add(objConDocLink.ContentDocumentId);
                lstContentDocumentLink.add(objConDocLink);
            }
        }
        
        //Quering all existing ContentDocumentLink records to find if  LinkedEntityId  is present in existing records, if exists putting in a map
        if(Schema.sObjectType.ContentDocumentLink.isAccessible() && Schema.sObjectType.ContentDocument.isAccessible() && setLinkedEntityId != null && setLinkedEntityId.size()>0) {
            
            //Query to get the Document Title of new Items that is going to be inserted
            //List<ContentDocument> lstContentDoc = [SELECT Id,Title,FileExtension FROM ContentDocument WHERE Id in :setDocumentId LIMIT 1];
            mapNewContentDoc = new Map<Id,ContentDocument>([SELECT Id,Title,FileExtension,LatestPublishedVersionId,LatestPublishedVersion.Content_Type__c FROM ContentDocument WHERE Id in :setDocumentId]);
            for(ContentDocumentLink  existConDoc : [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.FileExtension, ContentDocument.Title,ContentDocument.LatestPublishedVersion.Content_Type__c FROM ContentDocumentLink WHERE ContentDocument.LatestPublishedVersion.Content_Type__c != 'Other' and LinkedEntityId IN :setLinkedEntityId  ]){
                if(mapConDocLink.containsKey(existConDoc.LinkedEntityId)){
                    mapConDocLink.get(existConDoc.LinkedEntityId).add(existConDoc);
                } else {
                    mapConDocLink.put(existConDoc.LinkedEntityId, new List<ContentDocumentLink>{existConDoc});
                }
                if(existConDoc.LinkedEntityId.getSobjectType() == Contract.SobjectType){//151377
                    contractLinkedEntityId.add(existConDoc.LinkedEntityId);
                }
            }
        }       
        setLinkedEntityId.clear();
        setDocumentId.clear();
        //153713 -> Start
        if(!contractLinkedEntityId.isEmpty()){
            string crgRecordType = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();//151377
            
            for(Contract contractRec: [Select Id, Name, RecordTypeId from Contract Where Id IN:contractLinkedEntityId and RecordTypeId = :crgRecordType with SECURITY_ENFORCED]){//151377
                contractIdCrgType.add(contractRec.id);                      
            }
        }//153713 -> end
        
        //if the promotion record id present in the map , the error will occur and document will not be inserted            
        if(mapConDocLink !=null && mapConDocLink.size()>0){
            for(ContentDocumentLink conDocLnkObj : lstContentDocumentLink){
                if(mapConDocLink.containsKey(conDocLnkObj.LinkedEntityId)){
                    //Only one Promotional PDF is allowed per promotion
                    if(conDocLnkObj.LinkedEntityId != null && conDocLnkObj.LinkedEntityId.getSObjectType() == Promotion__c.sObjectType ){
                        conDocLnkObj.addError(label.OnePdfPerPromotion);
                    }else if(conDocLnkObj.LinkedEntityId != null && conDocLnkObj.LinkedEntityId.getSObjectType() == Order_Item__c.sObjectType && mapNewContentDoc != null && mapNewContentDoc.size()>0 ){
                        ContentDocument objContentDocument = mapNewContentDoc.get(conDocLnkObj.ContentDocumentId);
                        List<ContentDocumentLink> lstExistConDoc = mapConDocLink.get(conDocLnkObj.LinkedEntityId);
                        for(ContentDocumentLink objExistConDocLink : lstExistConDoc){
                            if((objContentDocument.LatestPublishedVersion.Content_Type__c).contains('Order Product Image') && (objExistConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c).contains('Order Product Image')){
                                conDocLnkObj.addError(label.OneImagePerOrderItem);
                            }
                        }
                    } 
                    else if(conDocLnkObj.LinkedEntityId != null && conDocLnkObj.LinkedEntityId.getSObjectType() == Opportunity_Template__c.sObjectType){                            
                        //This is used to check whether the new File extension already exists or not
                        if(mapNewContentDoc != null && mapNewContentDoc.size()>0 && mapNewContentDoc.containsKey(conDocLnkObj.ContentDocumentId)){
                            String acceptedExtension = Label.Accepted_Image_Extensions_In_OppTemp;
                            List<String> acceptedExtensions = acceptedExtension.split(';');
                            
                            List<ContentDocumentLink> lstExistConDoc = mapConDocLink.get(conDocLnkObj.LinkedEntityId);
                            ContentDocument newConDoc = mapNewContentDoc.get(conDocLnkObj.ContentDocumentId);
                            
                            for(ContentDocumentLink existConDoc : lstExistConDoc){
                                if(acceptedExtensions.contains(newConDoc.FileExtension) && acceptedExtensions.contains(existConDoc.ContentDocument.FileExtension)){
                                    conDocLnkObj.addError(label.One_File_type_Per_Opp_Template);
                                }else if(existConDoc.ContentDocument.FileExtension == newConDoc.FileExtension){
                                    conDocLnkObj.addError(label.One_File_type_Per_Opp_Template);
                                }
                            }                                
                        }
                    } else if(conDocLnkObj.LinkedEntityId != null && conDocLnkObj.LinkedEntityId.getSObjectType() == Account.sObjectType && mapNewContentDoc != null && mapNewContentDoc.size()>0){
                        ContentDocument objContentDocument = mapNewContentDoc.get(conDocLnkObj.ContentDocumentId);
                        List<ContentDocumentLink> lstExistConDoc = mapConDocLink.get(conDocLnkObj.LinkedEntityId);
                        for(ContentDocumentLink objExistConDocLink : lstExistConDoc){
                            if((objContentDocument.Title).contains('OutletImage_') && (objExistConDocLink.ContentDocument.Title).contains('OutletImage_')){
                                conDocLnkObj.addError(label.Oulet_Image_Exist_Error);
                            }
                        }                        
                    }else if(conDocLnkObj.LinkedEntityId != null && conDocLnkObj.LinkedEntityId.getSObjectType() == Product__c.sObjectType && mapNewContentDoc != null && mapNewContentDoc.size()>0){ 
                        ContentDocument objContentDocument = mapNewContentDoc.get(conDocLnkObj.ContentDocumentId);
                        List<ContentDocumentLink> lstExistConDoc = mapConDocLink.get(conDocLnkObj.LinkedEntityId);
                        for(ContentDocumentLink objExistConDocLink : lstExistConDoc){
                            if((objContentDocument.LatestPublishedVersion.Content_Type__c).contains('Product Image') && (objExistConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c).contains('Product Image')){
                                conDocLnkObj.addError(label.OneImageAlreadyPresent);
                            }
                        }   
                        
                    }else if(conDocLnkObj.LinkedEntityId != null && conDocLnkObj.LinkedEntityId.getSObjectType() == ECM_Addendum__c.sObjectType ){
                        conDocLnkObj.addError(label.ECM_OnePdfPerAddendum);
                    }
                    // Adding Market Setting Object related check (ECM-4924)
                    else if(conDocLnkObj.LinkedEntityId != null && conDocLnkObj.LinkedEntityId.getSObjectType() == Market_Setting__c.sObjectType && mapNewContentDoc != null && mapNewContentDoc.size()>0){
                        ContentDocument objContentDocument = mapNewContentDoc.get(conDocLnkObj.ContentDocumentId);
                        List<ContentDocumentLink> lstExistConDoc = mapConDocLink.get(conDocLnkObj.LinkedEntityId);
                        for(ContentDocumentLink objExistConDocLink : lstExistConDoc){
                            if(Label.ECM_MarketSettingContentTypesForRestriction.contains(objContentDocument.LatestPublishedVersion.Content_Type__c) && Label.ECM_MarketSettingContentTypesForRestriction.contains(objExistConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c)){
                                conDocLnkObj.addError(objExistConDocLink.ContentDocument.Title+' '+label.ECM_OneTandCPdfPerMarketSetting);
                            }
                        }
                        
                    } 
                    // Checking for Contract RecordType is having more than one Approval Mail Attachment ContentType (ECM-4959)
                    else if(conDocLnkObj.LinkedEntityId != null && conDoclnkObj.LinkedEntityId.getSobjectType() == Contract.SobjectType && mapNewContentDoc != null && mapNewContentDoc.size()>0 && !contractIdCrgType.contains(conDocLnkObj.LinkedEntityId))//151377 - added check for crg
                    {
                        ContentDocument objContentDocument = mapNewContentDoc.get(conDocLnkObj.ContentDocumentId);
                        List<ContentDocumentLink> lstExistConDoc = mapConDocLink.get(conDocLnkObj.LinkedEntityId);
                        for(ContentDocumentLink objExistConDocLink : lstExistConDoc)                        
                        {
                            if((objContentDocument.LatestPublishedVersion.Content_Type__c).contains(label.ECM_ContentTypeApprovalMail) && (objExistConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c).contains(label.ECM_ContentTypeApprovalMail))
                            {
                                conDocLnkObj.addError(label.ECM_ContentTypeApprovalMailCheck);
                            }
                        }
                    }   
                }                    
            }
        }
    }
    
    /*
@description : clearFieldDetails - This methods used to clear field details in object
@return : void
@param oldItems 
*/
    public static void clearFieldDetails(Map<Id, SObject> oldItems){
        Map<Id,ContentDocumentLink> mapContentDocLink = new Map<Id,ContentDocumentLink>(); 
        Map<string,ContentDocumentLink> mapContentDocLinkCM = new Map<string,ContentDocumentLink>(); 
        Map<Id,List<Id>> mapLinkedEntityId = new Map<Id,List<Id>>();
        //Map<Id, Contract> draftContracts = new Map<Id, Contract>();
        Map<string, CM_Attachment_Permission__mdt> mapCmPermission= new Map<string, CM_Attachment_Permission__mdt>();
        Set<Id> setContentDoc = new Set<Id>();
        //Set<Id> setContentDocs = new Set<Id>();
        // Set<Id> setContractIds = new Set<Id>();
        String recordTypeName;
        Id linkedEntityId;
        //145098
        //fix start -> 153831
        User userDetails = new User();
        System.debug(LoggingLevel.DEBUG, 'userDetails @ '+userDetails);
        if(Schema.sObjectType.User.isAccessible() || userinfo.getUserType() == 'Guest'){
            userDetails = [SELECT Id, Name, Available_Countries__c,ProfileId,Profile.Name FROM User where id=:userinfo.getuserId()];
        }else{
            userDetails = [SELECT Id, Name, Available_Countries__c,ProfileId,Profile.Name FROM User where id=:userinfo.getuserId() WITH SECURITY_ENFORCED];
        }//fix end -> 153831
        
        //Query File_Setting__mdt if already not present
        if(!(mapObjectFileSetting != null && mapObjectFileSetting.size()>0)){
            getFileSetting();            
        }
        
        try{
            if(oldItems != null && oldItems.size()>0){
                for(CM_Attachment_Permission__mdt cMPermission : CM_Attachment_Permission__mdt.getAll().values() )
                {
                    if(cMPermission.Profile_Name__c == userDetails.Profile.Name && cMPermission.Country_Code__c == userDetails.Available_Countries__c){
                        mapCmPermission.put(cMPermission.File_Type__c+cMPermission.Content_Type__c+cMPermission.Object__c,cMPermission);
                    }
                }
                setContentDoc = oldItems.keySet();
                for(ContentDocumentLink objConDocLink :[Select Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId, 
                                                        ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.RecordTypeId, 
                                                        ContentDocument.LatestPublishedVersion.RecordType.Name, ContentDocument.LatestPublishedVersion.RecordType.DeveloperName, ContentDocument.LatestPublishedVersion.Content_Type__c
                                                        FROM ContentDocumentLink 
                                                        WHERE ContentDocumentId IN :setContentDoc])
                {
                    string type;
                    type = objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c ;
                    String sobjectName;
                    sobjectName = (objConDocLink.LinkedEntityId).getSObjectType().getDescribe().getName();
                    string contractRecordTypeName;
                    contractRecordTypeName = objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName;
                    string contenttype;
                    contenttype = objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c;                       
                    //Add Pioneer Record TYpe.PION-955
                    if(objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName != System.Label.ECM_CVOthersRecType && objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c != 'Other' 
                       && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName != System.Label.ECM_CVDirectCustomerRecType && objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c != 'Direct Customer')
                    {
                        if(mapObjectFileSetting.containsKey(sobjectName) && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == mapObjectFileSetting.get(sobjectName).DeveloperName && 
                           ((objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVAccountRecType && (objConDocLink.ContentDocument.Title).contains('OutletImage_')) ||
                            (objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName != System.Label.ECM_CVAccountRecType)))
                        {
                            mapContentDocLink.put(objConDocLink.ContentDocumentId, objConDocLink); 
                            recordTypeName = objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName;     
                            if(mapLinkedEntityId.containsKey(objConDocLink.ContentDocumentId)){
                                mapLinkedEntityId.get(objConDocLink.ContentDocumentId).add(objConDocLink.LinkedEntityId);
                            } else {
                                mapLinkedEntityId.put(objConDocLink.ContentDocumentId, new List<Id> {objConDocLink.LinkedEntityId});
                            }
                        }      
                    }
                    if(objConDocLink.LinkedEntityId.getSObjectType().getDescribe().getName()=='Contract' || 
                       objConDocLink.LinkedEntityId.getSObjectType().getDescribe().getName()=='ECM_Payment_Summary__c' ||
                       objConDocLink.LinkedEntityId.getSObjectType().getDescribe().getName()=='ECM_Addendum__c')
                    {
                        mapContentDocLinkCM.put(objConDocLink.ContentDocument.LatestPublishedVersion.ID, objConDocLink);
                    }
                }
                //changes related to contract management ECM-4064
                for(Sobject contDocument: oldItems.values()) {
                    string uniqstr ='';
                    if(mapCmPermission.size()>0 && contDocument.get('LatestPublishedVersionId')!=Null && mapContentDocLinkCM.containskey(string.valueof(contDocument.get('LatestPublishedVersionId')))){
                        uniqstr = mapContentDocLinkCM.get(string.valueof(contDocument.get('LatestPublishedVersionId'))).ContentDocument.LatestPublishedVersion.RecordType.DeveloperName+mapContentDocLinkCM.get(string.valueof(contDocument.get('LatestPublishedVersionId'))).ContentDocument.LatestPublishedVersion.Content_Type__c+mapContentDocLinkCM.get(string.valueof(contDocument.get('LatestPublishedVersionId'))).LinkedEntityId.getSObjectType().getDescribe().getName();
                        if(uniqstr!='' && mapCmPermission.containskey(uniqstr)){                        
                            if(mapCmPermission.get(uniqstr).Permission__c=='No'){
                                contDocument.addError(label.ECM_AttachmentValidation);
                            }                            
                        }
                    }
                }
                if(String.isNotBlank(recordTypeName) && mapLinkedEntityId != null && mapLinkedEntityId.size()>0){
                    upsertSobjectData(mapContentDocLink, recordTypeName, mapLinkedEntityId, false, true);                    
                }
            }
        } catch (Exception excption){
            System.debug(LoggingLevel.Debug,'Exception clearFieldDetails::::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
        }
    }
    
    /*
@description : upsertDirectCustomerData - This is used to create the list and upsert Direct Customer data - PION-955
@return : void
@param mapContentDoc 
@param contentWorkSpaceName 
@param linkedEntityId 
@param insertWorkspace 
@param isDelete 
*/
    public static void upsertDirectCustomerData(Map<Id,ContentDocumentLink> mapContentDoc, String contentWorkSpaceName, Id linkedEntityId, Boolean insertWorkspace, Boolean isDelete){
        List<ContentWorkspaceDoc> lstContentWorkDoc = new List<ContentWorkspaceDoc>();
        //Map<Id,sObject> mapContent = new Map<Id,sObject>();
        ContentWorkspace contentWorkSpc;
        try{
            if(mapContentDoc != null && mapContentDoc.size()>0 && Schema.sObjectType.ContentWorkspace.isAccessible() 
               && Schema.sObjectType.ContentWorkspace.isCreateable() && Schema.sObjectType.ContentWorkspace.isUpdateable()){
                   contentWorkSpc = [SELECT Id FROM ContentWorkspace where name =:contentWorkSpaceName LIMIT 1];
                   for(Id contentDocId : mapContentDoc.keySet()){
                       if(insertWorkspace){
                           //Create ContentWorkSpaceDoc to craete the Link between the Library and Content Document
                           ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();
                           newWorkspaceDoc.ContentWorkspaceId = contentWorkSpc.Id; 
                           newWorkspaceDoc.ContentDocumentId = contentDocId;
                           lstContentWorkDoc.add(newWorkspaceDoc);  
                       }                    
                   }
                   
                   if(lstContentWorkDoc != null && lstContentWorkDoc.size()>0){                        
                       if(insertWorkspace){
                           Database.upsert(lstContentWorkDoc);
                       }                    
                   }
               }
            
        } catch(Exception excption){
            System.debug(LoggingLevel.Debug,'Exception upsertSobjectData in SDLT::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
        }
    }
    
    /*
@description : insertCaseAttachmentToFeed - This is used to insert a copy of the files uploaded under Case Attachments on the Feed - ES20-9665
@return : void
@param newItems 
*/
    /* public static void insertCaseAttachmentToFeed(Map<Id,SObject> newItems){
//Variable
Map<Id,ContentDocumentLink> contentDocumentLinkMap = (Map<Id, ContentDocumentLink>)newItems;
List<FeedItem> caseFeedList = new List<FeedItem>();
Set<Id> contentDocumentLinkIds = new Set<Id>();
List<FeedAttachment> newFeedAttachmentList = new List<FeedAttachment>();
Map<Id,Id> caseVsFeedMap = new Map<Id,Id>();
//Map<Id,List<Id>> conDocAndCaseIdMap = new Map<Id,List<Id>>();
List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
List<Id> conDocList = new List<Id>();//not used

if(!contentDocumentLinkMap.isEmpty() && Schema.sObjectType.ContentDocumentLink.isAccessible() && Schema.sObjectType.ContentDocumentLink.isCreateable())
{
//Considering only those ContentDocumentLinks which are associated with Case object
for(ContentDocumentLink conDocLnkObj : contentDocumentLinkMap.values()){
if(conDocLnkObj.LinkedEntityId.getSObjectType() == Case.sObjectType){
contentDocumentLinkIds.add(conDocLnkObj.id);
}
}
if(!contentDocumentLinkIds.isEmpty()){
for(ContentDocumentLink contentDocumentLinkObj : [SELECT Id,ContentDocument.LatestPublishedVersionId,
LinkedEntityId,LinkedEntity.Recordtype.Name,ContentDocumentId, 
ContentDocument.CreatedBy.Profile.Name FROM ContentDocumentLink 
WHERE ID IN:contentDocumentLinkIds])
{                                              
if(contentDocumentLinkObj.LinkedEntity.Recordtype.Name == 'Technical Issue' &&
contentDocumentLinkObj.ContentDocument.CreatedBy.Profile.Name == 'Integration User Profile')
{
FeedItem feed = new FeedItem();
feed.Body = Label.EDGE_DefaultCaseFeedBody;
feed.ParentId = contentDocumentLinkObj.LinkedEntityId;
feed.Visibility = 'AllUsers'; //NCP-5031
caseFeedList.add(feed);                                     
contentDocumentLinkList.add(contentDocumentLinkObj);                                                  
//conDocList.add(contentDocumentLinkObj.ContentDocumentId);//not used 
//if(conDocAndCaseIdMap.containsKey(contentDocumentLinkObj.LinkedEntityId)){
//  conDocAndCaseIdMap.get(contentDocumentLinkObj.LinkedEntityId).add(contentDocumentLinkObj.ContentDocumentId);                                                 
//}else{
//  conDocAndCaseIdMap.put(contentDocumentLinkObj.LinkedEntityId,new List<Id>{contentDocumentLinkObj.ContentDocumentId});
//}
}
}
}

//Creating Case Feed 
if(!caseFeedList.isEmpty()){
List<Database.SaveResult> insertedfeedItemList = Database.insert(caseFeedList,false);
Integer i=0;
for(Database.SaveResult sr : insertedfeedItemList){
if (sr.isSuccess()){
caseVsFeedMap.put(caseFeedList[i].ParentId,sr.getId());//Map with CaseId and FeedId
}
i++;
}
}

if(!caseVsFeedMap.isEmpty()){
for(ContentDocumentLink contentDocLink: contentDocumentLinkList){
//Checking ContentDocument and corresponding CaseId                                        
if(caseVsFeedMap!= null && caseVsFeedMap.containsKey(contentDocLink.LinkedEntityId)
// && conDocandcaseIdMap != null && conDocandcaseIdMap.containskey(contentDocLink.LinkedEntityId)
//&& conDocandcaseIdMap.get(contentDocLink.LinkedEntityId).contains(contentDocLink.ContentDocumentId)
)
{
Id feedId = caseVsFeedMap.get(contentDocLink.LinkedEntityId);
FeedAttachment feedAttachmentObj = new FeedAttachment();
feedAttachmentObj.FeedEntityId = feedId;
feedAttachmentObj.RecordId = contentDocLink.ContentDocument.LatestPublishedVersionId;
feedAttachmentObj.Type = 'CONTENT'; 
newFeedAttachmentList.add(feedAttachmentObj);                                             
}
}
}

//Inserting feedattachment records
if(!newFeedAttachmentList.isEmpty()){
Database.insert(newFeedAttachmentList);    
}
}
}*/
    
    /*
@description : insertCaseAttachmentToSNowTicket - This is used to insert a copy of the files uploaded under Case Attachments to the SNOW incident - ES20-9662
@return : void
@param newItems 
*/
    /* public static void insertCaseAttachmentToSNowTicket(Map<Id,SObject> newItems){
//Variable
Map<Id,ContentDocumentLink> contentDocumentLinkMap = (Map<Id, ContentDocumentLink>)newItems;
Map<Id,Map<Id, String>> caseIdConVersionMap = new Map<Id,Map<Id, String>>();
Set<Id> contentDocumentLinkIds = new Set<Id>();

if(!contentDocumentLinkMap.isEmpty() && Schema.sObjectType.ContentDocumentLink.isAccessible() && Schema.sObjectType.ContentDocumentLink.isCreateable()){
//Considering only those ContentDocumentLinks which are associated with Case object
for(ContentDocumentLink conDocLnkObj : contentDocumentLinkMap.values()){
if(conDocLnkObj.LinkedEntityId.getSObjectType() == Case.sObjectType ){
contentDocumentLinkIds.add(conDocLnkObj.id);
}
}
if(!contentDocumentLinkIds.isEmpty()){   
for(ContentDocumentLink contentDocumentLinkObj : [SELECT Id,ContentDocument.LatestPublishedVersionId,
LinkedEntityId,LinkedEntity.Recordtype.Name,
ContentDocument.Title,ContentDocument.FileExtension,
ContentDocumentId,ContentDocument.CreatedBy.Profile.Name
FROM ContentDocumentLink 
WHERE ID IN:contentDocumentLinkIds])
{                                                   
if(contentDocumentLinkObj.LinkedEntity.Recordtype.Name == 'Technical Issue' && 
contentDocumentLinkObj.ContentDocument.CreatedBy.Profile.Name != 'Integration User Profile')
{
string contentDocumentName = contentDocumentLinkObj.ContentDocument.Title + '.' +contentDocumentLinkObj.ContentDocument.FileExtension;
if(caseIdConVersionMap.get(contentDocumentLinkObj.LinkedEntityId) != null){
caseIdConVersionMap.get(contentDocumentLinkObj.LinkedEntityId).put(contentDocumentLinkObj.ContentDocument.LatestPublishedVersionId, contentDocumentName);
}
else{
Map<Id, String> contentVersionIdMap = new Map<Id, String>();
contentVersionIdMap.put(contentDocumentLinkObj.ContentDocument.LatestPublishedVersionId, contentDocumentName);
caseIdConVersionMap.put(contentDocumentLinkObj.LinkedEntityId,contentVersionIdMap);   
}
}
}
if(caseIdConVersionMap != null && caseIdConVersionMap.size() > 0){
System.enqueueJob(new Edge_CaseAttachmentIntegrationWithSNOW(caseIdConVersionMap));
}
} 
}
}*/
    /*
* @description : 145098 - Optimize the ContentDocumentTrigger_SFDC_Technical Debt 
* merged methods : (insertCaseAttachmentToSNowTicket - This is used to insert a copy of the files uploaded under Case Attachments to the SNOW incident - ES20-9662 )
* 					and (insertCaseAttachmentToFeed - This is used to insert a copy of the files uploaded under Case Attachments on the Feed - ES20-9665)
* @return : void
* @param newItems 
*/
    public static void processCaseAttachments(Map<Id, SObject> newItems) {
        Map<Id, ContentDocumentLink> contentDocumentLinkMap = (Map<Id, ContentDocumentLink>) newItems;
        List<FeedItem> caseFeedList = new List<FeedItem>();
        List<FeedAttachment> newFeedAttachmentList = new List<FeedAttachment>();
        Map<Id, Id> caseVsFeedMap = new Map<Id, Id>();
        Map<Id, Map<Id, String>> caseIdConVersionMap = new Map<Id, Map<Id, String>>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        
        
        set<Id> contentDocLinkIds = new set<Id>();
        
        if (!contentDocumentLinkMap.isEmpty() && Schema.sObjectType.ContentDocumentLink.isAccessible() && Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            // Filter ContentDocumentLinks associated with Case objects
            for (ContentDocumentLink conDocLnkObj : contentDocumentLinkMap.values()) {
                if (conDocLnkObj.LinkedEntityId.getSObjectType() == Case.sObjectType) {
                    contentDocLinkIds.add(conDocLnkObj.Id);
                }
            }
            
            if (!contentDocLinkIds.isEmpty()) {
                for (ContentDocumentLink contentDocumentLinkObj : [
                    SELECT Id, ContentDocument.LatestPublishedVersionId, LinkedEntityId, LinkedEntity.Recordtype.Name,
                    ContentDocument.Title, ContentDocument.FileExtension, ContentDocumentId,
                    ContentDocument.CreatedBy.Profile.Name
                    FROM ContentDocumentLink 
                    WHERE Id IN :contentDocLinkIds
                ]) {
                    String recordTypeName = contentDocumentLinkObj.LinkedEntity.Recordtype.Name;
                    String createdByProfileName = contentDocumentLinkObj.ContentDocument.CreatedBy.Profile.Name;
                    
                    if (recordTypeName == CASE_RECORD_TYPE_TECHNICAL_ISSUE) {
                        if (createdByProfileName == INTEGRATION_USER_PROFILE_NAME) {
                            // Insert Case Feed Item
                            FeedItem feed = new FeedItem(
                                Body = Label.EDGE_DefaultCaseFeedBody,
                                ParentId = contentDocumentLinkObj.LinkedEntityId,
                                Visibility = FEED_VISIBILITY
                            );
                            caseFeedList.add(feed);
                            contentDocumentLinkList.add(contentDocumentLinkObj);
                            
                        } else {
                            string contentDocumentName = contentDocumentLinkObj.ContentDocument.Title + '.' +contentDocumentLinkObj.ContentDocument.FileExtension;
                            if(caseIdConVersionMap.get(contentDocumentLinkObj.LinkedEntityId) != null){
                                caseIdConVersionMap.get(contentDocumentLinkObj.LinkedEntityId).put(contentDocumentLinkObj.ContentDocument.LatestPublishedVersionId, contentDocumentName);
                            }
                            else{
                                Map<Id, String> contentVersionIdMap = new Map<Id, String>();
                                contentVersionIdMap.put(contentDocumentLinkObj.ContentDocument.LatestPublishedVersionId, contentDocumentName);
                                caseIdConVersionMap.put(contentDocumentLinkObj.LinkedEntityId,contentVersionIdMap);   
                            }
                        }
                    }
                }
            }
            
            // Insert Case Feed Items
            if (!caseFeedList.isEmpty()) {
                List<Database.SaveResult> insertedFeedItemList = Database.insert(caseFeedList, false);
                Integer i = 0;
                for (Database.SaveResult sr : insertedFeedItemList) {
                    if (sr.isSuccess()) {
                        caseVsFeedMap.put(caseFeedList[i].ParentId, sr.Id);
                    }
                    i++;
                }
            }
            
            // Process and Insert Feed Attachments
            for (ContentDocumentLink contentDocLink : contentDocumentLinkList) {
                if (caseVsFeedMap.containsKey(contentDocLink.LinkedEntityId)) {
                    Id feedId = caseVsFeedMap.get(contentDocLink.LinkedEntityId);
                    FeedAttachment feedAttachmentObj = new FeedAttachment(
                        FeedEntityId = feedId,
                        RecordId = contentDocLink.ContentDocument.LatestPublishedVersionId,
                        Type = FEED_ATTACHMENT_TYPE
                    );
                    newFeedAttachmentList.add(feedAttachmentObj);
                }
            }
            
            // Insert Feed Attachments
            if (!newFeedAttachmentList.isEmpty()) {
                Database.insert(newFeedAttachmentList);
            }
        }
        
        // Enqueue Job
        if(!caseIdConVersionMap.isEmpty()){
            System.enqueueJob(new Edge_CaseAttachmentIntegrationWithSNOW(caseIdConVersionMap));
        }
    }
    
    
    /*
@description : lockClaimItem - Lock the chile record when claim is approved/rejected
@return : void
@param newItems 
*/
    public static void readOnlyAttach(List<ContentDocumentLink> newItems){
        Set<Id> cstClaimId = new Set<Id>();
        Map<string,ContentDocumentLink> mapClaimtoContent = new Map<string,ContentDocumentLink>();
        for(ContentDocumentLink  objConDocLink : newItems) {
            if(objConDocLink.LinkedEntityId != null && 
               (objConDocLink.LinkedEntityId.getSObjectType() == CST_Claim__c.sObjectType))
            {
                cstClaimId.add(objConDocLink.LinkedEntityId);
                mapClaimtoContent.put(objConDocLink.LinkedEntityId,objConDocLink);
            }
        }
        
        Id userId = UserInfo.getUserId();
        //145098
        if(!mapClaimtoContent.isEmpty()){
            for(CST_Claim__c objClaims : [select id,CST_Status__c,CreatedById from CST_Claim__c where id IN :cstClaimId]){
                if(objClaims.CST_Status__c == 'Approved' || objClaims.CST_Status__c == 'Rejected'){
                    if(mapClaimtoContent.containskey(objClaims.id)){
                        mapClaimtoContent.get(objClaims.id).addError('Claim Status is Approved/Rejected, Please Contact Administrator.');
                    }
                }
                else if(objClaims.CreatedById == userID && (objClaims.CST_Status__c == 'Assigned to Default Approver' ||  objClaims.CST_Status__c == 'Assigned To Approver')){
                    if(mapClaimtoContent.containskey(objClaims.id)){
                        mapClaimtoContent.get(objClaims.id).addError('Claim Status is Assigned to Default Approver/Assigned To Approver, Please Contact Administrator.');
                    }
                }
            }
        }
    }
    
    
    /*
@description : recordTypeUpdate - This is used to To Autopopulate the RecordType and Content Type for the Documents - ECM-3950
@return : void
@param newItems 
*/
    public static void recordTypeUpdate(Map<Id,SObject> newItems) {
        //145098
        Id profileID = LEGAL_USER_PROFILE_ID;
        
        if(Userinfo.getProfileId() == profileID){
            //Set<Id> setContentDoc = new Set<Id>();
            //List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
            Id linkedEntityId;
            Set<Id> conDocId = new Set<Id>();
            Map<Id,ContentDocumentLink> newContentDocumentLink = (Map<Id,ContentDocumentLink>)newItems;
            //To query the recordTypeId of Contracts In Content Version Sobject to update it to the followed Document
            Id rt = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get(System.Label.ECM_CVContractsRecType).getRecordTypeId();
            //To query Uploaded Document
            for(ContentDocumentLink objConDocLink :newContentDocumentLink.values()){
                String sobjectName = (objConDocLink.LinkedEntityId).getSObjectType().getDescribe().getName();       
                if(sobjectName == Label.ECM_Addendum_Object){      
                    conDocId.add(objConDocLink.ContentDocumentId);
                }               
            }
            //145098
            if(!conDocId.isEmpty()){
                List<ContentVersion> cdList = new List<ContentVersion>();
                for(ContentVersion cd : [SELECT Id, RecordTypeId, Content_Type__c FROM ContentVersion WHERE ContentDocumentId =:conDocId with SECURITY_ENFORCED]){    
                    cd.RecordTypeId = rt;
                    cd.Content_Type__c = Label.ECM_Amended_T_C;
                    cdList.add(cd);
                }
                Database.upsert(cdList);
            }
        }
    }
    //ECM-6291
    public static void validateContractSignedDate(List<SObject> newItems) {
        List<ContentDocumentLink> cdLinkList = (List<ContentDocumentLink>)(newItems);
        //Set<Id> conDocIds = new Set<id>();
        Map<Id,ContentDocumentLink> linkMap = new Map<Id,ContentDocumentLink>();
        Map<Id,Id> conDocMap = new Map<Id,Id>();
        Map<Id,Id> geoMap = new Map<Id,Id>();
        Map<Id,Contract> conMap = new Map<Id,Contract>();
        Map<Id,Decimal> msMap = new Map<Id,Decimal>();
        Id recordType = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get(System.Label.ECM_CVContractsRecType).getRecordTypeId();
        
        //145098
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        
        for(ContentDocumentLink conDocLnk: cdLinkList){
            if(conDocLnk.LinkedEntityId.getSobjectType() == Contract.sObjectType){
                linkMap.put(conDocLnk.ContentDocumentId,conDocLnk);
                conDocMap.put(conDocLnk.ContentDocumentId,conDocLnk.LinkedEntityId);
            }
        }
        //145098
        if(!conDocMap.isEmpty()){
            for(ContentVersion conVer: [SELECT Id,ContentDocumentId,Content_Type__c,ECM_Customer_Signed_Date__c,RecordTypeId FROM ContentVersion WHERE ContentDocumentId IN:conDocMap.keySet() AND RecordTypeId =:recordType AND Content_Type__c=:label.ECM_SignedContract with SECURITY_ENFORCED]){
                contentVersionList.add(conVer);
            }
        }
        if(!contentVersionList.isEmpty()){
            List<String> recordTypes = System.label.ECM_ContractRecordTypes.split(',');
            for(Contract con: [SELECT Id,Account.Country__c,AccountId,StartDate,CreatedDate FROM Contract WHERE Id IN:conDocMap.values() AND RecordType.Name IN:recordTypes]){
                geoMap.put(con.Id,con.Account.Country__c);
                conMap.put(con.Id,con);
            }
            if(geoMap.size()>0){
                for(Market_Setting__c ms: [SELECT Id,Geography__c,ECM_Max_Days_to_upload_Signed_PDF__c FROM Market_Setting__c WHERE Geography__c IN: geoMap.Values() with SECURITY_ENFORCED]){
                    msMap.put(ms.Geography__c,ms.ECM_Max_Days_to_upload_Signed_PDF__c);
                }
            }
            if(!contentVersionList.isEmpty()){
                for(ContentVersion conVer: contentVersionList){
                    Id linkedEntityId = conDocMap.containsKey(conVer.ContentDocumentId)?conDocMap.get(conVer.ContentDocumentId):null;
                    Id geoId = linkedEntityId!=null&&geoMap.containsKey(linkedEntityId)?geoMap.get(linkedEntityId):null;
                    Decimal maxDays = geoId!=null&&msMap.containsKey(geoId)?msMap.get(geoId):null;
                    if(maxDays!=null && conMap.containsKey(linkedEntityId)){
                        Date conStartDate = conMap.get(linkedEntityId).StartDate;
                        Date conCreatedDate = conMap.get(linkedEntityId).CreatedDate.date();
                        if((conStartDate>=conCreatedDate)&&(conStartDate.daysBetween(Date.today())>maxDays)){
                            linkMap.get(conVer.ContentDocumentId).addError(Label.ECM_ValidateSignedContract);
                        }
                    }
                }
            }
        }
        
        
    }
    /*
@description : onAddingContractAttachment - Calls method to send mail with relevant PDF attached: ECM-5900 & ECM-5901
@return : void
@param : Map<Id,SObject>
*/
    public static void onAddingContractAttachment(Map<Id,SObject> newItems) {
        Map<Id,ContentDocumentLink> signedPDFDocuments = new Map<Id,ContentDocumentLink>();
        Map<Id,ContentDocumentLink> assetPDFDocuments = new Map<Id,ContentDocumentLink>();
        //145098
        set<Id> conDocLinkIds = new set<Id>();
        
        // First we filter out those attachments (content documents) that pertain to Contracts
        for(ContentDocumentLink conObj : (List<ContentDocumentLink>)newItems.values()){
            if(conObj.LinkedEntityId.getSObjectType() == Contract.sObjectType ){
                conDocLinkIds.add(conObj.Id);           
            }            
        }
        
        // Once we have the list of these attachments we fetch their related Content Document Links
        if(!conDocLinkIds.isEmpty()){
            for(ContentDocumentLink objConDocLink :[SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId, 
                                                    ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.RecordTypeId, 
                                                    ContentDocument.LatestPublishedVersion.RecordType.Name, ContentDocument.LatestPublishedVersion.RecordType.DeveloperName, ContentDocument.LatestPublishedVersion.CreatedDate,
                                                    ContentDocument.LatestPublishedVersion.Content_Type__c
                                                    FROM ContentDocumentLink 
                                                    WHERE ID IN : conDocLinkIds])
            { 
                if(objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == System.Label.ECM_CVContractsRecType){
                    if(objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c == 'Signed Contract'){
                        signedPDFDocuments.put(objConDocLink.LinkedEntityId,objConDocLink);
                    }
                    else if(objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c == 'Asset PDF'){
                        assetPDFDocuments.put(objConDocLink.LinkedEntityId,objConDocLink);
                    }
                }
            }
        }
        
        // Here we fetch the contract data for each PDF and send the mails
        if(!signedPDFDocuments.isEmpty()) {
            sendMailForAttachments(signedPDFDocuments, false);
        } else if(!assetPDFDocuments.isEmpty()) {
            sendMailForAttachments(assetPDFDocuments, true);
        }
        
    }
    
    /*
@description : sendMailForAttachments - Handles sending of mail for both Signed Contract PDFs and Asset PDFs: ECM-5900 & ECM-5901
@return : void
@param : Map<Id,ContentDocumentLink>, Boolean
*/   
    public static void sendMailForAttachments(Map<Id,ContentDocumentLink> documents, Boolean isAssetPDF) {
        List<Contract> contractsList = new List<Contract>();
        Map<String,List<String>> mailingList = new Map<String,List<String>>();
        EmailTemplate template = new EmailTemplate();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        String mailTemplateString = '';
        Map<String,EmailTemplate> templateMap = new Map<String,EmailTemplate>();
        
        // Filter out unnecessary record types: Asset PDFs only get sent for Asset Contracts, Signed Contrcat PDFs only get sent for Outlet, Group & Asset Contracts
        List<String> recordTypes = new List<String>();
        if(isAssetPDF) {
            recordTypes.add('Asset Contract');
        } else {
            recordTypes.addAll(Label.ECM_SignedContractRecordTypes.split(','));
        }
        
        contractsList = [SELECT Id, Account.Email_for_contracts_payments__c,
                         Account.Country_Code__c, Owner.Email, Account.Person_Responsible__c,
                         Account.Person_Responsible__r.Email, RecordType.Name, ECM_Digitally_Signed__c,
                         Owner.Name, Account.Name, Owner.IsActive, ECM_Type_of_Contract__c,
                         ECM_Agreement_Type__r.ECM_Contract_Approval_mail_to_Customer__c
                         FROM Contract
                         WHERE Id IN :documents.keySet()
                         AND RecordType.Name IN :recordTypes];
        
        // Set the relevant template name prefix for creating map
        mailTemplateString = isAssetPDF ? '%ECM_AssetContractMailTemplate%' : '%ECM_SignedContractMailTemplate%';
        
        if (!contractsList.isEmpty()) {
            
            // Create Template Map using template name prefix
            templateMap = createTemplateMap(mailTemplateString);
            
            for (Contract conObj : contractsList) {
                // Only create and send mails if it is a Signed Contract PDF & ECM_Digitally_Signed__c has 'Without OTP' or 'OTP Used' value, 
                // or if the ECM_Contract_Approval_mail_to_Customer__c field is checked in case it is an Asset PDF
                //ECM-6149
                //Label modification added by Wribhu
                
                if((!isAssetPDF && String.isNotBlank(conObj.ECM_Digitally_Signed__c) 
                    && Label.ECM_SignedContractDigitallySignedValues.contains(conObj.ECM_Digitally_Signed__c)) ||
                   (isAssetPDF && conObj.ECM_Agreement_Type__r.ECM_Contract_Approval_mail_to_Customer__c)) {
                       
                       List<Id> attachments = new List<Id>();
                       attachments.add(documents.get(conObj.Id).ContentDocument.LatestPublishedVersionId);
                       
                       // Fetch the exact related template
                       template = fetchEmailTemplate(templateMap,conObj.Account.Country_Code__c);
                       maiLingList = createMailingLists(conObj);
                       
                       // Form and send the mail
                       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                       mail = createMail(mailingList, template.Id, conObj.Id, attachments);
                       
                       // Reply To is only needed for Asset PDFs - ECM-5900
                       if(isAssetPDF) {
                           mail.setReplyTo(Label.ECM_CustomerResponseEmailServiceAddress);
                       } else {
                           mail.setSaveAsActivity(true); // ECM-6107
                       }
                       
                       mails.add(mail);
                   }
            }
        }
        
        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails);
        }
    }
    
    /*
@description : createTemplateMap - Fetches email templates and creates map: ECM-5900 & ECM-5901
@return : Map<String,EmailTemplate>
@param : String
*/ 
    public static Map<String,EmailTemplate> createTemplateMap(String templateLike) {
        Map<String,EmailTemplate> emailTempMap = new Map<String,EmailTemplate>();
        
        for(EmailTemplate templtObj : [SELECT Body, BrandTemplateId, Description, FolderName, Id, Name, Subject 
                                       FROM EmailTemplate 
                                       WHERE Name 
                                       LIKE :templateLike])
        {
            if(templtObj.Name.contains('_')){
                // Here we create a map of country codes and related templates. 'EN' is the default country code linked to English templates
                String cc = templtObj.Name.substringAfterLast('_').trim();
                emailTempMap.put(cc,templtObj);
            }
        }
        return emailTempMap;
    }
    
    /*
@description : fetchEmailTemplate - Returns the relevant email template based on country code: ECM-5900 & ECM-5901
@return : EmailTemplate
@param : Map<String,EmailTemplate>, String
*/ 
    public static EmailTemplate fetchEmailTemplate(Map<String,EmailTemplate> emailTempMap, String countryCode) {
        
        if(emailTempMap.keySet().contains(countryCode)){
            return emailTempMap.get(countryCode);
        } else {
            return emailTempMap.get('EN');
        }
    }
    
    /*
@description : createMailingLists - Creates mailing lists: List of "to" and "cc" addresses: ECM-5900 & ECM-5901
@return : Map<String,List<String>>
@param : Contract
*/ 
    public static Map<String,List<String>> createMailingLists(Contract conObj) {
        Map<String,List<String>> mailingList = new Map<String,List<String>>();
        List<String> mToMail = new List<String>(); 
        List<String> mCCMail = new List<String>();
        
        if(String.isNotBlank(conObj.Account.Email_for_contracts_payments__c)){
            mToMail.add(conObj.Account.Email_for_contracts_payments__c);
        }
        
        // For Outlet Type: CC is the Contract Owner/Sales Rep and for Group Type: Person Responsible
        if((conObj.RecordType.Name == 'Outlet' ||
            (conObj.RecordType.Name == 'Asset Contract' && conObj.ECM_Type_of_Contract__c == 'Outlet'))
           && String.isNotBlank(conObj.Owner.Email)
           && conObj.Owner.IsActive)
        {
            mCCMail.add(conObj.Owner.Email);
        } else if((conObj.RecordType.Name == 'Group' ||
                   (conObj.RecordType.Name == 'Asset Contract' && conObj.ECM_Type_of_Contract__c == 'Group'))
                  && String.isNotBlank(conObj.Account.Person_Responsible__r.Email))
        {
            mCCMail.add(conObj.Account.Person_Responsible__r.Email);
        }
        
        mailingList.put('To',mToMail);
        mailingList.put('Cc',mCCMail);
        return mailingList;
    }
    
    /*
@description : createMail - Returns the mail that gets sent: ECM-5900 & ECM-5901
@return : Messaging.SingleEmailMessage
@param : Map<String,List<String>>, Id, Id, List<Id>
*/     
    public static Messaging.SingleEmailMessage createMail(Map<String,List<String>> mailingList, Id templateId, Id contractId, List<Id> attachments) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(maiLingList.get('To'));
        mail.setCcAddresses(maiLingList.get('Cc'));
        
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(userinfo.getuserid());
        mail.setWhatId(contractId);
        mail.setEntityAttachments(attachments);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setSaveAsActivity(false);
        
        return mail;
    }
    /**
* @description : checkFeedItem - This is used to check if Content Document is from AccountFeed and restrict trigger to 	prevent governor limit issue
* @return : void
* @param newItems 
*/
    public static void checkFeedItem(List<ContentDocumentLink> newItems) {
        Set<Id> linkedEntityIdList=new Set<Id>();
        List<AccountFeed> feedAttach = new List<AccountFeed>();
        for(ContentDocumentLink objConDocLink : newItems) {
            //145098
            if(objConDocLink.LinkedEntityId != null && objConDocLink.LinkedEntityId.getSObjectType() == Account.SObjectType)
            {
                linkedEntityIdList.add(objConDocLink.LinkedEntityId);
            }
        }
        //145098
        if(!linkedEntityIdList.isEmpty()){
            feedAttach=[SELECT Id from AccountFeed where ParentId IN:linkedEntityIdList with SECURITY_ENFORCED];
        }
        if(feedAttach.size()>0){
            ContentDocumentLinkTriggerHandler.triggerDisabled=True;
        }
    }
    
    //Added as part of ECM-6787
    /**
* @description : uncheckPsInvoiceAttachment - This is used to update payment summary
* @return : void
* @param newItems 
*/
    public static void uncheckPsInvoiceAttachment(List<ContentDocumentLink> oldItems){
        Set<Id> psIdSet = new Set<Id>();
        set<Id> contectDocIds = new set<Id>();
        
        for(ContentDocumentLink cdl:oldItems){
            contectDocIds.add(cdl.ContentDocumentId);
        }
        //145098
        for(ContentDocumentLink  objConDocLink : 
            [Select Id, LinkedEntityId,ContentDocumentId,
             ContentDocument.LatestPublishedVersion.RecordType.DeveloperName,
             ContentDocument.LatestPublishedVersion.Content_Type__c
             FROM ContentDocumentLink 
             WHERE ContentDocumentId IN :contectDocIds WITH SECURITY_ENFORCED]) {
                 if(objConDocLink.LinkedEntityId.getSObjectType() == ECM_Payment_Summary__c.sObjectType && 
                    objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == PAYMENT_SUMMARY_RECORD_TYPE){
                        psIdSet.add(objConDocLink.LinkedEntityId);
                    }
             }  
        if(!psIdSet.isEmpty()){
            EDGE_ContentDocumentTriggerHelper.updatePsInvoiceAttachment(psIdSet);
        }
    }
    
}