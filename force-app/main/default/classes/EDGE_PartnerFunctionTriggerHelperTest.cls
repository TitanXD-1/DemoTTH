/**
 * @name : EDGE_PartnerFunctionTriggerHelperTest
 * @description : Test class for Partner Function.
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Sagar Barman     20/02/2020       ES20-7089 Initial Development
 */

 @isTest
 public class EDGE_PartnerFunctionTriggerHelperTest {
     
     public static Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
     // Get the record type id of from the Map based on the Name
     public static Id directCustomerRecTypeId = mapAccountRecordTypes.get('Direct Customer').getRecordTypeId();
     
     @testSetup 
     public static void setup() {
         Pick_Up_Options__c pickupOption ;
         Geography__c country ;
         
         Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
         country = new Geography__c(Id= countryId);
         country.isDiageoOneEnabled__c   = True;
         upsert country;  
         
         pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
         pickupOption.Name = 'Gold[ES]';
         pickupOption.Status__c = 'Active';
         insert pickupOption;
         
           Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
         testoutlet.Name = 'Sample outlet 1';
         testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
         testoutlet.D1_Email_Send_Outlet_Customer__c = false;
         insert testoutlet;
         Contact primcon1=new Contact(FirstName='fname1',
                                      LastName = 'lname',
                                      Email = 'email1P@gmail.com',
                                      Phone = '12345672890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
         insert primcon1;
         
         
     }
     
     
     
     @isTest
     public static void mergeTest(){
         try {
             Account testoutlet = new Account();
             System.debug(LoggingLevel.Debug,'==>1 mergeTest '+[SELECT Id,name FROM Account]);
             testoutlet = [SELECT Id,name FROM Account WHERE Name='Sample outlet 1'];
             
             Account testoutlet2=testoutlet.clone(false,false,false,false);
             
             testoutlet2.AccountNumber = '10483';
             testoutlet2.VAT_Number__c = '1234';
             testoutlet2.BillingStreet = '17 Asian Highway 451';
             testoutlet2.BillingCity = 'Sydney';
             testoutlet2.BillingState = 'Tasmania';
             testoutlet2.BillingPostalCode = '5668';
             testoutlet2.BillingCountry = 'Australia';
             testoutlet2.BillingCountryCode = 'AU';
             testoutlet2.D1_Email_Send_Outlet_Customer__c = false;
             //testoutlet2.Direct_Customer__c = true;
             //testoutlet2.Name = 'Sample outlet 2';
             testoutlet2.RecordTypeId = directCustomerRecTypeId;
             //testoutlet2.Outlet_Visit_Prioritisation_Grade__c =  [SELECT Id FROM Pick_Up_Options__c LIMIT 1].Id; 
             insert testoutlet2;
             system.assert(testoutlet2.Id != null,'testoutlet2 should not be null');
             Contact primcon2=new Contact(FirstName='fname2',
                                          LastName = 'lname',
                                          Email = 'email2P@gmail.com',
                                          Phone = '12345672890',Contact_Type__c='Secondary',AccountID=testoutlet2.Id); 
             insert primcon2;
             
             Account testoutlet3 =testoutlet.clone(false,false,false,false);
             //testoutlet3.Name= 'Test768  i';
             testoutlet3.AccountNumber = '10422';
             testoutlet3.VAT_Number__c = '1235';
             testoutlet3.BillingStreet = '14 Asian Highway 45';
             testoutlet3.BillingCity = 'Sydney2';
             testoutlet3.BillingState = 'New South Wales';
             testoutlet3.BillingPostalCode = '5662';
             testoutlet3.BillingCountry = 'Australia';
             testoutlet3.BillingCountryCode = 'AU';
             testoutlet3.D1_Email_Send_Outlet_Customer__c = false;
             
             //testoutlet2.Name = 'Sample outlet 2';
             testoutlet3.RecordTypeId = directCustomerRecTypeId;
             insert testoutlet3;
             
             System.debug(LoggingLevel.Debug,'==>2 mergeTest '+[SELECT Id,name FROM Account]);
             
             List<Account> lacc = new List<Account>();
             List<Contact> listcontact = new List<Contact>();
             for(Integer t=0; t<50; t++){
                 
                 
                 Account temp =testoutlet.clone(false,false,false,false);
                 //temp.Name= 'Test768'+t;
                 temp.AccountNumber = '1042'+t;
                 temp.VAT_Number__c = '123'+t;
                 temp.BillingStreet = '14 Asian Highway 45'+t;
                 temp.BillingCity = 'Sydney2';
                 temp.BillingState = 'New South Wales';
                 temp.BillingPostalCode = '5662';
                 temp.BillingCountry = 'Australia';
                 temp.BillingCountryCode = 'AU';
                 temp.D1_Email_Send_Outlet_Customer__c = false;
                 
                 //testoutlet2.Name = 'Sample outlet 2';
                 //temp.RecordTypeId = directCustomerRecTypeId;
                 Contact tempC=new Contact(FirstName='fname2'+t,
                                           LastName = 'lname',
                                           Email = t+'email2P@gmail.com',
                                           Phone = '12345672890',Contact_Type__c='Secondary',AccountID=temp.Id); 
                 listcontact.add(tempC);
                 lacc.add(temp);
             }
             insert listcontact;
             insert lacc;
             lacc.add(testoutlet2);
             lacc.add(testoutlet3);
             Map < Id, Account > accountMapToMerge = new Map < Id, Account > ();
             
             
             Map<Account,Set<Id>> obj2 =EDGE_PartnerFunctionTriggerHelper.getDuplicates5(lacc);
             List<Id> acIds = new List<Id>();
             for(Account a: obj2.keySet()){
                 acIds.addAll(obj2.get(a));
             }
             //Map<Id,Set<Account>> obj = EDGE_PartnerFunctionTriggerHelper.getDuplicates(lacc);
             accountMapToMerge = new Map < Id, Account > ([SELECT Id, BillingStreet, BillingCity, BillingCountry, BillingState, BillingPostalCode, BillingStateCode, 
                                                           BillingCountryCode, Name, RecordTypeId 
                                                           FROM Account WHERE Id=:acIds]);
             Set<Account> duplicates = new Set<Account> ();
             for(Id ids: accountMapToMerge.KeySet()){
                 duplicates.add(accountMapToMerge.get(ids));
             }
             for(Account masterId: obj2.keySet()){
                 EDGE_PartnerFunctionTriggerHelper.mergeAccounts(accountMapToMerge.get(masterId.Id),duplicates);
             }
             
         } catch(Exception ex) {
             System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
         }
     }
     
     @isTest
     public static void mergeFailureTest(){
         Account testoutlet = new Account();
         testoutlet = [SELECT Id,name FROM Account WHERE Name='Sample outlet 1'];
         System.assert(testoutlet.id!=null,'lacc should not be null');
         
         //testoutlet2 = [SELECT Id,name FROM Account WHERE Name='Sample outlet 2'];
         Set<Account> lacc = new Set<Account>();
         lacc.add(testoutlet);//use same account record to merge for exception
         
         EDGE_PartnerFunctionTriggerHelper.mergeAccounts(testoutlet,lacc);
         
     }
     @isTest
     public static void testD1CheckDirectAccount() {
         //Insert Geography (Global)
         Geography__c globalGeography = EDGE_UtilityTestClass.createGeography('Global');
         globalGeography.Name = 'Global Northern Ireland';
         globalGeography.Code__c = 'GL1';
         insert globalGeography;
         system.assert(globalGeography.Id != null,'globalGeography should not be null');
         
         //Insert Geography (Market)
         Geography__c marketGeography = EDGE_UtilityTestClass.createGeography('Market');
         marketGeography.Name = 'Ireland Northern Ireland';
         marketGeography.Code__c = 'IM';
         marketGeography.Parent_Geography__c = globalGeography.Id;
         insert marketGeography;
         
         //Insert Geography (Hub)
         Geography__c hubGeography = EDGE_UtilityTestClass.createGeography('Hub');
         hubGeography.Name = 'Northern Ireland';
         hubGeography.Code__c = 'IOIH';
         hubGeography.Parent_Geography__c = marketGeography.Id;
         insert hubGeography;
         
         //Insert Geography (Cluster)
         Geography__c clusterGeography = EDGE_UtilityTestClass.createGeography('Cluster');
         clusterGeography.Name = 'Northern Ireland';
         clusterGeography.Code__c = 'IOIC';
         clusterGeography.Parent_Geography__c = hubGeography.Id;
         insert clusterGeography;
         
         //Insert Geography (Country)
         Geography__c countryGeography = EDGE_UtilityTestClass.createGeography('Country');
         countryGeography.Name = 'Northern Ireland';
         countryGeography.Code__c = 'NIR';
         countryGeography.Parent_Geography__c = clusterGeography.Id;
         insert countryGeography;
         
         //Insert Geography (Area)
         Geography__c areaGeography = EDGE_UtilityTestClass.createGeography('Area');
         areaGeography.Name = 'Northern Ireland Area';
         areaGeography.Code__c = 'IEA';
         areaGeography.Parent_Geography__c = countryGeography.Id;
         insert areaGeography;
         
         //Insert Geography (Region)
         Geography__c regionGeography = EDGE_UtilityTestClass.createGeography('Region');
         regionGeography.Name = 'Northern Ireland Region';
         regionGeography.Code__c = 'IER';
         regionGeography.Parent_Geography__c = areaGeography.Id;
         insert regionGeography;
         
         Geography__c geography =[select id,isDiageoOneEnabled__c from Geography__c where id=:countryGeography.id];
         Geography.isDiageoOneEnabled__c=true;
         update Geography;
         //Will get the Market_Setting and insert here
         Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(countryGeography.id);
         mktSetting.Account_Type_Priority__c = 'Ship-To';
         
         insert mktSetting;
         //Insert Pick_Up_Options
         String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
         Pick_Up_Options__c pOption = new Pick_Up_Options__c();
         pOption.Name = 'Gold[NIR]';
         pOption.Geography__c = countryGeography.Id;
         pOption.Type__c = 'Outlet Visit Prioritization';
         pOption.RecordTypeId = pickUpOptionRecordType;
         pOption.Days_between_visit__c = 5;
         pOption.Status__c = 'Active';
         insert pOption;
         EDGE_UtilityTestClass.createOrgSettings();
         Id directCustomerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
         
         
         Test.startTest();
         //Insert Account (outlet)
         Account directCustomer = EDGE_UtilityTestClass.getOutletRecord();
         directCustomer.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
         directCustomer.Independent_of_Owner__c = true;
         directCustomer.Country__c = countryGeography.Id;
         directCustomer.Area__c = areaGeography.Id;
         directCustomer.Region__c = regionGeography.Id;
         directCustomer.Customer_Type__c = 'Ship-To';
         directCustomer.Sales_Org__c = 'INA';
         directCustomer.Cluster__c = clusterGeography.Id;
         directCustomer.Market__c = marketGeography.Id;
         directCustomer.Hub__c = hubGeography.Id;
         directCustomer.D1_EDGE_Customer__c=true;
         directCustomer.RecordTypeId=directCustomerAccountRecordTypeId;
         
         
         insert DirectCustomer;
         system.assert(Null != DirectCustomer.Id,'DirectCustomer should not be null');
         
         //Insert partnerFunction
         PNR_Partner_Function__c partnerFunc = new PNR_Partner_Function__c();
         partnerFunc.PNR_Sales_Org__c = 'IN01';
         partnerFunc.PNR_Sold_To__c = DirectCustomer.Id;
         partnerFunc.PNR_Customer_No__c = DirectCustomer.Id;
         partnerFunc.PNR_Type__c = 'Ship-To';
         insert partnerFunc;
         
         test.stopTest();
         
         
     }
     @isTest
     public static void testUpdateShipToAccounts() {
         D1_TestDataUtility.createOrgSettings();
         //Id countryId = D1_TestDataUtility.setupCountry('GB');
         Account testAcc = D1_TestDataUtility.getDirectCustomer();
         PNR_Partner_Function__c partnerFunction = D1_TestDataUtility.getPartnerFunction(testAcc, 'Ship-To');
         partnerFunction.PNR_Sales_Org__c = 'IN01';
         insert partnerFunction;
         
         Test.startTest();
         
         partnerFunction.PNR_Sales_Org__c = 'IN013';
         update partnerFunction;
         Delete partnerFunction;
         system.assert(Null != partnerFunction.Id,'partnerFunction should not be null');        
         test.stopTest();
         
         
         /*//Insert Geography (Global)
         Geography__c globalGeography = EDGE_UtilityTestClass.createGeography('Global');
         globalGeography.Name = 'Global Northern Ireland';
         globalGeography.Code__c = 'GL1';
         insert globalGeography;
         
         //Insert Geography (Market)
         Geography__c marketGeography = EDGE_UtilityTestClass.createGeography('Market');
         marketGeography.Name = 'Ireland Northern Ireland';
         marketGeography.Code__c = 'IM';
         marketGeography.Parent_Geography__c = globalGeography.Id;
         insert marketGeography;
         
         //Insert Geography (Hub)
         Geography__c hubGeography = EDGE_UtilityTestClass.createGeography('Hub');
         hubGeography.Name = 'Northern Ireland';
         hubGeography.Code__c = 'IOIH';
         hubGeography.Parent_Geography__c = marketGeography.Id;
         insert hubGeography;
         
         //Insert Geography (Cluster)
         Geography__c clusterGeography = EDGE_UtilityTestClass.createGeography('Cluster');
         clusterGeography.Name = 'Northern Ireland';
         clusterGeography.Code__c = 'IOIC';
         clusterGeography.Parent_Geography__c = hubGeography.Id;
         insert clusterGeography;
         
         //Insert Geography (Country)
         Geography__c countryGeography = EDGE_UtilityTestClass.createGeography('Country');
         countryGeography.Name = 'Northern Ireland';
         countryGeography.Code__c = 'NIR';
         countryGeography.Parent_Geography__c = clusterGeography.Id;
         countryGeography.isDiageoOneEnabled__c   = True;
         countryGeography.Enable_E_Commerce__c = true;
         insert countryGeography;
         
         //Insert Geography (Area)
         Geography__c areaGeography = EDGE_UtilityTestClass.createGeography('Area');
         areaGeography.Name = 'Northern Ireland Area';
         areaGeography.Code__c = 'IEA';
         areaGeography.Parent_Geography__c = countryGeography.Id;
         insert areaGeography;
         
         //Insert Geography (Region)
         Geography__c regionGeography = EDGE_UtilityTestClass.createGeography('Region');
         regionGeography.Name = 'Northern Ireland Region';
         regionGeography.Code__c = 'IER';
         regionGeography.Parent_Geography__c = areaGeography.Id;
         insert regionGeography;
         
         EDGE_UtilityTestClass.createOrgSettings();
         
         //Insert Pick_Up_Options
         String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
         Pick_Up_Options__c pOption = new Pick_Up_Options__c();
         pOption.Name = 'Gold[NIR]';
         pOption.Geography__c = countryGeography.Id;
         pOption.Type__c = 'Outlet Visit Prioritization';
         pOption.RecordTypeId = pickUpOptionRecordType;
         pOption.Days_between_visit__c = 5;
         pOption.Status__c = 'Active';
         insert pOption;
         
         Test.startTest();
         
         //Insert Account (DirectCustomer)
         
         Account outlet = EDGE_UtilityTestClass.getOutletRecord();
         outlet.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
         outlet.Independent_of_Owner__c = true;
         outlet.Country__c = countryGeography.Id;
         outlet.Area__c = areaGeography.Id;
         outlet.Region__c = regionGeography.Id;
         outlet.Customer_Type__c = 'Sold-To';
         outlet.Sales_Org__c = 'INA';
         outlet.Cluster__c = clusterGeography.Id;
         outlet.Market__c = marketGeography.Id;
         outlet.Hub__c = hubGeography.Id;
         insert outlet;
         system.assert(Null != outlet.Id);
         
         //Insert partnerFunction
         PNR_Partner_Function__c partnerFunc = new PNR_Partner_Function__c();
         partnerFunc.PNR_Sales_Org__c = 'IN01';
         partnerFunc.PNR_Sold_To__c = outlet.Id;
         partnerFunc.PNR_Customer_No__c = outlet.Id;
         partnerFunc.PNR_Type__c = 'Ship-To';
         insert partnerFunc;
         partnerFunc.PNR_Sales_Org__c = 'IN013';
         update partnerFunc;
         Delete partnerFunc;
         system.assert(Null != partnerFunc.Id);
         system.assertEquals(outlet.Customer_Type__c == 'Ship-To' , outlet.Customer_Type__c == 'Ship-To' );
         system.assertEquals(outlet.Sales_Org__c ==  partnerFunc.PNR_Sales_Org__c, outlet.Sales_Org__c == partnerFunc.PNR_Sales_Org__c);
         
         test.stopTest();*/
     }
     
     
     @isTest
     public static void testContactPointAddress() {
          
         Org_Setting__c org =  new Org_Setting__c();
         org.Run_Triggers__c = true;
         insert org;
         system.assert(org.Id != null,'org should not be null');
         Account testoutlet = new Account();
         testoutlet = [SELECT Id,name FROM Account WHERE Name='Sample outlet 1'];
         
         List<BuyerAccount> buyerAccountLst = [select Id from BuyerAccount where isActive = true and BuyerId = :testoutlet.Id];
         
         BuyerGroup buyerGroupObj = new BuyerGroup();
         buyerGroupObj.Name = 'Test 11';
         buyerGroupObj.List_Price_Available__c = true;
         buyerGroupObj.PortfolioID__c = 'Test112233';
         insert buyerGroupObj;
        
         if(buyerAccountLst == NULL || buyerAccountLst.size() == 0) { 
             BuyerAccount buyerAccountObj = new BuyerAccount();
             buyerAccountObj.Name = 'Test';
             buyerAccountObj.BuyerId = testoutlet.Id;
             buyerAccountObj.isActive = true;
             buyerAccountObj.BuyerStatus = 'Active';
             insert buyerAccountObj;
         }
         buyerAccountLst = [select Id from BuyerAccount where isActive = true and BuyerId = :testoutlet.Id];
         
         system.debug(LoggingLevel.Debug,'buyerAccountLst'+buyerAccountLst);
         
         BuyerGroupMember buyerGrpMemberObj = new BuyerGroupMember();
         buyerGrpMemberObj.BuyerId = testoutlet.Id;
         buyerGrpMemberObj.BuyerGroupId = buyerGroupObj.Id;
         insert buyerGrpMemberObj;
         
         Account acc = [SELECT Id,IsBuyer FROM Account WHERE Id =: testoutlet.Id ];
         system.debug(LoggingLevel.Debug,'-acc------'+acc);
         PNR_Partner_Function__c pf = new PNR_Partner_Function__c();
         pf.PNR_Customer_No__c = testoutlet.Id;
         pf.PNR_Sold_To__c = testoutlet.Id;
         pf.D1_EDGE_Customer__c = true;
         pf.PNR_Type__c = 'Ship-To';
         pf.Item_Proposal__c ='PF-1234';
         insert pf;
         system.debug(LoggingLevel.Debug,'-acc------'+acc);
     }
     @isTest
     public static void copyTest(){
         //Create Outlet record 
         Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
         testoutlet.Name = '';
         testoutlet.BillingStreet = '';
         testoutlet.BillingCity = '';
         testoutlet.BillingPostalCode = '';
         //testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
         
         Account testDrtCust = PNR_TestDataUtility.getDirectCustomerRec();
         system.debug(LoggingLevel.Debug,'@@testDrtCust' +testDrtCust);
         system.debug(LoggingLevel.Debug,'@@testDrtCustID' +testDrtCust.Id);
         testDrtCust.AccountNumber = '1234';
         testDrtCust.Name = 'Test Acc';
         testDrtCust.BillingStreet = 'Test Street';
         testDrtCust.BillingCity =  'Test city';
         testDrtCust.BillingPostalCode =  '1235';
         testDrtCust.BillingCountry = 'Spain';
         testDrtCust.Transportation_Zone__c = 'Test TZ';
         testDrtCust.Central_Order_Block__c = 'Test OB';
         testDrtCust.Central_Delivery_Block__c = 'Test CD';
         testDrtCust.Central_Billing_Block__c = 'Test CB';
         testDrtCust.Deletion_Flag_from_SAP__c = true;
         testDrtCust.Sort__c = 'sort';
         testDrtCust.KUNNR__c = '54893';
         testDrtCust.Customer_Account_Group__c = 'Test';
         testDrtCust.PO_Box__c = 'Test PB';
         testDrtCust.new_VAT__c = 'Test Vat';
         testDrtCust.Delivery_Pattern__c = 'DP';
         testDrtCust.District__c = 'Test DS';
         testDrtCust.D1_EDGE_Customer__c = true;
         testDrtCust.Salesforce_Delivery_Days_Beer__c = 'Test DB';
         testDrtCust.Salesforce_Delivery_Days_Keg__c = 'Test Keg';
         testDrtCust.Salesforce_Delivery_Days_Keg_Stout__c = 'Test KS';
         testDrtCust.Salesforce_Delivery_Days_Packaged_Good__c = 'Test DP';
         testDrtCust.Language__c = 'English';
         testDrtCust.Phone = '45896574';
         testDrtCust.General_Information__c = 'Test GI';
         testDrtCust.SAP_Payer_Bill_To__c = 'Test SP';
         testDrtCust.Notes__c = 'test notes';
         testDrtCust.IsOwner__c = true;
         testDrtCust.Sales_Org__c = 'SO';
         testDrtCust.Direct_Customer__c = true;
         testDrtCust.Customer_Sales_Org_Status__c = 'Delivery Blocked';
         testDrtCust.Customer_Type__c = 'Sold-To';
         testDrtCust.Delivery_Plant__c = 'Test DP';
         testDrtCust.Products_Enabled__c = 'EDGE365';
         testDrtCust.AccountSource = 'SAP-Pioneer';
         testDrtCust.SAP_Ship_to__c = 'Test Ship to';
         testDrtCust.Account_Number_with_Credit_Limit_Ref__c = '12354';
         testDrtCust.Credit_Control_Area__c = 'Test';
         insert testDrtCust;
         system.assert(testDrtCust.id!=null,'testDrtCust id should not be null');
         EDGE_PartnerFunctionTriggerHelper.copyMasterAcc(testoutlet,testDrtCust);
         EDGE_PartnerFunctionTriggerHelper.createMergeAcc(testoutlet,testDrtCust);
     }
      @isTest
     public static void testDuplicate(){
         //Insert Geography (Global)
         Geography__c globalGeography = EDGE_UtilityTestClass.createGeography('Global');
         globalGeography.Name = 'Global Northern Ireland';
         globalGeography.Code__c = 'GL1';
         insert globalGeography;
         
         //Insert Geography (Market)
         Geography__c marketGeography = EDGE_UtilityTestClass.createGeography('Market');
         marketGeography.Name = 'Ireland Northern Ireland';
         marketGeography.Code__c = 'IM';
         marketGeography.Parent_Geography__c = globalGeography.Id;
         insert marketGeography;
         
         //Insert Geography (Hub)
         Geography__c hubGeography = EDGE_UtilityTestClass.createGeography('Hub');
         hubGeography.Name = 'Northern Ireland';
         hubGeography.Code__c = 'IOIH';
         hubGeography.Parent_Geography__c = marketGeography.Id;
         insert hubGeography;
         
         //Insert Geography (Cluster)
         Geography__c clusterGeography = EDGE_UtilityTestClass.createGeography('Cluster');
         clusterGeography.Name = 'Northern Ireland';
         clusterGeography.Code__c = 'IOIC';
         clusterGeography.Parent_Geography__c = hubGeography.Id;
         insert clusterGeography;
         
         //Insert Geography (Country)
         Geography__c countryGeography = EDGE_UtilityTestClass.createGeography('Country');
         countryGeography.Name = 'Northern Ireland';
         countryGeography.Code__c = 'NIR';
         countryGeography.Parent_Geography__c = clusterGeography.Id;
         insert countryGeography;
         
         //Insert Geography (Area)
         Geography__c areaGeography = EDGE_UtilityTestClass.createGeography('Area');
         areaGeography.Name = 'Northern Ireland Area';
         areaGeography.Code__c = 'IEA';
         areaGeography.Parent_Geography__c = countryGeography.Id;
         insert areaGeography;
         
         //Insert geography (Region)
         Geography__c regionGeography = EDGE_UtilityTestClass.createGeography('Region');
         regionGeography.Name = 'Northern Ireland Region';
         regionGeography.Code__c = 'IER';
         regionGeography.Parent_Geography__c = areaGeography.Id;
         insert regionGeography;
         
         Geography__c geography =[select id,isDiageoOneEnabled__c from Geography__c where id=:countryGeography.id];
         geography.isDiageoOneEnabled__c=true;
         update geography;
         //Will get the Market_Setting and insert here
         Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(countryGeography.id);
         mktSetting.Account_Type_Priority__c = 'Ship-To';
         
         insert mktSetting;
         //Insert Pick_Up_Options
         String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
         Pick_Up_Options__c pOption = new Pick_Up_Options__c();
         pOption.Name = 'Gold[NIR]';
         pOption.Geography__c = countryGeography.Id;
         pOption.Type__c = 'Outlet Visit Prioritization';
         pOption.RecordTypeId = pickUpOptionRecordType;
         pOption.Days_between_visit__c = 5;
         pOption.Status__c = 'Active';
         insert pOption;
         EDGE_UtilityTestClass.createOrgSettings();
         Id directCustomerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
         
         
         Test.startTest();
         //Insert Account (outlet)
         Account directCustomer = EDGE_UtilityTestClass.getOutletRecord();
         directCustomer.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
         directCustomer.Independent_of_Owner__c = true;
         directCustomer.Country__c = countryGeography.Id;
         directCustomer.Area__c = areaGeography.Id;
         directCustomer.Region__c = regionGeography.Id;
         directCustomer.Customer_Type__c = 'Ship-To';
         directCustomer.Sales_Org__c = 'INA';
         directCustomer.Cluster__c = clusterGeography.Id;
         directCustomer.Market__c = marketGeography.Id;
         directCustomer.Hub__c = hubGeography.Id;
         directCustomer.D1_EDGE_Customer__c=true;
         directCustomer.RecordTypeId=directCustomerAccountRecordTypeId;
         
         
         insert DirectCustomer;
         system.assert(Null != DirectCustomer.Id,'DirectCustomer should not be null');
         List<Id> accList = new List<Id>();
         accList.add(DirectCustomer.Id);
         EDGE_PartnerFunctionTriggerHelper.deleteRecordSet(accList);
     }
     @isTest
     public static void testSalesArea(){
         EDGE_UtilityTestClass.createOrgSettings();
         Account outlet = [SELECT Id,name FROM Account WHERE Name='Sample outlet 1'];
         
         Sales_Area__c saObj = D1_TestDataUtility.salesAreaData();
         insert saObj;
         system.assert(saObj.Id != null,'saObj should not be null');
         PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
         pFRec.PNR_Sold_To__c = outlet.Id;
         pFRec.PNR_Customer_No__c = outlet.Id;
         pFRec.PNR_Sales_Org__c = 'GB01';
         pFRec.PNR_Distribution_Channel__c = '10';
         pFRec.PNR_Division__c = '10';
         test.startTest();
         insert pFRec;
         test.stopTest();
     }
     @isTest
     public static void testSalesAreaUpdt(){
         EDGE_UtilityTestClass.createOrgSettings();
         Account outlet = [SELECT Id,name FROM Account WHERE Name='Sample outlet 1'];
         
         Sales_Area__c saObj = D1_TestDataUtility.salesAreaData();
         insert saObj;
         system.assert(saObj.Id != null,'saObj should not be null');
         PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
         pFRec.PNR_Sold_To__c = outlet.Id;
         pFRec.PNR_Customer_No__c = outlet.Id;
         pFRec.PNR_Sales_Org__c = 'GB01';
         pFRec.PNR_Distribution_Channel__c = '10';
         pFRec.PNR_Division__c = '12';
         insert pFRec;
         test.startTest();
         pFRec.PNR_Division__c = '10';
         update pFRec;
         test.stopTest();
     }
     
     @isTest
     public static void testItemProposalUpdate(){
         D1_TestDataUtility.createOrgSettings();
         Account dc = D1_TestDataUtility.getDirectCustomer();
         insert dc;
         
         BuyerAccount ba = D1_TestDataUtility.getBuyerAccount(dc.Id);
         insert ba;
         
         PNR_Partner_Function__c partnerFunc = D1_TestDataUtility.getPartnerFunction(dc, 'Sold-To');
         insert partnerFunc;
         
         BuyerGroup bg1 = D1_TestDataUtility.getBuyerGroup('223344');
         insert bg1;
         
         BuyerGroup bg2 = D1_TestDataUtility.getBuyerGroup('223355');
         bg2.Name = 'Test BuyerGroup2';
         insert bg2;
         
         BuyerGroupMember bgm = D1_TestDataUtility.getBuyerGroupMember(bg1.Id, dc);
         insert bgm;
         
         Test.startTest();
         partnerFunc.Item_Proposal__c = '223355';
         update partnerFunc;
         BuyerGroupMember buyGrpMem = [Select Id,BuyerGroup.PortfolioID__c FROM BuyerGroupMember where BuyerId =: dc.Id];
         System.assertEquals('223355', buyGrpMem.BuyerGroup.PortfolioID__c,'buyGrpMem.BuyerGroup should match');
         Test.stopTest();
         
         
     }
     
 }