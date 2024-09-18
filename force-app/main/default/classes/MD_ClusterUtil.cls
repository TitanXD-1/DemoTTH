/**************************************************************************************
Apex Class Name  :  MD_ClusterUtil
Version          :  1.0  
Created Date     :  18/12/2018
Release          :  R1
Function         :  Utils class for Cluster
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------                 
* Elena Schwarzböck          18/12/2018              Original Version
******************************************************************************/
public without sharing class MD_ClusterUtil {

    /* 
    * @Author      :    Elena Schwarzböck
    * @description :    
    * @returns     :    void
    */
    @TestVisible
    @Future
    public static void createsGroupMembers(String serializedGroupMembers){
    	List<GroupMember> groupMembers = (List<GroupMember>)JSON.deserialize(serializedGroupMembers, List<GroupMember>.class);
    	insert groupMembers;
    }

    /* 
    * @Author      :    Elena Schwarzböck
    * @description :    
    * @returns     :    void
    */
    @TestVisible
    @Future
    public static void deleteGroupMembers(Set<Id> groupMemberIds){
        delete [SELECT Id FROM GroupMember WHERE Id IN: groupMemberIds];
    }


    /* 
    * @Author      :    Elena Schwarzböck
    * @description :    Checks if the user has write permission to a set of cluster ids.
    * @returns     :    Map<Id,Boolean>
    */
    public static Map<Id,Boolean> getsClusterWriteAccess(Set<Id> clusterIds){
        Map<Id,Boolean> mapAccess = new Map<Id,Boolean>();
        Boolean isSysAdmin = false;
        Set<String> exceptionProfiles = new Set<String>{'System Administrator','Sys Admin','Restricted Admin'};
        Profile userProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
        SYSTEM.DEBUG([SELECT Id, Name, Alias, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()]);
        if(exceptionProfiles.contains(userProfile.Name)){
            isSysAdmin = true;
        }
        for(Id clusterId: clusterIds){
            mapAccess.put(clusterId, isSysAdmin);
        }
        if(!isSysAdmin){
            List<DiageoCMS__ClusterUser__c> clusterMembers = [SELECT Id, DiageoCMS__Cluster__c FROM DiageoCMS__ClusterUser__c WHERE DiageoCMS__User__c =: UserInfo.getUserId() AND DiageoCMS__Cluster__c IN: clusterIds AND DiageoCMS__AccessLevel__c = 'Read/Write'];
            for(DiageoCMS__ClusterUser__c clusterMember: clusterMembers){
                mapAccess.put(clusterMember.DiageoCMS__Cluster__c, true);
            }
        }
        return mapAccess;
    }

    /* 
    * @Author      :    Elena Schwarzböck
    * @description :    Checks if the user has write permission to a set of cluster ids.
    * @returns     :    Map<Id,Boolean>
    */
    public static Map<Id,Boolean> getsClusterWriteAccessSharing(Set<Id> clusterIds){
        Map<Id,Boolean> mapAccess = new Map<Id,Boolean>();
        for(Id clusterId: clusterIds){
            mapAccess.put(clusterId, false);
        }
        for(UserRecordAccess recordWOAccess: [SELECT RecordId FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND HasEditAccess = true AND RecordId IN: clusterIds]){
            mapAccess.put(recordWOAccess.RecordId, true);
        }
        return mapAccess;
    }

    /* 
    * @Author      :    Elena Schwarzböck
    * @description :    Checks if the user has write permission to a set of record ids.
    * @returns     :    Map<Id,Boolean>
    */
    public static Map<Id,Boolean> getsRecordWriteAccessSharing(Set<Id> recordIds){
        Map<Id,Boolean> mapAccess = new Map<Id,Boolean>();
        for(Id recordId: recordIds){
            mapAccess.put(recordId, false);
        }
        for(UserRecordAccess recordWOAccess: [SELECT RecordId FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND HasEditAccess = true AND RecordId IN: recordIds]){
            mapAccess.put(recordWOAccess.RecordId, true);
        }
        return mapAccess;
    }

    /* 
    * @Author      :    Elena Schwarzböck
    * @description :    Gets the root cluster for running user
    * @returns     :    DiageoCMS__Cluster__c
    */
    public static DiageoCMS__Cluster__c getCountryClusterForUser(Set<String> fieldset){
        List<DiageoCMS__CMSUserSettings__c> cmsSettings = MD_UserSessionUtil.getUser().DiageoCMS__CMSUsersSettings__r;

        if(cmsSettings.size() > 0) {
            String clusterId = cmsSettings.get(0).DiageoCMS__Cluster__c;

            String fields = '';
            if(!fieldset.isEmpty()){
                fields = String.join(new List<String>(fieldset),',');
            }else{
                fields = 'Id, Name';
            }
            String query = 'SELECT ' + fields + ' FROM DiageoCMS__Cluster__c WHERE Id = :clusterId LIMIT 1';
            System.debug('CG - in MD_ClusterUtil.getCountryClusterForUser() method. query: ' + query);

            List<DiageoCMS__Cluster__c> rootCluster = Database.query(query);

            if(!rootCluster.isEmpty()){
                return rootCluster.isEmpty() ? null : rootCluster[0];
            }
        }
        
        return null;
    }

    /* 
    * @Author      :    Elena Schwarzböck
    * @description :    
    * @returns     :    Map<Id,Boolean>
    */
    public static Map<Id,Boolean> getClusterAccess(Set<Id> clusterIds){

        Map<Id,Boolean> mapAccess = new Map<Id,Boolean>();
        for(Id clusterId: clusterIds){
            mapAccess.put(clusterId, false);
        }

        Set<Id> allClusters = new Set<Id>();
        Set<Id> parents = new Set<Id>();
        Map<Id,Set<Id>> mapClusters = new Map<Id,Set<Id>>();

        for(DiageoCMS__Cluster__c cluster: [SELECT Id, DiageoCMS__ParentCluster__c, DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__c, DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__c, DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__c FROM DiageoCMS__Cluster__c WHERE Id IN: clusterIds]){
            parents = new Set<Id>();
            parents.add(cluster.DiageoCMS__ParentCluster__c);
            parents.add(cluster.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__c);
            parents.add(cluster.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__c);
            parents.add(cluster.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__r.DiageoCMS__ParentCluster__c);
            allClusters.addALL(parents);
            allClusters.add(cluster.Id);
            mapClusters.put(cluster.Id, parents);
        }

        Set<Id> clusterWithAccess = new Set<Id>();

        for(DiageoCMS__ClusterUser__c clusterMember: [SELECT Id, DiageoCMS__Cluster__c FROM DiageoCMS__ClusterUser__c WHERE DiageoCMS__User__c =: UserInfo.getUserId() AND DiageoCMS__Cluster__c IN: allClusters AND DiageoCMS__AccessLevel__c = 'Read/Write']){
            clusterWithAccess.add(clusterMember.DiageoCMS__Cluster__c);
        }

        for(Id clusterId: clusterIds){
            if(clusterWithAccess.contains(clusterId)){
                mapAccess.put(clusterId, true);
                continue;
            }else if(mapClusters.containsKey(clusterId)){
                for(Id parentCluster: mapClusters.get(clusterId)){
                    if(clusterWithAccess.contains(parentCluster)){
                        mapAccess.put(clusterId, true);
                        continue;
                    }
                }

            }
        }
        return mapAccess;
    }


}