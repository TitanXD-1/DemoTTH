@isTest
public class EDGE_POSOrderEmailAttachmentCntrlTest {

    @isTest
    public static void testController(){
        EDGE_POSOrderEmailAttachmentController posOrdEmlController = new EDGE_POSOrderEmailAttachmentController();
        posOrdEmlController.orderToOrderItemMap = new Map<String,List<Order_Item__c>>();
        posOrdEmlController.orderIdToOrderAddressMap = new Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord>();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');     
        System.assert(countryId!=null);// Added by Divya
    }
}