/**********************************************************************
Name: ECM_AccrualsAndItemsInsertForPort_Batch
=======================================================================
Purpose: This Class is used to insert records to Accruals and AccrualItem objects through batch.
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0       Pravalika Golamari    14/01/2021        Initial Development


***********************************************************************/ 


global class ECM_AccrualsAndItemsInsertForPort_Batch implements Database.Batchable<sObject>, Database.Stateful {
    
    global ECM_AccrualsAndItemsInsertForPort_Batch(){
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([
            select Id,UOS_Rebate_Rate__c,Status,accountid,account.recordtypeid,(select id,ECM_Product_Name__c,ECM_Total_SKU_Specific_Rebate__c,ECM_TotalSKU_SpecificRebate__c,ECM_Product__c,ECM_Product__r.Product__c from Contract_Items__r) from Contract where Status ='Active' and 
            Account.country__r.Name='Australia' and UOS_Rebate_Rate__c>0 
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Contract>scope){
        system.debug('scopeeinsert'+scope);
        String periodval;
        List<Date>startDateList= new List<Date>();
        List<Date>endDateList= new List<Date>();
        Map<String,String>contractItemMap= new  Map<String,String>();
        Map<String,ECM_Accrual__c>AccuralMap= new  Map<String,ECM_Accrual__c>();
        Map<String,ECM_Accrual__c>AccuralForecastMap= new  Map<String,ECM_Accrual__c>();
        List<ECM_Accrual_Item__c> AccuralItemList= new List<ECM_Accrual_Item__c>();
        List<ECM_Accrual_Item__c> AccuralItemForeCastList= new List<ECM_Accrual_Item__c>();
        Map<String,List<Depletions__c>> depletionsMap= new Map<String,List<Depletions__c>>();
        Date foreastStartDate,foreastEndDate,StartDate,EndDate;
        String forecastperiod,period;
        List<String>outletList= new List<String>();
        set<id> depset= new set<id>();
        Map<Id,Decimal> PlMap= new Map<Id,Decimal>();
        Id outletRecordtypeId=account.sobjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        List<ECM_Accrual_Period__c> AlPeriod=[select id,Period__c,ECM_Start_Date__c,ECM_End_Date__c,ECM_Is_Forecast__c from ECM_Accrual_Period__c where ECM_Payment_Calculation_Date__c=:System.today() order by ECM_Start_Date__c desc];
        for(ECM_Accrual_Period__c ec:AlPeriod ){
            
            if(ec.ECM_Is_Forecast__c){
                foreastStartDate=ec.ECM_Start_Date__c;
                foreastEndDate=ec.ECM_End_Date__c;
                forecastperiod=ec.period__c;
            }else{
                StartDate=ec.ECM_Start_Date__c;
                EndDate=ec.ECM_End_Date__c;
                period=ec.period__c;
            }
            
        }
       if(foreastStartDate==null && foreastEndDate==null){
            
            foreastStartDate=StartDate;
            foreastEndDate=EndDate;
        }

        List<String>contractIdList= new List<String>();	
        Map<String,Set<String>> contractMap = new 	Map<String,Set<String>>();	
        for(Contract c : scope){
            
            contractIdList.add(c.Id);
            
            if(c.accountid!=null && c.account.recordtypeid==outletRecordtypeId){
                contractMap.put(c.id,new Set<String>{c.accountid});
                outletList.add(c.AccountId);
            }
        }

        for(Outlet_Contract__c o: [select id,Outlet__c,Contract__c from Outlet_Contract__c where Contract__c in:contractIdList]){
            
            if(o.Outlet__c!=null){
                outletList.add(o.Outlet__c);
            }            
            
            if(contractMap.get(o.Contract__c)!=null){
                
                contractMap.get(o.Contract__c).add(o.Outlet__c);
                
            }else{
                contractMap.put(o.Contract__c,new Set<String>{o.Outlet__c});
            }
        }

        for(Depletions__c d: [select id,Name,ECM_Outlet__c,ECM_Start_Period__c,ECM_End_Period__c,ECM_Product__c,ECM_Product__r.Name,ECM_Volume__c from Depletions__c where 
                              ((ECM_Start_Period__c >=:startDate and ECM_End_Period__c <=:EndDate) OR (ECM_Start_Period__c >=:foreastStartDate and ECM_End_Period__c <=:foreastEndDate)) and ECM_Outlet__c IN:outletList and ECM_Volume__c>0 ]){

                                  If(depletionsMap.get(d.ECM_Outlet__c)==Null){
                                      depletionsMap.put(d.ECM_Outlet__c,new list<Depletions__c>{d});
                                      depset.add(d.ECM_Product__c);
                                  }else{
                                      depletionsMap.get(d.ECM_Outlet__c).add(d);
                                      depset.add(d.ECM_Product__c);
                                  }
                              }
        if(foreastStartDate==StartDate && foreastEndDate==EndDate){
				
				foreastStartDate=null;
				foreastEndDate=null;
			}

        for(ECM_Price_List_Item__c PLI:[select id,ECM_UOS__c,ECM_Product__c,ECM_Price_List__c,ECM_Price_List__r.ECM_Active__c,ECM_Price_List__r.ECM_Geography__c from ECM_Price_List_Item__c where 
                                        ECM_Product__c IN:depset and ECM_Price_List__r.ECM_Active__c=true and ECM_Price_List__r.ECM_Geography__r.Name='Australia' ] ){
            if(PLI.ECM_UOS__c!=null)
                PlMap.put(PLI.ECM_Product__c,PLI.ECM_UOS__c);
        }
        
        for(Contract c : scope){ 
            if(contractMap.get(c.id)!=null){
            for(String outlet: contractMap.get(c.id) ){
  
                        if(depletionsMap.get(outlet)!=null){
                        for(Depletions__c di: depletionsMap.get(outlet)){
                            
                            ECM_Accrual_Item__c AI= new ECM_Accrual_Item__c();
                            AI.ECM_Rebate_Rate__c=c.UOS_Rebate_Rate__c;
                            if(di.ECM_Product__c!=null)
                            AI.ECM_Product__c=di.ECM_Product__c;
                            AI.ECM_Actual_Cases__c=di.ECM_Volume__c;
                            AI.ECM_Outlet__c=outlet;
                            if(PlMap.get(di.ECM_Product__c)!=null)
                            AI.ECM_UOS_Rate__c=AI.ECM_Actual_Cases__c*PlMap.get(di.ECM_Product__c);
                            if(AI.ECM_UOS_Rate__c!=null && AI.ECM_Rebate_Rate__c!=null)
                            AI.ECM_Actual_Rebate__c=AI.ECM_Rebate_Rate__c*AI.ECM_UOS_Rate__c;
                            if(di.ECM_Start_Period__c==foreastStartDate && di.ECM_End_Period__c==foreastEndDate){
                                AI.ECM_Is_forecast__c=true;
                                AccuralItemForeCastList.add(AI);
                            }else{
                                AccuralItemList.add(AI);
                            }						
                            
                        }	
                        
                    }			

                if(!AccuralItemList.isEmpty()){				
                    ECM_Accrual__c Accural= new ECM_Accrual__c();
                    Accural.ECM_Period__c=period;
                   Accural.ECM_Fiscal_Year__c=String.ValueOf(System.today().year());
                    Accural.ECM_Contract__c=c.Id;	
                    Accural.ECM_Outlet__c=outlet;
                    AccuralMap.put(Accural.ECM_Outlet__c,Accural);			
                }
                if(!AccuralItemForeCastList.isEmpty()){
                    ECM_Accrual__c Accural= new ECM_Accrual__c();
                    Accural.ECM_Period__c=forecastperiod;
                   Accural.ECM_Fiscal_Year__c=String.ValueOf(System.today().year());
                    Accural.ECM_Contract__c=c.Id;	
                    Accural.ECM_Is_forecast__c=true;
                    Accural.ECM_Outlet__c=outlet;
                    AccuralForeCastMap.put(Accural.ECM_Outlet__c,Accural);
                }
                
            }
        }
        }
        if(!(AccuralMap.values().isEmpty())){
            
            Database.insert(AccuralMap.Values());
        }	
        if(!(AccuralForeCastMap.values().isEmpty())){
            
            Database.insert(AccuralForeCastMap.Values());
        }	
        
        for(ECM_Accrual_Item__c Ax:AccuralItemList){
            if(AccuralMap.get(Ax.ECM_Outlet__c)!=null){
                Ax.ECM_Accrual__c=AccuralMap.get(Ax.ECM_Outlet__c).Id;
            }
        }
        
        for(ECM_Accrual_Item__c Ai:AccuralItemForeCastList){
            if(AccuralForeCastMap.get(Ai.ECM_Outlet__c)!=null){
                Ai.ECM_Accrual__c=AccuralForeCastMap.get(Ai.ECM_Outlet__c).Id;
            }
        }
        
        if(!(AccuralItemList.isEmpty())){
            
            Database.insert(AccuralItemList);
        }	
        if(!(AccuralItemForeCastList.isEmpty())){
            
            Database.insert(AccuralItemForeCastList);
        }	
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}