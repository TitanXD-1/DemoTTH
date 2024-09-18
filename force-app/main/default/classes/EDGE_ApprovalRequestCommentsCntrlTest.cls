/*
Name: EDGE_GenerateApprovalLinkControllerTest 

Used to give coverage of EDGE_GenerateApprovalLinkControllerTest
                                                          
History                                                            
                                                          
VERSION   AUTHOR            DATE              DETAIL
1.0       Mayukh S Roy     29/06/2023         298232 
*/

@IsTest
private class EDGE_ApprovalRequestCommentsCntrlTest {

    @IsTest
    private static void testMethod1(){
        
        EDGE_ApprovalRequestCommentsController contr = new EDGE_ApprovalRequestCommentsController();
        System.debug(logginglevel.debug,contr.comments );
        System.assert(contr.comments!=Null,'Not Found');
    }
}