/**
* @name : D1_OpportunityTemplateTriggerHelper
* @description : opportunity template trigger
* @history 
* VERSION     AUTHOR         DATE           DETAIL
* 1.0         Rithika        06/12/21       NCP-5508 (validateContentKeyAndType)
**/
public with sharing class D1_OpportunityTemplateTriggerHelper {
    /**
    * Validate Content Key and Content Type (NCP-5508)
    * @param newItems 
    * @param oldItems 
    */
    public static void validateContentKeyAndType(List<SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id,Opportunity_Template__c> oldOpportunityTemMap = (Map<Id,Opportunity_Template__c>)oldItems;
        List<Opportunity_Template__c> listNewOppTemp = (List<Opportunity_Template__c>)newItems;
        Boolean isOldMap = oldOpportunityTemMap!= null; 
        String contentType = 'Selling_Stories'; 
        Set<String> setContentKeys = new Set<String>();

        List<Opportunity_Template__c> listOppToProcess = new List<Opportunity_Template__c>();
        for(Opportunity_Template__c newOppTempObj : listNewOppTemp){
            if(!isOldMap                              
            || (isOldMap && oldOpportunityTemMap.get(newOppTempObj.Id).D1_Content_Reference__c != newOppTempObj.D1_Content_Reference__c)){
                setContentKeys.add(newOppTempObj.D1_Content_Reference__c);
                listOppToProcess.add(newOppTempObj);
            }
        }
        setContentKeys.remove(null); 

        Set<String> setFilteredContentKeys = new Set<String>();
        try{
            if(!setContentKeys.isEmpty()){
                String communityId = [SELECT id FROM Network WHERE Name = 'DiageoOne' LIMIT 1].Id;
                ConnectApi.ManagedContentVersionCollection contentList = ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, 
                                                                        new List<String>(setContentKeys), null, 200, null, contentType, false);
                List<ConnectApi.ManagedContentVersion> items = contentList.items;
                for(ConnectApi.ManagedContentVersion item : items){ setFilteredContentKeys.add(item.contentKey); 
                }           
            }
        }catch(Exception e){
            for(Opportunity_Template__c newOppTempObj : listOppToProcess){newOppTempObj.addError('Enter valid Content key');
            }
            return;
        } 
        for(Opportunity_Template__c newOppTempObj : listOppToProcess){
            if(!setFilteredContentKeys.contains(newOppTempObj.D1_Content_Reference__c) && newOppTempObj.D1_Content_Reference__c != null){
                newOppTempObj.addError('Enter valid Content key');
            }
        }
    }

   public static void sendNotification(List<Opportunity_Template__c> newItems,Map<Id, SObject> oldItems){
        
        Map<Id,Opportunity_Template__c> oldOpportunityTemMap;
        Set<String> userIds = new Set<String>();
        Set<String> managerUserIds = new Set<String>();
        Map<Id,Opportunity_Template__c> oppTempMap = new Map<Id,Opportunity_Template__c>();
        
        Set<String> clusterIds = new Set<String>();
        Set<String> marketCodes = new Set<String>();
        
        List<String> marketCodesList = new List<String>();
        Map<Id,Messaging.CustomNotification> oppNotificationMap = new Map<Id,Messaging.CustomNotification>();
        List<User> newlist = new List<User>();
        Map<String,set<String>> countryUsersMap = new Map<String,set<String>>();
        Map<Id,set<String>> geoIdCodeMap = new Map<Id,set<String>>();

        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='D1_New_Opportunity_Template'];
        
        if(oldItems!=null){
            oldOpportunityTemMap = (Map<Id,Opportunity_Template__c>)oldItems;  
        }

        //get geography ids (clusterIds)
        for(Opportunity_Template__c opp : newItems){
            if(opp.D1_Relevant__c && (oldOpportunityTemMap.get(opp.Id).D1_Relevant__c != opp.D1_Relevant__c) && opp.D1_Content_Reference__c == null){
                oppTempMap.put(opp.Id,opp);
                clusterIds.add(opp.Cluster__c);
            }
        }
        if(clusterIds == null) {  //US 150154:PMD Fix
            return;
        }

        //get users of permission set group (D1_Content_Manager,D1_Support_Admin,D1_Portal_Manager)
        if(oppTempMap!=null){
            String allowedPermissionSets = system.Label.D1_Allowed_PermissionSets_NewOppNotification;
            Set<String> permissionSetNames = new Set<String>(new List<String> (allowedPermissionSets.split(','))); 

            for(PermissionSetAssignment p: [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE PermissionSetGroupId IN (SELECT Id FROM PermissionSetGroup WHERE DeveloperName=:permissionSetNames)]){
                userIds.add(p.AssigneeId);  
            }
        }
       
        //get market code of geography from clusterIds
        for(Geography__c market:[SELECT id,code__c,Parent_Geography__c,Parent_Geography__r.Parent_Geography__c FROM Geography__c WHERE recordType.Name = 'Country' AND(Id IN: clusterIds OR Parent_Geography__c IN: clusterIds OR Parent_Geography__r.Parent_Geography__c IN: clusterIds)]){
            marketCodes.add(market.code__c);
            String parent1 = market.Parent_Geography__r.Parent_Geography__c;
            String parent2 = market.Parent_Geography__c;
            if(clusterIds.contains(market.Id)){
                if(!geoIdCodeMap.containskey(market.Id)){
                    geoIdCodeMap.put(market.Id,new set<String>{market.code__c});
                }
                else{
                    geoIdCodeMap.get(market.Id).add(market.code__c);
                }
            }
            else if(clusterIds.contains(parent1)){
                if(!geoIdCodeMap.containskey(parent1)){
                    geoIdCodeMap.put(parent1,new set<String>{market.code__c});
                }else{
                    geoIdCodeMap.get(parent1).add(market.code__c);
                }
            }
            else if(clusterIds.contains(parent2)){
                if(!geoIdCodeMap.containskey(parent2)){
                    geoIdCodeMap.put(parent2,new set<String>{market.code__c});
                }else {
                    geoIdCodeMap.get(parent2).add(market.code__c);
                } 
            }
        }

        //get active users with market code
        marketCodesList.addAll(marketCodes);
        String value = '(\'' + String.join(marketCodesList, '\',\'') + '\')';
        String queryString = 'SELECT Id, Available_Countries__c FROM User where Id=:userIds AND IsActive =true AND Available_Countries__c includes ' + value;

        newlist = DataBase.query(queryString);
       
        for(User u:newlist){
            managerUserIds.add(u.Id);
            String code = u.Available_Countries__c;
            if(code!=null){
                for(String s: code.split(';')){
                    if(!countryUsersMap.containskey(s)){
                        countryUsersMap.put(s,new set<String>{u.Id});
                    }else{
                        countryUsersMap.get(s).add(u.Id);
                    }
                }
            }
        }
        
        if(managerUserIds.isEmpty() && !Test.isRunningTest()) {
            return;
        }
        
        for(Opportunity_Template__c opp : oppTempMap.values()){
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(system.Label.D1_Opportunity_Template_Title);
                notification.setBody(system.Label.D1_Opportunity_Template_Body+' '+ opp.Name);
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(opp.Id);
                oppNotificationMap.put(opp.Cluster__c,notification);
        }

        for(Id oppClusterId: oppNotificationMap.keyset()){
            Messaging.CustomNotification notification = oppNotificationMap.get(oppClusterId);
            if(geoIdCodeMap.get(oppClusterId)!=null && geoIdCodeMap.get(oppClusterId).size()>0){
                for(String code : geoIdCodeMap.get(oppClusterId)){
                    try {
                        if(countryUsersMap.get(code)!=null){
                            notification.send(countryUsersMap.get(code));
                        }
                    }
                    catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, e.getMessage());
                    }
                }
            }
        }
    }
}