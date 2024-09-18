/**************************************************************************************
Apex Class Name : MD_DiageoFooterController 
Version : 1.0
Created Date : 22/10/2018
Release : R1
Function : It handles instances of CP_DiageoFooter.vfp, based on
the "DiageoCookiesCountryCode" set before
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------                 
* Angel Rodriguez	         22/10/2018  ECO-1202 Multicountry Footer Original Version
* 
******************************************************************************/


public class MD_DiageoFooterController {
    public String countryLocation {get;set;}    
    
    
    public MD_DiageoFooterController(){
        if(getParameterByName('country')=='GB'){
            countryLocation = 'en-gb';
        }else{
            countryLocation = '';
        }
    }
    
    public String getParameterByName(String paramName){
        return ApexPages.currentPage().getParameters().get(paramName);

    }
}