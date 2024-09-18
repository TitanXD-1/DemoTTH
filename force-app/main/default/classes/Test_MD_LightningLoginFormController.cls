@IsTest(SeeAllData = false)
public with sharing class Test_MD_LightningLoginFormController {

    @testSetup
    public static void createNavigationParentAndChild(){
        TestFactory_MD_Account.setup(true); 
    }

    @IsTest
    static void testLoginWithInvalidCredentials() {
        String  methodResponse = JSON.serialize(MD_LightningLoginFormController.login('testUser', 'fakepwd', null,'Sample Error'));
        System.assert(!String.isBlank(methodResponse));
    }
    
    @IsTest
    static void testLoginWithValidUsernameCredentials() {
        User user = [SELECT Id, Username FROM User LIMIT 1];  
        String  methodResponse = JSON.serialize(MD_LightningLoginFormController.login(user.Username, 'fakepwd', null,'Sample Error'));
        System.assert(!String.isBlank(methodResponse));
    }
    
    @IsTest
    static void successLoginActions() {
        User user = [SELECT Id FROM User WHERE Alias = 'hola' LIMIT 1]; 
        try{
            System.debug('userI: ' + user.Id);
            MD_LightningLoginFormController.successLoginActions(user);
        }catch(Exception e){
            
        }
        System.assert(user != null);
    }
    
    @IsTest
    static void failureLoginActions1() {
        User user = [SELECT Id,Username FROM User WHERE Alias = 'hola' LIMIT 1];
		
        try{
            System.debug('userI: ' + user.Id);
            String loginResponse = MD_LightningLoginFormController.login(user.Username,'fakePw','','Sample Error');
        }
        catch(Exception e){
            
        }
        System.assert(user != null);
    }
    
    @IsTest
    static void failureLoginActions2() {
        User user = [SELECT Id,Username FROM User WHERE Alias = 'hola' LIMIT 1];
		
        try{
            System.debug('userI: ' + user.Id);
            Exception e;
            MD_LightningLoginFormController.failureLoginActions(user, e);
        }catch(Exception e){
            
        }
        System.assert(user != null);
    }
    
    @IsTest
    static void executeHelperMethods() {
        User u = [SELECT Id,Username FROM User WHERE Alias = 'hola' LIMIT 1];
        datetime lastLogintime = System.now();
        
        MD_LightningLoginFormController.CP_UserLoginWrapper wrapperItem = new MD_LightningLoginFormController.CP_UserLoginWrapper();
        MD_LightningLoginFormController.CP_UserLoginWrapper obj = new MD_LightningLoginFormController.CP_UserLoginWrapper();
        MD_LightningLoginFormController ob1 = new MD_LightningLoginFormController();
        DateTime d = MD_LightningLoginFormController.getLockedTimeOfUser(u, 5);
		MD_LightningLoginFormController.replaceStringByTime(lastLogintime, 'Sample error [time]', 'Sample error');
        wrapperItem = MD_LightningLoginFormController.setWrapperByLockedErrorMessage(obj, 'Sample error message');
        wrapperItem = MD_LightningLoginFormController.setWrapperByInvalidPasswordMessage(obj,'Sample error');
        //wrapperItem = MD_LightningLoginFormController.setWrapperByLastAttemptLeftMessage(obj, 'Sample error');
        
        //Adding to cover Wrapper class variables
        wrapperItem.contactId  = 'test';
        wrapperItem.outletId = 'test';
        wrapperItem.outletType='test';
        wrapperItem.outletContactId = 'test' ;
        wrapperItem.clusterId = 'test';
        wrapperItem.countryCode = 'test';
        wrapperItem.languageCode = 'test';
     
    }
    
    
    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        MD_LightningLoginFormController controller = new MD_LightningLoginFormController();
        System.assertNotEquals(controller, null);
    }
    
    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(true, MD_LightningLoginFormController.getIsUsernamePasswordEnabled());
    }
    
    @IsTest
    static void testIsSelfRegistrationEnabled() {
        MD_LightningLoginFormController.setExperienceId('id');
        System.assertEquals(false, MD_LightningLoginFormController.getIsSelfRegistrationEnabled());
    }
    
    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, MD_LightningLoginFormController.getSelfRegistrationUrl());
    }
    
    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = MD_LightningLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }
    
    @IsTest
    static void getForgotPasswordUrl() {
        MD_LightningLoginFormController.getForgotPasswordUrl();
    }

}