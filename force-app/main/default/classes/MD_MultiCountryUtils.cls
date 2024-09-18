public class MD_MultiCountryUtils {

    //This method returns a map with region as key and a list of the permissions they use as value 
    public static Map<String, List<String>> getClusterPermissions(List<String> regionsList){
        System.debug('CG - in MD_MultiCountryUtils.getClusterPermissions. regionsList: ' + regionsList);
        
        List<DiageoCMS__Cluster__c> clusters = [SELECT MD_LocationType__c, MD_MyDiageoPermissions__c, DiageoCMS__ExternalId__c
                                                    FROM DiageoCMS__Cluster__c 
                                                    WHERE RecordType.developerName = 'ClusterLeaf' 
                                                        AND DiageoCMS__ExternalId__c IN :regionsList];
        
        System.debug('CG - in MD_MultiCountryUtils.getClusterPermissions. clusters: ' + clusters);
        
        Map<String, List<String>> permissionsByCountry = new Map<String, List<String>>();

        for(DiageoCMS__Cluster__c cluster : clusters) {
            permissionsByCountry.put(cluster.DiageoCMS__ExternalId__c, cluster.MD_MyDiageoPermissions__c.split(';'));
        }

        return permissionsByCountry;
    }
    
    //This method returns the permissions available on a specific region
    public static String getRegionPermissions(String region){
        List<DiageoCMS__Cluster__c> clusters = [SELECT Id, DiageoCMS__ExternalId__c, MD_MyDiageoPermissions__c 
                                                    FROM DiageoCMS__Cluster__c 
                                                    WHERE RecordType.developerName = 'ClusterLeaf' 
                                                        AND DiageoCMS__ExternalId__c = :region];
        if(clusters.size() > 0) {
        	return clusters.get(0).MD_MyDiageoPermissions__c;
        }
        return null;
    }
}