/*
 * @Name: CRG_GetContractDetailsControllerTest
 * @Description: This class is used to cover test data for the - CRG_GetContractDetailsController
 * @History 
 * VERSION			AUTHOR				DATE				DETAIL
 * 1.0			Saurav Prasad		05/02/2024			Initial Development : 148916 - CRG: Contract Approval email template_SFDC
 * 
 * */
@isTest
public class CRG_GetContractDetailsControllerTest {
    
    @isTest
    public static void testMethodForEmailTemplate(){
        
         Id geographyId = EDGE_UtilityTestClass.setupCountry('GB');
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User usr = new User();
        System.runAs (thisUser) {
            Profile prof = [select id from profile where name=: 'Sales Representative'];
            User usrmngr = new User();
            usrmngr.firstName = 'testManager';
            usrmngr.lastName = 't2';
            usrmngr.profileId = prof.id;        
            usrmngr.email = 'test.MamagerSfdc@test.com';
            usrmngr.Username ='test.MamagerSfdc@test.com';
            usrmngr.Alias='test';
            usrmngr.Timezonesidkey='America/Los_Angeles';
            usrmngr.LocaleSidKey='en_US';
            usrmngr.LanguageLocaleKey='en_US';
            usrmngr.EmailEncodingKey='UTF-8';
            usrmngr.Available_Countries__c='ES';
            insert usrmngr;
            
            usr.firstName = 'test1';
            usr.lastName = 'test2';
            usr.profileId = prof.id;        
            usr.email = 'test.MamagerSfdc1@test.com';
            usr.Username ='test.MamagerSfdc1@test.com';
            usr.Alias='test';
            usr.Timezonesidkey='America/Los_Angeles';
            usr.LocaleSidKey='en_US';
            usr.LanguageLocaleKey='en_US';
            usr.EmailEncodingKey='UTF-8';
            usr.Available_Countries__c='ES';
            usr.ManagerId = usrmngr.Id;
            usr.DelegatedApproverId = usrmngr.Id;
            insert usr;
            System.assert(usr.id!=null,'user id should not be null');
            
            PermissionSet ps = [Select Id from PermissionSet where Name =: 'CRG_AllConfig'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = usr.Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        contractType.ECM_of_Outlets_Tap_Space_Required__c = 0.8;
        insert contractType;
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Contract_Creation_Page__c='Global';
        mktSetting.ECM_Contract_Management_Market__c=true;
        mktSetting.ECM_SAP_Order_Type__c='YPCR';    
        mktSetting.ECM_Mandatory_field_for_Contract__c='SAP Sold To;Legal Name;SAP Ship to;Customer email for Contract;Sales org;';
        mktSetting.ECM_Payment_Management_Email__c='test@test22.com';
        mktSetting.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        insert mktSetting;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        outletAccount.SAP_Ship_to__c = 'sap1234';
        outletAccount.Sales_Org__c = 'sap0987';
        insert outletAccount;
        
        Business_Role__c businessRole =new Business_Role__c();
        businessRole.Name='Spain Mainland';
        businessRole.Country__c=geographyId;
        businessRole.Call_Type__c='Telephone';
        insert businessRole;
        
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= businessRole.Id ;
        ubr.User__c = usr.Id;
        insert ubr;
        
        ECM_Role_Agreement__c  roleAgreement =new ECM_Role_Agreement__c();        
        roleAgreement.Business_Role__c=businessRole.Id;
        roleAgreement.Agreement_Type__c=contractType.Id;
        insert roleAgreement;
        
        Account distr = EDGE_UtilityTestClass.getDistriAccRec();
        distr.Name = 'Test66_Distr';
        distr.Country__c = geographyId;
        distr.Status__c= 'Active';        
        insert distr;
        
        Supplier_Outlet__c suppl = EDGE_UtilityTestClass.suppOutletRec(outletAccount.Id,distr.Id);
        insert suppl;
        
        Test.startTest();
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        insert objContract;
        
        CRG_GetContractDetailsController controller = new CRG_GetContractDetailsController();
        controller.targetObjectId = objContract.Id;
        controller.getContHeaderDetails();
        
        Assert.areEqual(controller.targetObjectId, objContract.Id, 'Expected ID not assigned');
        
        System.assert(controller.targetObjectId != null, 'Contract Id does not exit');
        
        CRG_GetContractDetailsController controller1 = new CRG_GetContractDetailsController();
        try{
        controller1.getContHeaderDetails();
        }catch(Exception ex){
            system.debug(LOGGINGLEVEL.DEBUG,'handled the exception');
        }
        
        Test.stopTest();
        
    }

}