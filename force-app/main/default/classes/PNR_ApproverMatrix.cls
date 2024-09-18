/**
Name: PNR_ApproverMatrix
--
Req:  
User Story : PION-115 - SF Providing relevant approvers in drop down - Approval Flow 3
--
History                                                            
--                                                           
VERSION   AUTHOR            DATE              DETAIL
1.0 	Tanmoy Bardhan	 22/08/2019      	Created 
2.0     Saurav Paul		 03/03/2020			Modified logic for SendToSAP
3.0     Pratik Kumar     20/06/2022         fetchApproverEmail()-Added if conditions for CE01 market
**/
public with sharing class PNR_ApproverMatrix {
    @AuraEnabled
    public static Boolean updateEmailAdd(String recordId, String emailAddress){
        Correction_Document__c corDoc;
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            corDoc = [SELECT Id,Approver_Email__c FROM Correction_Document__c WHERE ID = :recordId];
        }
        
        Correction_Document__c cDoc = new Correction_Document__c();
        cDoc.Id = recordId;
        if(String.isNotBlank(corDoc.Approver_Email__c)){
            cDoc.Previous_Approver_Email__c = corDoc.Approver_Email__c;
            cDoc.Approver_Email__c = emailAddress;
        }else{
            cDoc.Approver_Email__c = emailAddress;
        }
        
        Database.SaveResult sRec = Database.update(cDoc, false);
        if(sRec.isSuccess()){
            return true;
        }else{
            return false;
        }
    }
    
    /*Start: Phase 2 Development*/
    @AuraEnabled
    public static List<String> fetchApproverEmail(String recordId){
        List<String> approverEmailList = new List<String>();
        List<Correction_Document__c> cDocList = new List<Correction_Document__c>();
        List<Approver_Matrix__c> appMatList = new List<Approver_Matrix__c>();
        List<Approver_Matrix__c> fileteredAppMatList = new List<Approver_Matrix__c>();
        List<PNR_Partner_Function__c> partnerFuncList = new List<PNR_Partner_Function__c>();
        List<String> salesOfficeList = new List<String>();
        
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            cDocList = [SELECT Sales_Org__c, Claimed_Amount__c,Document_Type__c,CurrencyIsoCode, Case__r.Owner.Email,
                        Case__r.CurrencyIsoCode, Case__r.Claimed_Amount__c, CreatedBy.Email, LastModifiedBy.Email, Case__r.AccountId
                        FROM Correction_Document__c
                        WHERE ID = :recordId];
        }
        //PION-2238 : changes made to fetch the approver email if the sales office is populated in ship-to partner function and approver matrix.
        //            If the sales office is not present in either partner function or approver matrix then approver emails are fetached based on the sales org.
        partnerFuncList = [SELECT PNR_Sales_Office__c 
                           FROM PNR_Partner_Function__c
                           WHERE PNR_Sold_To__c = :cDocList[0].Case__r.AccountId AND PNR_Sales_Office__c != NULL 
                           AND PNR_Type__c = 'Ship-To'
                          ];
        for(PNR_Partner_Function__c pf : partnerFuncList){
            salesOfficeList.add(pf.PNR_Sales_Office__c);
        }
        if(Schema.sObjectType.Approver_Matrix__c.isAccessible()){
            appMatList = [SELECT Approver_Email__c, Amount__c, Sales_Org__c,Min_Limit_Amount__c,Max_Limit__c,
                          Matrix_Status__c, Approval_Category__c,CurrencyIsoCode,PNR_Sales_Office__c
                          FROM Approver_Matrix__c
                          WHERE (PNR_Sales_Office__c IN :salesOfficeList OR Sales_Org__c like :cDocList[0].Sales_Org__c + '%') 
                          AND Matrix_Status__c = 'Enabled'
                          AND (Approval_Category__c = 'Credit/Debit approval' OR Approval_Category__c = 'Return order approval')];
        }
        
        System.debug('appMatList size===>'+appMatList.size());
       //  System.debug('appMatList size===>'+appMatList[0].Approver_Email__c);
        //Currency Conversion Logic
        MAP<String,decimal> mapcurrencyType = new MAP<String,decimal>();
        List<CurrencyType> currencyList = new List<CurrencyType>();
        
        if(Schema.sObjectType.CurrencyType.isAccessible()){
            currencyList = [SELECT ConversionRate,DecimalPlaces,Id,IsCorporate,IsoCode FROM CurrencyType];
        }
        for(CurrencyType record: currencyList){
            mapcurrencyType.put(record.IsoCode,record.ConversionRate);
        }
        
        if(!appMatList.isEmpty()){
            for(Approver_Matrix__c app : appMatList){
                boolean isSuccess = currencyConversion(app.Min_Limit_Amount__c, app.Max_Limit__c, app.CurrencyIsoCode, cDocList[0].Case__r.CurrencyIsoCode, cDocList[0].Case__r.Claimed_Amount__c,mapcurrencyType);
                if(isSuccess){
                    fileteredAppMatList.add(app);
                }
            }
        }
        System.debug('fileteredAppMatList size===>'+fileteredAppMatList.size());
        if(!fileteredAppMatList.isEmpty()){
            for(Approver_Matrix__c app : fileteredAppMatList){
                System.debug('cDocList[0].CreatedBy.Email '+cDocList[0].CreatedBy.Email+' app.Approver_Email__c:: '+app.Approver_Email__c);
                System.debug('app.Sales_Org__c.substring(0,4):: '+app.Sales_Org__c.substring(0,4)+' cDocList[0].Sales_Org__c:: '+cDocList[0].Sales_Org__c);
                System.debug('cDocList[0].LastModifiedBy.Email:: '+cDocList[0].LastModifiedBy.Email+' app.Approver_Email__c:: '+app.Approver_Email__c);
                if(cDocList[0].CreatedBy.Email != app.Approver_Email__c &&
                   app.Sales_Org__c.substring(0,4) == cDocList[0].Sales_Org__c &&
                   cDocList[0].LastModifiedBy.Email != app.Approver_Email__c){
                       //correction doc record record owner's email should not come in approver's email
                       if(cDocList[0].Document_Type__c == 'YRET'){
                           if(app.Approval_Category__c == 'Return order approval'){
                                //PION-2403 start
                                System.debug('HERE:: '+app.Sales_Org__c.substring(0,4)+'  '+app.PNR_Sales_Office__c);
                               if(app.Sales_Org__c.substring(0,4) == 'CE01' && (app.PNR_Sales_Office__c != '' || app.PNR_Sales_Office__c != null) && salesOfficeList.contains(app.PNR_Sales_Office__c)){
                                    approverEmailList.add(app.Approver_Email__c);
                               }else if(app.Sales_Org__c.substring(0,4) != 'CE01'){
                                    approverEmailList.add(app.Approver_Email__c);
                               }  //PION-2403 end
                           }
                           
                       }
                       else
                       {
                           if(app.Approval_Category__c == 'Credit/Debit approval'){
                                //PION-2403 start
                                System.debug('HERE:: '+app.Sales_Org__c.substring(0,4)+'  '+app.PNR_Sales_Office__c);
                                if(app.Sales_Org__c.substring(0,4) == 'CE01' && (app.PNR_Sales_Office__c != '' || app.PNR_Sales_Office__c != null) && salesOfficeList.contains(app.PNR_Sales_Office__c)){
                                    approverEmailList.add(app.Approver_Email__c);
                                }else if(app.Sales_Org__c.substring(0,4) != 'CE01'){
                                    approverEmailList.add(app.Approver_Email__c);
                                } //PION-2403 end
                           }
                           
                       }
                       
                   }
            }
        }
        return approverEmailList;
    }
    private static Boolean currencyConversion(Decimal minAmount, Decimal maxAmount, String appCurrencyCode,String corCurrencyCode,Decimal corAmount, MAP<String,decimal> mapcurrencyType){
        boolean isSuccess = false;
        
        //List<CurrencyType> currencyList = new List<CurrencyType>();
        //MAP<String,decimal> mapcurrencyType = new MAP<String,decimal>();
        
        //if(Schema.sObjectType.CurrencyType.isAccessible()){
        // currencyList = [SELECT ConversionRate,DecimalPlaces,Id,IsCorporate,IsoCode FROM CurrencyType];
        // }
        //for(CurrencyType record: currencyList){
        // mapcurrencyType.put(record.IsoCode,record.ConversionRate);
        // }
        
        if(appCurrencyCode == corCurrencyCode){
            if(corAmount!= Null){
                if(minAmount <= corAmount && maxAmount >= corAmount){
                    isSuccess = true;
                }
            }
        }
        else{
            if(corAmount!= Null){
                decimal cFactorCorCurrency = mapcurrencyType.get(corCurrencyCode);
                decimal cFactorAppCurrency = mapcurrencyType.get(appCurrencyCode);
                decimal convertedCorAmount = corAmount/cFactorCorCurrency;
                decimal convertedMinAmount = minAmount/cFactorAppCurrency;
                decimal convertedMaxAmount = maxAmount/cFactorAppCurrency;
                System.debug('==appCurrencyCode=='+appCurrencyCode+'==cFactorCorCurrency===' +cFactorCorCurrency +'==cFactorAppCurrency==' +cFactorAppCurrency +'==convertedCorAmount=='+convertedCorAmount+'==convertedMinAmount=='+convertedMinAmount);
                if(convertedMinAmount <= convertedCorAmount && convertedMaxAmount >= convertedCorAmount){
                    isSuccess = true;
                }
            }
            
        }
        
        return isSuccess;
    }
    /*End: Phase 2 Development*/
    @AuraEnabled
    public static Boolean validateApproverEmail(String recordId, String emailAddress){
        List<String> approverEmailList = fetchApproverEmail(recordId);
        Boolean isContains = approverEmailList.contains(emailAddress);
        return isContains;
    }
    
    @AuraEnabled
    public static string getCorDocApproverEmail(String recordId){
        Correction_Document__c appEmail = [SELECT Id,Approver_Email__c FROM Correction_Document__c WHERE ID = :recordId];
        return appEmail.Approver_Email__c;
    }
    @AuraEnabled
    public static void sendToSap(Id DocId){
        Set<Id> corrDocId = new Set<Id>();
        corrDocId.add(DocId);
        // PNR_CorrDocuTriggerHelper.getDocLineItems(corrDocId);
        PNR_CorrDocuTriggerHelper.getCorDocLineItems(corrDocId);
    }
    @AuraEnabled
    public static Boolean checkTL(){
        Id userProfileId = UserInfo.getProfileId();
        Id tlProfileId = [SELECT Id,Name FROM Profile WHERE Name = 'PNR_TeamLead'].Id;
        if(userProfileId == tlProfileId){
            return true;
        }else{
            return false;
        }
    }
    @AuraEnabled
    public static Boolean checkDataSentToSAP(String recordId){
        Boolean dataSentSAP = False;
        List<Correction_Document__c> cDocList = new List<Correction_Document__c>();
        cDocList = [SELECT Id,Data_Send_to_SAP__c,Status__c,SAP_Document_Number__c FROM Correction_Document__c WHERE Id = :recordId];
        if(!cDocList.isEmpty()){
            if((cDocList[0].Status__c != 'Approved' || cDocList[0].Status__c != 'Externally Approved') 
               && (cDocList[0].Data_Send_to_SAP__c == True || String.isNotBlank(cDocList[0].SAP_Document_Number__c))){
                   dataSentSAP = true;
               }else{
                   dataSentSAP = false;
               }
        }
        return dataSentSAP;
    }
    @AuraEnabled
    public static Boolean valStatus(Id DocId){
        List<Correction_Document__c> docList = new List<Correction_Document__c>();
        docList = [SELECT Id,Status__c FROM Correction_Document__c WHERE Id =: DocId];
        if(docList[0].Status__c.equalsIgnoreCase('Externally Approved') 
           || docList[0].Status__c.equalsIgnoreCase('Externally Approved With Change')){
               return true;
           }else{
               return false;   
           }
    }
    @AuraEnabled
    public static String createRequestByTL(String recordId)
    {
        
        String msg ='There is some issue reported. Please contact System Administrator.';
        Id userProfileId = UserInfo.getProfileId();
        Id tlProfileId = [SELECT Id,Name FROM Profile WHERE Name = 'PNR_TeamLead' ].Id;
        
        System.debug('userProfileId---'+userProfileId);
        System.debug('tlProfileId---'+tlProfileId);
        if(userProfileId != tlProfileId){
            msg = System.Label.PNR_NotTeamLead;
            return msg;
        }
        Boolean dataSentSAP = False;
        List<Correction_Document__c> cDocList = new List<Correction_Document__c>();
        cDocList = [SELECT Id,Data_Send_to_SAP__c, Approver_Email__c, Status__c,SAP_Document_Number__c, PNR_Request_Sent_by_TL__c FROM Correction_Document__c WHERE Id =:recordId];
        if(!cDocList.isEmpty()){
            if(cDocList[0].PNR_Request_Sent_by_TL__c == True){
                msg = 'Request to create Correction Document has already submitted by the TL';
                return msg;
            }
            if(cDocList[0].Data_Send_to_SAP__c == True && String.isNotBlank(cDocList[0].SAP_Document_Number__c)){
                msg = System.Label.PNR_DataSentToSAP;
                return msg;
            }
            else
            {
                if(!cDocList[0].Status__c.equalsIgnoreCase('Externally Approved With Change'))
                {
                    msg = System.Label.PNR_InvalidStatus;
                    return msg;
                }
                else
                {
                    if( cDocList[0].Approver_Email__c != null)
                    {
                        List<String> approverEmailList = fetchApproverEmail(recordId);
                        Boolean isContains = approverEmailList.contains(cDocList[0].Approver_Email__c);
                        if(!isContains)
                        {
                            msg = System.Label.PNR_InvalidApproverEmail;
                            return msg;
                        }
                        else
                        {
                            try
                            {
                                sendToSap(recordId);
                                cDocList[0].PNR_Request_Sent_by_TL__c = True;
                                update cDocList[0];
                                msg = 'Data has been sent to SAP. Please check the status in some time.';
                                return msg;
                            }
                            catch(Exception e)
                            {
                                msg = e.getMessage();
                                return msg;
                            }
                        }
                    }
                    else
                    {
                        msg = System.Label.PNR_ValidApproverEmail;
                        return msg;
                    }
                }
                
            }
            
        }
        return msg;
    }
    
}