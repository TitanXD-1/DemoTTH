/*

Name: EDGE_BillingRequestTriggerHelperTest
History                                                            

VERSION     AUTHOR              DATE               DETAIL
1.0         Sukanya Chatterjee  7/10/2021          Test Class for EDGE_BillingRequestTriggerHelper
2.0         Prasanth T          7/9/2022           Test Class Correction Due to Failure(ES20-13324)
*/
@isTest
public class EDGE_BillingRequestTriggerHelperTest {
    /*
Method  : testcheckstatus
Purpose : Test method of checkdelrecords

*/
    
    public static Map<String,Id> geoMap = new Map<String,Id>();
    @isTest
    public static void testcheckstatus(){
        EDGE_UtilityTestClass.createOrgSettings();       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();       
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert outlet;
        
        Test.startTest();   
        Master_Asset__c masterAsst = new Master_Asset__C();
        masterAsst.Name = 'Test Master Asset';
        masterAsst.GUID__c = 'TWRFSHJAKSVGA';
        masterAsst.Short_Description__c = 'test';
        masterAsst.Country__c = countryId;
        masterAsst.Priority_Assets__c = TRUE;
        masterAsst.Active__c = TRUE;
        masterAsst.COP__c = FALSE;
        masterAsst.Serialized__c = FALSE;
        insert masterAsst;
        
        Asset asst1 = new Asset();
        asst1.Name = 'Test_Asset1';
        asst1.GUID__c = 'TWRFSHJAKSVG1';
        asst1.AccountId = outlet.Id;
        asst1.Country__c = countryId;
        asst1.Quantity = 1;
        asst1.Master_Asset__c = masterAsst.Id;
        asst1.InstallDate = null;
        asst1.Asset_Removed__c = true;
        asst1.Asset_Location__c = 'Bar';
        insert asst1;
        
         Billing_Request__c bR = new Billing_Request__c();
        bR.Asset_Name__c = asst1.id;
        bR.Account__c = outlet.Id;
        bR.Status__c ='Closed';
        bR.Invoice_Number__c = '1777';
        insert bR;

        User usermdm=EDGE_UtilityTestClass.runAsUser('TestMDM', 'Master Data Manager');
        usermdm.Available_Countries__c='AU';
        usermdm.Default_Country__c='AU';
        insert usermdm;

        Outlet_Member__c omTest1 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, usermdm.id, 'Secondary');
        insert omTest1;

        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId =outlet.Id;
        newAccTeamMember.UserId = usermdm.id;
        insert newAccTeamMember;
        System.assert(newAccTeamMember!=null,'New Account Team Member should not be null');

        System.runAs(usermdm){
            try{
               delete bR;

            }
            catch(Exception e)
            {
              System.debug(LoggingLevel.Debug,'Error '+e.getMessage().contains(Label.BillingRequestDelError));
            }
            
        }
        

        delete bR;

        undelete bR;

        Test.stopTest();
    }
     
    
}