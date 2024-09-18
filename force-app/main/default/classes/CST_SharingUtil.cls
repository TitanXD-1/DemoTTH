/*
* Class Name : CST_SharingUtil
* @description: Custom Sharing - Sharing Util Class for CST
* @history
* VERSION    AUTHOR                DATE              DETAIL
* 1.0        Sayan Mullick 			25/11/2021        Initial Development
*/
public without sharing class CST_SharingUtil {
    
    /*
	* @description : generateSharingFromSalesOrg
	* @return : void
	* @param : List<SObject> lstSObject, String lookupField, String accessLevel
	*/
    public static void generateSharingFromSalesOrg(List<SObject> lstSObject, String lookupField, String accessLevel){        
        Map<Id,List<Id>> mapRecordsBySalesOrg = new Map<Id,List<Id>>();
        Map<Id,String> mapSalesOrgGroup = new Map<Id,String>();
        Map<String,Id> mapGroupSalesOrg = new Map<String,Id>();
        List<SObject> listOfSharesToInsert = new List<SObject>();
        Schema.SObjectType shareType;
        
        try{
            //Create a Map to get the mapping of SalesOrg and Record Id
            for(SObject record: lstSObject){
                Id salesOrg = (Id) record.get(lookupField);
                Id recordId = (Id) record.get('Id');
                if(salesOrg != null){
                    if(mapRecordsBySalesOrg.containsKey(salesOrg)){
                        mapRecordsBySalesOrg.get(salesOrg).add(recordId);                    
                    } else {
                        mapRecordsBySalesOrg.put(salesOrg, new List<Id>{recordId});
                    }                
                }
            }
            System.debug('mapRecordsBySalesOrg::'+mapRecordsBySalesOrg);
            
            //Create a Map to get the Sharing_Group_Name__c which can be used to get the Group Id later
            if(mapRecordsBySalesOrg != null && mapRecordsBySalesOrg.size()>0 && Schema.sObjectType.Sales_Organisation__c.isAccessible()){
                for(Sales_Organisation__c salesOrg: [SELECT Id, Code__c FROM Sales_Organisation__c WHERE Id IN: mapRecordsBySalesOrg.keyset()]){
                    if(accessLevel.equals('Read'))
                    	mapGroupSalesOrg.put('SO_'+salesOrg.Code__c+'_Read', salesOrg.Id);
                    else
                    mapGroupSalesOrg.put('SO_'+salesOrg.Code__c+'_Write', salesOrg.Id);
                }            
            }
            System.debug('mapGroupSalesOrg::'+mapGroupSalesOrg);            
            //Create a Mapping of Sales Org Id and Group Id that can be used later
            if(mapGroupSalesOrg != null && mapGroupSalesOrg.size()>0 && Schema.sObjectType.Group.isAccessible()){
                for(Group objGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: mapGroupSalesOrg.keySet()]){
                    mapSalesOrgGroup.put(mapGroupSalesOrg.get(objGroup.DeveloperName), objGroup.Id);
                }            
            }
            System.debug('mapSalesOrgGroup::'+mapSalesOrgGroup);            
            //Used to create the list of Share record per Share Object
            if(mapSalesOrgGroup != null && mapSalesOrgGroup.size()>0){
                for(Id salesOrgId : mapRecordsBySalesOrg.keySet()){
                    if(mapSalesOrgGroup.containsKey(salesOrgId)){
                        for(Id recordId: mapRecordsBySalesOrg.get(salesOrgId)){
                            String objectName = recordId.getSobjectType().getDescribe().getName();
                            String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
                            shareType = Schema.getGlobalDescribe().get(shareObjectName);
                            SObject shareRecord = shareType.newSObject();
                            if(shareObjectName.equals('AccountShare')){
                                shareRecord.put('AccountId', recordId);
                            	shareRecord.put('UserOrGroupId', mapSalesOrgGroup.get(salesOrgId));
                            	shareRecord.put('RowCause', 'Manual');
                                shareRecord.put('OpportunityAccessLevel', 'None');
                                shareRecord.put('CaseAccessLevel', 'None');
                                shareRecord.put('ContactAccessLevel', 'None');
                            	shareRecord.put('AccountAccessLevel', accessLevel);
                            	listOfSharesToInsert.add(shareRecord);
                            }
                            else
                            {
                                shareRecord.put('ParentId', recordId);
                            	shareRecord.put('UserOrGroupId', mapSalesOrgGroup.get(salesOrgId));
                            	shareRecord.put('RowCause', 'Sales_Org_Sharing__c');
                            	shareRecord.put('AccessLevel', accessLevel);
                            	listOfSharesToInsert.add(shareRecord);
                            }                            
                        }
                    }
                } 
                
                if(listOfSharesToInsert != null && listOfSharesToInsert.size()>0 && shareType.getDescribe().isCreateable()){
                    insert listOfSharesToInsert;
                }
            }
            System.debug('listOfSharesToInsert::'+listOfSharesToInsert);
            
        } catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, lstSObject[0]);
        }
        
    }

    /*
	* @description : daleteSharingRecords
	* @return : void
	* @param : List<SObject> newItems, List<SObject> oldItems, String lookupField
	*/
    
    public static void deleteSharingRecords(List<SObject> newItems, List<SObject> oldItems, String lookupField){
        List<SObject> listOfSharesToUpdate = new List<SObject>();
        Map<Id,List<Id>> mapOldRecordsBySalesOrg = new Map<Id,List<Id>>();
        Map<String,Id> mapGroupSalesOrg = new Map<String,Id>();
        Set<Id> setObjectId = new Set<Id>();
        List<Id> lstGroupId = new List<Id>();
        Id recordId;        
        try{
            if(oldItems != null && oldItems.size()>0){
                //Create a Map to get the mapping of Sales org and Record Id of Old Items
                for(SObject oldRecord: oldItems){
                    Id salesOrgId = (Id) oldRecord.get(lookupField);
                    recordId = (Id) oldRecord.get('Id');
                    setObjectId.add(recordId);
                    if(salesOrgId != null){
                        if(mapOldRecordsBySalesOrg.containsKey(salesOrgId)){
                            mapOldRecordsBySalesOrg.get(salesOrgId).add(recordId);                    
                        } else {
                            mapOldRecordsBySalesOrg.put(salesOrgId, new List<Id>{recordId});
                        }                
                    }
                }                
                //Create a Map to get the Sharing_Group_Name__c which can be used to get the Group Id later of Old items
                if(mapOldRecordsBySalesOrg != null && mapOldRecordsBySalesOrg.size()>0 && Schema.sObjectType.Sales_Organisation__c.isAccessible()){
                    for(Sales_Organisation__c salesOrg: [SELECT Id, Code__c FROM Sales_Organisation__c WHERE Id IN: mapOldRecordsBySalesOrg.keyset()]){
                        mapGroupSalesOrg.put('SO_'+salesOrg.Code__c+'_Read', salesOrg.Id);
                        mapGroupSalesOrg.put('SO_'+salesOrg.Code__c+'_Write', salesOrg.Id);
                    }                
                }                            
                //Create a Mapping of Sales Org Id and Group Id that can be used later of old items
                if(mapGroupSalesOrg != null && mapGroupSalesOrg.size()>0 && Schema.sObjectType.Group.isAccessible()){
                    for(Group objGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: mapGroupSalesOrg.keySet()]){
                        lstGroupId.add(objGroup.Id);
                    }                
                }                
                //Get the existing share record from Share object and delete them. As UserOrGroupId can't be changed for share record.
                if(lstGroupId != null && lstGroupId.size()>0){
                    String strQuery='';
                    String objectName = recordId.getSobjectType().getDescribe().getName();
                    String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
                    if(shareObjectName.equals('AccountShare'))
                        strQuery = 'SELECT Id, AccountId, UserOrGroupId, RowCause, AccountAccessLevel FROM ' + String.escapeSingleQuotes(shareObjectName) + ' WHERE AccountId IN :setObjectId AND RowCause =\'Manual\' AND UserOrGroupId IN :lstGroupId';
                    else
                        strQuery = 'SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM ' + String.escapeSingleQuotes(shareObjectName) + ' WHERE ParentId IN :setObjectId AND RowCause =\'Sales_Org_Sharing__c\' AND UserOrGroupId IN :lstGroupId';

                    List<SObject> listData = Database.query(strQuery);                   
                    if(listData != null && listData.size()>0 && Schema.getGlobalDescribe().get(shareObjectName).getDescribe().isDeletable()){
                        Database.delete(listData);   
                    }                
                }            
            }            
        } catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, newItems[0]);
        }        
    }
    
	/*
	* @description : validateCreatePermission
	* @return : void
	* @param : List<SObject> newItems, List<SObject> oldItems, String lookupField
	*/
    public static void validateCreatePermission(List<SObject> newItems, String lookupField){
        Set<Id> setSalesOrgId = new Set<Id>();
        Set<String> setGroupName = new Set<String>();
        Set<Id> setGroupId = new Set<Id>();
        Map<String,string> mapSalesOrgGroup=new Map<String,string>();
        Map<String,string> mapGroupIdName= new Map<String,string>();
        Map<String,String> userGroupMap= new Map<String,String>();       
        try{
            //Create a Map to get the mapping of Sales Organisation and Record Id
            for(SObject newRecord: newItems){
                Id salesOrgId = (Id) newRecord.get(lookupField);
                setSalesOrgId.add(salesOrgId);
            }
            System.debug('setSalesOrgId:::'+setSalesOrgId);                       
            if(setSalesOrgId != null && setSalesOrgId.size()>0 && Schema.sObjectType.Sales_Organisation__c.isAccessible()){
                String groupDown = EDGE_Constant.EDGE_GROUP_DOWN;
                //globalRecordId = Schema.SObjectType.Sales_Organisation__c.getRecordTypeInfosByName().get('Global').getRecordTypeId();
                //globalGeography = [SELECT ID FROM Geography__c WHERE RecordTypeId =:globalRecordId LIMIT 1];
                for(Sales_Organisation__c salesOrg : [SELECT ID, Code__c FROM Sales_Organisation__c 
                                             							WHERE Id IN :setSalesOrgId]
                   ){
                       Set<string> temgroupName = new Set<string>();
                       temgroupName.add('SO_'+salesOrg.Code__c+'_Read');
                       setGroupName.add('SO_'+salesOrg.Code__c+'_Read');                       
                       mapSalesOrgGroup.put(salesOrg.id,'SO_'+salesOrg.Code__c+'_Read');
                   }
                System.debug('setGroupName:::'+setGroupName);
                System.debug('mapSalesOrgGroup:::'+mapSalesOrgGroup);
                
                if(setGroupName != null && setGroupName.size()>0 && Schema.sObjectType.Group.isAccessible()){
                    //Get the Group Id from above created Set
                    for(Group objGroup : [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName IN :setGroupName]){
                        setGroupId.add(objGroup.Id);
                        mapGroupIdName.put(objGroup.DeveloperName,objGroup.id);
                    }
                    
                    System.debug('setGroupId:::'+setGroupId);
                    System.debug('mapGroupIdName:::'+mapGroupIdName);
                    
                    //If the user is not a member of any down group then it will throw an error message
                    if(setGroupId != null && setGroupId.size()>0 && Schema.sObjectType.GroupMember.isAccessible() && Schema.sObjectType.Profile.isAccessible()){

                        String sysAdminId = Label.CST_System_Admin_Id;

						List<String> sysAdminIdList=new List<String>();
						sysAdminIdList= sysAdminId != '' ?sysAdminId.split(','):null;
                        List<Profile> systemAdmin = [SELECT Id FROM Profile WHERE Id =:sysAdminIdList];
                        List<GroupMember> lstgroupMember = [SELECT Id, groupid, UserOrGroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId() AND GroupId IN :setGroupId];
                        System.debug('lstgroupMember:::'+lstgroupMember);
                        String profileId = UserInfo.getProfileId();
                        System.debug('lstgroupMember:::'+profileId);
                        if(!sysAdminIdList.contains(profileId.substring(0,15))){
                            for(GroupMember member : lstgroupMember ){
                                userGroupMap.put(member.groupId,member.UserOrGroupId);
                            }
                             System.debug('userGroupMap:::'+userGroupMap);
                            for(SObject newRecord: newItems){
                                String relatedSalesOrgId = (String) newRecord.get(lookupField);
								String groupId = mapSalesOrgGroup.containsKey(relatedSalesOrgId)?mapGroupIdName.get(mapSalesOrgGroup.get(relatedSalesOrgId)):'';
                                if(!userGroupMap.containsKey(groupId)){									
									system.debug('@@@@@TRUE@@@');
                                    newRecord.addError(Label.Sales_Organisation_Access_Message);									
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
    /*******************************************************************
    Method  : validateEditPermission
    Purpose : This will check whether the current user have access in the Record to Edit
    ********************************************************************/
    public static void validateEditPermission(List<SObject> newItems){
        
        Map<Id,Boolean> mapRecordAccess = new Map<Id,Boolean>();
        Set<Id> setParentId = new Set<Id>();                
        try{
            //Create a Map to get the mapping of SalesOrganisation and Record Id
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
    /*******************************************************************
    Method  : updateSharingRecords
    Purpose : This method is used to delete the existing sharing when geography is changed and 
                will call generateSharingFromSalesOrganisation method to recreate sharing.
    ********************************************************************/
    public static void updateSharingRecords(List<SObject> newItems, List<SObject> oldItems, String lookupField){
        List<SObject> listOfSharesToUpdate = new List<SObject>();
        Map<Id,List<Id>> mapOldRecordsBysalesOrg = new Map<Id,List<Id>>();
        Map<String,Id> mapGroupSalesOrg = new Map<String,Id>();
        Set<Id> setObjectId = new Set<Id>();
        List<Id> lstGroupId = new List<Id>();
        Id recordId;        
        try{
            if(oldItems != null && oldItems.size()>0){
                //Create a Map to get the mapping of SalesOrganisation and Record Id of Old Items
                for(SObject oldRecord: oldItems){
                    Id salesOrg = (Id) oldRecord.get(lookupField);
                    recordId = (Id) oldRecord.get('Id');
                    setObjectId.add(recordId);
                    if(salesOrg != null){
                        if(mapOldRecordsBysalesOrg.containsKey(salesOrg)){
                            mapOldRecordsBysalesOrg.get(salesOrg).add(recordId);                    
                        } else {
                            mapOldRecordsBysalesOrg.put(salesOrg, new List<Id>{recordId});
                        }                
                    }
                }
                
                //Create a Map to get the Sharing_Group_Name__c which can be used to get the Group Id later of Old items
                if(mapOldRecordsBysalesOrg != null && mapOldRecordsBysalesOrg.size()>0 && Schema.sObjectType.Sales_Organisation__c.isAccessible()){
                    for(Sales_Organisation__c salesOrg: [SELECT Id, Code__c FROM Sales_Organisation__c WHERE Id IN: mapOldRecordsBysalesOrg.keyset()]){
                        mapGroupSalesOrg.put('SO_'+salesOrg.Code__c+'_Read', salesOrg.Id);
                        mapGroupSalesOrg.put('SO_'+salesOrg.Code__c+'_Write', salesOrg.Id);
                    }                
                }            
                
                //Create a Mapping of Sales Organisation Id and Group Id that can be used later of old items
                if(mapGroupSalesOrg != null && mapGroupSalesOrg.size()>0 && Schema.sObjectType.Group.isAccessible()){
                    for(Group objGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: mapGroupSalesOrg.keySet()]){
                        lstGroupId.add(objGroup.Id);
                    }                
                }
                
                //Get the existing share record from Share object and delete them. As UserOrGroupId can't be changed for share record.
                if(lstGroupId != null && lstGroupId.size()>0){
                    String strQuery='';
                    String objectName = recordId.getSobjectType().getDescribe().getName();
                    String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
                    if(shareObjectName.equals('AccountShare'))
                        strQuery = 'SELECT Id, AccountId, UserOrGroupId, RowCause, AccountAccessLevel FROM ' + String.escapeSingleQuotes(shareObjectName) + ' WHERE AccountId IN :setObjectId AND RowCause =\'Manual\' AND UserOrGroupId IN :lstGroupId';
                    else
                        strQuery = 'SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM ' + String.escapeSingleQuotes(shareObjectName) + ' WHERE ParentId IN :setObjectId AND RowCause =\'Sales_Org_Sharing__c\' AND UserOrGroupId IN :lstGroupId';

                    List<SObject> listData = Database.query(strQuery);                    
                    if(listData != null && listData.size()>0 && Schema.getGlobalDescribe().get(shareObjectName).getDescribe().isDeletable()){
                        Database.delete(listData);
                    }                
                }            
            }            
        } catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, newItems[0]);
        }        
    }
	/*******************************************************************
    Method  : populatelookup
    Purpose : This will check whether the current user have access in the Record to Edit
    ********************************************************************/
  	public static void updateSalesOrganization(List<SObject> newItems, List<SObject> oldItems, String salesOrgField)
  	{
      	Set<String> setSalesOrgName = new Set<String>();
      	Map<String, Id> salesOrgNameIdMap = new Map<String, Id>();        
        String queryFilter = 'Code__c';
        String queryString = '';
            //Create a Map to get the mapping of Sales Organisation and Record Id            
            for(SObject newRecord: newItems){

            if(salesOrgField !=null  && newRecord.get(salesOrgField) != null)
            {

                    String salesOrgName = (String) newRecord.get(salesOrgField);
                	setSalesOrgName.add(salesOrgName);
                }                
            }
        
        if(newItems.size()>0){
            Schema.SObjectType ObjectType= newItems[0].getSObjectType();
            String objectName=ObjectType.getDescribe().getName();
            if(objectName.equals('ECM_Internal_Order__c')){
                queryFilter = 'Company_Code__c';
            }
            else{
                queryFilter = 'Code__c';
            } 
        }
        queryString = 'SELECT Id, Company_Code__c, Code__c FROM Sales_Organisation__c WHERE '+queryFilter+' IN :setSalesOrgName' ;
      	if(setSalesOrgName.size()>0 && setSalesOrgName!=null && Schema.sObjectType.Sales_Organisation__c.isAccessible()){
            for(Sales_Organisation__c so : Database.query(queryString)){
                if(queryFilter == 'Company_Code__c' )
                    salesOrgNameIdMap.put(so.Company_Code__c, so.Id);
                else
                    salesOrgNameIdMap.put(so.Code__c, so.Id);  
             }
         }
         if(salesOrgNameIdMap != null && salesOrgNameIdMap.size()>0){
             for(sObject newRecords : newItems){
                 String salesOrg= (String)newRecords.get(salesOrgField);
                 if(salesOrgNameIdMap.containsKey(salesOrg)){                            
                 	 Id salesOrgId= salesOrgNameIdMap.get(salesOrg);
                     Schema.SObjectType ObjectType= newRecords.getSObjectType();
                     String objectName=ObjectType.getDescribe().getName();
                    if(objectName.equals('Account')){
                         Account acc = (Account)newRecords;
                         acc.Sales_Organisation__c= salesOrgId;
                     }
                    else if(objectName.equals('Approver_Matrix__c')){
                         Approver_Matrix__c appMatrix = (Approver_Matrix__c)newRecords;
                         appMatrix.CST_Sales_Organisation__c= salesOrgId;
                     }
                    else if(objectName.equals('ECM_Internal_Order__c')){
                        ECM_Internal_Order__c internalOrder = (ECM_Internal_Order__c)newRecords;
                        internalOrder.Sales_Organisation__c= salesOrgId;
                    }

         		}
         	}
      	}
     }
}