/*
* @Name: ECM_PaymentSummaryToSAPCallout
* @description Callout to IPAAS for SAP integration from Salesforce
* @History                                                            
AUTHOR            DATE              DETAIL
Anivesh        	20/07/2020        ECM-1699(Initially)
Saurav Prasad  	06/10/2020		  ECM-2936
Keshav		   	21/10/2020        ECM-2935
Saurav Prasad  	29/10/2020		  ECM-2837,ECM-3058
chandrakanth   	25/05/2021		  ECM-4450
Saurav Prasad  	31/05/2021		  ECM-4493 - Internal order missing was triggering to Australian market.
Keshav		   	16/07/2021        ECM-4617,ECM-3195
Pratap Sen     	19/11/2021        ECM-4910 - Exclude zero-valued items in JSON payload
Saurav Paul    	07/12/2021        ECM-4934 - Dynamic Tax code value Populate
Veerendra       22/12/2021        ECM-4989 - Tech Debt_SAP Integration Class_GLO
Anamika Shukla  29/02/2024        EDGE Global: Mulesoft OAuth2 migration-358242
*/
public class ECM_PaymentSummaryToSAPCallout {
    public static final String ECM_SALESORDER_SAP = 'ECM_Mulesoft_SalesOrder_SAP';//358242
    
