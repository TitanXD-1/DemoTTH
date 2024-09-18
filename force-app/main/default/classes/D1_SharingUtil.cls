/**
 * @name D1_SharingUtil
 * @description This class is used to Share Geography records with Public Group
 * @history                                                                                                                        
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0   	  Saurav Paul       21/11/2020        NCP-1262 Initial Development
 * 2.0		  Kapil Baliyan		16/03/2021		  NCP-2091 (Method: generateSharingFromGeography, updateSharingRecords)
 * 3.0        Narayana          14/04/2022       NCP-6401
**/
public without sharing class D1_SharingUtil {
    
    /**
      * @userStory NCP-2091
      * @description shareGeography
      * @param newItems
    **/   
    public static void shareGeography(Map<Id, Geography__c> newItems){
        Set<String> countryCodeSet = new Set<String>();
        List<Group> grpList = new List<Group>();
        Map<String,Id> grpMap = new Map<String,Id>();
        Map<Id,Geography__c> countryGeoMap = new Map<Id,Geography__c>();
        //Id contryRecTypId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        List<Geography__Share> geoSharesList = new List<Geography__Share>();
        if(newItems!= null && !newItems.isEmpty()){
            for(Id geoId : newItems.keySet()){
                Geography__c geoObj = newItems.get(geoId);
                String grpName = Label.D1_Group_Prefix+geoObj.Code__c;
                String internalGroupName = Label.D1_Internal_Group_Prefix+geoObj.Code__c;//NCP-6401
                countryCodeSet.add(grpName);
                countryCodeSet.add(internalGroupName);//NCP-6401
                countryGeoMap.put(geoId,geoObj);
            }
        }
        if(!countryCodeSet.isEmpty()){
            grpList = [SELECT Id,Name FROM Group WHERE Name IN :countryCodeSet];
            if(!grpList.isEmpty()){
                for(Group grObj : grpList){
                    grpMap.put(grObj.Name,grObj.Id);
                }
            }
        }
        for(Geography__c geoObj : countryGeoMap.values()){
            String grpName = Label.D1_Group_Prefix+geoObj.Code__c;
            String internalGroupName = Label.D1_Internal_Group_Prefix+geoObj.Code__c;
            if(grpMap!= null && ( grpMap.containsKey(grpName) ||  grpMap.containsKey(internalGroupName))){
                Geography__Share geoShare = new Geography__Share();
                geoShare.ParentId = geoObj.Id;
                geoShare.UserOrGroupId = grpMap.get(grpName);
                geoShare.AccessLevel = 'Read';
                geoShare.RowCause = 'Geography_Sharing__c';
                geoSharesList.add(geoShare);
            }
        }
        if(!geoSharesList.isEmpty()){
            insert geoSharesList;
        }
    } 

    /**
     * @userStory NCP-2091
     * @description This method is used to create the sharing record based on the geography tagged with record
     * @param lstSObject 
     * @param lookupField 
     * @param accessLevel 
     */    
    public static void generateSharingFromGeography(List<SObject> lstSObject, String lookupField, String accessLevel){
        
        Map<Id,List<Id>> mapRecordsByGeography = new Map<Id,List<Id>>();
        Map<Id,String> mapGeographyGroup = new Map<Id,String>();
        Map<String,Id> mapGroupGeography = new Map<String,Id>();
        List<SObject> listOfSharesToInsert = new List<SObject>();
        Schema.SObjectType shareType;
        
        try{
            //Create a Map to get the mapping of Geography and Record Id
            for(SObject record: lstSObject){
                Id geographyId = (Id) record.get(lookupField);
                Id recordId = (Id) record.get('Id');
                if(geographyId != null){
                    if(mapRecordsByGeography.containsKey(geographyId)){
                        mapRecordsByGeography.get(geographyId).add(recordId);                    
                    } else {
                        mapRecordsByGeography.put(geographyId, new List<Id>{recordId});
                    }                
                }
            }
            
            //Create a Map to get the Sharing_Group_Name__c which can be used to get the Group Id later
            if(mapRecordsByGeography != null && mapRecordsByGeography.size()>0 && Schema.sObjectType.Geography__c.isAccessible()){
                for(Geography__c geography: [SELECT Id, D1_External_Group_Name__c, isDiageoOneEnabled__c FROM Geography__c WHERE Id IN: mapRecordsByGeography.keyset()]){
                    //Check if market is Diageo One Enabled or not bcoz we need to create sharing only for D1 Enabled Markets
                    if(geography.isDiageoOneEnabled__c){
                    	mapGroupGeography.put(geography.D1_External_Group_Name__c, geography.Id);    
                    }else{
                        mapRecordsByGeography.remove(geography.Id);
                    }
                }
            }
            
            //Create a Mapping of Geography Id and Group Id that can be used later
            if(mapGroupGeography != null && mapGroupGeography.size()>0 && Schema.sObjectType.Group.isAccessible()){
                for(Group objGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: mapGroupGeography.keySet()]){
                    mapGeographyGroup.put(mapGroupGeography.get(objGroup.DeveloperName), objGroup.Id);
                }            
            }
            
            //Used to create the list of Share record per Share Object
            if(mapGeographyGroup != null && mapGeographyGroup.size()>0){
                for(Id geographyId : mapRecordsByGeography.keySet()){
                    if(mapGeographyGroup.containsKey(geographyId)){
                        for(Id recordId: mapRecordsByGeography.get(geographyId)){
                            String objectName = recordId.getSobjectType().getDescribe().getName();
                            String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
                            shareType = Schema.getGlobalDescribe().get(shareObjectName);
                            SObject shareRecord = shareType.newSObject();
                            if(!objectName.endsWith('__c')){//NCP-6401- standard objects dont have parent id and access level as fields so splitting into two methods
                                shareRecord.put(objectName+'Id', recordId);
                                shareRecord.put('UserOrGroupId', mapGeographyGroup.get(geographyId));
                                shareRecord.put('RowCause', 'Manual');
                                shareRecord.put(objectName+'AccessLevel', accessLevel);
                            }
                            else{//custom object sharing
                                shareRecord.put('ParentId', recordId);
                                shareRecord.put('UserOrGroupId', mapGeographyGroup.get(geographyId));
                                shareRecord.put('RowCause', 'Geography_Sharing__c');
                                shareRecord.put('AccessLevel', accessLevel);
                            }
                            listOfSharesToInsert.add(shareRecord);
                        }
                    }
                } 
                
                if(listOfSharesToInsert != null && listOfSharesToInsert.size()>0 && shareType.getDescribe().isCreateable()){
                    insert listOfSharesToInsert;
                }
            }
            
        } catch(Exception excption){
            new EDGE_GenericException(excption, lstSObject[0]);
        }   
    }

    /**
     * @userStory NCP-2091
     * @description This method is used to delete the existing sharing when geography is changed and 
     *              will call generateSharingFromGeography method to recreate sharing.
     * @param newItems 
     * @param oldItems 
     * @param lookupField 
     */    
    public static void updateSharingRecords(List<SObject> newItems, List<SObject> oldItems, String lookupField){
        //List<SObject> listOfSharesToUpdate = new List<SObject>();
        Map<Id,List<Id>> mapOldRecordsByGeography = new Map<Id,List<Id>>();
        Map<String,Id> mapGroupGeography = new Map<String,Id>();
        Set<Id> setObjectId = new Set<Id>();
        List<Id> lstGroupId = new List<Id>();
        Id recordId;
        
        try{
            if(oldItems != null && oldItems.size()>0){
                //Create a Map to get the mapping of Geography and Record Id of Old Items
                for(SObject oldRecord: oldItems){
                    Id geographyId = (Id) oldRecord.get(lookupField);
                    recordId = (Id) oldRecord.get('Id');
                    setObjectId.add(recordId);
                    if(geographyId != null){
                        if(mapOldRecordsByGeography.containsKey(geographyId)){
                            mapOldRecordsByGeography.get(geographyId).add(recordId);                    
                        } else {
                            mapOldRecordsByGeography.put(geographyId, new List<Id>{recordId});
                        }                
                    }
                }
                
                //Create a Map to get the Sharing_Group_Name__c which can be used to get the Group Id later of Old items
                if(mapOldRecordsByGeography != null && mapOldRecordsByGeography.size()>0 && Schema.sObjectType.Geography__c.isAccessible()){
                    for(Geography__c geography: [SELECT Id, D1_External_Group_Name__c, isDiageoOneEnabled__c FROM Geography__c WHERE Id IN: mapOldRecordsByGeography.keyset()]){
                        //Check if market is Diageo One Enabled or not bcoz we need to create sharing only for D1 Enabled Markets
                        if(geography.isDiageoOneEnabled__c){
                            mapGroupGeography.put(geography.D1_External_Group_Name__c, geography.Id);  
                        }
                        else{
                            mapOldRecordsByGeography.remove(geography.Id);
                        }
                    }                
                }            
                
                //Create a Mapping of Geography Id and Group Id that can be used later of old items
                if(mapGroupGeography != null && mapGroupGeography.size()>0 && Schema.sObjectType.Group.isAccessible()){
                    for(Group objGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: mapGroupGeography.keySet()]){
                        lstGroupId.add(objGroup.Id);
                    }                
                }
                
                //Get the existing share record from Share object and delete them. As UserOrGroupId can't be changed for share record.
                if(lstGroupId != null && lstGroupId.size()>0){
                    String objectName = recordId.getSobjectType().getDescribe().getName();
                    String standardObjectId = objectName+'Id';
                    String standardObjectAccessLevel = objectName+'AccessLevel';
                    String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
                    String strQuery;
                    if(!objectName.endsWith('__c')){//NCP-6401- standard objects dont have parent id and access level as fields so splitting into two methods
                        strQuery = 'SELECT Id,'+String.escapeSingleQuotes(standardObjectId)+' ,UserOrGroupId, RowCause, '+String.escapeSingleQuotes(standardObjectAccessLevel)+' FROM '+ String.escapeSingleQuotes(shareObjectName) + ' WHERE '+ String.escapeSingleQuotes(standardObjectId)+' IN :setObjectId AND RowCause =\'Manual\' AND UserOrGroupId IN :lstGroupId';
                    }
                    else{//custom object sharing
                        strQuery = 'SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM ' + String.escapeSingleQuotes(shareObjectName) + ' WHERE ParentId IN :setObjectId AND RowCause =\'Geography_Sharing__c\' AND UserOrGroupId IN :lstGroupId';
                    }                    
                    List<SObject> listData = Database.query(strQuery);
                    if(listData != null && listData.size()>0 && Schema.getGlobalDescribe().get(shareObjectName).getDescribe().isDeletable()){
                        Database.delete(listData);
                    }                
                }            
            }            
        } catch(Exception excption){
            new EDGE_GenericException(excption, newItems[0]);
        }        
    }
}