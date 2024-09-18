/**********************************************************************
Name: PNR_CaseDetailInformationTest
=======================================================================
Req: This is the test class for the  PNR_CaseDetailInformation class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Juned Khan        16/07/2019      Initial Development
***********************************************************************/
@isTest
public class PNR_CaseDetailInformationTest {
    
    @isTest 
    static void validatedmethod(){
        
        //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('TL','PNR_Teamlead');    
        insert testadminUser;
        User usr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];
        Test.startTest();
        System.runAs (usr) {
           
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account cust= PNR_TestDataUtility.getDirectCustomerRec();
            cust.Country__c=countryId;
            cust.KUNNR__c='Test';
            cust.Central_Billing_Block__c='Blocked';
            cust.Central_Order_Block__c='Live';
            insert cust;
            
            Account cust1= PNR_TestDataUtility.getDirectCustomerRec();
            cust1.Country__c=countryId;
            cust1.KUNNR__c='Test1';
            cust1.Central_Billing_Block__c='Live';
            cust1.Central_Order_Block__c='Blocked';
            insert cust1;
            
            Invoice__c inv = PNR_TestDataUtility.getPNRInvoiceData();
            inv.Payer_Number__c=cust.Id;
            inv.Account__c = cust.Id;
            Insert inv;
            
            Invoice__c inv1 = PNR_TestDataUtility.getPNRInvoiceData();
            inv1.Payer_Number__c=cust1.Id;
            inv1.Account__c=cust1.Id;
            Insert inv1;
            
            List<case> csList = new List<Case>();
            Case cse =PNR_TestDataUtility.getCaseData();
            cse.AccountId=cust.Id;
            cse.Reference_Invoice__c=inv.Id;
            //insert cse;
            csList.add(cse);
            Case cse1 =PNR_TestDataUtility.getCaseData();
            cse1.AccountId=cust1.Id;
            cse1.Reference_Invoice__c=inv1.Id;
            //insert cse1;
            csList.add(cse1);
            insert csList;
            Case caserec =  PNR_CaseDetailInformation.fetchCaseDetailInfo(csList[0].Id);
            
            //check the Invoice record
            System.assertNotEquals(caserec,null);
            Case caserec1 =  PNR_CaseDetailInformation.fetchCaseDetailInfo('a0n9E000003AMPYQA4');
            //check the Invoice record
            System.assertEquals(caserec1,null);
            
            // check for one case
            // Check for Single reference
            String checkIsActive =  PNR_CaseDetailInformation.isActiveCust(csList[0].Id,true);
            //check the the record presence
            System.assertNotEquals(checkIsActive,null);
            // Check for Multiple reference
            String isActive =  PNR_CaseDetailInformation.isActiveCust(csList[0].Id,false);
            //check the the record presence
            System.assertNotEquals(isActive,null);
            
            // check for another case
            // Check for Single reference
            String cIsActive =  PNR_CaseDetailInformation.isActiveCust(csList[1].Id,true);
            //check the record presence
            System.assertNotEquals(cIsActive,null);
            // Check for Multiple reference
            String iActive =  PNR_CaseDetailInformation.isActiveCust(csList[1].Id,false);
            //check the record presence
            System.assertNotEquals(iActive,null);
            
            Boolean cordocexist=PNR_CaseDetailInformation.isCorrectionExist(csList[1].Id);
            //check the record presence
            System.assertNotEquals(cordocexist,true);
            
            String cordocexistWithInv=PNR_CaseDetailInformation.isCorrectionExistWithInvNumber(csList[1].Id);
            //check the record presence
            System.assertNotEquals(cordocexistWithInv,null);
            
        }
        Test.stopTest();
    }
}