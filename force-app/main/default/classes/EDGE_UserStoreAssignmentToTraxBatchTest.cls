/**
* @Description: Test Class for EDGE_UserStoreAssignmentToTraxBatch

* @History                                                            

*	Shivam Chauhan		18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*   Joshraj Sen         08/04/2024      152305 Fixed SCA

**/
@isTest
public class EDGE_UserStoreAssignmentToTraxBatchTest {
    
    @isTest
    public static void deleteInactiveUserFromTrax(){
        Test.startTest(); 
        //creating data
        List<User> userlist = new List<User>();
        String countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User newUserSR;
        User newUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
        newUser.Trax_User__c = true;
        insert newUser;
        userlist.add(newUser);
        System.runAs (newUser) {
        newUserSR = EDGE_UtilityTestClass.runAsUser('slsrp', 'Sales Representative');
        newUserSR.Trax_User__c = true;
        insert newUserSR;
        userlist.add(newUserSR);
        newUserSR.IsActive = False;
        update newUserSR;
        system.debug(LoggingLevel.Debug,'@@newUserSR' +newUserSR);
        Trax_User_Update__c setting = new Trax_User_Update__c ();
        setting.Name = newUserSR.Id;
        setting.country_code__c= 'AU';
        insert setting;
         
         } 
        
        
        EDGE_UtilityTestClass.createOrgSettings(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Account outlet =   EDGE_UtilityTestClass.getOutletRecord();
        outlet.Status__c = 'Active';
        outlet.Send_To_Trax__c = true;
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        insert outlet;
        
        
        Trax_User_Update__c tUpdate = new Trax_User_Update__c();
        tUpdate.Name = newUserSR.Id;
        tUpdate.Country_Code__c = 'AU';
        insert tUpdate;
                
        Outlet_Member__c oMC = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.id, newUser.id, 'Primary');
        insert oMC ;
        //Outlet_Member__c oMC1 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.id, newUser.id, 'Primary');
        //insert oMC1 ;
    
        System.debug(LoggingLevel.Debug,'Before@@traxlist'+ tUpdate);
       //System.assertEquals(False,traxList.isEmpty());
        
        //running batch
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UserStoreAssignmentToTraxBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.debug(LoggingLevel.Debug,'batchSettingch'+batchSetting);
        System.assert(batchSetting.id != null,'batch id should not be null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
  
        delete tUpdate;
        
        System.debug(LoggingLevel.Debug,'After@@traxlist'+ tUpdate);
        //System.assertEquals(True,traxList.isEmpty());
        Test.stopTest();
       
    }

    
    @isTest
    public static void testUserStoryAssignmentMock(){
        
       // Test.setMock(HttpCalloutMock.class, new EDGE_MockTraxResponse()); 
        Test.startTest();         
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UserStoreAssignmentToTraxBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        System.assert(batchSetting.id != null,'batch id should not be null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        //Test.startTest(); 
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();     
    }
    
    @isTest
    public static void testUserStoryAssignment(){        
        Test.startTest();         
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UserStoreAssignmentToTraxBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        System.assert(batchSetting.id != null,'batch id should not be null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        //Test.startTest(); 
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();
        try{
            throw new DMLException('DML EXCEPTION');
        }catch(Exception exMsg){
            System.debug(LoggingLevel.Debug,'excption::::'+exMsg.getMessage());
        }
        
    }
    
    public static void createData(){
        String countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        User newUser = EDGE_UtilityTestClass.runAsUser('uniqueKey', 'Master Data Manager');
        newUser.Trax_User__c = true;
        insert newUser;
        
        EDGE_UtilityTestClass.createOrgSettings(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Account outlet =   EDGE_UtilityTestClass.getOutletRecord();
        outlet.Status__c = 'Active';
        outlet.Send_To_Trax__c = true;
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        insert outlet;
        
        
        Trax_User_Update__c tUpdate = new Trax_User_Update__c();
        tUpdate.Name = newUser.Id;
        tUpdate.Country_Code__c = 'AU';
        insert tUpdate;
        
        /*set<Id> userIdSet= new set<Id>();
        userIdSet.add(tUpdate.name);*/
                
        Outlet_Member__c oMC = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.id, newUser.id, 'Primary');
        insert oMC ;
        
    }
   
    
    @isTest 
    public static void testCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new EDGE_MockTraxResponse());
        HTTPRequest req; 
        EDGE_MockTraxResponse mocktrax =  new EDGE_MockTraxResponse();
        HttpResponse res = mocktrax.respond(req);
        
        // Verify response received contains fake values
        String contentType = res.getHeader('Content-Type');
        System.assert(contentType != null,'content type should not be null');
        
    }
}