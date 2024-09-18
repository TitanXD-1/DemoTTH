@istest
public class ECM_SharingofDepletionrecords_Batch_Test {
    @isTest
    static void testAccrualInsertion(){

        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        system.assert(newuser!= null,'newuser should not be null');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
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
        
        User ciOuser = EDGE_UtilityTestClass.runAsUser('salesRep1_new','CIO User');
        ciOuser.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert ciOuser; 
        
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
        
         Account accNew = EDGE_UtilityTestClass.getOutletRecord(); 
         accNew.RecordTypeId=Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        accNew.Name = 'Test_Outlet5';
        accNew.BillingStreet = '17 Asian Highway 45';
        accNew.BillingCity = 'Sydney';
        accNew.IsOperator__c=true;
        accNew.BillingState = 'Queensland';
        accNew.BillingPostalCode = '4361';
        accNew.BillingCountry = 'Australia';
        accNew.BillingCountryCode = 'AU';
        accNew.Outlet_Email_Address__c = 'test4@test.com';
        accNew.Email_for_contracts_payments__c = 'test4@test.com';
        accNew.Global_Channel__c = 'Off Trade';
        accNew.Global_Sub_Channel__c = 'Retailer';
        accNew.Global_Segment__c = 'Hypermarket';
        accNew.Global_Sub_Segment__c = 'Modern Hypermarket';
        accNew.Status__c= 'Active';
        insert accNew;

        
        Product__c product1 = new Product__c();
        product1.Product_Full_Name__c='Product 1';
        product1.Country__c=geographyId;
        insert product1;
        
        Product__c product2 = new Product__c();
        product2.Product_Full_Name__c='Product 2';
        product2.Country__c=geographyId;
        insert product2;
        
        		Depletions__c d= new Depletions__c();
        		d.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d.ECM_Product__c=product1.id;
                d.ECM_Outlet__c=Acc.id;
                d.ECM_Volume__c=15;
                d.ecm_geography__c=geographyId;
        		insert d;
        
        		Depletions__c d1= new Depletions__c();
        		d1.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d1.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d1.ECM_Product__c=product2.id;
                d1.ECM_Outlet__c=Acc.id;
                d1.ECM_Volume__c=12;
        		d1.ecm_geography__c=geographyId;
        		insert d1;
        
        		Depletions__c d2= new Depletions__c();
        		d2.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d2.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d2.ECM_Product__c=product1.id;
                d2.ECM_Outlet__c=Acc1.id;
                d2.ECM_Volume__c=12;
                d2.ecm_geography__c=geographyId;
        		insert d2;
        
                
        		Depletions__c d3= new Depletions__c();
        		d3.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d3.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d3.ECM_Product__c=product2.id;
                d3.ECM_Outlet__c=Acc1.id;
                d3.ECM_Volume__c=12;
        		d3.ecm_geography__c=geographyId;
        		insert d3;

                
        		Depletions__c d4= new Depletions__c();
        		d4.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d4.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d4.ECM_Product__c=product1.id;
                d4.ECM_Outlet__c=Acc2.id;
                d4.ECM_Volume__c=12;
        		d4.ecm_geography__c=geographyId;
        		insert d4;  
        
                Depletions__c d5= new Depletions__c();
        		d5.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d5.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d5.ECM_Product__c=product2.id;
                d5.ECM_Outlet__c=Acc2.id;
                d5.ECM_Volume__c=12;
        		d5.ecm_geography__c=geographyId;
        		insert d5; 
        
        		Depletions__c d6= new Depletions__c();
        		d6.ECM_End_Period__c=System.today().tostartofMonth().addmonths(-2);
                d6.ECM_Start_Period__c=System.today().tostartofMonth().addmonths(-3);
                d6.ECM_Product__c=product2.id;
                d6.ECM_Outlet__c=Acc3.id;
                d6.ECM_Volume__c=12;
                d6.ecm_geography__c=geographyId;
        		insert d6; 
        
        		Test.startTest();
        			Database.executeBatch(new ECM_SharingofDepletionrecords_Batch());
        		Test.stopTest();

        
    }

}