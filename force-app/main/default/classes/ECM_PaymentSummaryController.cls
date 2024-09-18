/*
*@Name: ECM_PaymentSummaryController
*@description: This is class for fetch required data for components "ECM_PaymentSummary"
*@History:                                                            

*@AUTHOR                       DATE              DETAIL

*@Saurav Prasad				14/06/2021		  Development for ECM-4512
*@Anivesh Muppa             14/06/2021        Development for ECM-4516
*@Veerendra Billakurthi		22/06/2021        ECM-4543- Deployment_Remove hardcoding of Spain 
                                              from the Payment Summary Tab
*@Manikandan.T				17/08/2021        ECM-4611- Added fields ECM_Evidence_for_Payment_Summary__c and ECM_Invoices_for_Payment_Summary__c in the getPaymentSummaryDetails method
											  Modified getPSattachments method to include invoice type PS Attachments
*@Saurav Prasad				30/08/2021		  ECM-4760 Logic for Calculations in % Achieved table for Leading & Non Leading Brand in Payment Summary Screen
*@Saurav Paul               16/09/2021        ECM-4736 Added targetPercent for showing %Target Achieved Field]
*@Anivesh Muppa             07/10/2021        Fix for ECM-4866
*@Subhrojit Majumdar		08/10/2021		  ECM-4459 Appended two new fields in paymentSummaryRecord query
*@Keshav					09/11/2021		  ECM-4938 : Method to update Invoice & Evidence Attachment fields on PaymentSummary	
*@Saurav Prasad				29/12/2021		  ECM-4973 : POC_Group Contract Accessibility_SFDC_GLO
*@Saurav Prasad				08/03/2022		  ECM-5315 : Payment summary SFDC_need to validate the existing code to reconfigure it to access it through mobile (Part 2)
*@Anshu & Tanishq			21/06/2022		  ECM-5538 : Display of UoMs for RTD & Draught Cocktails on different screens/pages
*@Pratap & Subhrojit        06/07/2022        ECM-5619 : Added ECM_Updated_Forecasted_Volume__c in payment summary query of getPaymentSummary()
*@Anshu & Tanishq			18/08/2022		  ECM-5869 : Pop Up Message for the Requested Option for All PS_SFDC_EU
*@Tanishq					03/11/2022		  ECM-6317 : Fast track - CIO profile: allow access to multiple countries
*@Saurav Paul				1/12/2022		  ECM-6470 : Payment Summary Screen is not getting loaded
*@Anshu Prakash             08/12/2022        ECM-6461 : Customer Facing Product Name in CM_4
*@Anshu Prakash				09/01/2023		  ECM-6651 : PS for German is not getting submitted when Evidence/Invoice is mandatory in Agreement Type
*@Tanishq/Pratik            25/01/2023        ECM-6710 : Delegation of Manager approval for Payment Summary is not Working_EU
*@Sudipta Nandi             01/12/2022        146079: Approval Process for PS Initial vs Actual & Trigger from Apex_SFDC
*/
public without sharing class ECM_PaymentSummaryController {
    private static string countryName= 'Australia';
    public class PsWrapper{
        @AuraEnabled public Boolean isPSItem{get;set;}
        @AuraEnabled public ECM_Payment_Summary__c psgetwrap{get;set;}
        @AuraEnabled public List<SKURebatesRate> psContractItems{get;set;}
        @AuraEnabled public List<ConItemTier> psContractItemsTier{get;set;}
        @AuraEnabled public List<ECM_Payment_Summary_Item__c> approvedPaymentSummaryItems{get;set;}
        @AuraEnabled public Boolean isDepletionMarket{get;set;}
		@AuraEnabled public Boolean isConfirmEnabled{get; set;}
        @AuraEnabled public Boolean isInvoiceMail{get; set;}//ECM-5869
        //Added as part of ECM-4760
        @AuraEnabled public brandCalculation psBrandData{get; set;}
        //Added as part of ECM-4727
        @AuraEnabled public Boolean isDisplayPercentAcheivedTable{get;set;}
        //Added for ECM-4736
        @AuraEnabled public Decimal targetPercent{get;set;}
         //Added as part of  ECM-4915
        @AuraEnabled public boolean countryCheck {get;set;}
    }
    @AuraEnabled
    public static PsWrapper getPaymentSummaryDetails(String paymentSummaryId){
        PsWrapper psw = new PsWrapper();
        
        ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
        if(String.isNotEmpty(paymentSummaryId)){
            //ECM-5315
            paymentSummaryRecord = getPaymentSummary(paymentSummaryId);
            psw.psgetwrap = paymentSummaryRecord;
            String conPS = paymentSummaryRecord.ECM_Country_Code__c;//ECM-5869
            List<ECM_Technical_Market_Setting__mdt> techMarket = [SELECT Id,ECM_Invoice_Request__c,ECM_Country__c FROM ECM_Technical_Market_Setting__mdt WHERE ECM_Country__c =: conPS];//ECM-5869
            psw.isInvoiceMail = techMarket[0].ECM_Invoice_Request__c;//ECM-5869            
        }
        
        if(paymentSummaryRecord.Payment_Summary_Item__r.size()>0){
            if(paymentSummaryRecord.ECM_Budget_types__r.Name=='SKU Specific Rebates [AU]'/* 
               || paymentSummaryRecord.ECM_Budget_types__r.Name=='Portfolio Rebates [AU]'*/){
                   psw.psContractItems = getSKURebateCase(paymentSummaryRecord);//conItems.size()>0?conItems:Null;
               } 
            else if(paymentSummaryRecord.ECM_Budget_types__r.Name=='Portfolio Rebates [AU]'){
                psw.psContractItems = getActualSoldCases(paymentSummaryRecord);//conItems.size()>0?conItems:Null;            
                
            }  
            psw.isPSItem=true;
            psw.psContractItemsTier = getConItemTier(paymentSummaryRecord);
            psw.approvedPaymentSummaryItems= getApprovedPaymentSummaryItems(paymentSummaryRecord.ECM_Contract__c,paymentSummaryId);
            system.debug(LoggingLevel.DEBUG,'psw tier-->'+psw.psContractItemsTier);
        }else{
            psw.psContractItems = getActualSoldCases(paymentSummaryRecord);//conItems.size()>0?conItems:Null;            
            system.debug(LoggingLevel.DEBUG,'00000'+psw.psContractItems.size());
            psw.isPSItem=false;
        }
        //added as a part of ECM-4396
        //Depletion market check for Volume-Based
       
            for(Market_Setting__c marketSetting: [SELECT Id , Depletion_market__c,ECM_Enable_Target__c,ECM_Target__c
 												  FROM Market_Setting__c 
                                                  WHERE Geography__c =: paymentSummaryRecord.ECM_Contract__r.Account.Country__c]){
                psw.isDepletionMarket = marketSetting.Depletion_market__c;
                psw.isDisplayPercentAcheivedTable= marketSetting.ECM_Enable_Target__c;
                psw.targetPercent = marketSetting.ECM_Target__c;
            }
        
        //End of ECM-4396
        List<String> countryList = system.label.ECM_PS_ConfirmEnabled_Countries.split(';');
		List<ECM_Payment_Summary__c> paymentSummaryInApproval=[select id from ECM_Payment_Summary__c 
                                                               where ECM_Payment_Summary_Status__c=:system.label.ECM_In_Approval_Process_Apex 
                                                               and ecm_contract__c=:paymentSummaryRecord.ECM_Contract__c 
                                                               and ecm_type__c=:system.label.Ecm_Payment_Summary_Volume_based 
                                                               and id!=:paymentSummaryId
                                                               and ECM_Country_Code__c NOT IN :countryList];
		if(paymentSummaryInApproval.size()>0){
			psw.isConfirmEnabled=false;
		}else{
			psw.isConfirmEnabled=true;
        }
        //Added as part of ECM-4760        
        psw.psBrandData = getBrandCalulation(paymentSummaryRecord);
         //Added as part of  ECM-4915
        userMarketwrap userCountryWrap = fetchUserDetails();
        psw.countryCheck=userCountryWrap.volumecheck;
         //End of  ECM-4915

        system.debug(LoggingLevel.DEBUG,'psw-->'+psw);
        return psw;
    }
    
    /** 
* @description	:	ECM-5315 - Payment summary SFDC_need to validate the existing code to reconfigure it to access it through mobile (Part 2)
* @return		:	ECM_Payment_Summary__c
* @param event	:	String
**/
    @AuraEnabled
    public static ECM_Payment_Summary__c getPaymentSummary(String paymentSummaryId){
        //Added ECM_Contract_Agreement_Type__c field in query for ECM-5871
        //Added ECM_Payment_Frequency__c in query for ECM-6470
        //Added ECM_Contract_Item__r.ECM_Product_Name__c for ECM-6461
        return [Select Id, Name, ECM_Payment_Summary_Status__c,ECM_Contract_Agreement_Type__c,ECM_Contract_Account_Id__c,ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__r.Status,ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.StartDate,ECM_Contract__r.Account.Country__c,ECM_Contract__r.Account.Country__r.Code__c,ECM_Tax_Code__c,ECM_Tax_Code__r.Name,ECM_Contract__r.RecordTypeId, ECM_Total_to_be_Invoiced__c,ECM_No_Invoice_Required__c, 
                ECM_Total_Amount_Forecasted__c, ECM_Total_Amount_Confirmed__c, ECM_Invoice_Receival_Date__c,ECM_Contract__r.Account.SAP_Sold_to__c,ECM_Contract__r.ECM_Agreement_Type__c,ECM_Contract__r.ECM_Territory__c, ECM_UoS_Total__c,ECM_Contract__r.Account.parent_outlet__c,ECM_Country_Code__c,ECM_Invoice_Attachment__c,
                ECM_Invoice_Status__c, ECM_SAP_Credit_Note_Number__c, ECM_SAP_Credit_Note_Creation_Date__c, ECM_SAP_Billing_Doc_Number__c, ECM_Contract__r.UOS_Rebate_Rate__c,ECM_Contract__r.ECM_Upfront_Pre_payment_amount__c, ECM_Contract__r.ECM_Upfront_Annual_Payment_Amount__c,  ECM_SAP_Billing_Doc_Date__c, 
                ECM_SAP_payment_Reference_Number__c, ECM_SAP_Payment_Date__c, ECM_Tax_Rate__c,ECM_Type__c,Owner__c,ECM_Recommended_IO_Code__c, ECM_Budget_types__r.Name,ECM_Budget_types__r.ECM_Evidence_Mandatory__c, ECM_Budget_types__c,ECM_Contract__r.UOS_Earnt__c,ECM_Contract__r.Available_AP_Spend__c,ECM_Additional_Info__c,ECM_PaymentPSVia_SAP__c,
                ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name ,ECM_Contract__r.ECM_Banner__c,ECM_Contract__r.ECM_Contract_Other_Spent__c,ECM_Contract__r.ECM_Contract_Payment_Spent__c,ECM_Contract__r.ECM_Total_Training_Over_Term__c,ECM_Contract__r.ECM_Total_Others_Over_Term__c,ECM_Contract__r.OwnerId,
                ECM_Contract__r.Account.Id,ECM_Contract__r.Id,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Evidence_for_Payment_Summary__c,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Invoices_for_Payment_Summary__c,ECM_Contract__r.Account.Person_Responsible__c,
                ECM_Achieved_Leading_Brand__c,ECM_Achieved_Non_Leading_Brand__c,ECM_Achieved_Overall__c,ECM_Contract__r.ECM_Duration__c,UoM_for_Beer__c,UoM_for_Spirits__c,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Volume_UoM_for_RTD__c,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Volume_UoM_for_Draught_Cocktails__c,ECM_Payment_Frequency__c,ECM_Payment_Frequency__r.ECM_Type__c,
                (Select Id,Name,ECM_Contract_Item__r.ECM_Product__r.Product_Name__c,ECM_Planned_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,ECM_Contract_Item__r.ECM_UoM__c, ECM_Confirmed_Volume__c,
                 ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c,ECM_Product__c,ECM_Product__r.name,ECM_Total_UoS__c,ECM_Actual_Cases__c,ECM_Contract_Item__r.ECM_Actual_Volume_YTD__c,ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirm__c,ECM_Reject__c,ECM_Roll_Over__c,
                    ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Contract_Item__r.ECM_Volume__c,ECM_Contract_Item__r.ECM_Contracts_UoM__c,ECM_Percentage_Target_Achieved__c,ECM_To_Pay__c, ECM_Updated_Forecasted_Volume__c,ECM_Contract_Item__r.ECM_Product_Name__c, ECM_Internal_Order__c, ECM_Internal_Order__r.Id, ECM_Internal_Order__r.Name 
                 From Payment_Summary_Item__r) 
                From ECM_Payment_Summary__c
                Where id=:paymentSummaryId]; //ECM-5538: Added ECM_Volume_UoM_for_RTD__c & ECM_Volume_UoM_for_Draught_Cocktails__c in the query
    }
    /**
* @description	:	ECM-4760 - To Calculate the Logic for Calculations in % Achieved table for Leading & Non Leading Brand in Payment Summary Screen
* @return		:	Wrapper class brandCalculation
* @param event	:	ECM_Payment_Summary__c
*/
    @AuraEnabled
    public static brandCalculation getBrandCalulation(ECM_Payment_Summary__c ps){
        brandCalculation brandData = new brandCalculation();
        Integer months;
        if(ps.ECM_Start_Period__c!=Null && ps.ECM_End_Period__c!=Null){//Fix for ECM-4866
            months = ps.ECM_Start_Period__c.monthsBetween(ps.ECM_End_Period__c.addDays(1));
        }
        //Fix for ECM-4866
        if(months!=Null){
            for(ECM_Payment_Summary_Item__c psItem : ps.Payment_Summary_Item__r){
                if(psItem.ECM_Contract_Item__r.ECM_Lead_Brand__c){
                    brandData.sumOfLeadActualVol += psItem.ECM_Confirmed_Volume__c!=Null?(psItem.ECM_Confirmed_Volume__c).setScale(2):0;
                    brandData.sumOfLeadVolTarget += psItem.ECM_Contract_Item__r.ECM_Volume__c!=Null?psItem.ECM_Contract_Item__r.ECM_Volume__c:0;
                }else{
                    brandData.sumOfNonLeadActualVol += psItem.ECM_Confirmed_Volume__c!=Null?(psItem.ECM_Confirmed_Volume__c).setScale(2):0;
                    brandData.sumOfNonLeadVolTarget += psItem.ECM_Contract_Item__r.ECM_Volume__c!=Null?psItem.ECM_Contract_Item__r.ECM_Volume__c:0;
                }
            }            
            //Division by Duration & multiply by Payment Summary months
            brandData.sumOfLeadVolTarget = ((brandData.sumOfLeadVolTarget/ps.ECM_Contract__r.ECM_Duration__c) * months).setScale(2);
            brandData.sumOfNonLeadVolTarget = ((brandData.sumOfNonLeadVolTarget/ps.ECM_Contract__r.ECM_Duration__c) * months).setScale(2);
        }
        return brandData;
        //End of ECM-4760
    }
    
    
     @AuraEnabled
    public static List<ECM_Payment_Summary_Item__c> getApprovedPaymentSummaryItems(String contractId, Id paymentSummaryId){
        
         List<ECM_Payment_Summary_Item__c>approvedPaymentSummaryItemList=[Select Id,Name,ECM_Contract_Item__c, ECM_Confirmed_Volume__c,ECM_Confirmed_Amount_Per_Payment__c
                                     From ECM_Payment_Summary_Item__c where ECM_Payment_Summary__r.ECM_Contract__c=:contractId AND ECM_Payment_Summary__r.ECM_Contract__r.Status='Active' AND (ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c='Approved' OR ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c='Completed') AND ECM_Payment_Summary__r.Id!=:paymentSummaryId  AND ECM_Payment_Summary__r.ECM_Type__c=:system.label.Ecm_Payment_Summary_Volume_based ];
        
        
        return approvedPaymentSummaryItemList;
    }
    
    @AuraEnabled 
    public static user fetchUser(){
        User u = [select id,Profile.Name,Available_Countries__c,ManagerId,Manager.DelegatedApproverId from User where id =: userInfo.getUserId()];//ECM-6710
        return u;
    }
    //ECM-4543
     @AuraEnabled 
    public static userMarketwrap fetchUserDetails(){
         
	  userMarketwrap uswrap=New userMarketwrap();
        Map<String,Boolean>PaysumVolumeMapmdt= new Map<String,Boolean> ();
        User u = [select Id,Profile.Name,Available_Countries__c,Default_Country__c from User where Id =: userInfo.getUserId()];
        uswrap.us=u;
        uswrap.volumecheck=false;
        //ECM-4543
        for(ECM_Technical_Market_Setting__mdt mdt: [select masterlabel,ECM_Country__c,ECM_Payment_Summary_Volume__c,ECM_Contract_Extra_Approval__c from ECM_Technical_Market_Setting__mdt 
                                                    where ECM_Payment_Summary_Volume__c=True])
        {
            PaysumVolumeMapmdt.put(mdt.ECM_Country__c,mdt.ECM_Payment_Summary_Volume__c);
        }
        /*
        if(PaysumVolumeMapmdt.get(u.Available_Countries__c)!=null){
            uswrap.volumecheck= PaysumVolumeMapmdt.get(u.Available_Countries__c);
        }*/
        //ECM-6317
        if(u.Available_Countries__c != null){
            if(u.Available_Countries__c.contains(';')){
                uswrap.volumecheck= PaysumVolumeMapmdt.containsKey(u.Default_Country__c)?PaysumVolumeMapmdt.get(u.Default_Country__c):false;
            }else{
                uswrap.volumecheck = PaysumVolumeMapmdt.containsKey(u.Available_Countries__c)?PaysumVolumeMapmdt.get(u.Available_Countries__c):false;
            }
        }
        return uswrap;
    }
    @AuraEnabled
    public static ECM_Payment_Summary__c updatePaymentSummary(ECM_Payment_Summary__c ECM_PS, String ECM_PSIs){
        
        try{
            List<ECM_Payment_Summary_Item__c> PSIList = new List<ECM_Payment_Summary_Item__c>();
            //ECM_Payment_Summary__c PSIclone = ECM_PS.getRecord().clone();
            
            if(ECM_PSIs !=null){
                PSIList = (List<ECM_Payment_Summary_Item__c>)JSON.deserialize(ECM_PSIs, List<ECM_Payment_Summary_Item__c>.class);
                Database.SaveResult[] sr = Database.update(PSIList,false);
                //PSIcloneList=PSIList.deepClone();
            }
            if(ECM_PS!=null && ECM_PS.Id!=null){
                if(ECM_PS.ECM_Type__c=='Non-Volume'){
                   // ECM_PaymentSummaryHelper.ECM_Update_IO_Code(new List<ECM_Payment_Summary__c>{ECM_PS});
                   ECM_PaymentSummaryTriggerHelper.fetchContractDetails(new List<ECM_Payment_Summary__c>{ECM_PS});
                   ECM_PaymentSummaryTriggerHelper.updateIOCode(new List<ECM_Payment_Summary__c>{ECM_PS});
                    //sendRequestEmail(new List<Id>{ECM_PS.id});
                }
                update ECM_PS;
            }
            
        }catch(exception ex ){
            system.debug(LoggingLevel.DEBUG,'update PS '+ex);
        }
        return ECM_PS;
    }
   
    //Method to execute on click of "Confirm"
    
    @AuraEnabled
    public static ECM_Payment_Summary__c updatePaymentSummaryAndSubmit(ECM_Payment_Summary__c ECM_PS, String ECM_PSIs){
        try{
            List<ECM_Payment_Summary_Item__c> PSIList = new List<ECM_Payment_Summary_Item__c>();
            Map<Id,String> userRoleMap= new  Map<Id,String>();

            if(ECM_PSIs !=null){
                PSIList = (List<ECM_Payment_Summary_Item__c>)JSON.deserialize(ECM_PSIs, List<ECM_Payment_Summary_Item__c>.class);             
                Database.SaveResult[] sr = Database.update(PSIList,false);
            }
            if(ECM_PS!=null && ECM_PS.Id!=null && ECM_PS.ECM_Payment_Summary_Status__c!='Completed'){
                if(ECM_PS.ECM_Type__c=='Non-Volume'){
                  ECM_PaymentSummaryTriggerHelper.fetchContractDetails(new List<ECM_Payment_Summary__c>{ECM_PS});
                  ECM_PaymentSummaryTriggerHelper.updateIOCode(new List<ECM_Payment_Summary__c>{ECM_PS});
                }               
                User loggedUser = userInfo.getUserId()==ECM_PS.ECM_Contract__r.OwnerId? fetchUser():[SELECT Id,ManagerId,Manager.DelegatedApproverId FROM User where Id =:ECM_PS.ECM_Contract__r.OwnerId]; //ECM-6710        
                //Added Geography__r.Code__c field in query ECM-5871  
                Market_Setting__c marSet = [SELECT Id,Name,Geography__c,Geography__r.Code__c,ECM_Manager_Approval__c FROM Market_Setting__c Where Geography__c =: ECM_PS.ECM_Contract__r.Account.Country__c];
                List<String> managerApprovalPsTypes = new List<String>();
                if(marSet.ECM_Manager_Approval__c !=Null){
                    managerApprovalPsTypes = marSet.ECM_Manager_Approval__c.split(';');
                }
                String groupRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
                List<Id>paymentSummaryList= new List<Id>(); //Added for ECM-5871  
                List<Id>paymentSumListAddApprov= new List<Id>(); 
                if(ECM_PS.ECM_Type__c!='Non-Volume'){
                    if(managerApprovalPsTypes.contains(ECM_PS.ECM_Type__c)){
                        if(groupRecordTypeID==ECM_PS.ECM_Contract__r.RecordTypeId){
                            for(Account acc:[select id,Person_Responsible__r.ManagerId,Person_Responsible__r.Manager.DelegatedApproverId from account where id=:ECM_PS.ECM_Contract__r.Account.Id]){
                                ECM_PS.ECM_Manager_Approver__c = (managerApprovalPsTypes.contains(ECM_PS.ECM_Type__c) && acc.Person_Responsible__c!=Null && acc.Person_Responsible__r.ManagerId!=Null)?acc.Person_Responsible__r.Manager.DelegatedApproverId!=Null?acc.Person_Responsible__r.Manager.DelegatedApproverId:acc.Person_Responsible__r.ManagerId:null;//ECM-6710
                            }
                        }else{
                                ECM_PS.ECM_Manager_Approver__c = (managerApprovalPsTypes.contains(ECM_PS.ECM_Type__c) && loggedUser.ManagerId!=Null)?loggedUser.Manager.DelegatedApproverId!=Null?loggedUser.Manager.DelegatedApproverId:loggedUser.ManagerId:null;//ECM-6710
                        }
                        userRoleMap.put(ECM_PS.ECM_Manager_Approver__c,'');//newBuild
                        ECM_PaymentSummaryTriggerHelper.checkAndProvideAccountAccess(ECM_PS.ECM_Contract__r.Account.Id,userRoleMap);//newBuild
                        ECM_PS.ECM_Approval_Sub_Status__c=Label.ECM_In_Manager_Approval;
                    }else{
                        //Changes related to ECM-5871 Start
                        paymentSummaryList = ECM_PaymentSummaryTriggerHelper.checkForExtraApprovalAvailability(new List<ECM_Payment_Summary__c>{ECM_PS});
                        if(marSet.Geography__r.Code__c == 'AU'){
                           ECM_PS.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
                        }
                        else{
                            if(!paymentSummaryList.isEmpty()){
                        	 	ECM_PS.ECM_Approval_Sub_Status__c=label.ECM_In_Extra_Approval;
                            }
                            else{
                                //Changes for C360 - 146079
                                //ECM_PS.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
                                paymentSumListAddApprov = ECM_PaymentSummaryTriggerHelper.validateAdditionalExtraApproval(new List<ECM_Payment_Summary__c>{ECM_PS});
                                if(!paymentSumListAddApprov.isEmpty()){
                                     ECM_PS.ECM_Approval_Sub_Status__c=Label.C360_Extra_Approval_Initial_vs_Actual;
                                }
                                else{
                                    ECM_PS.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
                                }
                            }
                        }
                        //Changes related to ECM-5871 End
                        //ECM_PS.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
                    }
                }else{
                    ECM_PS.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
                }
                 //Added condition for ECM-5871 
                if(marSet.Geography__r.Code__c == 'AU'){
                	ECM_PS.ECM_Payment_Summary_Status__c=(managerApprovalPsTypes.contains(ECM_PS.ECM_Type__c))?'In Approval process':'Submitted';
                }
                else{
                     if(ECM_PS.ECM_Approval_Sub_Status__c == label.ECM_In_Extra_Approval || ECM_PS.ECM_Approval_Sub_Status__c== Label.ECM_In_Manager_Approval || ECM_PS.ECM_Approval_Sub_Status__c == label.C360_Extra_Approval_Initial_vs_Actual){
                         ECM_PS.ECM_Payment_Summary_Status__c = 'In Approval process';
                    }
                    else if(ECM_PS.ECM_Approval_Sub_Status__c == label.ECM_CIO_Approval){
                          ECM_PS.ECM_Payment_Summary_Status__c = 'Submitted';
                    }		
                }
                update ECM_PS;  
                
                //Changes related to ECM-5871 Start
                if((ECM_PS.ECM_Type__c!='Non-Volume') && ECM_PS.ECM_Payment_Summary_Status__c=='In Approval process' && ECM_PS.Owner__c== loggedUser.Id
                        && ECM_PS.ECM_Approval_Sub_Status__c == label.ECM_In_Extra_Approval){
                    ECM_PaymentSummaryTriggerHelper.checkForExtraApproval(new List<ECM_Payment_Summary__c>{ECM_PS});
                //Changes related to ECM-5871 End
                }
                //Changes for C360 - 146079 Start
                else if((ECM_PS.ECM_Type__c!='Non-Volume') && ECM_PS.ECM_Payment_Summary_Status__c=='In Approval process' && ECM_PS.Owner__c== loggedUser.Id
                        && ECM_PS.ECM_Approval_Sub_Status__c == label.C360_Extra_Approval_Initial_vs_Actual){//NewBuild
                    ECM_PaymentSummaryTriggerHelper.checkForAdditionalExtraApproval(new List<ECM_Payment_Summary__c>{ECM_PS});
                }
                //Changes for C360 - 146079 End
                else if((ECM_PS.ECM_Type__c!='Non-Volume') && ECM_PS.ECM_Payment_Summary_Status__c=='In Approval process' && ECM_PS.Owner__c== loggedUser.Id){
                      submitForApprovalProcess(ECM_PS, loggedUser,ECM_PS.ECM_Manager_Approver__c );
                }else if( ECM_PS.ECM_Payment_Summary_Status__c=='Submitted' && ECM_PS.Owner__c== loggedUser.Id ){ 
                    ECM_PaymentSummaryTriggerHelper.checkForCIOApproval(new List<ECM_Payment_Summary__c>{ECM_PS});
                }               
            }else{
                update ECM_PS;
            }           
        }catch(Exception Ex){
            system.debug(LoggingLevel.DEBUG,'updatePaymentSummary='+Ex);
        } 
         return ECM_PS;
    }
    @AuraEnabled
    Public static void submitForApprovalProcess(ECM_Payment_Summary__c ECM_PS, User loggedUser, Id approverId){
        
        // Create an approval request for the account
        Approval.ProcessSubmitRequest apprReq = 
            new Approval.ProcessSubmitRequest();
        apprReq.setComments(Label.ECM_PSApprovalReqMsg);
        apprReq.setObjectId(ECM_PS.id);
        if(approverId!=null){
        	apprReq.setNextApproverIds(new List<Id>{approverId});
        }
        // Submit on behalf of a specific submitter
        apprReq.setSubmitterId(loggedUser.Id); 
        
        // Submit the record to specific process and skip the criteria evaluation
        //apprReq.setProcessDefinitionNameOrId('ECM_Payment_Summary_Submitted_Status_001');
        apprReq.setSkipEntryCriteria(false);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(apprReq);
    }
            
    
    @AuraEnabled //get Invoice status Picklist Values
    public static Map<String, String> getInvoiceStatus(){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = ECM_Payment_Summary__c.ECM_Invoice_Status__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
    
    @AuraEnabled //get PS status Picklist Values
    public static Map<String, String> getPaymentSummaryStatus(){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = ECM_Payment_Summary__c.ECM_Payment_Summary_Status__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(), p.getLabel());
        }
        
        return options;
    }
    
    @AuraEnabled //get Tax Rate Picklist Values
    public static Map<String, String> getTaxRate(){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = ECM_Payment_Summary__c.ECM_Tax_Rate__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
    
    @AuraEnabled//actual cases sold in previous quarter - AU - S10_SFDC_AU_Logic Portfolio Rebates
    public static List<SKURebatesRate> getActualSoldCases(ECM_Payment_Summary__c ECM_PS){
        quarterlyPortfolioRebates qPR = new quarterlyPortfolioRebates();
        List<SKURebatesRate> qPRlst = new List<SKURebatesRate>();
        Map<id,string> productSet = new Map<id,string>();
        Integer ActualTotalCasesSoldInPrevQ = 0;
        Map<String,Decimal> depletionCountForOutlets = new Map<String,Decimal>();
       // map<String,quarterlyActualPSI> qPSI = new map<String,quarterlyActualPSI>();
        if(ECM_PS !=null && ECM_PS.ECM_Contract__c !=null && ECM_PS.ECM_Contract__r.Status=='Active'){
            String thisYear = String.valueOf(Date.today().Year());
            ECM_Rebates_Calendar__mdt rcMDT=ECM_PaymentSummaryController.getRcMdt(thisYear);           
            if(rcMDT !=null){
                Date startDate = ECM_PS.ECM_Contract__r.StartDate > rcMDT.ECM_Rebate_Period_Start__c?ECM_PS.ECM_Contract__r.StartDate:rcMDT.ECM_Rebate_Period_Start__c;
                for(Depletions__c depletionRecord: [SELECT Id, ECM_Outlet__c, ECM_Start_Period__c,ECM_Product__r.Name, ECM_End_Period__c, ECM_Product__c, 
                                                        ECM_Volume__c, ECM_UoM__c FROM Depletions__c Where ECM_Start_Period__c>=:startDate 
                                                        AND ECM_End_Period__c<=:rcMDT.ECM_Rebate_Period_End__c]){
                                                            if(ECM_PS.ECM_Contract__r.UOS_Rebate_Rate__c>0 && depletionRecord.ECM_Product__c!=null){
                                                                productSet.put((ID)depletionRecord.ECM_Product__c,depletionRecord.ECM_Product__r.Name);
                                                               if(depletionCountForOutlets.containsKey(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c)){
                                                                    Decimal volumeRate = depletionCountForOutlets.get(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c)+depletionRecord.ECM_Volume__c;
                                                                    depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c,volumeRate);
                                                                }else{
                                                                    depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c,depletionRecord.ECM_Volume__c);
                                                                }
                                                            }                                                            
                                                        }
                system.debug(LoggingLevel.DEBUG,'size of Depletion '+depletionCountForOutlets.size());
                Map<String, ECM_Price_List_Item__c> priceListMap = new Map<String, ECM_Price_List_Item__c>();
                List<ECM_Price_List_Item__c> priceListItem = [Select Id,ECM_UOS__c,ECM_Product__c,ECM_Pickup_Option__c from ECM_Price_List_Item__c where ECM_Price_List__r.ECM_Geography__r.Name =: countryName AND/* ECM_Product__c=:productSet.keyset() AND*/ ECM_Pickup_Option__c=:ECM_PS.ECM_Contract__r.ECM_Banner__c];
                
                for(ECM_Price_List_Item__c PLI: priceListItem){
                    if(PLI.ECM_Product__c !=null){
                        priceListMap.put(ECM_PS.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name=='Australia'? PLI.ECM_Product__c+'-'+PLI.ECM_Pickup_Option__c:PLI.ECM_Product__c ,PLI);
                    }
                }
                system.debug(LoggingLevel.DEBUG,'size of pli'+priceListMap);
                for(ECM_Payment_Summary_Item__c prodId: ECM_PS.Payment_Summary_Item__r){
                    SKURebatesRate skuRebate = new SKURebatesRate();
                    skuRebate.prod = prodId.ECM_Product__r.name;   
                    skuRebate.prodId = (string)prodId.ECM_Product__c;                
                    skuRebate.actualCase = prodId.ECM_Actual_Cases__c;//depletionCountForOutlets.get(ECM_PS.ECM_Contract__r.Account.parent_outlet__c+'-'+prodId)==NULL?0:depletionCountForOutlets.get(ECM_PS.ECM_Contract__r.Account.parent_outlet__c+'-'+prodId);
                    if(ECM_PS.ECM_Budget_types__r.Name =='Portfolio Rebates [AU]'){
                        skuRebate.ProductDisc_Total = skuRebate.actualCase;
                        skuRebate.uosWeight = priceListMap.containskey(prodId.ECM_Product__c+'-'+ECM_PS.ECM_Contract__r.ECM_Banner__c)?priceListMap.get(prodId.ECM_Product__c+'-'+ECM_PS.ECM_Contract__r.ECM_Banner__c).ECM_UOS__c:0;
                        skuRebate.totalUos = skuRebate.uosWeight*(skuRebate.actualCase!=Null?skuRebate.actualCase:0);
                    }
                    if(prodId.ECM_Actual_Cases__c>0){
                        qPRlst.add(skuRebate);
                }
                }
               /* List<ECM_Payment_Summary_Item__c>quarterlyPSI = [Select ECM_Confirm__c, ECM_Confirmed_Volume__c, 
                                                                 ECM_Contract_Item__r.ECM_Product_Name__c, ECM_Contract_Item__r.ECM_UOS__c,
                                                                 ECM_Contract_Item__r.ECM_Product__r.Product__c 
                                                                 FROM ECM_Payment_Summary_Item__c
                                                                 WHERE ECM_Payment_Summary__c=:ECM_PS.Id AND
                                                                 ECM_Confirm__c=TRUE AND
                                                                 Start_Period__c>=:startDate AND Start_Period__c<=:rcMDT.ECM_Rebate_Period_End__c AND
                                                                 ECM_End_Period__c>=:startDate AND ECM_End_Period__c<=:rcMDT.ECM_Rebate_Period_End__c];
               
                if(quarterlyPSI !=null && quarterlyPSI.size()>0){
                    for(ECM_Payment_Summary_Item__c p : quarterlyPSI){
                        
                        if(p.ECM_Contract_Item__r.ECM_Product__r.Product__c!=null){
                            Product__c pd = new Product__c();
                            pd.Id = p.ECM_Contract_Item__r.ECM_Product__r.Product__c;
                            pd.Name = p.ECM_Contract_Item__r.ECM_Product_Name__c;
                            
                            Decimal tNPP = (p.ECM_Confirmed_Volume__c * p.ECM_Contract_Item__r.ECM_UOS__c);
                            if(qPSI.get(pd.Id) !=null){
                                qPSI.get(pd.Id).noOfCases = qPSI.get(pd.Id).noOfCases+p.ECM_Confirmed_Volume__c;
                            }else{
                                quarterlyActualPSI qPSIInternal = new quarterlyActualPSI(pd,p.ECM_Confirmed_Volume__c,p.ECM_Contract_Item__r.ECM_UOS__c,tNPP);
                                qPSI.put(pd.Id,qPSIInternal);
                            }
                        }
                    }
                }
                if(qPSI!=null && qPSI.size()>0){
                    Decimal totalUOSInternal = 0;
                    Decimal totalToBeInvoicedInternal = 0;
                    Decimal uosPortfolioRebateRateInternal = ECM_PS.ECM_Contract__r.UOS_Rebate_Rate__c>0 ? ECM_PS.ECM_Contract__r.UOS_Rebate_Rate__c : 0;
                    for(quarterlyActualPSI q : qPSI.values()){
                        totalUOSInternal = totalUOSInternal+q.totalUOSPerProd;
                    }
                    if(totalUOSInternal>0 && uosPortfolioRebateRateInternal>0){
                        totalToBeInvoicedInternal = (totalToBeInvoicedInternal * uosPortfolioRebateRateInternal);
                    }
                    qPR.qPSIReturn =  qPSI.values();
                    qPR.totalUOS = totalUOSInternal;
                    qPR.uosPortfolioRebateRate = uosPortfolioRebateRateInternal;
                    qPR.totalToBeInvoiced = totalToBeInvoicedInternal;
                } */
                
            }
        }
        system.debug(LoggingLevel.DEBUG,'='+qPRlst);
        return qPRlst;
    }
    @AuraEnabled//actual cases sold in previous quarter - AU - S10_SFDC_AU_Logic SKU Specific Rebates
    public static List<SKURebatesRate> getSKURebateCase(ECM_Payment_Summary__c ECM_PS){
        List<SKURebatesRate> qPR = new List<SKURebatesRate>();
        Integer ActualTotalCasesSoldInPrevQ = 0;
        map<String,SKURebatesRate> qPSI = new map<String,SKURebatesRate>();
        Map<String,Decimal> depletionCountForOutlets = new Map<String,Decimal>(); 
        System.debug(LoggingLevel.DEBUG,'Payment='+ECM_PS.ECM_Contract__r.Status);
        if(ECM_PS !=null && ECM_PS.ECM_Contract__c !=null && ECM_PS.ECM_Contract__r.Status=='Active'){
            String thisYear = String.valueOf(Date.today().Year());
            List<ECM_Rebates_Calendar__mdt> rcMDT= new List<ECM_Rebates_Calendar__mdt>{ECM_PaymentSummaryController.getRcMdt(thisYear)};
            //system.debug(LoggingLevel.DEBUG,'rcMDT ==> '+rcMDT);
            if(rcMDT !=null && !rcMDT.isEmpty()){
                
                List<ECM_Contract_Item__c> conItems = [SELECT Id,ECM_Contract__r.Account.Hybrid__c, ECM_Contract__c,ECM_Contract__r.Account.parent_outlet__c,ECM_Contract__r.AccountId,ECM_Contract__r.UOS_Rebate_Rate__c, ECM_Product__c,ECM_Product__r.Product__c,ECM_Product_Name__c, ECM_TotalSKU_SpecificRebate__c,
                                                       ECM_Price_List_ConItem__r.ECM_UOS__c,ECM_Price_List_ConItem__c FROM ECM_Contract_Item__c Where ECM_Contract__c =: ECM_PS.ECM_Contract__c];
                
                if(conItems.size()>0){
                    Date startDate = ECM_PS.ECM_Contract__r.StartDate > rcMDT[0].ECM_Rebate_Period_Start__c?ECM_PS.ECM_Contract__r.StartDate:rcMDT[0].ECM_Rebate_Period_Start__c;
                    for(Depletions__c depletionRecord: [SELECT Id, ECM_Outlet__c, ECM_Start_Period__c, ECM_End_Period__c, ECM_Product__c, 
                                                        ECM_Volume__c, ECM_UoM__c FROM Depletions__c Where ECM_Start_Period__c>=:startDate 
                                                        AND ECM_End_Period__c<=:rcMDT[0].ECM_Rebate_Period_End__c]){
                                                            system.debug(LoggingLevel.DEBUG,conItems[0].ECM_Contract__r.AccountId+'date='+depletionRecord.ECM_Outlet__c);
                                                            system.debug(LoggingLevel.DEBUG,'date='+depletionRecord);
                                                            if(conItems[0].ECM_Contract__r.Account.parent_outlet__c!=Null && conItems[0].ECM_Contract__r.Account.Hybrid__c==true ){
                                                                if(depletionCountForOutlets.containsKey(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c)){
                                                                    Decimal volumeRate = depletionCountForOutlets.get(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c)+depletionRecord.ECM_Volume__c;
                                                                    depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c,volumeRate);
                                                                }else{
                                                                    depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c,depletionRecord.ECM_Volume__c);
                                                                }
                                                            }
                                                            
                                                        }
                    System.debug(LoggingLevel.DEBUG,'=='+depletionCountForOutlets);
                    for(ECM_Contract_Item__c conitem: conItems){
                        SKURebatesRate skuRebate = new SKURebatesRate();
                        skuRebate.prod = conitem.ECM_Product_Name__c;   
                        skuRebate.prodId =  conitem.Id;                
                        skuRebate.actualCase = depletionCountForOutlets.get(conitem.ECM_Contract__r.Account.parent_outlet__c+'-'+conitem.ECM_Product__r.Product__c)==NULL?0:depletionCountForOutlets.get(conitem.ECM_Contract__r.Account.parent_outlet__c+'-'+conitem.ECM_Product__r.Product__c);
                        if(ECM_PS.ECM_Budget_types__r.Name!='Portfolio Rebates [AU]'){
                            skuRebate.rebateCase = conitem.ECM_TotalSKU_SpecificRebate__c==Null?0:conitem.ECM_TotalSKU_SpecificRebate__c;
                            skuRebate.ProductDisc_Total = skuRebate.actualCase*skuRebate.rebateCase;
                            skuRebate.totalUos = skuRebate.ProductDisc_Total;
                        }else{
                            skuRebate.uosWeight = conitem.ECM_Price_List_ConItem__r.ECM_UOS__c!=Null?conitem.ECM_Price_List_ConItem__r.ECM_UOS__c:0;
                            skuRebate.totalUos = skuRebate.actualCase*skuRebate.uosWeight;
                            system.debug(LoggingLevel.DEBUG,'total uos'+skuRebate.totalUos);
                            skuRebate.ProductDisc_Total = skuRebate.totalUos*(conitem.ECM_Contract__r.UOS_Rebate_Rate__c!=Null?conitem.ECM_Contract__r.UOS_Rebate_Rate__c:0);
                        }
                        system.debug(LoggingLevel.DEBUG,'='+skuRebate.actualCase);
                        qPR.add(skuRebate);
                    }
                }
            }
        }
        system.debug(LoggingLevel.DEBUG,'qPR==> '+qPR); 
        return qPR;
    }
    @AuraEnabled
    public static List<ConItemTier> getConItemTier(ECM_Payment_Summary__c ECM_PS){
        system.debug(LoggingLevel.DEBUG,'Insideget ConItemTier');
        List<ConItemTier> conTierLst = new List<ConItemTier>();
        if(ECM_PS !=null && ECM_PS.ECM_Contract__c !=null && ECM_PS.ECM_Contract__r.Status=='Active'){
                Market_Setting__c marSet = [SELECT Id,Name,Geography__c,ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c FROM Market_Setting__c Where Geography__c =: ECM_PS.ECM_Contract__r.Account.Country__c];
                system.debug(LoggingLevel.DEBUG,'marSet-->'+marSet);
               // List<ECM_Payment_Summary__c> psLst = [select Id,name,ECM_Type__c,ECM_Contract__c from ECM_Payment_Summary__c where ECM_Type__c='Volume-Based' AND ECM_Contract__r.Account.Country__r.Name='Spain' And ECM_Contract__c=:ECM_PS.ECM_Contract__c];
                //system.debug('conItems-->'+psLst.Size());
                List<ECM_Contract_Item__c> conItems = [SELECT Id FROM ECM_Contract_Item__c Where ECM_Contract__c =: ECM_PS.ECM_Contract__c];
                system.debug(LoggingLevel.DEBUG,'conItems-->'+conItems);
                List<ECM_Tiering__c> tierLst = [SELECT Id,Name,ECM_Contract_Item__c,ECM_Tier_1_volume_limit__c,ECM_Tier_1_rate_per_UoM__c,ECM_Tier_2_volume_limit__c,ECM_Tier2_rate_per_UoM__c,ECM_Tier_3_volume_limit__c,ECM_Tier_3_rate_per_UoM__c FROM ECM_Tiering__c Where ECM_Contract_Item__c IN:conItems];
                system.debug(LoggingLevel.DEBUG,'tierLst-->'+tierLst);
                
                if(tierLst.size()>0){
                    for(ECM_Tiering__c tierObj: tierLst){
                        system.debug(LoggingLevel.DEBUG,'tierObj-->'+tierObj);
                        ConItemTier ConTier = new ConItemTier();   
                        ConTier.conItem =  tierObj.ECM_Contract_Item__c;
                        ConTier.marTier =  marSet.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c;
                        ConTier.t1Vol =  tierObj.ECM_Tier_1_volume_limit__c;
                        ConTier.t1Uom =  tierObj.ECM_Tier_1_rate_per_UoM__c;
                        ConTier.t2Vol =  tierObj.ECM_Tier_2_volume_limit__c;
                        ConTier.t2Uom =  tierObj.ECM_Tier2_rate_per_UoM__c;
                        ConTier.t3Vol =  tierObj.ECM_Tier_3_volume_limit__c;
                        ConTier.t3Uom =  tierObj.ECM_Tier_3_rate_per_UoM__c;
                        conTierLst.add(ConTier);
                    }
                }
        }
        system.debug(LoggingLevel.DEBUG,'conTierLst==> '+conTierLst); 
        return conTierLst;
    }
    @AuraEnabled
    public static Boolean handleCsvGeneration(string paymentSummaryId){
        system.debug(LoggingLevel.DEBUG,'paymentSummaryId-->'+paymentSummaryId);
        boolean Contentcheck = false;
        List<String> conDocIds = new List<String>();
        list<String> csvEnable =  new list<String>();
        
        list< ContentDocumentLink > paymentsummary = [Select Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink where LinkedEntityId in (SELECT Id FROM ECM_Payment_Summary__c where id =: paymentSummaryId) and LinkedEntity.Type='ECM_Payment_Summary__c'];
        if (paymentsummary.size()>0){
            for(ContentDocumentLink conDoc : paymentsummary){
                conDocIds.add(conDoc.ContentDocumentId);
            }
        }
        list<ContentVersion> fileExtension = [select Id, PathOnClient, FileExtension, ContentDocumentId from ContentVersion where ContentDocumentId IN: conDocIds];
        if (fileExtension.size()>0){
            for(ContentVersion conVer: fileExtension){
                if(conVer.PathOnClient == 'PaySumExcel.csv'){
                    csvEnable.add(conVer.Id);           
                }
            }
        }
        if (csvEnable.size()>0){                
            Contentcheck = true;             
        }else{
            Contentcheck = false; 
           // ECM_PaymentSummaryCsvExportHandler.sendEmail(new List<Id>{paymentSummaryId});
        }
        return Contentcheck;
    }
    
    //SAP callout for Payment Summary
    @AuraEnabled
    public static void sendSAPCallout(string paymentSummaryId){
        system.debug(LoggingLevel.DEBUG,'paymentSummaryId-->'+paymentSummaryId);
        ECM_Payment_Summary__c paymentRecord = 
            [SELECT ECM_Type__c,ECM_Payment_Summary_Status__c,
             ECM_Transmission_Status__c,ECM_Error_message__c,ECM_SAP_Credit_Note_Number__c,
             ECM_SAP_Credit_Note_Creation_Date__c
             FROM ECM_Payment_Summary__c
             WHERE Id =:paymentSummaryId];
        
        if(paymentRecord.ECM_Type__c=='Non-Volume'){
            ECM_PaymentSummaryToSAPCallout.getPaymentDataNonVolume(new set<Id>{paymentSummaryId});
        }
        else{
            ECM_PaymentSummaryToSAPCallout.getPaymentData(new set<Id>{paymentSummaryId});
        }
    }
    
    //method to retrieve attachments
    @AuraEnabled
    public static attachwrap getPSattachments(string paymentSummaryId,string selectedbudget){
        set<Id> contentdocId=New set<Id>();
        attachwrap attwrap=New attachwrap();
		attwrap.evidence=false;
		attwrap.invoice=false;
        List<ContentDocumentLink> cdlink=[SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: paymentSummaryId];
        for(ContentDocumentLink cdl:cdlink){
            contentdocId.add(cdl.ContentDocumentId);
        }
        Id recTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('ECM_Payments').getRecordTypeId(); //ECM-6651 - Added getRecordTypeInfosByDeveloperName and ECM_Payments
        //List<ContentVersion> cv=[SELECT Id, VersionData,Content_Type__c FROM ContentVersion WHERE  ContentDocumentId In:contentdocId AND (Content_Type__c ='Evidence' OR Content_Type__c='Invoice') AND recordtypeId=:recTypeId];
		        for(ContentVersion cv:[SELECT Id, VersionData,Content_Type__c FROM ContentVersion WHERE  ContentDocumentId In:contentdocId AND (Content_Type__c ='Evidence' OR Content_Type__c='Invoice') AND recordtypeId=:recTypeId]){
					if(cv.Content_Type__c=='Evidence'){
						attwrap.evidence=true;
					}else if(cv.Content_Type__c=='Invoice'){						
						attwrap.invoice=true;
					}
				}

        system.debug(LoggingLevel.DEBUG,'selectedbudget'+selectedbudget);
        //  ECM_Payment_Summary__c ps=[Select Id,Name,ECM_Budget_types__r.Name,ECM_Budget_types__r.ECM_Evidence_Mandatory__c from ECM_Payment_Summary__c where id=:paymentSummaryId];
        if(selectedbudget != '' && selectedbudget !=null){
            Pick_Up_Options__c pickobj=[Select Id,Name,ECM_Evidence_Mandatory__c from Pick_Up_Options__c where id=:selectedbudget];
            attwrap.psObj=pickobj;
        }
        else{
            attwrap.psObj =new Pick_Up_Options__c();  
        }
           
            return attwrap ; 
    }
    
    @AuraEnabled
    public static String getUserRole(String processInstanceStepId ){
        List<processInstanceStep>processStepList=[select id,OriginalActorId from processInstanceStep where id=:processInstanceStepId];
        if(!processStepList.isEmpty()){
           List<ECM_Extra_Approval__c>extraApprovalList= [select id,ECM_Approver_Position_Name__c from ECM_Extra_Approval__c where ECM_Extra_Approval_User__c=:processStepList[0].OriginalActorId];
            if(!extraApprovalList.isEmpty()){
                return extraApprovalList[0].ECM_Approver_Position_Name__c;
            }
        }
        return null;
    }
    

	Public static void updateInternalOrder(List<ECM_Internal_Order__c> internalOrderList){

        ECM_InternalOrderTriggerHandler.isFirstTime=false;

        Update internalOrderList;
	}
    
        //ECM-4938 : Method to update Invoice & Evidence Attachment fields on PaymentSummary
    //Referenced in EDGE_ContentDocumentLinkTriggerHelper class updatePaymentFields method
   Public static void updatePsFields(Map<Id, ECM_Payment_Summary__c> psMap){
        Update psMap.values();
	}
    
    public class attachwrap{
        @AuraEnabled public Pick_Up_Options__c psObj {get;set;}
        @AuraEnabled public boolean evidence {get;set;} 
		//ECM-4611
		@AuraEnabled public boolean invoice {get;set;} 
    }
    //ECM-4543
    public class userMarketwrap{
        @AuraEnabled public user us {get;set;}
        @AuraEnabled public boolean volumecheck {get;set;} 
    }
    /*public class quarterlyActualPSI{
        @AuraEnabled public String prod {get;set;}
        @AuraEnabled public Id prodId {get;set;}
        @AuraEnabled public Decimal actualCases {get;set;}
        @AuraEnabled public Decimal uosWeight{get;set;}
        @AuraEnabled public Decimal totalUOSPerProd{get;set;}
        public quarterlyActualPSI (string p,Id pid, Decimal c, Decimal u, Decimal t){
            prod = p;
            prodId = pid;
            actualCases = c;
            uosWeight = u;
            totalUOSPerProd = t;
        }
    }*/
    public class quarterlyPortfolioRebates{
        @AuraEnabled public List<SKURebatesRate> qPSIReturn {get;set;}
        @AuraEnabled public Decimal totalPSUOS {get;set;}
        @AuraEnabled public Decimal uosPortfolioRebateRate {get;set;}
        @AuraEnabled public Decimal totalToBeInvoiced {get;set;}
        public quarterlyPortfolioRebates(){
            qPSIReturn = new List<SKURebatesRate>();
            totalPSUOS = 0;
            uosPortfolioRebateRate = 0;
            totalToBeInvoiced = 0;
        }
    }
    public class SKURebatesRate{
        @AuraEnabled public string prod {get;set;}
        @AuraEnabled public string prodId{get;set;}
        @AuraEnabled public Decimal actualCase {get;set;}
        @AuraEnabled public Decimal uosWeight{get;set;}
        @AuraEnabled public Decimal totalUos{get;set;}
        @AuraEnabled public Decimal rebateCase{get;set;}
        @AuraEnabled public Decimal ProductDisc_Total{get;set;}
        public SKURebatesRate (/*Product__c p, Decimal c, Decimal u, Decimal t*/){
            prod = '';
            prodId = '';
            actualCase = 0;
            uosWeight = 0;
            totalUos = 0;
            rebateCase = 0;
            ProductDisc_Total = 0;
        }
    }
    public class ConItemTier{
        @AuraEnabled public string conItem {get;set;}
        @AuraEnabled public string marTier {get;set;}
        @AuraEnabled public Decimal t1Vol{get;set;}
        @AuraEnabled public Decimal t1Uom{get;set;}
        @AuraEnabled public Decimal t2Vol{get;set;}
        @AuraEnabled public Decimal t2Uom{get;set;}
        @AuraEnabled public Decimal t3Vol{get;set;}
        @AuraEnabled public Decimal t3Uom{get;set;}
        public ConItemTier (){
            conItem = '';
            marTier = '';
            t1Vol = 0;
            t1Uom = 0;
            t2Vol = 0;
            t2Uom = 0;
            t3Vol = 0;
            t3Uom = 0;
        }
    }
    //Added as part of ECM-4760
    public class brandCalculation{
        @AuraEnabled public Decimal sumOfLeadActualVol{get; set;}
        @AuraEnabled public Decimal sumOfLeadVolTarget{get; set;}
        @AuraEnabled public Decimal sumOfNonLeadActualVol{get; set;}
        @AuraEnabled public Decimal sumOfNonLeadVolTarget{get; set;}
        public brandCalculation (){
            sumOfLeadActualVol = 0;
            sumOfNonLeadActualVol = 0;
            sumOfLeadVolTarget = 0;
            sumOfNonLeadVolTarget = 0;
        }
    }
    public static ECM_Rebates_Calendar__mdt getRcMdt(String thisyear)
    {
        ECM_Rebates_Calendar__mdt rcMDT=new ECM_Rebates_Calendar__mdt();
        
        if(!Test.isRunningTest() && Schema.sObjectType.ECM_Rebates_Calendar__mdt.isAccessible())
        {
            rcMDT= [Select ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_End__c, 
                    ECM_Rebate_Period_Start__c, ECM_Region__c, ECM_Financial_Year__c,
                    ECM_Quarter__c
                    From ECM_Rebates_Calendar__mdt
                    Where ECM_Region__c=:countryName
                    and ECM_Financial_Year__c=:thisYear limit 1];
        }
        else if(Schema.sObjectType.ECM_Rebates_Calendar__mdt.isAccessible())
        {
            rcMDT= [Select ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_End__c, 
                    ECM_Rebate_Period_Start__c, ECM_Region__c, ECM_Financial_Year__c,
                    ECM_Quarter__c
                    From ECM_Rebates_Calendar__mdt
                    Where ECM_Region__c=:countryName
                    and ECM_Financial_Year__c='2023' limit 1];
        }
        return rcMDT;
    }
    
}