/**
* @Name: EDGE_CallTriggerHelper
* @Description: Trigger Helper Class for Call
* @History:

* @VERSION     AUTHOR            DATE              DETAIL
*  1.0      Saurav Paul     	06-Mar-2019        Initial Development  
*  2.0     Monalisa Halder      05-Oct-2020        ES20-11003
*  3.0	   Aparajita/Rajarshi   31-May-2022		   ES20-12716,ES20-12717
*  4.0     Joshraj Sen          08-Apr-2024        152305
*/ 
@isTest
public with sharing class EDGE_CallTriggerTest {
    
    @isTest
    public static void validatePopulateGUID(){
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        User testMDMUser;
        Account outletRec;
        Account operator;
        Pick_Up_Options__c  outletVisit;
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent'; //was commented before
        //market.Business_Hours__c =
        market.A_P_Threshold__c = 100.00; //100
        insert market;
        
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        System.runAs(testAdminUser){
            //create MDM User
            Test.startTest();
            
            testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','System Administrator');
            testMDMUser.Available_Countries__c = 'AU';
            testMDMUser.Trax_User__c = True;
            insert testMDMUser;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());

            String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            outletVisit = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            outletVisit.Name='Gold[AU]';
            outletVisit.RecordTypeId = pickupRecordType;
            insert outletVisit ;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Person_Responsible__c = testMDMUser.Id;
            operator.IsOperator__c = true;
            insert operator;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            outletRec = EDGE_UtilityTestClass.getOutletRecord();
            outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id;  
            outletRec.Operator__c = operator.Id;
            outletRec.Independent_of_Operator__c = false;
            outletRec.Independent_of_Owner__c = true;
            outletRec.Country__c = countryId;
            insert outletRec;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outletRec.Id;
            newAccTeamMember.UserId = testMDMUser.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            System.assert(newAccTeamMember.Id!=null,'newAccTeamMember Id should not be null');
        }
        
        //run as MDM user 
        System.runAs(testMDMUser) {
            //Create Call Rec
            Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
            insert callObj;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            System.assert(callObj.Id!= null,'callObj Id should not be null');
            
            Call__c callObjVal = [SELECT Id,GUID__c FROM Call__c WHERE Id = :callObj.Id];
            System.assert(callObjVal.GUID__c!= null,'callObj Id should not be null');
        }
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        Test.stopTest();
    }
    @isTest
    public static void validateUpdateLastVisit(){
        User testMDMUser;
        Account outletRec;
        Account operator;
        Pick_Up_Options__c  outletVisit;
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'countryId should not be null');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent'; //was commented before
        market.A_P_Threshold__c = 100.00; //100
        List<BusinessHours> bHoursList = [SELECT Id FROM BusinessHours];
        if(bHoursList.size()>0){
            market.Business_Hours__c = bHoursList[0].Id;	    
        }        
        insert market;
        
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        System.runAs(testAdminUser){
            //create MDM User
            testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','System Administrator');
            testMDMUser.Available_Countries__c = 'AU';
            testMDMUser.Trax_User__c = True;
            insert testMDMUser;
            System.assert(testMDMUser.Id!=null,'testMDMUser Id should not be null');
            
            String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            outletVisit =EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            outletVisit.Name='Gold[AU]';
            outletVisit.RecordTypeId = pickupRecordType;
            insert outletVisit ;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            Test.startTest();
            operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Person_Responsible__c = testMDMUser.Id;
            operator.IsOperator__c = true;
            insert operator;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            outletRec = EDGE_UtilityTestClass.getOutletRecord();
            outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id;  
            outletRec.Operator__c = operator.Id;
            //outletRec.ParentId = operator.Id;
            outletRec.Independent_of_Operator__c = false;
            outletRec.Independent_of_Owner__c = true;
            outletRec.Country__c = countryId;            
            insert outletRec;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outletRec.Id;
            newAccTeamMember.UserId = testMDMUser.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            newAccTeamMember.TeamMemberRole = 'Sales Rep';
            insert newAccTeamMember;

            System.assert(newAccTeamMember.Id!=null,'newAccTeamMember Id should not be null');
        }   
        
        //run as MDM user 
        System.runAs(testMDMUser) {
            
            //Create Pickup Option            
            
            //Create Call Rec
            Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
            insert callObj;
            
            System.assert(callObj.Id!= null,'testMDMUser Id should not be null');
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            Call__c callObjRec = new Call__c();
            callObjRec.Id = callObj.Id;
            callObjRec.End_Date__c = System.today().addDays(16);
            update callObjRec;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            Account accObj = [Select Id, Visit_Compliance__c, Last_Visit__c FROM Account WHERE Id =: outletRec.Id];
            System.assertEquals(accObj.Visit_Compliance__c, false,'Visit Compliance should be false');
        }
        Test.stopTest();
    }

    //ES20-7328 : testing Days In Trade      
    @isTest
    // Updated method name naming conventions --by Divya
    public static void atestDaysInTrade(){
        //List<Pick_Up_Options__c> lstPickupOption = new List<Pick_Up_Options__c>();
        Account outletRec;
        Pick_Up_Options__c outletVisit;
        User salesRep1= EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep1.Default_Country__c = 'AU';
        salesRep1.Available_Countries__c = 'AU';
        insert salesRep1;
        system.debug(LoggingLevel.Debug,'Line# 1 -->'+Limits.getqueries());
        
        //Creating country
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'countryId should not be null');
        
        //Creating Outet Visit Prioritization
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        outletVisit = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        outletVisit.Name='Gold[AU]';
        outletVisit.RecordTypeId = pickupRecordType;
        insert outletVisit;
        System.assert(outletVisit.Id!=null,'outlet Visit Id should not be null');        
		system.debug(LoggingLevel.Debug,'Line# 2 -->'+Limits.getqueries());   
        
        outletRec = EDGE_UtilityTestClass.getOutletRecord();
        outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id;
        outletRec.Independent_of_Operator__c = true; 
        outletRec.Independent_of_Owner__c = true;
        outletRec.Country__c = countryId;
        
        Test.startTest();
        insert outletRec;
        System.assert(outletRec.Id!=null,'outlet Rec Id should not be null');
        system.debug(LoggingLevel.Debug,'Line# 3 -->'+Limits.getqueries());
        
        //Create Call Type      
        Call_Type__c callType = EDGE_UtilityTestClass.getCallType(countryId);
        callType.Name = 'Prospect and Fact Finding';
        callType.Global_Equivalent_Call_Type__c = 'Physical';
        callType.KPIs_Active__c = 'Days in Trade';
        insert callType;
        system.debug(LoggingLevel.Debug,'Line# 4 -->'+Limits.getqueries());
        
        //Create Call Record
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
        callObj.Call_Performed_By__c=salesRep1.Id;
        callObj.Type_of_Call__c = callType.Id;
        callObj.Status__c = 'Completed';
        insert callObj;
        System.assert(callObj.Id!= null,'call object Id should not be null');
        system.debug(LoggingLevel.Debug,'Line# 5 -->'+Limits.getqueries());
        Test.stopTest();
    }
    
    @isTest
    // Updated method name naming conventions --by Divya
    public static void updateLastVisitSalesTest(){
        Account outletRec;
        Pick_Up_Options__c outletVisit;
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep','Sales Representative');
        salesRep.Default_Country__c = 'AU';
        salesRep.Available_Countries__c = 'AU';
        insert salesRep;

        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        //Creating country
        EDGE_UtilityTestClass.createOrgSettings();        
        
        System.assert(countryId!=null,'country id should not be null');

        Test.startTest();
        outletRec = createTestData(outletRec,outletVisit,countryId); 
                
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = outletRec.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        
        System.runAs(salesRep){
            //Create Call Record
            Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
            callObj.Call_Performed_By__c=salesRep.Id;
            callObj.End_Date__c = System.today().addDays(2);
            callObj.Status__c = 'Completed';
            
            callObj.Last_Visit_from_Mobile__c  = true;
            
            insert callObj;
            System.assert(callObj.Id!= null,'call object id should not be null');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void updateLastVisitQualityTest(){
        Account outletRec;
        Pick_Up_Options__c outletVisit;
        User qualityRep = EDGE_UtilityTestClass.runAsUser('qualityRep','Quality Representative');
        qualityRep.Default_Country__c = 'AU';
        qualityRep.Available_Countries__c = 'AU';
        insert qualityRep;
        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        //Creating country
        EDGE_UtilityTestClass.createOrgSettings();        
        
        System.assert(countryId!=null,'country id should not be null');
        
        Test.startTest();
        outletRec = createTestData(outletRec,outletVisit,countryId);
        
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = outletRec.Id;
        newAccTeamMember.UserId = qualityRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        
        System.runAs(qualityRep){
            //Create Call Record
            Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
            callObj.Call_Performed_By__c=qualityRep.Id;
            callObj.Call_Completed_in_Mobile__c = true;
            callObj.End_Date__c = System.today().addDays(2);
            
            callObj.Last_Visit_from_Mobile__c  = true;
            
            callObj.Status__c = 'Completed';
            insert callObj;
            System.assert(callObj.Id!= null,'call object Id should not be null');
        }
        Test.stopTest();        
    }
    
    @isTest
    public static void updateLastVisitQualityBlankTest(){
        Account outletRec;
        Pick_Up_Options__c outletVisit;
        User qualityRep = EDGE_UtilityTestClass.runAsUser('qualityRep','Quality Representative');
        qualityRep.Default_Country__c = 'AU';
        qualityRep.Available_Countries__c = 'AU';
        insert qualityRep;
        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        //Creating country
        EDGE_UtilityTestClass.createOrgSettings();        
        
        System.assert(countryId!=null,'country Id should not be null');
        
        Test.startTest();
        outletRec = createTestData(outletRec,outletVisit,countryId);
        outletRec.Last_Visit_Quality__c = null;
        update outletRec;
        
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = outletRec.Id;
        newAccTeamMember.UserId = qualityRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        
        System.runAs(qualityRep){
            //Create Call Record
            Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
            callObj.Call_Performed_By__c=qualityRep.Id;
            
            callObj.Last_Visit_from_Mobile__c  = true;
            
            callObj.End_Date__c = System.today().addDays(2);
            callObj.Status__c = 'Completed';
            insert callObj;
            System.assert(callObj.Id!= null,'call object Id should not be null');
        }
        Test.stopTest();
    }
        
    @isTest
    public static void updateLastVisitSalesBlankTest(){
        Account outletRec;
        Decimal decNum = 10.00;
        Pick_Up_Options__c outletVisit;
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep','Sales Representative');
        salesRep.Default_Country__c = 'AU';
        salesRep.Available_Countries__c = 'AU';
        insert salesRep;
        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        //Creating country
        EDGE_UtilityTestClass.createOrgSettings();        
        
        System.assert(countryId!=null,'country id should not be null');
        
        
        Test.startTest();
        outletRec = createTestData(outletRec,outletVisit,countryId);
        outletRec.Last_Visit__c = null;
        update outletRec;
        
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = outletRec.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        
        Call__c callObj;
        
        System.runAs(salesRep){
            //Create Call Record
            callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
            callObj.Call_Performed_By__c=salesRep.Id;
            
            callObj.Last_Visit_from_Mobile__c  = true;
            
            callObj.End_Date__c = null;
            callObj.Status__c = 'Open';   
            insert callObj;
            callObj.End_Date__c = System.today().addDays(2);
            callObj.Status__c = 'Completed';
            
            System.assert(callObj.Id!= null,'call object id should not be null');            
        }
        EDGE_CallTriggerHelper.checkForNull(decNum); 
        Test.stopTest();
        List<Call__c> callList = new List<Call__c>();
        callList = [Select Id , Status__c from Call__c where Id =:callObj.Id];        
    }
    
    @isTest
    // Updated method name naming conventions --by Divya
    public static void outletVisitComplianceTest(){
        Account outletRec;
        Pick_Up_Options__c outletVisit;
        User salesRep1= EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep1.Default_Country__c = 'AU';
        salesRep1.Available_Countries__c = 'AU';
        insert salesRep1;
        
        //Creating country
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'country id should not be null'); 
        
        Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(countryId);
        marketCycle.Start_Date__c = Date.Today();
        marketCycle.End_Date__c = Date.Today().addDays(30);
        marketCycle.Geography__c = countryId;
        insert marketCycle;
        
        //Creating Outet Visit Prioritization
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        outletVisit = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        outletVisit.Name='Gold[AU]';
        outletVisit.RecordTypeId = pickupRecordType;
        insert outletVisit;
        System.assert(outletVisit.Id!=null,'outlet Visit Id should not be null');
        
        Test.startTest();
        outletRec = EDGE_UtilityTestClass.getOutletRecord();
        outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id;
        outletRec.Independent_of_Operator__c = true; //false;
        outletRec.Independent_of_Owner__c = true;
        outletRec.Country__c = countryId;
        insert outletRec;
        System.assert(outletRec.Id!=null,'outlet Rec Id should not be null');
        
        //Create Call Type      
        Call_Type__c callType = EDGE_UtilityTestClass.getCallType(countryId);
        callType.Name = 'Prospect and Fact Finding';
        callType.Global_Equivalent_Call_Type__c = 'Physical';
        callType.KPIs_Active__c = 'Outlet Visit Compliance';
        insert callType;
        
        //Create Call Record
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
        callObj.Call_Performed_By__c=salesRep1.Id;
        callObj.Type_of_Call__c = callType.Id;
        callObj.Status__c = 'Completed';
        insert callObj;
        System.assert(callObj.Id!= null,'call object Id should not be null');
        
        Test.stopTest(); 
    }
    
    @isTest
    public static void updateCallComplianceOnDeleteTest(){
        User testMDMUser;
        Account outletRec;
        Account operator;
        Pick_Up_Options__c  outletVisit;
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'country Id should not be null');
        
        System.runAs(testAdminUser){
            //create MDM User
            testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','System Administrator');
            testMDMUser.ManagerId = testAdminUser.Id;
            testMDMUser.Available_Countries__c = 'AU';
            testMDMUser.Trax_User__c = True;
            insert testMDMUser;
            System.assert(testMDMUser.Id!=null,'test MDM user Id should not be null');
            
            String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            outletVisit =EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            outletVisit.Name='Gold[AU]';
            outletVisit.RecordTypeId = pickupRecordType;
            insert outletVisit ;

            operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Person_Responsible__c = testAdminUser.Id;
            operator.IsOperator__c = true;
            insert operator;
            
            Test.startTest();
            
            outletRec = EDGE_UtilityTestClass.getOutletRecord();
            outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id; 
            outletRec.Operator__c = operator.Id;
            outletRec.Independent_of_Operator__c = false;
            outletRec.Independent_of_Owner__c = true;
            outletRec.Country__c = countryId;
            outletRec.Number_Of_Planned_Calls__c = 10 ;
            outletRec.Number_Of_Planned_Calls_Completed__c = 5;
            insert outletRec;
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outletRec.Id;
            newAccTeamMember.UserId = testMDMUser.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            System.assert(newAccTeamMember.Id!=null,'new Acc team Member Id should not be null');
            
            Call_Type__c callType = EDGE_UtilityTestClass.getCallType(countryId);
            callType.Name = 'Prospect and Fact Finding';
            callType.Global_Equivalent_Call_Type__c = 'Virtual';
            insert callType;
        }
        
        System.runAs(testMDMUser) {
            Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(countryId);
            marketCycle.Start_Date__c = Date.Today();
            marketCycle.End_Date__c=Date.Today().addDays(30);
            insert marketCycle;
            
            Call__c callObj = new Call__c();
            callObj.Account__c = outletRec.id;
            callObj.Start_Date__c = System.today();
            
            callObj.Status__c = 'Planned';
            callObj.Call_Performed_By__c=testMDMUser.id;
            callObj.Plan_Start_Date__c = System.today().addDays(1);
            callObj.Plan_End_Date__c = System.today().addDays(15);
            callObj.Type_of_Call__c = [SELECT id from Call_Type__c where Name = 'Prospect and Fact Finding' limit 1 ].Id;
            
            insert callObj;
            
            Database.delete(callObj);
            undelete callObj;
        } 
        Test.stopTest();    
    }
        
    @isTest
    public static void updateVirtualCallCountTest(){
        User testMDMUser;
        Account outletRec;
        Account operator;
        Pick_Up_Options__c  outletVisit;
        Call_Type__c callType;
        Call_Type__c callType1;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        
        System.debug(loggingLevel.Debug,'@@@'+limits.getQueries());
        
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'country Id should not be null');
        
        System.runAs(testAdminUser){            
            Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(countryId);
            marketCycle.Start_Date__c = Date.Today().addDays(-1);
            marketCycle.End_Date__c=Date.Today().addDays(30);
            marketCycle.Geography__c = countryId;
            insert marketCycle;
            
            //create MDM User
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());            
            testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','System Administrator');
            testMDMUser.ManagerId = testAdminUser.Id;
            testMDMUser.Available_Countries__c = 'AU';
            testMDMUser.Trax_User__c = True;
            insert testMDMUser;
            
            System.assert(testMDMUser.Id!=null,'test MDM user Id should not be null');
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            outletVisit =EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            outletVisit.Name='Gold[AU]';
            outletVisit.RecordTypeId = pickupRecordType;
            insert outletVisit ;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            Test.startTest();
            operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Person_Responsible__c = testAdminUser.Id;
            operator.IsOperator__c = true;
            insert operator;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            outletRec = EDGE_UtilityTestClass.getOutletRecord();
            outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id; 
            outletRec.Operator__c = operator.Id;
            outletRec.Independent_of_Operator__c = false;
            outletRec.Independent_of_Owner__c = true;
            outletRec.Country__c = countryId;
            outletRec.Actual_Visits__c = 100;
            outletRec.Expected_Visits__c = 110; 
            insert outletRec;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outletRec.Id;
            newAccTeamMember.UserId = testMDMUser.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            
            System.assert(newAccTeamMember.Id!=null,'new Acc Team Member Id should not be null');
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            callType = EDGE_UtilityTestClass.getCallType(countryId);
            callType.Name = 'Prospect and Fact Finding';
            callType.KPI_Relevant__c = True;
            callType.Global_Equivalent_Call_Type__c = 'Virtual';
            callType.Min_call_duration__c = 1;
            insert callType;
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            callType1 = EDGE_UtilityTestClass.getCallType(countryId);
            callType1.Name = 'Sell and Measure';
            callType1.KPI_Relevant__c = True;
            callType1.Global_Equivalent_Call_Type__c = 'Physical';
            callType1.Min_call_duration__c = 1;
            insert callType1;
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
        }

        System.runAs(testMDMUser) {            
            Call__c callObj = new Call__c();
            callObj.Account__c = outletRec.id;
            callObj.Plan_Start_Date__c = Date.today();//sss
            callObj.Start_Date__c = System.today().addDays(-2);
            callObj.End_Date__c = System.now();
            callObj.Status__c = 'Open';
            callObj.Call_duration_compliance__c = true;
            callObj.Call_Performed_By__c=testMDMUser.id;
            callObj.Type_of_Call__c = callType.Id;
            insert callObj;
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            callObj.Status__c = 'Completed';
            callObj.End_Date__c = Date.today();            
            
            Call__c callObj1 = new Call__c();
            callObj1.Account__c = outletRec.id;
            callObj1.Plan_Start_Date__c = Date.today();
            callObj1.Start_Date__c = System.today().addDays(-2);
            callObj1.End_Date__c = System.now();
            callObj1.Status__c = 'Completed';
            callObj1.Call_duration_compliance__c = true;
            callObj1.Call_Performed_By__c=testMDMUser.id;
            callObj1.Type_of_Call__c = callType1.Id;

            Map<Id, Account> accIdToAccMap = new Map<Id, Account>();
            accIdToAccMap.put(outletRec.Id,outletRec);
            EDGE_CallTriggerHelper.updateActualVisit(accIdToAccMap , outletRec.Id);
            Test.stopTest();
        }        
    }
    
    private static Account createTestData(Account outletRec,  Pick_Up_Options__c outletVisit, Id countryId){    
        
        //Creating Market Cycle
        Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(countryId);
        marketCycle.Start_Date__c = Date.Today();
        marketCycle.End_Date__c=Date.Today().addDays(30);
        insert marketCycle;
        EDGE_UtilityClass.printGovLimits(918);
        
        //Creating Outet Visit Prioritization
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        outletVisit = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        outletVisit.Name='Gold[AU]';
        outletVisit.RecordTypeId = pickupRecordType;
        insert outletVisit;
        System.assert(outletVisit.Id!=null,'outlet Visit id should not be null');
        
        EDGE_UtilityClass.printGovLimits(929);
        
        //Creating outlet
        outletRec = EDGE_UtilityTestClass.getOutletRecord();
        outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id;
        outletRec.Independent_of_Operator__c = true; //false;
        outletRec.Independent_of_Owner__c = true;
        outletRec.Last_Visit__c = System.today().addDays(-3);
        outletRec.Last_Visit_Quality__c = System.today().addDays(-1);
        outletRec.Country__c = countryId;
        insert outletRec;
        System.assert(outletRec.Id!=null,'outlet rec Id should not be null');
        EDGE_UtilityClass.printGovLimits(953);
        
        //Database.insert(accounts);
        return outletRec;
    }
    
    @isTest
    public static void calculateVisitCompliance(){
        Account outletRec;
        Pick_Up_Options__c  outletVisit;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        User salesRepUser = EDGE_UtilityTestClass.runAsUser('salesRep123','Sales Representative');
        salesRepUser.ManagerId = testAdminUser.Id;
        salesRepUser.Available_Countries__c = 'AU';
        insert salesRepUser;
        System.assert(salesRepUser!=null,'salesRepUser should not be null');
        
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        
        Call_Type__c callType = EDGE_UtilityTestClass.getCallType(countryId);
        callType.Name = 'Prospect and Fact Finding';
        callType.Global_Equivalent_Call_Type__c = 'Physical';
        callType.KPIs_Active__c = 'Days in Trade';
        insert callType;
        System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
        
        System.runAs(testAdminUser){
            
            Test.startTest();
            outletRec = createTestData(outletRec,outletVisit,countryId);
            
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            //insert Business Role
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            brtest.Country__c = countryId;
            insert brtest;
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            User_Business_Role__c ubrtest1 = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
            insert ubrtest1;
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
            Role_Call__c roleCall = new Role_Call__c();
            roleCall.Call_Type__c = callType.Id;
            roleCall.KPIs_Active__c = 'Calls Per Day;Days In Trade;Coverage Compliance;Planned Call Compliance;Outlet Visit Compliance';
            roleCall.Business_Role__c = brtest.Id;
            insert roleCall;
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            List<Call__c> calllist = new List<Call__c>();
            Call__c callObj = new Call__c();
            callObj.Account__c = outletRec.id;
            Test.stopTest();
            callObj.Plan_Start_Date__c = Date.today();//Date.Today().addDays(3);
            callObj.Start_Date__c = System.today();
            callObj.Status__c = 'Planned';
            callObj.Call_Performed_By__c= salesRepUser.Id;
            callObj.Type_of_Call__c = callType.Id; 
            callObj.Call_duration_compliance__c = false;
            calllist.add(callObj);
            //insert callObj;
            
            
            Call__c callObj1 = new Call__c();
            callObj1.Account__c = outletRec.id;
            //Test.stopTest();
            callObj1.Plan_Start_Date__c = Date.today();//Date.Today().addDays(3);
            callObj1.Start_Date__c = System.today();
            callObj1.End_Date__c = System.today().addDays(1);
            callObj1.Status__c = 'Completed';
            callObj1.Call_Performed_By__c= salesRepUser.Id;
            callObj1.Type_of_Call__c = callType.Id; 
            callObj1.Call_duration_compliance__c = false;
             calllist.add(callObj1);
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            insert calllist;
            System.debug(loggingLevel.debug,'@@@'+limits.getQueries());
            
        }
    }
    
    //ES20-7328 : testing Calls per Day      
    @isTest
    // Updated method name naming conventions --by Divya
    public static void atestCallsPerDay(){
        Account outletRec;
        Pick_Up_Options__c outletVisit;
        
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        User salesRep1 = EDGE_UtilityTestClass.runAsUser('salesRep123','Sales Representative');
        salesRep1.Available_Countries__c = 'AU';
        insert salesRep1;
        EDGE_UtilityClass.printGovLimits(1041);
        
        Test.startTest();
        outletRec = createTestData(outletRec,outletVisit,countryId);
        
        //Create Call Type      
        Call_Type__c callType = EDGE_UtilityTestClass.getCallType(countryId);
        callType.Name = 'Prospect and Fact Finding';
        callType.Global_Equivalent_Call_Type__c = 'Physical';
        callType.KPIs_Active__c = 'Calls Per Day';
        insert callType;
        System.assert(callType!=null,'callType should not be null');

        //Create Call Record
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
        callObj.Call_Performed_By__c=salesRep1.Id;
        callObj.Type_of_Call__c = callType.Id;
        callObj.Status__c = 'Completed';
        Test.stopTest();
        EDGE_UtilityClass.printGovLimits(1064);
    } 
    
   /* @isTest
    public static void calculateCallPerDay(){
        //AccountTriggerHandler.triggerDisabled = true;
		System.debug('@@@enters here...'+limits.getQueries());
        User testMDMUser;
        Account outletRec;
        Account operator;
        Pick_Up_Options__c  outletVisit;
        Id callTypeId = [SELECT Id FROM Call_Type__c LIMIT 1].Id;
        System.debug('@@@'+limits.getQueries());
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        System.debug('@@@'+limits.getQueries());
        //Create Org Setting
        EDGE_UtilityTestClass.createOrgSettings();  
        System.debug('@@@'+limits.getQueries());
        Id countryId  = EDGE_UtilityTestClass.setupCountryGB('GB');     
        System.assert(countryId!=null);
        User salesRepUser;
        Call__c callObj = new Call__c();
        Call__c callObj1 = new Call__c(); 
        
        EDGE_UtilityClass.printGovLimits(400);
        
        System.runAs(testAdminUser){
            Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(countryId);
            marketCycle.Start_Date__c = Date.Today();
            marketCycle.End_Date__c = Date.Today().addDays(30);
            marketCycle.Geography__c = countryId;
            insert marketCycle;
            System.debug('@@@'+limits.getQueries());
            EDGE_UtilityClass.printGovLimits(409);
            //create MDM User
            testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','System Administrator');
            testMDMUser.ManagerId = testAdminUser.Id;
            testMDMUser.Available_Countries__c = 'GB';
            testMDMUser.Trax_User__c = True;
            insert testMDMUser;
            System.debug('@@@'+limits.getQueries());
            System.assert(testMDMUser.Id!=null);
            
            EDGE_UtilityClass.printGovLimits(418);
            String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            outletVisit =EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            outletVisit.Name='Gold[GB]';
            outletVisit.RecordTypeId = pickupRecordType;
            
            insert outletVisit ;
            System.debug('@@@'+limits.getQueries());
            operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Person_Responsible__c = testAdminUser.Id;
            operator.IsOperator__c = true;
            //insert operator;
            
            Test.startTest();
            outletRec = EDGE_UtilityTestClass.getOutletRecord();
            outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id; 
            outletRec.Independent_of_Operator__c = true; //false
            outletRec.Independent_of_Owner__c = true;
            
            insert outletRec;
            System.debug('@@@'+limits.getQueries());
            
            EDGE_UtilityClass.printGovLimits(449);

            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outletRec.Id;
            newAccTeamMember.UserId = testMDMUser.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            System.debug('@@@'+limits.getQueries());
            System.assert(newAccTeamMember.Id!=null);
            
            EDGE_UtilityClass.printGovLimits(462);
            
            //Create Sales Rep
            salesRepUser = EDGE_UtilityTestClass.runAsUser('SalesRep01','Sales Representative'); 
            salesRepUser.ManagerId = testadminUser.id;
            salesRepUser.Available_Countries__c = 'GB';
            insert salesRepUser;
			System.debug('@@@'+limits.getQueries());
            salesRepUser.Available_Countries__c = 'GB';
            update salesRepUser;

            System.debug('@@@'+limits.getQueries());
            //insert Business Role
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            brtest.Country__c = countryId;
            insert brtest;
            System.debug('@@@'+limits.getQueries());
            User_Business_Role__c ubrtest1 = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
            insert ubrtest1;
            System.debug('@@@'+limits.getQueries());
            EDGE_UtilityClass.printGovLimits(488);

            Role_Call__c roleCall = new Role_Call__c();
            roleCall.Call_Type__c = callTypeId; // [SELECT Id FROM Call_Type__c LIMIT 1].Id;
            roleCall.KPIs_Active__c = 'Calls Per Day;Days In Trade;Coverage Compliance;Planned Call Compliance;Outlet Visit Compliance';
            roleCall.Business_Role__c = brtest.Id;
            insert roleCall;
            System.debug('@@@'+limits.getQueries());
            EDGE_UtilityClass.printGovLimits(498);
            
            //salesRepUser = [Select Id from User LIMIT 1];// where Name = 'salesRep1' LIMIT 1];
            System.debug('salesRepUser : '+ salesRepUser);
        }

        System.runAs(testMDMUser) {
            
            List<Call__c> callList = new List<Call__c>();

            callObj.Account__c = outletRec.Id;
            callObj.Start_Date__c = System.today();
            callObj.Status__c = 'Open';
            callObj.Call_Performed_By__c=salesRepUser.Id;//testMDMUser.Id;
            callObj.Type_of_Call__c = callTypeId; //[SELECT Id FROM Call_Type__c LIMIT 1].Id;
            callObj.Plan_Start_Date__c = System.today();
            callList.add(callObj);
            //insert callObj;
            
            //Call__c callObj1 = new Call__c(); 
            callObj1.Account__c = outletRec.Id;
            callObj1.Start_Date__c = System.today();
            callObj1.Status__c = 'Open';
            callObj1.Call_Performed_By__c=salesRepUser.Id;
            callObj1.Type_of_Call__c = callTypeId;// [SELECT Id FROM Call_Type__c LIMIT 1].Id;
            callObj1.Plan_Start_Date__c = System.today();
            callList.add(callObj1);
            //insert callObj1;
            
            //EDGE_UtilityFlagControls.stopCallTriggerInsertUpdateToRun = true;
            Database.insert(callList);
            System.debug('@@@'+limits.getQueries());
            //EDGE_UtilityFlagControls.stopCallTriggerInsertUpdateToRun = false;

            EDGE_UtilityClass.printGovLimits(535);

            Test.stopTest();
        } 
        System.debug('@@@'+limits.getQueries());
        System.runAs(testAdminUser) {
            
            List<Call__c> updatedCallList = new List<Call__c>();
            
            //callObj.End_Date__c = System.now();
            //callObj.Status__c = 'Completed';
            //updatedCallList.add(callObj);
            
            Call__c CallObj11 = new Call__c();
            CallObj11.Id = callObj.Id;
            CallObj11.End_Date__c = System.now();
            CallObj11.Status__c = 'Completed';
            CallObj11.Call_Performed_By__c=salesRepUser.Id;
            CallObj11.Type_of_Call__c = callTypeId;
            //updatedCallList.add(callObj);
            
            //callObj1.End_Date__c = System.now();
            //callObj1.Status__c = 'Completed';
            //updatedCallList.add(callObj1);
            
            Map<Id, SObject> newItems = new Map<Id, SObject>();
            newItems.put(CallObj11.Id, CallObj11);
            Map<Id, SObject> oldItems = new Map<Id, SObject>();
            oldItems.put(callObj.Id, callObj);
            Database.update(updatedCallList);
            System.debug('@@@'+limits.getQueries());
            EDGE_CallTriggerExtendedHelper.calculateDaysinTrade(newItems, oldItems);
            EDGE_CallTriggerHelper.calculateCallPerDay(newItems.values());

            EDGE_UtilityClass.printGovLimits(566); 
			System.debug('@@@'+limits.getQueries());
            
        }
    }*/
}