/**
* @Description: EDGE_PersonRespAccTeamMemberAdd

* @Purpose: To delete Account Team Member when Person Responsible is removed from an Operator
* @History:                                                            

* @VERSION    AUTHOR               DATE           DETAIL

*	1.0		 Monalisa Halder	12-Sep-2022		 ES20-13286
*   1.1		 Monalisa Halder    27-04-2022		 ES20-13988 - UAT _ Operator Person Responsible
*/
public without sharing  class EDGE_PersonRespAccTeamMemberAdd implements Queueable,Database.AllowsCallouts{  //ES20-13988 //Changed to without sharing to allow MDMs to delete AccountTeamMembers
    List<AccountTeamMember> accteamMemberAdd = new List<AccountTeamMember>();
    
    public EDGE_PersonRespAccTeamMemberAdd(List<AccountTeamMember>accTeamToBeAddedUpdated){
        this.accteamMemberAdd = accTeamToBeAddedUpdated;
        
    }
    
    public void execute(QueueableContext bc){
        if(accteamMemberAdd.size() > 0){
            Database.SaveResult[] listinserted = Database.insert(accteamMemberAdd,false); 
            for(Database.SaveResult dsr : listinserted){
            if(dsr.getErrors() != null && dsr.getErrors().size() > 0){
                for(Database.Error err : dsr.getErrors()){
                    System.debug('Error - '+err.getMessage()+' - '+dsr.getId());
                }
            }
        }
        }
    }
    
}