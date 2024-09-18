/*
* @Name: EDGE_AccTeamMemInsDelQueueable
* @Req: This is Queueable class for inserting and deleting AccountTeamMembers

* @History                                                            
                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*   1.0      Mayukh SRoy       06/12/2022        ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction	
*/


public class EDGE_AccTeamMemInsDelQueueable implements Queueable {
 	
    Map<String,List<AccountTeamMember>> listOfATM;
    
    public EDGE_AccTeamMemInsDelQueueable(Map<String,List<AccountTeamMember>> listOfATM){
        this.listOfATM = listOfATM;
    }

    public void execute(QueueableContext context) {
       if(listOfATM.containskey('Insert') && listOfATM.get('Insert')!=Null && listOfATM.get('Insert').size()>0)
        {
            Database.upsert(listOfATM.get('Insert'));
        }
        if(!Test.isRunningTest() && listOfATM.containskey('Delete') && listOfATM.get('Delete')!=Null && listOfATM.get('Delete').size()>0) 
        {
            System.enqueueJob(new EDGE_AccTeamMemQueueable(listOfATM.get('Delete'), 'Delete'));
        }
	}
}