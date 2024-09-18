/**
 * @name D1_UserRegistrationDetailWrapperTest
 * @description Test Class for D1_UserRegistrationDetailWrapperTest Class.
 * @history
 * VERSION     AUTHOR           DATE           DETAIL
 * 1.0           -               -               -
 * 2.0         Rithika         15/07/2021     Test Class Refactor(NCP-3800)
**/

@isTest
public class D1_UserRegistrationDetailWrapperTest {
    /**
     * @description validateWrap method
     */    
    @isTest
    public static void validateWrap(){
            Id countryId = D1_TestDataUtility.setupCountry('ES');
            Geography__c country = new Geography__c(Id= countryId);
            upsert country; 
        	
            Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[ES]');
            insert pickupOption;
        	
        	D1_Setting__c d1setting = D1_TestDataUtility.createD1Settings(country);
        	
        	D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1setting.Id);
        	
        	Account testoutlet=D1_TestDataUtility.getDirectCustomer();
        	
        	Contact primcon2= D1_TestDataUtility.getContact(testoutlet.Id,'Secondary');
        	
			D1_UserRegistrationDetailWrapper userWrapper = new D1_UserRegistrationDetailWrapper();
            userWrapper.accountId = testoutlet.id;
            userWrapper.email = 'email1@gmail.com';
            userWrapper.firstName = 'John';
            userWrapper.lastName = 'Dario';
            userWrapper.mobile = '7895448';            
            userWrapper.languageLocaleKey= 'en_US';
            userWrapper.mobileCountryCode = 'ES';
            userWrapper.userCountryCode='ES';
            userWrapper.subscriptionValue = 'FrontendApp';
            userWrapper.contactId = primcon2.id;
            userWrapper.userType = d1UserType.id;
            userWrapper.d1SettingId = d1setting.id;
            userWrapper.subscriptionSource = 'FrontendApp';
            userWrapper.primarySalesRepEmail = 'abcd@diageo.com';
            userWrapper.accountNumber = '98798798';


        	userWrapper.description='test';
            userWrapper.city = 'test';
            userWrapper.phoneNumber = '9123456789';
        	userWrapper.area='test';
        	userWrapper.region ='test';
            userWrapper.areaName='test';
            userWrapper.regionName='test';
        	userWrapper.outletType ='test';
    		userWrapper.outletTypeId ='test';
    		userWrapper.outletSubType ='test';
            userWrapper.outletSubTypeURL ='test';
            userWrapper.customerSAPCode ='test';
             userWrapper.registrationType ='test';               
            userWrapper.uin ='test';
            userWrapper.leadType ='test';
        	userWrapper.survey ='test';
        	userWrapper.userPermission ='test';
            userWrapper.outletName='test';
            userWrapper.street = 'test';
            userWrapper.postalCode='test';
            userWrapper.countryCode='test';
            userWrapper.phoneNumberPrefix='test';
            System.assertEquals(userWrapper.email, 'email1@gmail.com', 'email not sent');
    }
}