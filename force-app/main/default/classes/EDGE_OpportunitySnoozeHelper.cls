/**********************************************************************
Name: EDGE_OpportunitySnoozeHelper
=======================================================================

History                                                            
-------                                                            
VERSION   AUTHOR            	  DATE              DETAIL
    1.0     Monalisa Halder     28/05/2021      ES20-10171 - (to unlock the opportunity records)
***********************************************************************/
public class EDGE_OpportunitySnoozeHelper {
    
    public static void unlockOpportunityRecords(List<Id> opportunityIdList){
    List<Approval.ProcessWorkitemRequest> reqs = new list<Approval.ProcessWorkitemRequest>();
        Set<Id> processInstanceIdSet = new Set<Id>();
        for(ProcessInstance processInstanceRec : [Select Id , TargetObjectId  from ProcessInstance where TargetObjectId IN :opportunityIdList]){
        	processInstanceIdSet.add(processInstanceRec.Id);  
            
        }
        
        for(ProcessInstanceWorkitem workItem  : [Select Id from ProcessInstanceWorkitem where ProcessInstanceId IN :processInstanceIdSet]){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments('Processed from backend');
            req.setAction('Reject');
            req.setWorkitemId(workItem.Id);
            reqs.add(req);
            }
        	
        Approval.ProcessResult[] result =  Approval.process(reqs);
    }
    
 
}