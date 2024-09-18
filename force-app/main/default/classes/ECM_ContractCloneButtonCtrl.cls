/*
@Name: ECM_ContractCloneButtonCtrl
@Description: This Class is used for fetching required data for components "ECM_ContractCloneButton.cmp"
@History                                                            

VERSION		AUTHOR					DATE				DETAIL
1.0      Veerendra              01/12/2021              intial 

1.2		Saurav Prasad			03/12/2021			-ECM-5032 -CLONE - Clone Popup Window_Validations_Part 2_SFDC_GLO - Added getCloneButtonAccess Method       
1.3		Veerendra				03/12/2021			-ECM-5003 : Clone Popup Window_Validations_SFDC_GLO - Added getCloneScreenlabels Method
1.4		Pratap Sen				03/12/2021			-ECM-4999 : Pop up window for Cloning of Contract_SFDC_GLO
1.5		Anshu Prakash			07/12/2021			-ECM-4998 : New field in Agreement type Creation and Logic _Cloning _GLO
1.6		Saurav Prasad			12/01/2022			-ECM-5112 : Mapping Child Contract from Parent Contract_SFDC_GLO - update on processCloneScreenInfo
1.7		Subhrojit Majumdar		25/01/2022			-ECM-5011 : Screen 5 Validations
1.8     Pratap Sen              27/01/2022          -ECM-5009 : Screen 3 Volume-Data Clone & Validations_SFDC_EU
1.9     Veerendra               28/01/2022          -ECM-5139 : Validations for options in clone popup_SFDC_EU
2.0		Saurav Prasad			07/02/2022			-ECM-5020 : Screen 3 Contract Cloning_Validations_SFDC_AU
2.1 	Swagata Mondal			08/02/2022			-ECM-5018 : Screen 1 Contract Cloning Fetcing Records
2.2     Tanishq & Anshu         08/02/2022          -ECM-5160 : Screen 5 Contract Recalling_Validations_SFDC_AU
2.3     Pratap Sen              11/02/2022          -ECM-5134 : Logic for Category Contracts on Screen-3 Clonning
2.4     Tanishq & Anshu         28/02/2022          -ECM-5278 : Sanity Bug_March 2022 Release_AUS_Recalling 5th Page Customer Investment Total Per Year_Not Calculated Properly
2.5		Saurav Prasad			01/04/2022			-ECM-5004 : Pop up window for Cloning of Contract_Group Contract_SFDC_GLO
2.6     Prashanth               24/06/2022          -ECM-5686 : Screen 5 Contract Cloning_Additional Clause_SFDC_GLO
2.7     Prashanth               24/06/2022          -ECM-5687 : Screen 5 Contract Recall_Additional Clause_SFDC_GLO
2.8		Wribhu Bose				06/07/2022			-ECM-5781 : Screen 1 Distributors Fields for Cloned Contract_SFDC_EU
2.9		Wribhu Bose				06/07/2022			-ECM-5779 : Screen 1 Distributors Fields for Recalled Contract_SFDC_EU
3.0     Pratap/Subhrojit        07/07/2022          -ECM-5782 & ECM-5783 : Clone Activation Spend Records on contract clonning/recalling
3.1     Tanishq Banerjee        08/01/2022          -ECM-5914 : Update Logic for NNLP, COGS at Contract Item + Migration
3.2     Abhsihek Shivam         09/11/2022          -ECM-6223 : Migrating Contract Item CTD KPIs from parent to child contract_SFDC_EU
3.3		Anuja Chattopadhyay		11/11/2022			-ECM-6310 : Payment schedule section to be non-editable_Addendum_SFDC_EU
3.4		Saurav/Doman       		05/10/2023			-146648 -  CM static code violation for the classes_SFDC_Global
3.5		Saurav      		15/12/2023			-149212 -  Fast track_ Allow Draft and In Approval process cloning validation 
*/ 
public with sharing class ECM_ContractCloneButtonCtrl {
    @AuraEnabled
    public static string validation_for_Agreement_Type(contract con,string accountid ,String recordTypeId){
        return ECM_CreateContractController.validation_for_Agreement_Type(con, accountid, recordTypeId);
    }
    @AuraEnabled
    //ECM-4998
    public static CustomCloneWrapper getCloneButtonAccess(String contractId){
        CustomCloneWrapper customCloneWrapperObj = new CustomCloneWrapper();
        Map<String,Map<String,String>> customValidationMap = new Map<String,Map<String,String>>();
        try{
            User oUser = [select id,Name,Profile.Name,Available_Countries__c FROM User Where id =: userInfo.getUserId()];

            //ECM-5018 Fetching Information from old Contract to Cloned Contract
            Contract con = [SELECT Id,Name,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                            StartDate,RecordTypeId,Recordtype.Name,ECM_Territory__c,ECM_Agreement_Type__c,
                            ECM_Agreement_Type__r.Geography__c,ECM_Agreement_Type__r.Geography__r.Name,CreatedBy.Name,
                            AccountId,Account.Name,Account.Local_Segment1__r.Name,Account.Country__r.Name,
                            Account.Country_Code__c,ECM_Parent_Contract__c,ECM_Cloned__c,ECM_Channel__c,ECM_Banner__c,ECM_RTD_Discount_Level__c,
							ECM_Spirits_Discount_Level__c,ECM_Spirits_Pouring_Discount_Level__c,ECM_Spirits_Premium_Discount_Level__c,
                            ECM_Spirits_Reserve_Discount_Level__c,ECM_Draught_Spirits_Discount_Level__c,
	         				ECM_Distilled_NonAlchlic_Discount_Level__c,ECM_RTD_Sales_driver__c, ECM_Spirits_Sales_driver__c, ECM_Spirits_Pouring_Sales_driver__c, ECM_Distilled_NonAlchlic_Sales_driver__c, ECM_Spirits_Premium_Sales_driver__c,
                            ECM_Spirits_Reserve_Sales_driver__c, ECM_Draught_Spirits_Sales_driver__c FROM Contract WHERE Id=:contractId WITH SECURITY_ENFORCED];


            System.debug(LoggingLevel.DEBUG,'Success1@@'+con);
            //Added ECM_Allow_draft_and_In_Approval_cloning__c in the query for defect 149171/149212
			ECM_Contract_Type__c ecmContractType = [select Id,Name,ECM_Enable_Cloning__c,ECM_Allow_draft_and_In_Approval_cloning__c,ECM_Screen_3_field_configuration__c,ECM_Volume_UoM_for_Beer__c,
                                                    Volume_UoM_for_Spirits__c,Geography__r.Code__c,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Aggrement_Duration__c,
                                                    ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,
                                                    ECM_Number_of_Retro_Months__c
                                                    from ECM_Contract_Type__c where Id=: con.ECM_Agreement_Type__c WITH SECURITY_ENFORCED];
            //Fetching country details from Market Settings to pass it to screen information
            Market_Setting__c marketObjs= [SELECT Id,Geography__r.Code__c,ECM_Contract_Creation_Page__c FROM Market_Setting__c 
                                           WHERE Geography__r.Code__c =: con.Account.Country_Code__c WITH SECURITY_ENFORCED LIMIT 1];
            String conCountry = '%'+marketObjs.ECM_Contract_Creation_Page__c+'%';
            System.debug(LoggingLevel.DEBUG,'Success2@@'+ecmContractType);
            //Fetching screen information from ECM_Clone_Contract_ScreenInfo__mdt metadata
            List<ECM_Clone_Contract_ScreenInfo__mdt> cloneLablesList = new List<ECM_Clone_Contract_ScreenInfo__mdt>();
            //ECM-5004 - added con.Recordtype.Name in query
            CloneLablesList = [SELECT ScreenName__c,Field_Name__c,Field_Label__c,Display_order__c,
                               Custom_Data_Type__c,Data_Type__c,Required__c,
                               Field_API_Name__c,Validation_Messages__c
                               FROM ECM_Clone_Contract_ScreenInfo__mdt 
                               WHERE Country_Code__c LIKE:conCountry AND
                               ECM_Contract_Record_Type__c LIKE :'%'+con.Recordtype.Name+'%'
                               ORDER BY Display_order__c];
            
            customCloneWrapperObj.listOfCustomMetaData = cloneLablesList;
            customCloneWrapperObj.userDetails = oUser;
            customCloneWrapperObj.agreementType = ecmContractType;
            customCloneWrapperObj.referenceContract = con;
            customCloneWrapperObj.recordtypeName= con.Recordtype.Name;
            customCloneWrapperObj.isAus = marketObjs.ECM_Contract_Creation_Page__c =='Australia'?true:false;
            
            //Adding validation map
            for(ECM_Clone_Contract_ScreenInfo__mdt rec:CloneLablesList){
                if(String.isNotBlank(rec.Validation_Messages__c)){
                    List<String> multiValidations = rec.Validation_Messages__c.split(';');
                    for(String str:multiValidations){
                        List<String> keyValuePair = str.split(',');
                        if(!customValidationMap.containsKey(rec.Field_Name__c)){
                            customValidationMap.put(rec.Field_Name__c,new Map<String,String>{keyValuePair[0] => keyValuePair[1]});
                        }else{
                            customValidationMap.get(rec.Field_Name__c).put(keyValuePair[0], keyValuePair[1]);
                        }
                    }
                }
            } 
            customCloneWrapperObj.ValidationMap = customValidationMap;
            
        }catch (Exception ex) {
            System.debug(LoggingLevel.DEBUG,'Class:ECM_ContractCloneButtonCtrl\nmethod:getCloneButtonAccess\nException:::' + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            
        }   
        return customCloneWrapperObj;
    }
    /*
* @description : This method is used to save the record based on the selected Screens on Clone Contract
* @return : Contract Record
* @param : Contract,String,String,String,String,List<Account>,String
*/
    @AuraEnabled
    public static contract processCloneScreenInfo(Contract con,String accId, String recordTypeId,String territoryId,String contractTypeId,List<Account> customerList,String jsonString ) {
		System.debug(LoggingLevel.DEBUG,'jsonString@'+jsonString);
        Map<String,String> customMap = (Map<String,String>)JSON.deserialize(jsonString, Map<String,String>.class);
    
        //Screen 1
        Contract conRec = new Contract();
        //Screen 2 
        List<ECM_Contract_Item__c> newConItems = new List<ECM_Contract_Item__c>();
        List<ECM_Product_Agreement__c> prodAgreementList = new List<ECM_Product_Agreement__c>();
        //Screen 3
        Map<Id,ECM_Contract_Item__c> newConItemsMap = new Map<Id,ECM_Contract_Item__c>();
        Set<Id> clonnedCIs = new Set<Id>();
        Contract parentCon = new Contract();
        //ECM-5160- Added some fields in the query
        //ECM-5278- Added some fields in the query
        parentCon = [SELECT Id,Name,ECM_Agreement_Type__c,ECM_Agreement_Type__r.ECM_Volume_target__c,
                     ECM_Agreement_Type__r.ECM_Screen_3_field_configuration__c,ECM_Agreement_Type__r.ECM_Category_Contracts__c,
                     ECM_Payment_Frequency_type__c,ECM_Additional_info_to_support_decision__c,ECM_A_P_Fund__c,ECM_Portfolio_Rebate__c,
                     ECM_Total_Training_Over_Term__c,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Additional_Investment_Total_Per_Onpr__c,
                     ECM_Total_Sales_Driver_Per_Year_Onpremis__c,ECM_Additional_Clause__c,
                     ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Selected_Payment_Schedule_AU__c, 
                     ECM_Payment_Schedule_Date_AU__c,ECM_A_P_RollOver__c,
                     AccountId,Account.Country__c,ECM_Primary_Beer_Distributor__c,ECM_Primary_Spirit_Distributor__c,ECM_Secondary_Spirit_Distributor__c
                     FROM Contract 
                     WHERE Id =: con.ECM_Parent_Contract__c WITH SECURITY_ENFORCED];

        //ECM-5020
        Boolean isAus = Boolean.valueOf(customMap.get('isAus'));
        //Screen 4
        Set<Id> productIds = new Set<Id>();
        Map<Id,ECM_Contract_Item__c> mapOfConItems = new Map<Id,ECM_Contract_Item__c>();
        /*Set<Id> marketAssortProductIds = new Set<Id>();
        Map<Id,List<ECM_Sales_Driver_Item_Detail__c>> mapOfSDID = new Map<Id,List<ECM_Sales_Driver_Item_Detail__c>>();
        Map<Id,ECM_Sales_Driver_Item__c> mapOfSDI = new Map<Id,ECM_Sales_Driver_Item__c>();
        List<ECM_Sales_Driver_Item_Detail__c> newSDIDList = new List<ECM_Sales_Driver_Item_Detail__c>();*/

        //ECM-5139
        List<ECM_Sales_Agreement__c> updatedsalesAgreementList = new List<ECM_Sales_Agreement__c>();
        ECM_CreateContractController.salesdriverswithAgreementType salesAgreementWrap = ECM_CreateContractController.salesdrivers(contractTypeId);
        updatedsalesAgreementList = salesAgreementWrap.salesAgreementList;
        System.debug(LoggingLevel.DEBUG,'@@con' +con);
        System.debug(LoggingLevel.DEBUG,'@@accId' +accId);
        
        //Screen 1 
        conRec = ECM_CreateContractController.createContract( con, accId,  recordTypeId, territoryId, contractTypeId, customerList );
        //ECM-5779 & ECM-5781
        if(String.isNotBlank(conRec.AccountId) && parentCon.AccountId == conRec.AccountId){
            for(Supplier_Outlet__c supOutObj : [SELECT Id, Name, Distributor_Wholesaler__c 
                                              	FROM Supplier_Outlet__c 
                                              	WHERE outlet__c = :conRec.AccountId]){
                if(String.isNotBlank(parentCon.ECM_Primary_Spirit_Distributor__c) && supOutObj.Distributor_Wholesaler__c == parentCon.ECM_Primary_Spirit_Distributor__c){
                    conrec.ECM_Primary_Spirit_Distributor__c = parentCon.ECM_Primary_Spirit_Distributor__c;
                }
                if(String.isNotBlank(parentCon.ECM_Primary_Beer_Distributor__c) && supOutObj.Distributor_Wholesaler__c == parentCon.ECM_Primary_Beer_Distributor__c){
                    conrec.ECM_Primary_Beer_Distributor__c =  parentCon.ECM_Primary_Beer_Distributor__c;
                }
                if(String.isNotBlank(parentCon.ECM_Secondary_Spirit_Distributor__c) && supOutObj.Distributor_Wholesaler__c == parentCon.ECM_Secondary_Spirit_Distributor__c){
                    conrec.ECM_Secondary_Spirit_Distributor__c = parentCon.ECM_Secondary_Spirit_Distributor__c;
                }                                  
            }
        }
        System.debug(LoggingLevel.DEBUG,'@@@clone'+conrec.ECM_Secondary_Spirit_Distributor__c);
        //Adding as a part of ECM-5112        
        //Screen 2
        List<ECM_Contract_Item__c> conitemList = new List<ECM_Contract_Item__c>();
        if(customMap.containsKey('Product') && Boolean.valueOf(customMap.get('Product'))){
            conitemList=dynamicQueryMethod('ECM_Contract_Item__c',con,'ECM_Contract__c=:parentid',null);
            system.debug(LoggingLevel.DEBUG,'size@@'+conitemList.size());
            for(ECM_Contract_Item__c oldConItem :conitemList){
                productIds.add(oldConItem.ECM_Product__c);
            }
            
            prodAgreementList = dynamicQueryMethod('ECM_Product_Agreement__c',con,'ECM_Contract_Type__c =:agreementType AND ECM_Market_Assortment_Product__c IN:productIds',productIds);
            system.debug(LoggingLevel.DEBUG,'prodAgreementListss@'+prodAgreementList);
            system.debug(LoggingLevel.DEBUG,'Product size@'+prodAgreementList.size());
            newConItems = ECM_SelectProductsController.insertContractitems(conRec,prodAgreementList,null);  
			system.debug(LoggingLevel.DEBUG,'conitem size@'+newConItems.size());
            //ECM-5020
            newConItems = dynamicQueryMethod('ECM_Contract_Item__c',conRec,'ECM_Contract__c=:conid',null);
        }
        if(!newConItems.isEmpty()){
            for(ECM_Contract_Item__c conItem : newConItems){
                newConItemsMap.put(conItem.ECM_Product__c,conItem);
            }
        }
        
        //Screen 3 : ECM-5009
        if(customMap.containsKey('Volume') && Boolean.valueOf(customMap.get('Volume'))){
            if(parentCon.ECM_Agreement_Type__r.ECM_Volume_target__c && !conitemList.isEmpty()){
                
                if(parentCon.ECM_Payment_Frequency_type__c != NULL){
                    List<ECM_Payment_Agreement__c> currPayAgg = [SELECT id,ECM_Payment_Frequency__c FROM ECM_Payment_Agreement__c WHERE 
                                                                 ECM_Payment_Frequency__c =: parentCon.ECM_Payment_Frequency_type__c AND ECM_Agreement_Type__c =: contractTypeId];
                    if(!currPayAgg.isEmpty()){
                       conRec.ECM_Payment_Frequency_type__c = parentCon.ECM_Payment_Frequency_type__c; 
                    } 
                }
                   
                    for(ECM_Contract_Item__c oldConItem : conitemList){
                        if(newConItemsMap.containsKey(oldConItem.ECM_Product__c) && newConItemsMap.get(oldConItem.ECM_Product__c)!=NULL){                        
                            //ECM-5020
                        if(isAus){
                            //ECM_VolumeTarget_AU component level fields
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_First_Pour__c = oldConItem.ECM_First_Pour__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Mandatory_Back_Bar__c = oldConItem.ECM_Mandatory_Back_Bar__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_volume_hybrid_override__c = oldConItem.ECM_volume_hybrid_override__c == NULL? 0 : oldConItem.ECM_volume_hybrid_override__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_MAT_override__c = oldConItem.ECM_MAT_override__c == NULL? 0 : oldConItem.ECM_MAT_override__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_TSDD_Override__c = oldConItem.ECM_TSDD_Override__c == NULL? 0 : oldConItem.ECM_TSDD_Override__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_TotalSKU_SpecificRebate__c = oldConItem.ECM_TotalSKU_SpecificRebate__c == NULL? 0 : oldConItem.ECM_TotalSKU_SpecificRebate__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_FinalLUC_Target__c = oldConItem.ECM_FinalLUC_Target__c == NULL? 0 : oldConItem.ECM_FinalLUC_Target__c;
                            
                            //ECM_VolumeTarget_AU helper level fields
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_MAT_Original_Entered__c = oldConItem.ECM_MAT_Original_Entered__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_LUC_Discount__c = oldConItem.ECM_LUC_Discount__c;
                            
                            //ECM_volumetargetController_AU level field mapping
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Volume_Target_Investment_Description__c = String.isBlank(oldConItem.ECM_Volume_Target_Investment_Description__c)? '' : oldConItem.ECM_Volume_Target_Investment_Description__c;
                            
                        }else{
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Baseline_volume__c = oldConItem.ECM_Baseline_volume__c == NULL? 0 : oldConItem.ECM_Baseline_volume__c;
                            newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Product_growth_driver__c = oldConItem.ECM_Product_growth_driver__c;
                            if( newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Contract__r.ECM_Amended__c){  //ECM-6223
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_CTD_A_P_Investment__c = oldConItem.ECM_CTD_A_P_Investment__c;
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_CTD_Trade_Lump_Sum__c = oldConItem.ECM_CTD_Trade_Lump_Sum__c;
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_CTD_Overall_Investment__c = oldConItem.ECM_CTD_Overall_Investment__c;
                                //newConItemsMap.get(oldConItem.ECM_Product__c).ECM_CTD_Total_NSV__c = oldConItem.ECM_CTD_Total_NSV__c;(not needed since ECM_CTD_Trade_Lump_Sum__c is copied)
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Parent_Actual_Volume_CTD__c = oldConItem.ECM_Actual_Volume_YTD__c; //ECM-6315
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Actual_Volume_YTD__c = oldConItem.ECM_Actual_Volume_YTD__c; //ECM-6315
                               }
                            if(!(parentCon.ECM_Agreement_Type__r.ECM_Category_Contracts__c && newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Lead_Brand__c)){//ECM-5134
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Volume__c = oldConItem.ECM_Volume__c == NULL? 0 : oldConItem.ECM_Volume__c;
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_UoM__c = oldConItem.ECM_UoM__c;
                                newConItemsMap.get(oldConItem.ECM_Product__c).ECM_Investment__c = oldConItem.ECM_Investment__c == NULL? 0 : oldConItem.ECM_Investment__c;
                            }
                        }
                        clonnedCIs.add(oldConItem.Id);
                    }
                }
                Database.SaveResult[] saveRes = Database.update(newConItems, false);
                System.debug(LoggingLevel.DEBUG,'saveRes @'+saveRes);
                if(parentCon.ECM_Agreement_Type__r.ECM_Screen_3_field_configuration__c.contains('Tiering')){
                    List<ECM_Tiering__c> listTier = new List<ECM_Tiering__c>();
                    for(ECM_Tiering__c tierRec : [SELECT ECM_Tier_1_volume_limit__c,ECM_Tier_1_rate_per_UoM__c,ECM_Tier_2_volume_limit__c,ECM_Tier2_rate_per_UoM__c,
                                                  ECM_Tier_3_volume_limit__c,ECM_Tier_3_rate_per_UoM__c,ECM_Contract_Item__r.ECM_Product__c FROM ECM_Tiering__c
                                                  WHERE ECM_Contract_Item__c IN: clonnedCIs WITH SECURITY_ENFORCED])
                    {
                        ECM_Tiering__c newTierRec = tierRec.clone(false,false,false,false);
                        newTierRec.ECM_Contract_Item__c = newConItemsMap.get(tierRec.ECM_Contract_Item__r.ECM_Product__c).Id;
                        listTier.add(newTierRec);
                    }
                    if(!listTier.isEmpty()){
                        insert listTier;
                    }                    
                }
            }
        }
        
        //Screen 4
        //ECM-5139
       
        if(customMap.containsKey('Sales Drivers') && Boolean.valueOf(customMap.get('Sales Drivers'))){
            Set<Id> sdIds = new Set<Id>();
            for(ECM_Sales_Agreement__c aggSdIds :updatedsalesAgreementList ){
                sdIds.add(aggSdIds.ECM_Sales_Driver__c);
            }
            //ECM-5782 & ECM-5783
            Id mustDoRecId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Must Do').getRecordTypeId();
            Id asSubGroupRecId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Activation Spend Sub-Group').getRecordTypeId();
            List<String> activationSpentPckUpOptions = new List<String>();
            for(Pick_Up_Options__c it : [SELECT Id FROM Pick_Up_Options__c WHERE Geography__c =: parentCon.Account.Country__c AND Status__c = 'Active' 
                         				 AND (RecordTypeId =: mustDoRecId OR RecordTypeId =: asSubGroupRecId) WITH SECURITY_ENFORCED]){
                     activationSpentPckUpOptions.add(it.Id);
            }
            System.debug(LoggingLevel.DEBUG,'sdIds@'+sdIds);
            System.debug(LoggingLevel.DEBUG,'Salescalls@');
            Boolean addSDInvestment = customMap.containsKey('SD Investments')?Boolean.valueOf(customMap.get('SD Investments')):false;
            mapOfConItems = new Map<Id,ECM_Contract_Item__c>(conitemList);
            
            insertSalesdriverItem(sdIds,con.ECM_Parent_Contract__c,con.Id,mapOfConItems.keyset(),JSON.serialize(newConItemsMap),activationSpentPckUpOptions,addSDInvestment);
            
        }
        //End of ECM-5112
        //Screen 5
        //ECM-5160 modification start
        Decimal aNdPUnspendVal=0;

        if(parentCon != NULL){
            //ECM-5686 and ECM-5687
            conRec.ECM_Additional_Clause__c = parentCon.ECM_Additional_Clause__c;  
            if(isAus){
                if(customMap.containsKey('A&P details') && Boolean.valueOf(customMap.get('A&P details'))){               
                    conRec.ECM_A_P_Fund__c = parentCon.ECM_A_P_Fund__c;
                    conRec.ECM_Portfolio_Rebate__c = parentCon.ECM_Portfolio_Rebate__c;
                    //Bug ECM-5278
                    conRec.ECM_OnPremise_Total_A_P_PerYear__c = parentCon.ECM_OnPremise_Total_A_P_PerYear__c!=Null?parentCon.ECM_OnPremise_Total_A_P_PerYear__c:0;
                }
                //Bug ECM-5278
                else{
                    conRec.ECM_OnPremise_Total_A_P_PerYear__c =0;
                }
                
                if(customMap.containsKey('Additional Investments') && Boolean.valueOf(customMap.get('Additional Investments'))){
                    conRec.ECM_Total_Training_Over_Term__c = parentCon.ECM_Total_Training_Over_Term__c;
                    conRec.ECM_Total_Upfront_Payment_Loan_Over_Term__c = parentCon.ECM_Total_Upfront_Payment_Loan_Over_Term__c;
                    conRec.ECM_Total_Others_Over_Term__c = parentCon.ECM_Total_Others_Over_Term__c;
                    conRec.ECM_Selected_Payment_Schedule_AU__c = parentCon.ECM_Selected_Payment_Schedule_AU__c;
                    conRec.ECM_Payment_Schedule_Date_AU__c = parentCon.ECM_Payment_Schedule_Date_AU__c;
                              
                   //Bug ECM-5278
                    conRec.ECM_Additional_Investment_Total_Per_Onpr__c = parentCon.ECM_Additional_Investment_Total_Per_Onpr__c!=Null?parentCon.ECM_Additional_Investment_Total_Per_Onpr__c:0;
                }
                //Bug ECM-5278
                else{
                   conRec.ECM_Additional_Investment_Total_Per_Onpr__c=0; 
                }
                //Bug ECM-5278                
                conRec.ECM_Total_Sales_Driver_Per_Year_Onpremis__c = parentCon.ECM_Total_Sales_Driver_Per_Year_Onpremis__c!=Null?parentCon.ECM_Total_Sales_Driver_Per_Year_Onpremis__c:0;
                conRec.ECM_Customer_Investment_TotalPer_Onpremi__c = conRec.ECM_Total_Sales_Driver_Per_Year_Onpremis__c + conRec.ECM_OnPremise_Total_A_P_PerYear__c + conRec.ECM_Additional_Investment_Total_Per_Onpr__c;
                                
                conRec.ECM_Additional_info_to_support_decision__c = parentCon.ECM_Additional_info_to_support_decision__c;

                ECM_ReviewAndSubmitController.WrapperInst wrapVal = ECM_ReviewAndSubmitController.get_active_A_Precord(conRec);
                
                if (wrapVal != null && wrapVal.apUnspent != Null) {
                    aNdPUnspendVal= wrapVal.apUnspent;
                }                
                if(aNdPUnspendVal>=parentCon.ECM_A_P_RollOver__c){
                    conRec.ECM_A_P_RollOver__c = parentCon.ECM_A_P_RollOver__c;
                }else{
                    conRec.ECM_A_P_RollOver__c = 0;
                }  
            }else{
                conRec.ECM_Additional_info_to_support_decision__c = parentCon.ECM_Additional_info_to_support_decision__c;
              
      
            }
          
          
        }
        //End of ECM-5160
        update conRec;
        return conRec;
    }
/* 
* Method Name   : insertSalesdriverItem
*  Description   : This method is used to Future call dml 
*  AUTHOR        : Anivesh Muppa
*  Date          : 28/01/2022
*/
    @future
    public static void insertSalesdriverItem(Set<Id> sdIds,String contractParent,String newContract,Set<Id> contractItemList,String newContItem,List<Id> asPickUpRecIds,boolean addSDInvestment){   
        
        System.debug(LoggingLevel.DEBUG,'insertSalesdriverItem@'+newContItem);
        Map<Id,ECM_Contract_Item__c> newConItemsrec = (Map<Id,ECM_Contract_Item__c>)JSON.deserialize(newContItem, Map<Id,ECM_Contract_Item__c>.class);
        Map<Id,List<ECM_Sales_Driver_Item_Detail__c>> mapOfSDID = new Map<Id,List<ECM_Sales_Driver_Item_Detail__c>>();
        Map<Id,ECM_Sales_Driver_Item__c> mapOfSDI = new Map<Id,ECM_Sales_Driver_Item__c>();
        List<ECM_Sales_Driver_Item_Detail__c> newSDIDList = new List<ECM_Sales_Driver_Item_Detail__c>();
        Id sdidASRecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();
        system.debug(LoggingLevel.DEBUG,'SDIDs@@'+sdIds);
        system.debug(LoggingLevel.DEBUG,'contractParent@@'+contractParent);
        
        for(ECM_Sales_Driver_Item_Detail__c sdid : 
            [SELECT Id,Name,ECM_Product__c,ECM_Investment_Amount__c,ECM_Activity_Type_Description__c,ECM_Delivery_Date_Year__c,
             ECM_Delivery_Date_Month__c,ECM_MustDo__c,ECM_Activation_Spend_SubGroup__c,ECM_Sales_Driver_Item__c,
             ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c,ECM_Product__r.ECM_Product__c,
             ECM_Product__r.ECM_Investment__c,ECM_Sales_Driver_Item__r.Contract__c,RecordTypeId,
             ECM_Product__r.ECM_Product_Name__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver_Name__c 
             FROM ECM_Sales_Driver_Item_Detail__c 
             WHERE ECM_Sales_Driver_Item__r.Contract__c=:contractParent AND
             ECM_Product__c IN:contractItemList AND ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c IN:sdIds AND ECM_Product__r.ECM_Product__c IN:newConItemsrec.keyset()
             ORDER BY ECM_Sales_Driver_Item__r.ECM_Sales_Driver_Name__c]){
                 ECM_Sales_Driver_Item_Detail__c newSDID ;
                 if(!mapOfSDID.containsKey(sdid.ECM_Sales_Driver_Item__c)){
                     newSDID = addSDInvestment?sdid.clone(false,false,false,false):new ECM_Sales_Driver_Item_Detail__c();
                     newSDID.ECM_Product__c = newConItemsrec.get(sdid.ECM_Product__r.ECM_Product__c).Id;
                     newSDID.RecordTypeId = sdid.RecordTypeId;
                     if(newSDID.RecordTypeId == sdidASRecId){
                         newSDID.ECM_MustDo__c = (asPickUpRecIds.contains(sdid.ECM_MustDo__c))?sdid.ECM_MustDo__c:NULL;
                         newSDID.ECM_Activation_Spend_SubGroup__c = (asPickUpRecIds.contains(sdid.ECM_Activation_Spend_SubGroup__c))?sdid.ECM_Activation_Spend_SubGroup__c:NULL;
                     }
                     mapOfSDID.put(sdid.ECM_Sales_Driver_Item__c,new List<ECM_Sales_Driver_Item_Detail__c>{newSDID});
                 }else{
                     newSDID = addSDInvestment?sdid.clone(false,false,false,false):new ECM_Sales_Driver_Item_Detail__c();
                     newSDID.ECM_Product__c = newConItemsrec.get(sdid.ECM_Product__r.ECM_Product__c).Id;
                     newSDID.RecordTypeId = sdid.RecordTypeId;
                     if(newSDID.RecordTypeId == sdidASRecId){
                         newSDID.ECM_MustDo__c = (asPickUpRecIds.contains(sdid.ECM_MustDo__c))?sdid.ECM_MustDo__c:NULL;
                         newSDID.ECM_Activation_Spend_SubGroup__c = (asPickUpRecIds.contains(sdid.ECM_Activation_Spend_SubGroup__c))?sdid.ECM_Activation_Spend_SubGroup__c:NULL;
                     }
                     mapOfSDID.get(sdid.ECM_Sales_Driver_Item__c).add(newSDID);
                 }
             }
        System.debug(LoggingLevel.DEBUG,'mapOfSDID@'+mapOfSDID);
        //Added ECM_Is_Cloned__c as a part of ECM-6310 in Query
        for(ECM_Sales_Driver_Item__c sdi:
            [SELECT Id, Name,ECM_Sales_Driver_Name__c,ECM_Range__c,ECM_Sales_Driver__c,ECM_1st_Prepayment_Date__c,ECM_Remaining_Payment_Date__c,ECM_Is_Cloned__c,
             ECM_Payment_Frequency__r.ECM_Type__c,ECM_Investement_Description__c,ECM_Prepayment__c,ECM_Investment_Yr1__c,ECM_Investment_Yr2__c,ECM_Investment_Yr3__c,
             ECM_Payment_Date_Yr1__c,ECM_Payment_Date_Yr2__c,ECM_Payment_Date_Yr3__c,ECM_1st_Prepayment_Amount__c,ECM_Remaining_Payment_Frequency__c,
             ECM_Payment_Date__c,ECM_Budget_Type__c,ECM_Sales_Driver__r.Name,ECM_Payment_Frequency__c,
             ECM_Total_Investment_Amount__c,Contract__c,RecordTypeId
             From ECM_Sales_Driver_Item__c 
             WHERE Contract__c=:contractParent AND ECM_Sales_Driver__c IN: sdIds
             ORDER BY ECM_Sales_Driver_Name__c]){
                 if(!contractItemList.isEmpty()){
                     ECM_Sales_Driver_Item__c newSDI ; 
                     newSDI = addSDInvestment ? sdi.clone(false,false,false,false):new ECM_Sales_Driver_Item__c();
                     newSDI.Contract__c = (Id)newContract;
                     newSDI.ECM_Sales_Driver_Name__c = sdi.ECM_Sales_Driver_Name__c;
                     newSDI.ECM_Sales_Driver__c = sdi.ECM_Sales_Driver__c;
                     newSDI.ECM_Range__c = sdi.ECM_Range__c;
                     newSDI.RecordTypeId = sdi.RecordTypeId;
                     newSDI.ECM_Is_Cloned__c = true;//added as a part of ECM-6310
                     mapOfSDI.put(sdi.Id,newSDI);
                 }
             }
        //Create SD Item
        if(!mapOfSDI.values().isEmpty()){
            
            try{
                system.debug(LoggingLevel.DEBUG,'SDI Insert before@'+mapOfSDI);
                Database.SaveResult[] srList = Database.insert(mapOfSDI.values(), false);
                System.debug(LoggingLevel.DEBUG,'srList @'+srList);
            }catch(Exception ex){
                system.debug(LoggingLevel.DEBUG,'Error==='+ex); 
            }
            system.debug(LoggingLevel.DEBUG,'SDI Insert@'+mapOfSDI);
            for(Id oldSdiId : mapOfSDI.keySet()){	
                if(mapOfSDID.containsKey(oldSdiId) && mapOfSDI.get(oldSdiId).Id!=Null){
                    for(ECM_Sales_Driver_Item_Detail__c sdid : mapOfSDID.get(oldSdiId)){
                        sdid.ECM_Sales_Driver_Item__c = mapOfSDI.get(oldSdiId).Id;
                        System.debug(LoggingLevel.DEBUG,'conItem product@'+sdid.ECM_Product__c);
                        System.debug(LoggingLevel.DEBUG,'SD ITEM@'+sdid.ECM_Sales_Driver_Item__c);
                        newSDIDList.add(sdid);
                    }
                }
            }            
            
        }
        //Create SD Item Detail
        if(!newSDIDList.isEmpty()){
            Insert newSDIDList;
        }
        
    }
    
/*
*  Method Name   : dynamicQueryMethod
*  Description   : This method is used to query records Dynamically
*  AUTHOR        : Veerendra Billakurthi  
*  Date          : 28/01/2022
*/
    public static List < sObject > dynamicQueryMethod(String ObjectName, contract con, string searchKeyWord,set<Id> productIds) {
        system.debug(LoggingLevel.INFO,'ObjectName-->' + ObjectName);
        system.debug(LoggingLevel.INFO,'searchKeyWord='+searchKeyWord);
        //Variable declaration for condtions
        string parentid=con.ECM_Parent_Contract__c;
        string agreementType= con.ECM_Agreement_Type__c;
        //ECM-5020
        string conid = con.Id;
        system.debug(LoggingLevel.INFO,'parentid@'+parentid+'\n agreementType@'+agreementType+'\n conid@'+conid);
        system.debug(LoggingLevel.INFO,'searchKeyWord@'+searchKeyWord);

        try{
            map<String, Schema.SobjectType> globalDescribe = Schema.getGlobalDescribe();
            //Fetching all the fieldset
            map<String,Schema.SObjectField> fields = globalDescribe.get(ObjectName).getDescribe().fields.getMap();
            List<String> fieldsList = new List<String>(Fields.keyset()); 
            //ECM-5914
            if(ObjectName == 'ECM_Product_Agreement__c'){
                FieldsList.add('ECM_Market_Assortment_Product__r.ECM_Pickup_Option__c');
                FieldsList.add('ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c');
            }
            if(ObjectName == 'ECM_Contract_Item__c'){
                FieldsList.add('ECM_Contract__r.ECM_Amended__c');
            }
            //Return type
            List < sObject > returnList = new List < sObject > ();
            // Create a Dynamic SOQL Query For Fetch Record List 
            String sQuery = ' SELECT ' + String.join( FieldsList, ',' )+' FROM '+ObjectName+' WHERE '+searchKeyWord;    
            system.debug(LoggingLevel.DEBUG,'query@@'+sQuery);
            List < sObject > lstOfRecords = Database.query(String.escapeSingleQuotes(sQuery));      //146648
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
            system.debug(LoggingLevel.DEBUG,'returnList@@'+returnList);
            return returnList;
        }
        //Exception 
        catch(exception e){
            system.debug(LoggingLevel.DEBUG,'exception @@'+e);
            return null;
        }
    }
    public class CustomCloneWrapper{
        @AuraEnabled
        public List<ECM_Clone_Contract_ScreenInfo__mdt> listOfCustomMetaData{get;set;}
        @AuraEnabled
        public User userDetails{get;set;}
        @AuraEnabled
        public ECM_Contract_Type__c agreementType{get;set;}
        @AuraEnabled
        public Contract referenceContract{get;set;} 
        @AuraEnabled
        public Contract newContract{get;set;}
        @AuraEnabled
        public Map<String,Map<String,String>> validationMap{get;set;}
        @AuraEnabled
        public Boolean isAus{get;set;}
        @AuraEnabled
        public string recordtypeName{get;set;}
        
        public CustomCloneWrapper(){
            this.listOfCustomMetaData = new List<ECM_Clone_Contract_ScreenInfo__mdt>();
            this.userDetails = new User();
            this.agreementType = new ECM_Contract_Type__c();
            this.referenceContract = new Contract();
            this.newContract = new Contract();
            this.validationMap = new Map<String,Map<String,String>>();
            this.isAus = false;
        }
    }
}