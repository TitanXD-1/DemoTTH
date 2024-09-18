@isTest
public class ECM_TemplateSectionTriggerTest {
    
    
/*
Name: ECM_TemplateSectionTriggerTest

Req: Test Class for  Template Section Trigger 

History                                                            
                                                         
VERSION   AUTHOR                        DATE             
1.0       Manikandan.T                29-12-2020        
1.1		  Keshav					  04-01-2021 Added code to cover Template Sub Section object Trigger,Handler and helper class	
*/

    
/*
Method  : checkSharingTest
Purpose : To check the sharing of object
*/
    @isTest
    private static void checkSharingTest(){
        //Creating Org setting
        Test.startTest();
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        //Creating Pickup Option Record
 
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        Geography__c secCountry2 = EDGE_UtilityTestClass.createGeography('Country');
        secCountry2.Name = 'Spain';
        secCountry2.Code__c = 'ES1';
        secCountry2.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry2;
        Test.stopTest();
        
       ECM_Template_Section__c tempSection = new ECM_Template_Section__c();
        tempSection.ECM_Terms_And_Condition__c = false;
        tempSection.ECM_Text__c='Test Content';
        tempSection.ECM_Title__c='Test Title';
        tempSection.ECM_Geography__c= secCountry.Id;
        insert tempSection ;
        system.assert(tempSection.Id != null,'tempSection should not be null');
        
        tempSection.ECM_Geography__c = secCountry2.Id;
        update tempSection;        
        
        delete tempSection;
        undelete tempSection;
		
		ECM_Template_Sub_Section__c tempSubSec = new ECM_Template_Sub_Section__c();
		tempSubSec.ECM_Terms_And_Condition__c = false;
        tempSubSec.ECM_Text__c='Test Content';
        tempSubSec.Name='Test Title';
        tempSubSec.ECM_Geography__c= secCountry.Id;
        insert tempSubSec ;
        system.assert(tempSubSec.Id != null,'tempSubSec should not be null');
        
        tempSubSec.ECM_Geography__c = secCountry2.Id;
        update tempSubSec;        
        
        delete tempSubSec;
        undelete tempSubSec;
        
        ECM_Sales_Driver__c salesdrive=new ECM_Sales_Driver__c();
        salesdrive.Name='Promotional';
        salesdrive.Geography__c=secCountry.Id;
        salesdrive.ECM_Is_Range__c=true;
        insert salesdrive;
        system.assert(salesdrive.Id != null,'salesdrive should not be null');
        
        salesdrive.Geography__c = secCountry2.Id;
        update salesdrive;        
        
        delete salesdrive;
        undelete salesdrive;
        
        
    }
    


}