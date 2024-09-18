/*
Name: Crg_ContractHelper
*
Purpose: Contract Record creation with Cold Room Grant Record Type
*
History                                                            
*                                                            
VERSION     AUTHOR              DATE                DETAIL
1.0         Joshraj Sen         27/12/2023          146153
2.0         Joshraj Sen         29/01/2024          150507
2.1			Saurav Prasad       30/01/2024          150544 - QA_Defect: Unable to Cancel the CRG contract in Screen 1 & Screen 2
2.2			Saurav Prasad		20/03/2024			151023 - CRG Enhancements: Outlet search/auto-populate_SFDC
*/
@isTest
public class Crg_ContractHelperTest {

    @isTest
    public static void testCrgContractHelper()
    {
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB'); 
        System.assert(geographyId!=null,'Geography Record Added');
        List<Pick_Up_Options__c> pickUps=Crg_ContractHelperTest.getPickupOptions(geographyId);
        List<Account> accounts=Crg_ContractHelperTest.getAccounts(pickUps[0]);
        Test.startTest();
        Market_Setting__c ms=EDGE_UtilityTestClass.getMarketSetting(geographyId); 
        ms.ECM_Mandatory_field_for_Contract__c='VAT number;SAP Sold to;SAP Ship to;Customer email for Contract;Legal Name;Sales org;Tax Identification number';
        insert ms;
        ECM_Contract_Type__c contractType=Crg_ContractHelperTest.getAgreementType(geographyId);
        String recordTypeId=Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();
        Contract contract=EDGE_UtilityTestClass.getContract(accounts[0].Id,recordTypeId);
        contract.ECM_Agreement_Type__c=contractType.Id;
        contract.Name='Test Contract 123';
        contract.CRG_Total_Investment__c=50000;
        contract.OwnerId=[Select Id from User where Name like '%Admin 2%' Limit 1][0].Id;
        insert contract;
        //String outletId=outletAccount.Id;
        /*Date endDate=System.today().addDays(50);
        String endDateString=String.valueOf(endDate);
        Map<String,String> dataFromOutletMainPageMap=new Map<String,String>();
        dataFromOutletMainPageMap.put('selectedOutlet',accounts[0].Id);    
        dataFromOutletMainPageMap.put('legalName','Test Legal');  
        dataFromOutletMainPageMap.put('agreementType',contractType.Id);
        dataFromOutletMainPageMap.put('contractName','Test Contract 123');
        dataFromOutletMainPageMap.put('contrStartDate',String.valueOf(System.today()));
        dataFromOutletMainPageMap.put('contrEndData',endDateString);
        dataFromOutletMainPageMap.put('selectedDuration',String.valueOf(50));
        dataFromOutletMainPageMap.put('contractStatus','Draft');
        String dataFromOutletMainPage=JSON.serialize(dataFromOutletMainPageMap);
        // System.debug('Value of dataFromOutletMainPage '+dataFromOutletMainPage);
        String dataFromPaymentPage = '{"refrigerationContractorValue":"test_Data","outletTradeAffiliationValue":"VFI","typeOfEquipmentOptionValue":"Cold-room","equipmentStatusValue":"New","powerprovidedforSurge20X_Value":true,"waterprovidedforSurge20X_Value":true,"installationDateValue":"2024-01-13","totalNumberofDiageoTapsValue":"3","totalNumberOfDiageoBrandsValue":"3","totalCostOfRefrigerationValue":"3004","diageoInvestmentEurosValue":"12","paymentMethodValue":"A/C Credit","paymentFrequencyValue":"Upfront","notesCommentsValue":"Hello","totalNumberofBrandsInOutletValue":"4"}';
        Test.stopTest();
        Crg_ContractHelper.AccountWrapper acc=new Crg_ContractHelper.AccountWrapper();
        acc=Crg_ContractHelper.getAccountById(accounts[0].Id);
        String output='';
        output=Crg_ContractHelper.checkMarketingSettingFieldValues(accounts[0].Id);
        Contract contr=new Contract();
        contr=Crg_ContractHelper.createContractRecord(dataFromOutletMainPage,dataFromPaymentPage,'In Approval Process');*/
        Crg_ContractHelper.ObjectWrapper occ=new Crg_ContractHelper.ObjectWrapper();
        occ=Crg_ContractHelper.saveContractForSubmit(JSON.serialize(contract));
        //150544
		Crg_ContractHelper.cancelOffer(contract.Id); 
        Account acc = accounts[0];
        acc.SAP_Sold_to__c = '';
        acc.New_VAT__c = '';
        acc.ECM_Legal_Name__c = '';
        acc.SAP_Ship_to__c = '';
        acc.Email_for_contracts_payments__c = '';
        acc.Sales_Org__c = '';
        acc.VAT_Number__c = '';
        String str = Crg_ContractHelper.validateMandatory(ms,acc);
        system.assert(str != null,'str should not be null');
        Assert.areNotEqual(str, null, 'str should not be null');
    }
    public static List<Pick_Up_Options__c> getPickupOptions(String geographyId)
    {
        List<Pick_Up_Options__c> pickUps=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickUps.add(pickupOption); 
        insert pickUps;
        return pickUps;
    }
    public static List<Account> getAccounts(Pick_Up_Options__c pickUp)
    {
        List<Account> accounts=new List<Account>();
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickUp.Id; 
        outletAccount.VAT_Number__c='123';
        outletAccount.SAP_Ship_to__c='124';
        outletAccount.SAP_Sold_to__c='125';
        outletAccount.Email_for_contracts_payments__c='test.test@diageo.com';
        outletAccount.Sales_Org__c='IS01';
        outletAccount.ECM_Legal_Name__c='Test Legal';
        outletAccount.New_VAT__c='126';
        accounts.add(outletAccount);
        insert outletAccount;
        Account operator=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Person_Responsible__c=userinfo.getUserId();
        insert operator;
        accounts.add(operator);
        return accounts;
    }
    public static ECM_Contract_Type__c getAgreementType(String geographyId)
    {
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        contractType.ECM_of_Outlets_Tap_Space_Required__c = 0.8;
        contractType.CRG_Cold_Room_Grant__c=true;
        contractType.CRG_Allow_Multiple_CRG_contracts__c=true;
        contractType.ECM_Automatic_approval_amount_threshold__c=500;
        insert contractType;
        return contractType;
        
    }
    @testsetup
    public static void createUsers()
    {
        User testadminUser = EDGE_UtilityTestClass.runAsUser('AdminManager','System Administrator');    
        testadminUser.Email='test.test1@diageo.com';
        testadminUser.Title='Test Manager';
        testadminUser.Username='test.test1@diageo.com.edge.dev2';
        insert testadminUser;
        User testadminUser2 = EDGE_UtilityTestClass.runAsUser('Admin 2','System Administrator');    
        testadminUser2.ManagerId=testadminUser.Id;
        testadminUser2.DelegatedApproverId=testadminUser.Id;
        testadminUser2.Email='test.test2@diageo.com';
        testadminUser2.Username='test.test2@diageo.com.edge.dev2';
        insert testadminUser2;
    }
    

}