/*
*@Name: ECM_PsPdfController
*@Description: This is class for Vf page -"ECM_PS_PSFGeneration_Validation.vfp" and Aura component -"ECM_SaveAsInvoice.cmp"
*@History                                                                                                                       

VERSION			AUTHOR					DATE				DETAIL
*1.0		Tanishq Banerjee		  24/02/2023         ECM-6767 : Payment Summary Document_Dynamic fields_SFDC
*1.1		Rajarshi Lahiri			  24/02/2023		 ECM-6746 : Payment Summary Document_Templates_SFDC
*1.2		Anshu Prakash			  24/02/2023		 ECM-6768 : Payment Summary Document_Product Table_SFDC
*1.3		Saurav Prasad             24/02/2023         ECM-6750 : Validation on Payment Summary Custom Screen
*1.4		Rajarshi Lahiri			  06/02/2023		 ECM-6792: Payment Summary Document_Text Update_SFDC 
*/
public With Sharing class ECM_PsPdfController {
    
    public ECM_PsPdfController() {
        //ECM-6750
        getPsPdfSetting = new Map<String,ECM_PS_PDF_Settings__mdt>();
    }
    
    public ECM_PsPdfWrapper.HeaderWrapper headervalue{get; set;}
    public ECM_PsPdfWrapper.BodyWrapper bodyWrapperValue{get; set;}
    public ECM_PsPdfWrapper.ProductTableHeaderWrapper productHeaderWrapperValue{get; set;}
    public ECM_PsPdfWrapper.DynamicFields dynamicFieldsValue{get; set;}
    public List<ECM_PsPdfWrapper.PsiWrapperTable> psiValue{get; set;}

    public String conDetContent{get; set;}
    public String paySumDtContent{get; set;}
    public String paySumDetailContent{get; set;}
    
    private Map<String,ECM_PS_PDF_Settings__mdt> getPsPdfSetting{get; set;}
    private List<String> tableHeaderContent{get; set;}
    private List<String> productHeaderContent{get; set;}

    /** 
    * @description	:	PS Pdf Generation
    * @param event	:	ApexPages.standardController
    **/ 
    
    public ECM_PsPdfController(ApexPages.standardController controller){        

        String paySumId;
        getPsPdfSetting = new Map<String,ECM_PS_PDF_Settings__mdt>();
        
        tableHeaderContent = new List<String>();
        productHeaderContent = new List<String>();
        //ECM-6767
        for(ECM_PS_PDF_Settings__mdt pdfSett : ECM_PS_PDF_Settings__mdt.getAll().values()){
            getPsPdfSetting.put(pdfSett.ECM_CountryCode__c+'_'+pdfSett.ECM_Language_for_PDF__c,pdfSett);                
        }
        
        String paramid= System.currentPageReference().getParameters().get('id');

        paySumId = paramid;
        
        ECM_PsPdfWrapper pdfWrapper=new ECM_PsPdfWrapper();
		ECM_Payment_Summary__c paySumObj = ECM_PsPdfControllerHelper.getPsDetails(paySumId);


        List<ECM_Payment_Summary_Item__c> psItems = ECM_PsPdfControllerHelper.getPsItems(paySumObj.Id);
        Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=Invoice.pdf');
        
        System.debug(LoggingLevel.DEBUG,'@@psItems'+psItems);
        pdfWrapper=psPdfGeneration(paySumObj,psItems);
        headervalue=pdfWrapper.headerWrapperValue;
        bodyWrapperValue=pdfWrapper.bodyWrapperValue;
        productHeaderWrapperValue=pdfWrapper.productHeaderWrapperValue;
        psiValue=pdfWrapper.psiWrapperValue;
        dynamicFieldsValue=pdfWrapper.dynamicFieldsValue;

    }
   

    
    /** 
    * @description	:	PS Pdf Generation
    * @param event	:	ECM_Payment_Summary__c,List<ECM_Payment_Summary_Item__c>
    **/ 
    
    private ECM_PsPdfWrapper psPdfGeneration(ECM_Payment_Summary__c psObj,List<ECM_Payment_Summary_Item__c> psItems){
        ECM_PsPdfWrapper psPdfWrapper=new ECM_PsPdfWrapper();
        ECM_PsPdfWrapper.HeaderWrapper headervalue = new ECM_PsPdfWrapper.HeaderWrapper();
        ECM_PsPdfWrapper.BodyWrapper bodyWrapperValue = new ECM_PsPdfWrapper.BodyWrapper();
        ECM_PsPdfWrapper.ProductTableHeaderWrapper productHeaderWrapperValue = new ECM_PsPdfWrapper.ProductTableHeaderWrapper();
        ECM_PsPdfWrapper.DynamicFields dynamicFieldsValue = new ECM_PsPdfWrapper.DynamicFields();
        List<ECM_PsPdfWrapper.PsiWrapperTable> psItemWrap = new List<ECM_PsPdfWrapper.PsiWrapperTable>();
        
        Decimal totalConfAmtCounter=0;
        Decimal totalConfVolCounter=0;
        if(psObj != null){
            List<AccountContactRelation> accContactRelLst = [SELECT Id,Contact.Name FROM AccountContactRelation WHERE Display_Contact__c = true AND AccountId =:psObj.ECM_Contract__r.AccountId WITH SECURITY_ENFORCED];

			setFields(accContactRelLst,psObj,dynamicFieldsValue);
            System.debug(LoggingLevel.DEBUG,'@@@@'+psItemWrap);
            String psKey = psObj.ECM_Contract__r.Account.Country_Code__c+'_'+(psObj.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c!=null ? psObj.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c: '');
            
            for(ECM_Payment_Summary_Item__c psItObj : psItems){
                System.debug(LoggingLevel.DEBUG,'@psItems'+psItems.size());
                ECM_PsPdfWrapper.PsiWrapperTable temp = new ECM_PsPdfWrapper.PsiWrapperTable(psItObj);
                psItemWrap.add(temp);
				totalConfAmtCounter += psItObj.ECM_Confirmed_Amount_Per_Payment__c != null?psItObj.ECM_Confirmed_Amount_Per_Payment__c:0;
				totalConfVolCounter += psItObj.ECM_Confirmed_Volume__c != null?psItObj.ECM_Confirmed_Volume__c:0;              
            }
            
            bodyWrapperValue.totalConfAmt=totalConfAmtCounter.setScale(2).format();
            bodyWrapperValue.totalConfVol=totalConfVolCounter.setScale(2).format();
            
            if(!getPsPdfSetting.isEmpty() && getPsPdfSetting.containsKey(psKey)){               
                populateGlobalFields(psKey,dynamicFieldsValue,bodyWrapperValue);
                setHeaderGlobalValues(headervalue,productHeaderWrapperValue);
            }
           psPdfWrapper.headerWrapperValue= headervalue;
           psPdfWrapper.bodyWrapperValue=bodyWrapperValue;
           psPdfWrapper.productHeaderWrapperValue=productHeaderWrapperValue;
           psPdfWrapper.psiWrapperValue=psItemWrap;
           psPdfWrapper.dynamicFieldsValue=dynamicFieldsValue;

        }
        return psPdfWrapper;
    }
    
    /** 
		* @description	:	Populates Billing Details
		* @return		:	String, ECM_PsPdfWrapper.DynamicFields
		* @param event	:	String
	**/
    private String populateBillingDetails(String billingDetails, ECM_PsPdfWrapper.DynamicFields dynamicFieldsValue){ 
        
        //System.debug(LoggingLevel.DEBUG,'@@legal'+cusLegalName);
        billingDetails=billingDetails.replace('{!Account.LegalName}' , dynamicFieldsValue.cusLegalName);
        billingDetails=billingDetails.replace('{!Account.BillingStreet}',dynamicFieldsValue.accBillStrt);
        billingDetails=billingDetails.replace('{!Account.BillingPostal Code}',dynamicFieldsValue.accBillPostCode);
        billingDetails=billingDetails.replace('{!Account.BillingCity}',dynamicFieldsValue.accBillCity);
        billingDetails=billingDetails.replace('{!Contact Full Name}',dynamicFieldsValue.contactName);
        return billingDetails;
    }
    
    /** 
		* @description	:	Populates Header in the 1st table of the invoice pdf
		* @return		:	ECM_PsPdfWrapper.HeaderWrapper
		* @param event	:	ECM_PsPdfWrapper.HeaderWrapper,List<String>
	**/ 
    private ECM_PsPdfWrapper.HeaderWrapper populateHeaderValue(ECM_PsPdfWrapper.HeaderWrapper headervalue,List<String> tableHeaderContent){
        headervalue.newVat=tableHeaderContent[0];
        headervalue.legacyFrontOffice=tableHeaderContent[1];
        headervalue.accountPhone=tableHeaderContent[2];
        headervalue.bank=tableHeaderContent[3];
        headervalue.iban=tableHeaderContent[4];
        headervalue.bic=tableHeaderContent[5];
        return headervalue;
    }
    
    /** 
		* @description	:	Populates Product Header in the 2nd table of the invoice pdf
		* @return		:	ECM_PsPdfWrapper.ProductTableHeaderWrapper
		* @param event	:	ECM_PsPdfWrapper.ProductTableHeaderWrapper,List<String>
	**/
    private ECM_PsPdfWrapper.ProductTableHeaderWrapper populateHeaderWrapperValue(ECM_PsPdfWrapper.ProductTableHeaderWrapper productHeaderWrapperValue, List<String> productHeaderContent){
        productHeaderWrapperValue.brandName=productHeaderContent[0];
        productHeaderWrapperValue.productName=productHeaderContent[1];
        productHeaderWrapperValue.quantity=productHeaderContent[2];
        productHeaderWrapperValue.bonusPerBottle=productHeaderContent[3];
        productHeaderWrapperValue.totalBonus=productHeaderContent[4];
        productHeaderWrapperValue.totalsLabel=productHeaderContent[5]; 
        return productHeaderWrapperValue;
    }
    
    /** 
            * @description	:	Setting dynamic field values
            * @return		:	void
            * @param event	:	List<AccountContactRelation>,ECM_Payment_Summary__c,ECM_PsPdfWrapper.DynamicFields
    **/
    
    private void setFields(List<AccountContactRelation> accContactRelLst,ECM_Payment_Summary__c psObj,ECM_PsPdfWrapper.DynamicFields dynamicFieldsValue){
        	dynamicFieldsValue.contactName='';
            if(!accContactRelLst.isEmpty()){
                for(AccountContactRelation accConRel:accContactRelLst){
                    dynamicFieldsValue.contactName += accConRel.Contact.Name + ',';
                }                
            }
            //ECM-6767
            dynamicFieldsValue.contactName = dynamicFieldsValue.contactName!=''?dynamicFieldsValue.contactName.removeEnd(','):'';                                    
            setAccntFields(psObj,dynamicFieldsValue);
        	setConPSFields(psObj,dynamicFieldsValue);
    }
    
    /** 
            * @description	:	setting account field values
            * @return		:	void
            * @param event	:	ECM_Payment_Summary__c,ECM_PsPdfWrapper.DynamicFields
    **/
    private void setAccntFields(ECM_Payment_Summary__c psObj,ECM_PsPdfWrapper.DynamicFields dynamicFieldsValue){
        dynamicFieldsValue.cusLegalName = psObj.ECM_Contract__r.Account.ECM_Legal_Name__c != null?psObj.ECM_Contract__r.Account.ECM_Legal_Name__c:'';
        dynamicFieldsValue.taxNumber = psObj.ECM_Contract__r.Account.New_VAT__c != null?psObj.ECM_Contract__r.Account.New_VAT__c:'';
        dynamicFieldsValue.customerNumber = psObj.ECM_Contract__r.Account.Legacy_Front_Office_Account_No__c != null?psObj.ECM_Contract__r.Account.Legacy_Front_Office_Account_No__c:'';
        dynamicFieldsValue.telephoneNo = psObj.ECM_Contract__r.Account.Phone != null?psObj.ECM_Contract__r.Account.Phone:'';
        dynamicFieldsValue.accBillStrt = psObj.ECM_Contract__r.Account.BillingStreet != null?psObj.ECM_Contract__r.Account.BillingStreet:'';
        dynamicFieldsValue.accBillPostCode = psObj.ECM_Contract__r.Account.BillingPostalCode != null?psObj.ECM_Contract__r.Account.BillingPostalCode:'';
        dynamicFieldsValue.accBillCity = psObj.ECM_Contract__r.Account.BillingCity != null?psObj.ECM_Contract__r.Account.BillingCity:'';
    }
    
    /** 
            * @description	:	setting contract & payment summary field values
            * @return		:	void
            * @param event	:	ECM_Payment_Summary__c,ECM_PsPdfWrapper.DynamicFields
    **/
    private void setConPSFields(ECM_Payment_Summary__c psObj,ECM_PsPdfWrapper.DynamicFields dynamicFieldsValue){
        dynamicFieldsValue.conOwnrName = psObj.ECM_Contract__r.ECM_Contract_Owner__c != null?psObj.ECM_Contract__r.ECM_Contract_Owner__c:'';
        dynamicFieldsValue.conOwnrEmail = psObj.ECM_Contract__r.Owner.Email != null?psObj.ECM_Contract__r.Owner.Email:'';
        dynamicFieldsValue.conName = psObj.ECM_Contract__r.Name != null?psObj.ECM_Contract__r.Name:'';
        dynamicFieldsValue.paySumNumber = psObj.Name != null?psObj.Name:'';
        dynamicFieldsValue.conNumber = psObj.ECM_Contract__r.ContractNumber != null?psObj.ECM_Contract__r.ContractNumber:'';            
        dynamicFieldsValue.conStrtDt = psObj.ECM_Contract__r.StartDate != null?((Datetime)psObj.ECM_Contract__r.StartDate).format('dd/MM/yyyy'):'';
        dynamicFieldsValue.paySumStrtDt = psObj.ECM_Start_Period__c != null?((Datetime)psObj.ECM_Start_Period__c).format('dd/MM/yyyy'):'';
        dynamicFieldsValue.paySumEndDt = psObj.ECM_End_Period__c != null?((Datetime)psObj.ECM_End_Period__c).format('dd/MM/yyyy'):'';
    }
    
    /** 
            * @description	:	Populates contract & payment summary field values
            * @return		:	void
            * @param event	:	String,ECM_PsPdfWrapper.DynamicFields,ECM_PsPdfWrapper.BodyWrapper
    **/
    
    private void populateGlobalFields(String psKey,ECM_PsPdfWrapper.DynamicFields dynamicFieldsValue,ECM_PsPdfWrapper.BodyWrapper bodyWrapperValue){
        
        conDetContent=getPsPdfSetting.get(psKey).ECM_Contract_Details_Content__c;
        //ECM-6792-split the text to make contract Number as bold.
        bodyWrapperValue.conDetStart=conDetContent.substringBefore('{!conNumber}')+' ';
        bodyWrapperValue.conDetEnd=conDetContent.substringAfter('{!conNumber}')+' ';
        //bodyWrapperValue.conDetEnd = bodyWrapperValue.conDetEnd.replace('{!conNumber}',dynamicFieldsValue.conNumber);
        bodyWrapperValue.conDetEnd = bodyWrapperValue.conDetEnd.replace('{!contactName}', dynamicFieldsValue.conName);
        bodyWrapperValue.conDetEnd = bodyWrapperValue.conDetEnd.replace('{!conStrtDt}', dynamicFieldsValue.conStrtDt);
		//ECM-6792-Split the text to make start date and end date as bold
        paySumDtContent=getPsPdfSetting.get(psKey).ECM_PS_Date_Content__c;
		bodyWrapperValue.paySumDetailStart=paySumDtContent.substringBefore('{!paySumStrtDt}')+' ';
        bodyWrapperValue.paySumDetailEnd=paySumDtContent.substringAfter('{!paySumStrtDt}');
        bodyWrapperValue.paySumDetailEnd=bodyWrapperValue.paySumDetailEnd.substringBefore('{!paySumEndDt}')+' ';
        paySumDetailContent = getPsPdfSetting.get(psKey).ECM_PS_Details_Content__c;
        
        paySumDetailContent = paySumDetailContent.replace('{!paySumNumber}', dynamicFieldsValue.paySumNumber);
        
        bodyWrapperValue.endContent = getPsPdfSetting.get(psKey).ECM_Conclusion_Content__c+' '+getPsPdfSetting.get(psKey).ECM_Conclusion_end_content__c;
        
        bodyWrapperValue.tableHeading = getPsPdfSetting.get(psKey).ECM_Table_Header__c;
        tableHeaderContent = getPsPdfSetting.get(psKey).ECM_First_Table_Content__c.split(',');
        productHeaderContent = getPsPdfSetting.get(psKey).ECM_Product_Table_Content__c.split(',');
        
        bodyWrapperValue.pdfHeading=getPsPdfSetting.get(psKey).ECM_PDF_Heading__c;
        bodyWrapperValue.psPDFHeaderSec=getPsPdfSetting.get(psKey).ECM_PS_PDF_Header_section__c;
        
        String billingDetails=getPsPdfSetting.get(psKey).ECM_Billing_Details_Section__c;
        billingDetails = populateBillingDetails(billingDetails,dynamicFieldsValue);
        
        bodyWrapperValue.psPDFHeaderSec+=getPsPdfSetting.get(psKey).ECM_Enable_Contract_Owner_Info__c?'\n'+dynamicFieldsValue.conOwnrName:'';
        bodyWrapperValue.psPDFHeaderSec+=getPsPdfSetting.get(psKey).ECM_Enable_Contract_Owner_Info__c?'\n'+dynamicFieldsValue.conOwnrEmail:'';
        bodyWrapperValue.billingDetails=billingDetails;

    }
    
    /** 
            * @description	:	Setting headervalues & productTableHeader values
            * @return		:	void
            * @param event	:	ECM_PsPdfWrapper.HeaderWrapper,ECM_PsPdfWrapper.ProductTableHeaderWrapper
    **/
    private void setHeaderGlobalValues(ECM_PsPdfWrapper.HeaderWrapper headervalue,ECM_PsPdfWrapper.ProductTableHeaderWrapper productHeaderWrapperValue){                
        headervalue = populateHeaderValue(headervalue, tableHeaderContent);        
        productHeaderWrapperValue = populateHeaderWrapperValue(productHeaderWrapperValue, productHeaderContent);
    }
}