/* @name: D1_TransferOrderController
* @discription: Transfer order for D1
* @History                                                                                                                       
* VERSION     AUTHOR         DATE              DETAIL
* 1.0         Rithika         22/04/21         Initial Development(NCP-2670)
* 1.0         Ajay            23/04/21         Initial Development
* 2.0         Rithika         12/10/21         NCP-4846
* 3.0         Rubeena         08/04/22         NCP-6473,NCP-6475,NCP-6474
* 4.0		  Subhrojit       20/09/22		   NCP-7289
**/
public without sharing class D1_TransferOrderController {
    
    static String wholesalerRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Distributor/Wholesaler').getRecordTypeId();
    
    public class Product{
        @AuraEnabled public Integer masterIndex{get;set;}
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String d1Name{get;set;}
        @AuraEnabled public String brand{get;set;}
        @AuraEnabled public String category{get;set;}
        @AuraEnabled public String subCategory{get;set;}
        @AuraEnabled public String volume{get;set;}
        @AuraEnabled public String classification{get;set;}
        @AuraEnabled public String contentVersionId{get;set;}
        @AuraEnabled public List<PickListOption> listOfUOM{get;set;}
        @AuraEnabled public String selectedUOM{get;set;}
        @AuraEnabled public Integer quantity{get;set;}
        
        public Product(Product__c product, Market_Assortment_Product__c assortmentProduct, Integer index){
            this.masterIndex = index;
            this.quantity = 1;
            this.id = product.Id;
            this.name = product.Name;
            this.d1Name = assortmentProduct.D1_Product_Name__c;
            this.brand = product.Brand_Formula__c;
            this.category = product.Category_Formula__c;
            this.subCategory = product.Sub_Category_Formula__c;
            this.volume = product.Volume_Formula__c;
            this.classification = product.Classification_Formula__c;
            this.contentVersionId = assortmentProduct.MAP_Image_Version__c;
            this.listOfUOM = toPickListOptions( assortmentProduct.TO_Used_UOM__c);
        }
        
        private List<PickListOption> toPickListOptions(String toUseUOM){
            List<PickListOption> options = new List<PickListOption>();
            List<String> uoms = String.isEmpty(toUseUOM) ? new List<String>(): toUseUOM.split(';');
            uoms.sort();
            
            for(String uom: uoms){
                options.add(new PickListOption(uom, uom));
            }
            return options;
        }
    }
    
    /**
    * Pick List Option Wrapper
    */
    public class PickListOption{
        @AuraEnabled public String value{get;set;}
        @AuraEnabled public String label{get;set;}
        
        public PickListOption(String value, String label){
            this.value = value;
            this.label = label;
        }
    }
    
    /**
    * Delivery Information wrapper
    */
    public class DeliveryInformation{
        public Id deliverToId;
        public Id distributorId;
        public Date preferredDeliveryDate;
        public Boolean isNextDeliveryDate;
        public String comments;
    }
    
    /**
     * Get Distributor list
     * @param {Id} userId optional
     */
    @AuraEnabled(cacheable=true)
    public static List<Supplier_Outlet__c> getDistributors(Id userId){
        //Fetch Current User
        User currentUser = getCurrentUser(userId);
        List<Supplier_Outlet__c> distributors = [SELECT Id, Distributor_Wholesaler__c, Distributor_Wholesaler__r.Name, Distributor_Wholesaler__r.BillingAddress, Distributor_Wholesaler__r.BillingStreet, Distributor_Wholesaler__r.BillingCity, 
                                                Distributor_Wholesaler__r.BillingState, Distributor_Wholesaler__r.BillingPostalCode, Distributor_Wholesaler__r.BillingCountry, isPrimary__c, Outlet__c, Preferred_Wholesaler__c 
                                                FROM Supplier_Outlet__c 
                                                WHERE Outlet__c =:currentUser.Effective_Account_Id__c
                                                AND Distributor_Wholesaler__c != null  
                                                ORDER BY Distributor_Wholesaler__r.Name ASC];
        
        return distributors;
    }
    
    /**
     * Get Transfer Order Products
     *  @param {Id} userId optional
     */
    @AuraEnabled(cacheable = true)
    public static Object getTransferOrderProducts(Id userId){
        User currentUser = getCurrentUser(userId);
        
        List<String> availableCountries = currentUser.Available_Countries__c == null ? new List<String>() : currentUser.Available_Countries__c.split(';');
        String accessibleChannel = getChannel(currentUser.Effective_Account_Id__c);
        
        Set<Id> accessibleProductIds = new Set<Id>();
        Map<Id, Market_Assortment_Product__c> mapOfProductAssortment = new Map<Id, Market_Assortment_Product__c>();
        //NCP-6473,NCP-6474
        List<Market_Assortment_Product__c> translatedAssortmentProducts = D1_TranslationsUtility.updateTranslationsInRecords([
            SELECT id, Product__c, toLabel(TO_Used_UOM__c), D1_Product_Name__c, Transfer_Order_Product_New__c, MAP_Image_Version__c,D1_Enabled__c
            FROM Market_Assortment_Product__c
            WHERE Market_Assortment__r.Code__c IN:availableCountries
            AND Transfer_Order_Product_New__c INCLUDES(:accessibleChannel)
            AND D1_Enabled__c= true 
        ]);
        
        //NCP-6473,NCP-6474
        for(Market_Assortment_Product__c assortmentProduct : translatedAssortmentProducts){
            accessibleProductIds.add(assortmentProduct.Product__c);
            mapOfProductAssortment.put(assortmentProduct.Product__c, assortmentProduct);
        }
        
        Integer counter = 0;
        List<Product> products = new List<Product>();
        for(Product__c product:[SELECT id, Name, Brand_Formula__c, Category_Formula__c, Sub_Category_Formula__c, Classification_Formula__c, Volume_Formula__c
                                FROM Product__c
                                WHERE Id IN: accessibleProductIds
                                ORDER BY Name])
        {
            products.add(new Product(product, mapOfProductAssortment.get(product.Id), counter++));
        }
        
        return products;
    }
    
    /**
     * Get Current user Information
     * @param {Id} userId optional
     */
    public static User getCurrentUser(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;
        
        List<User> users = [SELECT id, Effective_Account_Id__c, Available_Countries__c, ContactId
                            FROM User
                            WHERE id=: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        return users[0];
    }
    
    /**
     * Get global channel
     * @param {Id} accountId
     */
    public static String getChannel(Id accountId){
        List<Account> accounts = [SELECT id, Global_Channel__c
                                  FROM Account
                                  WHERE id=: accountId];
        if(accounts.isEmpty()){
            throw new AuraHandledException('Access Denied(Account)');
        }
        return accounts[0].Global_Channel__c;
    }
    
    /**
     * Submit Transfer Order
     * @param {String} jsonSelectedProducts JSON format of List<Product>
     * @param {String} jsonDeliveryInfo JSON format of DeliveryInformation
     */
    @AuraEnabled
    public static Id submitOrder(String jsonSelectedProducts, String jsonDeliveryInfo){
        try{
            
            List<Product> products = (List<Product>) JSON.deserialize(jsonSelectedProducts, List<Product>.class);
            DeliveryInformation deliveryInfo = (DeliveryInformation) JSON.deserialize(jsonDeliveryInfo, DeliveryInformation.class);
            if(products.isEmpty()){
                throw new AuraHandledException('Empty Order');
            }
            
            User currentUser = getCurrentUser(UserInfo.getUserId());
            
            //Insert Order with "Draft" Status
            Id orderId = insertOrder(currentUser, deliveryInfo);
            
            //Insert Order Items
            insertOrderItems(products, orderId);
            
            //Update Order with "Submitted" Status
            updateOrder(orderId);
            
            return orderId;
            
        }catch(Exception ex){
            throw ex;
        }
        
    }
    
    /**
    * Helper, Inserts Order & return Order Id
    */
    @testVisible
    private static Id insertOrder(User currentUser, DeliveryInformation deliveryInfo){
        final String orderRecordType = 'Transfer Order';
        final Map<String, Object> mapOfDefaultFieldValues= new Map<String, Object>{
            'RecordTypeId' => getRecordTypeIdByName('Order__c', orderRecordType),
            'Status__c' => 'Draft',
            'Source_Application__c' => 'Diageo One',
            'Sales_Representative__c' => currentUser.Id,
            'Account__c' => currentUser.Effective_Account_Id__c,
            'Contact__c' => currentUser.ContactId
            };
                    
        Order__c order = new Order__c();
        order = (Order__c) setDefaultFieldValues(order, mapOfDefaultFieldValues);
        order.Delivery_Address__c = deliveryInfo.deliverToId;
        order.Wholesaler__c = deliveryInfo.distributorId;
        order.Comments__c = deliveryInfo.comments;
        
        if(deliveryInfo.isNextDeliveryDate == true){
            order.Next_Delivery_Date__c = true;
        }else{
            order.Preferred_Delivery_Date__c = deliveryInfo.preferredDeliveryDate;
        }
        
        insert order;
        return order.id;
    }
    
    /**
    * Helper, Insert OrderItems
    */
    @testVisible
    private static void insertOrderItems(List<Product> products, Id orderId){
        final String orderItemRecordType = 'Transfer Order Item';
        final Map<String, Object> mapOfDefaultFieldValues= new Map<String, Object>{
            'RecordTypeId' => getRecordTypeIdByName('Order_Item__c', orderItemRecordType),
                'Status__c' => 'Submitted'
                };
                    
        User currentUser = getCurrentUser(UserInfo.getUserId());
        
        List<String> availableCountries = currentUser.Available_Countries__c == null ? new List<String>() : currentUser.Available_Countries__c.split(';');
        
        List<Order_Item__c> orderItems = new List<Order_Item__c>();
        set<Id> productIdSet = new set<Id>();
        for(Product product : products){
            productIdSet.add(product.Id);
        }
        Map<Id, Id> mapOfProductAssortment1 = new Map<Id, Id>();
        for(Market_Assortment_Product__c obj : [SELECT id, Product__c FROM Market_Assortment_Product__c
                                                WHERE Market_Assortment__r.Code__c IN:availableCountries AND Product__c IN :productIdSet]) {
                                                    mapOfProductAssortment1.put(obj.Product__c,obj.Id);
                                                }
        
        for(Product product : products){
            Order_Item__c item = new Order_Item__c();
            item = (Order_Item__c) setDefaultFieldValues(item, mapOfDefaultFieldValues);
            
            item.Order__c = orderId;
            item.Product__c = product.id;
            item.Quantity__c = product.quantity;
            item.Selected_UoM__c = product.selectedUOM;
            if(mapOfProductAssortment1.get(product.Id) != null) {
                item.Market_Assortment_Product__c = mapOfProductAssortment1.get(product.Id);
            }
            
            orderItems.add(item);
        }
        
        insert orderItems;
    }
    
    /**
    * Helper, Update Order
    */
    @testVisible
    private static void updateOrder(Id orderId){
        final String status = 'Submitted';
        
        update new Order__c(id = orderId, Status__c = status);
    }
    
    /**
    * Set Default values to an sObject
    * @param {sObject} targetRecord
    * @param {Map} mapOf Field Values
    */
    @testVisible
    private static sObject setDefaultFieldValues(sObject record, Map<String, Object> mapOfFieldValues){
        for (String field : mapOfFieldValues.keySet()) {
            record.put(field, mapOfFieldValues.get(field));
        }
        return record;
    }
    
    /**
    * Return RecordType Id from Object Name, RecordType Name
    */
    @testVisible
    private static Id getRecordTypeIdByName(String objectName, String strRecordTypeName){
        return  Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
    }
    
    /**
    * Get Current user Information
    * @param {Id} userId optional
    */
    @AuraEnabled(cacheable=true)    
    public static List<orderProductsWrap> getOrderItems(Id orderId, Id userId){
        
        Set<Id> prodIds = new Set<Id>();
        User currentUser = getCurrentUser(userId);
        List<String> availableCountries = currentUser.Available_Countries__c == null ? new List<String>() : currentUser.Available_Countries__c.split(';');
        List<orderProductsWrap> ordProdWrapList = new List<orderProductsWrap>();
        Map<Id, Id> productWithContentMap = new Map<Id, Id>();
        Map<Id, String> mapProductIdToD1ProductName = new Map<Id, String>();
        List<Order_Item__c> orderItems = [SELECT Id, Quantity__c, Selected_UoM__c, Product__c, Product__r.Name 
                                          FROM Order_Item__c 
                                          WHERE Order__c = :orderId];
        
        for(Order_Item__c ordItem : orderItems){
            prodIds.add(ordItem.Product__c);
        }

        //NCP-6475
        List<Market_Assortment_Product__c> translatedAssortmentProducts = D1_TranslationsUtility.updateTranslationsInRecords([
            SELECT id, Product__c,D1_Product_Name__c, MAP_Image_Version__c FROM Market_Assortment_Product__c
            WHERE Market_Assortment__r.Code__c IN:availableCountries AND Product__c IN :prodIds
        ]);
        
        //NCP-6475
        for(Market_Assortment_Product__c assortmentProduct : translatedAssortmentProducts){
            productWithContentMap.put(assortmentProduct.Product__c, assortmentProduct.MAP_Image_Version__c); 
            mapProductIdToD1ProductName.put(assortmentProduct.Product__c, assortmentProduct.D1_Product_Name__c);
        }
        
        for(Order_Item__c ordItem : orderItems){
            orderProductsWrap ordProdWrap = new orderProductsWrap();  
            ordProdWrap.ordItem = ordItem;
            String d1ProdName = mapProductIdToD1ProductName.get(ordItem.Product__c);
            ordProdWrap.productName = d1ProdName!=null ? d1ProdName : ordItem.Product__r.Name ;
            ordProdWrap.contentVersionId = productWithContentMap.containskey(ordItem.Product__c) ? productWithContentMap.get(ordItem.Product__c) : null;                     
            ordProdWrapList.add(ordProdWrap);
        }
        return ordProdWrapList;
    }
    
    public class OrderProductsWrap{
        @AuraEnabled public Order_Item__c ordItem{get;set;}
        @AuraEnabled public String productName{get;set;}
        @AuraEnabled public Id contentVersionId{get;set;}
    }
    
    //NCP-5162
    @AuraEnabled(cacheable=true)
    public static String getDistributorName(Id recordId){
        
        List<Account> distributors= [SELECT Id,Name FROM Account WHERE Id =: recordId];
        
        return distributors.isEmpty() ? '' : distributors[0].Name;
    }
}