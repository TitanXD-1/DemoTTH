public class FieldPermissionController {

    public FieldPermissionTopWrapper fieldPermissionsTopWrapper { get; set; }
    public List<FieldPermissionWrapper> fieldPermissions { get; set; }
    public final String SOBJECT_API_NAME = 'Order__c' ;
    
    public FieldPermissionController() {
        fieldPermissions = new List<FieldPermissionWrapper>();
        Map<String, List<ProfileLevelPermission>> profFieldLevelPermissionMap = new Map<String, List<ProfileLevelPermission>>();
		Set<String> profileNames = new Set<String>();
        
        Map<String, FieldWrapper> returnMap = getAllFieldDetailsToolingAPI(SOBJECT_API_NAME);
            
        for (FieldPermissions fieldPermission : [SELECT Field, PermissionsEdit, PermissionsRead, Parent.Profile.Name FROM FieldPermissions
                                                 where SObjectType= :SOBJECT_API_NAME AND Parent.profileid != null
                                                 order by Field]) 
        {

            String fieldAPIName = fieldPermission.Field;
            String profileName = fieldPermission.Parent.Profile.Name;
            
            ProfileLevelPermission plp = new ProfileLevelPermission();
            plp.profileName = profileName;
            plp.editable = fieldPermission.PermissionsEdit;
            plp.readable = fieldPermission.PermissionsRead;
            
            
            if(!profFieldLevelPermissionMap.containsKey(fieldAPIName)){
                FieldWrapper fw = new FieldWrapper(fieldAPIName);
                profFieldLevelPermissionMap.put(fieldAPIName,new List<ProfileLevelPermission>());
            }
            profFieldLevelPermissionMap.get(fieldAPIName).add(plp);
            
            if(!profileNames.contains(profileName)){
                profileNames.add(profileName);
            }
        }
        for(String fieldAPIName : profFieldLevelPermissionMap.keySet()){
            FieldPermissionWrapper dd = new FieldPermissionWrapper();
            dd.fieldWrapper = returnMap.get(fieldAPIName);
            //system.debug(fieldAPIName +' @@@ret : '+ returnMap.get(fieldAPIName));
            dd.profLevelPerm = profFieldLevelPermissionMap.get(fieldAPIName);
            fieldPermissions.add(dd);
        }
        
        fieldPermissionsTopWrapper = new FieldPermissionTopWrapper();
        fieldPermissionsTopWrapper.setOfProfileNames = profileNames;
        fieldPermissionsTopWrapper.fieldPermissions = fieldPermissions;
    }
    
    public Map<String, Schema.DescribeFieldResult> getAllFieldDetails(string sObjectAPIName){
        
        Map<String, Schema.DescribeFieldResult> returnMap = new Map<String, Schema.DescribeFieldResult>();
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(sObjectAPIName);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        for(String fieldName : MapofField.keySet()) 
        {
            Schema.SObjectField field = MapofField.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            //System.debug('Field Name: '+F.getName()); 
            returnMap.put(F.getName(), F);
        }

        return returnMap;
        
    }
    
    public Map<String, FieldWrapper> getAllFieldDetailsToolingAPI(string sObjectAPIName){
        
        Map<String, FieldWrapper> returnMap = new Map<String, FieldWrapper>();
        for(FieldDefinition fieldDefinition : [Select QualifiedApiName, Label, DataType, Length, Description from FieldDefinition 
                                where EntityDefinition.QualifiedApiName = :sObjectAPIName]) 
        {
            FieldWrapper fw = new FieldWrapper(fieldDefinition.QualifiedApiName);          
            //fw.field
            fw.label=fieldDefinition.Label;
            fw.type=fieldDefinition.DataType;
            fw.length=fieldDefinition.Length;
            fw.description=fieldDefinition.Description;
            returnMap.put(SOBJECT_API_NAME+'.'+fw.field, fw);
        }

        return returnMap;
        
    }
    
    public class FieldPermissionTopWrapper{
        public Set<String> setOfProfileNames { get; set; }
        public List<FieldPermissionWrapper> fieldPermissions { get; set; }
        public FieldPermissionTopWrapper(){}
    }

    public class FieldPermissionWrapper {
        //public String field { get; set; }
        public FieldWrapper fieldwrapper { get; set; }
        public List<ProfileLevelPermission> profLevelPerm { get; set; }       
        public FieldPermissionWrapper() {}
    }
    
    public class FieldWrapper {
        public String field { get; set; }
        public String label { get; set; }
        public String type { get; set; }
        public Decimal length { get; set; }
        public String description { get; set; }
        public FieldWrapper(String field) {
            this.field = field;
        }
    }
    
    public class ProfileLevelPermission{
        public String profileName { get; set; }
        public Boolean editable { get; set; }
        public Boolean readable { get; set; }
    }
}