/*
Test class Name: ECM_AccrualItemsCalculation_Batch_Test

Req: This test class is used for code coverage ECM_AccrualItemsCalculation_Batch  .
History                                                                                                                       
VERSION        AUTHOR                              DATE              DETAIL
1.0            Veerendra Billakurthi               10/02/2021        ECM-3888 - Batch for Calculating Accrual Items for A&P and TI Sales drivers_SFDC_US3_Accrual
2.0	           Suvendu Roy & Sagnik Sanyal		   06/06/2024		 153434 - For contacts moving from New to Old Logic_SFDC
*/

@istest
public class ECM_AccrualforAnP_TI_RetroBatch_Test {
    @isTest
    public static void accrualItemsCal(){
        Test.startTest();
        testAccrualInsertion();
        try{  
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_AccrualforAnP_TI_RetroBatch'
                                                      and Country_Code__c ='IE' ];
            
            
            String className = batchSetting.Batch_Class__c;   
            System.assert(className!=null,'className should not be null');   
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
            
            /*Market_Batch_Setting__mdt deleteBatchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_DeleteAccrualItemsBatch'
                                                      and Country_Code__c ='IE' ];
            
            
            String deleteClassName = deleteBatchSetting.Batch_Class__c;   
            System.assert(deleteClassName!=null,'deleteClassName should not be null');   
            Type deleteType = Type.forName(deleteClassName); 
            BatchJobManagementInterfaceClass deleteJob = (BatchJobManagementInterfaceClass)deleteType.newInstance();
            deleteJob.getBatchDetails(deleteBatchSetting);
            Database.executeBatch((Database.Batchable<SObject>)deleteJob,integer.valueOf(deleteBatchSetting.Scope__c));*/
            
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
            
            
        }
        Test.stopTest();
    }
    static @isTest void testAccrualInsertion(){
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractRecordTypeIdGroup = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountryPL('IE');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        system.assert(newuser.Id != null,'newuser Id should not be null');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Rate Per UoM;Investment';
        insert contractType;
        
        ECM_Payment_Frequency__c paymentFrequency=new ECM_Payment_Frequency__c();
        paymentFrequency.ECM_Geography__c=geographyId;
        paymentFrequency.ECM_Type__c='Equal Instalments';
        paymentFrequency.ECM_Other_Investment__c=true;
        insert paymentFrequency;
        
        ECM_Payment_Agreement__c paymentAgreement= new ECM_Payment_Agreement__c();
        paymentAgreement.ECM_Agreement_Type__c=contractType.Id;
        paymentAgreement.ECM_Payment_Frequency__c=paymentFrequency.id;
        
        insert paymentAgreement;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1_new2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep; 
        
        User cIOuser = EDGE_UtilityTestClass.runAsUser('salesRep1_new','CIO User');
        cIOuser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cIOuser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Account acc1 = EDGE_UtilityTestClass.getOutletRecord();
        acc1.Name = 'Test_Outlet_1';
        insert acc1;
        
        Account acc2 = EDGE_UtilityTestClass.getOutletRecord();
        acc2.Name = 'Test_Outlet_2';
        insert acc2;
        
        Account acc3 = EDGE_UtilityTestClass.getOutletRecord();
        acc3.Name = 'Test_Outlet_3';
        insert acc3;
        
        Account acc4 = EDGE_UtilityTestClass.getOutletRecord(); 
        acc4.Name = 'Test_Outlet_4';
        insert acc4;
        
        Account acc5 = EDGE_UtilityTestClass.getOutletRecord(); 
        acc5.RecordTypeId=Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        acc5.Name = 'Test_Operator_1';
        insert acc5;
        
        Date myDate = system.today().addmonths(6);
        Date myStartDate = system.today().addmonths(-6);
        
        Contract con1 = new Contract(Name = 'Test',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId=acc5.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeIdGroup,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con1;
        
        Contract con2 = new Contract(Name = 'Test2',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc3.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con2;
        
        Contract con3 = new Contract(Name = 'Test3',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc4.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con3;
        
        Date today = Date.today();
        Integer currentYear = today.year();
        Integer currentMonth = today.month();
        String fiscalYear = String.valueOf(currentMonth < 7 ? currentYear : currentYear+1);
        String fiscalPeriod ='P'+ String.valueOf(Math.mod((currentMonth - 7 + 12), 12) + 1);
        ECM_Accrual__c accrual1 = new ECM_Accrual__c(ECM_Contract__c = con1.Id, ECM_Period__c= fiscalPeriod, ECM_Fiscal_Year__c=fiscalYear);
        insert accrual1;

        fiscalYear = String.valueOf(currentMonth < 7 ? currentYear+1 : currentYear+2);        
        ECM_Accrual__c accrual2 = new ECM_Accrual__c(ECM_Contract__c = con1.Id, ECM_Period__c= fiscalPeriod, ECM_Fiscal_Year__c=fiscalYear);
        insert accrual2;
        
        con1.Status='Active';
        update con1;
        
        con2.Status='Active';
        update con2;
        
        con3.Status='Active';
        update con3;
        
        Outlet_Contract__c outlet1= new Outlet_Contract__c();
        outlet1.Outlet__c=acc.id;
        outlet1.Contract__c=con1.id;
        insert outlet1;
        
        Outlet_Contract__c outlet2= new Outlet_Contract__c();
        outlet2.Outlet__c=acc1.id;
        outlet2.Contract__c=con1.id;
        insert outlet2;
        
        Outlet_Contract__c outlet3= new Outlet_Contract__c();
        outlet3.Outlet__c=acc2.id;
        outlet3.Contract__c=con1.id;
        insert outlet3;
        
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = geographyId;
        pOption.type__c = 'Local-Segment1';
        pOption.RecordTypeId = pickupRecordTypeId;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        insert pOption;
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name='A&P [IE]';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.Status__c = 'Active';
        budgetTypeObj1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        insert budgetTypeObj1;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='TI [IE]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y20'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'y30';
        insert budgetTypeObj2;
        
        Product__c product1 = new Product__c();
        product1.Product_Full_Name__c='Product 1';
        product1.Country__c=geographyId;
        insert product1;
        
        Product__c product2 = new Product__c();
        product2.Product_Full_Name__c='Product 2';
        product2.Country__c=geographyId;
        insert product2;
        
        Product__c product3 = new Product__c();
        product3.Product_Full_Name__c='Product 3';
        product3.Country__c=geographyId;
        insert product3;
        
        Product__c product4 = new Product__c();
        product4.Product_Full_Name__c='Product 4';
        product4.Country__c=geographyId;
        insert product4;
        
        Market_Assortment_Product__c marketproduct= new Market_Assortment_Product__c();
        marketproduct.Product__c=product1.id;
        insert marketproduct;
        
        Market_Assortment_Product__c marketproduct2= new Market_Assortment_Product__c();
        marketproduct2.Product__c=product2.id;
        insert marketproduct2;
        
        Market_Assortment_Product__c marketproduct3= new Market_Assortment_Product__c();
        marketproduct3.Product__c=product3.id;
        insert marketproduct3;
        
        Market_Assortment_Product__c marketproduct4= new Market_Assortment_Product__c();
        marketproduct4.Product__c=product4.id;
        insert marketproduct4;
        
        ECM_Contract_Item__c eCI = new ECM_Contract_Item__c();
        eCI.ECM_MAT_override__c = 20.00;
        eCI.ECM_Contract__c = con1.id;
        eCI.ECM_MAT_UOS__c = 20.00;
        eCI.ECM_Total_GP__c = 20.00;
        eCI.ECM_Total_COGS__c = 20.00;
        eCI.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eCI.ECM_Total_GP_ON__c = 20.00;
        eCI.ECM_Product__c=marketproduct.id;       
        insert eCI;
        
        ECM_Contract_Item__c eCI2 = new ECM_Contract_Item__c();
        eCI2.ECM_MAT_override__c = 20.00;
        eCI2.ECM_Contract__c = con1.id;
        eCI2.ECM_MAT_UOS__c = 20.00;
        eCI2.ECM_Total_GP__c = 20.00;
        eCI2.ECM_Total_COGS__c = 20.00;
        eCI2.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI2.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI2.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eCI2.ECM_Total_GP_ON__c = 20.00;
        eCI2.ECM_Product__c=marketproduct2.id;       
        insert eCI2;
        
        ECM_Contract_Item__c eCI3 = new ECM_Contract_Item__c();
        eCI3.ECM_MAT_override__c = 20.00;
        eCI3.ECM_Contract__c = con2.id;
        eCI3.ECM_MAT_UOS__c = 20.00;
        eCI3.ECM_Total_GP__c = 20.00;
        eCI3.ECM_Total_COGS__c = 20.00;
        eCI3.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI3.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI3.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eCI3.ECM_Total_GP_ON__c = 20.00;
        eCI3.ECM_Product__c=marketproduct3.id;       
        insert eCI3;
        
        ECM_Contract_Item__c eCI4 = new ECM_Contract_Item__c();
        eCI4.ECM_MAT_override__c = 20.00;
        eCI4.ECM_Investment__c=10;
        eCI4.ECM_UoM__c='8.20';
        eCI4.ECM_Volume__c=10;
        eCI4.ECM_Contract__c = con3.id;
        eCI4.ECM_MAT_UOS__c = 20.00;
        eCI4.ECM_Total_GP__c = 20.00;
        eCI4.ECM_Total_COGS__c = 20.00;
        eCI4.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI4.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI4.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eCI4.ECM_Total_GP_ON__c = 20.00;
        eCI4.ECM_Product__c=marketproduct4.id;       
        insert eCI4;
        Market_Setting__c market= new Market_Setting__c();
        market.Name='Australia';
        market.Accrual_Creation__c ='Whole Numbers';
        market.ECM_Change_in_Accrual_Logic__c=true;
        market.Geography__c=geographyId;
        market.ECM_Budget_Type_for_Volume_Based_PS__c=pOption.id;
        market.ECM_Tiering_consideration_for_Accrual__c='Tier 2';
        insert market;
        
        //ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(eCI.Id, 10, 1, 20, 2, 30, 3);
        
        ECM_Sales_Driver__c sD = new ECM_Sales_Driver__c();
        sD.Name='test';
        sD.Geography__c=geographyId;
        sD.ECM_Budget_Type__c=budgetTypeObj2.Id;
        insert sD;
        
        ECM_Sales_Driver__c sD1 = new ECM_Sales_Driver__c();
        sD1.Name='test';
        sD1.Geography__c=geographyId;
        sD1.ECM_Budget_Type__c=pOption.Id;
        insert sD1;
        
        
        ECM_Sales_Driver_Item__c sDI = new ECM_Sales_Driver_Item__c();
        sDI.Contract__c= con3.Id;
        sDI.ECM_Sales_Driver__c=SD.Id;
        sDI.ECM_Payment_Frequency__c=paymentFrequency.Id;
        sDI.ECM_Investement_Description__c='TEST';
        insert sDI;
        
        ECM_Sales_Driver_Item__c sDI1 = new ECM_Sales_Driver_Item__c();
        sDI1.Contract__c= con3.Id;
        sDI1.ECM_Sales_Driver__c=SD1.Id;
        sDI1.ECM_Payment_Frequency__c=paymentFrequency.Id;
        sDI1.ECM_Investement_Description__c='TEST';
        insert sDI1;
        
        ECM_Sales_Driver_Item_Detail__c sDID = new ECM_Sales_Driver_Item_Detail__c();
        sDID.ECM_Investment_Amount__c=100;
        sDID.ECM_Sales_Driver_Item__c=SDI.id;
        sDID.ECM_Product__c=eCI4.id;
        sDID.ECM_Contract__c=con3.Id;
        insert sDID;
        
        ECM_Sales_Driver_Item_Detail__c sDID1 = new ECM_Sales_Driver_Item_Detail__c();
        sDID1.ECM_Investment_Amount__c=100;
        sDID1.ECM_Sales_Driver_Item__c=SDI1.id;
        sDID1.ECM_Product__c=eCI.id;
        sDID1.ECM_Contract__c=con3.Id;
        insert sDID1;
        
        ECM_Accrual_Period__c accrualPeriod= new ECM_Accrual_Period__c();
        accrualPeriod.ECM_Start_Date__c=System.today().tostartofMonth().addmonths(-3);
        accrualPeriod.ECM_End_Date__c=System.today().tostartofMonth().addmonths(-2);
        accrualPeriod.ECM_Execution_Month__c='6';
        accrualPeriod.ECM_Payment_Calculation_Date__c=System.today();
        accrualPeriod.Period__c='P3';
        accrualPeriod.Name='Test';
        accrualPeriod.ECM_Market_Setting__c=market.id;
        insert accrualPeriod;
        
        ECM_Accrual_Period__c accrualPeriod2= new ECM_Accrual_Period__c();
        accrualPeriod2.ECM_Start_Date__c=System.today().tostartofMonth();
        accrualPeriod2.ECM_End_Date__c=System.today().tostartofMonth().addmonths(1);
        accrualPeriod2.ECM_Execution_Month__c='6';
        accrualPeriod2.ECM_Payment_Calculation_Date__c=System.today();
        accrualPeriod2.Period__c='P6';
        accrualPeriod2.Name='Test';
        accrualPeriod2.ECM_Market_Setting__c=market.id;
        insert accrualPeriod2;
        
        ECM_Accrual_Period__c accrualPeriodForecast= new ECM_Accrual_Period__c();
        accrualPeriodForecast.ECM_Start_Date__c=System.today().tostartofMonth().addmonths(-3).addYears(-1);
        accrualPeriodForecast.ECM_End_Date__c=System.today().tostartofMonth().addmonths(-2).addYears(-1);
        accrualPeriodForecast.ECM_Execution_Month__c='6';
        accrualPeriodForecast.ECM_Payment_Calculation_Date__c=System.today();
        accrualPeriodForecast.Period__c='P6F';
        accrualPeriodForecast.ECM_Is_Forecast__c=true;
        accrualPeriodForecast.Name='Test';
        accrualPeriodForecast.ECM_Market_Setting__c=market.id;
        insert accrualPeriodForecast;
        
        ECM_Internal_Order__c iO= new ECM_Internal_Order__c();
        iO.Name='SampleTest12';
        iO.ECM_Active__c= true;
        iO.ECM_End_Date__c=System.today().tostartofMonth().addmonths(-2);
        iO.ECM_Start_Date__c=System.today().tostartofMonth().addmonths(-3);
        iO.ECM_Geography__c=geographyId;
        iO.ECM_Product__c=product1.id;
        iO.ECM_Fiscal_Year__c='FY'+string.valueof(System.today().year()).right(2);
        iO.ECM_Budget_Type_Pickup_Option__c=pOption.id;
        iO.ECM_Description__c='Sample Test';
        insert iO;
        
        Depletions__c d= new Depletions__c();
        d.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
        d.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
        d.ECM_Product__c=product1.id;
        d.ECM_Outlet__c=acc.id;
        d.ECM_Volume__c=15;
        d.ECM_Geography__c=geographyId;
        d.Forecast_Volume__c=20;
        d.Contract__c=con1.id;
        insert d;
        
        Depletions__c d1= new Depletions__c();
        d1.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
        d1.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
        d1.ECM_Product__c=product2.id;
        d1.ECM_Outlet__c=acc.id;
        d1.ECM_Volume__c=12;
        d1.ECM_Geography__c=geographyId;
        d1.Forecast_Volume__c=15;
        d1.Contract__c=con2.id;
        insert d1;
        
        Depletions__c d2= new Depletions__c();
        d2.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
        d2.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
        d2.ECM_Product__c=product1.id;
        d2.ECM_Outlet__c=acc1.id;
        d2.ECM_Volume__c=12;
        d2.ECM_Geography__c=geographyId;
        d2.Forecast_Volume__c=20;
        d2.Contract__c=con3.id;
        insert d2;
        
        
        Depletions__c d3= new Depletions__c();
        d3.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
        d3.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
        d3.ECM_Product__c=product2.id;
        d3.ECM_Outlet__c=acc1.id;
        d3.ECM_Volume__c=12;
        d3.ECM_Geography__c=geographyId;
        d3.Forecast_Volume__c=20;
        d3.Contract__c=con1.id;
        insert d3;
        
        
        Depletions__c d4= new Depletions__c();
        d4.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
        d4.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
        d4.ECM_Product__c=product1.id;
        d4.ECM_Outlet__c=acc2.id;
        d4.ECM_Volume__c=12;
        d4.ECM_Geography__c=geographyId;
        d4.Forecast_Volume__c=20;
        d4.Contract__c=con2.id;
        insert d4;  
        
        Depletions__c d5= new Depletions__c();
        d5.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
        d5.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
        d5.ECM_Product__c=product2.id;
        d5.ECM_Outlet__c=acc2.id;
        d5.ECM_Volume__c=12;
        d5.ECM_Geography__c=geographyId;
        d5.Forecast_Volume__c=20;
        d5.Contract__c=con3.id;
        insert d5; 
        
        Depletions__c d6= new Depletions__c();
        d6.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
        d6.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
        d6.ECM_Product__c=product3.id;
        d6.ECM_Outlet__c=acc3.id;
        d6.ECM_Volume__c=12;
        d6.ECM_Geography__c=geographyId;
        d6.Forecast_Volume__c=20;
        d6.Contract__c=con1.id;
        insert d6; 
        
        
    }
    
}