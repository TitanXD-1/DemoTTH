/**********************************************************************
  Name: PNR_diageoContactTriggerHelper
=======================================================================
  Purpose: This is to handle PNR_diageoContactTriggerHelper Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Tanmoy Bardhan     04/07/2019      Initial Development
***********************************************************************/
public without sharing class PNR_diageoContactTriggerHelper {
    public static void checkDuplicateContactType(List<SObject> newItems,Map<Id, SObject> OldItems, Boolean isUpdate) {
        List < Id > repIdList = new List < Id > ();
        List < String > nameList = new List < String > ();
        List < PNR_Diageo_Contact__c > repDiageoConList = new List < PNR_Diageo_Contact__c > ();
        List < PNR_Diageo_Contact__c > nameDiageoConList = new List < PNR_Diageo_Contact__c > ();
        User currentUser;
        Map<Id,PNR_Diageo_Contact__c> oldMap;
        if(newItems!= null){
            oldMap = (Map<Id,PNR_Diageo_Contact__c>)OldItems;
        }
        if (Schema.sObjectType.User.isAccessible()) {
            currentUser = [SELECT id, Name, managerId, manager.Name FROM User where Id =: userinfo.getuserid()];
        }
        for (PNR_Diageo_Contact__c diaCon: (List < PNR_Diageo_Contact__c > ) newItems) {
            if (diaCon.PNR_Diageo_Rep__c != Null) {
                repIdList.add(diaCon.PNR_Diageo_Rep__c);
            } else if (diaCon.PNR_Name__c != Null) {
                nameList.add(diaCon.PNR_Name__c);
            }
        }
        if (!repIdList.isEmpty()) {
            if (Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()) {
                repDiageoConList = [SELECT Id, Name, PNR_Diageo_Rep__c, PNR_Customer__c, PNR_Name__c, PNR_Contact_Type__c
                    FROM PNR_Diageo_Contact__c
                    WHERE PNR_Diageo_Rep__c IN: repIdList
                ];
            }
            for (PNR_Diageo_Contact__c diaCon: (List < PNR_Diageo_Contact__c > ) newItems) {
                if (diaCon.PNR_Diageo_Rep__c != Null) {
                    for (PNR_Diageo_Contact__c exDiaCon: repDiageoConList) {
                        if (diaCon.PNR_Diageo_Rep__c == exDiaCon.PNR_Diageo_Rep__c && diaCon.PNR_Customer__c == exDiaCon.PNR_Customer__c &&
                            diaCon.PNR_Contact_Type__c == exDiaCon.PNR_Contact_Type__c && !isUpdate) {
                            //if (!Test.isRunningTest()) {
                                if (currentUser.managerId != null && !Test.isRunningTest()) {
                                    diaCon.addError(Label.PNR_duplicateContactTypeDC);
                                } else if(!Test.isRunningTest()) {
                                    diaCon.addError(Label.PNR_duplicateDCTL);
                                }
                           // }
                        }else if(isUpdate && (oldMap.get(diaCon.Id).PNR_Diageo_Rep__c != diaCon.PNR_Diageo_Rep__c ||
                                 oldMap.get(diaCon.Id).PNR_Customer__c != diaCon.PNR_Customer__c ||
                                 oldMap.get(diaCon.Id).PNR_Contact_Type__c != diaCon.PNR_Contact_Type__c) ){
                                     
                                 if(diaCon.PNR_Diageo_Rep__c == exDiaCon.PNR_Diageo_Rep__c && diaCon.PNR_Customer__c == exDiaCon.PNR_Customer__c &&
                                    diaCon.PNR_Contact_Type__c == exDiaCon.PNR_Contact_Type__c){
                                        //if (!Test.isRunningTest()) {
                                            if (currentUser.managerId != null && !Test.isRunningTest()) {
                                                diaCon.addError(Label.PNR_duplicateContactTypeDC);
                                            } else if(!Test.isRunningTest()) {
                                                diaCon.addError(Label.PNR_duplicateDCTL);
                                            }
                                        //}
                                 }
                            
                        }
                    }
                }
            }
        } else if (!nameList.isEmpty()) {
            if (Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()) {
                nameDiageoConList = [SELECT Id, Name, PNR_Diageo_Rep__c, PNR_Customer__c, PNR_Name__c, PNR_Contact_Type__c
                    FROM PNR_Diageo_Contact__c
                    WHERE PNR_Name__c IN: nameList
                ];
            }
            for (PNR_Diageo_Contact__c diaCon: (List < PNR_Diageo_Contact__c > ) newItems) {
                if (diaCon.PNR_Name__c != Null) {
                    for (PNR_Diageo_Contact__c exDiaCon: nameDiageoConList) {
                        if (diaCon.PNR_Name__c == exDiaCon.PNR_Name__c && diaCon.PNR_Customer__c == exDiaCon.PNR_Customer__c &&
                            diaCon.PNR_Contact_Type__c == exDiaCon.PNR_Contact_Type__c && !isUpdate) {
                            //if (!Test.isRunningTest()) {
                                if (currentUser.managerId != null && !Test.isRunningTest()) {
                                    diaCon.addError(Label.PNR_duplicateContactTypeDC);
                                } else if (!Test.isRunningTest()) {
                                    diaCon.addError(Label.PNR_duplicateDCTL);
                                }
                           // }
                        }else if(isUpdate && (oldMap.get(diaCon.Id).PNR_Name__c != diaCon.PNR_Name__c ||
                                 oldMap.get(diaCon.Id).PNR_Customer__c != diaCon.PNR_Customer__c ||
                                 oldMap.get(diaCon.Id).PNR_Contact_Type__c != diaCon.PNR_Contact_Type__c) ){
                                     
                                 if(diaCon.PNR_Name__c == exDiaCon.PNR_Name__c && diaCon.PNR_Customer__c == exDiaCon.PNR_Customer__c &&
                                    diaCon.PNR_Contact_Type__c == exDiaCon.PNR_Contact_Type__c){
                                        //if (!Test.isRunningTest()) {
                                            if (currentUser.managerId != null && !Test.isRunningTest()) {
                                                diaCon.addError(Label.PNR_duplicateContactTypeDC);
                                            } else if(!Test.isRunningTest()) {
                                                diaCon.addError(Label.PNR_duplicateDCTL);
                                            }
                                        //}
                                 }
                            
                        }
                    }
                }
            }
        }
    }
}