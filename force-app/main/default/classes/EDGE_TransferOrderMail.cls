/*
* @Description: EDGE_TransferOrderMail

* @Purpose: Controller for vf page - EDGE_TransferOrderPDFMail

* @History:                                                            
                                                           
* @VERSION   AUTHOR            DATE              DETAIL
*    1.0     Monalisa Halder     17/06/2021       ES20-9974 
*    2.0     Manikant Prasad     17/06/2021       ES20-9976
*    3.0     Debolina/Mayukh     09/05/2022       ES20-12543
*	 4.0     Rajarshi Lahiri	 10/05/2022	      ES20-12641
*    5.0	 Rajarshi Lahiri     13/05/2022		  ES20-12728
*	 6.0	 Rajarshi Lahiri     18/05/2022		  ES20-12785
*    7.0     Rajarshi Lahiri     30/05/2022		  ES20-12875
*	 8.0	 Rajarshi Lahiri	 17/08/2022		  ES20-13154
*	 9.0	 Rajarshi/Swaraj     13/09/2022		  ES20-10234
*   10.0     Mayukh S Roy        27/06/2023       291561
**/

public class EDGE_TransferOrderMail{
    
    public static EDGE_TransferOrderMailWrapper.headerWrapper headervalue {get;set;}
    public static List<EDGE_TransferOrderMailWrapper.orderDetailsWrapper> wholeOrder {get;set;}
    public static String language {get;set;}
    
    public EDGE_TransferOrderMail(){
        EDGE_TransferOrderMailWrapper transferOrderData =  new EDGE_TransferOrderMailWrapper();
        Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
        Set<Id> orderIdSet = (Set<id>)System.JSON.deserialize(reqParams.get('orderListSTR'), Set<Id>.class); 
        Boolean isBatch = (Boolean)System.JSON.deserialize(reqParams.get('isBatch'), Boolean.class);
        language = (String)System.JSON.deserialize(reqParams.get('language'), String.class);
       
        if(orderIdSet != null && orderIdSet.size()>0){
        	EDGE_TransferOrderStatusHelper.setOrderDetails(orderIdSet,isBatch,language);
        	transferOrderData = getTransferOrderDetails(EDGE_TransferOrderStatusHelper.wholeOrderList,EDGE_TransferOrderStatusHelper.orderListOrderItemMap,EDGE_TransferOrderStatusHelper.languageName,EDGE_TransferOrderStatusHelper.labelToTranslatedStrMap,EDGE_TransferOrderStatusHelper.mapOrderShedAccount , isBatch);       
        	headervalue = transferOrderData.headerWrapperValue;
            wholeOrder = transferOrderData.orderDetailsWrapperValue;
        }
        //languageName = language;
       
    }
    
