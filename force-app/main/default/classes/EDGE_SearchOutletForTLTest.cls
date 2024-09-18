/**
* @Name: EDGE_SearchOutletForTLTest

* @Purpose: This is the test class for the  EDGE_SearchOutletForTL class.

* @History                                                            
                                                         
* @VERSION     AUTHOR            DATE              DETAIL
*  1.0      Preyanka Ghosh    26/02/2019    Initial Development         
*  2.0      Debolina/Mayukh  25/05/2022    ES20-12718 - INTRODUCTION OF MORE SEARCH RESULTS IN STATIC TARGET LIST_SFDC_TECH DEBT
**/
@isTest
public class EDGE_SearchOutletForTLTest {
    
    /**
    * @Purpose: Test method to cover searchOutletDetails                                                         
    **/
    @isTest
    public static void searchOutletDetailsTest(){
		       
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        //objAccount.Country__c = geographyID;
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Target_List__c objTarget = EDGE_UtilityTestClass.getTargetList(geographyID);
        //objTarget.Country__c = geographyID;
        insert objTarget;
        System.assertEquals(objTarget.Name, 'Target List 1','objTarget should match');
        
        String queryString = ' OR Name Like \'Test_Outlet%\'';
        test.startTest(); 
        EDGE_SearchOutletForTL.searchOutletDetails(queryString, objTarget.Id);
        test.stopTest();
    }
    
    /**
    * @Purpose: Test method to cover searchOutletDetails                                                         
    **/
    @isTest
    public static void searchOutletWithTLTest(){ 
          
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        //objAccount.Country__c = geographyID;
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Target_List__c objTarget = EDGE_UtilityTestClass.getTargetList(geographyID);
        //objTarget.Country__c = geographyID;
        insert objTarget;
        System.assertEquals(objTarget.Name, 'Target List 1','objTarget should match');
        
        Target_List_Member__c objTLM = EDGE_UtilityTestClass.getTargetMemList(objAccount.Id, objTarget.Id);
        //objTLM.Country__c = objGeo.Id;
        insert objTLM;
        
        String queryString = ' OR Name Like \'Test_Outlet%\'';
        test.startTest();
        EDGE_SearchOutletForTL.searchOutletDetails(queryString, objTarget.Id);  
        test.stopTest();
    }    
    
    /**
    * @Purpose: Test method to cover createTLMember                                                        
    **/
    @isTest
    public static void createTLMemberTest(){
        
        List<String> lstAccount = new List<String>();
        
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Account objAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        objAccount1.Name = 'Test 1';
        objAccount1.Status__c = 'Active';
        insert objAccount1;
        System.assertEquals(objAccount1.Name, 'Test 1','objAccount1 should match');
        
        lstAccount.add(objAccount.Id);
        lstAccount.add(objAccount1.Id);
        
        Target_List__c objTarget = EDGE_UtilityTestClass.getTargetList(geographyID);
        //objTarget.Country__c = geographyID;
        insert objTarget;
        test.startTest();
        Map<String,String> isSuccess;
        isSuccess = EDGE_SearchOutletForTL.createTLMember(lstAccount, objTarget.Id);
        test.stopTest();
    }
    
    /**
    * @Purpose: Test method to cover createTLMember                                                        
    **/
    @isTest
    public static void createTLMemberTest2(){
        
        List<String> lstAccount = new List<String>();
        
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Account objAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        objAccount1.Name = 'Test 1';
        objAccount1.Status__c = 'Active';
        insert objAccount1;
        System.assertEquals(objAccount1.Name, 'Test 1','objAccount1 should match');
        
        lstAccount.add(objAccount.Id);
        lstAccount.add(objAccount1.Id);
        
        Target_List__c objTarget = EDGE_UtilityTestClass.getTargetList(geographyID);
        //objTarget.Country__c = geographyID;
        insert objTarget;
        
        Target_List_Member__c tlm = new Target_List_Member__c();
        tlm.Assignment_Status__c = 'Waiting Activation';
        tlm.Outlet__c = objAccount.Id;
        tlm.Target_List__c = objTarget.Id;
        insert tlm;
        
        test.startTest();
        Map<String,String> isSuccess;
        isSuccess = EDGE_SearchOutletForTL.createTLMember(lstAccount, objTarget.Id);
        test.stopTest();
    }
    
    /**
    * @Purpose: Test method to cover getTerritoryAccount                                                        
    **/
    @isTest
    public static void searchOutletTerritoryTest(){
        test.startTest();
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        objAccount.Country__c = geographyID;
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Territory__c objTarget = EDGE_UtilityTestClass.getTerritoryRec();
        objTarget.Country__c = geographyID;
        insert objTarget;
        System.assertEquals(objTarget.Name, 'Test Territory','objTarget should match');
        
        String queryString = ' OR Name Like \'Test_Outlet%\'';
        
        EDGE_SearchOutletForTL.searchOutletDetails(queryString, objTarget.Id);
        test.stopTest();
    }
    
    /**
    * @Purpose: Test method to cover getTerritoryAccount for Territory                                                        
    **/
    @isTest
    public static void searchOutletTerritoryWithMemberTest(){
        test.startTest();
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        objAccount.Country__c = geographyID;
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Territory__c objTarget = EDGE_UtilityTestClass.getTerritoryRec();
        objTarget.Country__c = geographyID;
        insert objTarget;
        System.assertEquals(objTarget.Name, 'Test Territory','objTarget should match');
        
        Outlet_Territory__c objTerritoryOutlet = EDGE_UtilityTestClass.getOutltTerritory(objAccount.Id,objTarget.Id);
        insert objTerritoryOutlet;
        
        String queryString = ' OR Name Like \'Test_Outlet%\'';
        
        EDGE_SearchOutletForTL.searchOutletDetails(queryString, objTarget.Id);
        test.stopTest();
    }
    
