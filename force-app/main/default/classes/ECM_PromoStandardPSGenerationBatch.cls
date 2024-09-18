/**********************************************************************
Name: ECM_PromoStandardPSGenerationBatch
=======================================================================
Purpose:This class is used to generate promostandard payment summaries and its items
ECM_PromoStandardPSGenerationBatch.
=======================================================================
History                                                            
-------                                                            
AUTHOR            DATE              DETAIL
veerendra         08/02/2021      ECM-3803 : Missing table in the Evidence request email
veerendra      05/03/2021      ECM-4070 : CM Spain - INC19720170 Promotional Payment Summary creation  - from CI to SDI items 
Joshraj        20/12/2023      146153: Prevent the creation of Payment Summaries for CRG Contracts
***********************************************************************/
global class ECM_PromoStandardPSGenerationBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
       string days= System.label.ECM_PromoStandardBatchRunDays;
        String crgRecordTypeId = '';
        crgRecordTypeId=Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();//146153
        String query = 'SELECT Id, Name,startdate,Contract_End_Date__c FROM contract where Status=\'Active\' and Account.Country__r.Name != \'Australia\' and Contract_End_Date__c = LAST_N_DAYS:'+days+' and RecordTypeId != :crgRecordTypeId';//146153
        system.debug('queryss'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<contract> conrecords){
        set<Id> succesPSIds=New set<Id>();
        map<string,List<ECM_Sales_Driver_Item_Detail__c>> sdidmap=new  map<string,List<ECM_Sales_Driver_Item_Detail__c>>();
        Map<string,ECM_Payment_Summary__c> paymentSummaryMaptoInsert=New Map<String,ECM_Payment_Summary__c>();

      List<ECM_Sales_Driver_Item_Detail__c> sdidList=[Select id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Sales_Driver_Item__c,ECM_Sales_Driver_Item__r.Contract__c,
                                                         ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Territory_Budget__r.ECM_Budget_Type__c,ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__c,
                                                         ECM_Sales_Driver_Item__r.Contract__r.startdate,ECM_Sales_Driver_Item__r.Contract__r.Contract_End_Date__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c
                                                   		from ECM_Sales_Driver_Item_Detail__c where ECM_Sales_Driver_Item__r.Contract__c In:conrecords AND (ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c='At the End of the Contract' OR
                                                                                                                                                      ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c='Al finalizar el contrato')];
         system.debug('sdidList'+sdidList);
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
                // ps.ECM_Type__c='Promo-Standard';
                 ps.ECM_Payment_Summary_Status__c='Open';
                 ps.ECM_Budget_types__c=sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                 ps.ECM_Start_Period__c =sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.Contract__r.startdate;
                 ps.ECM_End_Period__c =sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.Contract__r.Contract_End_Date__c;
                 ps.ECM_Contract__c=sdidmap.get(str)[0].ECM_Sales_Driver_Item__r.Contract__c;
            paymentSummaryMaptoInsert.put(str,ps);             
                }
                if(paymentSummaryMaptoInsert.size()>0){
                    Database.insert(paymentSummaryMaptoInsert.values(), false);
                    for (string str:sdidmap.keyset()) {
                       if (paymentSummaryMaptoInsert.get(str).Id != null ){
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
                              ps.ECM_Type__c='Promo-Standard';
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