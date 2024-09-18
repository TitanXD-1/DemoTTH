/**
  * @name D1_UtilityTestClass
  * @purpose This is the test class for D1_UtilityClass
  * @history                                                                                                                       
  * @VERSION  	AUTHOR            DATE              DETAIL
  * 1.0         Narayana    22/04/2022      Initial Development [NCP-6450]
  * 2.0         Pratap      31/01/2023      NCP-7884
  * 3.0         Mayukh/Mukesh   21/08/2023  143985
  **/
@isTest
public  class D1_UtilityTestClass {
    /**
    * @name : setupData
    * @description : This method is used to create test data
    */  
    @TestSetup
    public static void setupData(){
        //Setup Country
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        
        
        //Setup Pickup Option
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        //Setup D1 Customer Account - SOLD TO
        Account soldToOutlet = D1_TestDataUtility.getD1Customer();
        soldToOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        soldToOutlet.Direct_Customer__c = false;
        insert soldToOutlet;

        //Setup D1 Customer Account - SHIP TO
        Account shipToOutlet = D1_TestDataUtility.getD1Customer();
        shipToOutlet.Name = 'testShipToAccount';
        shipToOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        shipToOutlet.KUNNR__c = '980807';
        shipToOutlet.Direct_Customer__c = true;
        insert shipToOutlet;
        
        //Setup External User with User Type Direct Buyer - D1 Settings also added
        D1_TestDataUtility.setUpExternalUser(soldToOutlet,'Direct Buyer');
        
        //Create Org Setting for Active Triggers
        D1_TestDataUtility.createOrgSettings();

        //Add Lead Record
        Lead successLead = D1_TestDataUtility.createLead();
        successLead.Country_ISO_Code__c = 'GB';
        successLead.Preferred_Language__c ='en_GB';
        successLead.Country__c = countryId;
        insert successLead;

        //Add ContactPointAddress
        ContactPointAddress cpa = D1_TestDataUtility.insertContactPointAddress();
        cpa.Account_Number__c = '980807';
        cpa.Name = 'testShipToAccount';
        cpa.parentId = soldToOutlet.Id;
        insert cpa;
    }

    /**
     * @name : testValidatePreferredLanguage
     * @Description : NCP-6450 - Added to Test validatePreferredLanguage() of D1_UtilityClass
     **/
    @isTest
    public static void testValidatePreferredLanguage(){
        Lead leadRec = [SELECT Id, company, status, firstname, lastname, Email, MobilePrefix__c, Mobile__c, PhonePrefix__c, Phone__c, 
                        MobilePhone, Phone 
                        FROM Lead WHERE Preferred_Language__c = 'en_GB' LIMIT 1];

        List<Lead> leadList = new List<Lead>();
        try{            
            Test.startTest();
                leadRec.Preferred_Language__c='en_IE';
                leadList.add(leadRec);
                update leadList;
            Test.stopTest();
            System.assert(leadList[0].Preferred_Language__c == 'en_IE', 'LEAD NOT UPDATED');
            Assert.isTrue(leadList[0].Preferred_Language__c == 'en_IE', 'LEAD NOT UPDATED');	 
        }
        catch(exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
    }

    /**
     * @name : testContactAddressPointShipTo
     * @Description : NCP-7884 - Added to Test getAltEffectiveAccountId() of D1_UtilityClass
     **/
    @isTest
    public static void testGetAltEffectiveAccountId(){
        User testUser = [SELECT Id, D1_User_Type__c 
                         FROM User 
                         WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        String shipToId = [SELECT Id FROM Account WHERE Direct_Customer__c = true LIMIT 1].Id;
        String soldToId = [SELECT Id FROM Account WHERE Direct_Customer__c = false LIMIT 1].Id;
        String altEffectiveAccountId;
        
        try{            
            Test.startTest();
                //For Direct Buyer the Ship-To should come up
                altEffectiveAccountId = D1_UtilityClass.getAltEffectiveAccountId(testUser.Id);
                System.assert(altEffectiveAccountId == shipToId, 'DIRECTBUYER SHIP-TO NOT FOUND');
                Assert.isTrue(altEffectiveAccountId == shipToId, 'DIRECTBUYER SHIP-TO NOT FOUND');
                
                //Update User Type To Outlet/Retailer from Direct Buyer
            	testUser.D1_User_Type__c = 'Outlet/Retailers';
                update testUser;
                
                //For Outlet/Retailer the Sold-To should come up
                altEffectiveAccountId = D1_UtilityClass.getAltEffectiveAccountId(testUser.Id);            
            Test.stopTest();
            
            System.assert(altEffectiveAccountId == soldToId, 'OUTLET/RETAILER SHIP-TO NOT FOUND');
            Assert.isTrue(altEffectiveAccountId == soldToId, 'OUTLET/RETAILER SHIP-TO NOT FOUND');
        }
        catch(exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
    }

    /**
     * @name : testGetD1Setting
     * @Description : 143985 - Added to Test getD1Setting() of D1_UtilityClass
     **/
    @isTest
    public static void testGetD1Setting(){
        User testUser = [SELECT Id, D1_User_Type__c 
                         FROM User 
                         WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        Test.startTest();
        System.runAs(testUser){
            try{
                Object d1Setting = D1_UtilityClass.getD1Setting(null);
                System.assert(d1Setting!=null,'D1Settings not found');
                Assert.isNotNull(d1Setting, 'D1Settings not found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
        Test.stopTest();
    }
    
    /**
     * @name : testGetD1UserType
     * @Description : 143985 - Added to Test getD1UserType() of D1_UtilityClass
     **/
    @isTest
    public static void testGetD1UserType(){
        User testUser = [SELECT Id, D1_User_Type__c 
                         FROM User 
                         WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        Test.startTest();
        System.runAs(testUser){
            try{
                Object d1UserType = D1_UtilityClass.getD1UserType(null);
                System.assert(d1UserType!=null,'No User Type Found');
                Assert.isNotNull(d1UserType, 'No User Type Found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
        Test.stopTest();
    }
}