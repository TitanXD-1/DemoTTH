/*
@Name: ECM_PS_ApprovalProcess_Queueable
@Test Class: ECM_PaymentSummaryTriggerHelperTest
@Description: This is class will initaiate Approval processes for Payment Summary
@
@History                                                            
@AUTHOR                       DATE              DETAIL
@Manikandan.T     		  28/07/2021        Initial Development for ECM-4567 and ECM-4569 
*/
public class ECM_PS_ApprovalProcess_Queueable implements Queueable {
    
     List<Id> newPaySumList;
     Map<id,List<Id>> paymentSummaryUserIds;
     Map<Id,String> userRoles;
    
   public ECM_PS_ApprovalProcess_Queueable(List<Id> newPaySumList,Map<id,List<Id>> paymentSummaryUserIds, Map<Id,String> userRoles){
       this.newPaySumList=newPaySumList;
       this.paymentSummaryUserIds=paymentSummaryUserIds;
       this.userRoles=userRoles;
        
   }
    
    public void execute(QueueableContext bc){
        
           try{
          List<ECM_Payment_Summary__c> paymentSummaryList=  [select id,ECM_Approval_Sub_Status__c,ECM_Payment_Summary_Status__c,ecm_contract__r.ownerid  from ECM_Payment_Summary__c where id IN:newPaySumList ];
            List<Approval.ProcessSubmitRequest> approvalRequestList = new List<Approval.ProcessSubmitRequest>();
               for(ECM_Payment_Summary__c paymentSummary:paymentSummaryList ){
                   
                   for(Id user:paymentSummaryUserIds.get(paymentSummary.Id)){
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    if(userRoles!=null && userRoles.get(user)!=null){
                        req1.setComments(Label.ECM_User_Role+userRoles.get(user)+Label.ECM_Comments);
                    }else{
                        req1.setComments('Request for Approval.');
                    }
                    req1.setObjectId(paymentSummary.Id);
                    req1.setNextApproverIds(new List<Id>{user});
                    if( paymentSummary.ecm_contract__r!=null && paymentSummary.ecm_contract__r.ownerid!=null){
                        req1.setSubmitterId(paymentSummary.ecm_contract__r.ownerid);
                    }
                    approvalRequestList.add(req1);
            }
               }

    
            List<Approval.ProcessResult> result = Approval.process(approvalRequestList);
            }catch(Exception e){
                system.debug('exception:'+e.getMessage());
            }
                
    }

}