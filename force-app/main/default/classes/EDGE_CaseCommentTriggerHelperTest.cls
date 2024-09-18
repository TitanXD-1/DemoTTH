/**
* @description EDGE_CaseCommentTriggerHelperTest
* @purpose This is the test class for EDGE_CaseCommentTriggerHelper
* @history
* Version  Developer           Date               Purpose
* 1.0      Juned khan       19/03/2021      Initial Development
*/
@IsTest
public class EDGE_CaseCommentTriggerHelperTest {
    public static Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();


    public static Id techCaseRecTypeId = mapAccountRecordTypes.get('Technical Issue').getRecordTypeId();
    public static Id caseRecTypeId = mapAccountRecordTypes.get('Diageo One Cases').getRecordTypeId();    

    


    @isTest
    public static void createTestData(){
        
        
            EDGE_UtilityTestClass.createOrgSettings();
            List<Case> caselist= new List<Case>();
            
            Case   tCase = new Case();
            tCase.Status = 'New';
            tCase.RecordTypeId=techCaseRecTypeId;
            tCase.Subject = 'Test Case Subject';
            tCase.Priority = '1-Low';
            tCase.Description = 'Test Description';
            tCase.Origin = 'EDGE365';
            tCase.Type='Dispute – Delivery';  
            tCase.Rejection_Reason__c='Already settled'; 
            caselist.add(tCase);
            
            Case   tCase1 = new Case();
            tCase1.Status = 'New';
            tCase.RecordTypeId=techCaseRecTypeId;
            tCase1.Subject = 'Test Case Subject';
            tCase1.Priority = '1-Low';
            tCase1.Description = 'Test1 Description';
            tCase1.Origin = 'EDGE365';
            tCase1.Type='Dispute – Delivery'; 
            tCase1.Rejection_Reason__c='Already settled';
            caselist.add(tCase1);
            
            Case   tCase2 = new Case();
            tCase2.Status = 'New';
            tCase2.RecordTypeId=caseRecTypeId;
            tCase2.Subject = 'Test D1 Case Subject';
            tCase2.Priority = '1-Low';
            tCase2.Description = 'Test D1 Description';
            tCase2.Origin = 'EDGE365';
            tCase2.Type='Dispute – Delivery';  
            tCase2.Rejection_Reason__c='Already settled'; 
            caselist.add(tCase2);
            
            Case   tCase3 = new Case();
            tCase3.Status = 'New';
            tCase3.RecordTypeId=caseRecTypeId;
            tCase3.Subject = 'Test2 D1 Case Subject';
            tCase3.Priority = '1-Low';
            tCase3.Description = 'Test D1 Description';
            tCase3.Origin = 'EDGE365';
            tCase3.Type='Dispute – Delivery';  
            tCase3.Rejection_Reason__c='Already settled'; 
            caselist.add(tCase3);
            
            insert caselist;
            
            
            List<CaseComment> caseComList=new List<CaseComment>();
            CaseComment   tComment = new CaseComment();
            tComment.ParentId = tCase.Id;
            tComment.CommentBody = 'Some Comment';
            tComment.IsPublished = TRUE;
            caseComList.add(tComment);
            
            CaseComment   tComment1 = new CaseComment();
            tComment1.ParentId = tCase1.Id;
            tComment1.CommentBody = 'Some1 Comment';
            tComment1.IsPublished = TRUE;
            caseComList.add(tComment1);
            
            CaseComment   tComment2 = new CaseComment();
            tComment2.ParentId = tCase2.Id;
            tComment2.CommentBody = 'Some D1 Comment';
            tComment2.IsPublished = TRUE;
            caseComList.add(tComment2);
            
            CaseComment   tComment3 = new CaseComment();
            tComment3.ParentId = tCase3.Id;
            tComment3.CommentBody = 'Some D1 Comment';
            tComment3.IsPublished = TRUE;
            caseComList.add(tComment3);
            
            INSERT caseComList;
            
            tComment1.CommentBody = 'test Comment';
            
            UPDATE tComment1;
            System.assert(caseComList.size()>0,'caseCom List should have value');
            
            List<FeedItem> feedList = new List<FeedItem>();
FeedItem feed = EDGE_UtilityTestClass.getFeedItem(caseComList[0].CommentBody, 'TextPost', caselist[0].Id);
feed.Status = 'Published';
feed.ParentId = tCase.Id;
feedList.add(feed);

FeedItem feed1 = EDGE_UtilityTestClass.getFeedItem(caseComList[1].CommentBody, 'TextPost', caselist[1].Id);
feed1.Status = 'Published';
feed1.ParentId = tCase1.Id;
feedList.add(feed1);

Database.insert(feedList); 
            
            DELETE tComment1;
            
            UNDELETE tComment1;
            
           
    }
}