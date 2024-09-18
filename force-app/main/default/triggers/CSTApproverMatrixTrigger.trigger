/**
@Name: CSTApproverMatrixTrigger

@Purpose: This is to handle CST Approver Matrix Events
@History                                                             
VERSION     AUTHOR          DATE              DETAIL
1.0         CST Team     10/08/2021        Initial Development
**/



trigger CSTApproverMatrixTrigger on Approver_Matrix__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
	  TriggerDispatcher.run(new CSTApproverMatrixHandler());
}