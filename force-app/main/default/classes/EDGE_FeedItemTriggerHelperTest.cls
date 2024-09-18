/**
* @Description : EDGE_FeedItemTriggerHelperTest

/*
* Class Name: EDGE_FeedItemTriggerHelperTest
* @description: This is the test class for EDGE_FeedItemTriggerHelper class.
* @history                                                          
* VERSION  AUTHOR            DATE              DETAIL
* 1.0 -    Sandip Ghosh 	20/08/2020      Initial Development   ES20-8463 
* 1.1-     Anshu Prakash  04/08/2021      ECM-4620- Updated the code to fetch the pickup option from database if it already exists.   
* 1.2      Joshraj Sen    08/04/2024      152305 SCA Fix
*/

@IsTest(SeeAllData=true)
public class EDGE_FeedItemTriggerHelperTest {
    
    static String operatorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
    static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    static String accCVRecordTypeId = ContentVersion.sObjectType.getDescribe().getRecordTypeInfosByName().get('Account').getRecordTypeId();
    
    /**

* @description : createNotesTest - Test method to cover getCallNotes

* @return : void

*/
    @isTest
    public static void createNotesTest(){
        
        User adminUser  = [Select Id , ProfileId from User where Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Id geographyId;
        Id clusterId;
        Id hubId;
        Id marketId;
        Id areaId;
        Id regionId;
        string countryCode;
        System.assert(adminUser!=null,'User Received');
        List<Geography__c> geoList = [Select Id, Code__c, Parent_Geography__c, Name, RecordTypeId, RecordType.Name from Geography__c];
        
        if(geoList == null || geoList.size()==0){
            
            //EDGE_UtilityTestClass.createOrgSettings();
            geographyId = EDGE_UtilityTestClass.setupCountry('AU');
            geoList = [Select Id, Code__c, Parent_Geography__c, Name, RecordTypeId, RecordType.Name from Geography__c];
        }
        for(Geography__c geo : geoList){
            
            if(geo.Code__c == 'AU'){
                geographyId = geo.Id;
                countryCode = geo.Code__c;
            }else if(geo.Code__c == 'AUCT' || geo.Code__c == 'AUSC'){
                clusterId = geo.Id;
            }else if(geo.Code__c == 'AUHT' || geo.Code__c == 'AUSH'){
                hubId = geo.Id;
            }else if(geo.Code__c == 'APAT' || geo.Code__c == 'APAC'){
                marketId = geo.Id;
            }else if(geo.Code__c == 'SAU1' || geo.Code__c == 'AUA'){
                areaId = geo.Id;
            }else if(geo.Code__c == 'SAU2' || geo.Code__c == 'QLD'){ //AU1
                regionId = geo.Id;
            }
        }
        List<Org_Setting__c> orgSetingList = new List<Org_Setting__c>(); 
        for(Org_Setting__c orgSetObj : [Select Id,Name,Run_Validation_Rules__c from Org_Setting__c]){
            orgSetObj.Run_Validation_Rules__c = false;
            orgSetingList.add(orgSetObj);
        }
        update orgSetingList;
        //String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        
        // Start added as part of User story ECM-4620
        /*Pick_Up_Options__c pickupOption= new Pick_Up_Options__c();
List<Pick_Up_Options__c> pickupOptionLst = [select id,name,RecordTypeId,Status__c from Pick_Up_Options__c where name='Gold[AU]' and RecordTypeId=:pickupRecordType Limit 1];
System.debug('geographyId'+geographyId);
//List<Geography__c> geog = new List<Geography__c>();
for(Geography__c geogObj: [SELECT Id, Name, Code__c, RecordType.Name from Geography__c Where id = :geographyId] ){
System.debug(geogObj.Name +geogObj.Code__c + geogObj.RecordType.Name + 'Testing from 78');
}
if(pickupOptionLst.isEmpty()){
EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
pickupOption.Name = 'Gold[AU]';
pickupOption.RecordTypeId = pickupRecordType;
pickupOption.Status__c = 'Active';
insert pickupOption;

}else{
pickupOption=pickupOptionLst[0];
}*/
        // End added as part of User story ECM-4620
        //system.assert(pickupOption.Id != null);
        
        EDGE_UtilityClass.printGovLimits(68);
        
        List<Account> accList = new List<Account>();
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Name = 'Test_Operator';
        objAccount.Status__c = 'Active';
        objAccount.RecordTypeId = operatorRecordTypeId;
        objAccount.IsOperator__c = true;
        objAccount.Person_Responsible__c = adminUser.Id;
        objAccount.Country__c = geographyId;
        objAccount.Hub__c = hubId;
        objAccount.Region__c=regionId;
        objAccount.Area__c=areaId;
        objAccount.Market__c = marketId;
        objAccount.Cluster__c= clusterId;
        accList.add(objAccount);
        
        EDGE_UtilityClass.printGovLimits(86);
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test_Operator';
        outlet.Status__c = 'Active';
        outlet.RecordTypeId = outletRecordTypeId;
        outlet.IsOperator__c = true;
        //outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        outlet.Person_Responsible__c = adminUser.Id;
        outlet.Country__c = geographyId;
        outlet.Hub__c = hubId;
        outlet.Region__c=regionId;
        outlet.Area__c=areaId;
        outlet.Market__c = marketId;
        outlet.Cluster__c= clusterId;
        accList.add(outlet);
        
        Test.startTest();
        Database.insert(accList);
        
        
        EDGE_UtilityClass.printGovLimits(106);
        
        System.runAs(adminUser){
            //Inserting the feed
            List<FeedItem> feedList = new List<FeedItem>();
            
            FeedItem feed = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'TextPost', objAccount.Id);
            // feed.ParentId=objAccount.Id;
            feed.Status = 'Published';
            feedList.add(feed);
            
            FeedItem feed1 = EDGE_UtilityTestClass.getFeedItem('feed post 5', 'TextPost', outlet.Id);
            //feed1.ParentId=outlet.Id;
            feed1.Status = 'Published';
            feedList.add(feed1);
            Database.insert(feedList);
            
            //Update the feed
            
            feed.Body = 'feed post 2';
            update feed;
            
            Map<String, Object> custom = new Map<String, Object>();
            custom.put('OutletId',outlet.Id);
            custom.put('OutletName',outlet.Name);
            custom.put('OwnerId',outlet.OwnerId);
            custom.put('ChatterId',feed1.Id);
            ConnectApi.FeedElement feedElem = ConnectApi.ChatterFeeds.getFeedElement(null, feed1.Id);
            List<ConnectApi.MessageSegment> messageSegments = feedElem.body.messageSegments;
            EDGE_PushNotificationHelper.pushNotificationMethod(messageSegments, 'test', custom);
            EDGE_PushNotificationHelper.pushNotificationMethod(null, 'test', custom);
            //Deleting the feed
            Database.delete(feed);
            
            //Undeleting the feed
            // Database.undelete(feed);
        }
        Test.stopTest();
    }
    @isTest
    public static void preventFeedItem()
    {
        Profile prof = [select id from profile where name= 'Sales Representative'];
        //Id caseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='IE';
        insert usr;
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = [Select Id from Geography__c where Name='Global' limit 1];
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = [Select Id from Geography__c where Name='Europe and Turkey' limit 1];
        geoMap.put('Market',market.Id);
        Geography__c hub =  [Select Id from Geography__c where Name='Island of Ireland' limit 1];
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = [Select Id from Geography__c where Name='Ireland' limit 1];
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = [Select Id from Geography__c where Name='Republic of Ireland' and RecordType.Name='Country' limit 1];
        geoMap.put('Country',country.Id);
        Geography__c area = [Select Id from Geography__c where Name='Republic of Ireland' and RecordType.Name='Area' limit 1];
        geoMap.put('Area',area.Id);        
        Geography__c region = [Select Id from Geography__c where Name='Carlow' and RecordType.Name='Region' limit 1];
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name='Gold1[IE]';
        insert pickupOption;
        Account outlet =EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Tes outle classs';
        outlet.Account_Type__c='Ship-to';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        insert outlet;
        Test.startTest();
        Case caserecd1=new Case();
        caserecd1.Status='Open';
        caserecd1.RecordTypeId=Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        caserecd1.Description='This is a description';
        caserecd1.Priority='1-Low';
        caserecd1.Origin='Diageo One';
        caserecd1.AccountId=outlet.Id;
        caserecd1.Sales_Org__c='IN01';
        caserecd1.Type='Kegs Collection';
        caserecd1.D1_Subject__c='Request empties keg collection';
        insert caserecd1;
        EntitySubscription es = new EntitySubscription();
        es.ParentId = caserecd1.Id;
        es.SubscriberId = usr.Id;
        insert es;
        FeedItem feed1 = new FeedItem();
        feed1.Body = 'Test feed comment';
        feed1.ParentId = caserecd1.id;
        insert feed1;
        
        Case cs=new Case();
        cs.Status='Closed';
        cs.RecordTypeId=Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        cs.Description='This is a description';
        cs.Type_of_Communication__c='Physical Visit';
        cs.Contacted_Date__c=System.now();
        cs.Priority='1-Low';
        cs.Origin='Diageo One';
        cs.AccountId=outlet.Id;
        cs.Sales_Org__c='IN01';
        cs.Type='Issues with Site';
        cs.D1_Subject__c='Technical Issues';
        insert cs;
        
        
        try
        {
            FeedItem feed = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'TextPost', cs.Id);
            // feed.ParentId=objAccount.Id;
            feed.Status = 'Published';
            insert feed;
            
        }
        catch(Exception e){
            System.assert(e.getMessage().contains(Label.Case_Comment_Error_Message),'Error Message Matched');
        }
        
        
        Test.stopTest();
    }
    
    
}