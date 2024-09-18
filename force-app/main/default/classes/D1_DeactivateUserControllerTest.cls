@isTest
public class D1_DeactivateUserControllerTest {
    @future
    @testsetup
    public static void setup(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        System.assert( pickupOption!= null, 'pick up option not found'); 
        Account testoutlet=D1_TestDataUtility.getD1Customer();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.D1_Registration_Status__c = '';
        testoutlet.Current_Approval_Step__c ='';
        testoutlet.Status__c='';
        insert testoutlet;
        System.assert(testoutlet != null, 'test outlet not found');  
        D1_TestDataUtility.setUpExternalUser(testoutlet,'Outlet/Retailers');
        Contact con = [select Id from contact limit 1];
        AccountContactRelation acr = D1_TestDataUtility.returnACR(testoutlet.id,con.id);
        update acr;
    }
    @isTest
    public static void testDeactivation(){
        Contact con = [select Id from contact limit 1];
        Boolean result = D1_DeactivateUserController.deactivateUser(con.Id);
        System.assertEquals(result, True, 'result not true');
        Map<String,Boolean> mapResult = D1_DeactivateUserController.isPrimary(con.Id);
        System.assertEquals(mapResult.get('isActive'), False, 'user de-activation unsuccessful');
    }

}