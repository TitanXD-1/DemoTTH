/**********************************************************************
Name: EDGE_DistributorGroupManager

=======================================================================                                                       
VERSION   AUTHOR            DATE              DETAIL
1.1      Anamika Shukla     28-April-2021    ES20-10036 (for this story created methods are shareDistToPersonResp,prepAccountTeamMember,createGroup,AddToGroups,grpMemCreate,shareDistUser)
**************************************************************************************************************************/

public class EDGE_DistributorGroupManager implements Queueable {
    List<GroupMember> listGroupMember = new List<GroupMember>();
    Map<Id, Set<Id>> distIdToPersonRepIds =new Map<Id, Set<Id>>();
    Set<String> groupNames=new Set<String>();
    public EDGE_DistributorGroupManager(List<GroupMember>listGroupMember , Map<Id, Set<Id>> distIdToPersonRepIds, Set<String> groupNames) {
        this.listGroupMember = listGroupMember;
        this.distIdToPersonRepIds=distIdToPersonRepIds;
        this.groupNames=groupNames;
    }
    public void execute(QueueableContext queCont) {
        System.debug('listGroupMember from EDGE_DistributorGroupManager =' + listGroupMember);
        EDGE_AccountTriggerPersonRespHelper.grpMemCreate(listGroupMember, distIdToPersonRepIds, groupNames);
        if(!Test.isRunningTest()){
            if(distIdToPersonRepIds != null && groupNames != null){
                System.enqueueJob(new EDGE_DistributorGroupUserShare(distIdToPersonRepIds,groupNames));
            }
        }        
    }
    
    }