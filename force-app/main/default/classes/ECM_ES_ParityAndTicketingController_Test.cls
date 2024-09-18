/*
@Name: ECM_ES_ParityAndTicketingController_Test
@Purpose: Class with all handler methods of ECM_ES_ParityAndTicketingController.
@History                                                                                                                      
@VERSION  	AUTHOR              DATE              	DETAIL
1.0        	
2.0			Saurav Prasad		14/07/2023			142555	: CM static code violation for the classes_SFDC_Technical Debt
*/
@isTest
private class ECM_ES_ParityAndTicketingController_Test {
    @isTest
    private static void testparity() {
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        /*String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();*/
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        /*String contractRecordGroupTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();*/
        
        //Territory for outlet
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
        
        //Contract Mandatory Records : Account
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        //Contract Mandatory Records : Agreement Type
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.Name='PromotionalAU';
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        insert contractType;
        
        Boolean checkVal = ECM_CreateContractControllerEandS.getAgreementType(contractType.Id);
        System.debug(LoggingLevel.DEBUG, checkVal);
        
        //Setting up three contracts : one with 'min UoM' & another one with '9LC EU' product uoM, one group contract
        Contract objContractAU = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContractAU.Status = 'Draft';
        objContractAU.ECM_Territory__c=testterritory.Id;
        objContractAU.ECM_Agreement_Type__c=contractType.Id;
        objContractAU.ECM_Channel__c='On-Premise';
        objContractAU.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractAU.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        
        ECM_ES_ParityAndTicketingController.savecontract(objContractAU);
        
        //ECM-5634 test starts;
        String recordTypeParityIdpo1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Parity').getRecordTypeId();
        Pick_Up_Options__c paritypo1 = new Pick_Up_Options__c();
        paritypo1.Name='Reduced Rate - Canarias-A&P[AU]';
        paritypo1.Geography__c=geographyId;
        paritypo1.RecordTypeId=recordTypeParityIdpo1;
        paritypo1.Status__c = 'Active';
        insert paritypo1;
        
        String recordTypeTicketIdpo2 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Ticket').getRecordTypeId();
        Pick_Up_Options__c ticketpo2 = new Pick_Up_Options__c();
        ticketpo2.Name='Reduced Rate[AU]';
        ticketpo2.Geography__c=geographyId;
        ticketpo2.RecordTypeId=recordTypeTicketIdpo2;
        ticketpo2.Status__c = 'Active';
        insert ticketpo2;
        
        ///ECM-5753
        ///ECM_Event_Additional_Info_Agreement__c is the bridge object between Agrement type and Pickup option
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI1 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI1.ECM_Agreement_Type__c = contractType.Id;
        eventAddInfoAgrEAI1.ECM_Event_Additional_Pickup_Option__c = paritypo1.Id;
        insert eventAddInfoAgrEAI1;
        
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI2 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI2.ECM_Agreement_Type__c = contractType.Id;
        eventAddInfoAgrEAI2.ECM_Event_Additional_Pickup_Option__c = ticketpo2.Id;
        insert eventAddInfoAgrEAI2;
        
        
        String recordTypeParityIdEAI1 = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Parity').getRecordTypeId();
        ECM_Event_Additional_Information__c eventAddInfoEAI1 =new ECM_Event_Additional_Information__c();
        eventAddInfoEAI1.ECM_Contract__c = objContractAU.Id;
        eventAddInfoEAI1.ECM_Information_Type__c = paritypo1.Id;
        eventAddInfoEAI1.ECM_Description__c = 'Parity';
        eventAddInfoEAI1.ECM_Unique_Id__c = objContractAU.Id+'_'+paritypo1.Id+'_'+recordTypeParityIdpo1;
        eventAddInfoEAI1.RecordTypeId=recordTypeParityIdEAI1;
        insert eventAddInfoEAI1;
        system.assertEquals(eventAddInfoEAI1.RecordTypeId, recordTypeParityIdEAI1,'Expected');
        Assert.areEqual(eventAddInfoEAI1.RecordTypeId, recordTypeParityIdEAI1,'Expected');
        //ECM_ES_ParityAndTicketingController.getActivationData(objContractAU.id,'Parity');
       
        String recordTypeTicketIdEAI2 = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Ticket').getRecordTypeId();
        ECM_Event_Additional_Information__c eventAddInfoEAI2 =new ECM_Event_Additional_Information__c();
        eventAddInfoEAI2.ECM_Contract__c = objContractAU.Id;
        eventAddInfoEAI2.ECM_Information_Type__c = ticketpo2.Id;
        eventAddInfoEAI2.ECM_Description__c = 'Ticket';
        eventAddInfoEAI2.ECM_Unique_Id__c = objContractAU.Id+'_'+ticketpo2.Id+'_'+'_'+recordTypeTicketIdpo2;
        eventAddInfoEAI2.RecordTypeId=recordTypeTicketIdEAI2;
        insert eventAddInfoEAI2;
        
        
        //String recordTypeTicketIdEAI3 = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Ticket').getRecordTypeId();
        ECM_Event_Additional_Information__c eventAddInfoEAI3 =new ECM_Event_Additional_Information__c();
        eventAddInfoEAI2.ECM_Information_Type__c = ticketpo2.Id;
        eventAddInfoEAI2.ECM_Description__c = 'Ticket';
        eventAddInfoEAI2.RecordTypeId=recordTypeTicketIdEAI2;
        List<ECM_Event_Additional_Information__c> data2= new List<ECM_Event_Additional_Information__c>{eventAddInfoEAI3,eventAddInfoEAI1};
            
        List<String> recordList = new List<String>();
        recordList.add(recordTypeParityIdEAI1);
        recordList.add(recordTypeTicketIdEAI2);
        String recordTypeIdsList = recordTypeParityIdEAI1+','+recordTypeTicketIdEAI2;
        String jasonData = JSON.Serialize(data2);
        //Map<String,List<ECM_Event_Additional_Information__c>> saveBrandingData = 
        ECM_ES_ParityAndTicketingController.savePTData(objContractAU.id,jasonData,recordTypeIdsList );
        ECM_ES_ParityAndTicketingController.getParityTicketData(objContractAU.Id, 'Parity,Ticket');
        ECM_ES_ParityAndTicketingController.savecontract(objContractAU);
        ///ECM-5753
        List<String> recordType = Label.ECM_ParityScreenRecordTypes.split(',');
        ECM_ES_ParityAndTicketingController.getPickUpOptionType(contractType.Id,'Pick_Up_Options__c',recordType);

        
        
    }


}