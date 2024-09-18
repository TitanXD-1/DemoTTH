/**********************************************************************
Name: EDGE_ApprovalRequestControllerTest 
=======================================================================
Used to give coverage of EDGE_ApprovalRequestController
-----------------------------------------------------------------------
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Aparajita         12/12/2020        ES20-9054   
***********************************************************************/
@isTest
public class EDGE_ApprovalRequestControllerTest {
    @isTest
    public  static void testComments(){
        EDGE_ApprovalRequestController ctrl = new EDGE_ApprovalRequestController();
        system.debug(logginglevel.debug,'Get URL '+ ctrl.getURL);
        System.assert(ctrl.getURL!=null,'URL Not Found');
    }

}