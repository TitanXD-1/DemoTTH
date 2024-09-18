/**
Class Name: ECM_OutletExecutionProcessBatchTest
Author                  Version    Date           Detail
Joshraj Sen/Sakshi Shan V3.0  01/04/2024  152305 SCA Violation Reduction
*/
@isTest
public class ECM_OutletExecutionProcessBatchTest {
    static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
     static Id defaulttypeRecTypeId = mapPickupoptionRecordTypes.get('Default Pickup').getRecordTypeId();
     static String productRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
     static String outletExecutionMASRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    static Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    static Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
    static Account acc =new Account();
    @isTest
    public static void checkForDataAndProcess () {
        List<Product__c> productList = new List<Product__c>();
        //Id geographyId = EDGE_UtilityTestClass.setupCountryIreland('IE');
        List<User> salesRepList = new  List<User>();
        salesRepList = ECM_OutletExecutionProcessBatchTest.getSalesRepList();
        acc =ECM_OutletExecutionProcessBatchTest.getAccounts();
        ECM_Contract_Type__c contractType = ECM_OutletExecutionProcessBatchTest.getContractType();
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting=ECM_OutletExecutionProcessBatchTest.getOrgSetting();
        Contract objContract = ECM_OutletExecutionProcessBatchTest.getObjContract(acc);
        //List<Contract> conList = new List<Contract>();
        ECM_Payment_Summary__c paysumm = new ECM_Payment_Summary__c();
        paysumm=ECM_OutletExecutionProcessBatchTest.getPaySumm(objContract);
        Contract contr = ECM_OutletExecutionProcessBatchTest.getContr(contractType,salesRepList,objContract);
        List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
        outletContractList = ECM_OutletExecutionProcessBatchTest.getOutletContractList(acc,contr);
        productList = ECM_OutletExecutionProcessBatchTest.getProductList();  
        List<Market_Assortment_Product__c> mapList = new List<Market_Assortment_Product__c>();
        mapList = ECM_OutletExecutionProcessBatchTest.getMapList(productList,salesRepList);        
        Test.startTest();
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        conItemList = ECM_OutletExecutionProcessBatchTest.getConItemList(contr,mapList);    
        Outlet_Execution__c oe = new Outlet_Execution__c();
        oe = ECM_OutletExecutionProcessBatchTest.getOE(acc,productList); 
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_OutletExecutionProcessBatch' AND Country_Code__c ='GB' ];
        String className = batchSetting.Batch_Class__c;
        system.debug(LoggingLevel.Debug,'GEOGRAPHY--'+[Select Id, Name, Code__c  From Geography__c]);
        batchSetting.Region__c = 'Europe and Turkey';
        batchSetting.Country_Code__c='GB';
        system.debug(LoggingLevel.Debug,'OE ====>'+[SELECT Id,Outlet__c,Outlet__r.Latest_Date_Of_Execution_Activation__c,Outlet__r.Latest_Date_Of_Execution_Product__c,Product__c,Date_of_Execution__c, Latest_Entry__c, RecordTypeId, Activation_Reference__c, Outlet__r.Country__r.Code__c FROM Outlet_Execution__c]);
        system.debug(LoggingLevel.Debug,'Outlet__c ====>'+[SELECT Id,Latest_Date_Of_Execution_Activation__c, Country__c, Country__r.Code__c FROM Account]);
        system.debug(LoggingLevel.Debug,'Country====>'+[SELECT Id,name, Code__c FROM Geography__c]);
        system.debug(LoggingLevel.Debug,'Outlet_Contract__c --'+[SELECT Id,Outlet__c,Contract__c,Contract__r.Status, Contract__r.AccountId,Contract__r.RecordTypeId, Contract__r.StartDate,Contract__r.Contract_End_Date__c FROM Outlet_Contract__c ]);
        system.debug(LoggingLevel.Debug,'System.Label.ECM_DistributionAchieved_ContractStatus--'  +System.Label.ECM_DistributionAchieved_ContractStatus+' =contr---'+[Select Id, Name, Status, RecordTypeId From Contract  Where Id =: contr.Id ]);
        System.assert(className!=null,'class Name should not be null');
        system.assertNotEquals(batchSetting,null,'BatchSetting is Null');
            Type t  = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            system.debug(LoggingLevel.Debug,'batchSetting--'+batchSetting);
            system.debug(LoggingLevel.Debug,'--t-- '+t+' --job--'+job);        
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));  
        test.stopTest();
    }
    /*
    public static void createData(){
        
        list<Outlet_Execution__c> oeList = new List<Outlet_Execution__c>();
        // create Geography record  
        Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();   
        
        Geography__c country = [SELECT Id, Code__c FROM Geography__c WHERE ID =:countryID LIMIT 1];
        
        //insert pickup option
        Pick_Up_Options__c pickUpVisit1 = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickUpVisit1.Name = 'Gold[AU]';
        insert pickUpVisit1;
        System.debug(LoggingLevel.DEBUG,'limita '+limits.getQueries());
        Pick_Up_Options__c pickUpVisit = new Pick_Up_Options__c();
        pickUpVisit.Name = 'Activation[AU]';
        pickUpVisit.Geography__c = country.Id;  
        pickUpVisit.RecordTypeId = defaulttypeRecTypeId;
        pickUpVisit.Type__c = 'MAS';
        pickUpVisit.Status__c ='Active'; 
        insert pickUpVisit;
        
        //create outlet record             
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Country__c = country.Id;
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =pickUpVisit1.Id;
        outletAccount.Latest_Date_Of_Execution_Product__c=Date.today().addDays(10);
        outletAccount.Latest_Date_Of_Execution_Activation__c=Date.today().addDays(10);
        outletAccount.Updated_Activation_Date_of_Execution__c=Date.today().addDays(10);
        outletAccount.Updated_Activation_Date_of_Execution__c=Date.today().addDays(10);
        insert outletAccount;
        Test.startTest();
        //create Product             
        Product__c testProd = EDGE_UtilityTestClass.getProd();
        testProd.Description__c='Johnny Walker';
        testProd.Type__c = 'Diageo Product';
        insert testProd;
        Outlet_Execution__c testOe = new Outlet_Execution__c();
        testOe.Product__c = testProd.id;
        testOe.Outlet__c = outletAccount.id;
        testOe.Date_of_Execution__c=Date.today().addDays(10);//Date.newInstance(2021, 02,15);
        testOe.RecordTypeId = productRecordTypeId;
        testOe.Latest_Entry__c=true;
        oeList.add(testOe);
        System.debug(LoggingLevel.DEBUG,'limitd '+limits.getQueries());
        Outlet_Execution__c testOe1 = new Outlet_Execution__c();
        testOe1.Product__c = testProd.id;
        testOe1.Outlet__c = outletAccount.id;
        testOe1.Date_of_Execution__c=Date.today();//Date.newInstance(2021, 02,16);
        testOe1.RecordTypeId = productRecordTypeId;
        testOe1.Latest_Entry__c=true;
        oeList.add(testOe1);
        Outlet_Execution__c testOe2 = new Outlet_Execution__c();
        testOe2.Activation_Reference__c = pickUpVisit.Name.substringBefore('[');
        testOe2.Outlet__c = outletAccount.id;
        testOe2.Date_of_Execution__c=Date.today().addDays(10);//Date.newInstance(2021, 02,15);
        testOe2.RecordTypeId = outletExecutionMASRecordTypeId;
        oeList.add(testOe2);
        Outlet_Execution__c testOe3 = new Outlet_Execution__c();
        testOe3.Activation_Reference__c = pickUpVisit.Name.substringBefore('[');
        testOe3.Outlet__c = outletAccount.id;
        testOe3.Date_of_Execution__c=Date.today();//Date.newInstance(2021, 02,16);
        testOe3.RecordTypeId = outletExecutionMASRecordTypeId;
        oeList.add(testOe3);             
        insert oeList;
        Test.stopTest(); 
        
    }*/
      public static List<User> getSalesRepList(){
             List<User> salesRepList = new  List<User>();
              User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
              salesRep.Username = 'salesRp1234@test.com';
              salesRep.Available_Countries__c = 'GB';
              salesRepList.add(salesRep);
              User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
              salesRep1.Username = 'salesRp12345@test.com';
              salesRep.Available_Countries__c = 'GB';
              salesRepList.add(salesRep1);
              insert salesRepList;
              return salesRepList;
        }
          public static Account getAccounts(){  
             Account acc=EDGE_UtilityTestClass.getOutletRecord();
             acc.Sales_Org__c ='GB01';
             acc.SAP_Sold_to__c ='sapsold';
             acc.Country__c = geographyId;
            insert acc;
            return acc;  
        }
        public static ECM_Contract_Type__c getContractType(){
             ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
             contractType.ECM_Enable_Recall_of_Contract__c=False;
             insert contractType;
             return contractType;
        }
        public static Org_Setting__c getOrgSetting(){
           Org_Setting__c orgSetting = new Org_Setting__c();
           orgSetting.Run_Triggers__c = true;
           insert orgSetting;
           return orgSetting;
        }
        public static Contract getObjContract(Account acc){
            Contract objContract = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);
            insert objContract;
            objContract.Status = 'Active';
            update objContract;
            return objContract;
        }
        public static ECM_Payment_Summary__c getPaySumm(Contract objContract){
            ECM_Payment_Summary__c paysumm = ECM_UtilityTestClass.getPaymentSummary(objContract.Id);
            paysumm.ECM_Payment_Summary_Status__c = 'Open';
            insert paysumm;
            return paysumm;
        }
        public static Contract getContr(ECM_Contract_Type__c contractType,List<User> salesRepList,Contract objContract)
        {
             Id outletRecordTypeId=Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
             Contract contr = ECM_UtilityTestClass.createContract(acc.Id,outletRecordTypeId);        
             contr.ECM_Agreement_Type__c = contractType.Id;
             contr.ownerId = salesRepList[1].Id;
             contr.Status = 'Draft';
             contr.StartDate = System.today();
             contr.Contract_End_Date__c = System.today().adddays(20);
             contr.ECM_Parent_Contract__c = objContract.Id;
             contr.ECM_Amended__c = true;
             insert contr;
             contr.Status = 'Active';
             update contr;
             return contr;
        }
        public static List<Outlet_Contract__c> getOutletContractList(Account acc,Contract contr){
             List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
            for(Integer i=0;i<2;i++){
            Outlet_Contract__c outletContract = new Outlet_Contract__c();
            outletContract.Contract__c = contr.Id;
            outletContract.Outlet__c = acc.Id;
            outletContract.Status__c ='Active';
            outletContractList.add(outletContract);
        }
            Insert outletContractList;
            return outletContractList;
        }
        public static List<Product__c> getProductList(){
            List<Product__c> productList = new List<Product__c>();
             //create product
            Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
            product.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
            product.Product_Full_Name__c='Test';
            insert product;
            
              //create product
            Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
            product1.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Item').getRecordTypeId();
            product1.Brand_Varient__c = product.Id;
            product1.Product_Full_Name__c='Test 2';
            insert product1;
            //productList.add(product1);
               //create product
            Product__c product2 = ECM_UtilityTestClass.createProduct(geographyId,'Test 3');
            product2.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('CRI').getRecordTypeId();
            product2.Product_Full_Name__c='Test 3';
            product2.Item__c = product1.Id;
            productList.add(product2);
                //create product
            Product__c product3 = ECM_UtilityTestClass.createProduct(geographyId,'Test 4');
            product3.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            product3.Brand_Varient__c = product.Id;
            product3.Item__c = product1.Id;
            product3.CRI__c = product2.Id;
            product3.Product_Full_Name__c='Test 4';
            //insert product3;
            productList.add(product3);
            insert  productList; 
            productList.add(product);
            productList.add(product1);
            return productList;
        }
           public static List<Market_Assortment_Product__c> getMapList(List<Product__c> productList,List<User> salesRepList){
             //create marketassort product
            List<Market_Assortment_Product__c> mapList = new List<Market_Assortment_Product__c>();
             Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(productList[0].Id,geographyId);
            marketassort.OwnerId = salesRepList[1].Id;
            //insert marketassort;
            mapList.add(marketassort);
            //create marketassort product 
            Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(productList[1].Id,geographyId);
            marketassort1.OwnerId = salesRepList[1].Id;
            //insert marketassort1;
            mapList.add(marketassort1);
            insert mapList;
            return mapList;
        }
        
        public static List<ECM_Contract_Item__c> getConItemList(Contract contr,List<Market_Assortment_Product__c> mapList){
            //create Contract_Item
                List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
                ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(contr.Id,mapList[0].id);
                newcontractitem.ECM_UoM__c = '1';
                newcontractitem.ECM_Lead_Brand__c = TRUE;
                newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
                newcontractitem.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
                newcontractitem.ECM_CTD_Trade_Lump_Sum__c = 20;
                newcontractitem.ECM_CTD_Overall_Investment__c = 30;
                //insert newcontractitem;
                conItemList.add(newcontractitem);
                //create Contract_Item
                ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(contr.Id,mapList[1].id);
                newcontractitem1.ECM_UoM__c = '1';
                newcontractitem1.ECM_Lead_Brand__c = false;
                newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
                newcontractitem1.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
                newcontractitem1.ECM_CTD_Trade_Lump_Sum__c = 20;
                newcontractitem1.ECM_CTD_Overall_Investment__c = 30;
                //insert newcontractitem1;
                conItemList.add(newcontractitem1);
                Insert conItemList;
                return conItemList;
        }
            public static Outlet_Execution__c getOE(Account acc,List<Product__c> productList){
            Outlet_Execution__c oe = new Outlet_Execution__c();
            oe.Outlet__c =  acc.Id;
            oe.Product__c = productList[2].Id;
            oe.Distribution_TRAX__c='Yes';
            oe.RecordTypeId = Schema.SObjectType.Outlet_Execution__c.getRecordTypeInfosByName().get(System.Label.ECM_OutletExecution_ProductRecordType).getRecordTypeId();
            //OE.Date_of_Execution__c = System.today().addDays(1);
            oe.Date_of_Execution__c = System.today().adddays(2);
            insert oe;
            return oe;
        }

    
}