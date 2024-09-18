/**
 * @Name: B2BUtilsTest
 * 
 * @Description: This provides test coverage to following controller:
 * B2BUtils
 * 
 * @History
 * --
 * VERSION     AUTHOR         DATE               DETAIL
 * 1.0         Ankit Garg	   04/01/2021		     -
 * 2.0			Rubeena		   01/07/2021		  Test Class Refractor [NCP-3763]
 * 3.0          Mayukh/Mukesh        21/08/2023  143985
 **/
@isTest
public class B2BUtilsTest {
    
    /**
     * @Name : createTestData
	 * @description : This method is used to create dummy test data for B2BUtilsTest class
	 */
    @testSetup    
    static void createTestData() {
        
        WebCart webCArtObj;
        WebStore webstoreObj;
        
        Account account = D1_TestDataUtility.getDirectCustomer();
        account.D1_Registration_Status__c = '';
        account.Current_Approval_Step__c ='';
        account.Status__c='';
        insert account;
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
            D1_TestDataUtility.b2bCommercePermissionset(userObj);

            webCartObj = [SELECT Id from WebCart where Name='TestCart'];
            webCartObj.OwnerId = userInfo.getUserId();
            update webCartObj;
        }
    }
    
    /**
     * @Name : testB2BCartDetailsController
	 * @description : This method is used to test positive cases while calling methods of B2BUtils class
	 */   
    @isTest 
    public static void testB2BCartDetailsController() {
        
        User userObj = [select Id,AccountId,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        WebStore  webstoreObj = [SELECT Id from WebStore limit 1];
        WebCart   webCartObj = [SELECT Id from WebCart where Name='TestCart'];
        
        Test.startTest();
        System.runAs(userObj){
                       
            B2BUtils.communityIdToWebStoreIdCache.put(webstoreObj.id,webstoreObj.id);
            B2BUtils.resolveCommunityIdToWebstoreId(webstoreObj.id);
            Object webCart = B2BUtils.getCartTotalWeight(webCartObj.id);
            System.assert(webCart!=null,'WebCart not present');
            Assert.isNotNull(webCart, 'WebCart not present');
            try{
                B2BUtils.resolveSortParam(null);
                B2BUtils.GenericCartWrapper gcw=B2BUtils.getCartId(userObj.Id,userObj.Effective_Account_Id__c);
                System.assert(gcw!=null,'Cart Wrapper Not Returned');
                Assert.isNotNull(gcw, 'Cart Wrapper Not Returned');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
            //143985:Migrate getD1Setting method in D1_UtilityClass
            /*try{
                Object d1Setting = B2BUtils.getD1Setting(null);
                System.assert(d1Setting!=null,'D1Settings not found');
                Assert.isNotNull(d1Setting, 'D1Settings not found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }*/
            
            try{
                Object ocw = B2BUtils.getUserOrderConfig(null);
                System.assert(ocw!=null,'Order Wrapper Not Returned');
                Assert.isNotNull(ocw, 'Order Wrapper Not Returned');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
            
            try{
                Object d1UserType = B2BUtils.getD1UserType(null);
                System.assert(d1UserType!=null,'UserType not found');
                Assert.isNotNull(d1UserType, 'UserType not found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
        Test.stopTest();
    }
    
    /**
     * @Name : testNegative
	 * @description : This method is used to test negative cases while calling methods of B2BUtils class
	 */   
    @isTest    
    public static void testNegative() {
        
        User userObj = [select Id,AccountId,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        WebStore  webstoreObj = [SELECT Id from WebStore limit 1];
        WebCart   webCartObj = [SELECT Id from WebCart where Name='TestCart'];
        delete webCartObj;
        
        Test.startTest();
        System.runAs(userObj){
            
             try{
                String webStoreIdRet = B2BUtils.resolveCommunityIdToWebstoreId(webstoreObj.id);
                System.assertEquals((String)webstoreObj.Id,webStoreIdRet, 'WebStore Not Found');
                Assert.areEqual((String)webstoreObj.Id,webStoreIdRet, 'WebStore Not Found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }

            try{
                B2BUtils.GenericCartWrapper gcw = B2BUtils.getCartId(userObj.Id,null);
                System.assert(gcw.cartId!=null, 'Cart not found');
                Assert.isNotNull(gcw.cartId, 'Cart not found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
            //143985:Migrate getD1Setting method in D1_UtilityClass
            /*try{
                Object d1Setting = B2BUtils.getD1Setting(userObj.Id);
                System.assert(d1Setting!=null,'D1Settings not found');
                Assert.isNotNull(d1Setting, 'D1Settings not found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }*/
            
            try{
                Object ocw =  B2BUtils.getUserOrderConfig(userObj.Id);
                System.assert(ocw!=null,'Order Wrapper Not Returned');
                Assert.isNotNull(ocw, 'Order Wrapper Not Returned');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
            
            try{
                Object d1UserType = B2BUtils.getD1UserType(userObj.Id);
                System.assert(d1UserType!=null,'UserType not found');
                Assert.isNotNull(d1UserType, 'UserType not found');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
        Test.stopTest();
    }
    
    
}