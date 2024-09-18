/*
* @Name: EDGE_OutletExeHistoricKPIBatchTest
* @Req: 
* @User Story : 
* @History                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Juned Khan        13/11/2019        Initial Development
*  1.1       Prasanth T        23/09/2022        Test Class Correction Due to Failure(ES20-13324)
*  1.2       Wribhu Bose       12/12/2022        Coverage for ECM_GroupContractOEHistoricKPIBatch
*  1.3       Sakshi Shah       22/08/2024        PMD Fix
*/

@isTest
public class EDGE_OutletExeHistoricKPIBatchTest {
    @isTest
    public static void testOutletExecutionsHistoricBatch(){
       
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OutletExecutionsHistoricKPIBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        //EDGE_OutletExecutionsHistoricKPIBatch obj = new EDGE_OutletExecutionsHistoricKPIBatch();
        // DataBase.executeBatch(obj); 
        Type t = Type.forName(className);
        System.assert(batchSetting.Id!=Null,'Batch Setting id should not be null.');
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    @isTest
    public static void testECMGroupContractOEHistoricKPIBatch(){
       
        createDataGroup();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_GroupContractOEHistoricKPIBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        //EDGE_OutletExecutionsHistoricKPIBatch obj = new EDGE_OutletExecutionsHistoricKPIBatch();
        // DataBase.executeBatch(obj); 
        Type t = Type.forName(className);
        System.assert(batchSetting.Id!=Null,'Batch Setting Id should not be null.');
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    /**
 * @description method Create Data
 */
    public static void createData(){
        
        // create Geography record  
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
        //insert pickup option
        Pick_Up_Options__c pickUpVisit = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickUpVisit.Name = 'Gold[AU]';
        insert pickUpVisit;
        
        //Geography__c country = [SELECT Id, Code__c FROM Geography__c WHERE ID =:countryID LIMIT 1];
        //create outlet record             
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =pickUpVisit.Id;
        outletAccount.Last_Update_TRAX__c = Date.today();
        outletAccount.Country__c = countryId;
        outletAccount.Date_of_Execution__c= Date.today();
        outletAccount.Outlet_Execution_Score__c=100.00;
        outletAccount.Distribution__c= 96.00;
        outletAccount.Minimum_Activation_Standards__c=100.00;
        outletAccount.Minimum_Product_Assortment__c=87.00;
        outletAccount.New_Product_Distribution__c=99.00;
        insert outletAccount;
        
        //Create Outlet_Execution_Historic__c Record
        Test.startTest();
        Outlet_Execution_Historic__c ohe= new Outlet_Execution_Historic__c();
        ohe.RecordTypeId=Schema.SObjectType.Outlet_Execution_Historic__c.getRecordTypeInfosByDeveloperName().get('Outlet_KPI').getRecordTypeId();
        ohe.Outlet__c= outletAccount.Id;
        ohe.Date_of_Execution__c = Date.today();
        ohe.Distribution__c = outletAccount.Distribution__c;
        ohe.Minimum_Activation_Standards__c = outletAccount.Minimum_Activation_Standards__c;
        ohe.Minimum_Product_Assortment__c = outletAccount.Minimum_Product_Assortment__c;
        ohe.New_Product_Distribution__c = outletAccount.New_Product_Distribution__c;
        ohe.Outlet_Execution_Score__c = outletAccount.Outlet_Execution_Score__c;
        insert ohe;
        System.assert(ohe.Id!=Null,'Outlet Excecution Historic id should not be null.');
        Test.stopTest();
    }
    /**
 * @description method Create Data Group
 */
    public static void createDataGroup(){
         EDGE_UtilityTestClass.createOrgSettings();
        // create Geography record  
        Id countryID = EDGE_UtilityTestClass.setupCountry('AU');
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        //insert pickup option
        Pick_Up_Options__c pickUpVisit = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickUpVisit.Name = 'Gold[AU]';
        insert pickUpVisit;
        
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'AU';
        insert testSysAdminUser;
        
         user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','Sales Representative');
        newuser.Email = userInfo.getUserEmail();
        newuser.Available_Countries__c ='AU';
        newuser.ManagerId =testSysAdminUser.Id;
        insert newuser;
        
        Geography__c country = [SELECT Id, Code__c FROM Geography__c WHERE ID =:countryID LIMIT 1];
        
        //create operator record
        Test.startTest();             
        Account operatorAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operatorAccount.Country__c = country.Id;
        operatorAccount.IsOperator__c = true;
        operatorAccount.Person_Responsible__c = newuser.Id;
        insert operatorAccount;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =pickUpVisit.Id;
        outletAccount.Country__c = country.Id;
        outletAccount.Independent_of_Operator__c = false;
        outletAccount.Operator__c = operatorAccount.Id;
        insert outletAccount;
        
        //contract type rec
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(countryID);
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        contractType.ECM_Anniversary_Email_to_Customer__c = 'To Contract Owner & Line Mgr';
        insert contractType;
        
        //product record
        Product__c pdt = ECM_UtilityTestClass.createProduct(countryID,'Test Product');
        pdt.Product_Full_Name__c = 'Test Product';
        pdt.Category__c = 'Cocktails';
        pdt.Classification__c = 'RTD';
        insert pdt;
        
        //map record
        Market_Assortment_Product__c maPdt = ECM_UtilityTestClass.createMarketAssortmentProduct(pdt.id,countryID);
        insert maPdt;
        
        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(outletAccount.id,contractRecordTypeId);  
        contr.Status = 'Draft';
        contr.ECM_Duration__c = 37;
        Date dt = System.today().addMonths(1);
        contr.StartDate = dt.addMonths(-36);
        contr.ECM_Agreement_Type__c = contractType.Id;
        integer months = null;
        months = Integer.valueOF(contractType.ECM_Expiration_Start_Date_Rule_in_Months__c);
        contr.Contract_End_Date__c = contr.StartDate.addMonths(37);
        contr.ECM_Expiration_Notification_sent__c = false;
        contr.ownerId = newuser.Id;
        insert contr;
        
        contr.Status = 'Active';
        update contr;
        Test.stopTest();
        
        //createcontractitem
        ECM_Contract_Item__c contractItem = ECM_UtilityTestClass.createcontractitem(contr.id,maPdt.id);
        contractItem.ECM_Lead_Brand__c = true;
        contractItem.ECM_Product_growth_driver__c = 'Test Pouring';
        contractItem.ECM_Product__c=maPdt.Id;
        insert contractItem;
        
        Outlet_Contract__c oCC = new Outlet_Contract__c();
        oCC.Contract__c = contr.Id;
        oCC.Outlet__c = outletAccount.id;
        insert oCC;
        
        Integer month = Date.today().month();
        Integer year = Date.Today().Year();
        
        //Create Outlet_Execution_Historic__c Record
        Outlet_Execution_Historic__c ohe= new Outlet_Execution_Historic__c();
        ohe.RecordTypeId=Schema.SObjectType.Outlet_Execution_Historic__c.getRecordTypeInfosByDeveloperName().get('Outlet_KPI').getRecordTypeId();
        ohe.Outlet__c= operatorAccount.Id;
        ohe.Date_of_Execution__c = Date.today();
        ohe.Distribution__c = operatorAccount.Distribution__c;
        ohe.Minimum_Activation_Standards__c = operatorAccount.Minimum_Activation_Standards__c;
        ohe.Minimum_Product_Assortment__c = operatorAccount.Minimum_Product_Assortment__c;
        ohe.New_Product_Distribution__c = operatorAccount.New_Product_Distribution__c;
        ohe.Outlet_Execution_Score__c = operatorAccount.Outlet_Execution_Score__c;
        ohe.Unique_Id__c = String.valueOf(month)+String.valueOf(year)+outletAccount.Id;
        insert ohe;
        System.assert(ohe.Id!=Null,'Outlet Excecution Historic id should not be null.');
    }
   
}