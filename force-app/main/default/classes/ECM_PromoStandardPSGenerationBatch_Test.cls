@isTest
public class ECM_PromoStandardPSGenerationBatch_Test {
    
    @isTest
    public static void createPromoStandardPSTest() {
        
        ECM_PromoStandardPSGenerationSchedule batchCls = new ECM_PromoStandardPSGenerationSchedule();
        String sch = '0 0 23 * * ?';
        system.schedule('Promo Stnd PS Generation', sch, batchCls);
        System.assert(sch!=null,'sch should not be null');
        
    } 
    @testsetup
    public static void createData()
    {
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        insert pickupOption;       
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = geographyId;
        outletAccount.Independent_of_Operator__c = true;
        outletAccount.Independent_of_Operator__c = true;
        insert outletAccount;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.StartDate=System.today()-1;
        objContract.Contract_End_Date__c = System.today()+1;
        insert objContract;
        objContract.Status = 'Active';
        update objContract;
        
    }
}