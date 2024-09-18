/**********************************************************************
Name: EDGE_DistributorGroupMemberDelete

=======================================================================                                                       
VERSION   AUTHOR            DATE              DETAIL
1.1      Anamika Shukla     7-June-2021     ES20-10235
**************************************************************************************************************************/

public class EDGE_DistributorGroupMemberDelete implements Queueable { 
    Map<Id, List<Id>> acctUserIdMap =new Map<Id, List<Id>>();
    
    public EDGE_DistributorGroupMemberDelete(Map<Id,List<Id>> acctUserIdMap){
        this.acctUserIdMap=acctUserIdMap;
        
    }
    
    public void execute(QueueableContext queCont) {
        if(!Test.isRunningTest()){
            EDGE_AccountTriggerPersonRespHelper.deleteGroupMem(acctUserIdMap);
        }
    }
}