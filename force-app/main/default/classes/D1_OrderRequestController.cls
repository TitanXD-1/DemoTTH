public without sharing class D1_OrderRequestController {
    @AuraEnabled //(cacheable=true)
    public static List<Order__c> getPOSOrders(string filterStr, string requestType, boolean isShowAccountName2, Boolean limitRecords){
        //Fetch Current User
        User currentUser = getCurrentUser(null);

        //Fetch Account List to fetch order against - NCP-7886
        List<Id> accId = new List<Id>();
        for(D1_DeliveryController.DeliveryAddress accRec : D1_DeliveryController.getDeliveredTo(currentUser.Id)){
            accId.add(accRec.addressId);
        }
        //string accId = currentUser.Effective_Account_Id__c;//AccountId
        
        //Set Other filter criterias and build query
        string recordTypeName = 'POS Order';//NOPMD
        string sourceApplication = 'Diageo One';//NOPMD
        string queryStr = 'SELECT Id, Name, toLabel(Request_Type__c), CreatedDate, toLabel(Status__c), Delivery_Address__c, Delivery_Address__r.Name';
        if(isShowAccountName2 == true){
            queryStr += ',Delivery_Address__r.Name2__c ';
        }
        
        queryStr += ' FROM Order__c WHERE Account__c IN: accId' +
            + ' AND RecordType.Name =:recordTypeName AND Source_Application__c =:sourceApplication' 
            + ' AND Request_Type__c =: requestType ';
                         
        if(string.isNotBlank(filterStr)){
            Map<String, Object> filterMap = (Map<String, Object>)JSON.deserializeUntyped(filterStr);
            
            if(filterMap != null && filterMap.size()>0){
                Time startTime = Time.newInstance(0, 0, 0, 0);
                
                //Get Delivery Address Filter
                string deliveryAddressId = string.valueOf(filterMap.get('deliveryAddress'));
                if(String.isNotBlank(deliveryAddressId) && deliveryAddressId.length() == 18){
                    queryStr += ' AND Delivery_Address__c =:deliveryAddressId';
                }
                
                //Get Start Date Filter
                string startDateStr = String.valueOf(filterMap.get('startDate'));
                if(String.isNotBlank(startDateStr)){
                    Date startDate = Date.valueOf(startDateStr);
                    DateTime startDateTime = DateTime.newInstanceGmt(startDate, startTime);//NOPMD
                    queryStr += ' AND CreatedDate >= :startDateTime';
                }
                
                //Get End Date Filter
                string endDateStr = String.valueOf(filterMap.get('endDate'));
                if(String.isNotBlank(endDateStr)){
                    Date endDate = Date.valueOf(endDateStr);
                    DateTime endDateTime = DateTime.newInstanceGmt(endDate.addDays(1), startTime);//NOPMD
                    queryStr += ' AND CreatedDate < :endDateTime';
                }            
            }
        }
        queryStr += ' WITH SECURITY_ENFORCED ORDER BY Name DESC';
        //NCP-8269 : added LimitRecords in the method
        if(LimitRecords == true){
            queryStr += ' LIMIT 5 ';
        }
        List<Order__c> orderList = new List<Order__c>();
        try {
            orderList = Database.query(queryStr);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return orderList;
    }
    
    public class TransferOrderWrapper{
        @AuraEnabled public Order__c orderobj{get;set;}
        @AuraEnabled public Boolean isStatusCheck{get;set;}
        
    }
    @AuraEnabled //(cacheable=true)
    public static List<TransferOrderWrapper> getTransferOrders(string filterStr, boolean isShowAccountName2, Boolean limitRecords){
        List<TransferOrderWrapper> transferOrderWrapperList = new List<TransferOrderWrapper>();
        //Fetch Current User
        User currentUser = getCurrentUser(null);
        string accId = currentUser.Effective_Account_Id__c;//NOPMD
        string recordTypeName = 'Transfer Order';//NOPMD
        string queryStr = 'SELECT Id,Name,Account__c,Delivery_Address__c, Account__r.Name,Delivery_Address__r.Name,Wholesaler__c,Wholesaler__r.Name,CreatedDate,Source_Application__c,Status__c';
        
        if(isShowAccountName2 == true){
            queryStr += ',Delivery_Address__r.Name2__c ';
        }
        
        queryStr += ' FROM Order__c WHERE Account__c =:accId' +
            + ' AND RecordType.Name =:recordTypeName';
        
        if(string.isNotBlank(filterStr )){
            Map<String, Object> filterMap = (Map<String, Object>)JSON.deserializeUntyped(filterStr);
            
            if(filterMap != null && filterMap.size()>0){
                Time startTime = Time.newInstance(0, 0, 0, 0);
                
                //Get Delivery Address Filter
                string deliveryAddressId = string.valueOf(filterMap.get('deliveryAddress'));
                if(String.isNotBlank(deliveryAddressId) && deliveryAddressId.length() == 18){
                    queryStr += ' AND Delivery_Address__c =:deliveryAddressId';
                }
                
                //Get Start Date Filter
                string startDateStr = String.valueOf(filterMap.get('startDate'));
                if(String.isNotBlank(startDateStr)){
                    Date startDate = Date.valueOf(startDateStr);
                    DateTime startDateTime = DateTime.newInstanceGmt(startDate, startTime);//NOPMD
                    queryStr += ' AND CreatedDate >= :startDateTime';
                }
                
                //Get End Date Filter
                string endDateStr = String.valueOf(filterMap.get('endDate'));
                if(String.isNotBlank(endDateStr)){
                    Date endDate = Date.valueOf(endDateStr);
                    DateTime endDateTime = DateTime.newInstanceGmt(endDate.addDays(1), startTime);//NOPMD
                    queryStr += ' AND CreatedDate < :endDateTime';
                }
            }
        }        
         queryStr += ' WITH SECURITY_ENFORCED ORDER BY Name DESC';
         //NCP-8270 : added LimitRecords in the method
        if(LimitRecords == true){
            queryStr += ' LIMIT 5 ';
        }
        List<Order__c> orderList = new List<Order__c>();
        try {
            orderList = Database.query(queryStr);
            for(Order__c order :orderList){
                TransferOrderWrapper transferOrderWrapperObj = new TransferOrderWrapper(); 
                transferOrderWrapperObj.orderobj = order;
                if(order.Status__c == 'Order Delivered'){
                    transferOrderWrapperObj.isStatusCheck = true;
                }else{
                    transferOrderWrapperObj.isStatusCheck = false;
                }
                transferOrderWrapperList.add(transferOrderWrapperObj);
                
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return transferOrderWrapperList;
    }
    
    @AuraEnabled
    public static void updateOrderStatus(Id orderId){
        List<Order__c> updateOrderList = new List<Order__c>();
        List<Order_Item__c> updateOrderItemList = new List<Order_Item__c>();
        for(Order__c order : [SELECT Id, Status__c from Order__c WHERE Id =: orderId]){
            order.Status__c = 'Order Delivered';
            updateOrderList.add(order);
        }
        update updateOrderList;
        
        for(Order_Item__c orderItem : [SELECT Id,Status__c FROM Order_Item__c WHERE Order__c =: orderId]){
            orderItem.Status__c = 'Order Delivered';
            updateOrderItemList.add(orderItem);
        }
        update updateOrderItemList;
        
    } 

    public static User getCurrentUser(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;
        List<User> users = [SELECT Id, AccountId, ContactId, Effective_Account_Id__c
                            FROM User
                            WHERE Id =:userId WITH SECURITY_ENFORCED];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        return users[0];
    }
}