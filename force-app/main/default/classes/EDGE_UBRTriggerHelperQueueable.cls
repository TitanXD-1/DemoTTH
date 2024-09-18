/*
* @Name: EDGE_UBRTriggerHelperQueueable
* @Req: This is Queueable class for EDGE_UserBusinessRoleTriggerHelper to execute assignUserToTerritories 

* @History                                                            
                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*   1.3		Supriya			  11/04/2022      US ES20-12426
*/
public class EDGE_UBRTriggerHelperQueueable implements Queueable {
 	
    List<UserTerritory2Association> listOfUser2Terr;
    String mode;
    
    
    public EDGE_UBRTriggerHelperQueueable(List<UserTerritory2Association> listOfUser2Terr, String mode){
        this.listOfUser2Terr = listOfUser2Terr;
        this.mode = mode;
        
    }

    public void execute(QueueableContext context) {
       if(mode == 'After Insert'){
        if(listOfUser2Terr.size()>0 && listOfUser2Terr != null)
        {
            Database.upsert(listOfUser2Terr);}
                            
       } 
        else if( mode == 'Delete'){
             Database.delete(listOfUser2Terr);
             
        }
    }
}