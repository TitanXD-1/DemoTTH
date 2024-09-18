/**

* @Description : EDGE_SharingUtil

* @Purpose : Utility class for providing sharing access 

* @History:

* @Version     Developer            Date            User Story	        

*  1.0       Preyanka Ghosh      10/05/2019        ES20-1614(Initial Development)
*  1.1       Aparajita			 27/12/2021		   ES20-11673(Method:createAndDeleteSharingRecords - Insertion)
*  1.2       Sukanya Chatterjee  28/12/2021        ES20-11674(Method:createAndDeleteSharingRecords - Deletion)
*  1.3       Prasanth T          27/12/2021        ES20-11675(Method:createAndDeleteSharingRecords - Deletion,getGeographyAgainstCode,getGeoIdFromCode)
*/

public without sharing class EDGE_SharingUtil {
    
    static String userPrefix = User.sObjectType.getDescribe().getKeyPrefix();
    
    /*
* @description: assignGroupMember
* @purpose : This class is used to create group member when a new group is created
* @parameters : String groupMember
**/
    @Future
    public static void assignGroupMember(String groupMember){
        if(String.isNotBlank(groupMember)){
            List<GroupMember> lstGroupMember = (List<GroupMember>)JSON.deserialize(groupMember, List<GroupMember>.class);
            Database.insert(lstGroupMember);
        }        
    }
    
    /*
* @description: getGeographyAgainstCode
* @purpose : This method is used to get geo Id against a geo code
* @parameters : List<SObject> lstSObject, String lookupField
**/
    public static Map<String,Id> getGeographyAgainstCode(List<SObject> lstSObject, String lookupField){
        Set<String> geoCodeSet = new Set<String>();
        List<String> geoCodeList = new List<String>();
        Map<String,Id> geoCodeToIdMap = new Map<String,Id>();
        
        if(lstSObject != null){
            for(SObject record: lstSObject){
                Id recordId = (Id) record.get('Id');
                String sObjectId = (String)recordId;
                if(sObjectId != null && sObjectId.startsWith(userPrefix) ){
                    String geoCode = (String)record.get(lookupField);
                    if(geoCode != null){
                        geoCodeList = geoCode.split(';');
                        geoCodeSet.addAll(geoCodeList);
                    }
                }
            }
        }
        
        if(geoCodeSet != null){
            for(Geography__c geoRec : [Select Id,Code__c from Geography__c where Code__c in :geoCodeSet]){
                geoCodeToIdMap.put(geoRec.Code__c, geoRec.Id);
            }
        }
        return geoCodeToIdMap;
    }
    
    /*
* @description: getGeoIdFromCode
* @purpose : This method is used to get geo record Id against a geo code like AU, GB etc.
* @parameters : SObject record, Id recordId, String lookupField, Map<String,Id> geoCodeToIdMap
**/
    public static Id getGeoIdFromCode(SObject record, Id recordId, String lookupField, Map<String,Id> geoCodeToIdMap){
        Id geographyId;
        String sObjectId = (String)recordId;
        if(!sObjectId.startsWith(userPrefix)){
            geographyId = (Id) record.get(lookupField);
        }else{//User object
            String geoCode = (String)record.get(lookupField);
            if(geoCodeToIdMap != null && geoCode != null){
                geographyId = geoCodeToIdMap.get(geoCode);
            }
        }
        return geographyId;
    }
    
    /*
* @description: generateSharingFromGeography
* @purpose : This method is used to create the sharing record based on the geography tagged with recod .
* @parameters : List<SObject> lstSObject, String lookupField, String accessDirection, String accessLevel
**/
    public static void generateSharingFromGeography(List<SObject> lstSObject, String lookupField, String accessDirection, String accessLevel){
        
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
                for(Geography__c geography: [SELECT Id, Sharing_Group_Name__c FROM Geography__c WHERE Id IN: mapRecordsByGeography.keyset()]){
                    mapGroupGeography.put(geography.Sharing_Group_Name__c + '_' + accessDirection, geography.Id);
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
                            if(objectName == 'Campaign'){
                                shareRecord.put('CampaignId', recordId);
                                shareRecord.put('UserOrGroupId', mapGeographyGroup.get(geographyId));
                                shareRecord.put('RowCause', 'Manual');
                                shareRecord.put('CampaignAccessLevel', accessLevel);
                            }else {
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
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, lstSObject[0]);
        }
        
    }
    
    /**
* @description  : updateSharingRecords
* @purpose : This method is used to delete the existing sharing when geography is changed and will call generateSharingFromGeography method to recreate sharing.
* @parameter : List<SObject> newItems, List<SObject> oldItems, String lookupField
*/
    public static void updateSharingRecords(List<SObject> newItems, List<SObject> oldItems, String lookupField){
        List<SObject> listOfSharesToUpdate = new List<SObject>();
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
                    for(Geography__c geography: [SELECT Id, Sharing_Group_Name__c FROM Geography__c WHERE Id IN: mapOldRecordsByGeography.keyset()]){
                        mapGroupGeography.put(geography.Sharing_Group_Name__c + '_Up', geography.Id);
                        mapGroupGeography.put(geography.Sharing_Group_Name__c + '_Down', geography.Id);
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
                    String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
                    String strQuery;
                    if(objectName == 'Campaign'){    
                        strQuery = 'SELECT Id, CampaignId, UserOrGroupId, RowCause, CampaignAccessLevel FROM ' + String.escapeSingleQuotes(shareObjectName) + ' WHERE CampaignId IN :setObjectId AND RowCause =\'Manual\' AND UserOrGroupId IN :lstGroupId';
                    }else{
                        strQuery = 'SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM ' + String.escapeSingleQuotes(shareObjectName) + ' WHERE ParentId IN :setObjectId AND RowCause =\'Geography_Sharing__c\' AND UserOrGroupId IN :lstGroupId';
                    }

                    List<SObject> listData = Database.query(strQuery);
                    
                    if(listData != null && listData.size()>0 && Schema.getGlobalDescribe().get(shareObjectName).getDescribe().isDeletable()){
                        Database.delete(listData);   
                        //generateSharingFromGeography(newItems, lookupField, accessDirection, accessLevel);
                    }                
                }            
            }            
        } catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, newItems[0]);
        }        
    }
    
    /**
* @description  : validateEditPermission
* @purpose : This will check whether the current user have access in the Record to Edit
* @parameters : List<SObject> newItems
*/
    public static void validateEditPermission(List<SObject> newItems){
        
        Map<Id,List<Id>> mapRecordsByGeography = new Map<Id,List<Id>>();
        Map<Id,Boolean> mapRecordAccess = new Map<Id,Boolean>();
        Set<Id> setParentId = new Set<Id>();        
        
        try{
            //Create a Map to get the mapping of Geography and Record Id
            for(SObject newRecord: newItems){
                Id recordId = (Id) newRecord.get('Id');
                setParentId.add(recordId);
                mapRecordAccess.put(recordId, FALSE);            
            }
            
            //Check from UserRecordAccess whether the current user has access or not
            if(!setParentId.isEmpty() && Schema.sObjectType.UserRecordAccess.isAccessible()){
                for(UserRecordAccess writeAccess: [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND RecordId IN :setParentId]){
                    mapRecordAccess.put(writeAccess.RecordId, writeAccess.HasEditAccess);
                }
                if(mapRecordAccess.values().contains(false)){
                    for(SObject newRecord: newItems){
                        Id parentId = (Id) newRecord.get('Id');
                        if(mapRecordAccess.containsKey(parentId) && mapRecordAccess.get(parentId) == FALSE){
                            newRecord.addError(Label.Edit_Access_Permission);                        
                        }                    
                    }
                }            
            }            
        } catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, newItems[0]);
        }
    }
    
    /**
* @method  : validateCreatePermission
* @purpose : This method is used to validate if the user has access in the Geography record selected in lookup field.
This method will be called from After Insert as well as from After Update if the Geography field changes.
* @parameters : List<SObject> newItems, String lookupField
*/
    public static void validateCreatePermission(List<SObject> newItems, String lookupField){
        Set<Id> setGeographyId = new Set<Id>();
        Set<String> setGroupName = new Set<String>();
        Set<Id> setGroupId = new Set<Id>();
        Id globalRecordId;
        Geography__c globalGeography;
        Map<Id,Set<string>> mapGeographyGroup=new Map<Id,Set<string>>();
        Map<Id,string> mapGroupIdName= new Map<Id,string>();
        Map<Id,Id> userGroupMap= new Map<Id,Id>();
        
        try{
            //Create a Map to get the mapping of Geography and Record Id
            for(SObject newRecord: newItems){
                Id geographyId = (Id) newRecord.get(lookupField);
                setGeographyId.add(geographyId);
            }
            
            //Get the group name from Sharing_Group_Name__c of Geography object, It will fetch all the sharing name of Country, Cluster, Hub and market level
            if(setGeographyId != null && setGeographyId.size()>0 && Schema.sObjectType.Geography__c.isAccessible()){
                String groupDown = EDGE_Constant.EDGE_GROUP_DOWN;
                globalRecordId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Global').getRecordTypeId();
                globalGeography = [SELECT ID FROM Geography__c WHERE RecordTypeId =:globalRecordId LIMIT 1];
                for(Geography__c existGeo : [SELECT ID, Sharing_Group_Name__c, Parent_Geography__c, Parent_Geography__r.Sharing_Group_Name__c, 
                                             Parent_Geography__r.Parent_Geography__c, Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c,
                                             Parent_Geography__r.Parent_Geography__r.Parent_Geography__c, Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c
                                             FROM Geography__c 
                                             WHERE Id IN :setGeographyId]
                   ){
                       set<string> temgroupName = new set<string>();
                       temgroupName.add(existGeo.Sharing_Group_Name__c+groupDown);
                       setGroupName.add(existGeo.Sharing_Group_Name__c+groupDown); 
                       if(existGeo.Parent_Geography__c != null && existGeo.Parent_Geography__c != globalGeography.Id && String.isNotBlank(existGeo.Parent_Geography__r.Sharing_Group_Name__c)){
                           setGroupName.add(existGeo.Parent_Geography__r.Sharing_Group_Name__c+groupDown);
                           temgroupName.add(existGeo.Parent_Geography__r.Sharing_Group_Name__c+groupDown);
                           if(existGeo.Parent_Geography__r.Parent_Geography__c != null && existGeo.Parent_Geography__r.Parent_Geography__c != globalGeography.Id && String.isNotBlank(existGeo.Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c)){
                               setGroupName.add(existGeo.Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c+groupDown);
                               temgroupName.add(existGeo.Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c+groupDown);
                               if(existGeo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c != null && existGeo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c != globalGeography.Id && String.isNotBlank(existGeo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c)){
                                   setGroupName.add(existGeo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c+groupDown);
                                   temgroupName.add(existGeo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Sharing_Group_Name__c+groupDown); 
                               }
                           }
                       }
                       mapGeographyGroup.put(existGeo.id,temgroupName);
                   }
                
                if(setGroupName != null && setGroupName.size()>0 && Schema.sObjectType.Group.isAccessible()){
                    //Get the Group Id from above created Set
                    for(Group objGroup : [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName IN :setGroupName]){
                        setGroupId.add(objGroup.Id);
                        mapGroupIdName.put(objGroup.id,objGroup.DeveloperName );
                    }
                    
                    //If the user is not a member of any down group then it will throw an error message
                    if(setGroupId != null && setGroupId.size()>0 && Schema.sObjectType.GroupMember.isAccessible() && Schema.sObjectType.Profile.isAccessible()){
                        String sysAdminId = Label.EDGE_System_Admin_Id;
                        Profile systemAdmin = [SELECT Id FROM Profile WHERE Id =:sysAdminId LIMIT 1];
                        List<GroupMember> lstgroupMember = [SELECT Id, groupid, UserOrGroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId() AND GroupId IN :setGroupId];
                        
                        if( UserInfo.getProfileId() != systemAdmin.Id){
                            for(GroupMember member : lstgroupMember ){
                                userGroupMap.put(member.UserOrGroupId, member.groupId);
                            }
                            
                            for(SObject newRecord: newItems){
                                Set<string> relatedGroupName = mapGeographyGroup.get((Id) newRecord.get(lookupField));
                                Id lastModifiedById= (Id)newRecord.get('LastModifiedById');
                                
                                if(userGroupMap.get(lastModifiedById)==null || (userGroupMap.get(lastModifiedById)!=null && !relatedGroupName.contains(mapGroupIdName.get(userGroupMap.get(lastModifiedById))))){
                                    newRecord.addError(Label.Geography_Access_Message);
                                }    
                            }
                        }
                    }
                }
            }
        }catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, newItems[0]);
        }
    }
    
    /**
* @description  : createUpdateGeographyShare
* @purpose : create/update geography sharing records
* @parameters : Map<Id, Geography__c> newItems, List<Group> lstGroup
*/
    public static void createUpdateGeographyShare(Map<Id, Geography__c> newItems, List<Group> lstGroup){
        String groupUp = EDGE_Constant.EDGE_GROUP_UP;
        String groupDown = EDGE_Constant.EDGE_GROUP_DOWN;
        Geography__share shareRecord;
        List<Geography__share> listOfSharesToInsert = new List<Geography__share>();
        Map<String,List<String>> mapParentGroupId = new Map<String,List<String>>();
        List<Id> lstGeographyId = new List<Id>();
        List<String> lstGroupName = new List<String>();
        if(lstGroup == null || (lstGroup != null && lstGroup.size()<1)){
            for(Geography__c geography : newItems.values()){
                lstGeographyId.add(geography.Parent_Geography__c);
            }
            
            if(lstGeographyId != null && lstGeographyId.size()>0){
                for(Geography__share geographyShare :[SELECT Id, UserorGroupId,ParentId FROM Geography__share WHERE ParentId IN :lstGeographyId AND AccessLevel != 'All' AND RowCause='Geography_Sharing__c']){
                    lstGroupName.add(geographyShare.UserorGroupId);                    
                    if(mapParentGroupId.containskey(geographyShare.ParentId)){
                        mapParentGroupId.get(geographyShare.ParentId).add(geographyShare.UserorGroupId);
                    } else {
                        mapParentGroupId.put(geographyShare.ParentId, new List<String>{geographyShare.UserorGroupId});
                    }
                }
                
                if(lstGroupName != null && lstGroupName.size()>0){
                    lstGroup = [SELECT Id,DeveloperName FROM Group WHERE Id IN :lstGroupName];
                }
            }
        }
        
        if(newItems != null && newItems.size()>0){
            for(Geography__c newGeography : newItems.values()){
                for(Group newGroup:lstGroup){
                    if(newGroup.DeveloperName.containsIgnoreCase('Up') && !(newGeography.Sharing_Group_Name__c).containsIgnoreCase('Global') &&
                       (newGroup.DeveloperName.contains(newGeography.Sharing_Group_Name__c+groupUp) || 
                        (mapParentGroupId != null && mapParentGroupId.size()>0 && mapParentGroupId.containskey(newGeography.Parent_Geography__c) && mapParentGroupId.get(newGeography.Parent_Geography__c).contains(newGroup.Id))
                       )){
                           shareRecord = new Geography__share();
                           shareRecord.ParentId = newGeography.Id;
                           shareRecord.UserOrGroupId = newGroup.Id;
                           shareRecord.RowCause = 'Geography_Sharing__c';
                           shareRecord.AccessLevel = 'Read';
                           listOfSharesToInsert.add(shareRecord);
                       } else if(newGroup.DeveloperName.containsIgnoreCase('Down') && !(newGeography.Sharing_Group_Name__c).containsIgnoreCase('Global') && 
                                 (newGroup.DeveloperName.contains(newGeography.Sharing_Group_Name__c+groupDown) || 
                                  (mapParentGroupId != null && mapParentGroupId.size()>0 && mapParentGroupId.containskey(newGeography.Parent_Geography__c) && mapParentGroupId.get(newGeography.Parent_Geography__c).contains(newGroup.Id))
                                 )){
                                     shareRecord = new Geography__share();
                                     shareRecord.ParentId = newGeography.Id;
                                     shareRecord.UserOrGroupId = newGroup.Id;
                                     shareRecord.RowCause = 'Geography_Sharing__c';
                                     shareRecord.AccessLevel = 'Edit';
                                     listOfSharesToInsert.add(shareRecord);
                                 }
                }
            }                
        }            
        
        if(listOfSharesToInsert != null && listOfSharesToInsert.size()>0 && Schema.sObjectType.Geography__share.isCreateable()){
            Database.insert(listOfSharesToInsert);
        }        
    }
    
    /*
* @description  : insertProductSharing
* @purpose : Insert product sharing records based on insert/update of Market Assortment Products
* @parameters : List<Market_Assortment_Product__c> newItems
**/
    public static void insertProductSharing(List<Market_Assortment_Product__c> newItems){
        Map<Id,Id> marketAssProductMap = new Map<Id,Id>();
        List<Product__Share> listOfProdSharesToInsert = new List<Product__Share>();
        
        try{
            if(newItems != null && newItems.size()>0){
                for(Market_Assortment_Product__c mapObj :newItems){
                    marketAssProductMap.put(mapObj.Id,mapObj.Product__c);
                }
                
                for(Market_Assortment_Product__Share mapsRecord :[SELECT id, ParentId, UserOrGroupId,RowCause, AccessLevel from Market_Assortment_Product__Share where ParentId IN :marketAssProductMap.keySet() and AccessLevel != 'All' and RowCause =  'Geography_Sharing__c']){
                    
                    if(marketAssProductMap.get(mapsRecord.ParentId) != null){
                        Product__Share prodShareRecord = new Product__Share();
                        prodShareRecord.ParentId =  marketAssProductMap.get(mapsRecord.ParentId);
                        prodShareRecord.UserOrGroupId =  mapsRecord.UserOrGroupId;
                        prodShareRecord.RowCause =  'Geography_Sharing__c';
                        prodShareRecord.AccessLevel =  mapsRecord.AccessLevel;
                        listOfProdSharesToInsert.add(prodShareRecord); 
                    }
                }
                if(listOfProdSharesToInsert != null && listOfProdSharesToInsert.size()>0 && Schema.sObjectType.Product__Share.isCreateable()){
                    insert listOfProdSharesToInsert;
                } 
            }
        }catch(Exception ex){
            System.debug('Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            new EDGE_GenericException(ex, newItems[0]);
        }   
    }
    
    /*
* @description  : deleteProductSharing
* @purpose : Delete product sharing records based on delete/update of Market Assortment Products
* @parameters : List<Market_Assortment_Product__c> oldItems
**/
    public static void deleteProductSharing(List<Market_Assortment_Product__c> oldItems){
        Map<Id,Id> marketAssProductMap = new Map<Id,Id>();
        List<Product__Share> listOfProdSharesToDelete = new List<Product__Share>();
        Map<String,Id> mapGroupGeography = new Map<String,Id>();
        Set<Id> geographyIdSet = new Set<Id>();    
        Set<Id> groupIdSet = new Set<Id>();
        try{
            if(oldItems != null && oldItems.size()>0 && Schema.sObjectType.Product__Share.isAccessible()){  
                for(Market_Assortment_Product__c mapObj :oldItems){
                    marketAssProductMap.put(mapObj.Id,mapObj.Product__c);
                    geographyIdSet.add(mapObj.Market_Assortment__c);
                }
                
                for(Market_Assortment_Product__Share mapsRecord :[SELECT id, ParentId, UserOrGroupId,RowCause, AccessLevel from Market_Assortment_Product__Share where ParentId IN :marketAssProductMap.keySet() and RowCause =  'Geography_Sharing__c']){
                    groupIdSet.add(mapsRecord.UserOrGroupId);
                }
               
                listOfProdSharesToDelete= [Select Id, ParentId, UserOrGroupId,RowCause, AccessLevel  from Product__Share where ParentId IN :marketAssProductMap.values() and UserOrGroupId IN :groupIdSet and RowCause =  'Geography_Sharing__c'];
                if(listOfProdSharesToDelete != null && listOfProdSharesToDelete.size()>0 && Schema.sObjectType.Product__Share.isDeletable()){
                    delete listOfProdSharesToDelete;
                } 
            }
        }catch(Exception ex){
            System.debug('Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            new EDGE_GenericException(ex, oldItems[0]);
        }   
    }
    
    /**
* @description ; createSharingRecords -> ES20-11673
* @purpose : This method is used to insert user-share records to enable sharing for users based on their geography settings
* @parameter : Map<Id,Set<Geography__c>> userGeoMap, String dmlOperation
*/
    public static void createAndDeleteSharingRecords(Map<Id,Set<Geography__c>> userGeoMap, String dmlOperation){
        
        String accessDirectionUp = 'Up';
        String accessDirectionDown = 'Down';
        
        //Assignment
        Map<String,Id> geoIdVsGeoGroupMap = new Map<String,Id>();
        Map<String,Id> geoGroupVsGeoIdMap = new Map<String,Id>();
        List<SObject> listOfSharesToInsert = new List<SObject>();
        List<SObject> listOfSharesToDelete = new List<SObject>();  
        List<UserShare> deleteUserShareList = new List<UserShare>();
        List<Id> groupIdList = new List<Id>();
        Set<String> userGeoSet = new Set<String>();
        Set<Id> userIdSet = new Set<Id>();
        Schema.SObjectType shareType;
        
        if(userGeoMap != null){
            for(Id userId : userGeoMap.keySet()){
                for(Geography__c geo : userGeoMap.get(userId)){
                    geoGroupVsGeoIdMap.put(geo.Sharing_Group_Name__c + '_' + accessDirectionUp, geo.Id);
                    geoGroupVsGeoIdMap.put(geo.Sharing_Group_Name__c + '_' + accessDirectionDown, geo.Id);
                    userGeoSet.add(userId + ';' + geo.Id + ';' + geo.Sharing_Group_Name__c + '_' + accessDirectionUp);
                    userGeoSet.add(userId + ';' + geo.Id + ';' + geo.Sharing_Group_Name__c + '_' + accessDirectionDown);
                    userIdSet.add(userId);
                }
            }
        }
        
        try{
            //INSERTION
            //Create a mapping of Geography Id and Group Id 
            if(geoGroupVsGeoIdMap != null && geoGroupVsGeoIdMap.size()>0 && Schema.sObjectType.Group.isAccessible()){
                for(Group objGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: geoGroupVsGeoIdMap.keySet()]){
                    geoIdVsGeoGroupMap.put(objGroup.DeveloperName, objGroup.Id);
                }            
            }
            
            if(dmlOperation!=null && dmlOperation.equals('Insert')){
                if(userGeoSet!=null && userGeoSet.size()>0){
                    for(String userGeoValue : userGeoSet){
                        Id userId = userGeoValue.split(';').get(0);
                        Id geoId = userGeoValue.split(';').get(1);
                        String sharingGrpName = userGeoValue.split(';').get(2);
                        String sObjectId = (String)userId;
                        if(sObjectId.startsWith(userPrefix)){
                            String shareObjectName = 'UserShare';
                            shareType = Schema.getGlobalDescribe().get(shareObjectName);
                            SObject shareRecord = shareType.newSObject();
                            shareRecord.put('UserId', userId);
                            shareRecord.put('UserAccessLevel', 'Read');
                            shareRecord.put('RowCause', 'Manual');
                            shareRecord.put('UserOrGroupId', geoIdVsGeoGroupMap.get(sharingGrpName));
                            listOfSharesToInsert.add(shareRecord); 
                        }         
                    }
                }
                
                //Inserting usershare records    
                if(listOfSharesToInsert != null && listOfSharesToInsert.size()>0 && shareType.getDescribe().isCreateable()){
                    Database.insert(listOfSharesToInsert);
                }
            }
            
            //DELETION
            if(dmlOperation!=null && dmlOperation.equals('Delete')){
                groupIdList = geoIdVsGeoGroupMap.values();
                String strQuery = 'SELECT Id, UserId, UserOrGroupId, RowCause, UserAccessLevel FROM UserShare WHERE UserId IN :userIdSet AND RowCause =\'Manual\' AND UserOrGroupId IN :groupIdList';
                if(userIdSet != null && groupIdList != null){
                    listOfSharesToDelete = Database.query(strQuery);     
                }                
                //Deleting user-share records
                if(listOfSharesToDelete != null && listOfSharesToDelete.size()>0 && Schema.getGlobalDescribe().get('UserShare').getDescribe().isDeletable()){
                    Database.delete(listOfSharesToDelete);   
                }
            }
            
        }catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
        }     
    }
}