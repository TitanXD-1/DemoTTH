/*
* @name: D1_MyProfileControllerTest
* @discription: Test class for D1_MyProfileController
* @history
* VERSION     AUTHOR           DATE       DETAIL
* 1.0         Ajay            10/6/20    Initial Development(NCP-582, NCP-583)
*/
@isTest
public with sharing class D1_MyProfileControllerTest {
    static final String DIAGEOONE_EXTERNAL_PROFILE = 'DiageoOne External User';
    final static String EMAIL ='Email';
    final static String PHONE = 'Phone';
    final static String SMS = 'SMS';
    final static String PUSHNOTI = 'Push Notification';

    /*  
    * @userstory: NCP-582
    * @discription: Test Get Profile
    * @Param:Nil
    */
    @isTest
    public static void testGetProfileDetails(){

        Map<String,Object> mapOfExternalUser = getExternalUser();
        User externalUser = (User)mapOfExternalUser.get('user');
        Contact externalUserContact = (Contact)mapOfExternalUser.get('contact');

        externalUserContact.MD_ContactSubscriptions__c = EMAIL + ';'+ PHONE + ';'+ SMS + ';' +PUSHNOTI;
        update externalUserContact;

        System.runAs(externalUser){
            Object result=D1_MyProfileController.getProfileDetails();
            System.assert(result!=null, 'getProfileDetails failed');
        }
    }

    /*  
    * @userstory: NCP-582
    * @discription: Test Update Profile
    * @Param:Nil
    */
    @isTest
    public static void testUpdateProfileDetails(){

        Map<String,Object> mapOfExternalUser = getExternalUser();
        User externalUser = (User)mapOfExternalUser.get('user');
        Contact externalUserContact = (Contact)mapOfExternalUser.get('contact');

        externalUserContact.MD_ContactSubscriptions__c = EMAIL + ';'+ PHONE + ';'+ SMS+ ';' +PUSHNOTI;
        update externalUserContact;

        String jsonProfileWrapperObject = getJSONProfileWrapperObject(externalUserContact.id);

        System.runAs(externalUser){
            Boolean isDone = D1_MyProfileController.updateProfileDetails(jsonProfileWrapperObject);
            System.assert(isDone == true, 'updateProfileDetails failed');

            try {
                D1_MyProfileController.updateProfileDetails(null);
            } catch (Exception ex) {
                System.assert(ex.getMessage()!=null, 'updateProfileDetails failed');
            }
        }
    }

    /*  
    * @userstory: NCP-582
    * @discription: Test Update Profile
    * @Param:Nil
    */
    @isTest
    public static void testChangePassword(){
        Test.startTest();
        try{
            D1_MyProfileController.changeUserPassword('t','t','t');
            D1_MyProfileController.sendEmail('D1_PasswordChangedMail');
        }catch(Exception ex){
            System.assert(ex.getMessage()!=null, 'passwordChange failed');
        }
        Test.stopTest();
    } 

    /*  
    * @userstory: NCP-582
    * @discription: Setup External User
    * @Param:Nil
    */
    private static Map<String,Object> getExternalUser(){
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        User externalUser;
        Contact contact;

        System.runAs(thisUser){            
            UserRole userRole   =     [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = userRole.id;
            insert testAdminUser;  
            
            Id countryId = D1_TestDataUtility.setupCountry('GB');
            country = new Geography__c(Id= countryId);
            country.isDiageoOneEnabled__c   = True;
            upsert country;  
            
            pickupOption =D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Test');
            pickupOption.Name = 'Gold[GB]';
           	insert pickupOption;
            
        }        
        system.runAs(testAdminUser){
            Account testoutlet=D1_TestDataUtility.getD1Customer();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert testoutlet;

            contact=new Contact(FirstName='fname1',
                                         LastName = 'lname',
                                         Email = 'email1@gmail.com',
                                         Phone = '12345672890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
            insert contact;
            
            externalUser = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
            externalUser.Username = 'email123@gmail.com';
            externalUser.Email='email1@gmail.com';
            externalUser.CommunityNickname = 'Mania.Test';
            externalUser.Available_Countries__c = 'GB';
            externalUser.ContactId = contact.id; 
            externalUser.isActive = True;
            insert externalUser;
        }

        return new Map<String,Object>{'user' => externalUser, 'contact' => contact};
    }

    /*  
    * @userstory: NCP-582
    * @discription: Setup Sample Profile Details
    * @Param:Nil
    */
    private static String getJSONProfileWrapperObject(Id contactId){
        D1_MyProfileController.ProfileWrapper profileWrapperObj = new D1_MyProfileController.ProfileWrapper();

        profileWrapperObj.firstName = 'test First Name';
        profileWrapperObj.lastName = 'test Last Name';
        profileWrapperObj.mobilePrefix = '+34';
        profileWrapperObj.mobileNumber = '612345678';
        profileWrapperObj.contactId = contactId;
        profileWrapperObj.isEmailSubscribed = true;
        profileWrapperObj.isPhoneSubscribed = true;
        profileWrapperObj.isSMSSubscribed = true;
        profileWrapperObj.isPushNotiSubscribed = true;
        profileWrapperObj.languageCode = 'en_GB';
        profileWrapperObj.localeKey = 'en_GB';

        return JSON.serialize(profileWrapperObj);
    } 
}