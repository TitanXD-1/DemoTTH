@isTest
public without sharing class TriggersHandlerManagerTest {
    
    @testSetup
    static void setup(){
        User u = new User(Id = UserInfo.getUserId());
        u.TriggersDebugs__c = 'triggerCanDebug';
        u.TriggersDebugs__c = 'triggerCanDebugButBypassed';
        u.TriggersByPass__c = 'triggerBypassedInUser';
        update u;
    }

    @isTest
    static void bypassTriggerTest(){
        //Comment: Add Trigger to bypass

        //When
        TriggersHandlerManager.byPassTrigger('testTrigger');

        //Then
        system.assert(TriggersHandlerManager.isByPassTrigger('testTrigger'));

        //Remove the trigger from bypass
        //When
        TriggersHandlerManager.removeByPassTrigger('testTrigger');
        //Then
        system.assert(!TriggersHandlerManager.isByPassTrigger('testTrigger'));
    }

    @isTest
    static void canAutoDebugTest(){
        //Comment: 

        //Given
        User u = [SELECT Id, TriggersDebugs__c FROM User WHERE Id =: UserInfo.getUserId()];

        //When
        Boolean canDebug;
        system.runAs(u){
            canDebug = TriggersHandlerManager.canAutoDebug('triggerCanDebug');
        }

        //Then
        system.assert(canDebug);
    }

    @isTest
    static void cannotAutoDebugTest(){
        //Comment: 

        //Given
        User u = [SELECT Id, TriggersDebugs__c FROM User WHERE Id =: UserInfo.getUserId()];
        TriggersHandlerManager.byPassTrigger('triggerCanDebugButBypassed');

        //When
        Boolean canDebug;
        system.runAs(u){
            canDebug = TriggersHandlerManager.canAutoDebug('triggerCanDebugButBypassed');
        }

        //Then
        system.assert(!canDebug);
    }

    @isTest
    static void canTriggerTest(){
        //Comment: 

        //Given
        User u = [SELECT Id, TriggersDebugs__c FROM User WHERE Id =: UserInfo.getUserId()];
        TriggersHandlerManager.byPassTrigger('triggerBypassed');

        //When
        Boolean canRun1;
        Boolean canRun2;
        Boolean canRun3;
        system.runAs(u){
            canRun1 = TriggersHandlerManager.canTrigger('triggerBypassed');
            canRun2 = TriggersHandlerManager.canTrigger('triggerBypassedInUser');
            canRun3 = TriggersHandlerManager.canTrigger('triggerCanRun');   
        }

        //Then
        system.assert(!canRun1);
        system.assert(!canRun2);
        system.assert(canRun3);
    }

    @isTest
    static void getTriggerListFilteredTest(){
        //Comment: 
        
        //Given
        List<User> userList = [SELECT Id, UserName, ProfileId FROM User ORDER BY CreatedDate DESC LIMIT 10];
        set<Id> profileIdsSet = new set<Id>();
        for(User u: userList){
        	profileIdsSet.add(u.ProfileId);
        }

        TriggersHandlerManager.triggerOld = userList;
        TriggersHandlerManager.triggerNew = userList;

        //When
        TriggersHandlerManager.TriggerFiltered filteredResultUserName = TriggersHandlerManager.getTriggerListFiltered('UserName');
        TriggersHandlerManager.TriggerFiltered filteredResultProfile = TriggersHandlerManager.getTriggerListFiltered('ProfileId');
        TriggersHandlerManager.TriggerFiltered filteredResultNull = TriggersHandlerManager.getTriggerListFiltered(null);

        //Then
        system.assertEquals(userList.size(), filteredResultUserName.triggerNewFiltered.keySet().size());
        system.assertEquals(userList.size(), filteredResultUserName.triggerOldFiltered.keySet().size());
        system.assertEquals(profileIdsSet.size(), filteredResultProfile.triggerNewFiltered.keySet().size());
        system.assertEquals(profileIdsSet.size(), filteredResultProfile.triggerOldFiltered.keySet().size());
        system.assert(filteredResultNull.triggerNewFiltered.keySet().isEmpty());
        system.assert(filteredResultNull.triggerOldFiltered.keySet().isEmpty());
    }

}