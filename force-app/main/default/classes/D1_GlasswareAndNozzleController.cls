/**
* @name D1_GlasswareAndNozzleController
* @description: Glassware/Nozzle Controller
* @History
* VERSION       AUTHOR              DATE            DETAIL
* 1.0           Ajay                03/1/21         Initial Development (NCP-2068,69)
* 2.0           Rubeena             28/09/21        NCP-4785 [BE_Tech_POS GlassType dropdown]
* 3.0           Narayana            10/11/21        NCP-4960 [getReasonForRequests]
* 4.0           Sai Kumar G         25/11/11        NCP-5189[getProductsNew]
* 5.0           Subhrojit/Pratap    12/02/23        NCP-7886
* 6.0           Mayukh/Mukesh       21/08/2023      143985
* 7.0           Kapil Baliyan       05/10/2023      141090
* 8.0           Kapil Baliyan       23/10/2023      147593 (Code-Refactor)
* 9.0           Prasanth T	        17/11/2023      143523 (productOrderItemRange and getProducts)
* 10.0          Sandeep Bhowmik     22/11/2023      148650 (POS Stock Allocation Gaps )
**/
public without sharing class D1_GlasswareAndNozzleController {
    
    /**
* 
* @param productSubTypes 
* @return  `List<Pick_Up_Options__c>`
*/
    @AuraEnabled(cacheable=true)
    public static List<Pick_Up_Options__c> getProductSubTypesWithTranslations(List<String> productSubTypes){
        List<Pick_Up_Options__c> subTypes = new List<Pick_Up_Options__c>();
        Id prodSubTypeRecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Product_Sub_Type').getRecordTypeId();
        if(productSubTypes != null && productSubTypes.size()>0){
            subTypes = [SELECT Id, Name, (SELECT Id, Option_Name__c FROM D1_Translations__r WHERE Language__c =:UserInfo.getLanguage()) FROM Pick_Up_Options__c WHERE Name IN :productSubTypes AND RecordTypeId = :prodSubTypeRecordTypeId AND Status__c = 'Active'];
        }
        
        return subTypes;
    }
    
    /**
* 
* @return  `ProductConfiguration`
*/
    @AuraEnabled(cacheable = true)
    public static ProductConfiguration getProductsPageConfigurations(){
        //Fetch Current User
        User currentUser = getCurrentUser(null);
        List<String> availableCountries = currentUser.Available_Countries__c == null ? new List<String>() : currentUser.Available_Countries__c.split(';');
        string countryCode = availableCountries != null && availableCountries.size()>0 ? availableCountries.get(0) : 'GB';
        
        //Fetch Order Validation
        Order_Validation_Per_Country__mdt orderValidation = getOrderValidationSettings(countryCode);
        
        //Create Product Config Wrapper
        ProductConfiguration configuration = new ProductConfiguration();
        configuration.isStockValidation = orderValidation?.D1_Stock_Validation__c;
        configuration.isLimitPerOrder = orderValidation?.D1_Product_Limit_Per_Order__c;
        
        return configuration;
    }
    
    /**
* 
* @param userId 
* @return  `User`
* @exception 
*/
    @testVisible
    private static User getCurrentUser(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;
        List<User> users = [SELECT Id, AccountId, Available_Countries__c, LanguageLocaleKey, ContactId, Effective_Account_Id__c FROM User WHERE Id =:userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        return users[0];
    }
    
    /**
* 
* @param countryCode 
* @return  `Order_Validation_Per_Country__mdt`
*/
    @testVisible
    private static Order_Validation_Per_Country__mdt getOrderValidationSettings(String countryCode){
        List<Order_Validation_Per_Country__mdt> orderValidations = [SELECT D1_Stock_Validation__c, D1_Product_Limit_Per_Order__c
                                                                    FROM Order_Validation_Per_Country__mdt
                                                                    WHERE Country_Code__c =: countryCode];
        
        return (orderValidations.isEmpty() ? null : orderValidations[0]);
    }
    
    /**
* 
* @param productSubType 
* @return  `List<Pick_Up_Options__c>`
* @exception 
*/
    @AuraEnabled(cacheable=true)
    public static List<Pick_Up_Options__c> getReasonForRequests(string productSubType){
        try {
            Id reasonForRequestRecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Reason_For_Request').getRecordTypeId();
            List<Pick_Up_Options__c> reasonForRequests = new List<Pick_Up_Options__c>();
            reasonForRequests = [SELECT Id, Name, Geography__r.Code__c FROM Pick_Up_Options__c WHERE RecordTypeId =:reasonForRequestRecordTypeId AND Status__c = 'Active' AND Parent_Option__r.Name =:productSubType ORDER BY Name ASC];
            reasonForRequests = D1_TranslationsUtility.updateTranslationsInRecords(reasonForRequests);
            
            return reasonForRequests;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<ProductWrapper> getProducts(String productType, String productSubType, String altEffectiveAccountId){
        try {
            List<ProductWrapper> productWrapperList = new List<ProductWrapper>();
            Id allocationRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByDeveloperName().get('Allocation').getRecordTypeId(); //NOPMD
            Id posRecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByDeveloperName().get('POS').getRecordTypeId();
            String outletType = 'Outlet'; //NOPMD
            String targetListType = 'Outlet (Target List)'; //NOPMD
            String stateType = 'State'; //NOPMD
            String segmentType = 'Segment'; //NOPMD
            String stateSegmentType = 'State+Segment'; //NOPMD
            string billingState;
            String globalSegment;
            String localSegment1;
            String localSegment2;
            Map<Id, Stock__c> productStockMap = new Map<Id, Stock__c>();
            List<Order_Item__c> orderItemList = new List<Order_Item__c>();
            
            //Get Current Users
            User currentUser = getCurrentUser(null);
            List<String> availableCountries = currentUser.Available_Countries__c == null ? new List<String>() : currentUser.Available_Countries__c.split(';');
            
            //Get D1 Settings
            D1_Setting__c d1Settings = getD1Setting(availableCountries, currentUser.LanguageLocaleKey);
            
            //Get Account Details
            List<Account> accounts = [SELECT Id, Country__c, BillingState, BillingStateCode, Global_Segment__c, Local_Segment1__c, Local_Segment2__c, Area__c FROM Account WHERE Id =: altEffectiveAccountId];//NCP-7886
            
            Id countryId = accounts.get(0).Country__c;
            
            //Get Product Type Ids
            Set<Id> productTypeIds = getProductTypes(productType, countryId); //NOPMD
            
            //Get Product Sub Type Ids
            Set<Id> productSubTypeIds = getProductSubTypes(productSubType, countryId); //NOPMD
            
            //Get Target List
            Set<Id> targetListIds = new Set<Id>();
            for(Target_List_Member__c tlm : [SELECT Id, Target_List__c FROM Target_List_Member__c WHERE Assignment_Status__c = 'Active' AND Outlet__c =:altEffectiveAccountId]){
                targetListIds.add(tlm.Target_List__c);
            }
            
            //Create Stock Query
            String stockQueryStr = 'SELECT Id, Allocated_Available__c, Product__c,Start_Date__c,End_Date__c FROM Stock__c '
                + ' WHERE RecordTypeId =:allocationRecordTypeId '
                + ' AND Country__c = :countryId '
                + ' AND Product__r.Product_Type__c IN :productTypeIds '
                + ' AND Product__r.Product_Sub_Type__c IN :productSubTypeIds ' 
                + ' AND Product__r.IsActive__c = TRUE '
                + ' AND Product__r.Diageo_One_Product__c = TRUE '
                + ' AND ( ';
            
            //Allocation By Outlet
            stockQueryStr += ' (Type__c =:outletType AND Outlet__c =:altEffectiveAccountId) ';
            
            //Allocation By Target List
            if(targetListIds.size()>0){
                stockQueryStr += ' OR (Type__c =:targetListType AND Target_List__c IN :targetListIds) ';
            }
            
            //Allocation By State
            if(accounts.get(0).BillingState != null){
                billingState = accounts.get(0).BillingState;
                stockQueryStr += ' OR (Type__c =:stateType AND State__r.Name =:billingState) ';
            }
            
            //Allocation By Segment
            if(accounts.get(0).Global_Segment__c != null){
                globalSegment = accounts.get(0).Global_Segment__c;
                localSegment1 = accounts.get(0).Local_Segment1__c;
                localSegment2 = accounts.get(0).Local_Segment2__c;
                
                stockQueryStr += ' OR (Type__c =:segmentType AND Global_Segment__c != NULL AND Global_Segment__c =:globalSegment AND (Local_Outlet_Segment1__c = NULL OR Local_Outlet_Segment1__c = :localSegment1) AND (Local_Outlet_Segment_2__c = NULL OR Local_Outlet_Segment_2__c = :localSegment2)) ';
            }
            
            //Allocation by Segment+State
            if(accounts.get(0).Global_Segment__c != null && accounts.get(0).BillingState != null){
                stockQueryStr += ' OR (Type__c =:stateSegmentType AND State__r.Name =:billingState AND Global_Segment__c != NULL AND Global_Segment__c =:globalSegment AND (Local_Outlet_Segment1__c = NULL OR Local_Outlet_Segment1__c = :localSegment1) AND (Local_Outlet_Segment_2__c = NULL OR Local_Outlet_Segment_2__c = :localSegment2)) ';
            }
            
            stockQueryStr += ')';
            
            //141090
            if(d1Settings.POS_Warehouse_Level_Allocation__c){
                Id areaId = accounts.get(0).Area__c; //NOPMD
                stockQueryStr += ' AND Area__c = :areaId';
            }
            //148650
            if(d1Settings.POS_Time_Based_Allocation__c){
                stockQueryStr += ' AND Start_Date__c <= TODAY AND End_Date__c >= TODAY ';
            }

            
            //stockQueryStr += ' WITH SECURITY_ENFORCED';
            Datetime minStartDate ;
                Datetime maxEndDate ;
            //Query Stock
            for(Stock__c stock : Database.query(stockQueryStr)){
                productStockMap.put(stock.Product__c, stock);
                //143523- Minimum StartDate and Max End Date is collected for all the products to collect order items when pos time based allocation is true.
                if(d1Settings.POS_Time_Based_Allocation__c){
                    if(minStartDate == null){
                        minStartDate = stock.Start_Date__c;
                    }else if(minStartDate != null && stock.Start_Date__c < minStartDate){
                        minStartDate = stock.Start_Date__c;
                    }
                    if(maxEndDate == null){
                        maxEndDate = stock.End_Date__c;
                    }else if(stock.End_Date__c > maxEndDate){
                        maxEndDate = stock.End_Date__c;
                    }               
                }
            }
            if(minStartDate != null && maxEndDate != null && d1Settings.POS_Time_Based_Allocation__c){
                orderItemList = productOrderItemRange(productStockMap, minStartDate, maxEndDate, altEffectiveAccountId); // Gettting order Items
            }
            //Get Products
            List<Product__c> products = [SELECT Id, Name, Description__c, Limit_Per_Order__c, Product_Image_Version_Id__c, Country__c, Country__r.Code__c,
                                         Pack_Size_Description__c, POS_Related_Brand__c, POS_Variant_Types__c,
                                         Product_Type__r.Delivery_Description__c,
                                         Product_Sub_Type__r.Card_Layout_Selection__c 
                                         FROM Product__c WHERE Id IN :productStockMap.keySet() 
                                         AND RecordTypeId =:posRecordTypeId AND IsActive__c = TRUE 
                                         AND Diageo_One_Product__c = TRUE AND Country__c =:countryId 
                                         AND (Start_Date__c = null OR Start_Date__c <= TODAY) 
                                         AND (Expiry_Date__c = null OR Expiry_Date__c >= TODAY) 
                                         ORDER BY Name];
            
            //Get Product Translation
            products = D1_TranslationsUtility.updateTranslationsInRecords(products);
            
            //Create Product Wrapper
            for(Product__c prod : products){
                //143523
                productWrapperList.add(new ProductWrapper(prod, productStockMap.get(prod.Id),orderItemList,d1Settings.POS_Time_Based_Allocation__c));
            }
            
            return productWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @testVisible
    private static Set<Id> getProductTypes(String productType, Id countryId){
        Id prodTypeRecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Product_Type').getRecordTypeId();
        Set<Id> prodTypeIds = new Set<Id>();
        for(Pick_Up_Options__c option : [SELECT Id FROM Pick_Up_Options__c WHERE Product_Type__c =:productType AND RecordTypeId =:prodTypeRecordTypeId AND Status__c = 'Active' AND Geography__c =:countryId]){
            prodTypeIds.add(option.Id);
        }
        
        return prodTypeIds;
    }
    
    @testVisible
    private static Set<Id> getProductSubTypes(String productSubType, Id countryId){
        Id prodSubTypeRecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Product_Sub_Type').getRecordTypeId();
        Set<Id> prodSubTypeIds = new Set<Id>();
        for(Pick_Up_Options__c option : [SELECT Id FROM Pick_Up_Options__c WHERE Name =:productSubType AND RecordTypeId =:prodSubTypeRecordTypeId AND Status__c = 'Active' AND Geography__c =:countryId]){
            prodSubTypeIds.add(option.Id);
        }
        
        return prodSubTypeIds;
    }
    
    @testVisible
    private static D1_Setting__c getD1Setting(List<String> availableCountries, String language){
        List<D1_Setting__c> d1Settings= [SELECT Id, Market__c, Market__r.Code__c, POS_Warehouse_Level_Allocation__c,POS_Time_Based_Allocation__c FROM D1_Setting__c WHERE Market__r.Code__c IN:availableCountries AND Language__c =:language];
        
        if(d1Settings.isEmpty()){
            throw new AuraHandledException('Access Denied(D1 settings)');
        }
        return d1Settings[0];
    }
    
    @AuraEnabled
    public static Id submitOrder(Order__c order, List<Order_Item__c> orderItems){
        try {
            Id posRecordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByDeveloperName().get('POS_Order').getRecordTypeId();
            Id posItemRecordTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByDeveloperName().get('POS_Item').getRecordTypeId();
            if(order != null){
                //Get Current Users
                User currentUser = getCurrentUser(null);
                
                //Update Order Fields and insert Order
                order.RecordTypeId = posRecordTypeId;
                order.Contact__c = currentUser.ContactId;
                
                insert order;
                
                //Update Order Items and insert Order Items
                if(orderItems != null && orderItems.size()>0){
                    for(Order_Item__c orderItem : orderItems){
                        orderItem.RecordTypeId = posItemRecordTypeId;
                        orderItem.Order__c = order.Id;
                    }
                    
                    insert orderItems;
                }
                
                //Update Order Status to Submitted
                Order__c ord = new Order__c(Id = order.Id, Status__c = 'Submitted');
                update ord;
            }
            
            return order != null ? order.Id : null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Wrapper Classes
    public class ProductConfiguration{
        @AuraEnabled public Boolean isStockValidation{get;set;}
        @AuraEnabled public Boolean isLimitPerOrder{get;set;}
    }
    
    public class ProductWrapper{
        @AuraEnabled public Product__c prod {get;set;}
        @AuraEnabled public Stock__c stock {get;set;}
        @AuraEnabled public List<Order_Item__c> orderItems {get;set;}
        @AuraEnabled public Boolean posTimeBasedCheck {get;set;}
        
        public ProductWrapper(Product__c product, Stock__c allocation,List<Order_Item__c> orderItemList,Boolean posTimeCheck){
            this.prod = product;
            this.stock = allocation;
            this.orderItems = orderItemList;
            this.posTimeBasedCheck = posTimeCheck;
        }
    }

    /**
     * productOrderItemRange
     * @param product 
     * @param startDate 
     * @param endDate 
     * @param itemOutletId 
     * @return  `Map<Id,List<Order_Item__c>>`
     * @description: Introduced Pos time based check to collect order Items and validate quantity.
     * @userStory : 143523
     * bug : 148650 Order_Item_Outlet__c And Order__r.Status__c condition added
     */
    public static List<Order_Item__c> productOrderItemRange(Map<Id, Stock__c> productStockMap,DateTime startDate, DateTime endDate, Id itemOutletId){
        Id posItemRecordTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByDeveloperName().get('POS_Item').getRecordTypeId();
        List<Order_Item__c> orderItemList = new List<Order_Item__c>();   
        orderItemList = [SELECT Id,product__c, Quantity__c,createdDate FROM Order_Item__c WHERE Order_Item_Outlet__c =:itemOutletId AND Order__r.Status__c !='Rejected' AND Product__c IN:productStockMap.keyset() AND RecordTypeId =: posItemRecordTypeId AND createdDate >=:startDate AND createdDate <=:endDate order by createdDate];
        return orderItemList;
    }
}