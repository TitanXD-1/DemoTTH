/**********************************************************************
Name: ECM_CreateFirstPaymentSummaryForAU
=======================================================================
Purpose: This is Class for Creating Payment Summaries for Australian Contracts
TestClass: ECM_CreatePaymentSummaryForAU_Test
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Pradeep Kumar Reddy     29/10/2020        ECM-3048: Creating Payment Summaries for Australian Contracts
***********************************************************************/ 
public class ECM_CreateFirstPaymentSummaryForAU {
    @InvocableMethod
    public static void insertPaymentSummaries(List<Contract> contracts){
        system.debug('Contracts==> '+contracts);
        Pick_Up_Options__c pickUpOption = [Select id, Name from Pick_Up_Options__c where Name='Upfront Payment [AU]'];
        list<ECM_Payment_Summary__c> firstPaymentSummaryList = new List<ECM_Payment_Summary__c>();
        list<Id>seletedPaymentScheduleList= new List<Id>();
        for(contract con: contracts){
            
            if(con.ECM_Selected_Payment_Schedule_AU__c!=null){
            
                seletedPaymentScheduleList.add(con.ECM_Selected_Payment_Schedule_AU__c);
            }
        
        }
        
        Map<id,ECM_Payment_Frequency__c>paymentFrequencyRecords= new Map<id,ECM_Payment_Frequency__c>([select id,ECM_Type__c from ECM_Payment_Frequency__c where id IN:seletedPaymentScheduleList]);
        
        for(contract con: contracts){
            decimal upfrontPaymentLoanOverTerm = con.ECM_Total_Upfront_Payment_Loan_Over_Term__c;
            decimal upfrontPaymentSpent = con.ECM_Upfront_Payment_Spent__c;

            if(upfrontPaymentLoanOverTerm == null){
                upfrontPaymentLoanOverTerm = 0;
            }
            if(upfrontPaymentSpent == null){
                upfrontPaymentSpent = 0;
            }


                if(con.ECM_Selected_Payment_Schedule_AU__c!=null && paymentFrequencyRecords.get(con.ECM_Selected_Payment_Schedule_AU__c)!=null && paymentFrequencyRecords.get(con.ECM_Selected_Payment_Schedule_AU__c).ECM_Type__c=='Retrospective'){
                
                    if(upfrontPaymentSpent == 0){
                
                    decimal uosEarnt = con.UOS_Earnt__c;
                        if(uosEarnt == null){
                            uosEarnt = 0;
                        }
                        ECM_Payment_Summary__c ps = new ECM_Payment_Summary__c();
                        ps.ECM_Contract__c = con.Id;
                        ps.ECM_Budget_types__c = pickUpOption.Id;
                        ps.ECM_Type__c = 'Non-Volume';
                        ps.ECM_Payment_Summary_Status__c = 'Open';
                        ps.ECM_UoS_Total__c = uosEarnt;
                        ps.ECM_Total_to_be_Invoiced__c= con.ECM_Upfront_Payment_Instalment__c;
                        firstPaymentSummaryList.add(ps);
                    }
                }else{

                    if((upfrontPaymentLoanOverTerm - upfrontPaymentSpent) > 0 && upfrontPaymentSpent == 0){
                
                        decimal upfrontPrePaymentAmount = con.ECM_Upfront_Pre_payment_amount__c;
                        if(upfrontPrePaymentAmount == null){
                            upfrontPrePaymentAmount = 0;
                        }
                        decimal uosEarnt = con.UOS_Earnt__c;
                        if(uosEarnt == null){
                            uosEarnt = 0;
                        }
                        ECM_Payment_Summary__c ps = new ECM_Payment_Summary__c();
                        ps.ECM_Contract__c = con.Id;
                        ps.ECM_Budget_types__c = pickUpOption.Id;
                        ps.ECM_Type__c = 'Non-Volume';
                        ps.ECM_Payment_Summary_Status__c = 'Open';
                        ps.ECM_UoS_Total__c = uosEarnt;     
                        ps.ECM_Total_to_be_Invoiced__c = upfrontPrePaymentAmount;
                        firstPaymentSummaryList.add(ps);
                    }               
                }               
            }
        
        if(firstPaymentSummaryList.size()>0){
            insert firstPaymentSummaryList;
        }
    }
}