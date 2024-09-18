/*
* Class Name: EDGE_OpportunitiesWOTemplateBatchTest
* Brief Description: This is test class for EDGE_OpportunitiesWithoutTemplateBatch class.
* Created Date: 20/05/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0			    Suvendu Roy		    20/08/2024			Initial Development : 155301
*/

@isTest
public class EDGE_OpportunitiesWOTemplateBatchTest {
    
    @isTest
    public static void oppWoOppTem(){
        Test.startTest();
        testStandredObjectInsertion();
        testOpportunitesInsertion();
        try{  
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OpportunitiesWithoutTemplateBatch'
                                                      and Country_Code__c ='GB' ];
            
            
            String className = batchSetting.Batch_Class__c;   
            System.assert(className!=null,'className should not be null');   
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,1);           
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());            
        }
        Test.stopTest();
    }
    static @isTest void testStandredObjectInsertion(){
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
         System.assert(thisUser!=null,'thisUser should not be null'); 
        // Insert account as current user
        System.runAs (thisUser) {
            Group queryOpportunitiesGroup = new Group(Name = 'GB_MDM');
            queryOpportunitiesGroup.type ='Queue';
            insert queryOpportunitiesGroup;
            
            User mdm1 = EDGE_UtilityTestClass.runAsUser('Testabc1','Master Data Manager');
            insert mdm1;
            User mdm2 = EDGE_UtilityTestClass.runAsUser('Testabc2','Master Data Manager');
            insert mdm2;
            User mdm3 = EDGE_UtilityTestClass.runAsUser('Testabc3','Master Data Manager');
            insert mdm3;
            
            List<GroupMember> groupMemberList = new List<GroupMember>();
            GroupMember groupMember1 = new GroupMember();
            groupMember1.UserOrGroupId = mdm1.Id;
            groupMember1.GroupId = queryOpportunitiesGroup.Id;          
            groupMemberList.add(groupMember1);
            
            GroupMember groupMember2 = new GroupMember();
            groupMember2.UserOrGroupId = mdm2.Id;
            groupMember2.GroupId = queryOpportunitiesGroup.Id;
            groupMemberList.add(groupMember2);
            
            GroupMember groupMember3 = new GroupMember();
            groupMember3.UserOrGroupId = mdm3.Id;
            groupMember3.GroupId = queryOpportunitiesGroup.Id;
            groupMemberList.add(groupMember3);
            
            insert groupMemberList;
        }
    }
    static @isTest void testOpportunitesInsertion(){
        
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        System.assert(geographyId!=null,'geographyId should not be null');
        Account acc1 = EDGE_UtilityTestClass.getOutletRecord();
        acc1.Name = 'Test_Outlet_1';
        insert acc1;
        
        Account acc2 = EDGE_UtilityTestClass.getOutletRecord();
        acc2.Name = 'Test_Outlet_2';
        insert acc2;
        
        Account acc3 = EDGE_UtilityTestClass.getOutletRecord();
        acc3.Name = 'Test_Outlet_3';
        insert acc3;
        
        
        Market_Setting__c market= new Market_Setting__c();
        market.Name='Great Britain';
        market.Geography__c=geographyId;
        market.Opportunity_Notification__c='Bell Notification;Email Notification';
        insert market;
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp11 = new Opportunity(Name='test11',AccountId=acc1.Id,StageName='Open',Type='MPA',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp11);
        Opportunity opp12 = new Opportunity(Name='test12',AccountId=acc2.Id,StageName='Open',Type='MPA',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp12);
        Opportunity opp13 = new Opportunity(Name='test13',AccountId=acc3.Id,StageName='Open',Type='MPA',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp13);
        Opportunity opp21 = new Opportunity(Name='test21',AccountId=acc1.Id,StageName='Open',Type='MPA',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp21);
        Opportunity opp22 = new Opportunity(Name='test22',AccountId=acc2.Id,StageName='Open',Type='MPA',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp22);
        Opportunity opp23 = new Opportunity(Name='test23',AccountId=acc3.Id,StageName='Open',Type='MPA',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp23);
        
        insert oppList;
    }
    
}