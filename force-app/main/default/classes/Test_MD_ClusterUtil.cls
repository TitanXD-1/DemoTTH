@isTest
public class Test_MD_ClusterUtil {        

    @testSetup 
    public static void setup(){
        TestFactory_MD_Account.setup(true);
        insert new DiageoCMS__CMSSettings__c(DiageoCMS__ClusterFieldForPublicGroups__c = 'DiageoCMS__ExternalId__c', DiageoCMS__SalesforceDomain__c = 'https://edge--edgedev3.lightning.force.com');
    }

    testmethod private static void createsDeleteGroupMembers(){

    	DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name='NIR ', DiageoCMS__ExternalId__c='NIR');
        insert cluster;

    	cluster = [SELECT Id, DiageoCMS__ExternalId__c, DiageoCMS__PublicGroupRWName__c, DiageoCMS__PublicGroupROUpName__c, DiageoCMS__PublicGroupRODownName__c FROM DiageoCMS__Cluster__c WHERE Id =: cluster.Id];
		Map<String, Id> groupsMap = new Map<String, Id>();
        for(Group g : [SELECT Id, Name FROM Group /*WHERE Name = :cluster.DiageoCMS__ExternalId__c*/]){
            groupsMap.put(g.Name, g.Id); System.debug(g.Name);
        } 
    	List<GroupMember> newGroupMembers = new List<GroupMember>();
    	newGroupMembers.add(new GroupMember(UserOrGroupId = UserInfo.getuserId(), GroupId = groupsMap.get(cluster.DiageoCMS__ExternalId__c + '_RW')));
    	newGroupMembers.add(new GroupMember(UserOrGroupId = UserInfo.getuserId(), GroupId = groupsMap.get(cluster.DiageoCMS__ExternalId__c + '_ROViewUp')));
    	newGroupMembers.add(new GroupMember(UserOrGroupId = UserInfo.getuserId(), GroupId = groupsMap.get(cluster.DiageoCMS__ExternalId__c + '_ROViewDown')));

    	MD_ClusterUtil.createsGroupMembers(JSON.serialize(newGroupMembers));

    }

    testmethod private static void deleteGroupMembers(){
    	MD_ClusterUtil.deleteGroupMembers(new Set<Id>());
    }
    
    testmethod private static void getsClusterWriteAccess(){

    	DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name='NIR ', DiageoCMS__ExternalId__c='NIR');
        insert cluster;
    	MD_ClusterUtil.getsClusterWriteAccess(new Set<Id>{cluster.Id});
    }
    
    testmethod private static void getsClusterWriteAccessSharing(){

        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name='NIR', DiageoCMS__ExternalId__c='NIR');
        insert cluster;
        MD_ClusterUtil.getsClusterWriteAccessSharing(new Set<Id>{cluster.Id});
    }
    
    testmethod private static void getsRecordWriteAccessSharing(){

        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name='NIR ', DiageoCMS__ExternalId__c='NIR');
        insert cluster;
        MD_ClusterUtil.getsRecordWriteAccessSharing(new Set<Id>{cluster.Id});
    }
    
    testmethod private static void getClusterAccess(){

    	DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name='NIR ', DiageoCMS__ExternalId__c='NIR');
        insert cluster;
        MD_ClusterUtil.getClusterAccess(new Set<Id>{cluster.Id});
    }
    
    testmethod private static void getCountryClusterForUser(){
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                     LanguageLocaleKey, EmailEncodingKey, LastName, FirstName, LocaleSidKey, TimeZoneSidKey,
                     Country FROM User WHERE ContactId != NULL LIMIT 1]; System.debug(user);
        
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name='NIR ', DiageoCMS__ExternalId__c='NIR');
        insert cluster;
        
        Map<String, Geography__c> geos  = new Map<String, Geography__c>();
        
        for(Geography__c g : [SELECT Id, RecordType.DeveloperName FROM Geography__c]) {
            geos.put(g.RecordType.DeveloperName, g);
        }
        
        Account acc = new Account(Name = 'TestAcc',
                                  Region__c = geos.get('Region').Id,
                                  Area__c = geos.get('Area').Id,
                                  Country__c = geos.get('Country').Id,
                                  Cluster__c = geos.get('Cluster').Id,
                                  Hub__c = geos.get('Hub').Id,
                                  Market__c = geos.get('Market').Id,
                                    Global_Channel__c = 'On Trade'
                                    , Global_Sub_Channel__c = 'On trade'
                                    , Global_Segment__c = 'Bars'
                                    , Global_Sub_Segment__c = 'Modern Bars'
                                 );
        insert acc;
        
        Contact ct = new Contact(LastName = 'TestCt', AccountId = acc.Id, Email = 'testct@test.com');
        insert ct;
        user.ContactId = ct.Id;
        AccountContactRelation accContact = [SELECT Id FROM AccountContactRelation WHERE ContactId =: user.ContactId LIMIT 1];
        TestFactory_MD_Account.createSettingsForUserWithCluster(user.Id, accContact.Id, new List<Id>{cluster.Id});
        
        System.runAs(user) {
            DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, cluster.Id, null, null, user.Id);
            MD_ClusterUtil.getCountryClusterForUser(new Set<String>{'Name'});
        }
    }

}