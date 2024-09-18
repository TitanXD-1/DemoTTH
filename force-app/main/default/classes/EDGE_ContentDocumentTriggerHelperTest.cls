/*
*	@description: EDGE_ContentDocumentTriggerHelperTest
*	@purpose: This is the test class for ContentDocumentTrigger,ContentDocumentTriggerHandler,
	EDGE_ContentDocumentTriggerHelper
*	@History :
*	@VERSION       AUTHOR            DATE              DETAIL
*	1.0   Monalisa Halder     22/03/2019      Initial Development
*/
@isTest
public with sharing class EDGE_ContentDocumentTriggerHelperTest {
    
    
    @isTest
    public static void updateContentDocument(){
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUS'); 
        Account disAccrec = EDGE_UtilityTestClass.getDistriAccRec();
        insert disAccrec;
        System.assert(disAccrec.Id != null,'disAccrec should not be null');
        
        Promotion__c promoRec = EDGE_UtilityTestClass.getPromotionRecord(geographyId);
        insert promoRec;
        System.assert(promoRec.Id != null,'promoRec should not be null');
        Test.startTest();
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.pdf');
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
        conVerRec.Content_Type__c = 'Promotional PDF';
        conVerRec.Title = 'PromotionalPDF.jpeg';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec should not be null');
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (promoRec.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        
        ContentVersion conVerRec1 = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
        conVerRec1.ContentDocumentId = documents[0].Id; 
        
        
        
        try{
            insert conVerRec1;
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
            //Checking file type update validation
            System.Assert(ex.getMessage()!= null,'ex should not be null');
        }
        Test.stopTest();
        
        
    }
    
    /*
Method  : updateAccountDetailsTest
Purpose : This methods used to cover updateContentVersionId method for Account
*/
    @isTest
    public static void updateAccountDetailsTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        //try{
        Id geographyId;
        geographyId = EDGE_UtilityTestClass.setupCountry('AUS'); 
        Account disAccrec = EDGE_UtilityTestClass.getDistriAccRec();
        insert disAccrec;
        System.assert(disAccrec.Id != null,'disAccrec should not be null');
        Test.startTest();
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('OutletImage_1234.jpeg');
        conVerRec.Title = 'OutletImage_1234.jpeg';
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        conVerRec.Content_Type__c = 'Outlet Image';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec should not be null');           
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (disAccrec.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        
        
        
        /*  }catch(Exception ex){
System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
//Checking file type update validation
//System.Assert(ex.getMessage().contains(Label.PromotionalPdf),'Message should contains the label value');
}*/
        Test.stopTest();
        
    }
    
    /*
Method  : updateAccountDetailsTest
Purpose : This methods used to cover negative scenario of updateContentVersionId method
*/
    @isTest
    public static void updateAccountDetailsToRunCatchPartTest() {
        Map<Id,Sobject> mapContentVer = new Map<Id,Sobject>{null => new ContentDocumentLink()};
            System.assert(mapContentVer != null,'mapContentVer should not be null');
        EDGE_ContentDocumentTriggerHelper.updateContentVersionId(mapContentVer);
        
    }
    
    /*
Method  : oppTemplateTest
Purpose : This is used to cover Opportunity_Template__c method
*/
    @isTest
    public static void oppTemplateTest(){        
        Test.startTest();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUS');
        
        Territory_Hierarchy__c businessUnit = new Territory_Hierarchy__c();
        businessUnit.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        businessUnit.Name = 'AUS';
        businessUnit.Geography__c = geographyId;
        insert businessUnit;
        
        Territory_Hierarchy__c salesArea = new Territory_Hierarchy__c();
        salesArea.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        salesArea.Name = 'SOU';
        salesArea.Parent_BU__c = businessUnit.Id;
        salesArea.Geography__c = geographyId;
        insert salesArea;
        
        Territory_Hierarchy__c region = new Territory_Hierarchy__c();
        region.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        region.Name = 'FSM VIC NORTH';
        region.Parent_BU__c = salesArea.Id;
        region.Geography__c = geographyId;
        insert region;
        
        Territory__c objTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        objTerritory.Region__c = region.Id;
        insert objTerritory;
        
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        insert objProduct;
        
        Opportunity_Template__c objOppTemplate = EDGE_UtilityTestClass.getOpportunityTemplate(objProduct.Id, objTerritory.Id, geographyId);
        insert objOppTemplate;
        
        EDGE_UtilityTestClass.createOrgSettings();
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle1234.jpeg');
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Opportunity Template').getRecordTypeId();
        conVerRec.Content_Type__c = 'Opportunity Template Image';
        conVerRec.Title = 'OutletRes.jpeg';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec should not be null');           
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (objOppTemplate.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        
        Test.stopTest();
    }
    /*
Method  : upsertDirectCustomerData
Purpose : This methods used to cover upsertDirectCustomerData method for Account
*/
    @isTest
    public static void upsertDirectCustomerData(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        //  try{
        Id geographyId;
        geographyId = EDGE_UtilityTestClass.setupCountry('AUS'); 
        Account disAccrec = EDGE_UtilityTestClass.getDistriAccRec();
        insert disAccrec;
        Test.startTest();
        System.assert(disAccrec.Id != null,'disAccrec should not be null');
        
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
        conVerRec.Title = 'Test.jpeg';
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        conVerRec.Content_Type__c = 'Direct Customer';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec should not be null');           
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (disAccrec.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        
        
        
        /*    }catch(Exception ex){
System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
//Checking file type update validation

}*/
        Test.stopTest();
        
    }
    
    @isTest
    public static Map<String,Id> insertGeoMap(){
        EDGE_UtilityTestClass.createOrgSettings();   
        Map<String,Id> geoMap=new Map<String,Id>();
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Asiapac';
        market.Code__c = 'APAT';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        System.assert(market.Id!=null,'Market Id should not be null');
        geoMap.put('Market',market.Id);
        return geoMap;
    }
    
    /*
Method  : insertClaimDataTest
Purpose : This methods used to cover readOnlyAttach method
*/
    @isTest
    public static void insertClaimDataTest1(){
        Map<String,Id> geoMap=new Map<String,Id>();
        geoMap.putAll(insertGeoMap());
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Australia Hub';
        hub.Code__c = 'AUHT';
        hub.Parent_Geography__c = geoMap.get('Market');
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Australia Cluster';
        cluster.Code__c = 'AUCT';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Australia';
        country.Code__c ='AU';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Australia1';
        area.Code__c = 'SAU1';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Australia2';
        region.Code__c = 'SAU2';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        Id countryId=country.Id; 
        Sales_Organisation__c salesOrg = new Sales_Organisation__c();
        salesOrg.Name='Test';
        salesOrg.Description__c='test';
        salesOrg.Code__c='BE01';
        salesOrg.Country__c=countryId;
        insert salesOrg;
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c =false;
        update orgSetting;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        List<Pick_Up_Options__c> pickupOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        pickupOptions.add(pickupOption);
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Tax Code');
        pickupOption1.Name = 'Gold[AU]';
        pickupOption1.RecordTypeId = pickupRecordType1 ;
        pickupOption1.Status__c = 'Active';
        pickupOption1.CST_Tax_Rate__c= 10;
        pickupOption1.CST_Type__c = 'A&P'; 
        pickupOption1.CST_Default_record__c = true;
        pickupOption1.Sales_Organisation__c= salesOrg.Id;
        pickupOptions.add(pickupOption1);
        upsert pickupOptions;               
        Account directCustomer =new Account();
        directCustomer.Name='Direct Customer';
        directCustomer.RecordTypeId=Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId(); 
        directCustomer.Country__c = geoMap.get('Country');
        directCustomer.Hub__c = geoMap.get('Hub');
        directCustomer.Region__c=geoMap.get('Region');
        directCustomer.Area__c=geoMap.get('Area');
        directCustomer.Market__c = geoMap.get('Market');
        directCustomer.Cluster__c= geoMap.get('Cluster');
        directCustomer.BillingCountry='Australia';
        insert directCustomer;
        orgSetting.Run_Triggers__c =true;
        update orgSetting;
        Test.startTest();
        directCustomer.Direct_Customer__c=true;
        directCustomer.Sales_Organisation__c=salesOrg.Id;
        update directCustomer;
        //System.runAs(usr){
        Profile prof = [select id from profile where name=: 'System Administrator'];
        Profile prof1 = [select id from profile where name=: 'CST Approver'];
        List<User> managers=new List<User>();
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcmMngr@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='AU';
        managers.add(usrmngr);
        User usrmngr1 = new User();
        usrmngr1.firstName = 'testManager';
        usrmngr1.lastName = 't2';
        usrmngr1.profileId = prof1.id;        
        usrmngr1.email = 'test.Mamager@test.com';
        usrmngr1.Username ='testcmMngr@test11.com';
        usrmngr1.Alias='test';
        usrmngr1.Timezonesidkey='America/Los_Angeles';
        usrmngr1.LocaleSidKey='en_US';
        usrmngr1.LanguageLocaleKey='en_US';
        usrmngr1.EmailEncodingKey='UTF-8';
        usrmngr1.Available_Countries__c='AU';
        managers.add(usrmngr1);
        insert managers;
        List<User> reps=new List<User>();        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.ManagerId = usrmngr.Id;
        reps.add(usr);
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof1.id;        
        usr1.email = 'test@test.com';
        usr1.Username ='testcm123@test22.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='AU';
        usr1.ManagerId = usrmngr1.Id;
        reps.add(usr1);
        insert reps;
        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, directCustomer.Id);
        claim.CST_Sales_Organisation__c=salesOrg.Id;
        claim.OwnerId = usr.Id;
        insert claim;
        claim.CST_Country__c=countryId;
        claim.CST_Invoice_Number__c='1';
        claim.CST_Invoice_Date__c=System.today()-2;
        claim.CurrencyIsoCode= 'AUD';
        claim.CST_Approver__c=usr.id;
        claim.CST_Account__c=directCustomer.Id;
        claim.CST_Total_Amount__c=10;
        claim.Claim_Tax_Code__c= pickupOption1.id;
        //claim.OwnerId = usr1.Id;
        claim.CST_Sales_Organisation__c=salesOrg.Id;
        //claim.CST_Status__c='Assigned to Default Approver';
        update claim;        
        System.runAs(usr){
            claim.CST_Status__c = 'Assigned to Default Approver';
            claim.CST_Approver__c=usrmngr.id;
            claim.OwnerId = usrmngr.id;
            update claim;   
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.Title = 'Test.jpeg';
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('CSTClaim').getRecordTypeId();
            //conVerRec.Content_Type__c = 'CSTClaim';
            insert conVerRec;
            //System.assert(conVerRec.Id != null,'conVerRec should not be null');                      
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'documents should match');            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (claim.Id,documents[0].Id);
            insert conDocLnkRec;      
            Test.stopTest();
        }
    }
    
     @isTest
    public static void updatePaymentFieldsTest(){
        //change made by Aparajita ES20-9665
          User newUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
          insert newUser;
          System.runAs(newUser){
              List<ContentDocument> adminDocuments = new List<ContentDocument>();
              Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
              EDGE_UtilityTestClass.createOrgSettings();
              
              Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
              objPickUp.Name = 'Gold[AUT]';
              insert objPickUp;
              
              Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
              outletAccount.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;                  
              insert outletAccount;
              
              ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
              contractType.Name='Promotional';
              contractType.Geography__c=geographyId;
              contractType.ECM_Abbreviation__c='POM';
              contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
              contractType.Volume_UoM_for_Spirits__c='CAS';
              contractType.ECM_Mandatory_Fields_Check__c='After Customer Signed';
              contractType.ECM_Screen_3_field_configuration__c='Product Name;UoM;Volume Target';
              contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
              insert contractType;
              
              String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
              
              Pick_Up_Options__c banner= new Pick_Up_Options__c();
              banner.Name='Range[ES]';
              banner.Geography__c=geographyId;
              banner.RecordTypeId=bannerRecordTypeId;
              
              String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
              Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
              objContract.Status = 'Draft';
              objContract.Contract_End_Date__c = System.today()+29;
              objContract.AccountId=outletAccount.Id;
              objContract.ECM_Overall_Investment_Amount__c=100020.55;
              objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
              objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
              objContract.ECM_Overall_Investment_Figure__c=122.43;
              objContract.ECM_Agreement_Type__c=contractType.Id;
              objContract.recordTypeId=contractRecordTypeId;
              objContract.ECM_Channel__c='On-Premise';
              objContract.StartDate = system.today();
              objContract.Contract_End_Date__c = system.today()+360;           
              insert objContract;                  
              objContract.status='Approved';
              update objContract;                  
              
              ECM_Payment_Summary__c paySummary =ECM_UtilityTestClass.getPaymentSummary(objContract.Id);
              insert paySummary;
              ContentVersion payConVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle12345.jpeg');
              payConVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Payments').getRecordTypeId();
              payConVerRec.Content_Type__c = 'Evidence';
              payConVerRec.Title = 'Signed_Contract.jpeg';                  
              insert payConVerRec;
              ContentVersion payConVerRec1 = EDGE_UtilityTestClass.gerConVerRec('Outle12345.jpeg');
              payConVerRec1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Payments').getRecordTypeId();
              payConVerRec1.Content_Type__c = 'Invoice';
              payConVerRec1.Title = 'Signed_Contract.jpeg';                  
              insert payConVerRec1;
              
              Test.startTest();
              
              List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
              System.assertEquals(documents1.size(), 2,'documents1 should match');
              ContentDocumentLink conDocLnkRecPay = EDGE_UtilityTestClass.getConDocLink (paySummary.Id,documents1[0].Id);
              insert conDocLnkRecPay;
              ContentDocumentLink conDocLnkRecPay1 = EDGE_UtilityTestClass.getConDocLink (paySummary.Id,documents1[1].Id);
              insert conDocLnkRecPay1;
              
              delete conDocLnkRecPay1;
              System.assert(conDocLnkRecPay.Id != null,'conDocLnkRecPay should not be null');
              Test.stopTest();
              
              adminDocuments = documents1.clone();
              delete adminDocuments;
              
              
              
          }
    }
}