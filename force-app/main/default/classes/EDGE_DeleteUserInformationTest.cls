/**
Name: EDGE_DeleteUserInformationTest

Req: This is the test class for the  EDGE_DeleteUserInformation class.
User Story : ES20-82826

History                                                            
-------                                                            
VERSION   AUTHOR              DATE              DETAIL
1.0   Monalisa Halder     05/10/2020      Initial Development
2.0   Joshraj Sen         08/04/2024      152305

*/
@isTest
public class EDGE_DeleteUserInformationTest {
    
    @isTest
    public static void getFieldDetailsTest(){
        test.startTest();
        Map<String, Map<String, Object>> mapFieldDetails = EDGE_SearchFieldController.getFieldDetails('User',True);
        System.assert(mapFieldDetails!=null,'mapFieldDetails should not be null');
        EDGE_SearchFieldController.getFieldDetails('User',null);
        test.stopTest();
        
        
    }
    @isTest
    public static void deleteInfoTest(){
        User mdmUser= EDGE_UtilityTestClass.runAsUser('mdmUser','Master Data Manager');
        mdmUser.Username = 'mdmusertosearchinactiveuser@delete.com';
        mdmUser.Default_Country__c = 'AU';
        mdmUser.Available_Countries__c = 'AU';
        insert mdmUser;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('test', 'Sales Representative');
        salesRep.Username = 'inactivesalesrepuser@delete.com';
        salesRep.Email = 'testUserEmail@delete.com';
        salesRep.Start_Street__c = 'Test Street';
        salesRep.Start_City__c = 'Test city';
        salesRep.Start_State__c = 'Test State';
        salesRep.Start_Postcode__c = '1234';
        salesRep.Start_Country__c = 'AU';
        salesRep.Start_Latitude__c = 20.10;
        salesRep.Start_Longitude__c = 22.20;
        salesRep.maps__MapsSetting__c = 'Test MapSetting';
        insert salesRep;
        salesRep.IsActive = False;
        update salesRep;
        system.assert(salesRep.Id!=null,'SalesRep should not be null');
        List<Id> userIdList = new List<Id>();
        userIdList.add(salesRep.Id);
        
       // System.runAs(adminUser){
        System.runAs(mdmUser){    
            string queryStr = 'AND Email = \'testUserEmail@delete.com\'';
            
            Coaching_Report__c coachReport = new Coaching_Report__c();
            coachReport.Sales_Representative__c = salesRep.Id;
            coachReport.Status__c = 'Draft';
            insert coachReport;
            Coaching_Survey__c coachSurvey = new Coaching_Survey__c();
            coachSurvey.Coaching_Report__c= coachReport.Id;
            insert coachSurvey;
            system.assert(coachSurvey.Id != null,'CoachSurvey should not be null');
            coachSurvey.Status__c = 'Report Generated';
            update coachSurvey;
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('CoachingReport.pdf');
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Coaching Report').getRecordTypeId();
            conVerRec.Content_Type__c = 'Coaching Report';
            conVerRec.Title = 'CoachingReport.pdf';
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null');  
           
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId = :conVerRec.Id];
           
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (coachSurvey.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be red');
            
            coachReport.Content_Document_Id__c = documents[0].Id;
            update coachReport;
            
            Personal_Information__c persInfo = new Personal_Information__c();
            persInfo.Registration_Number__c = '262';
            persInfo.User__c = salesRep.Id;
            insert persInfo;
            
            Travel_Logbook__c travelLogBook = new Travel_Logbook__c();
            travelLogBook.Personal_Information__c = persInfo.id;
            travelLogBook.Start_Date__c = system.today();
            travelLogBook.End_Date__c = system.today() + 2;
            insert travelLogBook;
            
            ContentVersion conVerRec1 = EDGE_UtilityTestClass.gerConVerRec('TravelLogBook.jpeg');
            conVerRec1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Travel Logbook').getRecordTypeId();
            conVerRec1.Content_Type__c = 'Travel Logbook';
            conVerRec1.Title = 'TravelLogBook.jpeg';
            insert conVerRec1;
            System.assert(conVerRec1.Id != null,'conVerRec1 should not be null');           
            
            List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId = :conVerRec1.Id];
            
            ContentDocumentLink conDocLnkRec1 = EDGE_UtilityTestClass.getConDocLink (travelLogBook.Id,documents1[0].Id);
            insert conDocLnkRec1;
            
            travelLogBook.Content_Document_Id__c = documents1[0].Id;
            update travelLogBook;
            
            Travel_Log__c travelLog = new Travel_Log__c();
            travelLog.Personal_Information__c = persInfo.id;
            travelLog.Start_Date__c = system.today();
            travelLog.End_Date__c = system.today() + 2;
            insert travelLog;
            
            maps__Location__c mapsLocation = new maps__Location__c();
            mapsLocation.maps__User__c = salesRep.Id;
            insert mapsLocation;
            
            test.startTest();
            System.debug(LoggingLevel.Debug,queryStr);
            EDGE_DeleteUserInformation.searchUserDetails(queryStr);
            EDGE_DeleteUserInformation.deleteUserInfo(userIdList);
            test.stopTest();
        } 
        
    }
    
    
}