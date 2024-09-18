/*
Name: ECM_PDF_Generation_Controller
Purpose: This is Class for fetch Template Section Map records to display data in PDF
https://edge--edgecmdev.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
History                                                            
*                                                            
VERSION         AUTHOR                      DATE                DETAIL
1.0         Pradeep Kumar Reddy         13/04/2020          Initial Development
1.1         Anivesh Muppa               14/04/2020          Initial Development
1.2         Veerendra Billakurthu       16/06/2021          ECM-4555 - Table generator for Ireland_SFDC_Tech debt
1.3         Anivesh Muppa               14/04/2020          ECM-4621 - changes on getSalesdrivelist
1.4         Manikandan.T                19/08/2022          ECM-4746 - changes on ECM_PDF_Generation_Controller(ApexPages.StandardController stdController) and getSalesdrivelist() to reduce the number of SOQL queries. 
1.5         Anivesh Muppa               14/04/2021          ECM-4761 - code consolidation
1.6         Anivesh Muppa               30/10/2021          ECM-4815 
1.7         Anivesh Muppa               10/11/2021          ECM-4908 - Logic for the Information field of SD on Screen 4 Contract creation_Single Yearly Payment
1.8         veerendra                   10/01/2022          ECM-5011 -bug
1.9         Anivesh Muppa               10/01/2022          ECM-4987  - Tech debt- revamped the class
2.0         Subhrojit Majumdar          06/04/2022          ECM-5417 : Added logic for ECM_MAT_Final__c field.
2.1         Saurav Prasad               29/08/2022          ECM-6076 : Logic for "Type" field on Template Agreement_Contracts_SFDC_EU   
2.2         Pratik                      02/09/2022          ECM-6052 : E&S Event Table Display_SFDC_AU_E&S
2.3         Pratap                      27/09/2022          ECM-6161 : Display dynamic clauses based on multiple growth drivers_SFDC_EU
2.4         Nikhilesh Chandak           26/10/2022          ECM-6268 : PDF generation for Addendum Child Contract_SFDC_EU
2.5         Saurav Prasad               07/11/2022          ECM-6306 : PF translation in Contract PDF
2.6         Priya Soni                  07/12/2022          ECM-6402 : Multi Select Sales Driver to appear multiple times in pdf
2.7         Saurav Prasad               13/12/2022          ECM-6558 : QA Defect_Total Investment Amount is not populating in PDF
2.8         Tanishq Banerjee            10/01/2023          ECM-6647 : CLONE - Removing Products/columns with zero Investment from PDF_SFDC_EU 
2.9         Saurav Prasad               10/01/2023          ECM-6597 : Removing Products/columns with zero Investment from PDF_SFDC_EU
3.0         Saurav Prasad               29/09/2023          144628  : DTG Discounts by Products enable in E&S Contracts
3.1         Saurav Prasad               13/10/2023          126383  : [ECM-6905] Product Order on PDF Output
*/ 

