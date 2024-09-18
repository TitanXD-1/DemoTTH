/**
 * @name D1_TransferOrderControllerTest
 * @description D1_TransferOrderController
 * @history
 * VERSION     	AUTHOR         		DATE            DETAIL
 * 1.0         	Amar Deep      		28/04/21
 * 2.0			Sayan Samaddar   	16/07/2021		Test Class Refractor [NCP-3801]
 * 3.0			Subhrojit Majumdar 	20/09/2022		NCP - 7289
**/
@isTest
public class D1_TransferOrderControllerTest {   
    
    /**
     * @description testGetDistributors method
     */    
    @isTest
    public static void testGetDistributors(){
       	setUpExternalUser();     
        user currentUser = [select id,LanguageLocaleKey,Effective_Account_Id__c,ContactId from User where username ='testclassextuser1@testdomain.com' AND isActive = true limit 1];
        
        List<Product__c> prods = [select id,Name,Brand_Formula__c,Category_Formula__c,Sub_Category_Formula__c,
                                  Volume_Formula__c,Classification_Formula__c from Product__c limit 1]; 
        
        Product__c product = prods[0];
        List<Market_Assortment_Product__c> maProds = [select id,D1_Product_Name__c,MAP_Image_Version__c from Market_Assortment_Product__c LIMIT 1];
        Market_Assortment_Product__c maProducts = maProds[0];
       // Product productObj = new Product(product.id,'',10);
        Product productObj = new Product(product,maProducts,10);
        String jsonSelectedProducts = JSON.serialize(new List<Product>{productObj});
        String jsonDeliveryInfo = '{}';
        
        System.runAs(currentUser){
            Test.startTest();
            
        	List<Supplier_Outlet__c> distributors = D1_TransferOrderController.getDistributors(currentUser.Id);
            String channel = D1_TransferOrderController.getChannel(currentUser.Effective_Account_Id__c);
            Object transferOrderProducts = D1_TransferOrderController.getTransferOrderProducts(currentUser.Id); 
            
            Id orderId = D1_TransferOrderController.submitOrder(jsonSelectedProducts,jsonDeliveryInfo);
            Order__c ord = [Select id,status__c from Order__c where id =: orderId];
            List<Order_Item__c> testOrderItems = [SELECT Id, Quantity__c, Selected_UoM__c, Product__c, Product__r.Name FROM Order_Item__c WHERE Order__c = :orderId];
            
			List<D1_TransferOrderController.orderProductsWrap> orderItems= D1_TransferOrderController.getOrderItems(orderId, null);
            
            Test.stopTest();
            
            System.assertEquals(distributors.size(),1, 'distribution size not correct');
            System.assertEquals(distributors[0].outlet__c,currentUser.Effective_Account_Id__c, 'distributor id not correct');
            System.assert(channel!=null,'Channels not found');
            System.assertEquals(channel,'Off Trade', 'channel not correct');
            System.assert(transferOrderProducts!=null,'Transfer order products not available');
            
            System.assert(orderId!=null,'OrderId is not created');
            System.assertEquals(ord.status__c, 'Submitted','order status incorrect');
            System.assertEquals(orderItems.size(),1, 'order item size in-correct');
            System.assertEquals(orderItems[0].ordItem,testOrderItems[0], 'order item not found');
        }
        
    }
    
    /**
     * @description setUpExternalUser
     */    
    private static void setUpExternalUser() {
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        D1_User_Type__c d1UserType;
        D1_Setting__c d1setting;
        
        System.runAs(thisUser){            
            UserRole ur = [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser;  
            
            Id countryId = D1_TestDataUtility.setupCountry('ES');
            country = new Geography__c(Id= countryId);
            upsert country;  
            
            pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[ES]');
            insert pickupOption;
            
			d1setting = D1_TestDataUtility.createD1Settings(country);
            insert d1setting;      
			
            d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1setting.Id);
            insert d1UserType;
       
            Product__c testProduct = D1_TestDataUtility.getProduct(countryId, 'POS', null);
            insert testProduct;

			Market_Assortment_Product__c testMAP = D1_TestDataUtility.getMap(countryId, testProduct.Id);
         	insert testMAP;            
        }        
        system.runAs(testAdminUser){
            Account testoutlet=D1_TestDataUtility.getD1Customer();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            insert testoutlet;
            
            Contact primcon1 = D1_TestDataUtility.getContact(testoutlet.Id, 'Primary');
            insert primcon1;
            
            List<AccountContactRelation> relations = [Select id,D1_Active__c from AccountContactRelation];
            for(AccountContactRelation acr: relations){
                acr.D1_Active__c = true;
            }
            update relations;
            
            Account distAccObj = D1_TestDataUtility.getDistributerAccountRecord();
            insert distAccObj;
            
            Supplier_Outlet__c prmrySubRecObj1 = D1_TestDataUtility.suppOutletRec(testoutlet.Id,distAccObj.Id);
            insert prmrySubRecObj1;
            
            PNR_Partner_Function__c pf = D1_TestDataUtility.getPartnerFunction(testoutlet,'Sold-To');
            insert pf;
            
            List<Contact> conList=[select id from Contact where accountId=:testoutlet.Id ];
            system.assert(conList.size() > 0, 'contact list not found');
            
            List<user> userList = new List<User>();
            
            User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'testclassextuser1@testdomain.com';
            externalUser1.Email='testclassextuser1@testdomain.com';
            externalUser1.CommunityNickname = 'Mania.Test1';
            externalUser1.Available_Countries__c = 'ES';
            externalUser1.ContactId = primcon1.id;
            externalUser1.Effective_Account_Id__c = primcon1.AccountId;
            externalUser1.isActive = True;
            externalUser1.D1_User_Type_Id__c = d1UserType.id;
            externalUser1.LanguageLocaleKey ='es';
            userList.add(externalUser1);
            insert userList;
        }
        
    }

    class Product{
        public Integer masterIndex;
        public Id id;
        public String name;
        public String d1Name;
        public String brand;
        public String category;
        public String subCategory;
        public String volume;
        public String classification;
        public String contentVersionId;
        public String selectedUOM;
        public Integer quantity;
        
      //  public Id id;
      //  public String selectedUOM;
      //  public Integer quantity;
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
           
        }
    /*    public Product(Id id, String selectedUOM, Integer quantity){
            this.id = id;
            this.selectedUom = selectedUOM;
            this.quantity = quantity;
        }*/
    }

}