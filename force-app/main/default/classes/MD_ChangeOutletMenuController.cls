/************************************************************************************
Apex Class Name  :  MD_ChangeOutletMenuController  
Version          :  1.0
Created Date     :  12/12/2018 
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Shwarzböck            12/12/2018              Original Version
******************************************************************************/
public without sharing class MD_ChangeOutletMenuController {

    public MD_UserSessionUtil.OutletInfo currentOutlet {get;set;}

    public MD_ChangeOutletMenuController(){
        currentOutlet = new MD_UserSessionUtil.OutletInfo();
        if(String.IsNotBlank(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c)){
            AccountContactRelation sessionOutlet = MD_UserSessionUtil.availableOutlets.get(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c);
            currentOutlet = new MD_UserSessionUtil.OutletInfo(sessionOutlet.Account.Name, sessionOutlet != null ? String.valueOf(sessionOutlet.Id) : null);
        }
    }

    @AuraEnabled
    public static String initChangeOutletMenu() {
        MD_ChangeOutletMenuController controller = new MD_ChangeOutletMenuController();
        return JSON.serialize(controller);
    }

}