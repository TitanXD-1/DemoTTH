/**************************************************************************************
Apex Class Name  :  MD_SiteMainController 
Version 		 : 	1.0
Created Date  	 : 	16/05/2018
Release  	     : 	R1
Function 		 : 	It retrieves all the data needed by the CP_LoginTheme component
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Julio enrique	         	16/05/2018              Original Version
* Hernan Arakaki	        22/08/2018		        INC6254608 - MyDiageo.com - footer not appearing when logged-in
******************************************************************************/

public without sharing class MD_LoginThemeController {

    @auraEnabled
    public static Object fetchBackgroundImage(String deviceType){
        /* MIGRATION - Commented */
        DiageoCMS__MediaElement__c me;
        
        me = [SELECT Id, DiageoCMS__FileURLDesktop__c, DiageoCMS__FileURLTablet__c, DiageoCMS__FileURLMobile__c 
              FROM DiageoCMS__MediaElement__c 
              WHERE DiageoCMS__ExternalId__c = 'loginBackgroundImage' 
              AND DiageoCMS__Status__c = 'Active'
              LIMIT 1];
        
        if(me == null) {
            return null;
        }

        CP_MediaElementWrapper wr;

        if(deviceType == 'DESKTOP') {
            wr = new CP_MediaElementWrapper();
            wr.imageUrl = me.DiageoCMS__FileURLDesktop__c;
        }else if(deviceType == 'TABLET') {
            wr = new CP_MediaElementWrapper();
            wr.imageUrl = me.DiageoCMS__FileURLTablet__c;
        }else if(deviceType == 'MOBILE') {
            wr = new CP_MediaElementWrapper();
            wr.imageUrl = me.DiageoCMS__FileURLMobile__c;
        }
		
        return JSON.serialize(wr);
        /* MIGRATION - Commented 
        return '';
        MIGRATION - Commented */
    }
    
    @auraEnabled
    public static String getRedirectURL(){
        Profile loggedProfile = [SELECT UserLicense.Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        if (loggedProfile.UserLicense.Name == Label.MD_MyDiageUserLicense){
            return MD_GeneralSettings.getBaseURL();
        }
        return '';
    }
}