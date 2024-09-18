/*
Name: ECM_PDF_GenerationComponentCtrl
Purpose: This Class is used for ECM_PDF_Generation_comp

History                                                            
*                                                            
VERSION    AUTHOR               DATE              DETAIL
1.0      Anivesh Muppa      10/01/2022        Initial Development
2.0      Anivesh Muppa		24/01/2022        PDF rendering Bug fix
3.0      Anivesh Muppa		6/02/2022         ECM-5135 - Implement Non Lead Product Functionality
4.0		 Subhrojit Majumdar 6/04/2022		  ECM-5417 : Added logic for ECM_MAT_Final__c field.
5.0      Vinay Tummala      13/05/2022        ECM-5603 : Combining the Information And Payment Frequency fields for the SD in the PDF &Dynamic field Translation
6.0      Pratap Sen         07/10/2022        ECM-6235 : Added Logic to display lead brand volume in product table depending upon ECM_Technical_Market_Setting__mdt     
7.0		 Saurav Prasad		10/11/2022		  ECM-6306 :  PF translation in Contract PDF
7.1		 Saurav Prasad		05/12/2022		  ECM-6339 : Amounts in PDF to be in currency standard
*/
public class ECM_PDF_GenerationComponentCtrl {
    public String contractId{get; set;} //This variable should not change
    public String AccountId{get;set;} //This variable should not change
    public String AgreementTypeID{get;set;} //This variable should not change   
    //ECM-6076
    public String addendumId{get;set;} //This variable should not change
    public Map<String, String> conitemsUOMValues{get; set;}
    public list<String> salesFieldsapi { get;set; } 
    public list<String> venuInfoApi { get;set; } 
    public List<ECM_PDF_Generation_Controller.lightningTableWrapper> listLgtnTableWraps {get; set;}
    public String UOM{get; set;}
    public String objectRecordsMap{get; set;}  
    public String salesDriverName{get;set;} 
    public Integer colnum{get;set;}
    public String countryAssigned{get;set;}
    public String conCntry{get;set;} //ECM-6235 - holds country code of the contract geography fetched from Vfp
    public Map<String,String> translations{get;set;} //ECM-5603
    public String translationsKey{get;set;}
    public ECM_PDF_Generation_Controller.templateSectionWrap mapObjTable {get;set;}
    
    //ECM-6306
    public String serializeMetaDataRecords {get;set;}
    public String serializeObjFieldMap {get;set;}
    public String languageForGAS {get;set;}
    Map<String,ECM_GAS_Market_Translation__mdt> metaDataRecords {get;set;}
    Map<String,String> objFieldMap {get;set;}
    
    //ECM-6718
    public String serializeFieldSetMap {get;set;}
    Map<String,List<String>> fieldSetMap {get;set;}
    public String serializedparentLabelToApi {get;set;}
    public Map<String, String> parentLabelToApi{get;set;} 
    public Map<String, List<Schema.SObjectField>> getGlobalFields{get;set;}
    
