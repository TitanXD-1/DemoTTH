/**********************************************************************
Name: PNR_CustomerCaseControllerTest
=======================================================================
Req: This is the test class for the  PNR_CustomerCaseController class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Sudipta Nandi     07/02/2019      Initial Development

***********************************************************************/
@isTest
public class PNR_CustomerCaseControllerTest {
    @isTest 
    static void validatemethod(){
        
        //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        System.runAs ( testadminUser ) {
           
            // Customer creation
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account cust= PNR_TestDataUtility.getDirectCustomerRec();
            cust.Country__c=countryId;
            insert cust;
           
            Case caseInfo = new Case();
            caseInfo.Description = 'Test Description';
            caseInfo.Origin = 'Email';
            caseInfo.Priority = 'Low';
            caseInfo.Status = 'New';
            caseInfo.AccountId = cust.Id;
            caseInfo.Type = 'Dispute - Pricing';
            insert caseInfo;
                      
            List<Case> caseDetails =  PNR_CustomerCaseController.fetchCustomerCases(cust.Id);
           //check the Case Deatils list
            system.assertnotEquals(caseDetails,null);
           // Sprint 10 Changes start
            List<String> recTypeList= PNR_CustomerCaseController.fetchRecordTypeValues();
            system.assertnotEquals(recTypeList,null);
            
            Id ids= PNR_CustomerCaseController.getRecTypeId('Other');
            system.assertnotEquals(ids,null); 
            // Sprint 10 Changes end
        }
    }
}