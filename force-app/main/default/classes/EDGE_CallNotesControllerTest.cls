/*
Name: EDGE_CallNotesControllerTest
Req: This is the test class for EDGE_CallNotesController class.
User Story : ES20-623
History                                                            
VERSION   AUTHOR            DATE              DETAIL
   1.0   Preyanka Ghosh     22/04/2019      Initial Development
*/
@isTest
public class EDGE_CallNotesControllerTest {
    
    /*
    Purpose: Test method to cover getCallNotes                                                         
    */
    @isTest
    public static void getCallNotesTest(){
        
        Test.startTest();
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','Object Account Name should be match');
        
        Call__c objCall = EDGE_UtilityTestClass.getCallRec(objAccount.Id);
        insert objCall;
        
        Call__c objSecCall = EDGE_UtilityTestClass.getCallRec(objAccount.Id);
        insert objSecCall;  
        
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.pdf');
        conVerRec.Content_Type__c = 'Other';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec insert');
        
        FeedItem feed = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'textPost', objAccount.Id);
        feed.RelatedRecordId = conVerRec.Id;
        insert feed;
        
        FeedItem secFeed = EDGE_UtilityTestClass.getFeedItem('feed post 2', 'contentPost', objCall.Id);
        secFeed.RelatedRecordId = conVerRec.Id;
        insert secFeed;
        
        FeedItem thirdFeed = EDGE_UtilityTestClass.getFeedItem('feed post 3', 'textPost', objSecCall.Id);
        thirdFeed.RelatedRecordId = conVerRec.Id;
        insert thirdFeed;
        
        FeedItem forthFeed = EDGE_UtilityTestClass.getFeedItem('feed post 4', 'contentPost', objAccount.Id);
        forthFeed.RelatedRecordId = conVerRec.Id;
        insert forthFeed;
        
        EDGE_CallNotesController.getCallNotes(objAccount.Id);
        
        //To cover catch block
        EDGE_CallNotesController.getCallNotes('1234');
        
        Test.stopTest();
    }

}