/**
Name: ECM_TerritoryBudgetHandler_Test

Purpose: This class is used to cover test data for the - ECM_TerritoryBudgetHandler

History                                                                                                                     
VERSION    AUTHOR          DATE              DETAIL
1.0		Saurav Prasad   26/11/2020		Updated - ECM-2190

**/
@isTest
public class ECM_TerritoryBudgetHandler_Test {
    
    @isTest 
    public static void test1(){
        Test.startTest();
        
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
        system.assert(usr.Id != null,'usr should not be null');
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
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy;UoM;';
            insert contractType;
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=BannerRecordTypeId;
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
            objContract7.ECM_Duration__c=12;
            objContract7.ECM_Hybrid_UOS_PerTerm__c=3;
            objContract7.ECM_Total_Upfront_Payment_Loan_Over_Term__c=2;
            objContract7.Contract_End_Date__c = system.today()+360;
            objContract7.ECM_Overall_Investment_Amount__c=30.00;
            insert objContract7;
            
            Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
            insert territory;
            Territory_Hierarchy__c territoryHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
            insert TerritoryHierarchy;
            
            testterritory.Business_Unit__c=TerritoryHierarchy.id;
            update testterritory;
            
            Territory_Budget__c territoryBudget = new territory_Budget__c();
            TerritoryBudget.ECM_Type__c =  'TI';
            TerritoryBudget.Territory__c = territory.id;
            TerritoryBudget.End_Date__c = system.today()+5;
            TerritoryBudget.Initial_Amount__c = 100.00;
            TerritoryBudget.Start_Date__c = system.today()+10;
            TerritoryBudget.ECM_Territory_Hierarchy__c = TerritoryHierarchy.id;
            
            Territory_Budget__c territoryBudget1 = new Territory_Budget__c();
            TerritoryBudget1.ECM_Type__c =  'A&P';
            TerritoryBudget1.Territory__c = testterritory.id;
            TerritoryBudget1.End_Date__c = system.today()+5;
            TerritoryBudget1.Initial_Amount__c = 100.00;
            TerritoryBudget1.Start_Date__c = system.today()+10;
            TerritoryBudget1.ECM_Territory_Hierarchy__c = TerritoryHierarchy.id;
            
            try{
                insert TerritoryBudget;
            }
            catch(Exception ex){
                
                insert TerritoryBudget1;
                
            }
            Test.stopTest();
        }
    }
    @isTest 
    public static void test2(){
        Test.startTest();
        
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
        system.assert(usr.Id != null,'usr should not be null');
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
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy;UoM;';
            insert contractType;
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=BannerRecordTypeId;
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
            objContract7.ECM_Duration__c=12;
            objContract7.ECM_Hybrid_UOS_PerTerm__c=3;
            objContract7.ECM_Total_Upfront_Payment_Loan_Over_Term__c=2;
            objContract7.Contract_End_Date__c = system.today()+360;
            objContract7.ECM_Overall_Investment_Amount__c=30.00;
            insert objContract7;
            
            Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
            insert territory;
            Territory_Hierarchy__c territoryHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
            insert TerritoryHierarchy;
            
            testterritory.Business_Unit__c=TerritoryHierarchy.id;
            update testterritory;
            
            Territory_Budget__c territoryBudget = new Territory_Budget__c();
            TerritoryBudget.ECM_Type__c =  'TI';
            TerritoryBudget.Territory__c = territory.id;
            TerritoryBudget.End_Date__c = system.today()+5;
            TerritoryBudget.Initial_Amount__c = 100.00;
            TerritoryBudget.Start_Date__c = system.today()+10;
            TerritoryBudget.ECM_Territory_Hierarchy__c = TerritoryHierarchy.id;
            
            Territory_Budget__c territoryBudget1 = new Territory_Budget__c();
            TerritoryBudget1.ECM_Type__c =  'A&P';
            TerritoryBudget1.Territory__c = testterritory.id;
            TerritoryBudget1.End_Date__c = system.today()+5;
            TerritoryBudget1.Initial_Amount__c = 100.00;
            TerritoryBudget1.Start_Date__c = system.today()+10;
            TerritoryBudget1.ECM_Territory_Hierarchy__c = TerritoryHierarchy.id;
            
            try{
                insert TerritoryBudget1;
                TerritoryBudget1.Territory__c = territory.id; 
                update TerritoryBudget1;
            }
            catch(Exception ex){
                
                system.debug(LoggingLevel.Debug,'Handled Exception');
                
            }
            Test.stopTest();
        }
    }
}