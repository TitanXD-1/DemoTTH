/*
* @Description: EDGE_TransferOrderStatusHelper

* @Purpose: Helper Class 

* @History:                                                            
                                                           
* @VERSION       AUTHOR             DATE           DETAIL
*    1.0     Monalisa Halder     17/06/2021       ES20-9974 
*    2.0     Manikant Prasad     17/06/2021       ES20-9976
*    3.0     Debolina/Mayukh     09/05/2022       ES20-12543
*	 4.0	 Rajarshi Lahiri	 10/05/2022		  ES20-12641
*	 5.0	 Rajarshi Lahiri	 13/05/2022		  ES20-12728
*	 6.0	 Rajarshi Lahiri	 17/08/2022		  ES20-13154
*    7.0     Mayukh S Roy        27/06/2023       291561 - VF rendering based on Language 
**/
public  class EDGE_TransferOrderStatusHelper {
    public static Map<String,List<Order_Item__c>> orderListOrderItemMap = new Map<String,List<Order_Item__c>>();
    public static Map<Id, Account> mapOrderShedAccount = new Map<Id, Account>();
    public static String languageName = '' ;
    public static Map<String, String> labelToTranslatedStrMap = new Map<String, String>();
    public static List<Order__c> wholeOrderList = new List<Order__c>();
    
    
    public static void setOrderDetails(Set<Id> orderIdSet, Boolean isBatch,String languageName){
        System.debug(loggingLevel.Debug,'@@languageName '+languageName);
        //string countryCode = '';
        List<Order_Item__c> orderItemList = new List<Order_Item__c>();
        Set<Id> allOrderSet = new Set<Id>();
        String freeGoodOrderRTId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        List<String> lstRecordTypeId = new List<String>();
        lstRecordTypeId.add(Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId());
        lstRecordTypeId.add(freeGoodOrderRTId);
        List<Id> lstSalesRepId = new List<Id>();
        List<String> countryCodeList = new List<String>();
        List<Order__c> orderList =  new List<Order__c>();
        
        if(orderIdSet.size() > 0){
            orderList = [Select Id,Name, RecordTypeId,Status__c,Account__r.Outlet_Email_Address__c,Delivery_Location__c,Order_Group__c,Wholesaler__c,Wholesaler__r.Outlet_Email_Address__c,Account__c,
                         Account__r.name,Wholesaler__r.Name,Wholesaler_Account_Number__c, Account__r.BillingStreet,Account__r.BillingState,Account__r.BillingCity,Account__r.BillingCountry,
                         Account__r.BillingPostalCode, Account__r.RecordTypeId,Account__r.Country__c,Account__r.Country__r.Name, Preferred_Delivery_Date__c, Next_Delivery_Date__c, Sales_Representative__c,
                         Source_Application__c,Contact__r.MobilePrefix__c,Contact__r.Mobile__c,Contact__c,Contact__r.Email,Country_Code__c,Sales_Representative__r.Name ,Sales_Representative__r.Email,
                         Sales_Representative__r.Mobile_Number__c,Comments__c,Signature_Image_Version_Id__c,Is_Promo_Transfer_Order__c FROM Order__c 
                         WHERE  RecordTypeId IN :lstRecordTypeId ANd ID IN: orderIdSet];  
        }
        if(isBatch){
            languageName = languageName;
        }else {
            languageName =  null;   
        }
        System.debug(loggingLevel.Debug,'@@languageName '+languageName);
        wholeOrderList = orderList;
        // updated NCP-2677 Source_Application__c,Contact__r.MobilePrefix__c,Contact__r.Mobile__c
        
        if(orderList !=null && orderList.size()>0){
            //Added Product Name of MAP and Customer Facing Description as part of ES20-12641
            //Added SAP SKU Code of Product as part of ES20-12728
            //ES20-13154 Added Promotion Product Related fields in Query
            orderItemList = [Select Id,Product__c,RecordTypeId,Product__r.Name,Product__r.Long_Description__c,Order__c,
                             Quantity__c,Selected_UoM__c,Market_Assortment_Product__r.Product__r.Name,
                             Market_Assortment_Product__r.D1_Product_Name__c,Product__r.SAP_SKU_Code__c,
                             Promotion_Product__c,Promotion_Product__r.Promotion__c,Promotion_Product__r.Promotion__r.Name,
                             Promotion_Product__r.Product__r.Product_Full_Name__c,
                             Promotion_Product__r.Promotion__r.Discount_for_promotion__c,
                             Promotion_Product__r.Product__r.SAP_SKU_Code__c,//come back
                             Promotion_Product__r.Promo_Transfer_Order_Used_UOM__c,
                             Promotion_Product__r.RecordTypeId,Promotion_Product__r.Promotion__r.RecordType.Name
                             from Order_Item__c where Order__c IN :orderList] ;
            
            //Check whether there is any Free Good Order whose Delivery location is "Shed"
            for(Order__c ordObj : orderList){
                if(ordObj.RecordTypeId == freeGoodOrderRTId && ordObj.Delivery_Location__c == 'Shed'){
                    lstSalesRepId.add(ordObj.Sales_Representative__c);                                                
                }                    
            }
            
            //Get the Shed Type of Account Address for that Sales Rep
            if(lstSalesRepId != null && lstSalesRepId.size()>0){
                String accountRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
                for(AccountShare accountTeamMem : [SELECT AccountId, Account.Name, Account.BillingStreet,Account.BillingState,Account.BillingCity,Account.BillingCountry, Account.BillingPostalCode, UserOrGroupId
                                                   FROM AccountShare
                                                   WHERE UserOrGroupId IN :lstSalesRepId AND Account.RecordTypeId =:accountRecordTypeId]){
                                                       Account account = new Account(Id=accountTeamMem.AccountId);
                                                       account.BillingStreet = accountTeamMem.Account.BillingStreet;
                                                       account.BillingState = accountTeamMem.Account.BillingState;
                                                       account.BillingCity = accountTeamMem.Account.BillingCity;
                                                       account.BillingCountry = accountTeamMem.Account.BillingCountry;
                                                       account.BillingPostalCode = accountTeamMem.Account.BillingPostalCode;
                                                       mapOrderShedAccount.put(accountTeamMem.UserOrGroupId, account);                        
                                                   }
            }
            
            for(Order__c ordObj : orderList){                    
                allOrderSet.add(ordObj.Id);
                countryCodeList.add(ordObj.Country_Code__c);// Added by Manikant 
                if(ordObj.Order_Group__c!=null){
                    allOrderSet.add(ordObj.Order_Group__c);
                }
            }     
            
        }
        
        //Getting MArket setting record related to that country code of Order 
        Map<String,Boolean> countryMarketMap = new Map<String,Boolean>();
        if(countryCodeList.size() > 0){
            for(Market_Setting__c marketSetting : [Select Geography__r.code__C ,Display_Transfer_Order_Comments__c from Market_Setting__c where Geography__r.code__C IN :countryCodeList]){
                if(!countryMarketMap.containsKey(marketSetting.Geography__r.code__C)){
                    countryMarketMap.put(marketSetting.Geography__r.code__C,marketSetting.Display_Transfer_Order_Comments__c);
                }
            }                
        }
        
        //Updating Order Item
        if(orderItemList!=null && orderItemList.size()>0){
            for(Order_Item__c ordItemObj : orderItemList){       
                if(orderListOrderItemMap.containsKey(ordItemObj.Order__c)){
                    List<Order_Item__c> orderItmList = orderListOrderItemMap.get(ordItemObj.Order__c);
                    orderItmList.add(ordItemObj);
                    orderListOrderItemMap.put(ordItemObj.Order__c,orderItmList);
                }else{
                    orderListOrderItemMap.put(ordItemObj.Order__c,new List<Order_Item__c> {ordItemObj});
                }
                
            }
        }
        
        if(isBatch){
            //ES20-12543 - Added the label - EDGE_WholesalerName
            //ES20-12728 - Added the label - EDGE_ProductSKUId
			//ES20-13154 - Added the labels - 'EDGE_FreeProductsYesNo','EDGE_Promotion_Name','EDGE_Promotion_Type','EDGE_Discount_for_Promotion
            labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_AccountName', 'EDGE_AccountAdress', 'EDGE_EmailBody', 'EDGE_PrefOderDate','EGDE_ProductName','EDGE_ProductDescription','EDGE_ProductQuantity','EDGE_UOM','EDGE_OrderedProducts','EDGE_SubjectTO','EDGE_BatchSubjectTO','EDGE_NextDeliveryDate','EDGE_FreeProducts','EDGE_Sales_Rep_Name','EDGE_MobileNumber','EDGE_Email','EDGE_Order_Number','EDGE_OverallComment','D1_Customer_Contact_Name','EDGE_OrderSignature','EDGE_WholesalerName','EDGE_ProductSKUId','EDGE_FreeProductsYesNo','EDGE_Promotion_Name','EDGE_Promotion_Type','EDGE_Discount_for_Promotion'}, languageName); 

        }else{
            labelToTranslatedStrMap = null;
            mapOrderShedAccount = null;
        }
    }
    // Calling this method from trigger context 
    @future(callout=true)
    public static void sendPDFAsyc(Set<Id> orderIdSet, Boolean isBatch ,List<String> emailList ,String ordrAccnt){
        String language = UserInfo.getLanguage(); //291561 - Added Context user language - Sales Rep Locale
        Map<String,String> subjuectStringMap = new Map<String,String>{'triggerSubject'=>ordrAccnt};
            Map<String,List<String>> emailListString = new Map<String,List<String>>{'TriggerMailList'=>emailList};
                sendPDF(orderIdSet,isBatch,null,null,emailListString,subjuectStringMap,language); //291561 - Sending language as a parameter
    }
    public static void sendPDF(Set<Id> orderIdSet ,Boolean isBatch, Account Wholesaler , List<Messaging.Emailfileattachment> fileAttachments,Map<String,List<String>> emailListStringMap,Map<String,String> subjuectStringMap,String language){
        //Map<Id,String> wholesalerEmailMapRec;
        //List<String> emailList;
        Blob blobData;
        //languageName = language;
        PageReference pdf =  Page.EDGE_TransferOrderPDFMail;
        pdf.getParameters().put('orderListSTR', JSON.serialize(orderIdSet));
        pdf.getParameters().put('isBatch', JSON.serialize(isBatch));        
        pdf.getParameters().put('language', JSON.serialize(language)); 
        
        pdf.setRedirect(true);
        
        
        if(!test.isRunningTest()){
            blobData = pdf.getContent();
        }
        else{
            blobData=blob.valueOf('Test');  
        }
        
        // Added to send mail
        List<Messaging.EmailFileAttachment> allFileAttachment = new List<Messaging.EmailFileAttachment>();
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('Transfer Order Attachment.pdf');
        efa.setBody(blobData);
        allFileAttachment.add(efa);
        String todayDate = date.today().format();
        String mailSubject = '';
        if(isBatch){
            semail.setToAddresses( emailListStringMap.get('batchEmail'));
            semail.setTargetObjectId(wholesaler.CreatedById);
            allFileAttachment.addAll(fileAttachments);
            mailSubject = subjuectStringMap.get('BatchSubject') + ' ' + todayDate;
            semail.setHtmlBody(subjuectStringMap.get('BatchMailBody'));
        }else{
            semail.setToAddresses(emailListStringMap.get('TriggerMailList')); 
            mailSubject = Label.EDGE_SubjectTO;
            if(mailSubject.containsIgnoreCase('<Account Name>')){
                mailSubject = mailSubject.replace('<Account Name>',subjuectStringMap.get('triggerSubject'));
            }
            if(mailSubject.containsIgnoreCase('<dd-mm-yyyy>')){
                mailSubject = mailSubject.replace('<dd-mm-yyyy>',todayDate);
            }
            semail.saveAsActivity = False;
            semail.setHtmlBody(Label.EDGE_Transfer_Order_Body);
        }
        semail.setSubject(mailSubject); 
        semail.setFileAttachments(allFileAttachment);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
        
    }
}