@isTest
public class D1_B2BGetInfoTest {
	@testSetup 
    public static void createTestData() {
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        D1_User_Type__c d1UserType;
        D1_Setting__c d1setting;
        
        System.runAs(thisUser){            
            UserRole ur = [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser;  
            
            
            Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
            country = new Geography__c(Id= countryId);
            country.isDiageoOneEnabled__c   = True;
            country.Enable_E_Commerce__c = true;
            upsert country;  
            
            pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[ES]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            d1setting = new D1_Setting__c();
            d1setting.Name = 'ES setting';
            d1setting.Unique_ID__c = 'test ES';
            d1setting.Language__c = D1_Setting__c.Language__c.getDescribe().getPicklistValues()[0].getValue();
            d1setting.Market__c = country.id;
            insert d1setting;
            
            d1UserType = new D1_User_Type__c();
            d1UserType.Name = 'Outlet Owner';
            d1UserType.D1_Setting__c = d1setting.Id;
            d1UserType.User_Type__c = D1_User_Type__c.User_Type__c.getDescribe().getPicklistValues()[0].getValue();
            insert d1UserType;
            
        } 
        system.runAs(testAdminUser){
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.D1_EDGE_Customer__c =true;
            testoutlet.Salesforce_Delivery_Days_Packaged_Good__c='1;2;3;4;5;6;7';
            testoutlet.Salesforce_Delivery_Days_Keg__c='1;2;3;4;5;6;7';
            testoutlet.Delivery_Pattern__c='0';
            testoutlet.KUNNR__c = '123456';
            insert testoutlet;
            
            Contact primcon1=new Contact(FirstName='fname1',
                                         LastName = 'lname',
                                         Email = 'email11@gmail.com',
                                         Phone = '12345672890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
            insert primcon1;
            
            
            
            List<Contact> conList=[select id from Contact where accountId=:testoutlet.Id ];
            system.assert(conList.size() > 0, 'contact list doen not exist');
            List<user> userList = new List<User>();
            User externalUser1 = EDGE_UtilityTestClass.runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'email12345@gmail.com';
            externalUser1.Email='email11@gmail.com';
            externalUser1.CommunityNickname = 'Mania.Test2';
            externalUser1.Available_Countries__c = 'ES';
            externalUser1.ContactId = primcon1.id; 
            externalUser1.isActive = True;
            externalUser1.D1_User_Type_Id__c = d1UserType.id;
            userList.add(externalUser1);
            insert userList;
        }
    }
    
    @isTest
    public static void testgetCartSummary() {
        User userObj = [select Id,AccountId,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        Org_Setting__c org =  new Org_Setting__c();
        org.Run_Triggers__c = true;
        insert org;
        
        WebStore webstoreObj = new WebStore();
        webstoreObj.Name = 'Test Store';
        webstoreObj.DefaultLanguage = 'en_GB';
        webstoreObj.SupportedLanguages = 'en_GB;es';
        insert webstoreObj;
        
        List<WebStore> webStoreList=[select id,Name from WebStore Limit 1];
        system.assert(webStoreList.size() > 0,'webstore list does not exist');
        
        Sales_Area__c sa= new Sales_Area__c();
        sa.Max_Order_Line_Items__c = 2;
        sa.Name ='Test Sales Area 123';
        insert sa; 
        
        PNR_Partner_Function__c pf = new PNR_Partner_Function__c();
        pf.PNR_Sold_To__c = userObj.AccountId;
        pf.PNR_Customer_No__c = userObj.AccountId; //7684
        pf.D1_EDGE_Customer__c = true;
        pf.PNR_Type__c = 'Sold-To';
        pf.Item_Proposal__c ='PF-1234';
        pf.Sales_Area__c = sa.Id;
        insert pf;
        
        BuyerGroup buyerGroupObj = new BuyerGroup();
        buyerGroupObj.Name = 'Test 11';
        buyerGroupObj.List_Price_Available__c = true;
        buyerGroupObj.PortfolioID__c = 'Test112233';
        insert buyerGroupObj;
        
        WebStoreBuyerGroup storeBuyerGrpObj = new WebStoreBuyerGroup();
        storeBuyerGrpObj.BuyerGroupId = buyerGroupObj.Id;
        storeBuyerGrpObj.WebStoreId = webstoreObj.Id;
        insert storeBuyerGrpObj;
        
        List<BuyerAccount> buyerAccountLst = [select Id from BuyerAccount where isActive = true and BuyerId = :userObj.AccountId];
        if(buyerAccountLst == NULL || buyerAccountLst.size() == 0) { 
            BuyerAccount buyerAccountObj = new BuyerAccount();
            buyerAccountObj.Name = 'Test';
            buyerAccountObj.BuyerId = userObj.AccountId;
            buyerAccountObj.isActive = true;
            buyerAccountObj.BuyerStatus = 'Active';
            insert buyerAccountObj;
        }
        buyerAccountLst = [select Id from BuyerAccount where isActive = true and BuyerId = :userObj.AccountId];
        BuyerGroupMember buyerGrpMemberObj = new BuyerGroupMember();
        buyerGrpMemberObj.BuyerId = userObj.AccountId;
        buyerGrpMemberObj.BuyerGroupId = buyerGroupObj.Id;
        insert buyerGrpMemberObj;
        
        Pricebook2 priceBookObj = new Pricebook2();
        priceBookObj.IsActive = true;
        priceBookObj.PortfolioID__c = 'Test112233';
        priceBookObj.Name = 'Test PB';
        insert priceBookObj;
        
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        
        BuyerGroupPricebook priceBookBuyerGrpObj = new BuyerGroupPricebook();
        priceBookBuyerGrpObj.BuyerGroupId = buyerGroupObj.Id;
        priceBookBuyerGrpObj.IsActive = true;
        priceBookBuyerGrpObj.Pricebook2Id = priceBookObj.Id;
        insert priceBookBuyerGrpObj;
        
        Product2 prodObj = new Product2();
        prodObj.Name = 'Test P';
        insert prodObj;
        
        Product2 prodObj1 = new Product2();
        prodObj1.Name = 'Test P1';
        insert prodObj1;
        
        Product2 prodObj2 = new Product2();
        prodObj2.Name = 'Test P1';
        insert prodObj2;
        
        OrderSplit__c oSpilt = new OrderSplit__c();
        oSpilt.Sales_Area__c = sa.Id;
        oSpilt.Description__c ='Test1234';
        oSpilt.Market_Description__c='Keg';
        oSpilt.Delivery_Day_Series__c=2;
        oSpilt.Max_future_order_days__c=56;
        insert oSpilt;
        
        OrderSplit__c oSpilt2 = new OrderSplit__c();
        oSpilt2.Sales_Area__c = sa.Id;
        oSpilt2.Description__c ='Test1234';
        oSpilt2.Market_Description__c='Keg';
        oSpilt2.Delivery_Day_Series__c=1;
        oSpilt2.Max_future_order_days__c=56;
        insert oSpilt2;

        
        
        DateTime todayDt = DateTime.now();

        Order_Delivery_Date__c orderDeliveryDate = new Order_Delivery_Date__c();
        orderDeliveryDate.Order_Split_ID__c=oSpilt.id;
        orderDeliveryDate.Cutoff_datetime__c=DateTime.newInstanceGmt(todayDt.year(), todayDt.month(), todayDt.day(), todayDt.hour(), todayDt.minute(), todayDt.second()).addDays(3);
        orderDeliveryDate.Substitue_Delivery_Date__c=System.Today().addDays(4);
        orderDeliveryDate.Is_Delivery__c=true;
          orderDeliveryDate.Delivery_Date__c=System.Today().addDays(4);
 
        insert orderDeliveryDate;
        Order_Delivery_Date__c orderDeliveryDate2 = new Order_Delivery_Date__c();
        orderDeliveryDate2.Order_Split_ID__c=oSpilt2.id;
        orderDeliveryDate2.Cutoff_datetime__c=DateTime.newInstanceGmt(todayDt.year(), todayDt.month(), todayDt.day(), todayDt.hour(), todayDt.minute(), todayDt.second()).addDays(1);
        orderDeliveryDate2.Substitue_Delivery_Date__c=System.Today().addDays(3);
        orderDeliveryDate2.Is_Delivery__c=true;
        orderDeliveryDate2.Delivery_Date__c=System.Today().addDays(4);
 		String plantfromdate = String.ValueOf(orderDeliveryDate2.Substitue_Delivery_Date__c.month()) + String.ValueOf(orderDeliveryDate2.Substitue_Delivery_Date__c.day());
				if (orderDeliveryDate2.Substitue_Delivery_Date__c.month() < 10)
					{
						plantfromdate = '0' + plantfromdate;
					}
					plantfromdate = String.ValueOf(orderDeliveryDate2.Substitue_Delivery_Date__c.year()) + plantfromdate;
        orderDeliveryDate2.Delivery_Date_ID__c='NON'+oSpilt2.Name+plantfromdate;
        insert orderDeliveryDate2;
          Order_Delivery_Date__c orderDeliveryDate3 = new Order_Delivery_Date__c();
        orderDeliveryDate3.Order_Split_ID__c=oSpilt.id;
        orderDeliveryDate3.Cutoff_datetime__c=DateTime.newInstanceGmt(todayDt.year(), todayDt.month(), todayDt.day(), todayDt.hour(), todayDt.minute(), todayDt.second()).addDays(1);
        orderDeliveryDate3.Substitue_Delivery_Date__c=System.Today().addDays(4);
        orderDeliveryDate3.Is_Delivery__c=true;
          orderDeliveryDate3.Delivery_Date__c=System.Today().addDays(4);
        insert orderDeliveryDate3;
               
      // update orderDeliveryDate2;
        Account acc =[select id,Delivery_Plant__c,Salesforce_Delivery_Days_Packaged_Good__c,Salesforce_Delivery_Days_Keg__c,Delivery_Pattern__c from account where id=:userObj.AccountId];

        CommerceEntitlementPolicy entPolicyObj = new CommerceEntitlementPolicy();
        entPolicyObj.PortfolioID__c = 'Test112233';
        entPolicyObj.Name = 'Test Policy';
        insert entPolicyObj;
        
        CommerceEntitlementProduct entProdObj = new CommerceEntitlementProduct();
        entProdObj.ProductId = [select Id from Product2 limit 1].Id;
        entProdObj.PolicyId = [select Id from CommerceEntitlementPolicy where PortfolioID__c = 'Test112233' limit 1].Id;
        insert entProdObj;
        
        WebStorePricebook webStorePBObj = new WebStorePricebook();
        webStorePBObj.IsActive = true;
        webStorePBObj.Pricebook2Id = priceBookObj.Id;
        webStorePBObj.WebStoreId = webstoreObj.Id;
        insert webStorePBObj;
        
        ProductCatalog productCatalogObj = new ProductCatalog();
        productCatalogObj.Name = webstoreObj.Name;
        insert productCatalogObj;
        
        WebStoreCatalog webStoreCatalogObj = new WebStoreCatalog();
        webStoreCatalogObj.ProductCatalogId = productCatalogObj.Id;
        webStoreCatalogObj.SalesStoreId = webstoreObj.Id;
        insert webStoreCatalogObj;
        
        PricebookEntry priceBookEntryObj1 = new PricebookEntry();
        priceBookEntryObj1.IsActive = true;
        priceBookEntryObj1.UnitPrice = 0;
        priceBookEntryObj1.Pricebook2Id = standardPricebook.Id;
        priceBookEntryObj1.Product2Id = [select Id from Product2 limit 1].Id;
        insert priceBookEntryObj1;
        
        PricebookEntry priceBookEntryObj = new PricebookEntry();
        priceBookEntryObj.IsActive = true;
        priceBookEntryObj.UnitPrice = 0;
        priceBookEntryObj.Pricebook2Id = priceBookObj.Id;
        priceBookEntryObj.Product2Id = [select Id from Product2 limit 1].Id;
        insert priceBookEntryObj;
        
        User testAdminUser = [select Id,AccountId,Account.Name from User where Profile.Name = 'System Administrator' 
                       and Isactive = true  limit 1];
        system.runAs(testAdminUser) {
            acc =[select id,Delivery_Plant__c,Salesforce_Delivery_Days_Packaged_Good__c,Salesforce_Delivery_Days_Keg__c,Delivery_Pattern__c,KUNNR__c from account where id=:userObj.AccountId];
            List<PermissionSet> permissionSetObj = new List<PermissionSet>();
            permissionSetObj = [select Id from PermissionSet where Label IN ('B2B Commerce User','Ordering','Transfer Orders','POS & Equipment Ordering')];
            //List<PermissionSetAssignment> psAssignmentLst = [select Id from PermissionSetAssignment  
                                                             //where PermissionSetId = :permissionSetObj.Id and AssigneeId =:userObj.Id];
            //if(psAssignmentLst == NULL || psAssignmentLst.size() == 0) {
            List<PermissionSetAssignment> psList = new List<PermissionSetAssignment>();
            for(PermissionSet ps : permissionSetObj){
                PermissionSetAssignment psObj = new PermissionSetAssignment();
                psObj.AssigneeId = userObj.Id;
                psObj.PermissionSetId = ps.Id;
                psList.add(psObj);
            }
            insert psList;
            //}
            
            Test.startTest();
            
            WebCart webCArtObj = new WebCart();
            webCArtObj.Name = 'TEst';
            webCArtObj.WebStoreId = webstoreObj.Id;
            webCArtObj.AccountId = userObj.AccountId;
            //webCArtObj.Order_Split_1__c = oSpilt.id;
            insert webCArtObj;
            
			WebCart afterInsertCart = [select id,Sales_Area__c from WebCart where Id=:webCArtObj.Id LIMIT 1];
            system.assertEquals(afterInsertCart.Sales_Area__c,sa.Id, 'sales area id not found');
            CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=webCArtObj.Id, Name='Default Delivery');
            insert cartDeliveryGroup;
               D1_OrderdeliverdatesCntrl.getOrdersplits(userObj.AccountId);
            D1_OrderdeliverdatesCntrl.getDeliveryDates(oSpilt.Id, userObj.AccountId,null);
            D1_OrderdeliverdatesCntrl.getDeliveryDates(oSpilt2.Id, userObj.AccountId,null);
            D1_OrderdeliverdatesCntrl.createDateWrapper(System.today(), System.now(), 'Keg');
            D1_OrderdeliverdatesCntrl.getDeliveryDates(oSpilt2.Id, userObj.AccountId,'123456');
            try{
                D1_OrderdeliverdatesCntrl.getnextDeliveryDates(oSpilt.Id, userObj.AccountId,null);
            }
            catch(exception ex){
                System.debug(LoggingLevel.ERROR,ex.getMessage());
                
            }
           
               
            // calling checkOutflow class 
            // Start
            List<ID> cartIds = new List<ID>();            
            cartIds.add(webCArtObj.id);
            
            Order ordRec = new Order();
            ordRec.AccountId = userObj.AccountId;
            ordRec.EffectiveDate = date.today();
            ordRec.Status = 'Draft';            
            insert ordRec;
            
           /* ConnectApi.OrderSummaryInputRepresentation input = new ConnectApi.OrderSummaryInputRepresentation();
            input.orderId = ordRec.id;
            ConnectApi.OrderSummaryOutputRepresentation ordSumm = ConnectApi.OrderSummaryCreation.createOrderSummary(input); 
            */
            //User userObj = [select Id,AccountId,Account.Name from User where Profile.Name = 'DiageoOne External User' 
              //          and Isactive = true  order by lastModifieddate desc limit 1];
            OrderItem ordProd = new OrderItem();
            
            ordProd.Product2Id = prodObj.id;
            ordProd.UnitPrice = 55.00;
            ordProd.Quantity = 5;
            ordProd.OrderId = ordRec.id;
            ordProd.ListPrice = 10;
            insert ordProd; 
            ordRec.Status = 'Activated';
            update ordRec;
            //String communityId = [SELECT ID FROM Network WHERE Name = 'DiageoOne' LIMIT 1].ID;
            //System.debug('Community: ' + communityId);
            //ConnectApi.CartSummary ccg = D1_B2BGetInfo.getCartSummary(communityId, userObj.Effective_Account_Id__c);
            
            D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper  cartOrdWrap =  new D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper();
            cartOrdWrap.cartId = webCArtObj.id;
            cartOrdWrap.orderId = ordRec.id;
            List<D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper> cartOrdWrapList = new List<D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper>();
            cartOrdWrapList.add(cartOrdWrap);
            D1_CheckoutFlow_UpdateCartController.updateCartPOnumbers(cartIds);
            D1_CheckoutFlow_UpdateOrderItems.updateOrderItems(cartOrdWrapList);
            
            
          /*  List<OrderSummary> orderSummaryList = [Select id  from OrderSummary where id =:ordSumm.orderSummaryId] ;
           // orderSummaryList.add(ordSumm.orderSummaryId);
            D1_CheckoutFlow_CreateSalesOrder.createSalesOrder(orderSummaryList);*/
            
            // End
            List<cartItem> cartItems = new List<CartItem>();
            
            CartItem cartItem = new CartItem(CartId=webCArtObj.Id, Sku='SKU_Test1', SalesPrice=10.00, Quantity=3.0, 
                                             Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id,
                                             Product2Id = prodObj.Id);
            cartItems.add(cartItem);
            insert cartItems;
           	
            //WebStoreNetwork webStoreNetwork = [Select id,NetworkId from WebStoreNetwork where WebStoreId = :webstoreObj.Id limit 1];
            B2BUtils.communityIdToWebStoreIdCache.put(webstoreObj.id,webstoreObj.id);
            try{
            D1_B2BGetInfo.getCartSummary(webstoreObj.Id, userObj.AccountId);
            }catch(Exception e){
                System.debug(LoggingLevel.ERROR, e.getMessage());
            }
            
            try{
                D1_B2BGetInfo.checkUniqueProduct(webstoreObj.Id, userObj.AccountId, prodObj.Id);
            }
            catch (Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
            Test.stopTest();
        }
    }
}