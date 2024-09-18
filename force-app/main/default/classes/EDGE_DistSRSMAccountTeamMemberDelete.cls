/**********************************************************************
Name: EDGE_DistSRSMAccountTeamMemberDelete
Purpose: Delete Distributor Sales User from Account Team Member
=======================================================================                                                       
VERSION    AUTHOR           DATE             DETAIL
1.1       Aparajita     15-June-2021       ES20-10310
***********************************************************************/
public class EDGE_DistSRSMAccountTeamMemberDelete implements Queueable { 
    List<AccountTeamMember> atmToDeleteList = new List<AccountTeamMember>();
    
    public EDGE_DistSRSMAccountTeamMemberDelete(List<AccountTeamMember> atmToDeleteList){
        this.atmToDeleteList=atmToDeleteList;      
    }
    
    public void execute(QueueableContext queCont) {
        Set<Id> atmIds = (new Map<Id,AccountTeamMember>(atmToDeleteList)).keySet();
        List<AccountTeamMember> atmList = [Select Id from AccountTeamMember where Id IN : atmIds];
        if(atmList.size()>0)
            delete atmList;     
    }
}