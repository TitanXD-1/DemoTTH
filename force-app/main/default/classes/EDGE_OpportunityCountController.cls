/**********************************************************************
Name: EDGE_OpportunityCountController
=======================================================================
Req: 
ES20-9158
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR              DATE            DETAIL
1.0       Amar Deep          18/12/2020      Initial Development
2.0       Dinesh Sharma      08/01/2021      ES20-9284
3.0       Prasanth T         04/05/2021      ES20-10256
4.0		  Aparajita   		 01/07/2021		 ES20-10583
5.0       Sagnik Sanyal      03/08/2024      156103 - GB Opportunity Scoring: Opportunity count custom service_Update to include Not Achieved Opportunity count
***********************************************************************/
public inherited sharing class EDGE_OpportunityCountController {
    
    /*******************************************************************
Purpose: To count all opportunities for the user passed from mobile                                                       
********************************************************************/    
    public static List<EDGE_OpportunityCountWrapper> getOpportunityCount(Id userId){
        List<EDGE_OpportunityCountWrapper> OpportunityCountWrapperList = new List<EDGE_OpportunityCountWrapper>();
        Map<Id,Opportunity> accountIdOppMap = new Map<Id,Opportunity>();
        Map<Id,Integer> accountWithOpenOpp = new Map<Id,Integer>();
        Map<Id,Integer> accountWithClosedOpp = new Map<Id,Integer>();
        List<String> countryCodeList = new List<String>();
        Set<Id> userBusinessRoleIds = new Set<Id>();
        Set<String> userGlobalEquivalent = new Set<String>();
        set<String> oppGlobalEquivalent = new set<String>();
        Date actvMarketCycleStartDate;
        Date actvMarketCycleEndtDate;
        
        if(Schema.sObjectType.User.isAccessible()){
            List<User> userRecord=[Select id,Available_Countries__c,Default_Country__c,Business_Role_ID__c from User where id=: userId];
            //Added for ES20-9284
            userBusinessRoleIds.add(userRecord[0].Business_Role_ID__c);
            string[] countryset;
            if(userRecord[0].Available_Countries__c != null)
            	countryset=userRecord[0].Available_Countries__c.split(';');
            if(countryset != null && countryset.size()>1 && userRecord[0].Default_Country__c != null){
                countryCodeList.add(userRecord[0].Default_Country__c); 
            }else{
                countryCodeList.add(userRecord[0].Available_Countries__c);
            }
        }
        //Added for ES20-9284 , ES20-10256
        if(userBusinessRoleIds != null && Schema.sObjectType.Business_Role__c.isAccessible()){
            List<Business_Role__c> bRoleList = [SELECT Id,Name,Global_Equivalent__c FROM Business_Role__c WHERE Id = :userBusinessRoleIds];
            if(bRoleList != null && bRoleList.size()> 0 && String.isNotBlank(bRoleList[0].Global_Equivalent__c)){
                userGlobalEquivalent.add(bRoleList[0].Global_Equivalent__c);
            }
        }
        system.debug('userGlobalEquivalent::'+userGlobalEquivalent);
        
        if(Schema.sObjectType.Market_Cycle__c.isAccessible()){
            List<Market_Cycle__c> marketCyclelst=[select id ,End_Date__c, Start_Date__c,Geography__r.code__c from 
                                                  Market_Cycle__c where Geography__r.code__c=: countryCodeList and active__c=true LIMIT 1];
            
            if(marketCyclelst!=null && marketCyclelst.size()>0){
                actvMarketCycleStartDate = marketCyclelst[0].Start_Date__c;
                actvMarketCycleEndtDate = marketCyclelst[0].End_Date__c; 
            }
        }
        //Added for ES20-10256 -- Changed the LIMIT to 49997 since service error was Too many query rows: 50001 error
        
        if(Schema.sObjectType.Opportunity.isAccessible() && Schema.sObjectType.Outlet_Member__c.isAccessible()){
            for(Opportunity oppRecd :[SELECT AccountId,Account.Name,StageName,CloseDate,Opportunity_Template__c,Opportunity_Template__r.BR_Global_equivalent__c,Opportunity_Template__r.Start_Date__c FROM Opportunity WHERE StageName in ('Open','Pending','Closed','Not Achieved') 
                                      AND AccountId in (SELECT Outlet__c FROM Outlet_Member__c WHERE User__c =: userId) order by Account.Name LIMIT 49997])
            {
                //Added for ES20-9284
                if(oppRecd.Opportunity_Template__c != null && oppRecd.Opportunity_Template__r.BR_Global_equivalent__c != null){
                    oppGlobalEquivalent = new set<String>(oppRecd.Opportunity_Template__r.BR_Global_equivalent__c.split(';'));
                }
                system.debug('oppGlobalEquivalent::'+oppGlobalEquivalent);
                if(oppRecd.Opportunity_Template__c == null || (oppRecd.Opportunity_Template__c != null && (oppRecd.Opportunity_Template__r.BR_Global_equivalent__c == null)) || (oppGlobalEquivalent != null && oppGlobalEquivalent.ContainsAll(userGlobalEquivalent))){
                       accountIdOppMap.put(oppRecd.AccountId,oppRecd);
                       if((oppRecd.Opportunity_Template__r.Start_Date__c!=null && oppRecd.Opportunity_Template__r.Start_Date__c<=Date.today()) && (oppRecd.StageName =='Open' || oppRecd.StageName =='Pending')) //ES20-10583
                       {
                           if(!accountWithOpenOpp.containsKey(oppRecd.AccountId)){
                               accountWithOpenOpp.put(oppRecd.AccountId,1);
                           }
                           else{
                               Integer openOpp = accountWithOpenOpp.get(oppRecd.AccountId);
                               accountWithOpenOpp.put(oppRecd.AccountId,openOpp+1);
                           }
                       } // 156103 - Added count for Not Achieved opportunites
                    else if((oppRecd.StageName =='Closed' || oppRecd.StageName == 'Not Achieved') && (oppRecd.CloseDate >= actvMarketCycleStartDate && oppRecd.CloseDate <= actvMarketCycleEndtDate)){
                           if(!accountWithClosedOpp.containsKey(oppRecd.AccountId)){
                               accountWithClosedOpp.put(oppRecd.AccountId,1);
                           }
                           else{
                               Integer closedOpp = accountWithClosedOpp.get(oppRecd.AccountId);
                               accountWithClosedOpp.put(oppRecd.AccountId, closedOpp+1);
                           }
                       }
                   } 
            }
        }
        system.debug('accountWithOpenOpp:::'+accountWithOpenOpp);
        system.debug('accountWithClosedOpp:::'+accountWithClosedOpp);
        
        for(Id accountId :accountIdOppMap.keyset()){
            Integer openOpportunities = accountWithOpenOpp.containsKey(accountId) ? accountWithOpenOpp.get(accountId) : 0;
            Integer closeOpportunities = accountWithClosedOpp.containsKey(accountId) ? accountWithClosedOpp.get(accountId) : 0;
            EDGE_OpportunityCountWrapper OpportunityCountWrapper = new EDGE_OpportunityCountWrapper();
            OpportunityCountWrapper.outletId = accountId;
            OpportunityCountWrapper.openOppsCount = openOpportunities;
            OpportunityCountWrapper.closedOppsCount = closeOpportunities;
            OpportunityCountWrapperList.add(OpportunityCountWrapper);
        }
        system.debug('OpportunityCountWrapperList::'+OpportunityCountWrapperList);
        
        return OpportunityCountWrapperList;
        
    } 
}