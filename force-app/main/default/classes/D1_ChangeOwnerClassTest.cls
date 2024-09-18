/*
 * @name
 * @description
 * @History                                                                                                                       
 * VERSION     AUTHOR            DATE              DETAIL 
 * 1.1         Abhishek Jethi	  15/02/2021		NCP-1584(changeOwnerMethod)
 **/
@isTest
public class D1_ChangeOwnerClassTest {
    /**
     * @description 
     */    
    @testSetup
    public static void setup() {
        Test.startTest();
        User u = new User(
            ProfileId = [Select ID from Profile where Name ='Master Data Manager'].Id,
            LastName = 'lastabhitest',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert u;
        
        PermissionSet ps = [Select Id from PermissionSet where Name= 'D1_MDMs'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        Test.stopTest();
    }
    
    /**
     * @description 
     * @return  `boolean`
     */    
    @isTest
    public static void testChangeOwnerMethod() {
        String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        // Create Country
        final Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');

        Test.startTest();
        // Create Pickup Option
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[ES]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        // Create Outlet record 
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        testoutlet.RecordTypeId = outletRecordTypeId ;
        insert testoutlet;
        
      
        User u = [SELECT Id FROM User WHERE LastName = 'lastabhitest' LIMIT 1];
        System.runAs(u) {
            String str = D1_ChangeOwnerClass.changeOwner(testoutlet.Id);
            Boolean valueStr = Boolean.valueOf(str);
            System.assertEquals(valueStr, True, 'Assertion failed');
            D1_ChangeOwnerClass.changeOwner(null);
        }
        Test.stopTest();
    }
}