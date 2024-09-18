@isTest
public class Test_MD_AgreementTriggerHandler {        

    @testSetup 
    public static void setup(){
        insert new DiageoCMS__CMSSettings__c(DiageoCMS__ClusterFieldForPublicGroups__c = 'DiageoCMS__ExternalId__c', DiageoCMS__SalesforceDomain__c = 'https://edge--edgedev3.lightning.force.com');
    }
    
    testmethod private static void createSharingRecordsTest(){
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
                                                                  DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
                                                                  DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
                                                                  DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown'
                                                                 );
		insert cluster;
        Test.startTest();       
        insert new MD_Agreement__c(Name = 'Test', Cluster__c = cluster.Id);
        Test.stopTest();
        
        MD_Agreement__c agreement = [SELECT Id, Cluster__c FROM MD_Agreement__c LIMIT 1];
        MD_Agreement__Share shareRecord = [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM MD_Agreement__Share LIMIT 1];
        
        System.AssertEquals(4, [SELECT Count() FROM MD_Agreement__Share]);
        System.AssertEquals(agreement.Id, shareRecord.ParentId);
    }
    
    testmethod private static void updateSharingRecordsTest(){
        DiageoCMS__Cluster__c cluster1 = new DiageoCMS__Cluster__c(Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
                                                                  DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
                                                                  DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
                                                                  DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown'
                                                                  );
        
        DiageoCMS__Cluster__c cluster2 = new DiageoCMS__Cluster__c(Name = 'GB', DiageoCMS__ExternalId__c = 'GB',
                                                                  DiageoCMS__PublicGroupRWName__c = 'GB_RW',
                                                                  DiageoCMS__PublicGroupROUpName__c = 'GB_ROViewUp', 
                                                                  DiageoCMS__PublicGroupRODownName__c = 'GB_ROViewDown'
                                                                  );
        insert cluster1; insert cluster2;
        MD_Agreement__c agreement = new MD_Agreement__c(Name = 'Test', Cluster__c = cluster1.Id);
        insert agreement;
        String clusterId = [SELECT Id, Cluster__c FROM MD_Agreement__c LIMIT 1].Cluster__c;     
        
        Test.startTest();       
        agreement.Cluster__c = cluster2.Id;
        update agreement;
        Test.stopTest();
        
        List<MD_Agreement__Share> shareRecords = [SELECT Id, ParentId, UserOrGroupId FROM MD_Agreement__Share];
        List<Id> groupIds = new List<Id>();
        for(MD_Agreement__Share shareRecord : shareRecords){
            groupIds.add(shareRecord.UserOrGroupId);
        }
        List<Group> groups = [SELECT Id, Name FROM Group WHERE ID =: groupIds];
        Boolean groupsCountry = true;
        for(Group g : groups){
            groupsCountry &= (g.Name.contains('GB'));
        }
        
        System.AssertEquals(4, shareRecords.size());        
        System.AssertEquals(true, groupsCountry);
        
    }
    
    testmethod private static void validatesPermissionOnSelectedClusterTest(){
        DiageoCMS__Cluster__c cluster1 = new DiageoCMS__Cluster__c(Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
                                                                  DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
                                                                  DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
                                                                  DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown'
                                                                  );
        
        DiageoCMS__Cluster__c cluster2 = new DiageoCMS__Cluster__c(Name = 'GB', DiageoCMS__ExternalId__c = 'GB',
                                                                  DiageoCMS__PublicGroupRWName__c = 'GB_RW',
                                                                  DiageoCMS__PublicGroupROUpName__c = 'GB_ROViewUp', 
                                                                  DiageoCMS__PublicGroupRODownName__c = 'GB_ROViewDown'
                                                                  );
        insert cluster1; insert cluster2;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User user = [SELECT Id, Name FROM User WHERE ProfileId =: p.Id AND isActive = True LIMIT 1];
        insert new MD_Agreement__c(Name = 'Test', Cluster__c = cluster1.Id);
        Test.startTest();            
        System.runAs(user){
            MD_Agreement__c agreement = [SELECT Id FROM MD_Agreement__c LIMIT 1];
            update agreement;
        }
        Test.stopTest();
    }

}