/**********************************************************************
Name: EDGE_DeleteGroupMember
=======================================================================
Req: 
User Story : 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0      Preyanka Ghosh     14/05/2019      Initial Development
***********************************************************************/
public class EDGE_DeleteGroupMember implements Database.Batchable<sObject> {
    
    Set<Id> setDeleteGroupMember = new Set<Id>();
    Map<Id, Id> mapDeleteGroupId = new Map<Id, Id>();
    List<GroupMember> lstGroupMember = new List<GroupMember>();
    
    //Constructor initialization
    public EDGE_DeleteGroupMember(Set<Id> setDeleteGroupMember, Map<Id, Id> mapDeleteGroupId, List<GroupMember> lstGroupMember) {
        this.setDeleteGroupMember = setDeleteGroupMember;
        this.mapDeleteGroupId = mapDeleteGroupId;
        this.lstGroupMember = lstGroupMember;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){        
        return DataBase.getQueryLocator([SELECT Id,GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN: setDeleteGroupMember]);        
    }
    
    public void execute(Database.BatchableContext bc, List<GroupMember> lstExistGroupMember){
		List<GroupMember> lstDeleteGroupMember = new List<GroupMember>();        
        for(GroupMember objGM : lstExistGroupMember){
            if(mapDeleteGroupId.containsKey(objGM.GroupId) && mapDeleteGroupId.get(objGM.GroupId) == objGM.UserOrGroupId){
                lstDeleteGroupMember.add(objGM);
            }                        
        }
        System.debug('lstDeleteGroupMember:::'+lstDeleteGroupMember);
        if(lstDeleteGroupMember != null && lstDeleteGroupMember.size()>0){
            Database.delete(lstDeleteGroupMember);
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        if(lstGroupMember != null && lstGroupMember.size()>0){
            Database.insert(lstGroupMember);
        }
        
    }


}