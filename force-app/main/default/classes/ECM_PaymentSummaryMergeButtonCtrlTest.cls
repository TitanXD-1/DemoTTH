/*
@Name: ECM_PaymentSummaryMergeButtonCtrlTest
@description: This Class is to cover the "ECM_PaymentSummaryMergeButtonCtrl" 
@History                                                            

VERSION			AUTHOR				DATE				DETAIL
1.0			Saurav Prasad		02/02/2023			Initial Development
*/
@isTest
public class ECM_PaymentSummaryMergeButtonCtrlTest {
    public static Id contractId;
    public static String paySumVolume;
    public static string paySumPromoStd;
    @isTest 
    public static void test1(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 Asian Highway1 45';
        insert acc;
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        update acc;
        
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractType.Id);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()));
        contractlst.add(contr1);
        insert contractlst;  
        
        contr.Status = 'Active';
        update contr;
        
        AccountContactRelation aCR = new AccountContactRelation();
        aCR.AccountId = acc.id;
        aCR.ContactId = con.id;
        aCR.Contact_Type__c = 'Primary';
        aCR.IsActive = true;
        insert aCR;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        
        ECM_Payment_Summary__c paymentSummary = new ECM_Payment_Summary__c();
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Total_Amount_Forecasted__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary.ECM_Type__c = 'Volume-Based';
        paymentSummary.ECM_Invoice_Status__c='Requested';
        paymentSummary.ECM_Contract__c = contr.id;
        paymentSummary.ECM_Start_Period__c = system.today();
        paymentSummary.ECM_End_Period__c = system.today()+30;
        paymentSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary.ECM_Invoice_Status__c ='Approved';
        paymentSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary.ECM_approval_sub_status__C = 'Manager Approval';
        paymentSummary.ECM_Manager_Approver__c=userinfo.getUserId();
        paymentSummary.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        //PaymentSummary.ECM_Contract__r.Id = contr.id;
        insert paymentSummary;
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Total_Amount_Forecasted__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Invoice_Status__c='Requested';
        paymentSummary2.ECM_Contract__c = contr.id;
        paymentSummary2.ECM_Start_Period__c = system.today()+30;
        paymentSummary2.ECM_End_Period__c = system.today()+60;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        PaymentSummary2.ECM_Email_Sent__c =false;
        //PaymentSummary2.ECM_Contract__r.Id = contr.id;
        insert paymentSummary2;
        
        ECM_Payment_Summary__c paymentSummary3 = new ECM_Payment_Summary__c();
        paymentSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary3.ECM_Total_Amount_Forecasted__c = 20.00;
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary3.ECM_Type__c = 'Volume-Based';
        paymentSummary3.ECM_Invoice_Status__c='Requested';
        paymentSummary3.ECM_Contract__c = contr.id;
        paymentSummary3.ECM_Start_Period__c = system.today()+60;
        paymentSummary3.ECM_End_Period__c = system.today()+90;
        paymentSummary3.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary3.ECM_Invoice_Status__c ='Approved';
        paymentSummary3.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary3.ECM_Email_Sent__c =false;
        //PaymentSummary3.ECM_Contract__r.Id = contr.id;
        insert paymentSummary3;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Market_Assortment_Product__c marketAssort = new Market_Assortment_Product__c();
        marketAssort.Product__c=product.Id;
        marketAssort.Market_Assortment__c=geographyId;
        marketAssort.ECM_INTO_Material__c = 9;
        insert marketAssort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketAssort.id;
        insert newcontractitem;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymentSummaryItem.ECM_Confirmed_Volume__c =10;
        paymentSummaryItem.ECM_Planned_Amount_Per_Payment__c =10;
        paymentSummaryItem.ECM_Updated_Forecasted_Volume__c =10;    
        insert paymentSummaryItem;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem2 = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem2.ECM_Payment_Summary__c = paymentSummary2.id;
        paymentSummaryItem2.ECM_Confirm__c = true;
        paymentSummaryItem2.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem2.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymentSummaryItem2.ECM_Confirmed_Volume__c =10;
        PaymentSummaryItem2.ECM_Planned_Amount_Per_Payment__c =10;
        paymentSummaryItem2.ECM_Updated_Forecasted_Volume__c =10;    
        insert paymentSummaryItem2;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem3 = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem3.ECM_Payment_Summary__c = paymentSummary3.id;
        paymentSummaryItem3.ECM_Confirm__c = true;
        paymentSummaryItem3.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem3.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymentSummaryItem3.ECM_Confirmed_Volume__c =10;
        paymentSummaryItem3.ECM_Planned_Amount_Per_Payment__c =10;
        paymentSummaryItem3.ECM_Updated_Forecasted_Volume__c =10;    
        insert paymentSummaryItem3;
        
        Test.startTest();
        String query = 'SELECT ID,';
        List<Schema.FieldSetMember> fieldSetPaySum = Schema.SObjectType.ECM_Payment_Summary__c.fieldSets.ECM_PS_Merge_Fields.getFields();
        for(Schema.FieldSetMember field : fieldSetPaySum) {
            query += field.getFieldPath() + ', ';
        }
        query += 'ECM_Contract__r.OwnerId FROM ECM_Payment_Summary__c WHERE ECM_Payment_Summary_Status__c=\''+String.escapeSingleQuotes(System.Label.ECM_Open_Status)+
            '\''+' AND ECM_Type__c=\''+String.escapeSingleQuotes(System.Label.ECM_PSType_VolumeBased)+'\''+'AND ECM_Contract__c=\''+contr.Id+'\'';
        query += ' WITH SECURITY_ENFORCED ORDER BY ECM_End_Period__c DESC';
        List <ECM_Payment_Summary__c>selectedPSList = Database.query(query);
        
        ECM_PaymentSummaryMergeButtonCtrl.getPaymentSummaryDetails(paymentSummary.id, 'ECM_Payment_Summary__c');
        ECM_PaymentSummaryMergeButtonCtrl.mergePaymentSummary(selectedPSList);
        System.assertNotEquals('Cancelled', paymentSummary.ECM_Payment_Summary_Status__c,'OK');
        Test.stopTest();
    }
    @isTest
    public static void setupDataGB(){
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB');
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 North Highway1 45';
        insert acc;
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale69';
        acc.SAP_Sold_to__c ='sapsoldto';
        update acc;
        
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test1';
        con.Email = 'test_setup@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractType.Id);
        Insert contr; 
        contractId = contr.Id;
        contr.Status = 'Active';
        update contr;
        
        AccountContactRelation aCR = new AccountContactRelation();
        aCR.AccountId = acc.id;
        aCR.ContactId = con.id;
        aCR.Contact_Type__c = 'Primary';
        aCR.IsActive = true;
        insert aCR;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        budgetTypeObj.Name='TI[GB]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[GB]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        
        ECM_Payment_Summary__c paymentSummary = new ECM_Payment_Summary__c();
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary.ECM_Type__c = 'Promo-Standard';
        paymentSummary.ECM_Invoice_Status__c='Requested';
        paymentSummary.ECM_Contract__c = contr.id;
        paymentSummary.ECM_Start_Period__c = system.today();
        paymentSummary.ECM_End_Period__c = system.today()+2;
        PaymentSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary.ECM_Invoice_Status__c ='Approved';
        paymentSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary.ECM_approval_sub_status__C = 'Manager Approval';
        paymentSummary.ECM_Manager_Approver__c=userinfo.getUserId();
        paymentSummary.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        insert paymentSummary;
        paySumPromoStd = paymentSummary.Id;
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Invoice_Status__c='Requested';
        paymentSummary2.ECM_Contract__c = contr.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        //PaymentSummary2.ownerid = uid;
        insert paymentSummary2;
        paySumVolume = paymentSummary2.Id;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Market_Assortment_Product__c marketAssort = new Market_Assortment_Product__c();
        marketAssort.Product__c=product.Id;
        marketAssort.Market_Assortment__c=geographyId;
        marketAssort.ECM_INTO_Material__c = 9;
        insert marketAssort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketAssort.id;
        insert newcontractitem;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Confirmed_Volume__c = 1;
        paymentSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem2 = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem2.ECM_Payment_Summary__c = paymentSummary2.id;
        paymentSummaryItem2.ECM_Confirm__c = true;
        paymentSummaryItem2.ECM_Confirmed_Volume__c = 1;
        paymentSummaryItem2.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem2.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem2;
        System.assertNotEquals('Open', paymentSummary.ECM_Payment_Summary_Status__c, 'OK');
        
    }
    @isTest
    public static void positiveTestCase(){
        setupDataGB();
        Test.startTest();
        ECM_PaymentSummaryMergeButtonCtrl.PSMergeWrapper psWrpr = ECM_PaymentSummaryMergeButtonCtrl.getPaymentSummaryDetails(paySumVolume,'ECM_Payment_Summary__c');
        System.assertEquals(paySumVolume, psWrpr.triggeredPsRecord.Id, 'Ok');
        Test.stopTest();
    }

}