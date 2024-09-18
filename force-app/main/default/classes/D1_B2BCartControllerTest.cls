@isTest
public class D1_B2BCartControllerTest {
    
    @isTest
    public static void testUpdateCart(){
        try{
            D1_B2BCartController.updateCartItem(null,null,null,null,null);
            System.assertEquals(D1_B2BCartController.updateCartItem(null,null,null,null,null), NULL, 'cart item not updated');
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }    
    }
    
    @isTest
    public static void testDeleteCartItem(){
        try{
            D1_B2BCartController.deleteCartItem(null,null,null,null);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            System.assertNotEquals(ex.getMessage(), '', 'assertion failed');
        }  
    }
    
    @isTest
    public static void testCreateCart(){
        try{
            D1_B2BCartController.createCart(null,null);
            System.assertEquals(D1_B2BCartController.createCart(null,null), NULL,'cart creation failed');
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }    
    }
    
    @isTest
    public static void testDeleteCart(){
        try{
            D1_B2BCartController.deleteCart(null,null,null);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            System.assertNotEquals(ex.getMessage(), '', 'assertion failed');
        }    
    }
    
    @isTest
    public static void testGetCartSummary(){
        try{
            D1_B2BCartController.getCartSummary(null,null,null);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            System.assertNotEquals(ex.getMessage(), '', 'assertion failed');
        }    
    }

   
    
    /**
     * @author Ankit
     * @date 04/01/2021 
     * @description Create Test Data
     * @param  
     * @return 
     */
    @testSetup static void createTestData() {
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        D1_User_Type__c d1UserType;
        D1_Setting__c d1setting;
        
        System.runAs(thisUser){            
            UserRole ur   =     [Select Id From UserRole Where Name = 'Global' Limit 1];
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
            insert testoutlet;
            
            Contact primcon1=new Contact(FirstName='fname1',
                                         LastName = 'lname',
                                         Email = 'email1@gmail.com',
                                         Phone = '12345672890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
            insert primcon1;
            
            PNR_Partner_Function__c pf = new PNR_Partner_Function__c();
            pf.D1_EDGE_Customer__c = true;
            pf.PNR_Customer_No__c = testoutlet.Id;
            pf.PNR_Type__c = 'Sold-To';
            insert pf;
            
            List<Contact> conList=[select id from Contact where accountId=:testoutlet.Id ];
            system.assert(conList.size() > 0, 'contact list not found');
            List<user> userList = new List<User>();
            User externalUser1 = EDGE_UtilityTestClass.runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'email1234@gmail.com';
            externalUser1.Email='email1@gmail.com';
            externalUser1.CommunityNickname = 'Mania.Test1';
            externalUser1.Available_Countries__c = 'ES';
            externalUser1.ContactId = primcon1.id; 
            externalUser1.isActive = True;
            externalUser1.D1_User_Type_Id__c = d1UserType.id;
            userList.add(externalUser1);
            insert userList;
        }
    }
    
    /**
     * @author Ankit
     * @date 04/01/2021 
     * @description First TestMthd
     * @param  
     * @return 
     */
    @isTest
    public static void testB2BCartDetailsController() {
        User userObj = [select Id,AccountId,Account.Name from User where Profile.Name = 'DiageoOne External User' 
                            and Isactive = true  order by lastModifieddate desc limit 1];
        
        WebStore webstoreObj = new WebStore();
        webstoreObj.Name = 'Test Store';
        insert webstoreObj;
        
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
            buyerAccountObj.Name = userObj.Account.Name;
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

        /*Pricebook2 priceBookObj1 = new Pricebook2();
        priceBookObj1.IsActive = true;
        //priceBookObj1.PortfolioID__c = 'Test112233';
        priceBookObj1.Name = 'Standard Price Book';
        insert priceBookObj1;*/

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        
        BuyerGroupPricebook priceBookBuyerGrpObj = new BuyerGroupPricebook();
        priceBookBuyerGrpObj.BuyerGroupId = buyerGroupObj.Id;
        priceBookBuyerGrpObj.IsActive = true;
        priceBookBuyerGrpObj.Pricebook2Id = priceBookObj.Id;
        insert priceBookBuyerGrpObj;

        Product2 prodObj = new Product2();
        prodObj.Name = 'Test P';
        insert prodObj;

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
    
        system.runAs(userObj) {
            PermissionSet permissionSetObj = [select Id from PermissionSet where Label = 'B2B Commerce User'];
            List<PermissionSetAssignment> psAssignmentLst = [select Id from PermissionSetAssignment  
                                                                where PermissionSetId = :permissionSetObj.Id and AssigneeId =:userObj.Id];
            if(psAssignmentLst == NULL || psAssignmentLst.size() == 0) {
                PermissionSetAssignment psObj = new PermissionSetAssignment();
                psObj.AssigneeId = userObj.Id;
                psObj.PermissionSetId = permissionSetObj.Id;
                insert psObj;
            }
            WebCart webCArtObj = new WebCart();
            webCArtObj.Name = 'TEst';
            webCArtObj.WebStoreId = webstoreObj.Id;
            webCArtObj.AccountId = userObj.AccountId;
            insert webCArtObj;
            
            CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=webCArtObj.Id, Name='Default Delivery');
            insert cartDeliveryGroup;

            
            
            CartItem cartItem = new CartItem(CartId=webCArtObj.Id, Sku='SKU_Test1', SalesPrice=10.00, Quantity=3.0, 
                                                Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id,
                                                Product2Id = prodObj.Id
                                            );
            insert cartItem;
            
            //getCartItems(String webStoreId, String accountId, String cartId, String pageParam, String sortParam, Boolean isSplitView)
            try{
            D1_B2BCartController.getCartItems(webstoreObj.Id,userObj.AccountId,webCArtObj.id,null,null);
            }catch(Exception ex){
                system.debug(LoggingLevel.ERROR, ex.getMessage());
                System.assertNotEquals(ex.getMessage(), '', 'assertion failed');
            }
          
        	//setUpCartItemWrapper(ConnectApi.CartItemCollection cartItemFromApi,String cartId,Boolean isSplitView)
            D1_B2BCartController.setUpCartItemWrapper(setUpCartItemsObj(prodObj.Id),webCArtObj.id);
            
            
        }
    }
    
    private static ConnectApi.CartItemCollection setUpCartItemsObj(Id productId){
        ConnectApi.CartItemProduct cartProduct = new ConnectApi.CartItemProduct();
        cartProduct.productId = productId;
        cartProduct.thumbnailImage = new ConnectApi.ProductMedia();
        
        ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
        cartItem.listPrice ='0';
        cartItem.productId = productId;
        cartItem.productDetails = cartProduct;
        
        ConnectApi.CartItemResult itemResult = new ConnectApi.CartItemResult();
        itemResult.cartItem = cartItem;
        
        ConnectApi.CartItemCollection collection = new ConnectApi.CartItemCollection();
        collection.cartItems = new List<ConnectApi.CartItemResult>{itemResult};
        collection.cartSummary = new ConnectApi.CartSummary();
        
        return collection;
    }
    
}