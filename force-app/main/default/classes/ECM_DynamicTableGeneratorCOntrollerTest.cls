/*
Name: ECM_DynamicTableGeneratorCOntrollerTest
*
Purpose: This class is used to cover test data for the - ECM_DynamicTableGeneratorCOntroller
*
History                                                            
*
VERSION			AUTHOR					DATE				DETAIL 
1.0			Inayathulla Md			20/05/2020			Initial Development
2.0			Anivesh Muppa			19/07/2021			As part of ECM-4621	
2.1			Saurav Prasad			13/12/2022			ECM-6558 : QA Defect_Total Investment Amount is not populating in PDF  
*/
@istest
public class ECM_DynamicTableGeneratorCOntrollerTest {
    @testSetup
    static void testData(){
        Id geographyIdAU;
        geographyIdAU = EDGE_UtilityTestClass.setupCountry('ES');
        
        Profile prof = [select id from profile where name=: 'System Administrator'];
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc2@test.com';
        usr.Username ='test.MamagerSfdc2@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='de_DE';
        usr.LanguageLocaleKey='de';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='DE';
        insert usr;
      
    }
    @isTest
    static void testgetFieldApiNames(){
      	Geography__c geoRecord = [select id,code__c,Parent_Geography__c,RecordTypeId from Geography__c where code__c='ES' Limit 1];
        
        Id geographyId = geoRecord.id;//EDGE_UtilityTestClass.setupCountry('ES'); 
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Australia';
        country.Code__c = 'AU';
        country.Parent_Geography__c = geoRecord.Parent_Geography__c;
        country.RecordTypeId=Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        country.Extended_Country_Code__c = 'AU-AUS1';
        insert country;
        
        
        system.assert(country.Id != null,'country Id should not be null');
        String sobjectName = 'ECM_Contract_Item__c';
        List<String> selectfields = new List<String> {'Record ID','Contract Item Name','Volume'};
        ECM_DynamicTableGeneratorController.getFieldApiNames(sobjectName,selectfields);
        ECM_DynamicTableGeneratorController.getRecords(sobjectName,selectfields);
        ECM_Dynamic_Table_Generator__c dynaTableGen= new ECM_Dynamic_Table_Generator__c();
        dynaTableGen.Name='TEST';
        dynaTableGen.ECM_Object__c='ECM_Contract_Item__c';
        dynaTableGen.ECM_Geography__c = geographyId;
        dynaTableGen.ECM_Dynamic_Sales_Driver_Item_Column__c=true;
        dynaTableGen.ECM_Field_API_Names__c='ECM_Product_Name__c,ECM_Volume__c';
        dynaTableGen.ECM_Dynamic_Fields__c='Product Name;Forecast Volume;Annual Volume;';
        Insert dynaTableGen;
        
        User salesRep = [SELECT Id from User where username='test.MamagerSfdc2@test.com'];
        
        DynaTableGen.ECM_Object__c='ECM_Sales_Driver_Item_Detail__c';
        DynaTableGen.ECM_Dynamic_Fields__c='Investment Amount;Total Investment Amount;Information;Payment Frequency Type';
        System.runAs(salesRep){
            update DynaTableGen;
        }
        DynaTableGen.ECM_Object__c='Outlet_Contract__c';
        DynaTableGen.ECM_Field_API_Names__c='ECM_Outlet_Name__c,ECM_Outlet_Street__c,ECM_Outlet_City__c';
        DynaTableGen.ECM_Dynamic_Fields__c='Outlet Name;Outlet Street;Outlet City';
        DynaTableGen.ECM_Geography__c = country.Id;//[select id,code__c from Geography__c where code__c='AU' Limit 1].Id;
        update DynaTableGen;
        
        Delete DynaTableGen;
        ECM_DynamicTableGeneratorController.lightningTableWrapper lwrap = new ECM_DynamicTableGeneratorController.lightningTableWrapper();
        lwrap.page=0;
    }
}