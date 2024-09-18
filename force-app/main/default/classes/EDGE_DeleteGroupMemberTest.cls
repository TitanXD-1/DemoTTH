/**********************************************************************
Name: EDGE_DeleteGroupMemberTest
=======================================================================
Req: 
User Story : 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0      Preyanka Ghosh     14/05/2019      Initial Development
***********************************************************************/
@isTest
public class EDGE_DeleteGroupMemberTest {
    
    @isTest
    static void test(){
        Set<Id> setDeleteGroupMember = new Set<Id>();
        Map<Id, Id> mapDeleteGroupId = new Map<Id, Id>();
        List<GroupMember> lstGroupMember = new List<GroupMember>();        
        
        Test.startTest();
        
        String groupName = 'MarketTestTH1'+EDGE_Constant.EDGE_GROUP_UP;
        Group objUpGroup = new Group(Name = groupName, DeveloperName = groupName);
        insert objUpGroup;
        System.assert(objUpGroup != null,'objUpGroup Inserted');
        
        groupName = 'HubTestTH1'+EDGE_Constant.EDGE_GROUP_DOWN;
        Group objDownGroup = new Group(Name = groupName, DeveloperName = groupName);
        insert objDownGroup; 
        System.assert(objDownGroup != null,'objDownGroup Inserted');
        
        groupName = 'MarketTestTH2'+EDGE_Constant.EDGE_GROUP_UP;
        Group objUpGroup1 = new Group(Name = groupName, DeveloperName = groupName);
        insert objUpGroup1;
        
        groupName = 'HubTestTH2'+EDGE_Constant.EDGE_GROUP_DOWN;
        Group objDownGroup1 = new Group(Name = groupName, DeveloperName = groupName);
        insert objDownGroup1;
        
        GroupMember objGroupMember = new GroupMember();
        objGroupMember.UserOrGroupId = objDownGroup.Id;
        objGroupMember.GroupId = objUpGroup.Id;
        lstGroupMember.add(objGroupMember);
        
        GroupMember objGroupMember1 = new GroupMember();
        objGroupMember1.UserOrGroupId = objDownGroup1.Id;
        objGroupMember1.GroupId = objUpGroup1.Id;
        insert objGroupMember1;
        
        setDeleteGroupMember.add(objUpGroup1.Id);
        setDeleteGroupMember.add(objDownGroup1.Id);
        mapDeleteGroupId.put(objUpGroup1.Id,objDownGroup1.Id);
        
        EDGE_DeleteGroupMember batchTest = new EDGE_DeleteGroupMember(setDeleteGroupMember, mapDeleteGroupId, lstGroupMember);
        Database.executeBatch(BatchTest);
        Test.stopTest();
    }
    
}