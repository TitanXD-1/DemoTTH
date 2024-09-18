/*
* @Name: EDGE_AccTeamMemQueueable
* @Req: This is Queueable class for EDGE_OutletMemberAccountTeamSync

* @History                                                            
                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*   1.0		Joshraj,Rajarshi  01/11/2022      ES20-13475
*/
public class EDGE_AccTeamMemQueueable implements Queueable {
 	
    List<AccountTeamMember> listOfATM;
    String mode;
    
    
    public EDGE_AccTeamMemQueueable(List<AccountTeamMember> listOfATM, String mode){
        this.listOfATM = listOfATM;
        this.mode = mode;
        
    }

    public void execute(QueueableContext context) {
       if(mode == 'Insert'){
        if(listOfATM.size()>0 && listOfATM != null)
        {
            Database.upsert(listOfATM);}
                            
       } 
       else if(mode == 'Delete'){//ES20-13475
        if(listOfATM.size()>0 && listOfATM != null)//ES20-13475
        {//ES20-13475
            Database.delete(listOfATM);}//ES20-13475
                            
       }//ES20-13475 
    }
}