public with sharing class ECM_PDF_Generation_Controller {
    
    public String sALESDRIVERITEM = 'ECM_Sales_Driver_Item_Detail__c';
    public String oUTLETCONTRACT = 'Outlet_Contract__c';
    public String cONTRACTITEM = 'ECM_Contract_Item__c';

    //126383
    public String category = System.Label.ECM_Category;
    public String productName = System.Label.ECM_ProductName;
    public String categoryOrder = ' '+System.Label.ECM_SortBy_Category_ProductName; 
    public String productNameOrder = ' '+System.Label.ECM_SortBy_ProductName; 
    
    public Map<String,List<Sobject>> objectRecordsMap;
    public Map<String, Schema.SobjectType> globalDescribe = Schema.getGlobalDescribe();
    public Id recordTypeIdEnS = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId();
    public Boolean isES = false;
    public Boolean dtgCIFilterMetadata = false; //ECM-6647
    public String imageUrl {get; set;}
    public String contractId{get; set;} //This variable should not change
    public String accountId{get;set;} //This variable should not change
    public String agreementTypeID{get;set;} //This variable should not change
    //Changes ECM-6076
    public String addendumId{get;set;} //This variable should not change
    public String templateAgreementType{get;set;}
    //End of ECM-6076
    public list<ECM_Template_Section_Map__c> templateSectionMapList{get; set;}
    public String footer{get; set;}
    public String addendumStatus{get;set;}
    public Map<String, String> conitemsUOMValues{get; set;}
    public List<string> salesFieldsapi { get;set; } 
    public List<string> venuInfoApi { get;set; } 
    public List<templateSectionMapWrapper> tempSectMapWrapper{get; set;}
    public String uOM{get; set;}
    public Contract contractDetails{get; set;}
    public String contractCountry{get;set;}
    public String salesDriverName{get;set;}
    public Integer colnum{get;set;}
    public String countryAssigned{get;set;}   
    public Map<string, Map<ECM_Template_Sub_Section_Map__c,string>> typeOfsubsectionsMap{get;set;}
    public String tncValues{get;set;}
    //comp
    public Id targetObjectId { get; set; }  
    public String textToDisplay { get; set; }  
    public String tempSecString{get;set;}
    
    public Map<Id,ECM_Contract_Item__c> conItemsList {get; set;}
    public List<Outlet_Contract__c> outletContractList{get; set;}
    //EnS starts
    public Map<String,ECM_EandSTableGenerateController.tableWrapper> tableDataMap {get;set;}
    
    
    //Ens ends
    //Start of ECM-6306
    public String languageForGAS { get; set; } 
    public Map<String,ECM_GAS_Market_Translation__mdt> metaDataRecords {get;set;}
    public Map<String,String> objFieldMap {get;set;}
    public String serializedMetaDataRecords { get; set; } 
    public String serializedObjFieldMap { get; set; } 
    //ECM-6718
    public String serializedFieldSetMap { get; set; } 
    Map<String,List<String>> fieldSetMap {get;set;} 
    public Map<String, String> parentLabelToApi{get;set;} 
    public static Map<String, List<Schema.SObjectField>> getGlobalFields{get;set;}
    public string serializedparentLabelToApi{get;set;} 
    
    
    
    
    //End of ECM-6306
    public ECM_PDF_Generation_Controller(ApexPages.StandardController stdController) {
        /*System.debug(LoggingLevel.INFO,'@@@Resource PDF Start: CPU '+Limits.getCpuTime()+'/'+Limits.getLimitCpuTime()+' Heap '+Limits.getHeapSize()+'/'+Limits.getLimitHeapSize()+
' Query '+Limits.getQueries()+'/'+Limits.getLimitQueries());*/
        tncValues = System.currentPageReference().getParameters().get('text');
        String paramId= System.currentPageReference().getParameters().get('Id');
        //ECM-6076
        String addId = System.currentPageReference().getParameters().get('addendumId');
        String isApproval = System.currentPageReference().getParameters().get('isApproval');
        addendumId = addId!=''?addId:'';
        templateAgreementType = addId!=''?'Addendum':'Contract';//replaced getLabel() with getName() for spanish user PDF gen bug fix
        //System.debug(LoggingLevel.INFO,'addId'+addendumId);
        //System.debug(LoggingLevel.INFO,'templateAgreementType '+templateAgreementType);
        //END OF ECM-6076
        footer = '';        
        salesFieldsapi = new List<String>();
        venuInfoApi =new List<String>();
        tempSectMapWrapper = new list<templateSectionMapWrapper>();
        objectRecordsMap= new map<String,List<Sobject>>();        
        contractId = paramid!=Null?paramid:(ID)stdController.getId();
        addendumStatus='';
        Map<Id,ECM_Addendum__c> addendumMap = new Map<Id,ECM_Addendum__c>();
        for(ECM_Addendum__c addendum : [SELECT Id,ECM_Status__c,ECM_Contract__c,ECM_New_T_C__c FROM ECM_Addendum__c WHERE ECM_Contract__c=:contractId WITH SECURITY_ENFORCED]){
            addendumMap.put(addendum.Id,addendum);
        }
        if(addendumId!=''){
            addendumStatus =boolean.valueOf(isApproval)?'Approved' : addendumMap.containsKey(addendumId)?addendumMap.get(addendumId).ECM_Status__c:'' ;
        }
        for(ECM_Addendum__c addendum:addendumMap.values()){
            if((tncValues =='' || tncValues == null) && contractId!=Null && addendum.ECM_Status__c == 'Approved'){   
                //NewTandC = [select id ,ECM_Contract__c, ECM_New_T_C__c from ECM_Addendum__c where ECM_Contract__c =:contractId and ECM_Status__c='Approved' Limit 1];            
                tncValues = addendum.ECM_New_T_C__c;  
                break;
            }
            else if(addendum.Id == tncValues){
                //NewTandC = [select id ,ECM_Contract__c, ECM_New_T_C__c from ECM_Addendum__c where ECM_Contract__c =:contractId and Id=:tncValues Limit 1];  
                tncValues = addendum.ECM_New_T_C__c;   
                break;
            }
        }
        
        contractDetails = [SELECT Id,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Contract_Owner__c,Owner.Email, ECM_Guarantor1_Address__c,ECM_Guarantor1_email__c,ECM_Guarantor1_Name__c,ECM_Guarantor1_Number__c,ECM_Guarantor2_Address__c,ECM_Guarantor2_email__c,ECM_Guarantor2_Name__c,ECM_Guarantor2_Number__c,
                           ECM_Agreement_Type__c,ECM_Select_UoM__c,ECM_Agreement_Type__r.Geography__r.Name,StartDate,Contract_End_Date__c,ECM_Duration__c,Status,ECM_Selected_Payment_Schedule_AU__c,ECM_Upfront_Pre_payment_amount__c,
                           ECM_Hybrid_UOS_PerTerm__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,AccountId,Account.Country__r.Code__c,RecordTypeId,
                           ECM_Size__c,ECM_Brands__c,
                           ECM_Opening_Hours__c,ECM_Activation_Plans_presented_to_Event__c,ECM_Quantity_of_Activation_Spaces__c,
                           ECM_Locations__c,ECM_Site_Maps__c,ECM_Indicative_Total_Funding__c,ECM_Amended__c
                           FROM Contract WHERE Id =: contractId WITH SECURITY_ENFORCED];
        contractCountry = contractDetails.Account?.Country__r.Code__c;
        
         //ECM-6647
        for(ECM_Technical_Market_Setting__mdt conTechMark : ECM_Technical_Market_Setting__mdt.getAll().values()){
            if(contractCountry == conTechMark.ECM_Country__c){
                dtgCIFilterMetadata = conTechMark.PDF_DTG_Remove_Row_Controller__c;
                break;
            }
        }

        templateAgreementType = contractDetails.ECM_Amended__c?'Addendum':templateAgreementType; //ECM-6268
        //EnS start
        List<String> sectionTypeListEnS = Label.ECM_EnS_Table_Type.split(','); /*Holds 'ES Table Type' & 'Amplification Settings' Picklist values from Template Section Object*/
        if(contractDetails.RecordTypeId.equals(recordTypeIdEnS)){
            tableDataMap = ECM_EandSTableGenerateController.prepareTableData(contractDetails, contractCountry);
            isES = true;
        }
        //EnS end       
        string dateFormat = '';
        List<Market_Setting__c> marketSetting = [SELECT Id,ECM_Contract_Creation_Page__c, Geography__c, Geography__r.Code__c,ECM_Date_Format__c FROM Market_Setting__c WHERE Geography__r.Code__c =: contractCountry WITH SECURITY_ENFORCED];
        if(marketSetting.Size()>0){
            dateFormat = marketSetting[0].ECM_Date_Format__c; //ECM-4555
            countryAssigned = marketSetting[0].ECM_Contract_Creation_Page__c;
        }
        else{
            dateFormat = null;
        }
        
        AccountId = contractDetails.AccountId; 
        AgreementTypeID = contractDetails.ECM_Agreement_Type__c;
        //ECM-6306
        languageForGAS = (System.Label.ECM_GAS_Market_CountryCodes).contains(contractCountry)?
            [SELECT Id,ECM_Language_for_Customer_Email__c FROM ECM_Contract_Type__c WHERE Id=:AgreementTypeID].ECM_Language_for_Customer_Email__c:'';
        //System.debug(LoggingLevel.INFO,'language @'+languageForGAS);
        metaDataRecords = new Map<String,ECM_GAS_Market_Translation__mdt>();
        objFieldMap = new Map<String,String>();
        for(ECM_GAS_Market_Translation__mdt metaData : 
            ECM_GAS_Market_Translation__mdt.getAll().values()){
                metaDataRecords.put(metaData.MasterLabel,metaData);
                //System.debug(LoggingLevel.INFO,'Outside loop @ ' + objFieldMap.keySet());
                List<String> tempList = new List<String>();
                tempList.addAll(objFieldMap.keySet());
                //System.debug(LoggingLevel.INFO,'Condition 1 @ '+metaData.ECM_Object_Name__c.split(';').equals(tempList));
                //System.debug(LoggingLevel.INFO,'Condition 2 @ '+metaData.ECM_Field_API_Name__c.split(';').equals(objFieldMap.values()));
                if(!metaData.ECM_Object_Name__c.split(';').equals(tempList) &&
                   !metaData.ECM_Field_API_Name__c.split(';').equals(objFieldMap.values())){
                       //System.debug(LoggingLevel.INFO,'Inside loop @');
                       for(Integer i=0;i<metaData.ECM_Object_Name__c.split(';').size();i++){
                           objFieldMap.put(metaData.ECM_Object_Name__c.split(';')[i],metaData.ECM_Field_API_Name__c.split(';')[i]);
                       }
                   }
            }
        serializedMetaDataRecords = JSON.serialize(metaDataRecords);
        serializedObjFieldMap = JSON.serialize(objFieldMap);
        //End of ECM-6306
        //Start of ECM-6718
        fieldSetMap = new map<String,List<String>>();
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        
        for(ECM_Contract_PDF_Formatting_Setting__mdt mdtRec:
            ECM_Contract_PDF_Formatting_Setting__mdt.getAll().values()){
                if(mdtRec.ECM_IsActive__c){
                    Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(mdtRec.ECM_Object_Api_Name__c);
                    Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
                    for(Schema.FieldSetMember field : 
                        describeSObjectResultObj.FieldSets.getMap().get(mdtRec.Field_Set_Api_Name__c).getFields()){//this loop can't be avoided
                            if(!fieldSetMap.containsKey(mdtRec.ECM_Object_Api_Name__c)){
                                fieldSetMap.put(mdtRec.ECM_Object_Api_Name__c,new List<String>{field.getFieldPath()});
                            }else{
                                fieldSetMap.get(mdtRec.ECM_Object_Api_Name__c).add(field.getFieldPath());
                            }
                        }
                }
            }
        serializedFieldSetMap = JSON.serialize(fieldSetMap);
                
        getGlobalFields = new Map<String, List<Schema.SObjectField>>();
        getGlobalFields= getGlobalFieldMap();
        //serializedgetGlobalFields = JSON.serialize(getGlobalFields);
        
        Schema.SObjectType schemaObjName = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item_Detail__c');
        Map<String, Schema.SObjectField> fieldsMap = schemaObjName.getDescribe().fields.getMap();
        parentLabelToApi = new  Map<String, String>();
        parentLabelToApi = getParentLabels('ECM_Sales_Driver_Item__c',null,fieldsMap);
        serializedparentLabelToApi = JSON.serialize(parentLabelToApi);
        
        // End of ECM-6718
                
        for(ECM_Dynamic_Query__mdt dyQuery: ECM_Dynamic_Query__mdt.getAll().values()){
            if(dyQuery.ECM_Object_API_Name__c != 'ECM_Sales_Driver_Item__c' && dyQuery.ECM_Object_API_Name__c != 'ECM_Payment_Frequency__c' && dyQuery.ECM_Object_API_Name__c != 'ECM_Sales_Driver__c'){
                List<Sobject> recordsList = dynamicQueryMethod(dyQuery);
                /*System.debug(LoggingLevel.INFO,'API Name @ '+dyQuery.ECM_Object_API_Name__c);
System.debug(LoggingLevel.INFO,'recordsList @ '+recordsList);
System.debug(LoggingLevel.INFO,'AccountId @'+AccountId);*/
                objectRecordsMap.put(dyQuery.ECM_Object_API_Name__c, recordsList);
            }
        }  
        
        UOM = contractDetails.ECM_Select_UOM__c;
        //Map of all product Growth Driver Ids and Name in query - ECM-5863
        list<ECM_Template_Section_Map__c> tempSectionMap = [SELECT Id, ECM_Template_Section__r.ECM_Sales_Driver__c, ECM_Template_Section__r.ECM_Text__c, ECM_Template_Section__r.ECM_Section_Type__c,ECM_Template_Section__r.ECM_Product_Growth_Driver__c,ECM_Template_Section__r.ECM_Product_Growth_Driver__r.Name, ECM_Template_Agreement__r.ECM_Type__c
                                                            FROM ECM_Template_Section_Map__c WHERE ECM_Template_Agreement__r.ECM_Agreement_Type__c =: contractDetails.ECM_Agreement_Type__c AND ECM_Template_Section__r.ECM_Active__c = true
                                                            AND (ECM_Template_Section__r.ECM_Section_Type__c = 'Sales-driver' OR ECM_Template_Section__r.ECM_Section_Type__c = 'Product Growth Driver')
                                                            AND ECM_Template_Agreement__r.ECM_Type__c=:templateAgreementType WITH SECURITY_ENFORCED];
        Map<String,String> pgdMap = new Map<String,String>(); //Stores all PGD from Contract Items - ECM-6161
        Set<Id> pgdFiltered = new Set<Id>();//Set with filtered PGD - ECM-6161
        Set<String> pgdNames = new Set<String>(); //Set of all PGD names from Contract Items - ECM-6161
        
        Set<Id> salesDriverIds = new set<Id>();
        Map<Id,List<ECM_Sales_Driver_Item__c>> sdWithSDIListMap = new Map<Id,List<ECM_Sales_Driver_Item__c>>();
        Set<Id> paymentFqIds = new set<Id>();
        Map<Id,ECM_Payment_Frequency__c> paymentFQMap = new Map<Id,ECM_Payment_Frequency__c>();
        Set<Id> finalSalesDriverIDs = new Set<Id>();
        Map<Id,ECM_Sales_Driver__c> salesDriverMap = new Map<Id,ECM_Sales_Driver__c>();
        //Sub Section 
        String sectionType;
        List<String> listOFSECTIONTYPES = new List<string>{'Body','Sales-driver','Annex'};
            typeOfsubsectionsMap = new Map<string, Map<ECM_Template_Sub_Section_Map__c,string>>();
        Set<Id> tempSectIds = new Set<Id>();
        //Added condtion for Product Growth Driver - ECM-5863
        if(tempSectionMap.size()>0){
            for(ECM_Template_Section_Map__c tsm : tempSectionMap){
                if(tsm.ECM_Template_Section__r.ECM_Section_Type__c ==  'Sales-driver'){
                    if(tsm.ECM_Template_Section__r.ECM_Sales_Driver__c != null){
                        salesDriverIds.add(tsm.ECM_Template_Section__r.ECM_Sales_Driver__c);
                    } 
                    tempSectIds.add(tsm.ECM_Template_Section__c);
                } 
                else if(tsm.ECM_Template_Section__r.ECM_Product_Growth_Driver__c != null && tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Product Growth Driver'){
                    pgdMap.put(tsm.ECM_Template_Section__r.ECM_Product_Growth_Driver__c, tsm.ECM_Template_Section__r.ECM_Product_Growth_Driver__r.Name.substringBefore('[').trim());
                } 
            }
            //Added block for Product Growth Driver - ECM-5863
            if(!pgdMap.isEmpty()){
                for(ECM_Contract_Item__c ciRec : [SELECT Id,ECM_Product_growth_driver__c FROM ECM_Contract_Item__c 
                                                  WHERE ECM_Contract__c =:contractId 
                                                  AND ECM_Product_growth_driver__c != null
                                                  AND ECM_Addendum__c=:addendumId WITH SECURITY_ENFORCED])
                {
                    pgdNames.addAll(ciRec.ECM_Product_growth_driver__c.split('/'));
                }
                for(String key : pgdMap.keySet()){
                    String pgdNm = pgdMap.get(key);
                    if(pgdNames.contains(pgdNm)){
                        pgdFiltered.add(key);
                    }
                }
            }
            //
            List<ECM_Template_Sub_Section_Map__c> lstTempSubSect = [SELECT Id, Name, ECM_Template_Section__c,ECM_Template_Section__r.ECM_Section_Type__c, ECM_Template_Sub_Section__c, 
                                                                    Sequence_Number__c,ECM_Template_Sub_Section__r.ECM_Text__c, Required__c,ECM_Template_Sub_Section__r.ECM_Active__c,
                                                                    ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__c,ECM_Template_Sub_Section__r.ECM_Sales_Driver__c,
                                                                    ECM_Template_Sub_Section__r.ECM_Section_Type__c FROM ECM_Template_Sub_Section_Map__c 
                                                                    WHERE ECM_Template_Section__r.ECM_Active__c = true AND Required__c=true AND ECM_Template_Sub_Section__r.ECM_Active__c=true
                                                                    AND ECM_Template_Sub_Section__r.ECM_Section_Type__c = 'Sales-driver' AND ECM_Template_Section__c IN:tempSectIds 
                                                                    AND Sequence_Number__c!=Null WITH SECURITY_ENFORCED ORDER BY Sequence_Number__c];
            if(lstTempSubSect.size()>0){
                for(ECM_Template_Sub_Section_Map__c tssm :lstTempSubSect){
                    if(tssm.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c!=Null){
                        salesDriverIds.add(tssm.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c);
                    }
                }
            }          
            
            if(salesDriverIds.size()>0){
                map<String,Schema.SObjectField> fields = globalDescribe.get('ECM_Sales_Driver_Item__c').getDescribe().fields.getMap();
                List<String> fieldsList = new List<String>(Fields.keyset());
                String salesDriverItemListQuery = ' SELECT ' + String.join( FieldsList, ',' )+' FROM ECM_Sales_Driver_Item__c WHERE Contract__c =: contractId AND ECM_Sales_Driver__c IN: salesDriverIds';
                list<ECM_Sales_Driver_Item__c> salesDriverItemList = database.query(salesDriverItemListQuery);
                if(salesDriverItemList.size()>0){
                    for(ECM_Sales_Driver_Item__c sdi : salesDriverItemList){
                        if(sdi.ECM_Payment_Frequency__c != null){
                            paymentFqIds.add(sdi.ECM_Payment_Frequency__c);
                        }
                        if(sdi.ECM_Sales_Driver__c != null){
                            finalSalesDriverIDs.add(sdi.ECM_Sales_Driver__c);
                        }
                        
                        if(sdWithSDIListMap.containskey(sdi.ECM_Sales_Driver__c)){
                            List<ECM_Sales_Driver_Item__c> sdiList = sdWithSDIListMap.get(sdi.ECM_Sales_Driver__c);
                            sdiList.add(sdi);
                            sdWithSDIListMap.put(sdi.ECM_Sales_Driver__c, sdiList);
                        }
                        else{
                            List<ECM_Sales_Driver_Item__c> sdiList = new list<ECM_Sales_Driver_Item__c>();
                            sdiList.add(sdi);
                            sdWithSDIListMap.put(sdi.ECM_Sales_Driver__c, sdiList);
                        }
                    }
                }
                if(paymentFqIds.size()>0){
                    map<String,Schema.SObjectField> paymentFQFields = globalDescribe.get('ECM_Payment_Frequency__c').getDescribe().fields.getMap();
                    List<String> paymentFQFieldsList = new List<String>(paymentFQFields.keyset());
                    String paymentFQQuery = ' SELECT ' + String.join( paymentFQFieldsList, ',' )+' FROM ECM_Payment_Frequency__c WHERE Id IN: paymentFqIds';
                    paymentFQMap = new Map<Id,ECM_Payment_Frequency__c>((List<ECM_Payment_Frequency__c>)database.query(paymentFQQuery));
                }
                if(finalSalesDriverIDs.size()>0){
                    map<String,Schema.SObjectField> salesDriverFields = globalDescribe.get('ECM_Sales_Driver__c').getDescribe().fields.getMap();
                    List<String> salesDriverFieldsList = new List<String>(salesDriverFields.keyset());
                    String salesDriverQuery = ' SELECT ' + String.join( salesDriverFieldsList, ',' )+' FROM ECM_Sales_Driver__c WHERE Id IN: finalSalesDriverIDs';
                    salesDriverMap = new Map<Id,ECM_Sales_Driver__c>((List<ECM_Sales_Driver__c>)database.query(salesDriverQuery));
                }
            }
        }
        for( ECM_Template_Sub_Section_Map__c tSSM: [SELECT Id, Name, ECM_Template_Section__c,ECM_Template_Section__r.ECM_Section_Type__c, ECM_Template_Sub_Section__c, 
                                                    Sequence_Number__c,ECM_Template_Sub_Section__r.ECM_Text__c, Required__c,ECM_Template_Sub_Section__r.ECM_Active__c,ECM_Template_Sub_Section__r.ECM_Sales_Driver__r.Name,ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Table_Type__c,
                                                    ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__c,ECM_Template_Sub_Section__r.ECM_Sales_Driver__c,ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c,ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Non_leading_Products_Table__c,
                                                    ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c,ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c,ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Sales_Driver_Item_Column__c,
                                                    ECM_Template_Sub_Section__r.ECM_Section_Type__c,ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Field_API_Names__c FROM ECM_Template_Sub_Section_Map__c 
                                                    WHERE ECM_Template_Section__r.ECM_Active__c = true AND Required__c=true AND Sequence_Number__c!=Null AND ECM_Template_Sub_Section__r.ECM_Active__c=true 
                                                    WITH SECURITY_ENFORCED
                                                    ORDER BY Sequence_Number__c]){
                                                        
                                                        if(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c!=Null && (TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.startsWith('<h') || TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.startsWith('<p'))){
                                                            system.debug(LoggingLevel.Info,'=='+TSSM.ECM_Template_Sub_Section__r.ECM_Text__c);
                                                            if(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.substringBetween('<','>')=='p' || TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.substringBetween('<','>')=='h'){
                                                                TSSM.ECM_Template_Sub_Section__r.ECM_Text__c =  TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.remove('<p>').remove('<h>');
                                                                TSSM.ECM_Template_Sub_Section__r.ECM_Text__c =  TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.remove('</p>').remove('</h>');
                                                            }else{
                                                                TSSM.ECM_Template_Sub_Section__r.ECM_Text__c = TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.remove(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.substringBetween('<','>'));
                                                                TSSM.ECM_Template_Sub_Section__r.ECM_Text__c =  TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.remove('<>');
                                                                TSSM.ECM_Template_Sub_Section__r.ECM_Text__c =  TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.remove('</>');
                                                            }
                                                        }
                                                        if(TSSM.ECM_Template_Sub_Section__r.ECM_Section_Type__c=='Sales-driver'){
                                                            if(salesDriverMap.containskey(TSSM.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c)){
                                                                if(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c != null){
                                                                    if(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c.contains('{!')){
                                                                        if(sdWithSDIListMap.containskey(TSSM.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c)){
                                                                            string dynamicText='';
                                                                            for(ECM_Sales_Driver_Item__c sdi : sdWithSDIListMap.get(TSSM.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c)){
                                                                                if(paymentFQMap.containskey(sdi.ECM_Payment_Frequency__c)){
                                                                                    list<Sobject> paymentFQList = new list<Sobject>();
                                                                                    paymentFQList.add(paymentFQMap.get(sdi.ECM_Payment_Frequency__c));
                                                                                    objectRecordsMap.put('ECM_Payment_Frequency__c',paymentFQList);
                                                                                }
                                                                                if(salesDriverMap.containskey(sdi.ECM_Sales_Driver__c)){
                                                                                    list<Sobject> salesDriverList = new list<Sobject>();
                                                                                    salesDriverList.add(salesDriverMap.get(sdi.ECM_Sales_Driver__c));
                                                                                    objectRecordsMap.put('ECM_Sales_Driver__c',salesDriverList);
                                                                                }
                                                                                list<Sobject> recordsList = new list<Sobject>();
                                                                                recordsList.add(sdi);
                                                                                objectRecordsMap.put('ECM_Sales_Driver_Item__c',recordsList);
                                                                                if(TSSM.ECM_Template_Section__r.ECM_Section_Type__c == 'Body'){  
                                                                                    //ECM-6306
                                                                                    dynamicText += ECM_MergeFieldHelper.getMergeText(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap)+'<br/>';
                                                                                }else{
                                                                                    //ECM-6306
                                                                                    TSSM.ECM_Template_Sub_Section__r.ECM_Text__c = ECM_MergeFieldHelper.getMergeText(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap)+'<br/>';
                                                                                }
                                                                                system.debug(LoggingLevel.Info,'TSSM='+TSSM.ECM_Template_Sub_Section__r.ECM_Text__c);
                                                                            }if(dynamicText!=''){
                                                                                TSSM.ECM_Template_Sub_Section__r.ECM_Text__c=dynamicText;
                                                                            }
                                                                        }
                                                                        else{
                                                                            TSSM.ECM_Template_Sub_Section__r.ECM_Text__c = '';//+TSSM.ECM_Template_Sub_Section__r.ECM_Text__c;
                                                                        }
                                                                    }
                                                                    else{
                                                                        TSSM.ECM_Template_Sub_Section__r.ECM_Text__c = TSSM.ECM_Template_Sub_Section__r.ECM_Text__c;
                                                                    }
                                                                }
                                                            }else{
                                                                TSSM.ECM_Template_Sub_Section__r.ECM_Text__c='';
                                                            }
                                                        }
                                                        if(TSSM.ECM_Template_Sub_Section__r.ECM_Text__c!=null && TSSM.ECM_Template_Sub_Section__r.ECM_Text__c!='' ){
                                                            if(typeOfsubsectionsMap.containsKey(TSSM.ECM_Template_Section__c)){
                                                                
                                                                typeOfsubsectionsMap.get(TSSM.ECM_Template_Section__c).put(TSSM,TSSM.ECM_Template_Sub_Section__r.ECM_Text__c);
                                                            }else{
                                                                typeOfsubsectionsMap.put(TSSM.ECM_Template_Section__c, new Map<ECM_Template_Sub_Section_Map__c,string>{TSSM=>TSSM.ECM_Template_Sub_Section__r.ECM_Text__c});
                                                            }
                                                        }
                                                        
                                                    }  
        //Template Section Map with Wrapper 
        //added ECM_ES_Table_Type__c in query as part of ECM-6052
        templateSectionMapList = [SELECT Id, ECM_Template_Section__r.ECM_Product_Growth_Driver__c,ECM_Template_Agreement__c, ECM_Template_Section__c, ECM_Template_Section__r.ECM_Active__c, ECM_Template_Section__r.ECM_Language__c, ECM_Template_Section__r.ECM_Number_of_signatures__c, ECM_Required__c,ECM_Template_Section__r.ECM_Sales_Driver__r.Name,ECM_Template_Section__r.Name,
                                  ECM_Template_Section__r.ECM_Sales_Driver__c,ECM_Template_Section__r.ECM_Deed_Guarantor__c,ECM_Template_Section__r.ECM_Display_Venue_Info__c , ECM_Template_Section__r.ECM_Section_Type__c, ECM_Template_Section__r.ECM_Text__c, ECM_Template_Section__r.ECM_Title__c,ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Non_leading_Products_Table__c,
                                  ECM_Template_Section__r.ECM_Dynamic_Table_Generator__c,ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c,ECM_Template_Section__r.ECM_Legal_T_C_section__c,ECM_Template_Agreement__r.ECM_Apply_Auto_Numbering__c,ECM_Template_Section__r.ECM_Customer_Obligations__c,ECM_Template_Section__r.ECM_Terms_And_Condition__c,ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Table_Type__c,
                                  ECM_Template_Section__r.ECM_Start_on_New_Page__c,ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Field_API_Names__c,ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Sales_Driver_Item_Column__c,ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c, ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c,
                                  ECM_Template_Section__r.ECM_ES_Table_Type__c,ECM_Template_Section__r.Amplification_Setting__c,ECM_Sequence_Number__c,ECM_Template_Agreement__r.ECM_Type__c FROM ECM_Template_Section_Map__c WHERE ECM_Template_Agreement__r.ECM_Agreement_Type__r.Geography__r.Name =:contractDetails.ECM_Agreement_Type__r.Geography__r.Name AND ECM_Template_Agreement__r.ECM_Agreement_Type__c =: contractDetails.ECM_Agreement_Type__c AND ECM_Template_Agreement__r.ECM_Status__c='Active'
                                  AND ECM_Template_Agreement__r.ECM_Type__c=:templateAgreementType AND ECM_Template_Section__r.ECM_Active__c = true AND ECM_Sequence_Number__c!=Null WITH SECURITY_ENFORCED ORDER BY ECM_Sequence_Number__c];
        integer sectionCount = 0;
        integer annexSectionCount = 0;
        Boolean includeTempText;//EnS
        for(ECM_Template_Section_Map__c tsm : templateSectionMapList){
            includeTempText = true;//EnS
            templateSectionMapWrapper tempWrap = new templateSectionMapWrapper();
            List<templateSubSectionMapWrapper> lstsubsectionval = new List<templateSubSectionMapWrapper>();
            if(tsm.ECM_Template_Section__r.ECM_Legal_T_C_section__c){
                tsm.ECM_Template_Section__r.ECM_Text__c=(tncValues!='' && tncValues!=Null)?tncValues:tsm.ECM_Template_Section__r.ECM_Text__c;
            }
            if(tsm.ECM_Template_Section__r.ECM_Section_Type__c != 'Footer'){
                tempWrap.textToDisplay = tsm.ECM_Template_Section__r.ECM_Text__c!=Null?tsm.ECM_Template_Section__r.ECM_Text__c:'';               
            }
            if(tsm.ECM_Template_Agreement__r.ECM_Apply_Auto_Numbering__c){
                //Sub section logic            
                if(listOFSECTIONTYPES.contains(tsm.ECM_Template_Section__r.ECM_Section_Type__c)){
                    system.debug(LoggingLevel.Info,'before replace'+tempWrap.textToDisplay);
                    
                    if(tempWrap.textToDisplay!=Null && (tempWrap.textToDisplay.startsWith('<h') || tempWrap.textToDisplay.startsWith('<p'))){
                        system.debug(LoggingLevel.INFO,'=='+tsm.ECM_Template_Section__r.ECM_Text__c);
                        if(tempWrap.textToDisplay.substringBetween('<','>')=='p' || tempWrap.textToDisplay.substringBetween('<','>')=='h'){
                            tempWrap.textToDisplay =  tempWrap.textToDisplay.remove('<p>').remove('<h>');
                            tempWrap.textToDisplay =  tempWrap.textToDisplay.remove('</p>').remove('</h>');
                        }else{
                            tempWrap.textToDisplay =tempWrap.textToDisplay.remove(tempWrap.textToDisplay.substringBetween('<','>'));
                            tempWrap.textToDisplay =  tempWrap.textToDisplay.remove('<>');
                            tempWrap.textToDisplay =  tempWrap.textToDisplay.remove('</>');
                        }                     
                    }
                    
                    if(tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Annex'){
                        annexSectionCount++;
                        tempWrap.textToDisplay ='<span style="font-size: 12pt;">'+annexSectionCount+'</span>'+'.'+tempWrap.textToDisplay;
                    }else{                        
                        if(tempWrap.textToDisplay !=null){
                            sectionCount++;
                            tempWrap.textToDisplay ='<span style="font-size: 12pt;">'+sectionCount+'</span>'+'.'+tempWrap.textToDisplay;                            
                        }            
                    }
                    
                    if(typeOfsubsectionsMap.containsKey(tsm.ECM_Template_Section__c)){
                        List<ECM_Template_Sub_Section_Map__c> lstTempSubSectn = new List<ECM_Template_Sub_Section_Map__c>(typeOfsubsectionsMap.get(tsm.ECM_Template_Section__c).keyset());
                        Decimal subSectionCount = 0.0+(tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Annex'?annexSectionCount:sectionCount);
                        for(Integer i=0; i<lstTempSubSectn.size();i++){
                            if(i<=8){
                                subSectionCount+=0.1;
                            }else{                             
                                String s = String.valueOf(subSectionCount); // assuming you meant to use d here
                                String afterDecimal = s.substringAfter('.');
                                if(afterDecimal == '9'){
                                    subSectionCount=((subSectionCount-0.9)+0.09)+0.01;
                                }else{
                                    subSectionCount+=0.01;    
                                }
                                
                            }
                            // subSectionCount+=0.1;
                            if(tsm.ECM_Template_Section__r.ECM_Section_Type__c=='Annex'){                            
                                templateSubSectionMapWrapper subsectionval = new templateSubSectionMapWrapper();
                                subsectionval.textToDisplay='';
                                subsectionval.templateSubSectionMap = lstTempSubSectn[i];//typeOfsubsectionsMap.get(tsm.ECM_Template_Section__c)[i]
                                subsectionval.textToDisplay +='<li style="text-indent: -15px; margin-left:25px;">'+subSectionCount+'.'+typeOfsubsectionsMap.get(tsm.ECM_Template_Section__c).get(lstTempSubSectn[i]).removeStart('<p>')+'</li>';
                                lstsubsectionval.add(subsectionval);//subsection
                            }else{
                                tempWrap.textToDisplay+='<li style="text-indent: -15px; margin-left:25px;">'+subSectionCount+'.'+typeOfsubsectionsMap.get(tsm.ECM_Template_Section__c).get(lstTempSubSectn[i]).removeStart('<p>')+'</li>';
                            }
                            
                        }
                    }else{
                        if(tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Sales-driver' && !salesDriverMap.containskey(tsm.ECM_Template_Section__r.ECM_Sales_Driver__c) && tempWrap.textToDisplay !=null){
                            sectionCount=sectionCount-1; 
                        }
                    }
                    
                    if(lstsubsectionval.size()>0){
                        tempWrap.subsection=lstsubsectionval;
                    }
                    sectionType = tsm.ECM_Template_Section__r.ECM_Section_Type__c;
                }
            }
            if(tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Signature'){
                if(tsm.ECM_Template_Section__r.ECM_Number_of_signatures__c != null){
                    tempWrap.templateSectionMap = tsm;
                    tempWrap.textToDisplay = '';
                    if(tempWrap.textToDisplay != null){
                        if(tsm.ECM_Template_Section__r.ECM_Number_of_signatures__c > 0){
                            for(decimal i=1; i<=tsm.ECM_Template_Section__r.ECM_Number_of_signatures__c; i++){
                                if(tsm.ECM_Template_Section__r.ECM_Text__c.contains('{!')){
                                    //ECM-6306
                                    tempWrap.textToDisplay += ECM_MergeFieldHelper.getMergeText(tsm.ECM_Template_Section__r.ECM_Text__c,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap)+'<br/>';
                                }
                                else{
                                    tempWrap.textToDisplay += tsm.ECM_Template_Section__r.ECM_Text__c;
                                }
                            }
                        }
                        else{
                            if(tsm.ECM_Template_Section__r.ECM_Text__c.contains('{!')){
                                //ECM-6306
                                tempWrap.textToDisplay += ECM_MergeFieldHelper.getMergeText(tsm.ECM_Template_Section__r.ECM_Text__c,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap)+'<br/>';
                            }
                            else{
                                tempWrap.textToDisplay += tsm.ECM_Template_Section__r.ECM_Text__c;
                            }
                        }
                    }
                } 
            }
            else if(tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Footer'){
                if(tsm.ECM_Template_Section__r.ECM_Text__c != null){
                    if(tsm.ECM_Template_Section__r.ECM_Text__c.contains('{!')){
                        //ECM-6306
                        footer += ECM_MergeFieldHelper.getMergeText(tsm.ECM_Template_Section__r.ECM_Text__c,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
                    }
                    else{
                        footer += tsm.ECM_Template_Section__r.ECM_Text__c;
                    }
                } 
            }
            //Added condtion for Product Growth Driver - ECM-5863 & ECM-6161
            else if(tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Product Growth Driver'){
                if(pgdFiltered.contains(tsm.ECM_Template_Section__r.ECM_Product_Growth_Driver__c)){
                    tempWrap.templateSectionMap = tsm;
                    tempWrap.textToDisplay = '';
                    if(tsm.ECM_Template_Section__r.ECM_Text__c != null){
                        if(tsm.ECM_Template_Section__r.ECM_Text__c.contains('{!')){
                            //ECM-6306
                            tempWrap.textToDisplay += ECM_MergeFieldHelper.getMergeText(tsm.ECM_Template_Section__r.ECM_Text__c,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
                        }
                        else{
                            tempWrap.textToDisplay += tsm.ECM_Template_Section__r.ECM_Text__c;
                        }
                    }
                }
                else{
                    includeTempText = false;
                }
            }
            else if(tsm.ECM_Template_Section__r.ECM_Section_Type__c == 'Sales-driver'){
                tempWrap.templateSectionMap = tsm;
                
                if(salesDriverMap.containskey(tsm.ECM_Template_Section__r.ECM_Sales_Driver__c)){
                    if(tempWrap.textToDisplay != null){
                        if(tempWrap.textToDisplay.contains('{!')){
                            if(sdWithSDIListMap.containskey(tsm.ECM_Template_Section__r.ECM_Sales_Driver__c)){
                                //ECM-6402
                                //firstFlag -- when auto numbering is on then tempWrap.textToDisplay contains sequence number, to remove sequence number after first line firstFlag is used.
                                Boolean firstFlag = true;
                                string dynamicText='';
                                //seperator -- when auto numberning is on we need lines to be seperated through new lines
                                String seperator = '';
                                if(tsm.ECM_Template_Agreement__r.ECM_Apply_Auto_Numbering__c){
                                    seperator = '<br/>'; 
                                }
                                String sInteger = '<span style="font-size: 12pt;">'+sectionCount+'</span>'+'.';
                                for(ECM_Sales_Driver_Item__c sdi : sdWithSDIListMap.get(tsm.ECM_Template_Section__r.ECM_Sales_Driver__c)){
                                    if(paymentFQMap.containskey(sdi.ECM_Payment_Frequency__c)){
                                        list<Sobject> paymentFQList = new list<Sobject>();
                                        paymentFQList.add(paymentFQMap.get(sdi.ECM_Payment_Frequency__c));
                                        objectRecordsMap.put('ECM_Payment_Frequency__c',paymentFQList);
                                    }
                                    if(salesDriverMap.containskey(sdi.ECM_Sales_Driver__c)){
                                        list<Sobject> salesDriverList = new list<Sobject>();
                                        salesDriverList.add(salesDriverMap.get(sdi.ECM_Sales_Driver__c));
                                        objectRecordsMap.put('ECM_Sales_Driver__c',salesDriverList);
                                    } 
                                    //ECM-6402
                                    list<Sobject> recordsList = new list<Sobject>();                                                                              
                                    recordsList.add(sdi);                                    
                                    objectRecordsMap.put('ECM_Sales_Driver_Item__c',recordsList);
                                    // dynamicText prepration
                                    if (firstFlag){
                                        dynamicText += ECM_MergeFieldHelper.getMergeText(tempWrap.textToDisplay,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap)+seperator;
                                        firstFlag = false;
                                        tempWrap.textToDisplay = tempWrap.textToDisplay.remove(sInteger);
                                    }else{
                                        dynamicText += ECM_MergeFieldHelper.getMergeText(tempWrap.textToDisplay,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap)+seperator;
                                    }
                                }
                                //ECM-6306 
                                //ECM-6402
                                if(dynamicText!=''){
                                    tempWrap.textToDisplay = dynamicText;
                                }
                            }
                            else{
                                if(tempWrap.textToDisplay.contains('<li>')){
                                    tempWrap.textToDisplay = ''+tempWrap.textToDisplay;
                                    
                                }
                            }
                        }
                        else{
                            tempWrap.textToDisplay = tempWrap.textToDisplay;
                        }
                    }
                }
                else{
                    
                    if(tsm.ECM_Template_Section__r.ECM_Text__c != null && tempWrap.textToDisplay.contains('<li>')){
                        tempWrap.textToDisplay = tempWrap.textToDisplay;
                    }else{
                        tempWrap.textToDisplay ='';
                    }
                }
            }
            else{                
                tempWrap.templateSectionMap = tsm;
                //EnS starts - added ECM_ES_Table_Type__c in query as part of ECM-6052
                if(isES && sectionTypeListEnS.contains(tsm.ECM_Template_Section__r.ECM_ES_Table_Type__c)){
                    if(tableDataMap.containsKey(tsm.ECM_Template_Section__r.ECM_ES_Table_Type__c) &&
                       (!tableDataMap.get(tsm.ECM_Template_Section__r.ECM_ES_Table_Type__c).tableContent.isEmpty() || 
                        !tableDataMap.get(tsm.ECM_Template_Section__r.ECM_ES_Table_Type__c).brandingVals.isEmpty())){
                            tempWrap.tableData = JSON.serialize(tableDataMap.get(tsm.ECM_Template_Section__r.ECM_ES_Table_Type__c));
                        }
                    else if(tsm.ECM_Template_Section__r.Amplification_Setting__c != NULL && 
                            tableDataMap.containsKey(tsm.ECM_Template_Section__r.Amplification_Setting__c) &&
                            !tableDataMap.get(tsm.ECM_Template_Section__r.Amplification_Setting__c).tableContent.isEmpty()){
                                tempWrap.tableData = JSON.serialize(tableDataMap.get(tsm.ECM_Template_Section__r.Amplification_Setting__c));
                            }
                    if(tempWrap.tableData == null){
                        includeTempText = false;
                    } 
                }
                //EnS ends
                if(includeTempText && tsm.ECM_Template_Section__r.ECM_Text__c != null){
                    if(tsm.ECM_Template_Section__r.ECM_Text__c.contains('{!')){
                        //ECM-6306
                        tempWrap.textToDisplay = ECM_MergeFieldHelper.getMergeText(tempWrap.textToDisplay,objectRecordsMap,dateFormat,contractCountry,metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
                    }
                    else{
                        tempWrap.textToDisplay = tempWrap.textToDisplay;
                        
                    }
                }
            }
            //system.debug(LoggingLevel.INFO,tempWrap.textToDisplay+'tempWrap size ='+tempWrap.subsection);
            //system.debug(LoggingLevel.INFO,'Section & Text '+tsm.ECM_Template_Section__r.ECM_Section_Type__c+' '+includeTempText);
            if(includeTempText){ //if condition added for EnS
                tempSectMapWrapper.add(tempWrap);
            }
        }
        //144628 - commented isES check to execute annex logic
        //if(!isES){
            processAnnexTable(tempSectMapWrapper);
        //}
        /* System.debug(LoggingLevel.INFO,'tempSecMap12@>'+tempSecString);
System.debug(LoggingLevel.INFO,'@@@Resource PDF End: CPU '+Limits.getCpuTime()+'/'+Limits.getLimitCpuTime()+' Heap '+Limits.getHeapSize()+'/'+Limits.getLimitHeapSize()+
' Query '+Limits.getQueries()+'/'+Limits.getLimitQueries());*/
    }
    public List<lightningTableWrapper> getSalesDriverAU(){return Null;}
    public List<lightningTableWrapper> getOutletContractList(){return Null;}
    public List<List<lightningTableWrapper>> getSalesdrivelist(){return Null;}
    //Removed code to Vf comp controller       
    public List<templateSectionMapWrapper> processAnnexTable(List<templateSectionMapWrapper> tempSectMapWrapper){
        system.debug(LoggingLevel.INFO,'processAnnexTable called');
        Map<String, String> labelToAPINameMap = new Map<String, String>();
        conItemsList = new Map<Id,ECM_Contract_Item__c>();      
        Set<Id> salesDriverIds = new Set<Id>();
        Map<Id,templateSectionMapWrapper> tempSectionMap = new Map<Id,templateSectionMapWrapper>();
        Map<Id,templateSubSectionMapWrapper> tempSubSectionMap = new Map<Id,templateSubSectionMapWrapper>();
        Map <String, String> labelToAPIName = new Map<String, String>();
        Map<Id, Map <String, String>> tempMapLabelToAPIName = new Map<Id, Map <String, String>>();
        //List<String> sALESDRIVERLABEL = system.Label.ECM_Sales_Driver_Table_Sequence.split(',');
        Map<String,String> sobjNameQuery =new Map<String,String>();
        //List<String> oUTLETFIELDLABEL = Label.ECM_Outlet_Column_Sequential.split(',');
        //List<String> cONTRACTITEMLABEL = Label.ECM_Product_Discount_Column_Sequentials.split(',');
        List<String> fieldlistdum = new List<String>();
        Boolean displaySalesdriversCol = false;
        for(templateSectionMapWrapper tempWrap : tempSectMapWrapper){
            //String queryFields;
            String sobjectName;
            //System.debug(LoggingLevel.INFO,'sobjectName='+sobjectName);
            if(tempWrap.templateSectionMap!=Null){
                tempSectionMap.put(tempWrap.templateSectionMap.Id,tempWrap);
                if(tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Section_Type__c == 'Annex' && 
                   tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__c!=Null
                  ){
                      sobjectName= tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;   
                      if(sobjectName!=Null){
                          //system.debug(LoggingLevel.INFO,'@>'+sobjectName);
                          labelToAPIName = getFieldApiNames(sobjectName, tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';'), tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c);
                          //System.debug(LoggingLevel.INFO,'labelToAPIName@>'+labelToAPIName);
                          tempMapLabelToAPIName.put(tempWrap.templateSectionMap.ECM_Template_Section__c,labelToAPIName);
                          //System.debug(LoggingLevel.INFO,'tempMapLabelToAPIName@>'+tempMapLabelToAPIName);
                          if(sobjectName.equalsIgnoreCase(SALESDRIVERITEM))
                          {                    
                              if(tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Sales_Driver__c!=null){
                                  salesDriverIds.add(tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Sales_Driver__c); 
                              }
                          }
                          else if(sobjectName.equalsIgnoreCase(CONTRACTITEM)){
                              if( countryAssigned != 'Australia'){
                                  displaySalesdriversCol = tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Sales_Driver_Item_Column__c;
                              }
                          }
                      }
                      
                      getQuery(labelToAPIName.Values(),sobjectName,sobjNameQuery);                       
                      if(tempWrap.subsection!=null){
                          string sobjectNameSubSection;
                          for(templateSubSectionMapWrapper tempSubWrap : tempWrap.subsection){
                              tempSubSectionMap.put(tempSubWrap.templateSubSectionMap.Id,tempSubWrap);
                              sobjectNameSubSection = tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;
                              if(tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Section_Type__c == 'Annex' && 
                                 tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__c!=Null){                   
                                     labelToAPIName = getFieldApiNames(sobjectNameSubSection, tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';'), tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c);
                                     system.debug(LoggingLevel.INFO,'labelToAPI'+labelToAPIName);
                                     tempMapLabelToAPIName.put(tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__c,labelToAPIName);                                   
                                     if(sobjectNameSubSection.equalsIgnoreCase(SALESDRIVERITEM)){                    
                                         if(tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c!=null)  {
                                             salesDriverIds.add(tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c);   
                                         }
                                         
                                     }else if(sobjectNameSubSection.equalsIgnoreCase(CONTRACTITEM)){
                                         if(countryAssigned != 'Australia'){
                                             
                                             displaySalesdriversCol = tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Sales_Driver_Item_Column__c;
                                             // fieldlistdum =new List<String>(labelToAPIName.keyset());
                                         }
                                     }
                                 }
                          }
                          getQuery(labelToAPIName.Values(),sobjectNameSubSection,sobjNameQuery);
                          
                      }
                  }
            }
        }
        Map<String, List<String>> salesdriveConcatinate = new Map<String,List<String>>(); 
        
        Map<string,List<Sobject>> getQueryDatabaseList  = getQueryDatabase(sobjNameQuery,salesDriverIds);
        //126383
        Map<string,List<SObject>> orderByProductName =new  Map<string,List<SObject>>();
        Boolean isSortedByProduct = false;
        if(getQueryDatabaseList.containsKey(CONTRACTITEM) && contractCountry==System.Label.ECM_CountryCodeAU 
           && (sobjNameQuery.get(CONTRACTITEM).split(',')).contains(category)){
               isSortedByProduct = true;
               List<SObject> records = new List<SObject>();
               records.addAll(getQueryDatabaseList.get(CONTRACTITEM));

               ECM_SortUtil.SortOrderWrap wrapper = new ECM_SortUtil.SortOrderWrap();
               wrapper.records = records;
               wrapper.fieldName = productName;
               ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.ASCENDING, ECM_SortUtil.Type.TYPE_STRING);
               records.clear();
               records.addAll(wrapper.records);
               orderByProductName.put(CONTRACTITEM,records);
               
           }
        
        labelToAPINameMap.PutAll(labelToAPIName);
        
        if(getQueryDatabaseList != Null && getQueryDatabaseList.containsKey(CONTRACTITEM)){
            
            conItemsList = new map<Id,ECM_Contract_Item__c>((List<ECM_Contract_Item__c>)getQueryDatabaseList.get(CONTRACTITEM));
            if(conItemsList.size()>0){
                conitemsUOMValues = ECM_PDF_GenerationComponentCtrl.getTieringValues(conItemsList.keyset());
            }    
            
        }
        If(displaySalesdriversCol){         
            for(ECM_Sales_Driver_Item_Detail__c saledrivitem : [Select Id,ECM_Sales_Driver_Item__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name,
                                                                ECM_Product__r.ECM_Product_Name__c,ECM_Product__c 
                                                                from ECM_Sales_Driver_Item_Detail__c where ECM_Product__c IN:conItemsList.keyset() AND ECM_Addendum__c=:addendumId WITH SECURITY_ENFORCED]){
                                                                    if(!fieldlistdum.contains(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name)){
                                                                        fieldlistdum.add(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name);}
                                                                    labelToAPINameMap.put(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name ,saledrivitem.ECM_Product__r.ECM_Product_Name__c+' '+saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name );      
                                                                    if(SalesdriveConcatinate.containskey(saledrivitem.ECM_Product__c)){
                                                                        SalesdriveConcatinate.get(saledrivitem.ECM_Product__c).add(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name);
                                                                    }else{
                                                                        SalesdriveConcatinate.put(saledrivitem.ECM_Product__c,new List<String>{saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name});
                                                                    }
                                                                }
        }
        //system.debug(LoggingLevel.INFO,'temp@>'+tempSectMapWrapper);
        
        for(templateSectionMapWrapper tempWrap : tempSectMapWrapper){
            if(tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Section_Type__c=='Annex'){
                //system.debug(LoggingLevel.INFO,'Query map'+getQueryDatabaseList);
                templateSectionWrap tempSecWrap = new templateSectionWrap();
                tempSecWrap.sobjectName = tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;
                //126383
                tempSecWrap.templateSectionMap = (contractCountry==System.Label.ECM_CountryCodeAU && tempSecWrap.sobjectName == CONTRACTITEM &&
                                                  !tempWrap.templateSectionMap.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Field_API_Names__c.split(',').contains(category)
                                                  && isSortedByProduct)? orderByProductName.get(tempSecWrap.sobjectName) : getQueryDatabaseList.get(tempSecWrap.sobjectName);  
                
                tempSecWrap.templateSection = tempWrap.templateSectionMap;
                tempSecWrap.uomValues = conitemsUOMValues;
                tempSecWrap.mapFields = tempMapLabelToAPIName.get(tempWrap.templateSectionMap.ECM_Template_Section__c);
                tempWrap.tableData = JSON.serialize(tempSecWrap);
                if(tempWrap.subsection!=null){
                    for(templateSubSectionMapWrapper tempSubWrap : tempWrap.subsection){
                        if(tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Section_Type__c=='Annex'){
                            templateSectionWrap tempsubSecWrap = new templateSectionWrap();
                            tempsubSecWrap.sobjectName = tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;
                            //126383
                            tempsubSecWrap.templateSectionMap = (contractCountry==System.Label.ECM_CountryCodeAU && tempsubSecWrap.sobjectName == CONTRACTITEM &&
                                                                 !tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Field_API_Names__c.split(',').contains(category) 
                                                                 && isSortedByProduct)? orderByProductName.get(tempsubSecWrap.sobjectName):getQueryDatabaseList.get(tempsubSecWrap.sobjectName);
                            
                            tempsubSecWrap.templateSubSection = tempSubWrap.templateSubSectionMap;
                            tempsubSecWrap.uomValues = conitemsUOMValues;
                            tempsubSecWrap.mapFields = tempMapLabelToAPIName.get(tempSubWrap.templateSubSectionMap.ECM_Template_Sub_Section__c);
                            tempSubWrap.subTableData = JSON.serialize(tempsubSecWrap);
                        }
                    }
                }
            }
        }
        //system.debug(LoggingLevel.INFO,'temp after@>'+tempSectMapWrapper);
        
        return tempSectMapWrapper;
    }
    public Map<string,List<Sobject>> getQueryDatabase(Map<String,String> objNameQuery,Set<Id> salesDriver){
        Map<string,List<Sobject>> sobjectData = new Map<string,List<Sobject>>();
        if(objNameQuery.containsKey(SALESDRIVERITEM)){
            string queryStr;
            //system.debug(LoggingLevel.INFO,'salesDriversscheck'+salesDriver);
            if(salesDriver!=null){
                queryStr = 'SELECT '+(objNameQuery.get(SALESDRIVERITEM).contains('ECM_Sales_Driver_Item__r.ECM_Payment_Frequency_Type__c')?'':'ECM_Sales_Driver_Item__r.ECM_Payment_Frequency_Type__c,')+objNameQuery.get(SALESDRIVERITEM)+(objNameQuery.get(SALESDRIVERITEM).contains('ECM_Sales_Driver_Item__r.ECM_Total_Investment_Amount__c')?'':',ECM_Sales_Driver_Item__r.ECM_Total_Investment_Amount__c')+',ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c FROM '+SALESDRIVERITEM+' WHERE ECM_Product__r.ECM_Contract__c=:contractId AND ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c IN:salesDriver AND ECM_Addendum__c=:addendumId order by ECM_Sales_Driver_Item__c';
            }            
            //system.debug(LoggingLevel.INFO,'queryStr='+queryStr);
            Map<id,Sobject> objData =new Map<id,Sobject>(database.query(string.escapeSingleQuotes(queryStr)));
            sobjectData.put(SALESDRIVERITEM,objData.values());
        }
        if(objNameQuery.containsKey(OUTLETCONTRACT)){
            string queryStr = 'SELECT '+objNameQuery.get(OUTLETCONTRACT)+' FROM '+OUTLETCONTRACT+' WHERE Contract__c =:contractId';
            Map<id,Sobject> objData =new Map<id,Sobject>(database.query(string.escapeSingleQuotes(queryStr)));
            sobjectData.put(OUTLETCONTRACT,objData.values());
        }
        if(objNameQuery.containsKey(CONTRACTITEM)){        
            string queryStr = 'SELECT '+objNameQuery.get(CONTRACTITEM)+',ECM_Lead_Brand__c,ECM_MAT_Final__c,ECM_MAT_original__c,ECM_Mandatory_Back_Bar__c,ECM_First_Pour__c  FROM '+CONTRACTITEM+' WHERE ECM_Contract__c =:contractId AND ECM_Addendum__c=:addendumId ';
            //126383 
            queryStr = contractCountry==System.Label.ECM_CountryCodeAU ? (objNameQuery.get(CONTRACTITEM).split(',')).contains(category) ?
                queryStr+' '+categoryOrder : queryStr+' '+productNameOrder : queryStr;
            
            //ECM-6647
            String zeroStr = '0';
            //List<String> zeroStrWithDec = new List<String>{'0','0.0','0.00'};
            if(dtgCIFilterMetadata && objNameQuery.get(CONTRACTITEM).contains('ECM_Trade_investments__c') 
            && objNameQuery.get(CONTRACTITEM).contains('ECM_UoM__c') 
            && !objNameQuery.get(CONTRACTITEM).contains('ECM_TotalAnP_incl_Indirect__c')){
                queryStr += ' AND ((ECM_Trade_investments__c!= null AND ECM_Trade_investments__c != 0) OR (ECM_UoM__c != null AND ECM_UoM__c !=:zeroStr))';
            }else if(dtgCIFilterMetadata && objNameQuery.get(CONTRACTITEM).contains('ECM_TotalAnP_incl_Indirect__c')
            && !objNameQuery.get(CONTRACTITEM).contains('ECM_UoM__c') 
            && !objNameQuery.get(CONTRACTITEM).contains('ECM_Trade_investments__c')){
                queryStr += ' AND ECM_TotalAnP_incl_Indirect__c != 0 AND ECM_TotalAnP_incl_Indirect__c!=null';
            }//ECM-6597
            else if(dtgCIFilterMetadata && objNameQuery.get(CONTRACTITEM).contains('ECM_TotalAnP_incl_Indirect__c')
            && objNameQuery.get(CONTRACTITEM).contains('ECM_UoM__c') 
            && objNameQuery.get(CONTRACTITEM).contains('ECM_Trade_investments__c')){
                queryStr += ' AND ((ECM_TotalAnP_incl_Indirect__c != 0 AND ECM_TotalAnP_incl_Indirect__c!=null) OR (ECM_Trade_investments__c!=null AND ECM_Trade_investments__c != 0) OR (ECM_UoM__c != null AND ECM_UoM__c !=:zeroStr))';
            }
            Map<id,Sobject> objData =new Map<id,Sobject>(database.query(string.escapeSingleQuotes(queryStr)));
            
            sobjectData.put(CONTRACTITEM,objData.values()); 
        }
        
        return sobjectData;
    }
    public Map<String,String> getQuery(List<string> dynamicFields,String sobjectName,Map<String,String> objNameQuery){
        String queryFields;
        //List<string> queryFieldList = new List<string>();
        if(!objNameQuery.isEmpty()){
            queryFields = objNameQuery.get(sobjectName);
        }
        for(string queryStr : dynamicFields){
            if(queryFields!=Null && !queryFields.contains(queryStr)){
                queryFields+=','+queryStr;
            }else if(queryFields==Null){
                queryFields=queryStr; 
            }
        }
        //system.debug(LoggingLevel.INFO,sobjectName+'queryField='+queryFields);
        objNameQuery.put(sobjectName,queryFields);
        return objNameQuery;
    }
    
    public Map <String, String> getFieldApiNames(String sobjectName,List<String> selectfields, String translationFields) {
        selectfields = ECM_DynamicTableGeneratorController.getPickListValuesIntoList(selectfields);
        //System.debug(LoggingLevel.INFO,'selectfields @'+selectfields);
        //Schema.SObjectType schemaObjName = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, String> fieldConversion = new Map<String, String>{
            'UOS' => 'UoS Conversion Rate',
                'MAT Override' => 'Annual Volume',
                'MAT UOS'=>'Total UOS',
                'Total Sales Driver Discount'=>'Discount per case off invoice',
                'Current LUC'=>'LUC'
                }; 
                    //ECM-6556
                    //ECM-6558 - removed static references
                    Map<String, String> labelToAPIName = new Map<String, String> ();
        Map<String, String> parentAPINames = new Map<String, String> ();
        try{   
            Map<String,String> labelsApiMap = new Map<String,String>();                    
            //Map<String, Schema.SObjectField> fieldsMap = schemaObjName.getDescribe().fields.getMap();
            if(sobjectName=='ECM_Sales_Driver_Item_Detail__c'){
                parentAPINames = parentLabelToApi;                
                //System.debug(LoggingLevel.INFO,'parentAPINames @'+parentAPINames);
            }
            for (Schema.SObjectField field : getGlobalFields.get(sobjectName)){                 
                if(selectfields.contains(field.getDescribe().getLabel())){ 
                    labelsApiMap.put(field.getDescribe().getLabel(), field.getDescribe().getName());
                }
                else if(selectfields.contains(fieldConversion.get(field.getDescribe().getLabel()))){
                    labelsApiMap.put(fieldConversion.get(field.getDescribe().getLabel()), field.getDescribe().getName());
                }              
            }    
            if(!parentAPINames.isEmpty()){
                for(string parentName : selectfields){
                    if(parentAPINames.containskey(parentName)){
                        labelsApiMap.put(parentName,parentAPINames.get(parentName));
                    }
                }
            }
            
            if(translationFields != null){
                List<String> translationFieldList = translationFields.split(',');
                if(translationFieldList.size() == selectfields.size()){
                    for(Integer i=0; i < translationFieldList.size(); i++){
                        if(labelsApiMap.containsKey(selectfields[i])){
                            labelToAPIName.put(translationFieldList[i],labelsApiMap.get(selectfields[i]));  
                        }                                             
                    }
                }
                else{
                    labelToAPIName = labelsApiMap;
                }               
            } 
            else{
                labelToAPIName = labelsApiMap;
            }
            
        }catch(Exception ex){
            system.debug(LoggingLevel.INFO,'==exception '+ex);
        }
        System.debug(LoggingLevel.INFO,'check @'+sobjectName);
        System.debug(LoggingLevel.INFO,'check1 @'+labelToAPIName);
        return labelToAPIName;
    }
    //Start of ECM-6718
    public static Map<String, List<Schema.SObjectField>> getGlobalFieldMap(){ 
        Map<String, String> fieldConversion = new Map<String, String>{
            'UOS' => 'UoS Conversion Rate',
                'MAT Override' => 'Annual Volume',
                'MAT UOS'=>'Total UOS',
                'Total Sales Driver Discount'=>'Discount per case off invoice',
                'Current LUC'=>'LUC'
                };
        Map<String, List<Schema.SObjectField>> globalFieldMap = new  Map<String, List<Schema.SObjectField>>();
        String objectName = 'ECM_Dynamic_Table_Generator__c';
        String controllingField = 'ECM_Object__c';
        String dependentField = 'ECM_Dynamic_Fields__c';  
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>() ;  
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName) ;   
        Schema.DescribeSObjectResult describeResult = objType.getDescribe() ;      
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();    
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();    
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues() ;    
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues() ;
        
        for(Schema.PicklistEntry currControllingValue : controllingValues){   
            controllingInfo.put(currControllingValue.getValue(),new List<String>());
        }
        for(Schema.PicklistEntry  currDependentValue : dependentValues){
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString,MyPickListInfo.class) ;
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer  baseCount = 0;
            for (Integer curr : hexString.getChars()){
                Integer val = 0;
                if(curr >= 65){
                    val = curr - 65 + 10;
                }else{
                    val = curr - 48;
                }
                if((val & 8) == 8){
                    controllingInfo.get (controllingValues[baseCount + 0].getValue()).add(currDependentValue.getLabel());
                }        
                if((val & 4)  ==  4){
                    controllingInfo.get (controllingValues[baseCount + 1].getValue()).add(currDependentValue.getLabel());
                }
                if((val & 2)  ==  2){
                    controllingInfo.get (controllingValues[baseCount + 2].getValue()).add(currDependentValue.getLabel());
                }        
                if((val & 1)  ==  1){
                    controllingInfo.get (controllingValues[baseCount + 3].getValue()).add(currDependentValue.getLabel());
                }
                baseCount += 4;
            }   
        }

        Map<String,list<String>> temp = new Map<String,list<String>>();
        System.debug(LoggingLevel.INFO,'###'+controllingInfo);
        System.debug(LoggingLevel.INFO,'controllingInfo @'+controllingInfo.get('Outlet_Contract__c').size());
        System.debug(LoggingLevel.INFO,'controllingInfo @'+controllingInfo.get('ECM_Contract_Item__c').size());
        System.debug(LoggingLevel.INFO,'controllingInfo @'+controllingInfo.get('ECM_Sales_Driver_Item_Detail__c').size());
        for(String sobjectName: controllingInfo.keySet()){
            globalFieldMap.put(sobjectName,new List<Schema.SObjectField>());
            temp.put(sobjectName, new List<String>());
            List<String> selectfields = controllingInfo.get(sobjectName);
            Schema.SObjectType schemaObjName = Schema.getGlobalDescribe().get(sobjectName);
            Map<String, Schema.SObjectField> fieldsMap = schemaObjName.getDescribe().fields.getMap();
            for(Schema.SObjectField field:fieldsMap.values()){
                if(selectfields.contains(field.getDescribe().getLabel())){ 
                    globalFieldMap.get(sobjectName).add(field);
                    temp.get(sobjectName).add(field.getDescribe().getLabel());
                }else if(selectfields.contains(fieldConversion.get(field.getDescribe().getLabel()))){
                    globalFieldMap.get(sobjectName).add(field);
                    temp.get(sobjectName).add(field.getDescribe().getLabel());
                }
            }
            System.debug(LoggingLevel.INFO,'global @'+globalFieldMap.get(sobjectName).size());
            
        }
        /*for(Integer i=0;i<temp.get('ECM_Contract_Item__c').size();i++){
            System.debug('Outer @'+temp.get('ECM_Contract_Item__c')[i]);
            for(Integer j=0;j<controllingInfo.get('ECM_Contract_Item__c').size();j++){
                if(temp.get('ECM_Contract_Item__c')[i]==controllingInfo.get('ECM_Contract_Item__c')[j]){
                    System.debug('Inner @'+controllingInfo.get('ECM_Contract_Item__c')[j]);
                    break;
                }
            }
        }
        System.debug('###'+globalFieldMap);*/
        return globalFieldMap;
    }
        
    public class MyPickListInfo {        
        public String validFor;        
    }
    //End of ECM-6718
    
    public static  Map<String,String> getParentLabels(string childName,List<String> labelNames,Map<String, Schema.SObjectField> schemafieldMap){
        //List<String> parentFieldLabels = new List<String>();
        Map<String,String> fieldNames = new Map<String,String>();
        for (String fieldName : schemafieldMap.keySet()){
            if(schemafieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.REFERENCE){
                Schema.SObjectType parentSchema = schemafieldMap.get(fieldName).getDescribe().getReferenceTo().get(0);
                string parentName=string.valueof(parentSchema);
                Map<String, Schema.SObjectField> parentFieldMap = parentSchema.getDescribe().fields.getMap();
                for(Schema.SObjectField parentField : parentFieldMap.values()){
                    if(parentName=='ECM_Sales_Driver_Item__c'){
                        fieldNames.put(parentField.getDescribe().getLabel(),parentName.replace('__c', '__r')+'.'+parentField.getDescribe().getName());
                    }
                    
                }
            }
        }                                                                                                                                                                       
        return fieldNames;
    }
    public List<obligationswrapper> getObligations(){
        List<obligationswrapper> obligationsList=New List<obligationswrapper>();      
        Integer noOfrepayments=Integer.valueOf(contractDetails.ECM_Duration__c/3);
        if(contractDetails.ECM_Hybrid_UOS_PerTerm__c !=null && contractDetails.ECM_Duration__c!=null && contractDetails.ECM_Total_Upfront_Payment_Loan_Over_Term__c!=null){
            for(Integer i=0;i<noOfrepayments;i++){
                obligationswrapper obligationwrap=New obligationswrapper();
                if(obligationsList.size()>0){
                    if(obligationsList[i-1].obligationcalcdate !=null){
                        date dt=obligationsList[i-1].obligationcalcdate.addMonths(3);                    
                        obligationwrap.obligationcalcdate = dt.addMonths(1).toStartofMonth().addDays(-1);
                        Datetime dttime = datetime.newInstance(obligationwrap.obligationcalcdate.year(), obligationwrap.obligationcalcdate.month(),obligationwrap.obligationcalcdate.day());
                        obligationwrap.obligationcalcdatestr=dttime.day()+'-'+dttime.format('MMM').toUppercase()+'-'+dttime.Year();
                    }
                }
                else{
                    date dt =contractDetails.StartDate.addMonths(3);
                    obligationwrap.obligationcalcdate = dt.toStartofMonth().addDays(-1);
                    Datetime dttime = datetime.newInstance(obligationwrap.obligationcalcdate.year(), obligationwrap.obligationcalcdate.month(),obligationwrap.obligationcalcdate.day());
                    obligationwrap.obligationcalcdatestr=dttime.day()+'-'+dttime.format('MMM').toUppercase()+'-'+dttime.Year();
                }
                
                obligationwrap.estimatedUOS=((contractDetails.ECM_Hybrid_UOS_PerTerm__c/(contractDetails.ECM_Duration__c/12))/4).setScale(2);
                
                if(i==noOfrepayments-1){
                    obligationwrap.repaymentdate = obligationwrap.obligationcalcdate;
                    Datetime dattime = datetime.newInstance(obligationwrap.repaymentdate.year(), obligationwrap.repaymentdate.month(),obligationwrap.repaymentdate.day());
                    obligationwrap.repaymentdatestr=dattime.day()+'-'+dattime.format('MMM').toUppercase()+'-'+dattime.Year();
                }else{
                    obligationwrap.repaymentdate = obligationwrap.obligationcalcdate.addMonths(3).toStartofMonth();
                    Datetime dattime = datetime.newInstance(obligationwrap.repaymentdate.year(), obligationwrap.repaymentdate.month(),obligationwrap.repaymentdate.day());
                    obligationwrap.repaymentdatestr=dattime.day()+'-'+dattime.format('MMM').toUppercase()+'-'+dattime.Year();
                }
                obligationwrap.repaymentInstallment ='$'+String.valueOf(((contractDetails.ECM_Total_Upfront_Payment_Loan_Over_Term__c/(contractDetails.ECM_Duration__c/12))/4).setScale(2));
                obligationsList.add(obligationwrap);
            }
        }       
        return obligationsList;
    }
    
    public class LightningTableWrapper {  
        public List<ObjValues> tablerows {get; set;}
        public Integer index{get; set;}  
        public boolean mergewrap{get; set;} 
        public boolean mergeCell{get; set;}  
        public lightningTableWrapper(){           
            tablerows = new List<ObjValues>();
            index=0;
            mergeCell=false;
            mergewrap=false;
            // size=0;
        }
    }
    
    // Method Name : dynamicQueryMethod
    // Description : This method is used to query records Dynamically
    public list<Sobject> dynamicQueryMethod(ECM_Dynamic_Query__mdt dynamicQueryData){
        try{
            map<String,Schema.SObjectField> fields = globalDescribe.get(dynamicQueryData.ECM_Object_API_Name__c).getDescribe().fields.getMap();
            List<String> fieldsList = new List<String>(Fields.keyset());
            String query = ' SELECT ' + String.join( FieldsList, ',' )+' FROM '+dynamicQueryData.ECM_Object_API_Name__c+' WHERE '+dynamicQueryData.ECM_Where_Condition__c;
            List<Sobject> recordsList = database.query(string.escapeSingleQuotes(query));
            return recordsList;
        }
        catch(exception e){
            system.debug(LoggingLevel.DEBUG,e);
            return null;
        }
    }
    
    public class ObjValues{
        public string header{get; set;}
        public string values{get; set;}
    }
    // Wrapper Class : templateSectionMapWrapper
    // Description   : This wrapper will hold Template Section Map and text to display in PDF 
    public class TemplateSectionMapWrapper{
        public ECM_Template_Section_Map__c templateSectionMap{get; set;}
        public string textToDisplay{get; set;}
        public String tableData{get;set;}
        public List<templateSubSectionMapWrapper> subsection{get;set;}
    }
    
    public class TemplateSubSectionMapWrapper{
        public ECM_Template_Sub_Section_Map__c templateSubSectionMap{get; set;}
        public string textToDisplay{get; set;}
        public string subTableData{get;set;}
    }
    public class LightningTableWrapperNumber {  
        public List<lightningTableWrapper> tableName {get; set;}
        public List<string> tableheader {get;set;}
        public string tableTitle {get;set;}
        public lightningTableWrapperNumber(List<lightningTableWrapper> tablesValues,List<string> headervals, string titleval){           
            tableName = tablesValues;
            tableheader = headervals;
            tableTitle = titleval;
        }
    }
    
    public class Obligationswrapper{
        public date obligationcalcdate{get;set;}
        public string obligationcalcdatestr{get;set;}
        public decimal estimatedUOS{get;set;}
        public date repaymentdate{get;set;}
        public string repaymentdatestr{get;set;}
        public string repaymentInstallment{get;set;}
    }
    public class TemplateSectionWrap{
        public List<Sobject> templateSectionMap{get; set;}
        public ECM_Template_Section_Map__c templateSection{get; set;}
        public ECM_Template_Sub_Section_Map__c templateSubSection{get; set;}
        public string sobjectName{get; set;}
        public Map<String, String> mapFields{get;set;}
        public Map<String, String> uomValues{get;set;}
    }
    
}