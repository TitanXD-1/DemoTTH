/*
 * @Name: ECM_VolumeInputControllerTest
 * @Description: Test Class for  ECM_volumeInputController
 * @History                                                            
                                                         
 VERSION    AUTHOR                DATE              DETAIL
 1.0        Chandrakanth Suram    22/04/2021        Initial Development
 1.1		Subhrojit Majumdar	  24/12/2021		Technical Debt Changes against ECM-5068		

1.2			Saurav Prasad		  	24/12/2021			ECM-4973 : POC_Group Contract Accessibility_SFDC_GLO	

*/ 

@isTest
public class ECM_VolumeInputControllerTest 
{
   /**
    * @Name : getVolumeInputAccessTest
	* @description : This method is used to test the getVolumeInputAccess() and contractValues() methods of the ECM_volumeInputController class
	*/
	@isTest
    public static void getVolumeInputAccessTest()
    {
        
        User usr = EDGE_UtilityTestClass.runAsUser('testUser','Sales Representative');

        usr.Available_Countries__c = 'ES';
        insert usr;
        
        User usr1 = EDGE_UtilityTestClass.runAsUser('testUserMDM','System Admin');
        usr1.Available_Countries__c = 'ES';
        insert usr1;
        

        Test.startTest();
        System.runAs(usr)
        {
        	WrapperInst wrapobj = createData();
        
            Territory__c testterritory = wrapobj.testterritory;
            Territory_Hierarchy__c hirarchy = wrapobj.hirarchy;
            testterritory.Primary_Sales_Rep__c = usr.id;
            testterritory.Region__c = hirarchy.Id;
            update testterritory;
            
            Market_Setting__c mktSetting = wrapobj.mktSetting;
            mktSetting.Depletion_market__c = false;
        	update mktSetting;
            
            Account outlet = wrapobj.outlet;
                        

            Account ownerAcc = wrapobj.ownerAcc;
            ownerAcc.Person_Responsible__c = usr.Id;
            update ownerAcc;
            

            String contractRecordTypeId = wrapobj.contractRecordTypeId;
            
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId); 
            insert objContract; 
       		objContract.Status ='Active';
        	update objContract;
            Contract getContract = ECM_volumeInputController.contractValues(objContract.Id);
            System.assert(getContract!= null,'contract values exist');
            ECM_volumeInputController.AccessWrapper wrapObjCtrl = ECM_volumeInputController.getVolumeInputAccess(objContract.Id);
            System.assert(wrapObjCtrl!= null,'wrapper object is not null');

            
            //ECM-4973
            Contract objContract1 = EDGE_UtilityTestClass.getContract(ownerAcc.Id, wrapobj.contractGroupRecordTypeId); 
            insert objContract1; 
            objContract1.Status ='Active';
            update objContract1;
            
            System.runAs(usr1){
                ECM_volumeInputController.AccessWrapper wrapObjCtrl1 = ECM_volumeInputController.getVolumeInputAccess(objContract1.Id);
                System.assert(wrapObjCtrl1!= null,'wrapper object is not null');
            }

        }
        Test.stopTest();
   }
   /**
    * @Name : createData()
	* @description : This method is used to create test data for testing ECM_PaymentAgreementTriggerHelper class
    * @return : a Wrapper with geography Id and components of market set up
	*/
    public static WrapperInst createData()
    {
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');

        

        Territory__c testterritory = EDGE_UtilityTestClass.getTerritoryRec();
       	insert testterritory;
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        
        testterritory.Region__c = hirarchy.Id;
        testterritory.Country__c= geographyId;
       	update testterritory;
        
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        
        mktSetting.Depletion_market__c = false;
        update mktSetting;
         
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet; 
        

        Account ownerAcc = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        insert ownerAcc;
        

        outlet.country__c = geographyId;
        update outlet;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();

        String contractGroupRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();


        WrapperInst wrapObj = new WrapperInst();
        wrapobj.testterritory = testterritory;
        wrapobj.hirarchy = hirarchy;
        wrapobj.mktSetting = mktSetting;
        wrapobj.outlet = outlet; 

        wrapobj.ownerAcc = ownerAcc;
        wrapobj.contractRecordTypeId = contractRecordTypeId; 
        wrapobj.contractGroupRecordTypeId = contractGroupRecordTypeId;

        return wrapObj;
    }
    class WrapperInst
    {
       Market_Setting__c mktSetting{get;set;}
       Territory_Hierarchy__c hirarchy{get;set;}
       Territory__c testterritory{get;set;}
       Account outlet{get;set;}

        Account ownerAcc{get;set;}
        String contractRecordTypeId{get;set;}
        String contractGroupRecordTypeId{get;set;}

    }
}