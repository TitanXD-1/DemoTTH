/**
* @description Util methods for B2B commerce on Lightning Samples
*
* @see B2BUtils
*/
public without sharing class B2BUtils {
    // A cache which maps community Ids to WebStore Ids
    @TestVisible private static Map<String, String> communityIdToWebStoreIdCache = new Map<String, String>();
    
    // A cache to map a string to ConnectApi.CartItemSortOrder
    private static Map<String, ConnectApi.CartItemSortOrder> sortOrderCache = new Map<String, ConnectApi.CartItemSortOrder>();
    
    /**
    * @description Given a community ID, returns the relavent webstore ID for use in B2B Commerce on lightning
    * @param  communityId The Id of the community from which the call originated
    * @return weStoreId The webStoreId corresponding to the community Id.
    * @example
    * String webStoreId = B2BUtils.resolveCommunityIdToWebstoreId('0DB2D0000004Xz7');
    */
    public static String resolveCommunityIdToWebstoreId(String communityId) {
        if (communityIdToWebStoreIdCache.containsKey(communityId)) {
            return communityIdToWebStoreIdCache.get(communityId);
        } else {
            String webStoreId = [
                SELECT WebStoreId
                FROM WebStoreNetwork
                WHERE NetworkId = :communityId
                LIMIT 1
            ].WebStoreId;
            communityIdToWebStoreIdCache.put(communityId, webStoreId);
            return webStoreId;
        }
    }
    
    /**
    * @description Given a sortParam string, return null or the relavent ConnectApi.CartItemSortOrder enum value
    * See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum for the enum values
    * @param  sortParam A string representing a sort Param.
    * @return resolvedSortParam A ConnectApi.CartItemSortOrder enum value or null
    * @example
    * ConnectApi.CartItemSortOrder sortParam = B2BUtils.resolveSortParam('CreatedDateAsc');
    */
    public static ConnectApi.CartItemSortOrder resolveSortParam(String sortParam) {
        if (sortOrderCache.isEmpty()) {
            for (
                ConnectApi.CartItemSortOrder sortOrder : ConnectApi.CartItemSortOrder.values()
            ) {
                sortOrderCache.put(sortOrder.name(), sortOrder);
            }
        }
        return sortOrderCache.get(sortParam);
    }
    
    //Method to get Cart Details
    @AuraEnabled
    public static GenericCartWrapper getCartId(String userId, String accountId){
        
        String webStoreName = System.Label.D1_Commerse_StoreName;
        GenericCartWrapper gcw;
        
        if(string.isNotBlank(userId)){
            String effectiveAccountId;
            if(string.isNotBlank(accountId)){
                effectiveAccountId = accountId;
            }else{
                List<User> userDetail = new List<User>();
                if(Schema.sObjectType.User.fields.Effective_Account_Id__c.isAccessible()){ //PMD-152932
                    userDetail = [SELECT Effective_Account_Id__c from User WHERE Id =:userId  LIMIT 1];
                    if(userDetail.size()>0){
                        effectiveAccountId= userDetail[0].Effective_Account_Id__c;
                    }
                }
            }                       
            
                List<WebStore> webStoreList = new List<WebStore>();
                if(Schema.sObjectType.WebStore.fields.Id.isAccessible()){ //PMD-152932
                    webStoreList = [SELECT Id FROM WebStore WHERE Name =:webStoreName];
                }

            if(webStoreList.size()>0){
                List<WebCart> webCartList = new List<WebCart>();
                if(Schema.sObjectType.WebCart.isAccessible()){ //PMD-152932
                    webCartList = [SELECT Id,Shipto_Party__c,
                                            Delivery_Address__c,
                                            Sales_Area__r.Max_Order_Line_Items__c,
                                            Sales_Area__r.Max_Weight__c,
                                            Sales_Area__r.Max_Pallets__c,CanViewPrice__c,
                                            Sales_Area__r.Min_Weight__c,Sales_Area__r.Min_Pallets__c
                                            FROM WebCart 
                                            WHERE Status ='Active' AND WebStoreId =:webStoreList[0].Id 
                                            AND AccountId =:effectiveAccountId AND OwnerId =:userId];
                }                                
                System.debug(LoggingLevel.INFO, webCartList);
                if(webCartList.size()>0){
                    gcw = new GenericCartWrapper();
                    gcw.accountId = effectiveAccountId;
                    gcw.webstoreId = webStoreList[0].Id;
                    gcw.cartId = webCartList[0].Id;
                    gcw.maxOrderLineItems =webCartList[0].Sales_Area__r.Max_Order_Line_Items__c;
                    gcw.maxWeight = webCartList[0].Sales_Area__r.Max_Weight__c;
                    gcw.maxPallets =webCartList[0].Sales_Area__r.Max_Pallets__c;
                    gcw.minWeight =	webCartList[0].Sales_Area__r.Min_Weight__c;
                    gcw.minPallets = webCartList[0].Sales_Area__r.Min_Pallets__c;
                            
                    gcw.canViewPrice =webCartList[0].CanViewPrice__c;
                    gcw.shipToNumber=webCartList[0].Shipto_Party__c;
                    gcw.deliveryToAddress=webCartList[0].Delivery_Address__c;
                } 
                else {
                    D1_B2BCartController.createCart(webStoreList[0].Id,effectiveAccountId);
                    webCartList = [ SELECT  Id,Shipto_Party__c,
                                            Delivery_Address__c,Sales_Area__r.Max_Order_Line_Items__c,
                                            Sales_Area__r.Max_Weight__c,
                                            Sales_Area__r.Max_Pallets__c,Sales_Area__r.Min_Weight__c,
                                            Sales_Area__r.Min_Pallets__c,CanViewPrice__c
                                            FROM WebCart WHERE Status ='Active' AND 
                                            WebStoreId =:webStoreList[0].Id AND AccountId =:effectiveAccountId AND OwnerId =:userId];
                    if(webCartList.size()>0){
                        gcw = new GenericCartWrapper();
                        gcw.accountId = effectiveAccountId;
                        gcw.webstoreId = webStoreList[0].Id;
                        gcw.cartId = webCartList[0].Id;
                        gcw.maxOrderLineItems =webCartList[0].Sales_Area__r.Max_Order_Line_Items__c;
                        gcw.maxWeight = webCartList[0].Sales_Area__r.Max_Weight__c;
                        gcw.maxPallets =webCartList[0].Sales_Area__r.Max_Pallets__c;
                        gcw.minWeight =	webCartList[0].Sales_Area__r.Min_Weight__c;
                        gcw.minPallets = webCartList[0].Sales_Area__r.Min_Pallets__c;
                        gcw.canViewPrice =webCartList[0].CanViewPrice__c;
                                    
                        gcw.shipToNumber=webCartList[0].Shipto_Party__c;
                        gcw.deliveryToAddress=webCartList[0].Delivery_Address__c;
                    }
                }
            }
        }
        return gcw;
    }
    
    //143985:Migrate getD1Setting method in D1_UtilityClass
    //Method to get Market Setting
   /* @AuraEnabled(cacheable = true)
    public static Object getD1Setting(Id userId){
        if(string.isEmpty(userId)){
            userId = userInfo.getUserId();
        }
        User loggedInUser = [SELECT Available_Countries__c,LanguageLocaleKey FROM User WHERE ID =: userId];
        
        List<String> availableCountry= loggedInUser.Available_Countries__c!=Null?loggedInUser.Available_Countries__c.split(','):new List<String>();
        //NCP-6299 added Customer_Service_Instructions_Tool_Tip__c,Delivery_Instructions_Tool_Tip__c
        List<D1_Setting__c> d1Settings = [SELECT Id,Language__c,Default__c,Delivery_Instructions__c,Is_KEG_Return__c,Market__r.Name,Contact_Us_Phone__c ,Market__c,Duplicate_PO_check__c,
                                          Order_Simulation_enabled__c,CS_Instructions_display__c,Order_Acknowledgement_PDF__c,Order_History_Date_Range__c, Billing_History_Date_Range__c,Cases_per_pallet__c,
                                          Split_1_PO_Number_Tool_Tip__c,Split_2_PO_Number_Tool_Tip__c,PO_Number_mandatory__c,Customer_status_Display__c,Duty_Paid_Label__c,Duty_Suspended_Label__c,Order_Status_Tooltip__c,
                                          List_Price_info_label__c,Tax_Identification_Number__c,MAX_Number_of_KEGS_allowed__c,Hide_Tax_Identification_Number__c,Max_Weight_Error__c,Weight_Pallet_Switched__c,Hide_Help_and_Support__c,
                                          Name_2_value__c,Delivery_date_additional_disclaimer__c,Is_Delivery_Date_Additional_Disclaimer__c,Prepopulate_next_Delivery_Date__c,Pioneer_Market__c,MOQ_multiple_validation__c,
                                          Deleted_Ship_To_Warning_Message__c, Blocked_Account_Sold_To_Warning_Message__c, Blocked_Ship_To_Warning_My_Business__c,
                                          Order_Limit_Per_Day__c,Order_Limit_Per_Day_Message__c, Next_Available_Delivery_Date_Message__c,Enable_Survey_Preference__c,Enable_POS_Order_Terms_and_Conditions__c,Enable_Transfer_Order_Terms_Conditions__c,Request_History_Date_Range__c,
                                          Add_Cases_To_Complete_Layer_Pallet_Msg__c,Customer_Service_Instructions_Tool_Tip__c,Delivery_Instructions_Tool_Tip__c,Proof_Of_Delivery__c,
                                          Show_EDGE_Quality_Cases__c, Enable_Collect_Keg_Button__c, Stock_Availability_Disabled__c, Product_Scanner_Enabled__c, NPS_Survey_Blocker__c,Enable_Push_Notification__c
                                          FROM D1_Setting__c 
                                          WHERE Market__r.Code__c IN: availableCountry 
                                          AND Language__c =: loggedInUser.LanguageLocaleKey];
        if(d1Settings.isEmpty()){
            throw new AuraHandledException('Access Denied');
        }
        return d1Settings[0];                          
    }*/
    
    @AuraEnabled
    public static Object getUserOrderConfig(Id userId){
        final String soldTo = 'Sold-To' ;
        
        if(string.isEmpty(userId)){
            userId = userInfo.getUserId();
        }
        
        List<User> users = [SELECT Id,AccountId,Account.Name,Account.KUNNR__c,Effective_Account_Id__c FROM User WHERE id =: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied');
        }
       
        User currentUser = users[0];
         system.debug(LoggingLevel.INFO, currentuser.Effective_Account_Id__c);
        List<PNR_Partner_Function__c> partnerFunctions = new List<PNR_Partner_Function__c>();
        if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){ //PMD-152932
            partnerFunctions = [SELECT id,Sales_Area__r.Sales_Area_ID__c,
                                    PNR_Distribution_Channel__c,PNR_Division__c,PNR_Sales_Org__c,
                                    PNR_Sold_To__r.Name, PNR_Sold_To__r.KUNNR__c
                                    FROM PNR_Partner_Function__c
                                    WHERE PNR_Sold_To__c  =: currentUser.Effective_Account_Id__c AND
                                    PNR_Type__c =: soldTo
                                    LIMIT 1];
        }
        if(partnerFunctions.isEmpty()){
            throw new AuraHandledException('Access Denied');
        }
        
        OrderConfigWrapper orderConfig = new OrderConfigWrapper();
        orderConfig.customerName = partnerFunctions[0].PNR_Sold_To__r.Name;
        orderConfig.customerNumber = partnerFunctions[0].PNR_Sold_To__r.KUNNR__c;
        orderConfig.salesOrg = partnerFunctions[0].Sales_Area__r.Sales_Area_ID__c;
        orderConfig.salesOrgCode = partnerFunctions[0].PNR_Sales_Org__c;
        orderConfig.distributionChannel = partnerFunctions[0].PNR_Distribution_Channel__c;
        orderConfig.division = partnerFunctions[0].PNR_Division__c;
        
        return orderConfig;
    }

    @AuraEnabled(cacheable = true)
    public static Object getD1UserType(Id userId){
        if(string.isEmpty(userId)){
            userId = userInfo.getUserId();
        }

        List<User> users = [SELECT Id,D1_User_Type_Id__c FROM User WHERE id =: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied');
        }

        List<D1_User_Type__c> userTypes = new List<D1_User_Type__c>();
        if(Schema.sObjectType.D1_User_Type__c.isAccessible()){ //PMD-152932
        userTypes = [SELECT Enable_Fault_Fixer__c,Fault_Fixer_Label__c,Customer_Service_Contact_Number__c,Contact_Us_Description__c,Enable_Contact_Us__c
                                            FROM D1_User_Type__c 
                                            WHERE Id =:users[0].D1_User_Type_Id__c];
        }
        if(userTypes.isEmpty()){
            throw new AuraHandledException('No User Type found');
        }
        D1_User_Type__c userType = userTypes[0];

        UserTypeWrapper userTypeObj = new UserTypeWrapper();
        userTypeObj.isAccessToFaultFixer = userType.Enable_Fault_Fixer__c;
        userTypeObj.faultFixerPageTitle = userType.Fault_Fixer_Label__c;
        userTypeObj.contactUsNumber = userType.Customer_Service_Contact_Number__c;
        userTypeObj.contactUsDescription = userType.Contact_Us_Description__c;
        userTypeObj.isAccessTofaultFixerContactUs= userType.Enable_Contact_Us__c;       
        return userTypeObj;
    }

    @AuraEnabled
    public static Object getCartTotalWeight(Id cartId){
        
        List<WebCart> cart =[Select id,Total_Weight__c,
                                       Sales_Area__r.Max_Weight__c,
                                       Total_Keg__c,
                                       Total_Pallets__c,
                                       Sales_Area__r.Max_Pallets__c,
                                       Sales_Area__r.Min_Weight__c,
                                       Sales_Area__r.Min_Pallets__c,
                                       Order_Split_1__r.Exempt_From_Weight_Validation__c,
                                       Order_Split_2__r.Exempt_From_Weight_Validation__c,
                                       Order_Split_2__r.SAP_OrderSplit_ID__c, Order_Split_2__r.MOQ_Multiple__c,
                                       Order_Split_1__r.SAP_OrderSplit_ID__c , Order_Split_1__r.MOQ_Multiple__c 
                                       from WebCart where id =: cartId];
       return cart[0];
	}

    @AuraEnabled
    public static decimal getLeadAndTransit(String accId, String salesArea){

        List<Outlet_Split_Transit_Duration__c> outletSplit = [SELECT Id, Outlet_ID__c, Order_Split_ID__c, Transit_Days__c
                                                              FROM Outlet_Split_Transit_Duration__c
                                                              WHERE Outlet_ID__r.KUNNR__c =:accId ];

        List<OrderSplit__c> orderSplit = [SELECT Id, Lead_Time_in_day__c 
                                          FROM OrderSplit__c 
                                          WHERE Sales_Area__r.Sales_Area_ID__c =:salesArea ];

        if(outletSplit != null && outletSplit.size()>0){                               
            return outletSplit[0].Transit_Days__c + orderSplit[0].Lead_Time_in_day__c;
        }else{
            return orderSplit[0].Lead_Time_in_day__c;
        }        
    }
    
    //Wrapper Classes
    public class GenericCartWrapper {
        @AuraEnabled public String cartId {get; set;}
        @AuraEnabled public String accountId {get; set;}
        @AuraEnabled public String webstoreId {get; set;}
        @AuraEnabled public Decimal maxOrderLineItems {get;set;}
        @AuraEnabled public Decimal maxWeight {get;set;}
        @AuraEnabled public Decimal maxPallets {get;set;}        
        @AuraEnabled public Decimal minWeight {get;set;}
        @AuraEnabled public Decimal minPallets {get;set;}
        @AuraEnabled public Boolean canViewPrice {get; set;} 
        
        @AuraEnabled public String shipToNumber {get;set;} 
        @AuraEnabled public String deliveryToAddress {get;set;} 

    }
	
	public class OrderConfigWrapper{
        @AuraEnabled public String customerName{get;set;}
		@AuraEnabled public String customerNumber{get;set;}
		@AuraEnabled public String salesOrg{get;set;}
        @AuraEnabled public String salesOrgCode{get;set;}
        @AuraEnabled public String distributionChannel{get;set;}
        @AuraEnabled public String division{get;set;}
	}

    public class UserTypeWrapper{
        @AuraEnabled public Boolean isAccessToFaultFixer{get;set;}
        @AuraEnabled public String faultFixerPageTitle{get;set;}
        @AuraEnabled public String contactUsNumber {get;set;}
        @AuraEnabled public String contactUsDescription {get;set;}
        @AuraEnabled public boolean isAccessTofaultFixerContactUs {get;set;}
    }
}