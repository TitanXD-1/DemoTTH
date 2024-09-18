/*
*@Name: ECM_PDF_Generation_Controller_Test
*@Purpose: This class is used to cover testclass for the - ECM_PDF_Generation_Controller & ECM_PDF_GenerationComponentCtrl
*@History:                                                            
*VERSION       AUTHOR                  DATE                   DETAIL
*1.0      Saurav Kumar Prasad       27/05/2020          Initial Development
*2.0	    Anivesh Muppa		    16/07/2020			ECM-4621
*3.0	    Anivesh Muppa		    01/10/2020			ECM-4815
*4.0         Pratap Sen             14/10/2022          Restructured the code & Added changes for ECM-6235
*4.1		Saurav Prasad			19/10/2023			126383  : [ECM-6905] Product Order on PDF Output
*4.2        Joshraj Sen             11/06/2024          PMD Fix
*/

@isTest
public class ECM_PDF_Generation_Controller_Test {
    /*
    * @description : tests generic & AU specific methods of ECM_PDF_Generation_Controller & ECM_PDF_GenerationComponentCtrl
    * @return : void
    * @param : void
    */
    @isTest
    public static void testPDF1(){        
        DataWrap conData = setupConData('AU', false);
        
        //Set up template sections & subsections for PDF
        ECM_Template_Agreement__c tmpAgree = new ECM_Template_Agreement__c(ECM_Type__c = 'Contract', ECM_Agreement_Type__c = conData.conTypeId, ECM_Status__c = 'Active');
        tmpAgree.ECM_Title__c = 'Template agreement TITLE';
        tmpAgree.ECM_Apply_Auto_Numbering__c = true;
        Insert tmpAgree;
        
        conData.tempAgrmntId = tmpAgree.Id;
        List<Id> objId = setupPDFtemplate(conData);//sets up template section & subsection related records and links with template agreement
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(conData.con); 
        Test.setCurrentPage(setPageRef(conData.conId, null));
        
        //Call ECM_PDF_Generation_Controller methods for testing
        ECM_PDF_Generation_Controller pdfTest = new ECM_PDF_Generation_Controller(sc);
        pdfTest.contractId = conData.conId;
        pdfTest.agreementTypeID = conData.conTypeId;
        pdfTest.getObligations();
        List<ECM_PDF_Generation_Controller.lightningTableWrapper> tblWrp = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();
        ECM_PDF_Generation_Controller.lightningTableWrapperNumber tblWrpNumbr = new ECM_PDF_Generation_Controller.lightningTableWrapperNumber(tblWrp,new List<String>{'hdr'},'title');
        System.debug(LoggingLevel.DEBUG,tblWrpNumbr);
        List<ECM_PDF_Generation_Controller.templateSectionMapWrapper> templateWrap = pdfTest.processAnnexTable(pdfTest.tempSectMapWrapper);
        
        //Prepare data wrapper for vfc
        List<String> tempSecString = new List<String>();
        List<String> tempSubSecString = new List<String>();
        for(ECM_PDF_Generation_Controller.templateSectionMapWrapper wrap : templateWrap){
            if(wrap.tableData != null && Wrap.subsection != null){
                tempSecString.add(wrap.tableData);               
                    for(ECM_PDF_Generation_Controller.templateSubSectionMapWrapper tempSubWrap: Wrap.subsection){
                        if(tempSubWrap.subTableData != null){
                            tempSubSecString.add(tempSubWrap.subTableData);
                        }                   
                }
            }
        }
        system.Assert(tempSecString.size()>0 && tempSubSecString.size()>0,'True'); //Assert wrapper created for table data of dtg isnot empty
        //Call ECM_PDF_GenerationComponentCtrl methods for testing with MDM context
        User mdmUsr = ECM_UtilityTestClass.createUser('mdm',ECM_UtilityTestClass.getProfile('Master Data Manager').Id);
        mdmUsr.Username = 'mdmUsr@test.com';
        mdmUsr.Available_Countries__c = 'AU';
        insert mdmUsr;
        
        AccountShare accountShare= new AccountShare();
        accountShare.accountId=pdfTest.accountId;
        accountShare.UserOrGroupid=mdmUsr.Id;
        accountShare.accountaccessLevel='Edit';
        accountShare.OpportunityAccessLevel='None';
        insert accountShare;
        
        ECM_PDF_GenerationComponentCtrl vfCompController = new ECM_PDF_GenerationComponentCtrl();
        vfCompController.conCntry = 'AU';
        vfCompController.serializeMetaDataRecords = JSON.serialize(pdfTest.metaDataRecords);
        vfCompController.serializeObjFieldMap = JSON.serialize(pdfTest.objFieldMap);
        vfCompController.serializeFieldSetMap = pdfTest.serializedFieldSetMap;
        vfCompController.serializedparentLabelToApi = pdfTest.serializedparentLabelToApi;
        vfCompController.getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
        system.runAs(mdmUsr){
            for(String tblData : tempSecString){
                vfCompController.agreementTypeID = conData.conTypeId;
                vfCompController.targetObjectId = objId[0];
                vfCompController.objectRecordsMap = tblData;
                vfCompController.getSalesDriverAU();
                vfCompController.getSalesdrivelist();
                vfCompController.getOutletContractList();
            }
        }
        ECM_PDF_GenerationComponentCtrl vfCompController2 = new ECM_PDF_GenerationComponentCtrl();
        vfCompController2.conCntry = 'AU';
        vfCompController2.serializeMetaDataRecords = JSON.serialize(pdfTest.metaDataRecords);
        vfCompController2.serializeObjFieldMap = JSON.serialize(pdfTest.objFieldMap);
        vfCompController2.serializeFieldSetMap = pdfTest.serializedFieldSetMap;
        vfCompController2.serializedparentLabelToApi = pdfTest.serializedparentLabelToApi;
        vfCompController2.getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
        system.runAs(mdmUsr){
            for(String tblData : tempSubSecString){
                vfCompController2.agreementTypeID = conData.conTypeId;
                vfCompController2.targetObjectId = objId[1];
                vfCompController2.objectRecordsMap = tblData;
                vfCompController2.getSalesdrivelist();
            }
        }
        Test.stopTest();
    }
    
