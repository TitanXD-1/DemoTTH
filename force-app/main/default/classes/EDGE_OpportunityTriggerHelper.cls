/*
* @description :  EDGE_OpportunityTriggerHelper
* @purpose : This is the Helper class for OpportunityTriggerHandler
* @Test Class: EDGE_OpportunityTriggerHelperTest
* @history :
* Version    Developer              Date                    User Story/Purpose
* 	1.0     Amar Deep         		10/12/2019			ES20-3967 updateUserFields,autopopulateSalesRep method added 
*   2.0		Shivam Chauhan			31/05/2023			ES20-13851 
*   3.0		Shivam Chauhan			08/06/2024			155299 
*/ 
/**
* @description Helper for OpportunityTriggerHandler
**/
public with sharing class EDGE_OpportunityTriggerHelper {
    
        /** 
    * @description  This is used to assign user from MDM Queue based on Market
    * @param  newItems
    **/
    public static void updateUserFields(List<Opportunity> newItems){
        List<Opportunity> oppList = new List<Opportunity>();
        Set<Id> accountSetId = new Set<Id>();
        Set<Id> countrySetId = new Set<Id>();
        Set<String> queueStrSet = new Set<String>();
        Map<Id, String> accQueueMap = new Map<Id, String>();
        Map<Id, Id> accountSalesrepMap = new Map<Id, Id>();
        Map<Id, String> mapMarketSetting = new Map<Id, String>();
        Map<String, List<Id>> queueUserMap = new Map<String, List<Id>>();
        Map<Id, String> accountCountryMap = new Map<Id, String>();
        
        if(newItems!=null){
            for(Opportunity oppRec : newItems){
                if(oppRec.Snooze_date__c != null && oppRec.Snooze_reason__c != null){
                    oppList.add(oppRec);
                    accountSetId.add(oppRec.AccountId);
                }
            }
        }
        
        // Fetching country of Account which is related to Opportunity
        If(accountSetId != null && accountSetId.size() > 0 ){
            for(Account acc : [SELECT Id, Country__c, Country__r.MDM_Queue__c, Primary_Sales_Rep__c, Primary_Sales_Rep__r.ManagerId FROM Account WHERE Id IN :accountSetId]){
                countrySetId.add(acc.Country__c);
                queueStrSet.add(acc.Country__r.MDM_Queue__c);
                accQueueMap.put(acc.Id, acc.Country__r.MDM_Queue__c);
                accountCountryMap.put(acc.Id, acc.Country__c);
                if(acc.Primary_Sales_Rep__r.ManagerId != null){
                    accountSalesrepMap.put(acc.Id, acc.Primary_Sales_Rep__r.ManagerId);
                }
            }
        }
        
        //Fetching respective market settings data
        If(countrySetId != null && countrySetId.size()>0){
            if(Schema.sObjectType.Market_Setting__c.isAccessible()){
                for(Market_Setting__c marketSettings : [SELECT Id, Geography__c, Geography__r.Code__c, Snooze_Opportunity_Request_Approval__c FROM Market_Setting__c WHERE Geography__c IN :countrySetId]){
                    mapMarketSetting.put(marketSettings.Geography__c, marketSettings.Snooze_Opportunity_Request_Approval__c);
                }
            }
        }
        
        //Get Queue Members
        if(queueStrSet.size()>0 && Schema.SObjectType.GroupMember.isAccessible()){
            for(GroupMember grpmem : [SELECT Group.Name, Userorgroupid from GroupMember where Group.type='Queue' and Group.Name IN: queueStrSet]){
                if(queueUserMap.containsKey(grpmem.Group.Name)){
                    List<Id> tempList = queueUserMap.get(grpmem.Group.Name);
                    tempList.add(grpmem.Userorgroupid);
                    queueUserMap.put(grpmem.Group.Name, tempList);                   
                }else{
                    queueUserMap.put(grpmem.Group.Name, new List<Id>{grpmem.Userorgroupid});
                }    
            }
        }
        
        //Update Opportunity
        if(oppList != null && oppList.size()>0){
            for(Opportunity newOppRec : oppList){
                string queueName = accQueueMap.get(newOppRec.AccountId);
                Id countryId = accountCountryMap.get(newOppRec.AccountId);
                
                if(String.isNotBlank(mapMarketSetting.get(countryId))){
                    string approvalStep = mapMarketSetting.get(countryId);
                    if(approvalStep.equalsIgnoreCase(Label.Opportunity_MDM_Approval)){
                        newOppRec.Current_Approval_Step__c = Label.Opportunity_MDM_Approval;
                        //Update MDM Queue Member
                        if(queueUserMap != null && queueUserMap.containsKey(queueName)){
                            List<Id> userList = queueUserMap.get(queueName);
                            if(!userList.isEmpty()){
                                if(userList.size()>=3){                     
                                    newOppRec.Approver_1__c = userList[0];
                                    newOppRec.Approver_2__c = userList[1];
                                    newOppRec.Approver_3__c = userList[2]; 
                                }else if(userList.size()==2){
                                    newOppRec.Approver_1__c = userList[0];
                                    newOppRec.Approver_2__c = userList[1];
                                    newOppRec.Approver_3__c = userList[1]; 
                                }else if(userList.size()==1){
                                    newOppRec.Approver_1__c = userList[0];
                                    newOppRec.Approver_2__c = userList[0];
                                    newOppRec.Approver_3__c = userList[0];
                                }
                            }
                        }
                    }else if(approvalStep.equalsIgnoreCase(Label.Opportunity_Sales_Manager_Approval)){
                        newOppRec.Current_Approval_Step__c = Label.Opportunity_Sales_Manager_Approval;
                        //Update Sales Rep Manager
                        if(accountSalesrepMap.size()>0 && accountSalesrepMap.containsKey(newOppRec.AccountId)){
                            newOppRec.Sales_Manager__c = accountSalesrepMap.get(newOppRec.AccountId);
                        }
                    }   
                }
            }
        }
    }
    
        /** 
    * @description  This method will update the owner field with current user
    * @param  newItems
    **/
    public static void changeOwner(List<Opportunity> newItems){
        if(newItems!=null){
            for(Opportunity oppRec : newItems){
                if(UserInfo.getUserId() != null){
                    if(oppRec.Snooze_date__c != null && oppRec.Snooze_reason__c != null){
                        oppRec.OwnerId = UserInfo.getUserId();     
                    }                	   
                }
            }
        }
    }
    
        /** 
    * @description  This method will autopopulate Assigned To field with Account's Primary Sales Rep
    * @param  newItems
    **/
    public static void autoPopulateAssignedTo(List<Opportunity> newItems){
        List<Id> oppId = new List <Id>();
        List<Opportunity> updateOpp = new List<Opportunity>();
        Map<String,Map<String,Object>> idCustomMsgAndroid = new Map<String,Map<String,Object>>();
        Map<String,String> idCustomMsgIosBody = new Map<String,String>();
        Map<String,Map<String,Object>> idCustomMsgIosType = new Map<String,Map<String,Object>>();
        String opportunityNotifText = Label.Edge_Opportunity_Notif_Text;
        final String opportunityNameStr = '{Opportunity Name}';
        final String accountNameStr = '{Account Name}';
        final String assigneeNameStr = '{Assignee Name}';
        final String bodyStr = 'Body';
        final String typeStr = 'Type';
        
        if(newItems!=null){
            for(Opportunity opp: newItems){
                oppId.add(opp.id);
            }
            
            for(Opportunity opp :[Select Id,Name, Assigned_To__c,Account.Primary_Sales_Rep__c,Account.Name,Hot_Lead__c from Opportunity Where id IN:oppId and Account.Primary_Sales_Rep__c!=null WITH SECURITY_ENFORCED]){
                Opportunity opp1 = new Opportunity(id=opp.id);
                opp1.Assigned_To__c = opp.Account.Primary_Sales_Rep__c;
                updateOpp.add(opp1);
                
                if(opp.Hot_Lead__c ==true){
                    Map<String,Object> customAndroid = new Map<String,Object>();
                    Map<String,Object> customIosType = new Map<String,Object>();
                    opportunityNotifText = opportunityNotifText.replace(opportunityNameStr, opp.Name);
                    opportunityNotifText = opportunityNotifText.replace(accountNameStr, opp.Account.Name);
                    opportunityNotifText = opportunityNotifText.replace(assigneeNameStr, UserInfo.getName());
                    customAndroid.put(bodyStr,opportunityNotifText);
                    customAndroid.put(typeStr,Label.Edge_Opportunity_Hot_leads);
                    customIosType.put(typeStr,Label.Edge_Opportunity_Hot_leads);
                    idCustomMsgAndroid.put(opp.Account.Primary_Sales_Rep__c,customAndroid);
                    idCustomMsgIosBody.put(opp.Account.Primary_Sales_Rep__c, opportunityNotifText);
                    idCustomMsgIosType.put(opp.Account.Primary_Sales_Rep__c, customIosType);
                }
            }
        }
        if(Schema.sObjectType.Opportunity.fields.Assigned_To__c.isUpdateable() && updateOpp.size()>0){
            Database.update(updateOpp);
        }
        if(idCustomMsgAndroid.size()>0){
            EDGE_NotifHelper.sendAndroidNotificationToUsers(idCustomMsgAndroid);
        }
        if(idCustomMsgIosBody.size()>0){
            EDGE_NotifHelper.sendIosNotificationToUsers(idCustomMsgIosBody,idCustomMsgIosType);
        }    
    }
    
        /** 
    * @description  This method will update fields of Opportunity which is coming from Andvanced Analytics 155299
    * @param  newItems
    * @param  oldItems
    **/
    public static void createOpportunities(List<Opportunity> newItems,List<Opportunity> oldItems){
        Set<Id> oppTempIdSet = new Set<Id>();
        Map<Id,Opportunity_Template__c> mapIDOpportunityTemplate = new Map<Id,Opportunity_Template__c>();
        Map<Id,id> mapOldIDOpp = new Map<Id,id>();
        Map<Id,id> mapNewIDOpp = new Map<Id,id>();
        List<String> oppTempTypePickListValues = new List<String>{'MPA','MAS','WPA','Cycle Brief'};
            
            for(Opportunity oppNew : newItems){
                oppTempIdSet.add(oppNew.Opportunity_Template__c);
                mapNewIDOpp.put(oppNew.id,oppNew.Opportunity_Template__c);
            }
        
        getOldIDOpp(oldItems,mapOldIDOpp);
        
        
        for(Opportunity_Template__c oppTemp : [Select id,Opportunity_Type__c,Source__c,Start_Date__c,End_Date__c,Action__c from Opportunity_Template__c where Id=:oppTempIdSet and Source__c = 'Advanced Analytics' and Opportunity_Type__c IN: oppTempTypePickListValues with security_enforced]){
            mapIDOpportunityTemplate.put(oppTemp.id,oppTemp);
        }
        
        for(Opportunity opp : newItems){
            
            if(!mapIDOpportunityTemplate.isEmpty() && mapIDOpportunityTemplate.keyset().contains(opp.Opportunity_Template__c) && (trigger.isInsert || (trigger.isUpdate && mapOldIDOpp.get(opp.id)!=mapNewIDOpp.get(opp.id)))){
                updateOppField(opp,mapIDOpportunityTemplate);
            } 
        }  
    }
    
        /** 
    * @description  This method will update fields of Opportunity which is coming from Andvanced Analytics 155299
    * @param  opp
    * @param  mapIDOpportunityTemplate
    **/
    public static void updateOppField(Opportunity opp,Map<Id,Opportunity_Template__c> mapIDOpportunityTemplate){
        List<String> oppTypePickListValues = new List<String>{'MPA','MAS','WPA'};
            String action;
        if(opp.Source__c == 'Advanced Analytics'){
            if(oppTypePickListValues.contains(opp.Type)){
                opp.CloseDate = mapIDOpportunityTemplate.get(opp.Opportunity_Template__c).End_Date__c == null ? Date.today().addYears(1) : mapIDOpportunityTemplate.get(opp.Opportunity_Template__c).End_Date__c;
            }else if(opp.Type == 'Cycle Brief'){
                opp.Start_Date__c = mapIDOpportunityTemplate.get(opp.Opportunity_Template__c).Start_Date__c;
                opp.CloseDate = mapIDOpportunityTemplate.get(opp.Opportunity_Template__c).Start_Date__c.addYears(1);
            }
            action = mapIDOpportunityTemplate.get(opp.Opportunity_Template__c).Action__c == null? '': mapIDOpportunityTemplate.get(opp.Opportunity_Template__c).Action__c;
            opp.Name = String.valueOf(opp.Type +'-'+action);
        }
    } 
    
        /** 
    * @description  This method will give map of old Items ID and Opportunity 155299
    * @param  oldItems
    * @param  mapOldIDOpp
    **/
    public static void getOldIDOpp(List<Opportunity> oldItems,Map<Id,id> mapOldIDOpp){
        if(oldItems!=null){
            for(Opportunity oppOld :oldItems){
                mapOldIDOpp.put(oppOld.id,oppOld.Opportunity_Template__c);
            }
        }
    }
    
}