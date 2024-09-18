@isTest
public class ECM_Request_T_and_C_Controller_Test {
	@isTest
    static void outletcreation(){
         Profile prof = [select id from profile where name=: 'Sales Representative'];
        User user = new User();
        user.firstName = 'test1';
        user.lastName = 'test2';
        user.profileId = prof.id;        
        user.email = 'test@test.com';
        user.Username ='testcm123@test.com';
        user.Alias='test';
        user.Timezonesidkey='America/Los_Angeles';
        user.LocaleSidKey='en_US';
        user.LanguageLocaleKey='en_US';
        user.EmailEncodingKey='UTF-8';
        user.Available_Countries__c='ES';
        insert user;
        system.assert(user.Id != null,'user Id should not be null');
        system.runAs(user){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        Geography__c geoId=[Select Id,Name from Geography__c where id=:geographyId];
         geoId.Name='Spain';
        update geoId;
        //user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        //insert newuser;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy;UoM;';
        insert contractType;
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = geographyId;
        pOption.Type__c = 'Local-Segment2';
        pOption.RecordTypeId = PickupRecordTypeId;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        insert pOption;
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
		budgetTypeObj1.Name='Upfront Payment [AU]';
		budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.Status__c = 'Active';
		budgetTypeObj1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
		insert budgetTypeObj1;

        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        ECM_Contract_Item__c eCI = new ECM_Contract_Item__c();
        eCI.ECM_MAT_override__c = 20.00;
        eCI.ECM_Contract__c = con.id;
        eCI.ECM_MAT_UOS__c = 20.00;
        eCI.ECM_Total_GP__c = 20.00;
        eCI.ECM_Total_COGS__c = 20.00;
        eCI.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI.ECM_Total_GP_ON__c = 20.00;
        insert eCI; 
       
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geoId.Id);
         mktSetting.ECM_Legal_Notifications__c='test@test.com';
        insert mktSetting;        
        ECM_Request_T_and_C_Controller.getcontractdetails(con.Id);  
       
        ECM_Request_T_and_C_Controller.submitAddendumRequest(con.Id,'test');
        }
    }
}