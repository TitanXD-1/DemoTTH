/**********************************************************************
Name: EDGE_OperatorCycleBriefOppDetailsHelper

=======================================================================
Req: 
ES20-8602 : To store the information -Total Open opportunity,Total Closed opportunity,Details of Open and Closed at operator level in KPI Information Section
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Monalisa Halder     15/09/2020       ES20-8602- method ->
***********************************************************************/

public class EDGE_OperatorCycleBriefOppDetailsHelper {
    public static List<Account> operatorOppDetails(Map<Id,Integer> operatorWithOpenOpp,Map<Id,Integer> operatorWithClosedOpp, Map<Id,list<Opportunity>> operatorOpportunityMap,Map<Id,Integer> operatorIdOpportunityCountMap){
        Map<Id,Account> operatorIdMap = new Map<Id,Account>();
        List<Account> operatorListToUpdate = new List<Account>();
        Set<Id> oppWrapIdSet = new Set<Id>();
        Set <Id> operatorIdSet =  new Set<Id>();
        
       
       try{
            for(Account operator :[Select Id, Cycle_Brief_Opportunities__c,Open_Cycle_Brief_Opp__c,Closed_Cycle_Brief_Opp__c from Account where Id IN :operatorOpportunityMap.keySet()]){
                operatorIdMap.put(operator.Id,operator);
            }
            
            for(Id operatorId :operatorWithOpenOpp.keySet()){
            	operatorIdSet.add(operatorId);    
            }
            
            for(Id operatorId :operatorWithClosedOpp.keySet()){
            	operatorIdSet.add(operatorId);    
            }
            for(Id operatorId :operatorOpportunityMap.keySet()){
            	operatorIdSet.add(operatorId);    
            }
            
            for(Id operatorId :operatorIdSet){
                EDGE_OperatorCycleBriefOppWrapper operatorCycleBriefOppWrapper = new EDGE_OperatorCycleBriefOppWrapper();
                if(operatorWithOpenOpp.containsKey(operatorId) && operatorWithOpenOpp.get(operatorId) != null){
                	operatorCycleBriefOppWrapper.CycleBriefOpenOpp = operatorWithOpenOpp.get(operatorId);    
                }
                if(operatorWithClosedOpp.containsKey(operatorId) && operatorWithClosedOpp.get(operatorId) != null){
                    operatorCycleBriefOppWrapper.CycleBriefCloseOpp = operatorWithClosedOpp.get(operatorId);
                }
                List<EDGE_OperatorCycleBriefOppWrapper.EDGE_CycleBriefOppWrapper> opportunityList = new List<EDGE_OperatorCycleBriefOppWrapper.EDGE_CycleBriefOppWrapper>();
                
                EDGE_OperatorCycleBriefOppWrapper.EDGE_CycleBriefOppWrapper opportunityWrapper = null;
                String existingString;
                if(operatorIdMap.get(operatorId) != null){
                    existingString = operatorIdMap.get(operatorId).Cycle_Brief_Opportunities__c;
                }
               
                Boolean isListEmpty = true;
                if(existingString != null){
                    EDGE_OperatorCycleBriefOppWrapper wrap  = (EDGE_OperatorCycleBriefOppWrapper )JSON.deserialize(existingString, EDGE_OperatorCycleBriefOppWrapper.class);
                    if(wrap.ListOpp != null){
                        operatorCycleBriefOppWrapper.ListOpp = new List<EDGE_OperatorCycleBriefOppWrapper.EDGE_CycleBriefOppWrapper>(); 
                    	operatorCycleBriefOppWrapper.ListOpp.addAll(wrap.ListOpp);
                        opportunityList = wrap.ListOpp;
                    	isListEmpty = false;
                    }
                }
                if(opportunityList != null && !opportunityList.isEmpty()){
                    for(EDGE_OperatorCycleBriefOppWrapper.EDGE_CycleBriefOppWrapper oppWrap :opportunityList){
                        oppWrapIdSet.add(oppWrap.OpportunityID); 
                    }    
                }
                
                List<Opportunity> operatorOppList = new List<Opportunity>();
                if(operatorOpportunityMap.containsKey(operatorId) && operatorOpportunityMap.get(operatorId) != null){
                    operatorOppList =  operatorOpportunityMap.get(operatorId); 
                }
                for(Opportunity opp :operatorOppList){
                    if(!oppWrapIdSet.contains(opp.Id)){
                        opportunityWrapper = new EDGE_OperatorCycleBriefOppWrapper.EDGE_CycleBriefOppWrapper();
                        opportunityWrapper.OutletID = opp.AccountId ;
                        opportunityWrapper.OutletName = opp.Account.Name;
                        opportunityWrapper.OpportunityID = opp.Id;
                        opportunityWrapper.OppName = opp.Name;
                        opportunityWrapper.Status = opp.StageName;
                        opportunityWrapper.PendingDate = opp.Pending_Date__c;
                        opportunityWrapper.CloseDate = opp.CloseDate;
                        opportunityList.add(opportunityWrapper);
                    }
                }
                
                if(operatorOpportunityMap.get(operatorId) != null && operatorOpportunityMap != null ){
                	 if( (isListEmpty && operatorOpportunityMap.get(operatorId).size() == 500) 
                        || (operatorOpportunityMap.get(operatorId).size() < 500  && operatorIdOpportunityCountMap.get(operatorId) != null && operatorIdOpportunityCountMap != null 
                        && (operatorOpportunityMap.get(operatorId).size() == operatorIdOpportunityCountMap.get(operatorId)))){
                            operatorCycleBriefOppWrapper.ListOpp = opportunityList;
                           
                        }    
                }
                String finalJSON =JSON.serialize(operatorCycleBriefOppWrapper);
                if(operatorIdMap.containsKey(operatorId)){
                    operatorIdMap.get(operatorId).Open_Cycle_Brief_Opp__c = operatorWithOpenOpp.get(operatorId);    
                    operatorIdMap.get(operatorId).Closed_Cycle_Brief_Opp__c = operatorWithClosedOpp.get(operatorId);
                    operatorIdMap.get(operatorId).Cycle_Brief_Opportunities__c = finalJSON;
                    operatorListToUpdate.add(operatorIdMap.get(operatorId));
                }
            }
        }catch(Exception excption){
            System.debug('With Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            System.debug(excption.getStackTraceString());
        }
        
        return operatorListToUpdate;
       
    }
}