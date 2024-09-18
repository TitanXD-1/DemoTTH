/**
*@ Description Name: EDGE_Send_Market_Cycle_AlertHelper

*@ History :                                                            
1.0    Mayukh S Roy    11/01/2021      US-2429747
**/

public class EDGE_Send_Market_Cycle_AlertHelper {
    public static void sendEmail(List <Market_Cycle__c>  cycles){
    Date current = Date.today();
    Date firstreminder = Date.today()+7;
    Date secondreminder = Date.today()+1;
    
   	Map<Market_Cycle__c,Id> cyclemap = new Map<Market_Cycle__c,Id>();
    Set<Id> GeoIds = new Set<Id>();
        
       for(Market_Cycle__c mark : cycles) {
           if(mark.End_Date__c == firstreminder || mark.End_Date__c == secondreminder){
               cyclemap.put( mark,mark.Id);
               GeoIds.add(mark.Geography__c);
           }
       }
        
       for(Market_Cycle__c nxtcycle:[Select Id,Active__c, Geography__c,Geography__r.Name,Geography__r.MDM_Queue__c,End_Date__c,Start_Date__c,Name from Market_Cycle__c where Geography__c IN :GeoIds and Start_Date__c >= :current ORDER BY Start_Date__c]){
           for(Market_Cycle__c currentcycle : cyclemap.keyset()){
              if(nxtcycle.Start_Date__c ==(currentcycle.End_Date__c+1)){
              	  cyclemap.remove(currentcycle);
     		      }
           		}
             }   
        
       if(!cyclemap.isEmpty())
       {
           EDGE_Send_Market_Cycle_AlertHelper.sendcycleEmail(cyclemap);
       }
       
    }

    
    /**
      *@ Method  : sendEmail

    **/
    public static void sendcycleEmail(Map<Market_Cycle__c,Id> alertmap){
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        for(Market_Cycle__c mark : alertmap.keyset()){
        	List<string> toAddress = new List<string>();
           	DateTime StartDate = mark.Start_Date__c;
            DateTime EndDate = mark.End_Date__c;
            Set<String> setQueueName = new Set<String>();
            Map<string, List<string>> mapActiveQueueMember = new Map<string, List<string>>();
            setQueueName.add(mark.Geography__r.MDM_Queue__c);
                if(setQueueName != null && setQueueName.size()>0 && Schema.sObjectType.GroupMember.isAccessible()){
                    List<GroupMember> lstGroupMember = [SELECT Group.Name, UserOrGroupId, GroupId FROM GroupMember WHERE group.name IN :setQueueName and group.type='Queue'];
                     mapActiveQueueMember = EDGE_Send_Market_Cycle_AlertHelper.getActiveQueueMember(lstGroupMember);
                     }
                if(mapActiveQueueMember.containsKey(mark.Geography__r.MDM_Queue__c)){
                    List<String> allMDMEmail = mapActiveQueueMember.get(mark.Geography__r.MDM_Queue__c);
                    toAddress.addAll(allMDMEmail);                    
                     }
            List<String> paramlist = new List<String>();
            paramlist.add(mark.Geography__r.Name);
            paramlist.add(EndDate.format('dd/MM/YYYY'));
            System.debug('toAddress:::::');
            if(!toAddress.equals(Null) && toAddress.size()>0){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddress);
                mail.setSubject(System.Label.EDGE_Alert_Subject+' '+mark.Geography__r.Name);
                String messageBody='<html><body><br></br>'+System.Label.EDGE_Alert_Body_1+'<br></br>';
                String param = String.format(System.Label.EDGE_Alert_Body_2,paramlist);
                messageBody+=param+'<br></br>Current Market Cycle:<br/>Name: '+mark.Name+'<br/>';
                messageBody+='Start Date: '+StartDate.format('MMMM d, y') + '<br/>End Date: '+EndDate.format('MMMM d, y')+'<br></br>This is an auto generated mail. Please do not reply.</br></br>Thanks & Regards,</br>EDGE Support Team</br></br></body></html>';
                 mail.setHtmlBody(messageBody);
                mailList.add(mail); 
            }
        }
        Messaging.sendEmail(mailList);
    }
    
    
     /**
      *@ Method  : getActiveQueueMember

    **/
    public static Map<string, List<string>> getActiveQueueMember(List<GroupMember> lstGroupMember){
        Map<string, List<string>> mapActiveQueueMember = new Map<string, List<string>>();
        Map<String,List<String>> mapGroupWithMember = new Map<String,List<String>>();
        Map<Id,User> mapActiveUser;
        Set<Id> setUserId = new Set<Id>();
        
        if(lstGroupMember != null && lstGroupMember.size()>0){
            for(GroupMember groupMember : lstGroupMember){
                setUserId.add(groupMember.UserOrGroupId);
                if(mapGroupWithMember.containsKey(groupMember.Group.Name)){
                    mapGroupWithMember.get(groupMember.Group.Name).add(groupMember.UserOrGroupId);
                } else {
                    mapGroupWithMember.put(groupMember.Group.Name, new List<String> {groupMember.UserOrGroupId });
                }
            }
            
            if(setUserId != null && setUserId.size()>0){
                mapActiveUser = new Map<Id,User>([SELECT Id, isActive, Email FROM User WHERE Id IN :setUserId AND isActive = True]);
            }            
            
            //Iterate over mapSalesmembers to get only active member list
            if(mapGroupWithMember.size()>0){
                for(string queueName : mapGroupWithMember.keySet()){
                    List<String> approverList =  mapGroupWithMember.get(queueName);
                    List<String> activeApproverist = new List<String>();
                    if(mapActiveUser != null && mapActiveUser.size()>0){
                        for(String userId : approverList){
                            if(mapActiveUser.containsKey(userId)){
                                activeApproverist.add(mapActiveUser.get(userId).Email);
                            }
                        }
                        mapActiveQueueMember.put(queueName, activeApproverist);
                    }
                }
            }
        }
        return mapActiveQueueMember;
    }
}