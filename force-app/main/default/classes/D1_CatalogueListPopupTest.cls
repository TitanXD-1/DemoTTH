/*
* @name: D1_CatalogueListPopupTest
* @discription: test class for D1_CatalogueListPopup 
* @history
* VERSION     AUTHOR           DATE          DETAIL
* 1.0        D1 DEV Team
*/
@isTest
public class D1_CatalogueListPopupTest {
    @testSetup 
    /**
     * @description 
     */    
    static void createTestData() {
        WebCart webCArtObj;
        WebStore webstoreObj;
        
        Account account = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        D1_TestDataUtility.insertCartAndCartItems(account);
        
        User userObj = [select Id,AccountId,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        
        webstoreObj = [SELECT Id from WebStore limit 1];
        webstoreObj.Name = 'Shop';
        webstoreObj.DefaultLanguage = 'en_GB';
        webstoreObj.SupportedLanguages = 'en_GB;es';
        update webstoreObj;
        
        D1_TestDataUtility.createOrgSettings();
        system.runAs(userObj){
            Test.startTest();

            D1_TestDataUtility.b2bCommercePermissionset(userObj);
            webCartObj = [SELECT Id from WebCart where Name='TestCart'];
            webCartObj.OwnerId = userInfo.getUserId();
            update webCartObj;
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testInitWishList(){
        User userObj = [select Id,AccountId,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        WebStore  webstoreObj = [SELECT Id from WebStore limit 1];
        //WebCart   webCartObj = [SELECT Id from WebCart where Name='TestCart'];
        System.runAs(userObj){
            Test.startTest();
            B2BUtils.communityIdToWebStoreIdCache.put(webstoreObj.id,webstoreObj.id);
			D1_CatalogueListPopup.initWishList(webstoreObj.Id,userObj.Effective_Account_Id__c,null);
            System.assert(D1_CatalogueListPopup.initWishList(webstoreObj.Id,userObj.Effective_Account_Id__c,null)!= NULL, 'Wishlist Creation is not Started');
            D1_CatalogueListPopup.createWishlistWithItem(webstoreObj.Id,userObj.Effective_Account_Id__c,'WishList1',null);
            System.assert(D1_CatalogueListPopup.createWishlistWithItem(webstoreObj.Id,userObj.Effective_Account_Id__c,'WishList1',null) == NULL, 'Wishlist Creation failed');
            D1_CatalogueListPopup.addWishlistItem(webstoreObj.Id,userObj.Effective_Account_Id__c,null,null);
            System.assert(D1_CatalogueListPopup.addWishlistItem(webstoreObj.Id,userObj.Effective_Account_Id__c,null,null) == NULL, 'Wishlist addition failed');
            D1_CatalogueListPopup.WishListWrapper wl = new D1_CatalogueListPopup.WishListWrapper('','');
            Assert.isNotNull(wl, 'Value should not be null');
            Test.stopTest();
        }
    }
}