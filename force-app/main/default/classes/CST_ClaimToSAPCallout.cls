/*
* Class Name : CST_ClaimToSAPCallout
* @description: Callout class calling from Claim trigger
* @history
* VERSION    AUTHOR                DATE              DETAIL
* 1.0        CST Team  			21/05/2021        Initial Development
* 1.1        Anamika Shukla     29/02/2024        EDGE Global: Mulesoft OAuth2 migration-358242
*/

public class CST_ClaimToSAPCallout{
    public static final String CST_SALESORDER_SAP = 'CST_Mulesoft_SalesOrder_SAP';//358242
    
    /*
* @description : getClaimBillingData
* @return : void
* @param : Set
*/      
@future(callout = true)
    public static void getClaimBillingData(set<Id> claimIds){
        List<Integration_Log__c> errLogList = new List<Integration_Log__c>();
        Map<string,List<CST_Claim_Item__c>> claimTypeToclaimItm = new Map<string,List<CST_Claim_Item__c>>() ;
        Map<string,CST_Claim__c> clmItmroClaim = new Map<string,CST_Claim__c>() ;
        string key;
        List<CST_Claim__c> claimLst = new List<CST_Claim__c>();
        try{
            List<CST_Claim_Item__c> claimItemLst = [SELECT name,id,CST_Claim__r.CST_Document_Type__c,
                                                    CST_Claim__r.CST_Sales_Organisation__r.Code__c,
                                                    CST_Claim__r.CST_Sales_Organisation__r.Block_Document_in_SAP__c,CST_Claim__r.Billing_notes__c,
                                                    CST_Claim__r.CST_Account__r.AccountNumber,CST_Claim__r.CST_Invoice_Number__c,
                                                    CST_Claim__r.CST_Invoice_Receive_Date__c,CST_Claim__r.CST_Invoice_Date__c,CST_Internal_Order__r.SAP_Product_Code__c,
                                                    CST_Net_Value__c,CurrencyIsoCode,CST_Claim__c,Type__c,
                                                    CST_Claim__r.CST_Account__r.Country__r.ECM_SAP_Plant_for_Payment_File__c,
                                                    CST_Internal_Order__r.Name,CST_General_Ledger__r.Pricing_Condition__c,
                                                    CST_Claim__r.CST_Account__r.CST_Payment_term__r.CST_SAP_Code__c,
                                                    CST_Claim__r.CST_Payment_Term__r.CST_SAP_Code__c,CST_Tax_Code__r.CST_SAP_Code__c,
                                                    Additional_Tax_Pricing_Condition__c,Additional_Tax_Value__c,Commitment_Number__c,
                                                    CST_Claim__r.Greek_reason_code__c,CST_Claim__r.CST_Status__c
													/*,Tax_detail__c,CST_Claim__r.Customer_Service_Internal_Use_only__c*/          
                                                    FROM CST_Claim_Item__c 
                                                    WHERE CST_Claim__c  in: claimIds];
                           
            for(CST_Claim_Item__c claimItm:claimItemLst){
                key ='';  
                key = claimItm.CST_Claim__c+'_'+ claimItm.Type__c;
                if(claimTypeToclaimItm.containsKey(key)){
                        claimTypeToclaimItm.get(key).add(claimItm);
                 }else{
                       claimTypeToclaimItm.put(key, new List<CST_Claim_Item__c>{claimItm});
                }           
            }
            
            string claimId ='';
            for(String str:claimTypeToclaimItm.keyset()){
                claimId = str.substringBefore('_');         
                CST_Claim__c claimobj = new CST_Claim__c(id =claimId);
                string JSONPayload;
                if(claimTypeToclaimItm.containskey(str) && claimTypeToclaimItm.get(str).size()>0){
                    JSONPayload = fetchClaimItemsJson(claimTypeToclaimItm.get(str));
                } 
                if(JSONPayload !=Null ){
                    system.debug('inside JSONPayload-->'+JSONPayload);                    
                    String respString = sendResponse(JSONPayload,'CST PaymentSummary');//For Dummy Response getresp(pdId);
                    system.debug('Res from SAP='+respString);                    
                    String respMsg = respString.remove('{');
                    respMsg = respMsg.remove('}');
                    respMsg = respMsg.replaceAll('"','');
                    respMsg = respMsg.substringAfterLast(':');
                           if(String.isNotBlank(respString) && (respString.contains('ERROR') || respString.contains('ErrorResponse'))){                  
                                Integration_Log__c logObj = new Integration_Log__c();
                                logObj.Error_Message__c = respMsg;
                                logObj.Interface_Name__c = 'CST PaymentSummary';
                                logObj.Status__c = 'Failure';
                                logObj.Type_of_Object__c = 'Payment File';
                                logObj.Response__c = 'Error Occurred for CST PaymentSummary Id : '+claimobj.Id;
                                logObj.Request__c = jsonPayload;
                        		if(clmItmroClaim.containsKey(claimobj.id)){
                                   clmItmroClaim.get(claimobj.id).SAP_Integration_Failure__c =true;
                                   clmItmroClaim.get(claimobj.id).Integration_Failure_Message__c =respMsg;
                                }else{
                                   claimobj.SAP_Integration_Failure__c = true;
								   claimobj.Integration_Failure_Message__c = respMsg;  
                                   clmItmroClaim.put(claimobj.id,claimobj);
                                }
                               	errLogList.add(logObj);                                 
                            }else if(String.isNotBlank(respString) && (respString.contains('SUCCESS') || respString.contains('successfully'))){
                                ECM_PaymentResponseParser ResWrap = ECM_PaymentResponseParser.Parser(respString);
                                system.debug('wrapRes='+ResWrap);
                                if(str.contains('A&P') ){
                                    if(clmItmroClaim.containsKey(claimobj.id))
                                        clmItmroClaim.get(claimobj.id).CST_SAP_Doc_number_AP__c =ResWrap.CreditNoteNumber==''?Null:ResWrap.CreditNoteNumber;                        
                                    else{
                                        claimobj.CST_SAP_Doc_number_AP__c =ResWrap.CreditNoteNumber==''?Null:ResWrap.CreditNoteNumber;
                                        claimobj.SAP_Integration_Failure__c =False;//1044
                                        claimobj.Integration_Failure_Message__c ='';
                                        clmItmroClaim.put(claimobj.id,claimobj);                            
                                    }    
                                }
                                else if(str.contains('Trade')){
                                    if(clmItmroClaim.containsKey(claimobj.id))
                                        clmItmroClaim.get(claimobj.id).CST_SAP_Doc_number_TI__c =ResWrap.CreditNoteNumber==''?Null:ResWrap.CreditNoteNumber;                        
                                    else{
                                        claimobj.CST_SAP_Doc_number_TI__c =ResWrap.CreditNoteNumber==''?Null:ResWrap.CreditNoteNumber;
                                        claimobj.SAP_Integration_Failure__c =False;//1044
                                        claimobj.Integration_Failure_Message__c ='';
                                        clmItmroClaim.put(claimobj.id,claimobj);                            
                                    }                       
                                } 
                            }
                    }
              }
            
            if(!clmItmroClaim.isempty()){
                update clmItmroClaim.values();
            }
                
       }
        catch(Exception Ex){
            system.debug('Error in getPaymentData:'+Ex);
        }
        if(!errLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()){
            insert errLogList;
        }
            
    }
    