    //comp
    public ID targetObjectId { get; set; }  
    public string textToDisplay { get; set; }  
    public String tempSecString{get;set;}
    public ECM_PDF_GenerationComponentCtrl(){  
        ECM_PDF_Generation_Controller.templateSectionWrap mapObjTable = new ECM_PDF_Generation_Controller.templateSectionWrap();
        string paramid= System.currentPageReference().getParameters().get('Id');
        //ECM-6076
        String addId = System.currentPageReference().getParameters().get('addendumId');
        addendumId = addId!=''?addId:'';
        contractId = paramid;
        salesDriverName =Null;
        listLgtnTableWraps = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>(); 
        // conitemsUOMValues = new Map<String, String>();
        // ECM-6306
        metaDataRecords = new Map<String,ECM_GAS_Market_Translation__mdt>();
        objFieldMap = new Map<String,String>();
        
        //ECM-6718
        fieldSetMap = new Map<String,List<String>>();
        parentLabelToApi = new Map<String, String> (); 
        getGlobalFields = new Map<String, List<Schema.SObjectField>>();
    }
    public List<List<ECM_PDF_Generation_Controller.lightningTableWrapper>> getSalesdrivelist(){  
        //Decimal allowed = System.Limits.getLimitCpuTime();
        //Decimal current = System.Limits.getCpuTime();
        
        mapObjTable=(ECM_PDF_Generation_Controller.templateSectionWrap)JSON.deserialize(objectRecordsMap,ECM_PDF_Generation_Controller.templateSectionWrap.class);
        List<ECM_Contract_Item__c> conItemsList = new List<ECM_Contract_Item__c>();
        map<Id,ECM_Contract_Item__c> conItemsMap = new map<Id,ECM_Contract_Item__c>();
        List<List<ECM_PDF_Generation_Controller.lightningTableWrapper>> listoflightningTableWrapper = new List<List<ECM_PDF_Generation_Controller.lightningTableWrapper>>();
        //sales Driver related to ECM-4621
        List<ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailList = new List<ECM_Sales_Driver_Item_Detail__c>();
        map<Id,ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailMap = new map<Id,ECM_Sales_Driver_Item_Detail__c>();
        List<String> labelToAPI = system.Label.ECM_Sales_Driver_Table_Sequence.split(',');//new List<String>{'Category','Product Name','Volume','UoS Conversion Rate','Total UOS','Discount per case off invoice','LUC'};
        
        Map<String, String> labelToAPINameMap = new Map<String, String>();
        Map<String, String> labelToAPIName = new Map<String, String>(); 
        List<String> fieldlistdum = new List<String>();
        List<String> fieldtranslations =new List<String>();
        Id someId = targetObjectId;
        Boolean displaySalesdriversCol=false;
        String ObjectName = string.valueof(someId.getSObjectType());//ECM_Template_Section__c,ECM_Template_Sub_Section__c
        String sobjectName='';
        Boolean nonLeadProduct = false;
        Boolean showLeadVol = false;
        ECM_Template_Section_Map__c templateSectionMapRec;
        ECM_Template_Sub_Section_Map__c templateSubSectionMapRec; //List<ECM_Template_Sub_Section_Map__c>
        //ECM-6306
        //System.debug('conCntry @'+conCntry);
        Boolean isGAS = false;
        if(conCntry !=null){
            isGAS=System.Label.ECM_GAS_Market_CountryCodes.contains(conCntry);
            /*System.debug('isGAS Comp @'+isGAS);
            System.debug('serializeMetaDataRecords Comp @'+serializeMetaDataRecords);
            System.debug('serializeObjFieldMap Comp @'+serializeObjFieldMap);*/
            metaDataRecords = (Map<String, ECM_GAS_Market_Translation__mdt>)
                JSON.deserialize(serializeMetaDataRecords, Map<String, ECM_GAS_Market_Translation__mdt>.class);
            //System.debug('metaDataRecords Comp @'+metaDataRecords);
            objFieldMap = (Map<String, String>)JSON.deserialize(serializeObjFieldMap, Map<String, String>.class);
            //System.debug('objFieldMap Comp @'+objFieldMap);
            fieldSetMap =(Map<String,List<String>>)JSON.deserialize(serializeFieldSetMap,Map<String,List<String>>.class);
            parentLabelToApi = (Map<String, String>)JSON.deserialize(serializedparentLabelToApi,Map<String, String>.class);
            getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
            System.debug('Sales Driver @'+ECM_PDF_Generation_Controller.getGlobalFields);
        }
        
        if(ObjectName.equalsIgnoreCase('ECM_Template_Section__c')){
            if(mapObjTable.templateSection!=Null){
                templateSectionMapRec = mapObjTable.templateSection;
                if(templateSectionMapRec.ECM_Template_Section__r.ECM_Section_Type__c == 'Annex' && 
                   templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__c!=Null &&
                   !templateSectionMapRec.ECM_Template_Section__r.ECM_Display_Venue_Info__c){                
                       sobjectName = templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;
                       //system.debug('sobjectNamess_temp'+sobjectName);  
                       if(sobjectName!=null){                                
                           displaySalesdriversCol =templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Sales_Driver_Item_Column__c ;
                           labelToAPIName = mapObjTable.mapFields;//getFieldApiNames(sobjectName, templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';'), templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c);//mapObjTable.mapFields;
                           //ECM-5603
                           translations = labelToAPIName;
                           translationsKey = String.join(new List<String>(labelToAPIName.keySet()),',');
                           //ECM-5603
                           //Related to ECM-4621
                           //System.Debug('@ field');
                           String ac='a';
                           //System.debug(translations);
                           if(sobjectName.equalsIgnoreCase('ECM_Sales_Driver_Item_Detail__c')){   
                               salesDriverItemDetailList = (List<ECM_Sales_Driver_Item_Detail__c>)(mapObjTable.templateSectionMap!=Null?mapObjTable.templateSectionMap:Null);                    
                               if((templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c==Null) || (templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',').size()!=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';').size())){
                                   //System.debug('labelToAPI Check @'+labelToAPI);
                                   for(string str:labelToAPI){
                                       //System.debug('labelToAPI STR @'+str);
                                       //System.debug('labelToAPIName STR @'+labelToAPIName);
                                       if(labelToAPIName.containskey(str)){
                                           fieldlistdum.add(str);
                                           //System.debug('fieldlistdum IF @'+fieldlistdum);
                                       }
                                   }
                               }else{                                   
                                   fieldlistdum=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',');
                                   //System.debug('fieldlistdum ELSE @'+fieldlistdum);
                               }
                           }else if(sobjectName.equalsIgnoreCase('ECM_Contract_Item__c')){
                               nonLeadProduct = templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Non_leading_Products_Table__c;
                               conItemsList = (List<ECM_Contract_Item__c>)(mapObjTable.templateSectionMap!=Null?mapObjTable.templateSectionMap:Null);
                               //System.debug('ConItem '+conItemsList);
                               conitemsUOMValues = (Map<String,String>)(mapObjTable.uomValues!=Null?mapObjTable.uomValues:Null);
                               if((templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c==Null) || (templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',').size()!=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';').size())){
                                   fieldlistdum = new List<String>(labelToAPIName.keyset());
                                  
                               }else{
                                   fieldlistdum=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',');                                   
                               } 
                           }
                       }
                   }
            }
        }
        else if(ObjectName.equalsIgnoreCase('ECM_Template_Sub_Section__c')){
            if(mapObjTable.templateSubSection!=Null){
                templateSubSectionMapRec = mapObjTable.templateSubSection;
                if(templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Section_Type__c == 'Annex' && 
                   templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__c!=Null ){ 
                       sobjectName = templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;
                       displaySalesdriversCol = templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Sales_Driver_Item_Column__c ;
                       labelToAPIName = mapObjTable.mapFields;
                       //System.debug('mapObjTable.mapFields @'+mapObjTable.mapFields);
                       //ECM-5603
                       translations = labelToAPIName;
                       translationsKey = String.join(new List<String>(labelToAPIName.keySet()),',');
                       //ECM-5603
                       //Related to ECM-4621
                       if(sobjectName.equalsIgnoreCase('ECM_Sales_Driver_Item_Detail__c')){   
                           salesDriverItemDetailList = (List<ECM_Sales_Driver_Item_Detail__c>)(mapObjTable.templateSectionMap!=Null?mapObjTable.templateSectionMap:Null);                    
                           if((templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c==Null) || (templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',').size()!=templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';').size())){
                               for(string str:labelToAPI){
                                   if(labelToAPIName.containskey(str)){
                                       fieldlistdum.add(str);
                                   }
                               }
                           }else{
                               fieldlistdum =templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',');                                   
                           }
                       }else if(sobjectName.equalsIgnoreCase('ECM_Contract_Item__c')){
                           //ECM-5135 changes
                           nonLeadProduct = templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Non_leading_Products_Table__c;
                           conItemsList = (List<ECM_Contract_Item__c>)(mapObjTable.templateSectionMap!=Null?mapObjTable.templateSectionMap:Null);
                           conitemsUOMValues = (Map<String,String>)(mapObjTable.uomValues!=Null?mapObjTable.uomValues:Null);
                           if((templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c==Null) || (templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',').size()!=templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';').size())){
                               fieldlistdum = new List<String>(labelToAPIName.keyset());
                               
                           }else{
                               fieldlistdum=templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',');                                   
                           }
                       }
                   }
            }
            
        }
        //System.debug('fieldlistdum @'+fieldlistdum); 
        //Related to ECM-4621
        colnum = fieldlistdum.size();
        if(templateSectionMapRec !=Null || templateSubSectionMapRec!=Null){  
            Map<String, List<String>> SalesdriveConcatinate = new Map<String,List<String>>();    
            labelToAPINameMap.PutAll(labelToAPIName);            
            map<Id,List<ECM_Sales_Driver_Item_Detail__c>> salesDriverItemMap = new map<Id,List<ECM_Sales_Driver_Item_Detail__c>>();

            if(conItemsList.size()>0)
                conItemsMap = new map<Id,ECM_Contract_Item__c>(conItemsList);
            if(!salesDriverItemDetailList.isEmpty()){
                salesDriverName = templateSectionMapRec!=Null?templateSectionMapRec.ECM_Template_Section__r.ECM_Sales_Driver__r.name:templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Sales_Driver__r.name;
                string salesDriver = templateSectionMapRec!=Null?templateSectionMapRec.ECM_Template_Section__r.ECM_Sales_Driver__c:templateSubSectionMapRec.ECM_Template_Sub_Section__r.ECM_Sales_Driver__c;
				salesDriverItemDetailMap = new map<Id,ECM_Sales_Driver_Item_Detail__c>(salesDriverItemDetailList);
                for(ECM_Sales_Driver_Item_Detail__c salezdrive : salesDriverItemDetailMap.values()){
                    if(salezdrive.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c == salesDriver){
                        if(salesDriverItemMap.containskey(salezdrive.ECM_Sales_Driver_Item__c)){
                            salesDriverItemMap.get(salezdrive.ECM_Sales_Driver_Item__c).add(salezdrive);                        
                        }else{     
                            salesDriverItemMap.put(salezdrive.ECM_Sales_Driver_Item__c,new List<ECM_Sales_Driver_Item_Detail__c>{salezdrive});
                        }
                    }
                }   
            }
            If(displaySalesdriversCol){
                for(ECM_Sales_Driver_Item_Detail__c saledrivitem : [Select Id,ECM_Sales_Driver_Item__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name,
                                                                    ECM_Product__r.ECM_Product_Name__c,ECM_Product__c 
                                                                    from ECM_Sales_Driver_Item_Detail__c where ECM_Product__c IN:conItemsList AND ECM_Addendum__c =:addendumId]){
                                                                        if(!fieldlistdum.contains(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name)){
                                                                            fieldlistdum.add(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name);
                                                                        }
                                                                        labelToAPINameMap.put(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name ,saledrivitem.ECM_Product__r.ECM_Product_Name__c+' '+saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name );
                                                                        if(SalesdriveConcatinate.containskey(saledrivitem.ECM_Product__c)){
                                                                            SalesdriveConcatinate.get(saledrivitem.ECM_Product__c).add(saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name);
                                                                        }else{
                                                                            SalesdriveConcatinate.put(saledrivitem.ECM_Product__c,new List<String>{saledrivitem.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name});
                                                                        }
                                                                    }
            }
            List<ECM_PDF_Generation_Controller.lightningTableWrapper> ltwwraps = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();
            //  labelToAPIName = new Map<string, string>();
            Integer index =0;
            if(conItemsList.size()>0){
                listoflightningTableWrapper = new List<List<ECM_PDF_Generation_Controller.lightningTableWrapper>>();
                //Added for ECM-6235
                List<ECM_Technical_Market_Setting__mdt> tmsLst = new List<ECM_Technical_Market_Setting__mdt>();
                tmsLst = [SELECT ECM_Show_Lead_Brand_Volume__c 
                          FROM ECM_Technical_Market_Setting__mdt 
                          WHERE ECM_Country__c =: conCntry AND ECM_Show_Lead_Brand_Volume__c = true]; 
                showLeadVol = (!tmsLst.isEmpty());
                
                for(ECM_Contract_Item__c conItems : conItemsList){ 
                    //ECM-5135 changes
                    if(nonLeadProduct && conItems.ECM_Lead_Brand__c){
                        continue;
                    }
                    ECM_PDF_Generation_Controller.lightningTableWrapper ltw = new ECM_PDF_Generation_Controller.lightningTableWrapper();
                    List<ECM_PDF_Generation_Controller.ObjValues> objvalList = new List<ECM_PDF_Generation_Controller.ObjValues>();
                    for(string labelName: labelToAPINameMap.keyset()){
                        Set<string> saleDriveList = new Set<string>();
                        if(labelToAPIName.containskey(labelName)){
                            ECM_PDF_Generation_Controller.ObjValues objval = new ECM_PDF_Generation_Controller.ObjValues();
                            objval.header = labelName;
                            //ECM-6306
                            List<String> relations = new List<String>{sobjectName,labelToAPIName.get(labelName)};
                            /*System.debug('1 labelToAPIName @ '+labelToAPIName.get(labelName));
                            System.debug('1 sobjectName Comp @ '+sobjectName);
                            System.debug('1 header @ '+objval.header);*/
                            string tableValue ='';
                            //ECM-6339
                            Boolean isGASCheck =System.Label.ECM_GAS_Market_CountryCodes.contains(conCntry);
                            if(labelToAPINameMap.get(labelName)=='ECM_Volume__c'){ //Added showLeadVol for ECM-6235
                                tableValue = ((labelName=='Forecast Volume' || labelToAPINameMap.get(labelName)=='ECM_Volume__c') && conItems.ECM_Lead_Brand__c && !showLeadVol)?'':
                                isGASCheck && String.valueof(conItems.get(labelToAPINameMap.get(labelName)))!=null?String.valueOf(Decimal.valueOf(String.valueof(conItems.get(labelToAPINameMap.get(labelName)))).setScale(2).format()):
                                String.valueof(conItems.get(labelToAPINameMap.get(labelName))); 
                            }else if(labelToAPINameMap.get(labelName)=='ECM_UoM__c'){
                                string uom = conitemsUOMValues.size()>0?conitemsUOMValues.get(conItems.Id):null;
                                //System.debug('uom @'+uom);
                                tableValue = uom ==Null?isGASCheck && String.valueof(conItems.get(labelToAPINameMap.get(labelName)))!=null?
                                    String.valueOf(Decimal.valueOf(String.valueof(conItems.get(labelToAPINameMap.get(labelName)))).setScale(2).format()):
                                String.valueof(conItems.get(labelToAPINameMap.get(labelName))):uom; 
                            }else{
                                //If contains translation for GAS
                                tableValue = ECM_MergeFieldHelper.gasMarketTranslation(objFieldMap, metaDataRecords, relations, conItems, conCntry, languageForGAS,fieldSetMap);
                            }
                            //System.debug('1 tableValue @ '+tableValue);
                            objval.values = tableValue;
                            //System.debug('1 values @ '+objval.values);
                            objvalList.add(objval);
                            //System.debug('objval @'+objval);
                        }If(!labelToAPIName.containskey(labelName) && SalesdriveConcatinate!=null){
                            If(SalesdriveConcatinate.containskey(conItems.Id) && SalesdriveConcatinate.get(conItems.Id) !=null){
                                for(string salescolumn : SalesdriveConcatinate.get(conItems.Id)){
                                    if(!saleDriveList.contains(conItems.Id+'-'+salescolumn)){
                                        ECM_PDF_Generation_Controller.ObjValues objval1 = new ECM_PDF_Generation_Controller.ObjValues();
                                        objval1.header = labelName;
                                        objval1.values = salescolumn==labelName?'X':'';
                                        /*System.debug('2 sobjectName Comp @ '+sobjectName);
                                        System.debug('2 header @ '+objval1.header);
                                        System.debug('2 values @ '+objval1.values);*/
                                        objvalList.add(objval1);
                                        saleDriveList.add(conItems.Id+'-'+salescolumn);
                                    }
                                }                                 
                            }else{
                                ECM_PDF_Generation_Controller.ObjValues objval1 = new ECM_PDF_Generation_Controller.ObjValues();
                                objval1.header = labelName;
                                objval1.values = '';
                                /*System.debug('3 sobjectName Comp @ '+sobjectName);
                                System.debug('3 header @ '+objval1.header);
                                System.debug('3 values @ '+objval1.values);*/
                                objvalList.add(objval1);
                            }
                        }
                    }
                    //System.debug('objvalList @'+objvalList);
                    ltw.tablerows = objvalList;
                    ltw.index = index++;                    
                    listLgtnTableWraps.add(ltw);
                    salesFieldsapi = fieldlistdum;
                }
                if(!listLgtnTableWraps.isEmpty())
                listoflightningTableWrapper.add(listLgtnTableWraps);
            }
            if(!salesDriverItemDetailList.isEmpty()){
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sobjectName).getDescribe().fields.getMap();
                listoflightningTableWrapper = new List<List<ECM_PDF_Generation_Controller.lightningTableWrapper>>();
                for(Id SdIDs: salesDriverItemMap.keyset()){
                    index =0;
                    listLgtnTableWraps = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();                  
                    for(ECM_Sales_Driver_Item_Detail__c salesDriveDetail : salesDriverItemMap.get(SdIDs)){
                        //system.debug('inside inner loop ='+listLgtnTableWraps);
                        boolean isSingleYearly=false;
                       
                        ECM_PDF_Generation_Controller.lightningTableWrapper ltw = new ECM_PDF_Generation_Controller.lightningTableWrapper();
                        List<ECM_PDF_Generation_Controller.ObjValues> objvalList = new List<ECM_PDF_Generation_Controller.ObjValues>();  
                        for(string labelName: labelToAPINameMap.keyset()){
                            Set<string> saleDriveList = new Set<string>();                             
                            if(labelToAPIName.containskey(labelName)){                               
                                ECM_PDF_Generation_Controller.ObjValues objval = new ECM_PDF_Generation_Controller.ObjValues();
                                objval.header = labelName;
                                //ECM-6306
                                List<String> relations = new List<String>{sobjectName,labelToAPIName.get(labelName)};
                                    //System.debug('relations in Comp@'+relations);
                                String tableValue =''; 
                                //ECM-4815 start
                                if(labelToAPINameMap.get(labelName).contains('__r')){
                                    //Added as part of ECM-4908
                                    if((string.valueof(salesDriveDetail.ECM_Sales_Driver_Item__r.ECM_Payment_Frequency_Type__c) == 'Single Yearly Payments')){
                                   // || labelToAPINameMap.get(labelName)=='ECM_Sales_Driver_Item__r.ECM_Total_Investment_Amount__c'){ --commented for ECM-5432
                                       isSingleYearly = true; 
                                    }
                                    tableValue = ECM_MergeFieldHelper.gasMarketTranslation(objFieldMap, metaDataRecords, relations, salesDriveDetail, conCntry, languageForGAS,fieldSetMap);
                                    //Added as part of ECM-4908
                                    if((labelToAPINameMap.get(labelName)=='ECM_Sales_Driver_Item__r.ECM_Investement_Description__c' && isSingleYearly)){
                                        tableValue = tableValue.replace(',','<br/>');
                                    }
                                }else{
                                    if(labelToAPINameMap.get(labelName)=='ECM_Investment_Amount__c'){
                                        decimal totalInvest = (Decimal)salesDriveDetail.getSobject('ECM_Sales_Driver_Item__r').get('ECM_Total_Investment_Amount__c');
                                        //ECM-6339
                                        Boolean isGASCheck =System.Label.ECM_GAS_Market_CountryCodes.contains(conCntry);
                                        tableValue =isGASCheck && String.valueof(salesDriveDetail.get(labelToAPINameMap.get(labelName)))!=null?String.valueOf(Decimal.valueOf(String.valueof(salesDriveDetail.get(labelToAPINameMap.get(labelName)))).setScale(2).format()):
                                        String.valueof(salesDriveDetail.get(labelToAPINameMap.get(labelName)));
                                    }
                                    else{
                                        tableValue =String.valueof(salesDriveDetail.get(labelToAPINameMap.get(labelName))); 
                                    }
                                }
                                objval.values = tableValue;
                                /*System.debug('4 labelToAPIName @ '+labelToAPIName.get(labelName));
                                System.debug('4 sobjectName Comp @ '+sobjectName);
                                System.debug('4 tableValue @ '+tableValue);
                                System.debug('4 header @ '+objval.header);
                                System.debug('4 values @ '+objval.values);*/
                                objvalList.add(objval);
                            }
                        }
                        
                        ltw.tablerows = objvalList;
                        ltw.index = index++; 
                        listLgtnTableWraps.add(ltw);
                        salesFieldsapi = fieldlistdum;
                        //System.debug(fieldlistdum);
                    }
                    listoflightningTableWrapper.add(listLgtnTableWraps);
                }
            }            
        }
       // System.debug('Resource Used in getSalesdrivelist():'+Limits.getQueries()+' '+Limits.getLimitCpuTime());
        return listoflightningTableWrapper;
    }
    public static Map<string,string> getTieringValues(Set<Id> conItemsId){
        Map<string,string> conitmsUom = new Map<string,string>();
        List<ECM_Tiering__c> lstofTiering = [SELECT Id, ECM_Contract_Item__c, ECM_Tier2_rate_per_UoM__c, ECM_Tier_1_rate_per_UoM__c, ECM_Tier_1_volume_limit__c, 
                                             ECM_Tier_2_volume_limit__c, ECM_Tier_3_rate_per_UoM__c, ECM_Tier_3_volume_limit__c FROM ECM_Tiering__c 
                                             where ECM_Contract_Item__c IN:conItemsId];
        string tierValue = '';
        if(lstofTiering.size()>0){
            for(ECM_Tiering__c tier : lstofTiering){
                if(!conitmsUom.containsKey(tier.ECM_Contract_Item__c)){
                    if(tier.ECM_Tier_1_volume_limit__c !=null){
                        tierValue = '(1-'+tier.ECM_Tier_1_volume_limit__c+') '+tier.ECM_Tier_1_rate_per_UoM__c+'<br/>';
                    }
                    if(tier.ECM_Tier_2_volume_limit__c !=null){
                        tierValue = tierValue+'('+(tier.ECM_Tier_1_volume_limit__c+1)+'-'+tier.ECM_Tier_2_volume_limit__c+') '+tier.ECM_Tier2_rate_per_UoM__c+'<br/>';
                    }
                    if(tier.ECM_Tier_3_volume_limit__c !=null){
                        tierValue = tierValue+'('+(tier.ECM_Tier_2_volume_limit__c+1)+'-'+tier.ECM_Tier_3_volume_limit__c+') '+tier.ECM_Tier_3_rate_per_UoM__c;
                    }
                    conitmsUom.put(tier.ECM_Contract_Item__c,tierValue);
                }
            }
            
        }
        return conitmsUom;
    }
    public Map <String, String> getFieldApiNames(String sobjectName,List<String> selectfields, String translationFields) {
       
        selectfields = ECM_DynamicTableGeneratorController.getPickListValuesIntoList(selectfields);
        //Schema.SObjectType schemaObjName = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, String> fieldConversion = new Map<String, String>{
            'UOS' => 'UoS Conversion Rate',
                'MAT Override' => 'Annual Volume',
                'MAT UOS'=>'Total UOS',
                'Total Sales Driver Discount'=>'Discount per case off invoice',
                'Current LUC'=>'LUC'
                }; 
                    Map<String, String> labelToAPIName = new Map<String, String> ();
        Map<String, String> parentAPINames = new Map<String, String> ();
        try{   
            Map<String,String> labelsApiMap = new Map<String,String>();                    
            //Map<String, Schema.SObjectField> fieldsMap = schemaObjName.getDescribe().fields.getMap();
            //system.debug('sobjectName--->'+sobjectName);
            if(sobjectName=='ECM_Sales_Driver_Item_Detail__c'){
                parentAPINames = parentLabelToApi;
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
                        labelToAPIName.put(translationFieldList[i],labelsApiMap.get(selectfields[i]));                        
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
            system.debug('==exception '+ex);
        }
        return labelToAPIName;
    }
    public List<ECM_PDF_Generation_Controller.lightningTableWrapper> getOutletContractList(){
        mapObjTable=(ECM_PDF_Generation_Controller.templateSectionWrap)JSON.deserialize(objectRecordsMap,ECM_PDF_Generation_Controller.templateSectionWrap.class);
        List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
        Map<String, String> labelToAPINameMap = new Map<String, String>();
        Map <String, String> labelToAPIName = new Map<String, String>(); 
        List<ECM_PDF_Generation_Controller.lightningTableWrapper> listLgtnTableWraps = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();
        List<String> fieldlistdum = new List<String>();
        salesFieldsapi = new List<String>();
        List<String> fieldlist = Label.ECM_Outlet_Column_Sequential.split(',');//new List<String>{'Outlet Name','Outlet Street','Outlet City','Outlet State','Outlet Postal Code'};
        string sobjectName='';//Outlet_Contract__c
        //ECM-6306
        //System.debug('conCntry @'+conCntry);
        Boolean isGAS = false;
        if(conCntry !=null){
            isGAS=System.Label.ECM_GAS_Market_CountryCodes.contains(conCntry);
            /*System.debug('isGAS Comp @'+isGAS);
            System.debug('serializeMetaDataRecords Comp @'+serializeMetaDataRecords);
            System.debug('serializeObjFieldMap Comp @'+serializeObjFieldMap);*/
            metaDataRecords = (Map<String, ECM_GAS_Market_Translation__mdt>)
                JSON.deserialize(serializeMetaDataRecords, Map<String, ECM_GAS_Market_Translation__mdt>.class);
            //System.debug('metaDataRecords Comp @'+metaDataRecords);
            objFieldMap = (Map<String, String>)JSON.deserialize(serializeObjFieldMap, Map<String, String>.class);
            //System.debug('objFieldMap Comp @'+objFieldMap);
            fieldSetMap =(Map<String,List<String>>)JSON.deserialize(serializeFieldSetMap,Map<String,List<String>>.class);
            parentLabelToApi = (Map<String, String>)JSON.deserialize(serializedparentLabelToApi,Map<String, String>.class);
            getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
            System.debug('Outlet Contract @'+ECM_PDF_Generation_Controller.getGlobalFields);
        }
        //ECM-4761       
        ECM_Template_Section_Map__c templateSectionMapRec;
        if(mapObjTable!=Null){  
            templateSectionMapRec = mapObjTable.templateSection;
            //System.debug('Title check --'+templateSectionMapRec.ECM_Template_Section__r.ECM_Section_Type__c);
            //System.debug('Title check --'+templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__c);
            System.debug('Title check --'+templateSectionMapRec.ECM_Template_Section__r.ECM_Display_Venue_Info__c);
            if(templateSectionMapRec.ECM_Template_Section__r.ECM_Section_Type__c == 'Annex' &&
               templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__c!=Null &&
               templateSectionMapRec.ECM_Template_Section__r.ECM_Display_Venue_Info__c){
                   outletContractList =  (List<Outlet_Contract__c>)(mapObjTable.templateSectionMap!=Null?mapObjTable.templateSectionMap:Null);                     
                   sobjectName = templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;   
                   List<String> temp=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';');               
                   labelToAPIName = getFieldApiNames(sobjectName, temp, templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c);
                   //sequencial format of colomns
                   
                   if((templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c==Null) ||
                      (templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',').size()!=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';').size())){
                          for(string str:fieldlist){
                              if(labelToAPIName.containskey(str)){
                                  fieldlistdum.add(str);
                              }
                          }
                      }else{
                          fieldlistdum =new List<String>(labelToAPIName.keyset());
                      }
                   
               }
        }
        if(templateSectionMapRec !=Null){          
            Map<String, List<String>> OutletContractConcatinate = new Map<String,List<String>>();      
            labelToAPINameMap.PutAll(labelToAPIName);  
            List<ECM_PDF_Generation_Controller.lightningTableWrapper> ltwwraps = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();
            if(outletContractList.size()>0){
                for(Outlet_Contract__c outCon : outletContractList){              
                    ECM_PDF_Generation_Controller.lightningTableWrapper ltw = new ECM_PDF_Generation_Controller.lightningTableWrapper();
                    List<ECM_PDF_Generation_Controller.ObjValues> objvalList = new List<ECM_PDF_Generation_Controller.ObjValues>();
                    for(string labelName: labelToAPINameMap.keyset()){
                        if(labelToAPIName.containskey(labelName)){
                            //ECM-6306
                            List<String> relations = new List<String>{sobjectName,labelToAPIName.get(labelName)};
                               String tableValue = ''; 
                            ECM_PDF_Generation_Controller.ObjValues objval = new ECM_PDF_Generation_Controller.ObjValues();
                            objval.header = labelName;
                            tableValue = ECM_MergeFieldHelper.gasMarketTranslation(objFieldMap, metaDataRecords, relations, outCon, conCntry, languageForGAS,fieldSetMap);
                            //System.debug('ConItem tableValue @'+tableValue);
                            objval.values = tableValue; 
                            objvalList.add(objval);
                        }                        
                        else{
                            ECM_PDF_Generation_Controller.ObjValues objval1 = new ECM_PDF_Generation_Controller.ObjValues();
                            objval1.header = labelName;
                            objval1.values = '';
                            objvalList.add(objval1);
                        }                        
                    }
                    ltw.tablerows = objvalList;
                    listLgtnTableWraps.add(ltw);
                    venuInfoApi = fieldlistdum;
                }
            }
        }
		//System.debug('Resource Used in getOutletContractList():'+Limits.getQueries()+' '+Limits.getLimitCpuTime());        
        //system.debug('listLgtnTableWraps--------'+listLgtnTableWraps.Size());
        return listLgtnTableWraps;
    }
    public List<ECM_PDF_Generation_Controller.lightningTableWrapper> getSalesDriverAU(){
        ECM_PDF_Generation_Controller.templateSectionWrap vfTableData = (ECM_PDF_Generation_Controller.templateSectionWrap)JSON.deserialize(objectRecordsMap,ECM_PDF_Generation_Controller.templateSectionWrap.class);
        listLgtnTableWraps = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();
        List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
        List<String> fieldlist = Label.ECM_Product_Discount_Column_Sequentials.split(',');
        List<ECM_Contract_Item__c> conItemsList = new List<ECM_Contract_Item__c>();
        Map<String, String> labelToAPINameMap = new Map<String, String>();
        salesFieldsapi = new List<String>();
        Id someId = targetObjectId;        
        String ObjectName = string.valueof(someId.getSObjectType());        
        Map <String, String> labelToAPIName = new Map<String, String>();
        string sobjectName;
        List<String> fieldlistdum = new List<String>();
        ECM_Template_Section_Map__c templateSectionMapRec;  
        boolean salesDriver = true;
        boolean nonLeadProduct = false;
        string categary='';
        if(conCntry !=null){
            parentLabelToApi = (Map<String, String>)JSON.deserialize(serializedparentLabelToApi,Map<String, String>.class);
            getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
            System.debug('Sales Driver AU @'+ECM_PDF_Generation_Controller.getGlobalFields);
        }
        ECM_Template_Sub_Section_Map__c templateSubSectionMapRec; 
        if(ObjectName.equalsIgnoreCase('ECM_Template_Section__c')){
            templateSectionMapRec = vfTableData.templateSection;
            if(templateSectionMapRec.ECM_Template_Section__r.ECM_Section_Type__c == 'Annex' && 
               templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__c!=Null &&
               !templateSectionMapRec.ECM_Template_Section__r.ECM_Display_Venue_Info__c){
                   sobjectName=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Object__c;
                   labelToAPIName = getFieldApiNames(sobjectName,  templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';'),  templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c);
                   conItemsList = (List<ECM_Contract_Item__c>)(vfTableData.templateSectionMap!=Null?vfTableData.templateSectionMap:Null);       
                   nonLeadProduct = templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Non_leading_Products_Table__c;
                   categary = templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Table_Type__c;
                   if((templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c==Null) || (templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields_Translation__c.split(',').size()!=templateSectionMapRec.ECM_Template_Section__r.ECM_Dynamic_Table_Generator__r.ECM_Dynamic_Fields__c.split(';').size())){
                       for(string str:fieldlist){
                           if(labelToAPIName.containskey(str)){
                               fieldlistdum.add(str);
                           }
                       }            
                     
                   }else{                     
                       fieldlistdum =new List<String>(labelToAPIName.keyset());                   
                   }
                   salesDriver=sobjectName.equalsIgnoreCase('ECM_Sales_Driver_Item_Detail__c')?true:false;
               }
            
            if(templateSectionMapRec !=Null && !salesDriver){ 
                Map<String, List<String>> SalesdriveConcatinate = new Map<String,List<String>>();      
                labelToAPINameMap.PutAll(labelToAPIName);
                
                if(conItemsList.size()>0){
                    List<ECM_PDF_Generation_Controller.lightningTableWrapper> ltwwraps = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();
                    for(ECM_Contract_Item__c conItems : conItemsList){    
                        ECM_PDF_Generation_Controller.lightningTableWrapper ltw = new ECM_PDF_Generation_Controller.lightningTableWrapper();
                        List<ECM_PDF_Generation_Controller.ObjValues> objvalList = new List<ECM_PDF_Generation_Controller.ObjValues>();
                        //ECM-5135 changes
                        if(nonLeadProduct && conItems.ECM_Lead_Brand__c){
                            continue;
                        }
                       if(!string.isEmpty(categary) &&
						(categary == 'ECM_First_Pour__c' && !conItems.ECM_First_Pour__c) || (categary == 'ECM_Mandatory_Back_Bar__c' && !conItems.ECM_Mandatory_Back_Bar__c)){
							continue;
						}
                        for(string labelName: labelToAPINameMap.keyset()){
                            Set<string> saleDriveList = new Set<string>();
                            if(labelToAPIName.containskey(labelName)){
                                ECM_PDF_Generation_Controller.ObjValues objval = new ECM_PDF_Generation_Controller.ObjValues();
                                objval.header = labelName;
                                if(labelName=='Annual Volume' || labelName=='Estimated Annual Volume'){
                                    objval.values = String.valueof((conItems.get('ECM_MAT_Final__c'))); //ECM-5417										                                       
                                }else{
                                    objval.values = String.valueof(conItems.get(labelToAPINameMap.get(labelName)));
                                }
                                objvalList.add(objval);
                            }
                        }
                        ltw.tablerows = objvalList;
                        listLgtnTableWraps.add(ltw);
                        salesFieldsapi = fieldlistdum;
                    }
                    
                }
                
            }
        }
        //System.debug('Resource Used in getSalesDriverAU():'+Limits.getQueries()+' '+Limits.getLimitCpuTime());
        //system.debug('listLgtnTableWraps'+listLgtnTableWraps.size());
        return listLgtnTableWraps;
    }
}