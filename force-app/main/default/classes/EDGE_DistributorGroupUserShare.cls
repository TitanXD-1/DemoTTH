/**********************************************************************
Name: EDGE_DistributorGroupUserShare

=======================================================================                                                       
VERSION   AUTHOR            DATE              DETAIL
1.1      Anamika Shukla     28-April-2021    ES20-10036 (for this story created methods are shareDistToPersonResp,prepAccountTeamMember,createGroup,AddToGroups,grpMemCreate,shareDistUser)
*****************************************************/
public class EDGE_DistributorGroupUserShare implements Queueable {   
    Map<Id, Set<Id>> distIdToPersonRepIds =new Map<Id, Set<Id>>();
    Set<String> groupNames=new Set<String>();
    
    public EDGE_DistributorGroupUserShare(Map<Id, Set<Id>> distIdToPersonRepIds, Set<String> groupNames) {
        this.distIdToPersonRepIds = distIdToPersonRepIds;
        this.groupNames = groupNames;
    }
    public void execute(QueueableContext queCont) {
        System.debug('EDGE_DistributorGroupUserShare > distIdToPersonRepIds = ' + distIdToPersonRepIds);
        System.debug('EDGE_DistributorGroupUserShare > groupNames = ' + groupNames);
        if(distIdToPersonRepIds != null && groupNames != null){
        	EDGE_AccountTriggerPersonRespHelper.shareDistUser(distIdToPersonRepIds, groupNames);   
        }
        
       
    }   
}