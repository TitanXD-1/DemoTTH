/**
* @Description: EDGE_PersonRespAccTeamMemberDelete

* @Purpose: To delete Account Team Member when Person Responsible is removed from an Operator
* @History:                                                            

* @VERSION    AUTHOR               DATE           DETAIL

*	1.0		 Monalisa Halder	12-Sep-2022		 ES20-13286
*   1.1		 Monalisa Halder    27-04-2022		 ES20-13988 - UAT _ Operator Person Responsible
*/
public without sharing  class EDGE_PersonRespAccTeamMemberDelete implements Queueable,Database.AllowsCallouts{ //ES20-13988 //Changed to without sharing to allow MDMs to create AccountTeamMembers

    List<AccountTeamMember> accteamMemberDelete = new List<AccountTeamMember>();
    List<AccountTeamMember> accteamMemberAdd = new List<AccountTeamMember>();
    
    public EDGE_PersonRespAccTeamMemberDelete( List<AccountTeamMember>accTeamToBeRemoved,List<AccountTeamMember>accTeamToBeAddedUpdated){
        this.accteamMemberDelete = accTeamToBeRemoved;
        this.accteamMemberAdd = accTeamToBeAddedUpdated;
        
    }
    
    public void execute(QueueableContext bc){
        if(accteamMemberDelete.size() > 0){
            Database.delete(accteamMemberDelete,false); 
        }
        if(!Test.isRunningTest()){
            if(accteamMemberAdd != null && accteamMemberAdd.size() > 0){
               System.enqueueJob(new EDGE_PersonRespAccTeamMemberAdd(accteamMemberAdd));
            }
        }
       
    }
   
}