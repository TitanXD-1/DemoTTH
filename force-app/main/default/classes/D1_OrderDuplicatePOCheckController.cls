/**
 * @name : D1_OrderDuplicatePOCheckController
 * @description : Controller Class for OrderDuplicatePOCheck
 * @history                                                                                                                      
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Kapil Baliyan     10/02/2021        Initial Development
 * 2.0         Saurav Paul       18/02/2021        doDuplicatePOcheck
 * 3.0         Dipanjan Das      03/08/2021        Code Refactoring(NCP-3775)  
 **/
public class D1_OrderDuplicatePOCheckController {

    /**
     * @description parseResponse
     * @param response 
     * @return  `DuplicatePOWrapper`
     */     
    public static DuplicatePOWrapper parseResponse(List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element> response){
        DuplicatePOWrapper duplicatePOWrapper = new DuplicatePOWrapper();
        List<DuplicatePOConflictWrapper> duplicatePOConflictWrapperList = new List<DuplicatePOConflictWrapper>();
        if(response != null){
            duplicatePOWrapper.hasPoConflict = true;
            for(D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element res : response){
                DuplicatePOConflictWrapper duplicatePOConflictWrapper = new DuplicatePOConflictWrapper();
                duplicatePOConflictWrapper.poNumber = res.PO_NUM;
                duplicatePOConflictWrapper.sapOrderNumber = res.SAP_ORDER;
                duplicatePOConflictWrapperList.add(duplicatePOConflictWrapper);
            }
            duplicatePOWrapper.duplicatePOConflictList = duplicatePOConflictWrapperList;//Added
        }else{
            duplicatePOWrapper.hasPoConflict = false;
            duplicatePOWrapper.duplicatePOConflictList = duplicatePOConflictWrapperList;
        }
        
        return duplicatePOWrapper;
    }
    
    public class DuplicatePOWrapper {
        @AuraEnabled public boolean isSuccess {get; set;}
        @AuraEnabled public Boolean hasPoConflict {get;set;}
        @AuraEnabled public boolean isPOException {get; set;}
        @AuraEnabled public List<DuplicatePOConflictWrapper> duplicatePOConflictList {get; set;}
        
    }
    
    public class DuplicatePOConflictWrapper {
        @AuraEnabled
        public string poNumber {get; set;}
        @AuraEnabled
        public string sapOrderNumber {get; set;}
    }
    
    /**
     * @description Callout to SAP Duplicate PO Interface
     * @param shiptoNumber 
     * @param poNumberList 
     * @return  `List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element>`
     */    
    public static List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element> doDuplicatePOcheck(String shiptoNumber,List<String> poNumberList){
        D1_OrderDuplicatePOCheckWSDL.HTTPS_Port req = new D1_OrderDuplicatePOCheckWSDL.HTTPS_Port();
        List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element> conflictsList = new List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element>();
        conflictsList = req.SI_PurchaseOrderCheck_Sync_Out_D1(shiptoNumber, poNumberList);
        return conflictsList;
    }
    

    /**
     * @description This method will return SAP Responses to LWC
     * @param poNumberList 
     * @param shipToNumber 
     * @return  `DuplicatePOWrapper`
     */
    @AuraEnabled
    public static DuplicatePOWrapper getDuplicatePO(List<String> poNumberList, String shipToNumber){
        D1_OrderDuplicatePOCheckWSDL.DT_PurchaseOrderCheck_Request_D1 request;
        List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element> response;
        try{
            if(!poNumberList.isEmpty()){
                request = new D1_OrderDuplicatePOCheckWSDL.DT_PurchaseOrderCheck_Request_D1();
                request.SHIP_TO = shipToNumber;
                request.PO_NUMBER = poNumberList;

                response = doDuplicatePOcheck(shipToNumber,poNumberList);//Get response
                DuplicatePOWrapper dupPOResponse = parseResponse(response);//Parse Response
                return dupPOResponse;
            }
        }catch(Exception ex){
            //NCP-3577
            D1_CustomLoggingUtility.logMessage('D1_OrderDuplicatePOCheckController', 'getDuplicatePO', ex, (request != NULL? JSON.serialize(request):''), (response != NULL? JSON.serialize(response):''));
            DuplicatePOWrapper duplicatePOWrapper = new DuplicatePOWrapper();
            List<DuplicatePOConflictWrapper> duplicatePOConflictWrapperList = new List<DuplicatePOConflictWrapper>();
            duplicatePOWrapper.hasPoConflict = false;
            duplicatePOWrapper.isPOException = true;
            duplicatePOWrapper.duplicatePOConflictList = duplicatePOConflictWrapperList;
            return duplicatePOWrapper;
        }
        return null;
    }

}