    public static EDGE_TransferOrderMailWrapper getTransferOrderDetails(List<Order__c> orderList, Map<String,List<Order_Item__c>> orderListOrderItemMap, String languageName, Map<String, String> labelToTranslatedStrMap, Map<Id, Account> mapOrderShedAccount,Boolean isBatch){
        String todayDate = date.today().format();
        //Create a Map depending on Account
        Map<String, List<Order__c>> mapAccountOrder = new Map<String, List<Order__c>>();
        Map<String, String> mapAccountName = new Map<String, String>();
        //Map<String, Account> mapAccount = new Map<String, Account>();
        String freeGoodOrderRTId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        String trnsferOrderRTId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        Map<Id,Market_Setting__c> countryMarketMap = new Map<Id,Market_Setting__c>();
        Set<Id> countryIdSet = new Set<Id>();
        Set<Id> orderIdSet = new Set<Id>();
        Map<Id,Order__c> orderIdToOrderMap = new Map<Id,Order__c>();
        EDGE_TransferOrderMailWrapper transferOrderWrapper = new EDGE_TransferOrderMailWrapper();
        
        EDGE_TransferOrderMailWrapper.headerWrapper headervalue = new EDGE_TransferOrderMailWrapper.headerWrapper();
        EDGE_TransferOrderMailWrapper.orderDetailsWrapper wholeOrder ;//= new EDGE_TransferOrderMailWrapper.orderDetailsWrapper();
        //wholeOrder.orderList = new List<EDGE_TransferOrderMailWrapper.orderObj >();
        List<EDGE_TransferOrderMailWrapper.orderDetailsWrapper> wholeOrderList = new List<EDGE_TransferOrderMailWrapper.orderDetailsWrapper>() ;
        String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();// for different orgs 
        //String imageUrl = '';
        
        String freeProductRecordType = Promotion_Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        //open table and prepare the header for batch..
        
        if(languageName != null && isBatch != null && isBatch){//Batch code
            System.debug(LoggingLevel.Debug,'languageName '+languageName);
            headervalue.TableBody = labelToTranslatedStrMap.get('EDGE_EmailBody')+' ' + todayDate ;
        }
        else{ //Trigger code
            headervalue.TableBody = Label.EDGE_EmailBody+' ' + todayDate ;
        }
        
        if(orderList!=null && orderList.size()>0){
            
            //Create Map of Order Account Wise
            for(Order__c ordObj : orderList){
                system.debug(LoggingLevel.Debug,'@@ordObjid ' +ordObj.id);
                mapAccountName.put(ordObj.Account__c, ordObj.Account__r.name);
                if(mapAccountOrder.containsKey(ordObj.Account__c)){
                    mapAccountOrder.get(ordObj.Account__c).add(ordObj);                                        
                } else {
                    mapAccountOrder.put(ordObj.Account__c, new List<Order__c> {ordObj});                    
                }
                //ES20-9289
                countryIdSet.add(ordObj.Account__r.Country__c);
                orderIdSet.add(ordObj.Id);
            }
            if (Test.isRunningTest()){
                for(Order__c ord : [Select Account__c, Account__r.Country__c from Order__c where Id in :orderIdSet]){
                    countryIdSet.add(ord.Account__r.Country__c);
                }
            }
            //ES20-9289
            for(Order__c orderRec : [Select Account__c, Account__r.Country__c,Sales_Representative__r.Name, Sales_Representative__r.Mobile_Number__c,
                                     Sales_Representative__r.Email,Name,Comments__c,Source_Application__c,Is_Promo_Transfer_Order__c  from Order__c 
                                     where Id in :orderIdSet]){
                                         orderIdToOrderMap.put(orderRec.Id, orderRec);
                                     }
            
            //ES20-9289
            if(countryIdSet.size() > 0){
                for(Market_Setting__c marketSetting : [Select Geography__c,Display_Transfer_Order_Comments__c from Market_Setting__c where Geography__c in :countryIdSet WITH SECURITY_ENFORCED]){
                    if(!countryMarketMap.containsKey(marketSetting.Geography__c)){
                        countryMarketMap.put(marketSetting.Geography__c,marketSetting);
                    }
                }                
            }
            
            for(String accountId : mapAccountOrder.keySet()){
                wholeOrder = new EDGE_TransferOrderMailWrapper.orderDetailsWrapper();
                List<Order__c> lstOrder = mapAccountOrder.get(accountId);
                if(languageName != null && isBatch){
                    headervalue.accountName = labelToTranslatedStrMap.get('EDGE_AccountName');
                    wholeOrder.accountName =  mapAccountName.get(accountId);
                   // headervalue.showWholesaler = True;
                } else{
                    headervalue.accountName = Label.EDGE_AccountName;
                    wholeOrder.accountName =  mapAccountName.get(accountId);
                }
                //Create the Order and Line Item section
                if(lstOrder != null && lstOrder.size()>0){
                    wholeOrder.orderList = new List<EDGE_TransferOrderMailWrapper.orderObj>();
                    for(Order__c ordObj : lstOrder){
                        if(orderListOrderItemMap.size()>0 && orderListOrderItemMap.containsKey(ordObj.Id)){
                            
                            EDGE_TransferOrderMailWrapper.orderObj individualOrder =  new EDGE_TransferOrderMailWrapper.orderObj();
                            List<Order_Item__c> ordItemQuantity = orderListOrderItemMap.get(ordObj.Id);
                            //ES20-13154
                            individualOrder.isPromoOrder=ordObj.Is_Promo_Transfer_Order__c;//ES20-10234
                            if(languageName != null && isBatch){//Batch code - start                                
                                individualOrder.isOrderItemPresent=False;
                                //This If else is used to show the Header whether the Order is Transfer Order or Free Good Order
                                if(ordObj.RecordTypeId == freeGoodOrderRTId){
                                    headervalue.recordType = labelToTranslatedStrMap.get('EDGE_FreeProducts');
                                } else {
                                    headervalue.recordType = labelToTranslatedStrMap.get('EDGE_OrderedProducts');
                                }
                                
                                // Image part added by Manikant >> Starts
                                if(ordObj.Source_Application__c =='EDGE 365' && ordObj.Signature_Image_Version_Id__c != null ){
                                    individualOrder.showImageSection = True;
                                    individualOrder.showText = false;
                                    individualOrder.showImage = True;  
                                    individualOrder.imageValue = baseUrl+'/sfc/servlet.shepherd/version/download/' +ordObj.Signature_Image_Version_Id__c + '?asPdf=false&operationContext=CHATTER';   
                                }
                                if(ordObj.Source_Application__c == 'Diageo One'){
                                    individualOrder.imageValue =  labelToTranslatedStrMap.get('EDGE_OrderSignature');
                                    individualOrder.showText = True;
                                    individualOrder.showImage = False; 
                                }

                                // Image part added by Manikant >> Ends
                                //This If else is used to show the Account addres based on Delivery location of Free Good Order
                                if(ordObj.RecordTypeId == freeGoodOrderRTId && ordObj.Delivery_Location__c == 'Shed' && mapOrderShedAccount.containsKey(ordObj.Sales_Representative__c)){
                                    Account account = mapOrderShedAccount.get(ordObj.Sales_Representative__c);
                                    individualOrder.accountAddress = ((account.BillingStreet)!=null ? account.BillingStreet:'') + ',' + ((account.BillingState)!=null ? account.BillingState:'') + ',' + ((account.BillingCity)!=null ? account.BillingCity:'') + ',' + ((account.Country__r.name)!=null ? account.Country__r.name:'') + '-' + ((account.BillingPostalCode)!=null ? account.BillingPostalCode:'');
                                    headervalue.accountAddress = labelToTranslatedStrMap.get('EDGE_AccountAdress');                             
                                } else {
                                    headervalue.accountAddress = labelToTranslatedStrMap.get('EDGE_AccountAdress');  
                                    individualOrder.accountAddress = ((ordObj.Account__r.BillingStreet)!=null ? ordObj.Account__r.BillingStreet:'') + ',' + ((ordObj.Account__r.BillingState)!=null ? ordObj.Account__r.BillingState:'') + ',' + ((ordObj.Account__r.BillingCity)!=null ? ordObj.Account__r.BillingCity:'') + ',' + ((ordObj.Account__r.Country__r.name)!=null ? ordObj.Account__r.Country__r.name:'') + '-' + ((ordObj.Account__r.BillingPostalCode)!=null ? ordObj.Account__r.BillingPostalCode:'');
                                }
                                
                                //This If else is used to change the label of Preferred delivery date
                                if(ordObj.Next_Delivery_Date__c){
                                    headervalue.PreferredOrderDate = labelToTranslatedStrMap.get('EDGE_NextDeliveryDate');
                                    individualOrder.OrderedDate = ((ordObj.Preferred_Delivery_Date__c)!=null ? ordObj.Preferred_Delivery_Date__c.format():'');
                                } else {
                                    headervalue.PreferredOrderDate = labelToTranslatedStrMap.get('EDGE_PrefOderDate');
                                    individualOrder.OrderedDate  = ((ordObj.Preferred_Delivery_Date__c)!=null ? ordObj.Preferred_Delivery_Date__c.format():'');
                                }
                                //ES20-9289
                                if(ordObj.Source_Application__c == 'Diageo One'){
                                    headervalue.salesRepName = labelToTranslatedStrMap.get('D1_Customer_Contact_Name'); 
                                    individualOrder.salesRepName = ((ordObj.Sales_Representative__r.Name!=null) ? ordObj.Sales_Representative__r.Name:'');
                                }else{
                                    headervalue.salesRepName = labelToTranslatedStrMap.get('EDGE_Sales_Rep_Name'); 
                                    individualOrder.salesRepName = ((ordObj.Sales_Representative__r.Name!=null) ? ordObj.Sales_Representative__r.Name:'');
                                }
                                //Added for including Wholesaler Name for Transfer Orders - ES20-12543 
                                //Added record type check for Free Goods as part of ES20-12785
                                //Removed Free Goods record type check for ES20-12875
                                if(ordObj.RecordTypeId == trnsferOrderRTId){
                                    headervalue.wholesalerName = labelToTranslatedStrMap.get('EDGE_WholesalerName');
                                    individualOrder.wholesalerName = ((ordObj.Wholesaler__r.Name!=null) ? ordObj.Wholesaler__r.Name:'');
                                     headervalue.wholesalerAccountNumber = Label.EDGE_WholesaleAccNumb;
                                    individualOrder.WholesalerAccountNumber =  ((ordObj.Wholesaler_Account_Number__c)!=null ? ordObj.Wholesaler_Account_Number__c:'');

                                    headervalue.showWholesaler = True; 
                                }
                                if(ordObj.Source_Application__c == 'Diageo One'){
                                    headervalue.mobileNumber = labelToTranslatedStrMap.get('EDGE_MobileNumber');
                                    individualOrder.MobileNumber = ((ordObj.Contact__r.MobilePrefix__c)!=null ? ordObj.Contact__r.MobilePrefix__c:'') + ((ordObj.Contact__r.Mobile__c)!=null ? ordObj.Contact__r.Mobile__c:'');
                                }else{
                                    headervalue.mobileNumber = labelToTranslatedStrMap.get('EDGE_MobileNumber');
                                    individualOrder.MobileNumber = ((ordObj.Sales_Representative__r.Mobile_Number__c)!=null ? ordObj.Sales_Representative__r.Mobile_Number__c:'');
                                }
                                if(ordObj.Source_Application__c == 'Diageo One'){
                                    headervalue.email = labelToTranslatedStrMap.get('EDGE_Email');
                                    individualOrder.Email = ((ordObj.Contact__r.Email)!=null ? ordObj.Contact__r.Email:'');
                                }else{
                                    headervalue.email = labelToTranslatedStrMap.get('EDGE_Email');
                                    individualOrder.Email = ((ordObj.Sales_Representative__r.Email)!=null ? ordObj.Sales_Representative__r.Email:'');
                                }
                                headervalue.orderNumber =  labelToTranslatedStrMap.get('EDGE_Order_Number');
                                individualOrder.OrderNumber =  +((ordObj.Name)!=null ? ordObj.Name:'');
                                if(ordObj != null && ordObj.Account__r.Country__c !=null && countryMarketMap != null && countryMarketMap.get(ordObj.Account__r.Country__c).Display_Transfer_Order_Comments__c && ordObj.Comments__c !=null){
                                    headervalue.overallComment = labelToTranslatedStrMap.get('EDGE_OverallComment');
                                    headerValue.showComment = True;
                                    individualOrder.OverAllComment = ((ordObj.Comments__c)!=null ? ordObj.Comments__c:'');
                                }
                                //section - Order Items header
                                headervalue.prodName = labelToTranslatedStrMap.get('EGDE_ProductName');
                                headervalue.productSKUID = labelToTranslatedStrMap.get('EDGE_ProductSKUId');//Added as part of ES20-12728
                                headervalue.prodQuant =labelToTranslatedStrMap.get('EDGE_ProductQuantity');
                                headervalue.UOM = labelToTranslatedStrMap.get('EDGE_UOM');
                                //ES20-13154
                                if(ordObj.Is_Promo_Transfer_Order__c){// If the TO is of PTO type
                                    headervalue.promotionName=labelToTranslatedStrMap.get('EDGE_Promotion_Name');
                                    headervalue.promotionType=labelToTranslatedStrMap.get('EDGE_Promotion_Type');
                                    headervalue.discountForPromotion=labelToTranslatedStrMap.get('EDGE_Discount_for_Promotion');
                                    headervalue.freeProdforPromo=labelToTranslatedStrMap.get('EDGE_FreeProductsYesNo');
                                }
                               
                            } else {//Trigger code - start
                                //This If else is used to show the Header whether the Order is Transfer Order or Free Good Order
                               if(ordObj.RecordTypeId == freeGoodOrderRTId){
                                    headervalue.recordType = Label.EDGE_FreeProducts;
                                } else {
                                    headervalue.recordType =  Label.EDGE_OrderedProducts;
                                }
                                
                                //This If else is used to show the Account addres based on Delivery location of Free Good Order
                                if(ordObj.RecordTypeId == freeGoodOrderRTId && ordObj.Delivery_Location__c == 'Shed' && mapOrderShedAccount.containsKey(ordObj.Sales_Representative__c)){
                                    Account account = mapOrderShedAccount.get(ordObj.Sales_Representative__c);
                                    individualOrder.accountAddress = ((account.BillingStreet)!=null ? account.BillingStreet:'') + ',' + ((account.BillingState)!=null ? account.BillingState:'') + ',' + ((account.BillingCity)!=null ? account.BillingCity:'') + ',' + ((account.Country__r.name)!=null ? account.Country__r.name:'') + '-' + ((account.BillingPostalCode)!=null ? account.BillingPostalCode:'');
                                    headervalue.accountAddress = Label.EDGE_AccountAdress; 
                                } else {
                                    headervalue.accountAddress = Label.EDGE_AccountAdress;  
                                    individualOrder.accountAddress = ((ordObj.Account__r.BillingStreet)!=null ? ordObj.Account__r.BillingStreet:'') + ',' + ((ordObj.Account__r.BillingState)!=null ? ordObj.Account__r.BillingState:'') + ',' + ((ordObj.Account__r.BillingCity)!=null ? ordObj.Account__r.BillingCity:'') + ',' + ((ordObj.Account__r.Country__r.name)!=null ? ordObj.Account__r.Country__r.name:'') + '-' + ((ordObj.Account__r.BillingPostalCode)!=null ? ordObj.Account__r.BillingPostalCode:'');
                                    
                                }
                                // This part is for signaturre 
                                if(ordObj.Source_Application__c =='EDGE 365' && ordObj.Signature_Image_Version_Id__c != null ){
                                    individualOrder.showImageSection = True;
                                    individualOrder.showText = false;
                                    individualOrder.showImage = True;  
                                    individualOrder.imageValue = baseUrl+'/sfc/servlet.shepherd/version/download/' +ordObj.Signature_Image_Version_Id__c + '?asPdf=false&operationContext=CHATTER';   
                                }
                                
                                if(ordObj.Source_Application__c =='Diageo One'){
                                    individualOrder.imageValue = Label.EDGE_OrderSignature;
                                    individualOrder.showText = True;
                                    individualOrder.showImage = False; 
                                }
                                
                                //This If else is used to change the label of Preferred delivery date
                                if(ordObj.Next_Delivery_Date__c){
                                    headervalue.PreferredOrderDate = Label.EDGE_NextDeliveryDate;
                                    individualOrder.OrderedDate = ((ordObj.Preferred_Delivery_Date__c)!=null ? ordObj.Preferred_Delivery_Date__c.format():'');
                                    
                                } else{
                                    headervalue.PreferredOrderDate = Label.EDGE_PrefOderDate;
                                    individualOrder.OrderedDate  = ((ordObj.Preferred_Delivery_Date__c)!=null ? ordObj.Preferred_Delivery_Date__c.format():'');
                                }
                                //added by manikant for ES20-8150
                                //Added record type check for Free Goods as part of ES20-12785
                                //Removed Free Goods record type check for ES20-12875
                                if(ordObj.RecordTypeId == trnsferOrderRTId){
                                    headervalue.showWholesaler = True; 
                                    headervalue.wholesalerName  = Label.EDGE_WholesalerName;
                                    headervalue.wholesalerAccountNumber = Label.EDGE_WholesaleAccNumb;
                                    individualOrder.wholesalerName = ((ordObj.Wholesaler__r.Name)!=null ? ordObj.Wholesaler__r.Name:'');
                                    individualOrder.WholesalerAccountNumber =  ((ordObj.Wholesaler_Account_Number__c)!=null ? ordObj.Wholesaler_Account_Number__c:'');
                                }
                                
                                
                                if(ordObj.Source_Application__c == 'Diageo One'){
                                    headervalue.salesRepName = label.D1_Customer_Contact_Name; 
                                    individualOrder.salesRepName = ((ordObj.Sales_Representative__r.Name!=null) ? ordObj.Sales_Representative__r.Name:'');
                                }else{
                                    headervalue.salesRepName = label.EDGE_Sales_Rep_Name; 
                                    individualOrder.salesRepName = ((ordObj.Sales_Representative__r.Name!=null) ? ordObj.Sales_Representative__r.Name:'');
                                }
                                if(ordObj.Source_Application__c == 'Diageo One'){
                                    headervalue.mobileNumber = Label.EDGE_MobileNumber;
                                    individualOrder.MobileNumber = ((ordObj.Contact__r.MobilePrefix__c)!=null ? ordObj.Contact__r.MobilePrefix__c:'') + ((ordObj.Contact__r.Mobile__c)!=null ? ordObj.Contact__r.Mobile__c:'');
                                    
                                }else{
                                    headervalue.mobileNumber = Label.EDGE_MobileNumber;
                                    individualOrder.MobileNumber = ((ordObj.Sales_Representative__r.Mobile_Number__c)!=null ? ordObj.Sales_Representative__r.Mobile_Number__c:'');
                                }
                                
                                if(ordObj.Source_Application__c == 'Diageo One'){
                                    headervalue.email = Label.EDGE_Email;
                                    individualOrder.Email = ((ordObj.Contact__r.Email)!=null ? ordObj.Contact__r.Email:'');
                                }else{
                                    headervalue.email = Label.EDGE_Email;
                                    individualOrder.Email = ((ordObj.Sales_Representative__r.Email)!=null ? ordObj.Sales_Representative__r.Email:'');
                                }
                                
                                headervalue.orderNumber = Label.EDGE_Order_Number;
                                individualOrder.OrderNumber =  +((ordObj.Name)!=null ? ordObj.Name:'');
                                if(ordObj != null && ordObj.Account__r.Country__c !=null && countryMarketMap != null && countryMarketMap.get(ordObj.Account__r.Country__c).Display_Transfer_Order_Comments__c && ordObj.Comments__c !=null){
                                    headervalue.overallComment = label.EDGE_OverallComment;
                                    headerValue.showComment = True;
                                    individualOrder.OverAllComment = ((ordObj.Comments__c)!=null ? ordObj.Comments__c:'');
                                }
                                //section - Order Items header                                
                                
                                headervalue.prodName = label.EGDE_ProductName;
                                headervalue.productSKUID=label.EDGE_ProductSKUId;//added as part of ES20-12728
                                headervalue.prodQuant = label.EDGE_ProductQuantity;
                                headervalue.UOM = label.EDGE_UOM;
                                //ES20-13154
                                 if(ordObj.Is_Promo_Transfer_Order__c){
                                    headervalue.promotionName=label.EDGE_Promotion_Name;
                                    headervalue.promotionType=label.EDGE_Promotion_Type;
                                    headervalue.discountForPromotion=label.EDGE_Discount_for_Promotion;
                                    headervalue.freeProdforPromo=label.EDGE_FreeProductsYesNo;
                                }
                                System.debug(LoggingLevel.Debug,'Line 192 > individualOrder ='+ individualOrder);
                            }//Trigger code - end
                            
                            if(orderListOrderItemMap!=null && orderListOrderItemMap.ContainsKey(ordObj.Id) ){
                                if(ordItemQuantity.size()>0){
                                    
                                    individualOrder.ordItemList = new List<EDGE_TransferOrderMailWrapper.orderItemObj>();
                                    individualOrder.promotionDetailsList = new List<EDGE_TransferOrderMailWrapper.promotionDetailsObj>();//ES20-13154
                                    Map<Id,EDGE_TransferOrderMailWrapper.promotionDetailsObj> promoToPromoDetails=new Map<Id,EDGE_TransferOrderMailWrapper.promotionDetailsObj>();
                                    for(integer i=0;i<ordItemQuantity.size();i++){
                                        if(ordItemQuantity[i].Promotion_Product__c!=null){//ES20-13154, Order Item came from a Promotion
                                            
                                            Id PromotionId= ordItemQuantity[i].Promotion_Product__r.Promotion__c;
                                            if(!promoToPromoDetails.containsKey(PromotionId)){
                                                EDGE_TransferOrderMailWrapper.promotionDetailsObj promotionDetails = new EDGE_TransferOrderMailWrapper.promotionDetailsObj();
                                                
                                                promotionDetails.promotionName=ordItemQuantity[i].Promotion_Product__r.Promotion__r.Name;
                                                promotionDetails.promotionType=ordItemQuantity[i].Promotion_Product__r.Promotion__r.RecordType.Name;
                                                if(ordItemQuantity[i].Promotion_Product__r.RecordTypeId!=freeProductRecordType){
                                                    promotionDetails.discountForPromotion=ordItemQuantity[i].Promotion_Product__r.Promotion__r.Discount_for_promotion__c;
                                                }
                                                promotionDetails.isFreePromotion=((ordItemQuantity[i].Promotion_Product__r.Promotion__r.RecordType.Name=='Free Product')?True:False);
                                                
                                                promotionDetails.promotionItemsObj = new List<EDGE_TransferOrderMailWrapper.promotionItemsObj>();
                                                
                                                EDGE_TransferOrderMailWrapper.promotionItemsObj promotionItem = new EDGE_TransferOrderMailWrapper.promotionItemsObj();
                                                promotionItem.productName=ordItemQuantity[i].Promotion_Product__r.Product__c != null ? ordItemQuantity[i].Promotion_Product__r.Product__r.Product_Full_Name__c : '';
                                                promotionItem.productQuantity=ordItemQuantity[i].Quantity__c ;
                                                promotionItem.productUOM=ordItemQuantity[i].Promotion_Product__r.Promo_Transfer_Order_Used_UOM__c;
                                                promotionItem.productSKUId=ordItemQuantity[i].Product__r.SAP_SKU_Code__c;
                                                promotionItem.isFreeProduct=((ordItemQuantity[i].Promotion_Product__r.RecordTypeId==freeProductRecordType)?'Yes':'No');
                                                
                                                promotionDetails.promotionItemsObj.add(promotionItem);
                                                individualOrder.promotionDetailsList.add(promotionDetails);
                                                
                                                promoToPromoDetails.put(PromotionId,promotionDetails);  
                                            }
                                            else{
                                                EDGE_TransferOrderMailWrapper.promotionDetailsObj promotionDetails = promoToPromoDetails.get(PromotionId);
                                                EDGE_TransferOrderMailWrapper.promotionItemsObj promotionItem = new EDGE_TransferOrderMailWrapper.promotionItemsObj();
                                                promotionItem.productName=ordItemQuantity[i].Promotion_Product__r.Product__r.Product_Full_Name__c;
                                                promotionItem.productQuantity=ordItemQuantity[i].Quantity__c ;
                                                promotionItem.productUOM=ordItemQuantity[i].Promotion_Product__r.Promo_Transfer_Order_Used_UOM__c;
                                                promotionItem.productSKUId=ordItemQuantity[i].Product__r.SAP_SKU_Code__c;
                                                promotionItem.isFreeProduct=((ordItemQuantity[i].Promotion_Product__r.RecordTypeId==freeProductRecordType)?'Yes':'No');
                                                promotionDetails.promotionItemsObj.add(promotionItem);
                                                
                                            }
                                            
                                        }
                                        else{//for non promo items - existing logic
                                            EDGE_TransferOrderMailWrapper.orderItemObj individualordItem = new EDGE_TransferOrderMailWrapper.orderItemObj();
                                            //Added as part of ES20-12641
                                            individualordItem.productName = ((ordItemQuantity[i].Market_Assortment_Product__r.D1_Product_Name__c)!=null ? ordItemQuantity[i].Market_Assortment_Product__r.D1_Product_Name__c:ordItemQuantity[i].Market_Assortment_Product__r.Product__r.Name);
                                            /*
                                            if(ordObj.RecordTypeId == freeGoodOrderRTId){
                                                individualordItem.productName =  ordItemQuantity[i].Product__r.Name;
                                            } else {
                                                individualordItem.productName = ((ordItemQuantity[i].Product__r.Long_Description__c)!=null ? ordItemQuantity[i].Product__r.Long_Description__c:'');
                                            }
                                            */
                                            individualordItem.productSKUId=ordItemQuantity[i].Product__r.SAP_SKU_Code__c;//Added as part of ES20-12728
                                            individualordItem.productQuantity =  ordItemQuantity[i].Quantity__c ;
                                            individualordItem.productUOM = ((ordItemQuantity[i].Selected_UoM__c)!=null ? ordItemQuantity[i].Selected_UoM__c:'');
                                            individualOrder.isOrderItemPresent=True;
                                            individualOrder.ordItemList.add(individualordItem);
                                        }
                                    }     
                                }//end of iterating through all Order Items
                            }
                            
                            wholeOrder.orderList.add(individualOrder); 
                            
                        }//end of orderListOrderItemMap   
                        
                    }                    
                }
                wholeOrderList.add(wholeOrder);
            }
        } 
        System.debug(LoggingLevel.Debug,'headervalue'+headervalue);
        System.debug(LoggingLevel.Debug,'wholeOrderList'+wholeOrderList);
        transferOrderWrapper.headerWrapperValue = headervalue;
        transferOrderWrapper.orderDetailsWrapperValue = wholeOrderList;
        return transferOrderWrapper;
    }

}