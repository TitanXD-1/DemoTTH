/*
Class Name: ECM_contractexcel
TestClassName : 
Req:This class is used to create excel to attach with contract approval email.
History:                                                 
VERSION   AUTHOR              DATE              DETAIL
1.0    Pravalika Glamari     28/04/2021      ECM-3692 Excel generation_Logic_EU_Contract Approval_part1
1.1    Pratap Sen            11/11/2021      ECM-4917 Target Volume renaming for EU contract Approval mail
1.1	   Keshav				 21/12/2021		 ECM-4991 Removed "Investment Summary KPIS" MS field reference
1.2    Suvendu               27/05/2022      ECM-5627 POC _Approval Email table to Configurable_EU
1.5    Suvendu               24/06/2022      ECM-5623  Renaming Of KPIs in the Approval Mails
1.6    Vinay                 05/08/2022      ECM-5913  Approval Mail _ Totals Column
1.7    Nikhilesh			 02/09/2022		 ECM-5912 Approval Mail Attachment_Columns to be Market configurable
*/
public class ECM_contractexcel {
    public static Boolean isAU = false;
    public static String finalstr = '';
    public static String generateExcel(Id contractId){		
        try{
            Contract contObj = new Contract();	
            contObj=[select Id,ECM_Overall_Investment_Figure__c,account.Country__c,account.Country_Code__c,ECM_Total_Volume_Target_Spirits__c,ECM_Incremental_Volume_Spirits__c,ECM_Incremental_NSV_Spirits__c,ECM_Total_trade_investment_Spirits__c,
                     ECM_Total_A_P_Investment_Spirits__c,ECM_Incremental_GP__c,ECM_Incremental_GP_ROI__c,ECM_Incremental_GP_CAAP__c,ECM_Incremental_GP_CAAP_ROI__c,ECM_Total_Volume_Target_Beers__c,
                     ECM_Incremental_Volume_Beers__c,ECM_Incremental_NSV_Beers__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Beers__c,ECM_Incremental_GP_Beers__c,ECM_Incremental_GP_ROI_Beers__c,
                     ECM_Incremental_GP_CAAP_Beers__c,ECM_Incremental_GP_CAAP_ROI_Beers__c,ECM_NSV_reserve_share__c,ECM_GP_reserve_share__c,ECM_GM_reserve_share__c,ECM_TV_reserve_share__c,ECM_IV_reserve_share__c,
                     ECM_NSV_innovation_share__c,ECM_GP_innovation_share__c,ECM_GM_innovation_share__c,ECM_TV_innovation_share__c,ECM_IV_innovation_share__c,
                     ECM_NSV_premium_core_share__c,ECM_GP_premium_core_share__c,ECM_GM_premium_core_share__c,ECM_TV_premium_core_share__c,ECM_IV_premium_core_share__c,
                     ECM_Total_Volume_Target__c,ECM_EU_Total_Trade_Investment__c,ECM_Total_A_P_Investment__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_Overall_investments__c, 
                     ECM_Total_GP__c,ECM_Total_GM__c,ECM_of_A_P_vs_NSV__c from Contract WHERE Id=: contractId];//ECM-5912 Added fields 
            if(contObj.account.Country_Code__c == 'AU'){ //Added for ECM-4917
                isAU = true;
            }
            Schema.SObjectType s = Schema.getGlobalDescribe().get('Market_Setting__c') ;
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
            List<Market_Setting__c>marketsettingsList= [select id,ECM_Contract_Header_Details__c,ECM_Category_Split_KPIS__c,ECM_Product_Investment_Details__c,ECM_Sales_Drivers_Details__c,ECM_Tiering_consideration_for_Accrual__c from Market_Setting__c where Geography__c=:contObj.account.country__c];
            system.debug('market Seting--->'+marketsettingsList);
            String query='select id';
            if(marketsettingsList[0].ECM_Contract_Header_Details__c!=null){
                query=query+','+marketsettingsList[0].ECM_Contract_Header_Details__c;
            }
            if(marketsettingsList[0].ECM_Category_Split_KPIS__c!=null){
                query=query+','+marketsettingsList[0].ECM_Category_Split_KPIS__c;
            }
            
            query=query.replace(';',',');
            query=query+' From contract where id=\''+contractId+'\'';
            system.debug('query--->'+query);
            List<Contract>contractList=Database.query(query);
            //Added for ECM_5627
            List<String> investmentSummaryfields = new List<String>();
            List<String> investmentSummaryColumns = new List<String>();//ECM-5912
            List<ECM_Technical_Market_Setting__mdt> investSummKPIsFieldNameList =[SELECT ECM_Investment_Summary_KPIs_Fields__c,ECM_Investment_Summary_KPI_Columns__c FROM ECM_Technical_Market_Setting__mdt where ECM_Country__c =:contObj.Account.Country_Code__c];
            if(!investSummKPIsFieldNameList.isEmpty()){
                if(String.isNotBlank(investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPI_Columns__c) && String.isNotBlank(investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPIs_Fields__c)){
                    investmentSummaryfields=investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPIs_Fields__c.split(',');
                    investmentSummaryColumns=investSummKPIsFieldNameList[0].ECM_Investment_Summary_KPI_Columns__c.split(',');//ECM-5912
                }
            }
            List<String> categoryfields=marketsettingsList[0].ECM_Category_Split_KPIS__c.split(';');
            List<String> Productfields=marketsettingsList[0].ECM_Product_Investment_Details__c.split(';');
            List<String> Salesdriverfields=marketsettingsList[0].ECM_Sales_Drivers_Details__c.split(';');
            
            if(!investmentSummaryfields.isEmpty() && !investmentSummaryColumns.isEmpty()){
            	finalstr='<\br><br>'+prepareExcelTableInvestSummaryKPIS(contObj,investmentSummaryfields,investmentSummaryColumns,'Investment Summary KPIs');
            }
            finalStr=finalstr+'<br><br>'+prepareExcelTableCategorySplit(fields,contObj,categoryfields,'Category Split ','ECM_Category_Split_KPIS__c');
            finalStr=finalstr+'<br><br>'+prepareExcelTableProducts(marketsettingsList,fields,contractList,Productfields,'Products & investment details','ECM_Product_Investment_Details__c');
            finalStr=finalstr+'<br><br>'+prepareExcelTableSalesDriver(fields,contractList,Salesdriverfields,'Sales drivers','ECM_Sales_Drivers_Details__c');
        }
        catch(Exception ex){ 
            System.debug('Exception caught in ECM_contractexcel class generateExcel method'+ex.getMessage());
        }
        return finalstr;
        
    }
    public static String prepareExcelTableInvestSummaryKPIS(contract contObj,List<String>selectfields,List<String>kpiColumns,String TableName){
        try{
            Boolean isSpirits=false;
            Boolean isBeer=false;
            Boolean isTotal=false,isBeerColumn=false,isSpiritColumn=false;
            List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
            List<ECM_Contract_KPI__c> conKpi = new List<ECM_Contract_KPI__c>();
            conKpi = [SELECT ECM_EU_Volume__c,ECM_Total_NSV__c,ECM_CAAP__c,ECM_NSV_EU__c,ECM_Trade_Investment_EU__c,ECM_CAAP_Percentage__c,ECM_CAAP_ROI_Percentage__c from ECM_Contract_KPI__c WHERE ECM_Contract__c=:contObj.Id AND ECM_Type__c ='Total'];
            //ECM-5912
            if(!kpiColumns.isEmpty()){
                isTotal = kpiColumns.contains('Total');
                isBeerColumn = kpiColumns.contains('Total Beer');
                isSpiritColumn = kpiColumns.contains('Total Spirit');
            }
            System.debug('isTotal : '+isTotal+'isBeerColumn : '+isBeercolumn+'isSpiritColumn : '+isSpiritColumn);
            //ECM-5912
            if((contObj.ECM_Total_Volume_Target_Spirits__c>0 ||contObj.ECM_Incremental_Volume_Spirits__c>0 ||contObj.ECM_Incremental_NSV_Spirits__c>0 ||contObj.ECM_Total_trade_investment_Spirits__c>0 ||contObj.ECM_Total_A_P_Investment_Spirits__c>0 ||contObj.ECM_Incremental_GP__c>0 ||contObj.ECM_Incremental_GP_ROI__c>0 ||contObj.ECM_Incremental_GP_CAAP__c>0 ||contObj.ECM_Incremental_GP_CAAP_ROI__c>0)&& isSpiritColumn ){
                isSpirits = true;
            }else{
                isSpirits = false;
            }
            if((contObj.ECM_Total_Volume_Target_Beers__c>0 ||contObj.ECM_Incremental_Volume_Beers__c>0 ||contObj.ECM_Incremental_NSV_Beers__c>0 ||contObj.ECM_Total_trade_investment_Beers__c>0 ||contObj.ECM_Total_A_P_Investment_Beers__c>0 ||contObj.ECM_Incremental_GP_Beers__c>0 ||contObj.ECM_Incremental_GP_ROI_Beers__c>0 ||contObj.ECM_Incremental_GP_CAAP_Beers__c>0 ||contObj.ECM_Incremental_GP_CAAP_ROI_Beers__c>0)&& isBeerColumn ){
                isBeer = true; 
            }else{
                isBeer = false;
            } 
            system.debug('isSpirits-->'+isSpirits+'isBeer--->'+isBeer);
            lightningTableWrapper ltw = new lightningTableWrapper();
            List<ObjValues> objvalList = new List<ObjValues>();
            for(string labelName: selectfields){
                ObjValues objval = new ObjValues();
                objval.header = labelName;
                if(labelName =='Total Forecast Volume'){
                    objval.values = String.valueof(contObj.ECM_Total_Volume_Target_Spirits__c);
                    objval.beer = String.valueof(contObj.ECM_Total_Volume_Target_Beers__c);
                    objval.totals = String.valueof(contObj.ECM_Total_Volume_Target__c);
                    if(isAU){
                        objval.header = 'Total Volume target';       //Added for ECM-4917
                    } 
                }else if(labelName =='Incremental Volume'){
                    objval.values = String.valueof(contObj.ECM_Incremental_Volume_Spirits__c);
                    objval.beer = String.valueof(contObj.ECM_Incremental_Volume_Beers__c);
                    objval.totals = String.valueof(contObj.ECM_Incremental_Volume_Spirits__c + contObj.ECM_Incremental_Volume_Beers__c);
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
                }//ECM-5913
                else if(labelName =='Total Investment'){
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
            ltw.tablerows = objvalList;
            listLgtnTableWraps.add(ltw);
            
            finalstr = '<table border="1"><th style="background-color:#FFF2CC">'+TableName+'</th>';
            //finalstr=finalstr+'<th style="background-color:#FFF2CC">'+Label.ECM_Totals+'</th>';
            if(isTotal){
                finalstr=finalstr+'<th style="background-color:#FFF2CC">'+Label.ECM_Totals+'</th>';
            }//ECM-5912
            if(isSpirits){
                finalstr=finalstr+'<th style="background-color:#FFF2CC">'+ Label.ECM_Total_Spirits +'</th>'; 
            }
            if(isBeer){
                finalstr=finalstr+'<th style="background-color:#FFF2CC">'+ Label.ECM_Total_Beer +'</th>';
            }

            for(ObjValues field:objvalList){
                finalstr=finalstr+'<tr><td>'+field.header;
                //ECM-5912 : Added changes to cover the Total column render
                /* This covers case when only Total is present in Investment Summary KPI Columns in Technical Market Setting */
                if(isTotal && !isSpirits && !isBeer){
                	finalstr=finalstr+'</td><td>'+field.totals+'</td></tr>';
                }
                else if(isTotal){
                	finalstr=finalstr+'</td><td>'+field.totals;
                }
                
                /*The below covers the case when Total Beer and Total Spirit is selected in Investment Summary KPI Columns in Technical Market Setting*/ 
                if(isBeer || isSpirits){
                    if(isSpirits && !isBeer){ 
                        finalstr=finalstr+'</td><td>'+field.values+'</td></tr>';   
                    }
                    else if(isSpirits && isBeer){
                        finalstr=finalstr+'</td><td>'+field.values;
                        finalstr=finalstr+'</td><td>'+field.beer+'</td></tr>';
                    }
                    else if(!isSpirits && isBeer){
                        finalstr=finalstr+'</td><td>'+field.beer+'</td></tr>';
                    } 
                }
                
            }
            finalstr=finalstr+'</table>';
            
        }
        catch(Exception ex){ 
            System.debug('Exception caught in ECM_contractexcel class prepareExcelTableInvestSummaryKPIS method'+ex.getMessage());
        }
        return finalstr;
        
    }
    public static String prepareExcelTableCategorySplit(Map<String,Schema.SObjectField> fields,contract contObj,List<String>categoryfields,String TableName,String MarketSettingFieldname){
        try{
            Map<String,String>fielMap= new Map<String,String>(); 
            Schema.DescribeFieldResult fieldResult = fields.get(MarketSettingFieldname).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                fielMap.put(pickListVal.getValue(),pickListVal.getLabel());
            } 
            
            set<string> SplitFields=new set<string>();
            set<string> SplitFields_column=new set<string>();
            string fieldvalue;
            
            for(String field:categoryfields){
                if(field.contains('reserve')||field.contains('innovation')||field.contains('premium_core')){
                    fieldvalue=fielMap.get(field).replace('Reserve','').replace('Innovation', '').replace('Premium core', '');
                }else{
                    fieldvalue=field;
                }
                SplitFields.add(fieldvalue);
            }
            
            List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
            
            lightningTableWrapper ltw = new lightningTableWrapper();
            List<ObjValues> objvalList = new List<ObjValues>();
            for(string labelName: SplitFields){
                ObjValues objval = new ObjValues();
                objval.Catheader = labelName;
                if(labelName.contains('NSV')){
                    if(categoryfields.contains('ECM_NSV_reserve_share__c')){
                        objval.ResValues = String.valueof(contObj.ECM_NSV_reserve_share__c);
                    }else{
                        objval.ResValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_NSV_innovation_share__c')){
                        objval.InnovationValues = String.valueof(contObj.ECM_NSV_innovation_share__c);
                    }else{
                        objval.InnovationValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_NSV_premium_core_share__c')){
                        objval.PremiumCoreVal = String.valueof(contObj.ECM_NSV_premium_core_share__c);
                    }else{
                        objval.PremiumCoreVal = String.valueof('0');
                    }
                }else if(labelName.contains('Gross Profit')){
                    if(categoryfields.contains('ECM_GP_reserve_share__c')){
                        objval.ResValues = String.valueof(contObj.ECM_GP_reserve_share__c);
                    }else{
                        objval.ResValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_GP_innovation_share__c')){
                        objval.InnovationValues = String.valueof(contObj.ECM_GP_innovation_share__c);
                    }else{
                        objval.InnovationValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_GP_premium_core_share__c')){
                        objval.PremiumCoreVal = String.valueof(contObj.ECM_GP_premium_core_share__c);
                    }else{
                        objval.PremiumCoreVal = String.valueof('0');
                    }
                }else if(labelName.contains('Gross Margin')){
                    if(categoryfields.contains('ECM_GM_reserve_share__c')){
                        objval.ResValues = String.valueof(contObj.ECM_GM_reserve_share__c);
                    }else{
                        objval.ResValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_GM_innovation_share__c')){
                        objval.InnovationValues = String.valueof(contObj.ECM_GM_innovation_share__c);
                    }else{
                        objval.InnovationValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_GM_premium_core_share__c')){
                        objval.PremiumCoreVal = String.valueof(contObj.ECM_GM_premium_core_share__c);
                    }else{
                        objval.PremiumCoreVal = String.valueof('0');
                    }
                }else if(labelName.contains('% Total Volume')){
                    if(categoryfields.contains('ECM_TV_reserve_share__c')){
                        objval.ResValues = String.valueof(contObj.ECM_TV_reserve_share__c);
                    }else{
                        objval.ResValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_TV_innovation_share__c')){
                        objval.InnovationValues = String.valueof(contObj.ECM_TV_innovation_share__c);
                    }else{
                        objval.InnovationValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_TV_premium_core_share__c')){
                        objval.PremiumCoreVal = String.valueof(contObj.ECM_TV_premium_core_share__c);
                    }else{
                        objval.PremiumCoreVal = String.valueof('0');
                    }
                }else if(labelName.contains('% Incremental Volume')){
                    if(categoryfields.contains('ECM_IV_reserve_share__c')){
                        objval.ResValues = String.valueof(contObj.ECM_IV_reserve_share__c);
                    }else{
                        objval.ResValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_IV_innovation_share__c')){
                        objval.InnovationValues = String.valueof(contObj.ECM_IV_innovation_share__c);
                    }else{
                        objval.InnovationValues = String.valueof('0');
                    }
                    if(categoryfields.contains('ECM_IV_premium_core_share__c')){
                        objval.PremiumCoreVal = String.valueof(contObj.ECM_IV_premium_core_share__c);
                    }else{
                        objval.PremiumCoreVal = String.valueof('0');
                    }
                }
                objvalList.add(objval);
                
            }
            ltw.tablerows = objvalList;
            listLgtnTableWraps.add(ltw);
            
            
            finalstr = '<table border="1"><th>'+TableName+'</th>';
            finalstr = finalstr+'<tr><th style="background-color:#FFF2CC">KPI</th>';
            finalstr=finalstr+'<th style="background-color:#FFF2CC">Reserve</th>'; 
            finalstr=finalstr+'<th style="background-color:#FFF2CC">Innovation</th>';  
            finalstr=finalstr+'<th style="background-color:#FFF2CC">Premium core</th></tr>'; 
            
            for(ObjValues field:objvalList){
                system.debug(field.Catheader);
                finalstr=finalstr+'<tr><td>'+field.Catheader;
                finalstr=finalstr+'</td><td>'+field.ResValues;  
                finalstr=finalstr+'</td><td>'+field.InnovationValues;   
                finalstr=finalstr+'</td><td>'+field.PremiumCoreVal+'</td></tr>';   
            }
            finalstr=finalstr+'</table>';	
        }
        catch(Exception ex){ 
            System.debug('Exception caught in ECM_contractexcel class prepareExcelTableCategorySplit method'+ex.getMessage());
        }
        return finalstr;
    }
    public static String prepareExcelTableProducts(List<Market_Setting__c>marketsettingsList,Map<String,Schema.SObjectField> fields,List<Contract>contractList,List<String>Productfields,String TableName,String MarketSettingFieldname){
        try{      
            //Map<String,Integer>fieldMap= new Map<String,Integer>{'ECM_Product_Name__c'=>1,'ECM_Baseline_volume__c'=>2,'ECM_Incremental_Volume__c'=>3,'ECM_Volume__c'=>4,'ECM_UoM__c'=>5,'Tiers'=>6,'ECM_Retro_investment__C'=>7,'ECM_Generated_NSV_EU__c'=>8,'ECM_Trade_Investments__C'=>9,'ECM_NSV_After_Investment__c'=>10,'ECM_AnP_investment__c'=>11,'ECM_Gross_margin__c'=>12,'ECM_Total_GP_EU__c'=>13,'ECM_Incremental_GP_after_Investment__c'=>14,'ECM_CAAP_Total__c'=>15,'ECM_Product_growth_driver__c'=>16};
            
            //ECM-4991 updated api name to __C and moved the Map hardcoding to label
            List<String> prodInv = Label.ECM_Products_Investment_Details.split(',');
            system.debug('prodInv-->'+prodInv);
            Map<String,Integer>fieldMap= new Map<String,Integer>();
            for(String labStr : prodInv){
                fieldMap.put(labStr.SubStringBefore('='),Integer.valueof(labStr.SubStringAfter('=')));    
            }
            system.debug('fieldMap-->'+fieldMap);
            
            List<Integer>fieldsort= new List<Integer>();
            List<String>newproductfields= new List<String>();
            for(String field:Productfields){
                fieldsort.add(fieldMap.get(field));
            }
            fieldsort.sort();
            for(Integer field:fieldsort){
                for(String fieldString:Productfields){
                    if(fieldMap.get(fieldString)==field){
                        newproductfields.add(fieldString);
                    }
                }
            }
            Productfields=newproductfields;
            Map<String,String>fielMap= new Map<String,String>(); 
            Schema.DescribeFieldResult fieldResult = fields.get(MarketSettingFieldname).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                fielMap.put(pickListVal.getValue(),pickListVal.getLabel());
            }
            set<string> SplitFields=new set<string>();
            string Prodfield;
            string query='select id';
            boolean istier=false;
            for(String Infield:Productfields){
                if(Infield=='Tiers'){
                    istier=true;
                }else{
                    query=query+','+Infield;
                }
                
            }
            query=query+' from ECM_Contract_Item__c where ECM_Contract__c=\''+contractList[0].id+'\'';
            system.debug('query prod--->'+query);
            
            
            list<ECM_Contract_Item__c> contractitemslist=database.query(query);
            system.debug('queryList-->'+contractitemslist);
            //Fetching Tiering records
            map<Id,ECM_Tiering__c> tierMap = new map<Id,ECM_Tiering__c>();
            if(isTier){
                for(ECM_Tiering__c tier : [SELECT Id,ECM_Contract_Item__c,ECM_Tier_1_rate_per_UoM__c,ECM_Tier_1_volume_limit__c,
                                           ECM_Tier2_rate_per_UoM__c,ECM_Tier_3_rate_per_UoM__c,ECM_Tier_2_volume_limit__c,ECM_Tier_3_volume_limit__c 
                                           FROM ECM_Tiering__c where ECM_Contract_Item__r.ECM_Contract__c IN:contractList]){
                                               tierMap.put(tier.ECM_Contract_Item__c,tier);
                                           }
            }
            List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
            Map<String,Map<String,String>>objValues= new Map<String,Map<String,String>>();
            for(ECM_Contract_Item__c citem:contractitemslist){
                Map<String,String>objfieldvalues= new Map<String,String>();
                for(String Infield:Productfields){
                    if(Infield!='Tiers'){
                        if(fielMap.get(Infield)!=null && citem.get(Infield)!=null){
                            objfieldvalues.put(fielMap.get(Infield),String.valueOf(citem.get(Infield)));
                        }
                    }else{
                        if(tierMap.get(citem.id)!=null){
                            ECM_Tiering__c tier=tierMap.get(citem.id);
                            string tiervalues=tier.ECM_Tier_1_volume_limit__c+'-'+tier.ECM_Tier_1_rate_per_UoM__c+'-'+tier.ECM_Tier_2_volume_limit__c+'-'+tier.ECM_Tier2_rate_per_UoM__c+'-'+tier.ECM_Tier_3_volume_limit__c+'-'+tier.ECM_Tier_3_rate_per_UoM__c;
                            objfieldvalues.put(Infield,tiervalues);
                        }
                    }
                    if(fielMap.get(Infield)!=null){
                        SplitFields.add(fielMap.get(Infield)); 
                    }	     		
                }
                objValues.put(citem.id,objfieldvalues);
            }
            system.debug('objValues--->'+objValues);
            
            finalstr = '<table border="1"><th>'+TableName+'</th>';
            finalstr=finalstr+'<tr><th style="background-color:#FFF2CC">'+'No.';
            for(string field: SplitFields){
                finalstr=finalstr+'</th><th style="background-color:#FFF2CC">'+field;
            }
            if(isAU){
                finalstr = finalstr.replace('Forecast Volume','Volume Target');
            }else{
                finalstr = finalstr.replace('Volume Target','Forecast Volume');
            }
            finalstr=finalstr+'</th></tr>'; 
            integer k=1;
            for(String cId:objValues.keySet()){
                Map<string,string>fieldvalues=objValues.get(cId);
                finalstr=finalstr+'<tr><td>'+k; 
                for(string field: SplitFields){
                    if(fieldvalues.get(field)!=null){
                        finalstr=finalstr+'</td><td>'+fieldvalues.get(field); 
                    }else{
                        finalstr=finalstr+'</td><td>'; 
                    }
                }
                k++;
            }
            finalstr=finalstr+'</td></tr>'; 
            
            finalstr=finalstr+'</table>';
        }
        catch(Exception ex){ 
            System.debug('Exception caught in ECM_contractexcel class prepareExcelTableProducts method'+ex.getMessage());
        }
        return finalstr;
        
    }
    public static String prepareExcelTableSalesDriver(Map<String,Schema.SObjectField> fields,List<Contract>contractList,List<String>salesfields,String TableName,String MarketSettingFieldname){
        try{
            //Map<String,Integer>fieldMap= new Map<String,Integer>{'ECM_Sales_Driver_Name__c'=>1,'ECM_Investement_Description__c'=>2,'ECM_Budget_Type__c'=>3,'ECM_Payment_Frequency__r.ECM_Type__c'=>4,'Payment dates'=>5,'ECM_Total_Investment_Amount__c'=>6,'ECM_Prepayment__c'=>7}; 
            
            //ECM-4991 Moved the Map hardcoding to label
            List<String> sdHeaderlst = Label.ECM_SalesDrivers_Header_Details.split(',');
            system.debug('sdHeaderlst-->'+sdHeaderlst);
            Map<String,Integer> fieldMap = new Map<String,Integer>();
            for(String labStr : sdHeaderlst){
                fieldMap.put(labStr.SubStringBefore('='),Integer.valueof(labStr.SubStringAfter('=')));    
            }
            system.debug('fieldMap product-->'+fieldMap);
            
            List<Integer>fieldsort= new List<Integer>();
            List<String>newproductfields= new List<String>();
            for(String field:salesfields){
                fieldsort.add(fieldMap.get(field));
            }
            fieldsort.sort();
            for(Integer field:fieldsort){
                for(String fieldString:salesfields){
                    if(fieldMap.get(fieldString)==field){
                        newproductfields.add(fieldString);
                    }
                }
            }
            salesfields=newproductfields;
            Map<String,String>fielMap= new Map<String,String>(); 
            Schema.DescribeFieldResult fieldResult = fields.get(MarketSettingFieldname).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                fielMap.put(pickListVal.getValue(),pickListVal.getLabel());
            }
            set<string> SplitFields=new set<string>();
            string Prodfield;
            string query='select id';
            boolean istier=false;
            for(String Infield:salesfields){
                if(Infield=='Payment dates'){
                    query=query+',ECM_Payment_Date__c,ECM_1st_Prepayment_Date__c,ECM_Remaining_Payment_Date__c';
                }else{
                    query=query+','+Infield;
                }
                
            }
            query=query+' from ECM_Sales_Driver_Item__c where Contract__c=\''+contractList[0].id+'\'';
            system.debug('query--->'+query);
            
            
            list<ECM_Sales_Driver_Item__c> salesDriverItemslist=database.query(query);
            system.debug('queryList-->'+salesDriverItemslist);
            
            Map<String,Map<String,String>>objValues= new Map<String,Map<String,String>>();
            for(ECM_Sales_Driver_Item__c citem:salesDriverItemslist){
                Map<String,String>objfieldvalues= new Map<String,String>();
                for(String Infield:salesfields){
                    if(Infield!='Payment dates'){
                        if(Infield=='ECM_Payment_Frequency__r.ECM_Type__c'){
                            objfieldvalues.put(fielMap.get(Infield),citem.ECM_Payment_Frequency__r.ECM_Type__c);
                        }else if(fielMap.get(Infield)!=null && citem.get(Infield)!=null){
                            objfieldvalues.put(fielMap.get(Infield),String.valueOf(citem.get(Infield)));
                        }
                    }else{
                        if(citem.get('ECM_Payment_Date__c')!=null){
                            objfieldvalues.put(Infield,String.valueOf(citem.get('ECM_Payment_Date__c')));
                        }else{
                            objfieldvalues.put(Infield,String.valueOf(citem.get('ECM_1st_Prepayment_Date__c'))+','+String.valueOf(citem.get('ECM_Remaining_Payment_Date__c')));
                        }
                        
                    }
                    if(fielMap.get(Infield)!=null){
                        SplitFields.add(fielMap.get(Infield)); 
                    }	     		
                }
                objValues.put(citem.id,objfieldvalues);
            }
            system.debug('objValues--->'+objValues);
            
            finalstr = '<table border="1"><th>'+TableName+'</th>';
            finalstr=finalstr+'<tr><th style="background-color:#FFF2CC">'+'No.';
            for(string field: SplitFields){
                finalstr=finalstr+'</th><th style="background-color:#FFF2CC">'+field;
            }
            finalstr=finalstr+'</th></tr>'; 
            integer k=1;
            for(String cId:objValues.keySet()){
                Map<string,string>fieldvalues=objValues.get(cId);
                finalstr=finalstr+'<tr><td>'+k; 
                for(string field: SplitFields){
                    if(fieldvalues.get(field)!=null){
                        finalstr=finalstr+'</td><td>'+fieldvalues.get(field); 
                    }else{
                        finalstr=finalstr+'</td><td>'; 
                    }
                }
                k++;
            }
            finalstr=finalstr+'</td></tr>'; 
            
            finalstr=finalstr+'</table>';	
        }
        catch(Exception ex){ 
            System.debug('Exception caught in ECM_contractexcel class prepareExcelTableSalesDriver method'+ex.getMessage());
        }
        return finalstr;
        
    }
    public class lightningTableWrapper {  
        public List<ObjValues> tablerows {get; set;}
        public lightningTableWrapper(){           
            tablerows = new List<ObjValues>();
        }
    }	
    
    public class ObjValues{
        public string header{get; set;}
        public string Catheader{get; set;}
        public string values{get; set;}
        public string beer{get; set;}
        public string ResValues{get; set;}
        public string InnovationValues{get; set;}
        public string PremiumCoreVal{get; set;}
        public string totals{get; set;} // ECM-5912
    }
    
}