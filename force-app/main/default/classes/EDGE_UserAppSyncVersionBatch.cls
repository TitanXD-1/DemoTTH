/**

* @description :  EDGE_UserAppSyncVersionBatch

* @purpose : Batch Class for storing sync report countrywise
* @history :

* Version    Developer                Date             User Story/Purpose

*  1.1      Mayukh S Roy			04/07/2022        
*/

global class EDGE_UserAppSyncVersionBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents{
    UserAppVersionSetting__c uavs= UserAppVersionSetting__c.getOrgDefaults();
    global Datetime dt = uavs.LatestReleaseDate__c;
    global String latestAppVersion=uavs.Latest_App_Version__c;
    global String latestAndroidAppVersion=uavs.Android_Latest_App_Version__c;
    global List<User> UserList = new List<User>();
    global Map<Id,String> userCountryMap =new  Map<Id,String>();
    global Map<String,String> UserProfileMap = new Map<String,String>();
    global Map<String,String> countryCodeMap = new Map<String,String>();
    global Map<String,Integer>  CountryMapLatest = new Map<String,Integer> ();
    global Map<String,Integer>  CountryMapActive = new Map<String,Integer> ();
    global Map<Id,UserWrapper> UserWrapperMap = new Map<Id,UserWrapper>();
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        //Creating Map for Country name and its country code    
        Schema.DescribeSObjectResult objSchema = User.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getmap();
        List<Schema.Picklistentry> fld =fieldmap.get('Available_Countries__c').getDescribe().getpicklistValues();
        
        for(Schema.Picklistentry pl : fld)
        {
            if(!countryCodeMap.containskey(pl.getValue()))
            {
                countryCodeMap.put(pl.getValue(),pl.getLabel());
            }
        }
        
        UserList= [SELECT Id,Name,Available_Countries__c,IsActive,Profile.Name,Default_Country__c  FROM User where (Profile.Name Like '%Sales%' or Profile.Name Like '%Quality%') and IsActive=true];
        System.debug('UserList'+UserList);
        for(User u:UserList)
        {
            if(userCountryMap.containsKey(u.Id)==false)
            {
                if(u.Default_Country__c != null)
                    userCountryMap.put(u.Id, u.Default_Country__c);
                else
                    userCountryMap.put(u.Id, u.Available_Countries__c);
            }
            if(!UserProfileMap.containsKey(u.id)){
                UserProfileMap.put(u.id,u.Profile.Name);
            }
        }
        
        EDGE_UtilityClass.printGovLimits(56);
        String queryString = 'Select CreatedDate,OwnerId,Version_Sync__c, Owner.Name,User_OS_App__c from Sync_Stat__c where createdDate>:dt and OwnerId IN:UserList';
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext bc, List<Sync_Stat__c> syncstats) {
        try{
            for(Sync_Stat__c sync : syncstats){
                if(UserWrapperMap.containsKey(sync.OwnerId)){
                    UserWrapper usrWrp = UserWrapperMap.get(sync.OwnerId);
                    if(sync.Version_Sync__c != usrWrp.VersionSync){
                        if(sync.Version_Sync__c == latestAppVersion || sync.Version_Sync__c == latestAndroidAppVersion){
                            usrWrp.VersionSync = sync.Version_Sync__c;
                            usrWrp.CreatedDate = sync.CreatedDate;
                            usrWrp.Platform = sync.User_OS_App__c;
                        }
                        else if(usrWrp.CreatedDate < sync.CreatedDate && (usrWrp.VersionSync != latestAppVersion || usrWrp.VersionSync != latestAndroidAppVersion)){
                            usrWrp.VersionSync = sync.Version_Sync__c;
                            usrWrp.CreatedDate = sync.CreatedDate;
                            usrWrp.Platform = sync.User_OS_App__c;
                        }
                    }
                }
                else{
                    UserWrapper usrWrp = new UserWrapper(sync.OwnerId,sync.Owner.Name,sync.Version_Sync__c,sync.CreatedDate,countryCodeMap.get(userCountryMap.get(sync.OwnerId)),sync.User_OS_App__c);
                    UserWrapperMap.put(sync.ownerId,usrWrp);
                }
            }
        }
        catch(Exception ex){
            System.debug('Exception'+ex);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        try{
            for(String usr : UserWrapperMap.keyset()){
                UserWrapper usrWrp = UserWrapperMap.get(usr);
                String userType;
                Integer userCountLatest = 1;
                Integer userCountActive = 1;
                if(UserProfileMap.get(usr).contains('Sales')){
                    userType = 'Sales';
                }
                else if(UserProfileMap.get(usr).contains('Quality')){
                    userType = 'Quality';
                }
                String uniqueKey = usrWrp.Country+'_'+userType+'_'+usrWrp.Platform;
                if(CountryMapLatest.containsKey(uniqueKey)){
                    userCountLatest = CountryMapLatest.get(uniqueKey);
                    if(usrWrp.VersionSync == latestAppVersion || usrWrp.VersionSync == latestAndroidAppVersion){
                        userCountLatest+=1;
                    }
                }
                CountryMapLatest.put(uniqueKey,userCountLatest);
                if(CountryMapActive.containsKey(uniqueKey)){
                    userCountActive = CountryMapActive.get(uniqueKey);
                    userCountActive+=1;
                }
                CountryMapActive.put(uniqueKey,userCountActive);
            }
            Map<String,UserApp_Sync_Version__c> usrappsyncMap = new Map<String,UserApp_Sync_Version__c>();
            for(String key : CountryMapActive.keyset()){
                UserApp_Sync_Version__c usrAppobj = new UserApp_Sync_Version__c ();
                usrAppobj.Unique_Key__c = key;
                if(key.contains('Quality')){
                    usrAppobj.Type__c = 'Quality';
                }
                else{
                    usrAppobj.Type__c = 'Sales';
                }
                if(key.contains('Android')){
                    usrAppobj.Platform__c = 'Android';
                    usrAppobj.App_Version__c = latestAndroidAppVersion;
                }
                else{
                    usrAppobj.Platform__c = 'iOS';
                    usrAppobj.App_Version__c = latestAppVersion;
                }
                if(CountryMapActive.get(key)==NUll || CountryMapActive.get(key)==0){
                    usrAppobj.Users_Synced__c = 0;
                }
                else{
                    usrAppobj.Users_Synced__c = CountryMapActive.get(key);
                }
                if(CountryMapLatest.get(key)==NUll || CountryMapActive.get(key)==Null || CountryMapActive.get(key)==0){
                    usrAppobj.Users_Synced_Percent__c = 0;
                }
                else{
                    usrAppobj.Users_Synced_Percent__c = (CountryMapLatest.get(key)*100)/CountryMapActive.get(key);
                }
                String Country = key.split('_')[0];
                usrAppobj.Country__c = Country;
                usrappsyncMap.put(key,usrAppobj);
            }
            if(!usrappsyncMap.isEmpty()){
                Database.upsert(usrappsyncMap.values(),UserApp_Sync_Version__c.Unique_Key__c);
            }
            UserAppVersionController.sendEmail(UserAppVersionController.sendEmailAttachment(UserWrapperMap,latestAppVersion,latestAndroidAppVersion));
            EDGE_UtilityClass.printGovLimits(200);
        }
        catch(Exception ex){
            System.debug('Exception@'+ex);
        }
    }
    
    public class UserWrapper{
        public Id OwnerId{ get;set; }
        public String OwnerName{ get;set; }
        public String VersionSync{ get;set; }
        public Datetime CreatedDate{ get;set; }
        public String Country{ get;set; }
        public String Platform{get;set; }
        
        public UserWrapper(String id,String name,String SyncVersion,Datetime dt,String CountryCode,String pt){
            OwnerId = id;
            OwnerName = name;
            VersionSync = SyncVersion;
            CreatedDate = dt;
            Country = CountryCode;
            Platform = pt;
        }
    }
}