/**
 * @name D1_Product2TriggerHandlerTest
 * @purpose This provides test coverage to following controller: D1_Product2TriggerHandler
 * @history
 * VERSION     AUTHOR         DATE               DETAIL
 * 1.0         -	   			-		     		-
 * 2.0			Rubeena		   01/07/2021		  Test Class Refractor [NCP-3763]
**/
@isTest
public class D1_Product2TriggerHandlerTest {
    /**
     * @description Test data setup for D1_Product2TriggerHandlerTest
     */    
    @testSetup 
    public static void setup() {
        
        List<Product_Volume_Configuration__c> pvcList = new List<Product_Volume_Configuration__c>();
        
        Product_Volume_Configuration__c pvc1 = D1_TestDataUtility.geProductVolumeConfiguration('Volume');
        pvcList.add(pvc1);
        
        Product_Volume_Configuration__c pvc2 = D1_TestDataUtility.geProductVolumeConfiguration('Configuration');
        pvc2.IntegrationID__c = '00B7';
        pvcList.add(pvc2);

        insert pvcList;

        Product__c productRec = D1_TestDataUtility.getProduct(null,'Brand Variant',null);
        productRec.SAP_Hierarchy_code__c = '123456123456';
        productRec.Source_System__c = 'SAP';
        productRec.UPI_Status__c = 'confirmed';
        productRec.Start_Date__c = system.today();   
        insert productRec;
    }
    /**
     * @description setProductLink method
     */
    @isTest
    static void setProductLink() {
        D1_TestDataUtility.createOrgSettings();
        
       
        
        Test.startTest();
        Product2 p = D1_TestDataUtility.getProduct();
        p.Name = 'Test Product L5';
        p.SAP_Material_Id__c='12345678';
        p.Hierarchy__c='12345612345600A00B';
        p.Hierarchy_Level__c='5';
        insert p;
		System.assert(p!=null,'Product insertion failed');
        
        Product2 tempP = [SELECT Id, Brand_Variant__c, Level_7__c, Level_6__c, Type, Name FROM Product2 WHERE Hierarchy__c='12345612345600A00B' LIMIT 1];
        System.assert(tempP.Brand_Variant__c != null, 'L5 product not linked');
        System.assert(tempP.Level_6__c != null, 'L6 product not linked');
        System.assert(tempP.Level_7__c != null, 'L7 product not linked');
        
        Test.stopTest();
    }

    /**
     * @description setProductLink2 method
     */
    @isTest
    static void setProductLink2() {
        D1_TestDataUtility.createOrgSettings();
        
        Test.startTest();
        Product2 p = D1_TestDataUtility.getProduct();
        p.Name = 'Test Product L6';
        p.SAP_Material_Id__c='12345678';
        p.Hierarchy__c='12345612345600A00D';
        p.Hierarchy_Level__c='6';
        insert p;
		System.assert(p!=null,'Product insertion failed');
        
        Product2 tempP = [SELECT Id, Brand_Variant__c, Level_7__c, Level_6__c, Type, Name FROM Product2 WHERE Hierarchy__c='12345612345600A00D' LIMIT 1];
        
        System.assert(tempP.Brand_Variant__c != null, 'L5 product not linked');
        System.assert(tempP.Level_6__c != null, 'L6 product not linked');
        
        Test.stopTest();
    }

    /**
     * @description setProductLink3 method
     */
    @isTest
    static void setProductLink3() {
        D1_TestDataUtility.createOrgSettings();
        Test.startTest();
        Product2 p = D1_TestDataUtility.getProduct();
        p.Name = 'Test Product L7';
        p.SAP_Material_Id__c='12345678';
        p.Hierarchy__c='12345682345600G00B';
        p.Hierarchy_Level__c='7';
        insert p;
		System.assert(p!=null,'Product insertion failed');
        
        Product2 tempP = [SELECT Id, Brand_Variant__c, Level_7__c, Level_6__c, Type, Name FROM Product2 WHERE Hierarchy__c='12345682345600G00B' LIMIT 1];
        
        System.assert(tempP.Level_7__c != null, 'L7 product not linked');
        
        Test.stopTest();
    }

    /**
     * @description setProductLinkForMultipleProducts method
     */
    @isTest
    static void setProductLinkForMultipleProducts() {
        Test.startTest();
        
        List<Product2> obj = new List<Product2>();
        Product2 p = D1_TestDataUtility.getProduct();
        p.Name = 'Test Product L5';
        p.SAP_Material_Id__c='123456781';
        p.Hierarchy__c='12345612345600A00B';
        p.Hierarchy_Level__c='5';
        obj.add(p);
        
        Product2 p2 = D1_TestDataUtility.getProduct();
        p2.Name = 'Test Product L6';
        p2.SAP_Material_Id__c='123456782';
        p2.Hierarchy__c='12345612345600A00D';
        p2.Hierarchy_Level__c='6';
        obj.add(p2);
        
        Product2 p3 = D1_TestDataUtility.getProduct();
        p3.Name = 'Test Product L7';
        p3.SAP_Material_Id__c='123456783';
        p3.Hierarchy__c='12345682345600G00B';
        p3.Hierarchy_Level__c='7';
        obj.add(p3);
        insert obj;
        System.assert(obj.size()>0,'Product List not inserted');
        Test.stopTest();
    }

    /**
     * @description setProductLinkForMultipleProducts2 method
     */
    @isTest
    static void setProductLinkForMultipleProducts2() {
        
        List<Product2> obj = new List<Product2>();
        Integer i=0;
        for(i=0;i<100;i++){
            Product2 p = new Product2();
            p.Name = 'Test Product L5'+i;
            p.SAP_Material_Id__c='123678'+i;
            p.Hierarchy__c='12345612345600A00B';
            p.Hierarchy_Level__c='5';
            p.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            obj.add(p); 
        }
        
        Integer j=0;
        for(j=0;j<100;j++){
            Product2 p2 = D1_TestDataUtility.getProduct();
            p2.Name = 'Test Product L6'+j;
            p2.SAP_Material_Id__c='13457'+j+'8';
            p2.Hierarchy__c='11345612345600A00D';
            p2.Hierarchy_Level__c='6';
            p2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            obj.add(p2);
        }
        
        Integer k=0;
        for(k=0;k<100;k++){
            Product2 p3 = D1_TestDataUtility.getProduct();
            p3.Name = 'Test Product L7'+k;
            p3.SAP_Material_Id__c=k+'145678';
            p3.Hierarchy__c='11245682345600G00B';
            p3.Hierarchy_Level__c='7';
            p3.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            obj.add(p3);
        }
        Test.startTest();
        insert obj;
        System.assert(obj.size()>0,'Products not inserted');
        Test.stopTest();
    }
    /**
     * @description product2Update method
     */
    @isTest 
    public static void product2Update(){
        D1_TestDataUtility.createOrgSettings();

        List<Product2> products = D1_TestDataUtility.product2TestData();
        
        List<Product2> proToUpdate = new List<Product2>();
        for(Product2 pro: products){
            pro.D1_Category__c = 'Spirit';
            proToUpdate.add(pro);
        }
       Test.StartTest();
       	update proToUpdate;
       Test.stopTest();
        
        List<ProductCategory> catt = [select id,name from ProductCategory where ParentCategory.Name = 'Product' and Catalog.name = 'Shop'];
       
        
        system.assert(catt.size() >1, 'cart size in-correct' );
    }
    
    
}