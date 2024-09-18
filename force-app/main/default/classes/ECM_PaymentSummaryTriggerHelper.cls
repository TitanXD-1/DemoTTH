/*
* Class Name : ECM_PaymentSummaryTriggerHelper
* @description: Helper Class for ECM_PaymentSummaryTriggerHandler
* @history
* VERSION    AUTHOR                    DATE              DETAIL
* 1.1        Veerendra Billakurthi     22/06/2021    ECM-4561 - Deployment_Enable the budget type for Ireland 
* 1.2        Sayan Mullick             02/08/2021    ECM-4620 - Rejection Notification for Sales rep for the Promo standard and Volume PS_SFDC_Approval revamp 
* 1.3        Saurav && Anuja           30/07/2021    ECM-4764 - Push Notification revamp
* 1.4        Anuja Chattopadhyay       05/10/2021    ECM-4787 - Email for the New Extra Approver Type-(Volume Based PS-Target) 
* 1.5        Manikandan.T			   26/11/2021    ECM-4958 - Trigger Helper Class Refactoring
* 1.6        Tanishq Banerjee          09/03/2022    ECM-5292,ECM-5301,ECM-5294 - Update CTD values in Contract and Contract Item from Payment Summary and Payment Summary Item
* 1.7        Vinay Tummala             05/04/2022    ECM-5399 - Push Notification Fix for PS_Mobile & Salesforce_Approval revamp
* 1.8        Abhijeet Mishra           16/06/2022    ECM-5682 - Payment Summary Approved field should be checked true when any Payment Summary
* 1.9        Pratap Sen                18/06/2022    ECM-5677 - Logic to update 'Last Volume Information Update' in contract object_SFDC_M&E Visualization Mobile
* 2.0        Pratap Sen                01/07/2022    ECM-5775 - Logic to update 'CTD Overall Investment'  field for EU KPI’s in the Contract Item Object
* 2.1		 Supriya G				   19/08/2022    ECM-5870 - Logic to send Email when Invoice status is 'Requested' 
* 2.2       Tanishq & Pratik           21/11/2022    ECM-6351: Regression_Defect : Request for evidence mail is triggering twice
* 2.2       Sudipta & Suvenndu         01/12/2022    146081: Sending Approval request to EA on PS Compliance Scenarios (from AT)_SFDC
*/

