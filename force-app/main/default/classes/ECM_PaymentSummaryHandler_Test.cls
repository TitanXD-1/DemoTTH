/*
* @Name: ECM_PaymentSummaryTriggerHandler_Test
* @Purpose: This class is used to cover test data for the - ECM_PaymentSummaryHandler
* @History                                                          
                                                          
* VERSION    AUTHOR        DATE              DETAIL
* 1.0        Keshav     28/07/2020        Initial Development
* 2.0		Saurav Prasad 07/10/2020		Updated - ECM-2878 
* 3.0       Joshraj Sen   22/12/2023        146153: Prevent the creation of Payment Summaries for CRG Contracts

*/
@istest
public class ECM_PaymentSummaryHandler_Test {
    public static string australiaOperatorAccountName='Australia Operator';
    public static string australiaOutletAccountName='Australia Outlet';
    public class MyException extends Exception{} 
    
    @testSetup
    static  void setupData(){
        Id australianGeographyId = EDGE_UtilityTestClass.setupCountry('AU');
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String outletRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();  
        
        Pick_Up_Options__c outletVisit= ECM_UtilityTestClass.createPickUpOption(australianGeographyId,outletRecordTypeId);
        outletVisit.Name='Premium[AU]';
        outletVisit.Geography__c=australianGeographyId;
        outletVisit.Type__c = 'Outlet Visit Prioritization'; 
        outletVisit.Value__c =4;
        outletVisit.Status__c='Active';
        
        Pick_Up_Options__c budgetTypeTI= new Pick_Up_Options__c();
        budgetTypeTI.Name='TI[AU]';
        budgetTypeTI.Geography__c=australianGeographyId;
        budgetTypeTI.RecordTypeId=bannerRecordTypeId;

        Pick_Up_Options__c budgetTypePortfolioRebates= new Pick_Up_Options__c();
        budgetTypePortfolioRebates.Name='Portfolio Rebates [AU]';
        budgetTypePortfolioRebates.Geography__c=australianGeographyId;
        budgetTypePortfolioRebates.Status__c = 'Active';
        budgetTypePortfolioRebates.RecordTypeId=bannerRecordTypeId;
        
        
        Pick_Up_Options__c budgetTypeSKU= new Pick_Up_Options__c();
        budgetTypeSKU.Name='SKU Specific Rebates [AU]';
        budgetTypeSKU.Geography__c=australianGeographyId;
        budgetTypeSKU.Status__c = 'Active';
        budgetTypeSKU.RecordTypeId=bannerRecordTypeId;
        
        
        Pick_Up_Options__c budgetTypePortUpfront = new Pick_Up_Options__c();
        budgetTypePortUpfront.Name='Upfront Payment [AU]';
        budgetTypePortUpfront.Geography__c=australianGeographyId;
        budgetTypePortUpfront.Status__c = 'Active';
        budgetTypePortUpfront.RecordTypeId=bannerRecordTypeId;
        
           

        Pick_Up_Options__c onPremise= new Pick_Up_Options__c();
        onPremise.Name='On-Premise[AU]';
        onPremise.Geography__c=australianGeographyId;
        onPremise.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        onPremise.ECM_SAP_Order_reason__c = 'Y10'; 
        onPremise.ECM_SAP_Pricing_condition__c = 'O25'; 
        
           Pick_Up_Options__c budgetTypeAP= new Pick_Up_Options__c();
           budgetTypeAP.Name='A&P[AU]';
           budgetTypeAP.Geography__c=australianGeographyId;
           budgetTypeAP.Status__c = 'Active';
           budgetTypeAP.RecordTypeId=bannerRecordTypeId;
        
        Pick_Up_Options__c budgetTypeOther= new Pick_Up_Options__c();
        budgetTypeOther.Name='Other [AU]';
        budgetTypeOther.Geography__c=australianGeographyId;
        budgetTypeOther.Status__c = 'Active';
        budgetTypeOther.RecordTypeId=bannerRecordTypeId;
        
        Pick_Up_Options__c taxcode = new Pick_Up_Options__c();
        taxcode.Name='TaxCode[AU]';
        taxcode.Geography__c=australianGeographyId;
        taxcode.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        taxcode.ECM_SAP_Order_reason__c = 'Y10'; 
        taxcode.ECM_SAP_Pricing_condition__c = 'O25';
        
        Pick_Up_Options__c budgetTypeTraining= new Pick_Up_Options__c();
        budgetTypeTraining.Name='Training [AU]';
        budgetTypeTraining.Geography__c=australianGeographyId;
        budgetTypeTraining.Status__c = 'Active';
        budgetTypeTraining.RecordTypeId=bannerRecordTypeId;
        insert new List<Pick_Up_Options__c>{outletVisit,budgetTypeTI,budgetTypePortfolioRebates,onPremise,budgetTypeTraining,budgetTypeOther,budgetTypeAP,budgetTypeSKU,budgetTypePortUpfront,taxcode};
        
        Account australiaOperatorAccount = EDGE_UtilityTestClass.getDistriAccRec();  
        australiaOperatorAccount.Name=australiaOperatorAccountName;
        australiaOperatorAccount.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        australiaOperatorAccount.Status__c = 'Active';
        australiaOperatorAccount.IsOwner__c =true;
        australiaOperatorAccount.country__c = australianGeographyId;
        australiaOperatorAccount.Person_Responsible__c=Userinfo.getUserId();
        insert australiaOperatorAccount;
        system.assert(australiaOperatorAccount.Id != null,'australiaOperatorAccount should not be null');
        
        Account australiaOutletAccount = EDGE_UtilityTestClass.getOutletRecord();
        australiaOutletAccount.Name= australiaOutletAccountName;
        australiaOutletAccount.country__c = australianGeographyId;
        australiaOutletAccount.Email_for_contracts_payments__c = 'test@abc.com';
        australiaOutletAccount.BillingState = 'Australian Capital Territory';
        australiaOutletAccount.ParentId = australiaOperatorAccount.Id;
        australiaOutletAccount.BillingPostalCode = '5668';
        australiaOutletAccount.BillingCountry = 'Australia';
        australiaOutletAccount.BillingCountryCode = 'AU';
        australiaOutletAccount.Independent_of_Owner__c=false;
        australiaOutletAccount.OwnerId=Userinfo.getUserId();
        australiaOutletAccount.Outlet_Visit_Prioritisation_Grade__c=outletVisit.Id;       
        insert australiaOutletAccount;
        system.assert(australiaOutletAccount.Id != null,'australiaOutletAccount should not be null');   
    }
	@isTest
	static void testupdatepaymentSummaryValues(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
        Id budgetTypeTaxCodeId;
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;

                }
               
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;

            }
        }

        

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        


        orgSetting.Run_Triggers__c=false;
        update orgSetting;
        


        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  




        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        


       


        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c=true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        




        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;      
        insert newcontractitem;
        system.assert(newcontractitem.Id != null,'newcontractitem should not be null');   


        orgSetting.Run_Triggers__c=false;
        update orgSetting;


        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.Name='IO-567801234';
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today()-1;
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_State__c = 'Australian Capital Territory';
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeTIId;
        internalOrder.ECM_Geography__c = australianGeographyId;
        internalOrder.Owner__c = australiaOperatorAccountId;
        insert internalOrder;
		system.assert(internalOrder.Id != null,'internalOrder should not be null');   
     
		orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
            List<ECM_Payment_Summary__c>paymemtSummarysList= new List<ECM_Payment_Summary__c>();
                  
            
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ecm_tax_code__c=budgetTypeTaxCodeId;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Payment_Summary_Status__c='Approved';
        paymemtSummarysList.add(paymemtSummary); 
            
         ECM_Payment_Summary__c paymemtSummarytraining = new ECM_Payment_Summary__c();
         paymemtSummarytraining.ECM_Total_Amount_Confirmed__c = 20.00;
         paymemtSummarytraining.ECM_Payment_Summary_Status__c = 'Open';
         paymemtSummarytraining.ECM_Type__c = 'Non-Volume';
         paymemtSummarytraining.ECM_Invoice_Status__c='Requested';
         paymemtSummarytraining.ECM_Contract__c = contr.id;
         paymemtSummarytraining.ECM_Start_Period__c = system.today()-300;
         paymemtSummarytraining.ECM_End_Period__c = system.today();
         paymemtSummarytraining.ECM_Budget_types__c = budgetTypeTrainingId;
         paymemtSummarytraining.ecm_tax_code__c=budgetTypeTaxCodeId;
         paymemtSummarytraining.ECM_Invoice_Status__c ='Approved';
		 paymemtSummarytraining.ECM_Payment_Summary_Status__c='Approved';
         paymemtSummarysList.add(paymemtSummarytraining);
            
         ECM_Payment_Summary__c paymemtSummaryother = new ECM_Payment_Summary__c();
         paymemtSummaryother.ECM_Total_Amount_Confirmed__c = 20.00;
         paymemtSummaryother.ECM_Payment_Summary_Status__c = 'Open';
         paymemtSummaryother.ECM_Type__c = 'Non-Volume';
         paymemtSummaryother.ECM_Invoice_Status__c='Requested';
         paymemtSummaryother.ECM_Contract__c = contr.id;
         paymemtSummaryother.ECM_Start_Period__c = system.today()-300;
         paymemtSummaryother.ECM_End_Period__c = system.today();
         paymemtSummaryother.ECM_Budget_types__c = budgetTypeOtherId;
         paymemtSummaryother.ecm_tax_code__c=budgetTypeTaxCodeId;
         paymemtSummaryother.ECM_Invoice_Status__c ='Approved';
		 paymemtSummaryother.ECM_Payment_Summary_Status__c='Approved';
         paymemtSummarysList.add(paymemtSummaryother);
            
        Database.insert(paymemtSummarysList);
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummarysList[0].id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;
		
         
            
                     Test.startTest();
            
             
        orgSetting.Run_Triggers__c=false;
        update orgSetting;


        contr.Status='Active';
        contr.ECM_Upfront_Payment_Spent__c=null;
        contr.ECM_Contract_SKU_Specific_Rebate_Paid__c=null;
        update contr;
        
             
     
		Test.stopTest();
        
    }	
	@isTest
	static void testValidatePaymentsummary(){
		
        

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
		Id budgetTypeTaxCodeId;
        
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   

            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;
                }             
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;
            }
        }
        
        ECM_Contract_Type__c contractType1 =new ECM_Contract_Type__c();
        contractType1.Name='Promotional';
        contractType1.Geography__c=australianGeographyId;
        contractType1.ECM_Abbreviation__c='POM';
        contractType1.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType1.Volume_UoM_for_Spirits__c='BTL';
        contractType1.CurrencyIsoCode = 'AUD';
        contractType1.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Rate Per UoM;Investment';
        contractType1.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType1;
        System.assert(contractType1.Id!=null,'contractType1 Id should not be null');
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType1.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
        EDGE_UtilityTestClass.createOrgSettings();
        
        
		
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        insert paymemtSummary;
        
        contr.Status='Active';
        contr.ECM_Upfront_Payment_Spent__c=null;
        contr.ECM_Contract_SKU_Specific_Rebate_Paid__c=null;
        update contr;
        
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Total_Amount_Confirmed__c=20;
        paymemtSummary.ECM_Type__c='Non-Volume';
        paymemtSummary.ECM_Payment_Summary_Status__c='Completed';
        paymemtSummary.ECM_SAP_Payment_Date__c=System.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeAPId;
        update paymemtSummary;
        Test.startTest();
        Profile prof = [select id from profile where name=: 'CIO User'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm12301@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        
        AccountShare accountShare= new AccountShare();
        accountShare.accountId=australiaOutletAccountId;
        accountShare.UserOrGroupid=usr.Id;
        accountShare.accountaccessLevel='Edit';
        accountShare.OpportunityAccessLevel='None';
        insert accountShare;
        
        paymemtSummary.ECM_Tax_Code__c=budgetTypeTaxCodeId;
        paymemtSummary.ECM_Payment_Summary_Status__c='Approved';
        update paymemtSummary;
        
        System.runAs(usr){
            ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
            paymemtSummary.ECM_SAP_Payment_Date__c=system.today().addDays(5);
        	update paymemtSummary;
        }

        
         ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
         paymemtSummary.ECM_Payment_Summary_Status__c='Completed';
         paymemtSummary.ECM_Budget_types__c = budgetTypeSKUId;
        update paymemtSummary;
        
        
		Test.stopTest();
        
    }
    @isTest
    static void testApprovalProcess(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeTaxCodeId;
                
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
				if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;
                }              
                
            }
        
            australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
        budgetTypeTIId=[select id from Pick_Up_Options__c where Name='TI[AU]'].Id;
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;
            }
        }
         
        List<Profile>extraApproverProfile= [select id from profile where Name='Extra Approver' Limit 1];
        User extraUser1=new User(firstname='extra_approver_1',lastname=userinfo.getOrganizationId(),
                                userName='extra_approver_1'+userinfo.getOrganizationId()+'@diageo.com',profileId=extraApproverProfile[0].id,
                                email='Sys_Admin_'+userinfo.getOrganizationId()+'@diageo.com',languagelocaleKey='en_US',
                                LocaleSidKey='en_US',TimeZoneSidkey='America/Los_Angeles',alias='usr1234',EmailEncodingKey='ISO-8859-1',Available_Countries__c='AU');
        insert extraUser1;
        System.assert(extraUser1.Id!=null,'extraUser1 Id should not be null');
         
        User extraUser2=new User(firstname='extra_approver_2',lastname=userinfo.getOrganizationId(),
                                userName='extra_approver_2'+userinfo.getOrganizationId()+'@diageo.com',profileId=extraApproverProfile[0].id,
                                email='Sys_Admin_'+userinfo.getOrganizationId()+'@diageo.com',languagelocaleKey='en_US',
                                LocaleSidKey='en_US',TimeZoneSidkey='America/Los_Angeles',alias='usr1234',EmailEncodingKey='ISO-8859-1',Available_Countries__c='AU');
        insert extraUser2;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        //contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate,ECM_Duration__c=12);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;
         
        ECM_Extra_Approval__c ex1= new ECM_Extra_Approval__c();
        ex1.ECM_Extra_Approval_User__c=extraUser1.Id;
        ex1.ECM_Lower_Limit_Amount__c=8.00;
        ex1.ECM_Upper_Limit_Amount__c=100;
        ex1.ECM_Approver_Position_Name__c='manager';
        ex1.ECM_Type__c='Volume-Based PS';
        ex1.ECM_Active__c=true;
        ex1.ECM_Delegated_Approver_Email_Address__c='name.surname@diageo.com';
        insert ex1;
        
        
        ECM_Extra_Approval__c ex2= new ECM_Extra_Approval__c();
        ex2.ECM_Extra_Approval_User__c=extraUser2.Id;
        ex2.ECM_Lower_Limit_Amount__c=8.00;
        ex2.ECM_Upper_Limit_Amount__c=100;
        ex2.ECM_Approver_Position_Name__c='Director';
        ex2.ECM_Type__c='Volume-Based PS';
        ex2.ECM_Active__c=true;   
        ex2.ECM_Delegated_Approver_Email_Address__c='name.surname2@diageo.com';
        insert ex2;
        
        ECM_Agreement_Approval__c agreementApproval1 = new ECM_Agreement_Approval__c();
            agreementApproval1.ECM_Agreement_Type__c=contractType.id;
            agreementApproval1.ECM_Extra_Approval__c=ex1.id;
        insert agreementApproval1;
        
        ECM_Agreement_Approval__c agreementApproval2 = new ECM_Agreement_Approval__c();
            agreementApproval2.ECM_Agreement_Type__c=contractType.id;
            agreementApproval2.ECM_Extra_Approval__c=ex2.id;
        insert agreementApproval2;
         
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
         
                orgSetting.Run_Triggers__c=false;
        update orgSetting;
         
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
		
        		           orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
     

        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Provisional';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Tax_Code__c=budgetTypeTaxCodeId;
        insert paymemtSummary;
        
        
         
        paymemtSummary.ECM_Type__c='Volume-Based';
        paymemtSummary.ECM_Payment_Summary_Status__c='In Approval process'; 
        paymemtSummary.ECM_Approval_Sub_Status__c='Extra Approval';
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        update paymemtSummary;
        
         ECM_Payment_Summary_Item__c psItem= new ECM_Payment_Summary_Item__c();
         psItem.ECM_Contract_Item__c=newcontractitem.Id;
         psItem.ECM_Payment_Summary__c=paymemtSummary.Id;
         psItem.ECM_Confirmed_Volume__c=12;
         psItem.ECM_Product__c=product.id;
         psItem.ECM_Confirm__c=true;
         insert psItem;
        
            Test.startTest();
        List<User> extrauser=[select id from user where profile.name='Extra Approver'];
        List<Approval.ProcessWorkitemRequest> processWorkitemRequestList = new List<Approval.ProcessWorkitemRequest>();
       ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        
        List<Approval.ProcessSubmitRequest>reqList= new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
		approvalReq.setObjectId(paymemtSummary.id);
        approvalReq.setNextApproverIds(new List<id>{extrauser[0].id});
        reqList.add(approvalReq);
        
        Approval.ProcessSubmitRequest approvalReq2 = new Approval.ProcessSubmitRequest();
		approvalReq2.setObjectId(paymemtSummary.id);
        approvalReq2.setNextApproverIds(new List<id>{extrauser[1].id});
        reqList.add(approvalReq2);
        
        
                for(ProcessInstance pInstance: [SELECT Id,TargetObjectId, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems),(SELECT Id, ActorId,Actor.Name,StepStatus,OriginalActorId FROM Steps)  FROM ProcessInstance where TargetObjectId=:paymemtSummary.Id order by lastmodifieddate desc]){
            system.debug(LoggingLevel.Debug,'size--->'+pInstance.Workitems);
            if(pInstance.Workitems!=null && pInstance.Workitems.size()>0){					
                for(ProcessInstanceWorkitem processWorkitem:pInstance.Workitems){
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest(); 
                    pwr.setAction('Approve');
                    pwr.setComments('Approval Request Approved by');
                    pwr.setWorkItemId(processWorkitem.id);
                    processWorkitemRequestList.add(pwr);
                }
            }	
        }
        

	 
        ecm_payment_summary__c ps1=[select id,name,ECM_Payment_Summary_Status__c,ECM_Approval_Sub_Status__c from ecm_payment_summary__c where id=:paymemtSummary.Id];
         system.debug(LoggingLevel.Debug,ps1);
         
         
        contr.status='Active';
        update contr;
         
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Payment_Summary_Status__c='Completed';
        paymemtSummary.ECM_Approval_Sub_Status__c='';
        paymemtSummary.ECM_SAP_Payment_Date__c=System.today();
        update paymemtSummary;
        
        //ECM_PaymentSummaryTriggerHelper.updateCIOApprovalRecords(new Set<Id>{paymemtSummary.Id});
        //ECM_PaymentSummaryTriggerHelper.checkAndProvideAccountAccess(australiaOutletAccountId,new Map<id,String>{extrauser1.id=>'CEO'});
        
        paymemtSummary.ECM_Start_Period__c =  Date.newInstance(System.today().year(),6,01) ;
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year(),6,30) ;      
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary});
        
        paymemtSummary.ECM_Start_Period__c =  Date.newInstance(System.today().year(),7,01) ;
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year(),7,31) ;      
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary});
           
        paymemtSummary.ECM_Start_Period__c =  Date.newInstance(System.today().year(),6,01) ;
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year()+1,6,30) ;      
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary});
        
        paymemtSummary.ECM_Start_Period__c =  Date.newInstance(System.today().year(),7,01) ;
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year()+1,7,31) ;      
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary});
         
        paymemtSummary.ECM_Start_Period__c = system.today()-365;
        paymemtSummary.ECM_End_Period__c = system.today();       
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary});   
         
        paymemtSummary.ECM_Start_Period__c =  Date.newInstance(System.today().year(),3,31);
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year(),8,31);      
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary}); 
         
        paymemtSummary.ECM_Start_Period__c =  Date.newInstance(System.today().year(),8,31);
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year()+1,3,31);      
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary}); 
         
        paymemtSummary.ECM_Start_Period__c =  Date.newInstance(System.today().year(),3,31);
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year()+1,8,31);      
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymemtSummary});
        
		Test.stopTest();
        
    }
    @isTest
      static void testApprovalProcessCIOApproved(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeTaxCodeId;
                
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
				if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;
                }              
                
            }
        
            australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
        budgetTypeTIId=[select id from Pick_Up_Options__c where Name='TI[AU]'].Id;
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;
            }
        }
         
        List<Profile>extraApproverProfile= [select id from profile where Name='Extra Approver' Limit 1];
        User extraUser1=new User(firstname='extra_approver_1',lastname=userinfo.getOrganizationId(),
                                userName='extra_approver_1'+userinfo.getOrganizationId()+'@diageo.com',profileId=extraApproverProfile[0].id,
                                email='Sys_Admin_'+userinfo.getOrganizationId()+'@diageo.com',languagelocaleKey='en_US',
                                LocaleSidKey='en_US',TimeZoneSidkey='America/Los_Angeles',alias='usr1234',EmailEncodingKey='ISO-8859-1',Available_Countries__c='AU');
        insert extraUser1;
        System.assert(extraUser1.Id!=null,'extraUser1 Id should not be null');
         
        User extraUser2=new User(firstname='extra_approver_2',lastname=userinfo.getOrganizationId(),
                                userName='extra_approver_2'+userinfo.getOrganizationId()+'@diageo.com',profileId=extraApproverProfile[0].id,
                                email='Sys_Admin_'+userinfo.getOrganizationId()+'@diageo.com',languagelocaleKey='en_US',
                                LocaleSidKey='en_US',TimeZoneSidkey='America/Los_Angeles',alias='usr1234',EmailEncodingKey='ISO-8859-1',Available_Countries__c='AU');
        insert extraUser2;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Screen_3_field_configuration__c ='Product Name;UoM;Volume Target;';
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;
         
        ECM_Extra_Approval__c ex1= new ECM_Extra_Approval__c();
        ex1.ECM_Extra_Approval_User__c=extraUser1.Id;
        ex1.ECM_Lower_Limit_Amount__c=8.00;
        ex1.ECM_Upper_Limit_Amount__c=100;
        ex1.ECM_Approver_Position_Name__c='manager';
        ex1.ECM_Type__c='Volume-Based PS';
        ex1.ECM_Active__c=true;
        ex1.ECM_Delegated_Approver_Email_Address__c='name.surname@diageo.com';
        insert ex1;
        
        
        ECM_Extra_Approval__c ex2= new ECM_Extra_Approval__c();
        ex2.ECM_Extra_Approval_User__c=extraUser2.Id;
        ex2.ECM_Lower_Limit_Amount__c=8.00;
        ex2.ECM_Upper_Limit_Amount__c=100;
        ex2.ECM_Approver_Position_Name__c='Director';
        ex2.ECM_Type__c='Volume-Based PS';
        ex2.ECM_Active__c=true;   
        ex2.ECM_Delegated_Approver_Email_Address__c='name.surname2@diageo.com';
        insert ex2;
        
        ECM_Agreement_Approval__c agreementApproval1 = new ECM_Agreement_Approval__c();
            agreementApproval1.ECM_Agreement_Type__c=contractType.id;
            agreementApproval1.ECM_Extra_Approval__c=ex1.id;
        insert agreementApproval1;
        
        ECM_Agreement_Approval__c agreementApproval2 = new ECM_Agreement_Approval__c();
            agreementApproval2.ECM_Agreement_Type__c=contractType.id;
            agreementApproval2.ECM_Extra_Approval__c=ex2.id;
        insert agreementApproval2;
         
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
         
                orgSetting.Run_Triggers__c=false;
        update orgSetting;
         
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
		
        		           orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
		  Test.startTest();

        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Provisional';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Tax_Code__c=budgetTypeTaxCodeId;
        insert paymemtSummary;
        
        
         
        paymemtSummary.ECM_Type__c='Volume-Based';
        paymemtSummary.ECM_Payment_Summary_Status__c='Submitted'; 
        paymemtSummary.ECM_Approval_Sub_Status__c='CIO Approval';
        paymemtSummary.ECM_Invoice_Status__c='Approved';
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        update paymemtSummary;
        
         ECM_Payment_Summary_Item__c psItem= new ECM_Payment_Summary_Item__c();
         psItem.ECM_Contract_Item__c=newcontractitem.Id;
         psItem.ECM_Payment_Summary__c=paymemtSummary.Id;
         psItem.ECM_Confirmed_Volume__c=12;
         psItem.ECM_Product__c=product.id;
         psItem.ECM_Confirm__c=true;
         insert psItem;
        
          
        List<User> extrauser=[select id from user where profile.name='Extra Approver'];
        List<Approval.ProcessWorkitemRequest> processWorkitemRequestList = new List<Approval.ProcessWorkitemRequest>();
       ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        
        List<Approval.ProcessSubmitRequest>reqList= new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
		approvalReq.setObjectId(paymemtSummary.id);
        approvalReq.setNextApproverIds(new List<id>{extrauser[0].id});
        reqList.add(approvalReq);
        
        Approval.ProcessSubmitRequest approvalReq2 = new Approval.ProcessSubmitRequest();
		approvalReq2.setObjectId(paymemtSummary.id);
        approvalReq2.setNextApproverIds(new List<id>{extrauser[1].id});
        reqList.add(approvalReq2);
        
        
                for(ProcessInstance pInstance: [SELECT Id,TargetObjectId, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems),(SELECT Id, ActorId,Actor.Name,StepStatus,OriginalActorId FROM Steps)  FROM ProcessInstance where TargetObjectId=:paymemtSummary.Id order by lastmodifieddate desc limit 1]){
            system.debug(LoggingLevel.Debug,'size--->'+pInstance.Workitems);
            if(pInstance.Workitems!=null && pInstance.Workitems.size()>0){					
                for(ProcessInstanceWorkitem processWorkitem:pInstance.Workitems){
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest(); 
                    pwr.setAction('Approve');
                    pwr.setComments('Approval Request Approved by');
                    pwr.setWorkItemId(processWorkitem.id);
                    processWorkitemRequestList.add(pwr);
                }
            }	
        }
             ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
 

		Test.stopTest();
        
    }
    @isTest
      static void testApprovalProcessCIORejected(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeTaxCodeId;
                
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
				if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;
                }              
                
            }
        
            australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
        budgetTypeTIId=[select id from Pick_Up_Options__c where Name='TI[AU]'].Id;
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;
            }
        }
         
        List<Profile>extraApproverProfile= [select id from profile where Name='Extra Approver' Limit 1];
        User extraUser1=new User(firstname='extra_approver_1',lastname=userinfo.getOrganizationId(),
                                userName='extra_approver_1'+userinfo.getOrganizationId()+'@diageo.com',profileId=extraApproverProfile[0].id,
                                email='Sys_Admin_'+userinfo.getOrganizationId()+'@diageo.com',languagelocaleKey='en_US',
                                LocaleSidKey='en_US',TimeZoneSidkey='America/Los_Angeles',alias='usr1234',EmailEncodingKey='ISO-8859-1',Available_Countries__c='AU');
        insert extraUser1;
        System.assert(extraUser1.Id!=null,'extraUser1 Id should not be null');
         
        User extraUser2=new User(firstname='extra_approver_2',lastname=userinfo.getOrganizationId(),
                                userName='extra_approver_2'+userinfo.getOrganizationId()+'@diageo.com',profileId=extraApproverProfile[0].id,
                                email='Sys_Admin_'+userinfo.getOrganizationId()+'@diageo.com',languagelocaleKey='en_US',
                                LocaleSidKey='en_US',TimeZoneSidkey='America/Los_Angeles',alias='usr1234',EmailEncodingKey='ISO-8859-1',Available_Countries__c='AU');
        insert extraUser2;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;UoM;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        //contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;
         
        ECM_Extra_Approval__c ex1= new ECM_Extra_Approval__c();
        ex1.ECM_Extra_Approval_User__c=extraUser1.Id;
        ex1.ECM_Lower_Limit_Amount__c=8.00;
        ex1.ECM_Upper_Limit_Amount__c=100;
        ex1.ECM_Approver_Position_Name__c='manager';
        ex1.ECM_Type__c='Volume-Based PS';
        ex1.ECM_Active__c=true;
        ex1.ECM_Delegated_Approver_Email_Address__c='name.surname@diageo.com';
        insert ex1;
        
        
        ECM_Extra_Approval__c ex2= new ECM_Extra_Approval__c();
        ex2.ECM_Extra_Approval_User__c=extraUser2.Id;
        ex2.ECM_Lower_Limit_Amount__c=8.00;
        ex2.ECM_Upper_Limit_Amount__c=100;
        ex2.ECM_Approver_Position_Name__c='Director';
        ex2.ECM_Type__c='Volume-Based PS';
        ex2.ECM_Active__c=true;   
        ex2.ECM_Delegated_Approver_Email_Address__c='name.surname2@diageo.com';
        insert ex2;
        
        ECM_Agreement_Approval__c agreementApproval1 = new ECM_Agreement_Approval__c();
            agreementApproval1.ECM_Agreement_Type__c=contractType.id;
            agreementApproval1.ECM_Extra_Approval__c=ex1.id;
        insert agreementApproval1;
        
        ECM_Agreement_Approval__c agreementApproval2 = new ECM_Agreement_Approval__c();
            agreementApproval2.ECM_Agreement_Type__c=contractType.id;
            agreementApproval2.ECM_Extra_Approval__c=ex2.id;
        insert agreementApproval2;
         
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
         
                orgSetting.Run_Triggers__c=false;
        update orgSetting;
         
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
		
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
		  Test.startTest();

        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Provisional';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Tax_Code__c=budgetTypeTaxCodeId;
        insert paymemtSummary;
        
        
         
        paymemtSummary.ECM_Type__c='Volume-Based';
        paymemtSummary.ECM_Payment_Summary_Status__c='Submitted'; 
        paymemtSummary.ECM_Approval_Sub_Status__c='CIO Approval';
        paymemtSummary.ECM_Invoice_Status__c='Approved';
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        update paymemtSummary;
        
         ECM_Payment_Summary_Item__c psItem= new ECM_Payment_Summary_Item__c();
         psItem.ECM_Contract_Item__c=newcontractitem.Id;
         psItem.ECM_Payment_Summary__c=paymemtSummary.Id;
         psItem.ECM_Confirmed_Volume__c=12;
         psItem.ECM_Product__c=product.id;
         psItem.ECM_Confirm__c=true;
         insert psItem;
        
        List<User> extrauser=[select id from user where profile.name='Extra Approver'];
        List<Approval.ProcessWorkitemRequest> processWorkitemRequestList = new List<Approval.ProcessWorkitemRequest>();
       ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        
        List<Approval.ProcessSubmitRequest>reqList= new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
		approvalReq.setObjectId(paymemtSummary.id);
        approvalReq.setNextApproverIds(new List<id>{extrauser[0].id});
        reqList.add(approvalReq);
        
        Approval.ProcessSubmitRequest approvalReq2 = new Approval.ProcessSubmitRequest();
		approvalReq2.setObjectId(paymemtSummary.id);
        approvalReq2.setNextApproverIds(new List<id>{extrauser[1].id});
        reqList.add(approvalReq2);
        
        
                for(ProcessInstance pInstance: [SELECT Id,TargetObjectId, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems),(SELECT Id, ActorId,Actor.Name,StepStatus,OriginalActorId FROM Steps)  FROM ProcessInstance where TargetObjectId=:paymemtSummary.Id order by lastmodifieddate desc limit 1]){
            system.debug(LoggingLevel.Debug,'size--->'+pInstance.Workitems);
            if(pInstance.Workitems!=null && pInstance.Workitems.size()>0){					
                for(ProcessInstanceWorkitem processWorkitem:pInstance.Workitems){
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest(); 
                    pwr.setAction('Reject');
                    pwr.setComments('Approval Request rejected by');
                    pwr.setWorkItemId(processWorkitem.id);
                    processWorkitemRequestList.add(pwr);
                }
            }	
        }
             ECM_PaymentSummaryTriggerHandler.isFirstTime=true;


		Test.stopTest();
        
    }
    @isTest
    static void testEmailHandler(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeTaxCodeId;
                
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
				if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;
                }              
                
            }
        
            australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
        budgetTypeTIId=[select id from Pick_Up_Options__c where Name='TI[AU]'].Id;
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;
            }
        }
         
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;UoM;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        //contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;
         
        
         
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;       
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
          
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
		
        Test.startTest();
		
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Promo-Standard';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Invoice_Status__c ='';
          
        ECM_Payment_Summary__c paymemtSummaryPrePayment = new ECM_Payment_Summary__c();
        paymemtSummaryPrePayment.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummaryPrePayment.ECM_Payment_Summary_Status__c = 'Provisional';
        paymemtSummaryPrePayment.ECM_Type__c = 'Promo-PrePayment';
        paymemtSummaryPrePayment.ECM_Invoice_Status__c='Requested';
        paymemtSummaryPrePayment.ECM_Contract__c = contr.id;
        paymemtSummaryPrePayment.ECM_Start_Period__c = system.today()-300;
        paymemtSummaryPrePayment.ECM_End_Period__c = system.today();
        paymemtSummaryPrePayment.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummaryPrePayment.ECM_Invoice_Status__c ='';
          
          insert new List<ECM_Payment_Summary__c>{paymemtSummaryPrePayment,paymemtSummary};
         
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Payment_Summary_Status__c='Submitted'; 
        paymemtSummaryPrePayment.ECM_Payment_Summary_Status__c ='Submitted';
        
        update new List<ECM_Payment_Summary__c>{paymemtSummaryPrePayment,paymemtSummary};
            
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Tax_Code__c=budgetTypeTaxCodeId;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
       //  paymemtSummary.ECM_Payment_Summary_Status__c='Approved'; 

          
       paymemtSummaryPrePayment.ECM_Tax_Code__c=budgetTypeTaxCodeId;
       paymemtSummaryPrePayment.ECM_Invoice_Status__c ='Approved';
       // paymemtSummaryPrePayment.ECM_Payment_Summary_Status__c ='Approved';
        
        update new List<ECM_Payment_Summary__c>{paymemtSummaryPrePayment,paymemtSummary};
            
                    ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
                    paymemtSummary.ECM_Payment_Summary_Status__c='Approved'; 

                    paymemtSummaryPrePayment.ECM_Payment_Summary_Status__c ='Approved';
        
        update new List<ECM_Payment_Summary__c>{paymemtSummaryPrePayment,paymemtSummary};

            
            
		Test.stopTest();
        
    }
	@isTest
    static void testsendRejectionEmail(){
		
        
        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
        Id budgetTypeTaxCodeId;
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;

                }
               
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;

            }
        }

        

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        
       
        


        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  




        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        


       


        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c=true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        EDGE_UtilityTestClass.createOrgSettings();
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;      
        insert newcontractitem;
        
        
        List<ECM_Payment_Summary__c>paymemtSummarysList= new List<ECM_Payment_Summary__c>();
                  
            
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'In Approval Process';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ecm_tax_code__c=budgetTypeTaxCodeId;
        paymemtSummarysList.add(paymemtSummary);
            
         
        
            
        Database.insert(paymemtSummarysList);
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummarysList[0].id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;
		
         
            
        Test.startTest();
            
         ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
         paymemtSummarysList[0].ECM_Payment_Summary_Status__c='Open';
        update paymemtSummarysList;
     
		Test.stopTest();
        
    }
    @isTest
     static void testinternalorder1(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
        Id budgetTypeTaxCodeId;
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;

                }
               
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;

            }
        }

        

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        


        orgSetting.Run_Triggers__c=false;
        update orgSetting;
        


        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  




        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        

		
       


        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        




        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;      
        insert newcontractitem;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;      
        insert newcontractitem1;// Covers ECM_ContractItemTrigger trigger 
        delete newcontractitem1;


        orgSetting.Run_Triggers__c=false;
        update orgSetting;


        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.Name='IO-567801234';
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today()-1;
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_State__c = 'Australian Capital Territory';
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeTIId;
        internalOrder.ECM_Geography__c = australianGeographyId;
        internalOrder.Owner__c = australiaOperatorAccountId;
        insert internalOrder;
		

        //Test.startTest();
		orgSetting.Run_Triggers__c=true;
        update orgSetting;


		
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        insert paymemtSummary;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;

        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;

        contr.Status='Active';
        contr.ECM_Upfront_Payment_Spent__c=null;
        contr.ECM_Contract_SKU_Specific_Rebate_Paid__c=null;
        update contr;
             
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
		Test.startTest();
        
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Total_Amount_Confirmed__c=20;
        paymemtSummary.ECM_Type__c='Non-Volume';
        paymemtSummary.ECM_Payment_Summary_Status__c='Completed';
        paymemtSummary.ECM_SAP_Payment_Date__c=System.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeAPId;
        update paymemtSummary;
        
     
    }
	@isTest
     static void testinternalOrder2(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
        Id budgetTypeTaxCodeId;
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;

                }
               
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;

            }
        }

        

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;UoM;Brand;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        


        orgSetting.Run_Triggers__c=false;
        update orgSetting;
        


        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  




        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        

		
       


        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        




        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;      
        insert newcontractitem;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;      
        insert newcontractitem1;// Covers ECM_ContractItemTrigger trigger 
        delete newcontractitem1;


        orgSetting.Run_Triggers__c=false;
        update orgSetting;


        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.Name='IO-567801234';
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today()-1;
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_State__c = 'Australian Capital Territory';
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeTIId;
        internalOrder.ECM_Geography__c = australianGeographyId;
        internalOrder.Owner__c = australiaOperatorAccountId;
        insert internalOrder;
		

        //Test.startTest();
		orgSetting.Run_Triggers__c=true;
        update orgSetting;


		
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        insert paymemtSummary;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;

        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;

        contr.Status='Active';
        contr.ECM_Upfront_Payment_Spent__c=null;
        contr.ECM_Contract_SKU_Specific_Rebate_Paid__c=null;
        update contr;
             
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
		Test.startTest();
        
        
        
         ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
         paymemtSummary.ECM_Payment_Summary_Status__c='Completed';
         paymemtSummary.ECM_Budget_types__c = budgetTypeSKUId;
        update paymemtSummary;
       
		Test.stopTest();
        
    }
	@isTest
     static void testinternalOrder3(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
        Id budgetTypeTaxCodeId;
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;

                }
               
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;

            }
        }

        

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;UoM;Brand;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        


        orgSetting.Run_Triggers__c=false;
        update orgSetting;
        


        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  




        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        

		
       


        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        




        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;      
        insert newcontractitem;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;      
        insert newcontractitem1;// Covers ECM_ContractItemTrigger trigger 
        delete newcontractitem1;


        orgSetting.Run_Triggers__c=false;
        update orgSetting;


        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.Name='IO-567801234';
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today()-1;
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_State__c = 'Australian Capital Territory';
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeTIId;
        internalOrder.ECM_Geography__c = australianGeographyId;
        internalOrder.Owner__c = australiaOperatorAccountId;
        insert internalOrder;
		

        //Test.startTest();
		orgSetting.Run_Triggers__c=true;
        update orgSetting;


		
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        insert paymemtSummary;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;

        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;

        contr.Status='Active';
        contr.ECM_Upfront_Payment_Spent__c=null;
        contr.ECM_Contract_SKU_Specific_Rebate_Paid__c=null;
        update contr;
             
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
		Test.startTest();
        
       
       
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Tax_Code__c=budgetTypeTaxCodeId;
		paymemtSummary.ECM_Payment_Summary_Status__c='Approved';
        update paymemtSummary;
        
		Test.stopTest();
        
    }
	@isTest
     static void testinternalOrder4(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
        Id budgetTypeTaxCodeId;
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;

                }
               
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;

            }
        }

        

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        


        orgSetting.Run_Triggers__c=false;
        update orgSetting;
        


        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  




        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        

		
       


        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        




        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;      
        insert newcontractitem;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;      
        insert newcontractitem1;// Covers ECM_ContractItemTrigger trigger 
        delete newcontractitem1;


        orgSetting.Run_Triggers__c=false;
        update orgSetting;


        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.Name='IO-567801234';
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today()-1;
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_State__c = 'Australian Capital Territory';
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeTIId;
        internalOrder.ECM_Geography__c = australianGeographyId;
        internalOrder.Owner__c = australiaOperatorAccountId;
        insert internalOrder;
		

        //Test.startTest();
		orgSetting.Run_Triggers__c=true;
        update orgSetting;


		
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        insert paymemtSummary;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;

        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;

        contr.Status='Active';
        contr.ECM_Upfront_Payment_Spent__c=null;
        contr.ECM_Contract_SKU_Specific_Rebate_Paid__c=null;
        update contr;
             
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
		Test.startTest();
        
        
         ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
         paymemtSummary.ECM_Payment_Summary_Status__c='Completed';
         paymemtSummary.ECM_Budget_types__c = budgetTypePortfolioId;
        update paymemtSummary;
        
		Test.stopTest();
        
    }
	@isTest
     static void testinternalOrder5(){
		
        EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();

        Id australiaOutletAccountId;
        Id australiaOperatorAccountId;
        Id australianGeographyId;
        Id budgetTypeTIId;
        Id budgetTypeAPId;
        Id budgetTypeOtherId;
        Id budgetTypeTrainingId;
        Id budgetTypePortfolioId;
        Id budgetTypeSKUId;
        Id budgetTypePortUpfrontId;
        Id budgetTypeTaxCodeId;
        
        australianGeographyId=[Select id from geography__c where Name='Australia'].Id;
        
   
            for(Pick_Up_Options__c budgetType:[select id,Name from Pick_Up_Options__c]){
                if(budgetType.Name=='TI[AU]'){
                    budgetTypeTIId=budgetType.Id;
                }else if(budgetType.Name=='A&P[AU]'){
                    budgetTypeAPId=budgetType.Id;
                }else if(budgetType.Name=='Training [AU]'){
                    budgetTypeTrainingId=budgetType.Id;
                }else if(budgetType.Name=='Other [AU]'){
                    budgetTypeOtherId=budgetType.Id;
                }else if(budgetType.Name=='Portfolio Rebates [AU]'){
                    budgetTypePortfolioId=budgetType.Id;
                }else if(budgetType.Name=='Upfront Payment [AU]'){
                    budgetTypePortUpfrontId=budgetType.Id;
                }else if(budgetType.Name=='SKU Specific Rebates [AU]'){
                    budgetTypeSKUId=budgetType.Id;
                }else if(budgetType.Name=='TaxCode[AU]'){
                    budgetTypeTaxCodeId=budgetType.Id;

                }
               
                
            }
        
        for(Account acc:[select id,name from account]){
            if(acc.Name==australiaOperatorAccountName){
                australiaOperatorAccountId=acc.Id;
            }else if(acc.Name==australiaOutletAccountName){
                australiaOutletAccountId=acc.Id;

            }
        }

        

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=australianGeographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.CurrencyIsoCode = 'AUD';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;UoM;Brand;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
       // contractType.ECM_Screen_3_field_configuration__c ='Rate Per UoM;Investment';
        insert contractType;
        System.assert(contractType.Id!=null,'contractType Id should not be null');
        


        orgSetting.Run_Triggers__c=false;
        update orgSetting;
        


        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = australiaOutletAccountId,ECM_Agreement_Type__c=contractType.Id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = australiaOutletAccountId,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  




        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=australianGeographyId;
        insert product;
        

		
       


        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(australianGeographyId);
        String geoName = [Select id,name from Geography__c where id=:australianGeographyId].Name;
        mktSetting.ECM_Evidence_email_enabled__c = true;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Contract_Approval_Template__c = geoName=='Spain'?'ECM_Contract_Approval_Template':'ECM_Contract_Approval_Request_Temp_AU';
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=australianGeographyId;
        insert marketassort;
        
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        




        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;      
        insert newcontractitem;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;      
        insert newcontractitem1;// Covers ECM_ContractItemTrigger trigger 
        delete newcontractitem1;


        orgSetting.Run_Triggers__c=false;
        update orgSetting;


        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.Name='IO-567801234';
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today()-1;
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_State__c = 'Australian Capital Territory';
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeTIId;
        internalOrder.ECM_Geography__c = australianGeographyId;
        internalOrder.Owner__c = australiaOperatorAccountId;
        insert internalOrder;
		

        //Test.startTest();
		orgSetting.Run_Triggers__c=true;
        update orgSetting;


		
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Non-Volume';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today()-300;
        paymemtSummary.ECM_End_Period__c = system.today();
        paymemtSummary.ECM_Budget_types__c = budgetTypeTIId;
        PaymemtSummary.ECM_Invoice_Status__c ='Approved';
        insert paymemtSummary;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;

        
        orgSetting.Run_Triggers__c=false;
        update orgSetting;

        contr.Status='Active';
        contr.ECM_Upfront_Payment_Spent__c=null;
        contr.ECM_Contract_SKU_Specific_Rebate_Paid__c=null;
        update contr;
             
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
		Test.startTest();
        
        paymemtSummary.ECM_Tax_Code__c=budgetTypeTaxCodeId;
        paymemtSummary.ECM_Payment_Summary_Status__c='Approved';
        update paymemtSummary;
         ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
         paymemtSummary.ECM_Payment_Summary_Status__c='Completed';
         paymemtSummary.ECM_Budget_types__c = budgetTypePortUpfrontId;
        update paymemtSummary;
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Budget_types__c = budgetTypeTrainingId;
        update paymemtSummary;
        ECM_PaymentSummaryTriggerHandler.isFirstTime=true;
        paymemtSummary.ECM_Budget_types__c = budgetTypeOtherId;
        update paymemtSummary;
		Test.stopTest();
        
    }
	
	
}