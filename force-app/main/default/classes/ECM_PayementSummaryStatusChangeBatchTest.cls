/*
*Name: ECM_PayementSummaryStatusChangeBatchTest

*Purpose: This class is used to cover test data for the - ECM_PayementSummaryStatusChangeBatch

*History                                                          
                                                            
*VERSION    AUTHOR        DATE              DETAIL
*1.0        Pravalika     30/03/2020        Initial Development

*/
@isTest
public class ECM_PayementSummaryStatusChangeBatchTest {
    @isTest
    public static void paymentSummaryCal(){
 Test.startTest();
          createPaymentSummaryTest();
        try{  
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_PayementSummaryStatusChangeBatch'
                                                      and Country_Code__c ='ES' ];
            
            
            String className = batchSetting.Batch_Class__c;  
            System.assert(className!=null,'className should not be null');     
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        Test.stopTest();
       

        
    }

   static void createPaymentSummaryTest() {
       String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type;
        type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountryPL('ES');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        System.assert(newuser!=null,'newuser should not be null');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
       contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
       contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
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
        Acc1.Country__c=geographyId;
        acc1.IsOperator__c = true;
        insert acc1;
        
        Account acc2 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc2.Person_Responsible__c = UserInfo.getUserId();
        acc2.IsOperator__c = true;
        insert acc2;
        
        Account acc3 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc3.Person_Responsible__c = UserInfo.getUserId();
        acc3.IsOperator__c = true;
        acc3.Country__c=geographyId;
        insert acc3;
        
        Account acc4 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc4.Person_Responsible__c = UserInfo.getUserId();
        acc4.IsOperator__c = true;
        acc4.Country__c=geographyId;
        insert acc4;
        
        
        Date myDate = system.today().addmonths(-1);
        Date myStartDate = system.today().addmonths(-6);
        
        Contract con1 = new Contract(Name = 'Test',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId=acc1.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con1;
        
        Contract con2 = new Contract(Name = 'Test2',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc3.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con2;
        
        Contract con3 = new Contract(Name = 'Test3',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc4.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
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
        budgetTypeObj1.Name='A&P [ES]';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.Status__c = 'Active';
        budgetTypeObj1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        insert budgetTypeObj1;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='TI [ES]';
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
        
        ECM_Contract_Item__c eci = new ECM_Contract_Item__c();
        eci.ECM_MAT_override__c = 20.00;
        eci.ECM_Contract__c = con1.id;
        eci.ECM_MAT_UOS__c = 20.00;
        eci.ECM_Total_GP__c = 20.00;
        eci.ECM_Total_COGS__c = 20.00;
        eci.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eci.ECM_Total_GP_ON__c = 20.00;
        eci.ECM_Product__c=marketproduct.id;       
        insert eci;
        
        ECM_Contract_Item__c eci2 = new ECM_Contract_Item__c();
        eci2.ECM_MAT_override__c = 20.00;
        eci2.ECM_Contract__c = con1.id;
        eci2.ECM_MAT_UOS__c = 20.00;
        eci2.ECM_Total_GP__c = 20.00;
        eci2.ECM_Total_COGS__c = 20.00;
        eci2.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci2.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci2.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eci2.ECM_Total_GP_ON__c = 20.00;
        eci2.ECM_Product__c=marketproduct2.id;       
        insert eci2;
        
        ECM_Contract_Item__c eci3 = new ECM_Contract_Item__c();
        eci3.ECM_MAT_override__c = 20.00;
        eci3.ECM_Contract__c = con2.id;
        eci3.ECM_MAT_UOS__c = 20.00;
        eci3.ECM_Total_GP__c = 20.00;
        eci3.ECM_Total_COGS__c = 20.00;
        eci3.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci3.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci3.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eci3.ECM_Total_GP_ON__c = 20.00;
        eci3.ECM_Product__c=marketproduct3.id;       
        insert eci3;
        
        ECM_Contract_Item__c eci4 = new ECM_Contract_Item__c();
        eci4.ECM_MAT_override__c = 20.00;
        eci4.ECM_Investment__c=10;
        eci4.ECM_UoM__c='8.20';
        eci4.ECM_Volume__c=10;
        eci4.ECM_Contract__c = con3.id;
        eci4.ECM_MAT_UOS__c = 20.00;
        eci4.ECM_Total_GP__c = 20.00;
        eci4.ECM_Total_COGS__c = 20.00;
        eci4.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci4.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci4.ECM_Total_SKU_Specific_Rebate__c= 10.00;
        eci4.ECM_Total_GP_ON__c = 20.00;
        eci4.ECM_Product__c=marketproduct4.id;       
        insert eci4;
        Market_Setting__c market= new Market_Setting__c();
        market.Name='Spain Setting';
        market.Geography__c=geographyId;
        market.ECM_Budget_Type_for_Volume_Based_PS__c = budgetTypeObj2.Id;
        market.ECM_Manager_Approval__c = 'Promo-Standard;Volume-Based;Promo-PrePayment';
        insert market;
        
        ECM_Sales_Driver__c sd = new ECM_Sales_Driver__c();
        sd.Name='test';
        sd.Geography__c=geographyId;
        
        sd.ECM_Budget_Type__c=budgetTypeObj2.Id;
        insert sd;
        
        
        ECM_Sales_Driver_Item__c sdi = new ECM_Sales_Driver_Item__c();
        sdi.Contract__c= con3.Id;
        sdi.ECM_Sales_Driver__c=SD.Id;
        sdi.ECM_Payment_Frequency__c=paymentFrequency.Id;
        sdi.ECM_Investement_Description__c='TEST';
        insert sdi;
        
        ECM_Sales_Driver_Item_Detail__c sdid = new ECM_Sales_Driver_Item_Detail__c();
        sdid.ECM_Investment_Amount__c=100;
        sdid.ECM_Sales_Driver_Item__c=SDI.id;
        sdid.ECM_Product__c=eci4.id;
        insert sdid;
       
        List<ECM_Payment_Summary__c>  payList=new List<ECM_Payment_Summary__c>();
        
       ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
       paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
       paymemtSummary2.ECM_Payment_Summary_Status__c = 'Provisional';
       paymemtSummary2.ECM_Type__c = 'Promo-PrePayment';
       paymemtSummary2.ECM_Invoice_Status__c='Requested';
       paymemtSummary2.ECM_Contract__c = con1.id;
       paymemtSummary2.ECM_Start_Period__c = system.today()-6;
       paymemtSummary2.ECM_End_Period__c = system.today()-2;
       paymemtSummary2.ECM_Budget_types__c = budgetTypeObj2.id;
       paymemtSummary2.ECM_Invoice_Status__c ='Approved';
        //paymemtSummary3.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        payList.add(paymemtSummary2);
       
        ECM_Payment_Summary__c paymemtSummary3 = new ECM_Payment_Summary__c();
        paymemtSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary3.ECM_Payment_Summary_Status__c = 'Provisional';
        paymemtSummary3.ECM_Type__c = 'Promo-Standard';
        paymemtSummary3.ECM_Invoice_Status__c='Requested';
        paymemtSummary3.ECM_Contract__c = con1.id;
        paymemtSummary3.ECM_Start_Period__c = system.today()-6;
        paymemtSummary3.ECM_End_Period__c = system.today()-2;
        paymemtSummary3.ECM_Budget_types__c = budgetTypeObj2.id;
        paymemtSummary3.ECM_Invoice_Status__c ='Approved';
        //paymemtSummary3.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary3.ECM_Email_Sent__c =false;
        payList.add(paymemtSummary3);
       insert payList;
       
       List<ECM_Payment_Summary__c> lstCont = [select id,ECM_End_Period__c,ECM_Type__c,ECM_Payment_Summary_Status__c,ECM_Contract__r.Account.country__r.code__c from ECM_Payment_Summary__c where Id = :paymemtSummary3.id and ECM_End_Period__c<=TODAY and ECM_Contract__r.Account.country__r.code__c='ES'];
       system.debug(LoggingLevel.Debug,'lstCont->'+lstCont);
    
    }
}