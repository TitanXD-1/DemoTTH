public class EDGE_POSOrderEmailAttachmentController {
	
    public String labelLang {get;set;}
    public String delPartnerId {get;set;}
    public String batchContext {get;set;}    
    public string xlsHeader {get;set;}
    public string endfile{get;set;}
	public List<Order__c> orderList{get;set;}
    public Map<String,List<Order_Item__c>> orderToOrderItemMap{get;set;}
    public Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord> orderIdToOrderAddressMap{get;set;}
    
    public EDGE_POSOrderEmailAttachmentController(){
        
       	Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
        Set<Id> orderIds = new Set<Id>();
        Set<Id> delivryPartnrMailSet = new Set<Id>();
        List<Delivery_Partner__c> deliveryPartMailList = new List<Delivery_Partner__c>();
        String posOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        String stockmovmntOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        String orderIdsParam = '';
        
        //VF page gives some issues directly using the below code there, so wrap up in variable
        xlsHeader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        
        labelLang = reqParams.get('label_lang');
        batchContext = reqParams.get('batch_context');
        delPartnerId = reqParams.get('del_partner_id');        
        orderIdsParam = reqParams.get('order_ids');
        
        if(Test.isRunningTest()){
        	labelLang = 'en_US';
            batchContext = 'true';
        }
        System.debug('orderIdsParam = '+ orderIdsParam);
        
        prepareEmailAttachment(labelLang, batchContext, delPartnerId, orderIdsParam);
    }
    
    public void prepareEmailAttachment(String labelLang, String batchContext, String delPartnerId, String orderIdsParam){
        
        Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
        Set<Id> orderIds = new Set<Id>();
        Set<Id> delivryPartnrMailSet = new Set<Id>();
        List<Delivery_Partner__c> deliveryPartMailList = new List<Delivery_Partner__c>();
        String posOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        String stockmovmntOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        
        //VF page gives some issues directly using the below code there, so wrap up in variable
        xlsHeader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        
        if(orderIdsParam != null){            
            orderIds = (Set<Id>)JSON.deserialize(orderIdsParam, Set<Id>.class);    
        }

        System.debug('orderIds = '+ orderIds);
        if(batchContext != null){
            
            if(batchContext.equalsIgnoreCase('false')){//Trigger context
                if(orderIds != null && orderIds.size() > 0){
                    orderList = EDGE_POSStockMvmtEmailHelper.getOrderList(orderIds, false, null);
                }
            }else if(batchContext.equalsIgnoreCase('true')){ //Batch context
                if(delPartnerId != null){
                   orderList = EDGE_POSStockMvmtEmailHelper.getOrderList(null, true, delPartnerId);
                } 
                //orderList = EDGE_POSStockMvmtEmailHelper.getOrderList(orderIds, false);
            }
        }
        System.debug('EDGE_POSOrderEmailAttachmentController > orderList = '+ orderList);
        
        if(orderList != null && orderList.size() > 0){
            
            orderToOrderItemMap = EDGE_POSStockMvmtEmailHelper.getOrderToOrderItemMap(orderList);
            System.debug('orderListOrderMap = '+ orderToOrderItemMap);
          /*  ES20-12722
           Map<Id, AccountContactRelation> orderIdsToContactMap = EDGE_POSStockMvmtEmailHelper.getOutletContactMap(orderList);
            System.debug('orderIdsToContactMap = '+ orderIdsToContactMap);
            */
            orderIdToOrderAddressMap = EDGE_POSStockMvmtEmailHelper.getAddressMap(orderList/*, orderIdsToContactMap*/);
            System.debug('orderIdToOrderAddressMap = '+ orderIdToOrderAddressMap);
            
        }
        
    }
}