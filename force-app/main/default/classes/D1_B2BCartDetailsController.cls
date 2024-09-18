/**
 * @name : D1_B2BCartDetailsController
 * @description :This class implements the methods for cart details for DiageoOne
 * @history
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0       Ankit Garg       28/12/2020        NCP-1094
 * 2.0       Manikant         12/03/2021        NCP-2359
 * 3.0       Mukesh Kanth     25/03/21          NCP-2051 : Updated getDeliverTo method for multiple sold to   
 * 4.0       Sai Kumar,Dipanjan                 TechDev stories 
 * 5.0       Ajay             11/10/2021        NCP-3362
 * 6.0       Mukesh Kanth     04/12/2023        US-148646 -Added getPaymentTerm method
 **/
public without sharing class D1_B2BCartDetailsController {
    public static Id debugUserId;

    /**
     * @author Ankit
     * @date 28-12-2020
     * @userStory NCP-1094
     * @description Get Cart Details
     * @param  Cart Id
     * @return CartDetailWrapper 
     */
    @AuraEnabled(cacheable = false)
    public static CartDetailWrapper getCartDetails(string cartId) {
        CartDetailWrapper cartDetailWrapperObj = new CartDetailWrapper();
        set<Id> orderSplitIdSet = new set<Id>();
        try {
            //Create Cart Wrapper
            for(WebCart webCartObj: [SELECT Id, AccountId, Account.KUNNR__c, Account.Country__c, Account.D1_Is_Dummy_Account__c, Delivery_Instructions__c, Customer_Service_Instruction__c,
                                     Delivery_Address__c,Delivery_Address__r.Status__c, PoNumber, Split_2_PO_Number__c, Order_Split_1__c, Order_Split_2__c,Order_Split_1__r.SAP_OrderSplit_ID__c, 
                                     Split_1_Delivery_date__c, Split_2_Delivery_date__c, UniqueProductCount,TotalProductCount,Ship_To_Number__c,
                                    Total_Weight__c,Shipto_Party__c,CanViewPrice__c,
                                    Maximum_Limit_Reached__c,Total_Keg__c,currencyIsoCode,grandTotalAmount,
                                    Total_Pallets__c,Order_Split_1__r.Exempt_From_Weight_Validation__c,
                                    Order_Split_2__r.Exempt_From_Weight_Validation__c,TotalProductAmount,
                                    Order_Split_2__r.SAP_OrderSplit_ID__c, Order_Split_2__r.MOQ_Multiple__c,Total_Non_Keg_Quantity__c,
                                    Order_Split_1__r.MOQ_Multiple__c,Order_Split_1__r.isKeg__c,Order_Split_2__r.isKeg__c,Total_Keg_Price__c,Total_Non_Keg_Price__c,Payment_Term_Code__c,Payment_Term_Description__c //Added for US 148646
                                     FROM WebCart WHERE  Id =:cartId]) 
            {
                cartDetailWrapperObj.cartId = webCartObj.Id;
                cartDetailWrapperObj.accountId = webCartObj.AccountId;
                cartDetailWrapperObj.accountNumber = webCartObj.Account.KUNNR__c;
                cartDetailWrapperObj.accountMarket = webCartObj.Account.Country__c;
                cartDetailWrapperObj.isDummyAccount = webCartObj.Account.D1_Is_Dummy_Account__c;
                cartDetailWrapperObj.deliveryToAddress = webCartObj.Delivery_Address__c;
                cartDetailWrapperObj.deliveryStatus  = webCartObj.Delivery_Address__r.Status__c;
                cartDetailWrapperObj.deliveryInstructions = webCartObj.Delivery_Instructions__c;
                cartDetailWrapperObj.customerServiceInstructions = webCartObj.Customer_Service_Instruction__c;
                cartDetailWrapperObj.split1PONumber = webCartObj.PoNumber != NULL ? string.valueof(webCartObj.PoNumber) : '';
                cartDetailWrapperObj.split2PONumber = webCartObj.Split_2_PO_Number__c != NULL ? string.valueOf(webCartObj.Split_2_PO_Number__c) : '';
                cartDetailWrapperObj.split1OrderSplit = webCartObj.Order_Split_1__c != NULL ? string.valueOf(webCartObj.Order_Split_1__c) : null;
                cartDetailWrapperObj.split2OrderSplit = webCartObj.Order_Split_2__c != NULL ? string.valueOf(webCartObj.Order_Split_2__c) : null;
                cartDetailWrapperObj.split1DeliveryDate = webCartObj.Split_1_Delivery_date__c != NULL ? string.valueOf(webCartObj.Split_1_Delivery_date__c) : '';
                cartDetailWrapperObj.split2DeliveryDate = webCartObj.Split_2_Delivery_date__c != NULL ? string.valueOf(webCartObj.Split_2_Delivery_date__c) : '';
                cartDetailWrapperObj.totalProduct = webCartObj.TotalProductCount != NULL ? webCartObj.TotalProductCount : 0;
                cartDetailWrapperObj.shipToNumber = webCartObj.Ship_To_Number__c != NULL ? webCartObj.Ship_To_Number__c : null;
                cartDetailWrapperObj.splitId = webCartObj.Order_Split_1__r.SAP_OrderSplit_ID__c;
                
                cartDetailWrapperObj.canViewPrice =webCartObj.CanViewPrice__c;
                cartDetailWrapperObj.totalWeight = webCartObj.Total_Weight__c != Null ? Integer.valueOf(webCartObj.Total_Weight__c) : 0;
                cartDetailWrapperObj.totalkeg =webCartObj.Total_Keg__c != Null ?Integer.valueOf(webCartObj.Total_Keg__c) : 0;
                cartDetailWrapperObj.totalNonkeg =webCartObj.Total_Non_Keg_Quantity__c != Null ?Integer.valueOf(webCartObj.Total_Non_Keg_Quantity__c) : 0;
                
                cartDetailWrapperObj.totalPallets =webCartObj.Total_Pallets__c != Null ?webCartObj.Total_Pallets__c : 0;

                cartDetailWrapperObj.split1ExemptFromWeightValidation=webCartObj.Order_Split_1__r.Exempt_From_Weight_Validation__c;
                cartDetailWrapperObj.split2ExemptFromWeightValidation=webCartObj.Order_Split_2__r.Exempt_From_Weight_Validation__c;
                cartDetailWrapperObj.split2MOQMultiple = webCartObj.Order_Split_2__r.MOQ_Multiple__c != Null ? Integer.valueOf(webCartObj.Order_Split_2__r.MOQ_Multiple__c) : 0;
                cartDetailWrapperObj.split1MOQMultiple = webCartObj.Order_Split_1__r.MOQ_Multiple__c != Null ? Integer.valueOf(webCartObj.Order_Split_1__r.MOQ_Multiple__c) : 0; 
                cartDetailWrapperObj.splitId2 =  webCartObj.Order_Split_2__r.SAP_OrderSplit_ID__c;
                cartDetailWrapperObj.uniqueProductCount= webCartObj.UniqueProductCount != Null ? webCartObj.UniqueProductCount : 0;
                cartDetailWrapperObj.grandTotalAmount = webCartObj.grandTotalAmount != NULL ? webCartObj.grandTotalAmount :0;
                cartDetailWrapperObj.currencyIsoCode = webCartObj.currencyIsoCode;
                cartDetailWrapperObj.split1isKeg =webCartObj.Order_Split_1__r.isKeg__c ;
                cartDetailWrapperObj.split2isKeg =webCartObj.Order_Split_2__r.isKeg__c ;
                cartDetailWrapperObj.totalKegPrice = webCartObj.Total_Keg_Price__c;
                cartDetailWrapperObj.totalNonKegPrice = webCartObj.Total_Non_Keg_Price__c;
                cartDetailWrapperObj.totalProductAmount = webCartObj.TotalProductAmount;
                cartDetailWrapperObj.paymentTermCode = webCartObj.Payment_Term_Code__c;//Added for US 148646
                cartDetailWrapperObj.paymentTermDescription = webCartObj.Payment_Term_Description__c;//Added for US 148646
               
                if(webCartObj.Order_Split_1__c != null){
                    orderSplitIdSet.add(webCartObj.Order_Split_1__c);
                }
                if(webCartObj.Order_Split_2__c != null){
                    orderSplitIdSet.add(webCartObj.Order_Split_2__c);
                }
                   
            }
            
            //Get Order Split Data
            if(!orderSplitIdSet.isEmpty()){
                for(OrderSplit__c orderSplit : [SELECT Id, Description__c, Market_Description__c, Cut_Off_Time__c FROm OrderSplit__c WHERE Id IN :orderSplitIdSet]){
                    if(orderSplit.Id == cartDetailWrapperObj.split1OrderSplit){
                        cartDetailWrapperObj.split1OrderSplitName = orderSplit.Market_Description__c != null ? orderSplit.Market_Description__c : orderSplit.Description__c;
                        cartDetailWrapperObj.split1CutOffTime = createCutOffTime(orderSplit.Cut_Off_Time__c);
                    }else if(orderSplit.Id == cartDetailWrapperObj.split2OrderSplit){
                        cartDetailWrapperObj.split2OrderSplitName = orderSplit.Market_Description__c != null ? orderSplit.Market_Description__c : orderSplit.Description__c;
                        cartDetailWrapperObj.split2CutOffTime = createCutOffTime(orderSplit.Cut_Off_Time__c);
                    }
                }
            }
        } catch (Exception ex) {
            throw ex;
        }
        return cartDetailWrapperObj;
    }
    
    /**
     * @description : Method to convert CutOffTime into DateTime
     * @param  cTime Time
     */
    public static DateTime createCutOffTime(Time cTime){
        Time cutOffTime = cTime != null ? cTime : Time.newInstance(0, 0, 0, 0);
        DateTime cutOffDateTime = DateTime.newInstanceGmt(Date.today(), cutOffTime);
        return cutOffDateTime;
    }

    /**
     * @author Sai Kumar
     * @date 28-12-2020
     * @userStory NCP-1193
     * @description Get Deliver Address Details from ContactPointAddress
     * @param  - NA
     * @return List of ContactPointAddress  
     */
    @AuraEnabled(cacheable = true)
    public static List < ContactPointAddress > getDeliverTo() {
        List < ContactPointAddress > contactPointAddressList = new List < ContactPointAddress > ();
        //NCP-2051 Change: added condition of effectiveaccountid for multiple sold to
        try {
            User usr = [SELECT Id, ContactId, AccountId, Effective_Account_Id__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            if (usr.Effective_Account_Id__c != null) {
                for (ContactPointAddress address: [SELECT Id, Name, Name2__c, Street, State, City, Country, PostalCode,
                                                   StateCode, CountryCode, Account_Number__c,Customer_status_Display__c FROM ContactPointAddress 
                                                   WHERE ParentId =: usr.Effective_Account_Id__c AND AddressType = 'Shipping'
                                                   ORDER BY createddate asc]) 
                {
                    contactPointAddressList.add(address);
                }
            }
        } catch (Exception ex) {
            throw ex;
        }
        return contactPointAddressList;
    }
    /**
     * @author Sai Kumar
     * @date 28-12-2020
     * @userStory NCP-1193
     * @description Get Deliver Address Details from ContactPointAddress
     * @param  selecteddeliverytoId Selected Shipto from Cart object
     * @return List of ContactPointAddress  
     */
    @AuraEnabled(cacheable = true)
    public static List < ContactPointAddress > getDeliverTodetails(String selecteddeliverytoId) {
        List < ContactPointAddress > contactPointAddressList = new List < ContactPointAddress > ();
        //NCP-2051 Change: added condition of effectiveaccountid for multiple sold to
        try {
            User usr = [SELECT Id, ContactId, AccountId, Effective_Account_Id__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            String accountId=usr.Effective_Account_Id__c;
            String shippinglabel='Shipping';
                
            if (accountId != null) {
              
                 String queryStr ='SELECT Id, Name, Name2__c, Street, State, City, Country, PostalCode,StateCode, CountryCode, Account_Number__c,Customer_status_Display__c,Status__c FROM ContactPointAddress WHERE  ParentId =:accountId  AND AddressType =: shippinglabel';
                 if(selecteddeliverytoId !=null){
                    queryStr += ' AND Id=:selecteddeliverytoId';
                }
                queryStr += ' ORDER BY Status__c,Name asc';
                for (ContactPointAddress address: Database.Query(queryStr)) 
                {
                    contactPointAddressList.add(address);
                }
            }
        } catch (Exception ex) {
            throw ex;
        }
       
        return contactPointAddressList;
    }
    
    /**
     * @author Sai Kumar
     * @date 28-12-2020
     * @userStory NCP-1193
     * @description Update Deliver Address selected on WebCart
     * @param  - Cart Id , Selcetd ContactPointAddress Id
     * @return WebCart 
     */
    @AuraEnabled
    public static WebCart updateDeliveryAddress(string cartId, string deliverytoaddressId) {
        try {
            List < WebCart > webCartlistUpdate = new List < WebCart > ();
            if (deliverytoaddressId != null && cartId != null) {
                for (WebCart webCartObj: [SELECT Delivery_Address__c FROM WebCart where Status = 'Active'
                        and Id =: cartId
                    ]) {
                    if (webCartObj.Delivery_Address__c != deliverytoaddressId) {
                        webCartObj.Delivery_Address__c = deliverytoaddressId;
                        webCartlistUpdate.add(webCartObj);
                    }
                }
            }

            if (webCartlistUpdate.size() > 0) {
                update webCartlistUpdate;
                return webCartlistUpdate[0];
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            //return ex.getMessage();
        }
        return null;
    }

    /**
     * @author Ankit
     * @date 28-12-2020
     * @userStory NCP-1094
     * @description Save Cart Details
     * @param  string
     * @return string 
     */
    @AuraEnabled
    public static string callSaveCart(string cartDetail) {
        try {
            CartDetailWrapper cartWrapperObj = (CartDetailWrapper) JSON.deserializeStrict(cartDetail, CartDetailWrapper.class);
            WebCart webCartObjToUpd = new WebCart(Id = cartWrapperObj.cartId);
            webCartObjToUpd.Delivery_Instructions__c = cartWrapperObj.deliveryInstructions;
            webCartObjToUpd.Customer_Service_Instruction__c = cartWrapperObj.customerServiceInstructions;
            webCartObjToUpd.PoNumber = cartWrapperObj.split1PONumber;
            webCartObjToUpd.Split_2_PO_Number__c = cartWrapperObj.split2PONumber;
            update webCartObjToUpd;
        } catch (Exception ex) {
            return ex.getMessage();
        }
        return NULL;
    }
    /**
     * @description Save Cart Details
     * @param  cartId Cart Id
     * @param  deliveryDate selected Delivery Date
     * @param  orderSplitId Selected Delivery Date Split Id
     * @return string 
     */
    @AuraEnabled
    public static string upDateOrderSplit(id cartId,date deliveryDate,String orderSplitId) {
        try {
            List<WebCart> webCartObj =[SELECT Id, Order_Split_1__c, Order_Split_2__c,Split_1_Delivery_date__c,
                                    Split_2_Delivery_date__c FROM WebCart WHERE Status = 'Active'
                                     AND Id =:cartId];
            if(webCartObj.size()>0){
                if(webCartObj[0].Order_Split_1__c ==orderSplitId ){
                    webCartObj[0].Split_1_Delivery_date__c=deliveryDate;
                }
                else if(webCartObj[0].Order_Split_2__c ==orderSplitId){
                    webCartObj[0].Split_2_Delivery_date__c=deliveryDate;
                }
            }
            update webCartObj;
           
        }
         catch (Exception ex) {
            return ex.getMessage();
        }
        return NULL;
    }

    
    /**
     * @description : Newly added method for Cart Update
     * @param  cart Cart object
     */
    @AuraEnabled
    public static WebCart updateCartDetails(WebCart cart){
        try {
            if(cart != null){
                update cart;
                return cart;
                //return getCartDetails(cart.Id);
            }else{
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @author Ankit
     * @date 28-12-2020
     * @userStory NCP-1094
     * @description Cart Details Wrapper class
     */
    public class CartDetailWrapper {
        @AuraEnabled public String cartId {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public String accountNumber {get;set;}
        @AuraEnabled public String accountMarket {get;set;}
        @AuraEnabled public Boolean isDummyAccount {get;set;}
        @AuraEnabled public String deliveryToAddress {get;set;}
        @AuraEnabled public String deliveryStatus {get;set;}
        @AuraEnabled public String deliveryInstructions {get;set;}
        @AuraEnabled public String customerServiceInstructions {get;set;}
        @AuraEnabled public String split1PONumber {get;set;}
        @AuraEnabled public String split2PONumber {get;set;}
        @AuraEnabled public String split1OrderSplit {get;set;}
        @AuraEnabled public String split2OrderSplit {get;set;}
        @AuraEnabled public String split1OrderSplitName {get;set;}
        @AuraEnabled public String split2OrderSplitName {get;set;}
        @AuraEnabled public String split1DeliveryDate {get;set;}
        @AuraEnabled public String split2DeliveryDate {get;set;}
        @AuraEnabled public DateTime split1CutOffTime {get;set;}
        @AuraEnabled public DateTime split2CutOffTime {get;set;}
        @AuraEnabled public Decimal totalProduct {get;set;}
        @AuraEnabled public Boolean isMaximumReached {get;set;}
        @AuraEnabled public Integer maxProdAllowed {get;set;}
        @AuraEnabled public String shipToNumber {get;set;}
        @AuraEnabled public String splitId {get;set;}


        @AuraEnabled public Integer totalWeight {get;set;} 
        @AuraEnabled public Boolean canViewPrice {get; set;} 
        @AuraEnabled public Boolean maxLimitReached {get;set;}
        @AuraEnabled public Integer totalkeg {get;set;}
        @AuraEnabled public Integer totalNonkeg {get;set;}
        @AuraEnabled public Decimal totalPallets {get;set;}
        @AuraEnabled public Boolean split1ExemptFromWeightValidation {get;set;} 
        @AuraEnabled public Boolean split2ExemptFromWeightValidation {get;set;} 
        @AuraEnabled public String split2SAPOrderSplitID {get;set;} 
        @AuraEnabled public Integer split1MOQMultiple {get;set;} 
        @AuraEnabled public Integer split2MOQMultiple {get;set;}
        @AuraEnabled public String splitId2 {get;set;} 
        @AuraEnabled public Integer uniqueProductCount {get;set;}
        @AuraEnabled public Decimal grandTotalAmount {get;set;}
        @AuraEnabled public String currencyIsoCode {get;set;}
        @AuraEnabled public Boolean split1isKeg {get;set;}
        @AuraEnabled public Boolean split2isKeg {get;set;}
        @AuraEnabled public Decimal totalKegPrice {get;set;}
        @AuraEnabled public Decimal totalNonKegPrice {get;set;}
        @AuraEnabled public Decimal totalProductAmount {get;set;}
        @AuraEnabled public String paymentTermCode {get;set;}//Added for US 148646
        @AuraEnabled public String paymentTermDescription {get;set;}//Added for US 148646
         
        CartDetailWrapper() {
            cartId = '';
            accountId = '';
            accountNumber = '';
            accountMarket = '';
            isDummyAccount = false;
            deliveryToAddress = '';
            deliveryStatus='';
            deliveryInstructions = '';
            customerServiceInstructions = '';
            split1PONumber = '';
            split2PONumber = '';
            split1OrderSplit = null;
            split2OrderSplit = null;
            split1OrderSplitName = '';
            split2OrderSplitName = '';
            split1DeliveryDate = '';
            split2DeliveryDate = '';
            totalProduct = 0;
            splitId = '';
            split1isKeg=false;
            split2isKeg=false;
            paymentTermCode='';//Added for US 148646
            paymentTermDescription='';//Added for US 148646
        }
    }
    /**
     * @userstory NCP-2359
     * @description Method to reset cart delivery dates value , irrespective of prior values 
     * @param cartId 
     * @return  `String`
     */    
    @AuraEnabled
    public static String upDateDelvryDates(id cartId) {
        List<WebCart> webCartObj = new  List<WebCart>();
        try {
             webCartObj =[SELECT Id,Split_1_Delivery_date__c,
                                    Split_2_Delivery_date__c FROM WebCart WHERE Status = 'Active'
                                     AND Id =:cartId];
            if(webCartObj.size()>0){
                    webCartObj[0].Split_1_Delivery_date__c = null; 
                    webCartObj[0].Split_2_Delivery_date__c = null;                
            }
            update webCartObj;
        }
         catch (Exception ex) {
            return ex.getMessage();
        }
        return null;
    }

    /**
     * @description checkUserCanOrderToday 
     * @userStory NCP-3362
     * @author Ajay
     * @return   error message if user cant order today
     */
    @AuraEnabled
    public static Integer getNoOfOrdersToday(){

        //Get user configurations effectiveAccountId, orderLimitsPerDay & orderLimitsPerDayErrorMessage
        User currentUser = [SELECT  Effective_Account_Id__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];

        //Query to get Order of Today order
        List<AggregateResult> orderInfos = [ SELECT COUNT(Id)noOfOrders
                                             FROM Order
                                             WHERE AccountId = :currentUser.Effective_Account_Id__c
                                             AND DAY_ONLY(convertTimezone(CreatedDate)) =: Date.today() ];        

        //No order => No order restriction
        if(orderInfos.isEmpty()){
            return null;
        }

        return Integer.valueOf(orderInfos[0].get('noOfOrders'));
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,String> getPaymentTerm(Id accountId){      //Added for US 148646
        /* Commented PaymentTerm Authorization as per Brazil Market confirmation -- SANDEEP BH*/
        //Get the name and Payment Term code of Payment Term object which is parent object of Customer Payment Term
        Date currentDate = System.today();
        Map<String,String> paymentTermOptions = new Map<String,String>();
        List<Customer_Payment_Term__c> custPaymentTerms = [SELECT Payment_Term__r.Name,Payment_Term__r.Payment_Term_Code__c FROM Customer_Payment_Term__c WHERE Account__c=:accountId AND Start_Date__c<=:currentDate AND End_Date__c>=:currentDate AND Payment_Term__r.Inactive__c = false ORDER BY Payment_Term__r.Name];
        //List<Payment_Term_Authorization__c> custPaymentTermAuths = [SELECT Payment_Term__r.Name,Payment_Term__r.Payment_Term_Code__c FROM Payment_Term_Authorization__c WHERE Start_Date__c<=:currentDate AND End_Date__c>=:currentDate AND Payment_Term__r.Inactive__c = false ORDER BY Payment_Term__r.Name];
        if(custPaymentTerms!=null && custPaymentTerms.size() > 0){
            for(Customer_Payment_Term__c custPaymentTerm :custPaymentTerms){
                paymentTermOptions.put(custPaymentTerm.Payment_Term__r.Payment_Term_Code__c,custPaymentTerm.Payment_Term__r.Name);
            }
        }
        
        /*if(custPaymentTermAuths!=null && custPaymentTermAuths.size() > 0){
            for(Payment_Term_Authorization__c custPaymentTermAuth :custPaymentTermAuths){
                if(!paymentTermOptions.containsKey(custPaymentTermAuth.Payment_Term__r.Payment_Term_Code__c)){
                    paymentTermOptions.put(custPaymentTermAuth.Payment_Term__r.Payment_Term_Code__c,custPaymentTermAuth.Payment_Term__r.Name);
                }
            }
        }*/
        
        return paymentTermOptions;
    } 

}
/**
 * DEbug helper
  D1_B2BCartDetailsController.debugUserId = '0057Z000007rscdQAA';
  System.debug(
     D1_B2BCartDetailsController.getErrorIfUserCantOrderToday()
  );
 */