/*
* Class Name: ECM_GetContractItemDetails
* Test Class: ECM_ReviewAndSubmitControllerTest
* Author: 
* Brief Description: This class is to fetch details used in Email for VF components.
* Created Date: 
* History: 
VERSION    AUTHOR                DATE              DETAIL
1.0												Initial Development
1.1		Saurav Prasad			23/03/2022		ECM-5358  Contract rejection email to Sales Rep_SFDC_GLO
1.2		Manikandan T			24/03/2022		ECM-5359  Payment summary rejection email to Sales Rep_SFDC_GLO
1.3     Vinay Tummala           28/04/2022      ECM-5478  Notification to Approvers of Parent Contract_Recall_SFDC_GLO
1.4     Suvendu                 27/05/2022      ECM-5627  POC _Approval Email table to Configurable_EU
1.5     Suvendu                 24/06/2022      ECM-5623  Renaming Of KPIs in the Approval Mails
1.6		Nikhilesh Chandak		24/06/2022		ECM-5458  Added Primary and Secondary Spirit Distributor and Beer Distributor in Contract Header Details 
1.7     Vinay                   05/08/2022      ECM-5913  Approval Mail _ Totals Column
1.8		Nikhilesh Chandak		13/09/2022		ECM-5952  Approval Mail Body_Columns to be Market configurable
1.9     Anamika Shukla          09/05/2024		366446    EDGE_Global: Allow Only Trusted Cross-Org Redirections
*/
public with sharing  class ECM_GetContractItemDetails {
    public ID targetObjectId { get; set; }    
    public list<string> contHeader { get;set; } 
    public list<string> sdidHeaders   { get;set; } 
    public list<string> InvSumHeader { get;set; } 
    public Boolean isSpirits { get;set; } 
    public Boolean isBeer { get;set; }
    public Boolean isTotal {get;set;}//ECM-5952
    //ECM-5358
    public ID approvalLogId { get; set; }
    
    public List<ECM_Contract_Item__c> getContractItems() {
        List<ECM_Contract_Item__c> contractItems;
        contractItems= [SELECT Id, Name, ECM_Contract__c, ECM_Lead_Brand__c, ECM_Product__c, ECM_Product__r.Name, ECM_Product__r.Product__r.Brand_Name__c,ECM_Retro_investment__c,
                        ECM_Trade_investment__c,ECM_A_P_investment__c,ECM_Gross_margin__c,ECM_Gross_Profit__c,ECM_NSV__c,ECM_Trade_investments__c,ECM_AnP_investment__c,
                        ECM_Product__r.Product__r.Name, ECM_Volume__c,ECM_Total_GP__c FROM ECM_Contract_Item__c WHERE ECM_Contract__c = :targetObjectId];
        return contractItems;         
    }  
    public List<Outlet_Contract__c > getOutletContracts() {
        List<Outlet_Contract__c> outletContracts;
        outletContracts= [SELECT Outlet__r.Name FROM Outlet_Contract__c WHERE Contract__c  = :targetObjectId];
        return outletContracts;         
    }   
    
    public List<ECM_Sales_Driver_Item__c> getSalesDriver()
    {
        List<ECM_Sales_Driver_Item__c> salesdriverobj;
        salesdriverobj= [SELECT Id, Name, Contract__c, ECM_Sales_Driver__c, ECM_Sales_Driver_Name__c,ECM_Sales_Driver__r.Name,ECM_Investement_Description__c FROM ECM_Sales_Driver_Item__c WHERE Contract__c=: targetObjectId ];
        return salesdriverobj;
    }
    public Id getAccountId()
    {   
        Id accId = [SELECT AccountId FROM Contract WHERE ID=: targetObjectId LIMIT 1].AccountId;        
        return accId;
    }
    public Contract getContractDetails()
    {
        Contract contractobj;
        contractobj= [SELECT Id, Name ,ECM_Amended__c,ContractNumber,Account.Name,Account.Person_Responsible__r.Name, Venue_Type__c , ECM_Duration__c , ECM_Actual_Cases_Per_Year_OnPremise__c , ECM_Hybrid_Actual_Cases_PerYear__c , ECM_UOS_Per_Year_Onpremise__c , ECM_Hybrid_UOS_PerYear__c , ECM_Gross_Profit_Bef_TI_Per_Yer_Onpremis__c , ECM_Hybrid_GP_BeforTI_PerYear__c , ECM_Gross_Profit_After_TI_Per_Year_Onpre__c , ECM_Hybrid_GP_AfterTI_PerYear__c ,Createdby.Name,ECM_Agreement_Type__r.Name,StartDate, LastModifiedBy.Name,
                      ECM_Hybrid_Total_A_P_PerUOS__c ,ECM_Hybrid_UOS_PerTerm__c ,ECM_UOS_Over_Term_Onpremise__c ,ECM_Hybrid_Actual_Cases_OverTerm__c ,ECM_Actual_Cases_Over_Term_Onpremise__c ,ECM_Hybrid_CustInvest_Total_PerTerm__c ,ECM_Customer_Investment_TotOver_onpremi__c ,ECM_Hybrid_NSV_AfterTI_PerTerm__c ,ECM_Net_Sales_Value_AfterTI_Over_Onpremi__c ,ECM_Hybrid_GMPercent_PerTerm__c ,ECM_GM_Over_Term_Onpremise__c ,ECM_Hybrid_COGS_PerTerm__c ,ECM_COGS_Over_Term_Onpremise__c ,ECM_Hybrid_GP_AfterTI_PerTerm__c ,ECM_Hybrid_GP_BeforeTI_PerTerm__c ,ECM_Gross_Profit_After_TI_Over_Term_Onpr__c ,ECM_Gross_Profit_Before_TI_Over_Onpremis__c ,AccountId,ECM_Hybrid_Total_A_P_PerYear__c ,Available_AP_Spend__c , Status, OwnerId, RecordTypeId, RecordType.Name, ECM_Territory__c, ECM_Territory__r.Name, ECM_Total_A_P_Investment__c,ECM_Generated_NSV__c, ECM_COGS_Per_Year_Onpremise__c, ECM_Hybrid_COGS_PerYear__c, ECM_GM_Per_Year_Onpremise__c,
                      ECM_Total_GP__c, ECM_Fixed_share__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ECM_EU_Total_Trade_Investment__c,ECM_Variable_share__c,ECM_Overall_Investment_Figure__c, ECM_Hybrid_GMPercent_PerYear__c, AP_Spent__c, ECM_A_P_RollOver__c,
                      ECM_of_the_total_investment_vs_NSV__c, ECM_Hybrid_NSV_AfterTI_PerYear__c ,ECM_Net_Sales_Value_After_TI_PerYea_Opre__c,ECM_GM_reserve_share__c,ECM_GM_innovation_share__c,ECM_GM_premium_core_share__c,ECM_GM_local_priority_brand_share__c,
                      ECM_GP_reserve_share__c,ECM_GP_innovation_share__c,ECM_GP_premium_core_share__c,ECM_GP_local_priority_brand_share__c,ECM_NSV_local_priority_brand_share__c,ECM_Total_TI_Investment__c,
                      ECM_NSV_premium_core_share__c,ECM_NSV_innovation_share__c,ECM_NSV_reserve_share__c,ECM_CAP_ROI__c,ECM_GP_ROI__c,ECM_Customer_Investment_TotalGP_Onpremis__c ,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                      ECM_Agreement_Type__c,ECM_Customer_Investment_TotalPer_Onpremi__c , ECM_Hybrid_CustInvest_Total_PerYear__c, ECM_Overall_Investment_Amount__c, ECM_RTD_Sales_driver__c, Contract_End_Date__c,ECM_Additional_info_to_support_decision__c,ECM_Current_A_P_Unspent__c
                      ,ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.ContractNumber,ECM_Parent_Contract__r.Name
                      FROM Contract WHERE Id=: targetObjectId];
        return contractobj;
    }
	/*
	Method name : getContHeaderDetails
	User story  : ECM-3939 Table generation for email body_Logic_EU_Contract Approval
	*/
    public List<lightningTableWrapper> getContHeaderDetails()
    {
        
        List<String> fieldlistdum = new List<String>();
        string sobjectName='Contract';
        Contract contObj = new Contract();		 
        List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
        try{
            Contract conobj;
            conobj= [SELECT Id, Account.Country__c FROM Contract WHERE Id=: targetObjectId];
            Set<Id> geoCountry = new Set<Id>();
            geoCountry.add(conobj.Account.Country__c);
            
            Market_Setting__c marketObj = new Market_Setting__c();
            marketObj = [SELECT Id, Name,Geography__c,ECM_Contract_Header_Details__c FROM Market_Setting__c WHERE Geography__c IN : geoCountry];
            System.debug('market'+marketObj);
            if(marketObj.ECM_Contract_Header_Details__c!=null){
                List<String> selectfields = new List<String>();
                selectfields = marketObj.ECM_Contract_Header_Details__c.split(';'); 
                //ECM-5458 - Added Distributor values to fieldConversion
                Map<String, String> fieldConversion = new Map<String, String>{
                    'ECM_Contract_Owner__c' => 'Contract created by',
                        'ECM_Territory__r.Name' => 'Territory',
                        'Account.ECM_Legal_Name__c'=>'Customer name',
                        'Account.Name'=>'Outlet name',
                        'ECM_Agreement_Type__r.Name'=>'Agreement type',
                        'StartDate'=>'Start date',
                        'Account.SAP_Ship_to__c'=>'SAP Ship to',
                        'Account.SAP_Sold_to__c'=>'SAP Sold to',
                        'Contract_End_Date__c'=>'End date',
                        'ContractNumber'=>'Contract number',
                        'Name'=>'Contract Name',
                        'ECM_Primary_Spirit_Distributor__r.Name'=>'Primary Spirit Distributor',
                        'ECM_Secondary_Spirit_Distributor__r.Name'=>'Secondary Spirit Distributor',
                        'ECM_Primary_Beer_Distributor__r.Name'=>'Primary Beer Distributor'
                        };
                Map<String,String> labelToApiName = new Map<String,String>();
                for (String field : selectfields){               
                    if(fieldConversion.containsKey(field)){
                        labelToApiName.put(fieldConversion.get(field),field);
                    }
                }
                fieldlistdum =new List<String>(labelToApiName.keySet());
                string queryStr;
                for(string fieldapi : labelToApiName.values()){
                    queryStr =queryStr==Null? fieldapi:queryStr+','+fieldapi;
                }
                queryStr = 'Select ECM_Outlets_selected__c,RecordType.Name,' + queryStr + ' FROM Contract Where Id=\''+ conobj.Id + '\'';
                contObj = database.query(queryStr);
                Map<String, String> labelToApiMap = new Map<String, String>();
                labelToApiMap.PutAll(labelToApiName);              
                lightningTableWrapper ltw = new lightningTableWrapper();
                List<ObjValues> objvalList = new List<ObjValues>();
                for(string labelName: labelToApiMap.keySet()){
                    if(labelToAPIName.containskey(labelName)){
                        ObjValues objval = new ObjValues();
                        objval.header = labelName;
                        if(labelName =='Territory'){
                            objval.values = String.valueof(contObj.ECM_Territory__r.Name);
                        }else if(labelName =='Customer name'){
                            objval.values = String.valueof(contObj.Account.ECM_Legal_Name__c);
                        }else if(labelName =='Outlet name'){
                            if(contObj.RecordType.Name =='Outlet'){
                                objval.values = String.valueof(contObj.Account.Name);
                            }else if(contObj.RecordType.Name =='Group'){
                                objval.values = String.valueof(contObj.ECM_Outlets_selected__c);
                            }
                        }else if(labelName =='Agreement type'){
                            objval.values = String.valueof(contObj.ECM_Agreement_Type__r.Name);
                        }
                        else if(labelName =='SAP Ship to'){
                            objval.values = String.valueof(contObj.Account.SAP_Ship_to__c);
                        }
                        else if(labelName =='SAP Sold to'){
                            objval.values = String.valueof(contObj.Account.SAP_Sold_to__c);
                        }
                        else if(labelName =='Primary Spirit Distributor'){
                            objval.values = String.valueof(contObj.ECM_Primary_Spirit_Distributor__r.Name);
                            objval.values = String.isBlank(objval.values)? System.Label.ECM_None : objval.values;
                        }
                        else if(labelName =='Secondary Spirit Distributor'){
                            objval.values = String.valueof(contObj.ECM_Secondary_Spirit_Distributor__r.Name);
                            objval.values = String.isBlank(objval.values)? System.Label.ECM_None : objval.values;
                        }
                        else if(labelName =='Primary Beer Distributor'){
                            objval.values = String.valueof(contObj.ECM_Primary_Beer_Distributor__r.Name);
                            objval.values = String.isBlank(objval.values)? System.Label.ECM_None : objval.values;
                        }
                        else{
                            objval.values = String.valueof(contObj.get(labelToApiMap.get(labelName)));  
                        }
                        objvalList.add(objval);
                    }							
                }
                System.debug(objvalList);
                ltw.tablerows = objvalList;
                listLgtnTableWraps.add(ltw);
                contHeader = fieldlistdum;
            }
        } 
        catch (Exception contractException) {
            System.debug('Class:ECM_GetContractItemDetails\nmethod:getContHeaderDetails\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
            
        }
        return listLgtnTableWraps;
        
    }
    /*
	Method name : getInvSumDetails
	User story  : ECM-3939 Table generation for email body_Logic_EU_Contract Approval
	*/
    public List<lightningTableWrapper> getInvSumDetails()
    {
        Contract contObj = new Contract();		 
        List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
        try{
            List<String> selectfields = new List<String>();
            List<String> investmentSummaryColumns = new List<String>();
            Boolean isBeerColumn=false,isSpiritColumn=false;
            contObj=[SELECT Id,Account.Country_Code__c,ECM_of_A_P_vs_NSV__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_Overall_Investment_Figure__c,
                     ECM_Total_Volume_Target_Spirits__c,ECM_Incremental_Volume_Spirits__c,ECM_Incremental_NSV_Spirits__c,ECM_Total_trade_investment_Spirits__c,
                     ECM_Total_A_P_Investment_Spirits__c,ECM_Incremental_GP_ROI__c,ECM_Incremental_GP_CAAP__c,ECM_Incremental_GP_CAAP_ROI__c,ECM_Incremental_GP_Beers__c,
                     ECM_Incremental_GP__c,ECM_Total_GP__c,ECM_Total_Volume_Target_Beers__c,ECM_Total_Volume_Target__c,ECM_Incremental_Volume_Beers__c,ECM_Incremental_NSV_Beers__c,
                     ECM_Total_trade_investment_Beers__c,ECM_EU_Total_Trade_Investment__c,ECM_Total_A_P_Investment_Beers__c,ECM_Total_A_P_Investment__c,ECM_Incremental_GP_ROI_Beers__c,
                     ECM_Incremental_GP_CAAP_Beers__c,ECM_Incremental_GP_CAAP_ROI_Beers__c,ECM_Overall_investments__c,ECM_Total_GM__c,
                     ECM_of_A_P_vs_NSV_Inc_Indirect_Inv__c 
                     FROM Contract 
                     WHERE Id=: targetObjectId]; 
            List<ECM_Contract_KPI__c> conKpi = new List<ECM_Contract_KPI__c>();
            //ECM-5913
            conKpi = [SELECT ECM_EU_Volume__c,ECM_Total_NSV__c,ECM_CAAP__c,ECM_NSV_EU__c,ECM_Trade_Investment_EU__c,
                      ECM_CAAP_Percentage__c,ECM_CAAP_ROI_Percentage__c 
                      FROM ECM_Contract_KPI__c 
                      WHERE ECM_Contract__c =: contObj.Id 
                      AND ECM_Type__c ='Total'];
            //Added for ECM_5627
            
            //ECM-5952 : Modified Query and Check for Null Values
            List<ECM_Technical_Market_Setting__mdt> investSummKPIsFieldNameList =[SELECT ECM_Investment_Summary_KPIs_Fields__c,ECM_Investment_Summary_KPI_Columns__c FROM ECM_Technical_Market_Setting__mdt where ECM_Country__c =:contObj.Account.Country_Code__c];
            if(!investSummKPIsFieldNameList.isEmpty()){
            	if(String.isNotBlank(investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPI_Columns__c) && String.isNotBlank(investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPIs_Fields__c)){
                    selectfields=investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPIs_Fields__c.split(',');
                    investmentSummaryColumns=investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPI_Columns__c.split(',');
                }
            }
            
            //ECM-5952
            if(!investmentSummaryColumns.isEmpty()){
                isTotal = investmentSummaryColumns.contains('Total');
                isBeerColumn = investmentSummaryColumns.contains('Total Beer');
                isSpiritColumn = investmentSummaryColumns.contains('Total Spirit');
            }
            
            if((contObj.ECM_Total_Volume_Target_Spirits__c>0 ||contObj.ECM_Incremental_Volume_Spirits__c>0 ||contObj.ECM_Incremental_NSV_Spirits__c>0 ||contObj.ECM_Total_trade_investment_Spirits__c>0 ||contObj.ECM_Total_A_P_Investment_Spirits__c>0 ||contObj.ECM_Incremental_GP__c>0 ||contObj.ECM_Incremental_GP_ROI__c>0 ||contObj.ECM_Incremental_GP_CAAP__c>0 ||contObj.ECM_Incremental_GP_CAAP_ROI__c>0) && isSpiritColumn){
                isSpirits = true;
            }else{
                isSpirits = false;
            }
            if((contObj.ECM_Total_Volume_Target_Beers__c>0 ||contObj.ECM_Incremental_Volume_Beers__c>0 ||contObj.ECM_Incremental_NSV_Beers__c>0 ||contObj.ECM_Total_trade_investment_Beers__c>0 ||contObj.ECM_Total_A_P_Investment_Beers__c>0 ||contObj.ECM_Incremental_GP_Beers__c>0 ||contObj.ECM_Incremental_GP_ROI_Beers__c>0 ||contObj.ECM_Incremental_GP_CAAP_Beers__c>0 ||contObj.ECM_Incremental_GP_CAAP_ROI_Beers__c>0) && isBeerColumn){
                isBeer = true;            
            }else{
                isBeer = false;
            }         
            lightningTableWrapper ltw = new lightningTableWrapper();
            List<ObjValues> objvalList = new List<ObjValues>();
            if(!selectfields.isEmpty()){
                for(string labelName: selectfields){
                    ObjValues objval = new ObjValues();
                    objval.header = labelName;
                    if(labelName =='Total Forecast Volume'){
                        objval.values = String.valueof(contObj.ECM_Total_Volume_Target_Spirits__c);
                        objval.beer = String.valueof(contObj.ECM_Total_Volume_Target_Beers__c);
                        objval.totals = String.valueof(contObj.ECM_Total_Volume_Target__c);
                        if(contObj.Account.Country_Code__c == 'AU'){ //Added for ECM-4917
                            objval.header = 'Total Volume target';
                        }
                    }else if(labelName =='Incremental Volume'){
                        objval.values = String.valueof(contObj.ECM_Incremental_Volume_Spirits__c);
                        objval.beer = String.valueof(contObj.ECM_Incremental_Volume_Beers__c);
                        objval.totals = String.valueof(contObj.ECM_Incremental_Volume_Spirits__c+contObj.ECM_Incremental_Volume_Beers__c);
                    }else if(labelName =='Incremental NSV'){
                        objval.values = String.valueof(contObj.ECM_Incremental_NSV_Spirits__c);
                        objval.beer = String.valueof(contObj.ECM_Incremental_NSV_Beers__c);
                        objval.totals = String.valueof(contObj.ECM_Incremental_NSV_Spirits__c+contObj.ECM_Incremental_NSV_Beers__c);
                    }else if(labelName =='Total Trade Investment'){
                        objval.values = String.valueof(contObj.ECM_Total_trade_investment_Spirits__c);
                        objval.beer = String.valueof(contObj.ECM_Total_trade_investment_Beers__c);
                        objval.totals = String.valueof(contObj.ECM_EU_Total_Trade_Investment__c);
                    }else if(labelName =='Total A&P Investment'){
                        objval.values = String.valueof(contObj.ECM_Total_A_P_Investment_Spirits__c);
                        objval.beer = String.valueof(contObj.ECM_Total_A_P_Investment_Beers__c);
                        objval.totals = String.valueof(contObj.ECM_Total_A_P_Investment__c);
                    }else if(labelName =='Incremental GP'){
                        objval.values = String.valueof(contObj.ECM_Incremental_GP__c);
                        objval.beer = String.valueof(contObj.ECM_Incremental_GP_Beers__c);
                        objval.totals = String.valueof(contObj.ECM_Incremental_GP_Beers__c+contObj.ECM_Incremental_GP__c);
                    }else if(labelName =='Incremental GP ROI%'){
                        objval.values = String.valueof(contObj.ECM_Incremental_GP_ROI__c) + '%';
                        objval.beer = String.valueof(contObj.ECM_Incremental_GP_ROI_Beers__c) + '%';
                        objval.totals = String.valueof(contObj.ECM_GP_ROI__c) + '%';
                    }else if(labelName =='Incremental CAAP'){
                        objval.values = String.valueof(contObj.ECM_Incremental_GP_CAAP__c);
                        objval.beer = String.valueof(contObj.ECM_Incremental_GP_CAAP_Beers__c);
                        objval.totals = String.valueof(contObj.ECM_Incremental_GP_CAAP__c+contObj.ECM_Incremental_GP_CAAP_Beers__c);
                    }else if(labelName =='Incremental CAAP ROI%'){
                        objval.values = String.valueof(contObj.ECM_Incremental_GP_CAAP_ROI__c) + '%';
                        objval.beer = String.valueof(contObj.ECM_Incremental_GP_CAAP_ROI_Beers__c) + '%';
                        objval.totals = String.valueof(contObj.ECM_CAP_ROI__c) + '%';
                    }else if(labelName =='Total Investment'){    //ECM-5913
                        objval.totals = String.valueof(contObj.ECM_Overall_Investment_Figure__c);
                    }else if(labelName == 'Gross Profit'){
                        objval.totals = String.valueof(contObj.ECM_Total_GP__c);
                    }else if(labelName == 'GM%'){
                        objval.totals = String.valueof(contObj.ECM_Total_GM__c)+'%';
                    }else if(labelName == 'A&P/Net NSV%'){
                        objval.totals = String.valueof(contObj.ECM_of_A_P_vs_NSV__c)+'%';
                    } 
                    if(!conKpi.isEmpty()){
                        if(labelName == 'EU Volume'){
                            objval.totals = String.valueof(conKpi[0].ECM_EU_Volume__c);
                        }else if(labelName == 'Total NSV'){
                            objval.totals = String.valueof(conKpi[0].ECM_Total_NSV__c);
                        }else if(labelName == 'CAAP'){
                            objval.totals = String.valueof(conKpi[0].ECM_CAAP__c);
                        }else if(labelName == 'NSV/EU'){
                            objval.totals = String.valueof(conKpi[0].ECM_NSV_EU__c);
                        }else if(labelName == 'Trade Investment/EU'){
                            objval.totals = String.valueof(conKpi[0].ECM_Trade_Investment_EU__c);
                        }else if(labelName == 'CAAP%'){
                            objval.totals = String.valueof(conKpi[0].ECM_CAAP_Percentage__c)+'%';
                        }else if(labelName == 'CAAP ROI%'){
                            objval.totals = String.valueof(conKpi[0].ECM_CAAP_ROI_Percentage__c)+'%';
                        }  
                    }//ECM-5913
                    
                    objvalList.add(objval);
                    
                }
                
            }
            ltw.tablerows = objvalList;
            listLgtnTableWraps.add(ltw);
            InvSumHeader = selectfields;
        } 
        catch (Exception contractException) {
            System.debug('Class:ECM_GetContractItemDetails\nmethod:getInvSumDetails\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
            
        }
        return listLgtnTableWraps;
        
    }
    /*
     @description	:	ECM-4689 Email Templates for Product level investment exceeding threshold
	 @Method name	:	getProductDetails
	 @Developer	:	Saurav Prasad
	 @Date		:	06/08/2021
	 */
    public List<lightningTableWrapper> getProductDetails(){
        
        List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
        try{
            Contract contractRecord = [SELECT Id, ECM_Agreement_Type__c,Account.Country__c FROM Contract WHERE Id=: targetObjectId];
            Market_Setting__c marketObj = new Market_Setting__c();
            marketObj = [SELECT Id, Name,Geography__c,ECM_Sales_Driver_Item_Details__c FROM Market_Setting__c WHERE Geography__c = : contractRecord.Account.Country__c];
            if(marketObj.ECM_Sales_Driver_Item_Details__c!=null){
                List<String> selectfields = new List<String>();
                selectfields = marketObj.ECM_Sales_Driver_Item_Details__c.split(';'); 
                System.debug('selectfields-->'+selectfields);
                
                sdidHeaders = selectfields; //Label.ECM_SDIDApprovalComp_Headers.split(',');
                System.debug('sdidHeaders-->'+sdidHeaders);
                

                Decimal upperLimit = null;
                //Will only have only one Extra Approval of type='Contract Sales Driver Item' to a specific Agreement Type
                for(ECM_Agreement_Approval__c approvalLimit:
                    [SELECT convertCurrency(ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c)
                     FROM ECM_Agreement_Approval__c 
                     WHERE ECM_Extra_Approval__r.ECM_Active__c =TRUE AND
                     ECM_Extra_Approval__r.ECM_Type__c = 'Contract Sales Driver Item' AND
                     ECM_Agreement_Type__c =:contractRecord.ECM_Agreement_Type__c]){
                         upperLimit = approvalLimit.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c;
                     }

                
                if(upperLimit!=null){
                    for(ECM_Sales_Driver_Item_Detail__c SDID:
                        [SELECT Id,ECM_Investment_Amount__c,
                         ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name,
                         ECM_Product__r.ECM_Product_Name__c
                         FROM ECM_Sales_Driver_Item_Detail__c
                         WHERE ECM_Investment_Amount__c >= :upperLimit  AND
                         ECM_Sales_Driver_Item__r.Contract__c =: contractRecord.Id
                         Order by ECM_Investment_Amount__c]){
                             lightningTableWrapper tableData = new lightningTableWrapper();
                             List<ObjValues> objData = new List<ObjValues>();
                             if(selectfields.contains('Product Name')){
                                 ObjValues objval = new ObjValues();
                                 objval.values = SDID.ECM_Product__r.ECM_Product_Name__c;
                                 objData.add(objval);
                             }
                             if(selectfields.contains('Sales Driver')){
                                 ObjValues objval = new ObjValues();
                                 objval.values = SDID.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name;
                                 objData.add(objval);
                             }
                             if(selectfields.contains('Investment')){
                                 ObjValues objval = new ObjValues();
                                 objval.values = String.valueOf(SDID.ECM_Investment_Amount__c);
                                 objData.add(objval);
                             }
                             if(selectfields.contains('Upper Limit Amount')){
                                 ObjValues objval = new ObjValues();
                                 objval.values = String.valueOf(upperLimit);
                                 objData.add(objval);
                             }
                             
                             if(!objData.isEmpty()){
                                 tableData.tablerows = objData;
                                 listLgtnTableWraps.add(tableData);
                             }
                         }  
                }
            }
            
        }catch (Exception contractException) {
            System.debug('Class:ECM_GetContractItemDetails\nmethod:getProductDetails\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
            
        }
        
        return listLgtnTableWraps;
    }
    
    /**
     * @description	:	ECM-5358 Contract rejection email to Sales Rep_SFDC_GLO
	 * @Method name	:	getApprovalLogDetails
	 * @Developer	:	Saurav Prasad
	 * @Date		:	24/03/2022
	 * @return		:	approvalLog
	 * @param		: 	No Parameters
	 * */
    public approvalLog getApprovalLogDetails(){
        
        approvalLog approvalProcessLog= new approvalLog();
        if(approvalLogId.getSObjectType().getDescribe().getName()=='ECM_Payment_Summary__c'){
            List<ECM_Payment_Summary__c> paymentSummarylist=[select id,Name,ecm_contract__r.contractNumber,ecm_contract__r.account.name,ecm_contract__r.owner.name from ecm_payment_summary__c where id=:approvalLogId];
            if(!paymentSummarylist.isEmpty()){
                approvalProcessLog.recipientName=paymentSummarylist[0].ecm_contract__r.owner.name;
                approvalProcessLog.ObjectDetails=System.Label.ECM_Payment_Summary_Name+' '+paymentSummarylist[0].Name+' '+System.Label.ECM_Payment_Summary_Rej_Template+' '+paymentSummarylist[0].ECM_Contract__r.ContractNumber;
                approvalProcessLog.Account=paymentSummarylist[0].ecm_contract__r.account.name;
                
                for(ProcessInstance pInstance: [SELECT Id,TargetObjectId,(SELECT Id, ActorId,Actor.Name,StepStatus,OriginalActorId,comments FROM Steps where StepStatus='Rejected' and ( not comments like '%Approval Request Rejected by%') ) FROM ProcessInstance where TargetObjectId =:approvalLogId order by lastmodifieddate desc]){
                    system.debug('approvalProcessLog.id-->'+pInstance.Id);
                    // for(processInstanceStep pInstanceStep:pInstance.Steps){
                    if(pInstance.Steps!=null && pInstance.Steps.size()>0){
                        processInstanceStep pInstanceStep=pInstance.Steps[0];
                        system.debug('.Comments-->'+pInstanceStep.Comments);
                        if(pInstanceStep.StepStatus==Label.ECM_Payment_Summary_Rejected && (pInstanceStep.comments==null || (pInstanceStep.comments !=null && !pInstanceStep.comments.contains('Approval Request Rejected by')))){
                            approvalProcessLog.ApproverName=pInstanceStep.Actor.name;
                            approvalProcessLog.Comments=pInstanceStep.comments!=null?pInstanceStep.comments:''; 
                            system.debug('approvalProcessLog.Comments-->'+approvalProcessLog.Comments);
                            break;
                        }														
                    }
                }
                return approvalProcessLog;
            }
            
        }else{
            //ECM-5358
            List<ECM_Approval_Log__c>approvalLogList=[SELECT Id, Name, ECM_Contract__c, ECM_Contract__r.ContractNumber, ECM_Contract__r.Owner.Name,
                                                      ECM_Contract__r.Account.Name, ECM_Comment__c,ECM_Contract__r.Owner.LanguageLocaleKey
                                                      FROM ECM_Approval_Log__c WHERE Id=: approvalLogId];
            if(!approvalLogList.isEmpty()){
                approvalProcessLog.recipientName=approvalLogList[0].ecm_contract__r.owner.name;
                approvalProcessLog.ObjectDetails=System.Label.ECM_ContractGAS+' '+approvalLogList[0].ECM_Contract__r.ContractNumber;
                approvalProcessLog.Account=approvalLogList[0].ecm_contract__r.account.name;
                approvalProcessLog.ApproverName=approvalLogList[0].Name;
                approvalProcessLog.Comments=approvalLogList[0].ECM_Comment__c!=null?approvalLogList[0].ECM_Comment__c:'';
                return approvalProcessLog;
            }
    
        }
        return null;
    }
    
    public class lightningTableWrapper {  
        public List<ObjValues> tablerows {get; set;}
        public lightningTableWrapper(){           
            tablerows = new List<ObjValues>();
        }
    }	
    
    public class ObjValues{
        public string header{get; set;}
        public string values{get; set;}
        public string beer{get; set;}
        public string totals{get; set;}
    }
    
    
    public Contract getDraftContractDetails()
    {
        Contract contractobj;
        Id accId=getAccountId();
        Set<string> statusval = new Set<String>{'Draft','In Approval Process'};
            try{
                contractobj= [SELECT Id, Name ,ContractNumber,Account.Name, Venue_Type__c , ECM_Duration__c , ECM_Actual_Cases_Per_Year_OnPremise__c , ECM_Hybrid_Actual_Cases_PerYear__c , ECM_UOS_Per_Year_Onpremise__c , ECM_Hybrid_UOS_PerYear__c , ECM_Gross_Profit_Bef_TI_Per_Yer_Onpremis__c , ECM_Hybrid_GP_BeforTI_PerYear__c , ECM_Gross_Profit_After_TI_Per_Year_Onpre__c , ECM_Hybrid_GP_AfterTI_PerYear__c ,Createdby.Name,ECM_Agreement_Type__r.Name,StartDate, LastModifiedBy.Name,
                              ECM_Hybrid_Total_A_P_PerUOS__c ,ECM_Hybrid_UOS_PerTerm__c ,ECM_UOS_Over_Term_Onpremise__c ,ECM_Hybrid_Actual_Cases_OverTerm__c ,ECM_Actual_Cases_Over_Term_Onpremise__c ,ECM_Hybrid_CustInvest_Total_PerTerm__c ,ECM_Customer_Investment_TotOver_onpremi__c ,ECM_Hybrid_NSV_AfterTI_PerTerm__c ,ECM_Net_Sales_Value_AfterTI_Over_Onpremi__c ,ECM_Hybrid_GMPercent_PerTerm__c ,ECM_GM_Over_Term_Onpremise__c , ECM_Hybrid_COGS_PerTerm__c ,ECM_COGS_Over_Term_Onpremise__c ,ECM_Hybrid_GP_AfterTI_PerTerm__c ,ECM_Hybrid_GP_BeforeTI_PerTerm__c ,ECM_Gross_Profit_After_TI_Over_Term_Onpr__c ,ECM_Gross_Profit_Before_TI_Over_Onpremis__c , ECM_Hybrid_Sales_Driver_Discount_Per_Yea__c,ECM_Hybrid_Total_A_P_PerYear__c , ECM_A_P_Fund__c, AccountId, Status, OwnerId, RecordTypeId, RecordType.Name, ECM_Territory__c, ECM_Territory__r.Name, ECM_Total_A_P_Investment__c,ECM_Generated_NSV__c, ECM_COGS_Per_Year_Onpremise__c, ECM_Hybrid_COGS_PerYear__c, ECM_GM_Per_Year_Onpremise__c,
                              ECM_Total_GP__c, ECM_Fixed_share__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ECM_EU_Total_Trade_Investment__c,ECM_Variable_share__c,ECM_Overall_Investment_Figure__c, ECM_Hybrid_GMPercent_PerYear__c, AP_Spent__c, ECM_A_P_RollOver__c,
                              ECM_of_the_total_investment_vs_NSV__c, ECM_Hybrid_NSV_AfterTI_PerYear__c ,ECM_Net_Sales_Value_After_TI_PerYea_Opre__c,ECM_GM_reserve_share__c,ECM_GM_innovation_share__c,ECM_GM_premium_core_share__c,ECM_GM_local_priority_brand_share__c,
                              ECM_GP_reserve_share__c,ECM_GP_innovation_share__c,ECM_GP_premium_core_share__c,ECM_GP_local_priority_brand_share__c,ECM_NSV_local_priority_brand_share__c,ECM_Total_TI_Investment__c,ECM_Hybrid_A_P_Fund_PerUOS__c,
                              ECM_NSV_premium_core_share__c,ECM_NSV_innovation_share__c,ECM_NSV_reserve_share__c,ECM_CAP_ROI__c,ECM_GP_ROI__c,ECM_Customer_Investment_TotalGP_Onpremis__c ,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                              ECM_Agreement_Type__c,ECM_Customer_Investment_TotalPer_Onpremi__c , ECM_Hybrid_CustInvest_Total_PerYear__c, ECM_Overall_Investment_Amount__c, ECM_RTD_Sales_driver__c, Contract_End_Date__c,ECM_Additional_info_to_support_decision__c
                              ,ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.ContractNumber,ECM_Parent_Contract__r.Name
                              FROM Contract WHERE Status IN:statusval AND ID=:targetObjectId AND AccountId=:accId LIMIT 1 ];
            }
        catch(Exception e) {
            system.debug('Exception'+e);
        }
        return contractobj;
    }
    public Contract getActiveContractDetails()
    {
        Contract contractobj;
        Id accId=getAccountId();
        try{
            contractobj= [SELECT Id, Name,ContractNumber,Account.Name,Account.Person_Responsible__c, Venue_Type__c , ECM_Duration__c , ECM_Actual_Cases_Per_Year_OnPremise__c , ECM_Hybrid_Actual_Cases_PerYear__c , ECM_UOS_Per_Year_Onpremise__c , ECM_Hybrid_UOS_PerYear__c , ECM_Gross_Profit_Bef_TI_Per_Yer_Onpremis__c , ECM_Hybrid_GP_BeforTI_PerYear__c , ECM_Gross_Profit_After_TI_Per_Year_Onpre__c , ECM_Hybrid_GP_AfterTI_PerYear__c ,Createdby.Name,ECM_Agreement_Type__r.Name,StartDate, LastModifiedBy.Name,
                          ECM_Hybrid_Total_A_P_PerUOS__c ,ECM_Hybrid_UOS_PerTerm__c ,ECM_UOS_Over_Term_Onpremise__c ,ECM_Hybrid_Actual_Cases_OverTerm__c ,ECM_Actual_Cases_Over_Term_Onpremise__c , ECM_Hybrid_CustInvest_Total_PerTerm__c ,ECM_Customer_Investment_TotOver_onpremi__c ,ECM_Hybrid_NSV_AfterTI_PerTerm__c ,ECM_Net_Sales_Value_AfterTI_Over_Onpremi__c ,ECM_Hybrid_GMPercent_PerTerm__c ,ECM_GM_Over_Term_Onpremise__c , ECM_Hybrid_COGS_PerTerm__c ,ECM_COGS_Over_Term_Onpremise__c ,ECM_Hybrid_GP_AfterTI_PerTerm__c ,ECM_Hybrid_GP_BeforeTI_PerTerm__c ,ECM_Gross_Profit_After_TI_Over_Term_Onpr__c , ECM_Gross_Profit_Before_TI_Over_Onpremis__c , ECM_Hybrid_Total_A_P_PerYear__c , ECM_Hybrid_Sales_Driver_Discount_Per_Yea__c, ECM_A_P_Fund__c, AccountId, Status, OwnerId, RecordTypeId, RecordType.Name, ECM_Territory__c, ECM_Territory__r.Name, ECM_Total_A_P_Investment__c,ECM_Generated_NSV__c, ECM_COGS_Per_Year_Onpremise__c, ECM_Hybrid_COGS_PerYear__c, ECM_GM_Per_Year_Onpremise__c,
                          ECM_Total_GP__c, ECM_Fixed_share__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ECM_EU_Total_Trade_Investment__c,ECM_Variable_share__c,ECM_Overall_Investment_Figure__c, ECM_Hybrid_GMPercent_PerYear__c, AP_Spent__c, ECM_A_P_RollOver__c,
                          ECM_of_the_total_investment_vs_NSV__c, ECM_Hybrid_NSV_AfterTI_PerYear__c ,ECM_Net_Sales_Value_After_TI_PerYea_Opre__c,ECM_GM_reserve_share__c,ECM_GM_innovation_share__c,ECM_GM_premium_core_share__c,ECM_GM_local_priority_brand_share__c,
                          ECM_GP_reserve_share__c,ECM_GP_innovation_share__c,ECM_GP_premium_core_share__c,ECM_GP_local_priority_brand_share__c,ECM_NSV_local_priority_brand_share__c,ECM_Total_TI_Investment__c,ECM_Hybrid_A_P_Fund_PerUOS__c,
                          ECM_NSV_premium_core_share__c,ECM_NSV_innovation_share__c,ECM_NSV_reserve_share__c,ECM_CAP_ROI__c,ECM_GP_ROI__c,ECM_Customer_Investment_TotalGP_Onpremis__c ,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                          ECM_Agreement_Type__c,ECM_Customer_Investment_TotalPer_Onpremi__c , ECM_Hybrid_CustInvest_Total_PerYear__c, ECM_Overall_Investment_Amount__c, ECM_RTD_Sales_driver__c, Contract_End_Date__c,ECM_Additional_info_to_support_decision__c
                          ,ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.ContractNumber,ECM_Parent_Contract__r.Name
                          FROM Contract WHERE status='Active' AND AccountId=:accId LIMIT 1];
        }
        catch(Exception e) {
            system.debug('Exception'+e);
        }
        return contractobj;
    }
    public String getDomainUrl() //366446
    {
        return URL.getSalesforceBaseUrl().ToExternalForm() + '/';
    }
    public class approvalLog{	
        	
        public String recipientName{get;set;}	
        public String ObjectDetails{get;set;}	
        public String Account{get;set;}	
        public String ApproverName{get;set;}	
        public String Comments{get;set;}	
    }
}