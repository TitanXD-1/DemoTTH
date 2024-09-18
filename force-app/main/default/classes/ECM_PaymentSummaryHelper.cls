/*
 * Class Name : ECM_PaymentSummaryHelper
 * @description: Helper Class for ECM_PaymentSummaryHandler
 * @history
 * VERSION    AUTHOR                    DATE              DETAIL
 * 1.1        Veerendra Billakurthi     22/06/2021    ECM-4561- Deployment_Enable the budget type for Ireland 
 * 1.2        Sayan Mullick             02/08/2021    ECM-4620 - Rejection Notification for Sales rep for the 
                                                      Promo standard and Volume PS_SFDC_Approval revamp 
 * 1.3        Saurav && Anuja           30/07/2021    ECM-4764 - Push Notification revamp
 * 1.4        Anuja Chattopadhyay       05/10/2021    ECM-4787 - Email for the New Extra Approver Type-(Volume Based PS-Target) 
*/

public without sharing class ECM_PaymentSummaryHelper {
    
    public static void ECM_Update_IO_Code(List < ECM_Payment_Summary__c > newPaySum) {
        date today = System.TODAY();
        // Set of Contract id from the Payment Summary Record
        set < id > contract_ids = new set < id > ();
        //Map of contracts of Geography : Australia
        Map < Id, Contract > Map_Id_Contract = new Map < Id, Contract > ();
        //Map of Unique String and Internal Order record
        Map < String, ECM_Internal_Order__c > Map_Unique_Internal_Order = new Map < String, ECM_Internal_Order__c > ();
        Id Owner_Recordtype_Id = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        
        list<Account> Owner = [select id from Account where recordtypeid =: Owner_Recordtype_Id and Name =: System.label.ECM_Recommended_IO_Code_Owner_Value
                               limit 1
                              ];
        for (ECM_Payment_Summary__c record: newPaySum) {
            
            if (record.ECM_Contract__c != null && record.ECM_Budget_types__c != null) {
                
                contract_ids.add(record.ECM_Contract__c);
            }
        }
        // if contract_ids size > 0
        if (contract_ids.size() > 0) {
            Map_Id_Contract = new Map < Id, Contract > ([select id, Account.Hybrid__c, Account.ParentId,Account.BillingState, ECM_Channel__c
                                                         from contract where id in: contract_ids and ECM_Agreement_Type__r.Geography__r.Name =: 'Australia'
                                                        ]);
        }
        //List of Internal Order records  where Active is true and Start Date and End Date lies between Today
        list < ECM_Internal_Order__c > List_Internal_Order = [select id, Name, ECM_Active__c, Ecm_Channel__c, Owner__c,
                                                              ECM_Budget_Type_Pickup_Option__c, ECM_End_Date__c, ECM_Start_Date__c,
                                                              ECM_State__c from ECM_Internal_Order__c where ECM_Active__c =: true
                                                              and ECM_Start_Date__c <=: today and ECM_End_Date__c >=: today and ECM_State__c != null and ECM_State__c != ''
                                                              and ECM_Start_Date__c != null and ECM_End_Date__c != null
                                                              and Owner__c != null and ECM_Budget_Type_Pickup_Option__c != null and Owner__c != ''
                                                              and ECM_Budget_Type_Pickup_Option__c != ''
                                                             ];
        if (List_Internal_Order.size() > 0) {
            for (ECM_Internal_Order__c Internal_Order: List_Internal_Order) {
                // creates a Unique pratten with Banner ,Budget Type ,State
                string unique = Internal_Order.Owner__c + '' + Internal_Order.ECM_Budget_Type_Pickup_Option__c + '' + Internal_Order.ECM_State__c;
                system.debug('unique' + unique);
                Map_Unique_Internal_Order.put(unique, Internal_Order);
            }
        }
        Map < Id, Account > Map_Id_Account = new Map < Id, Account > ();
        if (Map_Id_Contract.size() > 0 && newPaySum.size() > 0) {
            for (ECM_Payment_Summary__c Payment_Summary_Record: newPaySum) {
                if (Payment_Summary_Record.ECM_Budget_types__c != null) {
                    /*if ((Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).ECM_Channel__c == 'On-Premise' &&
!Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.Hybrid__c) ||
(Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).ECM_Channel__c == 'On-Premise' &&
Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.Hybrid__c) ||
(Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).ECM_Channel__c == 'Hybrid' &&
Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.Hybrid__c)

) {*/
                    if ( Owner.size()>0 && Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId == null ) {
                        Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId = Owner[0].id;
                    }
                    // creates a Unique pratten with Banner ,Budget Type ,State
                    if ((Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId != null ||
                         Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId != '')) {
                             string unique = Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.ParentId + '' + Payment_Summary_Record.ECM_Budget_types__c + '' + Map_Id_Contract.get(Payment_Summary_Record.ECM_Contract__c).Account.BillingState;
                             //Gets the IO Code from the Map_Unique_Internal_Order if records exsist 
                             if (Map_Unique_Internal_Order.containsKey(unique)) {
                                 Payment_Summary_Record.ECM_Recommended_IO_Code__c = Map_Unique_Internal_Order.get(unique).Name;
                             }
                         }
                    //  }
                }
                
            }
        }
        
    }
    /*
    * @description : This method is written to update the currencycode from associated agreement record
    * @return : void
    * @param : trigger.new,boolean
    */
    public static void updateCurrencyCode(List<ECM_Payment_Summary__c> newPaySum,Boolean isUpdate) { 
        Set<Id> contractIdSet = new Set<Id>();
        Map<Id,String> agreementTypeCurrency = new Map<Id,String>();
        //Boolean isUpdate = false;
        for(ECM_Payment_Summary__c paySumObj: newPaySum){
            contractIdSet.add(paySumObj.ECM_Contract__c);
        }
        if(!contractIdSet.isEmpty()){
            for(Contract conRec :[Select id,ECM_Agreement_Type__c,ECM_Agreement_Type__r.CurrencyIsoCode from Contract where Id in :contractIdSet]){
                agreementTypeCurrency.put(conRec.id,conRec.ECM_Agreement_Type__r.CurrencyIsoCode);
            }
        }
        
        
        if(!agreementTypeCurrency.isEmpty())
            for(ECM_Payment_Summary__c paySumObj: newPaySum){
                if(isUpdate && (paySumObj.CurrencyIsoCode!=agreementTypeCurrency.get(paySumObj.ECM_Contract__c)) && agreementTypeCurrency.containsKey(paySumObj.ECM_Contract__c)){
                    paySumObj.CurrencyIsoCode = agreementTypeCurrency.get(paySumObj.ECM_Contract__c);
                }
                else if(!isUpdate && agreementTypeCurrency.containsKey(paySumObj.ECM_Contract__c)){
                    paySumObj.CurrencyIsoCode = agreementTypeCurrency.get(paySumObj.ECM_Contract__c);
                }
            }    
    }
    
    
    /*
public static void ECM_Update_UpfrontLastPaymentdate(Map < Id, ECM_Payment_Summary__c > newPaySumMap, Map < Id, ECM_Payment_Summary__c > OldPaySumMap) {
Id AandP_RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();

List < ECM_Payment_Summary__c > triggernewrecords = [select id, ECM_Contract__c, ECM_Payment_Summary_Status__c, ECM_SAP_Payment_Date__c from ECM_Payment_Summary__c
where id in: newPaySumMap.keyset()
and ECM_Budget_types__r.Name =: 'Upfront Payment'
and ECM_contract__r.ECM_Agreement_Type__r.Geography__r.Name =: 'Australia'
and ECM_contract__r.status =: 'Active'
and ECM_Payment_Summary_Status__c =: 'Completed'
and ECM_SAP_Payment_Date__c != null and ECM_Contract__c != null and ECM_contract__r.recordtypeid !=: AandP_RecordTypeId
];
Map < id, ECM_Payment_Summary__c > Map_contract_and_contractids = new Map < id, ECM_Payment_Summary__c > ();
system.debug('triggernewrecords' + triggernewrecords);
list < contract > list_to_Update = new list < contract > ();
if (triggernewrecords.size() > 0) {
for (ECM_Payment_Summary__c newpaymentsumarryrecord: triggernewrecords) {
Map_contract_and_contractids.put(newpaymentsumarryrecord.ECM_Contract__c, newpaymentsumarryrecord);

}
}
system.debug('Map_contract_and_contractids' + Map_contract_and_contractids);
if (Map_contract_and_contractids.size() > 0) {
for (contract contra: [select id, ECM_Upfront_Last_Payment_date__c from contract
where id in: Map_contract_and_contractids.keyset()
]) {
system.debug('contra' + contra);
contra.ECM_Upfront_Last_Payment_date__c = Map_contract_and_contractids.get(contra.id).ECM_SAP_Payment_Date__c;
list_to_Update.add(contra);
}
}
system.debug(list_to_Update);
if (list_to_Update.size() > 0) {
update list_to_Update;
}
}
*/
 /*
    * @description : Update confirmed amount on contract
    * @return : void
    * @param : trigger.Newmap,trigger.OldMap
    */
    public static void ECM_Update_Payment_Summary_Conformed_Amount_On_Contracts(Map < Id, ECM_Payment_Summary__c > newPaySumMap, Map < Id, ECM_Payment_Summary__c > OldPaySumMap) {
        Id AandP_RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Id budgetType_RecordId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        list < contract > list_to_Update = new list < contract > ();
        
        Map < String, Pick_Up_Options__c > budgetTypeValues = new Map < String, Pick_Up_Options__c > ();
        List < String > BUDGET_TYPE = new List < String > {
            'SKU Specific Rebates [AU]',
                'Upfront Payment [AU]',
                'Portfolio Rebates [AU]'
                };
                    for (Pick_Up_Options__c pickOptionRecord: [select id, Name, Geography__r.Name, Status__c, RecordTypeId from Pick_Up_Options__c
                                                               Where Geography__r.Name =: 'Australia' AND Name IN: BUDGET_TYPE AND Status__c = 'Active'
                                                               AND RecordTypeId =: budgetType_RecordId
                                                              ]) {
                                                                  budgetTypeValues.put(pickOptionRecord.Name, pickOptionRecord);
                                                              }
        System.debug('newPaySumMap-->'+newPaySumMap.keyset());
        List < ECM_Payment_Summary__c > triggernewrecords = [select id, ECM_Contract__c, ECM_Payment_Summary_Status__c,ECM_Budget_types__c,ECM_Total_Amount_Confirmed__c, ECM_SAP_Payment_Date__c from ECM_Payment_Summary__c
                                                             where id in: newPaySumMap.keyset()
                                                             and ECM_contract__r.ECM_Agreement_Type__r.Geography__r.Name =: 'Australia'
                                                             and ECM_contract__r.status =: 'Active'
                                                             and ECM_Payment_Summary_Status__c =: 'Completed'
                                                             and ECM_SAP_Payment_Date__c != null and ECM_Contract__c != null ];
        //and ECM_Budget_types__r.Name =: 'Upfront Payment'
        
        Map < id, ECM_Payment_Summary__c > Map_contract_and_contractids = new Map < id, ECM_Payment_Summary__c > ();
        system.debug('triggernewrecords' + triggernewrecords);
        if (triggernewrecords.size() > 0) {
            for (ECM_Payment_Summary__c newpaymentsumarryrecord: triggernewrecords) {
                if(OldPaySumMap.get(newpaymentsumarryrecord.id).ECM_Payment_Summary_Status__c != newpaymentsumarryrecord.ECM_Payment_Summary_Status__c
                   && newpaymentsumarryrecord.ECM_Payment_Summary_Status__c== 'Completed') 
                    Map_contract_and_contractids.put(newpaymentsumarryrecord.ECM_Contract__c, newpaymentsumarryrecord);
                
            }
        }
        system.debug('Map_contract_and_contractids' + Map_contract_and_contractids);
        if(Map_contract_and_contractids.size() > 0) {
            for (contract contra: [select id, ECM_Upfront_Payment_Spent__c,ECM_Contract_SKU_Specific_Rebate_Paid__c,Rebate_Paid__c,ECM_Upfront_Last_Payment_date__c from contract
                                   where id in: Map_contract_and_contractids.keyset()
                                  ]) {
                                      if(budgetTypeValues.size() > 0 ){
                                          system.debug(contra);
                                          system.debug('Map_contract_and_contractids=====>'+Map_contract_and_contractids.get(contra.id).id);
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
    }
    /*
    * @description : To update Budget Type 
    * @return : void
    * @param : trigger.new
    */
    public static void ECM_Update_PS_BudgetType(List < ECM_Payment_Summary__c > newPaySum) {
        Set<Id> geoCountry = new Set<Id>();
        List<ECM_Payment_Summary__c> newPSList = new List<ECM_Payment_Summary__c>();
        newPSList = [SELECT id, Name, ECM_Type__c, ECM_Payment_Summary_Status__c, ECM_Email_Sent__c, 
                     ECM_SAP_payment_Reference_Number__c, ECM_Contract__r.Name, ECM_Contract__r.AccountId, 
                     ECM_Contract__r.Account.Country__c,ECM_Contract__r.Account.Country__r.Code__c,ECM_Contract__r.Account.Country__r.Name 
                     FROM ECM_Payment_Summary__c where id IN:newPaySum];
        for(ECM_Payment_Summary__c mailPS : newPSList){
            geoCountry.add(mailPS.ECM_Contract__r.Account.Country__c); //Customer country
            
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
        for(ECM_Payment_Summary__c ps : newPSList){
            if(PaysumVolumeMapmdt.get(ps.ECM_Contract__r.Account.Country__r.Code__c)!=null){
                if( ps.ECM_Type__c == 'Volume-Based' && PaysumVolumeMapmdt.get(ps.ECM_Contract__r.Account.Country__r.Code__c)){
                    if( marketGeoMap.containsKey(ps.ECM_Contract__r.Account.Country__c)){
                        ps.ECM_Budget_types__c=marketGeoMap.get(ps.ECM_Contract__r.Account.Country__c).ECM_Budget_Type_for_Volume_Based_PS__c;        
                        
                    }
                }
                
            }
            
            
        }
        if(newPSList.size()>0){
            update newPSList;
        }
    }
    /*
    * @description : Update email sent on Payment summary as true(ECM-4490)
    * @return : void
    * @param : trigger.new,trigger.OldMap
    */

    @future
    public static void updateEmailSent(set<id> paySumIds){
        List<ECM_Payment_Summary__c> updatePaySum = new List<ECM_Payment_Summary__c>();
        for(ECM_Payment_Summary__c paySum : [SELECT id,ECM_Email_Sent__c
                                             FROM ECM_Payment_Summary__c 
                                             where id IN:paySumIds]){
                                                 paySum.ECM_Email_Sent__c = true;
                                                 updatePaySum.add(paySum);
                                             }
        if(updatePaySum.size()>0){
            Update updatePaySum;
        }
    }
    /*
    * @description : This method fetches a list of Extra approvers who are eligible and then submits an approval request to them.(ECM-4567,ECM-4569)
    * @Author : Manikandan.T
    * @return : void
    * @param : trigger.new
    */
    public static void checkForExtraApproval(List<ECM_Payment_Summary__c> newPaySumList){
        
        Set<Id> agreementTypeList= new Set<Id>(); 
        Set<String> paymentSummaryTypeSet= new Set<String>(); 
        Map<String,List<ECM_Agreement_Approval__c>>approvalMap = new Map<String,List<ECM_Agreement_Approval__c>>();
        Map<Id,List<Id>>paymentSummaryApproval = new Map<Id,List<Id>>();
        Map<Id,String>userRoleMap= new  Map<Id,String>();
        List<ECM_Payment_Summary__c> cioApprovalCheckList= new List<ECM_Payment_Summary__c>();
        List<Id>paymentSummaryList= new List<Id>();
        Map<Id,List<Id>>paymentSummaryMap = new Map<Id,List<Id>>();
        Set<Id> paymentSummaryWithToPaySet = new Set<Id>();
        
        for(ECM_Payment_Summary__c PaymentSummary:newPaySumList){
            if(PaymentSummary.ECM_Contract_Agreement_Type__c!=null){
                agreementTypeList.add(PaymentSummary.ECM_Contract_Agreement_Type__c);
                paymentSummaryTypeSet.add(PaymentSummary.ECM_type__c+' PS');
            }
        }    
        //Added for ECM-4787
        paymentSummaryTypeSet.add('Volume Based PS-Target');
        system.debug('@@paymentSummaryTypeSet' +paymentSummaryTypeSet);
        for(ECM_Payment_Summary_Item__c paySumItem:[select ECM_Payment_Summary__c from ECM_Payment_Summary_Item__c where ECM_Payment_Summary__c IN:newPaysumList and ECM_To_Pay__c=true]){
            paymentSummaryWithToPaySet.add(paySumItem.ECM_Payment_Summary__c);
        }
        system.debug('@@paymentSummaryWithToPaySet' +paymentSummaryWithToPaySet);
        String ecm_type;
        
        for(ECM_Agreement_Approval__c agrementApproval: [select id,ECM_Agreement_Type__c,ECM_Extra_Approval__c,ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c,ECM_Extra_Approval__r.ECM_Type__c,ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c,ECM_Extra_Approval_Role__c from ECM_Agreement_Approval__c where ECM_Agreement_Type__c IN:agreementTypeList and ECM_Extra_Approval__r.ECM_Active__c=true and ECM_Extra_Approval__r.ECM_Extra_Approval_User__c!=null and ECM_Extra_Approval__r.ECM_Extra_Approval_User__r.isActive=true and ECM_Extra_Approval__r.ecm_type__c IN:paymentSummaryTypeSet]){
			 if(agrementApproval.ECM_Extra_Approval__r.ecm_type__c=='Volume Based PS-Target'){
                 ecm_type='Volume-Based PS';
                 system.debug('@@ecm_type1' +ecm_type);
             }else{
                 ecm_type=agrementApproval.ECM_Extra_Approval__r.ecm_type__c;
                 system.debug('@@ecm_type2' +ecm_type);
             }
            system.debug('@@ecm_type3' +ecm_type);
            if(approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type)!=null){ 
                List<ECM_Agreement_Approval__c> eclist=approvalMap.get(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type);
                ecList.add(agrementApproval);
                approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type,ecList);                
                
            }else{
                    approvalMap.put(string.valueOf(agrementApproval.ECM_Agreement_Type__c).substring(0,15)+'_'+ecm_type,new List<ECM_Agreement_Approval__c>{agrementApproval});
                }           
        }
        system.debug('@@approvalMap' +approvalMap); 
        system.debug('agreement type--->'+approvalMap);
        for(ECM_Payment_Summary__c PaymentSummary:newPaySumList ){
            system.debug('agreement type2--->'+string.valueOf(PaymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+PaymentSummary.ECM_type__c+' PS');
            if(PaymentSummary.ECM_Contract_Agreement_Type__c!=null && approvalMap.get(string.valueOf(PaymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+PaymentSummary.ECM_type__c+' PS')!=null){
                for(ECM_Agreement_Approval__c extraApproval:approvalMap.get(string.valueOf(PaymentSummary.ECM_Contract_Agreement_Type__c).substring(0,15)+'_'+PaymentSummary.ECM_type__c+' PS')){
                    if((extraApproval.ECM_Extra_Approval__r.ecm_type__c=='Volume Based PS-Target' && paymentSummaryWithToPaySet.contains(PaymentSummary.Id)) || (PaymentSummary.ECM_Total_Amount_Confirmed__c>=extraApproval.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c && PaymentSummary.ECM_Total_Amount_Confirmed__c<=extraApproval.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c) && extraApproval.ECM_Extra_Approval__r.ecm_type__c!='Volume Based PS-Target'){
                            userRoleMap.put(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c,extraApproval.ECM_Extra_Approval_Role__c);
                            if(paymentSummaryApproval.get(PaymentSummary.id)!=null){ 
                                List<Id> userlist=paymentSummaryApproval.get(PaymentSummary.id);
                                userlist.add(extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c);
                                paymentSummaryApproval.put(PaymentSummary.id,userlist);
                            }else{
                                paymentSummaryApproval.put(PaymentSummary.id,new List<Id>{extraApproval.ECM_Extra_Approval__r.ECM_Extra_Approval_User__c});
                            }
                   }
                }               
                
            }
                       
        }
        system.debug('@@paymentSummaryApproval' +paymentSummaryApproval);
         for(ECM_Payment_Summary__c paymentSummary:newPaySumList ){
             
             if(paymentSummaryApproval.get(paymentSummary.id)!=null){
                // initiateApprovalProcess(paymentSummary.id,paymentSummaryApproval.get(paymentSummary.id),userRoleMap);
                // system.enqueueJob(new ECM_PS_ApprovalProcess_Queueable(paymentSummary.id,paymentSummaryApproval.get(paymentSummary.id),userRoleMap));
                paymentSummaryList.add(paymentSummary.id);
                if(paymentSummaryApproval.get(paymentSummary.id)!=null){
                    paymentSummaryMap.put(paymentSummary.id,paymentSummaryApproval.get(paymentSummary.id));
                }
                
                 checkAndProvideAccountAccess(paymentSummary.ECM_Contract_Account_Id__c,userRoleMap);
             }else{
                 paymentSummary.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
                 paymentSummary.ECM_Payment_Summary_Status__c=Label.ECM_Submitted_Status;
                 cioApprovalCheckList.add(paymentSummary);
             }             
         }
         
         if(!paymentSummaryList.isEmpty()){
              system.enqueueJob(new ECM_PS_ApprovalProcess_Queueable(paymentSummaryList,paymentSummaryMap,userRoleMap));
         }
        
        if(!cioApprovalCheckList.isEmpty()){
            checkForCIOApproval(cioApprovalCheckList);
        }
    }
    /*
    * @description : This method checks if extra approvers have access to the respective account,if not they are provided with the access.(ECM-4567,ECM-4569)
    * @Author : Manikandan.T
    * @return : void
    * @param : accountid,userRoleMap
    */
    @future
    public static void checkAndProvideAccountAccess(Id accountId,Map<Id,String>userRoleMap){
        
        
        Map<Id,AccountShare>accShareMap= new Map<Id,AccountShare>();
        List<AccountShare>accountShareList= new List<AccountShare>();
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
        
    }
    /*
    * @description : This method checks if all extra approvers have approved,if yes then the CIO users are fetched
               from the queue related to the country and approval request are sent to them.(ECM-4567,ECM-4569)
    * @Author : Manikandan.T
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
        
        for(ECM_Payment_Summary__c paymentSummary:newPaySumList ){
                paymentSummaryList.add(paymentSummary.Id); 
                paymentSummaryCountrySet.add(paymentSummary.ECM_Country_Code__c+'_CIO');
        }
         system.debug('paymentSummaryCountrySet-->'+paymentSummaryCountrySet);
        for(ProcessInstanceWorkitem item: [SELECT Id, ProcessInstanceId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN :paymentSummaryList]){
            if(approvalMap.get(item.ProcessInstance.TargetObjectId)!=null){               
                List<ProcessInstanceWorkitem> tempList=approvalMap.get(item.ProcessInstance.TargetObjectId);
                tempList.add(item);
                approvalMap.put(item.ProcessInstance.TargetObjectId,tempList);
             }else{
                 approvalMap.put(item.ProcessInstance.TargetObjectId,new List<ProcessInstanceWorkitem>{item});
            }           
        }
          for(User userDetails:[select id from user where isActive=true]){
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
             
             if(approvalMap.get(paymentSummary.id)!=null && approvalMap.get(paymentSummary.id).size()>1){
                 paymentSummary.ECM_Approval_Sub_Status__c=Label.ECM_In_Extra_Approval;
                 paymentSummary.ECM_Payment_Summary_Status__c=Label.ECM_Payment_Summary_In_Approval;
             }else{
                 paymentSummariesList.add(paymentSummary.id);            
                if(memberIdGroup.get(paymentSummary.ECM_Country_Code__c+'_CIO')!=null){
                    paymentSummaryMap.put(paymentSummary.id,memberIdGroup.get(paymentSummary.ECM_Country_Code__c+'_CIO'));
                }
                
                 //initiateApprovalProcess(paymentSummary.Id,userIdList,null);
                 //system.enqueueJob(new ECM_PS_ApprovalProcess_Queueable(paymentSummary.Id,userIdList,null));
             }             
         }
                 
         if(!paymentSummaryList.isEmpty()){
              system.enqueueJob(new ECM_PS_ApprovalProcess_Queueable(paymentSummariesList,paymentSummaryMap,null));
         }
    }
    /*
    * @description : This method checks if any of the request is rejected , if yes then all approval requests related to
                the payment summary are rejected.(ECM-4567,ECM-4569) 
    * @Author : Manikandan.T
    * @return : void
    * @param : trigger.new
    */
          
      @Future
    public static void updateCIOApprovalRecords(Set<Id> paymentSummaryList){
            
        Map<Id,List<ProcessInstanceWorkitem>>approvalMap = new Map<Id,List<ProcessInstanceWorkitem>>();
        Map<Id,String>paymentSummaryMap= new Map<Id,String>();
        List<Id>userIdList= new List<Id>();
        
        for(ECM_Payment_Summary__c paymentSummary:[select id,ECM_Payment_Summary_Status__c,ECM_Approval_Sub_Status__c from ECM_Payment_Summary__c where id IN:paymentSummaryList ] ){
                
                paymentSummaryMap.put(paymentSummary.Id,paymentSummary.ECM_Payment_Summary_Status__c);
        }
        
                    boolean isRejected;
                    boolean isApproved;
                    String Username;
        List<Approval.ProcessWorkitemRequest> ProcessWorkitemRequestList = new List<Approval.ProcessWorkitemRequest>();
        //for(ProcessInstanceWorkitem item: [SELECT Id, ProcessInstanceId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN :paymentSummaryList]){
            for(ProcessInstance pInstance: [SELECT Id,TargetObjectId, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems),(SELECT Id, ActorId,Actor.Name,StepStatus,OriginalActorId FROM Steps)  FROM ProcessInstance where TargetObjectId IN :paymentSummaryList order by lastmodifieddate desc]){
                
                if(isRejected==null && isApproved==null && String.isBlank(Username)){
                    for(processInstanceStep pInstanceStep:pInstance.Steps){
                            
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
         
    } 
    /*
    * @description : This method calls the future method updateCIOApprovalRecords which updates all the approval request records
                to either rejected or approved based on the input from the user.(ECM-4567,ECM-4569) 
    * @Author : Manikandan.T
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
    * @Author : Sayan Mullick
    * @return : void
    * @param : trigger.new,trigger.OldMap
    */ 
    public static void sendPushNotificationForPF(List<ECM_Payment_Summary__c> newItems, Map<Id, sObject> oldItems){
        Map<Id, ECM_Payment_Summary__c> mapOldItems = new Map <Id, ECM_Payment_Summary__c>();
        Set<Id> psIdSet = new Set<Id>();
        if (oldItems != null) {
            mapOldItems = (Map<Id, ECM_Payment_Summary__c>) oldItems;
        }
        if(newItems!=null){
            for(ECM_Payment_Summary__c psObj : newItems){
                if(psObj.ECM_Payment_Summary_Status__c.equals('Open') && mapOldItems!=null && mapOldItems.containsKey(psObj.Id) 
                   && mapOldItems.get(psObj.Id).ECM_Payment_Summary_Status__c != psObj.ECM_Payment_Summary_Status__c && (psObj.ECM_Type__c == 'Promo-Standard'
                      || psObj.ECM_Type__c == 'Volume-Based')){
                       psIdSet.add(psObj.Id);
                }                   
            } 
            if(!psIdSet.isEmpty()){
                getPIStep(psIdSet);
            }
        }
    }
    /*
    * @description : Contract Approval or rejection notification for Sales rep.(ECM-4764) 
    * @Author : Anuja and Saurav
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
        psList = [SELECT Id,Name,ECM_Contract__c,Owner__c,LastmodifiedDate,ECM_Contract__r.ContractNumber
                  FROM ECM_Payment_Summary__c 
                  WHERE Id IN : psIdSet];
        for(ProcessInstanceStep rejLogObj :  [SELECT Id,Actor.Email,Comments,ProcessInstance.TargetObjectId,StepStatus,CreatedDate
                                              FROM ProcessInstanceStep
                                              WHERE ProcessInstance.TargetObjectId IN: psIdSet 
                                              AND StepStatus= 'Rejected'
                                              AND CreatedDate >:currDtTime
                                              ORDER BY CreatedDate ASC]){
            String cmpKey = String.valueOf(rejLogObj.ProcessInstance.TargetObjectId);
            if(!rejLogObj.Comments.startsWithIgnoreCase(Label.ECM_Payment_Summary_Generic_Approval_Message)){
                psRejLogMap.put(cmpKey, rejLogObj);                                
            }
        }
        for(ECM_Payment_Summary__c psObj : psList){
             String cmpKey = String.valueOf(psObj.Id);
             String notificationTxt ='';
            if(!psRejLogMap.isEmpty() && psRejLogMap.containsKey(cmpKey)){
                String email = psRejLogMap.get(cmpKey).Actor.Email;
                String comments = psRejLogMap.get(cmpKey).Comments;
                notificationTxt = Label.ECM_Payment_Summary_Message.replace('****',psObj.Name)+' '+psObj.ECM_Contract__r.ContractNumber+' '+Label.ECM_Contract_Push_Notification_Rejected_Message.replace('&&&&',email).replace('####',comments);
                custom.put('PaymentSummaryId',psObj.Id);
                custom.put('ContractId',psObj.ECM_Contract__c);
                custom.put('OwnerId',psObj.Owner__c);
                System.debug('@@notificationTxt'+notificationTxt);
                EDGE_PushNotificationHelper.pushNotificationMethod(null, notificationTxt, custom);
            }
        }
        
    }
}