    /*
    * @description : tests generic & EU specific methods of ECM_PDF_Generation_Controller & ECM_PDF_GenerationComponentCtrl
    * @return : void
    * @param : void
    */
    @isTest
    public static void testPDF2(){
        DataWrap conData = setupConData('ES', false);

        //Set up template section & subsections for PDF
        ECM_Template_Agreement__c tmpAgree = new ECM_Template_Agreement__c(ECM_Type__c = 'Contract', ECM_Agreement_Type__c = conData.conTypeId, ECM_Status__c = 'Active');
        tmpAgree.ECM_Title__c = 'Template agreement TITLE';
        tmpAgree.ECM_Apply_Auto_Numbering__c = true;
        Insert tmpAgree;
        
        conData.tempAgrmntId = tmpAgree.Id;
        List<Id> objId = setupPDFtemplate(conData);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(conData.con); 
        Test.setCurrentPage(setPageRef(conData.conId, null));
        
        //Call ECM_PDF_Generation_Controller methods for testing
        ECM_PDF_Generation_Controller pdfTest = new ECM_PDF_Generation_Controller(sc);
        pdfTest.contractId = conData.conId;
        pdfTest.agreementTypeID = conData.conTypeId;
        List<ECM_PDF_Generation_Controller.templateSectionMapWrapper> templateWrap = pdfTest.processAnnexTable(pdfTest.tempSectMapWrapper);

        //Prepare data wrapper for vfc
        List<String> tempSecString = new List<String>();
        List<String> tempSubSecString = new List<String>();
        for(ECM_PDF_Generation_Controller.templateSectionMapWrapper wrap : templateWrap){
            if(wrap.tableData != null && Wrap.subsection != null){
                tempSecString.add(wrap.tableData);                
                    for(ECM_PDF_Generation_Controller.templateSubSectionMapWrapper tempSubWrap: Wrap.subsection){
                        if(tempSubWrap.subTableData != null){
                            tempSubSecString.add(tempSubWrap.subTableData);
                        }
                    
                }
            }
        }
        system.Assert(tempSecString.size()>0 && tempSubSecString.size()>0,'True'); //Assert wrapper created for table data of dtg isnot empty
        //Call ECM_PDF_GenerationComponentCtrl methods for testing 
        ECM_PDF_GenerationComponentCtrl vfCompController = new ECM_PDF_GenerationComponentCtrl();
        for(String tblData : tempSecString){
            vfCompController.targetObjectId = objId[0];
            vfCompController.conCntry = 'AT'; //Added for ECM-6235
            vfCompController.serializeMetaDataRecords = JSON.serialize(pdfTest.metaDataRecords);
            vfCompController.serializeObjFieldMap = JSON.serialize(pdfTest.objFieldMap);
            vfCompController.serializeFieldSetMap = pdfTest.serializedFieldSetMap;
            vfCompController.serializedparentLabelToApi = pdfTest.serializedparentLabelToApi;
            vfCompController.getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
            vfCompController.objectRecordsMap = tblData;
            vfCompController.getSalesdrivelist();
            vfCompController.getOutletContractList();
        }
        ECM_PDF_GenerationComponentCtrl vfCompController2 = new ECM_PDF_GenerationComponentCtrl();
        vfCompController2.conCntry = 'AT';
        vfCompController2.serializeMetaDataRecords = JSON.serialize(pdfTest.metaDataRecords);
        vfCompController2.serializeObjFieldMap = JSON.serialize(pdfTest.objFieldMap);
        vfCompController2.serializeFieldSetMap = pdfTest.serializedFieldSetMap;
        vfCompController2.serializedparentLabelToApi = pdfTest.serializedparentLabelToApi;
        vfCompController2.getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
        for(String tblData : tempSubSecString){
            vfCompController2.targetObjectId = objId[1];
            vfCompController2.objectRecordsMap = tblData;
            vfCompController2.getSalesdrivelist();
        }
        
        ECM_PDF_GenerationComponentCtrl vfCompController3 = new ECM_PDF_GenerationComponentCtrl();
        for(String tblData : tempSecString){
            vfCompController3.targetObjectId = objId[0];
            vfCompController3.conCntry = 'DE'; //Added for ECM-6235
            vfCompController3.languageForGAS = 'DE';
            vfCompController3.serializeMetaDataRecords = JSON.serialize(pdfTest.metaDataRecords);
            vfCompController3.serializeObjFieldMap = JSON.serialize(pdfTest.objFieldMap);
            vfCompController3.serializeFieldSetMap = pdfTest.serializedFieldSetMap;
            vfCompController3.serializedparentLabelToApi = pdfTest.serializedparentLabelToApi;
        	vfCompController3.getGlobalFields = ECM_PDF_Generation_Controller.getGlobalFields;
            vfCompController3.objectRecordsMap = tblData;
            vfCompController3.getSalesdrivelist();
            vfCompController3.getOutletContractList();
        }
        Test.stopTest();
    }
    
