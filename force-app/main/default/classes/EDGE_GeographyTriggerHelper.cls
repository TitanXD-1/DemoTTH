/**********************************************************************
Name: EDGE_GeographyTriggerHelper
=======================================================================
Req: 
ES20-380 - MAS & MPA Weightings
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR               DATE              DETAIL
1.0       Dipanjan Das         12/03/2019        Added Method EDGE_GeographyTriggerHelper
2.0       Preyanka Ghosh       10/05/2019        ES20-1613 Custom Sharing - Geographies to Public Groups
3.0       Anuja Chattopadhyay  09/08/2019        ES20-3820 Added method createQueue 
4.0      Anivesh Muppa         14/04/2021        ECM-4199 removed area comment on line 118
***********************************************************************/

public with sharing class EDGE_GeographyTriggerHelper{
    
    /*******************************************************************
    Method  : globalTypeValidation
    Purpose : This methods used to validate that system should have only 
    one global value
    ********************************************************************/  
    
    
    public static void globalTypeValidation(List<SObject> newItems){
        Schema.DescribeSObjectResult results = Schema.SObjectType.Geography__c; 
        Map<String,Schema.RecordTypeInfo> rtMapByDevName = results.getRecordTypeInfosByDeveloperName();
        List<Geography__c> geoGlobal=new List<Geography__c>();
        if(Schema.sObjectType.Geography__c.isAccessible()){
            geoGlobal=[select id from Geography__c where recordtype.Name='Global'];            
        }        
        for(sObject sobj: newItems){
            Geography__c geo = (Geography__c )sobj;
            if(geo.RecordTypeId==rtMapByDevName.get('Global').getRecordTypeId() && geoGlobal.size()>=1){
                geo.addError('You can not have two global record in the system .');
            }
        }
    }
    
    
    /*******************************************************************
    Method  : updateCountryWeightage
    Purpose : This methods used to propagate KPIs from Global to Country level.
    ********************************************************************/       
    public static void updateCountryWeightage(List<SObject> newItems){
        //Id globalRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Global'].Id;
        //Id countryRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Country'].Id;
        
        if(!EDGE_UtilityClass.stopTriggerToRun){
            Schema.DescribeSObjectResult results = Schema.SObjectType.Geography__c; 
            Map<String,Schema.RecordTypeInfo> rtMapByDevName = results.getRecordTypeInfosByDeveloperName();
            List<Geography__c> geographyListToUpdate = new List<Geography__c>();
            Decimal globalMASValue=0, globalMPAValue=0;
            for(SObject obj :newItems){ 
                Geography__c geography = (Geography__c )obj;
                if(geography.RecordTypeId == rtMapByDevName.get('Global').getRecordTypeId()){
                    
                    if(geography.Minimum_Activation_Standards__c != null && geography.Minimum_Activation_Standards__c != 0.00){
                        globalMASValue = geography.Minimum_Activation_Standards__c;
                    }
                    if(geography.Minimum_Product_Assortment__c != null && geography.Minimum_Product_Assortment__c != 0.00){
                        globalMPAValue = geography.Minimum_Product_Assortment__c;
                    }
                    break;  
                }
            } 
            
            //if checks when trigger is firing for inserting new country value and propagate global weightage in the new country
            if(globalMASValue==0 &&  globalMPAValue==0 && Schema.sObjectType.Geography__c.isAccessible()){
                List<Geography__c> globalGeo=[select id,Minimum_Activation_Standards__c ,Minimum_Product_Assortment__c from Geography__c where recordtype.Name='Global'];
                if(globalGeo != null && globalGeo.size()>0) {
                    globalMASValue = globalGeo[0].Minimum_Activation_Standards__c;
                    globalMPAValue = globalGeo[0].Minimum_Product_Assortment__c;
                }
            }
            
            
            Id countryRecordTypeId=rtMapByDevName.get('Country').getRecordTypeId();
            for(Geography__c geography : [SELECT Id,Minimum_Activation_Standards__c,Minimum_Product_Assortment__c FROM Geography__c WHERE RecordTypeId = :countryRecordTypeId]){
                if((geography.Minimum_Activation_Standards__c == null || geography.Minimum_Activation_Standards__c == 0.00)
                   && (geography.Minimum_Product_Assortment__c == null || geography.Minimum_Product_Assortment__c == 0.00)){
                       Geography__c geo= new Geography__c(id=geography.id);
                       geo.Minimum_Activation_Standards__c = globalMASValue;
                       geo.Minimum_Product_Assortment__c = globalMPAValue;
                       geographyListToUpdate.add(geo);
                   }     
            }
            
            if(geographyListToUpdate != null && geographyListToUpdate.size() > 0 && Schema.sObjectType.Geography__c.isUpdateable()){
                EDGE_UtilityClass.stopTriggerToRun=true;
                
                update geographyListToUpdate;
                
            }  
        } 
    }
    
    /*******************************************************************
    Method  : createUpdatePublicGroup
    Purpose : Create and Update group name 
    ********************************************************************/       
    public static void createUpdatePublicGroup(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        String groupUp = EDGE_Constant.EDGE_GROUP_UP;
        String groupDown = EDGE_Constant.EDGE_GROUP_DOWN;
        Map<Id,Geography__c> mapNewGeography;
        Map<Id,Geography__c> mapOldGeography;
        Map<String, String> mapGroupName = new Map<String, String>();
        List<Group> lstGroup = new List<Group>();
        system.debug('newItems-->'+newItems);
        system.debug('oldItems-->'+oldItems);
        try{
            if(oldItems != null && oldItems.size()>0){
                mapOldGeography = (Map<Id,Geography__c>)oldItems;                                 
            }
            
            if(newItems != null && newItems.size()>0){
                mapNewGeography = (Map<Id,Geography__c>)newItems;
                for(Geography__c newGeography : mapNewGeography.values()){
                    if(!((newGeography.Sharing_Group_Name__c).containsIgnoreCase('Global') ||/* (newGeography.Sharing_Group_Name__c).containsIgnoreCase('Area') ||*/ (newGeography.Sharing_Group_Name__c).containsIgnoreCase('Region'))){
                        if(mapOldGeography != null && mapOldGeography.containsKey(newGeography.Id) && (newGeography.RecordTypeId != mapOldGeography.get(newGeography.Id).RecordTypeId || newGeography.Code__c != mapOldGeography.get(newGeography.Id).Code__c)){
                            mapGroupName.put(mapOldGeography.get(newGeography.Id).Sharing_Group_Name__c+groupDown, newGeography.Sharing_Group_Name__c+groupDown);
                            mapGroupName.put(mapOldGeography.get(newGeography.Id).Sharing_Group_Name__c+groupUp, newGeography.Sharing_Group_Name__c+groupUp);
                        } else if(mapOldGeography == null) {
                            mapGroupName.put(newGeography.Sharing_Group_Name__c+groupDown, newGeography.Sharing_Group_Name__c+groupDown);
                            mapGroupName.put(newGeography.Sharing_Group_Name__c+groupUp, newGeography.Sharing_Group_Name__c+groupUp);                            
                        }                        
                    }
                }
                
                if(mapGroupName != null && mapGroupName.size()>0){
                    if(Schema.sObjectType.Group.isAccessible() && Schema.sObjectType.Group.isCreateable() && Schema.sObjectType.Group.isUpdateable()){
                        Map<String, Group> mapOldGroup = new Map<String, Group>();
                        for(Group objOldGroup : [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName IN :mapGroupName.keySet()]){
                            mapOldGroup.put(objOldGroup.DeveloperName, objOldGroup);                            
                        }
                        
                        for(String objGroupName : mapGroupName.keySet()){
                            if(mapOldGroup.containsKey(objGroupName)){
                                String groupName = mapGroupName.get(objGroupName);
                                Group objOldGroup = mapOldGroup.get(objGroupName);
                                objOldGroup.Name = groupName;
                                objOldGroup.DeveloperName = groupName;                            
                                lstGroup.add(objOldGroup);
                            } else {
                                Group objGroup = new Group(Name = objGroupName, DeveloperName = objGroupName);
                                lstGroup.add(objGroup);
                            }
                        }                        
                    }
                }
                
                if(lstGroup != null && lstGroup.size()>0){
                    System.debug('lstGroup:::'+lstGroup);
                    Database.upsert(lstGroup);
                    System.debug(' after upsert lstGroup:::'+lstGroup);                    
                }
                
                if(mapOldGeography == null){
                    EDGE_SharingUtil.createUpdateGeographyShare(mapNewGeography, lstGroup);                        
                }
            }
        } catch(Exception excption){
            List<SObject> errorItem= newItems.values();
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);
        }
    }
    
    /*******************************************************************
    Method  : assignGroupAsMember
    Purpose : Assign Group as member of other group on Insert/Update
    ********************************************************************/
    public static void assignGroupAsMember(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id,Geography__c> mapNewGeography;
        Map<Id,Geography__c> mapOldGeography;
        Map<String, String> mapUpGroupName = new Map<String, String>();
        Map<String, String> mapDownGroupName = new Map<String, String>();
        Map<String, String> mapDeleteGroupName = new Map<String, String>();
        Map<Id, Id> mapDeleteGroupId = new Map<Id, Id>();
        Map<Id, List<Geography__c>> mapParentChildGeo = new Map<Id, List<Geography__c>>();
        Map<Id, List<Geography__c>> mapDeleteParentChildGeo = new Map<Id, List<Geography__c>>();
        
        Set<Id> setParentId = new Set<Id>();
        Set<String> setGroupName = new Set<String>();
        Set<String> setDeleteGroupName = new Set<String>();
        Set<Id> setDeleteGroupMember = new Set<Id>();
        
        List<GroupMember> lstGroupMember = new List<GroupMember>();
        
        try{
            if(oldItems != null && oldItems.size()>0){
                mapOldGeography = (Map<Id,Geography__c>)oldItems;                                 
            }
            
            if(newItems != null && newItems.size()>0 && Schema.sObjectType.Geography__c.isAccessible() && Schema.sObjectType.Group.isAccessible() && Schema.sObjectType.GroupMember.isAccessible()){
                mapNewGeography = (Map<Id,Geography__c>)newItems;
                Id globalRecordId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Global').getRecordTypeId();
                List<Geography__c> globalGeography = [SELECT ID FROM Geography__c WHERE RecordTypeId =:globalRecordId LIMIT 1];
                for(Geography__c newGeography : mapNewGeography.values()){                    
                    if(newGeography.Parent_Geography__c != null && globalGeography != null && globalGeography.size()> 0 && newGeography.Parent_Geography__c != globalGeography[0].Id){
                        setParentId.add(newGeography.Parent_Geography__c);
                        
                        //Create a Map of Parent Geography Id and List Geography, which is used to get the details of parent geography later
                        if(mapParentChildGeo.containsKey(newGeography.Parent_Geography__c)){
                            mapParentChildGeo.get(newGeography.Parent_Geography__c).add(newGeography);
                        } else {
                            mapParentChildGeo.put(newGeography.Parent_Geography__c, new List<Geography__c>{newGeography});
                        }
                    }
                        
                    //For update need to create a Map which will hold the data for delete
                    if(newGeography.Parent_Geography__c != null && mapOldGeography != null && mapOldGeography.size()>0 && mapOldGeography.containsKey(newGeography.Id) &&  globalGeography != null &&  globalGeography.size()> 0 && mapOldGeography.get(newGeography.Id).Parent_Geography__c != globalGeography[0].Id && mapOldGeography.get(newGeography.Id).Parent_Geography__c != newGeography.Parent_Geography__c){
                        setParentId.add(mapOldGeography.get(newGeography.Id).Parent_Geography__c);
                        if(mapDeleteParentChildGeo.containsKey(newGeography.Parent_Geography__c)){
                            mapDeleteParentChildGeo.get(mapOldGeography.get(newGeography.Id).Parent_Geography__c).add(newGeography);                                
                        } else {
                            mapDeleteParentChildGeo.put(mapOldGeography.get(newGeography.Id).Parent_Geography__c, new List<Geography__c>{newGeography});
                        }                            
                    }
                                    
                }
                System.debug('setParentId::'+setParentId);
                System.debug('mapDeleteParentChildGeo::'+mapDeleteParentChildGeo);
                if(setParentId != null && setParentId.size()>0){
                    //To get the Sharing Group Name of Parent Geography
                    for(Geography__c existGeography : [SELECT Id, Sharing_Group_Name__c FROM Geography__c WHERE Id IN :setParentId]){
                        
                        //Create Set of Group Name which is used to do the query and get the Group Id
                        if(mapParentChildGeo.containsKey(existGeography.Id)){
                            for(Geography__c newGeography : mapParentChildGeo.get(existGeography.Id)){
                                setGroupName.add(newGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN);
                                setGroupName.add(newGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP);
                                setGroupName.add(existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN);
                                setGroupName.add(existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP);
                                mapDownGroupName.put(newGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN,existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN);
                                mapUpGroupName.put(newGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP,existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP);
                            }                            
                        }
                        
                        //Create Set of Group Name which is used to delete existing Group share for Update
                        if(mapDeleteParentChildGeo.containsKey(existGeography.Id)){
                            for(Geography__c oldGeography : mapDeleteParentChildGeo.get(existGeography.Id)){
                                setDeleteGroupName.add(oldGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN);
                                setDeleteGroupName.add(oldGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP);
                                setDeleteGroupName.add(existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP);
                                setDeleteGroupName.add(existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN);
                                mapDeleteGroupName.put(oldGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN,existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN);
                                mapDeleteGroupName.put(existGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP,oldGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP);
                            }
                        }                        
                    }
                    
                    System.debug('setGroupName::'+setGroupName);
                    System.debug('setDeleteGroupName::'+setDeleteGroupName);
                    System.debug('mapDeleteGroupName::'+mapDeleteGroupName);
                    
                    if(setDeleteGroupName != null && setDeleteGroupName.size()>0){                        
                        Map<String, Id> mapGroupnameId = new Map<String, Id>();
                        
                        //Get the Group Id from above created Set
                        for(Group objGroup : [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName IN :setDeleteGroupName]){
                            setDeleteGroupMember.add(objGroup.Id);
                            mapGroupnameId.put(objGroup.DeveloperName, objGroup.Id);
                        }
                        
                        //Create Map which will hold the Id mapping and can be used for Deletion purpose when parent Geo Id update for a geography
                        for(String downGroupName:mapDeleteGroupName.keySet()){
                            mapDeleteGroupId.put(mapGroupnameId.get(downGroupName), mapGroupnameId.get(mapDeleteGroupName.get(downGroupName)));
                        }                        
                    }
                    System.debug('setDeleteGroupMember::'+setDeleteGroupMember);
                    System.debug('mapDeleteGroupId::'+mapDeleteGroupId);
                    
                    if(setGroupName != null && setGroupName.size()>0){
                        Map<String,Group> mapExistGroup = new Map<String, Group>();
                        for(Group objGroup : [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName IN :setGroupName]){
                            mapExistGroup.put(objGroup.DeveloperName, objGroup);
                        }
                        System.debug('mapExistGroup::'+mapExistGroup);
                        
                        //Create Up Group member 
                        if(mapExistGroup != null && mapExistGroup.size()>0){
                            for(String groupName : mapUpGroupName.keySet()){
                                if(mapExistGroup.containsKey(groupName)){
                                    GroupMember objGroupMember = new GroupMember();
                                    objGroupMember.GroupId = mapExistGroup.get(mapUpGroupName.get(groupName)).Id;
                                    objGroupMember.UserOrGroupId = mapExistGroup.get(groupName).Id;
                                    lstGroupMember.add(objGroupMember);
                                }
                            }
                            
                            //Create Down Group member
                            for(String groupName : mapDownGroupName.keySet()){
                                if(mapExistGroup.containsKey(groupName) && mapExistGroup.containsKey(mapDownGroupName.get(groupName))){
                                    GroupMember objGroupMember = new GroupMember();
                                    objGroupMember.UserOrGroupId = mapExistGroup.get(mapDownGroupName.get(groupName)).Id;
                                    objGroupMember.GroupId = mapExistGroup.get(groupName).Id;
                                    lstGroupMember.add(objGroupMember);
                                }
                            }                            
                        } 
                        System.debug('lstGroupMember::'+lstGroupMember);
                    }
                    
                    if(setDeleteGroupMember != null && setDeleteGroupMember.size()>0 && mapDeleteGroupId != null && mapDeleteGroupId.size()>0){
                        Database.executeBatch(new EDGE_DeleteGroupMember(setDeleteGroupMember,mapDeleteGroupId, lstGroupMember), 2000);                             
                    } else if(lstGroupMember != null && lstGroupMember.size()>0){
                        EDGE_SharingUtil.assignGroupMember(JSON.serialize(lstGroupMember));
                    }
                }                
            }
        } catch(Exception excption){
            List<SObject> errorItem = newItems.values();
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);
        }
    }
    
    /*******************************************************************
    Method  : deleteGroupAsMember
    Purpose : This is used to delete Group and also related member of those group
    ********************************************************************/
    public static void deleteGroupAsMember(Map<Id, SObject> oldItems){
        Map<Id,Geography__c> mapOldGeography = (Map<Id,Geography__c>)oldItems;
        Set<String> setGroupName = new Set<String>();
        List<Id> listDeleteGroupId = new List<Id>();
        
        try{
            for(Geography__c oldGeography : mapOldGeography.values()){
                setGroupName.add(oldGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_DOWN);
                setGroupName.add(oldGeography.Sharing_Group_Name__c+EDGE_Constant.EDGE_GROUP_UP);                
            }
            
            if(setGroupName != null && setGroupName.size()>0 && Schema.sObjectType.Group.isAccessible() && Schema.sObjectType.Group.isDeletable()){
                for(Group objGroup : [SELECT Id FROM Group WHERE DeveloperName =:setGroupName]){
                    listDeleteGroupId.add(objGroup.Id);
                }
                
                if(listDeleteGroupId != null && listDeleteGroupId.size()>0){
                    Database.delete(listDeleteGroupId);
                }
            }            
        } catch(Exception excption){
            List<SObject> errorItem = oldItems.values();
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);
        }
    }
    
    /*******************************************************************
    Method  : createNewQueue
    Purpose : This is used to create new queue on country creation
    ********************************************************************/
    
    public static void createNewQueue(List<Geography__c> newItems){
        
        //Variables
        String countryRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        List<Geography__c> countryList = new List<Geography__c>();
        List<Group> queueList = new List<Group>();
        Set<String> oldQueueToRemove = new Set<String>();
        Map<String,String> queueNameMap = new Map<String,String>();
        Map<String,Id> queueIdMap = new Map<String,Id>();
        String objName = 'Geography__c';
        
        
        
        for(Geography__c newGeography : newItems){
            if(newGeography.RecordTypeId == countryRecordTypeId){
                countryList.add(newGeography);
            }
        }
        Schema.FieldSet fsGeography = Schema.SObjectType.Geography__c.fieldSets.getMap().get('Queue_Creation_Fields');
        
        if(countryList != null && countryList.size()>0){
            for(Geography__c newCountryGeography : countryList){
                for(Schema.FieldSetMember fsm : fsGeography.getFields()){
                    String newQueueName = (String)newCountryGeography.get(fsm.getFieldPath());
                    Group countryQueue = new Group(Type='Queue', Name=newQueueName);
                    queueList.add(countryQueue);
                }   
            }
        }

        //Insert new queue
        if(queueList != null && queueList.size() > 0){
            insert queueList;
        }
        
        for(Group grpObj : queueList){
            queueIdMap.put(grpObj.name,grpObj.Id);
        }
        
        if(queueIdMap != null && queueIdMap.size()>0){
            assgnSpprtdObjToNewQueues(queueIdMap.Values(),objName); 
            //Database.executeBatch(new EDGE_Assign(queueIdMap.Values(),objName), 1);  
        }
      
    }
    
    /*******************************************************************
    Method  : assgnSpprtdObjToNewQueues
    Purpose : This is used to assign Supported Object as Geography to the inserted queue
    ********************************************************************/ 
    @future
    public static void assgnSpprtdObjToNewQueues(List<Id> queueIdList, String objName) {
        //Variables
        Set<QueueSobject> supportedObjSet = new Set<QueueSobject>();
        List<QueueSobject> supportedObjList = new List<QueueSobject>();

        //Assigning supported object to the newly inserted queues 
        if(queueIdList!=null && String.isNotBlank(objName) && Schema.SObjectType.Group.isAccessible()){
            for(Group grpObj : [SELECT Id from Group WHERE Id in :queueIdList]){
                QueueSobject qs = new QueueSobject();
                qs.QueueId = grpObj.Id;
                qs.SobjectType = objName;
                supportedObjSet.add(qs);
                
            } 
        }
        System.debug('@@supportedObjList' +supportedObjList);
        if(supportedObjSet!=null && supportedObjSet.size()>0 && Schema.SObjectType.QueueSobject.isCreateable()){
            supportedObjList.addall(supportedObjSet);
            insert supportedObjList;
        }
    }
    
    /*******************************************************************
    Method  : removeOldQueue
    Purpose : This is used to remove old queues whose Code gets modified
    ********************************************************************/   
    
    public static void removeOldQueue(List<Geography__c> oldItems) {
        //Variables
        String countryRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        Set<String> oldQueueNameToRemove = new Set<String>();
        List<Group> groupToDel = new List<Group>();
        
        Schema.FieldSet fsGeography = Schema.SObjectType.Geography__c.fieldSets.getMap().get('Queue_Creation_Fields');        
        for(Geography__c oldGeoObj : oldItems ){
            if(oldGeoObj.RecordTypeId == countryRecordTypeId){
               for(Schema.FieldSetMember fsm : fsGeography.getFields()){
                String oldQueueName = (string)oldGeoObj.get(fsm.getFieldPath());
                oldQueueNameToRemove.add(oldQueueName);
                }
              }  
                
            }
                 
        for(Group objGroup : [SELECT Id,name from Group WHERE group.name LIKE:oldQueueNameToRemove AND group.type='Queue' ]){
            groupToDel.add(objGroup);
        }
        if(groupToDel!=null && groupToDel.size()>0){
            delete groupToDel;
        }
        
    }
}