    public static Boolean materialVal = false;
    public static Boolean sapOrderReason = false;
    public static Boolean sapPlant = false;
    public static Boolean invoiceReceived = false;
    public static Boolean taxRate = false;
    public static Boolean paySum = false;
    public static Boolean recIOCode = false;
    public static Boolean prodName = false;
    public static Boolean sapPric = false;
    public static Boolean soldTo = false;
    public static Boolean curr = false;
    public static Boolean salesOrg = false;
    public static Boolean totRebate = false;
    public static Boolean conAmt = false;
    public static Boolean sapOrder = false;
    public static Boolean totAmtCon = false;
    public static Boolean sendSAPcall = true;
    public static String body = '';
    public static String payErrEmail='';
    public static String psName='';
    
    
    @future(callout = true)
    public static void getPaymentData(set<Id> payments){
        List<Integration_Log__c> errLogList = new List<Integration_Log__c>();
        Map<Id,List<ECM_Payment_Summary_Item__c>> paymentWithItems = new Map<Id,List<ECM_Payment_Summary_Item__c>>();
        Set<Id> pSIds = new Set<Id>();
        try{
            system.debug('=='+payments);
            List<ECM_Payment_Summary_Item__c> paymentSummaryItemsList = [Select Id,Name,ECM_Planned_Amount_Per_Payment__c,ECM_Total_Rebate__c,ECM_Contract_Item__r.ECM_Product__r.Product__c,ECM_Contract_Item__r.ECM_Product__r.Product__r.Name,
                                                                           ECM_Payment_Summary__c,ECM_Payment_Summary__r.ECM_Contract__r.Account.Sales_Org__c,ECM_Payment_Summary__r.ECM_Recommended_IO_Code__c,
                                                                           ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.Geography__c,ECM_Contract_Item__r.ECM_Product__r.Market_Assortment__r.ECM_SAP_Plant_for_Payment_File__c,
                                                                           ECM_Payment_Summary__r.ECM_Contract__r.Account.SAP_Sold_to__c,ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode,ECM_Payment_Summary__r.Name, ECM_Payment_Summary__r.ECM_Fiscal_Years__c,
                                                                           ECM_Payment_Summary__r.ECM_Invoice_Receival_Date__c,ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c,
                                                                           ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Order_reason__c,ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__r.name,
                                                                           ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__c,ECM_Payment_Summary__r.ECM_Contract__r.Account.Area__c,
                                                                           ECM_Payment_Summary__r.ECM_Tax_Rate__c,ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c,ECM_Payment_Summary__r.ECM_Budget_types__c,
                                                                           ECM_Contract_Item__r.ECM_Product__c,ECM_Contract_Item__r.ECM_UoM__c, ECM_Confirmed_Volume__c,ECM_Contract_Item__r.ECM_Product__r.Name,
                                                                           ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c,ECM_Contract_Item__r.ECM_Actual_Volume_YTD__c,
                                                                           ECM_Confirmed_Amount_Per_Payment__c,ECM_Roll_Over__c,
                                                                           ECM_Payment_Summary__r.ECM_Tax_Code__r.CST_SAP_Code__c,ECM_Payment_Summary__r.ECM_Type__c,//Modified for ECM-4934
                                                                           ECM_Internal_Order__r.Name, ECM_Internal_Order__c //ECM 6601
                                                                           From ECM_Payment_Summary_Item__c Where ECM_Payment_Summary__c IN:payments AND ECM_Confirm__c = true];
            

            List<ECM_Payment_Summary_Item__c> paymentItemsRecord =  New List<ECM_Payment_Summary_Item__c>();
           
            for(ECM_Payment_Summary_Item__c payItems : paymentSummaryItemsList){
                if((payItems.ECM_Payment_Summary__r.ECM_Type__c!='Non-Volume' && payItems.ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__r.name == 'Australia'  && payItems.ECM_Total_Rebate__c > 0) 
                   || (payItems.ECM_Payment_Summary__r.ECM_Type__c!='Non-Volume' && payItems.ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__r.name != 'Australia'  && payItems.ECM_Confirmed_Amount_Per_Payment__c > 0)){
                       
                       paymentItemsRecord.add(payItems);  
            }
            }
            if(paymentItemsRecord.size()>0){
                Set<String> UniqueIO = new Set<String>();
                List<String> psFisYearLst = new List<String>();
                Set<String> budgetTypeLst = new Set<String>();
                Set<String> prodIdLst = new Set<String>();
                Set<Id> geoAreaIdLst = new Set<Id>();
                Set<Id> countryIdLst = new Set<Id>();
                
                for(ECM_Payment_Summary_Item__c payItems : paymentItemsRecord){
                    if(payItems.ECM_Contract_Item__r.ECM_Product__r.Product__c!=Null){
                        prodIdLst.add(payItems.ECM_Contract_Item__r.ECM_Product__r.Product__c);                            
                    }
                    if(!String.isBlank(payItems.ECM_Payment_Summary__r.ECM_Budget_types__c))
                    {
                        budgetTypeLst.add(payItems.ECM_Payment_Summary__r.ECM_Budget_types__c);
                    }                    
                    if(!String.isBlank(payItems.ECM_Payment_Summary__r.ECM_Fiscal_Years__c))
                    {  
                        psFisYearLst.addall((payItems.ECM_Payment_Summary__r.ECM_Fiscal_Years__c).split('/'));
                    }
                    if(!String.isBlank(payItems.ECM_Payment_Summary__r.ECM_Contract__r.Account.Area__c)){
                        geoAreaIdLst.add(payItems.ECM_Payment_Summary__r.ECM_Contract__r.Account.Area__c);
                    }
                    if(!String.isBlank(payItems.ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__c)){
                        countryIdLst.add(payItems.ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__c);
                    }
                    if(paymentWithItems.containsKey(payItems.ECM_Payment_Summary__c)){
                        paymentWithItems.get(payItems.ECM_Payment_Summary__c).add(payItems);
                    }else{
                        paymentWithItems.put(payItems.ECM_Payment_Summary__c, new List<ECM_Payment_Summary_Item__c>{payItems});
                    }
                }
                List<ECM_Internal_Order__c> intOrdNoDupLst = new List<ECM_Internal_Order__c>(); 
                set<id> excludeProdId=new set<id>();
                for(ECM_Internal_Order__c internalOrder:[ SELECT Id,Name,ECM_Active__c,ECM_Budget_Amount__c,ECM_End_Date__c,
                                                         ECM_Fiscal_Year__c,ECM_Product__c,ECM_Start_Date__c,ECM_Auto_Assignment__c,ECM_Budget_Type__c,
                                                         ECM_Budget_Type_Pickup_Option__c,LastModifiedDate FROM ECM_Internal_Order__c
                                                         WHERE ECM_Product__c IN : prodIdLst AND ECM_Budget_Type_Pickup_Option__c IN :budgetTypeLst 
                                                         AND ECM_Fiscal_Year__c IN:psFisYearLst AND ECM_Active__c=true AND ECM_Auto_Assignment__c=true
                                                         AND ECM_Geography__c IN:geoAreaIdLst
                                                         ORDER BY LastModifiedDate DESC NULLS FIRST]){
                                                             intOrdNoDupLst.add(internalOrder);
                                                             excludeProdId.add(internalOrder.ECM_Product__c);   
                                                         }
                for(ECM_Internal_Order__c internalOrder:[ SELECT Id,Name,ECM_Active__c,ECM_Budget_Amount__c,ECM_End_Date__c,
                                                         ECM_Fiscal_Year__c,ECM_Product__c,ECM_Start_Date__c,ECM_Auto_Assignment__c,ECM_Budget_Type__c,
                                                         ECM_Budget_Type_Pickup_Option__c,LastModifiedDate FROM ECM_Internal_Order__c
                                                         WHERE ECM_Product__c IN : prodIdLst AND ECM_Budget_Type_Pickup_Option__c IN :budgetTypeLst 
                                                         AND ECM_Fiscal_Year__c IN:psFisYearLst AND ECM_Active__c=true AND ECM_Auto_Assignment__c=true
                                                         AND ECM_Geography__c IN:countryIdLst AND ECM_Product__c NOT IN:excludeProdId
                                                         ORDER BY LastModifiedDate DESC NULLS FIRST]){
                                                             intOrdNoDupLst.add(internalOrder);
                                                         }
                system.debug('internalOrder:'+intOrdNoDupLst);
                Map<Id,ECM_Internal_Order__c> internOrderMap = new Map<Id,ECM_Internal_Order__c>();
                for(ECM_Internal_Order__c inOrdObj : intOrdNoDupLst){
                    //Internal order Map
                    if(!internOrderMap.containsKey(inOrdObj.ECM_Product__c) && !UniqueIO.contains(inOrdObj.ECM_Product__c+'-'+inOrdObj.ECM_Budget_Type__c+'-'+inOrdObj.ECM_Fiscal_Year__c)){
                        internOrderMap.put(inOrdObj.ECM_Product__c,inOrdObj);
                        UniqueIO.add(inOrdObj.ECM_Product__c+'-'+inOrdObj.ECM_Budget_Type__c+'-'+inOrdObj.ECM_Fiscal_Year__c);
                    }                                     
                }
                List<ECM_Payment_Summary__c> updatePaymentSummary = new List<ECM_Payment_Summary__c>();
                
                for(Id pdId : payments){
                    ECM_Payment_Summary__c paymentSum = new ECM_Payment_Summary__c(Id=pdId);
                    string JSONPayload;
                    if(paymentWithItems.get(pdId).size()>0){
                        JSONPayload = fetchPayItemsJson(paymentWithItems.get(pdId),internOrderMap);
                    }                 
                    system.debug('JSONPayload:'+JSONPayload);
                     system.debug('sendSAPcall:'+sendSAPcall);
                    if(JSONPayload !=Null && sendSAPcall){

                        system.debug('inside JSONPayload:');

                        String respString = sendResponse(JSONPayload,'Payment Summary');//For Dummy Response getresp(pdId);
                        system.debug('Res from SAP='+respString);
                        String respMsg = respString.remove('{');
                        respMsg = respMsg.remove('}');
                        respMsg = respMsg.replaceAll('"','');
                        respMsg = respMsg.substringAfterLast(':');
                        if(String.isNotBlank(respString) && (respString.contains('ERROR') || respString.contains('ErrorResponse' ) || respString.contains('Duplicate'))){                  
                            Integration_Log__c logObj = new Integration_Log__c();
                            logObj.Error_Message__c = respMsg;
                            logObj.Interface_Name__c = 'Payment Summary';
                            logObj.Status__c = 'Failure';
                            logObj.Type_of_Object__c = 'Payment File';
                            logObj.Response__c = 'Error Occurred for Payment Summary Id : '+paymentSum.Id;
                            logObj.Request__c = jsonPayload;
                            errLogList.add(logObj);
                            paymentSum.ECM_Transmission_Status__c ='Fail';
                            paymentSum.ECM_Error_message__c = respMsg;
                            updatePaymentSummary.add(paymentSum);
                        }else if(String.isNotBlank(respString) && (respString.contains('SUCCESS') || respString.contains('successfully'))){
                            ECM_PaymentResponseParser ResWrap = ECM_PaymentResponseParser.Parser(respString);
                            system.debug('wrapRes:'+ResWrap);
                            if(paymentSum.Id == pdId){
                                // Changes for ECM-4989
                                Integration_Log__c logObj = new Integration_Log__c();

                                logObj.Error_Message__c = '';

                                logObj.Interface_Name__c = 'Payment Summary';
                                logObj.Status__c = 'Success';
                                logObj.Type_of_Object__c = 'Payment File';
                                logObj.Response__c = ResWrap.ResponseMessage;
                                logObj.Request__c = jsonPayload;
                                errLogList.add(logObj);
                                // End of Changes for ECM-4989
                                paymentSum.ECM_SAP_Credit_Note_Number__c =ResWrap.CreditNoteNumber==''?Null:integer.valueof(ResWrap.CreditNoteNumber);
                                paymentSum.ECM_SAP_Credit_Note_Creation_Date__c = ResWrap.CreditNoteCreationDate==''?Null:Date.valueOf(ResWrap.CreditNoteCreationDate);
                                paymentSum.ECM_Transmission_Status__c ='Success';
                                paymentSum.ECM_Error_message__c = '';
                                updatePaymentSummary.add(paymentSum);
                            }                                    
                        }
                    }
                }
                
                if(updatePaymentSummary.Size()>0){
                    update updatePaymentSummary;
                }
                
            }
        }
        catch(Exception Ex){
            system.debug('Error in getPaymentData:'+Ex);
        }
        if(!errLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()){
            insert errLogList;
        }
    }
    /*ECM - 2936 Non - volume Payment Summary */
    @future(callout = true)
    public static void getPaymentDataNonVolume(set<Id> payments){
        List<Integration_Log__c> errLogList = new List<Integration_Log__c>();
        Set<Id> pSIds = new Set<Id>();
        try{
            List<ECM_Payment_Summary__c> paymentRecords = 
                [SELECT ECM_Contract__r.Account.Sales_Org__c,ECM_Contract__r.Account.SAP_Sold_to__c,Id,ECM_Invoice_Receival_Date__c,
                 ECM_Budget_types__r.ECM_SAP_Order_reason__c,ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c,
                 ECM_Material_Tax_Classification__c,ECM_Budget_types__r.ECM_SAP_Pricing_condition__c,ECM_Recommended_IO_Code__c,Name,
                 ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode,ECM_Total_Amount_Confirmed__c,
                 ECM_SF_To_IPAAS_Time__c,ECM_Transmission_Status__c,ECM_Error_message__c,ECM_SAP_Credit_Note_Number__c,
                 ECM_SAP_Credit_Note_Creation_Date__c,ECM_Tax_Code__r.CST_SAP_Code__c//Modified for ECM-4934
                 FROM ECM_Payment_Summary__c
                 WHERE Id IN:payments AND ECM_Type__c='Non-Volume' AND ECM_Total_Amount_Confirmed__c > 0];
            List<ECM_Payment_Summary__c> updatePaymentSummary= new List<ECM_Payment_Summary__c>();
            if(paymentRecords.size()>0){
                for(ECM_Payment_Summary__c paymentSum: paymentRecords){
                    string JSONPayload;
                    JSONPayload=fetchPaymentJson(paymentSum);

                    system.debug('JSONPayload non volume :'+JSONPayload);
                    system.debug('sendSAPcall non volume :'+sendSAPcall);
                    if(JSONPayload !=Null && sendSAPcall){

                        String respString = sendResponse(JSONPayload,'Payment Summary');//For Dummy Response getresp(pdId);
                        system.debug('Res from SAP1='+respString);
                        String respMsg = respString.remove('{');
                        respMsg = respMsg.remove('}');
                        respMsg = respMsg.replaceAll('"','');
                        respMsg = respMsg.substringAfterLast(':');
                     if(String.isNotBlank(respString) && (respString.contains('ERROR') || respString.contains('ErrorResponse' ) || respString.contains('Duplicate'))){                
                            Integration_Log__c logObj = new Integration_Log__c();
                            logObj.Error_Message__c = respMsg;
                            logObj.Interface_Name__c = 'Payment Summary';
                            logObj.Status__c = 'Failure';
                            logObj.Type_of_Object__c = 'Payment File';
                            logObj.Response__c = 'Error Occurred for Payment Summary Id : '+paymentSum.Id;
                            logObj.Request__c = jsonPayload;
                            errLogList.add(logObj);
                            paymentSum.ECM_Transmission_Status__c ='Fail';
                            paymentSum.ECM_Error_message__c = respMsg;
                            updatePaymentSummary.add(paymentSum);
                        }else if(String.isNotBlank(respString) && (respString.contains('SUCCESS') || respString.contains('successfully'))){
                            ECM_PaymentResponseParser ResWrap = ECM_PaymentResponseParser.Parser(respString);


                            system.debug('wrapRes :'+ResWrap);
                            // Changes for ECM-4989
                            Integration_Log__c logObj = new Integration_Log__c();
                            logObj.Error_Message__c = '';


                            logObj.Interface_Name__c = 'Payment Summary';
                            logObj.Status__c = 'Success';
                            logObj.Type_of_Object__c = 'Payment File';
                            logObj.Response__c = ResWrap.ResponseMessage;
                            logObj.Request__c = jsonPayload;
                            errLogList.add(logObj);
                            paymentSum.ECM_SAP_Credit_Note_Number__c =ResWrap.CreditNoteNumber==''?Null:integer.valueof(ResWrap.CreditNoteNumber);
                            paymentSum.ECM_SAP_Credit_Note_Creation_Date__c = ResWrap.CreditNoteCreationDate==''?Null:Date.valueOf(ResWrap.CreditNoteCreationDate);
                            paymentSum.ECM_Transmission_Status__c ='Success';
                            paymentSum.ECM_Error_message__c = '';
                            updatePaymentSummary.add(paymentSum);
                        }
                    }
                }
            }
            if(updatePaymentSummary.Size()>0){
                update updatePaymentSummary;
            }
        }
        catch(Exception Ex){
            system.debug('Error in getPaymentDataNonVolume:'+Ex);
        }
        if(!errLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()){
            insert errLogList;
        }
    }
    /* Non-volume Type Payment Summary */
    public static string fetchPaymentJson(ECM_Payment_Summary__c paymentSum){
        system.debug('Inside Non Volume');
        String jsonData ='';
        try{
            Market_Setting__c markSetting = [Select Id,Name,Geography__c,ECM_SAP_Order_Type__c,CurrencyIsoCode,ECM_Email_to_Send_Payment_CSV__c FROM Market_Setting__c where 
                                             Geography__c=:paymentSum.ECM_Contract__r.Account.Country__c];
            if(markSetting!=Null){
                payErrEmail = markSetting.ECM_Email_to_Send_Payment_CSV__c;	
            }
            psName = paymentSum.Name;
            if(paymentSum.ECM_Budget_types__r.ECM_SAP_Order_reason__c!=null && paymentSum.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c!=null 
               && paymentSum.ECM_Invoice_Receival_Date__c!=null && paymentSum.ECM_Recommended_IO_Code__c!=null 
               && paymentSum.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c!=null && paymentSum.ECM_Contract__r.Account.SAP_Sold_to__c!=null 
               && paymentSum.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode!=null && paymentSum.ECM_Contract__r.Account.Sales_Org__c!=null 
               && markSetting.ECM_SAP_Order_Type__c!=null && paymentSum.Id!=null && paymentSum.ECM_Tax_Code__r.CST_SAP_Code__c!=null //modified as ECM-4934
               && paymentSum.ECM_Total_Amount_Confirmed__c!=null){
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();     
                gen.writeFieldName('PaymentFileData');
                gen.writeStartArray();
                
                //Wrapper class for Non-volume type Payment summary
                SAPWrapperNonVolume sapWrap= new SAPWrapperNonVolume();
                sapWrap.Order_Type_SAP=markSetting.ECM_SAP_Order_Type__c;
                sapWrap.Sales_Org_SAP=paymentSum.ECM_Contract__r.Account.Sales_Org__c;
                sapWrap.Division_SAP='10';//Hardcoded
                sapWrap.Channel_SAP='10';//Hardcoded
                sapWrap.Salesdoc_Number_SAP ='10'; //changes are done in CST for Claim_Id_SAP and it is mandatory in SAP against CST-876
                sapWrap.Claim_Id_SAP = paymentSum.Id;// changes are done in CST for Claim_Id_SAP and it is mandatory in SAP against CST-876
                sapWrap.Sold_to_SAP=paymentSum.ECM_Contract__r.Account.SAP_Sold_to__c;
                sapWrap.Ship_to_SAP=paymentSum.ECM_Contract__r.Account.SAP_Sold_to__c;
                sapWrap.PO_Number_SAP=paymentSum.Id;
                sapWrap.PO_Date_SAP=String.valueOf(paymentSum.ECM_Invoice_Receival_Date__c);
                sapWrap.Order_Reason_SAP=paymentSum.ECM_Budget_types__r.ECM_SAP_Order_reason__c;
                sapWrap.Material_SAP=String.valueOf(Label.ECM_PaymentSummaryNonVol_MaterialCode);//Hardcoded
                sapWrap.Quantity_SAP='1';//HardCoded
                sapWrap.UOM_SAP='';//ECM-3195 HardCoded
                sapWrap.Purchase_Order_Type_SAP = 'CMED';//ECM-4617 HardCoded
                sapWrap.Plant_SAP=paymentSum.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c;
                sapWrap.Tax_Classification1_SAP = paymentSum.ECM_Tax_Code__r.CST_SAP_Code__c;//Added for ECM-4934


                sapWrap.Internal_Order_SAP=paymentSum.ECM_Recommended_IO_Code__c;
                sapWrap.Pricing_Condition_SAP=paymentSum.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c;
                sapWrap.Currency_SAP=paymentSum.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode;
                sapWrap.Condition_Value_SAP=String.valueOf(paymentSum.ECM_Total_Amount_Confirmed__c);
                String s = JSON.serialize(sapWrap);
                Map<String,Object> obj =  (Map<String,Object>) JSON.deserializeUntyped(s);
                system.debug(obj.keyset());
                
                List<ECM_PaymentFile_To_SAP__mdt> payFileLabel = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName FROM ECM_PaymentFile_To_SAP__mdt];
                gen.writeStartObject(); 
                gen.writeFieldName(paymentSum.Name);
                gen.writeStartObject();
                for(ECM_PaymentFile_To_SAP__mdt payMtd : payFileLabel){  
                    if(obj.containskey(payMtd.DeveloperName+'_SAP')){
                        gen.writeStringField(payMtd.MasterLabel, String.valueOf(obj.get(payMtd.DeveloperName+'_SAP'))==Null?'':String.valueOf(obj.get(payMtd.DeveloperName+'_SAP')));               
                    }
                }
                gen.writeEndObject();
                gen.writeEndObject();
                
                gen.writeEndArray();
                gen.writeEndObject();
                jsonData = gen.getAsString();
            }else{
                system.debug('inside non volume else:');
                sendSAPcall = false;
                if(paymentSum.ECM_Total_Amount_Confirmed__c == null){
                    totAmtCon = true;
                }
                if(paymentSum.ECM_Budget_types__r.ECM_SAP_Order_reason__c == null){
                    sapOrderReason = true;
                }
                if(paymentSum.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c == null){
                    sapPlant = true;
                }
                if(paymentSum.ECM_Invoice_Receival_Date__c == null){
                    invoiceReceived = true;
                }


                // Added for ECM-4934
                if(String.isBlank(paymentSum.ECM_Tax_Code__r.CST_SAP_Code__c)){
                    taxRate = true;
                }
                if(paymentSum.Id == null){
                    paySum = true;
                }
                if(paymentSum.ECM_Recommended_IO_Code__c == null){
                    recIOCode = true;
                }
                if(paymentSum.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c == null){
                    sapPric = true;
                }
                if(paymentSum.ECM_Contract__r.Account.SAP_Sold_to__c == null){
                    soldTo = true;
                }
                if(paymentSum.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode==null){
                    curr = true;
                }
                if(paymentSum.ECM_Contract__r.Account.Sales_Org__c == null){
                    salesOrg = true;
                }
                if(markSetting.ECM_SAP_Order_Type__c == null){
                    sapOrder = true;
                }
            }
            System.debug('jsonData :' + jsonData);
            if(sapOrderReason){
                body = 'Order Reason value is Missing.'+'<br/>';
            }
            if(sapPlant){
                body += 'SAP Plant value is Missing.'+'<br/>';
            }
            if(invoiceReceived){
                body += 'Invoice Receival Date value is Missing.'+'<br/>';
            }
            if(taxRate){
                body += 'Material Tax Classification value is Missing.'+'<br/>';
            }
            if(paySum){
                body += 'Payment Summary value is Missing.'+'<br/>';
            }
            if(recIOCode){
                body += 'Recommended IO Code Value is Missing.'+'<br/>';
            }
            if(sapPric){
                body += 'SAP Pricing Condition value is Missing.'+'<br/>';
            }
            if(soldTo){
                body += 'Sold-to value is Missing.'+'<br/>';
            }
            if(curr){
                body += 'Currency value is Missing.'+'<br/>';
            }
            if(salesOrg){
                body += 'Sales Org value is Missing.'+'<br/>';
            }
            if(totAmtCon){
                body += 'Total Amount Confirmed value is Missing.'+'<br/>';
            }
            if(sapOrder){
                body += 'SAP Order Type value is Missing.'+'<br/>';
            }
            system.debug('inside body :'+body);
            if(String.isNotBlank(body)){
                // From Address Org Wide Email 
                OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where Address =: Label.ECM_OrgWideEmailAddress limit 1];
                Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();	
                List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();	
                String[] toAddresses = new list<string> {payErrEmail};
                    email.setOrgWideEmailAddressId(owa.id);
                
                String subject ='SAP Payment Summary Error Mail for '+psName;
                email.setHtmlBody(body);
                email.setToAddresses(toAddresses);
                email.setSubject(subject);
                allmsg.add(email); 
                system.debug('inside allmsg :'+allmsg);
                Messaging.sendEmail(allmsg);
            }
        }catch(exception ex){
            system.debug('error in fetchPaymentJson method:'+ex);
        }
        return jsonData;
    }
    /*ECM - 2936 End Here */
    
    public static string fetchPayItemsJson(List<ECM_Payment_Summary_Item__c> paymentItemsRecords,Map<Id,ECM_Internal_Order__c> internOrderName){
        String jsonData =''; 		
        try{                    
            Market_Setting__c markSetting = [Select Id,Name,Geography__c,ECM_SAP_Order_Type__c,CurrencyIsoCode,ECM_Email_to_Send_Payment_CSV__c FROM Market_Setting__c where 
                                             Geography__c=:paymentItemsRecords[0].ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__c];
            if(markSetting!=Null){
                payErrEmail = markSetting.ECM_Email_to_Send_Payment_CSV__c;	
            }				
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();     
            gen.writeFieldName('PaymentFileData');
            gen.writeStartArray();
            Integer salesdocNumber = 1;
            for(ECM_Payment_Summary_Item__c paymentItemsRecord : paymentItemsRecords){
					                
                psName = paymentItemsRecord.ECM_Payment_Summary__r.Name;
                if(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c!=null && paymentItemsRecord.ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Order_reason__c!=null && paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Market_Assortment__r.ECM_SAP_Plant_for_Payment_File__c!=null && paymentItemsRecord.ECM_Payment_Summary__r.ECM_Invoice_Receival_Date__c!=null 
                   && paymentItemsRecord.ECM_Payment_Summary__r.ECM_Tax_Code__r.CST_SAP_Code__c!=null && paymentItemsRecord.ECM_Payment_Summary__c!=null && paymentItemsRecord.ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c!=null && paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.SAP_Sold_to__c!=null && paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode!=null && paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.Sales_Org__c!=null && markSetting.ECM_SAP_Order_Type__c!=null ){
                    system.debug('Success inside if');
                    SAPWrapper sapWrap = new SAPWrapper();
                    sapWrap.Material_SAP = string.valueOf(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c);
                    sapWrap.Shipping_Instructions_SAP ='';
                    sapWrap.Text_Billing_Notes_for_printing_SAP = '';
                    sapWrap.Quantity_SAP = '1';
                    sapWrap.UOM_SAP = '';//ECM-3195 HardCoded
                    sapWrap.Purchase_Order_Type_SAP = 'CMED';//ECM-4617 HardCoded 
                    sapWrap.Salesdoc_Number_SAP = String.valueOf( salesdocNumber*10);//changes are done in CST for Claim_Id_SAP and it is mandatory in SAP against CST-876
                    salesdocNumber++ ; //changes are done in CST for Claim_Id_SAP and it is mandatory in SAP against CST-876
                	sapWrap.Claim_Id_SAP =  paymentItemsRecord.ECM_Payment_Summary__c;// changes are done in CST for Claim_Id_SAP and it is mandatory in SAP against CST-876   
                    sapWrap.Order_Reason_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Order_reason__c;
                    sapWrap.Item_Category_SAP ='';
                    sapWrap.Plant_SAP = paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Market_Assortment__r.ECM_SAP_Plant_for_Payment_File__c;
                    sapWrap.Pricing_Date_SAP ='';
                    sapWrap.RDD_SAP = '';
                    sapWrap.Batch_SAP = '';
                    sapWrap.PO_Date_SAP = String.valueOf(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Invoice_Receival_Date__c);
                       

                   //Commented for ECM-4934     

                    sapWrap.Tax_Classification1_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Tax_Code__r.CST_SAP_Code__c;//added for ECM-4934
                    sapWrap.PO_Number_SAP = paymentItemsRecord.ECM_Payment_Summary__c;
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__r.name == 'Australia'){
                        if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Recommended_IO_Code__c == null){
                            recIOCode = true;
                            sendSAPcall = false;
                        }
                        else{
                            sapWrap.Internal_Order_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Recommended_IO_Code__c;//from Internal order Record
                        }
                    }else{//start of ECM-6601
                        if(paymentItemsRecord.ECM_Internal_Order__c != null){
                            sapWrap.Internal_Order_SAP = paymentItemsRecord.ECM_Internal_Order__r.Name;//end of ECM-6601
                        }else if(internOrderName.containsKey(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Product__c)){
                            sapWrap.Internal_Order_SAP =internOrderName.get(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Product__c).Name;
                        }
                        else{
                            prodName = true;
                            sendSAPcall = false;
                        }
                    }
                    system.debug('internal :'+sapWrap.Internal_Order_SAP);
                    sapWrap.Payer_SAP = '';
                    sapWrap.Fixed_Value_Date_SAP = '';
                    sapWrap.Billto_SAP = '';
                    sapWrap.Pricing_Condition_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c;
                    sapWrap.Ship_to_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.SAP_Sold_to__c;
                    sapWrap.Amount_SAP = '5';
                    sapWrap.Cost_Center_SAP = '';
                    sapWrap.Sold_to_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.SAP_Sold_to__c;
                    sapWrap.Currency_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode;
                    sapWrap.Channel_SAP = '10';
                    sapWrap.Per_SAP = '';
                    sapWrap.Division_SAP = '10';
                    sapWrap.Sales_Org_SAP = paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.Sales_Org__c;
                    sapWrap.Unit_SAP = '';
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__r.name == 'Australia'){
                        if(paymentItemsRecord.ECM_Total_Rebate__c == null){
                            totRebate = true;
                            sendSAPcall = false;
                        }
                        else{
                            sapWrap.Condition_Value_SAP = string.valueOf(paymentItemsRecord.ECM_Total_Rebate__c);
                        }
                    }else{
                        if(paymentItemsRecord.ECM_Confirmed_Amount_Per_Payment__c==null){
                            conAmt = true;
                            sendSAPcall = false;
                        }
                        else{
                            sapWrap.Condition_Value_SAP = string.valueOf(paymentItemsRecord.ECM_Confirmed_Amount_Per_Payment__c);
                        }
                    }
                    sapWrap.Order_Type_SAP = markSetting.ECM_SAP_Order_Type__c;
                    String s = JSON.serialize(sapWrap);
                    Map<String,Object> obj =  (Map<String,Object>) JSON.deserializeUntyped(s);
                    system.debug(obj.keyset());
                    
                    List<ECM_PaymentFile_To_SAP__mdt> payFileLabel = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName FROM ECM_PaymentFile_To_SAP__mdt];
                    gen.writeStartObject(); 
                    gen.writeFieldName(paymentItemsRecord.Name);
                    gen.writeStartObject();
                    for(ECM_PaymentFile_To_SAP__mdt payMtd : payFileLabel){  
                        if(obj.containskey(payMtd.DeveloperName+'_SAP')){
                            gen.writeStringField(payMtd.MasterLabel, String.valueOf(obj.get(payMtd.DeveloperName+'_SAP'))==Null?'':String.valueOf(obj.get(payMtd.DeveloperName+'_SAP')));               
                        }
                    }
                    gen.writeEndObject();
                    gen.writeEndObject();
                }else{
                    sendSAPcall = false;
                    system.debug('inside else:');
                    if(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c == null){
                        materialVal = true;
                    }
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Order_reason__c == null){
                        sapOrderReason = true;
                    }
                    if(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Market_Assortment__r.ECM_SAP_Plant_for_Payment_File__c == null){
                        sapPlant = true;
                    }
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Invoice_Receival_Date__c == null){
                        invoiceReceived = true;
                    }

                    //commented for ECM-4934

                    //Added for ECM-4934
                    if(String.isBlank(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Tax_Code__r.CST_SAP_Code__c)){
                       taxRate = true; 
                    }
                    if(paymentItemsRecord.ECM_Payment_Summary__c == null){
                        paySum = true;
                    }
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c == null){
                        sapPric = true;
                    }
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.SAP_Sold_to__c == null){
                        soldTo = true;
                    }
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode==null){
                        curr = true;
                    }
                    if(paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.Sales_Org__c == null){
                        salesOrg = true;
                    }
                    if(markSetting.ECM_SAP_Order_Type__c == null){
                        sapOrder = true;
                    }
                    //start of ECM-4450
                    //ECM-4493 - Country check whether it is not australia
                    if(!internOrderName.containsKey(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Product__c)
                       &&
                       paymentItemsRecord.ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__r.name != 'Australia'){
                           prodName = true;
                       }
                    //End of ECM-4450,ECM-4493
                }
            }
            gen.writeEndArray();
            gen.writeEndObject();
            jsonData = gen.getAsString();
            System.debug('jsonData:' + jsonData);
            
            if(materialVal){
                body = 'Material value is Missing.'+'<br/>';
                
                //Added as a part of ECM-4238
                //Code Start
                body+='<br/><table border="1" style="border-collapse: collapse"><tr><th>Product Name</th></tr>';
                for(ECM_Payment_Summary_Item__c paymentItemsRecord : paymentItemsRecords){
                    if(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c == null){
                        String productName = paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Product__r.Name;
                        body+='<tr><td style="text-align:left">' + productName + '</td></tr>';
                    }
                }
                body+='</table><br/><br/>';
                //Code End
            }
            if(sapOrderReason){
                body += 'Order Reason value is Missing.'+'<br/>';
            }
            if(sapPlant){
                body += 'SAP Plant value is Missing.'+'<br/>';
            }
            if(invoiceReceived){
                body += 'Invoice Receival Date value is Missing.'+'<br/>';
            }
            if(taxRate){
                body += 'Material Tax Classification value is Missing.'+'<br/>';
            }
            if(paySum){
                body += 'Payment Summary value is Missing.'+'<br/>';
            }
            if(recIOCode){
                body += 'Recommended IO Code Value is Missing.'+'<br/>';
            }
            if(prodName){
                body += 'Internal Order value is Missing.'+'<br/>';
                
                //Added as a part of ECM-4238
                //Code Start
                body+='<br/><table border="1" style="border-collapse: collapse"><tr><th>Product Name</th></tr>';
                for(ECM_Payment_Summary_Item__c paymentItemsRecord : paymentItemsRecords){
                    if(!internOrderName.containsKey(paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Product__c)){
                        String productName = paymentItemsRecord.ECM_Contract_Item__r.ECM_Product__r.Product__r.Name;
                        body+='<tr><td style="text-align:left">' + productName + '</td></tr>';
                    }
                }
                body+='</table><br/><br/>';
                //Code End
            }
            if(sapPric){
                body += 'SAP Pricing Condition value is Missing.'+'<br/>';
            }
            if(soldTo){
                body += 'Sold-to value is Missing.'+'<br/>';
            }
            if(curr){
                body += 'Currency value is Missing.'+'<br/>';
            }
            if(salesOrg){
                body += 'Sales Org value is Missing.'+'<br/>';
            }
            if(totRebate){
                body += 'Total Rebate value is missing'+'<br/>';
            }
            if(conAmt){
                body += 'Confirmed Amount Per Payment value is Missing.'+'<br/>';
            }
            if(sapOrder){
                body += 'SAP Order Type value is Missing.'+'<br/>';
            }
            system.debug('inside body:'+body);
            if(String.isNotBlank(body)){
                // From Address Org Wide Email 
                OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where Address =: Label.ECM_OrgWideEmailAddress limit 1];
                Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();	
                List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();	
                String[] toAddresses = new list<string> {payErrEmail};
                    email.setOrgWideEmailAddressId(owa.id);
                
                String subject ='SAP Payment Summary Error Mail for '+psName;
                email.setHtmlBody(body);
                email.setToAddresses(toAddresses);
                email.setSubject(subject);
                allmsg.add(email); 
                system.debug('inside allmsg:'+allmsg);
                Messaging.sendEmail(allmsg);
            }
        }catch(exception ex){
            system.debug('error in fetchPayItemsJson method:'+ex);
        }
        return jsonData;
    }
    /*
	Method  : sendResponse
	Purpose : This method is used to Call-Out and Send Data
    */    
    public static string sendResponse(string jsonPayload, string PayItemId){
        String jsonBody = '';
        //String endPoint = Label.ECM_Endpoint_Sales_Order_SAP;//'https://api.eu.apiconnect.ibmcloud.com/diageo-gb-api/development/edgecmp/v1/soCreation';//Label.EndPoint_Credit_Debit_Return;
        //String clientId = Label.ECM_SO_Creation_SAP_Client_ID;//'e0e9cace-89e2-4883-913a-e488cc27bc16';//Label.X_IBM_Client_Id;
        //String clientSecret = Label.ECM_SO_Creation_SAP_Client_Secret;//'gU0xR2fT5kY6sR0hT1cV0bN0lS6cR0aG5tO5dW6wL0fL8wE8tE';//Label.X_IBM_Client_Secret;
        //String clientIdHeader = Label.ECM_SO_Creation_SAP_Client_ID_Header;
        //String clientSecretHeader = Label.ECM_SO_Creation_SAP_Client_Secret_Header;
        HttpRequest request = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        //request.setEndpoint(endPoint);
        request.setEndpoint('callout:' +ECM_SALESORDER_SAP);
        request.setMethod('POST');
        //request.setHeader(clientIdHeader,clientId);
        //request.setHeader(clientSecretHeader,clientSecret);
        request.setHeader('Content-Type','application/json');
        request.setBody(jsonPayload);
        request.setTimeout(120000);
        try {
            res = http.send(request);
            system.debug('res:'+res);
            if(res.getStatusCode() == 200){
                jsonBody = res.getBody();
            }else{
                /*PNR_CorrDocuTriggerHelper.*/createLog('Response Status code is : '+String.valueOf(res.getStatusCode()),
                                                        PayItemId, jsonPayload, 'Failure','Payment File',res.getBody());              
                jsonBody ='';
            }
        }catch(Exception ex){
            /*PNR_CorrDocuTriggerHelper.*/createLog(ex.getMessage(),PayItemId, jsonPayload, 'Failure','Payment File','Error Occurred for Payment Item Id : '+PayItemId);
        }
        return jsonBody;
    }
    /*
	Method  : createLog
	Purpose : This method is used to Create Integration log record
	*/
    public static void createLog(String errMsg, String interfcName, 
                                 String res, String status, String objType, String PayId){
                                     Integration_Log__c logObj = new Integration_Log__c();
                                     logObj.Error_Message__c = errMsg;
                                     logObj.Interface_Name__c = interfcName;
                                     logObj.Request__c = res;
                                     logObj.Status__c = status;
                                     logObj.Type_of_Object__c = objType;
                                     if(String.isNotBlank(PayId)){
                                         logObj.Response__c = 'Error Occurred for Payment Item Id : '+PayId;
                                     }
                                     if(Schema.SObjectType.Integration_Log__c.isCreateable() && Schema.sObjectType.Integration_Log__c.isUpdateable()){
                                         insert logObj;
                                     }
                                 }
    Public Class SAPWrapper{
        public String Material_SAP{get;set;}
        public String Shipping_Instructions_SAP{get;set;}
        public String Quantity_SAP{get;set;}        
        public String Text_Billing_Notes_for_printing_SAP{get;set;}
        public String UOM_SAP{get;set;}
        public String Order_Reason_SAP{get;set;}
        public String Item_Category_SAP{get;set;}
        public String Pricing_Date_SAP{get;set;}
        public String Plant_SAP{get;set;}
        public String RDD_SAP{get;set;}       
        public String Batch_SAP{get;set;}
        public String PO_Date_SAP{get;set;}
        public String Tax_Classification1_SAP{get;set;}//Added for ECM-4934
        public String Material_Tax_Classification_SAP{get;set;}
        public string PO_Number_SAP{get;set;}
        public String Internal_Order_SAP{get;set;}
        public String Payer_SAP{get;set;}
        public String Fixed_Value_Date_SAP{get;set;}
        public String Billto_SAP{get;set;}
        public String Pricing_Condition_SAP{get;set;}        
        public string Ship_to_SAP{get;set;}
        public string Amount_SAP{get;set;}
        public string Cost_Center_SAP{get;set;}
        public String Sold_to_SAP{get;set;}
        public String Currency_SAP{get;set;}
        public String Channel_SAP{get;set;}
        public String Per_SAP{get;set;}
        public string Division_SAP{get;set;}
        public string Unit_SAP{get;set;}
        public String Sales_Org_SAP{get;set;}
        public string Condition_Value_SAP{get;set;}
        public String Order_Type_SAP{get;set;} 
        public String Purchase_Order_Type_SAP{get;set;}	
        public string Claim_Id_SAP{get;set;}
        public string Salesdoc_Number_SAP{get;set;}
    }
    /* For Non-Volume type Payment Summary Wrapper*/
    Public Class SAPWrapperNonVolume{
        public String Order_Type_SAP{get;set;}
        public String Sales_Org_SAP{get;set;}
        public string Division_SAP{get;set;}
        public String Channel_SAP{get;set;}
        public String Sold_to_SAP{get;set;}
        public string Ship_to_SAP{get;set;}
        public string PO_Number_SAP{get;set;}
        public String PO_Date_SAP{get;set;}
        public String Order_Reason_SAP{get;set;}
        public String Material_SAP{get;set;}
        public String Quantity_SAP{get;set;}
        public String UOM_SAP{get;set;}
        public String Plant_SAP{get;set;}
        public String Tax_Classification1_SAP{get;set;}//Added for ECM-4934
	    public String Internal_Order_SAP{get;set;}
        public String Pricing_Condition_SAP{get;set;} 
        public String Currency_SAP{get;set;}
        public string Condition_Value_SAP{get;set;}
        public String Purchase_Order_Type_SAP{get;set;}	
        public string Claim_Id_SAP{get;set;}
        public string Salesdoc_Number_SAP{get;set;}
    }   
}