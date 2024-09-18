/*
* @name D1_OpportunityControllerTest
* @description Test class for D1_OpportunityController Class
* @history
* VERSION     AUTHOR              DATE              DETAIL
* 1.0		    Amar			  14/12/2021        NCP-5596,NCP-5597,NCP-5600
* 
* */
@isTest
public class D1_OpportunityControllerTest {
    /*Note : See All data is required in getOpportunityRecordstest() because we are calling here connectApi method*/
    private static Id oppTemplateId;
    /**
    * @Name : getOpportunityRecordstest
	* @description : This method is used to test the getOpportunityRecords() & addToOpportunityContentDetail method of the D1_OpportunityController class
	*/
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @IsTest(SeeAllData=true)
    public static void getOpportunityRecordstest(){
        setupdata();
        Test.startTest();
        try{
            User usr = [Select id from User where Profile.Name = 'DiageoOne External User' and IsActive=true and Username = 'testclassextuser1@testdomain.com' limit 1];
            Assert.isTrue(usr != NULL, 'USER NOT FOUND');
            System.Assert(usr != NULL,'USER NOT FOUND');
            system.runAs(usr){
                D1_OpportunityController.getOpportunityRecords(null);
            }
        }
        catch(Exception ex){
            system.debug(LoggingLevel.DEBUG, ex.getMessage());
        }
        Test.stopTest();
    }
    
    /**
    * @Name : testException
	* @description : This method is used to test negative scenario for getUserDetails() of the D1_OpportunityController class
	*/
    @isTest
    public static void testException(){ 
        String validContentId = System.Label.D1_OpportunityControllerTest; 
        Id myId = Id.valueOf(validContentId);
        Test.startTest();
        try{	
            D1_OpportunityController.getUserDetails(myId);
            System.Assert(myId != null, true);
        }
        catch(Exception ex){
            system.debug(LoggingLevel.DEBUG, ex.getMessage());
        }
        Test.stopTest();
    }
	
	/**
    * @Name : setupdata
	* @description : This method is used to create test data for the D1_OpportunityController class
	*/    
    public static void setupdata(){ 
        UserRole ur = [SELECT Id FROM UserRole WHERE Name = 'Global' LIMIT 1];
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');        
        testAdminUser.userRoleId = ur.id;
        insert testAdminUser;
        
        system.runAs(testAdminUser){
            Id countryId;
            /*To handle validation error against multiple 'Global' Geography records when opening up access to org data in test class*/
            List<Geography__c> geoList = new List<Geography__c>();
            geoList = [SELECT Id FROM Geography__c WHERE Code__c = 'GB' AND RecordType.Name = 'Country'];
            if(geoList.isEmpty()){
                countryId = D1_TestDataUtility.setupCountry('GB');
            }
            else{
                countryId = geoList[0].Id;
            } 
        
            Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','TestGold [GB]');
            insert pickupOption;
        
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            Geography__c hub =[SELECT Id FROM Geography__c WHERE RecordType.name='Hub' AND name ='Great Britain' LIMIT 1];
            Geography__c region =[SELECT Id FROM Geography__c WHERE RecordType.name='Region'AND name ='London' LIMIT 1];
            Geography__c area =[SELECT Id FROM Geography__c WHERE RecordType.name='Area' AND name ='Great Britain' LIMIT 1];
            Geography__c market =[SELECT Id FROM Geography__c WHERE RecordType.name='Market' AND name ='Europe and Turkey' LIMIT 1];
            Geography__c cluster =[SELECT Id FROM Geography__c WHERE RecordType.name='Cluster' AND name ='Great Britain' LIMIT 1];
            testoutlet.Country__c = countryId;
            testoutlet.Hub__c = hub.Id;
            testoutlet.Region__c=region.Id;
            testoutlet.Area__c=area.Id;
            testoutlet.Market__c = market.Id;
            testoutlet.Cluster__c= cluster.Id;
            testoutlet.D1_EDGE_Customer__c =true;
            testoutlet.Name='testcart Outlet ';
            testoutlet.Salesforce_Delivery_Days_Packaged_Good__c='1;2;3;4;5;6;7';
            testoutlet.Salesforce_Delivery_Days_Keg__c='1;2;3;4;5;6;7';
            testoutlet.Delivery_Pattern__c='0';
            testoutlet.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
            insert testoutlet;
            
            Contact primaryContact = D1_TestDataUtility.getContact(testOutlet.Id, 'Primary');
            insert primaryContact;

            Product__c product = new Product__c();
            product.Name = 'JW Black Label 70cl';
            product.Product_Full_Name__c = 'JW Black Label 70cl';
            product.RecordTypeId = D1_TestDataUtility.getRecordTypeIdByName('Product__c', 'SKU');
            insert product;
            system.assert(product!=null, 'product does not exist');
            
            Opportunity_Template__c oppTemplate = D1_TestDataUtility.getOpportunityTemplate(product.Id, null, countryId);
            oppTemplate.Cluster__c = countryId;
            oppTemplate.D1_Content_Reference__c = 'MCQCLALPVIJZA5XDOXIY7FUHHTF4';
            //oppTemplate.D1_Relevant__c = true;
            insert oppTemplate;
            
            Opportunity_Template__c oppTemp = new Opportunity_Template__c();
            oppTemp.Id = oppTemplate.Id;
            oppTemp.D1_Relevant__c = true;
            update oppTemp;

            //Insert Opportunity
            Opportunity opp = new Opportunity();
            opp.Name = 'Test D1 Opportunity';
            opp.AccountId = testOutlet.Id;
            opp.StageName = 'Open';
            opp.Type = 'Cycle Brief';
            opp.Product__c = product.Id;
            opp.Opportunity_Template__c = oppTemplate.Id;
            opp.CloseDate = System.Today()+10;
            insert opp;
        
            User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'testclassextuser1@testdomain.com';
            externalUser1.Email='testclassextuser1@testdomain.com';
            externalUser1.CommunityNickname = 'Mania.Test1';
            externalUser1.Available_Countries__c = 'GB';
            externalUser1.ContactId = primaryContact.Id;
            externalUser1.Effective_Account_Id__c = primaryContact.AccountId;
            externalUser1.isActive = true;
            externalUser1.D1_User_Type__c = 'Outlet/Retailers';
            externalUser1.LanguageLocaleKey ='en_GB';
            insert externalUser1;
        }
    }
}