    /*
* @description : fetchClaimItemsJson
* @return : string
* @param : List CST_Claim_Item__c
*/  

    public static string fetchClaimItemsJson(List<CST_Claim_Item__c> claimItemsRecords){
        String jsonData ='';
        integer a = 0;
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();     
        gen.writeFieldName('PaymentFileData');
        gen.writeStartArray();
            for(CST_Claim_Item__c claimItm : claimItemsRecords){                
                    //psName = claimItm.Name;             
                    system.debug('Success inside if');
                    
                    SAPWrapper sapWrap = new SAPWrapper();
                   
                    sapWrap.Material_SAP = claimItm.CST_Internal_Order__r.SAP_Product_Code__c;
                    sapWrap.Shipping_Instructions_SAP ='';
            		sapWrap.Text_Billing_Notes_for_printing_SAP = claimItm.CST_Claim__r.Billing_notes__c;
                    sapWrap.Quantity_SAP = '1';
                    sapWrap.UOM_SAP = '';
                    sapWrap.Order_Reason_SAP = 'Y35';
                    sapWrap.Item_Category_SAP ='';
                    sapWrap.Plant_SAP = claimItm.CST_Claim__r.CST_Account__r.Country__r.ECM_SAP_Plant_for_Payment_File__c;
                    sapWrap.Pricing_Date_SAP ='';
                    sapWrap.RDD_SAP = '';
                    sapWrap.Batch_SAP = '';
                    sapWrap.PO_Date_SAP = String.valueOf(claimItm.CST_Claim__r.CST_Invoice_Date__c);
                    sapWrap.Material_Tax_Classification_SAP = '0';
					if(claimItm.Type__c.contains('A&P')){
                        sapWrap.Claim_Id_SAP = claimItm.CST_Claim__c+'_'+'AP';
					}else if(claimItm.Type__c.contains('Trade')){
                        sapWrap.Claim_Id_SAP = claimItm.CST_Claim__c+'_'+'TI';
					}					
                    sapWrap.PO_Number_SAP = claimItm.CST_Claim__r.CST_Invoice_Number__c;                    
                    sapWrap.Internal_Order_SAP =claimItm.CST_Internal_Order__r.Name;
                    sapWrap.Payer_SAP = '';
                    sapWrap.Fixed_Value_Date_SAP = '';
                    sapWrap.Billto_SAP = '';
            		sapWrap.Pricing_Condition_SAP = claimItm.CST_General_Ledger__r.Pricing_Condition__c;
                    sapWrap.Ship_to_SAP = claimItm.CST_Claim__r.CST_Account__r.AccountNumber;
                    sapWrap.Amount_SAP = '5';
                    sapWrap.Cost_Center_SAP = '';
                    sapWrap.Sold_to_SAP = claimItm.CST_Claim__r.CST_Account__r.AccountNumber;
                    sapWrap.Currency_SAP = claimItm.CurrencyIsoCode;
                    sapWrap.Channel_SAP = '10';
                    sapWrap.Per_SAP = '';
                    sapWrap.Division_SAP = '10';
                    sapWrap.Sales_Org_SAP = claimItm.CST_Claim__r.CST_Sales_Organisation__r.Code__c;
                    sapWrap.Unit_SAP = '';
                    sapWrap.Condition_Value_SAP = String.valueOf(claimItm.CST_Net_Value__c);
                    sapWrap.Order_Type_SAP = claimItm.CST_Claim__r.CST_Document_Type__c;
                    if(claimItm.CST_Claim__r.CST_Sales_Organisation__r.Block_Document_in_SAP__c){
						sapWrap.Purchase_Order_Type_SAP ='CSBL';
					}else{
						sapWrap.Purchase_Order_Type_SAP ='CSUB';
					}
                    if(claimItm.CST_Claim__r.CST_Payment_Term__r.CST_SAP_Code__c != null){
                       sapWrap.Payment_Terms_SAP =claimItm.CST_Claim__r.CST_Payment_Term__r.CST_SAP_Code__c;                 
                    }else if(claimItm.CST_Claim__r.CST_Account__r.CST_Payment_term__r.CST_SAP_Code__c != null){
                        sapWrap.Payment_Terms_SAP =claimItm.CST_Claim__r.CST_Account__r.CST_Payment_term__r.CST_SAP_Code__c; 
                    }else{
                        sapWrap.Payment_Terms_SAP ='';     
                    }     
                    sapWrap.Tax_Classification1_SAP =  claimItm.CST_Tax_Code__r.CST_SAP_Code__c ;                    					
                    //CST-876
                    
                    integer Serial_no = a + 10;
                    a = Serial_no; 
                    sapWrap.Salesdoc_Number_SAP = String.valueOf(Serial_no);
                    if(claimItm.Additional_Tax_Pricing_Condition__c != null && claimItm.Additional_Tax_Value__c != null)
                    {
                        sapWrap.Additional_Tax_Value_SAP = String.valueOf(claimItm.Additional_Tax_Value__c);
                        sapWrap.Additional_Tax_Pricing_Condition_SAP = claimItm.Additional_Tax_Pricing_Condition__c;    
                    }else{
                        sapWrap.Additional_Tax_Value_SAP = '';
                        sapWrap.Additional_Tax_Pricing_Condition_SAP = ''; 
                    }
                    //CST-841
                    if(claimItm.Commitment_Number__c!=null){
                        sapWrap.Commitment_Number_SAP = claimItm.Commitment_Number__c;
                    }else{
                        sapWrap.Commitment_Number_SAP = '';
                    }  
                	//CST-1011
                    if(claimItm.CST_Claim__r.Greek_reason_code__c!=null){
                        sapWrap.Greek_reason_code_SAP = claimItm.CST_Claim__r.Greek_reason_code__c;
                    }
                	//CST-1037
					/*
                    if(claimItm.CST_Claim__r.CST_Sales_Organisation__r.Code__c == 'RU01' || claimItm.CST_Claim__r.CST_Sales_Organisation__r.Code__c == 'RU02'){
                        sapWrap.Tax_detail_SAP = '1VDS';
                   }
                
                    if(claimItm.CST_Claim__r.Customer_Service_Internal_Use_only__c!=null){
                        sapWrap.Customer_Service_Internal_Use_SAP = claimItm.CST_Claim__r.Customer_Service_Internal_Use_only__c;
                    }
					*/
                    
                    String s = JSON.serialize(sapWrap);
               	    system.debug(s);  
                    Map<String,Object> obj =  (Map<String,Object>) JSON.deserializeUntyped(s);
                    system.debug(obj.keyset());                 
                    List<ECM_PaymentFile_To_SAP__mdt> payFileLabel = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName FROM ECM_PaymentFile_To_SAP__mdt];
                    gen.writeStartObject(); 
                    gen.writeFieldName(claimItm.Name);
                    gen.writeStartObject();
                    for(ECM_PaymentFile_To_SAP__mdt payMtd : payFileLabel){  
                        if(obj.containskey(payMtd.DeveloperName+'_SAP')){
                            gen.writeStringField(payMtd.MasterLabel, String.valueOf(obj.get(payMtd.DeveloperName+'_SAP'))==Null?'':String.valueOf(obj.get(payMtd.DeveloperName+'_SAP')));               
                        }
                    }
                    gen.writeEndObject();
                    gen.writeEndObject();               
            }
            gen.writeEndArray();
            gen.writeEndObject();
            jsonData = gen.getAsString();
            return jsonData;
    }
    
    /*
* @description : sendResponse
* @return : string
* @param : string jsonPayload, string PayItemId
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
        request.setEndpoint('callout:' +CST_SALESORDER_SAP);
        request.setMethod('POST');
        //request.setHeader(clientIdHeader,clientId);
        //request.setHeader(clientSecretHeader,clientSecret);
        request.setHeader('Content-Type','application/json');
        request.setBody(jsonPayload);
        request.setTimeout(120000);
        try {
            res = http.send(request);
            system.debug('res='+res);
            if(res.getStatusCode() == 200){
                jsonBody = res.getBody();
            }else{
                createLog('Response Status code is : '+String.valueOf(res.getStatusCode()),PayItemId, jsonPayload, 'Failure','Payment File',res.getBody());              
                jsonBody ='';
            }
        }catch(Exception ex){
              createLog(ex.getMessage(),PayItemId, jsonPayload, 'Failure','Payment File','Error Occurred for Payment Item Id : '+PayItemId);
        }
        return jsonBody;
    }

    /*
* @description : createLog
* @return : Void
* @param : String errMsg, String interfcName, String res, String status, String objType, String PayId
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
    
    /*
* Class Name : SAPWrapper
* @description: Wrapper Class
* @history
*/
    
    public class SAPWrapper {
        public String Material_SAP {get;set;}
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
        public String Material_Tax_Classification_SAP{get;set;}
        public string PO_Number_SAP{get;set;}
        public string Claim_Id_SAP{get;set;}
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
        public String Payment_Terms_SAP{get;set;} 
		public String Tax_Classification1_SAP{get;set;} 		
        //CST-876
        public String Salesdoc_Number_SAP{get;set;}
        public String Additional_Tax_Value_SAP{get;set;}
        public String Additional_Tax_Pricing_Condition_SAP{get;set;}
        //CST-841
        public String Commitment_Number_SAP{get;set;}
        //CST-1011
        public String Greek_reason_code_SAP{get;set;}
        // CST-1037
		/*
        public String Tax_detail_SAP{get;set;}
        public String Customer_Service_Internal_Use_SAP{get;set;}
        */
        
        
    }
  
}