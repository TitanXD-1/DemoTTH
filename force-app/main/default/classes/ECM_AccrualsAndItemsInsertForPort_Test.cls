@istest
public class ECM_AccrualsAndItemsInsertForPort_Test {
    @isTest
    public static void testAccrualInsertion(){
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractRecordTypeIdGroup = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();

        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String Type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
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
		
       User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1_new2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert salesRep; 
        
        User cIOuser = EDGE_UtilityTestClass.runAsUser('salesRep1_new','CIO User');
        cIOuser.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert cIOuser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Name = 'Test_Outlet';
        acc.BillingStreet = '17 Asian Highway 45';
        acc.BillingCity = 'Sydney';
        acc.IsOperator__c=true;
        acc.BillingState = 'Victoria';
        acc.BillingPostalCode = '5668';
        acc.BillingCountry = 'Australia';
        acc.BillingCountryCode = 'AU';
        acc.Outlet_Email_Address__c = 'test@test.com';
        acc.Email_for_contracts_payments__c = 'test@test.com';
        acc.Global_Channel__c = 'Off Trade';
        acc.Global_Sub_Channel__c = 'Retailer';
        acc.Global_Segment__c = 'Hypermarket';
        acc.Global_Sub_Segment__c = 'Modern Hypermarket';
        acc.Status__c= 'Active';
        insert acc;
        
         Account acc1 = EDGE_UtilityTestClass.getOutletRecord();
         acc1.Name = 'Test_Outlet1';
        acc1.BillingStreet = '17 Asian Highway 45';
        acc1.BillingCity = 'Sydney';
        acc1.IsOperator__c=true;
        acc1.BillingState = 'South Australia';
        acc1.BillingPostalCode = '5668';
        acc1.BillingCountry = 'Australia';
        acc1.BillingCountryCode = 'AU';
        acc1.Outlet_Email_Address__c = 'test1@test.com';
        acc1.Email_for_contracts_payments__c = 'test1@test.com';
        acc1.Global_Channel__c = 'Off Trade';
        acc1.Global_Sub_Channel__c = 'Retailer';
        acc1.Global_Segment__c = 'Hypermarket';
        acc1.Global_Sub_Segment__c = 'Modern Hypermarket';
        acc1.Status__c= 'Active';
        insert acc1;
        
         Account acc2 = EDGE_UtilityTestClass.getOutletRecord();
        acc2.Name = 'Test_Outlet2';       
        acc2.BillingStreet = '17 Asian Highway 45';
        acc2.BillingCity = 'Sydney';
        acc2.IsOperator__c=true;
        acc2.BillingState = 'MADRID';
        acc2.BillingPostalCode = '5668';
        acc2.BillingCountry = 'Spain';
        acc2.BillingCountryCode = 'ES';
        acc2.Outlet_Email_Address__c = 'test2@test.com';
        acc2.Email_for_contracts_payments__c = 'test2@test.com';
        acc2.Global_Channel__c = 'Off Trade';
        acc2.Global_Sub_Channel__c = 'Retailer';
        acc2.Global_Segment__c = 'Hypermarket';
        acc2.Global_Sub_Segment__c = 'Modern Hypermarket';
        acc2.Status__c= 'Active';
        insert acc2;
        
        Account acc3 = EDGE_UtilityTestClass.getOutletRecord();
        acc3.Name = 'Test_Outlet3';
        acc3.BillingStreet = '17 Asian Highway 45';
        acc3.BillingCity = 'Sydney';
        acc3.IsOperator__c=true;
        acc3.BillingState = 'Scotland';
        acc3.BillingPostalCode = '756';
        acc3.BillingCountry = 'United Kingdom';
        acc3.BillingCountryCode = 'GB';
        acc3.Outlet_Email_Address__c = 'test3@test.com';
        acc3.Email_for_contracts_payments__c = 'test3@test.com';
        acc3.Global_Channel__c = 'Off Trade';
        acc3.Global_Sub_Channel__c = 'Retailer';
        acc3.Global_Segment__c = 'Hypermarket';
        acc3.Global_Sub_Segment__c = 'Modern Hypermarket';
        acc3.Status__c= 'Active';
        insert acc3;
        
        Account acc4 = EDGE_UtilityTestClass.getOutletRecord();
        acc4.Name = 'Test_Outlet4';
        acc4.BillingStreet = '17 Asian Highway 45';
        acc4.BillingCity = 'Sydney';
        acc4.IsOperator__c=true;
        acc4.BillingState = 'Queensland';
        acc4.BillingPostalCode = '4730';
        acc4.BillingCountry = 'Australia';
        acc4.BillingCountryCode = 'AU';
        acc4.Outlet_Email_Address__c = 'test4@test.com';
        acc4.Email_for_contracts_payments__c = 'test4@test.com';
        acc4.Global_Channel__c = 'Off Trade';
        acc4.Global_Sub_Channel__c = 'Retailer';
        acc4.Global_Segment__c = 'Hypermarket';
        acc4.Global_Sub_Segment__c = 'Modern Hypermarket';
        acc4.Status__c= 'Active';
        insert acc4;
        
         Account acc5 = EDGE_UtilityTestClass.getOutletRecord(); 
        acc5.RecordTypeId=Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        acc5.RecordTypeId=Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        acc5.Name = 'Test_Outlet5';
        acc5.BillingStreet = '17 Asian Highway 45';
        acc5.BillingCity = 'Sydney';
        acc5.IsOperator__c=true;
        acc5.BillingState = 'Queensland';
        acc5.BillingPostalCode = '4361';
        acc5.BillingCountry = 'Australia';
        acc5.BillingCountryCode = 'AU';
        acc5.Outlet_Email_Address__c = 'test4@test.com';
        acc5.Email_for_contracts_payments__c = 'test4@test.com';
        acc5.Global_Channel__c = 'Off Trade';
        acc5.Global_Sub_Channel__c = 'Retailer';
        acc5.Global_Segment__c = 'Hypermarket';
        acc5.Global_Sub_Segment__c = 'Modern Hypermarket';
        acc5.Status__c= 'Active';
        insert acc5;
        
        Date myDate = system.today().addmonths(6);
        Date myStartDate = system.today().addmonths(-6);
        
        Contract con1 = new Contract(Name = 'Test',StartDate=myStartDate,UOS_Rebate_Rate__c=0, UOS_Target__c=99,AccountId=acc5.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeIdGroup,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con1;
        
        Contract con2 = new Contract(Name = 'Test2',StartDate=myStartDate,UOS_Rebate_Rate__c=0, UOS_Target__c=99,AccountId =Acc3.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con2;
        
        Contract con3 = new Contract(Name = 'Test3',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc4.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con3;
        
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
        outlet3.Contract__c=con3.id;
        insert outlet3;
		
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = geographyId;
        pOption.Type__c = 'Local-Segment1';
        pOption.RecordTypeId = PickupRecordTypeId;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        insert pOption;
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
		budgetTypeObj1.Name='Upfront Payment [AU]';
		budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.Status__c = 'Active';
		budgetTypeObj1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
		insert budgetTypeObj1;

        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
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
        market.Geography__c=geographyId;
        insert market;
        
        ECM_Accrual_Period__c accrualPeriod= new ECM_Accrual_Period__c();
        accrualPeriod.ECM_Start_Date__c=Date.newInstance(2020,11,01);
        accrualPeriod.ECM_End_Date__c=Date.newInstance(2020,11, 30);
        accrualPeriod.ECM_Execution_Month__c='6';
        accrualPeriod.ECM_Payment_Calculation_Date__c=Date.newInstance(2020,12, 14);
        accrualPeriod.Period__c='P6';
        accrualPeriod.ECM_Is_Forecast__c=false;
        accrualPeriod.Name='Test';
        accrualPeriod.ECM_Market_Setting__c=market.id;
           insert accrualPeriod;
        
          ECM_Accrual_Period__c accrualPeriodForecast= new ECM_Accrual_Period__c();
          accrualPeriodForecast.ECM_Start_Date__c=Date.newInstance(2019,12, 01);
          accrualPeriodForecast.ECM_End_Date__c=Date.newInstance(2019,12,31);
          accrualPeriodForecast.ECM_Execution_Month__c='6';
          accrualPeriodForecast.ECM_Payment_Calculation_Date__c=Date.newInstance(2020,12, 14);
          accrualPeriodForecast.Period__c='P6F';
          accrualPeriodForecast.ECM_Is_Forecast__c=true;
          accrualPeriodForecast.Name='Test';
          accrualPeriodForecast.ECM_Market_Setting__c=market.id;
           insert accrualPeriodForecast;
        
        		Depletions__c d= new Depletions__c();
        		d.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d.ECM_Product__c=product1.id;
                d.ECM_Outlet__c=Acc.id;
                d.ECM_Volume__c=15;
        		insert d;
        
        		Depletions__c d1= new Depletions__c();
        		d1.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d1.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d1.ECM_Product__c=product2.id;
                d1.ECM_Outlet__c=Acc.id;
                d1.ECM_Volume__c=12;
        		insert d1;
        
        		Depletions__c d2= new Depletions__c();
        		d2.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d2.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d2.ECM_Product__c=product1.id;
                d2.ECM_Outlet__c=Acc1.id;
                d2.ECM_Volume__c=12;
        		insert d2;
        
                
        		Depletions__c d3= new Depletions__c();
        		d3.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d3.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d3.ECM_Product__c=product2.id;
                d3.ECM_Outlet__c=Acc1.id;
                d3.ECM_Volume__c=12;
        		insert d3;

                
        		Depletions__c d4= new Depletions__c();
        		d4.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d4.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d4.ECM_Product__c=product1.id;
                d4.ECM_Outlet__c=Acc2.id;
                d4.ECM_Volume__c=12;
        		insert d4;  
        
                Depletions__c d5= new Depletions__c();
        		d5.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d5.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d5.ECM_Product__c=product2.id;
                d5.ECM_Outlet__c=Acc2.id;
                d5.ECM_Volume__c=12;
        		insert d5; 
        Test.startTest();
        		Depletions__c d6= new Depletions__c();
        		d6.ECM_End_Period__c=Date.newInstance(2019,12,01);
                d6.ECM_Start_Period__c=Date.newInstance(2019,12,31);
                d6.ECM_Product__c=product4.id;
                d6.ECM_Outlet__c=Acc2.id;
                d6.ECM_Volume__c=12;
        		insert d6; 
     
        
                Depletions__c d7= new Depletions__c();
        		d7.ECM_End_Period__c=Date.newInstance(2020,11,01);
                d7.ECM_Start_Period__c=Date.newInstance(2020,11,30);
                d7.ECM_Product__c=product4.id;
                d7.ECM_Outlet__c=Acc2.id;
                d7.ECM_Volume__c=12;
        		insert d7; 
                 
                        
        ECM_Price_List__c pL=new ECM_Price_List__c();
        pL.Name='ES Pricelist';
        pL.ECM_Start_Date__c=System.today().tostartofMonth().addmonths(-3);
        pL.ECM_End_Date__c=System.today().tostartofMonth().addmonths(-2);
        pL.ECM_Active__c=true;
        pL.ECM_Geography__c=geographyId;
        insert pL;
        
        ECM_Price_List_Item__c pLI=new ECM_Price_List_Item__c();
        pLI.ECM_Price_List__c=PL.id;
        pLI.ECM_Product__c=product4.id;
        pLI.ECM_UOS__c=101.00;
        insert pLI;
        			Database.executeBatch(new ECM_AccrualsAndItemsInsertForPort_Batch());
        		Test.stopTest();
                    List<ECM_Accrual_Item__c> accrual= [select id,Name,ECM_Contract_Item__r.Name,ECM_Product__r.name,ECM_Rebate_Rate__c,ECM_UOS_Rate__c,ECM_Actual_Cases__c from ECM_Accrual_Item__c];
        			system.assertEquals(accrual.size(),4,'null');
        
    }

}