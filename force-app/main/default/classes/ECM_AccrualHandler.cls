/**********************************************************************
  Name: ECM_AccrualHandler
=======================================================================
  Purpose: Trigger Handler Class for ECM_AccrualTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Manikandan.T    15/02/2021      Initial Development
***********************************************************************/
public class ECM_AccrualHandler {
    //Before Insert Trigger Handler
      public void OnBeforeInsert( List<ECM_Accrual__C> newAccruals) {  
          Set<Id>contractList= new Set<Id>();
          Map<Id,Id>contractRegionMap= new Map<Id,Id>();
          Map<Id,String>contractCurrencycodeMap= new Map<Id,String>();
           Map<Id,Id>hierarchymemberMap= new Map<Id,Id>(); 
          for(ECM_Accrual__C accrual:newAccruals){  
              if(accrual.ECM_Contract__c!=null){
              	contractList.add(accrual.ECM_Contract__c); 
              }
          }
          for(contract c: [select id,ECM_Territory__c,ECM_Territory__r.Region__c,ECM_Agreement_Type__c,ECM_Agreement_Type__r.CurrencyIsoCode from contract where id IN:contractList ]){
              
              if(c.ECM_Territory__c!=null && c.ECM_Territory__r.region__c!=null){
                 contractRegionMap.put(c.id,c.ECM_Territory__r.Region__c);
              }
              if(c.ECM_Agreement_Type__c!=null && c.ECM_Agreement_Type__r.CurrencyIsoCode!=null){
              	 contractCurrencycodeMap.put(c.id,c.ECM_Agreement_Type__r.CurrencyIsoCode);
              }
          }
          
          for(Territory_Hierarchy_Member__c thmember: [select id,User__c,Status__c,Territory_Hierarchy__c from Territory_Hierarchy_Member__c where Territory_Hierarchy__c IN: contractRegionMap.values() and Status__c='Active' and user__r.profile.Name='Sales Manager' ]){
              hierarchymemberMap.put(thmember.Territory_Hierarchy__c,thmember.User__c);
          	}
      
    
          for(ECM_Accrual__C accrual:newAccruals){  
              if(contractRegionMap.get(accrual.ECM_Contract__c)!=null){
              	String region=contractRegionMap.get(accrual.ECM_Contract__c); 
                  if(hierarchymemberMap.get(region)!=null){
                      accrual.ECM_Sales_Manager__c=hierarchymemberMap.get(region);
                  }
              }
              if(contractCurrencycodeMap.get(accrual.ECM_Contract__c)!=null){
                  accrual.CurrencyIsoCode=contractCurrencycodeMap.get(accrual.ECM_Contract__c);
              }
          }
      }
}