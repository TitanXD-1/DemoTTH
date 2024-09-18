/**********************************************************************
Name: ECM_BatchPromoPrePymntPSfor100PrePymnt
=======================================================================
Purpose: This is Class for Creating Payment Summaries for Promo Prepayment and non Australian Contracts
Test Class: ECM_SchdleBchPrmPrPytPSfor100PrPyt_Test
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Pradeep Kumar Reddy     03/11/2020        ECM-2251: Promo-Prepayment PS auto-generation for PF=100% prepayment
2.0      Joshraj Sen             20/12/2023        146153: Prevent Payment Summary Creation for CRG Contracts
***********************************************************************/ 
global class ECM_BatchPromoPrePymntPSfor100PrePymnt implements Database.Batchable<sObject> {
	global Database.QueryLocator start(Database.BatchableContext bc) {
        String crgRecordTypeId = '';//146153
        crgRecordTypeId=Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();
        String query = 'SELECT Id, Name,startdate,Contract_End_Date__c, AccountID, Account.Country__r.Name FROM contract where Status=\'Active\' AND Account.Country__r.Name != \'Australia\' and RecordTypeID != :crgRecordTypeId';//146153
        system.debug('query'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<contract> conrecords){
        set<Id> succesPSIds=New set<Id>();
        map<string,List<ECM_Sales_Driver_Item_Detail__c>> sdidmap=new  map<string,List<ECM_Sales_Driver_Item_Detail__c>>();
        Map<string,ECM_Payment_Summary__c> paymentSummaryMaptoInsert=New Map<String,ECM_Payment_Summary__c>();

        List<ECM_Sales_Driver_Item_Detail__c> sdidList=[Select id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Sales_Driver_Item__c,ECM_Sales_Driver_Item__r.Contract__c,ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,
                                                         ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Territory_Budget__r.ECM_Budget_Type__c,ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c,
                                                         ECM_Sales_Driver_Item__r.Contract__r.startdate,ECM_Sales_Driver_Item__r.Contract__r.Contract_End_Date__c, ECM_Sales_Driver_Item__r.ECM_Prepayment__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c
                                                           from ECM_Sales_Driver_Item_Detail__c where ECM_Sales_Driver_Item__r.Contract__c In:conrecords AND ECM_Sales_Driver_Item__r.ECM_Payment_Date__c = Today AND
                                                           (ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c='100% Prepayment' OR ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c='100% prepago')];
        
        system.debug('sdidListsize'+sdidList.size());
        if(sdidList.size()>0){
            for(ECM_Sales_Driver_Item_Detail__c sdi: sdidList){
                if(sdi.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c !=null && sdi.ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__c !=null){
                    string keystr=sdi.ECM_Sales_Driver_Item__r.Contract__c+'-'+sdi.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                    if(sdidmap.containsKey(keystr)){
                        sdidmap.get(keystr).add(sdi);
                    }
                    else{ 
                       sdidmap.put(keystr,new List<ECM_Sales_Driver_Item_Detail__c>());
                       sdidmap.get(keystr).add(sdi);
                    }
                }
            }
            if(sdidmap.size()>0){
                for(string str:sdidmap.keyset()){
                    ECM_Payment_Summary__c ps=New ECM_Payment_Summary__c();
                    ps.ECM_Budget_types__c=sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                    ps.ECM_Start_Period__c = sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.ECM_Payment_Date__c;
                    ps.ECM_End_Period__c = sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.ECM_Payment_Date__c;
                    ps.ECM_Contract__c=sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.Contract__c;
                    ps.ECM_Total_Amount_Confirmed__c = null;
                    ps.ECM_Total_Amount_Forecasted__c = null;
                    //ps.ECM_Email_Sent__c=true;
                    paymentSummaryMaptoInsert.put(str,ps);             
                }
                if(paymentSummaryMaptoInsert.size()>0){
                    Database.insert(paymentSummaryMaptoInsert.values(), false);
                    for (string str:sdidmap.keyset()) {
                       if (paymentSummaryMaptoInsert.get(str).Id != null ){
                           system.debug('payment--->'+paymentSummaryMaptoInsert.get(str).ECM_Total_Amount_Confirmed__c+'--->'+paymentSummaryMaptoInsert.get(str).ECM_Total_Amount_Forecasted__c);
                           succesPSIds.add(paymentSummaryMaptoInsert.get(str).Id);
                       }
                    }
                
                }
                
                Map<String,Decimal> investmentMap = new Map<String,Decimal>();
                Map<String,Id> contractItemIdMap = new Map<String,Id>();
                Map<String,ECM_Payment_Summary__c> psMap = new Map<String,ECM_Payment_Summary__c>();
                
                for(string str:sdidmap.keyset()){
                    for(ECM_Sales_Driver_Item_Detail__c sdid : sdidmap.get(str)){
                        String key = sdid.ECM_Sales_Driver_Item__r.Contract__c+'-'+sdid.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c+'-'+sdid.ECM_Product__c;
                        psMap.put(key,paymentSummaryMaptoInsert.get(str));
                        contractItemIdMap.put(key,sdid.ECM_Product__c);
                        decimal cal = sdid.ECM_Investment_Amount__c;
                        if(cal == null){
                            cal = 0;
                        }
                        if(investmentMap.containsKey(key)){
                            decimal sumCal = investmentMap.get(key);
                            sumCal += cal;
                            investmentMap.put(key,sumCal);
                        }
                        else{
                            investmentMap.put(key,cal);
                        }
                    }
                }
                if(contractItemIdMap.size()>0){
                    
                    map<String,ECM_Payment_Summary_Item__c> insertPSIMap = new Map<String,ECM_Payment_Summary_Item__c>();
                    Map<Id,Decimal> totalinvestmentPSMap = new Map<Id,Decimal>();
                    for(string str : contractItemIdMap.KeySet()){
                        ECM_Payment_Summary_Item__c psi = new ECM_Payment_Summary_Item__c();
                        psi.ECM_Contract_Item__c = contractItemIdMap.get(str);
                        psi.ECM_Payment_Summary__c = psMap.get(str).Id;
                        psi.ECM_Planned_Amount_Per_Payment__c = investmentMap.get(str);
                        psi.ECM_Confirmed_Amount_Per_Payment__c = investmentMap.get(str);
                        psi.ECM_Confirm__c = true;
                        insertPSIMap.put(str, psi);
                        
                        if(totalinvestmentPSMap.containsKey(psMap.get(str).Id)){
                            decimal totalInvCal = totalinvestmentPSMap.get(psMap.get(str).Id) + investmentMap.get(str);
                            totalinvestmentPSMap.put(psMap.get(str).Id,totalInvCal);
                        }
                        else{
                            totalinvestmentPSMap.put(psMap.get(str).Id,investmentMap.get(str));
                        }
                    }
                    
                    if(insertPSIMap.size()>0){
                        Database.insert(insertPSIMap.values(), false);
                    }
                    List<ECM_Payment_Summary__c> psListfinal=[Select Id,ECM_Type__c,ECM_Payment_Summary_Status__c,ECM_Total_Amount_Forecasted__c,
                                                  ECM_Total_Amount_Confirmed__c from ECM_Payment_Summary__c where id In:totalinvestmentPSMap.Keyset()];
                    List<ECM_Payment_Summary__c> tobeUpdatedPSList =New List<ECM_Payment_Summary__c>();
                    if(psListfinal.size()>0){
                         for(ECM_Payment_Summary__c ps:psListfinal){
                             ps.ECM_Total_Amount_Forecasted__c=totalinvestmentPSMap.get(ps.Id);
                             ps.ECM_Total_Amount_Confirmed__c=totalinvestmentPSMap.get(ps.Id);
                             ps.ECM_Type__c='Promo-PrePayment';
                             ps.ECM_Payment_Summary_Status__c='Submitted';
                             tobeUpdatedPSList.add(ps);
                         }
                     }
                     if(tobeUpdatedPSList.size()>0){
                         Database.update(tobeUpdatedPSList, false);
                     }
                }
            }
        }
    }
    global void finish(Database.BatchableContext bc){
        
    } 
}