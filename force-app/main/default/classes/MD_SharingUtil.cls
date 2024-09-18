/**************************************************************************************
Apex Class Name  :  MD_SharingUtil
Version          :  1.0  
Created Date     :  18/12/2018
Release          :  R1
Function         :  Utils class for Sharing
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------                 
* Elena Schwarzböck          18/12/2018              Original Version
******************************************************************************/
public class MD_SharingUtil{

    /* 
    * @Author      :    Elena Schwarzböck   
    * @description :    Creates sharing records for the list of records and the groups related to the cluster
    * @returns     :    void
    */
	public static List<SObject> generateSharingForRecordsOnCluster(List<SObject> records, String lookupField){
        String nameObjectShare;
        Boolean isCluster;
        if(! records.isEmpty()){
            String objectName = records.get(0).Id.getSobjectType().getDescribe().getName();
            nameObjectShare = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
            isCluster = nameObjectShare == 'DiageoCMS__Cluster__c';
        }        
        DiageoCMS.SharingUtils.SharingWrapper wrapper = DiageoCMS.SharingUtils.generateSharingForRecordsOnCluster(records, lookupField, nameObjectShare, 'ClusterSharing__c', isCluster);
        return wrapper.listOfSharesToInsert;
		/*
        Map<Id,List<Id>> mapRecordsByCluster = new Map<Id,List<Id>>();

        for(SObject record: records){
            Id clusterId = (Id) record.get(lookupField);
            Id recordId = (Id) record.get('Id');
            if(!mapRecordsByCluster.containsKey(clusterId)){
            	mapRecordsByCluster.put(clusterId, new List<Id>{recordId});
        	}else{
                mapRecordsByCluster.get(clusterId).add(recordId);
        	}
        }
    
        Map<Id,DiageoCMS__Cluster__c> mapClusters = new Map<Id,DiageoCMS__Cluster__c>([SELECT Id, DiageoCMS__PublicGroupRWName__c, DiageoCMS__PublicGroupROUpName__c, DiageoCMS__PublicGroupRODownName__c FROM DiageoCMS__Cluster__c WHERE Id IN: mapRecordsByCluster.keyset()]); 
        Map<String,String> fieldNamesAndSecLevel = new Map<String,String>{'PublicGroupRW__c' => 'Edit', 'PublicGroupROU__c' => 'Read', 'PublicGroupROD__c' => 'Read'};
        
        List<SObject> listOfSharesToInsert = new List<SObject>();
        for(Id clusterId : mapRecordsByCluster.keySet()){
            if(mapClusters.containsKey(clusterId)){
                for(Id recordId: mapRecordsByCluster.get(clusterId)){
                	for(String fieldName: fieldNamesAndSecLevel.keySet()){
                		if(String.isNotBlank((String) mapClusters.get(clusterId).get(fieldName))){
		                	String objectName = recordId.getSobjectType().getDescribe().getName();
		                	String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
		                	Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
		                    SObject shareRecord = shareType.newSObject();
		                    shareRecord.put('ParentId', recordId);
		                    shareRecord.put('UserOrGroupId', mapClusters.get(clusterId).get(fieldName));
		                    shareRecord.put('RowCause', 'ClusterSharing__c');
		                    shareRecord.put('AccessLevel', fieldNamesAndSecLevel.get(fieldName));
		                    listOfSharesToInsert.add(shareRecord);
	                    }
                    }
                }
            }
        }
        return listOfSharesToInsert;
        */
    }

    public static List<SObject> removeSharingForRecords(String lookupField){
        Set<Id> odlClusterIds = new Set<Id>();
        for(SObject record: (List<SObject>)Trigger.new){
            SObject oldRecord = (SObject) Trigger.oldMap.get(record.Id);
            if(record.get(lookupField) != oldRecord.get(lookupField)){
                odlClusterIds.add((Id) oldRecord.get(lookupField));
            }
        }
        Map<Id,DiageoCMS__Cluster__c> mapClusters = new Map<Id,DiageoCMS__Cluster__c>([SELECT Id, DiageoCMS__PublicGroupRWName__c, DiageoCMS__PublicGroupROUpName__c, DiageoCMS__PublicGroupRODownName__c FROM DiageoCMS__Cluster__c WHERE Id IN: odlClusterIds]); 
        Map<Id,Set<String>> mapGroupsByRecord = new Map<Id,Set<String>>();
        Set<Id> parentIds = new Set<Id>();
        Set<String> groupIds = new Set<String>();
        Id auxId;
        for(SObject record: (List<SObject>)Trigger.new){
            SObject oldRecord = (SObject) Trigger.oldMap.get(record.Id);
            System.debug(record.get(lookupField) != oldRecord.get(lookupField) && oldRecord.get(lookupField) != null);
            if(record.get(lookupField) != oldRecord.get(lookupField) && oldRecord.get(lookupField) != null){
                DiageoCMS__Cluster__c cluster = mapClusters.get((Id)oldRecord.get(lookupField));
                Set<String> auxGroupIds = new Set<String>{cluster.DiageoCMS__PublicGroupRWName__c, cluster.DiageoCMS__PublicGroupROUpName__c, cluster.DiageoCMS__PublicGroupRODownName__c};
                mapGroupsByRecord.put(record.Id, auxGroupIds);
                parentIds.add(record.Id);
                groupIds.addAll(auxGroupIds);
                auxId = record.Id;
            }
        }
        List<SObject> sharesToDelete = new List<SObject>();        
        if(!parentIds.isEmpty() && !groupIds.isEmpty()){
            String objectName = auxId.getSobjectType().getDescribe().getName();
            String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
            String query = 'SELECT Id, ParentId, UserOrGroupId, UserOrGroup.Name FROM ' + shareObjectName + ' WHERE ParentId IN: parentIds AND UserOrGroup.Name IN: groupIds';
            for(SObject shareRecord : Database.query(query)){
                Id parentId = (Id) shareRecord.get('ParentId');
                String groupId = (String) shareRecord.getSObject('UserOrGroup').get('Name');
                if(mapGroupsByRecord.containsKey(parentId) && mapGroupsByRecord.get(parentId).contains(groupId)){
                    sharesToDelete.add(shareRecord);
                }
            }
        }
        return sharesToDelete;
    }

}