/*
Class Name: EDGE_NewsFeedStatusUpdateBatchTest

Author          Version    Date           Detail
Sandip Ghosh    V1.0       23/03/2020     [ES20-7585]This is the test class for 
EDGE_NewsFeedStatusUpdateBatch
Swaraj Samanta  V2.0       06/09/2022     [ES20-13284]Test Class Correction Due to Failure
Joshraj Sen/Sakshi Shan V3.0  01/04/2024  152305 SCA Violation Reduction
*/
@istest
public class EDGE_NewsFeedStatusUpdateBatchTest 
{
    static String newsFeedRecordTypeId = Notification__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Edge365 Newsfeed').getRecordTypeId();
    static String notiContentTypeRecTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Notification').getRecordTypeId();
    @isTest
    public static void activateNewsFeed(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'Country is Added');
        EDGE_UtilityTestClass.createOrgSettings();
        //System.debug('Condition 1 '+Limits.getQueries());
        Notification__c notificationObj = EDGE_NewsFeedStatusUpdateBatchTest.getNotificationObj(countryId);
        //System.debug('Condition 2 '+Limits.getQueries());
        List<ContentVersion> contentVersionList1= new List<ContentVersion>();
        contentVersionList1=EDGE_NewsFeedStatusUpdateBatchTest.getContentVersionList1();         
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument ORDER BY CREATEDDATE];
        //System.assertEquals(documents.size(), 1);
        //System.debug('Condition 4 '+Limits.getQueries());
        List<ContentDocumentLink> contentDocumentLinkList1= new List<ContentDocumentLink>();
        contentDocumentLinkList1=EDGE_NewsFeedStatusUpdateBatchTest.getContentDocumentLinkList1(notificationObj,documents);
        //System.debug('Condition 5 '+Limits.getQueries());
        executeBatch();
        //System.debug('Condition 9 '+Limits.getQueries());
        EDGE_NewsFeedStatusUpdateBatchTest.updateOrgSetting();
        //System.debug('Condition 10 '+Limits.getQueries());
        List<Notification__c> notificationListsSecond= EDGE_NewsFeedStatusUpdateBatchTest.getNotificationListsSecond(countryId);
        Test.startTest();
        //System.debug('Condition 11 '+Limits.getQueries()); 
        List<ContentVersion> contentVersionSecondList= new List<ContentVersion>();
        contentVersionSecondList=EDGE_NewsFeedStatusUpdateBatchTest.getContentVersionSecondList();         
        //System.debug('Condition 12 '+Limits.getQueries());
        List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument ORDER BY CREATEDDATE];
        List<ContentDocumentLink> contentDocumentLinkSecondList= new List<ContentDocumentLink>();
        contentDocumentLinkSecondList=EDGE_NewsFeedStatusUpdateBatchTest.getContentDocumentLinkSecondList(notificationListsSecond,documents1);
        //System.debug('Condition 17 '+Limits.getQueries());
        executeBatch();
        //System.debug('Condition 18 '+Limits.getQueries());  
        //System.debug('Condition 19 '+Limits.getQueries());
        //System.assert(conVerRec2.Id != null);           
        //System.debug('Condition 20 '+Limits.getQueries());
       /*List<ContentDocument> documents2 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument
                                            where Title = 'Notification003.jpeg'];*/
        //System.assertEquals(documents2.size(), 1);
        //System.debug('Condition 21 '+Limits.getQueries());
        executeBatch();
        //System.debug('Condition 26 '+Limits.getQueries());
        Test.stopTest();  
    }
    private static void executeBatch(){
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_NewsFeedStatusUpdateBatch'
                                                  and Country_Code__c ='AU'];
        System.assert(batchSetting.Id != null,'There is a batch');
        System.debug(LoggingLevel.debug,'batchSetting = '+ batchSetting);
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);       
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));       
    }
    public static Notification__c getNotificationObj(Id countryId){
        Notification__c notificationObj = new Notification__c(Status__c = 'Draft',Start_Date__c= System.today(), End_Date__c= System.today() + 5, Country__c = countryId, RecordTypeId = newsFeedRecordTypeId);
        insert notificationObj;
        return notificationObj;
    }
    public static List<ContentVersion> getContentVersionList1(){
        List<ContentVersion> contentVersionList1 = new List<ContentVersion>();
          //This is for Notification Image 
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Notification1234.jpeg');
        conVerRec.RecordTypeId = notiContentTypeRecTypeId;
        conVerRec.Content_Type__c = 'Notification Image';
        conVerRec.Title = 'Notification001.jpeg';
        contentVersionList1.add(conVerRec);
        ContentVersion conVerRecSec = EDGE_UtilityTestClass.gerConVerRec('Notification1234.pdf');
        conVerRecSec.RecordTypeId = notiContentTypeRecTypeId;
        conVerRecSec.Content_Type__c = 'Notification Attachment';
        conVerRecSec.Title = 'Notification001.pdf';
        contentVersionList1.add(conVerRecSec);
        insert contentVersionList1;
        System.assert(conVerRec.Id != null,'There is a Content Version');
        return  contentVersionList1;
         //System.debug('Condition 3 '+Limits.getQueries());
    }
    public static List<ContentDocumentLink> getContentDocumentLinkList1(Notification__c notificationObj,List<ContentDocument> documents){
         List<ContentDocumentLink> contentDocumentLinkList1=new List<ContentDocumentLink>();
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink(notificationObj.Id,documents[0].Id);
        contentDocumentLinkList1.add(conDocLnkRec);
        ContentDocumentLink conDocLnkRecSec = EDGE_UtilityTestClass.getConDocLink(notificationObj.Id,documents[1].Id);
        contentDocumentLinkList1.add(conDocLnkRecSec);
        insert contentDocumentLinkList1;
        System.assert(conDocLnkRec.Id != null,'Content Document Link is Added');
        return contentDocumentLinkList1;
    }
    public static List<Notification__c> getNotificationListsSecond(Id countryId){
        List<Notification__c> notificationListsSecond = new List<Notification__c>();
       Notification__c notificationObj1 = new Notification__c(Status__c = 'Draft',Start_Date__c= System.today()-10, End_Date__c= System.today() - 5, Country__c = countryId, RecordTypeId = newsFeedRecordTypeId);
        notificationListsSecond.add(notificationObj1);		
        Notification__c notificationObj2 = new Notification__c(Status__c = 'Draft',Start_Date__c= System.today()-50, End_Date__c= System.today()-5, Country__c = countryId, RecordTypeId = newsFeedRecordTypeId, URL__c = 'www.google.com');
        notificationListsSecond.add(notificationObj2);
        Database.insert(notificationListsSecond);
        return notificationListsSecond;
    }
    public static List<ContentVersion> getContentVersionSecondList(){
        List<ContentVersion> contentVersionSecondList = new List<ContentVersion>();
          ContentVersion conVerRec1 = EDGE_UtilityTestClass.gerConVerRec('Notification2345.jpeg');
        conVerRec1.RecordTypeId = notiContentTypeRecTypeId;
        conVerRec1.Content_Type__c = 'Notification Image';
        conVerRec1.Title = 'Notification002.jpeg';
        contentVersionSecondList.add(conVerRec1);
        ContentVersion conVerRecSec1 = EDGE_UtilityTestClass.gerConVerRec('Notification2345.pdf');
        conVerRecSec1.RecordTypeId = notiContentTypeRecTypeId;
        conVerRecSec1.Content_Type__c = 'Notification Attachment';
        conVerRecSec1.Title = 'Notification002.pdf';
        contentVersionSecondList.add(conVerRecSec1);
        ContentVersion conVerRec2 = EDGE_UtilityTestClass.gerConVerRec('Notification3456.jpeg');
        conVerRec2.RecordTypeId = notiContentTypeRecTypeId;
        conVerRec2.Content_Type__c = 'Notification Image';
        conVerRec2.Title = 'Notification003.jpeg';
        contentVersionSecondList.add(conVerRec2);
        ContentVersion conVerRecSec2 = EDGE_UtilityTestClass.gerConVerRec('Notification3456.pdf');
        conVerRecSec2.RecordTypeId = notiContentTypeRecTypeId;
        conVerRecSec2.Content_Type__c = 'Notification Attachment';
        conVerRecSec2.Title = 'Notification002.pdf';
        contentVersionSecondList.add(conVerRecSec2);
        insert contentVersionSecondList;
        System.assert(conVerRec1.Id != null,'Content Version is Added');  
        return contentVersionSecondList;
    }
    public static  List<ContentDocumentLink> getContentDocumentLinkSecondList(List<Notification__c> notificationListsSecond, List<ContentDocument> documents1){
    List<ContentDocumentLink> contentDocumentLinkSecondList= new List<ContentDocumentLink>();
       ContentDocumentLink conDocLnkRec1 = EDGE_UtilityTestClass.getConDocLink (notificationListsSecond[0].Id,documents1[0].Id);
        contentDocumentLinkSecondList.add(conDocLnkRec1); 
        ContentDocumentLink conDocLnkRecSec1 =EDGE_UtilityTestClass.getConDocLink(notificationListsSecond[0].Id,documents1[1].Id);
         contentDocumentLinkSecondList.add(conDocLnkRecSec1); 
        ContentDocumentLink conDocLnkRec2 = EDGE_UtilityTestClass.getConDocLink(notificationListsSecond[1].Id,documents1[2].Id);
         contentDocumentLinkSecondList.add(conDocLnkRec2);
        ContentDocumentLink conDocLnkRec3 = EDGE_UtilityTestClass.getConDocLink(notificationListsSecond[1].Id,documents1[3].Id);
        contentDocumentLinkSecondList.add(conDocLnkRec3);
        insert contentDocumentLinkSecondList;
        System.assert(conDocLnkRec1.Id != null,'Content Document Link is Added');
        //System.debug('Condition 14 '+Limits.getQueries());
        //This is for Notification Attachment 
       // System.assert(conVerRecSec1.Id != null);           
        //System.debug('Condition 15 '+Limits.getQueries());
        //List<ContentDocument> documentSec1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =:conVerRecSec1.Id];
        //System.assertEquals(documentSec1.size(), 1);
       // System.debug('Condition 16 '+Limits.getQueries());  
        System.assert(conDocLnkRecSec1.Id != null,'Content Document Link is Added');
        return contentDocumentLinkSecondList;
    }
    public static void updateOrgSetting(){
        Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
        orgSetting.Run_Validation_Rules__c = false;
        update orgSetting;
    }

}