/**********************************************************************
Name: EDGE_CoachingReportTriggerHelper
=======================================================================
Req: ES20-4641 - Coaching form PDF sharing rules
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0      Dipanjan D        16-09-2019        Initial Development
***********************************************************************/
public with sharing class EDGE_CoachingReportTriggerHelper {
    
/*******************************************************************
Method  : createCustomShareRep
Purpose : This methods used to create custom sharing for Sales Rep.
********************************************************************/  
    public static void createCustomShare(Map<Id, SObject> newItems){
        
        List<Coaching_Report__Share> crShareList = new List<Coaching_Report__Share>();
        for(SObject crSobject : newItems.values()){
            Coaching_Report__c cr = (Coaching_Report__c)crSobject;  
            if(cr.Sales_Representative__c != null){
                Coaching_Report__Share crShareRep = new Coaching_Report__Share();
                crShareRep.ParentId = cr.Id;
                crShareRep.UserOrGroupId = cr.Sales_Representative__c;
                crShareRep.AccessLevel = 'Read';
                crShareList.add(crShareRep);                
            }
            if(cr.Current_Sales_Manager__c != null){
                Coaching_Report__Share crShareManager = new Coaching_Report__Share();
                crShareManager.ParentId = cr.Id;
                crShareManager.UserOrGroupId = cr.Current_Sales_Manager__c;
                crShareManager.AccessLevel = 'Edit';
                crShareList.add(crShareManager);                    
            }           
        }
        
        if(crShareList != null && crShareList.size()>0){
            Database.insert(crShareList,false);
        }   
        
    }   
    
}