public without sharing class ECM_PaymentSummaryTriggerHelper {
    private static Map<Id,Contract> Map_Contract=new Map<Id,Contract>();
    static Map<Id,String> agreementTypeToLogic = new Map<Id,String>();
    static Set<Id> validPaySumIdList = new Set<Id>();
    static Map<Id,String> extraUserRoleMap= new  Map<Id,String>();
    static Set<Id> delegatedUsersForApproval = new Set<Id>();
    static Set<Id> activeUsersForApproval = new Set<Id>();
    static Map<String,List<ProcessInstanceWorkitem>> existingApprovalMapPI= new Map<String,List<ProcessInstanceWorkitem>>();
    static List<ECM_Payment_Summary__c> paymentSumListCIOForAdditonal = new List<ECM_Payment_Summary__c>();
    static Map<Id,Decimal> sumOfPSIMap = new Map<Id,Decimal>();
    static Map<Id,Decimal> sumOfCIMap = new Map<Id,Decimal>();
    static Map<Id,String> paySumMaptoApprovalStatus = new MAp<Id,String>();
   
   /*
* @description : Retrieve contract details for all the PaymentSummaries in the Trigger.new
* @return : void
* @param : trigger.New,Map_Contract
*/
   public static void fetchContractDetails(List < ECM_Payment_Summary__c > newPaySum){
       Set <id> contract_ids = new set <Id>();
       try{
           for (ECM_Payment_Summary__c record: newPaySum) {         
               if (record.ECM_Contract__c != null) {               
                   contract_ids.add(record.ECM_Contract__c);
               }
           }
           
           if(!contract_ids.isEmpty()){	
               for( contract contract: [select id, Name, Account.Hybrid__c, Account.ParentId,Account.BillingState, ECM_Channel__c,
                                        ECM_Agreement_Type__c,ECM_Agreement_Type__r.geography__r.Name,CurrencyIsoCode,ECM_Upfront_Payment_Spent__c,
                                        ECM_Contract_SKU_Specific_Rebate_Paid__c,Rebate_Paid__c,ECM_Agreement_Type__r.ECM_Prepayment_SR_approval__c,
                                        ECM_Upfront_Last_Payment_date__c,ECM_Total_amount_summary__c,AP_Spent__c,ECM_Contract_Other_Spent__c,ECM_Contract_Payment_Spent__c,Account.Country__c,Account.Country__r.name,Account.Country__r.code__c															
                                        from contract where id in: contract_ids
                                       ]){
                                           Map_Contract.put(contract.Id,contract);
                                       }                 
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in fetchContractDetails method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
   }
   
   
   /*
* @description : This method updates the ECM_Recommended_IO_Code__c for all PaymentSummaries in the Australian market
* @return : void
* @param : trigger.New,Map_Contract
*/
   public static void updateIOCode(List < ECM_Payment_Summary__c > newPaySum) {
       
       Date today = System.TODAY();
       Map <String,ECM_Internal_Order__c > Map_Unique_Internal_Order = new Map <String,ECM_Internal_Order__c >();
       list <ECM_Internal_Order__c> List_Internal_Order;
       try{
           List_Internal_Order = [select id, Name, ECM_Active__c, Ecm_Channel__c, Owner__c,
                                  ECM_Budget_Type_Pickup_Option__c, ECM_End_Date__c, ECM_Start_Date__c,
                                  ECM_State__c from ECM_Internal_Order__c where ECM_Active__c =: true
                                  and ECM_Start_Date__c <=: today and ECM_End_Date__c >=: today and ECM_State__c != null
                                  and Owner__c != null and ECM_Budget_Type_Pickup_Option__c != null
                                  and ECM_Budget_Type_Pickup_Option__c != ''
                                 ];
           if (!List_Internal_Order.isEmpty()) {
               for (ECM_Internal_Order__c Internal_Order: List_Internal_Order) {
                   string unique = Internal_Order.Owner__c + '' + Internal_Order.ECM_Budget_Type_Pickup_Option__c + '' + Internal_Order.ECM_State__c;
                   Map_Unique_Internal_Order.put(unique, Internal_Order);
               }
           }
           
           Map <Id,Account > Map_Id_Account = new Map <Id,Account >();
           
           for (ECM_Payment_Summary__c Payment_Summary_Record: newPaySum) {
               if (Payment_Summary_Record.ECM_Budget_types__c != null && Map_Contract.containsKey(Payment_Summary_Record.ECM_Contract__c) && Map_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account!=null && Map_Contract.get(Payment_Summary_Record.ECM_Contract__c).ECM_Agreement_Type__r.Geography__r.Name == system.label.ECM_Australia) {
                   if ((Map_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId != null ||
                        Map_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId != '')) {
                            string unique = Map_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId + '' + Payment_Summary_Record.ECM_Budget_types__c + '' + Map_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.BillingState;
                            if (Map_Unique_Internal_Order.containsKey(unique)) {
                                Payment_Summary_Record.ECM_Recommended_IO_Code__c = Map_Unique_Internal_Order.get(unique).Name;
                            }
                        }
               }    
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in updateIOCode method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
   }
   /*
* @description : This method updates the currencycode from associated agreement record
* @return : void
* @param : trigger.new,Map_Contract
*/
   public static void updateCurrencyCode(List<ECM_Payment_Summary__c> newPaySum) { 
       
       for(ECM_Payment_Summary__c paySumObj: newPaySum){			
           if(Map_Contract.containsKey(paySumObj.ECM_Contract__c)  && paySumObj.CurrencyIsoCode!=Map_Contract.get(paySumObj.ECM_Contract__c).CurrencyIsoCode){
               paySumObj.CurrencyIsoCode = Map_Contract.get(paySumObj.ECM_Contract__c).CurrencyIsoCode;
           }
       }
   }    
   
   /*
* @description : This method updates the Budget Type from the Market Settings 
* @return : void
* @param : trigger.new
*/
   public static void ECM_Update_PS_BudgetType(List <ECM_Payment_Summary__c> newPaySum) {
       Set<Id> geoCountry = new Set<Id>();
       Map<Id,ECM_Payment_Summary__c> PaymentSummaryMap = new Map<Id,ECM_Payment_Summary__c>();
       
       try{
           
           for(ECM_Payment_Summary__c mailPS : newPaySum){
               if(Map_Contract.containsKey(mailPS.ECM_Contract__c)){
                   geoCountry.add(Map_Contract.get(mailPS.ECM_Contract__c).Account.Country__c); 
               }
               
           }
           Map<String,Market_Setting__c> marketGeoMap =new Map<String,Market_Setting__c> ();
           for(Market_Setting__c market :[SELECT Id, Name__c,ECM_Budget_Type_for_Volume_Based_PS__c,Geography__c,Geography__r.Name FROM Market_Setting__c WHERE Geography__c IN : geoCountry AND ECM_Budget_Type_for_Volume_Based_PS__r.RecordType.DeveloperName = 'ECM_Budget_Type']){
               marketGeoMap.put(market.Geography__c,market);
           }
           //ECM-4561
           Map<String,Boolean> PaysumVolumeMapmdt= new Map<String,Boolean> ();
           for(ECM_Technical_Market_Setting__mdt mdt: [select masterlabel,ECM_Country__c,ECM_Payment_Summary_Volume__c,ECM_Contract_Extra_Approval__c from ECM_Technical_Market_Setting__mdt where ECM_Payment_Summary_Volume__c=True]){
               PaysumVolumeMapmdt.put(mdt.ECM_Country__c,mdt.ECM_Payment_Summary_Volume__c);
           }
           if(test.isRunningTest()){
               PaysumVolumeMapmdt.put('AU',true);
           }
           for(ECM_Payment_Summary__c paymentSummary : newPaySum){
               
               if( paymentSummary.ECM_Type__c == 'Volume-Based' && PaysumVolumeMapmdt.get(Map_Contract.get(paymentSummary.ECM_Contract__c).Account.Country__r.code__c)){
                   if( marketGeoMap.containsKey(Map_Contract.get(paymentSummary.ECM_Contract__c).Account.Country__c)){
                       paymentSummary.ECM_Budget_types__c=marketGeoMap.get(Map_Contract.get(paymentSummary.ECM_Contract__c).Account.Country__c).ECM_Budget_Type_for_Volume_Based_PS__c;        
                       
                   }
               }					
               
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in ECM_Update_PS_BudgetType method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
   }
   
   
   /*
* @description : This method creates payment Summary line Items for Australian Payment Summaries 
* @return : void
* @param : trigger.new
*/
   
   public static void insertPaymentSummaryLineItemsForAustralia(Map <Id,ECM_Payment_Summary__c> newPaySumMap){
       
       Set<String> geoCountryName=new Set<String>();
       Set<Id> pSIds = new Set<Id>();
       Set<Id> contractIds = new Set<Id>();
       Map<Id,Id> paymentWithContractId = new Map<Id,Id>();
       Map<Id,String> paymentWithbudgetType = new Map<Id,String>();
       Map<Id,String> pstypeMap = new Map<Id,String>();
       List<ECM_Payment_Summary_Item__c> newPSItemList = new list<ECM_Payment_Summary_Item__c>();
       Map<string,decimal> prodInvestmentmap=New Map<String,decimal>();  
       try{
           for(Integer i=0; i<newPaySumMap.size(); i++)
           {
               contractIds.add(newPaySumMap.Values().get(i).ECM_Contract__c);
               paymentWithContractId.put(newPaySumMap.Values().get(i).Id,newPaySumMap.Values().get(i).ECM_Contract__c);
               paymentWithbudgetType.put(newPaySumMap.Values().get(i).Id,newPaySumMap.Values().get(i).ECM_Budget_types__c);
               pstypeMap.put(newPaySumMap.Values().get(i).Id,newPaySumMap.Values().get(i).ECM_Type__c);
               
               if(newPaySumMap.Values().get(i).ECM_Payment_Summary_Status__c == 'Approved')
               {
                   pSIds.add(newPaySumMap.Values().get(i).Id);
               }
           }
           Map<Id,List<ECM_Contract_Item__c>> ContractWithConItems = new Map<Id,List<ECM_Contract_Item__c>>();
           
           
           for(ECM_Contract_Item__c contractItemList : [SELECT Id, ECM_Contract__c, ECM_Product__c, ECM_Actual_Volume_YTD__c, ECM_Contract__r.Account.Country__c,
                                                        ECM_Contract__r.Account.Country__r.Name, ECM_UoM__c FROM ECM_Contract_Item__c 
                                                        WHERE ECM_Contract__c IN: contractIds]){
                                                            if(ContractWithConItems.containsKey(contractItemList.ECM_Contract__c)){
                                                                List<ECM_Contract_Item__c> addItems = ContractWithConItems.get(contractItemList.ECM_Contract__c);
                                                                addItems.add(contractItemList);
                                                                ContractWithConItems.put(contractItemList.ECM_Contract__c, addItems);
                                                                geoCountryName.add(contractItemList.ECM_Contract__r.Account.Country__r.Name);
                                                            }else{
                                                                ContractWithConItems.put(contractItemList.ECM_Contract__c, new List<ECM_Contract_Item__c>{contractItemList});
                                                                geoCountryName.add(contractItemList.ECM_Contract__r.Account.Country__r.Name);
                                                            }
                                                        }
           
           for(id PsID :paymentWithContractId.keySet()){
               if((pstypeMap.get(PsID)== 'Non-Volume')|| ((pstypeMap.get(PsID)== 'Volume-Based') && geoCountryName.contains('Australia'))){
                   if(ContractWithConItems.containskey(paymentWithContractId.get(PsID)) && ContractWithConItems.get(paymentWithContractId.get(PsID)).size()>0 ){
                       for(ECM_Contract_Item__c ci :ContractWithConItems.get(paymentWithContractId.get(PsID))){ 
                           ECM_Payment_Summary_Item__c newPSI = new ECM_Payment_Summary_Item__c();
                           newPSI.ECM_Payment_Summary__c = PsID;
                           newPSI.ECM_Contract_Item__c = ci.Id;                        
                           if(ci.ECM_UoM__c == null){
                               ci.ECM_UoM__c = '0';
                           }
                           if(ci.ECM_Actual_Volume_YTD__c == null){
                               ci.ECM_Actual_Volume_YTD__c = 0;
                           }
                           newPSI.ECM_Confirmed_Volume__c = 0; 
                           newPSI.ECM_Confirm__c= true;     
                           newPSI.ECM_Confirmed_Amount_Per_Payment__c = 0;                        
                           newPSItemList.add(newPSI);
                       }
                   }
                   
               }
           }
           if(newPSItemList.size()>0){
               insert newPSItemList;
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in insertPaymentSummaryLineItemsForAustralia method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
       
   }
   
   /*
* @description : This method validates if there are any changes for Approved Payment Summaries. 
* @return : void
* @param : trigger.newMap,trigger.OldMap
*/
   public static void validatePaymentSummaryApproval(Map <Id,ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> oldPaySumMap){
       
       Set<Id> psIdSet = new Set<Id>();
       List<Id> psIdList = new List<Id>();
       list<ECM_Payment_Summary__c> psList = new List<ECM_Payment_Summary__c>();
       List<ECM_Payment_Summary__c> extraApprovalList = new  List<ECM_Payment_Summary__c>();
       List<ECM_Payment_Summary__c> cioApprovalList = new  List<ECM_Payment_Summary__c>();
       List<ECM_Payment_Summary__c> autoApprovalOrRejectList = new  List<ECM_Payment_Summary__c>();
       Profile CIOUserProfile = [SELECT Id,Name FROM Profile WHERE Name='CIO User'];
       
       for(ECM_Payment_Summary__c paymentSummary:newPaySumMap.Values())
       { 					
           if( oldPaySumMap.get(paymentSummary.Id).ECM_Invoice_Status__c !='Approved'  && paymentSummary.ECM_Payment_Summary_Status__c =='Approved' && paymentSummary.ECM_Type__c!='Non-Volume')
           {
               paymentSummary.addError(Label.ECM_Payment_Summary_Invoice_Status_Missing);
           }
           if(paymentSummary.ECM_Tax_Code__c==null && paymentSummary.ECM_Payment_Summary_Status__c =='Approved'){                   
               paymentSummary.addError(Label.ECM_Payment_summary_Tax_Code_Missing);                   
           }
           if( oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c =='Approved' && CIOUserProfile.Id == UserInfo.getProfileId())
           {	
               if(oldPaySumMap.get(paymentSummary.Id).ECM_Tax_Code__c != paymentSummary.ECM_Tax_Code__c
                  ||oldPaySumMap.get(paymentSummary.Id).ECM_Invoice_Receival_Date__c != paymentSummary.ECM_Invoice_Receival_Date__c
                  ||oldPaySumMap.get(paymentSummary.Id).ECM_Invoice_Status__c != paymentSummary.ECM_Invoice_Status__c
                  ||oldPaySumMap.get(paymentSummary.Id).ECM_Total_to_be_Invoiced__c != paymentSummary.ECM_Total_to_be_Invoiced__c
                  ||oldPaySumMap.get(paymentSummary.Id).ECM_UoS_Total__c != paymentSummary.ECM_UoS_Total__c
                  ||oldPaySumMap.get(paymentSummary.Id).CurrencyIsoCode != paymentSummary.CurrencyIsoCode
                  ||oldPaySumMap.get(paymentSummary.Id).ECM_No_Invoice_Required__c != paymentSummary.ECM_No_Invoice_Required__c ){
                      paymentSummary.addError(Label.ECM_Approved_Payment_Summary_cannot_be_changed);
                  } 
           }
           
       }
   }
   
   /*
* @description : This method updates the Total Amount Confirmed,Payment Summary Status and Fiscal Year fields of the payment Summaries in the NewMap 
* @return : void
* @param : trigger.Newmap,trigger.OldMap
*/
   public static void updatePaymentSummaryFields(Map <Id,ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> oldPaySumMap){
       
       list<ECM_Payment_Summary__c> psList = new List<ECM_Payment_Summary__c>();
       list<ECM_Payment_Summary__c> paymentSummaryList = new List<ECM_Payment_Summary__c>();
       try{
           for(ECM_Payment_Summary__c paymentSummary:newPaySumMap.Values()){
               
               if(oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c != paymentSummary.ECM_Payment_Summary_Status__c && 
                  paymentSummary.ECM_Payment_Summary_Status__c == 'Approved' && paymentSummary.ECM_Type__c == 'Non-Volume'){ 
                      paymentSummary.ECM_Total_Amount_Confirmed__c =  paymentSummary.ECM_Total_to_be_Invoiced__c;		 								  
                  }
               //End of ECM-4490
               
               if( paymentSummary.ECM_Type__c==system.label.ECM_PromoPrepayment_Type && newPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c==system.label.ECM_Open_Apex && !Map_contract.get(paymentSummary.ECM_Contract__c).ECM_Agreement_Type__r.ECM_Prepayment_SR_approval__c){
                   
                   paymentSummary.ECM_Payment_Summary_Status__c=system.label.ECM_Payment_Summary_Rejected;
               }
               
               if( oldPaySumMap.get(paymentSummary.Id).ECM_Start_Period__c!=paymentSummary.ECM_Start_Period__c || oldPaySumMap.get(paymentSummary.Id).ECM_End_Period__c!=paymentSummary.ECM_End_Period__c){
                   paymentSummaryList.add(paymentSummary);              
               }
               if(oldPaySumMap.get(paymentSummary.Id).ECM_Budget_types__c!=paymentSummary.ECM_Budget_types__c){
                   psList.add(paymentSummary);
               }
               
           }
           if(paymentSummaryList.size()>0){           
               fiscalYearCalculate(paymentSummaryList);           
           }
           
           if(psList.size()>0){           
               updateIOCode(psList);
           }
           
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in updatePaymentSummaryFields method of ECM_PaymentSummaryTriggerHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
       
   }
   /*
* @description : This method checks the PS status and if it is changed from Submitted to Open then Invoice Status is set to 'Rejected'
* @return : void
* @param : trigger.Newmap,trigger.OldMap
//5870
*/
   public static void updatePSInvoiceStatus(Map <Id,ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> oldPaySumMap){
       
       List<String> conLst = new List<String>();
       List<ECM_Technical_Market_Setting__mdt> techMarket = [SELECT Id,ECM_Invoice_Request__c,ECM_Country__c FROM ECM_Technical_Market_Setting__mdt WHERE ECM_Invoice_Request__c=False];
       for (ECM_Technical_Market_Setting__mdt techMarkObj : techMarket){
           conLst.add(techMarkObj.ECM_Country__c);
       }
       
       for(ECM_Payment_Summary__c paymentSummary:newPaySumMap.Values()){
           if(oldPaySumMap.containsKey(paymentSummary.Id) && oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c != paymentSummary.ECM_Payment_Summary_Status__c && 
              paymentSummary.ECM_Payment_Summary_Status__c == 'Open' && oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c == 'Submitted'){ 
                  if(!conLst.isEmpty() && conLst.contains(paymentSummary.ECM_Country_Code__c)){
                      paymentSummary.ECM_Invoice_Status__c = 'Rejected';
                  }		 								  
              }         
       }
   }
   //ECM-6351
   /*
* @description : This method checks the PS status and if it is changed from Submitted,In Approval Process to Open then Email Sent is set to False
* @return : void
* @param : trigger.Newmap,trigger.OldMap
*/
   public static void updateEmailSent(Map <Id,ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> oldPaySumMap){
       for(ECM_Payment_Summary__c paymentSummary:newPaySumMap.Values()){
           if(oldPaySumMap.containsKey(paymentSummary.Id) && oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c != paymentSummary.ECM_Payment_Summary_Status__c && 
              (paymentSummary.ECM_Payment_Summary_Status__c == 'Open') && ((oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c == 'Submitted')|| (oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c == 'In Approval process'))
              && ((paymentSummary.ECM_Type__c == 'Promo-Standard')||(paymentSummary.ECM_Type__c == 'Promo-PrePayment'))){   
                  paymentSummary.ECM_Email_Sent__c = false;
              }
       }
   }
   
   
   /*
* @description : This method checks the Approval Sub Status and initiates the related Approval Process accordingly for the payment Summaries in the NewMap 
* @return : void
* @param : trigger.Newmap,trigger.OldMap
*/
   public static void initiateApprovalProcess(Map <Id,ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> oldPaySumMap){
       
       List<ECM_Payment_Summary__c> extraApprovalList = new  List<ECM_Payment_Summary__c>();
       List<ECM_Payment_Summary__c> additionalExtraApprovalList = new  List<ECM_Payment_Summary__c>();
       List<ECM_Payment_Summary__c> cioApprovalList = new  List<ECM_Payment_Summary__c>();
       List<ECM_Payment_Summary__c> autoApprovalOrRejectList = new  List<ECM_Payment_Summary__c>();
       
       for(ECM_Payment_Summary__c paymentSummary:newPaySumMap.Values()){
           if(oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c!=null){
               paySumMaptoApprovalStatus.put(paymentSummary.Id, oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c);
           }
           system.debug(LoggingLevel.DEBUG,'Approval1-->'+oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c);
           system.debug(LoggingLevel.DEBUG,'Approval2-->'+paymentSummary.ECM_Approval_Sub_Status__c);
           if(oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c!=paymentSummary.ECM_Approval_Sub_Status__c && paymentSummary.ECM_Approval_Sub_Status__c==label.ECM_In_Extra_Approval){
               extraApprovalList.add(paymentSummary);
           }else if(oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c!=paymentSummary.ECM_Approval_Sub_Status__c && paymentSummary.ECM_Approval_Sub_Status__c==label.C360_Extra_Approval_Initial_vs_Actual){                         
               additionalExtraApprovalList.add(paymentSummary); //146081
           }else if(oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c!=paymentSummary.ECM_Approval_Sub_Status__c && paymentSummary.ECM_Approval_Sub_Status__c==label.ECM_CIO_Approval){                         
               cioApprovalList.add(paymentSummary);
           }else if(oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c!=paymentSummary.ECM_Approval_Sub_Status__c && String.isBlank(paymentSummary.ECM_Approval_Sub_Status__c) && (oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c==label.ECM_CIO_Approval || oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c==label.ECM_In_Extra_Approval || oldPaySumMap.get(paymentSummary.Id).ECM_Approval_Sub_Status__c==label.C360_Extra_Approval_Initial_vs_Actual) ){
               autoApprovalOrRejectList.add(paymentSummary);
           }
       }
       
       if(extraApprovalList.size()>0){
           checkForExtraApproval(extraApprovalList);
       }
       if(additionalExtraApprovalList.size()>0){
           checkForAdditionalExtraApproval(additionalExtraApprovalList);
       }
       if(cioApprovalList.size()>0){
           checkForCIOApproval(cioApprovalList);
       }
       if(autoApprovalOrRejectList.size()>0){                      
           updateCIOApproval(autoApprovalOrRejectList);                        
       }
       
   }
   
   /*
* @description : This method updates the confirmed amount of the payment Summary to the related contract for the payment Summaries in the NewMap 
* @return : void
* @param : trigger.Newmap,trigger.OldMap
*/
   public static void UpdatePaymentSummaryConfirmedAmountOnContracts(Map < Id, ECM_Payment_Summary__c > newPaySumMap, Map < Id, ECM_Payment_Summary__c > OldPaySumMap) {
       
       Id AandP_RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();
       Id budgetType_RecordId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
       list < contract > list_to_Update = new list < contract > ();
       
       Map < String, Pick_Up_Options__c > budgetTypeValues = new Map < String, Pick_Up_Options__c > ();
       List < String > BUDGET_TYPE = new List < String > {
           'SKU Specific Rebates [AU]',
               'Upfront Payment [AU]',
               'Portfolio Rebates [AU]'
               };
                   try{
                       for (Pick_Up_Options__c pickOptionRecord: [select id, Name, Geography__r.Name, Status__c, RecordTypeId from Pick_Up_Options__c
                                                                  Where Geography__r.Name =: 'Australia' AND Name IN: BUDGET_TYPE AND Status__c = 'Active'
                                                                  AND RecordTypeId =: budgetType_RecordId
                                                                 ]) {
                                                                     budgetTypeValues.put(pickOptionRecord.Name, pickOptionRecord);
                                                                 }
                       List < ECM_Payment_Summary__c > triggernewrecords = [select id, ECM_Contract__c, ECM_Payment_Summary_Status__c,ECM_Budget_types__c,ECM_Total_Amount_Confirmed__c, ECM_SAP_Payment_Date__c from ECM_Payment_Summary__c
                                                                            where id in: newPaySumMap.keyset()
                                                                            and ECM_contract__r.ECM_Agreement_Type__r.Geography__r.Name =: 'Australia'
                                                                            and ECM_contract__r.status =: 'Active'
                                                                            and ECM_Payment_Summary_Status__c =: 'Completed'
                                                                            and ECM_SAP_Payment_Date__c != null and ECM_Contract__c != null ];
                       
                       Map < id, ECM_Payment_Summary__c > Map_contract_and_contractids = new Map < id, ECM_Payment_Summary__c > ();
                       if (triggernewrecords.size() > 0) {
                           for (ECM_Payment_Summary__c newpaymentsumarryrecord: triggernewrecords) {
                               if(OldPaySumMap.get(newpaymentsumarryrecord.id).ECM_Payment_Summary_Status__c != newpaymentsumarryrecord.ECM_Payment_Summary_Status__c
                                  && newpaymentsumarryrecord.ECM_Payment_Summary_Status__c== 'Completed') 
                                   Map_contract_and_contractids.put(newpaymentsumarryrecord.ECM_Contract__c, newpaymentsumarryrecord);
                               
                           }
                       }
                       if(Map_contract_and_contractids.size() > 0) {
                           for (Id contractId: Map_contract_and_contractids.keySet()){
                               system.debug(LoggingLevel.DEBUG,'xyz--->'+Map_contract_and_contractids.get(contractId).ECM_Budget_types__c);
                               Contract contra = Map_Contract.get(contractId);                               
                               if(budgetTypeValues.size() > 0 ){
                                   if( budgetTypeValues.containskey('Upfront Payment [AU]') && Map_contract_and_contractids.get(contra.id).ECM_Budget_types__c ==budgetTypeValues.get('Upfront Payment [AU]').Id){
                                       if (contra.ECM_Upfront_Payment_Spent__c == null) {
                                           contra.ECM_Upfront_Payment_Spent__c = 0;
                                       }
                                       contra.ECM_Upfront_Last_Payment_date__c = Map_contract_and_contractids.get(contra.id).ECM_SAP_Payment_Date__c;
                                       contra.ECM_Upfront_Payment_Spent__c+=Map_contract_and_contractids.get(contra.id).ECM_Total_Amount_Confirmed__c;
                                   }
                                   else if(  budgetTypeValues.containskey('SKU Specific Rebates [AU]') && Map_contract_and_contractids.get(contra.id).ECM_Budget_types__c ==budgetTypeValues.get('SKU Specific Rebates [AU]').Id){
                                       if (contra.ECM_Contract_SKU_Specific_Rebate_Paid__c == null) {
                                           contra.ECM_Contract_SKU_Specific_Rebate_Paid__c = 0;
                                       }
                                       contra.ECM_Contract_SKU_Specific_Rebate_Paid__c+=Map_contract_and_contractids.get(contra.id).ECM_Total_Amount_Confirmed__c;
                                   }
                                   else if(  budgetTypeValues.containskey('Portfolio Rebates [AU]') && Map_contract_and_contractids.get(contra.id).ECM_Budget_types__c ==budgetTypeValues.get('Portfolio Rebates [AU]').Id){
                                       if (contra.Rebate_Paid__c == null) {
                                           contra.Rebate_Paid__c = 0;
                                       }
                                       contra.Rebate_Paid__c+=Map_contract_and_contractids.get(contra.id).ECM_Total_Amount_Confirmed__c;
                                   }
                               }
                               list_to_Update.add(contra);
                               
                           }
                       }
                       if (list_to_Update.size() > 0) {
                           update list_to_Update;
                       }
                   }catch(Exception e){
                       System.debug(LoggingLevel.DEBUG,'Exception Caught in UpdatePaymentSummaryConfirmedAmountOnContracts method of ECM_PaymentSummaryTriggerHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
                   }
   }
   
   
   /*
* @description : This method fetches a list of Extra approvers who are eligible and then submits an approval request to them.(ECM-4567,ECM-4569)
* @return : void
* @param : trigger.newMap,trigger.OldMap
*/
   public static void updateContractWithPaymentSummaryValues(Map <Id, ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> OldPaySumMap){
       
       try{
           List<ECM_Payment_Summary__c> paymentSummaryList = new List<ECM_Payment_Summary__c> ();               
           Set<Id> contractIdsSet = new Set<Id>();
           Set<Id> budgetIdsSet = new Set<Id>();
           List<Contract> contLst = new List<Contract>();
           decimal val = 0;
           decimal valAP = 0;
           decimal valOther = 0;
           decimal valTraining = 0;
           Map<Id,List<ECM_Payment_Summary__c>>paymentSummaryContractMap= new Map<Id,List<ECM_Payment_Summary__c>>();
           
           for ( ECM_Payment_Summary__c PaymentSummary : OldPaySumMap.Values()) {
               
               if ((PaymentSummary.ECM_Contract__c != null || oldPaySumMap.get(paymentSummary.Id).ECM_Contract__c != PaymentSummary.ECM_Contract__c) && (oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c != newPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c && newPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c=='Completed') ){
                   contractIdsSet.add(PaymentSummary.ECM_Contract__c);
               }
           }
           if(contractIdsSet.size()>0){
               for(ECM_Payment_Summary__c paymentSummary:[select id,ECM_Budget_types__r.Name,ECM_Contract__c,ECM_Payment_Summary_Status__c,ECM_Total_Amount_Confirmed__c from ECM_Payment_Summary__c where ECM_contract__c IN :contractIdsSet AND ECM_Type__c='Non-Volume' AND ECM_Budget_types__c!=null AND ECM_Total_Amount_Confirmed__c!=null]){
                   if(paymentSummary.ECM_Payment_Summary_Status__c =='Completed' || (newPaySumMap.containsKey(paymentSummary.Id) && (newPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c=='Completed') )){
                       if(paymentSummaryContractMap.containsKey(PaymentSummary.ECM_Contract__c)){
                           List<ECM_Payment_Summary__c> paymentSumamryList= new List<ECM_Payment_Summary__c>();
                           paymentSumamryList=paymentSummaryContractMap.get(PaymentSummary.ECM_Contract__c);
                           paymentSumamryList.add(PaymentSummary);
                           paymentSummaryContractMap.put(PaymentSummary.ECM_Contract__c,paymentSumamryList);
                       }else{
                           paymentSummaryContractMap.put(PaymentSummary.ECM_Contract__c,new List<ECM_Payment_Summary__c>{PaymentSummary});
                       }  
                   }
               }
               /*ECM-2519*/
               for (Id contractId : paymentSummaryContractMap.keySet()) {
                   Contract contr = Map_Contract.get(contractId);
                   if(contr.Account.Country__r.name == 'Australia'){                               
                       for(ECM_Payment_Summary__c pas : paymentSummaryContractMap.get(contractId)){
                           if(pas.ECM_Budget_types__r.Name.containsIgnoreCase('A&P')){									
                               valAP += pas.ECM_Total_Amount_Confirmed__c;
                           }else if(pas.ECM_Budget_types__r.Name.containsIgnoreCase('Other')){									
                               valOther += pas.ECM_Total_Amount_Confirmed__c;
                           }else if(pas.ECM_Budget_types__r.Name.containsIgnoreCase('Training')){									
                               valTraining += pas.ECM_Total_Amount_Confirmed__c;
                           }					
                       }
                       if(valAP>0){
                           contr.AP_Spent__c = valAP;
                       }
                       if(valOther>0){
                           contr.ECM_Contract_Other_Spent__c = valOther;
                       }
                       if(valTraining>0){
                           contr.ECM_Contract_Payment_Spent__c = valTraining;
                       }							
                   }
                   contLst.add(contr);
               }
           }
           
           if(contLst.size()>0)
           {
               update contLst;
           }
           
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in updateContractWithPaymentSummaryValues method of ECM_PaymentSummaryTriggerHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
   }			
   
   /*
Description: Method to update spend amount in Internal Order Object with Confirmed Amount Per Payment amount in Payment Summary Item.
@return : void
@param : trigger.newMap,trigger.oldMap
*/ 
   public static void updateInternalOrderSpentAmount(Map<Id,ECm_Payment_Summary__c> newPaySumMap,Map<Id,ECm_Payment_Summary__c> oldPaySumMap){
       
       try{
           Decimal spentAmount;
           Set<Id> pSIds = new Set<Id>();
           
           for(ECM_Payment_Summary__c paymentSummary:newPaySumMap.Values() ){
               
               if(oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c != 'Approved' && paymentSummary.ECM_Payment_Summary_Status__c=='Approved'){
                   
                   pSIds.add(paymentSummary.Id);
               }
               
               
           }
           
           List<String> prodIdLst = new List<String>();
           //Removed from ECM-4490 check
           List<ECM_Payment_Summary_Item__c> paySumItemIds = new List<ECM_Payment_Summary_Item__c>();
           List<ECM_Internal_Order__c> interOrderLst = new List<ECM_Internal_Order__c>();
           List<ECM_Internal_Order__c> interOrderSpentAmtLst = new List<ECM_Internal_Order__c>();
           Map<Id,decimal> paySumItemMap = new Map<Id,decimal>();
           Map<Id,Id> paySumItemIntOdrMap = new Map<Id,Id>();
           Set<String> budgetTypes = new Set<String>();
           Set<String> fiscalYearSet = new Set<String>();
           Set<String> countryCodeSet = new Set<String>();
           if(ECM_Payment_Summary_Item__c.SObjectType.getDescribe().isAccessible()){
               paySumItemIds = [SELECT CurrencyIsoCode,ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirm__c,ECM_Contract_Item__c,ECM_Payment_Summary__c,ECM_Payment_Summary__r.ECM_Budget_types__c,ECM_Payment_Summary__r.ECM_Fiscal_Years__c,ECM_Payment_Summary__r.ECM_Contract__r.Account.Area__c,ECM_Planned_Amount_Per_Payment__c,ECM_Reject__c,ECM_Roll_Over__c,Id,Name,ECM_Contract_Item__r.ECM_Product__r.Product__c,ECM_Internal_Order__c,ECM_Internal_Order__r.Id, ECM_Payment_Summary__r.ECM_Country_Code__c FROM ECM_Payment_Summary_Item__c WHERE ECM_Payment_Summary__c IN:pSIds AND ECM_Confirm__c = true];
           }
           if(paySumItemIds.size()>0){
               for(ECM_Payment_Summary_Item__c paySumObj: paySumItemIds)
               {
                   prodIdLst.add(paySumObj.ECM_Contract_Item__r.ECM_Product__r.Product__c);//Payment Summary Product List
                   //Payment Summary Item Map
                   paySumItemMap.put(paySumObj.ECM_Contract_Item__r.ECM_Product__r.Product__c,paySumObj.ECM_Confirmed_Amount_Per_Payment__c);                   
                   if(paySumObj.ECM_Internal_Order__c != null)
                   {
                       paySumItemIntOdrMap.put(paySumObj.ECM_Contract_Item__r.ECM_Product__r.Product__c, paySumObj.ECM_Internal_Order__r.Id);
                   }   
                   budgetTypes.add(paySumObj.ECM_Payment_Summary__r.ECM_Budget_types__c);               
                   fiscalYearSet.addAll((paySumObj.ECM_Payment_Summary__r.ECM_Fiscal_Years__c).split('/')); 
                   countryCodeSet.add(paySumObj.ECM_Payment_Summary__r.ECM_Country_Code__c);
                   
               }	
           }
           
           // Internal Order Records
           if(ECM_Internal_Order__c.SObjectType.getDescribe().isAccessible()){
               interOrderLst = [ SELECT Id,Name,ECM_Active__c,ECM_Product__c,ECM_Spent_Amount__c, ECM_Geography__r.Name, ECM_Geography__r.Code__c, ECM_Budget_Type_Pickup_Option__c, ECM_Auto_Assignment__c, ECM_Fiscal_Year__c FROM ECM_Internal_Order__c WHERE ECM_Product__c IN : prodIdLst AND ECM_Active__c=true ];
           }
           // Internal Order Product Map
           if(interOrderLst.size()>0){                
               for(ECM_Internal_Order__c inOrdObj : interOrderLst)
               {
                   if(inOrdObj.ECM_Geography__r.Name == System.Label.ECM_Australia || (budgetTypes.contains(inOrdObj.ECM_Budget_Type_Pickup_Option__c) && inOrdObj.ECM_Auto_Assignment__c == true && fiscalYearSet.contains(inOrdObj.ECM_Fiscal_Year__c) && countryCodeSet.contains(inOrdObj.ECM_Geography__r.Code__c)))
                   {
                       if(inOrdObj.ECM_Spent_Amount__c == null){
                           spentAmount = 0.00;
                       }else if(inOrdObj.ECM_Spent_Amount__c != null){
                           spentAmount = inOrdObj.ECM_Spent_Amount__c;
                       }
                       if(inOrdObj.ECM_Geography__r.Name != System.Label.ECM_Australia && paySumItemIntOdrMap.containsKey(inOrdObj.ECM_Product__c) && inOrdObj.Id == paySumItemIntOdrMap.get(inOrdObj.ECM_Product__c))
                       {
                           inOrdObj.ECM_Spent_Amount__c = spentAmount + paySumItemMap.get(inOrdObj.ECM_Product__c);
                       }else if(paySumItemMap.get(inOrdObj.ECM_Product__c) != null)
                       {
                           inOrdObj.ECM_Spent_Amount__c = spentAmount + paySumItemMap.get(inOrdObj.ECM_Product__c);
                       }
                       interOrderSpentAmtLst.add(inOrdObj);
                   }
               }
           }
           if(interOrderSpentAmtLst.size()>0)
           {
               ECM_PaymentSummaryController.updateInternalOrder(interOrderSpentAmtLst);
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in updateInternalOrderSpentAmount method of ECM_PaymentSummaryTriggerHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
   }
   
   /*
* Description: Method to initiate SAP call if the Status of any of the payment Summary in the NewMap is changed to Approved.
* @return : void
* @param : trigger.newMap,trigger.oldMap	
*/ 
   public static void initiateSAPCallout(Map<Id,ECm_Payment_Summary__c> newPaySumMap,Map<Id,ECm_Payment_Summary__c> oldPaySumMap){
       
       Set<Id> pSIds = new Set<Id>();
       Set<Id> nonVolpSIds = new Set<Id>();		
       for(ECM_Payment_Summary__c paymentSummary:newPaySumMap.Values() ){
           
           if(oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c != 'Approved' && paymentSummary.ECM_Payment_Summary_Status__c=='Approved'){			
               if(paymentSummary.ECM_Type__c=='Non-Volume'){
                   nonVolpSIds.add(paymentSummary.Id);
               }else{
                   pSIds.add(paymentSummary.Id);
               }				
           }					
       }
       if(pSIds.size()>0){
           ECM_PaymentSummaryToSAPCallout.getPaymentData(pSIds);
       }
       if(nonVolpSIds.size()>0){
           ECM_PaymentSummaryToSAPCallout.getPaymentDataNonVolume(nonVolpSIds);
       }                    
   }
   
   /*
* @description : This method fetches a list of Extra approvers who are eligible and then submits an approval request to them.(ECM-4567,ECM-4569)
* @return : void
* @param : trigger.new
*/
   public static void checkForExtraApproval(List<ECM_Payment_Summary__c> newPaySumList){
       
       Set<Id> agreementTypeList= new Set<Id>(); 
       Set<String> paymentSummaryTypeSet= new Set<String>(); 
       Map<String,List<ECM_Agreement_Approval__c>>approvalMap = new Map<String,List<ECM_Agreement_Approval__c>>();
       Map<Id,List<Id>>paymentSummaryApproval = new Map<Id,List<Id>>();
       Map<Id,String>userRoleMap= new  Map<Id,String>();
       List<ECM_Payment_Summary__c> additionalExtraApprovalList= new List<ECM_Payment_Summary__c>();
       //List<ECM_Payment_Summary__c> cioApprovalCheckList= new List<ECM_Payment_Summary__c>();
       List<Id>paymentSummaryList= new List<Id>();
       Map<Id,List<Id>>paymentSummaryMap = new Map<Id,List<Id>>();
       Set<Id> paymentSummaryWithToPaySet = new Set<Id>();
       Set<Id> delegatedUserIdSet = new Set<Id>();
       Set<Id> ActivedelegatedUserIdSet = new Set<Id>();
       Map<Id,Id> delegatedUserMap = new Map<Id,Id>();
       
       
       try{
           for(ECM_Payment_Summary__c PaymentSummary:newPaySumList){
               
               if(PaymentSummary.ECM_Contract_Agreement_Type__c!=null){
                   agreementTypeList.add(PaymentSummary.ECM_Contract_Agreement_Type__c);
                   paymentSummaryTypeSet.add(PaymentSummary.ECM_type__c+' PS');
               }
           }    
           //Added for ECM-4787
           paymentSummaryTypeSet.add('Volume Based PS-Target');
           for(ECM_Payment_Summary_Item__c paySumItem:[select ECM_Payment_Summary__c from ECM_Payment_Summary_Item__c where ECM_Payment_Summary__c IN:newPaysumList and ECM_To_Pay__c=true]){
               paymentSummaryWithToPaySet.add(paySumItem.ECM_Payment_Summary__c);
           }
           String ecm_type;
           for(ECM_Agreement_Approval__c agrementApproval: [select id,ECM_Agreement_Type__c,ECM_Extra_Approval__c,ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId,ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c,ECM_Extra_Approval__r.ECM_Type__c,ECM_Extra_Approval__r.ECM_Enable_Delegation__c,ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c,ECM_Extra_Approval_Role__c from ECM_Agreement_Approval__c where ECM_Agreement_Type__c IN:agreementTypeList and ECM_Extra_Approval__r.ECM_Active__c=true and ECM_Extra_Approval__r.ECM_Extra_Approval_User__c!=null and ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.isActive=true and ECM_Extra_Approval__r.ecm_type__c IN:paymentSummaryTypeSet]){
               if(agrementApproval.ECM_Extra_Approval__r.ecm_type__c=='Volume Based PS-Target'){
                   ecm_type='Volume-Based PS';
               }else{
                   ecm_type=agrementApproval.ECM_Extra_Approval__r.ecm_type__c;
               }
               if(approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type)!=null){ 
                   List<ECM_Agreement_Approval__c> eclist=approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type);
                   ecList.add(agrementApproval);
                   approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type,ecList);                
                   
               }else{
                   approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type,new List<ECM_Agreement_Approval__c>{agrementApproval});
               }
               if(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId!=null){
                   delegatedUserIdSet.add(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId);
               }
           }
           
           for(User u: [select id from user where id IN:delegatedUserIdSet and isActive=true]){
               
               ActivedelegatedUserIdSet.add(u.Id);
           }
           
           for(ECM_Payment_Summary__c PaymentSummary:newPaySumList ){
               if(PaymentSummary.ECM_Contract_Agreement_Type__c!=null && approvalMap.get(string.valueOf(PaymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+PaymentSummary.ECM_type__c+' PS')!=null){
                   for(ECM_Agreement_Approval__c extraApproval:approvalMap.get(string.valueOf(PaymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+PaymentSummary.ECM_type__c+' PS')){
                       
                       if((extraApproval.ECM_Extra_Approval__r.ecm_type__c=='Volume Based PS-Target' && paymentSummaryWithToPaySet.contains(PaymentSummary.Id)) || (PaymentSummary.ECM_Total_Amount_Confirmed__c>=extraApproval.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c && PaymentSummary.ECM_Total_Amount_Confirmed__c<=extraApproval.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c) && extraApproval.ECM_Extra_Approval__r.ecm_type__c!='Volume Based PS-Target'){
                           
                           if(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId!=null){
                               userRoleMap.put(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId,' Delegated '+extraApproval.ECM_Extra_Approval_Role__c);
                               
                           }else{
                               userRoleMap.put(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,extraApproval.ECM_Extra_Approval_Role__c);
                               
                           }
                           
                           if(paymentSummaryApproval.get(PaymentSummary.id)!=null){ 
                               List<Id> userlist=paymentSummaryApproval.get(PaymentSummary.id);
                               if( extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId!=null && ActivedelegatedUserIdSet.contains(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId) ){
                                   userlist.add(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId);
                               }else{
                                   userlist.add(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c);
                               }
                               
                               paymentSummaryApproval.put(PaymentSummary.id,userlist);
                               
                           }else{
                               
                               if(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId!=null && ActivedelegatedUserIdSet.contains(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId)){
                                   paymentSummaryApproval.put(PaymentSummary.id,new List<Id>{extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId});
                               }else{
                                   paymentSummaryApproval.put(PaymentSummary.id,new List<Id>{extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c});
                               }
                               
                           }
                       }
                   }               
                   
               }
               
           }
           for(ECM_Payment_Summary__c paymentSummary:newPaySumList ){
               
               if(paymentSummaryApproval.get(paymentSummary.id)!=null){
                   paymentSummaryList.add(paymentSummary.id);
                   if(paymentSummaryApproval.get(paymentSummary.id)!=null){
                       paymentSummaryMap.put(paymentSummary.id,paymentSummaryApproval.get(paymentSummary.id));
                   }
                   
                   
                   checkAndProvideAccountAccess(paymentSummary.ECM_Contract_Account_Id__c,userRoleMap);
                   
               }else{
                   // paymentSummary.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
                   // paymentSummary.ECM_Payment_Summary_Status__c=Label.ECM_Submitted_Status;
                   //cioApprovalCheckList.add(paymentSummary);
                   paymentSummary.ECM_Approval_Sub_Status__c=Label.C360_Extra_Approval_Initial_vs_Actual;
                   paymentSummary.ECM_Payment_Summary_Status__c=Label.ECM_Submitted_Status;
                   additionalExtraApprovalList.add(paymentSummary);
               }             
           }
           
           
           if(!paymentSummaryList.isEmpty()){
               system.enqueueJob(new ECM_PS_ApprovalProcess_Queueable(paymentSummaryList,paymentSummaryMap,userRoleMap));
           }
           
           //if(!cioApprovalCheckList.isEmpty()){
           // checkForCIOApproval(cioApprovalCheckList);
           // }
           if(!additionalExtraApprovalList.isEmpty()){
               checkForAdditionalExtraApproval(additionalExtraApprovalList);
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in checkForExtraApproval method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
   }
   /*
* @description : This method checks if extra approvers have access to the respective account,if not they are provided with the access.(ECM-4567,ECM-4569)
* @return : void
* @param : accountid,userRoleMap
*/
   @future
   public static void checkAndProvideAccountAccess(Id accountId,Map<Id,String>userRoleMap){        
       
       Map<Id,AccountShare>accShareMap= new Map<Id,AccountShare>();
       List<AccountShare>accountShareList= new List<AccountShare>();
       try{
           for(AccountShare accShare:[select id,userOrGroupId from accountshare where userOrGroupId IN:userRoleMap.keySet() and accountId=:accountId]){
               accShareMap.put(accShare.userOrGroupId,accShare);
           }
           for(Id userId:userRoleMap.keySet()){
               if(accShareMap.get(userId)==null){
                   AccountShare accountShare= new AccountShare();
                   accountShare.accountId=accountId;
                   accountShare.UserOrGroupid=userId;
                   accountShare.accountaccessLevel='Edit';
                   accountShare.OpportunityAccessLevel='None';
                   accountShareList.add(accountShare);
               }
           }
           
           if(!accountShareList.isEmpty()){
               database.insert(accountShareList);
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in checkAndProvideAccountAccess method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
   }
   
   /*
* @description : This method checks if all extra approvers have approved,if yes then the CIO users are fetched
from the queue related to the country and approval request are sent to them.(ECM-4567,ECM-4569)
* @return : void
* @param : trigger.new
*/  
   public static void checkForCIOApproval(List<ECM_Payment_Summary__c> newPaySumList){
       
       Set<Id> paymentSummaryList= new Set<Id>(); 
       Map<Id,List<ProcessInstanceWorkitem>>approvalMap = new Map<Id,List<ProcessInstanceWorkitem>>();
       List<Id>userIdList= new List<Id>();
       List<Id>memberIdList= new List<Id>();
       Set<String>paymentSummaryCountrySet= new Set<String>();
       Map<String,List<Id>>memberIdGroup= new Map<String,List<Id>>();
       List<Id> paymentSummariesList= new List<Id>();
       Map<Id,List<Id>> paymentSummaryMap = new  Map<Id,List<Id>>();
       //Map<Id,String> paySumMaptoApprovalStatus = new MAp<Id,String>();
       
       try{
           for(ECM_Payment_Summary__c paymentSummary:newPaySumList ){
               paymentSummaryList.add(paymentSummary.Id); 
               paymentSummaryCountrySet.add(paymentSummary.ECM_Country_Code__c+'_CIO');
           }
           system.debug(LoggingLevel.DEBUG,'paymentSummaryCountrySet-->'+paymentSummaryCountrySet);
           for(ProcessInstanceWorkitem item: [SELECT Id, ProcessInstanceId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN :paymentSummaryList]){
               if(approvalMap.get(item.ProcessInstance.TargetObjectId)!=null){               
                   List<ProcessInstanceWorkitem> tempList=approvalMap.get(item.ProcessInstance.TargetObjectId);
                   tempList.add(item);
                   approvalMap.put(item.ProcessInstance.TargetObjectId,tempList);
               }else{
                   approvalMap.put(item.ProcessInstance.TargetObjectId,new List<ProcessInstanceWorkitem>{item});
               }           
           }
           for(User userDetails:[select id from user where isActive=true and profile.name LIKE '%CIO%']){
               userIdList.add(userDetails.Id);
           }
           for(GroupMember grpmember:[Select id,UserOrGroupId,group.type,group.Name from GroupMember where group.type='Queue' and group.Name IN :paymentSummaryCountrySet]){
               memberIdList.add(grpmember.userOrGroupId);
               if(memberIdGroup.get(grpmember.group.Name)!=null){
                   List<Id>userList=memberIdGroup.get(grpmember.group.Name);
                   if(userIdList.contains(grpmember.userOrGroupId)){
                       userList.add(grpmember.userOrGroupId);
                       memberIdGroup.put(grpmember.group.Name,userList);
                   }
               }else{
                   if(userIdList.contains(grpmember.userOrGroupId)){
                       memberIdGroup.put(grpmember.group.Name,new List<Id>{grpmember.userOrGroupId});
                   }
               }
           }
           
           
           for(ECM_Payment_Summary__c paymentSummary:newPaySumList ){
               
               if(approvalMap.get(paymentSummary.Id)!=null && approvalMap.get(paymentSummary.id).size()>1 && paySumMaptoApprovalStatus.containsKey(paymentSummary.Id)){
                   paymentSummary.ECM_Approval_Sub_Status__c=paySumMaptoApprovalStatus.get(paymentSummary.Id);
                   paymentSummary.ECM_Payment_Summary_Status__c=Label.ECM_In_Approval_Process_Apex;
               }else{
                   paymentSummariesList.add(paymentSummary.id);            
                   if(memberIdGroup.get(paymentSummary.ECM_Country_Code__c+'_CIO')!=null){
                       paymentSummaryMap.put(paymentSummary.id,memberIdGroup.get(paymentSummary.ECM_Country_Code__c+'_CIO'));
                   }
               }             
           }
           
           if(!paymentSummaryList.isEmpty()){
               system.enqueueJob(new ECM_PS_ApprovalProcess_Queueable(paymentSummariesList,paymentSummaryMap,null));
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in checkForCIOApproval method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
   }
   
   /*
* @description : This method checks if any of the request is rejected , if yes then all approval requests related to
the payment summary are rejected.(ECM-4567,ECM-4569) 
* @return : void
* @param : trigger.new
*/        
   @Future
   public static void updateCIOApprovalRecords(Set<Id> paymentSummaryList){
       
       Map<Id,List<ProcessInstanceWorkitem>>approvalMap = new Map<Id,List<ProcessInstanceWorkitem>>();
       Map<Id,String>paymentSummaryMap= new Map<Id,String>();
       List<Id>userIdList= new List<Id>();
       
       try{
           for(ECM_Payment_Summary__c paymentSummary:[select id,ECM_Payment_Summary_Status__c,ECM_Approval_Sub_Status__c from ECM_Payment_Summary__c where id IN:paymentSummaryList ] ){
               
               paymentSummaryMap.put(paymentSummary.Id,paymentSummary.ECM_Payment_Summary_Status__c);
           }
           
           boolean isRejected;
           boolean isApproved;
           String Username;
           List<Approval.ProcessWorkitemRequest> ProcessWorkitemRequestList = new List<Approval.ProcessWorkitemRequest>();
           //for(ProcessInstanceWorkitem item: [SELECT Id, ProcessInstanceId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN :paymentSummaryList]){
           for(ProcessInstance pInstance: [SELECT Id,TargetObjectId, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems),(SELECT Id, ActorId,Actor.Name,StepStatus,OriginalActorId FROM Steps)  FROM ProcessInstance where TargetObjectId IN :paymentSummaryList order by lastmodifieddate desc]){
               system.debug(LoggingLevel.DEBUG,'PiStep--->'+pInstance);
               if(isRejected==null && isApproved==null && String.isBlank(Username)){
                   for(processInstanceStep pInstanceStep:pInstance.Steps){
                       system.debug(LoggingLevel.DEBUG,'PiStep1--->'+pInstanceStep);
                       if(pInstanceStep.StepStatus==Label.ECM_Payment_Summary_Rejected){
                           isRejected=true;
                           Username=pInstanceStep.Actor.name;
                           break;
                       }else if(pInstanceStep.StepStatus==Label.ECM_Payment_Summary_Approved && paymentSummaryMap.get(pInstance.TargetObjectId)==Label.ECM_Payment_Summary_Approved){
                           isApproved=true;
                           Username=pInstanceStep.Actor.name;
                           break;
                       }
                       
                   }
               }
               if(pInstance.Workitems!=null && pInstance.Workitems.size()>0){
                   
                   if(isRejected!=null && isRejected==true){
                       for(ProcessInstanceWorkitem processWorkitem:pInstance.Workitems){
                           Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest(); 
                           pwr.setAction('Reject');
                           pwr.setComments(Label.ECM_Approval_Request_Rejected_By+' '+Username+'.');
                           pwr.setWorkItemId(processWorkitem.id);
                           ProcessWorkitemRequestList.add(pwr);
                       }
                   }
                   
                   if(isApproved!=null && isApproved==true){
                       for(ProcessInstanceWorkitem processWorkitem:pInstance.Workitems){
                           Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest(); 
                           pwr.setAction('Approve');
                           pwr.setComments(Label.ECM_Approval_Request_Approved_By+' '+Username+'.');
                           pwr.setWorkItemId(processWorkitem.id);
                           ProcessWorkitemRequestList.add(pwr);
                       }
                       
                   }
                   
               }   
           }
           
           if(ProcessWorkitemRequestList.Size()>0){
               
               List<Approval.ProcessResult> resultList = Approval.process( ProcessWorkitemRequestList );
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in updateCIOApprovalRecords method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
   } 
   
   /*
* @description : This method calls the future method updateCIOApprovalRecords which updates all the approval request records
to either rejected or approved based on the input from the user.(ECM-4567,ECM-4569) 
* @return : void
* @param : trigger.new
*/        
   public static void updateCIOApproval(List<ECM_Payment_Summary__c> newPaySumList){
       
       Set<Id> paymentSummaryList= new Set<Id>();         
       for(ECM_Payment_Summary__c paymentSummary:newPaySumList ){
           paymentSummaryList.add(paymentSummary.Id);
       }
       updateCIOApprovalRecords(paymentSummaryList);
       
   }
   
   /*
* @description : Contract Approval or rejection notification for Sales rep.(ECM-4620) 
* @return : void
* @param : trigger.new,trigger.OldMap
*/ 
   public static void sendPushNotificationForPF(Map<Id,ECM_Payment_Summary__c> newItems, Map<Id, sObject> oldItems){
       
       try{
           
           Map<Id, ECM_Payment_Summary__c> mapOldItems = new Map <Id, ECM_Payment_Summary__c>();
           Set<Id> psIdSet = new Set<Id>();
           if (oldItems != null) {
               mapOldItems = (Map<Id, ECM_Payment_Summary__c>) oldItems;
           }
           if(newItems!=null){
               for(ECM_Payment_Summary__c psObj : newItems.Values()){
                   if(psObj.ECM_Payment_Summary_Status__c.equals('Open') && mapOldItems!=null && mapOldItems.containsKey(psObj.Id) 
                      
                      && mapOldItems.get(psObj.Id).ECM_Payment_Summary_Status__c != psObj.ECM_Payment_Summary_Status__c && (System.Label.ECM_Types_for_Rejection.contains(psObj.ECM_Type__c))){
                          
                          psIdSet.add(psObj.Id);
                          System.debug(LoggingLevel.DEBUG,psObj.Name);
                          System.debug(LoggingLevel.DEBUG,psObj.ECM_Payment_Summary_Status__c);
                      }                   
               } 
               if(!psIdSet.isEmpty() || Test.isRunningTest()){
                   getPIStep(psIdSet);
               }
           }
           
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in sendPushNotificationForPF method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
   }
   
   
   /*
* @description : Contract Approval or rejection notification for Sales rep.(ECM-4764) 
* @return : void
* @param : PaymentSummaryIdSet
*/
   @future
   public static void getPIStep(Set<Id> psIdSet){
       List<ECM_Payment_Summary__c> psList = new List<ECM_Payment_Summary__c>();
       Map<Id, ProcessInstanceStep> psRejLogMap = new Map<Id, ProcessInstanceStep>();
       Map<String, Object> custom = new Map<String, Object>(); 
       DateTime currDtTime = System.now();
       currDtTime = currDtTime.addMinutes(-2);
       
       try{
           psList = [SELECT Id,Name,ECM_Contract__c,Owner__c,LastmodifiedDate,ECM_Contract__r.ContractNumber,ECM_Contract__r.Owner.LanguageLocaleKey
                     FROM ECM_Payment_Summary__c 
                     WHERE Id IN : psIdSet];
           for(ProcessInstanceStep rejLogObj :  [SELECT Id,Actor.Email,Comments,ProcessInstance.TargetObjectId,StepStatus,CreatedDate
                                                 FROM ProcessInstanceStep
                                                 WHERE ProcessInstance.TargetObjectId IN: psIdSet 
                                                 AND StepStatus= 'Rejected'
                                                 AND CreatedDate >:currDtTime
                                                 ORDER BY CreatedDate ASC]){
                                                     String cmpKey = String.valueOf(rejLogObj.ProcessInstance.TargetObjectId);
                                                     
                                                     if(rejLogObj.Comments==null || !rejLogObj.Comments.startsWithIgnoreCase(Label.ECM_Payment_Summary_Generic_Approval_Message)){
                                                         psRejLogMap.put(cmpKey, rejLogObj);                                
                                                     }
                                                 }
           for(ECM_Payment_Summary__c psObj : psList){
               String cmpKey = String.valueOf(psObj.Id);
               String notificationTxt ='';
               if(!psRejLogMap.isEmpty() && psRejLogMap.containsKey(cmpKey)){
                   String email = psRejLogMap.get(cmpKey).Actor.Email;
                   String comments = psRejLogMap.get(cmpKey).Comments;
                   if(comments==null){
                       comments='';
                   }
                   if(psObj.ECM_Contract__r.Owner.LanguageLocaleKey == 'de'){
                       notificationTxt = Label.ECM_Payment_Summary_Message_DE.replace('****',psObj.Name)+' '+psObj.ECM_Contract__r.ContractNumber+' '+Label.ECM_Contract_Push_Notification_Rejected_Message_DE.replace('&&&&',email).replace('####',comments);
                   }else{
                       notificationTxt = Label.ECM_Payment_Summary_Message.replace('****',psObj.Name)+' '+psObj.ECM_Contract__r.ContractNumber+' '+Label.ECM_Contract_Push_Notification_Rejected_Message.replace('&&&&',email).replace('####',comments);
                   }                    
                   custom.put('PaymentSummaryId',psObj.Id);
                   custom.put('ContractId',psObj.ECM_Contract__c);
                   custom.put('OwnerId',psObj.Owner__c);
                   System.debug(LoggingLevel.DEBUG,'@@notificationTxt'+notificationTxt);
                   EDGE_PushNotificationHelper.pushNotificationMethod(null, notificationTxt, custom);
               }
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in getPIStep method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
       
   }
   
   /*
* Description: Method to calculate Fiscal Year in Payment Summary.
* @return : void
* @param : trigger.new
*/ 
   public static void fiscalYearCalculate(List<ECM_Payment_Summary__c> newPaySumList){        
       try{
           for(ECM_Payment_Summary__c newPaySum:newPaySumList){
               if(newPaySum.ECM_Start_Period__c!=null && newPaySum.ECM_End_Period__c!=null){    
                   Date startDate = newPaySum.ECM_Start_Period__c;
                   Date endDate = newPaySum.ECM_End_Period__c;
                   Integer startDateMonth = startDate.month();
                   Integer endDateMonth = endDate.month();
                   Integer startDateYear = startDate.year();
                   Integer endDateYear = endDate.year();
                   String fiscalYear = '';
                   for(integer i=startDateYear; i<= endDateYear; i++){
                       integer dateYear = i;
                       if(i==startDateYear){
                           if(startDateMonth<7){
                               fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                           }
                       }
                       if(i==endDateYear){
                           if(startDateYear == endDateYear){
                               if(startDateMonth<7 && endDateMonth >= 7){
                                   dateYear = dateYear+1;
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                               if(startDateMonth >= 7 && endDateMonth >= 7){
                                   dateYear = dateYear+1;
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                           }
                           else if(startDateYear+1 == endDateYear){
                               if(startDateMonth < 7 && endDateMonth < 7){
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                               if(startDateMonth >= 7 && endDateMonth < 7){
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                               if(startDateMonth >= 7 && endDateMonth >= 7){
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                   dateYear = dateYear+1;
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                               if(startDateMonth < 7 && endDateMonth >= 7){
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                   dateYear = dateYear+1;
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                           }
                           else{
                               if(endDateMonth >= 7){
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                   dateYear = dateYear+1;
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                               else{
                                   fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                               }
                           }
                       }
                       if(i != startDateYear && i != endDateYear){
                           fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                       }
                   }
                   
                   newPaySum.ECM_Fiscal_Years__c = fiscalYear.removeEndIgnoreCase('/');
                   system.debug(LoggingLevel.DEBUG,'Start date-->'+startDate);
                   system.debug(LoggingLevel.DEBUG,'End date-->'+endDate);
                   system.debug(LoggingLevel.DEBUG,'End date-->'+newPaySum.ECM_Fiscal_Years__c);
                   
                   
               }
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in fiscalYearCalculate method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
   }
   
   /*
* @description: Method to update CTD Overall Investment,CTD A&P Investment,CTD Trade Lump Sum Calculation in Contract and Contract Item Object with 
* Sum(Total Amount Confirmed) and Sum(Confirmed amount per payment) of Payment Summary and Payment Summary Item Object : ECM-5292,ECM-5301,ECM-5294
* @return : void
* @param : trigger.newMap,trigger.oldMap
* @Modification Log :
* ECM-5682 - Abhijeet Mishra - update 'Payment Summary Approved' in Contract
* ECM-5677 - Pratap Sen - update 'Last Volume Information Date' in Contract
* ECM-5775 - Pratap Sen - update 'CTD Overall Investment' in Contract Item
*/ 
   public static void updateCTDValues(Map <Id, ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> OldPaySumMap) {
       try{        
           Map<Id,Decimal> paymentSummaryContractMap = new Map<Id,Decimal>();
           Map<Id,Decimal> pSIContractItemMapTI = new Map<Id,Decimal>();
           Map<Id,Decimal> pSIContractItemMapAP = new Map<Id,Decimal>();
           Map<Id,Decimal> pSIContractItemMapOverall = new Map<Id,Decimal>();//ECM-5775
           Map<Id,Decimal> pSIContractItemMapTemp = new Map<Id,Decimal>();
           Map<Id,ECM_Contract_Item__c> contractItemMap;
           Map<Id,Contract> contractMap;
           Set<Id> contractIdsSet = new Set<Id>();
           Set<Id> psIdsSet = new Set<Id>();
           Set<ECM_Contract_Item__c> conItemLst = new Set<ECM_Contract_Item__c>();
           Set<Id> conIdforLastVolInfoUpdate = new Set<Id>();//ECM-5677
           List<Contract> contLst = new List<Contract>();
           Decimal invAmount = 0;
           Boolean isTi;
           Boolean isAP;
           
           if(oldPaySumMap != null){
               for (ECM_Payment_Summary__c paymentSummary : newPaySumMap.Values()) { 
                   if (paymentSummary.ECM_Country_Code__c != Label.ECM_CountryCodeAU && oldPaySumMap.containsKey(paymentSummary.Id) &&
                       (oldPaySumMap.get(paymentSummary.Id).ECM_Payment_Summary_Status__c != paymentSummary.ECM_Payment_Summary_Status__c && 
                        paymentSummary.ECM_Payment_Summary_Status__c.equals(Label.ECM_PS_ApprovedStatusInPSTrigger))){
                            contractIdsSet.add(paymentSummary.ECM_Contract__c);
                            psIdsSet.add(paymentSummary.Id);                         
                        }
               }
           }
           System.debug(LoggingLevel.DEBUG,'contractIdsSet'+contractIdsSet);
           System.debug(LoggingLevel.DEBUG,'psIdsSet'+psIdsSet);
           if(!contractIdsSet.isEmpty()) {                
               contractItemMap = new Map<Id,ECM_Contract_Item__c>([SELECT Id,ECM_Net_Net_List_Price__c,ECM_Actual_Volume_YTD__c,ECM_CTD_Total_NSV__c,ECM_CTD_A_P_Investment__c,
                                                                   ECM_CTD_Trade_Lump_Sum__c,ECM_CTD_Overall_Investment__c,ECM_UoM__c,ECM_Contract__c 
                                                                   FROM ECM_Contract_Item__c 
                                                                   WHERE ECM_Contract__c IN: contractIdsSet]);                
               contractMap = new Map<Id,Contract>([SELECT Id,ECM_CTD_Overall_Investment__c,ECM_Last_Volume_Information_Update__c,ECM_Payment_Frequency_type__r.ECM_Type__c,
                                                   ECM_Payment_Summary_Approved__c
                                                   FROM Contract
                                                   WHERE Id IN: contractIdsSet]);
               System.debug(LoggingLevel.DEBUG,'contractItemMap'+contractItemMap);
               System.debug(LoggingLevel.DEBUG,'contractMap'+contractMap);
               if(contractMap!= null && !contractMap.isEmpty()){                   
                   for(Contract conObj : contractMap.values()){                       
                       paymentSummaryContractMap.put(conObj.Id,conObj.ECM_CTD_Overall_Investment__c);
                   }
               }                               
               for(ECM_Payment_Summary__c paymentSummary : [SELECT Id,ECM_Contract__c,ECM_Type__c,ECM_Budget_types__r.Name,ECM_Payment_Summary_Status__c,ECM_Total_Amount_Confirmed__c,
                                                            (SELECT id,ECM_Contract_Item__c,ECM_Confirmed_Amount_Per_Payment__c FROM Payment_Summary_Item__r) 
                                                            FROM ECM_Payment_Summary__c
                                                            WHERE Id IN : psIdsSet 
                                                            AND ECM_Total_Amount_Confirmed__c != null 
                                                            AND ECM_Budget_types__c != null])
               {
                   if(paymentSummaryContractMap.containsKey(paymentSummary.ECM_Contract__c)){ //For 'CTD Overall Investment' in Contract                       
                       invAmount = (paymentSummaryContractMap.get(paymentSummary.ECM_Contract__c) != null)?paymentSummaryContractMap.get(paymentSummary.ECM_Contract__c):0;
                       if(paymentSummary.ECM_Total_Amount_Confirmed__c != null){                            
                           invAmount += paymentSummary.ECM_Total_Amount_Confirmed__c;                           
                       }                        
                       paymentSummaryContractMap.put(paymentSummary.ECM_Contract__c,invAmount);
                   }
                   isTi = false;
                   isAP = false;
                   if(System.Label.ECM_Promo_PrePayment.contains(paymentSummary.ECM_Type__c)) { //Assign Specific Map depending on budget type for Promo Type PS
                       if(paymentSummary.ECM_Budget_types__r.Name.containsIgnoreCase('TI')) {
                           isTi = true;
                           pSIContractItemMapTemp = pSIContractItemMapTI;
                       } else if(paymentSummary.ECM_Budget_types__r.Name.containsIgnoreCase('A&P')) {
                           isAP = true;
                           pSIContractItemMapTemp = pSIContractItemMapAP;
                       }
                   } else if(contractMap.containsKey(paymentSummary.ECM_Contract__c) && 
                             !System.Label.ECM_PFforActualVolumeYTD.contains(contractMap.get(paymentSummary.ECM_Contract__c).ECM_Payment_Frequency_type__r.ECM_Type__c)){
                                 conIdforLastVolInfoUpdate.add(paymentSummary.ECM_Contract__c); //Filter contract for specific PF and with Approved Volume Based PS to update 'Last Volume Information Date'
                             }
                   //calculate CI level values from PSI confirmed Amount Per Payment
                   for(ECM_Payment_Summary_Item__c psi : paymentSummary.Payment_Summary_Item__r){
                       invAmount = (psi.ECM_Confirmed_Amount_Per_Payment__c != null)? psi.ECM_Confirmed_Amount_Per_Payment__c : 0;
                       if(pSIContractItemMapOverall.containsKey(psi.ECM_Contract_Item__c)){
                           invAmount += pSIContractItemMapOverall.get(psi.ECM_Contract_Item__c); 
                       } 
                       pSIContractItemMapOverall.put(psi.ECM_Contract_Item__c,invAmount);//For 'CTD Overall Investment' in Contract Item
                       System.debug(LoggingLevel.DEBUG,'pSIContractItemMapOverall'+pSIContractItemMapOverall);
                       if(isTi || isAP){
                           invAmount = (psi.ECM_Confirmed_Amount_Per_Payment__c != null)? psi.ECM_Confirmed_Amount_Per_Payment__c : 0;
                           if(pSIContractItemMapTemp.containsKey(psi.ECM_Contract_Item__c)){
                               invAmount += pSIContractItemMapTemp.get(psi.ECM_Contract_Item__c); 
                           } 
                           pSIContractItemMapTemp.put(psi.ECM_Contract_Item__c,invAmount);
                       }
                   }
                   if(isTi){
                       pSIContractItemMapTI = pSIContractItemMapTemp;
                   } else if(isAP){
                       pSIContractItemMapAP = pSIContractItemMapTemp;
                   }
               }
               //Update values in Contract fields of Contract Map
               for (Id contractId : paymentSummaryContractMap.keySet()) {
                   if(contractMap.containsKey(contractId)){
                       Contract contr = contractMap.get(contractId);
                       //Commented below due to ECM-6307 and transferred same logic to Contract Item Trigger
                       /*
if(contr.ECM_CTD_Overall_Investment__c == null){
contr.ECM_CTD_Overall_Investment__c = 0;
}
contr.ECM_CTD_Overall_Investment__c = paymentSummaryContractMap.get(contractId); //update 'CTD Overall Investment' in Map
*/
                       contr.ECM_Payment_Summary_Approved__c = true; //ECM-5682 - update 'Payment Summary Approved' in Map
                       if(conIdforLastVolInfoUpdate.contains(contr.Id)){ //ECM-5677 - update 'Last Volume Information Date' in Map
                           contr.ECM_Last_Volume_Information_Update__c = System.today();
                       }                      
                       contLst.add(contr);
                   }                    
               }
               //Update KPI values in Contract Item fields of Contract Item Map
               for(Id contractItemId : contractItemMap.keySet()){
                   ECM_Contract_Item__c contrItem = contractItemMap.get(contractItemId);
                   //update 'CTD Trade Lump Sum Calculation' & 'CTD Total NSV' in Map
                   if(pSIContractItemMapTI.containsKey(contractItemId)){
                       if(contrItem.ECM_CTD_Trade_Lump_Sum__c == null){
                           contrItem.ECM_CTD_Trade_Lump_Sum__c = 0;
                       }
                       contrItem.ECM_CTD_Trade_Lump_Sum__c += pSIContractItemMapTI.get(contractItemId);
                   }
                   //update 'CTD A&P Investment' in Map
                   if(pSIContractItemMapAP.containsKey(contractItemId)){
                       if(contrItem.ECM_CTD_A_P_Investment__c == null){
                           contrItem.ECM_CTD_A_P_Investment__c = 0;
                       }
                       contrItem.ECM_CTD_A_P_Investment__c = contrItem.ECM_CTD_A_P_Investment__c + pSIContractItemMapAP.get(contractItemId);
                   }
                   //update 'CTD Overall Investment' in Map
                   System.debug(LoggingLevel.DEBUG,'pSIContractItemMapOverall.containsKey(contractItemId)'+pSIContractItemMapOverall.containsKey(contractItemId));
                   if(pSIContractItemMapOverall.containsKey(contractItemId)){
                       contrItem.ECM_CTD_Overall_Investment__c = (contrItem.ECM_CTD_Overall_Investment__c == null)? pSIContractItemMapOverall.get(contractItemId):
                       contrItem.ECM_CTD_Overall_Investment__c + pSIContractItemMapOverall.get(contractItemId);
                   }
                   System.debug(LoggingLevel.DEBUG,'contrItem.ECM_CTD_Overall_Investment__c'+contrItem.ECM_CTD_Overall_Investment__c);
                   conItemLst.add(contrItem);
               }
           }
           if(contLst.size()>0){
               update contLst;
           } 
           if(conItemLst.size()>0){
               List<ECM_Contract_Item__c> contItLst = new List<ECM_Contract_Item__c>(conItemLst);
               update contItLst;
           }             
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in updateCTDValues method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }        
   }
   
   /* @description : This method calls the ECM_PaymentSummaryEmailHandler sendEmail when the Invoice Status is set to Requested
* @return : void
* @param :
ECM-5870
*/
   public static void sendInvocePSEmail(Map <Id, ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> OldPaySumMap){
       List<Id> psinvoceList = new List<Id>();
       List<String> conLst = new List<String>();
       List<ECM_Technical_Market_Setting__mdt> techMarket = [SELECT Id,ECM_Invoice_Request__c,ECM_Country__c FROM ECM_Technical_Market_Setting__mdt WHERE ECM_Invoice_Request__c=False];
       for (ECM_Technical_Market_Setting__mdt techMarkObj : techMarket){
           conLst.add(techMarkObj.ECM_Country__c);
       }
       
       if(OldPaySumMap != null){
           
           for (ECM_Payment_Summary__c paymentSummary : newPaySumMap.Values()) { 
               
               if (oldPaySumMap.containsKey(paymentSummary.Id) &&
                   oldPaySumMap.get(paymentSummary.Id).ECM_Invoice_Status__c != paymentSummary.ECM_Invoice_Status__c && 
                   paymentSummary.ECM_Invoice_Status__c=='Requested'){
                       System.debug(LoggingLevel.DEBUG,'payment summ test '+paymentSummary.Id);
                       if(!conLst.isEmpty() && conLst.contains(paymentSummary.ECM_Country_Code__c)){
                           psinvoceList.add(paymentSummary.id);
                           
                       }                       
                   }
           }
       }
       
       ECM_PaymentSummaryEmailHandler.sendInvEmail(psinvoceList);
   }  
   /* @description : This method holds the logic of sending the Rejection Email to Rep
* @return : void
* @param :Map <Id, ECM_Payment_Summary__c> NewMap, OldMap
*/
   public static void sendRejectionEmail(Map <Id, ECM_Payment_Summary__c> newPaySumMap, Map <Id,ECM_Payment_Summary__c> OldPaySumMap) {
       
       List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
       List<Id>sendRejectionEmailList = new List<Id>();
       Set<Id>geoCountry = new Set<Id>();
       for(ECM_Payment_Summary__c mailPS : newPaySumMap.Values()){
           if(Map_Contract.containsKey(mailPS.ECM_Contract__c)){
               geoCountry.add(Map_Contract.get(mailPS.ECM_Contract__c).Account.Country__c); 
           }
       }
       Map<String,Market_Setting__c> marketGeoMap =new Map<String,Market_Setting__c> ();
       for(Market_Setting__c market :[SELECT Id, Name__c,ECM_Rejection_Email_to_Sales_Rep__c,Geography__c,Geography__r.Name FROM Market_Setting__c WHERE Geography__c IN : geoCountry]){
           marketGeoMap.put(market.Geography__c,market);
       }
       map<Id,ECM_Payment_Summary__c> PaySummarymap = new map<Id,ECM_Payment_Summary__c>();
       for(Id paySumId:newPaySumMap.keySet()) {
           system.debug(LoggingLevel.DEBUG,'new --->'+newPaySumMap.get(paySumId).ECM_Payment_Summary_Status__c);
           system.debug(LoggingLevel.DEBUG,'old --->'+OldPaySumMap.get(paySumId).ECM_Payment_Summary_Status__c);
           system.debug(LoggingLevel.DEBUG,'contract --->'+Map_Contract.get(newPaySumMap.get(paySumId).ecm_contract__c));
           system.debug(LoggingLevel.DEBUG,'Geomap --->'+marketGeoMap.get(Map_Contract.get(newPaySumMap.get(paySumId).ecm_contract__c).Account.country__c)); 
           
           if(newPaySumMap.get(paySumId).ECM_Payment_Summary_Status__c != OldPaySumMap.get(paySumId).ECM_Payment_Summary_Status__c && 
              newPaySumMap.get(paySumId).ECM_Payment_Summary_Status__c=='Open' && 
              (OldPaySumMap.get(paySumId).ECM_Payment_Summary_Status__c=='In Approval Process' || OldPaySumMap.get(paySumId).ECM_Payment_Summary_Status__c =='Submitted')){
                  
                  if( Map_Contract.get(newPaySumMap.get(paySumId).ecm_contract__c)!=null && marketGeoMap.get(Map_Contract.get(newPaySumMap.get(paySumId).ecm_contract__c).Account.country__c).ECM_Rejection_Email_to_Sales_Rep__c ){
                      sendRejectionEmailList.add(paySumId);
                  }
              }
       }
       if(!sendRejectionEmailList.isEmpty()){
           sendRejectionEmailToSalesRep(sendRejectionEmailList);
       }
   }
   
   @future
   public static void sendRejectionEmailToSalesRep(List<Id>sendRejectionEmailList){
       
       try{
           List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
           Map<id,ECM_Payment_Summary__c>PaySummarymap= new Map<id,ECM_Payment_Summary__c>();
           for(ECM_Payment_Summary__c paySum : [SELECT Id,Name,ecm_contract__r.owner.name,ecm_contract__r.ownerId,ecm_contract__r.owner.email FROM ECM_Payment_Summary__c WHERE Id IN:sendRejectionEmailList]) {
               PaySummarymap.put(paySum.id,paySum);                  
           }
           
           List<Emailtemplate> emailtemplateList = [SELECT Id FROM emailtemplate WHERE developername =: System.Label.ECM_PaymentSummary_Rejection];
           for(Id paySum: sendRejectionEmailList) {
               Messaging.SingleEmailMessage email= new Messaging.SingleEmailMessage();
               email.setTemplateid(emailtemplateList[0].Id);
               email.setTargetObjectid(PaySummarymap.get(paySum).ecm_contract__r.ownerId);
               email.setwhatId(paySum);
               email.setToAddresses(new List<String>{PaySummarymap.get(paySum).ecm_contract__r.owner.email});
               email.setSaveAsActivity(false);
               emailList.add(email);
           }
           Messaging.SendEmailResult[] r = Messaging.sendEmail(emailList);
       } catch(Exception ex){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in sendRejectionEmailToSalesRep method of ECM_PaymentSummaryTriggerHelper at Line: '+ex.getLineNumber()+' Error: '+ex.getMessage());
       }
       
   }
   
   /*
* @description : This method fetches a list of Extra approvers
* @return : void
* @param : 
*/
   //Added as part of ECM-5871 start 
   public static List<Id> checkForExtraApprovalAvailability(List<ECM_Payment_Summary__c> newPaySumList){
       
       Set<Id> agreementTypeList= new Set<Id>(); 
       Set<String> paymentSummaryTypeSet= new Set<String>(); 
       Map<String,List<ECM_Agreement_Approval__c>>approvalMap = new Map<String,List<ECM_Agreement_Approval__c>>();
       Map<Id,List<Id>>paymentSummaryApproval = new Map<Id,List<Id>>();
       Map<Id,String>userRoleMap= new  Map<Id,String>();
       List<ECM_Payment_Summary__c> cioApprovalCheckList= new List<ECM_Payment_Summary__c>();
       List<Id>paymentSummaryList= new List<Id>();
       //Map<Id,List<Id>>paymentSummaryMap = new Map<Id,List<Id>>();
       Set<Id> paymentSummaryWithToPaySet = new Set<Id>();
       Set<Id> delegatedUserIdSet = new Set<Id>();
       Set<Id> ActivedelegatedUserIdSet = new Set<Id>();
       Map<Id,Id> delegatedUserMap = new Map<Id,Id>();
       
       for(ECM_Payment_Summary__c PaymentSummary:newPaySumList){
           
           if(PaymentSummary.ECM_Contract_Agreement_Type__c!=null){
               agreementTypeList.add(PaymentSummary.ECM_Contract_Agreement_Type__c);
               paymentSummaryTypeSet.add(PaymentSummary.ECM_type__c+' PS');
           }
       }    
       //Added for ECM-4787
       paymentSummaryTypeSet.add('Volume Based PS-Target');
       for(ECM_Payment_Summary_Item__c paySumItem:[select ECM_Payment_Summary__c from ECM_Payment_Summary_Item__c where ECM_Payment_Summary__c IN:newPaysumList and ECM_To_Pay__c=true]){
           paymentSummaryWithToPaySet.add(paySumItem.ECM_Payment_Summary__c);
       }
       String ecm_type;
       for(ECM_Agreement_Approval__c agrementApproval: [select id,ECM_Agreement_Type__c,ECM_Extra_Approval__c,ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId,ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c,ECM_Extra_Approval__r.ECM_Type__c,ECM_Extra_Approval__r.ECM_Enable_Delegation__c,ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c,ECM_Extra_Approval_Role__c from ECM_Agreement_Approval__c where ECM_Agreement_Type__c IN:agreementTypeList and ECM_Extra_Approval__r.ECM_Active__c=true and ECM_Extra_Approval__r.ECM_Extra_Approval_User__c!=null and ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.isActive=true and ECM_Extra_Approval__r.ecm_type__c IN:paymentSummaryTypeSet]){
           if(agrementApproval.ECM_Extra_Approval__r.ecm_type__c=='Volume Based PS-Target'){
               ecm_type='Volume-Based PS';
           }else{
               ecm_type=agrementApproval.ECM_Extra_Approval__r.ecm_type__c;
           }
           if(approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type)!=null){ 
               List<ECM_Agreement_Approval__c> eclist=approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type);
               ecList.add(agrementApproval);
               approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type,ecList);                
               
           }else{
               approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type,new List<ECM_Agreement_Approval__c>{agrementApproval});
           }
           if(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId!=null){
               delegatedUserIdSet.add(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId);
           }
       }
       
       for(User u: [select id from user where id IN:delegatedUserIdSet and isActive=true]){
           
           ActivedelegatedUserIdSet.add(u.Id);
       }
       for(ECM_Payment_Summary__c PaymentSummary:newPaySumList ){
           if(PaymentSummary.ECM_Contract_Agreement_Type__c!=null && approvalMap.get(string.valueOf(PaymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+PaymentSummary.ECM_type__c+' PS')!=null){
               for(ECM_Agreement_Approval__c extraApproval:approvalMap.get(string.valueOf(PaymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+PaymentSummary.ECM_type__c+' PS')){ 
                   if((extraApproval.ECM_Extra_Approval__r.ecm_type__c=='Volume Based PS-Target' && paymentSummaryWithToPaySet.contains(PaymentSummary.Id)) || (PaymentSummary.ECM_Total_Amount_Confirmed__c>=extraApproval.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c && PaymentSummary.ECM_Total_Amount_Confirmed__c<=extraApproval.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c) && extraApproval.ECM_Extra_Approval__r.ecm_type__c!='Volume Based PS-Target'){
                       /*if(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId!=null){
userRoleMap.put(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId,' Delegated '+extraApproval.ECM_Extra_Approval_Role__c); 
}else{
userRoleMap.put(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,extraApproval.ECM_Extra_Approval_Role__c);
}*/
                       
                       if(paymentSummaryApproval.get(PaymentSummary.id)!=null){ 
                           List<Id> userlist=paymentSummaryApproval.get(PaymentSummary.id);
                           if( extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId!=null && ActivedelegatedUserIdSet.contains(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId) ){
                               userlist.add(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId);
                           }else{
                               userlist.add(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c);
                           }
                           paymentSummaryApproval.put(PaymentSummary.id,userlist);
                       }else{
                           if(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId!=null && ActivedelegatedUserIdSet.contains(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.delegatedApproverId)){
                               paymentSummaryApproval.put(PaymentSummary.id,new List<Id>{extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId});
                           }else{
                               paymentSummaryApproval.put(PaymentSummary.id,new List<Id>{extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c});
                           }
                       }
                   }
               }               
               
           }
           
       }
       for(ECM_Payment_Summary__c paymentSummary:newPaySumList ){
           
           if(paymentSummaryApproval.get(paymentSummary.id)!=null){
               paymentSummaryList.add(paymentSummary.id);
           }       
       }
       
       return paymentSummaryList;
       
   } 
   //Added as part of ECM-5871 End 
   
   /**
* @description : insert payment summary with payment line items for roll over [ECM-6201]
* @return : void
* @param : trigger.newMap,triggr.oldMap
*/
   
   public static void createRollOverPaymentSummary ( Map < Id, ECM_Payment_Summary__c > newMap, Map < Id, ECM_Payment_Summary__c > oldMap ) {
       Set<Id> setPaymentSummaries = new Set<Id>();
       List<ECM_Payment_Summary_Item__c> listLineItems = new List<ECM_Payment_Summary_Item__c>();
       Map<Id,ECM_Payment_Summary__c> mapIdWithReferencePaymentSummary = new Map<Id,ECM_Payment_Summary__c>();
       Map<Id, ECM_Payment_Summary__c> mapIdWithPaymentSummary = new Map<Id, ECM_Payment_Summary__c>();
       Map<String,ECM_Payment_Summary_Item__c> mapStringPaymentsummaryWithlineItens = new Map<String,ECM_Payment_Summary_Item__c>();
       Map<Id, RollupDataWrapper> mapIdWithRollupData = new Map<Id, RollupDataWrapper>();
       for ( ECM_Payment_Summary__c pm : newMap.values() ) {
           if ( pm.ECM_Payment_Summary_Status__c == system.label.ECM_Payment_Summary_Approved && String.isEmpty(pm.ECM_Approval_Sub_Status__c) &&
               oldMap.get(pm.Id).ECM_Approval_Sub_Status__c == system.label.ECM_CIO_Approval &&  pm.ECM_Type__c == system.label.ECM_PSType_PromoStandard &&
               pm.ECM_Total_Amount_Confirmed__c != pm.ECM_Total_Amount_Forecasted__c ) {
                   setPaymentSummaries.add(pm.Id);
               }
       }
       if ( setPaymentSummaries.size() >0 ){
           for (ECM_Payment_Summary__c pm : [Select Id, CurrencyIsoCode, ECM_Budget_types__c, ECM_Contract__c, ECM_End_Period__c, ECM_Fiscal_Years__c,
                                             ECM_Payment_Frequency__c, ECM_Payment_Frequency__r.ECM_Type__c, ECM_Start_Period__c, ECM_Type__c, 
                                             ECM_contract__r.Status,Name, ECM_Addendum__c, 
                                             (Select Id, CurrencyIsoCode, ECM_Confirmed_Amount_Per_Payment__c, ECM_Contract_Item__c, ECM_Planned_Amount_Per_Payment__c,
                                              ECM_Confirm__c, ECM_Payment_Summary__c, ECM_Product__c 
                                              FROM Payment_Summary_Item__r
                                              WHERE ECM_Roll_Over__c= TRUE) 
                                             FROM ECM_Payment_Summary__c
                                             WHERE Id IN: setPaymentSummaries 
                                             AND ECM_Payment_Frequency__r.ECM_Type__c =: system.label.ECM_PaymentByActivation
                                             AND ( ECM_contract__r.Status =: system.label.ECM_ContractApprovedStatus OR ECM_contract__r.Status =: system.label.ECM_Expired )] ){
                                                 if ( pm.Payment_Summary_Item__r.size() >0 ) {
                                                     ECM_Payment_Summary__c clonePaymentSummary = pm.clone ( false, true, false, false );
                                                     clonePaymentSummary.ECM_Parent_Payment_Summary__c = pm.Id;
                                                     if ( pm.ECM_contract__r.Status == system.label.ECM_ContractApprovedStatus && pm.ECM_Start_Period__c <= Date.today() ) {
                                                         clonePaymentSummary.ECM_Payment_Summary_Status__c = system.label.ECM_Open_Apex;
                                                     } else {
                                                         clonePaymentSummary.ECM_Payment_Summary_Status__c = system.label.ECM_Provisional;
                                                     }
                                                     listLineItems.addAll(pm.Payment_Summary_Item__r);
                                                     mapIdWithPaymentSummary.put(pm.Id, clonePaymentSummary);
                                                 }
                                             }
       }
       
       if ( listLineItems.size()>0 ) {
           for ( ECM_Payment_Summary_Item__c psi : listLineItems ) {
               ECM_Payment_Summary_Item__c clonedPSI = psi.clone(false, true, false, false);
               clonedPSI.ECM_Planned_Amount_Per_Payment__c = psi.ECM_Planned_Amount_Per_Payment__c - psi.ECM_Confirmed_Amount_Per_Payment__c;
               clonedPSI.ECM_Confirmed_Amount_Per_Payment__c = clonedPSI.ECM_Planned_Amount_Per_Payment__c;
               
               if ( mapIdWithRollupData.containsKey( psi.ECM_Payment_Summary__c ) ) {
                   mapIdWithRollupData.get(psi.ECM_Payment_Summary__c).totalAmountForcasted += clonedPSI.ECM_Planned_Amount_Per_Payment__c;
                   if ( psi.ECM_Confirm__c ) {
                       if( mapIdWithRollupData.get(psi.ECM_Payment_Summary__c).totalAmountConfirmed !=null ) {
                           mapIdWithRollupData.get(psi.ECM_Payment_Summary__c).totalAmountConfirmed += clonedPSI.ECM_Confirmed_Amount_Per_Payment__c;
                       } else {
                           mapIdWithRollupData.get(psi.ECM_Payment_Summary__c).totalAmountConfirmed = clonedPSI.ECM_Confirmed_Amount_Per_Payment__c;
                       }
                       
                   }
               } else {
                   RollupDataWrapper rollupwrapper = new RollupDataWrapper();
                   rollupwrapper.paymentSummaryId = psi.ECM_Payment_Summary__c;
                   rollupwrapper.totalAmountForcasted = clonedPSI.ECM_Planned_Amount_Per_Payment__c;
                   if ( psi.ECM_Confirm__c ) {
                       rollupwrapper.totalAmountConfirmed = clonedPSI.ECM_Confirmed_Amount_Per_Payment__c;
                   }
                   mapIdWithRollupData.put(psi.ECM_Payment_Summary__c, rollupwrapper);
               }
               mapStringPaymentsummaryWithlineItens.put(psi.ECM_Payment_Summary__c+'_'+psi.Id, clonedPSI);
           }
       }
       
       if ( mapIdWithRollupData.size()>0 ) {
           for (RollupDataWrapper rollupData : mapIdWithRollupData.values() ) {
               mapIdWithPaymentSummary.get(rollupData.paymentSummaryId).ECM_Total_Amount_Forecasted__c = rollupData.totalAmountForcasted;
               mapIdWithPaymentSummary.get(rollupData.paymentSummaryId).ECM_Total_Amount_Confirmed__c = rollupData.totalAmountConfirmed;
           }
       }
       
       if ( mapIdWithPaymentSummary.size()>0 ) {
           insert mapIdWithPaymentSummary.values();
       }
       
       if ( mapStringPaymentsummaryWithlineItens.size()>0 ) {
           for ( String psWithPSItem : mapStringPaymentsummaryWithlineItens.keySet() ) {
               mapStringPaymentsummaryWithlineItens.get(psWithPSItem).ECM_Payment_Summary__c =  mapIdWithPaymentSummary.get(psWithPSItem.substringBefore('_')).Id;
           }
           insert mapStringPaymentsummaryWithlineItens.values();
       }
   }
   //changes Start
    /*
   * @description : This method fetches a list of Extra approvers who are eligible and then submits an approval request to them.-146081
   * @return : void
   * @param : List<ECM_Payment_Summary__c>
   */
   public static void checkForAdditionalExtraApproval(List<ECM_Payment_Summary__c> newPaySumList){
       Set<Id> agreementTypeIDList= new Set<Id>(); 
       Set<Id> paySumtIdList = new Set<Id>();
       List<Id>paymentSummaryList= new List<Id>();
       Map<Id,List<Id>>paymentSummaryMap = new Map<Id,List<Id>>();
       Map<String,List<ECM_Agreement_Approval__c>>approvalMap = new Map<String,List<ECM_Agreement_Approval__c>>();
       
       try{
           for(ECM_Payment_Summary__c paymentSummary:newPaySumList){
               if(paymentSummary.ECM_Contract_Agreement_Type__c!=null){
                   agreementTypeIDList.add(paymentSummary.ECM_Contract_Agreement_Type__c);
                   paySumtIdList.add(paymentSummary.Id);
               }
           } 
           fetchExistingApprovalMapPI(paySumtIdList);
           populateExtraApprovalMap(agreementTypeIDList,approvalMap);
           fetchActivedelegatedUserIds (delegatedUsersForApproval);
           
           System.debug(LoggingLevel.DEBUG,'approvalMap' +approvalMap);
           for(ECM_Payment_Summary_Item__c paymentSumItem: [SELECT Id,ECM_Confirmed_Volume__c,ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c, ECM_Payment_Summary__c,ECM_Payment_Summary__r.ECM_Type__c,
                                                            ECM_Payment_Summary__r.ECM_Contract_Agreement_Type__c
                                                            FROM ECM_Payment_Summary_Item__c WHERE ECM_Payment_Summary__c IN :newPaySumList AND ECM_Payment_Summary__r.ECM_Contract_Agreement_Type__c !=null WITH SECURITY_ENFORCED]){
                                                             if(paymentSumItem.ECM_Payment_Summary__r.ECM_Type__c == label.Ecm_Payment_Summary_Volume_based &&
                                                                approvalMap.get(string.valueOf(paymentSumItem.ECM_Payment_Summary__r.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+paymentSumItem.ECM_Payment_Summary__r.ECM_type__c+' PS-Initial vs Actual') !=null){
                                                                  validatePSIAgainstAgreement(paymentSumItem);
                                                               }
                                                           }
          System.debug(LoggingLevel.DEBUG,'validPaySumIdList' +validPaySumIdList);
           paymentSummaryList = validatePaymentSummary(newPaySumList,paymentSummaryMap,approvalMap);
           if(!paymentSummaryList.isEmpty()){
               system.enqueueJob(new ECM_PS_ApprovalProcess_Queueable(paymentSummaryList,paymentSummaryMap,extraUserRoleMap));
           }
           System.debug(LoggingLevel.DEBUG,'paymentSummaryList' +paymentSummaryList);
           if(!paymentSumListCIOForAdditonal.isEmpty()){
               ECM_PaymentSummaryTriggerHelper.checkForCIOApproval(paymentSumListCIOForAdditonal);
           }
       }catch(Exception e){
           System.debug(LoggingLevel.DEBUG,'Exception Caught in checkForAdditionalExtraApproval method of ECM_PaymentSummaryTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
       }
   }
   
     /*
   * @description : This method fetches a list of Extra approvers who are eligible and then submits an approval request to them.-146081
   * @return : List<Id> of PS
   * @param : List<ECM_Payment_Summary__c>
   */
   public static List<Id> validateAdditionalExtraApproval(List<ECM_Payment_Summary__c> newPaySumList){
       Set<Id> agreementTypeIDList= new Set<Id>(); 
       List<Id>paymentSummaryList= new List<Id>();
       Map<Id,List<Id>>paymentSummaryMap = new Map<Id,List<Id>>();
       Map<String,List<ECM_Agreement_Approval__c>>approvalMap = new Map<String,List<ECM_Agreement_Approval__c>>();
       
       
       for(ECM_Payment_Summary__c paymentSummary:newPaySumList){
           if(paymentSummary.ECM_Contract_Agreement_Type__c!=null){
               agreementTypeIDList.add(paymentSummary.ECM_Contract_Agreement_Type__c);
           }
       } 
       populateExtraApprovalMap(agreementTypeIDList,approvalMap);
       fetchActivedelegatedUserIds(delegatedUsersForApproval);
       for(ECM_Payment_Summary_Item__c paymentSumItem: [SELECT Id,ECM_Confirmed_Volume__c,ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c, ECM_Payment_Summary__c,ECM_Payment_Summary__r.ECM_Type__c,
                                                        ECM_Payment_Summary__r.ECM_Contract_Agreement_Type__c
                                                        FROM ECM_Payment_Summary_Item__c WHERE ECM_Payment_Summary__c IN :newPaySumList WITH SECURITY_ENFORCED]){
                                                            if(paymentSumItem.ECM_Payment_Summary__r.ECM_Contract_Agreement_Type__c !=null
                                                               && paymentSumItem.ECM_Payment_Summary__r.ECM_Type__c == label.Ecm_Payment_Summary_Volume_based &&
                                                               approvalMap.get(string.valueOf(paymentSumItem.ECM_Payment_Summary__r.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+paymentSumItem.ECM_Payment_Summary__r.ECM_type__c+' PS-Initial vs Actual') !=null){
                                                                   validatePSIAgainstAgreement(paymentSumItem);
                                                               }
                                                        }
        
       paymentSummaryList = validatePaymentSummary(newPaySumList,paymentSummaryMap,approvalMap);
       return paymentSummaryList;
   }
   
   /*
   * @description : This method validate payment summary item against aggrement type initial vs actual field.-146081
   * @return : void
   * @param : List<ECM_Payment_Summary__c>
   */
   public static void validatePSIAgainstAgreement(ECM_Payment_Summary_Item__c paymentSumItem){
       String logic = agreementTypeToLogic.get(paymentSumItem.ECM_Payment_Summary__r.ECM_Contract_Agreement_Type__c);
       if(sumOfPSIMap.get(paymentSumItem.ECM_Payment_Summary__c) != null){ 
           sumOfPSIMap.put(paymentSumItem.ECM_Payment_Summary__c,sumOfPSIMap.get(paymentSumItem.ECM_Payment_Summary__c) + paymentSumItem.ECM_Confirmed_Volume__c);
           sumOfCIMap.put(paymentSumItem.ECM_Payment_Summary__c,sumOfCIMap.get(paymentSumItem.ECM_Payment_Summary__c) + paymentSumItem.ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c);  
           
       }else{
           sumOfPSIMap.put(paymentSumItem.ECM_Payment_Summary__c,paymentSumItem.ECM_Confirmed_Volume__c);
           sumOfCIMap.put(paymentSumItem.ECM_Payment_Summary__c,paymentSumItem.ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c);
       }
       if((logic == 'Product Level' || logic == 'Product or Overall') && paymentSumItem.ECM_Confirmed_Volume__c > paymentSumItem.ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c){
           validPaySumIdList.add(paymentSumItem.ECM_Payment_Summary__c);
       }else if(logic == 'Overall Level'){
           if(sumOfPSIMap.get(paymentSumItem.ECM_Payment_Summary__c) <= sumOfCIMap.get(paymentSumItem.ECM_Payment_Summary__c) && validPaySumIdList.contains(paymentSumItem.ECM_Payment_Summary__c)){
               validPaySumIdList.remove(paymentSumItem.ECM_Payment_Summary__c);
           }else{
               validPaySumIdList.add(paymentSumItem.ECM_Payment_Summary__c);
           }
       }
   } 
   /*
   * @description : This method populate approvalMap from agrrement approval records.-146081
   * @return : void
   * @param : Set<Id>, Map<String,List<ECM_Agreement_Approval__c>>
   */
   public static void populateExtraApprovalMap(Set<Id> agreementTypeIDList,Map<String,List<ECM_Agreement_Approval__c>>approvalMap){
       String ecmType;
       for(ECM_Agreement_Approval__c agrementApproval: [SELECT Id, ECM_Agreement_Type__c, ECM_Agreement_Type__r.C360_PS_Approval_Initial_vs_Actual__c,
                                                        ECM_Extra_Approval__c,ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,
                                                        ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId,
                                                        ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c,ECM_Extra_Approval__r.ECM_Type__c,
                                                        ECM_Extra_Approval__r.ECM_Enable_Delegation__c,ECM_Extra_Approval_Role__c,
                                                        ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c FROM ECM_Agreement_Approval__c 
                                                        WHERE ECM_Agreement_Type__c IN:agreementTypeIDList AND 
                                                        ECM_Extra_Approval__r.ECM_Active__c=true AND ECM_Extra_Approval__r.ECM_Extra_Approval_User__c!=null 
                                                        AND ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.isActive = true 
                                                        AND ECM_Extra_Approval__r.ecm_type__c =: label.C360_Volume_Based_PS_Initial_vs_Actual
                                                        AND ECM_Agreement_Type__r.C360_PS_Approval_Initial_vs_Actual__c !=''
                                                        WITH SECURITY_ENFORCED]){
                                                            ecmType=agrementApproval.ECM_Extra_Approval__r.ecm_type__c;
                                                            if(approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecmType)!=null){ 
                                                                List<ECM_Agreement_Approval__c> eclist = approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecmType);
                                                                eclist.add(agrementApproval);
                                                                approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecmType,ecList);                
                                                                
                                                            }else{
                                                                approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecmType,new List<ECM_Agreement_Approval__c>{agrementApproval});
                                                                agreementTypeToLogic.put(agrementApproval.ECM_Agreement_Type__c,agrementApproval.ECM_Agreement_Type__r.C360_PS_Approval_Initial_vs_Actual__c);
                                                            }
                                                            if(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId!=null){
                                                                delegatedUsersForApproval.add(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId);
                                                            }
                                                        }
        System.debug(LoggingLevel.DEBUG,'agreementTypeToLogic' +agreementTypeToLogic);
       
   }
   
    /*
   * @description : This method populate fetches existing approval process record.-146081
   * @return : void
   * @param : Set<Id> payment summary records
   */
   public static void fetchExistingApprovalMapPI(Set<Id> paySumtIdList){
       for(ProcessInstanceWorkitem item: [SELECT Id, ProcessInstanceId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN :paySumtIdList WITH SECURITY_ENFORCED]){
           if(existingApprovalMapPI.get(item.ProcessInstance.TargetObjectId)!=null){               
               List<ProcessInstanceWorkitem> tempList = existingApprovalMapPI.get(item.ProcessInstance.TargetObjectId);
               tempList.add(item);
               existingApprovalMapPI.put(item.ProcessInstance.TargetObjectId,tempList);
           }else{
               existingApprovalMapPI.put(item.ProcessInstance.TargetObjectId,new List<ProcessInstanceWorkitem>{item});
           }           
       }
   }
    /*
   * @description : This method validate payment symarry records based on filter criteria like extra approval,payment symmary type.-146081
   * @return : List<Id>
   * @param : List<ECM_Payment_Summary__c>,Map<Id,List<Id>>,Map<String,List<ECM_Agreement_Approval__c>>
   */
   public static List<Id> validatePaymentSummary(List<ECM_Payment_Summary__c> newPaySumList, Map<Id,List<Id>>paymentSummaryMap,Map<String,List<ECM_Agreement_Approval__c>>approvalMap){
       List<Id>paymentSummaryList= new List<Id>();
       for(ECM_Payment_Summary__c paymentSummary:newPaySumList){
           List<Id> approversId = new List<Id>();
           approversId = populateApproverListAndRoleMap(approvalMap,paymentSummary);
           if(existingApprovalMapPI.get(paymentSummary.id)!=null && existingApprovalMapPI.get(paymentSummary.id).size()>1){
               paymentSummary.ECM_Approval_Sub_Status__c=Label.ECM_In_Extra_Approval;
               paymentSummary.ECM_Payment_Summary_Status__c=Label.ECM_In_Approval_Process_Apex;
           }else if(validPaySumIdList.contains(paymentSummary.Id) && !approversId.isEmpty()){
               paymentSummaryList.add(paymentSummary.Id);
               paymentSummaryMap.put(paymentSummary.Id, approversId);
               ECM_PaymentSummaryTriggerHelper.checkAndProvideAccountAccess(paymentSummary.ECM_Contract_Account_Id__c,extraUserRoleMap);
           }else{
               paymentSummary.ECM_Approval_Sub_Status__c = Label.ECM_CIO_Approval;
               paymentSummary.ECM_Payment_Summary_Status__c = Label.ECM_Submitted_Status;
               paymentSumListCIOForAdditonal.add(paymentSummary);
           }
       }
       System.debug(LoggingLevel.DEBUG,'paymentSumListCIOForAdditonal' +paymentSumListCIOForAdditonal);
       return paymentSummaryList;
   }
    
   public static List<Id> populateApproverListAndRoleMap(Map<String,List<ECM_Agreement_Approval__c>>approvalMap,ECM_Payment_Summary__c paymentSummary){
       List<Id> approversId = new List<Id>();
       if(approvalMap.get(string.valueOf(paymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+paymentSummary.ECM_type__c+' PS-Initial vs Actual')!=null){
           for(ECM_Agreement_Approval__c agrementApproval: approvalMap.get(string.valueOf(paymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+paymentSummary.ECM_type__c+' PS-Initial vs Actual')){
               if(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId!=null && activeUsersForApproval.contains(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId)){
                   extraUserRoleMap.put(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,'Delegated '+agrementApproval.ECM_Extra_Approval_Role__c);
                   approversId.add(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.DelegatedApproverId);
               }else{
                   extraUserRoleMap.put(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,agrementApproval.ECM_Extra_Approval_Role__c);
                   approversId.add(agrementApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c);
               }
           }
       }
       System.debug(LoggingLevel.DEBUG,'approversId' +approversId);
       return approversId;
   }//changes end
   /*
   * @description : This method fetches active deligate user ids.-146081
   * @return : void
   * @param : Set<Id> payment summary records
   */
   public static void fetchActivedelegatedUserIds(Set<Id> delegatedUsersForApproval){
       for(User u: [select id from user where id IN:delegatedUsersForApproval and isActive=true WITH SECURITY_ENFORCED]){
           activeUsersForApproval.add(u.Id);
       }
   }
   
   public class RollupDataWrapper {
       public Decimal totalAmountConfirmed { get; set; }
       public Decimal totalAmountForcasted { get; set; }
       public String paymentSummaryId { get; set; }
   }
   
}