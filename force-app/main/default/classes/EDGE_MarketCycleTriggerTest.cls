/**********************************************************************
Name: EDGE_MarketCycleTriggerTest
=======================================================================
Req: Test Class for SupplierOutletTrigger
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0       Anuja Chattopadhyay     11-Mar-2019         ES20-408

***********************************************************************/
@isTest
public with sharing class EDGE_MarketCycleTriggerTest {
    /********
Name : testOverLappedInsert
Description : Test Class for insert
********/
    @isTest
    public static void testOverLappedInsert(){
        //User mdmUser;
        //User mdm;
        //List<User> users = new List<User>();
        EDGE_UtilityTestClass.createOrgSettings();
        /*User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        insert users;*/
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        Test.startTest();
        /*System.runAs(adminUser){
            //Creating Sales Rep 
            mdmUser=EDGE_UtilityTestClass.runAsUser('MDMUser','Master Data Manager');
            mdmUser.Available_Countries__c = 'AU';
            insert mdmUser;
            System.assert(mdmUser.Id!=null);              
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
            geoShare.UserOrGroupId = mdmUser.Id;
            geoShare.AccessLevel = 'Edit';
            Database.SaveResult sr1 = Database.insert(geoShare,false);
            List<Group>groups=new List<Group>();
            Group group1 = new Group(Name='MarketAPAT_Down1',DeveloperName = 'MarketAPAT_Down', Type = 'Regular',DoesIncludeBosses=true,DoesSendEmailToMembers=false);
            groups.add(group1);
            insert groups; 
            List<GroupMember> gms=new List<GroupMember>();
            GroupMember gm1=new GroupMember();
            gm1.UserOrGroupId= mdmUser.Id;
            gm1.GroupId=group1.Id;
            gms.add(gm1);
            insert gms;
          
            
        }*/
        //System.runAs(mdmUser){
            //updating outlet
            Market_Cycle__c marketCycle2 =  new  Market_Cycle__c();
            marketCycle2.Name='Cycle 124';
            marketCycle2.Geography__c=countryId;
            marketCycle2.Start_Date__c=System.today().addDays(100);
            marketCycle2.End_Date__c=System.today().addDays(200);
            insert marketCycle2;
            Market_Cycle__c marketCycle1 =  new  Market_Cycle__c();
            marketCycle1.Name='Cycle 122';
            marketCycle1.Geography__c=countryId;
            marketCycle1.Start_Date__c=System.today().addDays(100);
            marketCycle1.End_Date__c=System.today().addDays(200);
            
            try{
                insert marketCycle1;
            }catch(Exception ex){
                //Checking Overlap Validation Rule
                System.Assert(ex.getMessage().contains(Label.MarketCycleTimeOverlap),'null');
            }
            
            Test.stopTest();
            System.assertEquals(marketCycle1.Id,null,'null');
            
        //}
    }
    /********
Name : testOverLappedUpdate
Description : Test Class for insert
********/
    @isTest
    public static void testOverLappedUpdate(){
        //User mdmUser;
        //User mdm;
        //List<User> users = new List<User>();
        EDGE_UtilityTestClass.createOrgSettings();
        /*User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        insert users;*/
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        Test.startTest();
        /*System.runAs(adminUser){
            //Creating Sales Rep 
            mdmUser=EDGE_UtilityTestClass.runAsUser('MDMUser','Master Data Manager');
            mdmUser.Available_Countries__c = 'AU';
            insert mdmUser;
            System.assert(mdmUser.Id!=null);              
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
            geoShare.UserOrGroupId = mdmUser.Id;
            geoShare.AccessLevel = 'Read';
            Database.SaveResult sr1 = Database.insert(geoShare,false);

        }*/ 
        //System.runAs(mdmUser){
            //updating outlet
            Market_Cycle__c marketCycle2 =  new  Market_Cycle__c();
            marketCycle2.Name='Cycle 124';
            marketCycle2.Geography__c=countryId;
            marketCycle2.Start_Date__c=System.today().addDays(100);
            marketCycle2.End_Date__c=System.today().addDays(200);
            insert marketCycle2;
            Market_Cycle__c marketCycle1 =  new  Market_Cycle__c();
            marketCycle1.Name='Cycle 122';
            marketCycle1.Geography__c=countryId;
            marketCycle1.Start_Date__c=System.today().addDays(300);
            marketCycle1.End_Date__c=System.today().addDays(400);
            insert marketCycle1;
            try{
                marketCycle1.Start_Date__c=System.today().addDays(100);
                marketCycle1.End_Date__c=System.today().addDays(200);
                update marketCycle1;
            }catch(Exception ex){
                //Checking Overlap Validation Rule
                System.Assert(ex.getMessage().contains(Label.MarketCycleTimeOverlap),'null');
            }
            Test.stopTest();            
        //}
    }
    
    /*******************************************************************
Method  : checkSharingTest
Purpose : To check the sharing of object
********************************************************************/
    @isTest
    public static void checkSharingTest(){
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Market_Cycle__c marketCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        insert marketCycle;
        system.assert(marketCycle.Id != null,'market Cycle Id should not be null');      
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        marketCycle.Geography__c = secCountry.Id;
        update marketCycle;        
        delete marketCycle;
        undelete marketCycle;
        Test.stopTest();
    }
   
}