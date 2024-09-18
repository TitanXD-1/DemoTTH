/**
* @Name: EDGE_PickUpOptionTriggerTest

* @Req: Test Class for  Pick Up Option Trigger 

* @History                                                            

* @VERSION   AUTHOR                        DATE              DETAIL
*  1.0       Anuja Chattopadhyay           25-03-2019        ES20-500
*  2.0       Swaraj Samanta                05-09-2022        ES20-13284
*/
@isTest
public with sharing class EDGE_PickUpOptionTriggerTest {
    
    @isTest
    public static void validateGuid(){
        User testMDMUser;
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        Test.startTest();
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        System.runAs(testAdminUser){
            //create MDM User
            testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','Master Data Manager');
            testMDMUser.Available_Countries__c = 'AU';
            insert testMDMUser;
            //Create Pickup option Record
            Pick_Up_Options__c pckObj = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Local-Segment2');
            pckObj.RecordTypeId =  Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
            insert pckObj;
            System.assert(pckObj.id!=null,'pckObj should not be null');
            pckObj.Type__c='Local-Segment2';
            pckObj.Include_in_Total_Activation_Survey_KPI__c=true;
            update pckObj;
            Test.stopTest();
            Pick_Up_Options__c insrtPckObj =[SELECT Id,GUID__c FROM Pick_Up_Options__c WHERE Id =:pckObj.Id];
            System.assert(insrtPckObj.GUID__c!=null,'insrtPckObj should not be null');
        }
    }
    @isTest
    public static void validateDelete(){
        User testMDMUser;
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        Test.startTest();
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        System.runAs(testAdminUser){
            //create MDM User
            testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','Master Data Manager');
            testMDMUser.Available_Countries__c = 'AU';
            insert testMDMUser;
            List<Pick_Up_Options__c> pickUpOptions =new List<Pick_Up_Options__c>();
            Pick_Up_Options__c pckObj1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Local-Segment2');
            pckObj1.Name = 'Local [AU]';
            pckObj1.RecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
            pickUpOptions.add( pckObj1);
            Pick_Up_Options__c pckObj2 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Local-Segment2');
            pckObj2.Name = 'CST[AU]';
            pckObj2.Type__c='Tax Code';
            pckObj2.RecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
            pickUpOptions.add( pckObj2);
            insert pickUpOptions;
            System.assert(pckObj1.id!=null,'pckObj1 should not be null');
            //Delete Pick up Option
            delete pckObj1;
            //Undelete Pick up Option
            undelete pckObj1;
            Test.stopTest();
        }
    }
    
    /**
* @Method  : checkSharingTest
* @Purpose : To check the sharing of object
*/
    @isTest
    public static void checkSharingTest(){
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        //Creating Pickup Option Record
        Pick_Up_Options__c pickUpObj = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment2');
        Sales_Organisation__c salesOrg = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        insert salesOrg;
        pickUpObj.Sales_Organisation__c=salesOrg.Id;
        //pickUpObj.Type__c= 'Local-Segment2';
        pickUpObj.RecordTypeId =  Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        insert pickUpObj ;
        system.assert(pickUpObj.Id != null,'pickUpObj should not be null');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;        
        Test.startTest();
        
        
        pickUpObj.Geography__c = secCountry.Id;
        pickUpObj.Sales_Organisation__c=salesOrg.Id;
        pickUpObj.Name = 'Gold[AU1]';
        update pickUpObj;        
        delete pickUpObj;
        undelete pickUpObj;
        Test.stopTest();
    }
    @isTest
    public static void markforDeletion()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        List<Pick_Up_Options__c>pickUpOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c	pickUpOption= EDGE_UtilityTestClass.getPickUpOption(countryId,'Consumer Segmentation');
        pickUpOptions.add(pickUpOption);
        pickUpOption.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Consumer Segmentation').getRecordTypeId();
        Pick_Up_Options__c	pickUpOption1= EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickUpOptions.add(pickUpOption1);
        insert pickUpOptions;
        system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        system.assert(pickUpOption1.Id != null,'pickUpOption1 should not be null');
        /*outlet = EDGE_UtilityTestClass.getOutletRecord();  
outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;    
outlet.Minimum_Activation_Standards__c = 90.00;
outlet.Minimum_Product_Assortment__c = 40.00;
outlet.Global_Channel__c = 'Off Trade';
outlet.Global_Sub_Channel__c ='Retailer';
outlet.Global_Segment__c = 'Discounter';
outlet.Global_Sub_Segment__c = 'Modern Discounter';
outlet.Status__c ='Active';
outlet.Country__c = contId;*/
        Account account = EDGE_UtilityTestClass.getOutletRecord();
        account.Name='Outlet 1';
        account.Consumer_Segmentation__c = pickUpOption.Id;
        account.Outlet_Visit_Prioritisation_Grade__c = pickUpOption1.Id;
        account.Country__c = countryId;
        account.Status__c='Active';
        
        insert account;
        Test.startTest();
        try{
            pickUpOption.Status__c='Marked for Deletion';
            update pickUpOption;
        }
        catch(Exception e){
 System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
       
        
        Test.stopTest();
    }
    @isTest
    public static void markforDeletion1()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c	pickUpOption= EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment2');
        pickUpOption.RecordTypeId=  Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        
        insert pickUpOption;
        system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        pickUpOption.Status__c='Marked for Deletion';
        Test.startTest();
        update pickUpOption;
        Test.stopTest();
    }
    @isTest
    public static void markforDeletion2()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        List<Pick_Up_Options__c> pickUpOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c	pickUpOption= new Pick_Up_Options__c();
        pickUpOption.Name='Silver[AUT]';
        pickUpOption.Geography__c=countryId;
        pickUpOption.RecordTypeId=Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Consumer Segmentation').getRecordTypeId();
        pickUpOption.Type__c='Consumer Segmentation';
        pickUpOption.Status__c='Active';
        pickUpOptions.add(pickUpOption);
        //pickUpOption.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c	pickUpOption1= EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickUpOptions.add(pickUpOption1);
        insert pickUpOptions;
        system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        system.assert(pickUpOption1.Id != null,'pickUpOption1 should not be null');
        
        Account account = EDGE_UtilityTestClass.getOutletRecord();
        account.Name='Outlet 1';
        account.Consumer_Segmentation__c = pickUpOption.Id;
        account.Outlet_Visit_Prioritisation_Grade__c = pickUpOption1.Id;
        account.Country__c = countryId;
        account.Status__c='Active';
        
        insert account;
        Test.startTest();
        system.assert(account.Id != null,'account should not be null');
        try{
            pickUpOption.Status__c='Marked for Deletion';
            update pickUpOption;
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        
        Test.stopTest();
    }
    @isTest
    public static void markforDeletion3()
    {
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
       List<Pick_Up_Options__c> pickUpOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c	pickUpOption= new Pick_Up_Options__c();
        pickUpOption.Name='Silver[AUT]';
        pickUpOption.Geography__c=countryId;
        pickUpOption.RecordTypeId=Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Consumer Segmentation').getRecordTypeId();
        pickUpOption.Type__c='Consumer Segmentation';
        pickUpOption.Status__c='Active';
        pickUpOptions.add(pickUpOption);
        //pickUpOption.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c	pickUpOption1= EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickUpOptions.add(pickUpOption1);
        insert pickUpOptions;
        system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        system.assert(pickUpOption1.Id != null,'pickUpOption1 should not be null');
                
        Account account = EDGE_UtilityTestClass.getOutletRecord();
        account.Name='Outlet 1';
        account.Consumer_Segmentation__c = pickUpOption.Id;
        account.Outlet_Visit_Prioritisation_Grade__c = pickUpOption1.Id;
        account.Country__c = countryId;
        account.Status__c='Active';
        Test.startTest();
        insert account;
        try{
            pickUpOption.Status__c='Marked for Deletion';
            
            update pickUpOption;
            system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        Test.stopTest();
    }
    @isTest
    public static void markforDeletion4()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        List<Pick_Up_Options__c> pickUpOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c	pickUpOption= new Pick_Up_Options__c();
        pickUpOption.Name='Silver[AUT]';
        pickUpOption.Geography__c=countryId;
        pickUpOption.RecordTypeId=Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Consumer Segmentation').getRecordTypeId();
        pickUpOption.Type__c='Consumer Segmentation';
        pickUpOption.Status__c='Active';
        pickUpOptions.add(pickUpOption);
        //pickUpOption.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c	pickUpOption1= EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickUpOptions.add(pickUpOption1);
        insert pickUpOptions;
        system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        system.assert(pickUpOption1.Id != null,'pickUpOption1 should not be null ');
        
        Account account = EDGE_UtilityTestClass.getOutletRecord();
        account.Name='Outlet 1';
        account.Consumer_Segmentation__c = pickUpOption.Id;
        account.Outlet_Visit_Prioritisation_Grade__c = pickUpOption1.Id;
        account.Country__c = countryId;
        account.Status__c='Active';
        
        insert account;
        try{
            pickUpOption.Status__c='Marked for Deletion';
            Test.startTest();
            update pickUpOption;
            system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void markProductforDeletionTest()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c	pickUpOption= EDGE_UtilityTestClass.getPickUpOption(countryId,'Product Type');
        pickUpOption.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Product Type').getRecordTypeId();
        insert pickUpOption;
        
        
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Product_Type__c = pickUpOption.Id;
        product.Country__c = countryId;
        
        insert product;
        try{
            pickUpOption.Status__c='Marked for Deletion';
            update pickUpOption;
            system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void markOpportunityTemplateforDeletionTest()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id clusterRecTypeId = mapGeographyRecordTypes.get('Cluster').getRecordTypeId();
        
        Pick_Up_Options__c	pickUpOption= EDGE_UtilityTestClass.getPickUpOption(countryId,'MAS');
        pickUpOption.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        insert pickUpOption;
        system.assert(pickUpOption.Id != null,'pickUpOption should not be null');
        
        
        
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Service';
        insert territory;
        system.assert(territory.Id != null,'territory should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id hubId = geoMap.get('Hub');
        Geography__c cluster = createGeography('Cluster');
        cluster.Name = 'Australia1';
        cluster.Code__c = 'AUT1';
        cluster.Parent_Geography__c = hubId;
        cluster.RecordTypeId=clusterRecTypeId;
        insert cluster;
        Test.startTest();
        Opportunity_Template__c oppTem = new Opportunity_Template__c();
        oppTem.Cluster__c = geoMap.get('Cluster');
        oppTem.Opportunity_Type__c = 'Cycle Brief';
        OppTem.Action__c = 'TestAction';
        OppTem.Start_Date__c = System.today();
        oppTem.Closing_Method__c = 'Manual';
        OppTem.Weight_Type__c = 'Manual Value';
        OppTem.Activation__c = pickUpOption.Id;
        OppTem.Territory__c = territory.Id;   
        OppTem.End_Date__c = System.today()+10;        
        OppTem.Segment__c = 'Supermarket';
        OppTem.Sub_Segment__c = 'Reserve Supermarket';        
        OppTem.Channel__c = 'Off Trade';        
        opptem.Activation__c = pickUpOption.Id;
        insert oppTem;
        
        try{
            pickUpOption.Status__c='Marked for Deletion';
            update pickUpOption;
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        
        Test.stopTest();
    }
    @isTest
    public static void markDeletionSurveyKPITest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id bonusRecordTypeId = Schema.SObjectType.Bonus_Detail__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId();
        Bonus_Header__c bonusHeader= new Bonus_Header__c();
        bonusHeader.Country__c = countryId;
        insert bonusHeader;
        
        Pick_Up_Options__c	pickUpOption= EDGE_UtilityTestClass.getPickUpOption(countryId,'Survey KPI');
        pickUpOption.RecordTypeId=  Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        insert pickUpOption; 
        
        Bonus_Detail__c bonusDetail = new Bonus_Detail__c();
        bonusDetail.RecordTypeId = bonusRecordTypeId;
        bonusDetail.KPI_Type__c = 'Survey';
        bonusDetail.Weight__c = 20;
        bonusDetail.Bonus_Header__c = bonusHeader.Id;  
        bonusDetail.Survey_KPI__c = pickUpOption.Id;
        insert bonusDetail;
        system.assert(bonusDetail.Id!=null,'bonusDetail should not be null');
        try{
            pickUpOption.Status__c = 'Marked for Deletion';
            update pickUpOption;
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        Test.stopTest();
    }
    
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
    @isTest
    public static void insertTest(){
        
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('EU');
        
        List<Pick_Up_Options__c> insertPickUpOptionsRB = new List<Pick_Up_Options__c>();
        
        Pick_Up_Options__c	pickUpOption= getRBPickUpOption(countryId);
        pickUpOption.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Category').getRecordTypeId();
        pickUpOption.Reason_Category_Name__c='RB Reason Category';
        Insert pickUpOption;
        system.assert(pickUpOption.Id != null,'pickUpOption should not be null');

        //Id countryId2 = EDGE_UtilityTestClass.setupCountry('AU');
        Pick_Up_Options__c	pickUpOption2= getRBPickUpOption(countryId);
        pickUpOption2.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Code').getRecordTypeId();
        pickUpOption2.Reason_Category__c = pickUpOption.id;
        pickUpOption2.Reason_Code_Name__c='RB Reason Code';
        pickUpOption2.Name = '[AU]';
        insertPickUpOptionsRB.add(pickUpOption2);
        
        //Id countryId3 = EDGE_UtilityTestClass.setupCountry('GB');
        Pick_Up_Options__c	pickUpOption3= getRBPickUpOption(countryId);
        pickUpOption3.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Quality Resolution Code').getRecordTypeId();
        pickUpOption3.Resolution_Code_Name__c='Quality Resolution Code';
        pickUpOption3.Name = '[GB]';
        insertPickUpOptionsRB.add(pickUpOption3);
        
        //Id countryId4 = EDGE_UtilityTestClass.setupCountry('AFR');
        Pick_Up_Options__c	pickUpOption4= getRBPickUpOption(countryId);
        pickUpOption4.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Quality Reason Code').getRecordTypeId();
        pickUpOption4.Reason_Code_Name__c='Quality Reason Code';
        pickUpOption4.Name = '[AFR]';
        insertPickUpOptionsRB.add(pickUpOption4);
        
        insert insertPickUpOptionsRB;
        test.startTest();
        List<Pick_Up_Options__c> updatePickUpList = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c	pickUpRbUpdate1= getRBPickUpOption(countryId);
        pickUpRbUpdate1.Id = pickUpOption.Id;
        pickUpRbUpdate1.Reason_Category_Name__c='RB Reason Category Update';
        updatePickUpList.add(pickUpRbUpdate1);
        
        Pick_Up_Options__c	pickUpRbUpdate2= getRBPickUpOption(countryId);
        pickUpRbUpdate2.Id = pickUpOption2.Id;
        pickUpRbUpdate2.Reason_Category__c=null;
        pickUpRbUpdate2.Reason_Code_Name__c='Reason Code Update';
        updatePickUpList.add(pickUpRbUpdate2);
        
        Pick_Up_Options__c	pickUpRbUpdate3= getRBPickUpOption(countryId);
        pickUpRbUpdate3.Id = pickUpOption3.Id;
        pickUpRbUpdate3.Resolution_Code_Name__c='Quality Resolution Update';
        updatePickUpList.add(pickUpRbUpdate3);
        
        Pick_Up_Options__c	pickUpRbUpdate4= getRBPickUpOption(countryId);
        pickUpRbUpdate4.Id = pickUpOption4.Id;
        pickUpRbUpdate4.Reason_Code_Name__c='Quality Reason Update';
        updatePickUpList.add(pickUpRbUpdate4);
        update updatePickUpList;
        test.stopTest();
    }
    private static Pick_Up_Options__c getRBPickUpOption(Id countryId){
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = '[EU]';
        pOption.Geography__c = countryId;
        return pOption;
    }
    
}