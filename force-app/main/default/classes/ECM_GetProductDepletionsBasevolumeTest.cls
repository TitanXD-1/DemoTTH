/*
Name: ECM_GetProductDepletionsBasevolumeTest

*Purpose: This class is used to cover testclass for the - ECM_Get_Product_Depletions_Basevolume
*History                                                            
                                                            
*VERSION      AUTHOR                  DATE                DETAIL
*1.0      Saurav Kumar Prasad      27/05/2020        Initial Development

*/
@isTest
public class ECM_GetProductDepletionsBasevolumeTest {
    
    @isTest 
    public static void test1(){
        
        //ECM_CreateContractController_Test.createOutletContractTest();
        Test.startTest();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'ES';
        insert testAdminUser;
        Profile prof = [select id from profile where name=: 'Sales Representative'];
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
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        System.assert(usr!=null,'usr should not be null');
        
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
            // Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
            insert contractType;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            //outletAccount.Operator__c=contractType.id;
            insert outletAccount;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract7 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract7.Status = 'Draft';
            objContract7.Contract_End_Date__c = System.today();
            objContract7.AccountId=outletAccount.Id;
            objContract7.ECM_Territory__c=testterritory.Id;
            //objContract7.ECM_Contract_Type__c=contractType.Id;
            objContract7.ECM_Agreement_Type__c=contractType.Id;
            objContract7.recordTypeId=contractRecordTypeId;
            objContract7.ECM_Channel__c='On-Premise';
            objContract7.ECM_Banner__c=banner.Id;
            objContract7.StartDate = system.today();
            objContract7.Contract_End_Date__c = system.today()+360;
            objContract7.ECM_Overall_Investment_Amount__c=30.00;
            insert objContract7;
            
            Product__c product = new Product__c();
            product.Product_Full_Name__c='Test';
            product.Country__c=geographyId;
            insert product;
            Product_UOM__c prdtUOM = new Product_UOM__c();
            prdtUOM.Product__c = product.Id;
            prdtUOM.Conversion_Factor__c = 2;
            prdtUOM.Unique_ID__c = 'LK';
            insert prdtUOM;
            
            Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
            marketassort.Product__c=product.Id;
            marketassort.Market_Assortment__c=geographyId;
            //marketassort.ECM_Strategy__c='2';
            insert marketassort;
            
            List<ECM_Contract_Item__c> contractItemslist = new List<ECM_Contract_Item__c>();
            
            ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
            newcontractitem.ECM_Contract__c=objContract7.Id;
            newcontractitem.ECM_Product__c=marketassort.id;
            insert newcontractitem;
            contractItemslist.add(newcontractitem);
            System.runAs(testAdminUser){
            Depletions__c dep = new Depletions__c();
            dep.ECM_Volume__c = 100.00;
            dep.ECM_Outlet__c = outletAccount.id;
            dep.ECM_Start_Period__c = system.today()-25;
            dep.ECM_End_Period__c = system.today()-10;
            dep.ECM_Product__c = product.id;
            dep.ECM_Outlet__c = outletAccount.Id;
            insert dep;
            
            
            Depletions__c dep1 = new Depletions__c();
            dep1.ECM_Volume__c = 100.00;
            dep1.ECM_Outlet__c = outletAccount.id;
            dep1.ECM_Start_Period__c = system.today()-25;
            dep1.ECM_End_Period__c = system.today()-10;
            dep1.ECM_Product__c = product.id;
            dep1.ECM_Outlet__c = outletAccount.Id;
            insert dep1;
            }
            Outlet_Contract__c outletContract = new Outlet_Contract__c();
            outletContract.Contract__c = objContract7.Id;
            outletContract.Outlet__c = outletAccount.Id;
            insert outletContract;
            
            ECM_CreateContractController.get_contractitem_with_exsisiting_baseVol(contractItemslist);
        }
        Test.stopTest();
    }
       
    @isTest 
    public static void test2(){
        

        Test.startTest();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'ES';
        insert testAdminUser;
        Profile prof = [select id from profile where name=: 'Sales Representative'];
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
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        System.assert(usr!=null,'usr should not be null');
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
            // Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
            insert contractType;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            //outletAccount.Operator__c=contractType.id;
            insert outletAccount;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract7 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract7.Status = 'Draft';
            objContract7.Contract_End_Date__c = System.today();
            objContract7.AccountId=outletAccount.Id;
            objContract7.ECM_Territory__c=testterritory.Id;
            //objContract7.ECM_Contract_Type__c=contractType.Id;
            objContract7.ECM_Agreement_Type__c=contractType.Id;
            objContract7.recordTypeId=contractRecordTypeId;
            objContract7.ECM_Channel__c='On-Premise';
            objContract7.ECM_Banner__c=banner.Id;
            objContract7.StartDate = system.today();
            objContract7.Contract_End_Date__c = system.today()+360;
            objContract7.ECM_Overall_Investment_Amount__c=30.00;
            insert objContract7;
            
            Product__c product = new Product__c();
            product.Product_Full_Name__c='Test';
            product.Country__c=geographyId;
            insert product;
            Product_UOM__c prdtUOM = new Product_UOM__c();
            prdtUOM.Product__c = product.Id;
            prdtUOM.Conversion_Factor__c = 2;
            prdtUOM.Unique_ID__c = 'PK';
            insert prdtUOM;
            
            Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
            marketassort.Product__c=product.Id;
            marketassort.Market_Assortment__c=geographyId;
            //marketassort.ECM_Strategy__c='2';
            insert marketassort;
            
            List<ECM_Contract_Item__c> contractItemslist = new List<ECM_Contract_Item__c>();
            
            ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
            newcontractitem.ECM_Contract__c=objContract7.Id;
            newcontractitem.ECM_Product__c=marketassort.id;
            insert newcontractitem;
            contractItemslist.add(newcontractitem);
            System.runAs(testAdminUser){
            Depletions__c dep = new Depletions__c();
            dep.ECM_Volume__c = 100.00;
            dep.ECM_Outlet__c = outletAccount.id;
            dep.ECM_Start_Period__c = system.today()-25;
            dep.ECM_End_Period__c = system.today()-10;
            dep.ECM_Product__c = product.id;
            dep.ECM_Outlet__c = outletAccount.Id;
            insert dep;
            }
            
            Outlet_Contract__c outletContract = new Outlet_Contract__c();
            outletContract.Contract__c = objContract7.Id;
            outletContract.Outlet__c = outletAccount.Id;
            insert outletContract;
            
            Geography__c geo=[select name from geography__c where id=:geographyId];
            geo.Name='Spain';
            update geo;
            
            ECM_CreateContractController.get_contractitem_with_exsisiting_baseVol(contractItemslist);
            
            String contractGroupRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
            objContract7.recordTypeId=contractGroupRecordTypeId;
            update objContract7;
            
            ECM_CreateContractController.get_contractitem_with_exsisiting_baseVol(contractItemslist);
        }
        Test.stopTest();
        
        
    }
    
}