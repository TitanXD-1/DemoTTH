@isTest
public class Test_MD_RegistrationMapping {
    
    @isTest
    public static void testSubmitRequestForApproval(){
        Map<String, SObject> dataMap = getDataMap();
        MD_JSONResponse response = MD_RegistrationMapping.submitRequestForApproval(dataMap);
        
        System.assert(response.status);
        System.assertEquals(2, [SELECT count() FROM Account]);
        System.assertEquals(1, [SELECT count() FROM Contact]);
        System.assertEquals(1, [SELECT count() FROM AccountContactRelation]);
    }   
    
    static Map<String, SObject> getDataMap(){
              
        Map<String, Geography__c> geos  = TestFactory_MD_Account.createGeographies();
        Geography__c countryData = geos.get('Country');
        insert new Pick_Up_Options__c(Name = 'N0[ES]', Geography__c = countryData.Id, Type__c = 'Outlet Visit Prioritization');
        
        Account accountData = new Account(Name = 'TestCompanyName'
                                          , Region__c = geos.get('Region').Id
                                          , Area__c = geos.get('Area').Id
                                          , Country__c = geos.get('Country').Id
                                          , Hub__c = geos.get('Hub').Id
                                          , Market__c = geos.get('Market').Id
                                          , VAT_Number__c = '123456789'
                                          , BillingStreet = 'Evergreen 123'
                                          , BillingPostalCode = '1111'
                                          , BillingCity = 'Madrid'
                                          , Global_Channel__c = 'On Trade'
                                          , Global_Sub_Channel__c = 'On trade'
                                          , Global_Segment__c = 'Bars'
                                          , Global_Sub_Segment__c = 'Modern Bars'
                                         );
        
        Contact contactData = new Contact(FirstName = 'TestFirstName',
                                          LastName = 'TestLastName',
                                          Email = 'test@test.com',
                                          mobilePhone = '1123456789'
                                         );  
        
        Map<String, SObject> dataMap = new Map<String,SObject>();
        dataMap.put('Account', accountData);
        dataMap.put('Contact', contactData);
        dataMap.put('Geography__c', countryData);
        return dataMap;
    }
    
}