    /**
    * @Purpose: Test method to cover createTerritoryOutlet                                                        
    **/
    @isTest
    public static void createTerritoryOutletTest(){
        test.startTest();
        List<String> lstAccount = new List<String>();
        
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Account objAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        objAccount1.Name = 'Test 1';
        objAccount1.Status__c = 'Active';
        insert objAccount1;
        
        lstAccount.add(objAccount.Id);
        lstAccount.add(objAccount1.Id);
        
        Territory__c objTarget = EDGE_UtilityTestClass.getTerritoryRec();
        objTarget.Country__c = geographyID;
        insert objTarget;
        
        Map<String,List<String>> isSuccess;
        isSuccess = EDGE_SearchOutletForTL.createTerritoryOutlet(lstAccount, objTarget.Id);
        test.stopTest();
    }
    
    /**
    * @Purpose: Test method to cover createTerritoryOutlet with existing member                                                        
    **/
    @isTest
    public static void createTerritoryOutletWithMemberTest(){
        test.startTest();
        List<String> lstAccount = new List<String>();
        
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Account objAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        objAccount1.Name = 'Test 1';
        objAccount1.Status__c = 'Active';
        insert objAccount1;
        
        lstAccount.add(objAccount.Id);
        lstAccount.add(objAccount1.Id);
        
        Territory__c objTarget = EDGE_UtilityTestClass.getTerritoryRec();
        objTarget.Country__c = geographyID;
        objTarget.Territory_Type__c = 'Sales';
        insert objTarget;
        
        Outlet_Territory__c objTerritoryOutlet = EDGE_UtilityTestClass.getOutltTerritory(objAccount.Id,objTarget.Id);
        insert objTerritoryOutlet;
        
        Map<String,List<String>> isSuccess;
        isSuccess = EDGE_SearchOutletForTL.createTerritoryOutlet(lstAccount, objTarget.Id);
        test.stopTest();
    } 
    
    /**
    * @Purpose: Test method to cover updateTLQuery method                                                        
    **/
    @isTest
    public static void updateTLQueryTest(){
        
       // List<String> lstAccount = new List<String>();
        
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getOutletRecord();
        objAccount.Status__c = 'Active';
        insert objAccount; 
        System.assertEquals(objAccount.Name, 'Test_Outlet','objAccount should match');
        
        Target_List__c objTarget = EDGE_UtilityTestClass.getTargetList(geographyID);
        //objTarget.Country__c = geographyID;
        insert objTarget;
        
        String queryString = ' OR Name Like \'Test_Outlet%\'';
        test.startTest();
        Map<String,String> isSuccess;
        isSuccess = EDGE_SearchOutletForTL.updateTLQuery(objTarget.Id, queryString);
        test.stopTest();
    }
    
    /**
    * @Purpose: Test method to cover searchDistributorDetails                                                         
    **/
    @isTest
    public static void searchDistributorDetailsTest(){ 
          
      //  Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getDistriAccRec();
        objAccount.Status__c = 'Active';
        //objAccount.Country__c = geographyID;
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test Distributor Account','objAccount should match');
        
        Promotion_Master__c objPromotion = new Promotion_Master__c();
       
        objPromotion.Name = 'Test Promotion';
        objPromotion.Start_Date__c = system.today();
        objPromotion.End_Date__c = system.today();
        objPromotion.Description__c = 'Test';
        insert objPromotion;
        System.assertEquals(objPromotion.Name, 'Test Promotion','objPromotion should match');
        
        Promotion_Supplier__c objPS = new Promotion_Supplier__c();
        objPS.Promotion__c = objPromotion.Id;
        objPS.Supplier__c = objAccount.Id;
        insert objPS;
        
        String queryString = ' OR Name Like \'Test Distributor Account%\'';
        test.startTest();
        EDGE_SearchOutletForTL.searchOutletDetails(queryString, objPromotion.Id);  
        test.stopTest();
    }  
     /**
    * @Purpose: Test method to cover createPromotionSupplier                                                        
    **/
    @isTest
    public static void createSupplierOutletTest(){
        
        List<String> lstAccount = new List<String>();
        
      //  Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        Account objAccount = EDGE_UtilityTestClass.getDistriAccRec();
        objAccount.Status__c = 'Active';
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test Distributor Account','objAccount should match');
        
        Account objAccount1 = EDGE_UtilityTestClass.getDistriAccRec();
        objAccount1.Name = 'Test 1';
        objAccount1.Status__c = 'Active';
        insert objAccount1;
        System.assertEquals(objAccount1.Name, 'Test 1','objAccount1 should match');
        
        lstAccount.add(objAccount.Id);
        lstAccount.add(objAccount1.Id);
        
        Promotion_Master__c objPromotion = new Promotion_Master__c();
        
        objPromotion.Name = 'Test Promotion';
        objPromotion.Start_Date__c = system.today();
        objPromotion.End_Date__c = system.today();
        objPromotion.Description__c = 'Test';
        insert objPromotion;
        test.startTest();
        Map<String,String> isSuccess;
        isSuccess = EDGE_SearchOutletForTL.createPromotionSupplier(lstAccount, objPromotion.Id);
        test.stopTest();
    }
    
}