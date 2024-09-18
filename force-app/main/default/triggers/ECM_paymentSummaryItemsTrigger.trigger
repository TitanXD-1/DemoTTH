/*
 * Name: ECM_paymentSummaryItemsTrigger
 * Purpose: This is to handle for Payment summary items Events
 * History                                                            
 * VERSION     	AUTHOR                        DATE              DETAIL
 * 1.0      	CM Developmet Team		      30/07/2020       	Initial Development
 * 1.1      	Anivesh Muppa		          07/04/2021       	Related to ECM-4239
 * 1.2      	Tanishq Banerjee		      15/02/2021       	Related to ECM-5125
*/
trigger ECM_paymentSummaryItemsTrigger on ECM_Payment_Summary_Item__c ( after insert, after update, after undelete, after delete,before insert,before update) {
    if ( Trigger.isAfter ) {
        List<ECM_Payment_Summary__c> paymentSummaryListUpdatelist = new List<ECM_Payment_Summary__c>();
        List<ECM_Payment_Summary_Item__c> paymentSummaryList = new List<ECM_Payment_Summary_Item__c> ();
        Map<Id, ECM_Payment_Summary_Item__c> newMapPSI = Trigger.Newmap;
        Map<Id, ECM_Payment_Summary_Item__c> oldMapPSI = Trigger.oldmap;
        Set<Id> paymentsummaryIds = new Set<Id>();
        Map<Id,String> acctMarketSettMap = new Map<Id,String>();
        
        if ( Trigger.isDelete ) {
            paymentSummaryList = Trigger.Old;   
        } else {
            paymentSummaryList = Trigger.New;            
        }
        
        for ( ECM_Payment_Summary_Item__c PS : paymentSummaryList ) {
            if (PS.ECM_Payment_Summary__c != null ){
                paymentsummaryIds.add(PS.ECM_Payment_Summary__c);
                
                if(oldMapPSI!= NULL && oldMapPSI.size()>0){
                    if(oldMapPSI.containskey(PS.ECM_Payment_Summary__c) && oldMapPSI.get(PS.id).ECM_Payment_Summary__c !=null &&
                       PS.ECM_Payment_Summary__c != oldMapPSI.get(PS.id).ECM_Payment_Summary__c){
                           paymentsummaryIds.add(oldMapPSI.get(PS.id).ECM_Payment_Summary__c);
                           
                       }
                }
            }
        }   
        decimal val;
        Map<String,Boolean> marketSettingMap = new Map<String,Boolean>();
        Map<String,Decimal> marketSettingMap1 = new Map<String,Decimal>();
        
        List<ECM_Payment_Summary__c> paymentSummarys = [Select id, ECM_Type__c,ECM_Total_Amount_Confirmed__c,ECM_Contract__r.AccountId,ECM_Contract__r.Account.Country__c,ECM_Achieved_Non_Leading_Brand__c,
                                                        (select id,ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirm__c,ECM_To_Pay__c,ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Percentage_Target_Achieved__c from Payment_Summary_Item__r) from ECM_Payment_Summary__c
                                                        Where Id IN : paymentsummaryIds];
        if(paymentSummarys!= null && !paymentSummarys.isEmpty()){
            for(ECM_Payment_Summary__c psObj : paymentSummarys){
                acctMarketSettMap.put(psObj.ECM_Contract__r.AccountId,psObj.ECM_Contract__r.Account.Country__c); 
                
            }
            if(!acctMarketSettMap.isEmpty()){
                for(Market_Setting__c ms:[Select Id,Geography__c,ECM_Enable_Target__c,ECM_Target__c,Name                                           
                                          from Market_Setting__c Where Geography__c IN:acctMarketSettMap.Values()]){
                 	marketSettingMap.put(ms.Geography__c,ms.ECM_Enable_Target__c);                                             
                    marketSettingMap1.put(ms.Geography__c,ms.ECM_Target__c);
                }
            }
            for(ECM_Payment_Summary__c paySumObj : paymentSummarys){
                val = 0;
                String countryId;
                Boolean enableTarget =false;
                Decimal forecastVolume =0.0;
                
                if(!acctMarketSettMap.isEmpty()&&acctMarketSettMap.containsKey(paySumObj.ECM_Contract__r.AccountId) && !marketSettingMap.isEmpty() && marketSettingMap.containsKey(paySumObj.ECM_Contract__r.Account.Country__c)){
                    countryId = acctMarketSettMap.get(paySumObj.ECM_Contract__r.AccountId);                     
                    enableTarget =  marketSettingMap.get(countryId);                    
                }
                
                if(!acctMarketSettMap.isEmpty()&&acctMarketSettMap.containsKey(paySumObj.ECM_Contract__r.AccountId) && !marketSettingMap1.isEmpty() && marketSettingMap.containsKey(paySumObj.ECM_Contract__r.Account.Country__c)){
                    countryId = acctMarketSettMap.get(paySumObj.ECM_Contract__r.AccountId); 
                    forecastVolume =  marketSettingMap1.get(countryId)!= null? marketSettingMap1.get(countryId): 0.0;
                }
                
                if((paySumObj.ECM_Type__c=='Volume-Based') ||(System.Label.ECM_Promo_PrePayment.contains(paySumObj.ECM_Type__c))){
                    
                    for(ECM_Payment_Summary_Item__c pas : paySumObj.Payment_Summary_Item__r){
                        
                        if(pas.ECM_Confirmed_Amount_Per_Payment__c !=null &&((pas.ECM_Confirm__c && System.Label.ECM_Promo_PrePayment.contains(paySumObj.ECM_Type__c)) || (paySumObj.ECM_Type__c=='Volume-Based' && !enableTarget))){
                            val += pas.ECM_Confirmed_Amount_Per_Payment__c; 
                        }else if(pas.ECM_Confirmed_Amount_Per_Payment__c !=null && (paySumObj.ECM_Type__c=='Volume-Based'&& enableTarget)){                     
                            if(pas.ECM_Contract_Item__r.ECM_Lead_Brand__c){
                                val += pas.ECM_Confirmed_Amount_Per_Payment__c;  
                            }else{
                                if((forecastVolume <= pas.ECM_Percentage_Target_Achieved__c) && (forecastVolume <= paySumObj.ECM_Achieved_Non_Leading_Brand__c)){
                                    val += pas.ECM_Confirmed_Amount_Per_Payment__c;  
                                }else if(((forecastVolume > pas.ECM_Percentage_Target_Achieved__c) || (forecastVolume > paySumObj.ECM_Achieved_Non_Leading_Brand__c)) && pas.ECM_To_Pay__c){
                                    val += pas.ECM_Confirmed_Amount_Per_Payment__c;  
                                }else if(((forecastVolume > pas.ECM_Percentage_Target_Achieved__c) || (forecastVolume > paySumObj.ECM_Achieved_Non_Leading_Brand__c)) && !(pas.ECM_To_Pay__c)){
                                    pas.ECM_Confirmed_Amount_Per_Payment__c = 0;  
                                    val += pas.ECM_Confirmed_Amount_Per_Payment__c; 
                                }                            
                            }                            
                        }                                                    
                    }
                    
                    //set scale 2 related to ECM-4239
                    paySumObj.ECM_Total_Amount_Confirmed__c = val.setScale(2);
                }  
                
            }            
        }
		update paymentSummarys;
    }
    if ( Trigger.isBefore) {
       
        Map<Id,ECM_Payment_Summary__c> psMap = new Map<Id,ECM_Payment_Summary__c>();
        Set<Id> paymentsummaryIds = new Set<Id>();
        List<ECM_Payment_Summary_Item__c> paySumItemList = new List<ECM_Payment_Summary_Item__c>();
        Set<Id> countrySet = new Set<Id>();
        Map<String,Decimal> msTargetMap = new Map<String,Decimal>();
        Map<String,Boolean> msEnableTargetMap = new Map<String,Boolean>();
        paySumItemList = Trigger.New;
        Set<Id> conItemSet = new Set<Id>();
        Map<Id,ECM_Contract_Item__c> conItemMap ;
        for (ECM_Payment_Summary_Item__c psiObj : paySumItemList) {
            //start changes related to ECM-4239
            psiObj.ECM_Confirmed_Amount_Per_Payment__c = psiObj.ECM_Confirmed_Amount_Per_Payment__c != null?psiObj.ECM_Confirmed_Amount_Per_Payment__c.setscale(2):0;
            //end of ECM-4239
           	if(psiObj.ECM_Payment_Summary__c != null){
                paymentsummaryIds.add(psiObj.ECM_Payment_Summary__c);
                 conItemSet.add(psiObj.ECM_Contract_Item__c);
            }	
        }
        if(!conItemSet.isEmpty()){
            conItemMap = new Map<Id,ECM_Contract_Item__c>([Select Id,ECM_Lead_Brand__c From ECM_Contract_Item__c Where Id in :conItemSet]);
        }
        if(!paymentsummaryIds.isEmpty()){
            for(ECM_Payment_Summary__c psObj : [SELECT Id, ECM_Type__c,ECM_Total_Amount_Confirmed__c,ECM_Achieved_Non_Leading_Brand__c,
                                                ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode,
                                                ECM_Contract__r.Account.Country__c,ECM_Contract__r.AccountId,
                                                (SELECT id,ECM_Confirmed_Amount_Per_Payment__c 
                                                 FROM Payment_Summary_Item__r) 
                                                FROM ECM_Payment_Summary__c
                                                WHERE Id IN : paymentsummaryIds]){
                countrySet.add(psObj.ECM_Contract__r.Account.Country__c);                                    
        		//psCurMap.put(psObj.id,psObj.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode); 
                psMap.put(psObj.Id,psObj);
        	}
            if(!countrySet.isEmpty()){
                for(Market_Setting__c msObj :[SELECT Id,Geography__c,ECM_Enable_Target__c,ECM_Target__c,Name                                           
                                              FROM Market_Setting__c WHERE Geography__c IN : countrySet]){
                	msTargetMap.put(msObj.Geography__c,msObj.ECM_Target__c); 
                    msEnableTargetMap.put(msObj.Geography__c,msObj.ECM_Enable_Target__c);
            	}
            }
        }
        
        for(ECM_Payment_Summary_Item__c psItemObj:Trigger.new){
            if(psMap.containsKey(psItemObj.ECM_Payment_Summary__c)){
                ECM_Payment_Summary__c currPSObj = psMap.get(psItemObj.ECM_Payment_Summary__c);
                if(currPSObj!= null && Trigger.isInsert){
                    psItemObj.CurrencyIsoCode = currPSObj.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode;
                    String countryId = currPSObj.ECM_Contract__r.Account.Country__c;
                    if(String.isNotBlank(countryId) && msTargetMap.containsKey(countryId)){
                        Decimal forecastVolume = msTargetMap.get(countryId);
                        Boolean enableTarget =  msEnableTargetMap.get(countryId);
                        if(conItemMap!=null && conItemMap.containsKey(psItemObj.ECM_Contract_Item__c) && !(conItemMap.get(psItemObj.ECM_Contract_Item__c)).ECM_Lead_Brand__c){
                            if((currPSObj.ECM_Type__c=='Volume-Based'&& enableTarget)
                               &&((forecastVolume > psItemObj.ECM_Percentage_Target_Achieved__c) 
                                  || (forecastVolume > currPSObj.ECM_Achieved_Non_Leading_Brand__c)) 
                               && !(psItemObj.ECM_To_Pay__c)){
                                   psItemObj.ECM_Confirmed_Amount_Per_Payment__c = 0;
                               }
                        }
                        
                    }
                }
                
                //String countryId = 
            }
        }  
    }
    if ( Trigger.isBefore && Trigger.isUpdate) {
        Profile p = [SELECT Id,Name FROM Profile WHERE Name='Sales Representative'];
        List<ECM_Payment_Summary_Item__c> newPaySumItem = new List<ECM_Payment_Summary_Item__c>();
        newPaySumItem = Trigger.New;
        List<ECM_Payment_Summary_Item__c> oldPaySumItem = new List<ECM_Payment_Summary_Item__c>();
        oldPaySumItem = Trigger.old;
        Map<Id,String> psitemMap = new Map<Id,String>();
        Set<Id> PsItemSet = new Set<Id>();
        for(ECM_Payment_Summary_Item__c psItmObj : oldPaySumItem)
        {
            PsItemSet.add(psItmObj.Id);
        }
        List<ECM_Payment_Summary_Item__c> psItemLst = new List<ECM_Payment_Summary_Item__c>();
        psItemLst=[SELECT id,Name,ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c FROM ECM_Payment_Summary_Item__c where id IN:PsItemSet AND ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c='Approved'];
        if(psItemLst.size()>0){
            for(ECM_Payment_Summary_Item__c psitm : psItemLst)
            {
                psitemMap.put(psitm.Id,psitm.ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c);
            }	
            if(!oldPaySumItem.isEmpty()){
                for(Integer i=0; i<oldPaySumItem.size(); i++)
                { 
                    if( psitemMap.get(oldPaySumItem[i].Id) =='Approved' && p.Id == UserInfo.getProfileId())
                    {	
                        if(oldPaySumItem[i].ECM_Contract_Item__c != newPaySumItem[i].ECM_Contract_Item__c
                           ||oldPaySumItem[i].ECM_Planned_Amount_Per_Payment__c != newPaySumItem[i].ECM_Planned_Amount_Per_Payment__c
                           ||oldPaySumItem[i].ECM_Confirmed_Amount_Per_Payment__c != newPaySumItem[i].ECM_Confirmed_Amount_Per_Payment__c
                           ||oldPaySumItem[i].ECM_Confirm__c != newPaySumItem[i].ECM_Confirm__c
                           ||oldPaySumItem[i].ECM_Reject__c != newPaySumItem[i].ECM_Reject__c
                           ||oldPaySumItem[i].ECM_Roll_Over__c != newPaySumItem[i].ECM_Roll_Over__c
                           ||oldPaySumItem[i].ECM_Confirmed_Volume__c != newPaySumItem[i].ECM_Confirmed_Volume__c
                           ||oldPaySumItem[i].ECM_Total_Rebate__c != newPaySumItem[i].ECM_Total_Rebate__c
                           ||oldPaySumItem[i].CurrencyIsoCode != newPaySumItem[i].CurrencyIsoCode){
                               newPaySumItem[i].addError('Payment Summary Item values cannot be changed if Payment Summary Status is Approved');
                           } 
                    }
                }
            }
        }
    }
    
}