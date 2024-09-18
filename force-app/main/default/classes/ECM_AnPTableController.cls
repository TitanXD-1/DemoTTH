/*

*   @Class Name: ECM_AnPTableController 

*   @Author                  Version       Date                Detail
*	Rajarshi Lahiri		     1.0		07/08/2023      Initial Development for 143956, 143955
*	Saurav Prasad		     1.1		08/08/2023      143956 : A&P table Data Fetch
*	Shivam Chauhan			 1.2		23/08/2023		144334 : A&P Screen Save Button Function
*	Saurav Prasad			 1.3		23/08/2023		144340 : A&P Screen - Product in alphabetical order 
*/
public with sharing class ECM_AnPTableController {
    @AuraEnabled(cacheable=true)
    public static List<ECM_AnPScreenWrapper> getAnPValues(Id conId){
        List<String> fieldSetAPINames = System.Label.ECM_AnP_PlanningFieldSets.split(';');
        List<Schema.FieldSetMember> fsForecast = Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[0]).getFields();
        List<Schema.FieldSetMember> fsPaid= Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[1]).getFields();
        String query=getQueryStr(conId);
        System.debug(LoggingLevel.DEBUG,query);
        List<String> fieldNames=new List<String>();
        for(Integer i=0;i<fsForecast.size();i++){
            String nameJoin=fsForecast[i].getFieldPath()+'-'+fsPaid[i].getFieldPath();
            fieldNames.add(nameJoin);
        }
        List<ECM_A_P_Planning__c> anpLst=Database.query(String.escapeSingleQuotes(query));
        Map<Id,ECM_AnPScreenWrapper> wrapMap=new Map<Id,ECM_AnPScreenWrapper>();
        for(ECM_A_P_Planning__c apPlan:anpLst){
            updateWrapperMethod(wrapMap, apPlan,fieldNames);
        }
        
        return wrapMap.Values();
    }
    public static void updateWrapperMethod(Map<Id,ECM_AnPScreenWrapper> wrapMap, ECM_A_P_Planning__c apPlan,List<String> fieldNames){
        if(wrapMap.containsKey(apPlan.ECM_Contract_Item__c)){
            ECM_AnPScreenWrapper ob=wrapMap.get(apPlan.ECM_Contract_Item__c);
            //ob.forecast=new List<ECM_AnPScreenWrapper.monthWrapper>();
            ob.paidAndForecast.addAll(getMonthWrap(fieldNames,apPlan));
            //143956
            ob.listOfAnp.add(apPlan);
            wrapMap.put(apPlan.ECM_Contract_Item__c,ob);

        }
        else{
            ECM_AnPScreenWrapper ob=new ECM_AnPScreenWrapper();
            ob.paidAndForecast.add(new ECM_AnPScreenWrapper.monthWrapper());//dummy value to skip the first set of columns(Totals)
            
            ob.productName=apPlan.ECM_Contract_Item__r.ECM_Product_Name__c;
            ob.plannedAPTotal=apPlan.ECM_Contract_Item__r.ECM_TotalAnP_incl_Indirect__c!=null?apPlan.ECM_Contract_Item__r.ECM_TotalAnP_incl_Indirect__c:0.00;
            ob.phasingForeCastTotal=apPlan.ECM_Contract_Item__r.ECM_Phasing_Forecast_Total__c!=null?apPlan.ECM_Contract_Item__r.ECM_Phasing_Forecast_Total__c:0.00;
            ob.paidAPTotal=apPlan.ECM_Contract_Item__r.ECM_Paid_A_P_Total__c!=null?apPlan.ECM_Contract_Item__r.ECM_Paid_A_P_Total__c:0.00;
            ob.difference=apPlan.ECM_Contract_Item__r.ECM_Difference__c!=null?apPlan.ECM_Contract_Item__r.ECM_Difference__c:0.00;
            ob.paidAndForecast.addAll(getMonthWrap(fieldNames,apPlan));
            ob.conItemId = apPlan.ECM_Contract_Item__c;
            //143956
            ob.listOfAnp.add(apPlan);
            
            wrapMap.put(apPlan.ECM_Contract_Item__c,ob);
        }
    }
    public static String getQueryStr(Id conId){
        List<String> fieldSetAPINames = System.Label.ECM_AnP_PlanningFieldSets.split(';');
        List<Schema.FieldSetMember> fsForecast = Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[0]).getFields();
        List<Schema.FieldSetMember> fsPaid= Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[1]).getFields();
        String query = 'SELECT Id,ECM_Contract_Item__c,ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Contract_Item__r.ECM_TotalAnP_incl_Indirect__c,ECM_Contract_Item__r.ECM_Phasing_Forecast_Total__c,ECM_Contract_Item__r.ECM_Paid_A_P_Total__c,ECM_Contract_Item__r.ECM_Difference__c,ECM_Calendar_Year__c, ECM_Unique_Identifier__c, ';
        
        for(Schema.FieldSetMember f : fsForecast) {
            query += f.getFieldPath() + ', ';
        }
        for(Schema.FieldSetMember f : fsPaid) {
            query += f.getFieldPath() + ', ';
        }
        //144340
        //Added Ordered by ORDER BY ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Calendar_Year__c ASC
        query=query.substring(0, query.lastIndexOf(','));
        query+=' FROM ECM_A_P_Planning__c  WHERE ECM_Contract_Item__r.ECM_Contract__c=:conId ORDER BY ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Calendar_Year__c ASC';
        return query;
    }
    /*
    * @description : This method is used to return Wrapper class with fields set api names (143956)
    * @return : WrapperClass
    * @param : 
    */
    @AuraEnabled(cacheable=true)
    public static WrapperClass getFieldsAPI(){
        List<String> forecastFieldsAPI = new List<String>();
        List<String> paidFieldsAPI = new List<String>();
        
        List<String> fieldSetAPINames = System.Label.ECM_AnP_PlanningFieldSets.split(';');
        List<Schema.FieldSetMember> fsForecast = Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[0]).getFields();
        List<Schema.FieldSetMember> fsPaid= Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[1]).getFields();
        
        WrapperClass wrap = new WrapperClass();
        try {
            for(Schema.FieldSetMember f : fsForecast) {
                forecastFieldsAPI.add(f.getFieldPath());
            }
            for(Schema.FieldSetMember f : fsPaid) {
                paidFieldsAPI.add(f.getFieldPath());
            }
            
            wrap.forecastFields.addAll(forecastFieldsAPI);
            wrap.paidFields.addAll(paidFieldsAPI);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, 'Message: '+e.getMessage()+'\n Exception:'+e);
        }
        
        return wrap;
    }
    
    public static List<ECM_AnPScreenWrapper.monthWrapper> getMonthWrap(List<String> fieldNames,ECM_A_P_Planning__c apPlan){
        List<ECM_AnPScreenWrapper.monthWrapper> mthWrapList=new List<ECM_AnPScreenWrapper.monthWrapper>();
        for(String fields:fieldNames) {
            if(fields != null){
            String forecastField=fields.split('-')[0];
            String paidField=fields.split('-')[1];
            if(apPlan.get(forecastField)!=null && apPlan.get(paidField)!=null){
                ECM_AnPScreenWrapper.monthWrapper mntWrap=new ECM_AnPScreenWrapper.monthWrapper();
                mntWrap.paidValue=((Decimal)apPlan.get(paidField)).setScale(2);
                mntWrap.forecastValue=((Decimal)apPlan.get(forecastField)).setScale(2);
                mntWrap.uniqueId=paidField+'-'+forecastField+'-'+apPlan.ECM_Calendar_Year__c+'-'+apPlan.ECM_Contract_Item__c+'-'+apPlan.Id;
                mntWrap.paidColumn=paidField.split('_')[1]+'_'+apPlan.ECM_Calendar_Year__c+'_'+'Paid';
                mntWrap.forecastColumn=forecastField.split('_')[1]+'_'+apPlan.ECM_Calendar_Year__c+'_'+'Forecast';
                mthWrapList.add(mntWrap);
                //System.debug('@@mntWrap.forecastColumn'+mntWrap.forecastColumn);
            }
        }
        
        }
        
        return mthWrapList;
        
    }
    //144334
    @AuraEnabled
    public static void updateAnPValues(String payload, String conId){
        System.debug(LoggingLevel.DEBUG,conId);
        List<ECM_Contract_Item__c> updatedCI = new List<ECM_Contract_Item__c>();
        try{
            List<ECM_A_P_Planning__c> updateList=(List<ECM_A_P_Planning__c>)JSON.deserialize(payload, List<ECM_A_P_Planning__c>.class);
            System.debug(LoggingLevel.DEBUG, updateList);
            if(Schema.sObjectType.ECM_A_P_Planning__c.isUpdateable()){
                update updateList;
            }

            Id profileId = UserInfo.getProfileId();
            String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
            
            for(AggregateResult groupedResults : 
                [SELECT ECM_Contract_Item__c,
                 SUM(ECM_Sum_of_Forecast__c) forecastSum,
                 SUM(ECM_Sum_of_Paid__c) paidSum
                 FROM ECM_A_P_Planning__c 
                 WHERE ECM_Contract_Item__r.ECM_Contract__c =:conId
                 GROUP BY ECM_Contract_Item__c]){
                     ECM_Contract_Item__c contractItem = new ECM_Contract_Item__c(Id=String.valueOf(groupedResults.get('ECM_Contract_Item__c')));
                     contractItem.ECM_Phasing_Forecast_Total__c = Decimal.valueOf(String.valueOf(groupedResults.get('forecastSum'))).setScale(2);
                     contractItem.ECM_Paid_A_P_Total__c = Decimal.valueOf(String.valueOf(groupedResults.get('paidSum'))).setScale(2);
                     updatedCI.add(contractItem);
                 }
            if(Schema.sObjectType.ECM_Contract_Item__c.isUpdateable() || System.label.ECM_User_Profile_For_CI.contains(profileName)){
                update updatedCI;
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.DEBUG,'Exception @'+e);
            System.debug(LoggingLevel.DEBUG,'Update Failed');
        }
        
    }
    
    @AuraEnabled
    public static List<Date> getMonths(Id conId){
        
        List<Date> lstofMonths = new List<Date>();
        Date startDate;
        Date endDate;
        Map<String,Date> localeMonthNames = new Map<String,Date>();
        
        Contract con=[select Id,StartDate, Contract_End_Date__c from Contract where Id =:conId WITH SECURITY_ENFORCED LIMIT 1];
        startDate=con.StartDate;
        endDate=con.Contract_End_Date__c;
        Integer monthDiff = startDate!=null?startDate.monthsBetween(endDate.adddays(1)):0;
        for(Integer i=0; monthDiff>i;i++){
            DateTime monthName = startDate.addMonths(i);
            lstofMonths.add(startDate.addMonths(i));
            if(!localeMonthNames.containsKey(monthName.format('MMMMM'))){
                localeMonthNames.put(monthName.format('MMMMM'),startDate.addMonths(i));
            }
        }
        
        return lstofMonths;
    } 
    
    //143956
    public class WrapperClass
    {
        @AuraEnabled
        public List<String> forecastFields{get;set;}
        @AuraEnabled
        public List<String> paidFields{get;set;}
        
        public wrapperClass(){
            this.forecastFields = new List<String>();
            this.paidFields = new List<String>();
        }
    }
}