    /*
    * @description : tests E&S specific code
    * @return : void
    * @param : void
    */
    @isTest
    public static void testPDF3(){
        DataWrap conData = setupConData('AU', true);
        
        //Set up template section & subsections for PDF
        ECM_Template_Agreement__c tmpAgree = new ECM_Template_Agreement__c(ECM_Type__c = 'Contract', ECM_Agreement_Type__c = conData.conTypeId, ECM_Status__c = 'Active');
        tmpAgree.ECM_Title__c = 'Template agreement TITLE';
        tmpAgree.ECM_Apply_Auto_Numbering__c = true;
        Insert tmpAgree;
        system.Assert(conData.conId != null  ,'True');
        conData.tempAgrmntId = tmpAgree.Id;        
        setupPDFtemplateES(conData);
        Test.startTest();
        //run controller with E&S specific data
        ApexPages.StandardController sc = new ApexPages.StandardController(conData.con); 
        Test.setCurrentPage(setPageRef(conData.conId, null));      
        ECM_PDF_Generation_Controller pdfTestES = new ECM_PDF_Generation_Controller(sc);
        System.debug(LoggingLevel.INFO,pdfTestES);
        Test.stopTest();
    }
    
     /*
    * @description : tests addendum specific code
    * @return : void
    * @param : void
    */
    @isTest
    public static void testPDF4(){
        DataWrap conData = setupConData('ES', false);
        Test.startTest();
        //run controller with addendum Id
        System.Assert(conData.con != null,'true');
        ApexPages.StandardController sc = new ApexPages.StandardController(conData.con); 
        Test.setCurrentPage(setPageRef(conData.conId, conData.adnDmId));      
        ECM_PDF_Generation_Controller pdfTestES = new ECM_PDF_Generation_Controller(sc);
        System.debug(LoggingLevel.INFO,pdfTestES);
        Test.stopTest();
    }
    
    /*
    * @description : executes class variables which gets value from vfp and vfc (to increase class coverage)
    * @return : void
    * @param : void
    */
    @isTest
    public static void testPDF5(){        
        DataWrap conData = setupConData('AU', false);        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(conData.con); 
        Test.setCurrentPage(setPageRef(conData.conId, null));
        System.Assert(conData.conId != null,'true');
        //Call ECM_PDF_Generation_Controller methods for testing
        ECM_PDF_Generation_Controller pdfTest = new ECM_PDF_Generation_Controller(sc);
        pdfTest.imageUrl = '';
        pdfTest.salesDriverName = '';
        pdfTest.targetObjectId = conData.conId;
        pdfTest.textToDisplay = '';
        pdfTest.colnum = 2;
        pdfTest.outletContractList = new List<Outlet_Contract__c>();
        pdfTest.getSalesDriverAU();
        pdfTest.getOutletContractList();
        pdfTest.getSalesdrivelist();
        List<ECM_PDF_Generation_Controller.lightningTableWrapper> tblWrp = new List<ECM_PDF_Generation_Controller.lightningTableWrapper>();
        ECM_PDF_Generation_Controller.lightningTableWrapperNumber tblWrpNumbr = new ECM_PDF_Generation_Controller.lightningTableWrapperNumber(tblWrp,new List<String>{'hdr'},'title');
        System.debug(LoggingLevel.INFO,tblWrpNumbr);
        
        ECM_PDF_GenerationComponentCtrl vfCompController = new ECM_PDF_GenerationComponentCtrl();
        vfCompController.AccountId = '';
        vfCompController.UOM = '';
        vfCompController.countryAssigned = '';
        vfCompController.textToDisplay = '';
        vfCompController.tempSecString = '';
        Test.stopTest();
    }
    
