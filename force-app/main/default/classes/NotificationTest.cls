@isTest
public class NotificationTest {
    // Get Account Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
    // Get the record type id of from the Map based on the Name
    public static Id outletRecTypeId = mapAccountRecordTypes.get('Outlet').getRecordTypeId();
    public static Map<String,Id> geoMap = new Map<String,Id>();
    // Get Geography Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    // Get the record type id of from the Map based on the Name
    public static Id globalRecTypeId = mapGeographyRecordTypes.get('Global').getRecordTypeId();
    public static Id marketRecTypeId = mapGeographyRecordTypes.get('Market').getRecordTypeId();
    public static Id hubRecTypeId = mapGeographyRecordTypes.get('Hub').getRecordTypeId();    
    public static Id clusterRecTypeId = mapGeographyRecordTypes.get('Cluster').getRecordTypeId();
    public static Id countryRecTypeId = mapGeographyRecordTypes.get('Country').getRecordTypeId();
    public static Id areaRecTypeId = mapGeographyRecordTypes.get('Area').getRecordTypeId();
    public static Id regionRecTypeId = mapGeographyRecordTypes.get('Region').getRecordTypeId();
    public static Id stateRecTypeId = mapGeographyRecordTypes.get('State').getRecordTypeId();
    
    // Get Pickup Option Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id outletpriorRecTypeId = mapPickupoptionRecordTypes.get('Outlet Prioritization').getRecordTypeId();
    public static Id producttypeRecTypeId = mapPickupoptionRecordTypes.get('Product Type').getRecordTypeId();
    @isTest
    public static void oppWoOppTem(){
        Test.startTest();  
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OpportunitiesWithoutTemplateBatch'
                                                  and Country_Code__c ='GB'];
        system.assert(batchSetting != null,'Batch is Added');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        system.debug('getBatchDetails');
        Database.executeBatch((Database.Batchable<SObject>)job,200);
        system.debug(' Database.executeBatch');
        Test.stopTest();  
    }

    static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        Date todays = Date.today();
        //Create Account
        List<Account> accLst = new List<Account>();        
        Account outlet1 = getOutletRecord();
        outlet1.Name = 'Test Outlet1';
        outlet1.BillingStreet = '95 Lords Airway 1';
        accLst.add(outlet1);        
        Account outlet2 = getOutletRecord();       
        outlet2.Name = 'Test Outlet2';
        outlet2.BillingStreet = '17 Middleton Highway 45';
        accLst.add(outlet2);
        Account outlet3 = getOutletRecord();       
        outlet2.Name = 'Test Outlet3';
        outlet2.BillingStreet = '17 Seminar 45';
        accLst.add(outlet3);
        insert accLst; 
        // Create Market Setting
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Opportunity_Notification__c = 'Bell Notification;Email Notification';
        insert market;
        
        Group gbQueue = new Group(Name = 'GB_MDMs');
        gbQueue.type ='Queue';
        insert gbQueue;
        
        List<User> mdmList = new List<User>();
        User mdm1 = EDGE_UtilityTestClass.runAsUser('Testabc1','Master Data Manager');
        mdmList.add(mdm1);
        User mdm2 = EDGE_UtilityTestClass.runAsUser('Testabc2','Master Data Manager');
        mdmList.add(mdm2);
        User mdm3 = EDGE_UtilityTestClass.runAsUser('Testabc3','Master Data Manager');
        mdmList.add(mdm3);
        insert mdmList;
            
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.assert(thisUser!=null,'ThisUser should not be null'); 
        // Insert Account as current user
        System.runAs (thisUser) {            
            List<GroupMember> queueMemberList = new List<GroupMember>();
            for(integer i =0; i<mdmList.size();i++){
                GroupMember queMem = getQueueMember(mdmList[i].id,gbQueue.id);
                queueMemberList.add(queMem);
            }
            insert queueMemberList;
        }
        // Create Products
        List<Product__c> prodList = new List<Product__c>();
        Product__c prod1 = getProd();
        prod1.name = 'Prod1';
        prod1.Product_2_ID__c = '324';
        prod1.UPIID__c  = '343';
        prodList.add(prod1);
        Product__c prod2 = getProd();
        prod2.name = 'Prod2';
        prod2.Product_2_ID__c = '454';
        prod2.UPIID__c  = '767';
        prodList.add(prod2);
        Product__c prod3 = getProd();
        prod3.name = 'Prod3';
        prod3.Product_2_ID__c = '123';
        prod3.UPIID__c  = '987';
        prodList.add(prod3);
        insert prodList;
        
        // Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = new Opportunity(Name='Test1',AccountId=outlet1.Id,Product__c =prod1.id, StageName='Open',Type='MPA',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp1);
        Opportunity opp2 = new Opportunity(Name='Test2',AccountId=outlet1.Id,Product__c =prod2.id, StageName='Open',Type='Cycle Brief',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp2);
        Opportunity opp3 = new Opportunity(Name='Test1',AccountId=outlet1.Id,Product__c =prod3.id, StageName='Open',Type='MAS',Source__c='TRAX',CloseDate=System.today());       
        oppList.add(opp3);
        Opportunity opp4 = new Opportunity(Name='Test3',AccountId=outlet2.Id,Product__c =prod1.id, StageName='Open',Type='Cycle Brief',Source__c='EDGE',CloseDate=System.today());       
        oppList.add(opp4);
        Opportunity opp5 = new Opportunity(Name='Test4',AccountId=outlet2.Id,Product__c =prod2.id, StageName='Open',Type='WPA',Source__c='TRAX',CloseDate=System.today());       
        oppList.add(opp5);
        Opportunity opp6 = new Opportunity(Name='Test5',AccountId=outlet3.Id,Product__c =prod3.id, StageName='Open',Type='MPA',Source__c='Advanced Analytics',CloseDate=System.today());       
        oppList.add(opp6);
        
        insert oppList;
    }
    public static Id setupCountryGB(string countryCode){
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        return country.Id;        
    }
    
    public static Account getOutletRecord(){
        Account outlet = new Account();
        outlet.Name = 'Test_Outlet';
        outlet.RecordTypeId = OutletRecTypeId;
        outlet.BillingStreet = '17 GB Highway 45';
        outlet.BillingCity = 'Cononel';
        outlet.BillingState = 'Hampshire';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'United Kingdom';
        outlet.BillingCountryCode = 'GB';
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        outlet.Independent_of_Operator__c = true;
        outlet.Independent_of_Owner__c = true;
        return outlet;  
    }
    
    //Create Feed Item Record
    public static Opportunity getOpportunity(Id outletId, Id prodId){
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Test Opportunity';
        oppRec.AccountId = outletId;
        oppRec.StageName = 'Open' ;
        oppRec.Type = 'MPA';
        oppRec.Source__c = 'EDGE';
        oppRec.Opportunity_Template__c = null;
        oppRec.Product__c = prodId;
        return oppRec;
    }
    
    public static GroupMember getQueueMember(Id mdmId, Id queueId){
        GroupMember queueMember = new GroupMember();
        queueMember.UserOrGroupId = mdmId;
        system.debug('Line no 231'+ mdmId);
        queueMember.GroupId = queueId;
        return queueMember;           
    }
    //create Product record
    public static Product__c getProd(){
        Product__c testProd = new Product__c(Name='Johnny Walker Black Label');
        testProd.UPIID__c='12345';
        testProd.Product_2_ID__c = '4321';
        testProd.Product_Full_Name__c = 'New Product';
        testProd.Country__c =  geoMap.get('Country');
        testProd.Pricing_Type__c = 'By Unit';
        testProd.Limit_Per_Order__c=10;
        testProd.POS_Related_Item__c='JW';
        testProd.Product_Code__c='test234';
        return testProd; 
    }
    /* @isTest
static void createQueueDetails(){
User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
System.assert(thisUser!=null,'thisUser should not be null'); 
// Insert account as current user
System.runAs (thisUser) {


Group gbQueue = new Group(Name = 'GB_MDMs');
gbQueue.type ='Queue';
insert gbQueue;

List<User> mdmList = new List<User>();
User mdm1 = EDGE_UtilityTestClass.runAsUser('Testabc1','Master Data Manager');
mdmList.add(mdm1);
User mdm2 = EDGE_UtilityTestClass.runAsUser('Testabc2','Master Data Manager');
mdmList.add(mdm2);
User mdm3 = EDGE_UtilityTestClass.runAsUser('Testabc3','Master Data Manager');
mdmList.add(mdm3);
insert mdmList;
List<GroupMember> queueMemberList = new List<GroupMember>();
GroupMember queMem1 = new GroupMember();
queMem1.UserOrGroupId = mdm1.Id;
queMem1.GroupId = gbQueue.Id;          
queueMemberList.add(queMem1);

GroupMember queMem2 = new GroupMember();
queMem2.UserOrGroupId = mdm2.Id;
queMem2.GroupId = gbQueue.Id;
queueMemberList.add(queMem2);

GroupMember queMem3 = new GroupMember();
queMem3.UserOrGroupId = mdm3.Id;
queMem3.GroupId = gbQueue.Id;
queueMemberList.add(queMem3);

insert queueMemberList;
}
}*/
}