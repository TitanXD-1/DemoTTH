/**
 * @name : D1_VFLoginFlowController
 * @description : Controller class for VF D1_VFLoginFlow
 * @author : Gaurav Singh
 * @since 
 * @history
 * VERSION      AUTHOR                  DATE            DETAIL
 * 1.0          Gaurav Singh                            Initial Development(NCP-)
 * 2.0          Sayan Samaddar          12/07/2022      NCP-7157
 * 3.0          Kapil Baliyan           30/10/2022      NCP-7563
 * 4.0          Prasanth T           	19/09/2023      114761 Commented D1 Lite code
 * 5.0          Prasanth T           	28/09/2023      146448 uncommented
 */
public class D1_VFLoginFlowController {

    /**
     * @description : Method to get start url for D1 Lite (NCP-7157)
     * @return  `String`
     */ 
    //146448 uncommented this code used for redirection
    @AuraEnabled
    public static String setStartURLForLite(){
        string categoryId = D1_CustomCommunityThemeController.getProductCategoryId();
        
        //Relative URL For Shop Product Catalauge Page
        return System.Label.D1_Commerse_CommunityPrefix  + '/category/product/' + categoryId;
    }
    

    /**
     * @description : Method call from Login Flow
     * @return  `PageReference`
     */
    public PageReference FinishLoginFlowHome() {
        //114761
        /*String defaultCommunityRetURL = 'CommunitiesLanding';
        String d1Domain = 'diageo-one.com';
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        retURL = retURL == null ? '' : retURL;
        Boolean isHavingReturnURL = !retURL.containsIgnoreCase(defaultCommunityRetURL);

        //Get Base URL
        String baseURL = ApexPages.currentPage().getHeaders().get('Host');*/

        //Update Last Login Date on Contact
        D1_LoginFormController.updatelastlogin();

        return Auth.SessionManagement.finishLoginFlow();

        //Get Current User Detail
        /*User currentUser = [SELECT Id, Available_Countries__c, LanguageLocaleKey FROM User WHERE Id =:userinfo.getUserId() LIMIT 1];
        List<String> availableCountry = currentUser.Available_Countries__c != NULL ? currentUser.Available_Countries__c.split(',') : new List<String>();

        //Get D1 Setting
        List<D1_Setting__c> d1Settings = new List <D1_Setting__c>();
        d1Settings = [SELECT Id, D1_Lite_Version__c FROM D1_Setting__c WHERE Language__c =:currentUser.LanguageLocaleKey AND Market__r.Code__c IN :availableCountry LIMIT 1];
        
        //Check whether D1 Lite is enable or not
        Boolean isD1Lite = d1Settings != null && d1Settings.size()>0 ? d1Settings.get(0).D1_Lite_Version__c : false;

        //Check whether user is having Ordering Permission or not
        List<PermissionSetAssignment> psa = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment 
                                            WHERE AssigneeId =:currentUser.Id
                                            AND PermissionSet.Name IN ('B2B_Commerce_User', 'Ordering')];
        Boolean isOrderingPermission = psa != null && psa.size()>0 ? true : false;

        //Check if D1 Lite is Enabled and User is having Order Permission and does not have return url(not community default landing page url)
        if(isD1Lite && isOrderingPermission && !isHavingReturnURL){
            String d1LiteStartURL = '';
            //Get D1 Lite Home Page URL
            if(!baseURL.containsIgnoreCase(d1Domain)){ //to work redirection in dev box where we dont have domain enabled
                d1LiteStartURL = 'https://' + baseURL + setStartURLForLite();
            }else{
                d1LiteStartURL = setStartURLForLite();    
            }

            //Landing to Product Catalauge Page - D1 Lite
            return Auth.SessionManagement.finishLoginFlow(d1LiteStartURL);
        }else{
            //finish the login flow and send you the default homepage
            return Auth.SessionManagement.finishLoginFlow();
        }*/
    }
}