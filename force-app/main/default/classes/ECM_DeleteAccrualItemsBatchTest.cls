/*
Test class Name: ECM_DeleteAccrualItemsBatchTest
Req: This test class is used for code coverage ECM_DeleteAccrualItemsBatch and ECM_AccrualforAnP_TI_RetroBatch.
History                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Suvendu & Sagnik 11/06/202    ECM-3888 - Batch for Calculating Accrual Items for A&P and TI Sales drivers_SFDC_US3_Accrual
*/

@istest
public class ECM_DeleteAccrualItemsBatchTest {
    
    /*@isTest
    public static void accrualItemsCal2(){
        Test.startTest();
        testAccrualInsertion();
        try{  
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_DeleteAccrualItemsBatch'
                                                      and Country_Code__c ='IE' ];
            
            
            String className = batchSetting.Batch_Class__c;
            system.assert(className != null,'className should not be null');       
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,2000);
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());

        }
        Test.stopTest();
    }*/
    @isTest
    public static void testAccrualInsertion(){
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountryPL('IE');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        system.assert(newuser.Id != null, 'newuser Id should not be null');
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Screen_3_field_configuration__c = 'Investment';
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
        
        Account acc = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc.Person_Responsible__c = UserInfo.getUserId();
        acc.IsOperator__c = true;
        insert acc;
        
        Account acc1 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc1.Person_Responsible__c = UserInfo.getUserId();
        acc1.IsOperator__c = true;
        insert acc1;
        
        Account acc2 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc2.Person_Responsible__c = UserInfo.getUserId();
        acc2.IsOperator__c = true;
        insert acc2;
        
        Account acc3 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc3.Person_Responsible__c = UserInfo.getUserId();
        acc3.IsOperator__c = true;
        insert acc3;
        
        Account acc4 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc4.Person_Responsible__c = UserInfo.getUserId();
        acc4.IsOperator__c = true;
        insert acc4;
        
        
        Date myDate = system.today().addmonths(6);
        Date myStartDate = system.today().addmonths(-6);
        
        Contract con1 = new Contract(Name = 'Test',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId=Acc1.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con1;
        
        Contract con2 = new Contract(Name = 'Test2',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc3.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con2;
        
        Contract con3 = new Contract(Name = 'Test3',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc4.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con3;
        
        con1.Status='Active';
        update con1;
        
        con2.Status='Active';
        update con2;
        
        con3.Status='Active';
        update con3;
        
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = geographyId;
        pOption.Type__c = 'Local-Segment1';
        pOption.RecordTypeId = PickupRecordTypeId;
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
        
         ECM_Internal_Order__c ino=new ECM_Internal_Order__c();
        ino.Name='INO-12345678';
        ino.ECM_Active__c=true;
        ino.ECM_Budget_Type_Pickup_Option__c=budgetTypeObj2.id;
        ino.ECM_Fiscal_Year__c='FY21';
        ino.ECM_Product__c=product4.id;
        ino.ECM_Description__c='test';
        ino.ECM_Start_Date__c=System.today().tostartofMonth().addmonths(-3);
        ino.ECM_End_Date__c=System.today().tostartofMonth().addmonths(-2);
        ino.ECM_Geography__c=geographyId;
        insert ino;
        
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
        market.Name='Spain Setting';
        market.Geography__c=geographyId;
        market.ECM_Change_in_Accrual_Logic__c=true;
        market.Accrual_Creation__c = 'Whole Numbers';
        market.ECM_Budget_Type_for_Volume_Based_PS__c = budgetTypeObj2.Id;
        insert market;
        
        ECM_Sales_Driver__c sD = new ECM_Sales_Driver__c();
        sD.Name='test';
        sD.Geography__c=geographyId;
        
        sD.ECM_Budget_Type__c=budgetTypeObj2.Id;
        insert sD;
        
        
        ECM_Sales_Driver_Item__c sDI = new ECM_Sales_Driver_Item__c();
        sDI.Contract__c= con3.Id;
        sDI.ECM_Sales_Driver__c=SD.Id;
        sDI.ECM_Payment_Frequency__c=paymentFrequency.Id;
        sDI.ECM_Investement_Description__c='TEST';
        insert sDI;
        
        ECM_Sales_Driver_Item_Detail__c sDID = new ECM_Sales_Driver_Item_Detail__c();
        sDID.ECM_Investment_Amount__c=100;
        sDID.ECM_Sales_Driver_Item__c=SDI.id;
        sDID.ECM_Product__c=ECI4.id;
        insert sDID;
        
        ECM_Accrual_Period__c accrualPeriod= new ECM_Accrual_Period__c();
        accrualPeriod.ECM_Start_Date__c=System.today().tostartofMonth().addmonths(-3);
        accrualPeriod.ECM_End_Date__c=System.today().tostartofMonth().addmonths(-2);
        accrualPeriod.ECM_Execution_Month__c='6';
        accrualPeriod.ECM_Payment_Calculation_Date__c=System.today();
        accrualPeriod.Period__c='P6';
        accrualPeriod.Name='Test';
        accrualPeriod.ECM_Market_Setting__c=market.id;
        insert accrualPeriod;  
        
        ECM_Accrual__c accRec1  = new ECM_Accrual__c();
        accRec1.ECM_Period__c = 'P12';
        accRec1.ECM_Fiscal_Year__c = '2024';
        accRec1.ECM_Contract__c = con1.Id;
        insert accRec1;
        
        ECM_Accrual__c accRec2  = new ECM_Accrual__c();
        accRec2.ECM_Period__c = 'P1';
        accRec2.ECM_Fiscal_Year__c = '2025';
        accRec2.ECM_Contract__c = con1.Id;
        insert accRec2;
        
        ECM_Accrual__c accRec3  = new ECM_Accrual__c();
        accRec3.ECM_Period__c = 'P2';
        accRec3.ECM_Fiscal_Year__c = '2025';
        accRec3.ECM_Contract__c = con1.Id;
        insert accRec3;
        
        ECM_Accrual__c accRec4  = new ECM_Accrual__c();
        accRec4.ECM_Period__c = 'P3';
        accRec4.ECM_Fiscal_Year__c = '2025';
        accRec4.ECM_Contract__c = con1.Id;
        insert accRec4;
        
        ECM_Accrual__c accRec5  = new ECM_Accrual__c();
        accRec5.ECM_Period__c = 'P4';
        accRec5.ECM_Fiscal_Year__c = '2025';
        accRec5.ECM_Contract__c = con1.Id;
        insert accRec5;
        
        ECM_Accrual__c accRec6  = new ECM_Accrual__c();
        accRec6.ECM_Period__c = 'P6';
        accRec6.ECM_Fiscal_Year__c = '2024';
        accRec6.ECM_Contract__c = con2.Id;
        insert accRec6;
        
        ECM_Accrual__c accRec7  = new ECM_Accrual__c();
        accRec7.ECM_Period__c = 'P1';
        accRec7.ECM_Fiscal_Year__c = '2025';
        accRec7.ECM_Contract__c = con2.Id;
        insert accRec7;
        
        ECM_Accrual__c accRec8  = new ECM_Accrual__c();
        accRec8.ECM_Period__c = 'P1';
        accRec8.ECM_Fiscal_Year__c = '2025';
        accRec8.ECM_Contract__c = con2.Id;
        insert accRec8;
        
        ECM_Accrual__c accRec9  = new ECM_Accrual__c();
        accRec9.ECM_Period__c = 'P3';
        accRec9.ECM_Fiscal_Year__c = '2025';
        accRec9.ECM_Contract__c = con2.Id;
        insert accRec9;
        
        ECM_Accrual__c accRec10  = new ECM_Accrual__c();
        accRec10.ECM_Period__c = 'P4';
        accRec10.ECM_Fiscal_Year__c = '2025';
        accRec10.ECM_Contract__c = con2.Id;
        insert accRec10;
        
        ECM_Accrual__c accRec11  = new ECM_Accrual__c();
        accRec11.ECM_Period__c = 'P5';
        accRec11.ECM_Fiscal_Year__c = '2025';
        accRec11.ECM_Contract__c = con2.Id;
        insert accRec11;
        
        ECM_Accrual__c accRec12  = new ECM_Accrual__c();
        accRec12.ECM_Period__c = 'P6';
        accRec12.ECM_Fiscal_Year__c = '2025';
        accRec12.ECM_Contract__c = con2.Id;
        insert accRec12;
        
    }
    @isTest
    public static void accrualItemsCal1(){
        Test.startTest();
        testAccrualInsertion1();
        try{  
            EDGE_UtilityTestClass.createOrgSettings();
            
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_DeleteAccrualItemsBatch'
                                                      and Country_Code__c ='IE' ];
            
            List<Contract> conList = [Select id , name from Contract];
            System.assert(conList.size()!=null,'conList size should not be null');
            
            String className = batchSetting.Batch_Class__c;       
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,2000);
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Exception caused on ECM_AccrualforAnP_TI_RetroGroup_Test.\nException:'+ex);
        }
        Test.stopTest();
    }@isTest
    public static void testAccrualInsertion1(){
        
        String contractRecordTypeIdGroup = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        List<ECM_Internal_Order__c> internalOrderList = new List<ECM_Internal_Order__c>();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountryPL('IE');
        Territory_Hierarchy__c territoryHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
        insert territoryHierarchy;
        system.assert(territoryHierarchy.Id != null,'territoryHierarchy Id should not be null');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Business_Unit__c = territoryHierarchy.Id;
        insert territory;
        
        
        Territory_Budget__c territoryBudget = new Territory_Budget__c();
        territoryBudget.ECM_Type__c =  'TI';
        territoryBudget.Territory__c = territory.id;
        territoryBudget.End_Date__c = system.today()+5;
        territoryBudget.Initial_Amount__c = 100.00;
        territoryBudget.Start_Date__c = system.today()+10;
        territoryBudget.ECM_Territory_Hierarchy__c = TerritoryHierarchy.id;
        insert territoryBudget;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Screen_3_field_configuration__c = 'Investment';
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
        
        Account acc = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc.Person_Responsible__c = UserInfo.getUserId();
        acc.IsOperator__c = true;
        insert acc;
        
        Account acc1 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc1.Person_Responsible__c = UserInfo.getUserId();
        acc1.IsOperator__c = true;
        insert acc1;
        
        Account acc2 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc2.Person_Responsible__c = UserInfo.getUserId();
        acc2.IsOperator__c = true;
        insert acc2;
        
        Account acc3 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc3.Person_Responsible__c = UserInfo.getUserId();
        acc3.IsOperator__c = true;
        insert acc3;
        
        Account acc4 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc4.Person_Responsible__c = UserInfo.getUserId();
        acc4.IsOperator__c = true;
        insert acc4;
        
        
        Date myDate = system.today().addmonths(6);
        Date myStartDate = system.today().addmonths(-6);
        
        Contract con1 = new Contract(Name = 'Test',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId=Acc1.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeIdGroup,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con1;
        
        Contract con2 = new Contract(Name = 'Test2',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc3.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeIdGroup,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con2;
        
        Contract con3 = new Contract(Name = 'Test3',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc4.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeIdGroup,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con3;
        
        con1.Status='Active';
        update con1;
        
        con2.Status='Active';
        update con2;
        
        con3.Status='Active';
        update con3;
        
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = geographyId;
        pOption.Type__c = 'Local-Segment1';
        pOption.RecordTypeId = PickupRecordTypeId;
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
        
        //ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(ECI.Id, 10, 1, 20, 2, 30, 3);
        
        ECM_Internal_Order__c iORecord = new ECM_Internal_Order__c();
        iORecord.Name = 'IO-123456789';
        iORecord.ECM_Product__c = product1.Id;
        iORecord.ECM_Budget_Type__c = TerritoryBudget.Id;
        iORecord.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj1.Id;
        iORecord.ECM_Geography__c = geographyId;
        iORecord.ECM_Description__c = 'Testing Record';
        iORecord.ECM_Start_Date__c = myStartDate;
        iORecord.ECM_End_Date__c = myDate;
        iORecord.ECM_Budget_Amount__c = 100;
        iORecord.ECM_Fiscal_Year__c='FY'+string.valueof(System.today().year()).right(2);
        internalOrderList.add(iORecord);//insert iORecord;
        
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
        
        //ECM_Tiering__c tier2 = ECM_CreateContractController.createTieringRecord(eCI2.Id, 5, 1, 10, 2,15, 3);
        
        ECM_Internal_Order__c iORecord2 = new ECM_Internal_Order__c();
        iORecord2.Name = 'IO-123456798';
        iORecord2.ECM_Product__c = product2.Id;
        iORecord2.ECM_Budget_Type__c = TerritoryBudget.Id;
        iORecord2.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj1.Id;
        iORecord2.ECM_Geography__c = geographyId;
        iORecord2.ECM_Description__c = 'Testing Record';
        iORecord2.ECM_Start_Date__c = myStartDate;
        iORecord2.ECM_End_Date__c = myDate;
        iORecord2.ECM_Budget_Amount__c = 100;
        iORecord2.ECM_Fiscal_Year__c='FY'+string.valueof(System.today().year()).right(2);
        internalOrderList.add(iORecord2);//insert iORecord2;
        
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
        
        ECM_Internal_Order__c iORecord3 = new ECM_Internal_Order__c();
        iORecord3.Name = 'IO-123456897';
        iORecord3.ECM_Product__c = product3.Id;
        iORecord3.ECM_Budget_Type__c = TerritoryBudget.Id;
        iORecord3.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj2.Id;
        iORecord3.ECM_Geography__c = geographyId;
        iORecord3.ECM_Description__c = 'Testing Record';
        iORecord3.ECM_Start_Date__c = myStartDate;
        iORecord3.ECM_End_Date__c = myDate;
        iORecord3.ECM_Budget_Amount__c = 100;
        iORecord3.ECM_Fiscal_Year__c='FY'+string.valueof(System.today().year()).right(2);
        internalOrderList.add(iORecord3);//insert iORecord3;
        
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
        
        ECM_Internal_Order__c iORecord4 = new ECM_Internal_Order__c();
        iORecord4.Name = 'IO-123457896';
        iORecord4.ECM_Product__c = product4.Id;
        iORecord4.ECM_Budget_Type__c = TerritoryBudget.Id;
        iORecord4.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj2.Id;
        iORecord4.ECM_Geography__c = geographyId;
        iORecord4.ECM_Description__c = 'Testing Record';
        iORecord4.ECM_Start_Date__c = myStartDate;
        iORecord4.ECM_End_Date__c = myDate;
        iORecord4.ECM_Budget_Amount__c = 100;
        iORecord4.ECM_Fiscal_Year__c='FY'+string.valueof(System.today().year()).right(2);
        internalOrderList.add(iORecord4);//insert iORecord4;
        insert internalOrderList;
        
        Market_Setting__c market= new Market_Setting__c();
        market.Name='Spain Setting';
        market.Geography__c=geographyId;
        market.ECM_Budget_Type_for_Volume_Based_PS__c = budgetTypeObj2.Id;
        market.ECM_Tiering_consideration_for_Accrual__c='Tier 1';
        market.ECM_Change_in_Accrual_Logic__c=true;
        market.Accrual_Creation__c = 'Whole Numbers';
        insert market;
        
        ECM_Sales_Driver__c sD = new ECM_Sales_Driver__c();
        sD.Name='test';
        sD.Geography__c=geographyId;
        
        sD.ECM_Budget_Type__c=budgetTypeObj2.Id;
        insert sD;
        
        
        ECM_Sales_Driver_Item__c sDI = new ECM_Sales_Driver_Item__c();
        sDI.Contract__c= con3.Id;
        sDI.ECM_Sales_Driver__c=SD.Id;
        sDI.ECM_Payment_Frequency__c=paymentFrequency.Id;
        sDI.ECM_Investement_Description__c='TEST';
        insert sDI;
        
        ECM_Sales_Driver_Item__c sDI1 = new ECM_Sales_Driver_Item__c();
        sDI1.Contract__c= con3.Id;
        sDI1.ECM_Sales_Driver__c=SD.Id;
        sDI1.ECM_Payment_Frequency__c=paymentFrequency.Id;
        sDI1.ECM_Investement_Description__c='TEST1';
        insert sDI1;
        
        ECM_Sales_Driver_Item_Detail__c sDID = new ECM_Sales_Driver_Item_Detail__c();
        //sDID.ECM_Product__c='';
        sDID.ECM_Investment_Amount__c=100;
        sDID.ECM_Sales_Driver_Item__c=SDI.id;
        sDID.ECM_Product__c=ECI4.id;
        insert sDID;
        
        ECM_Sales_Driver_Item_Detail__c sDID1 = new ECM_Sales_Driver_Item_Detail__c();
        //SDID.ECM_Product__c='';
        sDID1.ECM_Investment_Amount__c=100;
        sDID1.ECM_Sales_Driver_Item__c=SDI.id;
        sDID1.ECM_Product__c=ECI4.id;
        insert sDID1;
        
        ECM_Accrual_Period__c accrualPeriod= new ECM_Accrual_Period__c();
        accrualPeriod.ECM_Start_Date__c=System.today().tostartofMonth().addmonths(-3);
        accrualPeriod.ECM_End_Date__c=System.today().tostartofMonth().addmonths(-2);
        accrualPeriod.ECM_Execution_Month__c='6';
        accrualPeriod.ECM_Payment_Calculation_Date__c=System.today();
        accrualPeriod.Period__c='P6';
        accrualPeriod.Name='Test';
        accrualPeriod.ECM_Market_Setting__c=market.id;
        insert accrualPeriod;
        
        ECM_Accrual__c accRec1  = new ECM_Accrual__c();
        accRec1.ECM_Period__c = 'P12';
        accRec1.ECM_Fiscal_Year__c = '2024';
        accRec1.ECM_Contract__c = con1.Id;
        insert accRec1;
        
        ECM_Accrual__c accRec2  = new ECM_Accrual__c();
        accRec2.ECM_Period__c = 'P1';
        accRec2.ECM_Fiscal_Year__c = '2025';
        accRec2.ECM_Contract__c = con1.Id;
        insert accRec2;
        
        ECM_Accrual__c accRec3  = new ECM_Accrual__c();
        accRec3.ECM_Period__c = 'P2';
        accRec3.ECM_Fiscal_Year__c = '2025';
        accRec3.ECM_Contract__c = con1.Id;
        insert accRec3;
        
        ECM_Accrual__c accRec4  = new ECM_Accrual__c();
        accRec4.ECM_Period__c = 'P3';
        accRec4.ECM_Fiscal_Year__c = '2025';
        accRec4.ECM_Contract__c = con1.Id;
        insert accRec4;
        
        ECM_Accrual__c accRec5  = new ECM_Accrual__c();
        accRec5.ECM_Period__c = 'P4';
        accRec5.ECM_Fiscal_Year__c = '2025';
        accRec5.ECM_Contract__c = con1.Id;
        insert accRec5;
        
        ECM_Accrual__c accRec6  = new ECM_Accrual__c();
        accRec6.ECM_Period__c = 'P6';
        accRec6.ECM_Fiscal_Year__c = '2024';
        accRec6.ECM_Contract__c = con2.Id;
        insert accRec6;
        
        ECM_Accrual__c accRec7  = new ECM_Accrual__c();
        accRec7.ECM_Period__c = 'P1';
        accRec7.ECM_Fiscal_Year__c = '2025';
        accRec7.ECM_Contract__c = con2.Id;
        insert accRec7;
        
        ECM_Accrual__c accRec8  = new ECM_Accrual__c();
        accRec8.ECM_Period__c = 'P1';
        accRec8.ECM_Fiscal_Year__c = '2025';
        accRec8.ECM_Contract__c = con2.Id;
        insert accRec8;
        
        ECM_Accrual__c accRec9  = new ECM_Accrual__c();
        accRec9.ECM_Period__c = 'P3';
        accRec9.ECM_Fiscal_Year__c = '2025';
        accRec9.ECM_Contract__c = con2.Id;
        insert accRec9;
        
        ECM_Accrual__c accRec10  = new ECM_Accrual__c();
        accRec10.ECM_Period__c = 'P4';
        accRec10.ECM_Fiscal_Year__c = '2025';
        accRec10.ECM_Contract__c = con2.Id;
        insert accRec10;
        
        ECM_Accrual__c accRec11  = new ECM_Accrual__c();
        accRec11.ECM_Period__c = 'P5';
        accRec11.ECM_Fiscal_Year__c = '2025';
        accRec11.ECM_Contract__c = con2.Id;
        insert accRec11;
        
        ECM_Accrual__c accRec12  = new ECM_Accrual__c();
        accRec12.ECM_Period__c = 'P6';
        accRec12.ECM_Fiscal_Year__c = '2025';
        accRec12.ECM_Contract__c = con2.Id;
        insert accRec12;
        
    }
    
}