/**********************************************************************
Name: ECM_CreateOngoingPaymentSummaryForAU
=======================================================================
Purpose: This is Class for Creating Payment Summaries for Australian Contracts
TestClass: ECM_CreatePaymentSummaryForAU_Test
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Pradeep Kumar Reddy     29/10/2020        ECM-3048: Creating Payment Summaries for Australian Contracts
***********************************************************************/ 
public class ECM_CreateOngoingPaymentSummaryForAU {
    @InvocableMethod
    public static void insertPaymentSummaries(List<Contract> contracts){
        Pick_Up_Options__c pickUpOption = [Select id, Name from Pick_Up_Options__c where Name='Upfront Payment [AU]'];
        list<ECM_Payment_Summary__c> ongoingPaymentSummaryList = new List<ECM_Payment_Summary__c>();
        for(contract con: contracts){
            decimal upfrontPaymentLoanOverTerm = con.ECM_Total_Upfront_Payment_Loan_Over_Term__c;
            decimal upfrontPaymentSpent = con.ECM_Upfront_Payment_Spent__c;

            if(upfrontPaymentLoanOverTerm == null){
                upfrontPaymentLoanOverTerm = 0;
            }
            if(upfrontPaymentSpent == null){
                upfrontPaymentSpent = 0;
            }
            
            if((upfrontPaymentLoanOverTerm - upfrontPaymentSpent) > 0){
                decimal uosUpfrontTarget = con.ECM_UOS_Upfront_Target__c;
                if(uosUpfrontTarget == null){
                    uosUpfrontTarget = 0;
                }
                decimal uosEarnt = con.UOS_Earnt__c;
                if(uosEarnt == null){
                    uosEarnt = 0;
                }
                decimal upfrontPaymentInstalment = con.ECM_Upfront_Payment_Instalment__c;
                if(upfrontPaymentInstalment == null){
                    upfrontPaymentInstalment = 0;
                }
                if(upfrontPaymentSpent > 0 && uosEarnt >= uosUpfrontTarget){
                    ECM_Payment_Summary__c ps = new ECM_Payment_Summary__c();
                    ps.ECM_Contract__c = con.Id;
                    ps.ECM_Budget_types__c = pickUpOption.Id;
                    ps.ECM_Type__c = 'Non-Volume';
                    ps.ECM_Payment_Summary_Status__c = 'Open';
                    ps.ECM_Total_to_be_Invoiced__c = upfrontPaymentInstalment;
                    ps.ECM_UoS_Total__c = uosEarnt;
                    ongoingPaymentSummaryList.add(ps);
                }
            }
        }
        if(ongoingPaymentSummaryList.size()>0){
            insert ongoingPaymentSummaryList;
        }
    }
}