/*
*@Name: ECM_PsPdfController_Test
*@Description: This test class is used to cover the methods of ECM_PsPdfController
*@History                                                                                                                       

VERSION			AUTHOR					DATE				DETAIL
*1.0		Rajarshi Lahiri			21/02/2023			   ECM-6746 : Payment Summary Document_Templates_SFDC		
*1.1		Tanishq Banerjee		24/02/2023			   ECM-6767 : Payment Summary Document_Dynamic fields_SFDC
*1.2        Sakshi Shah             14/05/2024             PMD Fix
*/


@istest
public class ECM_PsPdfController_Test {
    @isTest 
    public static void getsummarydetailstest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('DE');
        //Id uid = userinfo.getUserId();
         
        String localSegmentRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        String outVisitPriortRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        List<Pick_Up_Options__c> pickOptList=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption1= ECM_UtilityTestClass.createPickUpOption(geographyId,localSegmentRecordTypeId);
        pickupOption1.Name='FR[DE]';
        pickupOption1.Geography__c=geographyId;
        pickupOption1.ECM_SAP_Order_reason__c = 'Y10'; 
        pickupOption1.ECM_SAP_Pricing_condition__c = 'O25';
		pickupOption1.Type__c='Local-Segment1';
        pickupOption1.Status__c='Active';
        pickOptList.add(pickupOption1);
        
        Pick_Up_Options__c pickupOption2= ECM_UtilityTestClass.createPickUpOption(geographyId,outVisitPriortRecordTypeId);
        pickupOption2.Name='GOLD[DE]';
        pickupOption2.Geography__c=geographyId;
        pickupOption2.ECM_SAP_Order_reason__c = 'Y10'; 
        pickupOption2.ECM_SAP_Pricing_condition__c = 'O25';
        pickupOption2.Type__c='Outlet Visit Prioritization';
        pickupOption2.Status__c='Active';
        pickOptList.add(pickupOption2);
        
        
        insert pickOptList;
                
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 Asian Highway1 45';
        insert acc;
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        //acc.Local_Segment1__c = pickupOption1.id;
        acc.Outlet_Visit_Prioritisation_Grade__c = pickupOption2.id;
        update acc;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        
        AccountContactRelation accConRel= [SELECT Id,Display_Contact__c FROM AccountContactRelation WHERE AccountId =:acc.id WITH SECURITY_ENFORCED];        
        accConRel.Display_Contact__c = true;
        update accConRel;
        
        
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
        contractType.ECM_Language_for_Customer_Email__c='de';
        insert contractType; 
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractType.Id);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()));
        contractlst.add(contr1);
        insert contractlst;
        
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Volume-Based';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today();
        paymemtSummary.ECM_End_Period__c = system.today()+2;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_approval_sub_status__C = 'Manager Approval';
        paymemtSummary.ECM_Manager_Approver__c=userinfo.getUserId();
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        insert paymemtSummary;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;
        
        Test.startTest();
        
        PageReference pageRef = Page.ECM_PsPdfGeneration;
        pageRef.getParameters().put('Id', String.valueOf(paymemtSummary.Id));
		pageRef.getParameters().put('loadPDF', 'true');
        Test.setCurrentPage(pageRef);
        
        PageReference pageRef1 = Page.ECM_PsPdfGenerationValidation;        
        pageRef1.getParameters().put('Id', String.valueOf(paymemtSummary.Id));
		pageRef1.getParameters().put('loadPDF', 'false');
        Test.setCurrentPage(pageRef1);
   		
		ECM_PsPdfController vf1=null;
        vf1=new ECM_PsPdfController();
        ApexPages.standardController controller=new ApexPages.standardController(paymemtSummary);
        ECM_PsPdfController vf2=null;
        vf2=new ECM_PsPdfController(controller);
        
        ECM_PSPDFValidationHelper vfp1 = null;
        vfp1=new ECM_PSPDFValidationHelper();
		ECM_PSPDFValidationHelper vfp2=null;
        vfp2=new ECM_PSPDFValidationHelper(controller);
        
        ECM_PSPDFValidationHelper.CustomWrapper wrap = new ECM_PSPDFValidationHelper.CustomWrapper();
        wrap = ECM_PSPDFValidationHelper.generatePsPDF(paymemtSummary.Id);
        System.assert(wrap.isSuccess,true);  
        
        Test.stopTest();
        
    }
}