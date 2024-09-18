/*
* @Name: ECM_CreateContractControllerEandS
* @description: This Class is for handling E&S contract specific server calls 
* @History 

VERSION    AUTHOR                DATE			    DETAIL
1.0       Pratap Sen           20/05/2022      Initial Development
1.1       Abhijeet Mishra      09/06/2022      ECM-5634
1.2		  Manikandan.T		   14/06/2022	   ECM-5641 - created methods fetchInvestmentData and saveInvestmentRecord
1.3       Pratap Sen           26/08/2022      ECM-5816 - Added method 'submitForApproval' & added logic to save 'Total Indicative Funding' in contract
1.4       Priya Soni           15/09/2022      ECM-5753 - modified method 'getPickUpOptionType' & 'getBrandingData'
*/
public with sharing class ECM_CreateContractControllerEandS {
    /*
    * Name : getAgreementType
    * @description : Method to check data in Agreement Type
    * @return : Boolean
    * @param : String - Id of Agreement Type
	*/ 
    @AuraEnabled
    public static Boolean getAgreementType(String agreementTypeId){
        Boolean isVolumeTarget = [SELECT Id,ECM_Volume_target__c FROM ECM_Contract_Type__c WHERE Id =: agreementTypeId LIMIT 1].ECM_Volume_target__c;
        return isVolumeTarget;
    }
    
    /*
    * Name : savecontract
    * @description : Method to upsert cotract instance sent from Front-End
    * @return : Void
    * @param : Contract - Instance of Contract Record
	*/ 
    
    @AuraEnabled
    public static void savecontract(contract conRecord){
        upsert conRecord;
    }
    
    /*
    * Name : getListCon
    * @description : Method to calculate last screen KPIs
    * @return : ECM_ReviewAndSubmitController.Wrapper_Review_cal
    * @param : Contract - Instance of Contract Record
	*/ 
    @AuraEnabled
    Public Static ECM_ReviewAndSubmitController.Wrapper_Review_cal getListCon(Contract contractObj){
        return ECM_ReviewAndSubmitController.Review_On_Premise_Caluculatons(contractObj);
    }
    
    /*
    * Name : getBrandingData - ECM-5634
    * @description : Method to fetch screen-5 dropdown options & saved records
    * @return : brandingWrapper
    * @param : String - Id of Contract Record
	*/ 
    @AuraEnabled
    public static brandingWrapper getBrandingData (String ConId,String agreementId){
        List<String> recordType = Label.ECM_BrandingScreenRecordTypes.split(',');//Branding,Branding Merchandise
        List<ECM_Event_Additional_Information__c> branding_evntInfo = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> brandingMrchnds_evntInfo = new List<ECM_Event_Additional_Information__c>();
        
        List<List<Pick_Up_Options__c>> returnPickUpVal = getPickUpOptionType(agreementId, 'Pick_Up_Options__c', recordType);

        List<Pick_Up_Options__c> branding_pickUp = returnPickUpVal[0];
        List<Pick_Up_Options__c> brandingMr_pickUp = returnPickUpVal[1];
        
        Map<String,Id> recordTypeIds_evntInfo = new Map<String,Id>();
        Map<String,Id> recordTypeIds_pickUp = new Map<String,Id>();
        for(String recType : recordType){
            recordTypeIds_evntInfo.put(recType.trim(),ECM_TaxCodeDropdownComponentController.getRecordTypeIdForObject('ECM_Event_Additional_Information__c',recType.trim()));
        }
        for(ECM_Event_Additional_Information__c it : [SELECT Id,Name,ECM_Information_Type__c,ECM_Information_Type__r.Name, ECM_Quantity__c,
                                                      ECM_Description__c,RecordTypeId FROM ECM_Event_Additional_Information__c
                                                      WHERE ECM_Contract__c=:ConId AND ECM_Information_Type__c != NULL AND RecordTypeId IN: recordTypeIds_evntInfo.values()])
        {
            it.ECM_Information_Type__r.Name = it.ECM_Information_Type__r.Name.substringBefore('[');
            if(it.RecordTypeId == recordTypeIds_evntInfo.get(recordType[0])){
                branding_evntInfo.add(it);
            }
            else if(it.RecordTypeId == recordTypeIds_evntInfo.get(recordType[1])){
                brandingMrchnds_evntInfo.add(it);
            }
        }
        
        brandingWrapper retVal = new brandingWrapper();
        retVal.brandingPickUpList = branding_pickUp;
        retVal.brandingMrchndisePickUpList = brandingMr_pickUp;
        retVal.brandingEvntInfo = branding_evntInfo;
        retVal.brandingMrchndiseEvntInfo = brandingMrchnds_evntInfo;
        retVal.recTypeIds = recordTypeIds_evntInfo.values();
        return retVal;
    }
    
    /*
    * Name : saveBrandingData - ECM-5634
    * @description : Method to save user selected/modified records in screen-5
    * @return : Map<String,List<ECM_Event_Additional_Information__c>>
    * @param : String - Id of Contract Record, String - JSON data of user responses, List<String> - RecordType Ids of Items used in Screen 5
	*/     
    @AuraEnabled
    public static Map<String,List<ECM_Event_Additional_Information__c>> saveBrandingData(String conId, String data, List<String> recordTypeIDs){
        
        Map<String,List<ECM_Event_Additional_Information__c>> returnData = new Map<String,List<ECM_Event_Additional_Information__c>>();
        Map<String,ECM_Event_Additional_Information__c> existingData = new Map<String,ECM_Event_Additional_Information__c>(); //Existing Record
        List<ECM_Event_Additional_Information__c> brandingList = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> brandingMerchList = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> evntData = (List<ECM_Event_Additional_Information__c>)JSON.deserialize(data, List<ECM_Event_Additional_Information__c>.class);
        List<ECM_Event_Additional_Information__c> dataToDel = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> dataToUpsert = new List<ECM_Event_Additional_Information__c>();
        
        for(ECM_Event_Additional_Information__c evntInfo : [SELECT Id,ECM_Information_Type__c,ECM_Description__c,RecordTypeId, ECM_Quantity__c
                                                            FROM ECM_Event_Additional_Information__c 
                                                            WHERE ECM_Contract__c =: conId AND RecordTypeId IN: recordTypeIDs])
        {
            existingData.put(evntInfo.ECM_Information_Type__c+'_'+evntInfo.RecordTypeId,evntInfo);                                                   
        }
        
        for(ECM_Event_Additional_Information__c it : evntData){
            String key = it.ECM_Information_Type__c + '_' + it.RecordTypeId;
            ECM_Event_Additional_Information__c rec = new ECM_Event_Additional_Information__c();
            
            if(existingData.containsKey(key)){
                rec = existingData.get(key);
                rec.ECM_Quantity__c = it.ECM_Quantity__c;
                existingData.remove(key);
            }
            else{
                rec = it;
                rec.ECM_Contract__c = conId;
            }
            rec.ECM_Unique_Id__c = conId + '_' + key;
            dataToUpsert.add(rec);
        }
        Try{
            if(!existingData.isEmpty()){
                dataToDel = existingData.values();
            }
            if(!dataToUpsert.isEmpty()){
                upsert dataToUpsert ECM_Event_Additional_Information__c.ECM_Unique_Id__c;
            }
            if(!dataToDel.isEmpty()){
                delete dataToDel;
            }
        }
        Catch(Exception ex){
                 System.debug('Class:ECM_CreateContractControllerEandS\nmethod:saveBrandingData\nException:::' 
                              + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());            
        }
        for (ECM_Event_Additional_Information__c it : dataToUpsert){
            if(it.RecordTypeId == recordTypeIDs[0]){
                brandingList.add(it);
            }
            else if(it.RecordTypeId == recordTypeIDs[1]){
                brandingMerchList.add(it);
            }
        }
        returnData.put(recordTypeIDs[0],brandingList);
        returnData.put(recordTypeIDs[1],brandingMerchList);
        return returnData;
    }
    
    /*
    * Name : getPickUpOptionType
    * @description : Method to fetch PickUp Option Record of given RecordType
    * @return : list<Pick_Up_Options__c>
    * @param : String Agreement Id, String - API Name of Object, String - RecordType Name
	*/            
    @AuraEnabled
    public static List<List<Pick_Up_Options__c>> getPickUpOptionType(String agreementId, String objectName, List<String> recordType){
        List<List<Pick_Up_Options__c>>  returnVal = new List<List<Pick_Up_Options__c>>();
        
        Id brandingRecordTypeId =getRecordTypeIdForObject(objectName, recordType[0]);
        Id brandingMerchandiseRecordTypeId =getRecordTypeIdForObject(objectName, recordType[1]);
        
        List<ECM_Event_Additional_Info_Agreement__c> ecmEventAdditionalInfoAgreement = new List<ECM_Event_Additional_Info_Agreement__c>();
        List<Pick_Up_Options__c> ecmBrandingPkOptionTypeReturn  = new List<Pick_Up_Options__c>();
        List<Pick_Up_Options__c> ecmBrandingMerchandisePkOptionTypeReturn  = new List<Pick_Up_Options__c>();
   
        for(ECM_Event_Additional_Info_Agreement__c option : [SELECT Id,ECM_Event_Additional_Pickup_Option__c,ECM_Event_Additional_Pickup_Option__r.Name,
                                                             ECM_Event_Additional_Pickup_Option__r.Description__c,ECM_Record_Type__c  
                                                             FROM ECM_Event_Additional_Info_Agreement__c 
                                                             WHERE ECM_Agreement_Type__c =:agreementId AND ECM_Record_Type__c IN :recordType 
                                                             AND ECM_Event_Additional_Pickup_Option__r.Status__c='Active'
                                                             ORDER BY CreatedDate DESC]){
                                                  
            option.ECM_Event_Additional_Pickup_Option__r.Name = option.ECM_Event_Additional_Pickup_Option__r.Name.substringBefore('[').trim();
            Pick_Up_Options__c pkOption = new Pick_Up_Options__c(Id=option.ECM_Event_Additional_Pickup_Option__c);
            pkOption.name = option.ECM_Event_Additional_Pickup_Option__r.Name;
            pkOption.Description__c = option.ECM_Event_Additional_Pickup_Option__r.Description__c ;
            if (option.ECM_Record_Type__c == recordType[0]){
                pkOption.RecordTypeId = brandingRecordTypeId;
                ecmBrandingPkOptionTypeReturn .add(pkOption);
            }else{
                pkOption.RecordTypeId = brandingMerchandiseRecordTypeId;
                ecmBrandingMerchandisePkOptionTypeReturn .add(pkOption);
        }
    }
        returnVal.add(ecmBrandingPkOptionTypeReturn);
        returnVal.add(ecmBrandingMerchandisePkOptionTypeReturn);
        return returnVal;

    }
    
    
    /*
    * Name : getRecordTypeIdForObject
    * @description : Method to RecordTypeID of given Object & RecordType Name
    * @return : Id
    * @param : String - API Name of Object, String - RecordType Name
	*/  
    public static Id getRecordTypeIdForObject(String objName, String recTypeName) {
        return ((SObject)Type.forName(objName).newInstance())
            .getSObjectType()
            .getDescribe()
            .getRecordTypeInfosByName()
            .get(recTypeName)
            .getRecordTypeId();
    }
    
    /*
    * Name : getParityPickUpOptionType
    * @description : fetches pickup Options for branding screen
    * @return : brandingWrapper - wrapper
    * @param :  String - Id of Contract Record
	*/ 
    @AuraEnabled
    public static brandingWrapper getParityPickUpOptionType(String conId,String agreementId){
        List<String> recordType = Label.ECM_ParityScreenRecordTypes.split(',');
        List<List<Pick_Up_Options__c>> returnPickUpVal = getPickUpOptionType(agreementId, 'Pick_Up_Options__c', recordType);
        List<Pick_Up_Options__c> parity_pickUp = returnPickUpVal[0];
        List<Pick_Up_Options__c> ticketing_pickUp = returnPickUpVal[1];
        brandingWrapper parityPage = new brandingWrapper();
        parityPage.brandingPickUpList = parity_pickUp;
        parityPage.brandingMrchndisePickUpList = ticketing_pickUp;
        return parityPage;
    }
    
    /*
    * Name : fetchInvestmentData
    * @description : Method to fetch KPI values & Sponsorship table data of Investment Summary Screen
    * @return : tableData - wrapper
    * @param : String - Id of Contract Record
	*/      
    @AuraEnabled
	public static tableData fetchInvestmentData(String contractId) {
        Map < String, ECM_Event_Additional_Information__c > investmentMap = new Map < String, ECM_Event_Additional_Information__c > ();
        Map < String, ECM_Event_Additional_Information__c > eventInvestmentmap = new Map < String, ECM_Event_Additional_Information__c > ();
        List < String > SponsorshipList = new List < String > ();
        Decimal totalInvesmentAmount = 0.00;
        Decimal totalSponsorshipInvesmentAmount = 0.00;
        List < Cell > tempcellList = new List < Cell > ();
        List < Row > rowList = new List < Row > ();
        tableData dataWrapper = new tableData();
        Map < Id, ECM_Event__c > eventMap = new Map < Id, ECM_Event__c > ([select id, Name, ECM_Percent_Sponsorship_Fee_Allocation__c, ECM_Contract__c, ECM_Event_Date__c, ECM_Event_Name__c from ECM_Event__c where ECM_Contract__c =: contractId order by Name asc]);
        String countryCode;
        
        List<contract> contractLst= [SELECT Id,ECM_Additional_Brand_Funding__c,ECM_Additional_Brand_Funding_IO__c,Account.country_code__c FROM contract WHERE id=:contractid];
        if(!contractLst.isEmpty() && contractLst[0].Account!=null && contractLst[0].Account.country_code__c!=null ){
            countryCode= contractLst[0].Account.country_code__c;
        }
        List<ECM_Event_Additional_Information__c> eventAdditionalList=[select id, ECM_Amount_Per_Investment_Per_Event__c, ECM_Contract__c, ECM_Description__c, ECM_Event__c,
                ECM_Investment__c, ECM_Information_Type__c, ECM_Investment_Amount__c, ECM_Investment_Percentage__c,
                ECM_Investment_Type__c, ECM_Quantity__c, ECM_Unique_Id__c, recordtype.Name, ECM_Investment__r.ECM_Investment_Type__c,ECM_Event__r.name
                from ECM_Event_Additional_Information__c
                where ECM_Contract__c =: contractId];
           
        
         for (ECM_Event_Additional_Information__c eventadditional:eventAdditionalList){
    
            if (eventadditional.recordtype.Name == 'Investment') {
                investmentMap.put(eventadditional.ECM_Investment_Type__c, eventadditional);
                if (eventadditional.ECM_Investment_Type__c != 'Activation') {
                    totalSponsorshipInvesmentAmount = totalSponsorshipInvesmentAmount + eventadditional.ECM_Investment_Amount__c;
                }
                totalInvesmentAmount = totalInvesmentAmount + eventadditional.ECM_Investment_Amount__c;
            } else if (eventadditional.recordtype.Name == 'Event Investment') {
                eventInvestmentmap.put(eventadditional.ECM_Investment__r.ECM_Investment_Type__c + '_' + eventadditional.ECM_Event__r.Name, eventadditional);
            }
        }
    
        for (ECM_Technical_Market_Setting__mdt mdt: [select masterlabel, ECM_Country__c, ECM_E_And_S_Contract_Sponsorship_Details__c from ECM_Technical_Market_Setting__mdt where ECM_Country__c =: countryCode]) {
            SponsorshipList = mdt.ECM_E_And_S_Contract_Sponsorship_Details__c.split(';');
        }
    
        Row firstRow = new Row();
    
        Cell investmentTypecell = new Cell('Sponsorship Fees','Sponsorship Fees','text','fixedColumn bold');
        Cell feesAllocationcell = new Cell('Sponsorship Fee Allocation','Sponsorship Fee Allocation','text','fixedColumn1 bold');
        Cell totalcell = new Cell('100%','100%','text','fixedColumn2 bold');
    
        tempcellList.add(investmentTypecell);
        tempcellList.add(feesAllocationcell);
        tempcellList.add(totalcell);
    
        for (String key: eventMap.KeySet()) {
            Cell event = new Cell();
            event.Name = eventMap.get(key).Name;
            event.value = String.ValueOf(eventMap.get(key).ECM_Percent_Sponsorship_Fee_Allocation__c);
            event.Id = eventMap.get(key).Id;
            event.datatype = 'input';
            event.inputtype = 'percent-fixed';
            tempcellList.add(event);
        }
        
        firstRow.Cells = tempcellList;
        rowList.add(firstRow);
    
        Row secondRow = new Row();
        tempcellList = new List < Cell > ();
        Cell emptycell = new Cell('', '','','fixedColumn');
        Cell textcell = new Cell('(% of Sponsorship Fee may be reduced for organiser non-performance)','(% of Sponsorship Fee may be reduced for organiser non-performance)','text','fixedColumn1 bold');
        Cell totalAmountcell = new Cell('totalSponsorshipInvesmentAmount',String.ValueOf(totalSponsorshipInvesmentAmount),'input','fixedColumn2');
        totalAmountcell.inputtype = 'currency';
    
        tempcellList.add(emptycell);
        tempcellList.add(textcell);
        tempcellList.add(totalAmountcell);
    
        for (String key: eventMap.KeySet()) {
            if (eventMap.get(key).ECM_Percent_Sponsorship_Fee_Allocation__c == null) {
                eventMap.get(key).ECM_Percent_Sponsorship_Fee_Allocation__c = 0;
            }
            Cell event = new Cell();
            event.Name = eventMap.get(key).Name+'__'+'total';
            event.value = String.valueOf((eventMap.get(key).ECM_Percent_Sponsorship_Fee_Allocation__c / 100) * totalSponsorshipInvesmentAmount);
            event.Id = eventMap.get(key).Id;
            event.datatype = 'text';
            event.inputtype = 'currency';
            tempcellList.add(event);
        }
        secondRow.Cells = tempcellList;
        rowList.add(secondRow);
    
        for (String sponsorship: SponsorshipList) {
            Row dynamicRow = new Row();
            tempcellList = new List < Cell > ();
            Cell firstcell = new Cell();
            Cell secondcell = new Cell();
            Cell thirdcell = new Cell();
            ECM_Event_Additional_Information__c investment = new ECM_Event_Additional_Information__c();
            ECM_Event_Additional_Information__c eventinvestment = new ECM_Event_Additional_Information__c();
    
            if (investmentMap.containskey(sponsorship)) {
                investment = investmentMap.get(sponsorship);
    
            } else {
                investment.ECM_Investment_Type__c = sponsorship;
                investment.ECM_Investment_Percentage__c = 0;
                investment.ECM_Investment_Amount__c = 0;
            }
            firstcell = new Cell(investment.ECM_Investment_Type__c,investment.ECM_Investment_Type__c,'text','fixedColumn');
            firstcell.id = investment.Id;
            if(investment.ECM_Investment_Type__c!='Activation'){
                secondcell = new Cell( String.ValueOf('Investment Data_'+investment.ECM_Investment_Type__c+'_'+investment.Id),String.ValueOf(investment.ECM_Investment_Percentage__c),'input','fixedColumn1');
                secondcell.inputtype = 'percent-fixed';
                thirdcell = new Cell('total_per_sponsorship',String.ValueOf(investment.ECM_Investment_Amount__c),'text','fixedColumn2');
                thirdcell.inputtype = 'currency';
            }else{
                secondcell = new Cell(String.ValueOf('Investment Data_'+investment.ECM_Investment_Type__c+'_'+investment.Id),'','text','fixedColumn1');
                thirdcell = new Cell('total_per_sponsorship',String.ValueOf(investment.ECM_Investment_Amount__c),'input','fixedColumn2');
                thirdcell.inputtype = 'currency';            
            }
    
            tempcellList.add(firstcell);
            tempcellList.add(secondcell);
            tempcellList.add(thirdcell);
    
            for (String key: eventMap.KeySet()) {
                if (eventInvestmentmap.containsKey(sponsorship + '_' + eventMap.get(key).Name)) {
                    eventinvestment = eventInvestmentmap.get(sponsorship + '_' + eventMap.get(key).Name);
                } 
                else {
                    eventinvestment.ECM_Amount_Per_Investment_Per_Event__c = 0;
                }
                Cell event = new Cell();
                event.Name = 'EventInvestmentData__'+sponsorship + '__' + eventMap.get(key).Name+'__'+eventinvestment.Id;
                event.value = String.valueOf(eventinvestment.ECM_Amount_Per_Investment_Per_Event__c);
                event.Id = eventinvestment.Id;
                event.datatype = 'text';
                event.inputtype = 'currency';
                tempcellList.add(event);
            }
            dynamicRow.Cells = tempcellList;
            rowList.add(dynamicRow);
        }
        
        Row totalRow = new Row();
        tempcellList = new List < Cell > ();
        Cell totalemptycell = new Cell('Indicative Totals', 'Indicative Totals','text','fixedColumn bold');
        Cell totaltextcell = new Cell('','','text','fixedColumn1');
        Cell totaltotalAmountcell = new Cell('IndicativetotalInvesmentAmount',String.ValueOf(totalInvesmentAmount),'text','fixedColumn2 bold');
        totaltotalAmountcell.inputtype = 'currency';
    
        tempcellList.add(totalemptycell);
        tempcellList.add(totaltextcell);
        tempcellList.add(totaltotalAmountcell);
    
        for (String key: eventMap.KeySet()) {
            if (eventMap.get(key).ECM_Percent_Sponsorship_Fee_Allocation__c == null) {
                eventMap.get(key).ECM_Percent_Sponsorship_Fee_Allocation__c = 0;
            }
    
            Cell event = new Cell();
            event.Name = eventMap.get(key).Name+'_'+'Indicative';
            event.value = String.valueOf(((eventMap.get(key).ECM_Percent_Sponsorship_Fee_Allocation__c / 100) * totalInvesmentAmount).setScale(2));
            event.Id = eventMap.get(key).Id;
            event.datatype = 'text';
            event.inputtype = 'currency';
            event.className='bold';
            tempcellList.add(event);
        }
        totalRow.Cells = tempcellList;
        rowList.add(totalRow);
        if(contractLst[0].ECM_Additional_Brand_Funding__c==null){
            contractLst[0].ECM_Additional_Brand_Funding__c=0;
        }
        
        dataWrapper.eventList=eventMap.Values();
        dataWrapper.rows=rowList;
        dataWrapper.indicativetotalFunding=totalSponsorshipInvesmentAmount+contractLst[0].ECM_Additional_Brand_Funding__c;
        dataWrapper.AdditionalBrandFunding=contractLst[0].ECM_Additional_Brand_Funding__c;
        dataWrapper.AdditionalIO=contractLst[0].ECM_Additional_Brand_Funding_IO__c;
        return dataWrapper;
    }

    /*
    * Name : saveInvestmentRecord
    * @description : Method to save KPI values & Sponsorship table data of Investment Summary Screen
    * @return : void
    * @param : String - wrapper of investment table data, String - Wrapper of event table data, Decimal - AdditionalBrandFunding value,
    *          Decimal - indicativetotalfunding value, String - AdditionalIO code, String - wrapper of KPI data, Contract - instance of Contract Record
	*/           
    @AuraEnabled
	public static void saveInvestmentRecord(String investmentData, String eventData, Decimal AdditionalBrandFunding, Decimal indicativetotalfunding, String AdditionalIO, String onPremiseWrapper, Contract contractdetail) {
        
        Map<String,ECM_Event__c> evtMap = new Map<String,ECM_Event__c>();
        Map<String,ECM_Event_Additional_Information__c> eventadditionalMap = new Map<String,ECM_Event_Additional_Information__c>();
		Map<String,ECM_Event_Additional_Information__c> eventinvestmentMap = new Map<String,ECM_Event_Additional_Information__c>();
	    Id investmentrecordTypeId = Schema.SobjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByDeveloperName().get('Investment').getRecordTypeId();
		Id eventInvestmentrecordTypeId = Schema.SobjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByDeveloperName().get('ECM_Event_Investment').getRecordTypeId();
        String contractId;
        contractId = contractdetail.Id;        
        for(ECM_Event__c evt: (List<ECM_Event__c>)JSON.deserialize(eventData,List<ECM_Event__c>.class) ){
            evtMap.put(evt.Name,evt);            
        }
		system.debug('eventData-->'+evtMap);        
        for(Row r:(List<Row>)JSON.deserialize(investmentData,List<Row>.class)){
            for(Cell cellData:r.Cells){
                if(cellData.Name.contains('EVE') && cellData.datatype=='input' && evtMap.containsKey(cellData.Name)){
                        ECM_Event__c tempEvt=evtMap.get(cellData.Name);
                        tempEvt.ECM_Percent_Sponsorship_Fee_Allocation__c=decimal.valueOf(cellData.Value);
                        evtMap.put(cellData.Name,tempEvt);                
                }
                if(cellData.Name.contains('Investment Data')){
                        ECM_Event_Additional_Information__c eventadditional= new ECM_Event_Additional_Information__c();
                        eventadditional.RecordTypeId=investmentrecordTypeId;
                        eventadditional.ECM_Investment_Type__c=cellData.Name.split('_')[1];
                        eventadditional.ECM_Investment_Percentage__c=cellData.Value==''?null:Decimal.ValueOf(cellData.Value);
                        eventadditional.ECM_Investment_Amount__c=Decimal.ValueOf(r.Cells[2].Value);
                        eventadditional.ECM_Contract__c=contractId;
                        eventadditional.ECM_Unique_Id__c=contractId+'_'+eventadditional.ECM_Investment_Type__c;
                        if(cellData.Name.split('_')[2]!='null'){
                            eventadditional.Id=cellData.Name.split('_')[2];
                        }
                        eventadditionalMap.put(eventadditional.ECM_Investment_Type__c,eventadditional);                      
                }
                
                if(cellData.Name.contains('EventInvestmentData') && evtMap.containsKey(cellData.Name.split('__')[2])){
                        ECM_Event_Additional_Information__c eventadditionalInvestment= new ECM_Event_Additional_Information__c();
                        eventadditionalInvestment.RecordTypeId=eventInvestmentrecordTypeId;
                        eventadditionalInvestment.ECM_Event__c=evtMap.get(cellData.Name.split('__')[2]).Id;
                        eventadditionalInvestment.ECM_Amount_Per_Investment_Per_Event__c=Decimal.ValueOf(cellData.Value);
                        eventadditionalInvestment.ECM_Contract__c=contractId;
                        eventadditionalInvestment.ECM_Investment_Type__c=cellData.Name.split('__')[1];
                        if(cellData.Name.split('__')[3]!='null'){
                            eventadditionalInvestment.Id=cellData.Name.split('__')[3];
                        }
                    eventinvestmentMap.put(eventadditionalInvestment.ECM_Investment_Type__c+'_'+cellData.Name.split('__')[2],eventadditionalInvestment);                      
                }
                
            }
        }
        
        Try{
            if(!evtMap.isEmpty()){  
                Database.update(evtMap.Values());
            }
            if(!eventadditionalMap.isEmpty()){
                Database.upsert(eventadditionalMap.Values(),ECM_Event_Additional_Information__c.ECM_Unique_Id__c);
            }
            for(ECM_Event_Additional_Information__c eventinvestment: eventinvestmentMap.Values()){
               eventinvestment.ECM_Investment__c = eventadditionalMap.get(eventinvestment.ECM_Investment_Type__c).Id;
               eventinvestment.ECM_Unique_Id__c = contractId+'_'+eventinvestment.ECM_Event__c+'_'+eventinvestment.ECM_Investment__c;
            }
            if(!eventinvestmentMap.isEmpty()){
                Database.upsert(eventinvestmentMap.Values(),ECM_Event_Additional_Information__c.ECM_Unique_Id__c);
            }            
        }
        Catch(Exception ex){
                 System.debug('Class:ECM_CreateContractControllerEandS\nmethod:saveInvestmentRecord\nException:::' 
                              + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());             
        }
        
        ECM_ReviewAndSubmitController.Wrapper_Review_cal onpremisereview = (ECM_ReviewAndSubmitController.Wrapper_Review_cal)JSON.deserialize(onPremiseWrapper,ECM_ReviewAndSubmitController.Wrapper_Review_cal.class);
        contractdetail.ECM_Additional_Brand_Funding__c = AdditionalBrandFunding;
        contractdetail.ECM_Indicative_Total_Funding__c = indicativetotalfunding; //ECM-5816
        contractdetail.ECM_Additional_Brand_Funding_IO__c = AdditionalIO;
        ECM_ReviewAndSubmitController.SaveContract(contractdetail,null,null,null,onPremiseWrapper,null);
    }
    
    /*
    * Name : submitForApproval
    * @description : Submits Contract in Approval Process
    * @return : ECM_CreateContractController.objectWrapper
    * @param :  Contract - instance of Contract Record
	*/               
    @AuraEnabled
    Public static ECM_CreateContractController.objectWrapper submitForApproval(Contract ContractRecord){
        ECM_CreateContractController.objectWrapper wrapData = new ECM_CreateContractController.objectWrapper();
        wrapData = ECM_ReviewAndSubmitController.submitForApproval(ContractRecord);
        return wrapData;
    }

    /*Wrapper Class to hold branding data transmission between FE & BE*/
    public class brandingWrapper{
        @AuraEnabled public List<Pick_Up_Options__c> brandingPickUpList {get;set;}
        @AuraEnabled public List<Pick_Up_Options__c> brandingMrchndisePickUpList {get;set;}
        @AuraEnabled public List<ECM_Event_Additional_Information__c> brandingEvntInfo {get;set;}
        @AuraEnabled public List<ECM_Event_Additional_Information__c> brandingMrchndiseEvntInfo {get;set;}
        @AuraEnabled public List<String> recTypeIds {get;set;}
    }
    
    /*Wrapper Class to hold Investment Summary table data*/
    public class tableData{
        @AuraEnabled public List<Row> rows;
        @AuraEnabled public List<ECM_Event__c> eventList;
        @AuraEnabled public Decimal indicativetotalFunding;
        @AuraEnabled public Decimal AdditionalBrandFunding;
        @AuraEnabled public String AdditionalIO;
        public void tableData(){
            rows = new List<Row>();
			eventList = new List<ECM_Event__c>();
        }
    }
    
    /*Wrapper Class to hold Investment Summary table row data*/
    public class Row{
        @AuraEnabled public List<Cell> Cells;
        public void Row(){
            Cells = new List<Cell>();
        }
    }
    
    /*Wrapper Class to hold Investment Summary table cell data*/
    public class Cell{
        @AuraEnabled public String Name{get; set;}
        @AuraEnabled public String Value{get; set;}
        @AuraEnabled public String Id{get; set;}
        @AuraEnabled  public String datatype{get; set;}
        @AuraEnabled public String inputtype{get; set;}
        @AuraEnabled public String className{get; set;}
        public  Cell(){
            
        }
        public Cell(String Name, String value, String datatype, String className){
            this.Name=Name;
            this.Value=value;
            this.datatype=datatype;
			this.className=className;
        }
    }
}