/**
 * @description : This test class is to cover ECM_ContentDocumentLinkTriggerHelper and its related helper classes

* @history :
1.0      Chandrakanth Suram  	  18/02/2021        ECM-3950 
2.0      Joshraj Sen              05/04/2023        152305 SCA Fix
*/

@isTest
public without sharing class ECM_ContentDocumentLinkTriggerHelperTest {
    @testSetup static void setup() {
        Test.startTest();
        
        test.stopTest();
    }
    @isTest
    public static void updateRecordType(){
        Test.startTest();
        //try{
        Profile prof = [select id from profile where name=: 'Legal User'];
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
        usr.Title='Legal';
        insert usr;
        
        System.runAs(usr){   
            
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
            //Territory Hierarchy records creation for all different recordtypes
            string buRecType = 'Business Unit';
            Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, buRecType);
            insert terrHierBsUnitobj; 
            string saRecType = 'Sales Area';
            Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, saRecType);
            terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
            insert terrHierSalAreaobj;
            string reRecType = 'Region';
            Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, reRecType);
            terrHierRegionobj.Parent_BU__c=terrHierSalAreaobj.Id;
            insert terrHierRegionobj;
            
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Region__c = terrHierRegionobj.Id;
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            insert outletAccount;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Rate Per UoM;Investment';
            insert contractType;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract7 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract7.Status = 'Draft';
            objContract7.Contract_End_Date__c = System.today();
            objContract7.AccountId=outletAccount.Id;
            objContract7.ECM_Territory__c=testterritory.Id;
            objContract7.ECM_Agreement_Type__c=contractType.Id;
            objContract7.recordTypeId=contractRecordTypeId;
            objContract7.ECM_Channel__c='On-Premise';
            objContract7.StartDate = system.today();
            objContract7.ECM_Duration__c=12;
            objContract7.ECM_Hybrid_UOS_PerTerm__c=3;
            objContract7.ECM_Total_Upfront_Payment_Loan_Over_Term__c=2;
            objContract7.Contract_End_Date__c = system.today()+360;
            objContract7.ECM_Overall_Investment_Amount__c=30.00;
            insert objContract7;
            objContract7.Status = 'In Signing Customer';
            update objContract7;
            
            ECM_Addendum__c addendumRec = new ECM_Addendum__c();
            addendumRec.Name='Test';
            addendumRec.ECM_Contract__c = objContract7.Id;
            addendumRec.ECM_Status__c = 'Draft';
            Insert addendumRec;
            addendumRec.ECM_Status__c = 'Approved';
            addendumRec.ECM_New_T_C__c = 'Checking';
            Update addendumRec;
            
            ECM_Addendum__c addendumObj = new ECM_Addendum__c();
            addendumObj=[Select id,ECM_Contract__c,ECM_Contract__r.id,ECM_New_T_C__c from ECM_Addendum__c where id =:addendumRec.id];
            
            System.assert(outletAccount.Id != null,'Outlet is Added');
            EDGE_UtilityTestClass.createOrgSettings();
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.Title = 'Test.jpeg';
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Others').getRecordTypeId();
            conVerRec.Content_Type__c = 'Other';
            insert conVerRec;
            System.assert(conVerRec.Id != null,'Content Version is Added');
            /*conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
conVerRec.Content_Type__c = 'Amended T&C';
Database.upsert(conVerRec);*/
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'Size Matches');
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (addendumObj.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'Condition Matched');
            
        }
        
        /*}catch(Exception ex){
//Checking file type update validation
System.debug('Exception :'+ex);

}*/
        Test.stopTest();
        
    }
}