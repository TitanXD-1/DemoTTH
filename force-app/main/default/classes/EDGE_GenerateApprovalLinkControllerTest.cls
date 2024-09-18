/*
Name: EDGE_GenerateApprovalLinkControllerTest 

Used to give coverage of EDGE_GenerateApprovalLinkControllerTest
                                                          
History                                                            
                                                          
VERSION   AUTHOR            DATE              DETAIL
1.0       Mayukh S Roy     29/06/2023         298232 
*/

@isTest
public class EDGE_GenerateApprovalLinkControllerTest{
    @isTest
    public  static void testComments(){
        EDGE_GenerateApprovalLinkController ctrl = new EDGE_GenerateApprovalLinkController();
        system.debug(logginglevel.debug,'Get URL '+ ctrl.urlStr);
        System.assert(ctrl.urlStr!=null,'URL Not Found');
    }
}