    /**    
    * @description : returns pagereference of vf page of instance contract
    * @return PageReference
    * @param conId
    * @param addndmId
    **/
    public static PageReference setPageRef(Id conId, Id addndmId){
        PageReference pageRef = Page.ECM_PDF_Generation;
        Test.setCurrentPageReference(new PageReference('Page.ECM_PDF_Generation'));
        System.currentPageReference().getParameters().put('id', String.valueOf(conId));
        if(addndmId != null){
            System.currentPageReference().getParameters().put('text', String.valueOf(addndmId));
        }
        System.currentPageReference().getParameters().put('addendumId', (addndmId == null)?'':addndmId);
        System.currentPageReference().getParameters().put('isApproval','false');
        pageRef.getParameters().put('Id', String.valueOf(conId)); 
        if(addndmId != null){
            pageRef.getParameters().put('text', String.valueOf(addndmId)); 
        }
        pageRef.getParameters().put('addendumId',(addndmId == null)?'':String.valueOf(addndmId));
        pageRef.getParameters().put('isApproval','false');
        return pageRef;
    }
    
    /** 
    * @description  adds contract & it's related records
    * @return DataWrap
    * @param geoCode
    * @param isES
    **/
    public static DataWrap setupConData(String geoCode, Boolean isES){
        //Set up geography & User records
        Id geographyId = (geoCode != 'ES')? EDGE_UtilityTestClass.setupCountry(geoCode) : EDGE_UtilityTestClass.setupCountrySpain(geoCode);
        
        if(geoCode == 'AU'){
            Market_Setting__c mSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
            mSetting.ECM_Contract_Creation_Page__c = (geoCode != 'AU')?'Global':'Australia';
            mSetting.ECM_Date_Format__c = 'dd/MM/yyyy';
            insert mSetting;
        }
        
        User salesRep = ECM_UtilityTestClass.createUser('sr',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'srUsr@test.com';
        salesRep.isActive = true;
        salesRep.Available_Countries__c = geoCode;
        insert salesRep;
        
        //Mandatory Record to create contract : agreement type & account
        ECM_Contract_Type__c conType = ECM_UtilityTestClass.createContractType(geographyId);
        conType.Name='Promotional';
        conType.ECM_Volume_UoM_for_Beer__c = 'EU';
        conType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;UoM;Rate Per UoM;Investment';
        insert conType;
        
        Account accRec = EDGE_UtilityTestClass.getOutletRecord();
        accRec.Person_Responsible__c= salesRep.Id;
        accRec.OwnerId = salesRep.Id;
        insert accRec;
        
        //Create Product to Link with Contract through Contract Item
        Product__c prodRec = ECM_UtilityTestClass.createProduct(geographyId,'Johnny Walker');
        prodRec.Name='Johnny Walker Black Label';
        prodRec.UPIID__c='12345';
        prodRec.Product_Full_Name__c = 'Johnny Walker Black Label 7L';
        insert prodRec;
        
        Product_UOM__c prdUOM = new Product_UOM__c(Product__c = prodRec.Id, Conversion_Factor__c = 2, Unique_ID__c = 'Test1');
        insert prdUOM;
        Market_Assortment_Product__c mapRec = new Market_Assortment_Product__c(Product__c = prodRec.Id, Market_Assortment__c = geographyId);
        insert mapRec;
        
        //PF for Sales Driver Item
        ECM_Payment_Frequency__c pfRec = ECM_UtilityTestClass.getPayFre(geographyId);
        pfRec.ECM_Type__c = 'Single Yearly Payments';
        pfRec.ECM_End_Date__c = true;
        insert pfRec;
        
        //PGD for Contract Item
        String pgdId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product growth-driver').getRecordTypeId();
        Pick_Up_Options__c pgdRec = new Pick_Up_Options__c(RecordTypeId = pgdId, Geography__c = geographyId);
        pgdRec.Name = 'Gold[AU]';
        insert pgdRec;
        
        //Territory budget for Sales Driver creation
        Territory_Hierarchy__c terrHr = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
        insert terrHr;
        Territory__c  terRec = EDGE_UtilityTestClass.getTerritoryRec();
        terRec.Business_Unit__c = terrHr.Id;
        insert terRec;
        
        Territory_Budget__c terrBdgt1 = new Territory_Budget__c(Territory__c = terRec.Id, ECM_Territory_Hierarchy__c = terrHr.Id);
        terrBdgt1.ECM_Type__c =  'TI';
        terrBdgt1.End_Date__c = system.today()+5;
        terrBdgt1.Start_Date__c = system.today()+10;
        insert terrBdgt1;
        
        Territory_Budget__c terrBdgt2 = terrBdgt1.clone(false,false,false,false);
        terrBdgt2.ECM_Type__c =  'A&P';
        insert terrBdgt2;
        
        //Create Sales Drivers with Each Territory Budget
        String sdRecId = ECM_Sales_Driver__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        ECM_Sales_Driver__c sd1 = new ECM_Sales_Driver__c(Geography__c = geographyId, RecordTypeId = sdRecId, ECM_Territory_Budget__c = terrBdgt1.id);
        ECM_Sales_Driver__c sd2 = new ECM_Sales_Driver__c(Geography__c = geographyId, RecordTypeId = sdRecId, ECM_Territory_Budget__c = terrBdgt2.id);
        List<ECM_Sales_Driver__c> sdList = New List<ECM_Sales_Driver__c>{sd1, sd2};
        insert sdList;
        
        //Create Contract
        String recType = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objCon = EDGE_UtilityTestClass.getContract(accRec.Id, recType);
        objCon.Status = 'Draft';
        objCon.Contract_End_Date__c = System.today();
        objCon.ECM_Agreement_Type__c = conType.Id;
        objCon.StartDate = system.today();
        objCon.ECM_Duration__c = 12;
        objCon.ECM_Hybrid_UOS_PerTerm__c = 3;
        objCon.ECM_Total_Upfront_Payment_Loan_Over_Term__c = 2;
        objCon.Contract_End_Date__c = system.today()+360;
        objCon.ECM_Overall_Investment_Amount__c=30.00;
        insert objCon;
                
        ECM_Contract_Item__c ciRec = new ECM_Contract_Item__c(ECM_Contract__c = objCon.Id, ECM_Product__c = mapRec.Id);
        ciRec.ECM_Product_Growth_Driver__c = 'Gold/Silver';
        insert ciRec;
                
        //Create 10 Sales Driver Items with each of these sales drivers
        list<ECM_Sales_Driver_Item__c> sdiList = new List<ECM_Sales_Driver_Item__c>();            
        for(integer i=0; i<20; i++){
            ECM_Sales_Driver_Item__c sdItem = new ECM_Sales_Driver_Item__c(Contract__c = objCon.Id, ECM_Payment_Frequency__c = pfRec.Id);
            sdItem.ECM_Sales_Driver_Name__c = 'sdi'+i;
            sdItem.ECM_Sales_Driver__c = (i<10)? sd1.Id : sd2.Id;
            sdiList.add(sdItem); 
        }            
        insert sdiList;
        
        //Add Sales Driver Item Details
        ECM_Sales_Driver_Item_Detail__c sdDetail1 = new ECM_Sales_Driver_Item_Detail__c(ECM_Contract__c = objCon.Id, ECM_Product__c = ciRec.Id);
        sdDetail1.ECM_Sales_Driver_Item__c = sdiList[0].id;
        ECM_Sales_Driver_Item_Detail__c sdDetail2 = sdDetail1.clone(false,false,false,false);
        sdDetail2.ECM_Sales_Driver_Item__c = sdiList[10].id;
        List<ECM_Sales_Driver_Item_Detail__c> sdDtlList = new List<ECM_Sales_Driver_Item_Detail__c>{sdDetail1, sdDetail2}; 
        insert sdDtlList;
        
        //Add Tiering records        
        ECM_Tiering__c tieR = ECM_CreateContractController.createTieringRecord(ciRec.Id, 10, 10, 20, 20, 30, 30);
        System.debug(LoggingLevel.DEBUG,tieR);
        
        //Add Outlet Contract Record
        Outlet_Contract__c olCon = new Outlet_Contract__c(Contract__c = objCon.Id, Outlet__c = accRec.Id);
        insert olCon;
        
        //Add Addendum
        ECM_Addendum__c addnDm = new ECM_Addendum__c(ECM_Contract__c = objCon.Id, ECM_Status__c = 'Approved');
        addnDm.Name='Test';
        addnDm.ECM_New_T_C__c = 'Checking';
        insert addnDm;
        
        Contract conES;
        if(isES){
            //ES starts
            conES = objCon.clone(false,false,false,false);
            conES.RecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId();
            insert conES;
            
            //E&S specific contract related items
            ECM_Event__c objEve = new ECM_Event__c(ECM_Event_Name__c = 'Test Event', ECM_Event_Date__c = System.today(), ECM_Contract__c  = conES.Id);
            objEve.ECM_Event_Unique_Id__c = objEve.ECM_Contract__c + objEve.ECM_Event_Name__c + objEve.ECM_Event_Date__c;
            insert objEve;
            
            ECM_Amplification__c ampWeb = new ECM_Amplification__c(ECM_Contract__c = conES.Id, ECM_Logo_Inculsion__c = 'Yes', ECM_Home_Page_Banners__c = 'Yes');
            ampWeb.ECM_Unique_Id__c = conES.Id + 'website';
            ampWeb.RecordTypeId = Schema.SObjectType.ECM_Amplification__c.getRecordTypeInfosByName().get('Website').getRecordTypeId();
            insert ampWeb;
            //ES ends
        }

        DataWrap conData = new DataWrap();
        conData.con = (isES) ? conES : objCon;
        conData.conId =  (isES) ? conES.Id :objCon.Id;
        conData.conTypeId = conType.Id;
        conData.pgdId = pgdRec.Id;
        conData.sdList = sdList;
        conData.adnDmId = addnDm.Id;
        conData.countryId = geographyId;
        return conData;
    }
    
    /*Wrapper to wrap contract related data*/
    /** *
     * @description Wrapper for Test Class
    */
    public class DataWrap{
        public Contract con;
        public id conId;
        public id conTypeId;
        public id pgdId;
        public List<ECM_Sales_Driver__c> sdList;
        public id adnDmId;
        public id tempAgrmntId;
        public id countryId;
    }
    
    /** 
    * @description : adds E&S specific templates 
    * @param  conData
    **/
    public static void setupPDFtemplateES(DataWrap conData){
        List<ECM_Template_Section__c> esTSList = new List<ECM_Template_Section__c>();
        ECM_Template_Section__c tsES1 = new ECM_Template_Section__c(ECM_Title__c = 'ES', ECM_Active__c = true);
        tsES1.ECM_ES_Table_Type__c = 'Pourage';
        tsES1.ECM_Text__c = '';
        esTSList.add(tsES1);
        
        ECM_Template_Section__c tsES2 = new ECM_Template_Section__c(ECM_Title__c = 'ES2', ECM_Active__c = true);
        tsES2.ECM_ES_Table_Type__c = 'Event';
        tsES2.ECM_Text__c = '{!Con}';
        esTSList.add(tsES2);
        
        ECM_Template_Section__c tsES3 = new ECM_Template_Section__c(ECM_Title__c = 'ES3', ECM_Active__c = true);
        tsES3.ECM_ES_Table_Type__c = 'Amplification';
        tsES3.Amplification_Setting__c = 'Website';
        tsES3.ECM_Text__c = '{!Con}';
        esTSList.add(tsES3);
        
        for(ECM_Template_Section__c section: esTSList){
            section.ECM_Geography__c = conData.countryId;
        }
        insert esTSList;
        
        List<ECM_Template_Section_Map__c> esTsmList = new List<ECM_Template_Section_Map__c>();
        for(ECM_Template_Section__c ts : esTSList){
            ECM_Template_Section_Map__c esTSM = new ECM_Template_Section_Map__c(ECM_Template_Agreement__c = conData.tempAgrmntId, ECM_Template_Section__c = ts.Id, ECM_Sequence_Number__c=1);
            esTsmList.add(esTSM);
        }
        insert esTsmList;
    }
    
    /** 
    * @description  adds all the template related items
    * @return : List<Id> 
    * @param  conData
    **/
    public static List<Id> setupPDFtemplate(DataWrap conData){
        List<ECM_Sales_Driver__c> sdList = conData.sdList;
        Id pgdId = conData.pgdId;
        
        //List of DTG with all objects
        ECM_Dynamic_Table_Generator__c dtgCI = new ECM_Dynamic_Table_Generator__c(Name = 'TEST', ECM_Object__c = 'ECM_Contract_Item__c');
        dtgCI.ECM_Dynamic_Sales_Driver_Item_Column__c = true;
        dtgCI.ECM_Field_API_Names__c = 'ECM_Product_Name__c,ECM_Volume__c,ECM_UoM__c';
        dtgCI.ECM_Dynamic_Fields__c = 'Product Name;Forecast Volume;Rate/UoM;';
        dtgCI.ECM_Dynamic_Fields_Translation__c = 'A,B';
        
        ECM_Dynamic_Table_Generator__c dtgCI1 = new ECM_Dynamic_Table_Generator__c(Name = 'TEST', ECM_Object__c = 'ECM_Contract_Item__c');
        dtgCI1.ECM_Dynamic_Sales_Driver_Item_Column__c = false;
        dtgCI1.ECM_Non_leading_Products_Table__c = true;
        dtgCI1.ECM_Field_API_Names__c = 'ECM_MAT_override__c,ECM_MAT_UOS__c,ECM_Discount_per_case_off_invoice__c';
        dtgCI1.ECM_Dynamic_Fields__c = 'Annual Volume;Total UOS;Discount per case off invoice;';
        
        ECM_Dynamic_Table_Generator__c dtgSD = new ECM_Dynamic_Table_Generator__c(Name = 'TEST2', ECM_Object__c = 'ECM_Sales_Driver_Item_Detail__c');
        dtgSD.ECM_Dynamic_Sales_Driver_Item_Column__c = true;
        dtgSD.ECM_Field_API_Names__c = 'ECM_Investment_Amount__c,ECM_Product_Category__c,ECM_Product_Name__c';
        dtgSD.ECM_Dynamic_Fields__c = 'Product Category;Product Name;Investment Amount';
        dtgSD.ECM_Dynamic_Fields_Translation__c = 'A,B,C';
        
        ECM_Dynamic_Table_Generator__c dtgSD1 = dtgSD.clone(false,false,false,false);
        dtgSD1.ECM_Field_API_Names__c = 'ECM_Sales_Driver_Item__r.ECM_Total_Investment_Amount__c';
        dtgSD1.ECM_Dynamic_Fields__c = 'Total Investment Amount';
        dtgSD1.ECM_Dynamic_Sales_Driver_Item_Column__c = false;
        
        ECM_Dynamic_Table_Generator__c dtgOC = new ECM_Dynamic_Table_Generator__c(Name = 'TEST', ECM_Object__c='Outlet_Contract__c');
        dtgOC.ECM_Dynamic_Sales_Driver_Item_Column__c = true;
        dtgOC.ECM_Field_API_Names__c = 'ECM_Outlet_Name__c,ECM_Outlet_Street__c,ECM_Outlet_City__c,ECM_Outlet_State__c';
        dtgOC.ECM_Dynamic_Fields__c = 'Outlet Name;Outlet Street;Outlet City;Outlet State;';
        List<ECM_Dynamic_Table_Generator__c> dtgList = new List<ECM_Dynamic_Table_Generator__c>{dtgCI, dtgCI1, dtgSD, dtgSD1, dtgOC};
            
            for(ECM_Dynamic_Table_Generator__c dtg:dtgList){
                dtg.ECM_Geography__c = conData.countryId;
            }
        Insert dtgList;
        
        //List of Template Sections with all possible section types
        List<ECM_Template_Section__c> tsList = new List<ECM_Template_Section__c>();
        ECM_Template_Section__c tsRec = new ECM_Template_Section__c(ECM_Title__c = 'Bottle Serve SD - Static', ECM_Active__c = true, ECM_Section_Type__c = 'Signature');
        tsRec.ECM_Dynamic_Text__c = true;
        tsRec.ECM_Sales_Driver__c = sdList[0].id;
        tsRec.ECM_Number_of_signatures__c = 3;
        tsRec.ECM_Text__c='<h1>Bottle Serve</h1> status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsList.add(tsRec);
        
        ECM_Template_Section__c tsRec1 = tsRec.clone(false,false,false,false);
        tsRec1.ECM_Sales_Driver__c = sdList[1].id;
        tsRec1.ECM_Section_Type__c = 'Sales-driver';
        tsRec1.ECM_Text__c = '"Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsList.add(tsRec1);
        
        ECM_Template_Section__c tsRec2 = tsRec.clone(false,false,false,false);
        tsRec2.ECM_Text__c = '"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsList.add(tsRec2);
        
        ECM_Template_Section__c tsRec3 = tsRec.clone(false,false,false,false);
        tsRec3.ECM_Number_of_signatures__c = 0;
        tsRec3.ECM_Text__c = '"Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsList.add(tsRec3);
        
        ECM_Template_Section__c tsRec4 = tsRec3.clone(false,false,false,false);
        tsRec4.ECM_Text__c = '"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsList.add(tsRec4);
        
        ECM_Template_Section__c tsRec5 = tsRec1.clone(false,false,false,false);
        tsRec5.ECM_Dynamic_Text__c = false;
        tsRec5.ECM_Text__c = '"Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsList.add(tsRec5);
        
        ECM_Template_Section__c tsRec6 = tsRec5.clone(false,false,false,false);
        tsRec6.ECM_Text__c = '"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsRec6.ECM_Dynamic_Table_Generator__c = dtgCI.Id;
        tsList.add(tsRec6);
        
        ECM_Template_Section__c tsRec7 = new ECM_Template_Section__c(ECM_Active__c = true, ECM_Dynamic_Text__c = true);
        tsRec7.ECM_Section_Type__c = 'Annex';
        tsRec7.ECM_Dynamic_Table_Generator__c = dtgOC.id;
        tsRec7.ECM_Display_Venue_Info__c = true;
        tsRec7.ECM_Text__c = '"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsRec7.ECM_Title__c = 'Bottle Serve SD - Static 7';
        tsList.add(tsRec7);
        
        ECM_Template_Section__c tsRec8 = new ECM_Template_Section__c(ECM_Active__c = true, ECM_Dynamic_Text__c = false);
        tsRec8.ECM_Section_Type__c = 'Footer';
        tsRec8.ECM_Text__c='"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsRec8.ECM_Title__c='Bottle Serve SD - Static';
        tsList.add(tsRec8);
        
        ECM_Template_Section__c tsRec9 = tsRec7.clone(false,false,false,false);
        tsRec9.ECM_Dynamic_Table_Generator__c = dtgCI.id;
        tsRec9.ECM_Display_Venue_Info__c = false;
        tsList.add(tsRec9);
        
        ECM_Template_Section__c tsRec10 = new ECM_Template_Section__c(ECM_Active__c = true, ECM_Dynamic_Text__c = false);
        tsRec10.ECM_Section_Type__c = 'Product Growth Driver';
        tsRec10.ECM_Product_Growth_Driver__c = pgdId;
        tsRec10.ECM_Text__c = '"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsRec10.ECM_Title__c = 'PGD';
        tsList.add(tsRec10);
        
        ECM_Template_Section__c tsRec11 = tsRec9.clone(false,false,false,false);
        tsRec11.ECM_Dynamic_Table_Generator__c = dtgCI1.id;
        tsList.add(tsRec11);
        
        ECM_Template_Section__c tsRec12 = new ECM_Template_Section__c(ECM_Active__c = true, ECM_Dynamic_Text__c = false);
        tsRec12.ECM_Section_Type__c = 'Annex';
        tsRec12.ECM_Dynamic_Table_Generator__c = dtgSD1.id;
        tsRec12.ECM_Sales_Driver__c = sdList[0].id;
        tsRec12.ECM_Text__c = '"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
        tsRec12.ECM_Title__c = 'Bottle Serve SD';
        tsList.add(tsRec12);
        
        ECM_Template_Section__c tsRec13 = tsRec8.clone(false,false,false,false);
        tsRec13.ECM_Section_Type__c = 'Body';
        tsRec13.ECM_Legal_T_C_section__c = true;
        tsList.add(tsRec13);
        //Iteration
        for(Integer i=0; i<10; i++){
            ECM_Template_Section__c tsAnnx = new ECM_Template_Section__c(ECM_Active__c = true, ECM_Dynamic_Text__c = true, ECM_Sales_Driver__c = sdList[0].id);
            tsAnnx.ECM_Section_Type__c='Annex';
            tsAnnx.ECM_Display_Venue_Info__c = false;
            if(i<5){
                tsAnnx.ECM_Text__c='"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.';
            }
            else {
                tsAnnx.ECM_Text__c='<h1>"{!Bottle Serve"</h1> status means you must have the Product available to be sold by bottle and listed accordingly.';
            }
            tsAnnx.ECM_Title__c='Bottle Serve SD - Static';
            if(i==0){
                tsAnnx.ECM_Dynamic_Table_Generator__c = dtgSD.Id;
            }else {
                tsAnnx.ECM_Dynamic_Table_Generator__c = dtgCI.Id;
            }
            tsList.add(tsAnnx);
        }
        
        for(ECM_Template_Section__c tempSec:tsList){
            tempSec.ECM_Geography__c = conData.countryId;
        }
        insert tsList;
        
        //List of Template Section Maps to add template with template-agreement
        List<ECM_Template_Section_Map__c> tsmList = new List<ECM_Template_Section_Map__c>();
        for(ECM_Template_Section__c ts : tsList){
            ECM_Template_Section_Map__c esTSM = new ECM_Template_Section_Map__c(ECM_Template_Agreement__c = conData.tempAgrmntId, ECM_Template_Section__c = ts.Id, ECM_Sequence_Number__c=1);
            tsmList.add(esTSM);
        }
        insert tsmList;
        
        //List of template subsections
        List<ECM_Template_Sub_Section__c> tsSubSecLst = new List<ECM_Template_Sub_Section__c>();
        ECM_Template_Sub_Section__c tsSubSec = new ECM_Template_Sub_Section__c();
        tsSubSec.ECM_Active__c = true;
        tsSubSec.ECM_Text__c = '<p>testing sub section</p>';
        tsSubSecLst.add(tsSubSec);
        
        ECM_Template_Sub_Section__c tsSubSec1 = new ECM_Template_Sub_Section__c(ECM_Active__c = true, ECM_Section_Type__c = 'Annex');
        tsSubSec1.ECM_Dynamic_Table_Generator__c = dtgCI.id;
        tsSubSec1.ECM_Text__c = '<p>testing sub section</p>';
        tsSubSecLst.add(tsSubSec1);
        
        ECM_Template_Sub_Section__c tsSubSec2 = new ECM_Template_Sub_Section__c(ECM_Active__c = true, ECM_Section_Type__c = 'Sales-driver');
        tsSubSec2.ECM_Sales_Driver__c = sdList[1].Id;
        tsSubSec2.ECM_Text__c = '<h>"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.</h>';
        tsSubSecLst.add(tsSubSec2);
        
        ECM_Template_Sub_Section__c tsSubSec3 = tsSubSec1.clone(false,false,false,false);
        tsSubSec3.ECM_Dynamic_Table_Generator__c = dtgSD1.id;
        tsSubSec3.ECM_Text__c = '<h>"{!Bottle Serve" status means you must have the Product available to be sold by bottle and listed accordingly.</h>';
        tsSubSecLst.add(tsSubSec3);
        
        for(ECM_Template_Sub_Section__c subSection: tsSubSecLst){
            subSection.ECM_Geography__c = conData.countryId;
        }
        insert tsSubSecLst;
        
        //List of Template Sub Section Maps to add template-subsection with template
        List<ECM_Template_Sub_Section_Map__c> tsSubSecMpLst = new List<ECM_Template_Sub_Section_Map__c>();
        for(ECM_Template_Sub_Section__c subSc : tsSubSecLst){
            ECM_Template_Sub_Section_Map__c tsSubSecMap = new ECM_Template_Sub_Section_Map__c(Required__c = true, Sequence_Number__c = 1);
            tsSubSecMap.ECM_Template_Sub_Section__c  = subSc.id;
            tsSubSecMap.ECM_Template_Section__c  = tsRec7.id;
            tsSubSecMpLst.add(tsSubSecMap);
        }
        tsSubSecMpLst[2].ECM_Template_Section__c = tsRec6.id;
        insert tsSubSecMpLst;
        
        List<Id> retList = new List<Id>{tsList[0].id, tsSubSecLst[0].Id};
        return retList;  
    }
}